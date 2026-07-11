local Controller = {}

function Controller:Start()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local EquipmentUI = require(script.Parent.Parent.Parent.UI.Equipment.EquipmentUI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hasSelectedClass = false
local equipmentVisible = false
local equipmentUI = EquipmentUI.new(player:WaitForChild("PlayerGui"))

equipmentUI:OnUnequip(function(slot)
	if remotes:FindFirstChild("UnequipItem") then
		remotes.UnequipItem:FireServer(slot)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not hasSelectedClass then
		return
	end
	if input.KeyCode == Enum.KeyCode.C then
		equipmentVisible = not equipmentVisible
		equipmentUI:SetVisible(equipmentVisible)
	end
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	hasSelectedClass = payload.hasSelectedClass == true
	if not hasSelectedClass then
		equipmentVisible = false
		equipmentUI:SetVisible(false)
	elseif equipmentVisible then
		equipmentUI:SetVisible(true)
	end
	if payload.equipped then
		equipmentUI:Update(payload.equipped, Items)
	end
end)

end

return Controller
