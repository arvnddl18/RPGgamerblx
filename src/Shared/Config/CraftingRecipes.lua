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
	WarriorWeapon_Upgrade = {
		id = "WarriorWeapon_Upgrade",
		type = "equipmentUpgrade",
		slot = "weapon",
		classRestriction = "Warrior",
		materials = { { itemId = "IronOre" } },
	},
	WarriorArmor_Upgrade = {
		id = "WarriorArmor_Upgrade",
		type = "equipmentUpgrade",
		slot = "armor",
		classRestriction = "Warrior",
		materials = { { itemId = "IronOre" } },
	},
	MageWeapon_Upgrade = {
		id = "MageWeapon_Upgrade",
		type = "equipmentUpgrade",
		slot = "weapon",
		classRestriction = "Mage",
		materials = { { itemId = "ArcaneDust" } },
	},
	MageArmor_Upgrade = {
		id = "MageArmor_Upgrade",
		type = "equipmentUpgrade",
		slot = "armor",
		classRestriction = "Mage",
		materials = { { itemId = "ArcaneDust" } },
	},
	ArcherWeapon_Upgrade = {
		id = "ArcherWeapon_Upgrade",
		type = "equipmentUpgrade",
		slot = "weapon",
		classRestriction = "Archer",
		materials = { { itemId = "BeastHide" } },
	},
	PriestWeapon_Upgrade = {
		id = "PriestWeapon_Upgrade",
		type = "equipmentUpgrade",
		slot = "weapon",
		classRestriction = "Priest",
		materials = { { itemId = "ArcaneDust" } },
	},
	KavalierWeapon_Upgrade = {
		id = "KavalierWeapon_Upgrade",
		type = "equipmentUpgrade",
		slot = "weapon",
		classRestriction = "Kavalier",
		materials = { { itemId = "BeastHide" } },
	},
}

return CraftingRecipes
