local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local CraftingRecipes = require(Shared.Config.CraftingRecipes)
local RarityConfig = require(Shared.Config.RarityConfig)
local Items = require(Shared.Config.Items)

local CraftingService = {}
CraftingService._playerData = nil
CraftingService._remotes = nil

function CraftingService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._remotes = Framework:GetRemotesFolder()
	
	if not self._remotes:FindFirstChild("CraftItem") then
		local remote = Instance.new("RemoteFunction")
		remote.Name = "CraftItem"
		remote.Parent = self._remotes
	end
end

function CraftingService:CraftItem(player, recipeId)
	local recipe = CraftingRecipes[recipeId]
	if not recipe then
		return false, "Invalid recipe."
	end

	local data = self._playerData:GetData(player)
	if not data or data.level < (recipe.requiredLevel or 1) then
		return false, "Level too low."
	end

	-- Check materials
	for _, mat in pairs(recipe.materials) do
		if not self._playerData:HasItem(player, mat.itemId, mat.amount) then
			return false, "Missing materials."
		end
	end

	-- Deduct materials
	for _, mat in pairs(recipe.materials) do
		self._playerData:RemoveItem(player, mat.itemId, mat.amount)
	end

	-- Grant result
	local resultId = recipe.resultItem
	local itemConfig = Items[resultId]
	local rarityId = "Common"
	
	-- Support for rare equipment crafting:
	if itemConfig and (itemConfig.type == "weapon" or itemConfig.category == "armor") then
		local roll = math.random()
		if roll > 0.99 then rarityId = "Mythic"
		elseif roll > 0.95 then rarityId = "Legendary"
		elseif roll > 0.85 then rarityId = "Epic"
		elseif roll > 0.60 then rarityId = "Rare"
		elseif roll > 0.30 then rarityId = "Uncommon"
		end
	end

	local craftedItem = RarityConfig.GenerateItem(resultId, rarityId)
	
	if self._playerData:AddItem(player, craftedItem, recipe.resultAmount) then
		return true, "Crafted " .. (itemConfig and itemConfig.name or resultId) .. "!"
	else
		-- Refund materials if inventory is somehow full/bugged
		for _, mat in pairs(recipe.materials) do
			self._playerData:AddItem(player, mat.itemId, mat.amount)
		end
		return false, "Inventory error."
	end
end

function CraftingService:Start()
	self._remotes.CraftItem.OnServerInvoke = function(player, recipeId)
		return self:CraftItem(player, recipeId)
	end
end

return CraftingService
