local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CraftingUI = require(script.Parent.Parent.UI.Crafting.CraftingUI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local classId = nil
local inventory = {}
local equipped = {}
local craftingUI = CraftingUI.new(player:WaitForChild("PlayerGui"))

craftingUI:OnCraft(function(recipeId)
	local ok, result = remotes.CraftItem:InvokeServer(recipeId)
	craftingUI:SetBusy(false)
	if ok and result then
		remotes.RequestInventory:FireServer()
	end
end)

craftingUI:OnUpgrade(function(recipeId, targetUid)
	local ok, result = remotes.UpgradeEquipment:InvokeServer(recipeId, targetUid)
	craftingUI:SetBusy(false)
	if ok and result then
		remotes.RequestInventory:FireServer()
	end
end)

remotes.OpenCrafting.OnClientEvent:Connect(function(recipes)
	craftingUI:SetRecipes(recipes)
	craftingUI:SetClassId(classId)
	craftingUI:SetInventory(inventory)
	craftingUI:SetEquipped(equipped)
	craftingUI:SetVisible(true)
end)

remotes.InventoryUpdated.OnClientEvent:Connect(function(newInventory)
	inventory = newInventory or {}
	craftingUI:SetInventory(inventory)
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	classId = payload.classId
	equipped = payload.equipped or {}
	craftingUI:SetClassId(classId)
	craftingUI:SetEquipped(equipped)
end)

remotes.CraftResult.OnClientEvent:Connect(function(payload)
	craftingUI:SetBusy(false)
	if payload.outcome == "success" and payload.resultItem then
		craftingUI:SetVisible(false)
	end
	remotes.RequestInventory:FireServer()
end)
