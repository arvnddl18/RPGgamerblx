local Controller = {}

function Controller:Start()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local DashCooldownUI = require(script.Parent.Parent.Parent.UI.Dash.DashCooldownUI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hasSelectedClass = false
local dashUI = DashCooldownUI.new(player:WaitForChild("PlayerGui"))

local function getMoveDirection()
	local character = player.Character
	if not character then
		return Vector3.zero
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return Vector3.zero
	end
	return humanoid.MoveDirection
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not hasSelectedClass then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		if not dashUI:IsReady() then
			return
		end
		local direction = getMoveDirection()
		remotes.RequestDash:FireServer(direction)
	end
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	hasSelectedClass = payload.hasSelectedClass == true
	dashUI:SetVisible(hasSelectedClass)
end)

remotes.DashCooldownUpdated.OnClientEvent:Connect(function(duration)
	dashUI:StartCooldown(duration)
end)

end

return Controller
