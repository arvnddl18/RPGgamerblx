local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)

local QuestUI = {}
QuestUI.__index = QuestUI

local COLORS = {
	bg = Color3.fromRGB(15, 12, 10),
	overlay = Color3.fromRGB(0, 0, 0),
	panel = Color3.fromRGB(28, 22, 18),
	panelInner = Color3.fromRGB(36, 30, 24),
	border = Color3.fromRGB(180, 140, 55),
	borderDim = Color3.fromRGB(80, 65, 35),
	text = Color3.fromRGB(245, 235, 215),
	textDim = Color3.fromRGB(180, 170, 150),
	slot = Color3.fromRGB(35, 28, 23),
	slotEmpty = Color3.fromRGB(26, 21, 17),
	slotHover = Color3.fromRGB(50, 42, 34),
	slotSelected = Color3.fromRGB(60, 50, 40),
	accent = Color3.fromRGB(100, 150, 200),
	danger = Color3.fromRGB(180, 70, 60),
	success = Color3.fromRGB(85, 160, 100),
	locked = Color3.fromRGB(140, 60, 60),
	gold = Color3.fromRGB(255, 215, 65),
	exp = Color3.fromRGB(100, 200, 255),
}

local FONTS = {
	Header = Enum.Font.FredokaOne,
	Body = Enum.Font.Ubuntu,
	Bold = Enum.Font.GothamBold,
}

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.borderDim
	s.Thickness = thickness or 1.5
	s.Parent = parent
	return s
end

local function addGradient(parent, color1, color2)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2)
	})
	g.Rotation = 90
	g.Parent = parent
	return g
end

function QuestUI.new(playerGui)
	local self = setmetatable({}, QuestUI)
	
	self._quests = {}
	self._selectedIndex = nil
	self._mode = "log" -- "log" or "npc"
	
	self.OnAccept = nil
	self.OnTurnIn = nil

	-- ScreenGui
	self._screenGui = Instance.new("ScreenGui")
	self._screenGui.Name = "QuestUI"
	self._screenGui.ResetOnSpawn = false
	self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self._screenGui.DisplayOrder = 100
	self._screenGui.Parent = playerGui

	-- Overlay
	self._overlay = Instance.new("TextButton")
	self._overlay.Size = UDim2.fromScale(1, 1)
	self._overlay.BackgroundColor3 = COLORS.overlay
	self._overlay.BackgroundTransparency = 0.5
	self._overlay.Text = ""
	self._overlay.AutoButtonColor = false
	self._overlay.Visible = false
	self._overlay.Parent = self._screenGui

	-- Root Panel
	self._root = Instance.new("Frame")
	self._root.Name = "Root"
	self._root.AnchorPoint = Vector2.new(0.5, 0.5)
	self._root.Position = UDim2.fromScale(0.5, 0.5)
	self._root.Size = UDim2.fromScale(0.85, 0.85)
	self._root.BackgroundColor3 = COLORS.panel
	self._root.BorderSizePixel = 0
	self._root.Active = true
	self._root.Visible = false
	self._root.Parent = self._screenGui
	addCorner(self._root, 12)
	addStroke(self._root, COLORS.border, 3)
	
	-- Subtle background gradient for premium feel
	addGradient(self._root, Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))

	-- Close Button
	self._closeBtn = Instance.new("TextButton")
	self._closeBtn.Size = UDim2.new(0, 40, 0, 40)
	self._closeBtn.Position = UDim2.new(1, -50, 0, 10)
	self._closeBtn.BackgroundColor3 = COLORS.danger
	self._closeBtn.Text = "✕"
	self._closeBtn.TextColor3 = COLORS.text
	self._closeBtn.Font = FONTS.Header
	self._closeBtn.TextSize = 20
	self._closeBtn.ZIndex = 10
	self._closeBtn.Parent = self._root
	addCorner(self._closeBtn, 8)
	addStroke(self._closeBtn, Color3.fromRGB(100, 30, 20), 2)
	
	self._closeBtn.MouseEnter:Connect(function()
		TweenService:Create(self._closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 90, 80)}):Play()
	end)
	self._closeBtn.MouseLeave:Connect(function()
		TweenService:Create(self._closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.danger}):Play()
	end)
	
	self._closeBtn.MouseButton1Click:Connect(function() self:SetVisible(false) end)
	self._overlay.MouseButton1Click:Connect(function() self:SetVisible(false) end)

	-- LEFT PANEL: Quest List
	self._listPanel = Instance.new("Frame")
	self._listPanel.Name = "ListPanel"
	self._listPanel.Size = UDim2.new(0.35, -12, 1, -24)
	self._listPanel.Position = UDim2.new(0, 12, 0, 12)
	self._listPanel.BackgroundColor3 = COLORS.panelInner
	self._listPanel.BorderSizePixel = 0
	self._listPanel.Parent = self._root
	addCorner(self._listPanel, 10)
	addStroke(self._listPanel, COLORS.borderDim, 2)
	
	self._listTitle = Instance.new("TextLabel")
	self._listTitle.Size = UDim2.new(1, -24, 0, 40)
	self._listTitle.Position = UDim2.new(0, 12, 0, 12)
	self._listTitle.BackgroundTransparency = 1
	self._listTitle.Text = "📜 QUEST LOG"
	self._listTitle.TextColor3 = COLORS.gold
	self._listTitle.Font = FONTS.Header
	self._listTitle.TextSize = 22
	self._listTitle.TextXAlignment = Enum.TextXAlignment.Left
	self._listTitle.Parent = self._listPanel

	self._scrollList = Instance.new("ScrollingFrame")
	self._scrollList.Size = UDim2.new(1, -24, 1, -70)
	self._scrollList.Position = UDim2.new(0, 12, 0, 58)
	self._scrollList.BackgroundTransparency = 1
	self._scrollList.BorderSizePixel = 0
	self._scrollList.ScrollBarThickness = 8
	self._scrollList.ScrollBarImageColor3 = COLORS.gold
	self._scrollList.Parent = self._listPanel
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = self._scrollList
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self._scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 12)
	end)

	-- RIGHT PANEL: Details
	self._detailPanel = Instance.new("Frame")
	self._detailPanel.Name = "DetailPanel"
	self._detailPanel.Size = UDim2.new(0.65, -24, 1, -24)
	self._detailPanel.Position = UDim2.new(0.35, 12, 0, 12)
	self._detailPanel.BackgroundColor3 = COLORS.panelInner
	self._detailPanel.BorderSizePixel = 0
	self._detailPanel.Parent = self._root
	addCorner(self._detailPanel, 10)
	addStroke(self._detailPanel, COLORS.borderDim, 2)

	self._detailScroll = Instance.new("ScrollingFrame")
	self._detailScroll.Size = UDim2.new(1, -32, 1, -90)
	self._detailScroll.Position = UDim2.new(0, 16, 0, 16)
	self._detailScroll.BackgroundTransparency = 1
	self._detailScroll.BorderSizePixel = 0
	self._detailScroll.ScrollBarThickness = 8
	self._detailScroll.ScrollBarImageColor3 = COLORS.gold
	self._detailScroll.Parent = self._detailPanel

	local detailLayout = Instance.new("UIListLayout")
	detailLayout.Padding = UDim.new(0, 14)
	detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
	detailLayout.Parent = self._detailScroll
	detailLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self._detailScroll.CanvasSize = UDim2.new(0, 0, 0, detailLayout.AbsoluteContentSize.Y + 20)
	end)

	-- No Selection text
	self._noSelectionLabel = Instance.new("TextLabel")
	self._noSelectionLabel.Size = UDim2.new(1, 0, 1, 0)
	self._noSelectionLabel.BackgroundTransparency = 1
	self._noSelectionLabel.Text = "Select a quest to view details"
	self._noSelectionLabel.TextColor3 = COLORS.textDim
	self._noSelectionLabel.Font = FONTS.Body
	self._noSelectionLabel.TextSize = 18
	self._noSelectionLabel.ZIndex = 5
	self._noSelectionLabel.Parent = self._detailPanel

	-- Footer buttons
	self._footer = Instance.new("Frame")
	self._footer.Size = UDim2.new(1, -32, 0, 56)
	self._footer.Position = UDim2.new(0, 16, 1, -72)
	self._footer.BackgroundTransparency = 1
	self._footer.Parent = self._detailPanel
	
	self._acceptBtn = Instance.new("TextButton")
	self._acceptBtn.Size = UDim2.new(0.48, 0, 1, 0)
	self._acceptBtn.Position = UDim2.new(0, 0, 0, 0)
	self._acceptBtn.BackgroundColor3 = COLORS.success
	self._acceptBtn.Text = "✓ ACCEPT QUEST"
	self._acceptBtn.TextColor3 = COLORS.text
	self._acceptBtn.Font = FONTS.Header
	self._acceptBtn.TextSize = 18
	self._acceptBtn.Visible = false
	self._acceptBtn.Parent = self._footer
	addCorner(self._acceptBtn, 8)
	addStroke(self._acceptBtn, Color3.fromRGB(40, 100, 50), 2)
	addGradient(self._acceptBtn, Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))
	
	self._turnInBtn = Instance.new("TextButton")
	self._turnInBtn.Size = UDim2.new(0.48, 0, 1, 0)
	self._turnInBtn.Position = UDim2.new(0, 0, 0, 0)
	self._turnInBtn.BackgroundColor3 = COLORS.gold
	self._turnInBtn.Text = "🎁 TURN IN QUEST"
	self._turnInBtn.TextColor3 = Color3.fromRGB(60, 40, 10)
	self._turnInBtn.Font = FONTS.Header
	self._turnInBtn.TextSize = 18
	self._turnInBtn.Visible = false
	self._turnInBtn.Parent = self._footer
	addCorner(self._turnInBtn, 8)
	addStroke(self._turnInBtn, Color3.fromRGB(150, 100, 20), 2)
	addGradient(self._turnInBtn, Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 200))

	self._closeFooterBtn = Instance.new("TextButton")
	self._closeFooterBtn.Size = UDim2.new(0.48, 0, 1, 0)
	self._closeFooterBtn.Position = UDim2.new(0.52, 0, 0, 0)
	self._closeFooterBtn.BackgroundColor3 = COLORS.slot
	self._closeFooterBtn.Text = "CLOSE"
	self._closeFooterBtn.TextColor3 = COLORS.text
	self._closeFooterBtn.Font = FONTS.Header
	self._closeFooterBtn.TextSize = 18
	self._closeFooterBtn.Parent = self._footer
	addCorner(self._closeFooterBtn, 8)
	addStroke(self._closeFooterBtn, COLORS.borderDim, 2)

	local function setupHover(btn, normalColor, hoverColor)
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = normalColor}):Play()
		end)
	end
	
	setupHover(self._acceptBtn, COLORS.success, Color3.fromRGB(100, 190, 120))
	setupHover(self._turnInBtn, COLORS.gold, Color3.fromRGB(255, 230, 100))
	setupHover(self._closeFooterBtn, COLORS.slot, COLORS.slotHover)

	self._closeFooterBtn.MouseButton1Click:Connect(function() self:SetVisible(false) end)
	
	self._acceptBtn.MouseButton1Click:Connect(function()
		if self.OnAccept and self._selectedIndex then
			local q = self._quests[self._selectedIndex]
			if q and q.status == "Available" then
				self.OnAccept(q.config.id)
			end
		end
	end)
	
	self._turnInBtn.MouseButton1Click:Connect(function()
		if self.OnTurnIn and self._selectedIndex then
			local q = self._quests[self._selectedIndex]
			if q and q.status == "Ready" then
				self.OnTurnIn(q.config.id)
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if not self._root.Visible or gp then return end
		if input.KeyCode == Enum.KeyCode.Escape then
			self:SetVisible(false)
		end
	end)

	return self
end

function QuestUI:SetVisible(visible)
	if visible then
		self._overlay.Visible = true
		self._root.Visible = true
		self._root.Size = UDim2.fromScale(0.8, 0.8)
		TweenService:Create(self._root, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.85, 0.85)
		}):Play()
	else
		self._overlay.Visible = false
		self._root.Visible = false
	end
end

function QuestUI:IsVisible()
	return self._root.Visible
end

function QuestUI:Populate(mode, questList, npcName)
	self._mode = mode
	self._quests = questList
	self._selectedIndex = nil
	
	if mode == "npc" then
		self._listTitle.Text = "📜 " .. string.upper(npcName or "NPC") .. " QUESTS"
	else
		self._listTitle.Text = "📜 QUEST LOG"
	end
	
	for _, child in self._scrollList:GetChildren() do
		if child:IsA("TextButton") then child:Destroy() end
	end
	
	if #self._quests == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 40)
		empty.BackgroundTransparency = 1
		empty.Text = "No quests available."
		empty.TextColor3 = COLORS.textDim
		empty.Font = FONTS.Body
		empty.TextSize = 16
		empty.Parent = self._scrollList
		self:_refreshDetails()
		return
	end

	for i, q in ipairs(self._quests) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 64)
		btn.BackgroundColor3 = COLORS.slot
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.Parent = self._scrollList
		addCorner(btn, 8)
		local stroke = addStroke(btn, COLORS.borderDim, 2)
		
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -50, 0, 26)
		title.Position = UDim2.new(0, 14, 0, 10)
		title.BackgroundTransparency = 1
		title.Text = q.config.name
		title.TextColor3 = COLORS.text
		title.Font = FONTS.Bold
		title.TextSize = 16
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = btn
		
		local status = Instance.new("TextLabel")
		status.Size = UDim2.new(1, -50, 0, 18)
		status.Position = UDim2.new(0, 14, 0, 36)
		status.BackgroundTransparency = 1
		status.Text = q.status
		status.Font = FONTS.Body
		status.TextSize = 14
		status.TextXAlignment = Enum.TextXAlignment.Left
		status.Parent = btn
		
		if q.status == "Locked" then
			title.TextColor3 = COLORS.textDim
			status.TextColor3 = COLORS.locked
			local prerequisiteId = (q.config.prerequisites or {})[1]
			local prerequisite = prerequisiteId and Quests[prerequisiteId]
			status.Text = prerequisite and ("Complete: " .. prerequisite.name) or ("Requires Level " .. (q.config.requiredLevel or 1))
			local lockIcon = Instance.new("TextLabel")
			lockIcon.Size = UDim2.new(0, 30, 0, 30)
			lockIcon.Position = UDim2.new(1, -40, 0.5, -15)
			lockIcon.BackgroundTransparency = 1
			lockIcon.Text = "🔒"
			lockIcon.TextSize = 20
			lockIcon.Parent = btn
		elseif q.status == "Available" then
			status.TextColor3 = COLORS.gold
			status.Text = "⭐ Available"
		elseif q.status == "Accepted" then
			status.TextColor3 = COLORS.accent
			status.Text = "⏳ In Progress: " .. (q.progressText or "")
		elseif q.status == "Ready" then
			status.TextColor3 = COLORS.success
			status.Text = "🎁 Ready to Turn In!"
		elseif q.status == "Completed" then
			status.TextColor3 = COLORS.textDim
			status.Text = "✓ Completed"
		end
		
		btn.MouseEnter:Connect(function()
			if self._selectedIndex ~= i then stroke.Color = COLORS.border end
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.slotHover}):Play()
		end)
		btn.MouseLeave:Connect(function()
			if self._selectedIndex == i then
				stroke.Color = COLORS.accent
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.slotSelected}):Play()
			else
				stroke.Color = COLORS.borderDim
				TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = COLORS.slot}):Play()
			end
		end)
		
		btn.MouseButton1Click:Connect(function()
			self._selectedIndex = i
			for _, b in self._scrollList:GetChildren() do
				if b:IsA("TextButton") then
					b.BackgroundColor3 = COLORS.slot
					b:FindFirstChild("UIStroke").Color = COLORS.borderDim
				end
			end
			btn.BackgroundColor3 = COLORS.slotSelected
			stroke.Color = COLORS.accent
			self:_refreshDetails()
		end)
	end
	
	self:_refreshDetails()
end

function QuestUI:_refreshDetails()
	for _, child in self._detailScroll:GetChildren() do
		if child:IsA("GuiObject") then child:Destroy() end
	end
	
	if not self._selectedIndex then
		self._noSelectionLabel.Visible = true
		self._acceptBtn.Visible = false
		self._turnInBtn.Visible = false
		self._closeFooterBtn.Size = UDim2.new(1, 0, 1, 0)
		self._closeFooterBtn.Position = UDim2.new(0, 0, 0, 0)
		return
	end
	
	self._noSelectionLabel.Visible = false
	local q = self._quests[self._selectedIndex]
	local config = q.config
	
	-- Footer Buttons Setup
	self._acceptBtn.Visible = false
	self._turnInBtn.Visible = false
	self._closeFooterBtn.Size = UDim2.new(0.48, 0, 1, 0)
	self._closeFooterBtn.Position = UDim2.new(0.52, 0, 0, 0)
	
	if q.status == "Available" and self._mode == "npc" then
		self._acceptBtn.Visible = true
	elseif q.status == "Ready" and self._mode == "npc" then
		self._turnInBtn.Visible = true
	else
		-- Just showing log, or quest is locked/completed
		self._closeFooterBtn.Size = UDim2.new(1, 0, 1, 0)
		self._closeFooterBtn.Position = UDim2.new(0, 0, 0, 0)
	end

	local layoutOrder = 1
	local function nextOrder() layoutOrder += 1 return layoutOrder end
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 36)
	title.BackgroundTransparency = 1
	title.Text = config.name
	title.TextColor3 = COLORS.gold
	title.Font = FONTS.Header
	title.TextSize = 28
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.LayoutOrder = nextOrder()
	title.Parent = self._detailScroll
	
	-- Status badge
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0, 24)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = FONTS.Bold
	statusLabel.TextSize = 16
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.LayoutOrder = nextOrder()
	statusLabel.Parent = self._detailScroll
	
	if q.status == "Locked" then
		local prerequisiteId = (config.prerequisites or {})[1]
		local prerequisite = prerequisiteId and Quests[prerequisiteId]
		statusLabel.Text = prerequisite and ("🔒 Locked — Complete " .. prerequisite.name) or ("🔒 Locked (Requires Level " .. (config.requiredLevel or 1) .. ")")
		statusLabel.TextColor3 = COLORS.locked
	elseif q.status == "Available" then
		statusLabel.Text = "⭐ Available"
		statusLabel.TextColor3 = COLORS.gold
	elseif q.status == "Accepted" then
		statusLabel.Text = "⏳ In Progress: " .. (q.progressText or "")
		statusLabel.TextColor3 = COLORS.accent
	elseif q.status == "Ready" then
		statusLabel.Text = "🎁 Ready to Turn In!"
		statusLabel.TextColor3 = COLORS.success
	elseif q.status == "Completed" then
		statusLabel.Text = "✓ Completed"
		statusLabel.TextColor3 = COLORS.textDim
	end
	
	local function addSeparator()
		local sep = Instance.new("Frame")
		sep.Size = UDim2.new(1, 0, 0, 2)
		sep.BackgroundColor3 = COLORS.borderDim
		sep.BorderSizePixel = 0
		sep.LayoutOrder = nextOrder()
		sep.Parent = self._detailScroll
		local pad = Instance.new("Frame")
		pad.Size = UDim2.new(1, 0, 0, 6)
		pad.BackgroundTransparency = 1
		pad.LayoutOrder = nextOrder()
		pad.Parent = self._detailScroll
	end
	
	addSeparator()
	
	-- Lore
	if config.lore then
		local loreTitle = Instance.new("TextLabel")
		loreTitle.Size = UDim2.new(1, 0, 0, 28)
		loreTitle.BackgroundTransparency = 1
		loreTitle.Text = "📖 LORE"
		loreTitle.TextColor3 = COLORS.text
		loreTitle.Font = FONTS.Header
		loreTitle.TextSize = 16
		loreTitle.TextXAlignment = Enum.TextXAlignment.Left
		loreTitle.LayoutOrder = nextOrder()
		loreTitle.Parent = self._detailScroll
		
		local loreTxt = Instance.new("TextLabel")
		loreTxt.Size = UDim2.new(1, 0, 0, 0)
		loreTxt.AutomaticSize = Enum.AutomaticSize.Y
		loreTxt.BackgroundTransparency = 1
		loreTxt.Text = "<i>" .. config.lore .. "</i>"
		loreTxt.TextColor3 = COLORS.textDim
		loreTxt.Font = FONTS.Body
		loreTxt.TextSize = 15
		loreTxt.TextXAlignment = Enum.TextXAlignment.Left
		loreTxt.TextWrapped = true
		loreTxt.RichText = true
		loreTxt.LayoutOrder = nextOrder()
		loreTxt.Parent = self._detailScroll
		
		local pad = Instance.new("Frame")
		pad.Size = UDim2.new(1, 0, 0, 10)
		pad.BackgroundTransparency = 1
		pad.LayoutOrder = nextOrder()
		pad.Parent = self._detailScroll
	end
	
	-- Description / Requirements
	local descTitle = Instance.new("TextLabel")
	descTitle.Size = UDim2.new(1, 0, 0, 28)
	descTitle.BackgroundTransparency = 1
	descTitle.Text = "🎯 REQUIREMENTS"
	descTitle.TextColor3 = COLORS.text
	descTitle.Font = FONTS.Header
	descTitle.TextSize = 16
	descTitle.TextXAlignment = Enum.TextXAlignment.Left
	descTitle.LayoutOrder = nextOrder()
	descTitle.Parent = self._detailScroll
	
	local descTxt = Instance.new("TextLabel")
	descTxt.Size = UDim2.new(1, 0, 0, 0)
	descTxt.AutomaticSize = Enum.AutomaticSize.Y
	descTxt.BackgroundTransparency = 1
	descTxt.Text = config.description or ""
	descTxt.TextColor3 = COLORS.textDim
	descTxt.Font = FONTS.Body
	descTxt.TextSize = 16
	descTxt.TextXAlignment = Enum.TextXAlignment.Left
	descTxt.TextWrapped = true
	descTxt.LayoutOrder = nextOrder()
	descTxt.Parent = self._detailScroll
	
	local pad2 = Instance.new("Frame")
	pad2.Size = UDim2.new(1, 0, 0, 10)
	pad2.BackgroundTransparency = 1
	pad2.LayoutOrder = nextOrder()
	pad2.Parent = self._detailScroll

	-- Hints
	if config.hints then
		local hintsTitle = Instance.new("TextLabel")
		hintsTitle.Size = UDim2.new(1, 0, 0, 28)
		hintsTitle.BackgroundTransparency = 1
		hintsTitle.Text = "💡 HINTS"
		hintsTitle.TextColor3 = COLORS.text
		hintsTitle.Font = FONTS.Header
		hintsTitle.TextSize = 16
		hintsTitle.TextXAlignment = Enum.TextXAlignment.Left
		hintsTitle.LayoutOrder = nextOrder()
		hintsTitle.Parent = self._detailScroll
		
		local hintsTxt = Instance.new("TextLabel")
		hintsTxt.Size = UDim2.new(1, 0, 0, 0)
		hintsTxt.AutomaticSize = Enum.AutomaticSize.Y
		hintsTxt.BackgroundTransparency = 1
		hintsTxt.Text = config.hints
		hintsTxt.TextColor3 = COLORS.accent
		hintsTxt.Font = FONTS.Body
		hintsTxt.TextSize = 15
		hintsTxt.TextXAlignment = Enum.TextXAlignment.Left
		hintsTxt.TextWrapped = true
		hintsTxt.LayoutOrder = nextOrder()
		hintsTxt.Parent = self._detailScroll
		
		local pad3 = Instance.new("Frame")
		pad3.Size = UDim2.new(1, 0, 0, 10)
		pad3.BackgroundTransparency = 1
		pad3.LayoutOrder = nextOrder()
		pad3.Parent = self._detailScroll
	end
	
	addSeparator()
	
	-- Rewards
	local rewTitle = Instance.new("TextLabel")
	rewTitle.Size = UDim2.new(1, 0, 0, 28)
	rewTitle.BackgroundTransparency = 1
	rewTitle.Text = "🎁 REWARDS"
	rewTitle.TextColor3 = COLORS.gold
	rewTitle.Font = FONTS.Header
	rewTitle.TextSize = 16
	rewTitle.TextXAlignment = Enum.TextXAlignment.Left
	rewTitle.LayoutOrder = nextOrder()
	rewTitle.Parent = self._detailScroll
	
	local rewGrid = Instance.new("Frame")
	rewGrid.Size = UDim2.new(1, 0, 0, 70)
	rewGrid.BackgroundTransparency = 1
	rewGrid.LayoutOrder = nextOrder()
	rewGrid.Parent = self._detailScroll
	
	local rl = Instance.new("UIListLayout")
	rl.FillDirection = Enum.FillDirection.Horizontal
	rl.Padding = UDim.new(0, 14)
	rl.Parent = rewGrid
	
	if config.rewards then
		if config.rewards.gold and config.rewards.gold > 0 then
			local goldBox = Instance.new("Frame")
			goldBox.Size = UDim2.fromOffset(90, 60)
			goldBox.BackgroundColor3 = COLORS.slot
			goldBox.Parent = rewGrid
			addCorner(goldBox, 8)
			addStroke(goldBox, COLORS.borderDim, 2)
			
			local gl = Instance.new("TextLabel")
			gl.Size = UDim2.fromScale(1, 1)
			gl.BackgroundTransparency = 1
			gl.Text = "💰 " .. config.rewards.gold .. "g"
			gl.TextColor3 = COLORS.gold
			gl.Font = FONTS.Header
			gl.TextSize = 18
			gl.Parent = goldBox
		end
		
		if config.rewards.experience and config.rewards.experience > 0 then
			local xpBox = Instance.new("Frame")
			xpBox.Size = UDim2.fromOffset(90, 60)
			xpBox.BackgroundColor3 = COLORS.slot
			xpBox.Parent = rewGrid
			addCorner(xpBox, 8)
			addStroke(xpBox, COLORS.borderDim, 2)
			
			local xl = Instance.new("TextLabel")
			xl.Size = UDim2.fromScale(1, 1)
			xl.BackgroundTransparency = 1
			xl.Text = "✨ " .. config.rewards.experience .. " XP"
			xl.TextColor3 = COLORS.exp
			xl.Font = FONTS.Header
			xl.TextSize = 18
			xl.Parent = xpBox
		end
		
		if config.rewards.items then
			local ItemsConfig = require(Shared.Config.Items)
			for _, rItem in ipairs(config.rewards.items) do
				local itm = ItemsConfig[rItem.itemId]
				if itm then
					local itmBox = Instance.new("Frame")
					itmBox.Size = UDim2.fromOffset(60, 60)
					itmBox.BackgroundColor3 = COLORS.slot
					itmBox.Parent = rewGrid
					addCorner(itmBox, 8)
					addStroke(itmBox, COLORS.borderDim, 2)
					
					local icon = Instance.new("Frame")
					icon.Size = UDim2.fromScale(0.7, 0.7)
					icon.AnchorPoint = Vector2.new(0.5, 0.5)
					icon.Position = UDim2.fromScale(0.5, 0.5)
					icon.BackgroundColor3 = itm.color or COLORS.text
					icon.Parent = itmBox
					addCorner(icon, 6)
					
					if rItem.quantity and rItem.quantity > 1 then
						local qty = Instance.new("TextLabel")
						qty.Size = UDim2.new(1, -6, 0, 16)
						qty.Position = UDim2.new(0, 3, 1, -18)
						qty.BackgroundTransparency = 1
						qty.Text = "x" .. rItem.quantity
						qty.TextColor3 = COLORS.text
						qty.Font = FONTS.Header
						qty.TextSize = 14
						qty.TextXAlignment = Enum.TextXAlignment.Right
						qty.ZIndex = 2
						qty.Parent = itmBox
					end
				end
			end
		end
	end
end

return QuestUI
