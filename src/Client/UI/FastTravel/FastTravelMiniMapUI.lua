local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FastTravelConfig = require(Shared.Config.FastTravel)
local FastTravelUtil = require(Shared.Util.FastTravelUtil)

local FastTravelMiniMapUI = {}
FastTravelMiniMapUI.__index = FastTravelMiniMapUI

local MINIMAP_SIZE = 156
local MINIMAP_MARGIN = 12

function FastTravelMiniMapUI.new(playerGui)
	local self = setmetatable({}, FastTravelMiniMapUI)
	self._onOpenMap = nil
	self._unlocked = {}
	self._playerPosition = Vector3.zero
	self._baseSize = MINIMAP_SIZE
	self._basePosition = UDim2.new(1, -(MINIMAP_SIZE + MINIMAP_MARGIN), 0, MINIMAP_MARGIN)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FastTravelMiniMapUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 20
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local container = Instance.new("TextButton")
	container.Name = "MiniMapButton"
	container.Size = UDim2.fromOffset(MINIMAP_SIZE, MINIMAP_SIZE)
	container.Position = self._basePosition
	container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	container.Text = ""
	container.AutoButtonColor = false
	container.Visible = false
	container.Parent = screenGui
	self._container = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 100, 180)
	stroke.Thickness = 2
	stroke.Parent = container

	local mapBg = Instance.new("Frame")
	mapBg.Size = UDim2.new(1, -8, 1, -8)
	mapBg.Position = UDim2.fromOffset(4, 4)
	mapBg.BackgroundColor3 = Color3.fromRGB(30, 45, 35)
	mapBg.BorderSizePixel = 0
	mapBg.Active = false
	mapBg.ClipsDescendants = true
	mapBg.Parent = container
	local mapCorner = Instance.new("UICorner")
	mapCorner.CornerRadius = UDim.new(0, 8)
	mapCorner.Parent = mapBg

	self._playerDot = Instance.new("Frame")
	self._playerDot.Size = UDim2.fromOffset(10, 10)
	self._playerDot.AnchorPoint = Vector2.new(0.5, 0.5)
	self._playerDot.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	self._playerDot.BorderSizePixel = 0
	self._playerDot.ZIndex = 3
	self._playerDot.Active = false
	self._playerDot.Parent = mapBg
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = self._playerDot
	local dotStroke = Instance.new("UIStroke")
	dotStroke.Color = Color3.fromRGB(12, 28, 18)
	dotStroke.Thickness = 1.5
	dotStroke.Parent = self._playerDot

	self._markerLayer = Instance.new("Frame")
	self._markerLayer.Size = UDim2.fromScale(1, 1)
	self._markerLayer.BackgroundTransparency = 1
	self._markerLayer.Active = false
	self._markerLayer.Parent = mapBg
	self._markers = {}
	self._markersBuilt = false

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 16)
	label.Position = UDim2.new(0, 0, 1, 4)
	label.BackgroundTransparency = 1
	label.Text = "Map"
	label.TextColor3 = Color3.fromRGB(200, 200, 210)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.Active = false
	label.Parent = container

	local function openMap()
		if self._onOpenMap then
			self._onOpenMap()
		end
	end

	container.MouseButton1Click:Connect(openMap)
	container.Activated:Connect(openMap)

	local hoverSize = MINIMAP_SIZE + 8
	local hoverPosition = UDim2.new(1, -(hoverSize + MINIMAP_MARGIN), 0, MINIMAP_MARGIN - 4)

	container.MouseEnter:Connect(function()
		TweenService:Create(container, TweenInfo.new(0.15), {
			Size = UDim2.fromOffset(hoverSize, hoverSize),
			Position = hoverPosition,
		}):Play()
	end)

	container.MouseLeave:Connect(function()
		TweenService:Create(container, TweenInfo.new(0.15), {
			Size = UDim2.fromOffset(MINIMAP_SIZE, MINIMAP_SIZE),
			Position = self._basePosition,
		}):Play()
	end)

	return self
end

function FastTravelMiniMapUI:_buildMarkers()
	for id, location in FastTravelUtil.GetEnabledLocations(FastTravelConfig) do
		local x, z = FastTravelUtil.WorldToMapPercent(location.position, FastTravelConfig.MiniMapBounds)
		local dot = Instance.new("Frame")
		dot.Name = id
		dot.Size = UDim2.fromOffset(6, 6)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(x, z)
		dot.BackgroundColor3 = Color3.fromRGB(180, 180, 200)
		dot.BorderSizePixel = 0
		dot.Active = false
		dot.Parent = self._markerLayer
		local mCorner = Instance.new("UICorner")
		mCorner.CornerRadius = UDim.new(1, 0)
		mCorner.Parent = dot
		self._markers[id] = dot
	end
end

function FastTravelMiniMapUI:_ensureMarkers()
	if self._markersBuilt then
		return
	end
	self._markersBuilt = true
	self:_buildMarkers()
end

function FastTravelMiniMapUI:OnOpenMap(callback)
	self._onOpenMap = callback
end

function FastTravelMiniMapUI:SetVisible(visible)
	self._container.Visible = visible
	if visible then
		self:_ensureMarkers()
	end
end

function FastTravelMiniMapUI:SetUnlocked(unlocked)
	self:_ensureMarkers()
	self._unlocked = unlocked or {}
	for id, dot in self._markers do
		local isUnlocked = self._unlocked[id] == true
		dot.BackgroundColor3 = isUnlocked and Color3.fromRGB(120, 170, 255) or Color3.fromRGB(90, 90, 100)
	end
end

function FastTravelMiniMapUI:SetPlayerPosition(position)
	self._playerPosition = position or Vector3.zero
	local x, z = FastTravelUtil.WorldToMapPercent(self._playerPosition, FastTravelConfig.MiniMapBounds)
	self._playerDot.Position = UDim2.fromScale(x, z)
end

return FastTravelMiniMapUI
