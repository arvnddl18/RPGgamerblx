local LootTables = {
	-- ENHANCEMENT SCROLLS ARE SHOP-ONLY — DO NOT ADD TO ANY LOOT TABLE.
	GoblinDrops = {
		{ itemId = "Herb", weight = 40 },
		{ itemId = "IronOre", weight = 25 },
		{ itemId = "HealthPotion", weight = 20 },
		{ itemId = "IronSword", weight = 5 },
	},
	SkeletonDrops = {
		{ itemId = "Herb", weight = 30 },
		{ itemId = "IronOre", weight = 30 },
		{ itemId = "ArcaneDust", weight = 25 },
		{ itemId = "ManaPotion", weight = 15 },
	},
	OrcDrops = {
		{ itemId = "IronOre", weight = 35 },
		{ itemId = "BeastHide", weight = 35 },
		{ itemId = "HealthPotion", weight = 20 },
		{ itemId = "IronSword", weight = 10 },
	},
	WolfDrops = {
		{ itemId = "BeastHide", weight = 50 },
		{ itemId = "Herb", weight = 30 },
		{ itemId = "HealthPotion", weight = 20 },
	},
	SpiderDrops = {
		{ itemId = "BeastHide", weight = 35 },
		{ itemId = "ArcaneDust", weight = 35 },
		{ itemId = "ManaPotion", weight = 30 },
	},
	SlimeDrops = {
		{ itemId = "Herb", weight = 45 },
		{ itemId = "ArcaneDust", weight = 35 },
		{ itemId = "ManaPotion", weight = 20 },
	},
}

function LootTables.Roll(tableId)
	local tableData = LootTables[tableId]
	if not tableData then
		return nil
	end

	local totalWeight = 0
	for _, entry in tableData do
		totalWeight += entry.weight
	end

	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for _, entry in tableData do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.itemId
		end
	end
	return nil
end

return LootTables
