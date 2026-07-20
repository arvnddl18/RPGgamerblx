local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skills = require(Shared.Config.Skills)
local SkillConfig = require(Shared.Config.SkillConfig)
local TargetingUtil = require(Shared.Combat.TargetingUtil)
local SkillVfxConfig = require(Shared.Config.SkillVfxConfig)
local ClassMasteryConfig = require(Shared.Config.ClassMasteryConfig)

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
SkillService._autoFarm = {}
SkillService._autoFarmGeneration = {}
SkillService._autoFarmOrigin = {}
SkillService._targetLocks = {}

local AUTO_FARM_INTERVAL = 0.1
local AUTO_FARM_PATROL_RADIUS = 14
local AUTO_FARM_REACH_DISTANCE = 2.5
local AUTO_FARM_PICKUP_RADIUS = 8
local AUTO_FARM_PATROL_POINTS = {
	Vector3.new(1, 0, 0),
	Vector3.new(0, 0, 1),
	Vector3.new(-1, 0, 0),
	Vector3.new(0, 0, -1),
}
local TARGET_LOCK_MAX_DISTANCE = 100

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
	Framework:GetRemote("AutoFarmToggle")
	Framework:GetRemote("AutoFarmState")
	Framework:GetRemote("AutoAttackPerformed")
	Framework:GetRemote("AutoFarmSkillPerformed")
	Framework:GetRemote("TargetLockRequest")
	Framework:GetRemote("TargetLockUpdated")
end

function SkillService:GetLockedTarget(player)
	local target = self._targetLocks[player]
	if not target or not target.Parent or not CollectionService:HasTag(target, "Enemy")
		or (target:GetAttribute("Health") or 0) <= 0 then
		if target then
			self._targetLocks[player] = nil
			self._remotes.TargetLockUpdated:FireClient(player, nil)
		end
		return nil
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
	if not root or not targetRoot or (targetRoot.Position - root.Position).Magnitude > TARGET_LOCK_MAX_DISTANCE then
		self._targetLocks[player] = nil
		self._remotes.TargetLockUpdated:FireClient(player, nil)
		return nil
	end
	return target
end

function SkillService:SetTargetLock(player, target)
	if target == nil then
		self._targetLocks[player] = nil
		self._remotes.TargetLockUpdated:FireClient(player, nil)
		return
	end
	if typeof(target) ~= "Instance" or not target:IsA("Model") or not target.Parent then
		return
	end

	local isEnemy = CollectionService:HasTag(target, "Enemy")
	local isPlayer = Players:GetPlayerFromCharacter(target) ~= nil
	if not isEnemy and not (isPlayer and target ~= player.Character) then
		return
	end

	local health = target:GetAttribute("Health")
	if not health then
		local humanoid = target:FindFirstChild("Humanoid")
		if humanoid then
			health = humanoid.Health
		end
	end
	if (health or 0) <= 0 then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local targetRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
	if not root or not targetRoot or (targetRoot.Position - root.Position).Magnitude > TARGET_LOCK_MAX_DISTANCE then
		return
	end
	self._targetLocks[player] = target
	self._remotes.TargetLockUpdated:FireClient(player, target)
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
	local lockedTarget = self:GetLockedTarget(player)
	local lockedRoot = lockedTarget and (lockedTarget:FindFirstChild("HumanoidRootPart") or lockedTarget.PrimaryPart)
	if lockedRoot and skill.skillType ~= "heal" and skill.skillType ~= "buff" then
		local lockedOffset = lockedRoot.Position - root.Position
		if Vector3.new(lockedOffset.X, 0, lockedOffset.Z).Magnitude <= range + 0.5 then
			sanitized.targetInstance = lockedTarget
			sanitized.attackTargetPosition = lockedRoot.Position
			if skill.targetType == SkillConfig.TargetTypes.Ground then
				sanitized.groundPosition = lockedRoot.Position
			end
			if lockedOffset.Magnitude > 0.01 then
				sanitized.direction = lockedOffset.Unit
			end
		end
	end

	if skill.targetType == SkillConfig.TargetTypes.Ground then
		if not sanitized.groundPosition then
			return nil
		end
		if not TargetingUtil.IsValidTargetPosition(root.Position, sanitized.groundPosition, range) then
			return nil
		end
		local validationLook = lockedTarget and sanitized.direction or root.CFrame.LookVector
		if not TargetingUtil.IsInFront(root.Position, validationLook, sanitized.groundPosition) then
			return nil
		end
		sanitized.groundPosition = TargetingUtil.ClampGroundPosition(root.Position, sanitized.groundPosition, range)
	else
		-- Preserve the direction captured when an auto-attack starts so moving
		-- does not change a valid attack, while the target still must be ahead.
		if skill.slotType ~= "autoAttack" or not sanitized.direction then
			sanitized.direction = root.CFrame.LookVector
		end
		if skill.slotType == "autoAttack" and sanitized.attackOrigin then
			-- A dash can move the client before that movement reaches the server.
			-- Bound the accepted snapshot so it cannot be used as an arbitrary
			-- remote attack position.
			if (sanitized.attackOrigin - root.Position).Magnitude > 25 then
				sanitized.attackOrigin = root.Position
			end
		else
			sanitized.attackOrigin = root.Position
		end
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

function SkillService:FindPlayerDamageTargets(attacker, character, range, coneOnly, lookVector, origin)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not self._combatService then
		return {}
	end

	origin = origin or root.Position
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

function SkillService:FindMeleeTargets(character, range, coneOnly, lookVector, origin)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return {}
	end

	origin = origin or root.Position
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

function SkillService:FindNearestDamageTarget(attacker, character, range, requireFront, lookVector, origin)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	lookVector = lookVector or root.CFrame.LookVector
	origin = origin or root.Position

	local nearest = nil
	local nearestDist = range

	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if enemyRoot then
				local offset = enemyRoot.Position - origin
				local flatDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if flatDistance <= nearestDist then
					if requireFront == false or TargetingUtil.IsInFront(origin, lookVector, enemyRoot.Position) then
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
					local offset = otherRoot.Position - origin
					local flatDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude
					if flatDistance <= nearestDist then
						if requireFront == false or TargetingUtil.IsInFront(origin, lookVector, otherRoot.Position) then
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

function SkillService:ApplyMasteryUpgrade(skill, masteryRank, slotIndex)
	-- Slots 2-5 are Skill 1, Skill 2, Skill 3, and Ultimate respectively.
	-- Their upgrades unlock at Mastery Ranks 6-9.
	if slotIndex < 2 or slotIndex > 5 or masteryRank < slotIndex + 4 then
		return skill
	end

	local multiplier = ClassMasteryConfig.skillUpgradeMultiplier
	for _, key in { "damage", "healAmount", "shieldAmount" } do
		if skill[key] then
			skill[key] *= multiplier
		end
	end
	if skill.buffStats then
		local upgradedStats = {}
		for stat, value in pairs(skill.buffStats) do
			upgradedStats[stat] = value * multiplier
		end
		skill.buffStats = upgradedStats
	end
	return skill
end

function SkillService:ApplySkillDamage(player, skill, enemyTargets, playerTargets)
	local baseDamage = skill.damage or 0
	local damageType = self:ResolveDamageType(skill)

	for _, enemy in enemyTargets do
		local damageDealt = self._enemyService:DamageEnemy(enemy, baseDamage, self:GetAttackerStats(player), player, damageType)
		self._playerData:ApplyLifeSteal(player, damageDealt, damageType)

		if skill.statusEffect and self._buffService then
			self._buffService:ApplyEffect(enemy, skill.statusEffect, skill.statusDuration or 3, player, skill.statusIntensity)
		end
	end

	for _, targetPlayer in playerTargets do
		local damageDealt = self._combatService:DamagePlayer(player, targetPlayer, baseDamage, damageType)
		self._playerData:ApplyLifeSteal(player, damageDealt or 0, damageType)

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
		self._playerData:Heal(target, amountPerTarget, "Heal · " .. skill.name)
	end
end

function SkillService:ApplyFriendlyBuff(caster, skill, targets)
	if not skill.statusEffect or not self._buffService then
		return
	end

	-- These are caster stats: a support build makes the buffs it casts stronger
	-- and longer, without changing item/enemy status effects or hostile debuffs.
	local casterStats = self:GetAttackerStats(caster)
	local effectMultiplier = math.max(0, casterStats.buffEffectMultiplier or 1)
	local durationMultiplier = math.max(0, casterStats.buffDurationMultiplier or 1)
	local extraData = {}
	if skill.buffStats then
		extraData.statBonuses = {}
		for stat, value in pairs(skill.buffStats) do
			extraData.statBonuses[stat] = value * effectMultiplier
		end
	end
	if skill.shieldAmount then
		extraData.shieldAmount = skill.shieldAmount * effectMultiplier
	end
	local duration = math.max(0.1, (skill.statusDuration or 8) * durationMultiplier)

	for _, target in targets do
		self._buffService:ApplyEffect(
			target,
			skill.statusEffect,
			duration,
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
	local attackOrigin = targetData and targetData.attackOrigin or root.Position

	-- Auto-attacks resolve from the attack-start position and range, using the
	-- attack-start facing direction so rear attacks cannot deal damage.
	if skill.slotType == "autoAttack" then
		-- Prefer the target snapshot captured by the attacking client. This
		-- prevents a moving target's replicated position from lagging behind the
		-- attack and making a valid live-speed hit miss.
		local lockedTarget = self:GetLockedTarget(player)
		local lockedRoot = lockedTarget and (lockedTarget:FindFirstChild("HumanoidRootPart") or lockedTarget.PrimaryPart)
		local lockedDistance = lockedRoot and (Vector3.new(
			lockedRoot.Position.X - attackOrigin.X,
			0,
			lockedRoot.Position.Z - attackOrigin.Z
		).Magnitude)
		local snapshotTarget = lockedDistance and lockedDistance <= range + 0.5 and lockedTarget or nil
		if not snapshotTarget and targetData and targetData.targetUserId then
			snapshotTarget = Players:GetPlayerByUserId(targetData.targetUserId)
		elseif not snapshotTarget and targetData and targetData.targetInstance
			and CollectionService:HasTag(targetData.targetInstance, "Enemy") then
			local targetRoot = targetData.targetInstance:FindFirstChild("HumanoidRootPart") or targetData.targetInstance.PrimaryPart
			local targetDistance = targetRoot and (targetRoot.Position - attackOrigin).Magnitude
			if targetData.targetInstance ~= lockedTarget and targetDistance and targetDistance <= range + 0.5 then
				snapshotTarget = targetData.targetInstance
			end
		end

		if snapshotTarget and snapshotTarget.Parent then
			local snapshotRoot
			if snapshotTarget:IsA("Player") then
				local snapshotCharacter = snapshotTarget.Character
				snapshotRoot = snapshotCharacter and snapshotCharacter:FindFirstChild("HumanoidRootPart")
			else
				snapshotRoot = snapshotTarget:FindFirstChild("HumanoidRootPart") or snapshotTarget.PrimaryPart
			end
			local snapshotPosition = targetData.attackTargetPosition
			local snapshotDistance = snapshotPosition and (snapshotPosition - attackOrigin).Magnitude
			local currentDistance = snapshotRoot and (snapshotRoot.Position - attackOrigin).Magnitude
			local validDistance = snapshotDistance and snapshotDistance <= range + 0.5
			local stillReasonablyClose = currentDistance and currentDistance <= range + 8
			local validFacing = snapshotPosition and TargetingUtil.IsInFront(attackOrigin, lookVector, snapshotPosition)

			if snapshotRoot and validDistance and stillReasonablyClose and validFacing then
				if snapshotTarget:IsA("Player") then
					if self._combatService:CanDamagePlayer(player, snapshotTarget) then
						playerTargets = { snapshotTarget }
					end
				else
					if (snapshotTarget:GetAttribute("Health") or 0) > 0 then
						enemyTargets = { snapshotTarget }
					end
				end
			end
			if #enemyTargets > 0 or #playerTargets > 0 then
				return enemyTargets, playerTargets
			end
		end

		if targetType == SkillConfig.TargetTypes.Single then
			local target = self:FindNearestDamageTarget(player, character, range, true, lookVector, attackOrigin)
			if target then
				if typeof(target) == "Instance" and target:IsA("Player") then
					playerTargets = { target }
				else
					enemyTargets = { target }
				end
			end
		else
			enemyTargets = self:FindMeleeTargets(character, range, true, lookVector, attackOrigin)
			playerTargets = self:FindPlayerDamageTargets(player, character, range, true, lookVector, attackOrigin)
		end
		return enemyTargets, playerTargets
	end

	if targetType == SkillConfig.TargetTypes.Ground then
		local lockedTarget = self:GetLockedTarget(player)
		local lockedRoot = lockedTarget and (lockedTarget:FindFirstChild("HumanoidRootPart") or lockedTarget.PrimaryPart)
		local lockedDistance = lockedRoot and (lockedRoot.Position - root.Position).Magnitude
		local groundPos = lockedRoot and lockedDistance <= range + 0.5
			and lockedRoot.Position or (targetData and targetData.groundPosition or root.Position)
		local radius = skill.aoeRadius or range
		enemyTargets = TargetingUtil.GetTargetsInRadius(groundPos, radius)
		playerTargets = TargetingUtil.GetPlayersInRadius(groundPos, radius, function(otherPlayer)
			return otherPlayer ~= player and self._combatService:CanDamagePlayer(player, otherPlayer)
		end)
	elseif targetType == SkillConfig.TargetTypes.Circle then
		local radius = skill.aoeRadius or range
		local lockedTarget = self:GetLockedTarget(player)
		local lockedRoot = lockedTarget and (lockedTarget:FindFirstChild("HumanoidRootPart") or lockedTarget.PrimaryPart)
		local lockedDistance = lockedRoot and (lockedRoot.Position - root.Position).Magnitude
		local center = lockedRoot and lockedDistance <= range + 0.5 and lockedRoot.Position or root.Position
		enemyTargets = TargetingUtil.GetTargetsInRadius(center, radius)
		playerTargets = TargetingUtil.GetPlayersInRadius(center, radius, function(otherPlayer)
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
		local lockedTarget = self:GetLockedTarget(player)
		if lockedTarget then
			local lockedRoot = lockedTarget:FindFirstChild("HumanoidRootPart") or lockedTarget.PrimaryPart
			if lockedRoot and (lockedRoot.Position - root.Position).Magnitude <= range + 0.5 then
				primaryTarget = lockedTarget
			end
		end
		if not primaryTarget then
			if targetData and targetData.targetUserId then
				local targetPlayer = Players:GetPlayerByUserId(targetData.targetUserId)
				if targetPlayer and self._combatService:CanDamagePlayer(player, targetPlayer) then
					primaryTarget = targetPlayer
				end
			else
				primaryTarget = self:FindNearestDamageTarget(player, character, range)
			end
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

function SkillService:BuildAutoFarmTargetData(player, skill)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local target = TargetingUtil.GetNearestEnemy(root.Position, skill.range or 10)
	local nearestDist = skill.range or 10
	if target then
		local enemyRoot = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
		if enemyRoot then
			nearestDist = (enemyRoot.Position - root.Position).Magnitude
		end
	end

	local targetPlayer = TargetingUtil.GetNearestPlayer(root.Position, nearestDist, function(otherPlayer)
		if otherPlayer == player then return false end
		local c = otherPlayer.Character
		if not c then return false end
		local health = c:GetAttribute("Health")
		if not health then
			local hum = c:FindFirstChild("Humanoid")
			if hum then health = hum.Health end
		end
		return (health or 0) > 0
	end)

	if targetPlayer and targetPlayer.Character then
		target = targetPlayer.Character
	end

	local targetRoot = target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)
	if not targetRoot then
		return nil
	end

	local offset = targetRoot.Position - root.Position
	local flatOffset = Vector3.new(offset.X, 0, offset.Z)
	if flatOffset.Magnitude <= 0.01 then
		return nil
	end

	-- Face the selected mob on the server so AFK attacks use the same validated
	-- forward arc as normal attacks, without trusting a client-supplied target.
	root.CFrame = CFrame.lookAt(root.Position, root.Position + flatOffset)
	local targetData = {
		direction = flatOffset.Unit,
		attackOrigin = root.Position,
		attackTargetPosition = targetRoot.Position,
	}
	
	if targetPlayer and targetPlayer.Character == target then
		targetData.targetUserId = targetPlayer.UserId
	else
		targetData.targetInstance = target
	end

	if skill.targetType == SkillConfig.TargetTypes.Ground then
		targetData.groundPosition = targetRoot.Position
	end
	return targetData
end

function SkillService:TryAutoFarmSkill(player)
	local data = self._playerData:GetData(player)
	if not data then
		return false
	end

	-- Slots 6 and 7 are reserved for potions. Combat skills in slots 2-5
	-- are attempted in loadout order, with the normal server cooldown/mana
	-- checks still deciding whether the cast is accepted.
	for slotIndex = 2, 5 do
		local skillId = self:GetSkillIdForSlot(player, slotIndex)
		local skill = skillId and self:GetSkill(skillId)
		if skill
			and skill.slotType ~= "autoAttack"
			and skill.skillType ~= "heal"
			and skill.skillType ~= "buff"
			and (data.classMasteryRank or 1) >= (skill.requiredMasteryRank or 1)
			and not self:IsOnCooldown(player, skillId)
			and (data.mana or 0) >= (skill.manaCost or 0) then
			local targetData = self:BuildAutoFarmTargetData(player, skill)
			if targetData then
				self:HandleCastSkill(player, slotIndex, targetData, true)
				return true
			end
		end
	end
	return false
end

function SkillService:CollectNearbyAutoFarmPickups(player, origin)
	if not self._inventoryService or not origin then
		return
	end

	local pickupsFolder = workspace:FindFirstChild("Pickups")
	if not pickupsFolder then
		return
	end

	for _, pickup in pickupsFolder:GetChildren() do
		if pickup:IsA("BasePart") and pickup:GetAttribute("ItemId")
			and (pickup.Position - origin).Magnitude <= AUTO_FARM_PICKUP_RADIUS then
			self._inventoryService:CollectPickup(player, pickup)
		end
	end
end

function SkillService:SetAutoFarm(player, enabled)
	enabled = enabled == true
	if enabled and not self._playerData:HasSelectedClass(player) then
		enabled = false
	end

	local wasEnabled = self._autoFarm[player] == true
	if wasEnabled == enabled then
		self._remotes.AutoFarmState:FireClient(player, enabled)
		return
	end

	self._autoFarm[player] = enabled
	self._autoFarmGeneration[player] = (self._autoFarmGeneration[player] or 0) + 1
	local generation = self._autoFarmGeneration[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	self._autoFarmOrigin[player] = root and root.Position or nil
	self._remotes.AutoFarmState:FireClient(player, enabled)

	self._remotes.Notification:FireClient(player, enabled and "Auto-farm enabled (F to toggle)." or "Auto-farm disabled.")
	if not enabled then
		return
	end

	task.spawn(function()
		local patrolIndex = 1
		local returningToOrigin = false

		while self._autoFarm[player] and self._autoFarmGeneration[player] == generation and player.Parent do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not root or not humanoid or humanoid.Health <= 0 then
				task.wait(0.5)
				continue
			end

			-- A respawn or server teleport establishes a fresh farming origin.
			if not self._autoFarmOrigin[player]
				or (root.Position - self._autoFarmOrigin[player]).Magnitude > 40 then
				self._autoFarmOrigin[player] = root.Position
				patrolIndex = 1
				returningToOrigin = false
			end

			self:CollectNearbyAutoFarmPickups(player, root.Position)

			local skillId = self:GetSkillIdForSlot(player, 1)
			local skill = skillId and self:GetSkill(skillId)
			if skill and skill.slotType == "autoAttack" then
				local castSkill = not character:GetAttribute("IsCasting") and self:TryAutoFarmSkill(player)
				local targetData = not castSkill and self:BuildAutoFarmTargetData(player, skill) or nil
				if targetData then
					-- Hold the current patrol position while there is a mob in range.
					humanoid:MoveTo(root.Position)
					self:HandleCastSkill(player, 1, targetData, true)
				else
					local origin = self._autoFarmOrigin[player]
					local destination
					if returningToOrigin then
						destination = origin
					else
						local offset = AUTO_FARM_PATROL_POINTS[patrolIndex] * AUTO_FARM_PATROL_RADIUS
						destination = origin + offset
					end

					local flatDistance = (Vector3.new(destination.X, root.Position.Y, destination.Z) - root.Position).Magnitude
					if flatDistance <= AUTO_FARM_REACH_DISTANCE then
						if returningToOrigin then
							returningToOrigin = false
							patrolIndex = 1
						else
							patrolIndex += 1
							if patrolIndex > #AUTO_FARM_PATROL_POINTS then
								returningToOrigin = true
							end
						end
					else
						humanoid:MoveTo(Vector3.new(destination.X, root.Position.Y, destination.Z))
					end
				end
			end
			task.wait(AUTO_FARM_INTERVAL)
		end
	end)
end

function SkillService:HandleCastSkill(player, slotIndex, targetData, isAutoFarm)
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
	local requiredMasteryRank = skill.requiredMasteryRank or 1
	if not data or (data.classMasteryRank or 1) < requiredMasteryRank then
		self._remotes.Notification:FireClient(player, "Requires Mastery Rank " .. requiredMasteryRank .. "!")
		return
	end
	skill = self:ApplyMasteryUpgrade(skill, data.classMasteryRank, slotIndex)

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

	-- Auto-attacks should deal damage when their animation starts. The client
	-- starts the animation before sending CastSkill, so do not wait for the
	-- animation's duration here. Special skills keep their cast time.
	local castTime = skill.slotType == "autoAttack" and 0 or (skill.castTime or 0)

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
		if success and isAutoFarm then
			self._remotes.AutoFarmSkillPerformed:FireClient(player, skillId)
		end
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
	self._remotes.AutoFarmToggle.OnServerEvent:Connect(function(player, enabled)
		self:SetAutoFarm(player, enabled)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._cooldowns[player] = nil
		self._autoFarm[player] = nil
		self._autoFarmGeneration[player] = nil
		self._autoFarmOrigin[player] = nil
		self._targetLocks[player] = nil
	end)
	self._remotes.TargetLockRequest.OnServerEvent:Connect(function(player, target)
		if target == self._targetLocks[player] then
			self:SetTargetLock(player, nil)
		else
			self:SetTargetLock(player, target)
		end
	end)
end

return SkillService
