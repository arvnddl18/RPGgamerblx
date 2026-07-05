local ShopUI = {}
ShopUI.__index = ShopUI

local TAB_COLORS = {
	active = Color3.fromRGB(80, 100, 180),
	inactive = Color3.fromRGB(45, 45, 60),
}

function ShopUI.new(playerGui)
	local self = setmetatable({}, ShopUI)
	self._playerLevel = 1
	self._onPurchase = nil
	self._activeTab = "materials"

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShopUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.Size = UDim2.new(0, 400, 0, 420)
	panel.Position = UDim2.new(0.5, -200, 0.5, -210)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui
	self._panel = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 36)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "Shop"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -42, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = panel
	closeBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, -20, 0, 36)
	tabBar.Position = UDim2.new(0, 10, 0, 48)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = panel
	self._tabBar = tabBar

	self._tabButtons = {}
	for i, tabId in { "materials", "scrolls" } do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.5, -4, 1, 0)
		btn.Position = UDim2.new((i - 1) * 0.5, (i - 1) * 4, 0, 0)
		btn.BackgroundColor3 = TAB_COLORS.inactive
		btn.Text = tabId == "materials" and "Materials" or "Scrolls"
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.Parent = tabBar
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn
		btn.MouseButton1Click:Connect(function()
			self:SetTab(tabId)
		end)
		self._tabButtons[tabId] = btn
	end

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -20, 1, -100)
	list.Position = UDim2.new(0, 10, 0, 92)
	list.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.Parent = panel
	self._list = list

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	self._shopItems = {}
	return self
end

function ShopUI:OnPurchase(callback)
	self._onPurchase = callback
end

function ShopUI:SetPlayerLevel(level)
	self._playerLevel = level or 1
end

function ShopUI:SetTab(tabId)
	self._activeTab = tabId
	for id, btn in self._tabButtons do
		btn.BackgroundColor3 = id == tabId and TAB_COLORS.active or TAB_COLORS.inactive
	end
	self:_render()
end

function ShopUI:SetItems(items)
	self._shopItems = items or {}
	self:_render()
end

function ShopUI:SetVisible(visible)
	self._panel.Visible = visible
end

function ShopUI:_render()
	for _, child in self._list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for _, item in self._shopItems do
		local category = item.category or "materials"
		if category == self._activeTab then
		local locked = item.requiredLevel and self._playerLevel < item.requiredLevel
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 72)
		row.BackgroundColor3 = locked and Color3.fromRGB(35, 35, 45) or Color3.fromRGB(40, 40, 55)
		row.BorderSizePixel = 0
		row.Parent = self._list

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -160, 0, 22)
		nameLabel.Position = UDim2.new(0, 10, 0, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = item.name
		nameLabel.TextColor3 = locked and Color3.fromRGB(140, 140, 140) or Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 14
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local desc = item.description or ""
		if locked then
			desc = "Requires Level " .. item.requiredLevel
		end
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -160, 0, 36)
		descLabel.Position = UDim2.new(0, 10, 0, 28)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = desc
		descLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 11
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.Parent = row

		local qtyBox = Instance.new("TextBox")
		qtyBox.Size = UDim2.new(0, 40, 0, 28)
		qtyBox.Position = UDim2.new(1, -130, 0.5, -14)
		qtyBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		qtyBox.Text = "1"
		qtyBox.TextColor3 = Color3.new(1, 1, 1)
		qtyBox.Font = Enum.Font.Gotham
		qtyBox.TextSize = 14
		qtyBox.Visible = category == "materials"
		qtyBox.Parent = row

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 72, 0, 32)
		buyBtn.Position = UDim2.new(1, -82, 0.5, -16)
		buyBtn.BackgroundColor3 = locked and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 140, 50)
		buyBtn.Text = item.price .. "g"
		buyBtn.TextColor3 = Color3.new(1, 1, 1)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextSize = 13
		buyBtn.Active = not locked
		buyBtn.AutoButtonColor = not locked
		buyBtn.Parent = row

		if not locked then
			buyBtn.MouseButton1Click:Connect(function()
				local qty = math.clamp(tonumber(qtyBox.Text) or 1, 1, 99)
				if self._onPurchase then
					self._onPurchase(item.itemId, qty)
				end
			end)
		end
		end
	end

	task.defer(function()
		local layout = self._list:FindFirstChildOfClass("UIListLayout")
		if layout then
			self._list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
		end
	end)
end

return ShopUI
