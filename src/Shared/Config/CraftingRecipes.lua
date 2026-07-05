local CraftingRecipes = {
	-- Example recipe
	HealthPotion = {
		id = "HealthPotion",
		resultItem = "HealthPotion",
		resultAmount = 1,
		requiredLevel = 1,
		materials = {
			{ itemId = "Herb", amount = 2 },
		}
	},
	ManaPotion = {
		id = "ManaPotion",
		resultItem = "ManaPotion",
		resultAmount = 1,
		requiredLevel = 1,
		materials = {
			{ itemId = "Herb", amount = 3 },
		}
	},
	-- Weapons and equipment
	IronSword = {
		id = "IronSword",
		resultItem = "IronSword",
		resultAmount = 1,
		requiredLevel = 5,
		materials = {
			{ itemId = "Herb", amount = 10 }, -- placeholder
		}
	}
}

return CraftingRecipes
