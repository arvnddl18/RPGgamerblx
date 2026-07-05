local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Classes = require(Shared.Config.Classes)
local StatsPanelUI = require(script.Parent.Parent.UI.Stats.StatsPanelUI)

local player = game:GetService("Players").LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local statsPanelUI = StatsPanelUI.new(player:WaitForChild("PlayerGui"))

statsPanelUI:OnSetPvpMode(function(mode)
	remotes.SetPvpMode:FireServer(mode)
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	local hasSelectedClass = payload.hasSelectedClass == true
	statsPanelUI:SetHudVisible(hasSelectedClass)
	statsPanelUI:Update(payload, Classes)
end)
