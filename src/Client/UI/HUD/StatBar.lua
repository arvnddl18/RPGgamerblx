local StatBar = {}
StatBar.__index = StatBar

function StatBar.new(parent, config)
	local self = setmetatable({}, StatBar)
	self._config = config

	local bg = Instance.new("Frame")
	bg.Name = config.name .. "Bg"
	bg.Size = config.size or UDim2.new(1, -16, 0, 18)
	bg.Position = config.position or UDim2.new(0, 8, 0, 34)
	bg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	bg.BorderSizePixel = 0
	bg.Visible = config.visible ~= false
	bg.Parent = parent
	self._bg = bg

	local fill = Instance.new("Frame")
	fill.Name = config.name .. "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = config.fillColor or Color3.fromRGB(220, 60, 60)
	fill.BorderSizePixel = 0
	fill.Parent = bg
	self._fill = fill

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = config.defaultText or ""
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = config.textSize or 12
	label.Parent = bg
	self._label = label

	return self
end

function StatBar:SetVisible(visible)
	self._bg.Visible = visible
end

function StatBar:Update(current, max, textOverride)
	local ratio = max > 0 and math.clamp(current / max, 0, 1) or 0
	self._fill.Size = UDim2.new(ratio, 0, 1, 0)
	self._label.Text = textOverride or (math.floor(current) .. " / " .. math.floor(max))
end

return StatBar
