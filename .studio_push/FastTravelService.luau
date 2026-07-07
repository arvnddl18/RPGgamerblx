local current = game:GetService("ServerScriptService")
current = current:FindFirstChild("Server") or (function() local inst = Instance.new("Folder"); inst.Name = "Server"; inst.Parent = current; return inst end)()
current = current:FindFirstChild("Services") or (function() local inst = Instance.new("Folder"); inst.Name = "Services"; inst.Parent = current; return inst end)()
local existing = current:FindFirstChild("FastTravelService")
if existing then existing:Destroy() end
local scriptInst = Instance.new("ModuleScript")
scriptInst.Name = "FastTravelService"
scriptInst.Source = [=[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FastTravelConfig = require(Shared.Config.FastTravel)
local FastTravelUtil = require(Shared.Util.FastTravelUtil)

local FADE_WAIT = 0.55
local REQUEST_DEBOUNCE = 0.5

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

function FastTravelService:CreatePortals()
	local folder = workspace:FindFirstChild("FastTravel")
	if folder then
		folder:Destroy()
	end

	folder = Instance.new("Folder")
	folder.Name = "FastTravel"
	folder.Parent = workspace

	for id, location in FastTravelUtil.GetEnabledLocations(FastTravelConfig) do
		local pos = location.position
		local y = self._mapGenerator:GetGroundHeight(pos.X, pos.Z) + 2

		local portal = Instance.new("Part")
		portal.Name = id
		portal.Size = Vector3.new(6, 8, 6)
		portal.Anchored = true
		portal.CanCollide = false
		portal.Transparency = 1
		portal.Position = Vector3.new(pos.X, y, pos.Z)
		portal:SetAttribute("FastTravelId", id)
		portal.Parent = folder

		local spawn = Instance.new("Part")
		spawn.Name = "Spawn"
		spawn.Size = Vector3.new(4, 1, 4)
		spawn.Anchored = true
		spawn.CanCollide = false
		spawn.Transparency = 1
		spawn.CFrame = self:GetSpawnCFrame(location)
		spawn.Parent = portal

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TravelPrompt"
		prompt.ObjectText = location.displayName
		prompt.ActionText = "Fast Travel"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = portal

		local effect = Instance.new("ParticleEmitter")
		effect.Name = "PortalEffect"
		effect.Color = ColorSequence.new(Color3.fromRGB(120, 180, 255))
		effect.LightEmission = 0.8
		effect.Size = NumberSequence.new(0.3, 0)
		effect.Lifetime = NumberRange.new(0.5, 1)
		effect.Rate = 12
		effect.Speed = NumberRange.new(1, 2)
		effect.SpreadAngle = Vector2.new(180, 180)
		effect.Parent = portal
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

	local req = location.unlockRequirement
	if req and req.type == "visit" then
		self:UnlockLocation(player, locationId)
	else
		self:UnlockLocation(player, locationId)
	end
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

	self._teleporting[player] = true
	self:SetMovementLocked(player, true)

	root.Anchored = true
	character:PivotTo(self:GetSpawnCFrame(destination))
	task.wait(0.1)

	if root.Parent then
		root.Anchored = false
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	self:SetMovementLocked(player, false)
	self._teleporting[player] = nil

	self:OnPortalVisited(player, toId)
	return true
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

	self._remotes.FastTravelBegin:FireClient(player, destinationId)
	task.wait(FADE_WAIT)

	if not player.Parent then
		return
	end

	canTravel, reason = self:CanTravel(player, sourceId, destinationId)
	if not canTravel then
		self._remotes.FastTravelComplete:FireClient(player, destinationId)
		self._remotes.FastTravelResult:FireClient(player, false, reason or "Cannot travel.")
		self._remotes.Notification:FireClient(player, reason or "Cannot travel.")
		return
	end

	local success = self:TeleportPlayer(player, destinationId)
	if not success then
		self._remotes.FastTravelComplete:FireClient(player, destinationId)
		self._remotes.FastTravelResult:FireClient(player, false, "Teleport failed.")
		self._remotes.Notification:FireClient(player, "Teleport failed.")
		return
	end

	self._remotes.FastTravelComplete:FireClient(player, destinationId)
	local arriveMsg = "Arrived at " .. FastTravelConfig.Locations[destinationId].displayName
	self._remotes.FastTravelResult:FireClient(player, true, arriveMsg)
	self._remotes.Notification:FireClient(player, arriveMsg)
	self:FireStateUpdated(player)
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
	end)
end

return FastTravelService
]=]
scriptInst.Parent = current
return "Created ServerScriptService.Server.Services.FastTravelService"
