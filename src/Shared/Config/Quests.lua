local MobTypeConfig = require(script.Parent.MobTypeConfig)

local QuestConfig = {
	GoblinMenace = {
		id = "GoblinMenace",
		name = "Goblin Menace",
		npcName = "Goblin Quest Giver",
		description = "Kill 10 goblins terrorizing the village.",
		objective = "Kill Goblins",
		objectiveType = "kill",
		targetEnemy = "Goblin",
		spawnArea = {
			Center = Vector3.new(0, 0, 0),
			Radius = 500,
		},
		targets = {
			{ type = "enemy", name = "Goblin", quantity = 10, mobType = MobTypeConfig.Hostile },
		},
		rewards = {
			gold = 100,
			experience = 500,
			items = {
				{ itemId = "health_potion", quantity = 2 },
			},
		},
		maxProgress = 10,
		mobConfig = MobTypeConfig.Hostile,
	},
	SkeletonScourge = {
		id = "SkeletonScourge",
		name = "Skeleton Scourge",
		description = "Skeletons have invaded the old graveyard. Clear them out.",
		objective = "Slay Skeletons",
		objectiveType = "kill",
		targetEnemy = "Skeleton",
		spawnArea = {
			Center = Vector3.new(100, 50, -300),
			Radius = 200,
		},
		targets = {
			{ type = "enemy", name = "Skeleton", quantity = 15, mobType = MobTypeConfig.Hostile },
		},
		rewards = {
			gold = 150,
			experience = 750,
			items = {
				{ itemId = "mana_potion", quantity = 1 },
				{ itemId = "health_potion", quantity = 1 },
			},
		},
		maxProgress = 15,
		mobConfig = MobTypeConfig.Hostile,
	},
	SpiderInfestation = {
		id = "SpiderInfestation",
		name = "Spider Infestation",
		description = "Giant spiders have taken over the caves to the west. Clear them.",
		objective = "Eliminate Spiders",
		objectiveType = "kill",
		targetEnemy = "Spider",
		spawnArea = {
			Center = Vector3.new(-400, 20, -200),
			Radius = 250,
		},
		targets = {
			{ type = "enemy", name = "Spider", quantity = 20, mobType = MobTypeConfig.Hostile },
		},
		rewards = {
			gold = 200,
			experience = 1000,
			items = {
				{ itemId = "mana_potion", quantity = 2 },
				{ itemId = "health_potion", quantity = 2 },
			},
		},
		maxProgress = 20,
		mobConfig = MobTypeConfig.Hostile,
	},
	OrcInvasion = {
		id = "OrcInvasion",
		name = "Orc Invasion",
		description = "A band of orcs is marching towards the village from the north! Defend the town.",
		objective = "Repel Orcs",
		objectiveType = "kill",
		targetEnemy = "Orc",
		spawnArea = {
			Center = Vector3.new(0, 0, -700),
			Radius = 300,
		},
		targets = {
			{ type = "enemy", name = "Orc", quantity = 25, mobType = MobTypeConfig.Hostile },
		},
		rewards = {
			gold = 300,
			experience = 1500,
			items = {
				{ itemId = "mana_potion", quantity = 3 },
				{ itemId = "health_potion", quantity = 3 },
				{ itemId = "orc_ear", quantity = 5 },
			},
		},
		maxProgress = 25,
		mobConfig = MobTypeConfig.Hostile,
	},
	DireWolfProblem = {
		id = "DireWolfProblem",
		name = "Dire Wolf Problem",
		description = "Dire wolves are attacking livestock outside the village. Hunt them down.",
		objective = "Hunt Wolves",
		objectiveType = "kill",
		targetEnemy = "Dire Wolf",
		spawnArea = {
			Center = Vector3.new(300, 0, -600),
			Radius = 200,
		},
		targets = {
			{ type = "enemy", name = "Dire Wolf", quantity = 8, mobType = MobTypeConfig.Hostile },
		},
		rewards = {
			gold = 120,
			experience = 600,
			items = {
				{ itemId = "health_potion", quantity = 2 },
				{ itemId = "wolf_fang", quantity = 3 },
			},
		},
		maxProgress = 8,
		mobConfig = MobTypeConfig.Hostile,
	},
	SlimeInfestation = {
		id = "SlimeInfestation",
		name = "Slime Infestation",
		description = "Slimes have flooded the swampy areas to the southeast. Clear them out.",
		objective = "Clear Slimes",
		objectiveType = "kill",
		targetEnemy = "Slime",
		spawnArea = {
			Center = Vector3.new(500, 0, 400),
			Radius = 250,
		},
		targets = {
			{ type = "enemy", name = "Slime", quantity = 20, mobType = MobTypeConfig.Neutral },
		},
		rewards = {
			gold = 100,
			experience = 400,
			items = {
				{ itemId = "slime_extract", quantity = 5 },
			},
		},
		maxProgress = 20,
		mobConfig = MobTypeConfig.Neutral,
	},
	GoblinAmbush = {
		id = "GoblinAmbush",
		name = "Goblin Ambush!",
		description = "Goblins have ambushed you on the road! Clear them out.",
		objective = "Defeat Goblins",
		objectiveType = "kill",
		targetEnemy = "Goblin",
		spawnArea = {
			Center = Vector3.new(0, 0, -250),
			Radius = 150,
		},
		targets = {
			{ type = "enemy", name = "Goblin", quantity = 10, mobType = MobTypeConfig.Hostile },
		},
		rewards = {
			gold = 80,
			experience = 400,
			items = {
				{ itemId = "health_potion", quantity = 2 },
			},
		},
		maxProgress = 10,
		mobConfig = MobTypeConfig.Hostile,
	},
	ZombieApocalypse = {
		id = "ZombieApocalypse",
		name = "Zombie Apocalypse",
		description = "Zombies are rising from the cemetery! Clear the area.",
		objective = "Eliminate Zombies",
		objectiveType = "kill",
		targetEnemy = "Skeleton",
		spawnArea = {
			Center = Vector3.new(100, 20, -300),
			Radius = 200,
		},
		targets = {
			{ type = "enemy", name = "Skeleton", quantity = 20, mobType = MobTypeConfig.Hostile },
		},
		rewards = {
			gold = 200,
			experience = 1000,
			items = {
				{ itemId = "mana_potion", quantity = 1 },
				{ itemId = "health_potion", quantity = 1 },
			},
		},
		maxProgress = 20,
		mobConfig = MobTypeConfig.Hostile,
	},
	GiantSpiderNest = {
		id = "GiantSpiderNest",
		name = "Giant Spider Nest",
		description = "A nest of giant spiders has appeared in the caves. Clear them out to stop them from spreading.",
		objective = "Clear the Spider Nest",
		objectiveType = "kill",
		targetEnemy = "Spider",
		spawnArea = {
			Center = Vector3.new(-400, 20, -200),
			Radius = 250,
		},
		targets = {
			{ type = "enemy", name = "Spider", quantity = 20, mobType = MobTypeConfig.Hostile },
		},
		rewards = {
			gold = 200,
			experience = 1000,
			items = {
				{ itemId = "mana_potion", quantity = 2 },
				{ itemId = "health_potion", quantity = 2 },
			},
		},
		maxProgress = 20,
		mobConfig = MobTypeConfig.Hostile,
	},
	OrcishScouts = {
		id = "OrcishScouts",
		name = "Orcish Scouts",
		description = "Orc scouts are scouting the area near the village. Eliminate them to prevent a full invasion.",
		objective = "Eliminate Orc Scouts",
		objectiveType = "kill",
		targetEnemy = "Orc",
		spawnArea = {
			Center = Vector3.new(0, 0, -700),
			Radius = 300,
		},
		targets = {
			{ type = "enemy", name = "Orc", quantity = 15, mobType = MobTypeConfig.Hostile },
		},
		rewards = {
			gold = 150,
			experience = 750,
			items = {
				{ itemId = "health_potion", quantity = 2 },
				{ itemId = "orc_ear", quantity = 3 },
			},
		},
		maxProgress = 15,
		mobConfig = MobTypeConfig.Hostile,
	},
	DireWolfPack = {
		id = "DireWolfPack",
		name = "Dire Wolf Pack",
		description = "A pack of dire wolves has been seen hunting near the village. Hunt them down before they cause more trouble.",
		objective = "Hunt the Wolves",
		objectiveType = "kill",
		targetEnemy = "Dire Wolf",
		spawnArea = {
			Center = Vector3.new(300, 0, -600),
			Radius = 200,
		},
		targets = {
			{ type = "enemy", name = "Dire Wolf", quantity = 8, mobType = MobTypeConfig.Hostile },
		},
		rewards = {
			gold = 120,
			experience = 600,
			items = {
				{ itemId = "health_potion", quantity = 2 },
				{ itemId = "wolf_fang", quantity = 3 },
			},
		},
		maxProgress = 8,
		mobConfig = MobTypeConfig.Hostile,
	},
	SwampSlimes = {
		id = "SwampSlimes",
		name = "Swamp Slimes",
		description = "Slimes have infested the swamp to the southeast. Clear them out to make the area safer.",
		objective = "Clear the Slimes",
		objectiveType = "kill",
		targetEnemy = "Slime",
		spawnArea = {
			Center = Vector3.new(500, 0, 400),
			Radius = 250,
		},
		targets = {
			{ type = "enemy", name = "Slime", quantity = 20, mobType = MobTypeConfig.Neutral },
		},
		rewards = {
			gold = 100,
			experience = 400,
			items = {
				{ itemId = "slime_extract", quantity = 5 },
			},
		},
		maxProgress = 20,
		mobConfig = MobTypeConfig.Neutral,
	},
	ForestBandits = {
		id = "ForestBandits",
		name = "Forest Bandits",
		description = "Bandits are robbing travelers on the forest path. Clear them out to make the roads safer.",
		objective = "Eliminate Bandits",
		objectiveType = "kill",
		targetEnemy = "Bandit",
		spawnArea = {
			Center = Vector3.new(300, 0, -400),
			Radius = 200,
		},
		targets = {
			{ type = "enemy", name = "Bandit", quantity = 12, mobType = MobTypeConfig.Hostile },
		},
		rewards = {
			gold = 180,
			experience = 900,
			items = {
				{ itemId = "health_potion", quantity = 3 },
				{ itemId = "gold_coins", quantity = 1 },
			},
		},
		maxProgress = 12,
		mobConfig = MobTypeConfig.Hostile,
	},
	CollectHerbs = {
		id = "CollectHerbs",
		name = "Collect Herbs",
		description = "The Herb Master needs help gathering herbs from the forest. Collect 5 herbs.",
		objective = "Collect Herbs",
		objectiveType = "collect",
		targetItem = "herb",
		spawnArea = {
			Center = Vector3.new(-15, 0, 140),
			Radius = 300,
		},
		targets = {
			{ type = "item", name = "herb", quantity = 5 },
		},
		rewards = {
			gold = 50,
			experience = 200,
			items = {
				{ itemId = "health_potion", quantity = 1 },
			},
		},
		maxProgress = 5,
		mobConfig = MobTypeConfig.Neutral,
	},
	TalkToElder = {
		id = "TalkToElder",
		name = "Talk to the Elder",
		description = "The Village Elder has important information for you. Go speak with him.",
		objective = "Talk to the Village Elder",
		objectiveType = "talk",
		targetNpc = "Village Elder",
		spawnArea = {
			Center = Vector3.new(0, 0, 110),
			Radius = 100,
		},
		targets = {
			{ type = "npc", name = "Village Elder", quantity = 1 },
		},
		rewards = {
			gold = 25,
			experience = 100,
			items = {},
		},
		maxProgress = 1,
		mobConfig = MobTypeConfig.Neutral,
	},
	ReachMonument = {
		id = "ReachMonument",
		name = "Reach the Monument",
		description = "The Scout has spotted an ancient monument to the north. Reach it to uncover its secrets.",
		objective = "Reach the Monument",
		objectiveType = "reach",
		targetZone = "QuestMonumentZone",
		spawnArea = {
			Center = Vector3.new(0, 0, 300),
			Radius = 200,
		},
		targets = {
			{ type = "zone", name = "QuestMonumentZone", quantity = 1 },
		},
		rewards = {
			gold = 75,
			experience = 300,
			items = {
				{ itemId = "mana_potion", quantity = 1 },
			},
		},
		maxProgress = 1,
		mobConfig = MobTypeConfig.Neutral,
	},
}

function QuestConfig.GetRequired(config)
	return config.maxProgress or 1
end

return QuestConfig