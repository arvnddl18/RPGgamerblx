local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PvpConfig = require(Shared.Config.Pvp)

local PvpService = {}
PvpService._playerData = nil
PvpService._partyService = nil
PvpService._remotes = nil
PvpService._toggleCooldowns = {}

function PvpService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._partyService = Framework:GetService("PartyService")
	self._remotes = Framework:GetRemotesFolder()

	Framework:GetRemote("SetPvpMode")
end

function PvpService:GetPvpMode(player)
	local data = self._playerData:GetData(player)
	if not data then
		return "Peaceful"
	end
	return data.pvpMode or "Peaceful"
end

function PvpService:IsHostile(player)
	return self:GetPvpMode(player) == "Hostile"
end

function PvpService:IsInSafeZone(player)
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local pos = root.Position
	local dist = math.sqrt(pos.X * pos.X + pos.Z * pos.Z)
	return dist <= PvpConfig.VillageSafeZoneRadius
end

function PvpService:CanDamagePlayer(attacker, target)
	if not attacker or not target or attacker == target then
		return false
	end

	if self._partyService and self._partyService:AreInSameParty(attacker, target) then
		return false
	end

	if self:IsInSafeZone(attacker) or self:IsInSafeZone(target) then
		return false
	end

	return self:IsHostile(attacker)
end

function PvpService:IsInCombat(player)
	local data = self._playerData:GetData(player)
	if not data or not data.hasSelectedClass then
		return false
	end

	if data.lastCombatTime and tick() - data.lastCombatTime < PvpConfig.CombatTagSeconds then
		return true
	end

	return false
end

function PvpService:SyncPlayerAttribute(player)
	local mode = self:GetPvpMode(player)
	player:SetAttribute("PvpMode", mode)
end

function PvpService:HandleSetPvpMode(player, mode)
	if mode ~= "Peaceful" and mode ~= "Hostile" then
		return
	end

	local data = self._playerData:GetData(player)
	if not data or not data.hasSelectedClass then
		return
	end

	if self:GetPvpMode(player) == mode then
		return
	end

	local cooldownExpires = self._toggleCooldowns[player]
	if cooldownExpires and tick() < cooldownExpires then
		local remaining = math.ceil(cooldownExpires - tick())
		self._remotes.Notification:FireClient(player, "PvP toggle on cooldown (" .. remaining .. "s)")
		return
	end

	if self:IsInCombat(player) then
		self._remotes.Notification:FireClient(player, "Cannot change PvP mode while in combat.")
		return
	end

	data.pvpMode = mode
	self:SyncPlayerAttribute(player)
	self._toggleCooldowns[player] = tick() + PvpConfig.ToggleCooldownSeconds
	self._playerData:FireStatsUpdated(player)
	self._remotes.Notification:FireClient(player, "PvP mode: " .. mode)
end

function PvpService:Start()
	self._remotes.SetPvpMode.OnServerEvent:Connect(function(player, mode)
		self:HandleSetPvpMode(player, mode)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._toggleCooldowns[player] = nil
	end)
end

return PvpService
