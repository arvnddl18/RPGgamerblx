local StatsPanelUI = {}
StatsPanelUI.__index = StatsPanelUI

local STAT_LINES = {
	{ key = "level", label = "Level", format = function(v) return tostring(v) end },
	{ key = "xp", label = "XP", format = function(v, payload) return v .. " / " .. (payload.requiredXp or 0) end },
	{ key = "hp", label = "HP", format = function(v, payload) return v .. " / " .. (payload.maxHp or 0) end },
	{ key = "mana", label = "Mana", format = function(v, payload) return v .. " / " .. (payload.maxMana or 0) end },
	{ key = "shield", label = "Shield", format = function(v) return tostring(v or 0) end },
	{ key = "physicalAttack", label = "Physical ATK", stat = true },
	{ key = "magicAttack", label = "Magic ATK", stat = true },
	{ key = "defense", label = "Defense", stat = true },
	{ key = "magicalResistance", label = "Magic RES", stat = true },
	{ key = "critChance", label = "Crit Chance", stat = true, percent = true },
	{ key = "evasion", label = "Evasion", stat = true, percent = true },
	{ key = "healPower", label = "Heal Power", stat = true },
	{ key = "movementSpeed", label = "Move Speed", stat = true },
}

local function makeButton(parent, text, size, position, color)
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = position
	btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 70)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.BorderSizePixel = 0
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	return btn
end

function StatsPanelUI.new(playerGui)
	local self = setmetatable({}, StatsPanelUI)
	self._statLabels = {}
	self._pvpMode = "Peaceful"
	self._onSetPvpMode = nil

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StatsPanelUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local iconBtn = Instance.new("TextButton")
	iconBtn.Name = "StatsIcon"
	iconBtn.Size = UDim2.new(0, 36, 0, 36)
	iconBtn.Position = UDim2.new(1, -52, 0, 16)
	iconBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	iconBtn.BackgroundTransparency = 0.15
	iconBtn.Text = "S"
	iconBtn.TextColor3 = Color3.fromRGB(255, 220, 100)
	iconBtn.Font = Enum.Font.GothamBold
	iconBtn.TextSize = 16
	iconBtn.Visible = false
	iconBtn.Parent = screenGui
	self._iconBtn = iconBtn

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 8)
	iconCorner.Parent = iconBtn

	local panel = Instance.new("Frame")
	panel.Name = "StatsPanel"
	panel.Size = UDim2.new(0, 240, 0, 380)
	panel.Position = UDim2.new(1, -256, 0, 60)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui
	self._panel = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Position = UDim2.new(0, 8, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "Character Stats"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local classLabel = Instance.new("TextLabel")
	classLabel.Name = "ClassLabel"
	classLabel.Size = UDim2.new(1, -16, 0, 18)
	classLabel.Position = UDim2.new(0, 8, 0, 34)
	classLabel.BackgroundTransparency = 1
	classLabel.Text = ""
	classLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
	classLabel.Font = Enum.Font.Gotham
	classLabel.TextSize = 12
	classLabel.TextXAlignment = Enum.TextXAlignment.Left
	classLabel.Parent = panel
	self._classLabel = classLabel

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "StatList"
	scroll.Size = UDim2.new(1, -16, 0, 230)
	scroll.Position = UDim2.new(0, 8, 0, 56)
	scroll.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	scroll.BackgroundTransparency = 0.3
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = panel

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 6)
	scrollCorner.Parent = scroll

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	for i, line in STAT_LINES do
		local row = Instance.new("TextLabel")
		row.Name = line.key
		row.Size = UDim2.new(1, -8, 0, 18)
		row.BackgroundTransparency = 1
		row.Text = line.label .. ": --"
		row.TextColor3 = Color3.fromRGB(210, 210, 230)
		row.Font = Enum.Font.Gotham
		row.TextSize = 11
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.LayoutOrder = i
		row.Parent = scroll
		self._statLabels[line.key] = { row = row, config = line }
	end

	local pvpLabel = Instance.new("TextLabel")
	pvpLabel.Size = UDim2.new(1, -16, 0, 18)
	pvpLabel.Position = UDim2.new(0, 8, 1, -74)
	pvpLabel.BackgroundTransparency = 1
	pvpLabel.Text = "PvP Mode"
	pvpLabel.TextColor3 = Color3.fromRGB(255, 200, 120)
	pvpLabel.Font = Enum.Font.GothamBold
	pvpLabel.TextSize = 12
	pvpLabel.TextXAlignment = Enum.TextXAlignment.Left
	pvpLabel.Parent = panel

	self._peacefulBtn = makeButton(panel, "Peaceful", UDim2.new(0.48, -6, 0, 26), UDim2.new(0, 8, 1, -52), Color3.fromRGB(50, 100, 70))
	self._hostileBtn = makeButton(panel, "Hostile", UDim2.new(0.48, -6, 0, 26), UDim2.new(0.52, 0, 1, -52), Color3.fromRGB(120, 50, 50))

	self._peacefulBtn.MouseButton1Click:Connect(function()
		if self._onSetPvpMode then
			self._onSetPvpMode("Peaceful")
		end
	end)

	self._hostileBtn.MouseButton1Click:Connect(function()
		if self._onSetPvpMode then
			self._onSetPvpMode("Hostile")
		end
	end)

	iconBtn.MouseButton1Click:Connect(function()
		self:TogglePanel()
	end)

	return self
end

function StatsPanelUI:OnSetPvpMode(callback)
	self._onSetPvpMode = callback
end

function StatsPanelUI:SetHudVisible(visible)
	self._iconBtn.Visible = visible
	if not visible then
		self._panel.Visible = false
	end
end

function StatsPanelUI:TogglePanel()
	self._panel.Visible = not self._panel.Visible
end

function StatsPanelUI:SetVisible(visible)
	self._panel.Visible = visible
end

function StatsPanelUI:UpdatePvpButtons(mode)
	self._pvpMode = mode or "Peaceful"
	self._peacefulBtn.BackgroundColor3 = self._pvpMode == "Peaceful"
		and Color3.fromRGB(50, 100, 70) or Color3.fromRGB(50, 50, 70)
	self._hostileBtn.BackgroundColor3 = self._pvpMode == "Hostile"
		and Color3.fromRGB(120, 50, 50) or Color3.fromRGB(50, 50, 70)
end

function StatsPanelUI:Update(payload, classesConfig)
	if not payload then
		return
	end

	local className = payload.classId
	if classesConfig and classesConfig[payload.classId] then
		className = classesConfig[payload.classId].displayName
	end
	self._classLabel.Text = className or "Unknown Class"

	for key, entry in self._statLabels do
		local line = entry.config
		local value
		if line.stat then
			value = payload.combatStats and payload.combatStats[key]
		else
			value = payload[key]
		end

		if value ~= nil then
			local text
			if line.format then
				text = line.format(value, payload)
			elseif line.percent then
				text = string.format("%.0f%%", value * 100)
			else
				text = tostring(math.floor(value * 10) / 10)
			end
			entry.row.Text = line.label .. ": " .. text
		end
	end

	self:UpdatePvpButtons(payload.pvpMode)
end

return StatsPanelUI
