local Players = game:GetService("Players")

local DeathService = {}
DeathService._playerData = nil
DeathService._remotes = nil
DeathService._respawning = {}

local RESPAWN_DELAY = 3

function DeathService:Init()
	local Framework = require(game:GetService("ReplicatedStorage").Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._remotes = Framework:GetRemotesFolder()
end

function DeathService:HandleDeath(player)
	if self._respawning[player] then
		return
	end

	self._respawning[player] = true
	self._remotes.Notification:FireClient(player, "You died! Respawning in " .. RESPAWN_DELAY .. " seconds...")

	task.delay(RESPAWN_DELAY, function()
		local data = self._playerData:GetData(player)
		if data then
			data.hp = data.maxHp
			data.mana = data.maxMana
		end

		if player.Parent then
			player:LoadCharacter()
		end

		self._respawning[player] = nil
		if data then
			self._playerData:FireStatsUpdated(player)
		end
	end)
end

function DeathService:Start()
	Players.PlayerRemoving:Connect(function(player)
		self._respawning[player] = nil
	end)
end

return DeathService
