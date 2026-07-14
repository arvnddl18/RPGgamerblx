local TweenService = game:GetService("TweenService")

local StatsPanelUI = {}
StatsPanelUI.__index = StatsPanelUI

local STAT_LINES = {
	-- Every supported combat stat, grouped in display order to keep offense, defense, and utility easy to scan.
	{ key = "physicalAttack", label = "Physical ATK" }, { key = "magicAttack", label = "Magic ATK" },
	{ key = "critChance", label = "Crit Chance", percent = true }, { key = "critDamage", label = "Crit Damage", multiplier = true },
	{ key = "accuracy", label = "Accuracy", percent = true }, { key = "defense", label = "Physical Defense" },
	{ key = "magicalResistance", label = "Magic RES" }, { key = "critReduction", label = "Crit Reduction", percent = true },
	{ key = "evasion", label = "Evasion", percent = true }, { key = "healPower", label = "Heal Power", multiplier = true },
	{ key = "buffEffectMultiplier", label = "Buff Effect", multiplier = true }, { key = "buffDurationMultiplier", label = "Buff Duration", multiplier = true },
	{ key = "movementSpeed", label = "Move Speed" }, { key = "maxHp", label = "Max Health" },
	{ key = "maxMana", label = "Max Mana" }, { key = "hpRegen", label = "HP Regen" },
	{ key = "manaRegen", label = "Mana Regen" }, { key = "shield", label = "Shield", payload = true },
}

local COLORS = {
	overlay = Color3.fromRGB(0, 0, 0), panel = Color3.fromRGB(28, 22, 18), panelInner = Color3.fromRGB(36, 30, 24),
	border = Color3.fromRGB(180, 140, 55), borderDim = Color3.fromRGB(80, 65, 35), text = Color3.fromRGB(245, 235, 215),
	textDim = Color3.fromRGB(180, 170, 150), slot = Color3.fromRGB(35, 28, 23), slotHover = Color3.fromRGB(50, 42, 34),
	slotSelected = Color3.fromRGB(60, 50, 40), gold = Color3.fromRGB(255, 215, 65), danger = Color3.fromRGB(180, 70, 60),
	success = Color3.fromRGB(85, 160, 100), blue = Color3.fromRGB(100, 150, 200), mana = Color3.fromRGB(70, 120, 210),
}
local FONTS = { Header = Enum.Font.FredokaOne, Body = Enum.Font.Ubuntu, Bold = Enum.Font.GothamBold }

local function corner(parent, radius) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, radius or 8); c.Parent = parent end
local function stroke(parent, color, thickness) local s = Instance.new("UIStroke"); s.Color = color or COLORS.borderDim; s.Thickness = thickness or 1.5; s.Parent = parent; return s end
local function pane(parent, name, size, position)
	local f = Instance.new("Frame"); f.Name = name; f.Size = size; f.Position = position; f.BackgroundColor3 = COLORS.panelInner; f.BorderSizePixel = 0; f.Parent = parent; corner(f, 10); stroke(f, COLORS.borderDim, 2); return f
end
local function button(parent, text, color)
	local b = Instance.new("TextButton"); b.BackgroundColor3 = color or COLORS.slot; b.BorderSizePixel = 0; b.Text = text; b.TextColor3 = COLORS.text; b.Font = FONTS.Header; b.TextSize = 15; b.TextTruncate = Enum.TextTruncate.AtEnd; b.AutoButtonColor = false; b.Parent = parent; corner(b, 8); stroke(b, COLORS.borderDim, 2)
	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.16), { BackgroundColor3 = b.BackgroundColor3 == COLORS.danger and Color3.fromRGB(220, 90, 80) or COLORS.slotHover }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.16), { BackgroundColor3 = color or COLORS.slot }):Play() end)
	return b
end

function StatsPanelUI.new(playerGui)
	local self = setmetatable({}, StatsPanelUI)
	self._statLabels = {}; self._flagSecondsRemaining = 0; self._pvpMode = "Peaceful"
	local gui = Instance.new("ScreenGui"); gui.Name = "StatsPanelUI"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.DisplayOrder = 100; gui.Parent = playerGui; self._screenGui = gui
	local overlay = Instance.new("TextButton"); overlay.Size = UDim2.fromScale(1, 1); overlay.BackgroundColor3 = COLORS.overlay; overlay.BackgroundTransparency = 0.5; overlay.Text = ""; overlay.AutoButtonColor = false; overlay.Visible = false; overlay.Parent = gui; self._overlay = overlay
	local root = Instance.new("Frame"); root.Name = "StatsPanel"; root.AnchorPoint = Vector2.new(0.5, 0.5); root.Position = UDim2.fromScale(0.5, 0.5); root.Size = UDim2.fromScale(0.72, 0.76); root.BackgroundColor3 = COLORS.panel; root.BorderSizePixel = 0; root.Active = true; root.Visible = false; root.Parent = gui; corner(root, 12); stroke(root, COLORS.border, 3); self._panel = root
	local constraint = Instance.new("UISizeConstraint"); constraint.MinSize = Vector2.new(520, 450); constraint.MaxSize = Vector2.new(1120, 780); constraint.Parent = root
	local close = button(root, "×", COLORS.danger); close.Size = UDim2.fromOffset(40, 40); close.Position = UDim2.new(1, -50, 0, 10); close.TextSize = 22; close.ZIndex = 5; close.MouseButton1Click:Connect(function() self:SetVisible(false) end); overlay.MouseButton1Click:Connect(function() self:SetVisible(false) end)

	local overview = pane(root, "OverviewPane", UDim2.new(0.36, -16, 1, -24), UDim2.new(0, 12, 0, 12))
	local heading = Instance.new("TextLabel"); heading.Size = UDim2.new(1, -24, 0, 40); heading.Position = UDim2.new(0, 12, 0, 12); heading.BackgroundTransparency = 1; heading.Text = "CHARACTER"; heading.TextColor3 = COLORS.gold; heading.Font = FONTS.Header; heading.TextSize = 22; heading.TextXAlignment = Enum.TextXAlignment.Left; heading.Parent = overview
	local class = Instance.new("TextLabel"); class.Size = UDim2.new(1, -24, 0, 28); class.Position = UDim2.new(0, 12, 0, 54); class.BackgroundTransparency = 1; class.Text = "Unknown Class"; class.TextColor3 = COLORS.blue; class.Font = FONTS.Header; class.TextSize = 18; class.TextXAlignment = Enum.TextXAlignment.Left; class.TextTruncate = Enum.TextTruncate.AtEnd; class.Parent = overview; self._classLabel = class
	local level = Instance.new("TextLabel"); level.Size = UDim2.new(1, -24, 0, 28); level.Position = UDim2.new(0, 12, 0, 87); level.BackgroundTransparency = 1; level.Text = "Level 0"; level.TextColor3 = COLORS.text; level.Font = FONTS.Bold; level.TextSize = 16; level.TextXAlignment = Enum.TextXAlignment.Left; level.Parent = overview; self._levelLabel = level
	local resources = Instance.new("Frame"); resources.Size = UDim2.new(1, -24, 0, 190); resources.Position = UDim2.new(0, 12, 0, 129); resources.BackgroundColor3 = COLORS.slot; resources.BorderSizePixel = 0; resources.Parent = overview; corner(resources, 8); stroke(resources, COLORS.borderDim, 1.5)
	local resourceTitle = Instance.new("TextLabel"); resourceTitle.Size = UDim2.new(1, -20, 0, 28); resourceTitle.Position = UDim2.new(0, 10, 0, 8); resourceTitle.BackgroundTransparency = 1; resourceTitle.Text = "RESOURCES"; resourceTitle.TextColor3 = COLORS.text; resourceTitle.Font = FONTS.Header; resourceTitle.TextSize = 16; resourceTitle.TextXAlignment = Enum.TextXAlignment.Left; resourceTitle.Parent = resources
	local function resourceLine(name, color, y)
		local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -20, 0, 18); label.Position = UDim2.new(0, 10, 0, y); label.BackgroundTransparency = 1; label.TextColor3 = COLORS.text; label.Font = FONTS.Body; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = resources
		local back = Instance.new("Frame"); back.Size = UDim2.new(1, -20, 0, 12); back.Position = UDim2.new(0, 10, 0, y + 19); back.BackgroundColor3 = Color3.fromRGB(20, 16, 14); back.BorderSizePixel = 0; back.Parent = resources; corner(back, 4)
		local fill = Instance.new("Frame"); fill.Size = UDim2.new(); fill.BackgroundColor3 = color; fill.BorderSizePixel = 0; fill.Parent = back; corner(fill, 4)
		return { label = label, fill = fill, name = name }
	end
	self._hp = resourceLine("HP", COLORS.danger, 40); self._mana = resourceLine("MANA", COLORS.mana, 76); self._xp = resourceLine("XP", COLORS.gold, 112); self._masteryXp = resourceLine("MASTERY XP", COLORS.blue, 148)
	local karma = Instance.new("TextLabel"); karma.Size = UDim2.new(1, -24, 0, 20); karma.Position = UDim2.new(0, 12, 0, 334); karma.BackgroundTransparency = 1; karma.TextColor3 = COLORS.textDim; karma.Font = FONTS.Body; karma.TextSize = 14; karma.TextXAlignment = Enum.TextXAlignment.Left; karma.TextTruncate = Enum.TextTruncate.AtEnd; karma.Parent = overview; self._karmaLabel = karma
	local pk = karma:Clone(); pk.Position = UDim2.new(0, 12, 0, 358); pk.Text = "PK Count: 0"; pk.Parent = overview; self._pkLabel = pk
	local flag = karma:Clone(); flag.Position = UDim2.new(0, 12, 0, 382); flag.TextColor3 = Color3.fromRGB(225, 125, 225); flag.Font = FONTS.Bold; flag.Visible = false; flag.Parent = overview; self._flagLabel = flag

	local detail = pane(root, "StatsPane", UDim2.new(0.64, -20, 1, -24), UDim2.new(0.36, 4, 0, 12))
	local detailTitle = Instance.new("TextLabel"); detailTitle.Size = UDim2.new(1, -82, 0, 40); detailTitle.Position = UDim2.new(0, 16, 0, 12); detailTitle.BackgroundTransparency = 1; detailTitle.Text = "COMBAT STATS"; detailTitle.TextColor3 = COLORS.gold; detailTitle.Font = FONTS.Header; detailTitle.TextSize = 22; detailTitle.TextXAlignment = Enum.TextXAlignment.Left; detailTitle.Parent = detail
	local scroll = Instance.new("ScrollingFrame"); scroll.Name = "StatList"; scroll.Size = UDim2.new(1, -32, 1, -146); scroll.Position = UDim2.new(0, 16, 0, 58); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 8; scroll.ScrollBarImageColor3 = COLORS.gold; scroll.CanvasSize = UDim2.new(); scroll.Parent = detail
	local layout = Instance.new("UIGridLayout"); layout.CellSize = UDim2.new(0.5, -5, 0, 38); layout.CellPadding = UDim2.new(0, 8, 0, 8); layout.FillDirectionMaxCells = 2; layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = scroll; layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8) end)
	for _, line in STAT_LINES do
		local row = Instance.new("Frame"); row.Size = UDim2.new(); row.BackgroundColor3 = COLORS.slot; row.BorderSizePixel = 0; row.Parent = scroll; corner(row, 7); stroke(row, COLORS.borderDim, 1.5)
		local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.64, -8, 1, 0); label.Position = UDim2.new(0, 8, 0, 0); label.BackgroundTransparency = 1; label.Text = line.label; label.TextColor3 = COLORS.textDim; label.Font = FONTS.Body; label.TextSize = 13; label.TextXAlignment = Enum.TextXAlignment.Left; label.TextTruncate = Enum.TextTruncate.AtEnd; label.Parent = row
		local value = Instance.new("TextLabel"); value.Size = UDim2.new(0.36, -8, 1, 0); value.Position = UDim2.new(0.64, 0, 0, 0); value.BackgroundTransparency = 1; value.Text = "--"; value.TextColor3 = COLORS.text; value.Font = FONTS.Bold; value.TextSize = 14; value.TextXAlignment = Enum.TextXAlignment.Right; value.TextTruncate = Enum.TextTruncate.AtEnd; value.Parent = row
		self._statLabels[line.key] = { value = value, config = line }
	end
	local pvpTitle = Instance.new("TextLabel"); pvpTitle.Size = UDim2.new(1, -32, 0, 20); pvpTitle.Position = UDim2.new(0, 16, 1, -78); pvpTitle.BackgroundTransparency = 1; pvpTitle.Text = "PVP MODE"; pvpTitle.TextColor3 = COLORS.text; pvpTitle.Font = FONTS.Header; pvpTitle.TextSize = 16; pvpTitle.TextXAlignment = Enum.TextXAlignment.Left; pvpTitle.Parent = detail
	self._peacefulBtn = button(detail, "PEACEFUL", COLORS.success); self._peacefulBtn.Size = UDim2.new(0.48, 0, 0, 38); self._peacefulBtn.Position = UDim2.new(0, 16, 1, -52)
	self._hostileBtn = button(detail, "HOSTILE", COLORS.danger); self._hostileBtn.Size = UDim2.new(0.48, 0, 0, 38); self._hostileBtn.Position = UDim2.new(0.52, -16, 1, -52)
	self._peacefulBtn.MouseButton1Click:Connect(function() if self._onSetPvpMode then self._onSetPvpMode("Peaceful") end end)
	self._hostileBtn.MouseButton1Click:Connect(function() if self._onSetPvpMode then self._onSetPvpMode("Hostile") end end)
	return self
end

function StatsPanelUI:OnSetPvpMode(callback) self._onSetPvpMode = callback end
function StatsPanelUI:SetHudVisible(visible) if not visible then self:SetVisible(false) end end
function StatsPanelUI:TogglePanel() self:SetVisible(not self._panel.Visible) end
function StatsPanelUI:SetVisible(visible)
	if visible then self._overlay.Visible = true; self._panel.Visible = true; self._panel.Size = UDim2.fromScale(0.67, 0.71); TweenService:Create(self._panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.72, 0.76) }):Play()
	else self._overlay.Visible = false; self._panel.Visible = false end
end
function StatsPanelUI:UpdatePvpButtons(mode)
	self._pvpMode = mode or "Peaceful"
	self._peacefulBtn.BackgroundColor3 = self._pvpMode == "Peaceful" and COLORS.success or COLORS.slot
	self._hostileBtn.BackgroundColor3 = self._pvpMode == "Hostile" and COLORS.danger or COLORS.slot
end
local function flagTime(seconds) return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60) end
function StatsPanelUI:UpdateKarmaDisplay(payload)
	local state = payload.karmaState == "Chaotic" and "Outlaw" or "Innocent"
	self._karmaLabel.Text = string.format("Karma: %s (%d pts)", state, payload.karmaPoints or 0)
	self._pkLabel.Text = "PK Count: " .. tostring(payload.pkCount or 0)
	self._flagSecondsRemaining = payload.karmaFlagSecondsRemaining or 0
	self._flagLabel.Visible = self._flagSecondsRemaining > 0
	self._flagLabel.Text = self._flagSecondsRemaining > 0 and "Outlaw timer: " .. flagTime(self._flagSecondsRemaining) or ""
end
function StatsPanelUI:StartFlagCountdown()
	if self._countdownThread then return end
	self._countdownThread = task.spawn(function()
		while self._screenGui.Parent do task.wait(1); if self._flagSecondsRemaining > 0 then self._flagSecondsRemaining -= 1; self._flagLabel.Visible = self._flagSecondsRemaining > 0; self._flagLabel.Text = self._flagSecondsRemaining > 0 and "Outlaw timer: " .. flagTime(self._flagSecondsRemaining) or "" end end
	end)
end
local function updateResource(resource, current, maximum)
	current, maximum = current or 0, math.max(maximum or 0, 1)
	resource.label.Text = resource.name .. "  " .. tostring(current) .. " / " .. tostring(maximum)
	resource.fill.Size = UDim2.new(math.clamp(current / maximum, 0, 1), 0, 1, 0)
end
function StatsPanelUI:Update(payload, classesConfig)
	if not payload then return end
	local class = classesConfig and classesConfig[payload.classId] and classesConfig[payload.classId].displayName or payload.classId or "Unknown Class"
	local masteryRank = payload.classMastery and payload.classMastery.rank or 1
	self._classLabel.Text = string.format("%s — Mastery Rank %d", class, masteryRank)
	self._levelLabel.Text = "Level " .. tostring(payload.level or 0)
	local mastery = payload.classMastery or { rank = 1, xp = 0, requiredXp = 0 }
	updateResource(self._hp, payload.hp, payload.maxHp); updateResource(self._mana, payload.mana, payload.maxMana); updateResource(self._xp, payload.xp, payload.requiredXp); updateResource(self._masteryXp, mastery.xp, mastery.requiredXp)
	for key, entry in self._statLabels do
		local config = entry.config
		local value = config.payload and payload[key] or payload.combatStats and payload.combatStats[key]
		if value ~= nil then
			entry.value.Text = config.percent and string.format("%.0f%%", value * 100)
				or config.multiplier and string.format("%.2fx", value)
				or tostring(math.floor(value * 10) / 10)
		end
	end
	self:UpdatePvpButtons(payload.pvpMode); self:UpdateKarmaDisplay(payload); self:StartFlagCountdown()
end
return StatsPanelUI
