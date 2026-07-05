local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local StatBar = require(script.Parent.Parent.UI.HUD.StatBar)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local stats = {
	hasSelectedClass = false,
	hp = 0,
	maxHp = 1,
	mana = 0,
	maxMana = 1,
	level = 1,
	xp = 0,
	requiredXp = 100,
	coins = 0,
	classId = nil,
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

local hud = Instance.new("Frame")
hud.Name = "HUD"
hud.Size = UDim2.new(0, 240, 0, 150)
hud.Position = UDim2.new(0, 16, 0, 16)
hud.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
hud.BackgroundTransparency = 0.2
hud.BorderSizePixel = 0
hud.Visible = false
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

local classLabel = Instance.new("TextLabel")
classLabel.Name = "ClassLabel"
classLabel.Size = UDim2.new(1, -16, 0, 16)
classLabel.Position = UDim2.new(0, 8, 0, 28)
classLabel.BackgroundTransparency = 1
classLabel.Text = ""
classLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
classLabel.Font = Enum.Font.Gotham
classLabel.TextSize = 12
classLabel.TextXAlignment = Enum.TextXAlignment.Left
classLabel.Parent = hud

local hpBar = StatBar.new(hud, {
	name = "HP",
	position = UDim2.new(0, 8, 0, 48),
	size = UDim2.new(1, -16, 0, 18),
	fillColor = Color3.fromRGB(220, 60, 60),
	defaultText = "0 / 0 HP",
})

local manaBar = StatBar.new(hud, {
	name = "Mana",
	position = UDim2.new(0, 8, 0, 72),
	size = UDim2.new(1, -16, 0, 16),
	fillColor = Color3.fromRGB(50, 100, 220),
	defaultText = "0 / 0 Mana",
	textSize = 11,
})

local xpBar = StatBar.new(hud, {
	name = "XP",
	position = UDim2.new(0, 8, 0, 94),
	size = UDim2.new(1, -16, 0, 14),
	fillColor = Color3.fromRGB(80, 160, 255),
	defaultText = "0 / 100 XP",
	textSize = 10,
})

local goldLabel = Instance.new("TextLabel")
goldLabel.Size = UDim2.new(1, -16, 0, 22)
goldLabel.Position = UDim2.new(0, 8, 0, 116)
goldLabel.BackgroundTransparency = 1
goldLabel.Text = "Gold: 0"
goldLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
goldLabel.Font = Enum.Font.GothamBold
goldLabel.TextSize = 14
goldLabel.TextXAlignment = Enum.TextXAlignment.Left
goldLabel.Parent = hud

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
questProgress.Text = "Progress: 0/5"
questProgress.TextColor3 = Color3.fromRGB(180, 220, 255)
questProgress.Font = Enum.Font.Gotham
questProgress.TextSize = 13
questProgress.TextXAlignment = Enum.TextXAlignment.Left
questProgress.Parent = questTracker

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

local levelUpFlash = Instance.new("Frame")
levelUpFlash.Name = "LevelUpFlash"
levelUpFlash.Size = UDim2.new(1, 0, 1, 0)
levelUpFlash.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
levelUpFlash.BackgroundTransparency = 1
levelUpFlash.BorderSizePixel = 0
levelUpFlash.Visible = false
levelUpFlash.ZIndex = 50
levelUpFlash.Parent = screenGui

local levelUpLabel = Instance.new("TextLabel")
levelUpLabel.Size = UDim2.new(1, 0, 0, 60)
levelUpLabel.Position = UDim2.new(0, 0, 0.4, 0)
levelUpLabel.BackgroundTransparency = 1
levelUpLabel.Text = "LEVEL UP!"
levelUpLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
levelUpLabel.Font = Enum.Font.GothamBold
levelUpLabel.TextSize = 42
levelUpLabel.TextTransparency = 1
levelUpLabel.Parent = levelUpFlash

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

local shopModal = Instance.new("Frame")
shopModal.Name = "ShopModal"
shopModal.Size = UDim2.new(0, 400, 0, 300)
shopModal.Position = UDim2.new(0.5, -200, 0.5, -150)
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
inventoryBtn.Visible = false
inventoryBtn.Parent = screenGui

local invBtnCorner = Instance.new("UICorner")
invBtnCorner.CornerRadius = UDim.new(0, 8)
invBtnCorner.Parent = inventoryBtn

inventoryBtn.MouseButton1Click:Connect(function()
	local inventoryUI = playerGui:FindFirstChild("InventoryUI")
	if inventoryUI then
		local toggleEvent = inventoryUI:FindFirstChild("ToggleInventory")
		if toggleEvent then
			toggleEvent:Fire()
		end
	end
end)

local function updateHud()
	local showHud = stats.hasSelectedClass == true
	hud.Visible = showHud
	inventoryBtn.Visible = showHud

	if not showHud then
		return
	end

	levelLabel.Text = "Level " .. stats.level
	classLabel.Text = stats.classId or ""
	hpBar:Update(stats.hp, stats.maxHp, math.floor(stats.hp) .. " / " .. stats.maxHp .. " HP")
	manaBar:Update(stats.mana, stats.maxMana, math.floor(stats.mana) .. " / " .. stats.maxMana .. " Mana")
	local reqXp = stats.requiredXp or 100
	xpBar:Update(stats.xp, reqXp, stats.xp .. " / " .. reqXp .. " XP")
	goldLabel.Text = "Gold: " .. (stats.gold or stats.coins or 0)
end

local function updateQuestTracker()
	if not stats.hasSelectedClass then
		questTracker.Visible = false
		return
	end

	if quest.accepted and not quest.completed then
		questTracker.Visible = true
		questTitle.Text = quest.name ~= "" and quest.name or "Active Quest"
		local objectiveHint = ""
		if quest.objectiveType == "kill" then
			objectiveHint = "Kills"
		elseif quest.objectiveType == "collect" then
			objectiveHint = "Collected"
		elseif quest.objectiveType == "talk" then
			objectiveHint = "Talked"
		elseif quest.objectiveType == "reach" then
			objectiveHint = "Reached"
		else
			objectiveHint = "Progress"
		end
		questProgress.Text = objectiveHint .. ": " .. quest.progress .. "/" .. (quest.required or "?")
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

local function playLevelUpEffect()
	levelUpFlash.Visible = true
	levelUpLabel.TextTransparency = 0
	levelUpFlash.BackgroundTransparency = 0.7

	task.delay(0.15, function()
		levelUpFlash.BackgroundTransparency = 1
	end)
	task.delay(1.2, function()
		levelUpLabel.TextTransparency = 1
		levelUpFlash.Visible = false
	end)
end

local playerInventory = {}
local lastShopItems = {}

local function renderSellSection(shopItems)
	local sellPrices = {}
	for _, shopItem in shopItems do
		if shopItem.sellPrice then
			sellPrices[shopItem.itemId] = shopItem.sellPrice
		end
	end

	for _, entry in playerInventory do
		local sellPrice = sellPrices[entry.id]
		if sellPrice and entry.count > 0 then
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -8, 0, 48)
			row.BackgroundColor3 = Color3.fromRGB(45, 40, 55)
			row.BorderSizePixel = 0
			row.Parent = shopList

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = UDim2.new(1, -100, 1, 0)
			nameLbl.Position = UDim2.new(0, 10, 0, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text = "Sell: " .. entry.id .. " x" .. entry.count
			nameLbl.TextColor3 = Color3.fromRGB(200, 220, 255)
			nameLbl.Font = Enum.Font.Gotham
			nameLbl.TextSize = 13
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.Parent = row

			local sellBtn = Instance.new("TextButton")
			sellBtn.Size = UDim2.new(0, 72, 0, 32)
			sellBtn.Position = UDim2.new(1, -82, 0.5, -16)
			sellBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 180)
			sellBtn.Text = sellPrice .. "g"
			sellBtn.TextColor3 = Color3.new(1, 1, 1)
			sellBtn.Font = Enum.Font.GothamBold
			sellBtn.TextSize = 13
			sellBtn.Parent = row

			local itemId = entry.id
			sellBtn.MouseButton1Click:Connect(function()
				if remotes:FindFirstChild("SellItem") then
					remotes.SellItem:FireServer(itemId, 1)
				end
			end)
		end
	end
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
		priceLbl.Text = (item.category or "item") .. " | Buy: " .. item.price .. "g"
			.. (item.sellPrice and (" | Sell: " .. item.sellPrice .. "g") or "")
		priceLbl.TextColor3 = Color3.fromRGB(160, 160, 160)
		priceLbl.Font = Enum.Font.Gotham
		priceLbl.TextSize = 11
		priceLbl.TextXAlignment = Enum.TextXAlignment.Left
		priceLbl.Parent = row

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 72, 0, 32)
		buyBtn.Position = UDim2.new(1, -82, 0.5, -16)
		buyBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 50)
		buyBtn.Text = item.price .. "g"
		buyBtn.TextColor3 = Color3.new(1, 1, 1)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextSize = 13
		buyBtn.Parent = row

		buyBtn.MouseButton1Click:Connect(function()
			remotes.PurchaseItem:FireServer(item.itemId)
		end)
	end

	renderSellSection(items)

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
	local previousLevel = stats.level
	stats = payload
	if payload.quest then
		quest.accepted = payload.quest.accepted
		quest.completed = payload.quest.completed
		quest.progress = payload.quest.progress or 0
	end
	if payload.hasSelectedClass and payload.level and payload.level > previousLevel then
		playLevelUpEffect()
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
	quest.description = payload.description
	quest.objectiveType = payload.objectiveType
	updateQuestTracker()
end)

remotes.OpenQuest.OnClientEvent:Connect(function(payload)
	currentQuestId = payload.id
	questModalTitle.Text = payload.name
	questModalDesc.Text = payload.description .. "\n\nReward: XP + Gold"

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
	lastShopItems = items or {}
	renderShop(lastShopItems)
	shopModal.Visible = true
	remotes.RequestInventory:FireServer()
end)

remotes.InventoryUpdated.OnClientEvent:Connect(function(inventory)
	playerInventory = inventory or {}
	if shopModal.Visible then
		renderShop(lastShopItems)
	end
end)

remotes.Notification.OnClientEvent:Connect(function(text)
	showNotification(text)
	if text:find("Level Up") then
		playLevelUpEffect()
	end
end)

if remotes:FindFirstChild("LevelUp") then
	remotes.LevelUp.OnClientEvent:Connect(function()
		playLevelUpEffect()
	end)
end

updateHud()
updateQuestTracker()
