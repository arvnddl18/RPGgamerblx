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
	root.Size = UDim2.new(0, 240, 0, 54)
	root.Position = UDim2.new(0, 16, 1, -165)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.Parent = screenGui
	self._root = root

	local barsFrame = Instance.new("Frame")
	barsFrame.Name = "Bars"
	barsFrame.Size = UDim2.new(1, 0, 0, 50)
	barsFrame.BackgroundTransparency = 1
	barsFrame.Parent = root

	self._hpBar = makeBar(barsFrame, "Hp", 0, 22, Color3.fromRGB(210, 50, 50))
	self._manaBar = makeBar(barsFrame, "Mana", 24, 16, Color3.fromRGB(60, 120, 220))
	self._shieldBar = makeBar(barsFrame, "Shield", 42, 10, Color3.fromRGB(80, 180, 255))
	self._shieldBar.bg.Visible = false

	local statusFrame = Instance.new("Frame")
	statusFrame.Name = "StatusEffects"
	statusFrame.Size = UDim2.new(1, 0, 0, 32)
	statusFrame.Position = UDim2.new(0, 0, 0, 54)
	statusFrame.BackgroundTransparency = 1
	statusFrame.ClipsDescendants = false
	statusFrame.Parent = root
	self._statusFrame = statusFrame

	local statusLayout = Instance.new("UIListLayout")
	statusLayout.FillDirection = Enum.FillDirection.Horizontal
	statusLayout.Padding = UDim.new(0, 4)
	statusLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statusLayout.Parent = statusFrame

	return self
end

function PlayerHUDUI:SetVisible(visible)
	self._root.Visible = visible
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

	local hasEffects = #self._activeEffects > 0
	local hasShield = self._shieldBar.bg.Visible
	local barHeight = hasShield and 54 or 42
	self._root.Size = UDim2.new(0, 240, 0, barHeight + (hasEffects and 34 or 0))
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
			if not anyActive and #self._activeEffects == 0 then
				local hasShield = self._shieldBar.bg.Visible
				local barHeight = hasShield and 54 or 42
				self._root.Size = UDim2.new(0, 240, 0, barHeight)
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
