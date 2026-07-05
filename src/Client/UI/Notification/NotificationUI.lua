local NotificationUI = {}
NotificationUI.__index = NotificationUI

local MAX_TOASTS = 4
local TOAST_DURATION = 4
local TOAST_HEIGHT = 36
local TOAST_PADDING = 6

function NotificationUI.new(playerGui)
	local self = setmetatable({}, NotificationUI)
	self._toasts = {}

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NotificationUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 50
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local container = Instance.new("Frame")
	container.Name = "ToastContainer"
	container.Size = UDim2.new(0, 360, 1, 0)
	container.Position = UDim2.new(0.5, -180, 0, 80)
	container.BackgroundTransparency = 1
	container.Parent = screenGui
	self._container = container

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, TOAST_PADDING)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	return self
end

function NotificationUI:Show(message)
	while #self._toasts >= MAX_TOASTS do
		local oldest = table.remove(self._toasts, 1)
		if oldest and oldest.frame then
			oldest.frame:Destroy()
		end
	end

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, TOAST_HEIGHT)
	toast.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	toast.BackgroundTransparency = 0.1
	toast.BorderSizePixel = 0
	toast.LayoutOrder = tick()
	toast.Parent = self._container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = Color3.fromRGB(255, 230, 180)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextWrapped = true
	label.Parent = toast

	table.insert(self._toasts, { frame = toast })

	task.delay(TOAST_DURATION, function()
		for i, entry in ipairs(self._toasts) do
			if entry.frame == toast then
				table.remove(self._toasts, i)
				break
			end
		end
		if toast.Parent then
			toast:Destroy()
		end
	end)
end

return NotificationUI
