local RarityConfig = {
	ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
	Common = {
		id = "Common",
		name = "Common",
		multiplierMin = 0.8,
		multiplierMax = 1.0,
		color = Color3.fromRGB(200, 200, 200),
		hasAffix = false,
	},
	Uncommon = {
		id = "Uncommon",
		name = "Uncommon",
		multiplierMin = 1.0,
		multiplierMax = 1.2,
		color = Color3.fromRGB(100, 200, 100),
		hasAffix = false,
	},
	Rare = {
		id = "Rare",
		name = "Rare",
		multiplierMin = 1.2,
		multiplierMax = 1.4,
		color = Color3.fromRGB(50, 100, 220),
		hasAffix = false,
	},
	Epic = {
		id = "Epic",
		name = "Epic",
		multiplierMin = 1.4,
		multiplierMax = 1.7,
		color = Color3.fromRGB(150, 50, 200),
		hasAffix = false,
	},
	Legendary = {
		id = "Legendary",
		name = "Legendary",
		multiplierMin = 1.7,
		multiplierMax = 2.0,
		color = Color3.fromRGB(255, 180, 50),
		hasAffix = true,
	},
	Mythic = {
		id = "Mythic",
		name = "Mythic",
		multiplierMin = 2.0,
		multiplierMax = 2.5,
		color = Color3.fromRGB(255, 50, 50),
		hasAffix = true,
	},
}

function RarityConfig.GetRank(rarityId)
	rarityId = rarityId or "Common"
	for rank, id in RarityConfig.ORDER do
		if id == rarityId then
			return rank
		end
	end
	return 1
end

function RarityConfig.GetNextRarity(rarityId)
	local rank = RarityConfig.GetRank(rarityId)
	local nextId = RarityConfig.ORDER[rank + 1]
	return nextId
end

function RarityConfig.MeetsMinRarity(haveRarity, requiredRarity)
	return RarityConfig.GetRank(haveRarity or "Common") >= RarityConfig.GetRank(requiredRarity or "Common")
end

function RarityConfig.GetColor(rarityId)
	local tier = RarityConfig[rarityId]
	return tier and tier.color or Color3.fromRGB(200, 200, 200)
end

-- Returns a random multiplier based on the rarity tier's bounds
function RarityConfig.RollMultiplier(rarityId)
	local tier = RarityConfig[rarityId]
	if not tier then
		return 1.0
	end
	return tier.multiplierMin + (math.random() * (tier.multiplierMax - tier.multiplierMin))
end

-- Generates a complete item object table
function RarityConfig.GenerateItem(itemId, rarityId)
	local tierId = rarityId or "Common"
	local multiplier = RarityConfig.RollMultiplier(tierId)
	return {
		id = itemId,
		rarity = tierId,
		statMultiplier = multiplier,
		-- Could generate a random affix here if hasAffix is true
	}
end

return RarityConfig
