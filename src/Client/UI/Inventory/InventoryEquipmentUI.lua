local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local RarityConfig = require(Shared.Config.RarityConfig)
local EquipmentSlots = require(Shared.Config.EquipmentSlots)
local EnhancementConfig = require(Shared.Config.EnhancementConfig)

local InventoryEquipmentUI = {}
InventoryEquipmentUI.__index = InventoryEquipmentUI

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
	slotDrag = Color3.fromRGB(60, 48, 35),
	accent = Color3.fromRGB(85, 125, 175),
	danger = Color3.fromRGB(140, 55, 45),
	success = Color3.fromRGB(65, 120, 75),
}

local MAX_INVENTORY_SLOTS = 100
local SLOT_SIZE = 54
local SLOT_PAD = 4

local EQUIP_LAYOUT = {
	helmet = { x = 0.50, y = 0.07, label = "Helm" },
	shoulders = { x = 0.20, y = 0.20, label = "Shld" },
	upperArms = { x = 0.80, y = 0.26, label = "Arms" },
	armor = { x = 0.50, y = 0.30, label = "Chest" },
	gloves = { x = 0.18, y = 0.46, label = "Glov" },
	weapon = { x = 0.14, y = 0.62, label = "Wpn" },
	pants = { x = 0.50, y = 0.52, label = "Legs" },
	boots = { x = 0.50, y = 0.74, label = "Boot" },
}

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

local ACTION_CALLBACKS = {
	use = "onUse",
	equip = "onEquip",
	unequip = "onUnequip",
	enhance = "onEnhance",
	dropItem = "onDropItem",
	craft = "onCraft",
}

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

local function formatItemName(item, entry)
	if not item or not entry then
		return "Unknown"
	end
	local name = item.name
	if entry.count and entry.count > 1 then
		name ..= " x" .. entry.count
	end
	if entry.enhanceLevel and entry.enhanceLevel > 0 then
		name ..= " +" .. entry.enhanceLevel
	end
	return name
end

local function getItemColor(item, entry)
	if entry and entry.rarity and item and item.slot then
		return RarityConfig.GetColor(entry.rarity)
	end
	return item and item.color or COLORS.slot
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
			return false
		end
	end
	return true
end

local function matchesRarityFilter(entry, rarityFilter)
	if rarityFilter == "all" then
		return true
	end
	return (entry.rarity or "Common") == rarityFilter
end

function InventoryEquipmentUI.new(playerGui)
	local self = setmetatable({}, InventoryEquipmentUI)

	self._playerGui = playerGui
	self._inventory = {}
	self._equipped = {}
	self._activeBag = 1
	self._categoryFilter = "all"
	self._rarityFilter = "all"
	self._visible = false
	self._drag = nil
	self._hoverToken = 0
	self._callbacks = {}

	self._screenGui = Instance.new("ScreenGui")
	self._screenGui.Name = "InventoryEquipmentUI"
	self._screenGui.ResetOnSpawn = false
	self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self._screenGui.DisplayOrder = 100
	self._screenGui.Parent = playerGui

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

	self._inventoryPanel = Instance.new("Frame")
	self._inventoryPanel.Name = "InventoryPanel"
	self._inventoryPanel.Size = UDim2.new(0.58, -12, 1, -24)
	self._inventoryPanel.Position = UDim2.new(0, 12, 0, 12)
	self._inventoryPanel.BackgroundColor3 = COLORS.panelInner
	self._inventoryPanel.BorderSizePixel = 0
	self._inventoryPanel.Parent = self._root
	addCorner(self._inventoryPanel, 8)
	addStroke(self._inventoryPanel, COLORS.borderDim)

	local invTitle = Instance.new("TextLabel")
	invTitle.Size = UDim2.new(0.5, -12, 0, 28)
	invTitle.Position = UDim2.new(0, 12, 0, 8)
	invTitle.BackgroundTransparency = 1
	invTitle.Text = "INVENTORY"
	invTitle.TextColor3 = COLORS.text
	invTitle.Font = Enum.Font.GothamBold
	invTitle.TextSize = 18
	invTitle.TextXAlignment = Enum.TextXAlignment.Left
	invTitle.Parent = self._inventoryPanel

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

	self._inventorySlots = {}
	for idx = 1, MAX_INVENTORY_SLOTS do
		local slot = self:_createSlot(self._gridFrame, {
			kind = "inventory",
			index = idx,
			size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
			position = UDim2.fromOffset(0, 0), -- Position is managed by UIGridLayout
		})
		slot.frame.LayoutOrder = idx
		self._inventorySlots[idx] = slot
	end

	self._characterPanel = Instance.new("Frame")
	self._characterPanel.Name = "CharacterPanel"
	self._characterPanel.Size = UDim2.new(0.42, -12, 1, -24)
	self._characterPanel.Position = UDim2.new(0.58, 0, 0, 12)
	self._characterPanel.BackgroundColor3 = COLORS.panelInner
	self._characterPanel.BorderSizePixel = 0
	self._characterPanel.Parent = self._root
	addCorner(self._characterPanel, 8)
	addStroke(self._characterPanel, COLORS.borderDim)

	local charTitle = Instance.new("TextLabel")
	charTitle.Size = UDim2.new(1, -20, 0, 32)
	charTitle.Position = UDim2.new(0, 12, 0, 8)
	charTitle.BackgroundTransparency = 1
	charTitle.Text = "CHARACTER"
	charTitle.TextColor3 = COLORS.text
	charTitle.Font = Enum.Font.GothamBold
	charTitle.TextSize = 18
	charTitle.TextXAlignment = Enum.TextXAlignment.Left
	charTitle.Parent = self._characterPanel

	self._silhouette = Instance.new("Frame")
	self._silhouette.Name = "Silhouette"
	self._silhouette.AnchorPoint = Vector2.new(0.5, 0.5)
	self._silhouette.Position = UDim2.fromScale(0.5, 0.48)
	self._silhouette.Size = UDim2.new(0, 120, 0, 280)
	self._silhouette.BackgroundColor3 = Color3.fromRGB(15, 12, 10)
	self._silhouette.BackgroundTransparency = 0.4
	self._silhouette.BorderSizePixel = 0
	self._silhouette.Parent = self._characterPanel
	addCorner(self._silhouette, 60)

	self._equipSlots = {}
	for _, slotId in EquipmentSlots.ORDER do
		local layout = EQUIP_LAYOUT[slotId]
		if layout then
			local slot = self:_createSlot(self._characterPanel, {
				kind = "equipment",
				slotId = slotId,
				label = layout.label,
				size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE),
				position = UDim2.new(layout.x, -SLOT_SIZE / 2, layout.y, 0),
			})
			self._equipSlots[slotId] = slot
		end
	end

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

	self._contextMenu = Instance.new("Frame")
	self._contextMenu.Name = "ContextMenu"
	self._contextMenu.Size = UDim2.fromOffset(140, 10)
	self._contextMenu.BackgroundColor3 = Color3.fromRGB(18, 15, 12)
	self._contextMenu.BorderSizePixel = 0
	self._contextMenu.Visible = false
	self._contextMenu.ZIndex = 100
	self._contextMenu.Active = true
	self._contextMenu.Parent = self._screenGui
	addCorner(self._contextMenu, 6)
	addStroke(self._contextMenu, COLORS.border)

	self._contextLayout = Instance.new("UIListLayout")
	self._contextLayout.Padding = UDim.new(0, 2)
	self._contextLayout.Parent = self._contextMenu

	self._dragGhost = Instance.new("Frame")
	self._dragGhost.Name = "DragGhost"
	self._dragGhost.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
	self._dragGhost.BackgroundTransparency = 0.3
	self._dragGhost.BorderSizePixel = 0
	self._dragGhost.Visible = false
	self._dragGhost.ZIndex = 55
	self._dragGhost.Parent = self._screenGui
	addCorner(self._dragGhost, 6)
	addStroke(self._dragGhost, COLORS.border, 2)

	self._dragIcon = Instance.new("Frame")
	self._dragIcon.Size = UDim2.fromScale(0.75, 0.75)
	self._dragIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	self._dragIcon.Position = UDim2.fromScale(0.5, 0.5)
	self._dragIcon.BorderSizePixel = 0
	self._dragIcon.Parent = self._dragGhost
	addCorner(self._dragIcon, 4)

	self._closeBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	self._overlay.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not self._visible or processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			self:HideContextMenu()
			self:SetVisible(false)
		end
	end)

	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		task.defer(function()
			if self._contextMenu.Visible then
				local pos = UserInputService:GetMouseLocation()
				local guiInset = game:GetService("GuiService"):GetGuiInset()
				local hits = self._playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y - guiInset.Y)
				for _, obj in hits do
					if obj == self._contextMenu or obj:IsDescendantOf(self._contextMenu) then
						return
					end
				end
				self:HideContextMenu()
			end
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

	self._enhanceBar = Instance.new("Frame")
	self._enhanceBar.Name = "EnhanceBar"
	self._enhanceBar.AnchorPoint = Vector2.new(0.5, 0)
	self._enhanceBar.Size = UDim2.new(0.88, 0, 0, 40)
	self._enhanceBar.Position = UDim2.new(0.5, 0, 0.055, 0)
	self._enhanceBar.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
	self._enhanceBar.BorderSizePixel = 0
	self._enhanceBar.Visible = false
	self._enhanceBar.ZIndex = 45
	self._enhanceBar.Parent = self._screenGui
	addCorner(self._enhanceBar, 6)

	self._enhanceLabel = Instance.new("TextLabel")
	self._enhanceLabel.Size = UDim2.new(1, -120, 1, 0)
	self._enhanceLabel.Position = UDim2.new(0, 10, 0, 0)
	self._enhanceLabel.BackgroundTransparency = 1
	self._enhanceLabel.Text = "Enhance: select a scroll, then Apply"
	self._enhanceLabel.TextColor3 = COLORS.text
	self._enhanceLabel.Font = Enum.Font.Gotham
	self._enhanceLabel.TextSize = 12
	self._enhanceLabel.TextXAlignment = Enum.TextXAlignment.Left
	self._enhanceLabel.Parent = self._enhanceBar

	self._enhanceApply = Instance.new("TextButton")
	self._enhanceApply.Size = UDim2.new(0, 90, 0, 28)
	self._enhanceApply.Position = UDim2.new(1, -100, 0.5, -14)
	self._enhanceApply.BackgroundColor3 = COLORS.success
	self._enhanceApply.Text = "Apply"
	self._enhanceApply.TextColor3 = COLORS.text
	self._enhanceApply.Font = Enum.Font.GothamBold
	self._enhanceApply.TextSize = 12
	self._enhanceApply.Parent = self._enhanceBar
	addCorner(self._enhanceApply, 4)

	self._enhanceCancel = Instance.new("TextButton")
	self._enhanceCancel.Size = UDim2.new(0, 70, 0, 28)
	self._enhanceCancel.Position = UDim2.new(1, -178, 0.5, -14)
	self._enhanceCancel.BackgroundColor3 = COLORS.danger
	self._enhanceCancel.Text = "Cancel"
	self._enhanceCancel.TextColor3 = COLORS.text
	self._enhanceCancel.Font = Enum.Font.GothamBold
	self._enhanceCancel.TextSize = 12
	self._enhanceCancel.Parent = self._enhanceBar
	addCorner(self._enhanceCancel, 4)

	self._enhanceMode = false
	self._enhanceTargetUid = nil
	self._enhanceScrollId = nil

	self._enhanceApply.MouseButton1Click:Connect(function()
		if self._callbacks.onEnhanceApply and self._enhanceScrollId and self._enhanceTargetUid then
			self._callbacks.onEnhanceApply(self._enhanceScrollId, self._enhanceTargetUid)
		end
	end)

	self._enhanceCancel.MouseButton1Click:Connect(function()
		self:SetEnhanceMode(false)
		if self._callbacks.onEnhanceCancel then
			self._callbacks.onEnhanceCancel()
		end
	end)

	self:_bindDragInput()

	return self
end

function InventoryEquipmentUI:_createSlot(parent, config)
	local frame = Instance.new("TextButton")
	frame.Name = config.kind .. (config.slotId or config.index)
	frame.Size = config.size
	frame.Position = config.position
	frame.BackgroundColor3 = COLORS.slotEmpty
	frame.Text = config.label or ""
	frame.TextColor3 = COLORS.textDim
	frame.Font = Enum.Font.Gotham
	frame.TextSize = 9
	frame.AutoButtonColor = false
	frame:SetAttribute("SlotKind", config.kind)
	if config.slotId then
		frame:SetAttribute("EquipSlot", config.slotId)
	end
	if config.index then
		frame:SetAttribute("InvIndex", config.index)
	end
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

	local countLabel = Instance.new("TextLabel")
	countLabel.Name = "Count"
	countLabel.Size = UDim2.new(1, -4, 0, 14)
	countLabel.Position = UDim2.new(0, 2, 1, -16)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = ""
	countLabel.TextColor3 = COLORS.text
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextSize = 10
	countLabel.TextXAlignment = Enum.TextXAlignment.Right
	countLabel.Visible = false
	countLabel.ZIndex = 2
	countLabel.Parent = frame

	local slotData = {
		frame = frame,
		icon = icon,
		countLabel = countLabel,
		stroke = stroke,
		config = config,
		entry = nil,
	}

	frame.MouseEnter:Connect(function()
		stroke.Color = COLORS.border
		frame.BackgroundColor3 = COLORS.slotHover
		self:_scheduleTooltip(slotData)
	end)

	frame.MouseLeave:Connect(function()
		stroke.Color = COLORS.borderDim
		frame.BackgroundColor3 = slotData.entry and COLORS.slot or COLORS.slotEmpty
		self:_hideTooltip()
	end)

	frame.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:_showContextMenu(slotData)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			if self._enhanceMode and slotData.entry then
				local item = Items[slotData.entry.id]
				if item and item.category == "scrolls" then
					self._enhanceScrollId = slotData.entry.id
					self._enhanceLabel.Text = "Scroll: " .. item.name .. " — click Apply"
					return
				end
			end
			self:_beginDrag(slotData, input)
		end
	end)

	return slotData
end

function InventoryEquipmentUI:_bindDragInput()
	local function endDrag(input)
		if not self._drag or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local drag = self._drag
		self._drag = nil
		self._dragGhost.Visible = false

		local pos = UserInputService:GetMouseLocation()
		local guiInset = game:GetService("GuiService"):GetGuiInset()
		local hitPos = Vector2.new(pos.X, pos.Y - guiInset.Y)
		local hits = Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(hitPos.X, hitPos.Y)

		local targetSlot = nil
		for _, obj in hits do
			if obj:IsA("GuiObject") and obj:GetAttribute("SlotKind") then
				local kind = obj:GetAttribute("SlotKind")
				if kind == "equipment" then
					targetSlot = self._equipSlots[obj:GetAttribute("EquipSlot")]
					break
				elseif kind == "inventory" then
					targetSlot = self._inventorySlots[obj:GetAttribute("InvIndex")]
					break
				end
			end
		end

		if targetSlot and targetSlot ~= drag.source and self._callbacks.onDragDrop then
			self._callbacks.onDragDrop(drag.source, targetSlot)
		end
	end

	UserInputService.InputEnded:Connect(endDrag)
	RunService.RenderStepped:Connect(function()
		if not self._drag then
			return
		end
		local pos = UserInputService:GetMouseLocation()
		local guiInset = game:GetService("GuiService"):GetGuiInset()
		self._dragGhost.Position = UDim2.fromOffset(pos.X - SLOT_SIZE / 2, pos.Y - guiInset.Y - SLOT_SIZE / 2)
	end)
end

function InventoryEquipmentUI:_beginDrag(slotData, input)
	if self._enhanceMode then
		return
	end
	if not slotData.entry then
		return
	end
	self:HideContextMenu()
	self._drag = { source = slotData, input = input }
	local item = Items[slotData.entry.id]
	self._dragIcon.BackgroundColor3 = getItemColor(item, slotData.entry)
	self._dragGhost.BackgroundColor3 = COLORS.slotDrag
	self._dragGhost.Visible = true
end

function InventoryEquipmentUI:_scheduleTooltip(slotData)
	self._hoverToken += 1
	local token = self._hoverToken
	task.delay(0.15, function()
		if token ~= self._hoverToken then
			return
		end
		self:_showTooltip(slotData)
	end)
end

function InventoryEquipmentUI:_hideTooltip()
	self._hoverToken += 1
	self._tooltip.Visible = false
end

function InventoryEquipmentUI:_buildTooltipText(slotData)
	if slotData.config.kind == "equipment" and not slotData.entry then
		local slotId = slotData.config.slotId
		return EquipmentSlots.LABELS[slotId] or slotId, "Empty slot — drag gear here to equip."
	end
	if not slotData.entry then
		return "Empty", "Drag items here or pick up loot."
	end

	local entry = slotData.entry
	local item = Items[entry.id]
	if not item then
		return "Unknown", ""
	end

	local title = formatItemName(item, entry)
	if entry.rarity and item.slot then
		title = "[" .. entry.rarity .. "] " .. title
	end

	local lines = { item.description or "" }
	if item.slot then
		table.insert(lines, "Slot: " .. (EquipmentSlots.LABELS[item.slot] or item.slot))
	end
	if entry.rarity then
		table.insert(lines, "Rarity: " .. entry.rarity)
	end
	if entry.enhanceLevel and entry.enhanceLevel > 0 then
		table.insert(lines, "Enhancement: +" .. entry.enhanceLevel)
		if entry.enhancementBonuses then
			for stat, value in pairs(entry.enhancementBonuses) do
				table.insert(lines, "Bonus: " .. formatStatBonus(stat, value))
			end
		else
			local bonus = entry.enhanceLevel * EnhancementConfig.STAT_BONUS_PER_LEVEL
			table.insert(lines, "Bonus: +" .. bonus .. " stats")
		end
	end
	if item.damage then
		table.insert(lines, "Damage: " .. item.damage)
	end
	if item.type then
		table.insert(lines, "Type: " .. item.type)
	end

	return title, table.concat(lines, "\n")
end

function InventoryEquipmentUI:_showTooltip(slotData)
	local title, body = self:_buildTooltipText(slotData)
	self._tooltipTitle.Text = title
	self._tooltipBody.Text = body

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

function InventoryEquipmentUI:HideContextMenu()
	self._contextMenu.Visible = false
	for _, child in self._contextMenu:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

function InventoryEquipmentUI:_showContextMenu(slotData)
	self:HideContextMenu()
	self:_hideTooltip()
	local options = {}

	if slotData.entry then
		local item = Items[slotData.entry.id]
		if item then
			if item.usable and self._callbacks.onUse then
				table.insert(options, { label = "Use", action = "use" })
			end
			if item.slot and slotData.config.kind == "inventory" and self._callbacks.onEquip then
				table.insert(options, { label = "Equip", action = "equip" })
			end
			if slotData.config.kind == "equipment" and self._callbacks.onUnequip then
				table.insert(options, { label = "Unequip", action = "unequip" })
			end
			if item.slot and self._callbacks.onEnhance then
				table.insert(options, { label = "Enhance", action = "enhance" })
			end
			if self._callbacks.onCraft and (item.slot or item.category == "materials" or item.category == "potions" or item.type == "consumable") then
				table.insert(options, { label = "Craft", action = "craft" })
			end
			if self._callbacks.onDropItem then
				table.insert(options, { label = "Drop", action = "dropItem", danger = true })
			end
		end
	end

	if #options == 0 then
		return
	end

	for _, opt in options do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -8, 0, 28)
		btn.BackgroundColor3 = opt.danger and COLORS.danger or COLORS.slot
		btn.Text = opt.label
		btn.TextColor3 = COLORS.text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.ZIndex = 101
		btn.Active = true
		btn.AutoButtonColor = true
		btn.Parent = self._contextMenu
		addCorner(btn, 4)
		btn.Activated:Connect(function()
			local cbKey = ACTION_CALLBACKS[opt.action]
			local cb = cbKey and self._callbacks[cbKey]
			if cb then
				cb(slotData)
			end
			self:HideContextMenu()
		end)
	end

	self._contextMenu.Size = UDim2.fromOffset(150, #options * 30 + 8)

	local pos = UserInputService:GetMouseLocation()
	local guiInset = game:GetService("GuiService"):GetGuiInset()
	local x = pos.X
	local y = pos.Y - guiInset.Y
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	if x + 150 > vp.X then
		x = pos.X - 150
	end
	if y + self._contextMenu.AbsoluteSize.Y > vp.Y then
		y = pos.Y - guiInset.Y - self._contextMenu.AbsoluteSize.Y
	end
	self._contextMenu.Position = UDim2.fromOffset(x, y)
	self._contextMenu.Visible = true
end

function InventoryEquipmentUI:_getFilteredInventory()
	local filtered = {}
	for _, entry in self._inventory do
		local item = Items[entry.id]
		if item and matchesCategoryFilter(item, self._categoryFilter) and matchesRarityFilter(entry, self._rarityFilter) then
			table.insert(filtered, entry)
		end
	end
	return filtered
end

function InventoryEquipmentUI:_getGridEntries()
	local flat = self:_getFilteredInventory()
	local gridEntries = {}
	for i = 1, MAX_INVENTORY_SLOTS do
		gridEntries[i] = flat[i]
	end
	return gridEntries, #flat
end

function InventoryEquipmentUI:SetCategoryFilter(filterId)
	self._categoryFilter = filterId
	for id, btn in self._filterButtons do
		btn.BackgroundColor3 = id == filterId and COLORS.accent or COLORS.slot
	end
	self:Refresh()
end

function InventoryEquipmentUI:SetRarityFilter(rarityId)
	self._rarityFilter = rarityId
	local label = rarityId == "all" and "All" or rarityId
	self._rarityButton.Text = "Rarity: " .. label .. " ▾"
	self:Refresh()
end

function InventoryEquipmentUI:_updateFilterInfo(totalCount)
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

function InventoryEquipmentUI:_renderSlot(slotData, entry)
	slotData.entry = entry
	local frame = slotData.frame
	local icon = slotData.icon
	local countLabel = slotData.countLabel

	if not entry then
		icon.Visible = false
		countLabel.Visible = false
		frame.BackgroundColor3 = COLORS.slotEmpty
		if slotData.config.kind == "equipment" then
			frame.Text = slotData.config.label or ""
		else
			frame.Text = ""
		end
		return
	end

	local item = Items[entry.id]
	if not item then
		return
	end

	frame.Text = ""
	frame.BackgroundColor3 = COLORS.slot
	icon.BackgroundColor3 = getItemColor(item, entry)
	icon.Visible = true

	if entry.count and entry.count > 1 then
		countLabel.Text = tostring(entry.count)
		countLabel.Visible = true
	else
		countLabel.Visible = false
	end
end

function InventoryEquipmentUI:Refresh()
	local gridEntries, totalCount = self:_getGridEntries()
	self:_updateFilterInfo(totalCount)

	for idx, slotData in self._inventorySlots do
		self:_renderSlot(slotData, gridEntries[idx])
	end

	for slotId, slotData in self._equipSlots do
		local equippedEntry = self._equipped[slotId]
		if type(equippedEntry) == "table" then
			self:_renderSlot(slotData, equippedEntry)
		else
			self:_renderSlot(slotData, nil)
		end
	end
end

function InventoryEquipmentUI:SetInventory(inventory)
	self._inventory = inventory or {}
	if self._visible then
		self:Refresh()
	end
end

function InventoryEquipmentUI:SetEquipped(equipped)
	self._equipped = equipped or {}
	if self._visible then
		self:Refresh()
	end
end

function InventoryEquipmentUI:SetVisible(visible)
	self._visible = visible
	self._overlay.Visible = visible
	self._root.Visible = visible
	if self._enhanceBar and not visible then
		self._enhanceBar.Visible = false
	end
	if not visible then
		self:HideContextMenu()
		self:_hideTooltip()
		self._drag = nil
		self._dragGhost.Visible = false
		if self._enhanceBar then
			self._enhanceBar.Visible = false
		end
	else
		self:Refresh()
	end
end

function InventoryEquipmentUI:IsVisible()
	return self._visible
end

function InventoryEquipmentUI:OnUse(cb)
	self._callbacks.onUse = cb
end

function InventoryEquipmentUI:OnEquip(cb)
	self._callbacks.onEquip = cb
end

function InventoryEquipmentUI:OnUnequip(cb)
	self._callbacks.onUnequip = cb
end

function InventoryEquipmentUI:OnCraft(cb)
	self._callbacks.onCraft = cb
end

function InventoryEquipmentUI:OnDropItem(cb)
	self._callbacks.onDropItem = cb
end

function InventoryEquipmentUI:OnEnhance(cb)
	self._callbacks.onEnhance = cb
end

function InventoryEquipmentUI:OnDragDrop(cb)
	self._callbacks.onDragDrop = cb
end

function InventoryEquipmentUI:GetScreenGui()
	return self._screenGui
end

function InventoryEquipmentUI:OnEnhanceApply(cb)
	self._callbacks.onEnhanceApply = cb
end

function InventoryEquipmentUI:OnEnhanceCancel(cb)
	self._callbacks.onEnhanceCancel = cb
end
function InventoryEquipmentUI:SetEnhanceMode(active, targetUid, scrollId)
	self._enhanceMode = active == true
	self._enhanceTargetUid = targetUid
	self._enhanceScrollId = scrollId
	if self._enhanceBar then
		self._enhanceBar.Visible = self._enhanceMode and self._visible
	end
	if self._enhanceMode and targetUid then
		self._enhanceLabel.Text = "Enhance: pick a scroll for target item"
	end
	if self._visible then
		self:Refresh()
	end
end

return InventoryEquipmentUI
