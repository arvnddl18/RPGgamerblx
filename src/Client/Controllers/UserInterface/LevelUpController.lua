local Controller = {}

function Controller:Start()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function flashLevelUp(level)
	local playerGui = player:WaitForChild("PlayerGui")

	local existing = playerGui:FindFirstChild("LevelUpFlash")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LevelUpFlash"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 50
	screenGui.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 80)
	label.Position = UDim2.new(0, 0, 0.35, 0)
	label.BackgroundTransparency = 1
	label.Text = "LEVEL UP!  Lv." .. tostring(level)
	label.TextColor3 = Color3.fromRGB(255, 220, 80)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 36
	label.TextStrokeTransparency = 0.4
	label.TextTransparency = 1
	label.Parent = screenGui

	local tweenIn = TweenService:Create(label, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
	})
	local tweenOut = TweenService:Create(label, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
	})

	tweenIn:Play()
	tweenIn.Completed:Connect(function()
		task.wait(1)
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			screenGui:Destroy()
		end)
	end)
end

if remotes:FindFirstChild("LevelUp") then
	remotes.LevelUp.OnClientEvent:Connect(function(level)
		flashLevelUp(level)
	end)
end

end

return Controller
