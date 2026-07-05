local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skills = require(Shared.Config.Skills)

local SkillService = {}
SkillService._playerData = nil
SkillService._enemyService = nil
SkillService._inventoryService = nil
SkillService._combatService = nil
SkillService._partyService = nil
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
	self._buffService = Framework:GetService("BuffService")
	self._remotes = Framework:GetRemotesFolder()

	Framework:GetRemote("CastSkill")
	Framework:GetRemote("SkillCooldownUpdated")
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

function SkillService:FindMeleeTargets(character, range, coneOnly)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return {}
	end

	local origin = root.Position
	local look = root.CFrame.LookVector
	local targets = {}

	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if enemyRoot then
				local offset = enemyRoot.Position - origin
				local distance = offset.Magnitude
				if distance <= range then
					if not coneOnly or offset.Unit:Dot(look) > 0.2 then
						table.insert(targets, enemy)
					end
				end
			end
		end
	end

	return targets
end

function SkillService:FindNearestTarget(character, range)
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
				local distance = (enemyRoot.Position - root.Position).Magnitude
				if distance <= nearestDist then
					nearestDist = distance
					nearest = enemy
				end
			end
		end
	end

	return nearest
end

function SkillService:ApplySkillDamage(player, skill, targets)
	local attackerStats = self:GetAttackerStats(player)
	local baseDamage = skill.damage or 0

	for _, enemy in targets do
		self._enemyService:DamageEnemy(enemy, baseDamage, attackerStats, player, skill.skillType)

		if skill.statusEffect and self._buffService then
			self._buffService:ApplyEffect(enemy, skill.statusEffect, skill.statusDuration or 3, player, skill.statusIntensity)
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
	local targets = self:FindFriendlyTargets(player, range)

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

function SkillService:ExecuteSkill(player, skill, slotIndex)
	local character = player.Character
	if not character then
		return false
	end

	if skill.skillType == "heal" or skill.skillType == "buff" then
		return self:ExecuteFriendlySkill(player, skill)
	end

	local range = skill.range or 10
	local targets = {}

	if skill.aoe then
		targets = self:FindMeleeTargets(character, range, false)
	elseif skill.skillType == "melee" then
		targets = self:FindMeleeTargets(character, range, true)
	elseif skill.skillType == "magic" or skill.skillType == "ranged" then
		local nearest = self:FindNearestTarget(character, range)
		if nearest then
			targets = { nearest }
		end
	else
		targets = self:FindMeleeTargets(character, range, true)
	end

	if skill.slotType == "autoAttack" and slotIndex == 1 then
		targets = self:FindMeleeTargets(character, range, true)
	end

	if #targets == 0 and (skill.damage or 0) > 0 then
		return false
	end

	self:ApplySkillDamage(player, skill, targets)
	return true
end

function SkillService:HandleCastSkill(player, slotIndex)
	if not self._playerData:HasSelectedClass(player) then
		return
	end

	local character = player.Character
	if character and (character:GetAttribute("IsStunned") or character:GetAttribute("IsSilenced") or character:GetAttribute("IsKnockedDown")) then
		return
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

	local skill = Skills[skillId]
	if not skill then
		return
	end

	if self:IsOnCooldown(player, skillId) then
		return
	end

	local data = self._playerData:GetData(player)
	if skill.manaCost and skill.manaCost > 0 then
		if not data or data.mana < skill.manaCost then
			self._remotes.Notification:FireClient(player, "Not enough Mana!")
			return
		end
		self._playerData:SpendMana(player, skill.manaCost)
	end

	local success = self:ExecuteSkill(player, skill, slotIndex)
	if not success and skill.manaCost and skill.manaCost > 0 then
		self._playerData:RestoreMana(player, skill.manaCost)
		return
	end

	self:SetCooldown(player, skillId, skill.cooldown or 1)
end

function SkillService:Start()
	self._remotes.CastSkill.OnServerEvent:Connect(function(player, slotIndex)
		self:HandleCastSkill(player, slotIndex)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._cooldowns[player] = nil
	end)
end

return SkillService
