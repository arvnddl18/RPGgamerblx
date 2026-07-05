local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skills = require(Shared.Config.Skills)
local Items = require(Shared.Config.Items)
local DamageCalculator = require(Shared.Combat.DamageCalculator)

local SkillService = {}
SkillService._playerData = nil
SkillService._enemyService = nil
SkillService._inventoryService = nil
SkillService._combatService = nil
SkillService._cooldowns = {}
SkillService._remotes = nil

local POTION_SLOTS = {
	[6] = "HealthPotion",
	[7] = "ManaPotion",
}

function SkillService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._enemyService = Framework:GetService("EnemyService")
	self._inventoryService = Framework:GetService("InventoryService")
	self._combatService = Framework:GetService("CombatService")
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
		
		if skill.statusEffect then
			local Framework = require(ReplicatedStorage.Shared.Framework)
			local buffService = Framework:GetService("BuffService")
			if buffService then
				buffService:ApplyEffect(enemy, skill.statusEffect, skill.statusDuration or 3, player, skill.statusIntensity)
			end
		end
	end
end

function SkillService:ExecuteSkill(player, skill, slotIndex)
	local character = player.Character
	if not character then
		return false
	end

	if skill.skillType == "heal" or skill.skillType == "buff" then
		if skill.healAmount and skill.healAmount > 0 then
			self._playerData:Heal(player, skill.healAmount)
		end
		self._remotes.Notification:FireClient(player, "Cast " .. skill.name)
		return true
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

	if #targets == 0 and skill.skillType ~= "heal" and (skill.damage or 0) > 0 then
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
