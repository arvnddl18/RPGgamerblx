local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local RarityConfig = require(Shared.Config.RarityConfig)
local EquipmentSlots = require(Shared.Config.EquipmentSlots)

local ShopUI = {}
ShopUI.__index = ShopUI

-- ─── Shared color palette (mirrors InventoryEquipmentUI) ────────────────────
local COLORS = {
	bg = Color3.fromRGB(10, 8, 7),
	overlay = Color3.fromRGB(0, 0, 0),
	panel = Color3.fromRGB(24, 19, 15),
	panelInner = Color3.fromRGB(32, 26, 20),
	border = Color3.fromRGB(150, 115, 45),
	borderDim = Color3.fromRGB(70, 55, 28),
	text = Color3.fromRGB(235, 225, 205),
	textDim = Color3.fromRGB(150, 140, 120),
	slot = Color3.fromRGB(30, 24, 19),
	slotEmpty = Color3.fromRGB(22, 18, 14),
	slotHover = Color3.fromRGB(45, 36, 28),
	slotSelected = Color3.fromRGB(55, 44, 32),
	accent = Color3.fromRGB(85, 125, 175),
	danger = Color3.fromRGB(140, 55, 45),
	success = Color3.fromRGB(65, 120, 75),
	gold = Color3.fromRGB(220, 185, 55),
	locked = Color3.fromRGB(80, 80, 80),
}

local MAX_SHOP_SLOTS = 100
local SLOT_SIZE = 54
local SLOT_PAD = 4

local CATEGORY_FILTERS = {
	{ id = "all", label = "All" },
	{ id = "weapon", label = "Weapons", slot = "weapon" },
	{ id = "helmet", label = "Helmet", slot = "helmet" },
	{ id = "armor", label = "Chest", slot = "armor" },
	{ id = "upperArms", label = "Arms", slot = "upperArms" },
	{ id = "shoulders", label = "Shoulders", slot = "shoulders" },
	{ id = "gloves", label = "Gloves", slot = "gloves" },
	{ id = "pants", label = "Legs", slot = "pants" },
	{ id = "boots", label = "Boots", slot = "boots" },
	{ id = "materials", label = "Materials", category = "materials" },
	{ id = "consumables", label = "Consumables", consumable = true },
	{ id = "Fighter", label = "Fighter", enhancementCategory = "Fighter" },
	{ id = "Mage", label = "Mage", enhancementCategory = "Mage" },
	{ id = "Healer", label = "Healer", enhancementCategory = "Healer" },
	{ id = "Lucky", label = "Lucky", enhancementCategory = "Lucky" },
	{ id = "Guardian", label = "Guardian", enhancementCategory = "Guardian" },
	{ id = "Rogue", label = "Rogue", enhancementCategory = "Rogue" },
	{ id = "Hybrid", label = "Hybrid", enhancementCategory = "Hybrid" },
}

local RARITY_OPTIONS = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

local STAT_DISPLAY_NAMES = {
	physicalAttack = "Physical Attack", magicAttack = "Magic Attack", maxHp = "Max HP", maxMana = "Max Mana",
	defense = "Defense", magicalResistance = "Magic Resistance", movementSpeed = "Move Speed",
	critChance = "Critical Chance", critDamage = "Critical Damage", critReduction = "Critical Reduction",
	accuracy = "Accuracy", evasion = "Evasion", healPower = "Heal Power", hpRegen = "HP Regen", manaRegen = "Mana Regen",
}
local PERCENT_STATS = { critChance = true, critDamage = true, critReduction = true, accuracy = true, evasion = true, healPower = true }

local function formatStatBonus(statName, value)
	local label = STAT_DISPLAY_NAMES[statName] or statName:gsub("(%u)", " %1"):gsub("^%s+", "")
	if PERCENT_STATS[statName] then
		return string.format("+%.3f%% %s", value * 100, label)
	end
	return string.format("+%g %s", value, label)
end

-- ─── Helpers ────────────────────────────────────────────────────────────────
local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.borderDim
	s.Thickness = thickness or 1
	s.Parent = parent
	return s
end

local function matchesCategoryFilter(item, filterId)
	if filterId == "all" then
		return true
	end
	if not item then
		return false
	end
	for _, filter in CATEGORY_FILTERS do
		if filter.id == filterId then
			if filter.slot then
				return item.slot == filter.slot
			end
			if filter.category then
				return item.category == filter.category or item.type == "material"
			end
			if filter.consumable then
				return item.usable == true
					or item.category == "potions"
					or item.type == "consumable"
			end
			if filter.enhancementCategory then
				return item.enhancementCategory == filter.enhancementCategory
			end
			return false
		end
	end
	return true
end

local function matchesRarityFilter(shopEntry, rarityFilter)
	if rarityFilter == "all" then
		return true
	end
	-- Shop items don't inherently have rarity, but the underlying item config
	-- may have a supportsRarity flag. For now filter by checking the Items config.
	local item = Items[shopEntry.itemId]
	if not item then
		return false
	end
	-- Shop items are sold "as-is"; rarity filter only applies if the item has a rarity field
	-- For shop purposes, if no explicit rarity, treat as "Common"
	return rarityFilter == "Common"
end

-- ─── Constructor ────────────────────────────────────────────────────────────
function ShopUI.new(playerGui)
	local self = setmetatable({}, ShopUI)

	self._playerGui = playerGui
	self._shopItems = {}
	self._shopType = "equipment"
	self._playerLevel = 1
	self._categoryFilter = "all"
	self._rarityFilter = "all"
	self._visible = false
	self._selectedIndex = nil  -- index into filtered list
	self._onPurchase = nil
	self._hoverToken = 0

	-- ── ScreenGui ──
	self._screenGui = Instance.new("ScreenGui")
	self._screenGui.Name = "ShopUI"
	self._screenGui.ResetOnSpawn = false
	self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self._screenGui.DisplayOrder = 100
	self._screenGui.Parent = playerGui

	-- ── Overlay ──
	self._overlay = Instance.new("TextButton")
	self._overlay.Name = "Overlay"
	self._overlay.Size = UDim2.fromScale(1, 1)
	self._overlay.BackgroundColor3 = COLORS.overlay
	self._overlay.BackgroundTransparency = 0.45
	self._overlay.BorderSizePixel = 0
	self._overlay.Text = ""
	self._overlay.AutoButtonColor = false
	self._overlay.Visible = false
	self._overlay.Parent = self._screenGui

	-- ── Root ──
	self._root = Instance.new("Frame")
	self._root.Name = "Root"
	self._root.AnchorPoint = Vector2.new(0.5, 0.5)
	self._root.Position = UDim2.fromScale(0.5, 0.5)
	self._root.Size = UDim2.fromScale(1, 1)
	self._root.BackgroundColor3 = COLORS.panel
	self._root.BorderSizePixel = 0
	self._root.Active = true
	self._root.Visible = false
	self._root.Parent = self._screenGui
	addCorner(self._root, 10)
	addStroke(self._root, COLORS.border, 2)

	-- ── Close Button ──
	self._closeBtn = Instance.new("TextButton")
	self._closeBtn.Size = UDim2.new(0, 36, 0, 36)
	self._closeBtn.Position = UDim2.new(1, -44, 0, 8)
	self._closeBtn.BackgroundColor3 = COLORS.danger
	self._closeBtn.Text = "✕"
	self._closeBtn.TextColor3 = COLORS.text
	self._closeBtn.Font = Enum.Font.GothamBold
	self._closeBtn.TextSize = 16
	self._closeBtn.ZIndex = 10
	self._closeBtn.Parent = self._root
	addCorner(self._closeBtn, 6)

	-- ══════════════════════════════════════════════════════════════════════
	-- LEFT PANEL — Item Grid + Filters
	-- ══════════════════════════════════════════════════════════════════════
	self._inventoryPanel = Instance.new("Frame")
	self._inventoryPanel.Name = "ShopGridPanel"
	self._inventoryPanel.Size = UDim2.new(0.58, -12, 1, -24)
	self._inventoryPanel.Position = UDim2.new(0, 12, 0, 12)
	self._inventoryPanel.BackgroundColor3 = COLORS.panelInner
	self._inventoryPanel.BorderSizePixel = 0
	self._inventoryPanel.Parent = self._root
	addCorner(self._inventoryPanel, 8)
	addStroke(self._inventoryPanel, COLORS.borderDim)

	-- Panel title
	local invTitle = Instance.new("TextLabel")
	invTitle.Size = UDim2.new(0.5, -12, 0, 28)
	invTitle.Position = UDim2.new(0, 12, 0, 8)
	invTitle.BackgroundTransparency = 1
	invTitle.Text = "SHOP"
	invTitle.TextColor3 = COLORS.text
	invTitle.Font = Enum.Font.GothamBold
	invTitle.TextSize = 18
	invTitle.TextXAlignment = Enum.TextXAlignment.Left
	invTitle.Parent = self._inventoryPanel
	self._shopTitle = invTitle

	-- ── Rarity Dropdown ──
	self._rarityDropdown = Instance.new("Frame")
	self._rarityDropdown.Name = "RarityDropdown"
	self._rarityDropdown.Size = UDim2.new(0, 130, 0, 28)
	self._rarityDropdown.Position = UDim2.new(1, -142, 0, 8)
	self._rarityDropdown.BackgroundColor3 = COLORS.slot
	self._rarityDropdown.BorderSizePixel = 0
	self._rarityDropdown.Parent = self._inventoryPanel
	addCorner(self._rarityDropdown, 4)
	addStroke(self._rarityDropdown, COLORS.borderDim)

	self._rarityButton = Instance.new("TextButton")
	self._rarityButton.Size = UDim2.fromScale(1, 1)
	self._rarityButton.BackgroundTransparency = 1
	self._rarityButton.Text = "Rarity: All ▾"
	self._rarityButton.TextColor3 = COLORS.text
	self._rarityButton.Font = Enum.Font.GothamBold
	self._rarityButton.TextSize = 11
	self._rarityButton.Parent = self._rarityDropdown

	self._rarityList = Instance.new("Frame")
	self._rarityList.Name = "RarityList"
	self._rarityList.Size = UDim2.new(1, 0, 0, #RARITY_OPTIONS * 26 + 4)
	self._rarityList.Position = UDim2.new(0, 0, 1, 4)
	self._rarityList.BackgroundColor3 = Color3.fromRGB(18, 15, 12)
	self._rarityList.BorderSizePixel = 0
	self._rarityList.Visible = false
	self._rarityList.ZIndex = 30
	self._rarityList.Parent = self._rarityDropdown
	addCorner(self._rarityList, 4)
	addStroke(self._rarityList, COLORS.borderDim)

	local rarityLayout = Instance.new("UIListLayout")
	rarityLayout.Padding = UDim.new(0, 2)
	rarityLayout.Parent = self._rarityList

	for _, rarityId in RARITY_OPTIONS do
		local opt = Instance.new("TextButton")
		opt.Size = UDim2.new(1, -4, 0, 24)
		opt.BackgroundColor3 = COLORS.slotEmpty
		opt.Text = rarityId
		opt.TextColor3 = rarityId == "All" and COLORS.text or RarityConfig.GetColor(rarityId)
		opt.Font = Enum.Font.Gotham
		opt.TextSize = 11
		opt.Parent = self._rarityList
		addCorner(opt, 3)
		opt.MouseButton1Click:Connect(function()
			self:SetRarityFilter(rarityId == "All" and "all" or rarityId)
			self._rarityList.Visible = false
		end)
	end

	self._rarityButton.MouseButton1Click:Connect(function()
		self._rarityList.Visible = not self._rarityList.Visible
	end)

	-- ── Category Filter Bar ──
	self._filterBar = Instance.new("ScrollingFrame")
	self._filterBar.Name = "FilterBar"
	self._filterBar.Size = UDim2.new(1, -24, 0, 30)
	self._filterBar.Position = UDim2.new(0, 12, 0, 40)
	self._filterBar.BackgroundTransparency = 1
	self._filterBar.BorderSizePixel = 0
	self._filterBar.ScrollBarThickness = 4
	self._filterBar.ScrollingDirection = Enum.ScrollingDirection.X
	self._filterBar.CanvasSize = UDim2.new(0, 0, 0, 0)
	self._filterBar.Parent = self._inventoryPanel

	local filterLayout = Instance.new("UIListLayout")
	filterLayout.FillDirection = Enum.FillDirection.Horizontal
	filterLayout.Padding = UDim.new(0, 2)
	filterLayout.Parent = self._filterBar

	self._filterButtons = {}
	for _, filter in CATEGORY_FILTERS do
		local btn = Instance.new("TextButton")
		btn.Name = "Filter_" .. filter.id
		btn.Size = UDim2.fromOffset(math.max(48, #filter.label * 6 + 10), 24)
		btn.BackgroundColor3 = filter.id == "all" and COLORS.accent or COLORS.slot
		btn.Text = filter.label
		btn.TextColor3 = COLORS.text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 10
		btn.Parent = self._filterBar
		addCorner(btn, 4)
		self._filterButtons[filter.id] = btn
		btn.MouseButton1Click:Connect(function()
			self:SetCategoryFilter(filter.id)
		end)
	end

	task.defer(function()
		self._filterBar.CanvasSize = UDim2.new(0, filterLayout.AbsoluteContentSize.X + 8, 0, 0)
	end)
	filterLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self._filterBar.CanvasSize = UDim2.new(0, filterLayout.AbsoluteContentSize.X + 8, 0, 0)
	end)

	-- ── Filter Info ──
	self._filterInfo = Instance.new("TextLabel")
	self._filterInfo.Size = UDim2.new(1, -24, 0, 16)
	self._filterInfo.Position = UDim2.new(0, 12, 0, 72)
	self._filterInfo.BackgroundTransparency = 1
	self._filterInfo.Text = ""
	self._filterInfo.TextColor3 = COLORS.textDim
	self._filterInfo.Font = Enum.Font.Gotham
	self._filterInfo.TextSize = 10
	self._filterInfo.TextXAlignment = Enum.TextXAlignment.Left
	self._filterInfo.Parent = self._inventoryPanel

	-- ── Item Grid ──
	self._gridFrame = Instance.new("ScrollingFrame")
	self._gridFrame.Name = "Grid"
	self._gridFrame.Size = UDim2.new(1, -24, 1, -100)
	self._gridFrame.AnchorPoint = Vector2.new(0.5, 0)
	self._gridFrame.Position = UDim2.new(0.5, 0, 0, 92)
	self._gridFrame.BackgroundTransparency = 1
	self._gridFrame.BorderSizePixel = 0
	self._gridFrame.ScrollBarThickness = 6
	self._gridFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	self._gridFrame.Parent = self._inventoryPanel

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
	gridLayout.CellPadding = UDim2.fromOffset(SLOT_PAD, SLOT_PAD)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = self._gridFrame

	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self._gridFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 8)
	end)

	-- Create enough slots for every rank in a focused enhancement category.
	self._shopSlots = {}
	for idx = 1, MAX_SHOP_SLOTS do
		local slot = self:_createSlot(self._gridFrame, idx)
		slot.frame.LayoutOrder = idx
		self._shopSlots[idx] = slot
	end

	-- ══════════════════════════════════════════════════════════════════════
	-- RIGHT PANEL — Item Details
	-- ══════════════════════════════════════════════════════════════════════
	self._detailPanel = Instance.new("Frame")
	self._detailPanel.Name = "DetailPanel"
	self._detailPanel.Size = UDim2.new(0.42, -12, 1, -24)
	self._detailPanel.Position = UDim2.new(0.58, 0, 0, 12)
	self._detailPanel.BackgroundColor3 = COLORS.panelInner
	self._detailPanel.BorderSizePixel = 0
	self._detailPanel.Parent = self._root
	addCorner(self._detailPanel, 8)
	addStroke(self._detailPanel, COLORS.borderDim)

	local detailTitle = Instance.new("TextLabel")
	detailTitle.Size = UDim2.new(1, -20, 0, 32)
	detailTitle.Position = UDim2.new(0, 12, 0, 8)
	detailTitle.BackgroundTransparency = 1
	detailTitle.Text = "ITEM DETAILS"
	detailTitle.TextColor3 = COLORS.text
	detailTitle.Font = Enum.Font.GothamBold
	detailTitle.TextSize = 18
	detailTitle.TextXAlignment = Enum.TextXAlignment.Left
	detailTitle.Parent = self._detailPanel

	-- Scrollable content for item details
	self._detailScroll = Instance.new("ScrollingFrame")
	self._detailScroll.Name = "DetailScroll"
	self._detailScroll.Size = UDim2.new(1, -24, 1, -110)
	self._detailScroll.Position = UDim2.new(0, 12, 0, 44)
	self._detailScroll.BackgroundTransparency = 1
	self._detailScroll.BorderSizePixel = 0
	self._detailScroll.ScrollBarThickness = 4
	self._detailScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	self._detailScroll.Parent = self._detailPanel

	self._detailLayout = Instance.new("UIListLayout")
	self._detailLayout.Padding = UDim.new(0, 6)
	self._detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
	self._detailLayout.Parent = self._detailScroll

	self._detailLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self._detailScroll.CanvasSize = UDim2.new(0, 0, 0, self._detailLayout.AbsoluteContentSize.Y + 8)
	end)

	-- ── "No item selected" placeholder ──
	self._noSelectionLabel = Instance.new("TextLabel")
	self._noSelectionLabel.Name = "NoSelection"
	self._noSelectionLabel.Size = UDim2.new(1, 0, 0, 60)
	self._noSelectionLabel.BackgroundTransparency = 1
	self._noSelectionLabel.Text = "Select an item to view details"
	self._noSelectionLabel.TextColor3 = COLORS.textDim
	self._noSelectionLabel.Font = Enum.Font.Gotham
	self._noSelectionLabel.TextSize = 13
	self._noSelectionLabel.LayoutOrder = 1
	self._noSelectionLabel.Parent = self._detailScroll

	-- ══════════════════════════════════════════════════════════════════════
	-- BOTTOM BAR — Quantity + Buy (inside detail panel)
	-- ══════════════════════════════════════════════════════════════════════
	self._buyBar = Instance.new("Frame")
	self._buyBar.Name = "BuyBar"
	self._buyBar.Size = UDim2.new(1, -24, 0, 54)
	self._buyBar.Position = UDim2.new(0, 12, 1, -66)
	self._buyBar.BackgroundColor3 = COLORS.slot
	self._buyBar.BorderSizePixel = 0
	self._buyBar.Visible = false
	self._buyBar.Parent = self._detailPanel
	addCorner(self._buyBar, 6)
	addStroke(self._buyBar, COLORS.borderDim)

	-- Quantity label
	local qtyLabel = Instance.new("TextLabel")
	qtyLabel.Size = UDim2.new(0, 36, 0, 28)
	qtyLabel.Position = UDim2.new(0, 8, 0.5, -14)
	qtyLabel.BackgroundTransparency = 1
	qtyLabel.Text = "Qty:"
	qtyLabel.TextColor3 = COLORS.textDim
	qtyLabel.Font = Enum.Font.GothamBold
	qtyLabel.TextSize = 12
	qtyLabel.TextXAlignment = Enum.TextXAlignment.Left
	qtyLabel.Parent = self._buyBar

	-- Minus button
	self._qtyMinus = Instance.new("TextButton")
	self._qtyMinus.Size = UDim2.new(0, 28, 0, 28)
	self._qtyMinus.Position = UDim2.new(0, 44, 0.5, -14)
	self._qtyMinus.BackgroundColor3 = COLORS.slotEmpty
	self._qtyMinus.Text = "−"
	self._qtyMinus.TextColor3 = COLORS.text
	self._qtyMinus.Font = Enum.Font.GothamBold
	self._qtyMinus.TextSize = 16
	self._qtyMinus.Parent = self._buyBar
	addCorner(self._qtyMinus, 4)

	-- Quantity display
	self._qtyDisplay = Instance.new("TextLabel")
	self._qtyDisplay.Size = UDim2.new(0, 36, 0, 28)
	self._qtyDisplay.Position = UDim2.new(0, 74, 0.5, -14)
	self._qtyDisplay.BackgroundColor3 = Color3.fromRGB(18, 15, 12)
	self._qtyDisplay.Text = "1"
	self._qtyDisplay.TextColor3 = COLORS.text
	self._qtyDisplay.Font = Enum.Font.GothamBold
	self._qtyDisplay.TextSize = 14
	self._qtyDisplay.BorderSizePixel = 0
	self._qtyDisplay.Parent = self._buyBar
	addCorner(self._qtyDisplay, 4)
	addStroke(self._qtyDisplay, COLORS.borderDim)

	-- Plus button
	self._qtyPlus = Instance.new("TextButton")
	self._qtyPlus.Size = UDim2.new(0, 28, 0, 28)
	self._qtyPlus.Position = UDim2.new(0, 112, 0.5, -14)
	self._qtyPlus.BackgroundColor3 = COLORS.slotEmpty
	self._qtyPlus.Text = "+"
	self._qtyPlus.TextColor3 = COLORS.text
	self._qtyPlus.Font = Enum.Font.GothamBold
	self._qtyPlus.TextSize = 16
	self._qtyPlus.Parent = self._buyBar
	addCorner(self._qtyPlus, 4)

	-- Buy Button
	self._buyButton = Instance.new("TextButton")
	self._buyButton.Size = UDim2.new(1, -160, 0, 36)
	self._buyButton.Position = UDim2.new(1, -self._buyButton.Size.X.Offset - 8, 0.5, -18)
	self._buyButton.BackgroundColor3 = COLORS.gold
	self._buyButton.Text = "BUY"
	self._buyButton.TextColor3 = Color3.fromRGB(30, 20, 10)
	self._buyButton.Font = Enum.Font.GothamBold
	self._buyButton.TextSize = 15
	self._buyButton.Parent = self._buyBar
	addCorner(self._buyButton, 6)
	addStroke(self._buyButton, COLORS.border)

	-- ── Internal quantity state ──
	self._quantity = 1
	self._isStackable = false

	-- ── Wire up buttons ──
	self._closeBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	self._overlay.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	self._qtyMinus.MouseButton1Click:Connect(function()
		self:_setQuantity(self._quantity - 1)
	end)

	self._qtyPlus.MouseButton1Click:Connect(function()
		self:_setQuantity(self._quantity + 1)
	end)

	self._buyButton.MouseButton1Click:Connect(function()
		self:_handleBuy()
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not self._visible or processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			self:SetVisible(false)
		end
	end)

	-- Close rarity dropdown when clicking elsewhere
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		task.defer(function()
			if not self._rarityList or not self._rarityList.Visible then
				return
			end
			local pos = UserInputService:GetMouseLocation()
			local guiInset = game:GetService("GuiService"):GetGuiInset()
			local hits = self._playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y - guiInset.Y)
			for _, obj in hits do
				if obj == self._rarityDropdown or obj:IsDescendantOf(self._rarityDropdown) then
					return
				end
			end
			self._rarityList.Visible = false
		end)
	end)

	-- ── Tooltip (for hover) ──
	self._tooltip = Instance.new("Frame")
	self._tooltip.Name = "Tooltip"
	self._tooltip.Size = UDim2.fromOffset(220, 10)
	self._tooltip.BackgroundColor3 = Color3.fromRGB(12, 10, 8)
	self._tooltip.BackgroundTransparency = 0.05
	self._tooltip.BorderSizePixel = 0
	self._tooltip.Visible = false
	self._tooltip.ZIndex = 50
	self._tooltip.Parent = self._screenGui
	addCorner(self._tooltip, 6)
	addStroke(self._tooltip, COLORS.border)

	self._tooltipTitle = Instance.new("TextLabel")
	self._tooltipTitle.Size = UDim2.new(1, -12, 0, 22)
	self._tooltipTitle.Position = UDim2.new(0, 6, 0, 6)
	self._tooltipTitle.BackgroundTransparency = 1
	self._tooltipTitle.Text = ""
	self._tooltipTitle.TextColor3 = COLORS.text
	self._tooltipTitle.Font = Enum.Font.GothamBold
	self._tooltipTitle.TextSize = 13
	self._tooltipTitle.TextXAlignment = Enum.TextXAlignment.Left
	self._tooltipTitle.TextWrapped = true
	self._tooltipTitle.Parent = self._tooltip

	self._tooltipBody = Instance.new("TextLabel")
	self._tooltipBody.Size = UDim2.new(1, -12, 0, 10)
	self._tooltipBody.Position = UDim2.new(0, 6, 0, 28)
	self._tooltipBody.BackgroundTransparency = 1
	self._tooltipBody.Text = ""
	self._tooltipBody.TextColor3 = COLORS.textDim
	self._tooltipBody.Font = Enum.Font.Gotham
	self._tooltipBody.TextSize = 11
	self._tooltipBody.TextXAlignment = Enum.TextXAlignment.Left
	self._tooltipBody.TextYAlignment = Enum.TextYAlignment.Top
	self._tooltipBody.TextWrapped = true
	self._tooltipBody.Parent = self._tooltip

	return self
end

-- ─── Slot Creation ──────────────────────────────────────────────────────────
function ShopUI:_createSlot(parent, index)
	local frame = Instance.new("TextButton")
	frame.Name = "ShopSlot" .. index
	frame.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
	frame.BackgroundColor3 = COLORS.slotEmpty
	frame.Text = ""
	frame.TextColor3 = COLORS.textDim
	frame.Font = Enum.Font.Gotham
	frame.TextSize = 9
	frame.AutoButtonColor = false
	frame.Parent = parent
	addCorner(frame, 5)
	local stroke = addStroke(frame, COLORS.borderDim, 1)

	local icon = Instance.new("Frame")
	icon.Name = "Icon"
	icon.Size = UDim2.fromScale(0.72, 0.72)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.BackgroundColor3 = COLORS.slot
	icon.BorderSizePixel = 0
	icon.Visible = false
	icon.Parent = frame
	addCorner(icon, 4)

	-- Lock icon overlay for level-locked items
	local lockIcon = Instance.new("TextLabel")
	lockIcon.Name = "Lock"
	lockIcon.Size = UDim2.fromScale(1, 1)
	lockIcon.BackgroundTransparency = 0.5
	lockIcon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	lockIcon.Text = "🔒"
	lockIcon.TextColor3 = COLORS.textDim
	lockIcon.Font = Enum.Font.Gotham
	lockIcon.TextSize = 18
	lockIcon.Visible = false
	lockIcon.ZIndex = 3
	lockIcon.Parent = frame
	addCorner(lockIcon, 5)

	local slotData = {
		frame = frame,
		icon = icon,
		lockIcon = lockIcon,
		stroke = stroke,
		index = index,
		shopEntry = nil,
	}

	frame.MouseEnter:Connect(function()
		stroke.Color = COLORS.border
		frame.BackgroundColor3 = COLORS.slotHover
		self:_scheduleTooltip(slotData)
	end)

	frame.MouseLeave:Connect(function()
		stroke.Color = (self._selectedIndex == slotData._filteredIndex) and COLORS.border or COLORS.borderDim
		if self._selectedIndex == slotData._filteredIndex then
			frame.BackgroundColor3 = COLORS.slotSelected
		else
			frame.BackgroundColor3 = slotData.shopEntry and COLORS.slot or COLORS.slotEmpty
		end
		self:_hideTooltip()
	end)

	frame.MouseButton1Click:Connect(function()
		if slotData.shopEntry then
			self:_selectItem(slotData._filteredIndex)
		end
	end)

	return slotData
end

-- ─── Tooltip ────────────────────────────────────────────────────────────────
function ShopUI:_scheduleTooltip(slotData)
	self._hoverToken += 1
	local token = self._hoverToken
	task.delay(0.15, function()
		if token ~= self._hoverToken then
			return
		end
		self:_showTooltip(slotData)
	end)
end

function ShopUI:_hideTooltip()
	self._hoverToken += 1
	self._tooltip.Visible = false
end

function ShopUI:_showTooltip(slotData)
	if not slotData.shopEntry then
		return
	end
	local entry = slotData.shopEntry
	local item = Items[entry.itemId]
	if not item then
		return
	end

	self._tooltipTitle.Text = item.name
	self._tooltipBody.Text = (item.description or "") .. "\nPrice: " .. entry.price .. "g"

	local textH = self._tooltipBody.TextBounds.Y
	self._tooltipBody.Size = UDim2.new(1, -12, 0, textH)
	self._tooltip.Size = UDim2.fromOffset(220, 40 + textH)

	local pos = UserInputService:GetMouseLocation()
	local guiInset = game:GetService("GuiService"):GetGuiInset()
	local x = pos.X + 16
	local y = pos.Y - guiInset.Y + 16
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	if x + 220 > vp.X then
		x = pos.X - 236
	end
	if y + self._tooltip.AbsoluteSize.Y > vp.Y then
		y = pos.Y - guiInset.Y - self._tooltip.AbsoluteSize.Y - 8
	end
	self._tooltip.Position = UDim2.fromOffset(x, y)
	self._tooltip.Visible = true
end

-- ─── Selection & Detail Panel ───────────────────────────────────────────────
function ShopUI:_selectItem(filteredIndex)
	self._selectedIndex = filteredIndex
	self._quantity = 1
	self:_refreshGrid()
	self:_refreshDetails()
end

function ShopUI:_getSelectedEntry()
	if not self._selectedIndex then
		return nil
	end
	local filtered = self:_getFilteredItems()
	return filtered[self._selectedIndex]
end

function ShopUI:_refreshDetails()
	-- Clear old detail children (except layout and placeholder)
	for _, child in self._detailScroll:GetChildren() do
		if child:IsA("GuiObject") and child ~= self._noSelectionLabel then
			child:Destroy()
		end
	end

	local entry = self:_getSelectedEntry()
	if not entry then
		self._noSelectionLabel.Visible = true
		self._buyBar.Visible = false
		return
	end

	self._noSelectionLabel.Visible = false
	self._buyBar.Visible = true

	local item = Items[entry.itemId]
	if not item then
		return
	end

	local locked = entry.requiredLevel and self._playerLevel < entry.requiredLevel

	-- Determine if stackable
	self._isStackable = item.stackable == true
		or item.type == "material"
		or item.type == "consumable"
		or item.category == "potions"

	local order = 1
	local function nextOrder()
		order += 1
		return order
	end

	-- ── Item Icon ──
	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "DetailIcon"
	iconFrame.Size = UDim2.new(0, 64, 0, 64)
	iconFrame.BackgroundColor3 = item.color or COLORS.slot
	iconFrame.BorderSizePixel = 0
	iconFrame.LayoutOrder = nextOrder()
	iconFrame.Parent = self._detailScroll
	addCorner(iconFrame, 8)
	addStroke(iconFrame, COLORS.border)

	-- ── Item Name ──
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "DetailName"
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name
	nameLabel.TextColor3 = locked and COLORS.locked or COLORS.text
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextWrapped = true
	nameLabel.LayoutOrder = nextOrder()
	nameLabel.Parent = self._detailScroll

	-- ── Description ──
	if item.description and item.description ~= "" then
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "DetailDesc"
		descLabel.Size = UDim2.new(1, 0, 0, 0)
		descLabel.AutomaticSize = Enum.AutomaticSize.Y
		descLabel.BackgroundTransparency = 1
		descLabel.Text = item.description
		descLabel.TextColor3 = COLORS.textDim
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 12
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.LayoutOrder = nextOrder()
		descLabel.Parent = self._detailScroll
	end

	-- ── Separator ──
	local function addSeparator()
		local sep = Instance.new("Frame")
		sep.Size = UDim2.new(1, 0, 0, 1)
		sep.BackgroundColor3 = COLORS.borderDim
		sep.BorderSizePixel = 0
		sep.LayoutOrder = nextOrder()
		sep.Parent = self._detailScroll
	end

	addSeparator()

	-- ── Price ──
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Size = UDim2.new(1, 0, 0, 20)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = "💰 Price: " .. entry.price .. " gold"
	priceLabel.TextColor3 = COLORS.gold
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.TextSize = 14
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.LayoutOrder = nextOrder()
	priceLabel.Parent = self._detailScroll

	-- ── Slot / Type ──
	if item.slot then
		local slotLabel = Instance.new("TextLabel")
		slotLabel.Size = UDim2.new(1, 0, 0, 18)
		slotLabel.BackgroundTransparency = 1
		slotLabel.Text = "Slot: " .. (EquipmentSlots.LABELS[item.slot] or item.slot)
		slotLabel.TextColor3 = COLORS.text
		slotLabel.Font = Enum.Font.Gotham
		slotLabel.TextSize = 12
		slotLabel.TextXAlignment = Enum.TextXAlignment.Left
		slotLabel.LayoutOrder = nextOrder()
		slotLabel.Parent = self._detailScroll
	end

	if item.type then
		local typeLabel = Instance.new("TextLabel")
		typeLabel.Size = UDim2.new(1, 0, 0, 18)
		typeLabel.BackgroundTransparency = 1
		typeLabel.Text = "Type: " .. item.type:sub(1, 1):upper() .. item.type:sub(2)
		typeLabel.TextColor3 = COLORS.text
		typeLabel.Font = Enum.Font.Gotham
		typeLabel.TextSize = 12
		typeLabel.TextXAlignment = Enum.TextXAlignment.Left
		typeLabel.LayoutOrder = nextOrder()
		typeLabel.Parent = self._detailScroll
	end

	-- ── Damage ──
	if item.damage then
		local dmgLabel = Instance.new("TextLabel")
		dmgLabel.Size = UDim2.new(1, 0, 0, 18)
		dmgLabel.BackgroundTransparency = 1
		dmgLabel.Text = "⚔ Base Damage: " .. item.damage
		dmgLabel.TextColor3 = Color3.fromRGB(255, 120, 80)
		dmgLabel.Font = Enum.Font.GothamBold
		dmgLabel.TextSize = 12
		dmgLabel.TextXAlignment = Enum.TextXAlignment.Left
		dmgLabel.LayoutOrder = nextOrder()
		dmgLabel.Parent = self._detailScroll
	end

	-- ── Status Effects / Stat Bonuses ──
	if item.statBonuses and next(item.statBonuses) then
		addSeparator()

		local statsHeader = Instance.new("TextLabel")
		statsHeader.Size = UDim2.new(1, 0, 0, 20)
		statsHeader.BackgroundTransparency = 1
		statsHeader.Text = "ADDITIONAL STATS"
		statsHeader.TextColor3 = COLORS.accent
		statsHeader.Font = Enum.Font.GothamBold
		statsHeader.TextSize = 11
		statsHeader.TextXAlignment = Enum.TextXAlignment.Left
		statsHeader.LayoutOrder = nextOrder()
		statsHeader.Parent = self._detailScroll

		for statName, statValue in item.statBonuses do
			local statLabel = Instance.new("TextLabel")
			statLabel.Size = UDim2.new(1, 0, 0, 16)
			statLabel.BackgroundTransparency = 1
			-- Format stat name: "PhysicalDamage" → "Physical Damage"
			local formatted = statName:gsub("(%u)", " %1"):gsub("^%s+", "")
			statLabel.Text = "  + " .. statValue .. " " .. formatted
			statLabel.TextColor3 = COLORS.success
			statLabel.Font = Enum.Font.Gotham
			statLabel.TextSize = 12
			statLabel.TextXAlignment = Enum.TextXAlignment.Left
			statLabel.LayoutOrder = nextOrder()
			statLabel.Parent = self._detailScroll
		end
	end

	-- ── Consumable Effects ──
	if item.healAmount then
		addSeparator()
		local healLabel = Instance.new("TextLabel")
		healLabel.Size = UDim2.new(1, 0, 0, 20)
		healLabel.BackgroundTransparency = 1
		healLabel.Text = "STATUS EFFECT"
		healLabel.TextColor3 = COLORS.accent
		healLabel.Font = Enum.Font.GothamBold
		healLabel.TextSize = 11
		healLabel.TextXAlignment = Enum.TextXAlignment.Left
		healLabel.LayoutOrder = nextOrder()
		healLabel.Parent = self._detailScroll

		local effectLabel = Instance.new("TextLabel")
		effectLabel.Size = UDim2.new(1, 0, 0, 16)
		effectLabel.BackgroundTransparency = 1
		effectLabel.Text = "  ❤ Restores " .. item.healAmount .. " HP"
		effectLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
		effectLabel.Font = Enum.Font.Gotham
		effectLabel.TextSize = 12
		effectLabel.TextXAlignment = Enum.TextXAlignment.Left
		effectLabel.LayoutOrder = nextOrder()
		effectLabel.Parent = self._detailScroll
	end

	if item.manaAmount then
		if not item.healAmount then
			addSeparator()
			local manaHeader = Instance.new("TextLabel")
			manaHeader.Size = UDim2.new(1, 0, 0, 20)
			manaHeader.BackgroundTransparency = 1
			manaHeader.Text = "STATUS EFFECT"
			manaHeader.TextColor3 = COLORS.accent
			manaHeader.Font = Enum.Font.GothamBold
			manaHeader.TextSize = 11
			manaHeader.TextXAlignment = Enum.TextXAlignment.Left
			manaHeader.LayoutOrder = nextOrder()
			manaHeader.Parent = self._detailScroll
		end

		local manaLabel = Instance.new("TextLabel")
		manaLabel.Size = UDim2.new(1, 0, 0, 16)
		manaLabel.BackgroundTransparency = 1
		manaLabel.Text = "  🔷 Restores " .. item.manaAmount .. " Mana"
		manaLabel.TextColor3 = Color3.fromRGB(80, 140, 255)
		manaLabel.Font = Enum.Font.Gotham
		manaLabel.TextSize = 12
		manaLabel.TextXAlignment = Enum.TextXAlignment.Left
		manaLabel.LayoutOrder = nextOrder()
		manaLabel.Parent = self._detailScroll
	end

	-- ── Scroll Tier ──
	if item.scrollTier then
		addSeparator()
		local scrollHeader = Instance.new("TextLabel")
		scrollHeader.Size = UDim2.new(1, 0, 0, 20)
		scrollHeader.BackgroundTransparency = 1
		scrollHeader.Text = "ENHANCEMENT"
		scrollHeader.TextColor3 = COLORS.accent
		scrollHeader.Font = Enum.Font.GothamBold
		scrollHeader.TextSize = 11
		scrollHeader.TextXAlignment = Enum.TextXAlignment.Left
		scrollHeader.LayoutOrder = nextOrder()
		scrollHeader.Parent = self._detailScroll

		local tierLabel = Instance.new("TextLabel")
		tierLabel.Size = UDim2.new(1, 0, 0, 16)
		tierLabel.BackgroundTransparency = 1
		tierLabel.Text = "  Enhances gear from +" .. (item.scrollTier - 1) .. " to +" .. item.scrollTier
		tierLabel.TextColor3 = Color3.fromRGB(140, 170, 255)
		tierLabel.Font = Enum.Font.Gotham
		tierLabel.TextSize = 12
		tierLabel.TextXAlignment = Enum.TextXAlignment.Left
		tierLabel.LayoutOrder = nextOrder()
		tierLabel.Parent = self._detailScroll
	end

	if item.enhancementBonuses then
		addSeparator()
		local bonusHeader = Instance.new("TextLabel")
		bonusHeader.Size = UDim2.new(1, 0, 0, 20)
		bonusHeader.BackgroundTransparency = 1
		bonusHeader.Text = string.upper(item.enhancementCategory or "FOCUSED") .. " BONUS ON SUCCESS"
		bonusHeader.TextColor3 = COLORS.accent
		bonusHeader.Font = Enum.Font.GothamBold
		bonusHeader.TextSize = 11
		bonusHeader.TextXAlignment = Enum.TextXAlignment.Left
		bonusHeader.LayoutOrder = nextOrder()
		bonusHeader.Parent = self._detailScroll
		for statName, statValue in pairs(item.enhancementBonuses) do
			local statLabel = Instance.new("TextLabel")
			statLabel.Size = UDim2.new(1, 0, 0, 16)
			statLabel.BackgroundTransparency = 1
			statLabel.Text = "  " .. formatStatBonus(statName, statValue)
			statLabel.TextColor3 = COLORS.success
			statLabel.Font = Enum.Font.Gotham
			statLabel.TextSize = 12
			statLabel.TextXAlignment = Enum.TextXAlignment.Left
			statLabel.LayoutOrder = nextOrder()
			statLabel.Parent = self._detailScroll
		end
	end

	-- ── Class Restriction ──
	if item.classRestriction then
		addSeparator()
		local classLabel = Instance.new("TextLabel")
		classLabel.Size = UDim2.new(1, 0, 0, 18)
		classLabel.BackgroundTransparency = 1
		classLabel.Text = "⚠ Class: " .. item.classRestriction .. " only"
		classLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
		classLabel.Font = Enum.Font.GothamBold
		classLabel.TextSize = 12
		classLabel.TextXAlignment = Enum.TextXAlignment.Left
		classLabel.LayoutOrder = nextOrder()
		classLabel.Parent = self._detailScroll
	end

	-- ── Prerequisites ──
	if entry.requiredLevel then
		addSeparator()
		local reqHeader = Instance.new("TextLabel")
		reqHeader.Size = UDim2.new(1, 0, 0, 20)
		reqHeader.BackgroundTransparency = 1
		reqHeader.Text = "PREREQUISITES"
		reqHeader.TextColor3 = COLORS.accent
		reqHeader.Font = Enum.Font.GothamBold
		reqHeader.TextSize = 11
		reqHeader.TextXAlignment = Enum.TextXAlignment.Left
		reqHeader.LayoutOrder = nextOrder()
		reqHeader.Parent = self._detailScroll

		local lvlLabel = Instance.new("TextLabel")
		lvlLabel.Size = UDim2.new(1, 0, 0, 18)
		lvlLabel.BackgroundTransparency = 1
		lvlLabel.Text = locked
			and ("  🔒 Requires Level " .. entry.requiredLevel .. "  (You: Lv." .. self._playerLevel .. ")")
			or ("  ✅ Requires Level " .. entry.requiredLevel .. "  (Met)")
		lvlLabel.TextColor3 = locked and COLORS.danger or COLORS.success
		lvlLabel.Font = Enum.Font.Gotham
		lvlLabel.TextSize = 12
		lvlLabel.TextXAlignment = Enum.TextXAlignment.Left
		lvlLabel.LayoutOrder = nextOrder()
		lvlLabel.Parent = self._detailScroll
	end

	-- Pre-requisite item (if the data structure supports it in the future)
	if entry.requiredItem then
		local reqItemLabel = Instance.new("TextLabel")
		reqItemLabel.Size = UDim2.new(1, 0, 0, 18)
		reqItemLabel.BackgroundTransparency = 1
		local reqItem = Items[entry.requiredItem]
		local reqName = reqItem and reqItem.name or entry.requiredItem
		reqItemLabel.Text = "  📦 Pre-requisite: " .. reqName
		reqItemLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
		reqItemLabel.Font = Enum.Font.Gotham
		reqItemLabel.TextSize = 12
		reqItemLabel.TextXAlignment = Enum.TextXAlignment.Left
		reqItemLabel.LayoutOrder = nextOrder()
		reqItemLabel.Parent = self._detailScroll
	end

	-- ── Update buy bar ──
	self:_updateBuyBar(entry, locked)
end

function ShopUI:_updateBuyBar(entry, locked)
	-- Show/hide quantity controls based on stackability
	self._qtyMinus.Visible = self._isStackable
	self._qtyPlus.Visible = self._isStackable
	self._qtyDisplay.Visible = self._isStackable

	-- For non-stackable items, force qty to 1 and shift buy button
	if not self._isStackable then
		self._quantity = 1
		self._buyButton.Size = UDim2.new(1, -16, 0, 36)
		self._buyButton.Position = UDim2.new(0, 8, 0.5, -18)
	else
		self._buyButton.Size = UDim2.new(1, -160, 0, 36)
		self._buyButton.Position = UDim2.new(0, 148, 0.5, -18)
	end

	self:_updateBuyButtonText(entry, locked)
end

function ShopUI:_updateBuyButtonText(entry, locked)
	if locked then
		self._buyButton.Text = "LOCKED"
		self._buyButton.BackgroundColor3 = COLORS.locked
		self._buyButton.Active = false
		self._buyButton.AutoButtonColor = false
	else
		local totalCost = entry.price * self._quantity
		self._buyButton.Text = "BUY — " .. totalCost .. "g"
		self._buyButton.BackgroundColor3 = COLORS.gold
		self._buyButton.Active = true
		self._buyButton.AutoButtonColor = true
	end

	self._qtyDisplay.Text = tostring(self._quantity)
end

function ShopUI:_setQuantity(newQty)
	self._quantity = math.clamp(newQty, 1, 99)
	local entry = self:_getSelectedEntry()
	if entry then
		local locked = entry.requiredLevel and self._playerLevel < entry.requiredLevel
		self:_updateBuyButtonText(entry, locked)
	end
end

function ShopUI:_handleBuy()
	local entry = self:_getSelectedEntry()
	if not entry then
		return
	end
	local locked = entry.requiredLevel and self._playerLevel < entry.requiredLevel
	if locked then
		return
	end
	if self._onPurchase then
		self._onPurchase(entry.itemId, self._quantity)
	end
end

-- ─── Filtering ──────────────────────────────────────────────────────────────
function ShopUI:_getFilteredItems()
	local filtered = {}
	for _, entry in self._shopItems do
		local item = Items[entry.itemId]
		if item then
			-- Category filter
			local catMatch = matchesCategoryFilter(item, self._categoryFilter)
			-- Rarity filter (shop items don't have individual rarity, so
			-- only "all" or "Common" will pass through)
			local rarMatch = matchesRarityFilter(entry, self._rarityFilter)
			if catMatch and rarMatch then
				table.insert(filtered, entry)
			end
		end
	end
	return filtered
end

function ShopUI:SetCategoryFilter(filterId)
	self._categoryFilter = filterId
	for id, btn in self._filterButtons do
		btn.BackgroundColor3 = id == filterId and COLORS.accent or COLORS.slot
	end
	self._selectedIndex = nil
	self:Refresh()
end

function ShopUI:SetRarityFilter(rarityId)
	self._rarityFilter = rarityId
	local label = rarityId == "all" and "All" or rarityId
	self._rarityButton.Text = "Rarity: " .. label .. " ▾"
	self._selectedIndex = nil
	self:Refresh()
end

-- ─── Grid Rendering ─────────────────────────────────────────────────────────
function ShopUI:_refreshGrid()
	local filtered = self:_getFilteredItems()
	local count = math.min(#filtered, MAX_SHOP_SLOTS)

	for idx = 1, MAX_SHOP_SLOTS do
		local slotData = self._shopSlots[idx]
		local entry = filtered[idx]
		slotData.shopEntry = entry
		slotData._filteredIndex = idx

		local frame = slotData.frame
		local icon = slotData.icon
		local lockIcon = slotData.lockIcon

		if not entry then
			icon.Visible = false
			lockIcon.Visible = false
			frame.BackgroundColor3 = COLORS.slotEmpty
			slotData.stroke.Color = COLORS.borderDim
			frame.Text = ""
		else
			local item = Items[entry.itemId]
			if item then
				icon.BackgroundColor3 = item.color or COLORS.slot
				icon.Visible = true
				frame.Text = ""

				local locked = entry.requiredLevel and self._playerLevel < entry.requiredLevel
				lockIcon.Visible = locked == true

				if self._selectedIndex == idx then
					frame.BackgroundColor3 = COLORS.slotSelected
					slotData.stroke.Color = COLORS.border
				else
					frame.BackgroundColor3 = COLORS.slot
					slotData.stroke.Color = COLORS.borderDim
				end
			end
		end
	end

	self:_updateFilterInfo(count)
end

function ShopUI:_updateFilterInfo(totalCount)
	local hasFilter = self._categoryFilter ~= "all" or self._rarityFilter ~= "all"
	if not hasFilter then
		self._filterInfo.Text = totalCount .. " items"
		return
	end
	local parts = {}
	if self._categoryFilter ~= "all" then
		for _, filter in CATEGORY_FILTERS do
			if filter.id == self._categoryFilter then
				table.insert(parts, filter.label)
				break
			end
		end
	end
	if self._rarityFilter ~= "all" then
		table.insert(parts, self._rarityFilter)
	end
	self._filterInfo.Text = string.format("%d items · %s", totalCount, table.concat(parts, " · "))
end

-- ─── Public API ─────────────────────────────────────────────────────────────
function ShopUI:Refresh()
	self:_refreshGrid()
	self:_refreshDetails()
end

function ShopUI:SetItems(items)
	self._shopItems = items or {}
	self._selectedIndex = nil
	if self._visible then
		self:Refresh()
	end
end

function ShopUI:SetShopType(shopType)
	self._shopType = shopType or "equipment"
	self._categoryFilter = "all"
	local enhancementFilters = { all = true, Fighter = true, Mage = true, Healer = true, Lucky = true, Guardian = true, Rogue = true, Hybrid = true }
	for id, button in pairs(self._filterButtons) do
		button.Visible = self._shopType ~= "enhancement" or enhancementFilters[id] == true
		button.BackgroundColor3 = id == "all" and COLORS.accent or COLORS.slot
	end
	if self._shopTitle then
		self._shopTitle.Text = self._shopType == "enhancement" and "ENHANCEMENT SCROLLS" or "EQUIPMENT SHOP"
	end
end

function ShopUI:SetPlayerLevel(level)
	self._playerLevel = level or 1
	if self._visible then
		self:Refresh()
	end
end

function ShopUI:OnPurchase(callback)
	self._onPurchase = callback
end

function ShopUI:SetVisible(visible)
	self._visible = visible
	self._overlay.Visible = visible
	self._root.Visible = visible
	if not visible then
		self:_hideTooltip()
		self._rarityList.Visible = false
		self._selectedIndex = nil
	else
		self:Refresh()
	end
end

function ShopUI:IsVisible()
	return self._visible
end

function ShopUI:GetScreenGui()
	return self._screenGui
end

-- Backward-compat alias used by the old ShopUI
function ShopUI:SetTab(tabId)
	-- Map old tab IDs to category filters
	if tabId == "materials" then
		self:SetCategoryFilter("materials")
	elseif tabId == "scrolls" then
		self:SetCategoryFilter("all")
	else
		self:SetCategoryFilter("all")
	end
end

return ShopUI
