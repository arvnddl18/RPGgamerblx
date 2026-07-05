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
			armor = "WarriorPlate",
			pants = "WarriorLeggings",
			boots = "WarriorBoots",
			gloves = "WarriorGauntlets",
		},
		skills = {
			autoAttack = "Warrior_AutoAttack",
			skill1 = "Warrior_Slash",
			skill2 = "Warrior_Charge",
			skill3 = "Warrior_Whirlwind",
			ultimate = "Warrior_Berserk",
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
			armor = "MageRobe",
			pants = "MagePants",
			boots = "MageBoots",
			gloves = "MageGloves",
		},
		skills = {
			autoAttack = "Mage_AutoAttack",
			skill1 = "Mage_Fireball",
			skill2 = "Mage_IceSpike",
			skill3 = "Mage_LightningStorm",
			ultimate = "Mage_Meteor",
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
			armor = "ArcherVest",
			pants = "ArcherPants",
			boots = "ArcherBoots",
			gloves = "ArcherGloves",
		},
		skills = {
			autoAttack = "Archer_AutoAttack",
			skill1 = "Archer_MultiShot",
			skill2 = "Archer_PiercingArrow",
			skill3 = "Archer_RainOfArrows",
			ultimate = "Archer_SniperShot",
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
			armor = "PriestRobe",
			pants = "PriestPants",
			boots = "PriestBoots",
			gloves = "PriestGloves",
		},
		skills = {
			autoAttack = "Priest_AutoAttack",
			skill1 = "Priest_Heal",
			skill2 = "Priest_Blessing",
			skill3 = "Priest_HolyNova",
			ultimate = "Priest_DivineProtection",
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
			armor = "KavalierArmor",
			pants = "KavalierPants",
			boots = "KavalierBoots",
			gloves = "KavalierGauntlets",
		},
		skills = {
			autoAttack = "Kavalier_AutoAttack",
			skill1 = "Kavalier_DashStrike",
			skill2 = "Kavalier_SpearThrow",
			skill3 = "Kavalier_LanceSpin",
			ultimate = "Kavalier_DragonCharge",
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
