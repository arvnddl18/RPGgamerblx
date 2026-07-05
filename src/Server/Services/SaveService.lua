local SaveService = {}

SaveService._storeName = "SimpleRPG_PlayerData_v1"
SaveService._store = nil
SaveService._playerData = nil
SaveService._dirty = {}

function SaveService:Init()
	local Framework = require(game:GetService("ReplicatedStorage").Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")

	local DataStoreService = game:GetService("DataStoreService")
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(self._storeName)
	end)
	if ok then
		self._store = store
	end
end

function SaveService:MarkDirty(player)
	self._dirty[player] = true
end

function SaveService:LoadPlayer(player)
	if not self._store then
		return nil
	end

	local key = "player_" .. player.UserId
	local ok, data = pcall(function()
		return self._store:GetAsync(key)
	end)

	if ok and type(data) == "table" and (data.version == 1 or data.version == 2) then
		return data
	end
	return nil
end

function SaveService:SavePlayer(player)
	if not self._store then
		return
	end

	local snapshot = self._playerData:GetSaveSnapshot(player)
	if not snapshot then
		return
	end

	local key = "player_" .. player.UserId
	pcall(function()
		self._store:SetAsync(key, snapshot)
	end)
	self._dirty[player] = nil
end

function SaveService:Start()
	local Players = game:GetService("Players")

	Players.PlayerRemoving:Connect(function(player)
		if self._dirty[player] or self._playerData:HasSelectedClass(player) then
			self:SavePlayer(player)
		end
		self._dirty[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(120)
			for _, player in Players:GetPlayers() do
				if self._dirty[player] then
					self:SavePlayer(player)
				end
			end
		end
	end)
end

return SaveService
