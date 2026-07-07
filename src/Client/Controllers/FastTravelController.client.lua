local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FastTravelUI = require(script.Parent.Parent.UI.FastTravel.FastTravelUI)
local FastTravelWorldMapUI = require(script.Parent.Parent.UI.FastTravel.FastTravelWorldMapUI)
local FastTravelMiniMapUI = require(script.Parent.Parent.UI.FastTravel.FastTravelMiniMapUI)
local FastTravelConfirmationUI = require(script.Parent.Parent.UI.FastTravel.FastTravelConfirmationUI)
local FastTravelFadeUI = require(script.Parent.Parent.UI.FastTravel.FastTravelFadeUI)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FastTravelConfig = require(Shared.Config.FastTravel)
local FastTravelUtil = require(Shared.Util.FastTravelUtil)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hasSelectedClass = false
local playerLevel = 1
local unlockedLocations = {}
local currentPortalId = nil
local pendingDestinationId = nil
local lastPositionUpdate = 0

local playerGui = player:WaitForChild("PlayerGui")
local mainUI = FastTravelUI.new(playerGui)
local worldMapUI = FastTravelWorldMapUI.new(playerGui)
local miniMapUI = FastTravelMiniMapUI.new(playerGui)
local confirmUI = FastTravelConfirmationUI.new(playerGui)
local fadeUI = FastTravelFadeUI.new(playerGui)

local function getNearestLocationIdByPosition(position)
	local nearestId = nil
	local nearestDist = math.huge

	for id, location in FastTravelUtil.GetEnabledLocations(FastTravelConfig) do
		local dist = (location.position - position).Magnitude
		if dist < nearestDist then
			nearestDist = dist
			nearestId = id
		end
	end

	return nearestId
end

local function getPortalPosition(portal)
	if portal:IsA("Model") and portal.PrimaryPart then
		return portal.PrimaryPart.Position
	end
	if portal:IsA("BasePart") then
		return portal.Position
	end
	local post = portal:FindFirstChild("Post", true)
	if post and post:IsA("BasePart") then
		return post.Position
	end
	return nil
end

local function getNearestPortalId()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return currentPortalId
	end

	local folder = workspace:FindFirstChild("FastTravel")
	if folder then
		local nearestId = nil
		local nearestDist = math.huge

		for _, portal in folder:GetChildren() do
			local id = portal:GetAttribute("FastTravelId")
			local portalPos = getPortalPosition(portal)
			if type(id) == "string" and portalPos then
				local dist = (portalPos - root.Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestId = id
				end
			end
		end

		if nearestId and nearestDist <= 16 then
			return nearestId
		end
	end

	return getNearestLocationIdByPosition(root.Position) or currentPortalId
end

local function getDisplayName(locationId)
	local location = FastTravelUtil.GetLocation(FastTravelConfig, locationId)
	return location and location.displayName or "Unknown"
end

local function syncUIState()
	mainUI:SetUnlocked(unlockedLocations)
	mainUI:SetPlayerLevel(playerLevel)
	mainUI:SetCurrentLocation(currentPortalId)

	worldMapUI:SetUnlocked(unlockedLocations)
	worldMapUI:SetPlayerLevel(playerLevel)
	worldMapUI:SetCurrentLocation(currentPortalId)

	miniMapUI:SetUnlocked(unlockedLocations)
end

local function closeAllPanels()
	mainUI:SetVisible(false)
	worldMapUI:SetVisible(false)
	confirmUI:SetVisible(false)
end

local function requestTravel(destinationId)
	if not currentPortalId then
		currentPortalId = getNearestPortalId()
	end
	if not currentPortalId then
		return
	end
	remotes.RequestFastTravel:FireServer(destinationId, currentPortalId)
	closeAllPanels()
end

local function canTravelTo(destinationId)
	if destinationId == currentPortalId then
		return false
	end
	if not unlockedLocations[destinationId] then
		return false
	end
	local location = FastTravelUtil.GetLocation(FastTravelConfig, destinationId)
	if location and playerLevel < (location.levelRequirement or 1) then
		return false
	end
	return true
end

local function promptTravel(destinationId)
	if not canTravelTo(destinationId) then
		return
	end
	pendingDestinationId = destinationId
	confirmUI:SetDestination(getDisplayName(destinationId))
	confirmUI:SetVisible(true)
end

local function openFastTravel(fromPortalId)
	if not hasSelectedClass then
		return
	end

	currentPortalId = fromPortalId or getNearestPortalId()
	if currentPortalId then
		remotes.FastTravelVisit:FireServer(currentPortalId)
	end

	syncUIState()
	mainUI:SetVisible(true)
	if currentPortalId then
		mainUI:SelectLocation(currentPortalId)
	end
end

local function openWorldMap()
	if not hasSelectedClass then
		return
	end

	currentPortalId = getNearestPortalId()
	syncUIState()
	worldMapUI:SetVisible(true)
end

mainUI:OnTravel(promptTravel)
mainUI:OnCancel(closeAllPanels)
mainUI:OnSelect(function(locationId)
	worldMapUI:SelectLocation(locationId)
end)

worldMapUI:OnTravel(promptTravel)
worldMapUI:OnSelect(function(locationId)
	mainUI:SelectLocation(locationId)
end)
worldMapUI:OnClose(function()
	worldMapUI:SetVisible(false)
end)

miniMapUI:OnOpenMap(openWorldMap)

confirmUI:OnConfirm(function()
	if pendingDestinationId then
		requestTravel(pendingDestinationId)
		pendingDestinationId = nil
	end
end)
confirmUI:OnCancel(function()
	pendingDestinationId = nil
end)

remotes.FastTravelStateUpdated.OnClientEvent:Connect(function(state)
	if type(state) ~= "table" then
		return
	end
	unlockedLocations = state.unlocked or {}
	playerLevel = state.level or playerLevel
	syncUIState()
end)

remotes.FastTravelBegin.OnClientEvent:Connect(function()
	fadeUI:FadeOut(0.4)
end)

remotes.FastTravelComplete.OnClientEvent:Connect(function()
	fadeUI:FadeIn(0.4)
	currentPortalId = getNearestPortalId()
	syncUIState()
end)

remotes.FastTravelResult.OnClientEvent:Connect(function(_success, _message)
	-- Notifications are fired server-side via Notification remote.
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	hasSelectedClass = payload.hasSelectedClass == true
	playerLevel = payload.level or playerLevel
	miniMapUI:SetVisible(hasSelectedClass)
	syncUIState()
end)

local boundPrompts = {}

local function bindPortal(portal)
	local id = portal:GetAttribute("FastTravelId")
	local prompt = portal:FindFirstChild("TravelPrompt", true)
	if type(id) ~= "string" or not prompt or not prompt:IsA("ProximityPrompt") then
		return
	end
	if boundPrompts[prompt] then
		return
	end
	boundPrompts[prompt] = true

	prompt.Triggered:Connect(function(triggerPlayer)
		if triggerPlayer == player then
			openFastTravel(id)
		end
	end)
end

local function watchFastTravelFolder(folder)
	for _, portal in folder:GetChildren() do
		bindPortal(portal)
	end
	folder.ChildAdded:Connect(bindPortal)
end

task.spawn(function()
	local folder = workspace:WaitForChild("FastTravel", 60)
	if folder then
		watchFastTravelFolder(folder)
	end
end)

RunService.Heartbeat:Connect(function()
	if not hasSelectedClass then
		return
	end

	local now = tick()
	if now - lastPositionUpdate < 0.1 then
		return
	end
	lastPositionUpdate = now

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	miniMapUI:SetPlayerPosition(root.Position)
	if worldMapUI:IsVisible() then
		worldMapUI:SetPlayerPosition(root.Position)
	end

	local nearId = getNearestPortalId()
	if nearId and nearId ~= currentPortalId then
		currentPortalId = nearId
		if mainUI:IsVisible() or worldMapUI:IsVisible() then
			syncUIState()
		end
	end
end)
