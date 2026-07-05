local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RestConfig = require(Shared.Config.Rest)

local RestService = {}
RestService._playerData = nil
RestService._remotes = nil
RestService._resting = {}

function RestService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._remotes = Framework:GetRemotesFolder()
	Framework:GetRemote("SetResting")
end

function RestService:IsResting(player)
	return self._resting[player] == true
end

function RestService:ApplyRestMovement(player, isResting)
	local character = player.Character
	if not character then
		return
	end
	character:SetAttribute("IsResting", isResting)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if isResting then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	else
		local data = self._playerData:GetData(player)
		if data and data.hasSelectedClass then
			humanoid.WalkSpeed = math.max(0, data.combatStats.movementSpeed)
			humanoid.JumpPower = 50
		end
	end
end

function RestService:CancelRest(player, silent)
	if not self._resting[player] then
		return
	end
	self._resting[player] = nil
	self:ApplyRestMovement(player, false)
	if not silent then
		self._remotes.Notification:FireClient(player, "You stop resting.")
	end
end

function RestService:StartRest(player)
	local data = self._playerData:GetData(player)
	if not data or not data.hasSelectedClass then
		return
	end

	if data.hp <= 0 then
		return
	end

	self._resting[player] = true
	self:ApplyRestMovement(player, true)
	self._remotes.Notification:FireClient(player, "Resting... Press M to stand up.")
end

function RestService:HandleSetResting(player, wantsRest)
	if wantsRest then
		if self:IsResting(player) then
			return
		end
		self:StartRest(player)
	else
		self:CancelRest(player)
	end
end

function RestService:Start()
	self._remotes.SetResting.OnServerEvent:Connect(function(player, wantsRest)
		self:HandleSetResting(player, wantsRest == true)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._resting[player] = nil
	end)

	task.spawn(function()
		while task.wait(RestConfig.TickInterval) do
			for player in self._resting do
				if not player.Parent then
					self._resting[player] = nil
					continue
				end

				local data = self._playerData:GetData(player)
				if not data or data.hp <= 0 then
					self:CancelRest(player, true)
					continue
				end

				local atFullHp = data.hp >= data.combatStats.maxHp
				local atFullMana = data.mana >= data.combatStats.maxMana
				if atFullHp and atFullMana then
					self:CancelRest(player)
					self._remotes.Notification:FireClient(player, "Fully recovered.")
					continue
				end

				if not atFullHp then
					self._playerData:Heal(player, RestConfig.HpRegenPerTick)
				end
				if not atFullMana then
					self._playerData:RestoreMana(player, RestConfig.ManaRegenPerTick)
				end

				self:ApplyRestMovement(player, true)
			end
		end
	end)
end

return RestService
