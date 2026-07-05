local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local inventory = {}
local visible = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "InventoryPanel"
panel.Size = UDim2.new(0, 320, 0, 280)
panel.Position = UDim2.new(0.5, -160, 0.5, -140)
panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 36)
title.Position = UDim2.new(0, 10, 0, 8)
title.BackgroundTransparency = 1
title.Text = "Inventory (Press I to close)"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

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

local function renderInventory()
	for _, child in listFrame:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	if #inventory == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 40)
		empty.BackgroundTransparency = 1
		empty.Text = "No items yet. Defeat goblins for drops!"
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
			row.Size = UDim2.new(1, -8, 0, 48)
			row.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
			row.BorderSizePixel = 0
			row.Parent = listFrame

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 6)
			rowCorner.Parent = row

			local icon = Instance.new("Frame")
			icon.Size = UDim2.new(0, 32, 0, 32)
			icon.Position = UDim2.new(0, 8, 0.5, -16)
			icon.BackgroundColor3 = item.color
			icon.BorderSizePixel = 0
			icon.Parent = row

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -120, 0, 22)
			nameLabel.Position = UDim2.new(0, 48, 0, 6)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = item.name .. " x" .. entry.count
			nameLabel.TextColor3 = Color3.new(1, 1, 1)
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = 14
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = row

			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, -120, 0, 18)
			descLabel.Position = UDim2.new(0, 48, 0, 26)
			descLabel.BackgroundTransparency = 1
			descLabel.Text = item.description
			descLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextSize = 11
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.Parent = row

			if item.usable then
				local useBtn = Instance.new("TextButton")
				useBtn.Size = UDim2.new(0, 56, 0, 32)
				useBtn.Position = UDim2.new(1, -64, 0.5, -16)
				useBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 80)
				useBtn.Text = "Use"
				useBtn.TextColor3 = Color3.new(1, 1, 1)
				useBtn.Font = Enum.Font.GothamBold
				useBtn.TextSize = 14
				useBtn.Parent = row

				local btnCorner = Instance.new("UICorner")
				btnCorner.CornerRadius = UDim.new(0, 6)
				btnCorner.Parent = useBtn

				useBtn.MouseButton1Click:Connect(function()
					remotes.UseItem:FireServer(entry.id)
				end)
			end
		end
	end

	task.defer(function()
		listFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
	end)
end

local function setVisible(value)
	visible = value
	panel.Visible = visible
	if visible then
		renderInventory()
		remotes.RequestInventory:FireServer()
	end
end

-- Expose a BindableEvent so UIController can toggle the inventory
local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleInventory"
toggleEvent.Parent = screenGui

toggleEvent.Event:Connect(function()
	setVisible(not visible)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.I then
		setVisible(not visible)
	end
end)

remotes.InventoryUpdated.OnClientEvent:Connect(function(newInventory)
	inventory = newInventory or {}
	if visible then
		renderInventory()
	end
end)

remotes.RequestInventory:FireServer()
