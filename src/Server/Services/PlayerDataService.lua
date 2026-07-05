local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local Classes = require(Shared.Config.Classes)
local LevelGrowth = require(Shared.Config.LevelGrowth)

local PlayerDataService = {}
PlayerDataService._data = {}
PlayerDataService._remotes = nil
PlayerDataService._saveService = nil
PlayerDataService._questService = nil

local EQUIPMENT_SLOTS = { "weapon", "helmet", "armor", "pants", "boots", "gloves" }

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

local function getRemotes()
	if not PlayerDataService._remotes then
		PlayerDataService._remotes = ReplicatedStorage:WaitForChild("Remotes")
	end
	return PlayerDataService._remotes
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
	return {
		classId = nil,
		hasSelectedClass = false,
		hp = 1,
		maxHp = 1,
		mana = 0,
		maxMana = 0,
		level = 1,
		xp = 0,
		requiredXp = LevelGrowth.GetRequiredXp(1),
		coins = 0,
		physicalAttack = 0,
		magicAttack = 0,
		defense = 0,
		movementSpeed = 0,
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
	}
end

local function sumEquipmentBonuses(equipped)
	local bonuses = {
		maxHp = 0,
		maxMana = 0,
		physicalAttack = 0,
		magicAttack = 0,
		defense = 0,
		movementSpeed = 0,
	}

	for _, slot in EQUIPMENT_SLOTS do
		local itemId = equipped[slot]
		if itemId then
			local item = Items[itemId]
			if item and item.statBonuses then
				for stat, value in item.statBonuses do
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

	humanoid.MaxHealth = math.max(1, data.maxHp)
	humanoid.Health = math.clamp(data.hp, 0, data.maxHp)
	humanoid.WalkSpeed = math.max(0, data.movementSpeed)
	humanoid.JumpPower = 50
end

local function buildStatsPayload(player, data)
	local leaderstats = player:FindFirstChild("leaderstats")
	return {
		classId = data.classId,
		hasSelectedClass = data.hasSelectedClass,
		hp = data.hp,
		maxHp = data.maxHp,
		mana = data.mana,
		maxMana = data.maxMana,
		level = leaderstats and leaderstats.Level.Value or data.level,
		xp = leaderstats and leaderstats.XP.Value or data.xp,
		requiredXp = data.requiredXp,
		coins = leaderstats and leaderstats.Coins.Value or data.coins,
		gold = leaderstats and leaderstats.Coins.Value or data.coins,
		physicalAttack = data.physicalAttack,
		magicAttack = data.magicAttack,
		defense = data.defense,
		movementSpeed = data.movementSpeed,
		equippedWeapon = data.equippedWeapon,
		equipped = data.equipped,
		skillLoadout = data.skillLoadout,
		quest = data.quest,
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

	data.maxHp = base.maxHp + levelBonuses.maxHp + equipBonuses.maxHp
	data.maxMana = base.maxMana + levelBonuses.maxMana + equipBonuses.maxMana
	data.physicalAttack = base.physicalAttack + levelBonuses.physicalAttack + equipBonuses.physicalAttack
	data.magicAttack = base.magicAttack + levelBonuses.magicAttack + equipBonuses.magicAttack
	data.defense = base.defense + levelBonuses.defense + equipBonuses.defense
	data.movementSpeed = base.movementSpeed + equipBonuses.movementSpeed
	data.requiredXp = LevelGrowth.GetRequiredXp(data.level)

	data.hp = math.clamp(data.hp, 0, data.maxHp)
	data.mana = math.clamp(data.mana, 0, data.maxMana)
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
	data.equipped = createEmptyEquipped()

	for slot, itemId in classConfig.startingEquipment do
		data.equipped[slot] = itemId
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
	data.hp = data.maxHp
	data.mana = data.maxMana
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
		version = 1,
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
	data.skillLoadout = snapshot.skillLoadout or {}
	data.quest = snapshot.quest or data.quest

	if snapshot.position then
		data.savedPosition = Vector3.new(snapshot.position.x, snapshot.position.y, snapshot.position.z)
	end

	if data.hasSelectedClass then
		self:RecalculateStats(player)
		data.hp = math.min(data.hp, data.maxHp)
		data.mana = math.min(data.mana, data.maxMana)
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

	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		local data = self._data[player]
		if data and data.hasSelectedClass and data.hp <= 0 then
			data.hp = data.maxHp
			data.mana = data.maxMana
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

	while data.xp >= data.requiredXp do
		data.xp -= data.requiredXp
		data.level += 1
		leaderstats.Level.Value = data.level
		leaderstats.XP.Value = data.xp
		self:RecalculateStats(player)
		data.hp = data.maxHp
		data.mana = data.maxMana
		getRemotes().Notification:FireClient(player, "Level Up! You are now level " .. data.level)
		if getRemotes():FindFirstChild("LevelUp") then
			getRemotes().LevelUp:FireClient(player, data.level)
		end
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

function PlayerDataService:Damage(player, amount)
	local data = self._data[player]
	if not data or not data.hasSelectedClass then
		return
	end

	local mitigated = math.max(1, amount - math.floor(data.defense * 0.5))
	data.hp = math.max(0, data.hp - mitigated)
	syncHumanoid(player, data)
	self:FireStatsUpdated(player)

	if data.hp <= 0 then
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

	data.hp = math.min(data.maxHp, data.hp + amount)
	syncHumanoid(player, data)
	self:FireStatsUpdated(player)
	return true
end

function PlayerDataService:RestoreMana(player, amount)
	local data = self._data[player]
	if not data then
		return false
	end

	data.mana = math.min(data.maxMana, data.mana + amount)
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
	return math.max(1, data.physicalAttack + weaponDamage)
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

	local item = Items[itemId]
	if not item or not item.slot then
		return false, "Item cannot be equipped"
	end

	if not self:HasItem(player, itemId, 1) then
		return false, "Item not in inventory"
	end

	local slot = item.slot
	local currentId = data.equipped[slot]
	if currentId then
		self:AddItem(player, currentId, 1)
	end

	if not self:RemoveItem(player, itemId, 1) then
		return false, "Could not remove item from inventory"
	end

	data.equipped[slot] = itemId
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

	local itemId = data.equipped[slot]
	self:AddItem(player, itemId, 1)
	data.equipped[slot] = nil
	self:RecalculateStats(player)
	syncHumanoid(player, data)
	self:FireStatsUpdated(player)
	return true
end

function PlayerDataService:GetInventory(player)
	local data = self._data[player]
	return data and data.inventory or {}
end

function PlayerDataService:AddItem(player, itemId, count)
	local data = self._data[player]
	if not data or not Items[itemId] then
		return false
	end

	count = count or 1
	local item = Items[itemId]
	for _, entry in data.inventory do
		if entry.id == itemId then
			local maxStack = item.maxStack or 99
			entry.count = math.min(maxStack, entry.count + count)
			getRemotes().InventoryUpdated:FireClient(player, data.inventory)
			markSaveDirty(player)
			local questService = getQuestService()
			if questService then
				questService:OnItemCollected(player, itemId, count)
			end
			return true
		end
	end

	table.insert(data.inventory, { id = itemId, count = count })
	getRemotes().InventoryUpdated:FireClient(player, data.inventory)
	markSaveDirty(player)
	local questService = getQuestService()
	if questService then
		questService:OnItemCollected(player, itemId, count)
	end
	return true
end

function PlayerDataService:RemoveItem(player, itemId, count)
	local data = self._data[player]
	if not data then
		return false
	end

	count = count or 1
	for i, entry in data.inventory do
		if entry.id == itemId then
			if entry.count < count then
				return false
			end
			entry.count -= count
			if entry.count <= 0 then
				table.remove(data.inventory, i)
			end
			getRemotes().InventoryUpdated:FireClient(player, data.inventory)
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
	for _, entry in data.inventory do
		if entry.id == itemId and entry.count >= count then
			return true
		end
	end
	return false
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
