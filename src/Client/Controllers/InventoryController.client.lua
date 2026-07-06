local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local LocalAnimationBuilder = require(Shared.Util.LocalAnimationBuilder)
local RarityConfig = require(Shared.Config.RarityConfig)
local EnhancementConfig = require(Shared.Config.EnhancementConfig)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local inventory = {}
local equipped = {}
local visible = false
local hasSelectedClass = false
local enhanceMode = false
local selectedScrollId = nil
local selectedTargetUid = nil
local enhanceBusy = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "InventoryPanel"
panel.Size = UDim2.new(0, 360, 0, 380)
panel.Position = UDim2.new(0.5, -180, 0.5, -190)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 0, 36)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Inventory (L)"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local enhanceToggle = Instance.new("TextButton")
enhanceToggle.Size = UDim2.new(0, 90, 0, 28)
enhanceToggle.Position = UDim2.new(1, -100, 0, 12)
enhanceToggle.BackgroundColor3 = Color3.fromRGB(80, 60, 140)
enhanceToggle.Text = "Enhance"
enhanceToggle.TextColor3 = Color3.new(1, 1, 1)
enhanceToggle.Font = Enum.Font.GothamBold
enhanceToggle.TextSize = 12
enhanceToggle.Parent = panel

local enhancePreview = Instance.new("TextLabel")
enhancePreview.Size = UDim2.new(1, -20, 0, 70)
enhancePreview.Position = UDim2.new(0, 10, 1, -78)
enhancePreview.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
enhancePreview.Text = ""
enhancePreview.TextColor3 = Color3.fromRGB(200, 200, 200)
enhancePreview.Font = Enum.Font.Gotham
enhancePreview.TextSize = 11
enhancePreview.TextWrapped = true
enhancePreview.TextYAlignment = Enum.TextYAlignment.Top
enhancePreview.Visible = false
enhancePreview.Parent = panel

local enhanceConfirm = Instance.new("TextButton")
enhanceConfirm.Size = UDim2.new(0, 100, 0, 28)
enhanceConfirm.Position = UDim2.new(1, -110, 1, -38)
enhanceConfirm.BackgroundColor3 = Color3.fromRGB(80, 140, 80)
enhanceConfirm.Text = "Apply Scroll"
enhanceConfirm.TextColor3 = Color3.new(1, 1, 1)
enhanceConfirm.Font = Enum.Font.GothamBold
enhanceConfirm.TextSize = 12
enhanceConfirm.Visible = false
enhanceConfirm.Parent = panel

local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "ItemList"
listFrame.Size = UDim2.new(1, -20, 1, -56)
listFrame.Position = UDim2.new(0, 10, 0, 48)
listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 6
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.Parent = panel

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = listFrame

local function formatEntryName(item, entry)
	local label = item.name
	if entry.count and entry.count > 1 then
		label ..= " x" .. entry.count
	end
	if entry.rarity and item.supportsRarity then
		label ..= " [" .. entry.rarity .. "]"
	end
	if entry.enhanceLevel and entry.enhanceLevel > 0 then
		label ..= " +" .. entry.enhanceLevel
	end
	if entry.rarity and item.slot then
		label = "[" .. (entry.rarity or "Common") .. "] " .. label
	end
	return label
end

local function updateEnhancePreview()
	if not enhanceMode or not selectedScrollId or not selectedTargetUid then
		enhancePreview.Text = enhanceMode and "Select scroll, then gear." or ""
		return
	end

	local scroll = Items[selectedScrollId]
	local targetEntry = nil
	for _, e in inventory do
		if e.uid == selectedTargetUid then
			targetEntry = e
			break
		end
	end
	if not targetEntry then
		for _, slot in { "weapon", "helmet", "armor", "pants", "boots", "gloves" } do
			local e = equipped[slot]
			if type(e) == "table" and e.uid == selectedTargetUid then
				targetEntry = e
				break
			end
		end
	end
	if not scroll or not targetEntry then
		enhancePreview.Text = "Invalid selection."
		return
	end

	local level = targetEntry.enhanceLevel or 0
	local tier = EnhancementConfig.GetTierForLevel(level + 1)
	enhancePreview.Text = string.format(
		"Scroll: %s → +%d\nGold cost: %d\nSuccess: %d%%  Fail: %d%%  Down: %d%%  Break: %d%%",
		scroll.name,
		level + 1,
		tier.applyGoldCost,
		math.floor(tier.success * 100),
		math.floor(tier.fail * 100),
		math.floor(tier.downgrade * 100),
		math.floor(tier.breakChance * 100)
	)
end

local function renderInventory()
	for _, child in listFrame:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	enhancePreview.Visible = enhanceMode
	enhanceConfirm.Visible = enhanceMode
	listFrame.Size = enhanceMode and UDim2.new(1, -20, 1, -140) or UDim2.new(1, -20, 1, -56)

	if #inventory == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 40)
		empty.BackgroundTransparency = 1
		empty.Text = "No items yet. Defeat enemies for drops!"
		empty.TextColor3 = Color3.fromRGB(180, 180, 180)
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 14
		empty.Parent = listFrame
		listFrame.CanvasSize = UDim2.new(0, 0, 0, 50)
		return
	end

	for _, entry in inventory do
		local item = Items[entry.id]
		if item then
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -8, 0, 52)
			row.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
			if enhanceMode and entry.uid == selectedTargetUid then
				row.BackgroundColor3 = Color3.fromRGB(50, 70, 90)
			elseif enhanceMode and entry.id == selectedScrollId then
				row.BackgroundColor3 = Color3.fromRGB(70, 50, 90)
			end
			row.BorderSizePixel = 0
			row.Parent = listFrame

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 6)
			rowCorner.Parent = row

			local icon = Instance.new("Frame")
			icon.Size = UDim2.new(0, 32, 0, 32)
			icon.Position = UDim2.new(0, 8, 0.5, -16)
			icon.BackgroundColor3 = item.color
			if entry.rarity and item.slot then
				icon.BackgroundColor3 = RarityConfig.GetColor(entry.rarity)
			end
			icon.BorderSizePixel = 0
			icon.Parent = row

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -200, 0, 22)
			nameLabel.Position = UDim2.new(0, 48, 0, 8)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = formatEntryName(item, entry)
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 13
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = row

			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, -200, 0, 18)
			descLabel.Position = UDim2.new(0, 48, 0, 28)
			descLabel.BackgroundTransparency = 1
			descLabel.Text = item.description
			descLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextSize = 10
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.Parent = row

			local buttonOffset = -58
			if enhanceMode then
				if item.category == "scrolls" then
					local selBtn = Instance.new("TextButton")
					selBtn.Size = UDim2.new(0, 52, 0, 28)
					selBtn.Position = UDim2.new(1, buttonOffset, 0.5, -14)
					selBtn.BackgroundColor3 = Color3.fromRGB(100, 70, 160)
					selBtn.Text = "Scroll"
					selBtn.TextColor3 = Color3.new(1, 1, 1)
					selBtn.Font = Enum.Font.GothamBold
					selBtn.TextSize = 11
					selBtn.Parent = row
					selBtn.MouseButton1Click:Connect(function()
						selectedScrollId = entry.id
						updateEnhancePreview()
						renderInventory()
					end)
				elseif item.slot and entry.uid then
					local tgtBtn = Instance.new("TextButton")
					tgtBtn.Size = UDim2.new(0, 52, 0, 28)
					tgtBtn.Position = UDim2.new(1, buttonOffset, 0.5, -14)
					tgtBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 80)
					tgtBtn.Text = "Target"
					tgtBtn.TextColor3 = Color3.new(1, 1, 1)
					tgtBtn.Font = Enum.Font.GothamBold
					tgtBtn.TextSize = 11
					tgtBtn.Parent = row
					tgtBtn.MouseButton1Click:Connect(function()
						selectedTargetUid = entry.uid
						updateEnhancePreview()
						renderInventory()
					end)
				end
			else
				if item.usable then
					local useBtn = Instance.new("TextButton")
					useBtn.Size = UDim2.new(0, 52, 0, 32)
					useBtn.Position = UDim2.new(1, buttonOffset, 0.5, -16)
					useBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 80)
					useBtn.Text = "Use"
					useBtn.TextColor3 = Color3.new(1, 1, 1)
					useBtn.Font = Enum.Font.GothamBold
					useBtn.TextSize = 13
					useBtn.Parent = row
					useBtn.MouseButton1Click:Connect(function()
						local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
						if entry.id == "HealthPotion" then
							LocalAnimationBuilder.DrinkHealthPotion(humanoid)
						elseif entry.id == "ManaPotion" then
							LocalAnimationBuilder.DrinkManaPotion(humanoid)
						end
						remotes.UseItem:FireServer(entry.id)
					end)
					buttonOffset -= 58
				end

				if item.slot and remotes:FindFirstChild("EquipItem") then
					local equipBtn = Instance.new("TextButton")
					equipBtn.Size = UDim2.new(0, 52, 0, 32)
					equipBtn.Position = UDim2.new(1, buttonOffset, 0.5, -16)
					equipBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 180)
					equipBtn.Text = "Equip"
					equipBtn.TextColor3 = Color3.new(1, 1, 1)
					equipBtn.Font = Enum.Font.GothamBold
					equipBtn.TextSize = 13
					equipBtn.Parent = row
					equipBtn.MouseButton1Click:Connect(function()
						remotes.EquipItem:FireServer(entry.id)
					end)
				end
			end
		end
	end

	updateEnhancePreview()
	task.defer(function()
		listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
	end)

	if enhanceMode then
		for _, slot in { "weapon", "helmet", "armor", "pants", "boots", "gloves" } do
			local entry = equipped[slot]
			if type(entry) == "table" and entry.uid and Items[entry.id] and Items[entry.id].slot then
				local item = Items[entry.id]
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, -8, 0, 44)
				row.BackgroundColor3 = entry.uid == selectedTargetUid and Color3.fromRGB(50, 70, 90) or Color3.fromRGB(35, 45, 55)
				row.Parent = listFrame
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -70, 1, 0)
				lbl.Position = UDim2.new(0, 8, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = "(Equipped) " .. formatEntryName(item, entry)
				lbl.TextColor3 = Color3.new(1, 1, 1)
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = row
				local tgtBtn = Instance.new("TextButton")
				tgtBtn.Size = UDim2.new(0, 52, 0, 28)
				tgtBtn.Position = UDim2.new(1, -58, 0.5, -14)
				tgtBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 80)
				tgtBtn.Text = "Target"
				tgtBtn.TextColor3 = Color3.new(1, 1, 1)
				tgtBtn.Font = Enum.Font.GothamBold
				tgtBtn.TextSize = 11
				tgtBtn.Parent = row
				tgtBtn.MouseButton1Click:Connect(function()
					selectedTargetUid = entry.uid
					updateEnhancePreview()
					renderInventory()
				end)
			end
		end
	end
end

enhanceToggle.MouseButton1Click:Connect(function()
	enhanceMode = not enhanceMode
	enhanceToggle.BackgroundColor3 = enhanceMode and Color3.fromRGB(120, 90, 200) or Color3.fromRGB(80, 60, 140)
	selectedScrollId = nil
	selectedTargetUid = nil
	if visible then
		renderInventory()
	end
end)

enhanceConfirm.MouseButton1Click:Connect(function()
	if enhanceBusy or not selectedScrollId or not selectedTargetUid then
		return
	end
	enhanceBusy = true
	enhanceConfirm.Text = "..."
	local ok, result = remotes.ApplyEnhancement:InvokeServer(selectedScrollId, selectedTargetUid)
	enhanceBusy = false
	enhanceConfirm.Text = "Apply Scroll"
	if ok then
		selectedScrollId = nil
		selectedTargetUid = nil
	end
	if result and result.message then
		-- server sends EnhancementResult event separately
	end
	renderInventory()
end)

local function setVisible(value)
	if not hasSelectedClass then
		return
	end
	visible = value
	panel.Visible = visible
	if visible then
		renderInventory()
		remotes.RequestInventory:FireServer()
	end
end

local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleInventory"
toggleEvent.Parent = screenGui
toggleEvent.Event:Connect(function()
	setVisible(not visible)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not hasSelectedClass then
		return
	end
	if input.KeyCode == Enum.KeyCode.L then
		setVisible(not visible)
	end
end)

remotes.InventoryUpdated.OnClientEvent:Connect(function(newInventory)
	inventory = newInventory or {}
	if visible then
		renderInventory()
	end
end)

remotes.EnhancementResult.OnClientEvent:Connect(function(payload)
	enhanceBusy = false
	enhanceConfirm.Text = "Apply Scroll"
	if payload.outcome then
		renderInventory()
	end
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	hasSelectedClass = payload.hasSelectedClass == true
	equipped = payload.equipped or {}
	if not hasSelectedClass then
		setVisible(false)
	end
end)
