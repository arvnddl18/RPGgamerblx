local LevelGrowth = {
	baseRequiredXp = 100,
	xpExponent = 1.15,
	perLevel = {
		maxHp = 12,
		maxMana = 5,
		physicalAttack = 2,
		magicAttack = 2,
		defense = 1,
	},
}

function LevelGrowth.GetRequiredXp(level)
	return math.floor(LevelGrowth.baseRequiredXp * (level ^ LevelGrowth.xpExponent))
end

function LevelGrowth.GetLevelBonuses(level)
	local bonuses = {
		maxHp = 0,
		maxMana = 0,
		physicalAttack = 0,
		magicAttack = 0,
		defense = 0,
	}
	local levelsGained = math.max(0, level - 1)
	for stat, amount in LevelGrowth.perLevel do
		bonuses[stat] = amount * levelsGained
	end
	return bonuses
end

return LevelGrowth
