local PlayerHUDUI = {}
PlayerHUDUI.__index = PlayerHUDUI

local EFFECT_DISPLAY = {
	Stun = { label = "Stun", color = Color3.fromRGB(255, 210, 60) },
	Knockdown = { label = "Knockdown", color = Color3.fromRGB(255, 160, 40) },
	Slow = { label = "Slow", color = Color3.fromRGB(100, 180, 255) },
	Silence = { label = "Silence", color = Color3.fromRGB(160, 120, 220) },
	Poison = { label = "Poison", color = Color3.fromRGB(80, 200, 80) },
	Burn = { label = "Burn", color = Color3.fromRGB(255, 100, 50) },
	Bleed = { label = "Bleed", color = Color3.fromRGB(200, 50, 50) },
	StatBuff = { label = "Buff", color = Color3.fromRGB(120, 200, 255) },
	Blessing = { label = "Blessing", color = Color3.fromRGB(255, 230, 120) },
	DivineShield = { label = "Shield", color = Color3.fromRGB(120, 200, 255) },
}

local function makeBar(parent, name, yOffset, height, fillColor)
	local bg = Instance.new("Frame")
	bg.Name = name .. "Bg"
	bg.Size = UDim2.new(1, 0, 0, height)
	bg.Position = UDim2.new(0, 0, 0, yOffset)
	bg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	bg.BorderSizePixel = 0
	bg.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = bg

	local fill = Instance.new("Frame")
	fill.Name = name .. "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.Parent = bg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	local label = Instance.new("TextLabel")
	label.Name = name .. "Label"
	label.Size = UDim2.new(1, -8, 1, 0)
	label.Position = UDim2.new(0, 4, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = ""
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextStrokeTransparency = 0.6
	label.Parent = bg

	return { bg = bg, fill = fill, label = label }
end

function PlayerHUDUI.new(playerGui)
	local self = setmetatable({}, PlayerHUDUI)
	self._statusEntries = {}
	self._activeEffects = {}
	self._countdownThread = nil

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PlayerHUDUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 5
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local root = Instance.new("Frame")
	root.Name = "PlayerHUD"
	-- Keep this frame at a stable size so status effects never move the bars.
	root.Size = UDim2.new(0, 320, 0, 78)
	root.AnchorPoint = Vector2.new(0, 1)
	root.Position = UDim2.new(0, 16, 1, -16)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.Parent = screenGui
	self._root = root

	local barsFrame = Instance.new("Frame")
	barsFrame.Name = "Bars"
	barsFrame.Size = UDim2.new(0, 240, 0, 84)
	barsFrame.Position = UDim2.new(0, 0, 0, 22)
	barsFrame.BackgroundTransparency = 1
	barsFrame.Parent = root

	-- Level Ribbon (positioned above the HP bar, upper-left)
	local levelRibbon = Instance.new("Frame")
	levelRibbon.Name = "LevelRibbon"
	levelRibbon.Size = UDim2.new(0, 50, 0, 20)
	levelRibbon.Position = UDim2.new(0, 0, 0, 0)
	levelRibbon.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
	levelRibbon.BorderSizePixel = 0
	levelRibbon.Parent = root

	local ribbonCorner = Instance.new("UICorner")
	ribbonCorner.CornerRadius = UDim.new(0, 6)
	ribbonCorner.Parent = levelRibbon

	local ribbonGrad = Instance.new("UIGradient")
	ribbonGrad.Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), Color3.fromRGB(220, 160, 30))
	ribbonGrad.Rotation = 90
	ribbonGrad.Parent = levelRibbon

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(1, 0, 1, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Lv.1"
	levelLabel.TextColor3 = Color3.fromRGB(30, 20, 5)
	levelLabel.Font = Enum.Font.GothamBlack
	levelLabel.TextSize = 12
	levelLabel.Parent = levelRibbon
	self._levelLabel = levelLabel

	self._hpBar = makeBar(barsFrame, "Hp", 0, 22, Color3.fromRGB(210, 50, 50))
	self._manaBar = makeBar(barsFrame, "Mana", 24, 16, Color3.fromRGB(60, 120, 220))
	self._xpBar = makeBar(barsFrame, "Xp", 42, 14, Color3.fromRGB(180, 140, 255))
	self._shieldBar = makeBar(barsFrame, "Shield", 58, 10, Color3.fromRGB(80, 180, 255))
	self._shieldBar.bg.Visible = false

	local goldLabel = Instance.new("TextLabel")
	goldLabel.Name = "GoldLabel"
	goldLabel.Size = UDim2.new(0, 70, 0, 40)
	goldLabel.Position = UDim2.new(0, 250, 0, 0)
	goldLabel.BackgroundTransparency = 1
	goldLabel.Text = "Gold 0"
	goldLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
	goldLabel.Font = Enum.Font.GothamBold
	goldLabel.TextSize = 11
	goldLabel.TextXAlignment = Enum.TextXAlignment.Left
	goldLabel.TextYAlignment = Enum.TextYAlignment.Center
	goldLabel.TextStrokeTransparency = 0.6
	goldLabel.Parent = barsFrame
	self._goldLabel = goldLabel

	local statusFrame = Instance.new("Frame")
	statusFrame.Name = "StatusEffects"
	statusFrame.Size = UDim2.new(1, 0, 0, 32)
	statusFrame.AnchorPoint = Vector2.new(0, 1)
	statusFrame.Position = UDim2.new(0, 0, 0, -4)
	statusFrame.BackgroundTransparency = 1
	statusFrame.ClipsDescendants = false
	statusFrame.Parent = root
	self._statusFrame = statusFrame

	local statusLayout = Instance.new("UIListLayout")
	statusLayout.FillDirection = Enum.FillDirection.Horizontal
	statusLayout.Padding = UDim.new(0, 4)
	statusLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statusLayout.Parent = statusFrame

	local actionBar = Instance.new("Frame")
	actionBar.Name = "HUDActionBar"
	actionBar.Size = UDim2.new(0, 350, 0, 46)
	actionBar.AnchorPoint = Vector2.new(1, 1)
	actionBar.Position = UDim2.new(1, -16, 1, -16)
	actionBar.BackgroundTransparency = 1
	actionBar.Visible = false
	actionBar.Parent = screenGui
	self._actionBar = actionBar

	local actionLayout = Instance.new("UIListLayout")
	actionLayout.FillDirection = Enum.FillDirection.Horizontal
	actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	actionLayout.Padding = UDim.new(0, 5)
	actionLayout.Parent = actionBar

	for _, action in {
		{ id = "Inventory", label = "Inventory", key = "I" },
		{ id = "Party", label = "Party", key = "P" },
		{ id = "QuestLog", label = "Quest Log", key = "J" },
		{ id = "Rest", label = "Rest", key = "M" },
		{ id = "Stats", label = "Stats", key = "K" },
	} do
		local button = Instance.new("TextButton")
		button.Name = action.id .. "Button"
		button.Size = UDim2.new(0, 66, 0, 46)
		button.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		button.BackgroundTransparency = 0.12
		button.BorderSizePixel = 0
		button.AutoButtonColor = true
		button.Text = action.label .. "\n[" .. action.key .. "]"
		button.TextColor3 = Color3.fromRGB(225, 225, 235)
		button.Font = Enum.Font.GothamBold
		button.TextSize = 10
		button.Parent = actionBar

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(0, 6)
		buttonCorner.Parent = button

		button.Activated:Connect(function()
			if self._onAction then
				self._onAction(action.id)
			end
		end)
	end

	return self
end

function PlayerHUDUI:SetVisible(visible)
	self._root.Visible = visible
	self._actionBar.Visible = visible
end

function PlayerHUDUI:OnAction(callback)
	self._onAction = callback
end

function PlayerHUDUI:UpdateBar(bar, current, max, prefix)
	local ratio = max > 0 and math.clamp(current / max, 0, 1) or 0
	bar.fill.Size = UDim2.new(ratio, 0, 1, 0)
	bar.label.Text = string.format("%s %d / %d", prefix, math.floor(current), math.floor(max))
end

function PlayerHUDUI:ClearStatusEntries()
	for _, entry in self._statusEntries do
		if entry.frame then
			entry.frame:Destroy()
		end
	end
	table.clear(self._statusEntries)
end

function PlayerHUDUI:CreateStatusBadge(effect)
	local display = EFFECT_DISPLAY[effect.id] or { label = effect.id, color = Color3.fromRGB(180, 180, 200) }

	local badge = Instance.new("Frame")
	badge.Name = "Status_" .. effect.id
	badge.Size = UDim2.new(0, 72, 0, 28)
	badge.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	badge.BackgroundTransparency = 0.15
	badge.BorderSizePixel = 0
	badge.Parent = self._statusFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = badge

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 3, 1, -4)
	accent.Position = UDim2.new(0, 2, 0, 2)
	accent.BackgroundColor3 = display.color
	accent.BorderSizePixel = 0
	accent.Parent = badge

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 2)
	accentCorner.Parent = accent

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 14)
	nameLabel.Position = UDim2.new(0, 8, 0, 2)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = display.label
	nameLabel.TextColor3 = display.color
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 10
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = badge

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(1, -10, 0, 12)
	timeLabel.Position = UDim2.new(0, 8, 0, 14)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.TextSize = 9
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Parent = badge

	local stacks = effect.intensity and effect.intensity > 1 and (" x" .. math.floor(effect.intensity)) or ""
	timeLabel.Text = math.ceil(effect.remaining) .. "s" .. stacks

	table.insert(self._statusEntries, {
		frame = badge,
		timeLabel = timeLabel,
		effect = effect,
		stacksSuffix = stacks,
	})
end

function PlayerHUDUI:UpdateStatusEffects(effects)
	local incoming = effects or {}

	-- Build lookup of incoming effects by id
	local incomingById = {}
	for _, effect in incoming do
		incomingById[effect.id] = effect
	end

	-- Build lookup of existing entries by effect id
	local existingById = {}
	for i, entry in self._statusEntries do
		existingById[entry.effect.id] = i
	end

	-- Remove entries that are no longer present (iterate backwards to safely remove)
	for i = #self._statusEntries, 1, -1 do
		local entry = self._statusEntries[i]
		if not incomingById[entry.effect.id] then
			if entry.frame then
				entry.frame:Destroy()
			end
			table.remove(self._statusEntries, i)
		end
	end

	-- Update existing entries and add new ones
	for _, effect in incoming do
		local existingIdx = nil
		for i, entry in self._statusEntries do
			if entry.effect.id == effect.id then
				existingIdx = i
				break
			end
		end

		if existingIdx then
			-- Update the existing badge's timer and data
			local entry = self._statusEntries[existingIdx]
			entry.effect.remaining = effect.remaining
			entry.effect.intensity = effect.intensity
			local stacks = effect.intensity and effect.intensity > 1 and (" x" .. math.floor(effect.intensity)) or ""
			entry.stacksSuffix = stacks
			if entry.timeLabel then
				entry.timeLabel.Text = math.ceil(effect.remaining) .. "s" .. stacks
			end
		else
			-- Create a new badge for this effect
			self:CreateStatusBadge(effect)
		end
	end

	self._activeEffects = incoming

end

function PlayerHUDUI:StartStatusCountdown()
	if self._countdownThread then
		return
	end

	self._countdownThread = task.spawn(function()
		while self._screenGui.Parent do
			task.wait(1)
			local anyActive = false
			for i = #self._activeEffects, 1, -1 do
				local effect = self._activeEffects[i]
				effect.remaining = math.max(0, effect.remaining - 1)
				if effect.remaining <= 0 then
					table.remove(self._activeEffects, i)
					local entry = self._statusEntries[i]
					if entry and entry.frame then
						entry.frame:Destroy()
					end
					table.remove(self._statusEntries, i)
				else
					anyActive = true
					local entry = self._statusEntries[i]
					if entry and entry.timeLabel then
						entry.timeLabel.Text = math.ceil(effect.remaining) .. "s" .. (entry.stacksSuffix or "")
					end
				end
			end
		end
	end)
end

function PlayerHUDUI:Update(payload)
	if not payload then
		return
	end

	local hasClass = payload.hasSelectedClass == true
	self:SetVisible(hasClass)
	if not hasClass then
		return
	end

	self:UpdateBar(self._hpBar, payload.hp or 0, payload.maxHp or 1, "HP")
	self:UpdateBar(self._manaBar, payload.mana or 0, payload.maxMana or 1, "MP")
	self:UpdateBar(self._xpBar, payload.xp or 0, payload.requiredXp or 1, "XP")
	self._goldLabel.Text = "Gold " .. tostring(math.max(0, math.floor(payload.gold or payload.coins or 0)))

	if payload.level then
		self._levelLabel.Text = "Lv." .. tostring(payload.level)
	end

	local shield = payload.shield or 0
	if shield > 0 then
		self._shieldBar.bg.Visible = true
		local maxHp = payload.maxHp or 1
		self:UpdateBar(self._shieldBar, shield, maxHp, "Shield")
	else
		self._shieldBar.bg.Visible = false
	end

	local effects = {}
	if payload.statusEffects then
		for _, effect in payload.statusEffects do
			table.insert(effects, {
				id = effect.id,
				remaining = effect.remaining,
				intensity = effect.intensity,
			})
		end
	end
	self:UpdateStatusEffects(effects)
	self:StartStatusCountdown()
end

return PlayerHUDUI
