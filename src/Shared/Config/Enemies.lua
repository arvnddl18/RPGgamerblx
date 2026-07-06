-- ⚠️ ANIMATION IDs ARE PLACEHOLDERS — Replace each rbxassetid://9XXXXXXX with your actual uploaded animation ID.
-- Monster walk/idle/attack: 90000061–90000085
-- Goblin: walk 90000061, idle 90000062, attacks 90000063–90000064
-- Skeleton: walk 90000065, idle 90000066, attacks 90000067–90000068
-- Orc: walk 90000069, idle 90000070, attacks 90000071–90000073
-- DireWolf: walk 90000074, idle 90000075, attacks 90000076–90000077
-- Spider: walk 90000078, idle 90000079, attacks 90000080–90000081
-- Slime: walk 90000082, idle 90000083, attacks 90000084–90000085

local Enemies = {
	Goblin = {
		id = "Goblin",
		name = "Goblin",
		MaxHP = 50,
		PhysicalDamage = 8,
		PhysicalResistance = 3,
		MoveSpeed = 4,
		attackCooldown = 3,
		aggroRange = 40,
		attackRange = 6,
		xpReward = 20,
		coinReward = 20,
		dropChance = 0.35,
		dropItem = "Herb",
		lootTableId = "GoblinDrops",
		color = Color3.fromRGB(60, 140, 60),
		damageType = "physical",
		statusEffect = "Bleed",

		-- Animation metadata
		walkAnimId = "rbxassetid://90000061",
		idleAnimId = "rbxassetid://90000062",
		attackAnims = {
			"rbxassetid://90000063",
			"rbxassetid://90000064",
		},
		attackHitTime = 0.4, -- seconds from attack start to damage application
	},
	Skeleton = {
		id = "Skeleton",
		name = "Skeleton",
		MaxHP = 75,
		PhysicalDamage = 12,
		PhysicalResistance = 5,
		MoveSpeed = 4,
		attackCooldown = 3.5,
		aggroRange = 45,
		attackRange = 6,
		xpReward = 35,
		coinReward = 30,
		dropChance = 0.25,
		dropItem = "Herb",
		lootTableId = "SkeletonDrops",
		color = Color3.fromRGB(200, 200, 190),
		damageType = "physical",
		statusEffect = "Slow",

		-- Animation metadata
		walkAnimId = "rbxassetid://90000065",
		idleAnimId = "rbxassetid://90000066",
		attackAnims = {
			"rbxassetid://90000067",
			"rbxassetid://90000068",
		},
		attackHitTime = 0.45,
	},
	Orc = {
		id = "Orc",
		name = "Orc",
		MaxHP = 120,
		PhysicalDamage = 18,
		PhysicalResistance = 8,
		MoveSpeed = 3,
		attackCooldown = 4,
		aggroRange = 40,
		attackRange = 7,
		xpReward = 60,
		coinReward = 50,
		dropChance = 0.5,
		dropItem = "IronOre",
		lootTableId = "OrcDrops",
		color = Color3.fromRGB(50, 100, 40),
		damageType = "physical",
		statusEffect = "Stun",

		-- Animation metadata
		walkAnimId = "rbxassetid://90000069",
		idleAnimId = "rbxassetid://90000070",
		attackAnims = {
			"rbxassetid://90000071",
			"rbxassetid://90000072",
			"rbxassetid://90000073",
		},
		attackHitTime = 0.5,
	},
	DireWolf = {
		id = "DireWolf",
		name = "DireWolf",
		MaxHP = 80,
		PhysicalDamage = 14,
		PhysicalResistance = 4,
		MoveSpeed = 7,
		attackCooldown = 2,
		aggroRange = 60,
		attackRange = 6,
		xpReward = 40,
		coinReward = 35,
		dropChance = 0.3,
		dropItem = "BeastHide",
		lootTableId = "WolfDrops",
		color = Color3.fromRGB(80, 80, 80),
		damageType = "physical",
		statusEffect = "Bleed",

		-- Animation metadata
		walkAnimId = "rbxassetid://90000074",
		idleAnimId = "rbxassetid://90000075",
		attackAnims = {
			"rbxassetid://90000076",
			"rbxassetid://90000077",
		},
		attackHitTime = 0.3,
	},
	Spider = {
		id = "Spider",
		name = "Spider",
		MaxHP = 60,
		PhysicalDamage = 10,
		PhysicalResistance = 2,
		MoveSpeed = 6,
		attackCooldown = 2.5,
		aggroRange = 50,
		attackRange = 5,
		xpReward = 30,
		coinReward = 25,
		dropChance = 0.4,
		dropItem = "BeastHide",
		lootTableId = "SpiderDrops",
		color = Color3.fromRGB(40, 40, 40),
		damageType = "magic",
		statusEffect = "Poison",

		-- Animation metadata
		walkAnimId = "rbxassetid://90000078",
		idleAnimId = "rbxassetid://90000079",
		attackAnims = {
			"rbxassetid://90000080",
			"rbxassetid://90000081",
		},
		attackHitTime = 0.35,
	},
	Slime = {
		id = "Slime",
		name = "Slime",
		MaxHP = 40,
		PhysicalDamage = 5,
		PhysicalResistance = 1,
		MoveSpeed = 2,
		attackCooldown = 4,
		aggroRange = 30,
		attackRange = 5,
		xpReward = 15,
		coinReward = 10,
		dropChance = 0.2,
		dropItem = "Herb",
		lootTableId = "SlimeDrops",
		color = Color3.fromRGB(50, 200, 100),
		damageType = "magic",
		statusEffect = "Slow",

		-- Animation metadata
		walkAnimId = "rbxassetid://90000082",
		idleAnimId = "rbxassetid://90000083",
		attackAnims = {
			"rbxassetid://90000084",
			"rbxassetid://90000085",
		},
		attackHitTime = 0.5,
	}
}

return Enemies
