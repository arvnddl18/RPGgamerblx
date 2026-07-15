local MobTypeConfig = require(script.Parent.MobTypeConfig)

-- Chapter 1 is deliberately linear.  The service validates prerequisites;
-- this table remains the single source of truth for UI, rewards, and lore.
local QuestConfig = {
	VanguardAtDawn = {
		id = "VanguardAtDawn", name = "A Vanguard at Dawn", chapter = 1,
		questGiver = "Commander Rhessa Kael", npcName = "Commander Rhessa Kael",
		isMainStory = true, firstInteractionSceneId = "RhessaIntro",
		description = "Speak with Commander Rhessa Kael at the Valdris marketplace.",
		lore = "At dawn, the bells of Valdris call a new Vanguard recruit to service.",
		hints = "Commander Rhessa waits at the marketplace near Emberholt Castle.",
		objective = "Speak with Commander Rhessa", objectiveType = "talk", targetNpc = "Commander Rhessa Kael",
		targets = { { type = "npc", name = "Commander Rhessa Kael", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 25, experience = 100, items = { { itemId = "HealthPotion", quantity = 1 } } },
	},
	VillageSupplyLine = {
		id = "VillageSupplyLine", name = "A Village Worth Saving", chapter = 1,
		questGiver = "Sister Amara", npcName = "Sister Amara", prerequisites = { "VanguardAtDawn" }, isMainStory = true,
		description = "Speak with Sister Amara at Valdris' market infirmary before taking the northern road.",
		lore = "The first refugees speak of a cold that follows the frightened beasts.", hints = "Sister Amara tends the wounded beside the marketplace.",
		objective = "Hear the refugees' account", objectiveType = "talk", targetNpc = "Sister Amara",
		targets = { { type = "npc", name = "Sister Amara", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 25, experience = 100, items = { { itemId = "AppleJuice", quantity = 2 }, { itemId = "AntidoteHerb", quantity = 1 } } },
	},
	NorthernWaygate = {
		id = "NorthernWaygate", name = "The Northern Waygate", chapter = 1,
		questGiver = "Scout Iven", npcName = "Scout Iven", prerequisites = { "VillageSupplyLine" }, isMainStory = true,
		description = "Travel through the North Gate and activate the dormant Frosthorn Waygate.",
		lore = "Only the northern road is open. The other royal waygates remain sealed.",
		hints = "Follow the northern road beyond Valdris until you reach the blue waygate.",
		objective = "Activate the Northern Waygate", objectiveType = "reach", targetZone = "FrosthornWaygate",
		targets = { { type = "zone", name = "FrosthornWaygate", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 40, experience = 150, items = { { itemId = "ManaPotion", quantity = 1 } } },
	},
	FoothillDisturbance = {
		id = "FoothillDisturbance", name = "Foothill Disturbance", chapter = 1,
		questGiver = "Commander Rhessa Kael", npcName = "Commander Rhessa Kael", prerequisites = { "NorthernWaygate" }, isMainStory = true,
		description = "Drive back the Slimes and Goblin raiders gathering in the lower foothills.",
		lore = "Even the smallest creatures are moving uphill, as if fleeing something unseen.",
		hints = "Search the first camps beyond the Frosthorn Waygate.", objective = "Defeat foothill raiders", objectiveType = "kill",
		targets = { { type = "enemy", name = "Slime", quantity = 6 }, { type = "enemy", name = "Goblin", quantity = 6 } }, maxProgress = 12,
		rewards = { gold = 80, experience = 350, items = { { itemId = "HealthPotion", quantity = 2 } } },
	},
	FieldMedicRemedy = {
		id = "FieldMedicRemedy", name = "The Field Medic's Lesson", chapter = 1,
		questGiver = "Sister Amara", npcName = "Sister Amara", prerequisites = { "FoothillDisturbance" }, isMainStory = true,
		description = "Gather Slime Gel and herbs from the foothills, then craft a Health Potion for the wounded.",
		lore = "The green creatures' residue is mundane; the frost in their wounds is not.", hints = "Use the Crafting Master after collecting supplies.",
		objective = "Prepare a field remedy", objectiveType = "collectcraft",
		targets = { { type = "item", name = "SlimeGel", quantity = 3 }, { type = "item", name = "Herb", quantity = 2 }, { type = "craft", name = "HealthPotion", quantity = 1 } }, maxProgress = 6,
		rewards = { gold = 75, experience = 300, items = { { itemId = "WarmSoup", quantity = 2 }, { itemId = "HealthPotion", quantity = 2 } } },
	},
	FleeingPeak = {
		id = "FleeingPeak", name = "Fleeing the Peak", chapter = 1,
		questGiver = "Scout Iven", npcName = "Scout Iven", prerequisites = { "FieldMedicRemedy" }, isMainStory = true,
		description = "Investigate Frostwood and thin the Spider nests and Dire Wolf packs displaced from the summit.",
		lore = "The forest’s predators are not hunting. They are running.", hints = "Continue north into the snow-dusted pines.",
		objective = "Defeat creatures fleeing Frostwood", objectiveType = "kill",
		targets = { { type = "enemy", name = "Spider", quantity = 8 }, { type = "enemy", name = "DireWolf", quantity = 6 } }, maxProgress = 14,
		rewards = { gold = 120, experience = 550, items = { { itemId = "ManaPotion", quantity = 2 } } },
	},
	WebsOfWarning = {
		id = "WebsOfWarning", name = "Webs of Warning", chapter = 1,
		questGiver = "Scout Iven", npcName = "Scout Iven", prerequisites = { "FleeingPeak" }, isMainStory = true,
		description = "Recover Spider Silk from Frostwood. Iven believes the webs were woven to keep something in, not catch prey.",
		lore = "Every strand points away from the summit.", hints = "Search the spider nests in Frostwood.",
		objective = "Collect Spider Silk", objectiveType = "collect", targetItem = "SpiderSilk",
		targets = { { type = "item", name = "SpiderSilk", quantity = 4 } }, maxProgress = 4,
		rewards = { gold = 100, experience = 450, items = { { itemId = "WardingCharm", quantity = 1 }, { itemId = "SpeedyBootsPotion", quantity = 1 } } },
	},
	ScholarInRuins = {
		id = "ScholarInRuins", name = "The Scholar in the Ruins", chapter = 1,
		questGiver = "Magister Toven Ashe", npcName = "Magister Toven Ashe", prerequisites = { "WebsOfWarning" }, unlockNpc = "Magister Toven Ashe", isMainStory = true, firstInteractionSceneId = "TovenIntro",
		description = "Speak with Magister Toven Ashe at the ancient ruins.", lore = "The stones predate Valdris — and perhaps the kingdom itself.",
		hints = "Toven studies the broken archway beyond Frostwood.", objective = "Speak with Magister Toven", objectiveType = "talk", targetNpc = "Magister Toven Ashe",
		targets = { { type = "npc", name = "Magister Toven Ashe", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 75, experience = 300, items = { { itemId = "ArcaneDust", quantity = 2 } } },
	},
	EchoesBelow = {
		id = "EchoesBelow", name = "Echoes Below", chapter = 1,
		questGiver = "Magister Toven Ashe", npcName = "Magister Toven Ashe", prerequisites = { "ScholarInRuins" }, isMainStory = true,
		description = "Clear the Skeletons circling the sealed inner chamber.", lore = "The dead guard a door no living scholar can open.",
		hints = "Search the ruin courtyard and its collapsed halls.", objective = "Defeat Skeleton guardians", objectiveType = "kill",
		targetEnemy = "Skeleton", targets = { { type = "enemy", name = "Skeleton", quantity = 10 } }, maxProgress = 10,
		rewards = { gold = 150, experience = 700, items = { { itemId = "IronOre", quantity = 3 } } },
	},
	SealedChamber = {
		id = "SealedChamber", name = "The Sealed Chamber", chapter = 1,
		questGiver = "Magister Toven Ashe", npcName = "Magister Toven Ashe", prerequisites = { "EchoesBelow" }, isMainStory = true,
		description = "Defeat the Skeleton Knights and inspect the chamber door. Its secret must wait.", lore = "The seal bears a crest scratched out of every royal record.",
		hints = "The elite guardians stand closest to the chamber door.", objective = "Break the chamber guard", objectiveType = "killreach",
		targets = { { type = "enemy", name = "SkeletonKnight", quantity = 3 }, { type = "zone", name = "SealedChamberDoor", quantity = 1 } }, maxProgress = 4,
		rewards = { gold = 180, experience = 850, items = { { itemId = "HealthPotion", quantity = 2 } } },
	},
	TheBrokenOath = {
		id = "TheBrokenOath", name = "The Broken Oath", chapter = 1,
		questGiver = "Magister Toven Ashe", npcName = "Magister Toven Ashe", prerequisites = { "SealedChamber" }, isMainStory = true,
		description = "Return to Toven with the scratched royal crest. He can finally read the inscription.",
		lore = "The chamber was sealed by the first Vanguards — not against an invasion, but against their own king.", hints = "Speak with Toven at the ruins.",
		objective = "Question Magister Toven", objectiveType = "talk", targetNpc = "Magister Toven Ashe",
		targets = { { type = "npc", name = "Magister Toven Ashe", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 150, experience = 650, items = { { itemId = "ArcaneDust", quantity = 3 }, { itemId = "ScrollOfShielding", quantity = 1 } } },
	},
	WarbandsRefuge = {
		id = "WarbandsRefuge", name = "The Warband's Refuge", chapter = 1,
		questGiver = "Warden Edda", npcName = "Warden Edda", prerequisites = { "TheBrokenOath" }, isMainStory = true,
		description = "Clear the Orc warband entrenched on the upper slope.", lore = "The Orcs did not come to conquer Frosthorn. They came to hide.",
		hints = "Climb north from the ruins until you find their barricaded camp.", objective = "Defeat the Orc warband", objectiveType = "kill",
		targetEnemy = "Orc", targets = { { type = "enemy", name = "Orc", quantity = 12 } }, maxProgress = 12,
		rewards = { gold = 230, experience = 1100, items = { { itemId = "IronOre", quantity = 4 } } },
	},
	ForgeTheVanguard = {
		id = "ForgeTheVanguard", name = "Forge the Vanguard", chapter = 1,
		questGiver = "Blacksmith Doran", npcName = "Blacksmith Doran", prerequisites = { "WarbandsRefuge" }, isMainStory = true,
		description = "Use the ore taken from the warband to improve a piece of equipment at the forge.",
		lore = "Doran recognizes the warband's iron: it was once issued to Valdris' royal guard.", hints = "Upgrade equipment through the Crafting Master.",
		objective = "Upgrade one piece of gear", objectiveType = "upgrade",
		targets = { { type = "upgrade", name = "equipment", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 250, experience = 950, items = { { itemId = "PowerCrystal", quantity = 1 }, { itemId = "HardCandy", quantity = 1 } } },
	},
	SealTheVanguard = {
		id = "SealTheVanguard", name = "Seal of the Vanguard", chapter = 1,
		questGiver = "Blacksmith Doran", npcName = "Blacksmith Doran", prerequisites = { "ForgeTheVanguard" }, isMainStory = true,
		description = "Imprint an enhancement scroll on your equipment before climbing into Frosthorn's killing winds.",
		lore = "A surviving seal answers the old crest. The throne has been rewriting history for generations.", hints = "Use an Enhancement Scroll from the equipment merchant.",
		objective = "Enhance one piece of gear", objectiveType = "enhance",
		targets = { { type = "enhance", name = "equipment", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 300, experience = 1000, items = { { itemId = "InvincibilityStar", quantity = 1 }, { itemId = "MagicCookie", quantity = 1 } } },
	},
	WesternWatch = {
		id = "WesternWatch", name = "The Western Watch", chapter = 1,
		questGiver = "Warden Edda", npcName = "Warden Edda", prerequisites = { "WarbandsRefuge" }, isMainStory = false, repeatable = true,
		description = "Search the western Frosthorn watch for wolves driven from the high pass.",
		lore = "The abandoned watchfire has been stamped out from the inside.", hints = "Follow the western ridge from the Orc refuge.",
		objective = "Secure the western watch", objectiveType = "killreach",
		targets = { { type = "enemy", name = "DireWolf", quantity = 6 }, { type = "zone", name = "WesternWatch", quantity = 1 } }, maxProgress = 7,
		rewards = { gold = 180, experience = 650, items = { { itemId = "SpeedyBootsPotion", quantity = 2 }, { itemId = "BeastHide", quantity = 3 } } },
	},
	EasternWatch = {
		id = "EasternWatch", name = "The Eastern Watch", chapter = 1,
		questGiver = "Warden Edda", npcName = "Warden Edda", prerequisites = { "SealTheVanguard" }, isMainStory = false, repeatable = true,
		description = "Investigate the eastern cliffs and clear the wyverns circling the broken signal tower.",
		lore = "The tower's signal lens bears the same forbidden royal crest as the sealed chamber.", hints = "Follow the eastern ridge beyond Frostwood.",
		objective = "Secure the eastern watch", objectiveType = "killreach",
		targets = { { type = "enemy", name = "Wyvern", quantity = 3 }, { type = "zone", name = "EasternWatch", quantity = 1 } }, maxProgress = 4,
		rewards = { gold = 260, experience = 900, items = { { itemId = "ScrollOfWind", quantity = 1 }, { itemId = "CrystalShard", quantity = 2 } } },
	},
	WingsOverFrosthorn = {
		id = "WingsOverFrosthorn", name = "Wings over Frosthorn", chapter = 1,
		questGiver = "Warden Edda", npcName = "Warden Edda", prerequisites = { "SealTheVanguard" }, isMainStory = false, repeatable = true,
		description = "Hunt elite Wyverns and Griffins on the upper cliffs before facing the summit.", lore = "The sky itself has become territorial.",
		hints = "The cliff patrols are optional, but their equipment may save your life.", objective = "Defeat cliff elites", objectiveType = "kill",
		targets = { { type = "enemy", name = "Wyvern", quantity = 2 }, { type = "enemy", name = "Griffin", quantity = 2 } }, maxProgress = 4,
		rewards = { gold = 250, experience = 900, items = { { itemId = "HealthPotion", quantity = 2 } } },
	},
	FrostwingsDomain = {
		id = "FrostwingsDomain", name = "The Frostwing's Domain", chapter = 1,
		questGiver = "Warden Edda", npcName = "Warden Edda", prerequisites = { "SealTheVanguard" }, isMainStory = true,
		description = "Reach Frosthorn's summit and defeat Skorvath, the Frostwing.", lore = "At the peak waits the ancient force that has driven the mountain mad.",
		hints = "The summit lies beyond the upper cliffs. Return to Rhessa after the battle.", objective = "Defeat Skorvath", objectiveType = "kill",
		targetEnemy = "Skorvath", targets = { { type = "enemy", name = "Skorvath", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 500, experience = 2200, items = { { itemId = "StarFragment", quantity = 1 }, { itemId = "DragonTear", quantity = 1 }, { itemId = "HerosFeast", quantity = 1 } } },
	},
	ReturnToValdris = {
		id = "ReturnToValdris", name = "The Crown's Lie", chapter = 1,
		questGiver = "Commander Rhessa Kael", npcName = "Commander Rhessa Kael", prerequisites = { "FrostwingsDomain" }, isMainStory = true,
		description = "Return to Commander Rhessa in Valdris with the Frostwing's final memory.",
		lore = "Skorvath was a guardian, forced mad by a royal command etched into the mountain. Rhessa knew enough to fear the truth.", hints = "Return to the marketplace.",
		objective = "Confront Commander Rhessa", objectiveType = "talk", targetNpc = "Commander Rhessa Kael",
		targets = { { type = "npc", name = "Commander Rhessa Kael", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 750, experience = 3000, items = { { itemId = "RoyalSeal", quantity = 1 }, { itemId = "ElixirOfLife", quantity = 1 } } },
	},
}

QuestConfig.FutureChapters = {
	{ chapter = 2, name = "Chapter 2 — The Ashbound March", lockedReason = "The southeastern Waygate is sealed. Coming soon." },
	{ chapter = 3, name = "Chapter 3 — The Hollow King", lockedReason = "The southern Waygate is sealed. Coming soon." },
	{ chapter = 4, name = "Chapter 4 — The Shattered Crown", lockedReason = "The western Waygate is sealed. Coming soon." },
}

function QuestConfig.GetRequired(config)
	return config.maxProgress or 1
end

function QuestConfig.IsTarget(config, targetType, targetName)
	for _, target in ipairs(config.targets or {}) do
		if target.type == targetType and target.name == targetName then return true end
	end
	return false
end

return QuestConfig
