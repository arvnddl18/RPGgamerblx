local Controller = {}

function Controller:Start()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopUI = require(script.Parent.Parent.Parent.UI.Shop.ShopUI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local playerLevel = 1
local shopUI = ShopUI.new(player:WaitForChild("PlayerGui"))

	local MusicController = require(script.Parent.Parent.Effects.MusicController)

	shopUI:OnPurchase(function(itemId, quantity)
		MusicController:Play8DASMR("PurchaseItem")
		remotes.PurchaseItem:FireServer(itemId, quantity)
	end)
	
	remotes.OpenShop.OnClientEvent:Connect(function(items, shopType)
		shopUI:SetPlayerLevel(playerLevel)
		shopUI:SetShopType(shopType)
		shopUI:SetItems(items)
		shopUI:SetVisible(true)
		MusicController:Play8DASMR("Open")
	end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	playerLevel = payload.level or 1
	shopUI:SetPlayerLevel(playerLevel)
	shopUI:SetGold(payload.gold or payload.coins or 0)
end)

end

return Controller
