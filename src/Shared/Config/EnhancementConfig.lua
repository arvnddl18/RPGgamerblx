local EnhancementConfig = {
	STAT_BONUS_PER_LEVEL = 1,
	MAX_ENHANCE_LEVEL = 20,
	Tiers = {
		{ maxLevel = 5, applyGoldCost = 10, success = 0.90, fail = 0.10, downgrade = 0.00, breakChance = 0.00 },
		{ maxLevel = 10, applyGoldCost = 50, success = 0.75, fail = 0.20, downgrade = 0.05, breakChance = 0.00 },
		{ maxLevel = 15, applyGoldCost = 150, success = 0.60, fail = 0.25, downgrade = 0.12, breakChance = 0.03 },
		{ maxLevel = 20, applyGoldCost = 500, success = 0.45, fail = 0.30, downgrade = 0.20, breakChance = 0.05 },
	},
}

function EnhancementConfig.GetTierForLevel(targetLevel)
	for _, tier in EnhancementConfig.Tiers do
		if targetLevel <= tier.maxLevel then
			return tier
		end
	end
	return EnhancementConfig.Tiers[#EnhancementConfig.Tiers]
end

function EnhancementConfig.GetTierForScroll(scrollTier)
	return EnhancementConfig.GetTierForLevel(scrollTier)
end

function EnhancementConfig.GetOutcomesForAttempt(currentEnhanceLevel)
	local targetLevel = currentEnhanceLevel + 1
	local tier = EnhancementConfig.GetTierForLevel(targetLevel)
	return tier, targetLevel
end

return EnhancementConfig
