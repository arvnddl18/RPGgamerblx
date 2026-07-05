local DashCooldownUI = {}
DashCooldownUI.__index = DashCooldownUI

function DashCooldownUI.new(playerGui)
	local self = setmetatable({}, DashCooldownUI)
	self._cooldownEnd = 0

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DashUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "DashCooldown"
	container.Size = UDim2.new(0, 46, 0, 46)
	container.Position = UDim2.new(0.5, 220, 1, -70)
	container.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	container.BorderSizePixel = 0
	container.Visible = false
	container.Parent = screenGui
	self._container = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = container

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 1, -14)
	icon.BackgroundTransparency = 1
	icon.Text = "DASH"
	icon.TextColor3 = Color3.fromRGB(255, 220, 80)
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 11
	icon.Parent = container

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 14)
	label.Position = UDim2.new(0, 0, 1, -14)
	label.BackgroundTransparency = 1
	label.Text = "SHIFT"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 8
	label.Parent = container

	local radial = Instance.new("Frame")
	radial.Name = "RadialFill"
	radial.Size = UDim2.new(1, 0, 1, 0)
	radial.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	radial.BackgroundTransparency = 0.4
	radial.BorderSizePixel = 0
	radial.Visible = false
	radial.ZIndex = 2
	radial.Parent = container

	local radialCorner = Instance.new("UICorner")
	radialCorner.CornerRadius = UDim.new(0, 6)
	radialCorner.Parent = radial

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Size = UDim2.new(1, 0, 1, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = ""
	timerLabel.TextColor3 = Color3.new(1, 1, 1)
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.TextSize = 16
	timerLabel.ZIndex = 3
	timerLabel.Parent = radial
	self._timerLabel = timerLabel
	self._radial = radial

	return self
end

function DashCooldownUI:SetVisible(visible)
	self._container.Visible = visible
end

function DashCooldownUI:StartCooldown(duration)
	self._cooldownEnd = tick() + duration
	self._radial.Visible = true

	task.spawn(function()
		while tick() < self._cooldownEnd do
			local remaining = self._cooldownEnd - tick()
			self._timerLabel.Text = tostring(math.ceil(remaining))
			task.wait(0.1)
		end
		self._radial.Visible = false
		self._timerLabel.Text = ""
		self._cooldownEnd = 0
	end)
end

function DashCooldownUI:IsReady()
	return tick() >= self._cooldownEnd
end

return DashCooldownUI
