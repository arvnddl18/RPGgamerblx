local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local RarityConfig = require(Shared.Config.RarityConfig)
local EquipmentSlots = require(Shared.Config.EquipmentSlots)
local EnhancementConfig = require(Shared.Config.EnhancementConfig)

local EnhancementUI = {}
EnhancementUI.__index = EnhancementUI

local COLORS = {
	panel = Color3.fromRGB(24, 19, 15), inner = Color3.fromRGB(32, 26, 20), dark = Color3.fromRGB(20, 16, 12),
	border = Color3.fromRGB(150, 115, 45), borderDim = Color3.fromRGB(70, 55, 28), text = Color3.fromRGB(235, 225, 205),
	dim = Color3.fromRGB(150, 140, 120), slot = Color3.fromRGB(30, 24, 19), empty = Color3.fromRGB(22, 18, 14),
	accent = Color3.fromRGB(85, 125, 175), success = Color3.fromRGB(65, 120, 75), danger = Color3.fromRGB(140, 55, 45),
}
local DISPLAY = { physicalAttack = "Physical Attack", magicAttack = "Magic Attack", maxHp = "Max HP", maxMana = "Max Mana", defense = "Defense", magicalResistance = "Magic Resistance", movementSpeed = "Move Speed", critChance = "Crit Chance", critDamage = "Crit Damage", critReduction = "Crit Reduction", accuracy = "Accuracy", evasion = "Evasion", healPower = "Heal Power", buffEffectMultiplier = "Buff Effect", buffDurationMultiplier = "Buff Duration", hpRegen = "HP Regen", manaRegen = "Mana Regen" }
local LEGACY = { PhysicalDamage = "Physical Attack", MagicalDamage = "Magic Attack", PhysicalResistance = "Defense", MagicResistance = "Magic Resistance", MaxHP = "Max HP", MaxMana = "Max Mana", MoveSpeed = "Move Speed", Evasion = "Evasion" }
local PERCENT = { critChance = true, critDamage = true, critReduction = true, accuracy = true, evasion = true, healPower = true, buffEffectMultiplier = true, buffDurationMultiplier = true }
local PERCENT_LABELS = { ["Crit Chance"] = true, ["Crit Damage"] = true, ["Crit Reduction"] = true, Accuracy = true, Evasion = true, ["Heal Power"] = true, ["Buff Effect"] = true, ["Buff Duration"] = true }

local function corner(p, r) local x = Instance.new("UICorner"); x.CornerRadius = UDim.new(0, r or 6); x.Parent = p end
local function stroke(p, c, t) local x = Instance.new("UIStroke"); x.Color = c or COLORS.borderDim; x.Thickness = t or 1; x.Parent = p; return x end
local function label(parent, text, size, pos, font, color)
	local x = Instance.new("TextLabel"); x.Size = size; x.Position = pos; x.BackgroundTransparency = 1; x.Text = text; x.TextColor3 = color or COLORS.text; x.Font = font or Enum.Font.Gotham; x.TextSize = 12; x.TextXAlignment = Enum.TextXAlignment.Left; x.Parent = parent; return x
end
local function button(parent, text, size, pos, color)
	local x = Instance.new("TextButton"); x.Size = size; x.Position = pos; x.BackgroundColor3 = color or COLORS.slot; x.Text = text; x.TextColor3 = COLORS.text; x.Font = Enum.Font.GothamBold; x.TextSize = 12; x.AutoButtonColor = false; x.Parent = parent; corner(x, 5); return x
end
local function itemColor(item, entry) return entry.rarity and item.slot and RarityConfig.GetColor(entry.rarity) or item.color or COLORS.slot end
local function addValue(values, name, value) if value then values[name] = (values[name] or 0) + value end end
local function sortedKeys(values)
	local keys = {}
	for key in pairs(values) do table.insert(keys, key) end
	table.sort(keys)
	return keys
end

local function fitGrid(frame, grid)
	local width = frame.AbsoluteSize.X
	if width <= 0 then return end
	local cell = math.clamp(math.floor((width - 12) / 3), 58, 88)
	grid.CellSize = UDim2.fromOffset(cell, cell)
	grid.CellPadding = UDim2.fromOffset(5, 5)
end

function EnhancementUI.new(playerGui)
	local self = setmetatable({ _inventory = {}, _equipped = {}, _scroll = nil, _target = nil, _visible = false }, EnhancementUI)
	self._screen = Instance.new("ScreenGui"); self._screen.Name = "EnhancementUI"; self._screen.ResetOnSpawn = false; self._screen.DisplayOrder = 102; self._screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; self._screen.Parent = playerGui
	self._overlay = button(self._screen, "", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.new()); self._overlay.BackgroundTransparency = .45; self._overlay.Visible = false
	self._root = Instance.new("Frame"); self._root.AnchorPoint = Vector2.new(.5, .5); self._root.Position = UDim2.fromScale(.5, .5); self._root.Size = UDim2.fromScale(.94, .90); self._root.BackgroundColor3 = COLORS.panel; self._root.Visible = false; self._root.Parent = self._screen; corner(self._root, 10); stroke(self._root, COLORS.border, 2)
	local rootConstraint = Instance.new("UISizeConstraint"); rootConstraint.MinSize = Vector2.new(760, 500); rootConstraint.MaxSize = Vector2.new(1500, 900); rootConstraint.Parent = self._root
	label(self._root, "ENHANCEMENT FORGE", UDim2.new(1, -70, 0, 34), UDim2.fromOffset(16, 7), Enum.Font.GothamBold).TextSize = 19
	self._close = button(self._root, "×", UDim2.fromOffset(36, 32), UDim2.new(1, -44, 0, 8), COLORS.danger); self._close.TextSize = 20
	self._currentGold = label(self._root, "GOLD: 0", UDim2.fromOffset(140, 28), UDim2.new(1, -190, 0, 10), Enum.Font.GothamBold, Color3.fromRGB(255, 210, 80)); self._currentGold.TextSize = 14; self._currentGold.TextXAlignment = Enum.TextXAlignment.Right; self._currentGold.ZIndex = 11

	self._scrollPanel = self:_panel("Scroll Inventory", UDim2.new(.30, -10, 1, -58), UDim2.fromOffset(12, 46))
	self._gearPanel = self:_panel("Equipment Selection", UDim2.new(.34, -10, 1, -58), UDim2.new(.30, 2, 0, 46))
	self._detailPanel = self:_panel("Enhancement Details", UDim2.new(.36, -14, 1, -58), UDim2.new(.64, 0, 0, 46))

	self._scrollList = Instance.new("ScrollingFrame"); self._scrollList.Size = UDim2.new(1, -16, 1, -45); self._scrollList.Position = UDim2.fromOffset(8, 37); self._scrollList.BackgroundTransparency = 1; self._scrollList.BorderSizePixel = 0; self._scrollList.ScrollBarThickness = 5; self._scrollList.Parent = self._scrollPanel
	local listLayout = Instance.new("UIGridLayout"); listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Parent = self._scrollList; fitGrid(self._scrollList, listLayout); self._scrollList:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() fitGrid(self._scrollList, listLayout) end); listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() self._scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4) end)
	local gearHint = label(self._gearPanel, "Choose an equipment or weapon to enhance", UDim2.new(1, -20, 0, 18), UDim2.fromOffset(10, 31), Enum.Font.Gotham, COLORS.dim); gearHint.TextSize = 10
	self._gearGrid = Instance.new("ScrollingFrame"); self._gearGrid.Size = UDim2.new(1, -16, 1, -62); self._gearGrid.Position = UDim2.fromOffset(8, 55); self._gearGrid.BackgroundTransparency = 1; self._gearGrid.BorderSizePixel = 0; self._gearGrid.ScrollBarThickness = 5; self._gearGrid.Parent = self._gearPanel
	local gearLayout = Instance.new("UIGridLayout"); gearLayout.SortOrder = Enum.SortOrder.LayoutOrder; gearLayout.Parent = self._gearGrid; fitGrid(self._gearGrid, gearLayout); self._gearGrid:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() fitGrid(self._gearGrid, gearLayout) end)
	gearLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() self._gearGrid.CanvasSize = UDim2.new(0, 0, 0, gearLayout.AbsoluteContentSize.Y + 5) end)
	self._emptyGear = label(self._gearPanel, "No equipment or weapons available.", UDim2.new(1, -20, 0, 40), UDim2.new(0, 10, .5, -10), Enum.Font.Gotham, COLORS.dim); self._emptyGear.TextWrapped = true; self._emptyGear.TextXAlignment = Enum.TextXAlignment.Center

	self._detailName = label(self._detailPanel, "Choose a scroll and an item", UDim2.new(1, -28, 0, 38), UDim2.fromOffset(14, 38), Enum.Font.GothamBold); self._detailName.TextSize = 16; self._detailName.TextWrapped = true; self._detailName.TextYAlignment = Enum.TextYAlignment.Top
	self._detailLevel = label(self._detailPanel, "", UDim2.new(1, -28, 0, 18), UDim2.fromOffset(14, 80), Enum.Font.Gotham, COLORS.dim); self._detailLevel.TextSize = 11; self._detailLevel.TextWrapped = true
	self._detailBody = Instance.new("ScrollingFrame"); self._detailBody.Name = "DetailsScroll"; self._detailBody.Size = UDim2.new(1, -28, 1, -235); self._detailBody.Position = UDim2.fromOffset(14, 105); self._detailBody.BackgroundTransparency = 1; self._detailBody.BorderSizePixel = 0; self._detailBody.ScrollBarThickness = 5; self._detailBody.CanvasSize = UDim2.new(); self._detailBody.Parent = self._detailPanel
	self._detailStats = label(self._detailBody, "", UDim2.new(0.5, -6, 0, 0), UDim2.fromOffset(0, 0), Enum.Font.Gotham, COLORS.text); self._detailStats.TextYAlignment = Enum.TextYAlignment.Top; self._detailStats.TextWrapped = true; self._detailStats.RichText = true; self._detailStats.AutomaticSize = Enum.AutomaticSize.Y
	self._detailStatsRight = label(self._detailBody, "", UDim2.new(0.5, -6, 0, 0), UDim2.new(0.5, 2, 0, 0), Enum.Font.Gotham, Color3.fromRGB(143, 206, 255)); self._detailStatsRight.TextYAlignment = Enum.TextYAlignment.Top; self._detailStatsRight.TextWrapped = true; self._detailStatsRight.RichText = true; self._detailStatsRight.AutomaticSize = Enum.AutomaticSize.Y
	local function resizeDetailsCanvas()
		self._detailBody.CanvasSize = UDim2.new(0, 0, 0, math.max(self._detailStats.AbsoluteSize.Y, self._detailStatsRight.AbsoluteSize.Y) + 8)
	end
	self._detailStats:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeDetailsCanvas)
	self._detailStatsRight:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeDetailsCanvas)
	self._goldCost = label(self._detailPanel, "Required Gold: --", UDim2.new(1, -28, 0, 18), UDim2.new(0, 14, 1, -151), Enum.Font.GothamBold, Color3.fromRGB(255, 210, 80)); self._goldCost.TextSize = 12
	self._status = label(self._detailPanel, "", UDim2.new(1, -28, 0, 64), UDim2.new(0, 14, 1, -126), Enum.Font.Gotham, COLORS.dim); self._status.TextWrapped = true; self._status.TextYAlignment = Enum.TextYAlignment.Top; self._status.TextSize = 10
	self._apply = button(self._detailPanel, "APPLY ENHANCEMENT", UDim2.new(1, -28, 0, 40), UDim2.new(0, 14, 1, -56), COLORS.success)
	self._close.MouseButton1Click:Connect(function() self:SetVisible(false) end)
	self._overlay.MouseButton1Click:Connect(function()
		local mouse = UserInputService:GetMouseLocation()
		local inset = GuiService:GetGuiInset()
		local point = Vector2.new(mouse.X, mouse.Y - inset.Y)
		local position, size = self._root.AbsolutePosition, self._root.AbsoluteSize
		local insideRoot = point.X >= position.X and point.X <= position.X + size.X and point.Y >= position.Y and point.Y <= position.Y + size.Y
		if not insideRoot then self:SetVisible(false) end
	end)
	self._apply.MouseButton1Click:Connect(function() if self._onApply and self:_canApply() then self._onApply(self._scroll.id, self._target.uid) end end)
	UserInputService.InputBegan:Connect(function(input, processed) if self._visible and not processed and input.KeyCode == Enum.KeyCode.Escape then self:SetVisible(false) end end)
	return self
end

function EnhancementUI:_panel(title, size, pos)
	local p = Instance.new("Frame"); p.Size = size; p.Position = pos; p.BackgroundColor3 = COLORS.inner; p.BorderSizePixel = 0; p.Parent = self._root; corner(p, 8); stroke(p)
	local t = label(p, title:upper(), UDim2.new(1, -16, 0, 26), UDim2.fromOffset(10, 7), Enum.Font.GothamBold); t.TextSize = 15
	return p
end

function EnhancementUI:_renderScrolls()
	for _, child in self._scrollList:GetChildren() do if child:IsA("GuiButton") then child:Destroy() end end
	local found = 0
	for _, entry in ipairs(self._inventory) do
		local item = Items[entry.id]
		if item and item.category == "scrolls" and item.scrollTier then
			found += 1; local selected = self._scroll and self._scroll.id == entry.id
			local b = button(self._scrollList, "", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), selected and COLORS.accent or COLORS.dark); b.LayoutOrder = found; stroke(b, selected and COLORS.border or COLORS.borderDim)
			local swatch = Instance.new("Frame"); swatch.Size = UDim2.fromScale(.58, .58); swatch.AnchorPoint = Vector2.new(.5, 0); swatch.Position = UDim2.new(.5, 0, .08, 0); swatch.BackgroundColor3 = item.color or COLORS.slot; swatch.Parent = b; corner(swatch, 5)
			local level = label(b, "Lv. " .. item.scrollTier, UDim2.new(1, -4, 0, 12), UDim2.new(0, 2, 1, -26), Enum.Font.GothamBold); level.TextSize = 9; level.TextXAlignment = Enum.TextXAlignment.Center
			local count = label(b, string.format("Lv. %d  ·  x%d", item.scrollTier, entry.count or 1), UDim2.new(1, -60, 0, 16), UDim2.fromOffset(54, 29), Enum.Font.Gotham, COLORS.dim); count.TextSize = 10
			count.Text = "x" .. (entry.count or 1)
			count.Size = UDim2.new(1, -4, 0, 12)
			count.Position = UDim2.new(0, 2, 1, -14)
			count.TextSize = 9
			count.TextXAlignment = Enum.TextXAlignment.Right
			count.TextStrokeTransparency = 0.45
			count.Visible = (entry.count or 1) > 1
			b.MouseButton1Click:Connect(function() self._scroll = entry; self:_renderScrolls(); self:_refreshDetails() end)
		end
	end
	if found == 0 then local empty = label(self._scrollList, "No enhancement scrolls in your inventory.", UDim2.new(1, 0, 0, 40), UDim2.fromOffset(0, 0), Enum.Font.Gotham, COLORS.dim); empty.TextWrapped = true; empty.TextXAlignment = Enum.TextXAlignment.Center end
end

function EnhancementUI:_renderGear()
	for _, child in self._gearGrid:GetChildren() do if child:IsA("GuiButton") then child:Destroy() end end
	local entries, seen = {}, {}
	for _, entry in ipairs(self._inventory) do
		local item = Items[entry.id]
		if item and item.slot and entry.uid then table.insert(entries, { entry = entry, equipped = false }); seen[entry.uid] = true end
	end
	for _, entry in pairs(self._equipped) do
		local item = type(entry) == "table" and Items[entry.id]
		if item and item.slot and entry.uid and not seen[entry.uid] then table.insert(entries, { entry = entry, equipped = true }) end
	end
	self._emptyGear.Visible = #entries == 0
	for index, record in ipairs(entries) do
		local entry, item = record.entry, Items[record.entry.id]
		local selected = self._target and self._target.uid == entry.uid
		local card = button(self._gearGrid, "", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), selected and COLORS.accent or COLORS.dark); card.LayoutOrder = index; stroke(card, selected and COLORS.border or COLORS.borderDim)
		local icon = Instance.new("Frame"); icon.Size = UDim2.fromScale(.56, .56); icon.AnchorPoint = Vector2.new(.5, 0); icon.Position = UDim2.new(.5, 0, .09, 0); icon.BackgroundColor3 = itemColor(item, entry); icon.BorderSizePixel = 0; icon.Parent = card; corner(icon, 5)
		local level = label(card, "+" .. (entry.enhanceLevel or 0), UDim2.new(0.55, -2, 0, 12), UDim2.new(0, 2, 1, -14), Enum.Font.GothamBold); level.TextSize = 9; level.TextXAlignment = Enum.TextXAlignment.Left
		if (entry.count or 1) > 1 then
			local count = label(card, "x" .. entry.count, UDim2.new(0.45, -2, 0, 12), UDim2.new(.55, 0, 1, -14), Enum.Font.GothamBold)
			count.TextSize = 9
			count.TextXAlignment = Enum.TextXAlignment.Right
			count.TextStrokeTransparency = 0.45
		end
		if record.equipped then local equipped = label(card, "E", UDim2.fromOffset(12, 12), UDim2.fromOffset(3, 3), Enum.Font.GothamBold, COLORS.text); equipped.TextSize = 8; equipped.TextXAlignment = Enum.TextXAlignment.Center end
		card.MouseButton1Click:Connect(function() self._target = entry; self:_renderGear(); self:_refreshDetails() end)
	end
end

function EnhancementUI:_statText()
	if not self._target then return "" end
	local item = Items[self._target.id]; local values = {}; local bonuses = self._target.enhancementBonuses or {}
	if item.damage then addValue(values, "Weapon Damage", item.damage) end
	for key, value in pairs(item.statBonuses or {}) do addValue(values, LEGACY[key] or DISPLAY[key] or key, value) end
	for key, value in pairs(bonuses) do addValue(values, DISPLAY[key] or LEGACY[key] or key, value) end
	local lines = { "<b>TOTAL ITEM STATS</b>" }
	for _, key in ipairs(sortedKeys(values)) do
		local value = values[key]
		table.insert(lines, string.format("%s: %s", key, PERCENT_LABELS[key] and string.format("%.2f%%", value * 100) or string.format("%g", value)))
	end
	if #lines == 1 then table.insert(lines, "No inherent stat bonuses.") end
	local rightLines = {}
	if self._scroll then
		local scrollItem = Items[self._scroll.id]
		local bonusLines = {}
		for _, key in ipairs(sortedKeys(scrollItem.enhancementBonuses or {})) do
			local value = scrollItem.enhancementBonuses[key]
			table.insert(bonusLines, string.format("+%s %s", PERCENT[key] and string.format("%.2f%%", value * 100) or string.format("%g", value), DISPLAY[key] or key))
		end
		table.insert(lines, "\n<b>SCROLL BONUS</b>")
		table.insert(rightLines, "<b>SCROLL BONUS</b>")
		local split = math.ceil(#bonusLines / 2)
		for index, bonus in ipairs(bonusLines) do
			table.insert(index <= split and lines or rightLines, bonus)
		end
	end
	return table.concat(lines, "\n"), table.concat(rightLines, "\n")
end

function EnhancementUI:_canApply()
	return self._scroll ~= nil and self._target ~= nil
end

function EnhancementUI:_refreshDetails()
	self._status.TextColor3 = COLORS.dim
	self._detailStatsRight.Text = ""
	if not self._target then self._detailName.Text = "Choose an equipment or weapon"; self._detailLevel.Text = ""; self._detailStats.Text = ""; self._goldCost.Text = "Required Gold: --"; self._status.Text = "Select a piece of gear in the middle panel."; self._apply.BackgroundColor3 = COLORS.empty; return end
	local item = Items[self._target.id]; local level = self._target.enhanceLevel or 0; self._detailName.Text = item.name; self._detailLevel.Text = string.format("%s  ·  Current enhancement +%d", item.slot == "weapon" and "Weapon" or EquipmentSlots.LABELS[item.slot], level); self._detailStats.Text = self:_statText()
	local _, rightStats = self:_statText()
	self._detailStatsRight.Text = rightStats
	if not self._scroll then self._goldCost.Text = "Required Gold: --"; self._status.Text = "Select an enhancement scroll from the left panel."; self._apply.BackgroundColor3 = COLORS.empty; return end
	local scroll = Items[self._scroll.id]; local tier = EnhancementConfig.GetTierForLevel(scroll.scrollTier)
	if self:_canApply() then
		local breakChance = math.max(0, 1 - tier.success - tier.fail - tier.downgrade)
		self._status.Text = string.format("Replaces the current imprint with +%d on success. Cost: %d gold  ·  Success: %d%%  ·  Fail: %d%%  ·  Down: %d%%  ·  Break: %d%%", scroll.scrollTier, tier.applyGoldCost, tier.success * 100, tier.fail * 100, tier.downgrade * 100, breakChance * 100)
		self._status.Text = string.format("Applies +%d immediately and replaces the current imprint. Cost: %d gold. Guaranteed enhancement.", scroll.scrollTier, tier.applyGoldCost)
		self._goldCost.Text = string.format("Required Gold: %d", tier.applyGoldCost)
		self._apply.BackgroundColor3 = COLORS.success
	end
end

function EnhancementUI:SetInventory(inventory) self._inventory = inventory or {}; if self._visible then self:_renderScrolls(); self:_refreshDetails() end end
function EnhancementUI:SetEquipped(equipped) self._equipped = equipped or {}; if self._visible then self:_renderGear(); self:_refreshDetails() end end
function EnhancementUI:SetVisible(visible) self._visible = visible; self._overlay.Visible = visible; self._root.Visible = visible; if visible then self:_renderScrolls(); self:_renderGear(); self:_refreshDetails() end end
function EnhancementUI:Open(targetUid)
	self:SetVisible(true)
	if targetUid then
		self._target = nil
		for _, entry in pairs(self._equipped) do
			if type(entry) == "table" and entry.uid == targetUid then self._target = entry; break end
		end
		-- The inventory context menu can also open the forge for a bag item. It is
		-- still valid to enhance; the equipped layout simply has no matching slot.
		if not self._target or self._target.uid ~= targetUid then
			for _, entry in ipairs(self._inventory) do
				if entry.uid == targetUid then self._target = entry; break end
			end
		end
		self:_renderGear(); self:_refreshDetails()
	end
end
function EnhancementUI:OnApply(callback) self._onApply = callback end
function EnhancementUI:GetScreenGui() return self._screen end
function EnhancementUI:SetGold(amount) self._currentGold.Text = "GOLD: " .. tostring(math.max(0, math.floor(amount or 0))) end
function EnhancementUI:ShowMessage(message, isError)
	self._status.Text = message or ""
	self._status.TextColor3 = isError and COLORS.danger or COLORS.dim
end

return EnhancementUI
