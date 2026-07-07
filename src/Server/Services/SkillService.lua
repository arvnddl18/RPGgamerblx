local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skills = require(Shared.Config.Skills)
local SkillConfig = require(Shared.Config.SkillConfig)
local TargetingUtil = require(Shared.Combat.TargetingUtil)
local SkillVfxConfig = require(Shared.Config.SkillVfxConfig)

local SkillService = {}
SkillService._playerData = nil
SkillService._enemyService = nil
SkillService._inventoryService = nil
SkillService._combatService = nil
SkillService._partyService = nil
SkillService._pvpService = nil
SkillService._restService = nil
SkillService._buffService = nil
SkillService._cooldowns = {}
SkillService._remotes = nil

local POTION_SLOTS = {
	[6] = "HealthPotion",
	[7] = "ManaPotion",
}

local MULTI_TARGET_HEAL_SCALE = 0.7

function SkillService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._enemyService = Framework:GetService("EnemyService")
	self._inventoryService = Framework:GetService("InventoryService")
	self._combatService = Framework:GetService("CombatService")
	self._partyService = Framework:GetService("PartyService")
	self._pvpService = Framework:GetService("PvpService")
	self._restService = Framework:GetService("RestService")
	self._buffService = Framework:GetService("BuffService")
	self._remotes = Framework:GetRemotesFolder()

	Framework:GetRemote("CastSkill")
	Framework:GetRemote("SkillCooldownUpdated")
end

function SkillService:GetSkill(skillId)
	return Skills.Get(skillId)
end

function SkillService:GetSkillIdForSlot(player, slotIndex)
	local data = self._playerData:GetData(player)
	if not data or not data.skillLoadout then
		return nil
	end
	return data.skillLoadout[slotIndex]
end

function SkillService:IsOnCooldown(player, skillId)
	local playerCooldowns = self._cooldowns[player]
	if not playerCooldowns then
		return false
	end
	local expires = playerCooldowns[skillId]
	return expires and tick() < expires
end

function SkillService:SetCooldown(player, skillId, cooldown)
	if not self._cooldowns[player] then
		self._cooldowns[player] = {}
	end
	self._cooldowns[player][skillId] = tick() + cooldown
	self._remotes.SkillCooldownUpdated:FireClient(player, skillId, cooldown)
end

function SkillService:GetAttackerStats(player)
	local data = self._playerData:GetData(player)
	if not data then
		return {}
	end
	return data.combatStats
end

function SkillService:ValidateTargetData(player, skill, targetData)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local sanitized = TargetingUtil.SanitizeTargetData(targetData)
	local range = skill.range or 10

	if skill.targetType == SkillConfig.TargetTypes.Ground then
		if not sanitized.groundPosition then
			return nil
		end
		if not TargetingUtil.IsValidTargetPosition(root.Position, sanitized.groundPosition, range) then
			return nil
		end
		if not TargetingUtil.IsInFront(root.Position, root.CFrame.LookVector, sanitized.groundPosition) then
			return nil
		end
		sanitized.groundPosition = TargetingUtil.ClampGroundPosition(root.Position, sanitized.groundPosition, range)
	else
		sanitized.direction = root.CFrame.LookVector
	end

	if sanitized.targetUserId then
		local targetPlayer = Players:GetPlayerByUserId(sanitized.targetUserId)
		if not targetPlayer or targetPlayer == player then
			sanitized.targetUserId = nil
		end
	end

	return sanitized
end

function SkillService:FindFriendlyTargets(caster, range)
	if not self._partyService then
		return { caster }
	end

	local character = caster.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return { caster }
	end

	local candidates = self._partyService:GetPartyMembers(caster)
	local targets = {}

	for _, member in candidates do
		if member ~= caster and not self._partyService:AreInSameParty(caster, member) then
			continue
		end

		local memberCharacter = member.Character
		local memberRoot = memberCharacter and memberCharacter:FindFirstChild("HumanoidRootPart")
		local memberData = self._playerData:GetData(member)
		if memberRoot and memberData and memberData.hasSelectedClass and memberData.hp > 0 then
			local distance = (memberRoot.Position - root.Position).Magnitude
			if distance <= range then
				table.insert(targets, member)
			end
		end
	end

	if #targets == 0 then
		local casterData = self._playerData:GetData(caster)
		if casterData and casterData.hasSelectedClass and casterData.hp > 0 then
			return { caster }
		end
	end

	return targets
end

function SkillService:FindPlayerDamageTargets(attacker, character, range, coneOnly, lookVector)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not self._combatService then
		return {}
	end

	local origin = root.Position
	local look = lookVector or root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude > 0 then
		flatLook = flatLook.Unit
	end
	local targets = {}

	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= attacker and self._combatService:CanDamagePlayer(attacker, otherPlayer) then
			local otherCharacter = otherPlayer.Character
			local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
			local otherData = self._playerData:GetData(otherPlayer)
			if otherRoot and otherData and otherData.hp > 0 then
				local offset = otherRoot.Position - origin
				local flatOffset = Vector3.new(offset.X, 0, offset.Z)
				local flatDistance = flatOffset.Magnitude
				if flatDistance <= range then
					if not coneOnly or (flatDistance > 0 and flatOffset.Unit:Dot(flatLook) >= TargetingUtil.GetConeDotThreshold()) then
						table.insert(targets, otherPlayer)
					end
				end
			end
		end
	end

	return targets
end

function SkillService:FindMeleeTargets(character, range, coneOnly, lookVector)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return {}
	end

	local origin = root.Position
	local look = lookVector or root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude > 0 then
		flatLook = flatLook.Unit
	end
	local targets = {}

	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if enemyRoot then
				local offset = enemyRoot.Position - origin
				local flatOffset = Vector3.new(offset.X, 0, offset.Z)
				local flatDistance = flatOffset.Magnitude
				if flatDistance <= range then
					if not coneOnly or (flatDistance > 0 and flatOffset.Unit:Dot(flatLook) >= TargetingUtil.GetConeDotThreshold()) then
						table.insert(targets, enemy)
					end
				end
			end
		end
	end

	return targets
end

function SkillService:FindNearestDamageTarget(attacker, character, range)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local nearest = nil
	local nearestDist = range

	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if enemyRoot then
				local offset = enemyRoot.Position - root.Position
				local flatDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if flatDistance <= nearestDist then
					if TargetingUtil.IsInFront(root.Position, root.CFrame.LookVector, enemyRoot.Position) then
						nearestDist = flatDistance
						nearest = enemy
					end
				end
			end
		end
	end

	if attacker and self._combatService then
		for _, otherPlayer in Players:GetPlayers() do
			if otherPlayer ~= attacker and self._combatService:CanDamagePlayer(attacker, otherPlayer) then
				local otherCharacter = otherPlayer.Character
				local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
				local otherData = self._playerData:GetData(otherPlayer)
				if otherRoot and otherData and otherData.hp > 0 then
					local offset = otherRoot.Position - root.Position
					local flatDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude
					if flatDistance <= nearestDist then
						if TargetingUtil.IsInFront(root.Position, root.CFrame.LookVector, otherRoot.Position) then
							nearestDist = flatDistance
							nearest = otherPlayer
						end
					end
				end
			end
		end
	end

	return nearest
end

function SkillService:ResolveDamageType(skill)
	if skill.skillType == "magic" then
		return "magic"
	end
	return "physical"
end

function SkillService:ApplySkillDamage(player, skill, enemyTargets, playerTargets)
	local baseDamage = skill.damage or 0
	local damageType = self:ResolveDamageType(skill)

	for _, enemy in enemyTargets do
		self._enemyService:DamageEnemy(enemy, baseDamage, self:GetAttackerStats(player), player, damageType)

		if skill.statusEffect and self._buffService then
			self._buffService:ApplyEffect(enemy, skill.statusEffect, skill.statusDuration or 3, player, skill.statusIntensity)
		end
	end

	for _, targetPlayer in playerTargets do
		self._combatService:DamagePlayer(player, targetPlayer, baseDamage, damageType)

		if skill.statusEffect and self._buffService then
			self._buffService:ApplyEffect(targetPlayer, skill.statusEffect, skill.statusDuration or 3, player, skill.statusIntensity)
		end
	end
end

function SkillService:ApplyFriendlyHeal(caster, skill, targets)
	local casterStats = self:GetAttackerStats(caster)
	local healPower = casterStats.healPower or 1
	local baseHeal = (skill.healAmount or 0) * healPower
	if baseHeal <= 0 then
		return
	end

	local amountPerTarget = baseHeal
	if #targets > 1 then
		amountPerTarget *= MULTI_TARGET_HEAL_SCALE
	end

	for _, target in targets do
		self._playerData:Heal(target, amountPerTarget)
	end
end

function SkillService:ApplyFriendlyBuff(caster, skill, targets)
	if not skill.statusEffect or not self._buffService then
		return
	end

	local extraData = {}
	if skill.buffStats then
		extraData.statBonuses = skill.buffStats
	end
	if skill.shieldAmount then
		extraData.shieldAmount = skill.shieldAmount
	end

	for _, target in targets do
		self._buffService:ApplyEffect(
			target,
			skill.statusEffect,
			skill.statusDuration or 8,
			caster,
			skill.statusIntensity,
			extraData
		)
	end
end

function SkillService:ExecuteFriendlySkill(player, skill)
	local range = skill.range or 0
	local targets

	if skill.targetType == SkillConfig.TargetTypes.PartyCircle then
		targets = self:FindFriendlyTargets(player, range)
	elseif skill.targetType == SkillConfig.TargetTypes.Self then
		targets = { player }
	else
		targets = self:FindFriendlyTargets(player, range)
	end

	if skill.skillType == "heal" then
		if skill.healAmount and skill.healAmount > 0 then
			self:ApplyFriendlyHeal(player, skill, targets)
		end
	elseif skill.skillType == "buff" then
		self:ApplyFriendlyBuff(player, skill, targets)
	end

	local targetCount = #targets
	local suffix = targetCount > 1 and (" (" .. targetCount .. " allies)") or ""
	self._remotes.Notification:FireClient(player, "Cast " .. skill.name .. suffix)
	return true
end

function SkillService:ResolveTargets(player, skill, targetData)
	local character = player.Character
	if not character then
		return {}, {}
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return {}, {}
	end

	local range = skill.range or 10
	local lookVector = targetData and targetData.direction or root.CFrame.LookVector
	local targetType = skill.targetType
	local enemyTargets = {}
	local playerTargets = {}

	if targetType == SkillConfig.TargetTypes.Ground then
		local groundPos = targetData and targetData.groundPosition or root.Position
		local radius = skill.aoeRadius or range
		enemyTargets = TargetingUtil.GetTargetsInRadius(groundPos, radius)
		playerTargets = TargetingUtil.GetPlayersInRadius(groundPos, radius, function(otherPlayer)
			return otherPlayer ~= player and self._combatService:CanDamagePlayer(player, otherPlayer)
		end)
	elseif targetType == SkillConfig.TargetTypes.Circle then
		local radius = skill.aoeRadius or range
		enemyTargets = TargetingUtil.GetTargetsInRadius(root.Position, radius)
		playerTargets = TargetingUtil.GetPlayersInRadius(root.Position, radius, function(otherPlayer)
			return otherPlayer ~= player and self._combatService:CanDamagePlayer(player, otherPlayer)
		end)
	elseif targetType == SkillConfig.TargetTypes.Cone or targetType == SkillConfig.TargetTypes.Directional then
		local angle = skill.coneAngle or 60
		enemyTargets = TargetingUtil.GetTargetsInCone(root.Position, lookVector, range, angle)
		playerTargets = TargetingUtil.GetPlayersInCone(root.Position, lookVector, range, angle, function(otherPlayer)
			return otherPlayer ~= player and self._combatService:CanDamagePlayer(player, otherPlayer)
		end)
	elseif targetType == SkillConfig.TargetTypes.Single then
		local primaryTarget = nil
		if targetData and targetData.targetUserId then
			local targetPlayer = Players:GetPlayerByUserId(targetData.targetUserId)
			if targetPlayer and self._combatService:CanDamagePlayer(player, targetPlayer) then
				primaryTarget = targetPlayer
			end
		else
			primaryTarget = self:FindNearestDamageTarget(player, character, range)
		end

		if primaryTarget then
			if skill.aoeRadius and skill.aoeRadius > 0 then
				local targetRoot = primaryTarget:FindFirstChild("HumanoidRootPart") or primaryTarget.PrimaryPart
				if targetRoot then
					enemyTargets = TargetingUtil.GetTargetsInRadius(targetRoot.Position, skill.aoeRadius)
					playerTargets = TargetingUtil.GetPlayersInRadius(targetRoot.Position, skill.aoeRadius, function(otherPlayer)
						return otherPlayer ~= player and self._combatService:CanDamagePlayer(player, otherPlayer)
					end)
				end
			else
				if typeof(primaryTarget) == "Instance" and primaryTarget:IsA("Player") then
					playerTargets = { primaryTarget }
				else
					enemyTargets = { primaryTarget }
				end
			end
		end
	else
		enemyTargets = self:FindMeleeTargets(character, range, true, lookVector)
		playerTargets = self:FindPlayerDamageTargets(player, character, range, true, lookVector)
	end



	return enemyTargets, playerTargets
end

function SkillService:ExecuteSkill(player, skill, slotIndex, targetData)
	local character = player.Character
	if not character then
		return false
	end

	if skill.skillType == "heal" or skill.skillType == "buff" then
		return self:ExecuteFriendlySkill(player, skill)
	end

	local enemyTargets, playerTargets = self:ResolveTargets(player, skill, targetData)

	local totalTargets = #enemyTargets + #playerTargets
	if totalTargets == 0 and (skill.damage or 0) > 0 then
		return false
	end

	self:ApplySkillDamage(player, skill, enemyTargets, playerTargets)
	return true
end

function SkillService:HandleCastSkill(player, slotIndex, targetData)
	if not self._playerData:HasSelectedClass(player) then
		return
	end

	local character = player.Character
	if character and (character:GetAttribute("IsStunned") or character:GetAttribute("IsSilenced") or character:GetAttribute("IsKnockedDown")) then
		return
	end

	if self._restService then
		self._restService:CancelRest(player, true)
	end

	slotIndex = math.floor(slotIndex)
	if slotIndex < 1 or slotIndex > 7 then
		return
	end

	if POTION_SLOTS[slotIndex] then
		self._inventoryService:UseItem(player, POTION_SLOTS[slotIndex])
		return
	end

	local skillId = self:GetSkillIdForSlot(player, slotIndex)
	if not skillId then
		return
	end

	local skill = self:GetSkill(skillId)
	if not skill then
		return
	end

	local data = self._playerData:GetData(player)
	local requiredLevel = skill.requiredLevel or 1
	if not data or data.level < requiredLevel then
		self._remotes.Notification:FireClient(player, "Requires Level " .. requiredLevel .. "!")
		return
	end

	if self:IsOnCooldown(player, skillId) then
		return
	end

	if skill.manaCost and skill.manaCost > 0 then
		if not data or data.mana < skill.manaCost then
			self._remotes.Notification:FireClient(player, "Not enough Mana!")
			return
		end
		self._playerData:SpendMana(player, skill.manaCost)
	end

	local validatedTargetData = self:ValidateTargetData(player, skill, targetData)
	if not validatedTargetData then
		if skill.manaCost and skill.manaCost > 0 then
			self._playerData:RestoreMana(player, skill.manaCost)
		end
		self._remotes.Notification:FireClient(player, "Invalid target position!")
		return
	end

	self:SetCooldown(player, skillId, skill.cooldown or 1)

	local vfxKey = SkillVfxConfig.GetForSkill(skillId)
	if vfxKey then
		self._remotes.PlaySkillVfx:FireAllClients(player, vfxKey)
	end

	local castTime = skill.castTime or 0

	if character then
		character:SetAttribute("IsCasting", castTime > 0)
	end

	local function executeAndFinalize()
		if not player.Parent then
			return
		end
		local character = player.Character
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local success = self:ExecuteSkill(player, skill, slotIndex, validatedTargetData)
		if not success and skill.manaCost and skill.manaCost > 0 then
			self._playerData:RestoreMana(player, skill.manaCost)
		end

		if character and character.Parent then
			character:SetAttribute("IsCasting", false)
		end
	end

	if castTime > 0 then
		task.delay(castTime, executeAndFinalize)
	else
		executeAndFinalize()
	end
end

function SkillService:Start()
	self._remotes.CastSkill.OnServerEvent:Connect(function(player, slotIndex, targetData)
		self:HandleCastSkill(player, slotIndex, targetData)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._cooldowns[player] = nil
	end)
end

return SkillService
