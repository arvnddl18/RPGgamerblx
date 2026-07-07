local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FastTravelConfig = require(Shared.Config.FastTravel)
local FastTravelUtil = require(Shared.Util.FastTravelUtil)
local WorldMapTerrainRenderer = require(script.Parent.WorldMapTerrainRenderer)

local FastTravelWorldMapUI = {}
FastTravelWorldMapUI.__index = FastTravelWorldMapUI

function FastTravelWorldMapUI.new(playerGui)
	local self = setmetatable({}, FastTravelWorldMapUI)
	self._onSelect = nil
	self._onTravel = nil
	self._onClose = nil
	self._unlocked = {}
	self._playerLevel = 1
	self._currentLocationId = nil
	self._selectedId = nil
	self._playerPosition = Vector3.zero
	self._zoom = 1
	self._panOffset = Vector2.zero
	self._dragging = false
	self._dragStart = nil
	self._markers = {}
	self._markersBuilt = false
	self._terrainBuilt = false

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FastTravelWorldMapUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 58
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "WorldMapPanel"
	panel.Size = UDim2.fromScale(1, 1)
	panel.Position = UDim2.fromOffset(0, 0)
	panel.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui
	self._panel = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 200, 0, 40)
	title.Position = UDim2.new(0, 16, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "World Map"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 20
	title.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.Position = UDim2.new(1, -56, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.ZIndex = 20
	closeBtn.Parent = panel
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Size = UDim2.new(1, -32, 1, -72)
	body.Position = UDim2.new(0, 16, 0, 56)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.ZIndex = 2
	body.Parent = panel
	self._body = body

	local mapViewport = Instance.new("Frame")
	mapViewport.Name = "MapViewport"
	mapViewport.Size = UDim2.new(1, -316, 1, 1)
	mapViewport.Position = UDim2.fromOffset(0, 0)
	mapViewport.BackgroundColor3 = Color3.fromRGB(18, 28, 22)
	mapViewport.ClipsDescendants = true
	mapViewport.BorderSizePixel = 0
	mapViewport.ZIndex = 1
	mapViewport.Parent = body
	self._mapViewport = mapViewport
	local mapCorner = Instance.new("UICorner")
	mapCorner.CornerRadius = UDim.new(0, 10)
	mapCorner.Parent = mapViewport

	local squareMap = Instance.new("Frame")
	squareMap.Name = "SquareMapContainer"
	squareMap.AnchorPoint = Vector2.new(0.5, 0.5)
	squareMap.Position = UDim2.fromScale(0.5, 0.5)
	squareMap.Size = UDim2.fromScale(1, 1)
	squareMap.BackgroundTransparency = 1
	squareMap.BorderSizePixel = 0
	squareMap.Parent = mapViewport
	self._squareMap = squareMap

	local squareAspect = Instance.new("UIAspectRatioConstraint")
	squareAspect.AspectRatio = 1
	squareAspect.Parent = squareMap

	local mapCanvas = Instance.new("Frame")
	mapCanvas.Name = "MapCanvas"
	mapCanvas.Size = UDim2.fromScale(1, 1)
	mapCanvas.BackgroundTransparency = 1
	mapCanvas.Parent = squareMap
	self._mapCanvas = mapCanvas

	local mapScale = Instance.new("UIScale")
	mapScale.Scale = 1
	mapScale.Parent = mapCanvas
	self._mapScale = mapScale

	local grid = Instance.new("Frame")
	grid.Name = "TerrainFallback"
	grid.Size = UDim2.fromScale(1, 1)
	grid.BackgroundColor3 = Color3.fromRGB(30, 45, 35)
	grid.BorderSizePixel = 0
	grid.ZIndex = 1
	grid.Parent = mapCanvas
	self._terrainFallback = grid

	local terrainHost = Instance.new("Frame")
	terrainHost.Name = "TerrainHost"
	terrainHost.Size = UDim2.fromScale(1, 1)
	terrainHost.BackgroundTransparency = 1
	terrainHost.BorderSizePixel = 0
	terrainHost.ZIndex = 2
	terrainHost.Visible = false
	terrainHost.Parent = mapCanvas
	self._terrainHost = terrainHost

	local loadingLabel = Instance.new("TextLabel")
	loadingLabel.Name = "TerrainLoading"
	loadingLabel.Size = UDim2.new(0, 220, 0, 28)
	loadingLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingLabel.Position = UDim2.fromScale(0.5, 0.5)
	loadingLabel.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
	loadingLabel.BackgroundTransparency = 0.15
	loadingLabel.Text = "Rendering terrain..."
	loadingLabel.TextColor3 = Color3.fromRGB(200, 210, 220)
	loadingLabel.Font = Enum.Font.GothamBold
	loadingLabel.TextSize = 14
	loadingLabel.ZIndex = 15
	loadingLabel.Visible = false
	loadingLabel.Parent = mapCanvas
	self._terrainLoadingLabel = loadingLabel
	local loadingCorner = Instance.new("UICorner")
	loadingCorner.CornerRadius = UDim.new(0, 6)
	loadingCorner.Parent = loadingLabel

	local playerDot = Instance.new("Frame")
	playerDot.Name = "PlayerDot"
	playerDot.Size = UDim2.new(0, 12, 0, 12)
	playerDot.AnchorPoint = Vector2.new(0.5, 0.5)
	playerDot.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	playerDot.BorderSizePixel = 0
	playerDot.ZIndex = 10
	playerDot.Parent = mapCanvas
	self._playerDot = playerDot
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = playerDot
	local dotStroke = Instance.new("UIStroke")
	dotStroke.Color = Color3.fromRGB(12, 28, 18)
	dotStroke.Thickness = 2
	dotStroke.Parent = playerDot

	local infoPanel = Instance.new("Frame")
	infoPanel.Name = "InfoPanel"
	infoPanel.Size = UDim2.new(0, 300, 1, 1)
	infoPanel.Position = UDim2.new(1, -300, 0, 0)
	infoPanel.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
	infoPanel.BackgroundTransparency = 0
	infoPanel.BorderSizePixel = 0
	infoPanel.ClipsDescendants = false
	infoPanel.ZIndex = 5
	infoPanel.Parent = body
	self._infoPanel = infoPanel
	local infoCorner = Instance.new("UICorner")
	infoCorner.CornerRadius = UDim.new(0, 10)
	infoCorner.Parent = infoPanel
	local infoStroke = Instance.new("UIStroke")
	infoStroke.Color = Color3.fromRGB(90, 110, 150)
	infoStroke.Thickness = 2
	infoStroke.Parent = infoPanel

	local infoHeader = Instance.new("TextLabel")
	infoHeader.Name = "InfoHeader"
	infoHeader.Size = UDim2.new(1, -28, 0, 22)
	infoHeader.Position = UDim2.fromOffset(14, 14)
	infoHeader.BackgroundTransparency = 1
	infoHeader.Text = "LOCATION"
	infoHeader.TextColor3 = Color3.fromRGB(120, 140, 180)
	infoHeader.Font = Enum.Font.GothamBold
	infoHeader.TextSize = 12
	infoHeader.TextXAlignment = Enum.TextXAlignment.Left
	infoHeader.ZIndex = 6
	infoHeader.Parent = infoPanel

	self._infoName = Instance.new("TextLabel")
	self._infoName.Size = UDim2.new(1, -28, 0, 40)
	self._infoName.Position = UDim2.fromOffset(14, 40)
	self._infoName.BackgroundTransparency = 1
	self._infoName.Text = "Select a location"
	self._infoName.TextColor3 = Color3.new(1, 1, 1)
	self._infoName.Font = Enum.Font.GothamBold
	self._infoName.TextSize = 20
	self._infoName.TextXAlignment = Enum.TextXAlignment.Left
	self._infoName.TextWrapped = true
	self._infoName.TextYAlignment = Enum.TextYAlignment.Top
	self._infoName.ZIndex = 6
	self._infoName.Parent = infoPanel

	self._infoRegion = Instance.new("TextLabel")
	self._infoRegion.Size = UDim2.new(1, -28, 0, 22)
	self._infoRegion.Position = UDim2.fromOffset(14, 84)
	self._infoRegion.BackgroundTransparency = 1
	self._infoRegion.Text = "Tap a map icon"
	self._infoRegion.TextColor3 = Color3.fromRGB(140, 160, 200)
	self._infoRegion.Font = Enum.Font.Gotham
	self._infoRegion.TextSize = 14
	self._infoRegion.TextXAlignment = Enum.TextXAlignment.Left
	self._infoRegion.ZIndex = 6
	self._infoRegion.Parent = infoPanel

	self._infoDesc = Instance.new("TextLabel")
	self._infoDesc.Size = UDim2.new(1, -28, 0, 140)
	self._infoDesc.Position = UDim2.fromOffset(14, 112)
	self._infoDesc.BackgroundTransparency = 1
	self._infoDesc.Text = ""
	self._infoDesc.TextColor3 = Color3.fromRGB(200, 202, 214)
	self._infoDesc.Font = Enum.Font.Gotham
	self._infoDesc.TextSize = 14
	self._infoDesc.TextWrapped = true
	self._infoDesc.TextXAlignment = Enum.TextXAlignment.Left
	self._infoDesc.TextYAlignment = Enum.TextYAlignment.Top
	self._infoDesc.ZIndex = 6
	self._infoDesc.Parent = infoPanel

	self._infoLock = Instance.new("TextLabel")
	self._infoLock.Size = UDim2.new(1, -28, 0, 40)
	self._infoLock.Position = UDim2.new(0, 14, 1, -104)
	self._infoLock.BackgroundTransparency = 1
	self._infoLock.Text = ""
	self._infoLock.TextColor3 = Color3.fromRGB(255, 170, 140)
	self._infoLock.Font = Enum.Font.GothamBold
	self._infoLock.TextSize = 13
	self._infoLock.TextWrapped = true
	self._infoLock.TextXAlignment = Enum.TextXAlignment.Left
	self._infoLock.ZIndex = 6
	self._infoLock.Parent = infoPanel

	self._travelBtn = Instance.new("TextButton")
	self._travelBtn.Size = UDim2.new(1, -28, 0, 44)
	self._travelBtn.Position = UDim2.new(0, 14, 1, -58)
	self._travelBtn.BackgroundColor3 = Color3.fromRGB(55, 130, 80)
	self._travelBtn.Text = "Travel"
	self._travelBtn.TextColor3 = Color3.new(1, 1, 1)
	self._travelBtn.Font = Enum.Font.GothamBold
	self._travelBtn.TextSize = 16
	self._travelBtn.AutoButtonColor = false
	self._travelBtn.ZIndex = 6
	self._travelBtn.Parent = infoPanel
	self._canTravelSelected = false
	local travelCorner = Instance.new("UICorner")
	travelCorner.CornerRadius = UDim.new(0, 6)
	travelCorner.Parent = self._travelBtn

	local zoomOut = Instance.new("TextButton")
	zoomOut.Size = UDim2.new(0, 40, 0, 40)
	zoomOut.Position = UDim2.new(0, 24, 1, -56)
	zoomOut.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	zoomOut.Text = "-"
	zoomOut.TextColor3 = Color3.new(1, 1, 1)
	zoomOut.Font = Enum.Font.GothamBold
	zoomOut.TextSize = 22
	zoomOut.ZIndex = 20
	zoomOut.Parent = panel
	local zoomOutCorner = Instance.new("UICorner")
	zoomOutCorner.CornerRadius = UDim.new(0, 6)
	zoomOutCorner.Parent = zoomOut

	local zoomIn = Instance.new("TextButton")
	zoomIn.Size = UDim2.new(0, 40, 0, 40)
	zoomIn.Position = UDim2.new(0, 72, 1, -56)
	zoomIn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	zoomIn.Text = "+"
	zoomIn.TextColor3 = Color3.new(1, 1, 1)
	zoomIn.Font = Enum.Font.GothamBold
	zoomIn.TextSize = 22
	zoomIn.ZIndex = 20
	zoomIn.Parent = panel

	local resetView = Instance.new("TextButton")
	resetView.Size = UDim2.new(0, 88, 0, 40)
	resetView.Position = UDim2.new(0, 120, 1, -56)
	resetView.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	resetView.Text = "Reset"
	resetView.TextColor3 = Color3.new(1, 1, 1)
	resetView.Font = Enum.Font.GothamBold
	resetView.TextSize = 14
	resetView.ZIndex = 20
	resetView.Parent = panel
	local resetCorner = Instance.new("UICorner")
	resetCorner.CornerRadius = UDim.new(0, 6)
	resetCorner.Parent = resetView
	local zoomInCorner = Instance.new("UICorner")
	zoomInCorner.CornerRadius = UDim.new(0, 6)
	zoomInCorner.Parent = zoomIn

	closeBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
		if self._onClose then
			self._onClose()
		end
	end)

	zoomIn.MouseButton1Click:Connect(function()
		self._zoom = math.clamp(self._zoom + 0.15, 0.5, 3.5)
		self._mapScale.Scale = self._zoom
	end)

	zoomOut.MouseButton1Click:Connect(function()
		self._zoom = math.clamp(self._zoom - 0.15, 0.5, 3.5)
		self._mapScale.Scale = self._zoom
	end)

	resetView.MouseButton1Click:Connect(function()
		self:_resetView()
	end)

	self._travelBtn.MouseButton1Click:Connect(function()
		if self._canTravelSelected and self._selectedId and self._onTravel then
			self._onTravel(self._selectedId)
		end
	end)

	mapViewport.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._dragging = true
			self._dragStart = input.Position
		end
	end)

	mapViewport.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self._dragging = false
			self._dragStart = nil
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not self._panel.Visible or not self._dragging or not self._dragStart then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - self._dragStart
			self._dragStart = input.Position
			self._panOffset += Vector2.new(delta.X, delta.Y)
			self._mapCanvas.Position = UDim2.fromOffset(self._panOffset.X, self._panOffset.Y)
		end
	end)

	self._markersBuilt = false
	return self
end

function FastTravelWorldMapUI:_resetView()
	self._panOffset = Vector2.zero
	self._mapCanvas.Position = UDim2.fromOffset(0, 0)
	self._zoom = 1
	self._mapScale.Scale = 1
end

function FastTravelWorldMapUI:_applyTerrainLayer(layer)
	if not layer or not self._terrainHost then
		return
	end

	if layer.Parent ~= self._terrainHost then
		for _, child in self._terrainHost:GetChildren() do
			if child ~= layer then
				child:Destroy()
			end
		end
		layer.Parent = self._terrainHost
	end

	self._terrainHost.Visible = true
	self._terrainFallback.Visible = false
	self._terrainLoadingLabel.Visible = false
	self._terrainBuilt = true
end

function FastTravelWorldMapUI:_ensureTerrain()
	if self._terrainBuilt then
		return
	end

	self._terrainLoadingLabel.Visible = true
	WorldMapTerrainRenderer.GetTerrainLayer(FastTravelConfig.MapBounds, 160, function(layer)
		if not self._panel.Visible then
			return
		end
		if layer then
			self:_applyTerrainLayer(layer)
		else
			self._terrainLoadingLabel.Text = "Terrain unavailable"
		end
	end)
end

function FastTravelWorldMapUI:_ensureMarkers()
	if self._markersBuilt then
		return
	end
	self._markersBuilt = true
	self:_buildMarkers()
end

function FastTravelWorldMapUI:OnSelect(callback)
	self._onSelect = callback
end

function FastTravelWorldMapUI:OnTravel(callback)
	self._onTravel = callback
end

function FastTravelWorldMapUI:OnClose(callback)
	self._onClose = callback
end

function FastTravelWorldMapUI:SetUnlocked(unlocked)
	self._unlocked = unlocked or {}
	self:_updateMarkerStates()
	self:_updateInfo()
end

function FastTravelWorldMapUI:SetPlayerLevel(level)
	self._playerLevel = level or 1
	self:_updateInfo()
end

function FastTravelWorldMapUI:SetCurrentLocation(locationId)
	self._currentLocationId = locationId
	self:_updateInfo()
end

function FastTravelWorldMapUI:SetPlayerPosition(position)
	self._playerPosition = position or Vector3.zero
	local x, z = FastTravelUtil.WorldToMapPercent(self._playerPosition, FastTravelConfig.MapBounds)
	self._playerDot.Position = UDim2.fromScale(x, z)
end

function FastTravelWorldMapUI:SelectLocation(locationId)
	self._selectedId = locationId
	self:_updateMarkerStates()
	self:_updateInfo()
	if self._onSelect then
		self._onSelect(locationId)
	end
end

function FastTravelWorldMapUI:_buildMarkers()
	for id, location in FastTravelUtil.GetEnabledLocations(FastTravelConfig) do
		local x, z = FastTravelUtil.WorldToMapPercent(location.position, FastTravelConfig.MapBounds)

		local marker = Instance.new("ImageButton")
		marker.Name = id
		marker.Size = UDim2.new(0, 28, 0, 28)
		marker.AnchorPoint = Vector2.new(0.5, 0.5)
		marker.Position = UDim2.fromScale(x, z)
		marker.BackgroundTransparency = 1
		marker.Image = location.icon or ""
		marker.ImageColor3 = Color3.new(1, 1, 1)
		marker.ScaleType = Enum.ScaleType.Fit
		marker.ZIndex = 8
		marker.Parent = self._mapCanvas

		local tooltip = Instance.new("TextLabel")
		tooltip.Size = UDim2.new(0, 120, 0, 20)
		tooltip.Position = UDim2.new(0.5, -60, 0, -24)
		tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		tooltip.BackgroundTransparency = 0.2
		tooltip.Text = location.displayName
		tooltip.TextColor3 = Color3.new(1, 1, 1)
		tooltip.Font = Enum.Font.GothamBold
		tooltip.TextSize = 10
		tooltip.Visible = false
		tooltip.ZIndex = 6
		tooltip.Parent = marker
		local tipCorner = Instance.new("UICorner")
		tipCorner.CornerRadius = UDim.new(0, 4)
		tipCorner.Parent = tooltip

		marker.MouseEnter:Connect(function()
			tooltip.Visible = true
			TweenService:Create(marker, TweenInfo.new(0.15), { Size = UDim2.new(0, 34, 0, 34) }):Play()
		end)
		marker.MouseLeave:Connect(function()
			tooltip.Visible = false
			local size = id == self._selectedId and UDim2.new(0, 36, 0, 36) or UDim2.new(0, 28, 0, 28)
			TweenService:Create(marker, TweenInfo.new(0.15), { Size = size }):Play()
		end)
		marker.MouseButton1Click:Connect(function()
			self:SelectLocation(id)
		end)

		self._markers[id] = marker
	end
end

function FastTravelWorldMapUI:_updateMarkerStates()
	for id, marker in self._markers do
		local unlocked = self._unlocked[id] == true
		marker.ImageColor3 = unlocked and Color3.new(1, 1, 1) or Color3.fromRGB(100, 100, 100)
		marker.ImageTransparency = unlocked and 0 or 0.35
		local isSelected = id == self._selectedId
		marker.Size = isSelected and UDim2.new(0, 36, 0, 36) or UDim2.new(0, 28, 0, 28)
	end
end

function FastTravelWorldMapUI:_canTravelTo(id)
	if id == self._currentLocationId then
		return false, "Already here"
	end
	if not self._unlocked[id] then
		local loc = FastTravelUtil.GetLocation(FastTravelConfig, id)
		return false, FastTravelUtil.GetUnlockHint(loc)
	end
	local loc = FastTravelUtil.GetLocation(FastTravelConfig, id)
	if loc and self._playerLevel < (loc.levelRequirement or 1) then
		return false, "Requires Level " .. tostring(loc.levelRequirement)
	end
	return true
end

function FastTravelWorldMapUI:_updateInfo()
	local location = FastTravelUtil.GetLocation(FastTravelConfig, self._selectedId)
	if not location then
		self._infoName.Text = "Select a location"
		self._infoRegion.Text = "Tap a map icon"
		self._infoDesc.Text = ""
		self._infoLock.Text = ""
		self._canTravelSelected = false
		self._travelBtn.Text = "Travel"
		self._travelBtn.BackgroundColor3 = Color3.fromRGB(75, 78, 90)
		self._travelBtn.TextColor3 = Color3.fromRGB(220, 222, 230)
		return
	end

	self._infoName.Text = location.displayName
	self._infoRegion.Text = "Region: " .. (location.region or "Unknown")
	self._infoDesc.Text = location.description or ""

	local canTravel, reason = self:_canTravelTo(self._selectedId)
	self._canTravelSelected = canTravel
	self._infoLock.Text = canTravel and "" or (reason or "Locked")
	self._travelBtn.Text = "Travel"
	if canTravel then
		self._travelBtn.BackgroundColor3 = Color3.fromRGB(55, 130, 80)
		self._travelBtn.TextColor3 = Color3.new(1, 1, 1)
	else
		self._travelBtn.BackgroundColor3 = Color3.fromRGB(75, 78, 90)
		self._travelBtn.TextColor3 = Color3.fromRGB(220, 222, 230)
	end
end

function FastTravelWorldMapUI:SetVisible(visible)
	self._panel.Visible = visible
	if visible then
		self:_ensureMarkers()
		self:_ensureTerrain()
		self:_resetView()
		self:_refreshSelection()
		self:_updateMarkerStates()
		self:_updateInfo()
	end
end

function FastTravelWorldMapUI:_refreshSelection()
	local targetId = self._selectedId or self._currentLocationId
	if targetId then
		self._selectedId = targetId
	end
end

function FastTravelWorldMapUI:IsVisible()
	return self._panel.Visible
end

return FastTravelWorldMapUI
