local LootTables = {
	-- ENHANCEMENT SCROLLS ARE SHOP-ONLY — DO NOT ADD TO ANY LOOT TABLE.
	GoblinDrops = {
		{ itemId = "GoblinCloth", weight = 40 },
		{ itemId = "Herb", weight = 25 },
		{ itemId = "HealthPotion", weight = 20 },
		{ itemId = "IronSword", weight = 10 },
		{ itemId = "WolfFang", weight = 5 },
	},
	SkeletonDrops = {
		{ itemId = "Herb", weight = 30 },
		{ itemId = "IronOre", weight = 30 },
		{ itemId = "ArcaneDust", weight = 25 },
		{ itemId = "ManaPotion", weight = 15 },
	},
	OrcDrops = {
		{ itemId = "IronOre", weight = 30 },
		{ itemId = "BeastHide", weight = 30 },
		{ itemId = "BearClaw", weight = 20 },
		{ itemId = "HealthPotion", weight = 15 },
		{ itemId = "WarriorSword", weight = 5 },
	},
	WolfDrops = {
		{ itemId = "BeastHide", weight = 45 },
		{ itemId = "WolfFang", weight = 25 },
		{ itemId = "Herb", weight = 20 },
		{ itemId = "SpeedyBootsPotion", weight = 10 },
	},
	SpiderDrops = {
		{ itemId = "SpiderSilk", weight = 40 },
		{ itemId = "ArcaneDust", weight = 30 },
		{ itemId = "AntidoteHerb", weight = 20 },
		{ itemId = "ManaPotion", weight = 10 },
	},
	SlimeDrops = {
		{ itemId = "SlimeGel", weight = 50 },
		{ itemId = "Herb", weight = 30 },
		{ itemId = "ArcaneDust", weight = 15 },
		{ itemId = "ManaPotion", weight = 5 },
	},
	-- ELITE / BOSS TABLES
	DragonDrops = {
		{ itemId = "DragonHorn", weight = 40 },
		{ itemId = "DragonTear", weight = 20 },
		{ itemId = "StarFragment", weight = 20 },
		{ itemId = "Starcaller", weight = 10 },
		{ itemId = "DragonLance", weight = 10 },
	},
	WyvernDrops = {
		{ itemId = "DrakeScale", weight = 40 },
		{ itemId = "CrystalShard", weight = 30 },
		{ itemId = "GoldenApple", weight = 20 },
		{ itemId = "AegisPlate", weight = 10 },
	},
	GriffinDrops = {
		{ itemId = "PhoenixFeather", weight = 40 },
		{ itemId = "MagicCore", weight = 30 },
		{ itemId = "Hero's Feast", weight = 20 },
		{ itemId = "Windpiercer", weight = 10 },
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
