local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FastTravelConfig = require(Shared.Config.FastTravel)
local FastTravelUtil = require(Shared.Util.FastTravelUtil)

local FastTravelMiniMapUI = {}
FastTravelMiniMapUI.__index = FastTravelMiniMapUI

function FastTravelMiniMapUI.new(playerGui)
	local self = setmetatable({}, FastTravelMiniMapUI)
	self._onOpenMap = nil
	self._unlocked = {}
	self._playerPosition = Vector3.zero

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FastTravelMiniMapUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 6
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local container = Instance.new("TextButton")
	container.Name = "MiniMapButton"
	container.Size = UDim2.new(0, 88, 0, 88)
	container.Position = UDim2.new(1, -100, 0, 16)
	container.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	container.Text = ""
	container.AutoButtonColor = false
	container.Visible = false
	container.Parent = screenGui
	self._container = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = container

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 100, 180)
	stroke.Thickness = 2
	stroke.Parent = container

	local mapBg = Instance.new("Frame")
	mapBg.Size = UDim2.new(1, -12, 1, -12)
	mapBg.Position = UDim2.new(0, 6, 0, 6)
	mapBg.BackgroundColor3 = Color3.fromRGB(30, 45, 35)
	mapBg.BorderSizePixel = 0
	mapBg.Parent = container
	local mapCorner = Instance.new("UICorner")
	mapCorner.CornerRadius = UDim.new(1, 0)
	mapCorner.Parent = mapBg

	self._playerDot = Instance.new("Frame")
	self._playerDot.Size = UDim2.new(0, 8, 0, 8)
	self._playerDot.AnchorPoint = Vector2.new(0.5, 0.5)
	self._playerDot.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
	self._playerDot.BorderSizePixel = 0
	self._playerDot.ZIndex = 3
	self._playerDot.Parent = mapBg
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = self._playerDot

	self._markerLayer = Instance.new("Frame")
	self._markerLayer.Size = UDim2.fromScale(1, 1)
	self._markerLayer.BackgroundTransparency = 1
	self._markerLayer.Parent = mapBg
	self._markers = {}

	for id, location in FastTravelUtil.GetEnabledLocations(FastTravelConfig) do
		local x, z = FastTravelUtil.WorldToMapPercent(location.position, FastTravelConfig.MapBounds)
		local dot = Instance.new("Frame")
		dot.Name = id
		dot.Size = UDim2.new(0, 5, 0, 5)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromScale(x, z)
		dot.BackgroundColor3 = Color3.fromRGB(180, 180, 200)
		dot.BorderSizePixel = 0
		dot.Parent = self._markerLayer
		local mCorner = Instance.new("UICorner")
		mCorner.CornerRadius = UDim.new(1, 0)
		mCorner.Parent = dot
		self._markers[id] = dot
	end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 14)
	label.Position = UDim2.new(0, 0, 1, 2)
	label.BackgroundTransparency = 1
	label.Text = "Map"
	label.TextColor3 = Color3.fromRGB(200, 200, 210)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 10
	label.Parent = container

	container.MouseEnter:Connect(function()
		TweenService:Create(container, TweenInfo.new(0.15), {
			Size = UDim2.new(0, 94, 0, 94),
			Position = UDim2.new(1, -103, 0, 13),
		}):Play()
	end)

	container.MouseLeave:Connect(function()
		TweenService:Create(container, TweenInfo.new(0.15), {
			Size = UDim2.new(0, 88, 0, 88),
			Position = UDim2.new(1, -100, 0, 16),
		}):Play()
	end)

	container.MouseButton1Click:Connect(function()
		if self._onOpenMap then
			self._onOpenMap()
		end
	end)

	return self
end

function FastTravelMiniMapUI:OnOpenMap(callback)
	self._onOpenMap = callback
end

function FastTravelMiniMapUI:SetVisible(visible)
	self._container.Visible = visible
end

function FastTravelMiniMapUI:SetUnlocked(unlocked)
	self._unlocked = unlocked or {}
	for id, dot in self._markers do
		local isUnlocked = self._unlocked[id] == true
		dot.BackgroundColor3 = isUnlocked and Color3.fromRGB(120, 170, 255) or Color3.fromRGB(90, 90, 100)
	end
end

function FastTravelMiniMapUI:SetPlayerPosition(position)
	self._playerPosition = position or Vector3.zero
	local x, z = FastTravelUtil.WorldToMapPercent(self._playerPosition, FastTravelConfig.MapBounds)
	self._playerDot.Position = UDim2.fromScale(x, z)
end

return FastTravelMiniMapUI
