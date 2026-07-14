local Controller = {}

function Controller:Start()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerHUDUI = require(script.Parent.Parent.Parent.UI.HUD.PlayerHUDUI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hasSelectedClass = false
local playerGui = player:WaitForChild("PlayerGui")
local playerHUD = PlayerHUDUI.new(playerGui)

local actionEvent = Instance.new("BindableEvent")
actionEvent.Name = "HUDAction"
actionEvent.Parent = playerGui

playerHUD:OnAction(function(actionId)
	actionEvent:Fire(actionId)
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	hasSelectedClass = payload.hasSelectedClass == true
	playerHUD:Update(payload)
end)

end

return Controller
