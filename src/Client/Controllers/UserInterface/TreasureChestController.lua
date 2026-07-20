local TreasureChestController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TreasureChestUI = require(script.Parent.Parent.Parent.UI.TreasureChest.TreasureChestUI)

function TreasureChestController:Init()
	TreasureChestUI:Init()
end

function TreasureChestController:Start()
	local MusicController = require(script.Parent.Parent.Effects.MusicController)
	
	-- Play chest open sound when chest is opened
	local remotesFolder = require(ReplicatedStorage.Shared.Framework):GetRemotesFolder()
	remotesFolder:WaitForChild("ChestOpened").OnClientEvent:Connect(function(chestData)
		MusicController:Play8DASMR("Chest Open")
	end)
	
	TreasureChestUI:Start()
end

return TreasureChestController
