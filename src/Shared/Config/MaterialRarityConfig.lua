local MaterialRarityConfig = {
	weights = {
		{ rarity = "Common", weight = 240 },
		{ rarity = "Uncommon", weight = 100 },
		{ rarity = "Rare", weight = 40 },
		{ rarity = "Epic", weight = 16 },
		{ rarity = "Legendary", weight = 4 },
		{ rarity = "Mythic", weight = 1 },
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

