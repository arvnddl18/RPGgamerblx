local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local Classes = require(Shared.Config.Classes)
local LevelGrowth = require(Shared.Config.LevelGrowth)
local ExperienceConfig = require(Shared.Config.ExperienceConfig)
local CombatConfig = require(Shared.Config.CombatConfig)
local DamageCalculator = require(Shared.Combat.DamageCalculator)
local RarityConfig = require(Shared.Config.RarityConfig)

local PlayerDataService = {}
PlayerDataService._data = {}
PlayerDataService._remotes = nil
PlayerDataService._saveService = nil
PlayerDataService._questService = nil

local EQUIPMENT_SLOTS = { "weapon", "helmet", "armor", "pants", "boots", "gloves" }

local function getEnhancementConfig()
	local ok, config = pcall(require, Shared.Config.EnhancementConfig)
	return ok and config or nil
end

local function normalizeInventoryEntry(entry)
	if type(entry) ~= "table" or not entry.id then
		return entry
	end
	local itemConfig = Items[entry.id]
	if not itemConfig then
		return entry
	end
	if itemConfig.supportsRarity and not entry.rarity then
		entry.rarity = "Common"
	end
	if itemConfig.slot then
		entry.enhanceLevel = entry.enhanceLevel or 0
		entry.rarity = entry.rarity or "Common"
		entry.statMultiplier = entry.statMultiplier or 1.0
		if not entry.uid then
			entry.uid = HttpService:GenerateGUID(false)
		end
	end
	return entry
end

local function getRemotes()
	if not PlayerDataService._remotes then
		PlayerDataService._remotes = ReplicatedStorage:WaitForChild("Remotes")
	end
	return PlayerDataService._remotes
end

local function fireInventoryUpdated(player, inventory)
	getRemotes().InventoryUpdated:FireClient(player, inventory)
end

local function getSaveService()
	if not PlayerDataService._saveService then
		local ok, Framework = pcall(function()
			return require(ReplicatedStorage.Shared.Framework)
		end)
		if ok then
			PlayerDataService._saveService = Framework:GetService("SaveService")
		end
	end
	return PlayerDataService._saveService
end

local function getQuestService()
	if not PlayerDataService._questService then
		local ok, Framework = pcall(function()
			return require(ReplicatedStorage.Shared.Framework)
		end)
		if ok then
			PlayerDataService._questService = Framework:GetService("QuestService")
		end
	end
	return PlayerDataService._questService
end

local function markSaveDirty(player)
	local saveService = getSaveService()
	if saveService then
		saveService:MarkDirty(player)
	end
end

local function createEmptyEquipped()
	return {
		weapon = nil,
		helmet = nil,
		armor = nil,
		pants = nil,
		boots = nil,
		gloves = nil,
	}
end

local function createEmptyData()
	local ok, StatsModule = pcall(require, ReplicatedStorage.Shared.Combat.StatsModule)
	local baseStats = ok and StatsModule.GetBaseStats() or {}
	return {
		classId = nil,
		hasSelectedClass = false,
		hp = 1,
		mana = 0,
		level = 1,
		xp = 0,
		requiredXp = LevelGrowth.GetRequiredXp(1),
		coins = 0,
		combatStats = baseStats,
		equipped = createEmptyEquipped(),
		equippedWeapon = nil,
		skillLoadout = {},
		inventory = {},
		quest = {
			id = nil,
			accepted = false,
			completed = false,
			progress = 0,
		},
		pvpMode = "Peaceful",
		lastCombatTime = nil,
		karmaPoints = 0,
		pkCount = 0,
		karmaFlagExpiry = nil,
		fastTravel = {
			visited = {},
			favorites = {},
		},
	}
end

local function getBuffService()
	if not PlayerDataService._buffService then
		local ok, Framework = pcall(function()
			return require(ReplicatedStorage.Shared.Framework)
		end)
		if ok then
			PlayerDataService._buffService = Framework:GetService("BuffService")
		end
	end
	return PlayerDataService._buffService
end

local function getRestService()
	if not PlayerDataService._restService then
		local ok, Framework = pcall(function()
			return require(ReplicatedStorage.Shared.Framework)
		end)
		if ok then
			PlayerDataService._restService = Framework:GetService("RestService")
		end
	end
	return PlayerDataService._restService
end

local function getKarmaService()
	if not PlayerDataService._karmaService then
		local ok, Framework = pcall(function()
			return require(ReplicatedStorage.Shared.Framework)
		end)
		if ok then
			PlayerDataService._karmaService = Framework:GetService("KarmaService")
		end
	end
	return PlayerDataService._karmaService
end

local function getPvpService()
	if not PlayerDataService._pvpService then
		local ok, Framework = pcall(function()
			return require(ReplicatedStorage.Shared.Framework)
		end)
		if ok then
			PlayerDataService._pvpService = Framework:GetService("PvpService")
		end
	end
	return PlayerDataService._pvpService
end

local function sumEquipmentBonuses(equipped)
	local bonuses = {}
	local enhConfig = getEnhancementConfig()

	for _, equippedItem in pairs(equipped) do
		if equippedItem and type(equippedItem) == "table" then
			local itemId = equippedItem.id
			local item = Items[itemId]
			local multiplier = equippedItem.statMultiplier or 1.0
			local enhanceLevel = equippedItem.enhanceLevel or 0
			local flatPerLevel = enhConfig and enhConfig.STAT_BONUS_PER_LEVEL or 1
			local flatBonus = enhanceLevel * flatPerLevel
			
			if item and item.statBonuses then
				for stat, value in pairs(item.statBonuses) do
					bonuses[stat] = (bonuses[stat] or 0) + (value * multiplier) + flatBonus
				end
			end
		elseif equippedItem and type(equippedItem) == "string" then
			local item = Items[equippedItem]
			if item and item.statBonuses then
				for stat, value in pairs(item.statBonuses) do
					bonuses[stat] = (bonuses[stat] or 0) + value
				end
			end
		end
	end

	return bonuses
end

local function syncHumanoid(player, data)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if not data.hasSelectedClass then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.MaxHealth = 100
		humanoid.Health = 100
		return
	end

	humanoid.MaxHealth = math.max(1, data.combatStats.maxHp)
	humanoid.Health = math.clamp(data.hp, 0, data.combatStats.maxHp)
	if character:GetAttribute("IsResting") then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	else
		humanoid.WalkSpeed = math.max(0, data.combatStats.movementSpeed)
		humanoid.JumpPower = 50
	end
end

local function buildStatsPayload(player, data)
	local leaderstats = player:FindFirstChild("leaderstats")
	local buffService = getBuffService()
	local shield = buffService and buffService:GetShieldAmount(player) or 0
	local statusEffects = buffService and buffService:GetActiveEffectsSnapshot(player) or {}
	local karmaService = getKarmaService()
	local karmaState = karmaService and karmaService:GetKarmaState(player) or "Innocent"
	local karmaFlagSecondsRemaining = karmaService and karmaService:GetKarmaFlagSecondsRemaining(player) or 0
	return {
		classId = data.classId,
		hasSelectedClass = data.hasSelectedClass,
		hp = data.hp,
		mana = data.mana,
		maxHp = data.combatStats.maxHp,
		maxMana = data.combatStats.maxMana,
		combatStats = data.combatStats,
		level = leaderstats and leaderstats.Level.Value or data.level,
		xp = leaderstats and leaderstats.XP.Value or data.xp,
		requiredXp = data.requiredXp,
		coins = leaderstats and leaderstats.Coins.Value or data.coins,
		gold = leaderstats and leaderstats.Coins.Value or data.coins,
		equippedWeapon = data.equippedWeapon,
		equipped = data.equipped,
		skillLoadout = data.skillLoadout,
		quest = data.quest,
		pvpMode = data.pvpMode or "Peaceful",
		karmaPoints = data.karmaPoints or 0,
		pkCount = data.pkCount or 0,
		karmaState = karmaState,
		karmaFlagSecondsRemaining = karmaFlagSecondsRemaining,
		shield = shield,
		statusEffects = statusEffects,
	}
end

function PlayerDataService:RecalculateStats(player)
	local data = self._data[player]
	if not data or not data.hasSelectedClass or not data.classId then
		return
	end

	local classConfig = Classes[data.classId]
	if not classConfig then
		return
	end

	local levelBonuses = LevelGrowth.GetLevelBonuses(data.level)
	local equipBonuses = sumEquipmentBonuses(data.equipped)
	local base = classConfig.baseStats
	
	local combinedBase = {}
	for k, v in pairs(base) do
		combinedBase[k] = v + (levelBonuses[k] or 0)
	end

	local ok, StatsModule = pcall(require, ReplicatedStorage.Shared.Combat.StatsModule)
	local buffService = getBuffService()
	local buffBonuses = buffService and buffService:GetActiveStatBonuses(player) or nil
	if ok then
		data.combatStats = StatsModule.CombineStats(combinedBase, equipBonuses, buffBonuses, nil)
	end
	
	data.requiredXp = LevelGrowth.GetRequiredXp(data.level)

	data.hp = math.clamp(data.hp, 0, data.combatStats.maxHp)
	data.mana = math.clamp(data.mana, 0, data.combatStats.maxMana)
	data.equippedWeapon = data.equipped.weapon
end

function PlayerDataService:ApplyClass(player, classId)
	local data = self._data[player]
	if not data or data.hasSelectedClass then
		return false
	end

	local classConfig = Classes[classId]
	if not classConfig then
		return false
	end

	data.classId = classId
	data.hasSelectedClass = true
	data.level = 1
	data.xp = 0
	data.coins = 0
	data.pvpMode = data.pvpMode or "Peaceful"
	data.equipped = createEmptyEquipped()

	for slot, itemId in classConfig.startingEquipment do
		local item = RarityConfig.GenerateItem(itemId, "Common")
		normalizeInventoryEntry(item)
		data.equipped[slot] = item
	end

	data.skillLoadout = {
		classConfig.skills.autoAttack,
		classConfig.skills.skill1,
		classConfig.skills.skill2,
		classConfig.skills.skill3,
		classConfig.skills.ultimate,
		"HealthPotion",
		"ManaPotion",
	}

	self:RecalculateStats(player)
	data.hp = data.combatStats.maxHp
	data.mana = data.combatStats.maxMana
	data.equippedWeapon = data.equipped.weapon

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Level.Value = data.level
		leaderstats.XP.Value = data.xp
		leaderstats.Coins.Value = data.coins
	end

	self:AddItem(player, "HealthPotion", 3)
	self:AddItem(player, "ManaPotion", 3)

	syncHumanoid(player, data)
	player:SetAttribute("PvpMode", data.pvpMode)
	self:FireStatsUpdated(player)
	return true
end

function PlayerDataService:GetSaveSnapshot(player)
	local data = self._data[player]
	if not data then
		return nil
	end

	local position = nil
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		position = { x = root.Position.X, y = root.Position.Y, z = root.Position.Z }
	end

	return {
		version = 2,
		classId = data.classId,
		hasSelectedClass = data.hasSelectedClass,
		level = data.level,
		xp = data.xp,
		coins = data.coins,
		hp = data.hp,
		mana = data.mana,
		equipped = data.equipped,
		equippedWeapon = data.equippedWeapon,
		inventory = data.inventory,
		skillLoadout = data.skillLoadout,
		quest = data.quest,
		pvpMode = data.pvpMode or "Peaceful",
		karmaPoints = data.karmaPoints or 0,
		pkCount = data.pkCount or 0,
		karmaFlagExpiry = data.karmaFlagExpiry,
		fastTravel = data.fastTravel or { visited = {}, favorites = {} },
		position = position,
	}
end

function PlayerDataService:LoadFromSnapshot(player, snapshot)
	local data = self._data[player]
	if not data or type(snapshot) ~= "table" then
		return
	end

	data.classId = snapshot.classId
	data.hasSelectedClass = snapshot.hasSelectedClass == true
	data.level = snapshot.level or 1
	data.xp = snapshot.xp or 0
	data.coins = snapshot.coins or 0
	data.hp = snapshot.hp or 1
	data.mana = snapshot.mana or 0
	data.equipped = snapshot.equipped or createEmptyEquipped()
	data.equippedWeapon = snapshot.equippedWeapon or data.equipped.weapon
	data.inventory = snapshot.inventory or {}
	for _, entry in data.inventory do
		normalizeInventoryEntry(entry)
	end
	for slot, equippedItem in pairs(data.equipped) do
		if type(equippedItem) == "table" then
			normalizeInventoryEntry(equippedItem)
		elseif type(equippedItem) == "string" then
			local migrated = RarityConfig.GenerateItem(equippedItem, "Common")
			normalizeInventoryEntry(migrated)
			data.equipped[slot] = migrated
		end
	end
	data.skillLoadout = snapshot.skillLoadout or {}
	data.quest = snapshot.quest or data.quest
	data.pvpMode = snapshot.pvpMode or data.pvpMode or "Peaceful"
	data.karmaPoints = snapshot.karmaPoints or 0
	data.pkCount = snapshot.pkCount or 0
	data.karmaFlagExpiry = snapshot.karmaFlagExpiry
	data.fastTravel = snapshot.fastTravel or { visited = {}, favorites = {} }
	if type(data.fastTravel.visited) ~= "table" then
		data.fastTravel.visited = {}
	end
	if type(data.fastTravel.favorites) ~= "table" then
		data.fastTravel.favorites = {}
	end

	if snapshot.position then
		data.savedPosition = Vector3.new(snapshot.position.x, snapshot.position.y, snapshot.position.z)
	end

	if data.hasSelectedClass then
		self:RecalculateStats(player)
		data.hp = math.min(data.hp, data.combatStats.maxHp)
		data.mana = math.min(data.mana, data.combatStats.maxMana)
	end

	data.requiredXp = LevelGrowth.GetRequiredXp(data.level)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Level.Value = data.level
		leaderstats.XP.Value = data.xp
		leaderstats.Coins.Value = data.coins
	end
end

function PlayerDataService:FireStatsUpdated(player)
	local data = self._data[player]
	if not data then
		return
	end
	getRemotes().StatsUpdated:FireClient(player, buildStatsPayload(player, data))
	markSaveDirty(player)

	local ok, Framework = pcall(function()
		return require(ReplicatedStorage.Shared.Framework)
	end)
	if ok then
		local partyService = Framework:GetService("PartyService")
		if partyService and partyService.OnMemberStatsChanged then
			partyService:OnMemberStatsChanged(player)
		end
	end
end

function PlayerDataService:GetData(player)
	return self._data[player]
end

function PlayerDataService:HasSelectedClass(player)
	local data = self._data[player]
	return data and data.hasSelectedClass or false
end

function PlayerDataService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._remotes = Framework:GetRemotesFolder()
	Framework:GetRemote("LevelUp")
	Framework:GetRemote("Notification")
	Framework:GetRemote("StatsUpdated")
	Framework:GetRemote("InventoryUpdated")
end

function PlayerDataService:SetupPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = leaderstats

	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Value = 0
	xp.Parent = leaderstats

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats

	self._data[player] = createEmptyData()
	player:SetAttribute("PvpMode", "Peaceful")

	local saveService = getSaveService()
	if saveService then
		local snapshot = saveService:LoadPlayer(player)
		if snapshot then
			self:LoadFromSnapshot(player, snapshot)
			if snapshot.hasSelectedClass and snapshot.classId then
				task.defer(function()
					local Framework = require(ReplicatedStorage.Shared.Framework)
					local classService = Framework:GetService("ClassService")
					if classService then
						local payload = classService:BuildClassPayload(snapshot.classId)
						if payload then
							getRemotes().ClassSelected:FireClient(player, payload)
						end
					end
				end)
			end
		end
	end

	local data = self._data[player]
	if data then
		player:SetAttribute("PvpMode", data.pvpMode or "Peaceful")
		local karmaService = getKarmaService()
		if karmaService then
			karmaService:RestorePlayerFlag(player, data)
			karmaService:SyncKarmaState(player)
		end
		local pvpService = getPvpService()
		if pvpService then
			pvpService:SyncPlayerAttribute(player)
		end
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		local data = self._data[player]
		if data and data.hasSelectedClass and data.hp <= 0 then
			data.hp = data.combatStats.maxHp
			data.mana = data.combatStats.maxMana
		end
		syncHumanoid(player, data)
		self:FireStatsUpdated(player)

		if data and data.savedPosition then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = CFrame.new(data.savedPosition)
				data.savedPosition = nil
			end
		end

		if data and data.hasSelectedClass then
			task.defer(function()
				local Framework = require(ReplicatedStorage.Shared.Framework)
				local equipmentService = Framework:GetService("EquipmentService")
				local combatService = Framework:GetService("CombatService")
				if equipmentService then
					equipmentService:EquipPlayer(player)
				end
				if combatService then
					combatService:GiveWeapon(player)
				end
			end)
		end
	end)

	if player.Character then
		syncHumanoid(player, self._data[player])
		if self._data[player].hasSelectedClass then
			task.defer(function()
				local Framework = require(ReplicatedStorage.Shared.Framework)
				local equipmentService = Framework:GetService("EquipmentService")
				local combatService = Framework:GetService("CombatService")
				if equipmentService then
					equipmentService:EquipPlayer(player)
				end
				if combatService then
					combatService:GiveWeapon(player)
				end
			end)
		end
	end

	self:FireStatsUpdated(player)
end

function PlayerDataService:CleanupPlayer(player)
	self._data[player] = nil
end

function PlayerDataService:AddXP(player, amount)
	local data = self._data[player]
	if not data or not data.hasSelectedClass then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	data.xp += amount
	leaderstats.XP.Value = data.xp
	
	if amount > 0 then
		local ok, Framework = pcall(function() return require(game:GetService("ReplicatedStorage").Shared.Framework) end)
		if ok then
			local combatEvent = Framework:GetRemote("CombatEvents")
			combatEvent:FireClient(player, "Exp", amount)
		end
	end

	while data.xp >= data.requiredXp and not ExperienceConfig.IsMaxLevel(data.level) do
		data.xp -= data.requiredXp
		data.level += 1
		leaderstats.Level.Value = data.level
		leaderstats.XP.Value = data.xp
		data.requiredXp = ExperienceConfig.GetRequiredXp(data.level)
		self:RecalculateStats(player)
		data.hp = data.combatStats.maxHp
		data.mana = data.combatStats.maxMana
		getRemotes().Notification:FireClient(player, "Level Up! You are now level " .. data.level)
		if getRemotes():FindFirstChild("LevelUp") then
			getRemotes().LevelUp:FireClient(player, data.level)
		end
	end

	if ExperienceConfig.IsMaxLevel(data.level) then
		data.xp = math.min(data.xp, data.requiredXp)
		leaderstats.XP.Value = data.xp
	end

	syncHumanoid(player, data)
	self:FireStatsUpdated(player)
end

function PlayerDataService:AddCoins(player, amount)
	local data = self._data[player]
	if not data then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	data.coins += amount
	leaderstats.Coins.Value = data.coins
	self:FireStatsUpdated(player)
	
	if amount > 0 then
		local ok, Framework = pcall(function() return require(game:GetService("ReplicatedStorage").Shared.Framework) end)
		if ok then
			local combatEvent = Framework:GetRemote("CombatEvents")
			combatEvent:FireClient(player, "Gold", amount)
		end
	end
end

function PlayerDataService:TakeCoins(player, amount)
	local data = self._data[player]
	if not data or data.coins < amount then
		return false
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false
	end

	data.coins -= amount
	leaderstats.Coins.Value = data.coins
	self:FireStatsUpdated(player)
	return true
end

function PlayerDataService:Damage(player, amount, attacker, skipMitigation, damageType)
	local data = self._data[player]
	if not data or not data.hasSelectedClass then
		return
	end

	data.lastCombatTime = tick()

	local restService = getRestService()
	if restService then
		restService:CancelRest(player, true)
	end

	local buffService = getBuffService()
	if buffService then
		amount = buffService:AbsorbDamage(player, amount)
	end

	if amount <= 0 then
		self:FireStatsUpdated(player)
		return
	end

	local mitigated
	if skipMitigation then
		mitigated = math.max(CombatConfig.minDamage, amount)
	elseif typeof(attacker) == "Instance" and attacker:IsA("Model") and CombatConfig.enemyMitigationUsesCalculator then
		local attackerStats = {
			physicalAttack = attacker:GetAttribute("Attack") or amount,
			magicAttack = attacker:GetAttribute("Attack") or amount,
			accuracy = 1,
			critChance = 0,
			critDamage = 1,
		}
		local targetStats = {
			defense = data.combatStats.defense,
			magicalResistance = data.combatStats.magicalResistance or 0,
			evasion = 0,
			critReduction = data.combatStats.critReduction or 0,
		}
		local hit = DamageCalculator.ComputeHit(0, attackerStats, targetStats, damageType or "physical")
		mitigated = hit.isMiss and 0 or hit.damage
	else
		local res = data.combatStats.defense
		if damageType == "magic" then
			res = data.combatStats.magicalResistance or 0
		end
		mitigated = math.max(CombatConfig.minDamage, amount - math.floor(res * 0.5))
	end
	data.hp = math.max(0, data.hp - mitigated)
	syncHumanoid(player, data)
	self:FireStatsUpdated(player)
	
	if player.Character and mitigated > 0 then
		local ok, Framework = pcall(function() return require(game:GetService("ReplicatedStorage").Shared.Framework) end)
		if ok then
			local combatEvent = Framework:GetRemote("CombatEvents")
			combatEvent:FireAllClients("Damage", player.Character, mitigated, false, attacker)
		end
	end

	if data.hp <= 0 then
		-- Kill-confirmation: apply karma penalty only when a Hostile player attacker
		-- lands the killing blow on a Peaceful victim. Environmental/mob deaths pass no Player attacker.
		if typeof(attacker) == "Instance" and attacker:IsA("Player") then
			local pvpService = getPvpService()
			local karmaService = getKarmaService()
			if pvpService and karmaService
				and pvpService:IsHostile(attacker)
				and pvpService:GetPvpMode(player) == "Peaceful"
			then
				karmaService:ApplyKillPenalty(attacker)
			end
		end

		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
		local ok, Framework = pcall(function()
			return require(ReplicatedStorage.Shared.Framework)
		end)
		if ok then
			local deathService = Framework:GetService("DeathService")
			if deathService then
				deathService:HandleDeath(player)
			end
		end
	end
end

function PlayerDataService:Heal(player, amount)
	local data = self._data[player]
	if not data then
		return false
	end

	data.hp = math.min(data.combatStats.maxHp, data.hp + amount)
	syncHumanoid(player, data)
	self:FireStatsUpdated(player)
	
	if player.Character and amount > 0 then
		local ok, Framework = pcall(function() return require(game:GetService("ReplicatedStorage").Shared.Framework) end)
		if ok then
			local combatEvent = Framework:GetRemote("CombatEvents")
			combatEvent:FireAllClients("Heal", player.Character, amount)
		end
	end
	
	return true
end

function PlayerDataService:RestoreMana(player, amount)
	local data = self._data[player]
	if not data then
		return false
	end

	data.mana = math.min(data.combatStats.maxMana, data.mana + amount)
	self:FireStatsUpdated(player)
	return true
end

function PlayerDataService:SpendMana(player, amount)
	local data = self._data[player]
	if not data or data.mana < amount then
		return false
	end

	data.mana -= amount
	self:FireStatsUpdated(player)
	return true
end

function PlayerDataService:GetWeaponDamage(player)
	local data = self._data[player]
	if not data then
		return 12
	end

	local weaponId = data.equippedWeapon
	local weapon = weaponId and Items[weaponId]
	local weaponDamage = weapon and weapon.damage or 0
	local enhanceLevel = 0
	if type(data.equipped.weapon) == "table" then
		enhanceLevel = data.equipped.weapon.enhanceLevel or 0
	end
	local enhConfig = getEnhancementConfig()
	local flatPerLevel = enhConfig and enhConfig.STAT_BONUS_PER_LEVEL or 1
	local enhanceBonus = enhanceLevel * flatPerLevel
	return math.max(1, data.combatStats.physicalAttack + weaponDamage + enhanceBonus)
end

function PlayerDataService:SetEquippedWeapon(player, weaponId)
	local data = self._data[player]
	if not data or not Items[weaponId] then
		return false
	end

	data.equipped.weapon = weaponId
	data.equippedWeapon = weaponId
	self:RecalculateStats(player)
	syncHumanoid(player, data)
	self:FireStatsUpdated(player)
	return true
end

function PlayerDataService:EquipItem(player, itemId)
	local data = self._data[player]
	if not data or not data.hasSelectedClass then
		return false, "Select a class first"
	end

	local itemConfig = Items[itemId]
	if not itemConfig or not itemConfig.slot then
		return false, "Item cannot be equipped"
	end

	-- Find the specific item entry in inventory
	local itemEntry = nil
	local itemIndex = nil
	for i, entry in ipairs(data.inventory) do
		if entry.id == itemId then
			itemEntry = entry
			itemIndex = i
			break
		end
	end

	if not itemEntry then
		return false, "Item not in inventory"
	end

	normalizeInventoryEntry(itemEntry)

	local slot = itemConfig.slot
	local currentEquipped = data.equipped[slot]
	
	-- Remove the item from inventory (since it's moving to equipped)
	if itemEntry.count > 1 then
		itemEntry.count -= 1
	else
		table.remove(data.inventory, itemIndex)
	end
	getRemotes().InventoryUpdated:FireClient(player, data.inventory)
	
	-- If something was already equipped, return it to inventory
	if currentEquipped then
		self:AddItem(player, currentEquipped, 1)
	end

	-- Store the full item entry (including rarity, uid, etc.) in equipped slot
	local equippedItem = {
		id = itemEntry.id,
		uid = itemEntry.uid,
		rarity = itemEntry.rarity,
		statMultiplier = itemEntry.statMultiplier,
		enhanceLevel = itemEntry.enhanceLevel or 0,
	}
	data.equipped[slot] = equippedItem
	
	self:RecalculateStats(player)
	syncHumanoid(player, data)
	self:FireStatsUpdated(player)
	return true
end

function PlayerDataService:UnequipItem(player, slot)
	local data = self._data[player]
	if not data or not data.hasSelectedClass then
		return false, "Select a class first"
	end

	if not slot or not data.equipped[slot] then
		return false, "Nothing equipped in that slot"
	end

	local equippedItem = data.equipped[slot]
	-- Add back the specific item object
	self:AddItem(player, equippedItem, 1)
	data.equipped[slot] = nil
	
	self:RecalculateStats(player)
	syncHumanoid(player, data)
	self:FireStatsUpdated(player)
	return true
end

function PlayerDataService:GetInventoryEntryByUid(player, uid)
	local data = self._data[player]
	if not data or not uid then
		return nil, nil
	end
	for index, entry in data.inventory do
		if entry.uid == uid then
			return entry, index
		end
	end
	return nil, nil
end

function PlayerDataService:FindEquippedSlotByUid(player, uid)
	local data = self._data[player]
	if not data or not uid then
		return nil
	end
	for _, slot in EQUIPMENT_SLOTS do
		local equipped = data.equipped[slot]
		if type(equipped) == "table" and equipped.uid == uid then
			return slot
		end
	end
	return nil
end

function PlayerDataService:HasMaterial(player, itemId, amount, minRarity)
	local data = self._data[player]
	if not data then
		return false
	end
	amount = amount or 1
	minRarity = minRarity or "Common"
	local total = 0
	for _, entry in data.inventory do
		if entry.id == itemId and RarityConfig.MeetsMinRarity(entry.rarity or "Common", minRarity) then
			total += entry.count or 1
		end
	end
	return total >= amount
end

function PlayerDataService:RemoveMaterial(player, itemId, amount, minRarity)
	local data = self._data[player]
	if not data then
		return false
	end
	amount = amount or 1
	minRarity = minRarity or "Common"
	local remaining = amount
	for i = #data.inventory, 1, -1 do
		local entry = data.inventory[i]
		if entry.id == itemId and RarityConfig.MeetsMinRarity(entry.rarity or "Common", minRarity) then
			local take = math.min(remaining, entry.count or 1)
			entry.count = (entry.count or 1) - take
			remaining -= take
			if entry.count <= 0 then
				table.remove(data.inventory, i)
			end
			if remaining <= 0 then
				fireInventoryUpdated(player, data.inventory)
				markSaveDirty(player)
				return true
			end
		end
	end
	return false
end

function PlayerDataService:RemoveItemByUid(player, uid)
	local data = self._data[player]
	if not data or not uid then
		return false
	end
	for i, entry in data.inventory do
		if entry.uid == uid then
			table.remove(data.inventory, i)
			fireInventoryUpdated(player, data.inventory)
			markSaveDirty(player)
			return true, entry
		end
	end
	return false
end

function PlayerDataService:UnequipByUid(player, uid)
	local slot = self:FindEquippedSlotByUid(player, uid)
	if slot then
		return self:UnequipItem(player, slot)
	end
	return false
end

function PlayerDataService:GetInventory(player)
	local data = self._data[player]
	return data and data.inventory or {}
end

function PlayerDataService:AddItem(player, itemData, count)
	local data = self._data[player]
	local itemId = type(itemData) == "table" and itemData.id or itemData
	
	if not data or not Items[itemId] then
		return false
	end

	count = count or 1
	local itemConfig = Items[itemId]
	local rarity = type(itemData) == "table" and itemData.rarity or nil
	
	if itemConfig.stackable then
		local stackRarity = itemConfig.supportsRarity and (rarity or "Common") or nil
		for _, entry in data.inventory do
			local rarityMatch = not stackRarity or (entry.rarity or "Common") == stackRarity
			if entry.id == itemId and rarityMatch then
				local maxStack = itemConfig.maxStack or 99
				entry.count = math.min(maxStack, entry.count + count)
				fireInventoryUpdated(player, data.inventory)
				markSaveDirty(player)
				local questService = getQuestService()
				if questService then questService:OnItemCollected(player, itemId, count) end
				return true
			end
		end
	end

	local newEntry = type(itemData) == "table" and itemData or { id = itemId }
	newEntry.count = count
	if itemConfig.slot and not newEntry.rarity then
		local generated = RarityConfig.GenerateItem(itemId, "Common")
		newEntry.rarity = generated.rarity
		newEntry.statMultiplier = generated.statMultiplier
	end
	normalizeInventoryEntry(newEntry)

	table.insert(data.inventory, newEntry)
	fireInventoryUpdated(player, data.inventory)
	markSaveDirty(player)
	local questService = getQuestService()
	if questService then
		questService:OnItemCollected(player, itemId, count)
	end
	return true
end

function PlayerDataService:RemoveItem(player, itemId, count, rarity)
	local data = self._data[player]
	if not data then
		return false
	end

	count = count or 1
	for i, entry in data.inventory do
		local rarityMatch = not rarity or (entry.rarity or "Common") == rarity
		if entry.id == itemId and rarityMatch then
			if entry.count < count then
				return false
			end
			entry.count -= count
			if entry.count <= 0 then
				table.remove(data.inventory, i)
			end
			fireInventoryUpdated(player, data.inventory)
			markSaveDirty(player)
			return true
		end
	end
	return false
end

function PlayerDataService:HasItem(player, itemId, count)
	local data = self._data[player]
	if not data then
		return false
	end

	count = count or 1
	local total = 0
	for _, entry in data.inventory do
		if entry.id == itemId then
			total += entry.count or 1
		end
	end
	return total >= count
end

function PlayerDataService:Start()
	Players.PlayerAdded:Connect(function(player)
		self:SetupPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:CleanupPlayer(player)
	end)

	for _, player in Players:GetPlayers() do
		self:SetupPlayer(player)
	end
end

return PlayerDataService
