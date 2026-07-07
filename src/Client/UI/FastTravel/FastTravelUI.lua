local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FastTravelConfig = require(Shared.Config.FastTravel)
local FastTravelUtil = require(Shared.Util.FastTravelUtil)

local FastTravelUI = {}
FastTravelUI.__index = FastTravelUI

local PANEL_COLOR = Color3.fromRGB(30, 30, 40)
local LIST_COLOR = Color3.fromRGB(20, 20, 28)
local ACCENT = Color3.fromRGB(80, 100, 180)

function FastTravelUI.new(playerGui)
	local self = setmetatable({}, FastTravelUI)
	self._onTravel = nil
	self._onCancel = nil
	self._onSelect = nil
	self._currentLocationId = nil
	self._selectedId = nil
	self._searchText = ""
	self._activeCategory = "All"
	self._unlocked = {}
	self._playerLevel = 1
	self._listButtons = {}

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FastTravelUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 55
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "MainPanel"
	panel.Size = UDim2.new(0, 720, 0, 480)
	panel.Position = UDim2.new(0.5, -360, 0.5, -240)
	panel.BackgroundColor3 = PANEL_COLOR
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui
	self._panel = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	self._currentLabel = Instance.new("TextLabel")
	self._currentLabel.Size = UDim2.new(1, -20, 0, 32)
	self._currentLabel.Position = UDim2.new(0, 10, 0, 10)
	self._currentLabel.BackgroundTransparency = 1
	self._currentLabel.Text = "Current: Unknown"
	self._currentLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
	self._currentLabel.Font = Enum.Font.GothamBold
	self._currentLabel.TextSize = 16
	self._currentLabel.TextXAlignment = Enum.TextXAlignment.Left
	self._currentLabel.Parent = panel

	local leftPanel = Instance.new("Frame")
	leftPanel.Size = UDim2.new(0.42, -16, 1, -100)
	leftPanel.Position = UDim2.new(0, 10, 0, 48)
	leftPanel.BackgroundColor3 = LIST_COLOR
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = panel
	self._leftPanel = leftPanel
	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(0, 8)
	leftCorner.Parent = leftPanel

	self._searchBox = Instance.new("TextBox")
	self._searchBox.Size = UDim2.new(1, -16, 0, 30)
	self._searchBox.Position = UDim2.new(0, 8, 0, 8)
	self._searchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
	self._searchBox.PlaceholderText = "Search locations..."
	self._searchBox.Text = ""
	self._searchBox.TextColor3 = Color3.new(1, 1, 1)
	self._searchBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
	self._searchBox.Font = Enum.Font.Gotham
	self._searchBox.TextSize = 13
	self._searchBox.ClearTextOnFocus = false
	self._searchBox.Parent = leftPanel
	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 6)
	searchCorner.Parent = self._searchBox

	self._filterBar = Instance.new("Frame")
	self._filterBar.Size = UDim2.new(1, -16, 0, 28)
	self._filterBar.Position = UDim2.new(0, 8, 0, 44)
	self._filterBar.BackgroundTransparency = 1
	self._filterBar.Parent = leftPanel
	self._filterButtons = {}

	local filterLayout = Instance.new("UIListLayout")
	filterLayout.FillDirection = Enum.FillDirection.Horizontal
	filterLayout.Padding = UDim.new(0, 4)
	filterLayout.Parent = self._filterBar

	for _, category in FastTravelConfig.Categories do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 58, 1, 0)
		btn.BackgroundColor3 = category == "All" and ACCENT or Color3.fromRGB(45, 45, 60)
		btn.Text = category
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 10
		btn.Parent = self._filterBar
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = btn
		btn.MouseButton1Click:Connect(function()
			self:SetCategory(category)
		end)
		self._filterButtons[category] = btn
	end

	self._list = Instance.new("ScrollingFrame")
	self._list.Size = UDim2.new(1, -16, 1, -88)
	self._list.Position = UDim2.new(0, 8, 0, 80)
	self._list.BackgroundTransparency = 1
	self._list.BorderSizePixel = 0
	self._list.ScrollBarThickness = 5
	self._list.CanvasSize = UDim2.new(0, 0, 0, 0)
	self._list.Parent = leftPanel
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.Parent = self._list

	local rightPanel = Instance.new("Frame")
	rightPanel.Size = UDim2.new(0.58, -16, 1, -100)
	rightPanel.Position = UDim2.new(0.42, 6, 0, 48)
	rightPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	rightPanel.BorderSizePixel = 0
	rightPanel.Parent = panel
	self._rightPanel = rightPanel
	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(0, 8)
	rightCorner.Parent = rightPanel

	self._previewIcon = Instance.new("ImageLabel")
	self._previewIcon.Size = UDim2.new(1, -20, 0, 140)
	self._previewIcon.Position = UDim2.new(0, 10, 0, 10)
	self._previewIcon.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
	self._previewIcon.Image = ""
	self._previewIcon.ScaleType = Enum.ScaleType.Fit
	self._previewIcon.Parent = rightPanel
	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 8)
	previewCorner.Parent = self._previewIcon

	self._nameLabel = Instance.new("TextLabel")
	self._nameLabel.Size = UDim2.new(1, -20, 0, 28)
	self._nameLabel.Position = UDim2.new(0, 10, 0, 158)
	self._nameLabel.BackgroundTransparency = 1
	self._nameLabel.Text = "Select a destination"
	self._nameLabel.TextColor3 = Color3.new(1, 1, 1)
	self._nameLabel.Font = Enum.Font.GothamBold
	self._nameLabel.TextSize = 18
	self._nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	self._nameLabel.Parent = rightPanel

	self._regionLabel = Instance.new("TextLabel")
	self._regionLabel.Size = UDim2.new(1, -20, 0, 20)
	self._regionLabel.Position = UDim2.new(0, 10, 0, 186)
	self._regionLabel.BackgroundTransparency = 1
	self._regionLabel.Text = ""
	self._regionLabel.TextColor3 = Color3.fromRGB(140, 160, 200)
	self._regionLabel.Font = Enum.Font.Gotham
	self._regionLabel.TextSize = 12
	self._regionLabel.TextXAlignment = Enum.TextXAlignment.Left
	self._regionLabel.Parent = rightPanel

	self._levelLabel = Instance.new("TextLabel")
	self._levelLabel.Size = UDim2.new(1, -20, 0, 20)
	self._levelLabel.Position = UDim2.new(0, 10, 0, 206)
	self._levelLabel.BackgroundTransparency = 1
	self._levelLabel.Text = ""
	self._levelLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
	self._levelLabel.Font = Enum.Font.Gotham
	self._levelLabel.TextSize = 12
	self._levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	self._levelLabel.Parent = rightPanel

	self._descLabel = Instance.new("TextLabel")
	self._descLabel.Size = UDim2.new(1, -20, 0, 80)
	self._descLabel.Position = UDim2.new(0, 10, 0, 232)
	self._descLabel.BackgroundTransparency = 1
	self._descLabel.Text = ""
	self._descLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
	self._descLabel.Font = Enum.Font.Gotham
	self._descLabel.TextSize = 13
	self._descLabel.TextWrapped = true
	self._descLabel.TextXAlignment = Enum.TextXAlignment.Left
	self._descLabel.TextYAlignment = Enum.TextYAlignment.Top
	self._descLabel.Parent = rightPanel

	self._lockLabel = Instance.new("TextLabel")
	self._lockLabel.Size = UDim2.new(1, -20, 0, 24)
	self._lockLabel.Position = UDim2.new(0, 10, 0, 316)
	self._lockLabel.BackgroundTransparency = 1
	self._lockLabel.Text = ""
	self._lockLabel.TextColor3 = Color3.fromRGB(220, 120, 120)
	self._lockLabel.Font = Enum.Font.GothamBold
	self._lockLabel.TextSize = 12
	self._lockLabel.TextXAlignment = Enum.TextXAlignment.Left
	self._lockLabel.Parent = rightPanel

	self._travelBtn = Instance.new("TextButton")
	self._travelBtn.Size = UDim2.new(1, -20, 0, 40)
	self._travelBtn.Position = UDim2.new(0, 10, 1, -50)
	self._travelBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 80)
	self._travelBtn.Text = "Travel"
	self._travelBtn.TextColor3 = Color3.new(1, 1, 1)
	self._travelBtn.Font = Enum.Font.GothamBold
	self._travelBtn.TextSize = 16
	self._travelBtn.Parent = rightPanel
	local travelCorner = Instance.new("UICorner")
	travelCorner.CornerRadius = UDim.new(0, 8)
	travelCorner.Parent = self._travelBtn

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0, 120, 0, 36)
	cancelBtn.Position = UDim2.new(0.5, -60, 1, -44)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
	cancelBtn.Text = "Cancel"
	cancelBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 14
	cancelBtn.Parent = panel
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 8)
	cancelCorner.Parent = cancelBtn

	self._searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		self._searchText = string.lower(self._searchBox.Text)
		self:_renderList()
	end)

	self._travelBtn.MouseButton1Click:Connect(function()
		if self._selectedId and self._onTravel then
			self._onTravel(self._selectedId)
		end
	end)

	cancelBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
		if self._onCancel then
			self._onCancel()
		end
	end)

	return self
end

function FastTravelUI:OnTravel(callback)
	self._onTravel = callback
end

function FastTravelUI:OnCancel(callback)
	self._onCancel = callback
end

function FastTravelUI:OnSelect(callback)
	self._onSelect = callback
end

function FastTravelUI:SetUnlocked(unlocked)
	self._unlocked = unlocked or {}
	self:_renderList()
	self:_updatePreview()
end

function FastTravelUI:SetPlayerLevel(level)
	self._playerLevel = level or 1
	self:_updatePreview()
end

function FastTravelUI:SetCurrentLocation(locationId)
	self._currentLocationId = locationId
	local location = FastTravelUtil.GetLocation(FastTravelConfig, locationId)
	self._currentLabel.Text = "Current: " .. (location and location.displayName or "Unknown")
end

function FastTravelUI:SetCategory(category)
	self._activeCategory = category
	for name, btn in self._filterButtons do
		btn.BackgroundColor3 = name == category and ACCENT or Color3.fromRGB(45, 45, 60)
	end
	self:_renderList()
end

function FastTravelUI:SelectLocation(locationId)
	self._selectedId = locationId
	self:_renderList()
	self:_updatePreview()
	if self._onSelect then
		self._onSelect(locationId)
	end
end

function FastTravelUI:IsLocationSelectable(locationId)
	if locationId == self._currentLocationId then
		return false, "Already here"
	end
	if not self._unlocked[locationId] then
		local loc = FastTravelUtil.GetLocation(FastTravelConfig, locationId)
		return false, FastTravelUtil.GetUnlockHint(loc)
	end
	local loc = FastTravelUtil.GetLocation(FastTravelConfig, locationId)
	if loc and self._playerLevel < (loc.levelRequirement or 1) then
		return false, "Requires Level " .. tostring(loc.levelRequirement)
	end
	return true
end

function FastTravelUI:_renderList()
	for _, child in self._list:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	self._listButtons = {}

	for id, location in FastTravelUtil.GetEnabledLocations(FastTravelConfig) do
		local matchesCategory = self._activeCategory == "All" or location.category == self._activeCategory
		local matchesSearch = self._searchText == ""
			or string.find(string.lower(location.displayName), self._searchText, 1, true)
			or string.find(string.lower(location.region or ""), self._searchText, 1, true)

		if matchesCategory and matchesSearch then
			local isUnlocked = self._unlocked[id] == true
			local isCurrent = id == self._currentLocationId
			local isSelected = id == self._selectedId

			local row = Instance.new("TextButton")
			row.Size = UDim2.new(1, -4, 0, 44)
			row.BackgroundColor3 = isSelected and ACCENT or Color3.fromRGB(40, 40, 55)
			row.Text = ""
			row.AutoButtonColor = false
			row.Parent = self._list

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 6)
			rowCorner.Parent = row

			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -50, 1, 0)
			name.Position = UDim2.new(0, 10, 0, 0)
			name.BackgroundTransparency = 1
			name.Text = location.displayName .. (isCurrent and " (Here)" or "")
			name.TextColor3 = isUnlocked and Color3.new(1, 1, 1) or Color3.fromRGB(130, 130, 140)
			name.Font = Enum.Font.GothamBold
			name.TextSize = 13
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Parent = row

			if not isUnlocked then
				local lock = Instance.new("TextLabel")
				lock.Size = UDim2.new(0, 24, 0, 24)
				lock.Position = UDim2.new(1, -30, 0.5, -12)
				lock.BackgroundTransparency = 1
				lock.Text = "🔒"
				lock.TextSize = 14
				lock.Parent = row
			end

			row.MouseEnter:Connect(function()
				if not isSelected then
					TweenService:Create(row, TweenInfo.new(0.12), {
						BackgroundColor3 = Color3.fromRGB(55, 55, 72),
					}):Play()
				end
			end)
			row.MouseLeave:Connect(function()
				if not isSelected then
					TweenService:Create(row, TweenInfo.new(0.12), {
						BackgroundColor3 = Color3.fromRGB(40, 40, 55),
					}):Play()
				end
			end)

			row.MouseButton1Click:Connect(function()
				self:SelectLocation(id)
			end)

			self._listButtons[id] = row
		end
	end

	task.defer(function()
		local layout = self._list:FindFirstChildOfClass("UIListLayout")
		if layout then
			self._list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
		end
	end)
end

function FastTravelUI:_updatePreview()
	local location = FastTravelUtil.GetLocation(FastTravelConfig, self._selectedId)
	if not location then
		self._nameLabel.Text = "Select a destination"
		self._regionLabel.Text = ""
		self._levelLabel.Text = ""
		self._descLabel.Text = ""
		self._lockLabel.Text = ""
		self._previewIcon.Image = ""
		self._travelBtn.Active = false
		self._travelBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		return
	end

	self._nameLabel.Text = location.displayName
	self._regionLabel.Text = "Region: " .. (location.region or "Unknown")
	self._levelLabel.Text = "Recommended Level: " .. tostring(location.levelRequirement or 1)
	self._descLabel.Text = location.description or ""
	self._previewIcon.Image = location.icon or ""

	local canSelect, reason = self:IsLocationSelectable(self._selectedId)
	self._lockLabel.Text = canSelect and "" or (reason or "Locked")
	self._travelBtn.Active = canSelect
	self._travelBtn.BackgroundColor3 = canSelect and Color3.fromRGB(60, 120, 80) or Color3.fromRGB(80, 80, 80)
end

function FastTravelUI:SetVisible(visible)
	self._panel.Visible = visible
	if visible then
		self._panel.Size = UDim2.new(0, 680, 0, 450)
		TweenService:Create(self._panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 720, 0, 480),
		}):Play()
		self:_renderList()
		self:_updatePreview()
	end
end

function FastTravelUI:IsVisible()
	return self._panel.Visible
end

return FastTravelUI
