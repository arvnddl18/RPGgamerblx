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

-- Status attributes are derived from the active effects instead of being toggled
-- independently.  This prevents one expiring control effect from clearing another
-- one which is still active (for example, Stun while Knockdown is active).
function BuffService:SyncControlState(target)
	local character = target:IsA("Player") and target.Character or target
	if not character or not character:IsA("Model") then
		return
	end

	local state = {
		IsStunned = false,
		IsKnockedDown = false,
		IsSilenced = false,
		IsSlowed = false,
		slowMultiplier = 1,
	}
	for effectId, effect in pairs(self._activeBuffs[target] or {}) do
		local config = StatusEffectModule.EffectTypes[effectId]
		if config then
			if config.disablesInput or config.appliesAttribute == "IsStunned" then state.IsStunned = true end
			if config.forceRagdoll or config.appliesAttribute == "IsKnockedDown" then state.IsKnockedDown = true end
			if config.disablesSkills and not config.disablesInput then state.IsSilenced = true end
			if config.appliesAttribute == "IsSlowed" then
				state.IsSlowed = true
				state.slowMultiplier = math.min(state.slowMultiplier, effect.slowMultiplier or config.slowMultiplier or 0.5)
			end
		end
	end

	character:SetAttribute("IsStunned", state.IsStunned)
	character:SetAttribute("IsKnockedDown", state.IsKnockedDown)
	character:SetAttribute("IsSilenced", state.IsSilenced)
	character:SetAttribute("IsSlowed", state.IsSlowed)
	character:SetAttribute("StatusSlowMultiplier", state.slowMultiplier)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		if state.IsStunned or state.IsKnockedDown then
			humanoid:Move(Vector3.zero)
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		else
			local baseSpeed = humanoid:GetAttribute("BaseWalkSpeed") or humanoid.WalkSpeed
			humanoid.WalkSpeed = math.max(0, baseSpeed * state.slowMultiplier)
			humanoid.JumpPower = humanoid:GetAttribute("BaseJumpPower") or 50
		end
	end
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
				if extraData.slowMultiplier then
					existing.slowMultiplier = extraData.slowMultiplier
				end
			end
			self:SyncControlState(target)
			if target:IsA("Player") then
				self._playerData:RecalculateStats(target)
				self._playerData:SyncCharacterMovement(target)
				self._playerData:FireStatsUpdated(target)
			end
			return true
		elseif config.stackBehavior == "Stack" then
			existing.intensity = (existing.intensity or 1) + (customIntensity or 1)
			existing.duration = duration
			existing.startTime = tick()
			self:SyncControlState(target)
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
		slowMultiplier = extraData and extraData.slowMultiplier or config.slowMultiplier,
	}

	self:SyncControlState(target)

	if target:IsA("Player") then
		self._playerData:RecalculateStats(target)
		self._playerData:SyncCharacterMovement(target)
		self._playerData:FireStatsUpdated(target)
	end

	local character = target:IsA("Player") and target.Character or (typeof(target) == "Instance" and target)
	if character and character:IsA("Model") then
		local ok, Framework = pcall(function() return require(game:GetService("ReplicatedStorage").Shared.Framework) end)
		if ok then
			local combatEvent = Framework:GetRemote("CombatEvents")
			local labelText = string.upper(effectId) .. "!"
			combatEvent:FireAllClients("Skill", character, labelText)
		end
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


	self:SyncControlState(target)

	if target:IsA("Player") then
		self._playerData:RecalculateStats(target)
		self._playerData:SyncCharacterMovement(target)
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
