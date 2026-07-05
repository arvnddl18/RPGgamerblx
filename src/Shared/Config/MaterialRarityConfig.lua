local MaterialRarityConfig = {
	weights = {
		{ rarity = "Common", weight = 60 },
		{ rarity = "Uncommon", weight = 25 },
		{ rarity = "Rare", weight = 10 },
		{ rarity = "Epic", weight = 4 },
		{ rarity = "Legendary", weight = 1 },
	},
}

function MaterialRarityConfig.Roll()
	local totalWeight = 0
	for _, entry in MaterialRarityConfig.weights do
		totalWeight += entry.weight
	end

	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for _, entry in MaterialRarityConfig.weights do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.rarity
		end
	end
	return "Common"
end

return MaterialRarityConfig
