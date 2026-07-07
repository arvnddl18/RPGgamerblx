local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalancingConfig = require(Shared.Config.BalancingConfig)
local ExperienceConfig = require(Shared.Config.ExperienceConfig)
local MonsterConfig = require(Shared.Config.MonsterConfig)

local ExperienceService = {}
ExperienceService._playerData = nil
ExperienceService._partyService = nil

function ExperienceService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._partyService = Framework:GetService("PartyService")
end

function ExperienceService:GetBoosterMultiplier(_player)
	if not BalancingConfig.expBoosters.enabled then
		return 1
	end
	return BalancingConfig.expBoosters.defaultMultiplier
end

function ExperienceService:GetPartyMultiplier(_player, _source)
	if not BalancingConfig.partyExpShare.enabled then
		return 1
	end
	return 1
end

function ExperienceService:CalculateMonsterReward(monsterConfig, _killerLevel)
	local config = MonsterConfig.Normalize(monsterConfig)
	if not config then
		return 0
	end
	return config.experienceReward or BalancingConfig.CalculateMonsterExp(config.level or 1)
end

function ExperienceService:GrantExperience(player, amount, _source)
	if not player or not self._playerData then
		return
	end

	amount = math.floor(amount or 0)
	if amount <= 0 then
		return
	end

	local data = self._playerData:GetData(player)
	if not data then
		return
	end

	local prestigeCount = data.prestigeCount or 0
	local multiplier = ExperienceConfig.GetPrestigeMultiplier(prestigeCount)
		* self:GetBoosterMultiplier(player)
		* self:GetPartyMultiplier(player, _source)

	local finalAmount = math.floor(amount * multiplier)
	if finalAmount <= 0 then
		return
	end

	self._playerData:AddXP(player, finalAmount)
end

function ExperienceService:Start()
end

return ExperienceService
