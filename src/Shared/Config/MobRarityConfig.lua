local MobRarityConfig = {
	Common = {
		id = "Common",
		hpScale = 1.0,
		damageScale = 1.0,
		defenseScale = 1.0,
		xpScale = 1.0,
	},
	Uncommon = {
		id = "Uncommon",
		hpScale = 1.2,
		damageScale = 1.1,
		defenseScale = 1.05,
		xpScale = 1.25,
	},
	Rare = {
		id = "Rare",
		hpScale = 1.5,
		damageScale = 1.25,
		defenseScale = 1.15,
		xpScale = 1.75,
	},
	Epic = {
		id = "Epic",
		hpScale = 2.5,
		damageScale = 1.5,
		defenseScale = 1.25,
		xpScale = 3.0,
	},
	Legendary = {
		id = "Legendary",
		hpScale = 5.0,
		damageScale = 2.0,
		defenseScale = 1.5,
		xpScale = 6.0,
	},
	Mythic = {
		id = "Mythic",
		hpScale = 10.0,
		damageScale = 2.5,
		defenseScale = 1.75,
		xpScale = 15.0,
	}
}

return MobRarityConfig
