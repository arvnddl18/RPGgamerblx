local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TreasureChestConfig = require(Shared.Config.TreasureChestConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local MaterialRarityConfig = require(Shared.Config.MaterialRarityConfig)
local Items = require(Shared.Config.Items)

local TreasureChestService = {}
TreasureChestService._playerData = nil
TreasureChestService._partyService = nil
TreasureChestService._remotes = nil
TreasureChestService._nextChestId = 1
TreasureChestService._activeChests = {}

function TreasureChestService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._partyService = Framework:GetService("PartyService")
	self._remotes = Framework:GetRemotesFolder()
	Framework:GetRemote("ChestOpened")
end

function TreasureChestService:_createChestModel(position, rarity)
	local chest = Instance.new("Model")
	chest.Name = rarity .. " Treasure Chest"
	
	-- Base part
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(4, 3, 3)
	base.Position = position + Vector3.new(0, 1.5, 0)
	base.Anchored = true
	base.Color = RarityConfig.GetColor(rarity)
	base.Material = Enum.Material.Wood
	base.Parent = chest
	
	chest.PrimaryPart = base
	
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.ObjectText = rarity .. " Chest"
	prompt.HoldDuration = TreasureChestConfig.HOLD_DURATIONS[rarity] or 1
	prompt.MaxActivationDistance = 10
	prompt.Parent = base
	
	return chest
end

function TreasureChestService:SpawnWorldChest(spawnData)
	local chestModel = self:_createChestModel(spawnData.position, spawnData.rarity)
	local chestId = "world_" .. self._nextChestId
	self._nextChestId += 1
	
	chestModel:SetAttribute("ChestId", chestId)
	chestModel:SetAttribute("ChestSource", "world")
	chestModel:SetAttribute("ChestRarity", spawnData.rarity)
	
	self._activeChests[chestId] = {
		model = chestModel,
		source = "world",
		rarity = spawnData.rarity,
		spawnData = spawnData,
	}
	
	chestModel.PrimaryPart.ProximityPrompt.Triggered:Connect(function(player)
		self:HandleChestOpened(player, chestId)
	end)
	
	local chestsFolder = workspace:FindFirstChild("TreasureChests")
	if not chestsFolder then
		chestsFolder = Instance.new("Folder")
		chestsFolder.Name = "TreasureChests"
		chestsFolder.Parent = workspace
	end
	
	chestModel.Parent = chestsFolder
end

function TreasureChestService:SpawnBossChest(position, bossId)
	local rarity = TreasureChestConfig.BOSS_CHEST_MAPPINGS[bossId]
	if not rarity then return end -- Boss doesn't drop a chest
	
	-- Offset position slightly so it doesn't spawn exactly inside the boss corpse
	local spawnPos = position + Vector3.new(0, 0, 3)
	
	local chestModel = self:_createChestModel(spawnPos, rarity)
	local chestId = "boss_" .. self._nextChestId
	self._nextChestId += 1
	
	chestModel:SetAttribute("ChestId", chestId)
	chestModel:SetAttribute("ChestSource", "boss")
	chestModel:SetAttribute("ChestRarity", rarity)
	
	self._activeChests[chestId] = {
		model = chestModel,
		source = "boss",
		rarity = rarity,
	}
	
	chestModel.PrimaryPart.ProximityPrompt.Triggered:Connect(function(player)
		self:HandleChestOpened(player, chestId)
	end)
	
	local chestsFolder = workspace:FindFirstChild("TreasureChests")
	if not chestsFolder then
		chestsFolder = Instance.new("Folder")
		chestsFolder.Name = "TreasureChests"
		chestsFolder.Parent = workspace
	end
	
	chestModel.Parent = chestsFolder
	
	-- Auto-despawn boss chests after 60 seconds if not opened
	task.delay(60, function()
		if self._activeChests[chestId] then
			self._activeChests[chestId].model:Destroy()
			self._activeChests[chestId] = nil
		end
	end)
end

function TreasureChestService:HandleChestOpened(player, chestId)
	local chestData = self._activeChests[chestId]
	if not chestData then return end
	
	-- Prevent double triggers
	self._activeChests[chestId] = nil
	local chestPosition = Vector3.new()
	if chestData.model then
		chestPosition = chestData.model.PrimaryPart and chestData.model.PrimaryPart.Position or chestData.model:GetPivot().Position
		chestData.model:Destroy()
	end
	
	local rolledItems = TreasureChestConfig.RollChest(chestData.rarity)
	local formattedLoot = {}
	
	-- Process rolled items, assigning a specific material rarity if the item supports it
	for _, itemId in rolledItems do
		local itemConfig = Items[itemId]
		local rarity = "Common"
		
		if itemConfig and itemConfig.supportsRarity then
			-- Roll material rarity, but cap it at the chest's rarity
			rarity = MaterialRarityConfig.Roll()
			if not TreasureChestConfig.IsValidRarity(rarity, chestData.rarity) then
				rarity = chestData.rarity
			end
		end
		
		table.insert(formattedLoot, {
			itemId = itemId,
			rarity = rarity,
			count = 1
		})
	end
	
	if chestData.source == "world" then
		-- World chest: Only opener gets the loot
		self:_giveLootToPlayer(player, formattedLoot)
		self._remotes.ChestOpened:FireClient(player, { chestRarity = chestData.rarity, items = formattedLoot, position = chestPosition })
		
		-- Schedule respawn
		task.delay(chestData.spawnData.respawnTime or 300, function()
			self:SpawnWorldChest(chestData.spawnData)
		end)
		
	elseif chestData.source == "boss" then
		-- Boss chest: Anyone can open, but loot goes to the opener's party
		local recipients = self._partyService:GetPartyMembers(player)
		
		for _, recipient in recipients do
			self:_giveLootToPlayer(recipient, formattedLoot)
			self._remotes.ChestOpened:FireClient(recipient, { chestRarity = chestData.rarity, items = formattedLoot, position = chestPosition })
		end
	end
end

function TreasureChestService:_giveLootToPlayer(player, formattedLoot)
	for _, lootItem in formattedLoot do
		local addData = lootItem.itemId
		local itemConfig = Items[lootItem.itemId]
		
		if itemConfig and itemConfig.supportsRarity then
			addData = { id = lootItem.itemId, rarity = lootItem.rarity }
		end
		
		self._playerData:AddItem(player, addData, lootItem.count)
		self._remotes.Notification:FireClient(player, "Obtained " .. (itemConfig and itemConfig.name or lootItem.itemId) .. " x" .. lootItem.count)
	end
end

function TreasureChestService:Start()
	for _, spawnData in TreasureChestConfig.WORLD_SPAWNS do
		self:SpawnWorldChest(spawnData)
	end
end

return TreasureChestService
