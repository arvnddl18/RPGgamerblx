local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FastTravelConfig = require(Shared.Config.FastTravel)
local FastTravelUtil = require(Shared.Util.FastTravelUtil)

local UI_ROOT = script.Parent.Parent.UI.FastTravel

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hasSelectedClass = false
local playerLevel = 1
local unlockedLocations = {}
local currentPortalId = nil
local pendingDestinationId = nil
local lastPositionUpdate = 0

local ui = {}
local wired = {
	main = false,
	worldMap = false,
	miniMap = false,
	confirm = false,
}

local function getUI(name)
	if ui[name] then
		return ui[name]
	end

	local module = UI_ROOT:FindFirstChild(name)
	if not module then
		return nil
	end

	ui[name] = require(module).new(player:WaitForChild("PlayerGui"))
	return ui[name]
end

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
	if ui.FastTravelUI then
		ui.FastTravelUI:SetUnlocked(unlockedLocations)
		ui.FastTravelUI:SetPlayerLevel(playerLevel)
		ui.FastTravelUI:SetCurrentLocation(currentPortalId)
	end
	if ui.FastTravelWorldMapUI then
		ui.FastTravelWorldMapUI:SetUnlocked(unlockedLocations)
		ui.FastTravelWorldMapUI:SetPlayerLevel(playerLevel)
		ui.FastTravelWorldMapUI:SetCurrentLocation(currentPortalId)
	end
	if ui.FastTravelMiniMapUI then
		ui.FastTravelMiniMapUI:SetUnlocked(unlockedLocations)
	end
end

local function closeAllPanels()
	if ui.FastTravelUI then
		ui.FastTravelUI:SetVisible(false)
	end
	if ui.FastTravelWorldMapUI then
		ui.FastTravelWorldMapUI:SetVisible(false)
	end
	if ui.FastTravelConfirmationUI then
		ui.FastTravelConfirmationUI:SetVisible(false)
	end
end

local ensureConfirmWired
local ensureWorldMapWired
local ensureMainWired
local ensureMiniMapWired
local promptTravel
local openWorldMap

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

ensureConfirmWired = function()
	if wired.confirm then
		return getUI("FastTravelConfirmationUI")
	end
	wired.confirm = true

	local confirmUI = getUI("FastTravelConfirmationUI")
	confirmUI:OnConfirm(function()
		if pendingDestinationId then
			requestTravel(pendingDestinationId)
			pendingDestinationId = nil
		end
	end)
	confirmUI:OnCancel(function()
		pendingDestinationId = nil
	end)
	return confirmUI
end

promptTravel = function(destinationId)
	if not canTravelTo(destinationId) then
		return
	end
	pendingDestinationId = destinationId
	local confirmUI = ensureConfirmWired()
	confirmUI:SetDestination(getDisplayName(destinationId))
	confirmUI:SetVisible(true)
end

ensureWorldMapWired = function()
	if wired.worldMap then
		return getUI("FastTravelWorldMapUI")
	end
	wired.worldMap = true

	local worldMapUI = getUI("FastTravelWorldMapUI")

	worldMapUI:OnTravel(promptTravel)
	worldMapUI:OnSelect(function(locationId)
		if wired.main then
			getUI("FastTravelUI"):SelectLocation(locationId, true)
		end
	end)
	worldMapUI:OnClose(function()
		worldMapUI:SetVisible(false)
	end)
	return worldMapUI
end

ensureMainWired = function()
	if wired.main then
		return getUI("FastTravelUI")
	end
	wired.main = true

	local mainUI = getUI("FastTravelUI")
	mainUI:OnTravel(promptTravel)
	mainUI:OnCancel(closeAllPanels)
	mainUI:OnSelect(function(locationId)
		ensureWorldMapWired():SelectLocation(locationId)
	end)
	if wired.worldMap then
		getUI("FastTravelWorldMapUI"):OnSelect(function(locationId)
			mainUI:SelectLocation(locationId, true)
		end)
	end

	return mainUI
end

openWorldMap = function()
	if not hasSelectedClass then
		return
	end

	currentPortalId = getNearestPortalId()
	syncUIState()
	ensureWorldMapWired():SetVisible(true)
end

ensureMiniMapWired = function()
	local miniMapUI = getUI("FastTravelMiniMapUI")
	miniMapUI:OnOpenMap(openWorldMap)
	if not wired.miniMap then
		wired.miniMap = true
	end
	return miniMapUI
end

local function openFastTravel(fromPortalId)
	if not hasSelectedClass then
		return
	end

	currentPortalId = fromPortalId or getNearestPortalId()

	local mainUI = ensureMainWired()
	mainUI:SetCurrentLocation(currentPortalId)
	mainUI:SetPlayerLevel(playerLevel)
	mainUI:SetUnlocked(unlockedLocations)
	mainUI:SetVisible(true)
	if currentPortalId then
		mainUI:SelectLocation(currentPortalId, true)
	end

	if currentPortalId then
		task.defer(function()
			remotes.FastTravelVisit:FireServer(currentPortalId)
		end)
	end
end

remotes.FastTravelStateUpdated.OnClientEvent:Connect(function(state)
	if type(state) ~= "table" then
		return
	end
	unlockedLocations = state.unlocked or {}
	playerLevel = state.level or playerLevel
	syncUIState()
end)

remotes.FastTravelBegin.OnClientEvent:Connect(function()
	getUI("FastTravelFadeUI"):FadeOut(0.4)
end)

remotes.FastTravelComplete.OnClientEvent:Connect(function()
	getUI("FastTravelFadeUI"):FadeIn(0.4)
	currentPortalId = getNearestPortalId()
	syncUIState()
end)

remotes.FastTravelResult.OnClientEvent:Connect(function(_success, _message)
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	hasSelectedClass = payload.hasSelectedClass == true
	playerLevel = payload.level or playerLevel
	if hasSelectedClass then
		ensureMiniMapWired():SetVisible(true)
		task.defer(ensureMainWired)
	end
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

	if ui.FastTravelMiniMapUI then
		ui.FastTravelMiniMapUI:SetPlayerPosition(root.Position)
	end
	if ui.FastTravelWorldMapUI and ui.FastTravelWorldMapUI:IsVisible() then
		ui.FastTravelWorldMapUI:SetPlayerPosition(root.Position)
	end

	local nearId = getNearestPortalId()
	if nearId and nearId ~= currentPortalId then
		currentPortalId = nearId
		if (ui.FastTravelUI and ui.FastTravelUI:IsVisible())
			or (ui.FastTravelWorldMapUI and ui.FastTravelWorldMapUI:IsVisible()) then
			syncUIState()
		end
	end
end)
