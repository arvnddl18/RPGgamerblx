local ExperienceConfig = require(script.Parent.ExperienceConfig)

local ClassMasteryConfig = {
	maxRank = 10,
	startingRank = 1,
	skillUpgradeMultiplier = 1.25,
}

-- Mastery deliberately uses the same per-rank requirements as character levels,
-- while remaining a completely separate XP track.
function ClassMasteryConfig.GetRequiredXp(rank)
	rank = math.clamp(math.floor(rank or ClassMasteryConfig.startingRank), ClassMasteryConfig.startingRank, ClassMasteryConfig.maxRank)
	if rank >= ClassMasteryConfig.maxRank then
		return 0
	end
	return ExperienceConfig.GetRequiredXp(rank)
end

function ClassMasteryConfig.IsMaxRank(rank)
	return math.floor(rank or ClassMasteryConfig.startingRank) >= ClassMasteryConfig.maxRank
end

function ClassMasteryConfig.GetPassiveBonuses(classConfig, rank)
	local passive = classConfig and classConfig.masteryPassive
	if not passive or rank < 5 then
		return {}
	end
	return rank >= ClassMasteryConfig.maxRank and (passive.rank10Bonuses or passive.rank5Bonuses or {}) or (passive.rank5Bonuses or {})
end

return ClassMasteryConfig
