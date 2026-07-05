local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local stats = {
	hp = 2000,
	maxHp = 10000,
	level = 1,
	xp = 0,
	coins = 0,
}

local quest = {
	accepted = false,
	completed = false,
	progress = 0,
	required = 5,
	name = "",
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RPGHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- HUD panel
local hud = Instance.new("Frame")
hud.Name = "HUD"
hud.Size = UDim2.new(0, 220, 0, 120)
hud.Position = UDim2.new(0, 16, 0, 16)
hud.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
hud.BackgroundTransparency = 0.2
hud.BorderSizePixel = 0
hud.Parent = screenGui

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 8)
hudCorner.Parent = hud

local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "LevelLabel"
levelLabel.Size = UDim2.new(1, -16, 0, 22)
levelLabel.Position = UDim2.new(0, 8, 0, 8)
levelLabel.BackgroundTransparency = 1
levelLabel.Text = "Level 1"
levelLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
levelLabel.Font = Enum.Font.GothamBold
levelLabel.TextSize = 16
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.Parent = hud

local hpBg = Instance.new("Frame")
hpBg.Size = UDim2.new(1, -16, 0, 18)
hpBg.Position = UDim2.new(0, 8, 0, 34)
hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
hpBg.BorderSizePixel = 0
hpBg.Parent = hud

local hpFill = Instance.new("Frame")
hpFill.Name = "HPFill"
hpFill.Size = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBg

local hpLabel = Instance.new("TextLabel")
hpLabel.Size = UDim2.new(1, 0, 1, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.Text = "100 / 100 HP"
hpLabel.TextColor3 = Color3.new(1, 1, 1)
hpLabel.Font = Enum.Font.GothamBold
hpLabel.TextSize = 12
hpLabel.Parent = hpBg

local xpBg = Instance.new("Frame")
xpBg.Size = UDim2.new(1, -16, 0, 14)
xpBg.Position = UDim2.new(0, 8, 0, 58)
xpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
xpBg.BorderSizePixel = 0
xpBg.Parent = hud

local xpFill = Instance.new("Frame")
xpFill.Name = "XPFill"
xpFill.Size = UDim2.new(0, 0, 1, 0)
xpFill.BackgroundColor3 = Color3.fromRGB(80, 160, 255)
xpFill.BorderSizePixel = 0
xpFill.Parent = xpBg

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(1, -16, 0, 22)
coinsLabel.Position = UDim2.new(0, 8, 0, 80)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "Coins: 0"
coinsLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextSize = 14
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
coinsLabel.Parent = hud

-- Quest tracker
local questTracker = Instance.new("Frame")
questTracker.Name = "QuestTracker"
questTracker.Size = UDim2.new(0, 260, 0, 56)
questTracker.Position = UDim2.new(0.5, -130, 1, -80)
questTracker.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
questTracker.BackgroundTransparency = 0.25
questTracker.BorderSizePixel = 0
questTracker.Visible = false
questTracker.Parent = screenGui

local questCorner = Instance.new("UICorner")
questCorner.CornerRadius = UDim.new(0, 8)
questCorner.Parent = questTracker

local questTitle = Instance.new("TextLabel")
questTitle.Size = UDim2.new(1, -16, 0, 22)
questTitle.Position = UDim2.new(0, 8, 0, 6)
questTitle.BackgroundTransparency = 1
questTitle.Text = "Quest"
questTitle.TextColor3 = Color3.new(1, 1, 1)
questTitle.Font = Enum.Font.GothamBold
questTitle.TextSize = 14
questTitle.TextXAlignment = Enum.TextXAlignment.Left
questTitle.Parent = questTracker

local questProgress = Instance.new("TextLabel")
questProgress.Size = UDim2.new(1, -16, 0, 20)
questProgress.Position = UDim2.new(0, 8, 0, 28)
questProgress.BackgroundTransparency = 1
questProgress.Text = "Goblins: 0/5"
questProgress.TextColor3 = Color3.fromRGB(180, 220, 255)
questProgress.Font = Enum.Font.Gotham
questProgress.TextSize = 13
questProgress.TextXAlignment = Enum.TextXAlignment.Left
questProgress.Parent = questTracker

-- Notification
local notification = Instance.new("TextLabel")
notification.Name = "Notification"
notification.Size = UDim2.new(0, 400, 0, 40)
notification.Position = UDim2.new(0.5, -200, 0, 60)
notification.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
notification.BackgroundTransparency = 0.15
notification.Text = ""
notification.TextColor3 = Color3.new(1, 1, 1)
notification.Font = Enum.Font.GothamBold
notification.TextSize = 16
notification.Visible = false
notification.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 8)
notifCorner.Parent = notification

-- Quest dialog modal
local questModal = Instance.new("Frame")
questModal.Name = "QuestModal"
questModal.Size = UDim2.new(0, 360, 0, 220)
questModal.Position = UDim2.new(0.5, -180, 0.5, -110)
questModal.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
questModal.BorderSizePixel = 0
questModal.Visible = false
questModal.Parent = screenGui

local questModalCorner = Instance.new("UICorner")
questModalCorner.CornerRadius = UDim.new(0, 10)
questModalCorner.Parent = questModal

local questModalTitle = Instance.new("TextLabel")
questModalTitle.Size = UDim2.new(1, -20, 0, 32)
questModalTitle.Position = UDim2.new(0, 10, 0, 12)
questModalTitle.BackgroundTransparency = 1
questModalTitle.Text = "Quest"
questModalTitle.TextColor3 = Color3.new(1, 1, 1)
questModalTitle.Font = Enum.Font.GothamBold
questModalTitle.TextSize = 20
questModalTitle.TextXAlignment = Enum.TextXAlignment.Left
questModalTitle.Parent = questModal

local questModalDesc = Instance.new("TextLabel")
questModalDesc.Size = UDim2.new(1, -20, 0, 80)
questModalDesc.Position = UDim2.new(0, 10, 0, 50)
questModalDesc.BackgroundTransparency = 1
questModalDesc.Text = ""
questModalDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
questModalDesc.Font = Enum.Font.Gotham
questModalDesc.TextSize = 14
questModalDesc.TextWrapped = true
questModalDesc.TextXAlignment = Enum.TextXAlignment.Left
questModalDesc.TextYAlignment = Enum.TextYAlignment.Top
questModalDesc.Parent = questModal

local acceptBtn = Instance.new("TextButton")
acceptBtn.Size = UDim2.new(0, 120, 0, 36)
acceptBtn.Position = UDim2.new(0.5, -130, 1, -52)
acceptBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 80)
acceptBtn.Text = "Accept"
acceptBtn.TextColor3 = Color3.new(1, 1, 1)
acceptBtn.Font = Enum.Font.GothamBold
acceptBtn.TextSize = 14
acceptBtn.Parent = questModal

local closeQuestBtn = Instance.new("TextButton")
closeQuestBtn.Size = UDim2.new(0, 120, 0, 36)
closeQuestBtn.Position = UDim2.new(0.5, 10, 1, -52)
closeQuestBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
closeQuestBtn.Text = "Close"
closeQuestBtn.TextColor3 = Color3.new(1, 1, 1)
closeQuestBtn.Font = Enum.Font.GothamBold
closeQuestBtn.TextSize = 14
closeQuestBtn.Parent = questModal

local currentQuestId = nil

-- Shop modal
local shopModal = Instance.new("Frame")
shopModal.Name = "ShopModal"
shopModal.Size = UDim2.new(0, 380, 0, 260)
shopModal.Position = UDim2.new(0.5, -190, 0.5, -130)
shopModal.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
shopModal.BorderSizePixel = 0
shopModal.Visible = false
shopModal.Parent = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 10)
shopCorner.Parent = shopModal

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, -20, 0, 32)
shopTitle.Position = UDim2.new(0, 10, 0, 12)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "Shop"
shopTitle.TextColor3 = Color3.new(1, 1, 1)
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 20
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.Parent = shopModal

local shopList = Instance.new("ScrollingFrame")
shopList.Size = UDim2.new(1, -20, 1, -100)
shopList.Position = UDim2.new(0, 10, 0, 50)
shopList.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
shopList.BorderSizePixel = 0
shopList.ScrollBarThickness = 6
shopList.CanvasSize = UDim2.new(0, 0, 0, 0)
shopList.Parent = shopModal

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 8)
shopLayout.Parent = shopList

local closeShopBtn = Instance.new("TextButton")
closeShopBtn.Size = UDim2.new(0, 120, 0, 36)
closeShopBtn.Position = UDim2.new(0.5, -60, 1, -48)
closeShopBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
closeShopBtn.Text = "Close"
closeShopBtn.TextColor3 = Color3.new(1, 1, 1)
closeShopBtn.Font = Enum.Font.GothamBold
closeShopBtn.TextSize = 14
closeShopBtn.Parent = shopModal

-- Action Bar
local actionBar = Instance.new("Frame")
actionBar.Name = "ActionBar"
actionBar.Size = UDim2.new(0, 380, 0, 60)
actionBar.Position = UDim2.new(0.5, -190, 1, -70)
actionBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
actionBar.BackgroundTransparency = 0.5
actionBar.BorderSizePixel = 0
actionBar.Parent = screenGui

local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
actionLayout.Padding = UDim.new(0, 8)
actionLayout.Parent = actionBar

local actionSlots = {
	{key = "1", name = "Attack"},
	{key = "2", name = "Skill 1"},
	{key = "3", name = "Skill 2"},
	{key = "4", name = "Skill 3"},
	{key = "5", name = "Ultimate"},
	{key = "6", name = "HP Pot"},
	{key = "7", name = "MP Pot"},
}

for i, slotData in actionSlots do
	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. slotData.key
	slot.Size = UDim2.new(0, 46, 0, 46)
	slot.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	slot.BorderSizePixel = 0
	slot.Parent = actionBar
	
	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 6)
	slotCorner.Parent = slot
	
	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.new(0, 16, 0, 16)
	keyLabel.Position = UDim2.new(0, 2, 0, 2)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Text = slotData.key
	keyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.TextSize = 10
	keyLabel.TextXAlignment = Enum.TextXAlignment.Left
	keyLabel.Parent = slot
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.Position = UDim2.new(0, 0, 1, -16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = slotData.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 9
	nameLabel.Parent = slot
end

-- Inventory Button (visible on HUD, positioned to the right of the action bar)
local inventoryBtn = Instance.new("TextButton")
inventoryBtn.Name = "InventoryButton"
inventoryBtn.Size = UDim2.new(0, 80, 0, 46)
inventoryBtn.Position = UDim2.new(1, -96, 1, -70)
inventoryBtn.BackgroundColor3 = Color3.fromRGB(50, 45, 70)
inventoryBtn.BorderSizePixel = 0
inventoryBtn.Text = "Bag (I)"
inventoryBtn.TextColor3 = Color3.fromRGB(255, 220, 100)
inventoryBtn.Font = Enum.Font.GothamBold
inventoryBtn.TextSize = 14
inventoryBtn.Parent = screenGui

local invBtnCorner = Instance.new("UICorner")
invBtnCorner.CornerRadius = UDim.new(0, 8)
invBtnCorner.Parent = inventoryBtn

inventoryBtn.MouseButton1Click:Connect(function()
	-- Find the InventoryUI and fire its toggle event
	local inventoryUI = playerGui:FindFirstChild("InventoryUI")
	if inventoryUI then
		local toggleEvent = inventoryUI:FindFirstChild("ToggleInventory")
		if toggleEvent then
			toggleEvent:Fire()
		end
	end
end)

local function updateHud()
	levelLabel.Text = "Level " .. stats.level
	hpFill.Size = UDim2.new(math.clamp(stats.hp / stats.maxHp, 0, 1), 0, 1, 0)
	hpLabel.Text = math.floor(stats.hp) .. " / " .. stats.maxHp .. " HP"
	xpFill.Size = UDim2.new(math.clamp(stats.xp / 100, 0, 1), 0, 1, 0)
	coinsLabel.Text = "Coins: " .. stats.coins
end

local function updateQuestTracker()
	if quest.accepted and not quest.completed then
		questTracker.Visible = true
		questTitle.Text = quest.name ~= "" and quest.name or "Active Quest"
		questProgress.Text = "Goblins: " .. quest.progress .. "/" .. quest.required
	elseif quest.completed then
		questTracker.Visible = true
		questTitle.Text = quest.name ~= "" and quest.name or "Quest"
		questProgress.Text = "Complete!"
	else
		questTracker.Visible = false
	end
end

local function showNotification(text)
	notification.Text = text
	notification.Visible = true
	task.delay(3, function()
		notification.Visible = false
	end)
end

local function renderShop(items)
	for _, child in shopList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, item in items do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 56)
		row.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
		row.BorderSizePixel = 0
		row.Parent = shopList

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -100, 0, 22)
		nameLbl.Position = UDim2.new(0, 10, 0, 8)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = item.name
		nameLbl.TextColor3 = Color3.new(1, 1, 1)
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 14
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Parent = row

		local priceLbl = Instance.new("TextLabel")
		priceLbl.Size = UDim2.new(1, -100, 0, 18)
		priceLbl.Position = UDim2.new(0, 10, 0, 30)
		priceLbl.BackgroundTransparency = 1
		priceLbl.Text = item.description
		priceLbl.TextColor3 = Color3.fromRGB(160, 160, 160)
		priceLbl.Font = Enum.Font.Gotham
		priceLbl.TextSize = 11
		priceLbl.TextXAlignment = Enum.TextXAlignment.Left
		priceLbl.Parent = row

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 72, 0, 32)
		buyBtn.Position = UDim2.new(1, -82, 0.5, -16)
		buyBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 50)
		buyBtn.Text = item.price .. "c"
		buyBtn.TextColor3 = Color3.new(1, 1, 1)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextSize = 13
		buyBtn.Parent = row

		buyBtn.MouseButton1Click:Connect(function()
			remotes.PurchaseItem:FireServer(item.itemId)
		end)
	end

	task.defer(function()
		shopList.CanvasSize = UDim2.new(0, 0, 0, shopLayout.AbsoluteContentSize.Y + 8)
	end)
end

acceptBtn.MouseButton1Click:Connect(function()
	if currentQuestId then
		remotes.AcceptQuest:FireServer(currentQuestId)
		questModal.Visible = false
	end
end)

closeQuestBtn.MouseButton1Click:Connect(function()
	questModal.Visible = false
end)

closeShopBtn.MouseButton1Click:Connect(function()
	shopModal.Visible = false
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	stats = payload
	if payload.quest then
		quest.accepted = payload.quest.accepted
		quest.completed = payload.quest.completed
		quest.progress = payload.quest.progress or 0
	end
	updateHud()
	updateQuestTracker()
end)

remotes.QuestUpdated.OnClientEvent:Connect(function(payload)
	quest.accepted = payload.accepted
	quest.completed = payload.completed
	quest.progress = payload.progress
	quest.required = payload.required
	quest.name = payload.name
	updateQuestTracker()
end)

remotes.OpenQuest.OnClientEvent:Connect(function(payload)
	currentQuestId = payload.id
	questModalTitle.Text = payload.name
	questModalDesc.Text = payload.description .. "\n\nReward: XP + Coins"

	if payload.completed then
		acceptBtn.Visible = false
		questModalDesc.Text ..= "\n\n(Status: Complete)"
	elseif payload.accepted then
		acceptBtn.Visible = false
		questModalDesc.Text ..= "\n\n(Status: In progress " .. payload.progress .. "/" .. payload.required .. ")"
	else
		acceptBtn.Visible = true
	end

	questModal.Visible = true
end)

remotes.OpenShop.OnClientEvent:Connect(function(items)
	renderShop(items)
	shopModal.Visible = true
end)

remotes.Notification.OnClientEvent:Connect(function(text)
	showNotification(text)
end)

updateHud()
updateQuestTracker()
