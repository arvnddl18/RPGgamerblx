local Classes = {
	Warrior = {
		id = "Warrior",
		displayName = "Warrior",
		description = "Frontline melee fighter with high HP and defense.",
		role = "Tank / Melee",
		accentColor = Color3.fromRGB(180, 60, 60),
		baseStats = {
			maxHp = 150,
			maxMana = 30,
			physicalAttack = 18,
			magicAttack = 4,
			defense = 12,
			movementSpeed = 16,
		},
		startingEquipment = {
			weapon = "WarriorSword",
			helmet = "WarriorHelm",
			shoulders = "WarriorShoulders",
			armor = "WarriorPlate",
			upperArms = "WarriorUpperArms",
			gloves = "WarriorGauntlets",
			pants = "WarriorLeggings",
			boots = "WarriorBoots",
		},
		skills = {
			autoAttack = "Warrior_AutoAttack",
			skill1 = "Warrior_Slash",
			skill2 = "Warrior_Charge",
			skill3 = "Warrior_Whirlwind",
			ultimate = "Warrior_Berserk",
		},
		masteryPassive = {
			name = "Bloodlust",
			description = "Restore health from physical damage dealt.",
			rank5Bonuses = { physicalLifeSteal = 0.08 },
			rank10Bonuses = { physicalLifeSteal = 0.15 },
		},
	},
	Mage = {
		id = "Mage",
		displayName = "Mage",
		description = "Arcane spellcaster with devastating magic attacks.",
		role = "Magic DPS",
		accentColor = Color3.fromRGB(80, 100, 220),
		baseStats = {
			maxHp = 80,
			maxMana = 100,
			physicalAttack = 5,
			magicAttack = 22,
			defense = 5,
			movementSpeed = 15,
		},
		startingEquipment = {
			weapon = "MageStaff",
			helmet = "MageHood",
			shoulders = "MageShoulders",
			armor = "MageRobe",
			upperArms = "MageUpperArms",
			gloves = "MageGloves",
			pants = "MagePants",
			boots = "MageBoots",
		},
		skills = {
			autoAttack = "Mage_AutoAttack",
			skill1 = "Mage_Fireball",
			skill2 = "Mage_IceSpike",
			skill3 = "Mage_LightningStorm",
			ultimate = "Mage_Meteor",
		},
		masteryPassive = {
			name = "Arcane Siphon",
			description = "Restore health from magic damage dealt.",
			rank5Bonuses = { magicLifeSteal = 0.08 },
			rank10Bonuses = { magicLifeSteal = 0.15 },
		},
	},
	Archer = {
		id = "Archer",
		displayName = "Archer",
		description = "Ranged specialist who strikes from a distance.",
		role = "Ranged DPS",
		accentColor = Color3.fromRGB(60, 160, 80),
		baseStats = {
			maxHp = 100,
			maxMana = 50,
			physicalAttack = 16,
			magicAttack = 8,
			defense = 7,
			movementSpeed = 18,
		},
		startingEquipment = {
			weapon = "ArcherBow",
			helmet = "ArcherCap",
			shoulders = "ArcherShoulders",
			armor = "ArcherVest",
			upperArms = "ArcherUpperArms",
			gloves = "ArcherGloves",
			pants = "ArcherPants",
			boots = "ArcherBoots",
		},
		skills = {
			autoAttack = "Archer_AutoAttack",
			skill1 = "Archer_MultiShot",
			skill2 = "Archer_PiercingArrow",
			skill3 = "Archer_RainOfArrows",
			ultimate = "Archer_SniperShot",
		},
		masteryPassive = {
			name = "Eagle Eye",
			description = "Increase critical-hit chance.",
			rank5Bonuses = { critChance = 0.10 },
			rank10Bonuses = { critChance = 0.20 },
		},
	},
	Priest = {
		id = "Priest",
		displayName = "Priest",
		description = "Holy healer who supports allies and smites foes.",
		role = "Healer / Support",
		accentColor = Color3.fromRGB(220, 200, 80),
		baseStats = {
			maxHp = 110,
			maxMana = 90,
			physicalAttack = 8,
			magicAttack = 16,
			defense = 9,
			movementSpeed = 15,
		},
		startingEquipment = {
			weapon = "PriestMace",
			helmet = "PriestHood",
			shoulders = "PriestShoulders",
			armor = "PriestRobe",
			upperArms = "PriestUpperArms",
			gloves = "PriestGloves",
			pants = "PriestPants",
			boots = "PriestBoots",
		},
		skills = {
			autoAttack = "Priest_AutoAttack",
			skill1 = "Priest_Heal",
			skill2 = "Priest_Blessing",
			skill3 = "Priest_HolyNova",
			ultimate = "Priest_DivineProtection",
		},
		masteryPassive = {
			name = "Divine Grace",
			description = "Increase the effect and duration of friendly buffs.",
			rank5Bonuses = { buffEffectMultiplier = 0.15, buffDurationMultiplier = 0.15 },
			rank10Bonuses = { buffEffectMultiplier = 0.30, buffDurationMultiplier = 0.30 },
		},
	},
	Kavalier = {
		id = "Kavalier",
		displayName = "Kavalier",
		description = "Lancer knight who charges into battle with a spear.",
		role = "Lancer / Melee",
		accentColor = Color3.fromRGB(140, 80, 200),
		baseStats = {
			maxHp = 130,
			maxMana = 45,
			physicalAttack = 17,
			magicAttack = 6,
			defense = 10,
			movementSpeed = 17,
		},
		startingEquipment = {
			weapon = "KavalierSpear",
			helmet = "KavalierHelm",
			shoulders = "KavalierShoulders",
			armor = "KavalierArmor",
			upperArms = "KavalierUpperArms",
			gloves = "KavalierGauntlets",
			pants = "KavalierPants",
			boots = "KavalierBoots",
		},
		skills = {
			autoAttack = "Kavalier_AutoAttack",
			skill1 = "Kavalier_DashStrike",
			skill2 = "Kavalier_SpearThrow",
			skill3 = "Kavalier_LanceSpin",
			ultimate = "Kavalier_DragonCharge",
		},
		masteryPassive = {
			name = "Cavalier's Momentum",
			description = "Increase movement speed while fighting on foot.",
			rank5Bonuses = { movementSpeed = 2 },
			rank10Bonuses = { movementSpeed = 4 },
		},
	},
}

function Classes.GetAll()
	local list = {}
	for _, classConfig in Classes do
		if type(classConfig) == "table" and classConfig.id then
			table.insert(list, classConfig)
		end
	end
	table.sort(list, function(a, b)
		return a.displayName < b.displayName
	end)
	return list
end

return Classes
