local RarityConfig = require(script.Parent.RarityConfig)
local Items = require(script.Parent.Items)

local TreasureChestConfig = {
	RARITY_ORDER = RarityConfig.ORDER,

	-- Min and max item rolls per chest rarity
	LOOT_COUNTS = {
		Common = { min = 2, max = 3 },
		Uncommon = { min = 2, max = 4 },
		Rare = { min = 3, max = 5 },
		Epic = { min = 4, max = 6 },
		Legendary = { min = 5, max = 7 },
		Mythic = { min = 6, max = 8 },
	},

	-- Hold duration (seconds) required to open chests based on rarity
	HOLD_DURATIONS = {
		Common = 3,
		Uncommon = 5,
		Rare = 8,
		Epic = 12,
		Legendary = 18,
		Mythic = 25,
	},

	-- Mapping boss enemy IDs to the chest rarity they drop
	BOSS_CHEST_MAPPINGS = {
		Dragon = "Legendary",
		-- If Wyvern/Griffin should drop chests too, uncomment:
		-- Wyvern = "Epic",
		-- Griffin = "Epic",
	},

	-- World chest fixed spawn points
	WORLD_SPAWNS = {
		-- Example spawns near the village
		{ position = Vector3.new(100, 3, -100), rarity = "Common", respawnTime = 300 },
		{ position = Vector3.new(-150, 3, 200), rarity = "Uncommon", respawnTime = 600 },
		-- Deep forest
		{ position = Vector3.new(500, 3, -800), rarity = "Rare", respawnTime = 900 },
		-- Mountains
		{ position = Vector3.new(1200, 3, 400), rarity = "Epic", respawnTime = 1200 },
	}
}

-- Master loot pool with the max rarity allowed for each item.
-- If a chest is Rare, it can roll items with maxRarity <= Rare (e.g. Common, Uncommon, Rare)
TreasureChestConfig.MASTER_LOOT_POOL = {
	-- Materials
	{ itemId = "SlimeGel", weight = 100, maxRarity = "Common" },
	{ itemId = "GoblinCloth", weight = 100, maxRarity = "Common" },
	{ itemId = "CopperOre", weight = 90, maxRarity = "Common" },
	{ itemId = "SweetLeaf", weight = 80, maxRarity = "Common" },
	{ itemId = "RustedCoin", weight = 70, maxRarity = "Common" },

	{ itemId = "SilverOre", weight = 70, maxRarity = "Uncommon" },
	{ itemId = "HealingBlossom", weight = 60, maxRarity = "Uncommon" },
	{ itemId = "SpiderSilk", weight = 60, maxRarity = "Uncommon" },
	{ itemId = "GlassBead", weight = 50, maxRarity = "Uncommon" },
	{ itemId = "ManaRoot", weight = 50, maxRarity = "Uncommon" },

	{ itemId = "GoldOre", weight = 50, maxRarity = "Rare" },
	{ itemId = "Ruby", weight = 40, maxRarity = "Rare" },
	{ itemId = "Sapphire", weight = 40, maxRarity = "Rare" },
	{ itemId = "ShinyPearl", weight = 40, maxRarity = "Rare" },
	{ itemId = "DrakeScale", weight = 30, maxRarity = "Rare" },

	{ itemId = "Diamond", weight = 30, maxRarity = "Epic" },
	{ itemId = "Emerald", weight = 30, maxRarity = "Epic" },
	{ itemId = "GoldenIdol", weight = 20, maxRarity = "Epic" },
	{ itemId = "PhoenixFeather", weight = 20, maxRarity = "Epic" },

	{ itemId = "StarFragment", weight = 15, maxRarity = "Legendary" },
	{ itemId = "DragonHorn", weight = 15, maxRarity = "Legendary" },
	{ itemId = "JeweledCrown", weight = 10, maxRarity = "Legendary" },
	{ itemId = "PureAether", weight = 10, maxRarity = "Legendary" },

	{ itemId = "PrismaticGeode", weight = 5, maxRarity = "Mythic" },
	{ itemId = "LeviathanEye", weight = 5, maxRarity = "Mythic" },
	{ itemId = "WorldTreeSap", weight = 5, maxRarity = "Mythic" },

	-- Consumables
	{ itemId = "AppleJuice", weight = 80, maxRarity = "Common" },
	{ itemId = "RedPotion", weight = 60, maxRarity = "Common" },
	
	{ itemId = "BluePotion", weight = 50, maxRarity = "Uncommon" },
	{ itemId = "SpeedyBootsPotion", weight = 40, maxRarity = "Uncommon" },
	
	{ itemId = "WarmSoup", weight = 30, maxRarity = "Rare" },
	{ itemId = "AntidoteHerb", weight = 30, maxRarity = "Rare" },
	{ itemId = "PowerCrystal", weight = 25, maxRarity = "Rare" },
	
	{ itemId = "StarFruit", weight = 20, maxRarity = "Epic" },
	{ itemId = "WardingCharm", weight = 15, maxRarity = "Epic" },
	
	{ itemId = "GoldenApple", weight = 10, maxRarity = "Legendary" },
	{ itemId = "HerosFeast", weight = 10, maxRarity = "Legendary" },
	{ itemId = "InvincibilityStar", weight = 10, maxRarity = "Legendary" },
	
	{ itemId = "ElixirOfLife", weight = 5, maxRarity = "Mythic" },
	{ itemId = "TearsOfTheGoddess", weight = 2, maxRarity = "Mythic" },
}

-- Helper to check if an item rarity is valid for a chest rarity
function TreasureChestConfig.IsValidRarity(itemRarity, chestRarity)
	local itemRank = RarityConfig.GetRank(itemRarity)
	local chestRank = RarityConfig.GetRank(chestRarity)
	return itemRank <= chestRank
end

function TreasureChestConfig.RollChest(chestRarity)
	local counts = TreasureChestConfig.LOOT_COUNTS[chestRarity] or TreasureChestConfig.LOOT_COUNTS.Common
	local numItems = math.random(counts.min, counts.max)
	
	local validPool = {}
	local totalWeight = 0
	
	for _, entry in TreasureChestConfig.MASTER_LOOT_POOL do
		if TreasureChestConfig.IsValidRarity(entry.maxRarity, chestRarity) then
			table.insert(validPool, entry)
			totalWeight += entry.weight
		end
	end
	
	local rolledItems = {}
	for i = 1, numItems do
		local roll = math.random(1, totalWeight)
		local cumulative = 0
		for _, entry in validPool do
			cumulative += entry.weight
			if roll <= cumulative then
				table.insert(rolledItems, entry.itemId)
				break
			end
		end
	end
	
	return rolledItems
end

return TreasureChestConfig
