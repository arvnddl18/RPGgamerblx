local LootTables = {
	GoblinDrops = {
		{ itemId = "Herb", weight = 70 },
		{ itemId = "HealthPotion", weight = 20 },
		{ itemId = "IronSword", weight = 10 },
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
