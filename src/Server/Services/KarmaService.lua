local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local KarmaConfig = require(Shared.Config.Karma)
local Items = require(Shared.Config.Items)
local NameColorResolver = require(Shared.Util.NameColorResolver)

local KarmaService = {}
KarmaService._playerData = nil
KarmaService._remotes = nil
KarmaService._enemyService = nil
KarmaService._chaoticTimers = {}

local function getKarmaFlagExpiry(self, player, data)
	return self._chaoticTimers[player] or (data and data.karmaFlagExpiry)
end

function KarmaService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._enemyService = Framework:GetService("EnemyService")
	self._remotes = Framework:GetRemotesFolder()
end

function KarmaService:GetKarmaState(player)
	local data = self._playerData:GetData(player)
	if not data then
		return KarmaConfig.STATE_INNOCENT
	end

	local flagExpiry = getKarmaFlagExpiry(self, player, data)
	if flagExpiry and tick() < flagExpiry then
		return KarmaConfig.STATE_CHAOTIC
	end

	return KarmaConfig.STATE_INNOCENT
end

function KarmaService:GetKarmaFlagSecondsRemaining(player)
	local data = self._playerData:GetData(player)
	if not data then
		return 0
	end

	local flagExpiry = getKarmaFlagExpiry(self, player, data)
	if not flagExpiry then
		return 0
	end

	return math.max(0, math.ceil(flagExpiry - tick()))
end

function KarmaService:GetKarmaColor(player, pvpMode)
	return NameColorResolver.Resolve(self:GetKarmaState(player), pvpMode)
end

function KarmaService:RestorePlayerFlag(player, data)
	if not data or not data.karmaFlagExpiry then
		return
	end
	if tick() < data.karmaFlagExpiry then
		self._chaoticTimers[player] = data.karmaFlagExpiry
	end
end

-- Kill-confirmation flow: called from PlayerDataService:Damage when hp hits 0.
-- Only fires when a Hostile player attacker confirms the killing blow on a Peaceful victim.
-- Same-party and safe-zone kills are blocked upstream in PvpService:CanDamagePlayer.
function KarmaService:ApplyKillPenalty(attacker)
	local data = self._playerData:GetData(attacker)
	if not data then
		return
	end

	data.karmaPoints = (data.karmaPoints or 0) + KarmaConfig.KARMA_PENALTY_PER_KILL
	data.pkCount = (data.pkCount or 0) + KarmaConfig.PK_COUNT_INCREMENT

	local flagExpiry = tick() + KarmaConfig.CHAOTIC_FLAG_DURATION
	self._chaoticTimers[attacker] = flagExpiry
	data.karmaFlagExpiry = flagExpiry

	local minutes = math.ceil(KarmaConfig.CHAOTIC_FLAG_DURATION / 60)
	self._remotes.Notification:FireClient(attacker, "You have become an Outlaw — " .. minutes .. " minutes remaining")

	self:SyncKarmaState(attacker)
end

function KarmaService:SyncKarmaState(player)
	local state = self:GetKarmaState(player)
	player:SetAttribute("KarmaState", state)
	self._playerData:FireStatsUpdated(player)
end

function KarmaService:AddKarma(player, amount)
	local data = self._playerData:GetData(player)
	if not data or amount == 0 then
		return
	end

	data.karmaPoints = (data.karmaPoints or 0) + amount
	self:SyncKarmaState(player)
end

function KarmaService:OnMobKilled(player)
	if not player then
		return
	end
	self:AddKarma(player, KarmaConfig.KARMA_MOB_KILL_BONUS)
end

function KarmaService:OnQuestCompleted(player)
	if not player then
		return
	end
	self:AddKarma(player, KarmaConfig.KARMA_QUEST_COMPLETE_BONUS)
end

function KarmaService:ProcessDeathDrops(player)
	if self:GetKarmaState(player) ~= KarmaConfig.STATE_CHAOTIC then
		return
	end

	local data = self._playerData:GetData(player)
	if not data then
		return
	end

	local dropChance = math.min(
		KarmaConfig.MAX_DROP_CHANCE,
		KarmaConfig.BASE_DROP_CHANCE + ((data.pkCount or 0) * KarmaConfig.DROP_CHANCE_PER_PK)
	)

	if math.random() > dropChance then
		return
	end

	local materialEntries = {}
	for idx, invItem in ipairs(data.inventory) do
		local itemConfig = Items[invItem.id]
		if itemConfig and itemConfig.type == "material" then
			table.insert(materialEntries, { index = idx, entry = invItem })
		end
	end

	if #materialEntries == 0 then
		return
	end

	local dropChoice = materialEntries[math.random(1, #materialEntries)]
	local itemEntry = dropChoice.entry
	local itemId = itemEntry.id

	if itemEntry.count and itemEntry.count > 1 then
		itemEntry.count -= 1
	else
		table.remove(data.inventory, dropChoice.index)
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local dropPosition = root and root.Position or Vector3.new()

	if self._enemyService then
		self._enemyService:CreatePickup(dropPosition, itemId)
	end

	self._remotes.Notification:FireClient(player, "You dropped a material due to your Chaotic status!")
	self._remotes.InventoryUpdated:FireClient(player, data.inventory)
	self._playerData:FireStatsUpdated(player)
end

function KarmaService:Start()
	Players.PlayerRemoving:Connect(function(player)
		self._chaoticTimers[player] = nil
	end)

	task.spawn(function()
		while task.wait(5) do
			local now = tick()
			for _, player in ipairs(Players:GetPlayers()) do
				local expiry = self._chaoticTimers[player]
				if expiry and now >= expiry then
					self._chaoticTimers[player] = nil
					local data = self._playerData:GetData(player)
					if data then
						data.karmaFlagExpiry = nil
					end
					self._remotes.Notification:FireClient(player, "Your Chaotic flag has expired.")
					self:SyncKarmaState(player)
				end
			end
		end
	end)

	task.spawn(function()
		while task.wait(KarmaConfig.KARMA_REGEN_INTERVAL) do
			for _, player in ipairs(Players:GetPlayers()) do
				if self:GetKarmaState(player) ~= KarmaConfig.STATE_CHAOTIC then
					self:AddKarma(player, KarmaConfig.KARMA_REGEN_AMOUNT)
				end
			end
		end
	end)
end

return KarmaService
