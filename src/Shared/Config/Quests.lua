local Quests = {
	KillGoblins = {
		id = "KillGoblins",
		name = "Goblin Trouble",
		description = "The village is overrun! Defeat 5 Goblins.",
		npcName = "Quest Giver",
		objectiveType = "kill",
		targetEnemy = "Goblin",
		required = 5,
		xpReward = 100,
		coinReward = 50,
		itemRewards = {},
	},
	CollectHerbs = {
		id = "CollectHerbs",
		name = "Herb Gathering",
		description = "Collect 3 Herbs for the village alchemist.",
		npcName = "Herb Master",
		objectiveType = "collect",
		targetItem = "Herb",
		required = 3,
		xpReward = 60,
		coinReward = 30,
		itemRewards = { { itemId = "HealthPotion", count = 2 } },
	},
	TalkToElder = {
		id = "TalkToElder",
		name = "Word of the Elder",
		description = "Speak with the Village Elder near the monument.",
		npcName = "Quest Giver",
		objectiveType = "talk",
		targetNpc = "Village Elder",
		required = 1,
		xpReward = 40,
		coinReward = 20,
		itemRewards = {},
	},
	ReachMonument = {
		id = "ReachMonument",
		name = "Reach the Monument",
		description = "Travel to the grand monument on the hill.",
		npcName = "Quest Giver",
		objectiveType = "reach",
		targetZone = "QuestMonumentZone",
		required = 1,
		xpReward = 80,
		coinReward = 40,
		itemRewards = {},
	},
}

function Quests.GetRequired(config)
	if config.required then
		return config.required
	end
	return config.requiredKills or 1
end

return Quests
