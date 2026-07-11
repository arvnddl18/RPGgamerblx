local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FastTravelConfig = require(Shared.Config.FastTravel)
local FastTravelUtil = require(Shared.Util.FastTravelUtil)

local FADE_WAIT = 0.45
local REQUEST_DEBOUNCE = 0.5
local STREAM_TIMEOUT = 3

local FastTravelService = {}
FastTravelService._playerData = nil
FastTravelService._pvpService = nil
FastTravelService._restService = nil
FastTravelService._deathService = nil
FastTravelService._mapGenerator = nil
FastTravelService._saveService = nil
FastTravelService._remotes = nil
FastTravelService._lastRequest = {}
FastTravelService._teleporting = {}
FastTravelService._spawnCache = {}
FastTravelService._travelToken = {}

function FastTravelService:Init()
	local Framework = require(Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._pvpService = Framework:GetService("PvpService")
	self._restService = Framework:GetService("RestService")
	self._deathService = Framework:GetService("DeathService")
	self._mapGenerator = Framework:GetService("MapGeneratorService")
	self._saveService = Framework:GetService("SaveService")
	self._remotes = Framework:GetRemotesFolder()

	Framework:GetRemote("RequestFastTravel")
	Framework:GetRemote("FastTravelVisit")
	Framework:GetRemote("FastTravelBegin")
	Framework:GetRemote("FastTravelComplete")
	Framework:GetRemote("FastTravelStateUpdated")
	Framework:GetRemote("FastTravelResult")
end

function FastTravelService:GetSpawnCFrame(location)
	local pos = location.position
	local offset = location.spawnOffset or Vector3.zero
	local x = pos.X + offset.X
	local z = pos.Z + offset.Z
	local y = self._mapGenerator:GetGroundHeight(x, z) + 3
	return CFrame.new(x, y, z)
end

function FastTravelService:GetPostPosition(location, groundY)
	local pos = location.position
	local offset = location.spawnOffset or Vector3.zero
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude > 0.1 then
		pos = pos + flat.Unit * 12
	end
	return Vector3.new(pos.X, groundY, pos.Z)
end

function FastTravelService:CreateTravelPost(location, groundY)
	local model = Instance.new("Model")
	model.Name = location.id

	local isGate = location.category == "Gates"
	local postPos = self:GetPostPosition(location, groundY)

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(isGate and 3.5 or 2.5, 0.6, isGate and 3.5 or 2.5)
	base.Position = postPos + Vector3.new(0, 0.3, 0)
	base.Color = Color3.fromRGB(90, 85, 75)
	base.Material = Enum.Material.Cobblestone
	base.Anchored = true
	base.CanCollide = true
	base.Parent = model

	local pole = Instance.new("Part")
	pole.Name = "Post"
	pole.Shape = Enum.PartType.Cylinder
	pole.Size = Vector3.new(isGate and 7 or 5, 1.1, 1.1)
	pole.CFrame = CFrame.new(postPos + Vector3.new(0, isGate and 4 or 3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pole.Color = Color3.fromRGB(80, 55, 35)
	pole.Material = Enum.Material.Wood
	pole.Anchored = true
	pole.CanCollide = false
	pole.Parent = model

	if isGate then
		local sign = Instance.new("Part")
		sign.Name = "Sign"
		sign.Size = Vector3.new(4, 2.2, 0.25)
		sign.CFrame = CFrame.new(postPos + Vector3.new(0, 7.2, 0))
		sign.Color = Color3.fromRGB(55, 50, 45)
		sign.Material = Enum.Material.WoodPlanks
		sign.Anchored = true
		sign.CanCollide = false
		sign.Parent = model

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "SignLabel"
		billboard.Size = UDim2.new(0, 140, 0, 44)
		billboard.StudsOffset = Vector3.new(0, 8.6, 0)
		billboard.AlwaysOnTop = false
		billboard.MaxDistance = 90
		billboard.Parent = pole

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = location.displayName
		label.TextColor3 = Color3.fromRGB(220, 200, 140)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.TextStrokeTransparency = 0.5
		label.Parent = billboard

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 200, 120)
		light.Range = 14
		light.Brightness = 0.7
		light.Parent = pole

		local effect = Instance.new("ParticleEmitter")
		effect.Name = "PortalEffect"
		effect.Color = ColorSequence.new(Color3.fromRGB(120, 180, 255))
		effect.LightEmission = 0.6
		effect.Size = NumberSequence.new(0.25, 0)
		effect.Lifetime = NumberRange.new(0.4, 0.8)
		effect.Rate = 3
		effect.Speed = NumberRange.new(0.5, 1.2)
		effect.SpreadAngle = Vector2.new(180, 180)
		effect.Parent = pole
	else
		local marker = Instance.new("BillboardGui")
		marker.Name = "MarkerLabel"
		marker.Size = UDim2.new(0, 100, 0, 28)
		marker.StudsOffset = Vector3.new(0, 4.5, 0)
		marker.AlwaysOnTop = false
		marker.MaxDistance = 60
		marker.Parent = pole

		local markerText = Instance.new("TextLabel")
		markerText.Size = UDim2.fromScale(1, 1)
		markerText.BackgroundTransparency = 1
		markerText.Text = location.displayName
		markerText.TextColor3 = Color3.fromRGB(180, 200, 255)
		markerText.Font = Enum.Font.GothamBold
		markerText.TextSize = 12
		markerText.TextStrokeTransparency = 0.6
		markerText.Parent = marker
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TravelPrompt"
	prompt.ObjectText = location.displayName
	prompt.ActionText = "Fast Travel"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = isGate and 12 or 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = pole

	model.PrimaryPart = pole
	model:SetAttribute("FastTravelId", location.id)
	return model
end

function FastTravelService:CreatePortals()
	local folder = workspace:FindFirstChild("FastTravel")
	if folder then
		folder:Destroy()
	end

	folder = Instance.new("Folder")
	folder.Name = "FastTravel"
	folder.Parent = workspace

	self._spawnCache = {}

	for id, location in FastTravelUtil.GetEnabledLocations(FastTravelConfig) do
		local pos = location.position
		local groundY = self._mapGenerator:GetGroundHeight(pos.X, pos.Z)
		self._spawnCache[id] = self:GetSpawnCFrame(location)

		local portal = self:CreateTravelPost(location, groundY)
		if portal.PrimaryPart then
			portal:PivotTo(CFrame.new(self:GetPostPosition(location, groundY)))
		end
		portal.Parent = folder

		local spawn = Instance.new("Part")
		spawn.Name = "Spawn"
		spawn.Size = Vector3.new(4, 1, 4)
		spawn.Anchored = true
		spawn.CanCollide = false
		spawn.Transparency = 1
		spawn.CFrame = self._spawnCache[id]
		spawn.Parent = portal
	end
end

function FastTravelService:GetStateForPlayer(player)
	local data = self._playerData:GetData(player)
	local snapshot = FastTravelUtil.BuildSnapshotFromData(data)
	local unlocked = {}

	for id, location in FastTravelUtil.GetEnabledLocations(FastTravelConfig) do
		unlocked[id] = FastTravelUtil.IsUnlocked(location, snapshot)
	end

	return {
		unlocked = unlocked,
		visited = snapshot.visited,
		level = snapshot.level,
		quest = snapshot.quest,
	}
end

function FastTravelService:FireStateUpdated(player)
	self._remotes.FastTravelStateUpdated:FireClient(player, self:GetStateForPlayer(player))
end

function FastTravelService:UnlockLocation(player, locationId)
	local data = self._playerData:GetData(player)
	if not data then
		return
	end

	if not data.fastTravel then
		data.fastTravel = { visited = {}, favorites = {} }
	end
	if not data.fastTravel.visited then
		data.fastTravel.visited = {}
	end

	if data.fastTravel.visited[locationId] then
		return
	end

	data.fastTravel.visited[locationId] = true
	if self._saveService then
		self._saveService:MarkDirty(player)
	end
	self:FireStateUpdated(player)
end

function FastTravelService:OnPortalVisited(player, locationId)
	local location = FastTravelUtil.GetLocation(FastTravelConfig, locationId)
	if not location then
		return
	end

	self:UnlockLocation(player, locationId)
end

function FastTravelService:IsRespawning(player)
	return self._deathService and self._deathService._respawning[player] == true
end

function FastTravelService:CanTravel(player, fromId, toId)
	if not self._playerData:HasSelectedClass(player) then
		return false, "Select a class first."
	end

	local data = self._playerData:GetData(player)
	if not data or data.hp <= 0 then
		return false, "You cannot travel while dead."
	end

	if self:IsRespawning(player) then
		return false, "You cannot travel while respawning."
	end

	if self._pvpService:IsInCombat(player) then
		return false, "Cannot fast travel while in combat."
	end

	if self._restService:IsResting(player) then
		return false, "Cannot fast travel while resting."
	end

	local character = player.Character
	if not character then
		return false, "Character not loaded."
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, "You cannot travel while dead."
	end

	if character:GetAttribute("IsStunned") or character:GetAttribute("IsKnockedDown") then
		return false, "Cannot fast travel while stunned."
	end

	if character:GetAttribute("IsDashing") then
		return false, "Cannot fast travel while dashing."
	end

	if character:GetAttribute("IsCasting") then
		return false, "Cannot fast travel while casting."
	end

	if character:GetAttribute("IsTeleporting") or self._teleporting[player] then
		return false, "Already traveling."
	end

	if character:GetAttribute("FastTravelRestricted") then
		return false, "Fast travel is restricted right now."
	end

	if type(toId) ~= "string" then
		return false, "Invalid destination."
	end

	if fromId == toId then
		return false, "You are already at this location."
	end

	local destination = FastTravelUtil.GetLocation(FastTravelConfig, toId)
	if not destination or destination.enabled == false then
		return false, "Destination not found."
	end

	local snapshot = FastTravelUtil.BuildSnapshotFromData(data)
	if not FastTravelUtil.IsUnlocked(destination, snapshot) then
		return false, FastTravelUtil.GetUnlockHint(destination)
	end

	local levelReq = destination.levelRequirement or 1
	if data.level < levelReq then
		return false, "Requires Level " .. tostring(levelReq)
	end

	return true, nil
end

function FastTravelService:SetMovementLocked(player, locked)
	local character = player.Character
	if not character then
		return
	end

	character:SetAttribute("IsTeleporting", locked)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if locked then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
	else
		local data = self._playerData:GetData(player)
		if data and data.hasSelectedClass then
			humanoid.WalkSpeed = math.max(0, data.combatStats.movementSpeed)
			humanoid.JumpPower = 50
		end
		humanoid.AutoRotate = true
	end
end

function FastTravelService:TeleportPlayer(player, toId)
	local destination = FastTravelUtil.GetLocation(FastTravelConfig, toId)
	if not destination then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	local targetCF = self._spawnCache[toId] or self:GetSpawnCFrame(destination)

	self._teleporting[player] = true
	self:SetMovementLocked(player, true)

	pcall(function()
		player:RequestStreamAroundAsync(targetCF.Position, STREAM_TIMEOUT)
	end)

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(targetCF)

	task.defer(function()
		if root.Parent then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		self:SetMovementLocked(player, false)
		self._teleporting[player] = nil
	end)

	self:OnPortalVisited(player, toId)
	return true
end

function FastTravelService:FinishTravel(player, destinationId, sourceId, travelToken, success, message)
	if not player.Parent or self._travelToken[player] ~= travelToken then
		return
	end

	self._remotes.FastTravelComplete:FireClient(player, destinationId)
	self._remotes.FastTravelResult:FireClient(player, success, message)
	if success then
		self._remotes.Notification:FireClient(player, message)
		self:FireStateUpdated(player)
	else
		self._remotes.Notification:FireClient(player, message)
	end
end

function FastTravelService:HandleTravelRequest(player, destinationId, sourceId)
	local now = tick()
	if self._lastRequest[player] and now - self._lastRequest[player] < REQUEST_DEBOUNCE then
		return
	end
	self._lastRequest[player] = now

	if type(destinationId) ~= "string" or type(sourceId) ~= "string" then
		self._remotes.FastTravelResult:FireClient(player, false, "Invalid travel request.")
		self._remotes.Notification:FireClient(player, "Invalid travel request.")
		return
	end

	if not FastTravelUtil.GetLocation(FastTravelConfig, destinationId) then
		self._remotes.FastTravelResult:FireClient(player, false, "Unknown destination.")
		self._remotes.Notification:FireClient(player, "Unknown destination.")
		return
	end

	if not FastTravelUtil.GetLocation(FastTravelConfig, sourceId) then
		self._remotes.FastTravelResult:FireClient(player, false, "Unknown source.")
		self._remotes.Notification:FireClient(player, "Unknown source.")
		return
	end

	local canTravel, reason = self:CanTravel(player, sourceId, destinationId)
	if not canTravel then
		self._remotes.FastTravelResult:FireClient(player, false, reason or "Cannot travel.")
		self._remotes.Notification:FireClient(player, reason or "Cannot travel.")
		return
	end

	local travelToken = (self._travelToken[player] or 0) + 1
	self._travelToken[player] = travelToken

	self._remotes.FastTravelBegin:FireClient(player, destinationId)

	task.delay(FADE_WAIT, function()
		if not player.Parent or self._travelToken[player] ~= travelToken then
			return
		end

		canTravel, reason = self:CanTravel(player, sourceId, destinationId)
		if not canTravel then
			self:FinishTravel(player, destinationId, sourceId, travelToken, false, reason or "Cannot travel.")
			return
		end

		local teleported = self:TeleportPlayer(player, destinationId)
		if not teleported then
			self:FinishTravel(player, destinationId, sourceId, travelToken, false, "Teleport failed.")
			return
		end

		local arriveMsg = "Arrived at " .. FastTravelConfig.Locations[destinationId].displayName
		self:FinishTravel(player, destinationId, sourceId, travelToken, true, arriveMsg)
	end)
end

function FastTravelService:Start()
	self:CreatePortals()

	self._remotes.RequestFastTravel.OnServerEvent:Connect(function(player, destinationId, sourceId)
		task.spawn(function()
			self:HandleTravelRequest(player, destinationId, sourceId)
		end)
	end)

	self._remotes.FastTravelVisit.OnServerEvent:Connect(function(player, locationId)
		if type(locationId) == "string" then
			self:OnPortalVisited(player, locationId)
		end
	end)

	local function onPlayerReady(player)
		task.defer(function()
			if player.Parent then
				self:FireStateUpdated(player)
			end
		end)
	end

	Players.PlayerAdded:Connect(onPlayerReady)
	for _, player in Players:GetPlayers() do
		onPlayerReady(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		self._lastRequest[player] = nil
		self._teleporting[player] = nil
		self._travelToken[player] = nil
	end)
end

return FastTravelService
