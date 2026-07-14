local Controller = {}

function Controller:Start()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopUI = require(script.Parent.Parent.Parent.UI.Shop.ShopUI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local playerLevel = 1
local shopUI = ShopUI.new(player:WaitForChild("PlayerGui"))

shopUI:OnPurchase(function(itemId, quantity)
	remotes.PurchaseItem:FireServer(itemId, quantity)
end)

remotes.OpenShop.OnClientEvent:Connect(function(items, shopType)
	shopUI:SetPlayerLevel(playerLevel)
	shopUI:SetShopType(shopType)
	shopUI:SetItems(items)
	shopUI:SetVisible(true)
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	playerLevel = payload.level or 1
	shopUI:SetPlayerLevel(playerLevel)
end)

end

return Controller
