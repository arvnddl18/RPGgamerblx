local CraftingRecipes = {
	HealthPotion = {
		id = "HealthPotion",
		type = "consumable",
		resultItem = "HealthPotion",
		resultAmount = 1,
		requiredLevel = 1,
		materials = {
			{ itemId = "Herb", amount = 2 },
		},
	},
	ManaPotion = {
		id = "ManaPotion",
		type = "consumable",
		resultItem = "ManaPotion",
		resultAmount = 1,
		requiredLevel = 1,
		materials = {
			{ itemId = "Herb", amount = 2 },
			{ itemId = "ArcaneDust", amount = 1 },
		},
	},
	AppleJuice = {
		id = "AppleJuice", type = "consumable", resultItem = "AppleJuice", resultAmount = 1, requiredLevel = 1,
		materials = { { itemId = "SweetLeaf", amount = 2 } },
	},
	RedPotion = {
		id = "RedPotion", type = "consumable", resultItem = "RedPotion", resultAmount = 1, requiredLevel = 3,
		materials = { { itemId = "SlimeGel", amount = 3 }, { itemId = "Herb", amount = 1 } },
	},
	BluePotion = {
		id = "BluePotion", type = "consumable", resultItem = "BluePotion", resultAmount = 1, requiredLevel = 3,
		materials = { { itemId = "ManaRoot", amount = 2 }, { itemId = "WaterDrop", amount = 1 } },
	},
	GoldenApple = {
		id = "GoldenApple", type = "consumable", resultItem = "GoldenApple", resultAmount = 1, requiredLevel = 25,
		materials = { { itemId = "LifeSeed", amount = 3 }, { itemId = "GoldenIdol", amount = 1 } },
	},
	TearsOfTheGoddess = {
		id = "TearsOfTheGoddess", type = "consumable", resultItem = "TearsOfTheGoddess", resultAmount = 1, requiredLevel = 50,
		materials = { { itemId = "DragonTear", amount = 2 }, { itemId = "CosmicSpark", amount = 1 }, { itemId = "WorldTreeSap", amount = 1 } },
	},
	WarriorEquipment_Upgrade = {
		id = "WarriorEquipment_Upgrade",
		type = "equipmentUpgrade",
		classRestriction = "Warrior",
		materials = { { itemId = "IronOre" } },
	},
	MageEquipment_Upgrade = {
		id = "MageEquipment_Upgrade",
		type = "equipmentUpgrade",
		classRestriction = "Mage",
		materials = { { itemId = "ArcaneDust" } },
	},
	ArcherEquipment_Upgrade = {
		id = "ArcherEquipment_Upgrade",
		type = "equipmentUpgrade",
		classRestriction = "Archer",
		materials = { { itemId = "BeastHide" } },
	},
	PriestEquipment_Upgrade = {
		id = "PriestEquipment_Upgrade",
		type = "equipmentUpgrade",
		classRestriction = "Priest",
		materials = { { itemId = "ArcaneDust" } },
	},
	KavalierEquipment_Upgrade = {
		id = "KavalierEquipment_Upgrade",
		type = "equipmentUpgrade",
		classRestriction = "Kavalier",
		materials = { { itemId = "BeastHide" } },
	},
}

return CraftingRecipes
