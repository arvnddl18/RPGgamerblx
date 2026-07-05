local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local StatusEffectModule = require(Shared.Combat.StatusEffectModule)

local BuffService = {}
BuffService._activeBuffs = {}
BuffService._playerData = nil

function BuffService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._enemyService = Framework:GetService("EnemyService")
end

function BuffService:ApplyEffect(target, effectId, duration, instigator, customIntensity, extraData)
	local config = StatusEffectModule.EffectTypes[effectId]
	if not config then
		return false
	end

	if not self._activeBuffs[target] then
		self._activeBuffs[target] = {}
	end

	local targetBuffs = self._activeBuffs[target]
	local existing = targetBuffs[effectId]

	if existing then
		if config.stackBehavior == "Ignore" then
			return false
		elseif config.stackBehavior == "Refresh" then
			existing.duration = duration
			existing.startTime = tick()
			if extraData then
				if extraData.statBonuses then
					existing.statBonuses = extraData.statBonuses
				end
				if extraData.shieldAmount then
					existing.shieldRemaining = extraData.shieldAmount
				end
			end
			if target:IsA("Player") then
				self._playerData:RecalculateStats(target)
				self._playerData:FireStatsUpdated(target)
			end
			return true
		elseif config.stackBehavior == "Stack" then
			existing.intensity = (existing.intensity or 1) + (customIntensity or 1)
			existing.duration = duration
			existing.startTime = tick()
			return true
		end
	end

	targetBuffs[effectId] = {
		id = effectId,
		duration = duration,
		startTime = tick(),
		instigator = instigator,
		intensity = customIntensity or 1,
		lastTick = tick(),
		statBonuses = extraData and extraData.statBonuses or nil,
		shieldRemaining = extraData and extraData.shieldAmount or nil,
	}

	if config.disablesInput then
		if target:IsA("Player") and target.Character then
			target.Character:SetAttribute("IsStunned", true)
		elseif typeof(target) == "Instance" then
			target:SetAttribute("IsStunned", true)
		end
	end

	if config.forceRagdoll then
		if target:IsA("Player") and target.Character then
			target.Character:SetAttribute("IsKnockedDown", true)
		elseif typeof(target) == "Instance" then
			target:SetAttribute("IsKnockedDown", true)
		end
	end

	if target:IsA("Player") then
		self._playerData:RecalculateStats(target)
		self._playerData:FireStatsUpdated(target)
	end

	return true
end

function BuffService:GetActiveEffectsSnapshot(target)
	local effects = self._activeBuffs[target]
	if not effects then
		return {}
	end

	local now = tick()
	local snapshot = {}
	for effectId, effect in pairs(effects) do
		local remaining = effect.duration - (now - effect.startTime)
		if remaining > 0 then
			table.insert(snapshot, {
				id = effectId,
				remaining = remaining,
				intensity = effect.intensity or 1,
			})
		end
	end

	table.sort(snapshot, function(a, b)
		return a.id < b.id
	end)

	return snapshot
end

function BuffService:GetActiveStatBonuses(target)
	local bonuses = {}
	local effects = self._activeBuffs[target]
	if not effects then
		return bonuses
	end

	for _, effect in pairs(effects) do
		if effect.statBonuses then
			for stat, value in pairs(effect.statBonuses) do
				bonuses[stat] = (bonuses[stat] or 0) + value
			end
		end
	end

	return bonuses
end

function BuffService:GetShieldAmount(target)
	local total = 0
	local effects = self._activeBuffs[target]
	if not effects then
		return 0
	end

	for _, effect in pairs(effects) do
		if effect.shieldRemaining and effect.shieldRemaining > 0 then
			total += effect.shieldRemaining
		end
	end

	return total
end

function BuffService:AbsorbDamage(target, amount)
	local remaining = amount
	local effects = self._activeBuffs[target]
	if not effects or remaining <= 0 then
		return remaining
	end

	for effectId, effect in pairs(effects) do
		if effect.shieldRemaining and effect.shieldRemaining > 0 then
			local absorbed = math.min(effect.shieldRemaining, remaining)
			effect.shieldRemaining -= absorbed
			remaining -= absorbed

			if effect.shieldRemaining <= 0 then
				self:RemoveEffect(target, effectId)
			elseif target:IsA("Player") then
				self._playerData:FireStatsUpdated(target)
			end

			if remaining <= 0 then
				break
			end
		end
	end

	return remaining
end

function BuffService:RemoveEffect(target, effectId)
	if not self._activeBuffs[target] then
		return
	end
	local effect = self._activeBuffs[target][effectId]
	if not effect then
		return
	end

	local config = StatusEffectModule.EffectTypes[effectId]
	self._activeBuffs[target][effectId] = nil

	if config and config.disablesInput then
		if target:IsA("Player") and target.Character then
			target.Character:SetAttribute("IsStunned", false)
		elseif typeof(target) == "Instance" then
			target:SetAttribute("IsStunned", false)
		end
	end

	if config and config.forceRagdoll then
		if target:IsA("Player") and target.Character then
			target.Character:SetAttribute("IsKnockedDown", false)
		elseif typeof(target) == "Instance" then
			target:SetAttribute("IsKnockedDown", false)
		end
	end

	if target:IsA("Player") then
		self._playerData:RecalculateStats(target)
		self._playerData:FireStatsUpdated(target)
	end
end

function BuffService:TickEffects()
	local now = tick()
	for target, effects in pairs(self._activeBuffs) do
		for effectId, effect in pairs(effects) do
			local config = StatusEffectModule.EffectTypes[effectId]

			if now - effect.startTime >= effect.duration then
				self:RemoveEffect(target, effectId)
			elseif config and config.isDoT and (now - effect.lastTick >= config.tickRate) then
				effect.lastTick = now
				local tickDamage = effect.intensity

				if target:IsA("Player") then
					self._playerData:Damage(target, tickDamage)
				else
					local attackerStats = { magicAttack = 0, physicalAttack = 0, accuracy = 1, critChance = 0, critDamage = 1 }
					self._enemyService:DamageEnemy(target, tickDamage, attackerStats, effect.instigator, config.damageType)
				end
			end
		end
	end
end

function BuffService:Start()
	task.spawn(function()
		while true do
			self:TickEffects()
			task.wait(0.2)
		end
	end)
end

return BuffService
