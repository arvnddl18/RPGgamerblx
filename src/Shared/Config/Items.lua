local Items = {
	Herb = {
		id = "Herb",
		name = "Herb",
		description = "A common herb dropped by goblins.",
		type = "material",
		usable = false,
		color = Color3.fromRGB(80, 180, 80),
	},
	HealthPotion = {
		id = "HealthPotion",
		name = "Health Potion",
		description = "Restores 30 HP.",
		type = "consumable",
		usable = true,
		healAmount = 30,
		color = Color3.fromRGB(220, 50, 80),
	},
	ManaPotion = {
		id = "ManaPotion",
		name = "Mana Potion",
		description = "Restores 30 Mana.",
		type = "consumable",
		usable = true,
		manaAmount = 30,
		color = Color3.fromRGB(50, 100, 220),
	},
	IronSword = {
		id = "IronSword",
		name = "Iron Sword",
		description = "A stronger blade.",
		type = "weapon",
		usable = false,
		damage = 25,
		color = Color3.fromRGB(160, 160, 180),
	},
	WoodenSword = {
		id = "WoodenSword",
		name = "Wooden Sword",
		description = "A basic training sword.",
		type = "weapon",
		usable = false,
		damage = 12,
		color = Color3.fromRGB(139, 90, 43),
	},
}

return Items
