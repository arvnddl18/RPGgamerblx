local EnhancementConfig = {
	STAT_BONUS_PER_LEVEL = 1,
	MAX_ENHANCE_LEVEL = 100,
	-- Scroll stat scaling: 1x at rank 1, about 1.9x at rank 10, and it
	-- approaches 4x by rank 100. Keeping a cap lets high-rank scrolls feel
	-- powerful without outscaling class progression and equipment entirely.
	ScrollPowerScaling = {
		maxMultiplier = 4,
		curve = 25,
	},
	-- Every scroll grants this small all-stat foundation. Category bonuses below
	-- are added on top, so build identity comes from stronger favored stats.
	UniversalScrollBonuses = {
		maxHp = 0.15, maxMana = 0.1,
		physicalAttack = 0.02, magicAttack = 0.02,
		defense = 0.015, magicalResistance = 0.015,
		critChance = 0.00015, critDamage = 0.0003, critReduction = 0.00015,
		accuracy = 0.00015, evasion = 0.0001, healPower = 0.00015,
		buffEffectMultiplier = 0.00005, buffDurationMultiplier = 0.00005,
		movementSpeed = 0.002, hpRegen = 0.005, manaRegen = 0.005,
	},
	ScrollCategories = {
		Fighter = {
			label = "Fighter", description = "All stats, heavily favoring Physical Attack, Defense, and Magic Resistance.",
			biasBonuses = { maxHp = 0.35, physicalAttack = 0.16, defense = 0.085, magicalResistance = 0.085 },
		},
		Mage = {
			label = "Mage", description = "All stats, heavily favoring Magic Attack, Max Mana, and Mana Regeneration.",
			biasBonuses = { magicAttack = 0.16, maxMana = 0.3, magicalResistance = 0.04, manaRegen = 0.02 },
		},
		Healer = {
			label = "Healer", description = "All stats, heavily favoring Heal Power, Max Mana, Magic Attack, and recovery.",
			biasBonuses = { magicAttack = 0.08, maxMana = 0.25, healPower = 0.0015, buffEffectMultiplier = 0.002, buffDurationMultiplier = 0.003, hpRegen = 0.02, critReduction = 0.0002 },
		},
		Lucky = {
			label = "Lucky", description = "All stats, heavily favoring Critical Chance, Critical Damage, Accuracy, and Evasion.",
			biasBonuses = { critChance = 0.00085, critDamage = 0.0017, accuracy = 0.00085, evasion = 0.0007 },
		},
		Guardian = {
			label = "Guardian", description = "All stats, heavily favoring Max HP, defenses, resistance, critical reduction, and HP recovery.",
			biasBonuses = { maxHp = 0.5, defense = 0.085, magicalResistance = 0.085, critReduction = 0.0008, hpRegen = 0.015 },
		},
		Rogue = {
			label = "Rogue", description = "All stats, heavily favoring Evasion, Critical Chance, Accuracy, and Move Speed.",
			biasBonuses = { evasion = 0.00085, critChance = 0.00075, accuracy = 0.0006, movementSpeed = 0.008 },
		},
		Hybrid = {
			label = "Hybrid", description = "All stats, favoring balanced Physical Attack, Magic Attack, HP, Mana, and resistances.",
			biasBonuses = { physicalAttack = 0.07, magicAttack = 0.07, maxHp = 0.18, maxMana = 0.18, defense = 0.025, magicalResistance = 0.025 },
		},
	},
	Tiers = {
		{ maxLevel = 5, applyGoldCost = 10, success = 0.90, fail = 0.10, downgrade = 0.00, breakChance = 0.00 },
		{ maxLevel = 10, applyGoldCost = 50, success = 0.75, fail = 0.20, downgrade = 0.05, breakChance = 0.00 },
		{ maxLevel = 15, applyGoldCost = 150, success = 0.60, fail = 0.25, downgrade = 0.12, breakChance = 0.03 },
		{ maxLevel = 20, applyGoldCost = 500, success = 0.45, fail = 0.30, downgrade = 0.20, breakChance = 0.05 },
	},
}

function EnhancementConfig.GetScrollBonuses(category, level)
	local profile = EnhancementConfig.ScrollCategories[category]
	if not profile then
		return nil
	end

	-- Formula: 1 + (maxMultiplier - 1) * (1 - e^(-(level - 1) / curve))
	-- It rewards each new rank while smoothly approaching the configured cap.
	level = math.clamp(math.floor(level or 1), 1, EnhancementConfig.MAX_ENHANCE_LEVEL)
	local scaling = EnhancementConfig.ScrollPowerScaling
	local multiplier = 1 + (scaling.maxMultiplier - 1) * (1 - math.exp(-(level - 1) / scaling.curve))
	local bonuses = {}
	for stat, value in pairs(EnhancementConfig.UniversalScrollBonuses) do
		bonuses[stat] = value * multiplier
	end
	for stat, value in pairs(profile.biasBonuses or {}) do
		bonuses[stat] = (bonuses[stat] or 0) + value * multiplier
	end
	return bonuses
end

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
