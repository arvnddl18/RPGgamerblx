local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local RarityConfig = require(Shared.Config.RarityConfig)
local CraftingConfig = require(Shared.Config.CraftingConfig)
local EquipmentSlots = require(Shared.Config.EquipmentSlots)

local CraftingUI = {}
CraftingUI.__index = CraftingUI

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
	if not item or not entry then return "Unknown" end
	local name = item.name
	if entry.count and entry.count > 1 then name ..= " x" .. entry.count end
	if entry.enhanceLevel and entry.enhanceLevel > 0 then name ..= " +" .. entry.enhanceLevel end
	return name
end

local function getItemColor(item, entry)
	if entry and entry.rarity and item and item.slot then
		return RarityConfig.GetColor(entry.rarity)
	end
	return item and item.color or COLORS.slot
end

local function matchesCategoryFilter(item, filterId)
	if filterId == "all" then return true end
	if not item then return false end
	for _, filter in CATEGORY_FILTERS do
		if filter.id == filterId then
			if filter.slot then return item.slot == filter.slot end
			if filter.category then return item.category == filter.category or item.type == "material" end
			if filter.consumable then
				return item.usable == true or item.category == "potions" or item.type == "consumable"
			end
			return false
		end
	end
	return true
end

local function matchesRarityFilter(entry, rarityFilter)
	if rarityFilter == "all" then return true end
	return (entry.rarity or "Common") == rarityFilter
end

function CraftingUI.new(playerGui)
	local self = setmetatable({}, CraftingUI)
	self._playerGui = playerGui
	self._recipes = {}
	self._inventory = {}
	self._equipped = {}
	self._classId = nil
	self._onCraft = nil
	self._onUpgrade = nil
	self._activeTab = "upgrade"
	self._selectedRecipe = nil
	self._selectedTargetUid = nil
	self._busy = false
	self._visible = false
	self._drag = nil

	self._categoryFilter = "all"
	self._rarityFilter = "all"

	self._screenGui = Instance.new("ScreenGui")
	self._screenGui.Name = "CraftingUI"
	self._screenGui.ResetOnSpawn = false
	self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self._screenGui.DisplayOrder = 101
	self._screenGui.Parent = playerGui

	self._overlay = Instance.new("TextButton")
	self._overlay.Size = UDim2.fromScale(1, 1)
	self._overlay.BackgroundColor3 = COLORS.overlay
	self._overlay.BackgroundTransparency = 0.45
	self._overlay.Text = ""
	self._overlay.AutoButtonColor = false
	self._overlay.Visible = false
	self._overlay.Parent = self._screenGui

	self._root = Instance.new("Frame")
	self._root.Name = "Root"
	self._root.AnchorPoint = Vector2.new(0.5, 0.5)
	self._root.Position = UDim2.fromScale(0.5, 0.5)
	self._root.Size = UDim2.fromScale(0.94, 0.90)
	self._root.BackgroundColor3 = COLORS.panel
	self._root.BorderSizePixel = 0
	self._root.Active = true
	self._root.Visible = false
	self._root.Parent = self._screenGui
	addCorner(self._root, 10)
	addStroke(self._root, COLORS.border, 2)
	local rootConstraint = Instance.new("UISizeConstraint")
	rootConstraint.MinSize = Vector2.new(760, 500)
	rootConstraint.MaxSize = Vector2.new(1500, 900)
	rootConstraint.Parent = self._root
	self._currentGold = Instance.new("TextLabel")
	self._currentGold.Name = "CurrentGold"
	self._currentGold.Size = UDim2.fromOffset(140, 28)
	self._currentGold.Position = UDim2.new(1, -190, 0, 10)
	self._currentGold.BackgroundTransparency = 1
	self._currentGold.Text = "GOLD: 0"
	self._currentGold.TextColor3 = Color3.fromRGB(255, 210, 80)
	self._currentGold.Font = Enum.Font.GothamBold
	self._currentGold.TextSize = 14
	self._currentGold.TextXAlignment = Enum.TextXAlignment.Right
	self._currentGold.ZIndex = 11
	self._currentGold.Parent = self._root

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
	self._closeBtn.MouseButton1Click:Connect(function() self:SetVisible(false) end)
	self._overlay.MouseButton1Click:Connect(function()
		local mouse = UserInputService:GetMouseLocation()
		local inset = GuiService:GetGuiInset()
		local point = Vector2.new(mouse.X, mouse.Y - inset.Y)
		local position, size = self._root.AbsolutePosition, self._root.AbsoluteSize
		local insideRoot = point.X >= position.X and point.X <= position.X + size.X and point.Y >= position.Y and point.Y <= position.Y + size.Y
		if not insideRoot then self:SetVisible(false) end
	end)

	-- Inventory Panel (Left)
	self._inventoryPanel = Instance.new("Frame")
	self._inventoryPanel.Name = "InventoryPanel"
	self._inventoryPanel.Size = UDim2.new(0.42, -12, 1, -24)
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
	self._rarityDropdown.Size = UDim2.new(0, 130, 0, 28)
	self._rarityDropdown.Position = UDim2.new(1, -142, 0, 8)
	self._rarityDropdown.BackgroundColor3 = COLORS.slot
	self._rarityDropdown.ZIndex = 100
	self._rarityDropdown.Active = true
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
	self._rarityButton.ZIndex = 101
	self._rarityButton.Parent = self._rarityDropdown

	self._rarityList = Instance.new("Frame")
	self._rarityList.Size = UDim2.new(1, 0, 0, #RARITY_OPTIONS * 26 + 4)
	self._rarityList.Position = UDim2.new(0, 0, 1, 4)
	self._rarityList.BackgroundColor3 = Color3.fromRGB(18, 15, 12)
	self._rarityList.Visible = false
	self._rarityList.ZIndex = 102
	self._rarityList.Active = true
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
		opt.ZIndex = 103
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
	filterLayout.SortOrder = Enum.SortOrder.LayoutOrder
	filterLayout.Padding = UDim.new(0, 2)
	filterLayout.Parent = self._filterBar

	self._filterButtons = {}
	for filterIndex, filter in CATEGORY_FILTERS do
		local btn = Instance.new("TextButton")
		btn.LayoutOrder = filterIndex
		btn.Size = UDim2.fromOffset(math.max(48, #filter.label * 6 + 10), 24)
		btn.BackgroundColor3 = filter.id == "all" and COLORS.accent or COLORS.slot
		btn.Text = filter.label
		btn.TextColor3 = COLORS.text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 10
		btn.Parent = self._filterBar
		addCorner(btn, 4)
		self._filterButtons[filter.id] = btn
		btn.MouseButton1Click:Connect(function() self:SetCategoryFilter(filter.id) end)
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
	self._filterInfo.TextColor3 = COLORS.textDim
	self._filterInfo.Font = Enum.Font.Gotham
	self._filterInfo.TextSize = 10
	self._filterInfo.TextXAlignment = Enum.TextXAlignment.Left
	self._filterInfo.Parent = self._inventoryPanel

	self._gridFrame = Instance.new("ScrollingFrame")
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
		local slot = self:_createSlot(self._gridFrame, { kind = "inventory", index = idx })
		slot.frame.LayoutOrder = idx
		self._inventorySlots[idx] = slot
	end

	-- Crafting Panel (Right)
	self._craftPanel = Instance.new("Frame")
	self._craftPanel.Name = "CraftPanel"
	self._craftPanel.Size = UDim2.new(0.58, -12, 1, -24)
	self._craftPanel.Position = UDim2.new(0.42, 0, 0, 12)
	self._craftPanel.BackgroundColor3 = COLORS.panelInner
	self._craftPanel.BorderSizePixel = 0
	self._craftPanel.Parent = self._root
	addCorner(self._craftPanel, 8)
	addStroke(self._craftPanel, COLORS.borderDim)

	local craftTitle = Instance.new("TextLabel")
	craftTitle.Size = UDim2.new(1, -20, 0, 28)
	craftTitle.Position = UDim2.new(0, 12, 0, 8)
	craftTitle.BackgroundTransparency = 1
	craftTitle.Text = "CRAFTING"
	craftTitle.TextColor3 = COLORS.text
	craftTitle.Font = Enum.Font.GothamBold
	craftTitle.TextSize = 18
	craftTitle.TextXAlignment = Enum.TextXAlignment.Left
	craftTitle.Parent = self._craftPanel

	self._tabBar = Instance.new("Frame")
	self._tabBar.Size = UDim2.new(1, -24, 0, 32)
	self._tabBar.Position = UDim2.new(0, 12, 0, 44)
	self._tabBar.BackgroundTransparency = 1
	self._tabBar.Parent = self._craftPanel
	
	self._tabButtons = {}
	for i, tabId in { "upgrade", "potions" } do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.5, -4, 1, 0)
		btn.Position = UDim2.new((i - 1) * 0.5, (i - 1) * 4, 0, 0)
		btn.BackgroundColor3 = tabId == self._activeTab and COLORS.accent or COLORS.slot
		btn.Text = tabId == "upgrade" and "Equipment Upgrade" or "Potions & Materials"
		btn.TextColor3 = COLORS.text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.Parent = self._tabBar
		addCorner(btn, 6)
		btn.MouseButton1Click:Connect(function() self:SetTab(tabId) end)
		self._tabButtons[tabId] = btn
	end

	-- Split inside Crafting Panel: Left = Recipe List, Right = Details
	self._recipePanel = Instance.new("Frame")
	self._recipePanel.Size = UDim2.new(0.4, -6, 1, -92)
	self._recipePanel.Position = UDim2.new(0, 12, 0, 84)
	self._recipePanel.BackgroundColor3 = Color3.fromRGB(20, 16, 12)
	self._recipePanel.BorderSizePixel = 0
	self._recipePanel.Parent = self._craftPanel
	addCorner(self._recipePanel, 6)
	addStroke(self._recipePanel, COLORS.borderDim)

	self._recipeList = Instance.new("ScrollingFrame")
	self._recipeList.Size = UDim2.new(1, -8, 1, -8)
	self._recipeList.Position = UDim2.new(0, 4, 0, 4)
	self._recipeList.BackgroundTransparency = 1
	self._recipeList.BorderSizePixel = 0
	self._recipeList.ScrollBarThickness = 4
	self._recipeList.Parent = self._recipePanel
	local recLayout = Instance.new("UIGridLayout")
	recLayout.CellSize = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
	recLayout.CellPadding = UDim2.fromOffset(SLOT_PAD, SLOT_PAD)
	recLayout.SortOrder = Enum.SortOrder.LayoutOrder
	recLayout.Parent = self._recipeList

	self._detailsPanel = Instance.new("Frame")
	self._detailsPanel.Size = UDim2.new(0.6, -6, 1, -92)
	self._detailsPanel.Position = UDim2.new(0.4, 12, 0, 84)
	self._detailsPanel.BackgroundColor3 = Color3.fromRGB(20, 16, 12)
	self._detailsPanel.BorderSizePixel = 0
	self._detailsPanel.Parent = self._craftPanel
	addCorner(self._detailsPanel, 6)
	addStroke(self._detailsPanel, COLORS.borderDim)

	self._targetSlot = Instance.new("Frame")
	self._targetSlot.Size = UDim2.fromOffset(80, 80)
	self._targetSlot.AnchorPoint = Vector2.new(0.5, 0)
	self._targetSlot.Position = UDim2.new(0.5, 0, 0, 20)
	self._targetSlot.BackgroundColor3 = COLORS.slotEmpty
	self._targetSlot.Parent = self._detailsPanel
	addCorner(self._targetSlot, 8)
	addStroke(self._targetSlot, COLORS.border)
	
	self._targetIcon = Instance.new("Frame")
	self._targetIcon.Size = UDim2.fromScale(0.7, 0.7)
	self._targetIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	self._targetIcon.Position = UDim2.fromScale(0.5, 0.5)
	self._targetIcon.Visible = false
	self._targetIcon.Parent = self._targetSlot
	addCorner(self._targetIcon, 6)

	self._targetLabel = Instance.new("TextLabel")
	self._targetLabel.Size = UDim2.new(1, -20, 0, 20)
	self._targetLabel.Position = UDim2.new(0, 10, 0, 110)
	self._targetLabel.BackgroundTransparency = 1
	self._targetLabel.Text = "Select recipe or drop item"
	self._targetLabel.TextColor3 = COLORS.text
	self._targetLabel.Font = Enum.Font.GothamBold
	self._targetLabel.TextSize = 14
	self._targetLabel.Parent = self._detailsPanel

	self._requirementsLabel = Instance.new("TextLabel")
	self._requirementsLabel.Size = UDim2.new(1, -20, 0, 20)
	self._requirementsLabel.Position = UDim2.new(0, 10, 0, 140)
	self._requirementsLabel.BackgroundTransparency = 1
	self._requirementsLabel.Text = "Requirements"
	self._requirementsLabel.TextColor3 = COLORS.textDim
	self._requirementsLabel.Font = Enum.Font.Gotham
	self._requirementsLabel.TextSize = 12
	self._requirementsLabel.TextXAlignment = Enum.TextXAlignment.Left
	self._requirementsLabel.Parent = self._detailsPanel

	self._matList = Instance.new("Frame")
	self._matList.Size = UDim2.new(1, -20, 0, 100)
	self._matList.Position = UDim2.new(0, 10, 0, 160)
	self._matList.BackgroundTransparency = 1
	self._matList.Parent = self._detailsPanel
	local matLayout = Instance.new("UIGridLayout")
	matLayout.CellSize = UDim2.new(0.5, -4, 0, 36)
	matLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	matLayout.SortOrder = Enum.SortOrder.LayoutOrder
	matLayout.Parent = self._matList

	self._statsLabel = Instance.new("TextLabel")
	self._statsLabel.Size = UDim2.new(1, -20, 0, 40)
	self._statsLabel.Position = UDim2.new(0, 10, 1, -120)
	self._statsLabel.BackgroundTransparency = 1
	self._statsLabel.Text = ""
	self._statsLabel.TextColor3 = COLORS.text
	self._statsLabel.Font = Enum.Font.Gotham
	self._statsLabel.TextSize = 12
	self._statsLabel.TextXAlignment = Enum.TextXAlignment.Center
	self._statsLabel.Parent = self._detailsPanel

	self._confirmBtn = Instance.new("TextButton")
	self._confirmBtn.Size = UDim2.new(0.8, 0, 0, 40)
	self._confirmBtn.AnchorPoint = Vector2.new(0.5, 1)
	self._confirmBtn.Position = UDim2.new(0.5, 0, 1, -20)
	self._confirmBtn.BackgroundColor3 = COLORS.success
	self._confirmBtn.Text = "Confirm"
	self._confirmBtn.TextColor3 = COLORS.text
	self._confirmBtn.Font = Enum.Font.GothamBold
	self._confirmBtn.TextSize = 16
	self._confirmBtn.Parent = self._detailsPanel
	addCorner(self._confirmBtn, 6)
	self._confirmBtn.MouseButton1Click:Connect(function()
		if self._busy then return end
		if self._activeTab == "potions" and self._selectedRecipe and self._onCraft then
			self:SetBusy(true)
			self._onCraft(self._selectedRecipe.id)
		elseif self._activeTab == "upgrade" and self._selectedRecipe and self._selectedTargetUid and self._onUpgrade then
			self:SetBusy(true)
			self._onUpgrade(self._selectedRecipe.id, self._selectedTargetUid)
		end
	end)

	self._dragGhost = Instance.new("Frame")
	self._dragGhost.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
	self._dragGhost.BackgroundTransparency = 0.3
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

	self:_bindInput()
	return self
end

function CraftingUI:_createSlot(parent, config)
	local frame = Instance.new("TextButton")
	frame.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
	frame.BackgroundColor3 = COLORS.slotEmpty
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.Parent = parent
	addCorner(frame, 5)
	local stroke = addStroke(frame, COLORS.borderDim, 1)

	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromScale(0.72, 0.72)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.BackgroundColor3 = COLORS.slot
	icon.Visible = false
	icon.Parent = frame
	addCorner(icon, 4)

	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, -4, 0, 14)
	countLabel.Position = UDim2.new(0, 2, 1, -16)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = ""
	countLabel.TextColor3 = COLORS.text
	countLabel.Font = Enum.Font.GothamBold
	countLabel.TextSize = 10
	countLabel.TextXAlignment = Enum.TextXAlignment.Right
	countLabel.TextStrokeTransparency = 0.45
	countLabel.Visible = false
	countLabel.ZIndex = 4
	countLabel.Parent = frame

	local slotData = { frame = frame, icon = icon, countLabel = countLabel, config = config }

	frame.MouseEnter:Connect(function()
		stroke.Color = COLORS.border
		frame.BackgroundColor3 = COLORS.slotHover
	end)
	frame.MouseLeave:Connect(function()
		stroke.Color = COLORS.borderDim
		frame.BackgroundColor3 = slotData.entry and COLORS.slot or COLORS.slotEmpty
	end)
	frame.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if config.onClick then
				config.onClick(slotData)
			elseif slotData.entry then
				-- Left click selects target item
				self:_selectTargetItem(slotData.entry)
				self:_beginDrag(slotData, input)
			end
		end
	end)
	return slotData
end

function CraftingUI:_bindInput()
	UserInputService.InputEnded:Connect(function(input)
		if not self._drag or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local drag = self._drag
		self._drag = nil
		self._dragGhost.Visible = false

		local pos = UserInputService:GetMouseLocation()
		local guiInset = game:GetService("GuiService"):GetGuiInset()
		local hitPos = Vector2.new(pos.X, pos.Y - guiInset.Y)
		local hits = self._playerGui:GetGuiObjectsAtPosition(hitPos.X, hitPos.Y)

		for _, obj in hits do
			if obj == self._targetSlot or obj:IsDescendantOf(self._targetSlot) or obj == self._detailsPanel then
				self:_selectTargetItem(drag.source.entry)
				break
			end
		end
	end)
	RunService.RenderStepped:Connect(function()
		if not self._drag then return end
		local pos = UserInputService:GetMouseLocation()
		local guiInset = game:GetService("GuiService"):GetGuiInset()
		self._dragGhost.Position = UDim2.fromOffset(pos.X - SLOT_SIZE / 2, pos.Y - guiInset.Y - SLOT_SIZE / 2)
	end)
	UserInputService.InputBegan:Connect(function(input, gp)
		if not self._visible or gp then return end
		if input.KeyCode == Enum.KeyCode.Escape then
			self:SetVisible(false)
		end
	end)
end

function CraftingUI:_beginDrag(slotData, input)
	self._drag = { source = slotData, input = input }
	local item = Items[slotData.entry.id]
	self._dragIcon.BackgroundColor3 = getItemColor(item, slotData.entry)
	self._dragGhost.BackgroundColor3 = COLORS.slotDrag
	self._dragGhost.Visible = true
end

function CraftingUI:_selectTargetItem(entry)
	if self._activeTab ~= "upgrade" then return end
	local item = Items[entry.id]
	if not item then return end
	
	-- Try to match with an upgrade recipe
	local matchingRecipe = nil
	for _, recipe in self._recipes do
		if recipe.type == "equipmentUpgrade" and recipe.slot == item.slot then
			if not recipe.classRestriction or recipe.classRestriction == self._classId or item.classRestriction == recipe.classRestriction then
				matchingRecipe = recipe
				break
			end
		end
	end
	
	if matchingRecipe then
		self._selectedRecipe = matchingRecipe
		self._selectedTargetUid = entry.uid
		self:_updatePreview()
	end
end

function CraftingUI:SetTab(tabId)
	self._activeTab = tabId
	self._selectedRecipe = nil
	self._selectedTargetUid = nil
	for id, btn in self._tabButtons do
		btn.BackgroundColor3 = id == tabId and COLORS.accent or COLORS.slot
	end
	self:_renderCrafting()
end

function CraftingUI:SetCategoryFilter(filterId)
	self._categoryFilter = filterId
	for id, btn in self._filterButtons do
		btn.BackgroundColor3 = id == filterId and COLORS.accent or COLORS.slot
	end
	self:RefreshInventory()
end

function CraftingUI:SetRarityFilter(rarityId)
	self._rarityFilter = rarityId
	local label = rarityId == "all" and "All" or rarityId
	self._rarityButton.Text = "Rarity: " .. label .. " ▾"
	self:RefreshInventory()
end

function CraftingUI:_getFilteredInventory()
	local filtered = {}
	for _, entry in self._inventory do
		local item = Items[entry.id]
		if item and matchesCategoryFilter(item, self._categoryFilter) and matchesRarityFilter(entry, self._rarityFilter) then
			table.insert(filtered, entry)
		end
	end
	return filtered
end

function CraftingUI:_renderSlot(slotData, entry)
	slotData.entry = entry
	local frame, icon, countLabel = slotData.frame, slotData.icon, slotData.countLabel
	if not entry then
		icon.Visible = false
		countLabel.Visible = false
		frame.BackgroundColor3 = COLORS.slotEmpty
		return
	end
	local item = Items[entry.id]
	if not item then return end
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

function CraftingUI:RefreshInventory()
	local flat = self:_getFilteredInventory()
	self._filterInfo.Text = #flat .. " items"
	for idx, slotData in self._inventorySlots do
		self:_renderSlot(slotData, flat[idx])
	end
end

function CraftingUI:_renderCrafting()
	for _, child in self._recipeList:GetChildren() do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local layoutOrder = 1
	if self._activeTab == "upgrade" then
		local allItems = {}
		for _, entry in self._inventory do table.insert(allItems, entry) end
		for _, entry in pairs(self._equipped) do table.insert(allItems, entry) end

		for _, entry in allItems do
			local item = Items[entry.id]
			if not item or not item.slot then continue end
			
			local matchingRecipe = nil
			for _, recipe in self._recipes do
				if recipe.type == "equipmentUpgrade" and (not recipe.slot or recipe.slot == item.slot) then
					if not recipe.classRestriction or recipe.classRestriction == self._classId or item.classRestriction == recipe.classRestriction then
						matchingRecipe = recipe
						break
					end
				end
			end
			
			if matchingRecipe then
				local currentRarity = entry.rarity or "Common"
				local nextRarity = RarityConfig.GetNextRarity(currentRarity)
				if nextRarity then
					local slot = self:_createSlot(self._recipeList, {
						kind = "recipe",
						onClick = function()
							self._selectedRecipe = matchingRecipe
							self._selectedTargetUid = entry.uid
							self:_renderCrafting()
						end
					})
					slot.frame.LayoutOrder = layoutOrder
					layoutOrder += 1
					
					-- Show it as selected if it's the current target
					if self._selectedTargetUid == entry.uid then
						slot.frame.BackgroundColor3 = COLORS.accent
					end
					
					local virtualEntry = { id = entry.id, rarity = nextRarity, count = 1 }
					self:_renderSlot(slot, virtualEntry)
					
					-- Keep selection visual
					if self._selectedTargetUid == entry.uid then
						slot.frame.BackgroundColor3 = COLORS.accent
					end
				end
			end
		end
	elseif self._activeTab == "potions" then
		for _, recipe in self._recipes do
			if recipe.type ~= "consumable" then continue end
			
			local slot = self:_createSlot(self._recipeList, {
				kind = "recipe",
				onClick = function()
					self._selectedRecipe = recipe
					self._selectedTargetUid = nil
					self:_renderCrafting()
				end
			})
			slot.frame.LayoutOrder = layoutOrder
			layoutOrder += 1
			
			if self._selectedRecipe == recipe then
				slot.frame.BackgroundColor3 = COLORS.accent
			end
			
			local virtualEntry = { id = recipe.resultItem, count = recipe.resultAmount or 1 }
			self:_renderSlot(slot, virtualEntry)
			
			if self._selectedRecipe == recipe then
				slot.frame.BackgroundColor3 = COLORS.accent
			end
		end
	end

	task.defer(function()
		local layout = self._recipeList:FindFirstChildOfClass("UIGridLayout")
		if layout then self._recipeList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8) end
	end)
	self:_updatePreview()
end

function CraftingUI:_updatePreview()
	for _, child in self._matList:GetChildren() do
		if child:IsA("Frame") then child:Destroy() end
	end

	if not self._selectedRecipe then
		self._targetIcon.Visible = false
		self._targetSlot.BackgroundColor3 = COLORS.slotEmpty
		self._targetLabel.Text = "Select recipe or drop item"
		self._statsLabel.Text = ""
		self._confirmBtn.BackgroundColor3 = COLORS.slotEmpty
		self._confirmBtn.Text = "Confirm"
		return
	end

	if self._activeTab == "potions" then
		local resItem = Items[self._selectedRecipe.resultItem]
		if resItem then
			self._targetIcon.BackgroundColor3 = resItem.color
			self._targetIcon.Visible = true
			self._targetSlot.BackgroundColor3 = COLORS.slot
			self._targetLabel.Text = resItem.name .. " x" .. (self._selectedRecipe.resultAmount or 1)
		end
		self._statsLabel.Text = "100% Success\nNo destroy risk"
		self:_renderMaterials(self._selectedRecipe.materials)
		self._confirmBtn.BackgroundColor3 = COLORS.success
		self._confirmBtn.Text = "Craft"
		return
	end

	if self._activeTab == "upgrade" then
		if not self._selectedTargetUid then
			self._targetIcon.Visible = false
			self._targetSlot.BackgroundColor3 = COLORS.slotEmpty
			self._targetLabel.Text = "Select an item to upgrade"
			self._statsLabel.Text = ""
			self._confirmBtn.BackgroundColor3 = COLORS.slotEmpty
			return
		end

		local targetEntry = nil
		for _, entry in self._inventory do
			if entry.uid == self._selectedTargetUid then
				targetEntry = entry
				break
			end
		end
		if not targetEntry then
			for _, entry in pairs(self._equipped) do
				if entry.uid == self._selectedTargetUid then
					targetEntry = entry
					break
				end
			end
		end
		if not targetEntry then
			self._selectedTargetUid = nil
			self:_updatePreview()
			return
		end
		local item = Items[targetEntry.id]
		local currentRarity = targetEntry.rarity or "Common"
		local targetRarity = RarityConfig.GetNextRarity(currentRarity)
		if not targetRarity then
			self._targetLabel.Text = formatItemName(item, targetEntry)
			self._targetLabel.TextColor3 = COLORS.text
			self._statsLabel.Text = "Already at Max Rarity"
			self._confirmBtn.BackgroundColor3 = COLORS.slotEmpty
			return
		end

		self._targetIcon.BackgroundColor3 = getItemColor(item, targetEntry)
		self._targetIcon.Visible = true
		self._targetSlot.BackgroundColor3 = COLORS.slot
		self._targetLabel.Text = string.format("[%s] %s", targetRarity, formatItemName(item, targetEntry))
		self._targetLabel.TextColor3 = RarityConfig.GetColor(targetRarity)

		local attempt = CraftingConfig.GetUpgradeAttempt(targetRarity)
		if attempt then
			local reqMats = {}
			for _, req in self._selectedRecipe.materials do
				table.insert(reqMats, { itemId = req.itemId, amount = attempt.materialAmount, minRarity = attempt.materialMinRarity })
			end
			self:_renderMaterials(reqMats, attempt.goldCost)
			self._statsLabel.Text = string.format("Success: %d%% | Fail: %d%% | Destroy: %d%%",
				attempt.success * 100, attempt.fail * 100, attempt.destroy * 100)
			self._confirmBtn.BackgroundColor3 = COLORS.success
			self._confirmBtn.Text = "Upgrade to " .. targetRarity
		end
	end
end

function CraftingUI:_countItems(itemId, minRarity)
	local count = 0
	local reqRank = RarityConfig.GetRank(minRarity or "Common")
	for _, entry in self._inventory do
		if entry.id == itemId then
			local r = RarityConfig.GetRank(entry.rarity or "Common")
			if r >= reqRank then
				count += (entry.count or 1)
			end
		end
	end
	return count
end

function CraftingUI:_renderMaterials(materials, goldCost)
	local layoutOrder = 1
	for _, req in materials do
		local item = Items[req.itemId]
		if not item then continue end

		local have = self:_countItems(req.itemId, req.minRarity)
		local need = req.amount or 1

		local matSlot = Instance.new("Frame")
		matSlot.BackgroundColor3 = COLORS.slot
		matSlot.LayoutOrder = layoutOrder
		matSlot.Parent = self._matList
		layoutOrder += 1
		addCorner(matSlot, 6)

		local icon = Instance.new("Frame")
		icon.Size = UDim2.fromOffset(28, 28)
		icon.Position = UDim2.fromOffset(4, 4)
		icon.BackgroundColor3 = RarityConfig.GetColor(req.minRarity or "Common")
		icon.Parent = matSlot
		addCorner(icon, 4)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -40, 0.5, 0)
		nameLabel.Position = UDim2.new(0, 36, 0, 0)
		nameLabel.BackgroundTransparency = 1
		local prefix = req.minRarity and (req.minRarity ~= "Common") and ("[" .. req.minRarity .. "] ") or ""
		nameLabel.Text = prefix .. item.name
		nameLabel.TextColor3 = COLORS.text
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 11
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = matSlot

		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(1, -40, 0.5, 0)
		countLabel.Position = UDim2.new(0, 36, 0.5, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = "Have: " .. have .. " / Need: " .. need
		countLabel.TextColor3 = have >= need and COLORS.textDim or COLORS.danger
		countLabel.Font = Enum.Font.Gotham
		countLabel.TextSize = 11
		countLabel.TextXAlignment = Enum.TextXAlignment.Left
		countLabel.Parent = matSlot
	end

	if goldCost and goldCost > 0 then
		local goldSlot = Instance.new("Frame")
		goldSlot.BackgroundColor3 = COLORS.slot
		goldSlot.LayoutOrder = layoutOrder
		goldSlot.Parent = self._matList
		addCorner(goldSlot, 6)

		local icon = Instance.new("Frame")
		icon.Size = UDim2.fromOffset(28, 28)
		icon.Position = UDim2.fromOffset(4, 4)
		icon.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		icon.Parent = goldSlot
		addCorner(icon, 4)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -40, 0.5, 0)
		nameLabel.Position = UDim2.new(0, 36, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "Gold"
		nameLabel.TextColor3 = COLORS.text
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 11
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = goldSlot

		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(1, -40, 0.5, 0)
		countLabel.Position = UDim2.new(0, 36, 0.5, 0)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = "Cost: " .. goldCost
		countLabel.TextColor3 = COLORS.textDim
		countLabel.Font = Enum.Font.Gotham
		countLabel.TextSize = 11
		countLabel.TextXAlignment = Enum.TextXAlignment.Left
		countLabel.Parent = goldSlot
	end
end

function CraftingUI:SetBusy(busy)
	self._busy = busy
	self._confirmBtn.Text = busy and "..." or "Confirm"
end

function CraftingUI:SetEquipped(equipped)
	self._equipped = equipped or {}
	if self._visible then
		self:_renderCrafting()
		self:_updatePreview()
	end
end

function CraftingUI:SetInventory(inventory)
	self._inventory = inventory or {}
	if self._visible then
		self:RefreshInventory()
		self:_renderCrafting()
	end
end

function CraftingUI:SetClassId(classId)
	self._classId = classId
	if self._visible then
		self:_renderCrafting()
	end
end

function CraftingUI:SetGold(amount)
	self._currentGold.Text = "GOLD: " .. tostring(math.max(0, math.floor(amount or 0)))
end

function CraftingUI:SetRecipes(recipes)
	self._recipes = recipes or {}
	if self._visible then
		self:_renderCrafting()
	end
end

function CraftingUI:SetVisible(visible)
	self._visible = visible
	self._overlay.Visible = visible
	self._root.Visible = visible
	if visible then
		self:RefreshInventory()
		self:_renderCrafting()
	else
		self._drag = nil
		self._dragGhost.Visible = false
	end
end

function CraftingUI:ApplyOpenContext(context)
	if not context then return end
	if context.tab then
		self:SetTab(context.tab)
	end
end

function CraftingUI:OnCraft(cb) self._onCraft = cb end
function CraftingUI:OnUpgrade(cb) self._onUpgrade = cb end

return CraftingUI
