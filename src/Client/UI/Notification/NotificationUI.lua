local NotificationUI = {}
NotificationUI.__index = NotificationUI

local MAX_TOASTS = 2
local TOAST_DURATION = 3
local TOAST_HEIGHT = 38
local TOAST_PADDING = 4

function NotificationUI.new(playerGui)
	local self = setmetatable({}, NotificationUI)
	self._toasts = {}

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NotificationUI"
	screenGui.ResetOnSpawn = false
	-- Modals (inventory, shop, crafting, and enhancement) use orders 100–102.
	-- Keep action feedback above them so it cannot be hidden by an open panel.
	screenGui.DisplayOrder = 1000
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local container = Instance.new("Frame")
	container.Name = "ToastContainer"
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.Size = UDim2.fromOffset(340, 90)
	container.Position = UDim2.new(0.5, 0, 0, 12)
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
	for _, entry in ipairs(self._toasts) do
		if entry.message == message then
			return
		end
	end

	while #self._toasts >= MAX_TOASTS do
		local oldest = table.remove(self._toasts, 1)
		if oldest and oldest.frame then
			oldest.frame:Destroy()
		end
	end

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(1, 0, 0, TOAST_HEIGHT)
	local success = message:find("Purchased", 1, true) or message:find("Crafted", 1, true) or message:find("success", 1, true) or message:find("complete", 1, true)
	toast.BackgroundColor3 = success and Color3.fromRGB(31, 86, 54) or Color3.fromRGB(98, 48, 40)
	toast.BackgroundTransparency = 0.04
	toast.BorderSizePixel = 0
	toast.LayoutOrder = tick()
	toast.Parent = self._container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	local outline = Instance.new("UIStroke")
	outline.Color = success and Color3.fromRGB(110, 220, 135) or Color3.fromRGB(235, 125, 95)
	outline.Thickness = 1.5
	outline.Parent = toast

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -30, 1, 0)
	label.Position = UDim2.new(0, 24, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = Color3.fromRGB(255, 250, 235)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 12
	label.TextWrapped = false
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = toast

	local marker = Instance.new("TextLabel")
	marker.Size = UDim2.fromOffset(18, 18)
	marker.Position = UDim2.new(0, 6, 0.5, -9)
	marker.BackgroundTransparency = 1
	marker.Text = success and "+" or "!"
	marker.TextColor3 = success and Color3.fromRGB(160, 255, 180) or Color3.fromRGB(255, 175, 140)
	marker.Font = Enum.Font.GothamBold
	marker.TextSize = 14
	marker.Parent = toast

	table.insert(self._toasts, { frame = toast, message = message })

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
