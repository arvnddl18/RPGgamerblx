local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local RarityConfig = require(Shared.Config.RarityConfig)

local FloatingText = require(script.Parent.Parent.Parent.Util.FloatingText)

local TreasureChestUI = {}
TreasureChestUI._screenGui = nil
TreasureChestUI._container = nil

function TreasureChestUI:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._remotes = Framework:GetRemotesFolder()
	
	-- Create the UI
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	self._screenGui = Instance.new("ScreenGui")
	self._screenGui.Name = "TreasureChestUI"
	self._screenGui.ResetOnSpawn = false
	self._screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	self._screenGui.Parent = playerGui

	-- Dark overlay
	self._overlay = Instance.new("Frame")
	self._overlay.Name = "Overlay"
	self._overlay.Size = UDim2.new(1, 0, 1, 0)
	self._overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	self._overlay.BackgroundTransparency = 1
	self._overlay.Visible = false
	self._overlay.Parent = self._screenGui

	-- Main container
	self._container = Instance.new("Frame")
	self._container.Name = "Container"
	self._container.Size = UDim2.new(0, 400, 0, 300)
	self._container.Position = UDim2.new(0.5, 0, 0.5, 0)
	self._container.AnchorPoint = Vector2.new(0.5, 0.5)
	self._container.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	self._container.BorderSizePixel = 0
	self._container.BackgroundTransparency = 1
	self._container.Visible = false
	self._container.Parent = self._screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 12)
	uiCorner.Parent = self._container

	-- Title
	self._title = Instance.new("TextLabel")
	self._title.Name = "Title"
	self._title.Size = UDim2.new(1, 0, 0, 40)
	self._title.Position = UDim2.new(0, 0, 0, 10)
	self._title.BackgroundTransparency = 1
	self._title.Font = Enum.Font.GothamBold
	self._title.Text = "Treasure Obtained!"
	self._title.TextColor3 = Color3.new(1, 1, 1)
	self._title.TextSize = 24
	self._title.TextTransparency = 1
	self._title.Parent = self._container

	-- Items list (ScrollingFrame)
	self._itemsList = Instance.new("ScrollingFrame")
	self._itemsList.Name = "ItemsList"
	self._itemsList.Size = UDim2.new(1, -20, 1, -70)
	self._itemsList.Position = UDim2.new(0, 10, 0, 60)
	self._itemsList.BackgroundTransparency = 1
	self._itemsList.ScrollBarThickness = 4
	self._itemsList.CanvasSize = UDim2.new(0, 0, 0, 0)
	self._itemsList.Parent = self._container

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = self._itemsList

	-- Automatically adjust canvas size
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self._itemsList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
	end)

	-- Button to close
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(1, 0, 1, 0)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = ""
	closeBtn.Parent = self._overlay

	closeBtn.MouseButton1Click:Connect(function()
		self:Hide()
	end)
end

function TreasureChestUI:_createItemEntry(itemData, layoutOrder)
	local itemConfig = Items[itemData.itemId]
	local rarityColor = RarityConfig.GetColor(itemData.rarity or "Common")
	local itemName = itemConfig and itemConfig.name or itemData.itemId

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -10, 0, 40)
	frame.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	frame.BorderSizePixel = 0
	frame.LayoutOrder = layoutOrder
	frame.BackgroundTransparency = 1

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 6)
	uiCorner.Parent = frame

	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.new(0, 30, 0, 30)
	iconFrame.Position = UDim2.new(0, 5, 0.5, 0)
	iconFrame.AnchorPoint = Vector2.new(0, 0.5)
	iconFrame.BackgroundColor3 = itemConfig and itemConfig.color or rarityColor
	iconFrame.BorderSizePixel = 0
	iconFrame.BackgroundTransparency = 1
	iconFrame.Parent = frame

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0, 4)
	iconCorner.Parent = iconFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -90, 1, 0)
	nameLabel.Position = UDim2.new(0, 45, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamMedium
	nameLabel.Text = itemName
	nameLabel.TextColor3 = rarityColor
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTransparency = 1
	nameLabel.Parent = frame

	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(0, 40, 1, 0)
	countLabel.Position = UDim2.new(1, -45, 0, 0)
	countLabel.BackgroundTransparency = 1
	countLabel.Font = Enum.Font.GothamBold
	countLabel.Text = "x" .. tostring(itemData.count)
	countLabel.TextColor3 = Color3.new(1, 1, 1)
	countLabel.TextSize = 16
	countLabel.TextXAlignment = Enum.TextXAlignment.Right
	countLabel.TextTransparency = 1
	countLabel.Parent = frame

	return frame, { iconFrame, nameLabel, countLabel }
end

function TreasureChestUI:Show(chestData)
	-- chestData = { chestRarity = "Rare", items = { {itemId="Gold", rarity="Rare", count=1}, ... } }
	
	-- Clear old items
	for _, child in self._itemsList:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	self._title.Text = chestData.chestRarity .. " Chest Opened!"
	self._title.TextColor3 = RarityConfig.GetColor(chestData.chestRarity)

	local allElements = { self._title }

	for i, itemData in ipairs(chestData.items) do
		local entry, innerElements = self:_createItemEntry(itemData, i)
		entry.Parent = self._itemsList
		table.insert(allElements, entry)
		for _, el in innerElements do
			table.insert(allElements, el)
		end
		
		-- Spawn 3D floating text indicator above the chest if position exists
		if chestData.position then
			local itemConfig = Items[itemData.itemId]
			local itemName = itemConfig and itemConfig.name or itemData.itemId
			local rarityColor = RarityConfig.GetColor(itemData.rarity or "Common")
			FloatingText.ShowLootDrop(chestData.position, itemName, itemData.count, rarityColor)
		end
	end

	self._overlay.Visible = true
	self._container.Visible = true

	-- Animate in
	TweenService:Create(self._overlay, TweenInfo.new(0.3), { BackgroundTransparency = 0.5 }):Play()
	TweenService:Create(self._container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { 
		BackgroundTransparency = 0,
		Size = UDim2.new(0, 400, 0, 300)
	}):Play()
	
	self._container.Size = UDim2.new(0, 380, 0, 280) -- slight pop effect

	for _, el in allElements do
		if el:IsA("TextLabel") or el:IsA("TextButton") then
			TweenService:Create(el, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
		elseif el:IsA("Frame") or el:IsA("ScrollingFrame") then
			TweenService:Create(el, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
		end
	end

	-- Auto hide after 5 seconds
	if self._hideTask then
		task.cancel(self._hideTask)
	end
	self._hideTask = task.delay(5, function()
		self:Hide()
	end)
end

function TreasureChestUI:Hide()
	if self._hideTask then
		task.cancel(self._hideTask)
		self._hideTask = nil
	end

	TweenService:Create(self._overlay, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	
	local hideTween = TweenService:Create(self._container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { 
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 380, 0, 280)
	})
	
	hideTween:Play()

	for _, child in self._itemsList:GetChildren() do
		if child:IsA("Frame") then
			TweenService:Create(child, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
			for _, subChild in child:GetChildren() do
				if subChild:IsA("TextLabel") then
					TweenService:Create(subChild, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
				elseif subChild:IsA("Frame") then
					TweenService:Create(subChild, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
				end
			end
		end
	end

	TweenService:Create(self._title, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()

	hideTween.Completed:Connect(function()
		self._overlay.Visible = false
		self._container.Visible = false
	end)
end

function TreasureChestUI:Start()
	self._remotes.ChestOpened.OnClientEvent:Connect(function(chestData)
		self:Show(chestData)
	end)
end

return TreasureChestUI
