local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)

local PlayerDataService = {}
PlayerDataService._data = {}
PlayerDataService._remotes = nil

local XP_PER_LEVEL = 100
local BASE_MAX_HP = 10000 -- Max HP is 10000
local HP_PER_LEVEL = 10

local function getRemotes()
	if not PlayerDataService._remotes then
		PlayerDataService._remotes = ReplicatedStorage:WaitForChild("Remotes")
	end
	return PlayerDataService._remotes
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
	humanoid.MaxHealth = data.maxHp
	humanoid.Health = math.clamp(data.hp, 0, data.maxHp)
end

local function buildStatsPayload(player, data)
	local leaderstats = player:FindFirstChild("leaderstats")
	return {
		hp = data.hp,
		maxHp = data.maxHp,
		level = leaderstats and leaderstats.Level.Value or data.level,
		xp = leaderstats and leaderstats.XP.Value or data.xp,
		coins = leaderstats and leaderstats.Coins.Value or data.coins,
		equippedWeapon = data.equippedWeapon,
		quest = data.quest,
	}
end

function PlayerDataService:FireStatsUpdated(player)
	local data = self._data[player]
	if not data then
		return
	end
	getRemotes().StatsUpdated:FireClient(player, buildStatsPayload(player, data))
end

function PlayerDataService:GetData(player)
	return self._data[player]
end

function PlayerDataService:Init(remotes)
	self._remotes = remotes
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

	self._data[player] = {
		hp = 2000,
		maxHp = BASE_MAX_HP,
		level = 1,
		xp = 0,
		coins = 0,
		equippedWeapon = "WoodenSword",
		inventory = {},
		quest = {
			id = nil,
			accepted = false,
			completed = false,
			progress = 0,
		},
	}

	player.CharacterAdded:Connect(function()
		task.wait(0.1)
		local data = self._data[player]
		if data and data.hp <= 0 then
			data.hp = data.maxHp
		end
		syncHumanoid(player, data)
		self:FireStatsUpdated(player)
	end)

	if player.Character then
		syncHumanoid(player, self._data[player])
	end

	self:FireStatsUpdated(player)
end

function PlayerDataService:CleanupPlayer(player)
	self._data[player] = nil
end

function PlayerDataService:AddXP(player, amount)
	local data = self._data[player]
	if not data then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	data.xp += amount
	leaderstats.XP.Value = data.xp

	while data.xp >= XP_PER_LEVEL do
		data.xp -= XP_PER_LEVEL
		data.level += 1
		data.maxHp += HP_PER_LEVEL
		data.hp = data.maxHp
		leaderstats.Level.Value = data.level
		leaderstats.XP.Value = data.xp
		getRemotes().Notification:FireClient(player, "Level Up! You are now level " .. data.level)
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
	if not data then
		return
	end

	data.hp = math.max(0, data.hp - amount)
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

function PlayerDataService:GetWeaponDamage(player)
	local data = self._data[player]
	if not data then
		return 12
	end

	local weaponId = data.equippedWeapon or "WoodenSword"
	local weapon = Items[weaponId]
	return weapon and weapon.damage or 12
end

function PlayerDataService:SetEquippedWeapon(player, weaponId)
	local data = self._data[player]
	if not data or not Items[weaponId] then
		return false
	end

	data.equippedWeapon = weaponId
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
	for _, entry in data.inventory do
		if entry.id == itemId then
			entry.count += count
			getRemotes().InventoryUpdated:FireClient(player, data.inventory)
			return true
		end
	end

	table.insert(data.inventory, { id = itemId, count = count })
	getRemotes().InventoryUpdated:FireClient(player, data.inventory)
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
