local ExperienceConfig = {
	maxLevel = 100,
	baseExp = 100,
	growthMultiplier = 1.22,
	curveExponent = 0.65,
	curveType = "hybrid",
	levelOverrides = {
		[2] = 180,
		[3] = 300,
		[10] = 2000,
		[25] = 12000,
	},
	prestige = {
		enabled = false,
		resetLevel = 1,
		expMultiplierPerPrestige = 1.5,
	},
}

local function computeHybridXp(level)
	return math.floor(
		ExperienceConfig.baseExp
			* (level ^ ExperienceConfig.curveExponent)
			* (ExperienceConfig.growthMultiplier ^ (level - 1))
	)
end

local function computePowerXp(level)
	return math.floor(ExperienceConfig.baseExp * (level ^ ExperienceConfig.curveExponent))
end

local function computeExponentialXp(level)
	return math.floor(ExperienceConfig.baseExp * (ExperienceConfig.growthMultiplier ^ (level - 1)))
end

function ExperienceConfig.GetRequiredXp(level)
	level = math.max(1, math.floor(level or 1))

	if ExperienceConfig.levelOverrides[level] then
		return ExperienceConfig.levelOverrides[level]
	end

	local curveType = ExperienceConfig.curveType
	if curveType == "power" then
		return computePowerXp(level)
	elseif curveType == "exponential" then
		return computeExponentialXp(level)
	elseif curveType == "table" then
		return ExperienceConfig.levelOverrides[level] or computeHybridXp(level)
	end

	return computeHybridXp(level)
end

function ExperienceConfig.GetTotalXpForLevel(level)
	level = math.max(1, math.floor(level or 1))
	local total = 0
	for currentLevel = 1, level - 1 do
		total += ExperienceConfig.GetRequiredXp(currentLevel)
	end
	return total
end

function ExperienceConfig.GetLevelFromTotalXp(totalXp)
	totalXp = math.max(0, math.floor(totalXp or 0))
	local level = 1
	local remaining = totalXp

	while level < ExperienceConfig.maxLevel do
		local required = ExperienceConfig.GetRequiredXp(level)
		if remaining < required then
			break
		end
		remaining -= required
		level += 1
	end

	return level, remaining
end

function ExperienceConfig.GetPrestigeMultiplier(prestigeCount)
	if not ExperienceConfig.prestige.enabled then
		return 1
	end
	prestigeCount = math.max(0, math.floor(prestigeCount or 0))
	return ExperienceConfig.prestige.expMultiplierPerPrestige ^ prestigeCount
end

function ExperienceConfig.IsMaxLevel(level)
	return math.floor(level or 1) >= ExperienceConfig.maxLevel
end

return ExperienceConfig
