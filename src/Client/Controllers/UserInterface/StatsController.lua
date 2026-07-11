local Controller = {}

function Controller:Start()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Classes = require(Shared.Config.Classes)
local StatsPanelUI = require(script.Parent.Parent.Parent.UI.Stats.StatsPanelUI)

local player = game:GetService("Players").LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local statsPanelUI = StatsPanelUI.new(player:WaitForChild("PlayerGui"))

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.K then
		statsPanelUI:TogglePanel()
	end
end)

statsPanelUI:OnSetPvpMode(function(mode)
	remotes.SetPvpMode:FireServer(mode)
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	local hasSelectedClass = payload.hasSelectedClass == true
	statsPanelUI:SetHudVisible(hasSelectedClass)
	statsPanelUI:Update(payload, Classes)
end)

end

return Controller
