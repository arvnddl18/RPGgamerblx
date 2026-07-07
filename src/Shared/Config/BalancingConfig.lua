local BalancingConfig = {
	baseMonsterExp = 20,
	monsterExpExponent = 1.45,
	monsterExpOverrides = {},

	difficultyColors = {
		muchWeaker = Color3.fromRGB(80, 220, 80),
		similar = Color3.fromRGB(255, 255, 255),
		slightlyStronger = Color3.fromRGB(255, 230, 80),
		strong = Color3.fromRGB(255, 150, 50),
		dangerous = Color3.fromRGB(220, 60, 60),
		boss = Color3.fromRGB(180, 80, 255),
	},

	levelDiffThresholds = {
		muchWeaker = -10,
		similar = -3,
		slightlyStronger = 3,
		strong = 8,
		dangerous = 15,
	},

	partyExpShare = {
		enabled = false,
		range = 80,
		sharePercent = 0.5,
	},

	expBoosters = {
		enabled = false,
		defaultMultiplier = 1.0,
	},

	regionRecommendations = {},
}

function BalancingConfig.CalculateMonsterExp(level)
	level = math.max(1, math.floor(level or 1))
	if BalancingConfig.monsterExpOverrides[level] then
		return BalancingConfig.monsterExpOverrides[level]
	end
	return math.floor(BalancingConfig.baseMonsterExp * (level ^ BalancingConfig.monsterExpExponent))
end

function BalancingConfig.GetDifficultyColor(monsterLevel, playerLevel, rarity)
	if rarity == "Boss" then
		return BalancingConfig.difficultyColors.boss
	end

	local diff = (monsterLevel or 1) - (playerLevel or 1)
	local thresholds = BalancingConfig.levelDiffThresholds
	local colors = BalancingConfig.difficultyColors

	if diff <= thresholds.muchWeaker then
		return colors.muchWeaker
	elseif diff <= thresholds.similar then
		return colors.similar
	elseif diff <= thresholds.slightlyStronger then
		return colors.slightlyStronger
	elseif diff <= thresholds.strong then
		return colors.strong
	end
	return colors.dangerous
end

return BalancingConfig
