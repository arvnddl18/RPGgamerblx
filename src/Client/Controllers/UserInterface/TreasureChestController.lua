local TreasureChestController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TreasureChestUI = require(script.Parent.Parent.Parent.UI.TreasureChest.TreasureChestUI)

function TreasureChestController:Init()
	TreasureChestUI:Init()
end

function TreasureChestController:Start()
	TreasureChestUI:Start()
end

return TreasureChestController
