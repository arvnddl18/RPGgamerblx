local TweenService = game:GetService("TweenService")

local FastTravelConfirmationUI = {}
FastTravelConfirmationUI.__index = FastTravelConfirmationUI

local PANEL_COLOR = Color3.fromRGB(30, 30, 40)

function FastTravelConfirmationUI.new(playerGui)
	local self = setmetatable({}, FastTravelConfirmationUI)
	self._onConfirm = nil
	self._onCancel = nil
	self._destinationName = ""

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FastTravelConfirmationUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 60
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Visible = false
	backdrop.Parent = screenGui
	self._backdrop = backdrop

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 360, 0, 160)
	panel.Position = UDim2.new(0.5, -180, 0.5, -80)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui
	self._panel = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 36)
	title.Position = UDim2.new(0, 10, 0, 12)
	title.BackgroundTransparency = 1
	title.Text = "Confirm Travel"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	self._message = Instance.new("TextLabel")
	self._message.Size = UDim2.new(1, -20, 0, 48)
	self._message.Position = UDim2.new(0, 10, 0, 48)
	self._message.BackgroundTransparency = 1
	self._message.Text = "Travel to this location?"
	self._message.TextColor3 = Color3.fromRGB(200, 200, 210)
	self._message.Font = Enum.Font.Gotham
	self._message.TextSize = 14
	self._message.TextWrapped = true
	self._message.TextXAlignment = Enum.TextXAlignment.Left
	self._message.TextYAlignment = Enum.TextYAlignment.Top
	self._message.Parent = panel

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Size = UDim2.new(0, 120, 0, 36)
	confirmBtn.Position = UDim2.new(1, -250, 1, -52)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 80)
	confirmBtn.Text = "Travel"
	confirmBtn.TextColor3 = Color3.new(1, 1, 1)
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.TextSize = 14
	confirmBtn.Parent = panel
	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 6)
	confirmCorner.Parent = confirmBtn

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0, 120, 0, 36)
	cancelBtn.Position = UDim2.new(1, -130, 1, -52)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
	cancelBtn.Text = "Cancel"
	cancelBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 14
	cancelBtn.Parent = panel
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 6)
	cancelCorner.Parent = cancelBtn

	confirmBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
		if self._onConfirm then
			self._onConfirm()
		end
	end)

	cancelBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
		if self._onCancel then
			self._onCancel()
		end
	end)

	backdrop.MouseButton1Click:Connect(function()
		self:SetVisible(false)
		if self._onCancel then
			self._onCancel()
		end
	end)

	return self
end

function FastTravelConfirmationUI:OnConfirm(callback)
	self._onConfirm = callback
end

function FastTravelConfirmationUI:OnCancel(callback)
	self._onCancel = callback
end

function FastTravelConfirmationUI:SetDestination(name)
	self._destinationName = name or "this location"
	self._message.Text = "Travel to " .. self._destinationName .. "?"
end

function FastTravelConfirmationUI:SetVisible(visible)
	self._backdrop.Visible = visible
	self._panel.Visible = visible
	if visible then
		self._panel.Size = UDim2.new(0, 340, 0, 150)
		TweenService:Create(self._panel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 360, 0, 160),
		}):Play()
	end
end

return FastTravelConfirmationUI
