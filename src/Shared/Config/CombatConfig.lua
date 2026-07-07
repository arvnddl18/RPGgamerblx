local CombatConfig = {
	resistanceHalfLife = 100,
	minDamage = 1,
	enemyMitigationUsesCalculator = true,
	combatIgnoresPlayerLevel = true,
	coneDotThreshold = 0.2,
	pvpScaling = {
		enabled = false,
		levelDiffMultiplier = 0.02,
	},
}

return CombatConfig
