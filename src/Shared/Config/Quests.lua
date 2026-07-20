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
	N1MissingAtFirstLight = {
		id = "N1MissingAtFirstLight", name = "Missing at First Light", chapter = 1,
		questGiver = "Elder Mara", npcName = "Elder Mara", prerequisites = { "NorthernWaygate" }, isMainStory = true,
		description = "Protect Elder Mara's foothill village from the creatures fleeing Frosthorn.",
		lore = "A child saw the animals run before the mountain wind changed. The danger is moving downhill.",
		hints = "Defeat the Slimes around the foothill village, then return to Elder Mara.", objective = "Protect the foothill village", objectiveType = "kill",
		targets = { { type = "enemy", name = "Slime", quantity = 4 } }, maxProgress = 4,
		rewards = { gold = 50, experience = 220, items = { { itemId = "AppleJuice", quantity = 2 }, { itemId = "HealthPotion", quantity = 1 } } },
	},
	B1SlimeSupplyRoad = {
		id = "B1SlimeSupplyRoad", name = "Slime on the Supply Road", chapter = 1,
		questGiver = "Commander Rhessa Kael", npcName = "Commander Rhessa Kael", prerequisites = { "N1MissingAtFirstLight" }, isMainStory = true,
		description = "Clear the slimes blocking the northern supply road.", lore = "The slimes are gathering around the road instead of the wells, as if something uphill is pushing them down.", hints = "Search the supply road beyond the Northern Waygate.",
		objective = "Defeat supply-road Slimes", objectiveType = "kill", targets = { { type = "enemy", name = "Slime", quantity = 8 } }, maxProgress = 8,
		rewards = { gold = 60, experience = 250, items = { { itemId = "HealthPotion", quantity = 2 }, { itemId = "IronOre", quantity = 1 } } },
	},
	B2GoblinQuickfingers = {
		id = "B2GoblinQuickfingers", name = "Goblin Quickfingers", chapter = 1,
		questGiver = "Commander Rhessa Kael", npcName = "Commander Rhessa Kael", prerequisites = { "B1SlimeSupplyRoad" }, isMainStory = true,
		description = "Stop the goblin raiders that followed the slimes down from the mountain.", lore = "The raiders are stealing supplies, but their tracks point back toward Frosthorn.", hints = "Follow the broken wagons near the supply road.",
		objective = "Defeat goblin raiders", objectiveType = "kill", targets = { { type = "enemy", name = "Goblin", quantity = 8 } }, maxProgress = 8,
		rewards = { gold = 70, experience = 280, items = { { itemId = "AppleJuice", quantity = 2 }, { itemId = "GoblinCloth", quantity = 1 } } },
	},
	N2QuartermastersLedger = {
		id = "N2QuartermastersLedger", name = "The Quartermaster's Ledger", chapter = 1,
		questGiver = "Quartermaster Elian", npcName = "Quartermaster Elian", prerequisites = { "B2GoblinQuickfingers" }, isMainStory = true,
		description = "Recover the supply records lost in the abandoned camp.",
		lore = "The missing patrol numbers stop two days before the creatures began fleeing the mountain.",
		hints = "Collect Slime Gel from the abandoned supply camp and return to Quartermaster Elian.", objective = "Recover the supply records", objectiveType = "collect",
		targets = { { type = "item", name = "SlimeGel", quantity = 3 } }, maxProgress = 3,
		rewards = { gold = 65, experience = 260, items = { { itemId = "ManaPotion", quantity = 2 }, { itemId = "IronOre", quantity = 1 } } },
	},
	FoothillDisturbance = {
		id = "FoothillDisturbance", name = "Foothill Disturbance", chapter = 1,
		questGiver = "Commander Rhessa Kael", npcName = "Commander Rhessa Kael", prerequisites = { "N2QuartermastersLedger" }, isMainStory = true,
		description = "Drive back the Slimes and Goblin raiders gathering in the lower foothills.",
		lore = "Even the smallest creatures are moving uphill, as if fleeing something unseen.",
		hints = "Search the first camps beyond the Frosthorn Waygate.", objective = "Defeat foothill raiders", objectiveType = "kill",
		targets = { { type = "enemy", name = "Slime", quantity = 6 }, { type = "enemy", name = "Goblin", quantity = 6 } }, maxProgress = 12,
		rewards = { gold = 80, experience = 350, items = { { itemId = "HealthPotion", quantity = 2 } } },
	},
	FieldMedicRemedy = {
		id = "FieldMedicRemedy", name = "The Field Medic's Lesson", chapter = 1,
		questGiver = "Sister Amara", npcName = "Sister Amara", prerequisites = { "FoothillDisturbance" }, isMainStory = true,
		description = "Collect 5 Herbs, then craft 1 Health Potion for the wounded.",
		lore = "The green creatures' residue is mundane; the frost in their wounds is not.", hints = "Use the Crafting Master after collecting supplies.",
		objective = "Prepare a field remedy", objectiveType = "collectcraft",
		targets = { { type = "item", name = "Herb", quantity = 5 }, { type = "craft", name = "HealthPotion", quantity = 1 } }, maxProgress = 6,
		rewards = { gold = 75, experience = 300, items = { { itemId = "WarmSoup", quantity = 2 }, { itemId = "HealthPotion", quantity = 2 } } },
	},
	FleeingPeak = {
		id = "FleeingPeak", name = "Fleeing the Peak", chapter = 1,
		questGiver = "Scout Iven", npcName = "Scout Iven", prerequisites = { "FieldMedicRemedy" }, isMainStory = true,
		description = "Defeat 7 Spiders in the east/west forest clearings and 7 Dire Wolves in the north deep forest.",
		hints = "Spiders spawn in the east and west forest clearings. Dire Wolves spawn in the north deep forest. Defeat 7 of each.",
		lore = "The forest’s predators are not hunting. They are running.", hints = "Continue north into the snow-dusted pines.",
		objective = "Defeat creatures fleeing Frostwood", objectiveType = "kill",
		targets = { { type = "enemy", name = "Spider", quantity = 7 }, { type = "enemy", name = "DireWolf", quantity = 7 } }, maxProgress = 14,
		rewards = { gold = 120, experience = 550, items = { { itemId = "ManaPotion", quantity = 2 } } },
	},
	B3WebsAcrossRoad = {
		id = "B3WebsAcrossRoad", name = "Webs Across the Road", chapter = 1,
		questGiver = "Scout Iven", npcName = "Scout Iven", prerequisites = { "FleeingPeak" }, isMainStory = true,
		description = "Clear the spider nests spreading across the Frostwood patrol route.", lore = "The spiders are building webs toward the summit, not toward the road.", hints = "Search Frostwood after following the fleeing creatures uphill.",
		objective = "Defeat Frostwood Spiders", objectiveType = "kill", targets = { { type = "enemy", name = "Spider", quantity = 10 } }, maxProgress = 10,
		rewards = { gold = 110, experience = 500, items = { { itemId = "AntidoteHerb", quantity = 2 }, { itemId = "WardingCharm", quantity = 1 } } },
	},
	B4RunningPack = {
		id = "B4RunningPack", name = "The Running Pack", chapter = 1,
		questGiver = "Scout Iven", npcName = "Scout Iven", prerequisites = { "B3WebsAcrossRoad" }, isMainStory = true,
		description = "Drive the Dire Wolves away from the road and follow their tracks uphill.", lore = "Even the pack alpha refuses to face whatever waits above Frostwood.", hints = "Watch where the wolves retreat after the battle.",
		objective = "Defeat the fleeing Dire Wolves", objectiveType = "kill", targets = { { type = "enemy", name = "DireWolf", quantity = 6 } }, maxProgress = 6,
		rewards = { gold = 130, experience = 580, items = { { itemId = "WolfFang", quantity = 2 }, { itemId = "SpeedyBootsPotion", quantity = 1 } } },
	},
	N4AntidoteForPatrol = {
		id = "N4AntidoteForPatrol", name = "Antidote for the Patrol", chapter = 1,
		questGiver = "Healer Lysa", npcName = "Healer Lysa", prerequisites = { "B4RunningPack" }, isMainStory = true,
		description = "Gather herbs to help the patrol recover from the Frostwood spiders.",
		lore = "The poison is unusually strong. Something near the summit is changing the creatures below it.",
		hints = "Collect Antidote Herbs from the Frostwood area and return to Healer Lysa.", objective = "Prepare patrol antidotes", objectiveType = "collect",
		targets = { { type = "item", name = "AntidoteHerb", quantity = 3 } }, maxProgress = 3,
		rewards = { gold = 100, experience = 500, items = { { itemId = "AntidoteHerb", quantity = 3 }, { itemId = "HealthPotion", quantity = 1 } } },
	},
	N5HuntersLastTrail = {
		id = "N5HuntersLastTrail", name = "The Hunter's Last Trail", chapter = 1,
		questGiver = "Hunter Corren", npcName = "Hunter Corren", prerequisites = { "N4AntidoteForPatrol" }, isMainStory = true,
		description = "Follow the displaced wolf pack and secure the Frostwood watchpost.",
		lore = "The wolves are not hunting. Their tracks point uphill, away from the thing that frightened them.",
		hints = "Defeat the Dire Wolves along the watchpost trail and return to Hunter Corren.", objective = "Follow the hunter's trail", objectiveType = "kill",
		targets = { { type = "enemy", name = "DireWolf", quantity = 4 } }, maxProgress = 4,
		rewards = { gold = 120, experience = 560, items = { { itemId = "WolfFang", quantity = 2 }, { itemId = "SpeedyBootsPotion", quantity = 1 } } },
	},
	WebsOfWarning = {
		id = "WebsOfWarning", name = "Webs of Warning", chapter = 1,
		questGiver = "Scout Iven", npcName = "Scout Iven", prerequisites = { "N5HuntersLastTrail" }, isMainStory = true,
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
	N3GoblinHonestWork = {
		id = "N3GoblinHonestWork", name = "A Goblin's Honest Work", chapter = 1,
		questGiver = "Nib Quickfinger", npcName = "Nib Quickfinger", prerequisites = { "WebsOfWarning" }, isMainStory = true,
		description = "Recover the goblin supply crates hidden in Frostwood.",
		lore = "Nib wants to repair one small wrong before the mountain turns every survivor into an enemy.",
		hints = "Collect Goblin Cloth from the Frostwood raiders and bring it back to Nib.", objective = "Recover the missing crates", objectiveType = "collect",
		targets = { { type = "item", name = "GoblinCloth", quantity = 3 } }, maxProgress = 3,
		rewards = { gold = 140, experience = 600, items = { { itemId = "SpeedyBootsPotion", quantity = 1 }, { itemId = "GoblinCloth", quantity = 2 } } },
	},
	N6PagesBeneathSnow = {
		id = "N6PagesBeneathSnow", name = "Pages Beneath the Snow", chapter = 1,
		questGiver = "Magister Toven Ashe", npcName = "Magister Toven Ashe", prerequisites = { "ScholarInRuins" }, isMainStory = true,
		description = "Recover the arcane dust scattered beneath the ancient ruins.",
		lore = "Toven's notes mention a royal expedition whose leader was erased from every surviving page.",
		hints = "Collect Arcane Dust in the ruins and return to Magister Toven Ashe.", objective = "Recover Toven's lost pages", objectiveType = "collect",
		targets = { { type = "item", name = "ArcaneDust", quantity = 3 } }, maxProgress = 3,
		rewards = { gold = 130, experience = 620, items = { { itemId = "ArcaneDust", quantity = 2 }, { itemId = "ScrollOfShielding", quantity = 1 } } },
	},
	B5BonesAncientSnow = {
		id = "B5BonesAncientSnow", name = "Bones in Ancient Snow", chapter = 1,
		questGiver = "Magister Toven Ashe", npcName = "Magister Toven Ashe", prerequisites = { "EchoesBelow" }, isMainStory = true,
		description = "Defeat the Skeletons wandering out from the ancient ruins.",
		lore = "The ruin guardians are leaving the sealed door, as if something deeper has called them away.",
		hints = "Protect Toven's excavation in the ancient ruin courtyard.", objective = "Defeat wandering Skeletons", objectiveType = "kill",
		targets = { { type = "enemy", name = "Skeleton", quantity = 12 } }, maxProgress = 12,
		rewards = { gold = 140, experience = 650, items = { { itemId = "ArcaneDust", quantity = 2 }, { itemId = "IronOre", quantity = 2 } } },
	},
	B6KnightsSealedDoor = {
		id = "B6KnightsSealedDoor", name = "Knights of the Sealed Door", chapter = 1,
		questGiver = "Magister Toven Ashe", npcName = "Magister Toven Ashe", prerequisites = { "B5BonesAncientSnow" }, isMainStory = true,
		description = "Defeat the armored guardians protecting the sealed chamber.",
		lore = "Their shields carry a royal symbol that should not exist in these ruins.",
		hints = "The Skeleton Knights stand closest to the Sealed Chamber Door.", objective = "Defeat the Skeleton Knights", objectiveType = "kill",
		targets = { { type = "enemy", name = "SkeletonKnight", quantity = 3 } }, maxProgress = 3,
		rewards = { gold = 170, experience = 800, items = { { itemId = "ScrollOfShielding", quantity = 1 }, { itemId = "IronOre", quantity = 2 } } },
	},
	N7BrokenVanguardBlade = {
		id = "N7BrokenVanguardBlade", name = "The Broken Vanguard Blade", chapter = 1,
		questGiver = "Smith Hadrik", npcName = "Smith Hadrik", prerequisites = { "B6KnightsSealedDoor" }, isMainStory = true,
		description = "Recover old iron from the Skeleton Knights so Smith Hadrik can protect the living.",
		lore = "The metal remembers a battle that the royal records chose to forget.",
		hints = "Collect Iron Ore from the ancient ruins and return to Smith Hadrik.", objective = "Recover Vanguard steel", objectiveType = "collect",
		targets = { { type = "item", name = "IronOre", quantity = 3 } }, maxProgress = 3,
		rewards = { gold = 180, experience = 820, items = { { itemId = "PowerCrystal", quantity = 1 }, { itemId = "IronOre", quantity = 2 } } },
	},
	EchoesBelow = {
		id = "EchoesBelow", name = "Echoes Below", chapter = 1,
		questGiver = "Magister Toven Ashe", npcName = "Magister Toven Ashe", prerequisites = { "N6PagesBeneathSnow" }, isMainStory = true,
		description = "Clear the Skeleton guardians circling the sealed inner chamber.", lore = "Silent guardians protect a door no living scholar can open.",
		hints = "Search the ruin courtyard and its collapsed halls.", objective = "Defeat Skeleton guardians", objectiveType = "kill",
		targetEnemy = "Skeleton", targets = { { type = "enemy", name = "Skeleton", quantity = 10 } }, maxProgress = 10,
		rewards = { gold = 150, experience = 700, items = { { itemId = "IronOre", quantity = 3 } } },
	},
	SealedChamber = {
		id = "SealedChamber", name = "The Sealed Chamber", chapter = 1,
		questGiver = "Magister Toven Ashe", npcName = "Magister Toven Ashe", prerequisites = { "N7BrokenVanguardBlade" }, isMainStory = true,
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
	B7AshenSpear = {
		id = "B7AshenSpear", name = "The Ashen Spear", chapter = 1,
		questGiver = "Commander Rhessa Kael", npcName = "Commander Rhessa Kael", prerequisites = { "TheBrokenOath" }, isMainStory = true,
		description = "Clear the Ashen Spear warband's barricade and open the upper-slope road.",
		lore = "The Orc warband is hiding from the same summit danger as the creatures of Frosthorn.",
		hints = "Climb to the upper-slope camp beyond the ancient ruins.", objective = "Defeat the Ashen Spear warband", objectiveType = "kill",
		targets = { { type = "enemy", name = "Orc", quantity = 8 } }, maxProgress = 8,
		rewards = { gold = 210, experience = 1000, items = { { itemId = "IronOre", quantity = 3 }, { itemId = "BearClaw", quantity = 1 } } },
	},
	N8OrcsDebt = {
		id = "N8OrcsDebt", name = "An Orc's Debt", chapter = 1,
		questGiver = "Scout Varok", npcName = "Scout Varok", prerequisites = { "B7AshenSpear" }, isMainStory = true,
		description = "Help the Ashen Spear scouts trapped below their camp.",
		lore = "The warband offers a warning instead of a threat: the Frostwing is not the oldest thing beneath the mountain.",
		hints = "Defeat the Orc scouts' pursuers and return to Scout Varok.", objective = "Help the Ashen Spear scouts", objectiveType = "kill",
		targets = { { type = "enemy", name = "Orc", quantity = 4 } }, maxProgress = 4,
		rewards = { gold = 220, experience = 1050, items = { { itemId = "BearClaw", quantity = 2 }, { itemId = "HealthPotion", quantity = 2 } } },
	},
	WarbandsRefuge = {
		id = "WarbandsRefuge", name = "The Warband's Refuge", chapter = 1,
		questGiver = "Warden Edda", npcName = "Warden Edda", prerequisites = { "N8OrcsDebt" }, isMainStory = true,
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
		description = "Imprint an enhancement scroll on your equipment before climbing into Frosthorn's bitter winds.",
		lore = "A surviving seal answers the old crest. The throne has been rewriting history for generations.", hints = "Use an Enhancement Scroll from the equipment merchant.",
		objective = "Enhance one piece of gear", objectiveType = "enhance",
		targets = { { type = "enhance", name = "equipment", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 300, experience = 1000, items = { { itemId = "InvincibilityStar", quantity = 1 }, { itemId = "MagicCookie", quantity = 1 } } },
	},
	N9FeathersForSignal = {
		id = "N9FeathersForSignal", name = "Feathers for the Signal", chapter = 1,
		questGiver = "Scout Iven", npcName = "Scout Iven", prerequisites = { "SealTheVanguard" }, isMainStory = true,
		description = "Collect Wyvern scales for a signal that can warn Valdris about the summit.",
		lore = "The warning must reach the valley before the summit storm closes the road.",
		hints = "Collect Drake Scales from the upper cliffs and return to Scout Iven.", objective = "Prepare the cliff signal", objectiveType = "collect",
		targets = { { type = "item", name = "DrakeScale", quantity = 3 } }, maxProgress = 3,
		rewards = { gold = 260, experience = 1000, items = { { itemId = "CrystalShard", quantity = 2 }, { itemId = "SpeedyBootsPotion", quantity = 1 } } },
	},
	N10MealAboveClouds = {
		id = "N10MealAboveClouds", name = "A Meal Above the Clouds", chapter = 1,
		questGiver = "Cook Branna", npcName = "Cook Branna", prerequisites = { "N9FeathersForSignal" }, isMainStory = true,
		description = "Gather herbs and prepare a warm meal for the summit party.",
		lore = "A warm meal cannot stop the mountain, but it can give a frightened team the courage to continue.",
		hints = "Collect Herbs from the upper-cliff camp and return to Cook Branna.", objective = "Prepare the summit meal", objectiveType = "collect", targetItem = "Herb",
		targets = { { type = "item", name = "Herb", quantity = 5 } }, maxProgress = 5,
		rewards = { gold = 280, experience = 1050, items = { { itemId = "WarmSoup", quantity = 3 }, { itemId = "GoldenApple", quantity = 1 } } },
	},
	B8TalonsFrosthorn = {
		id = "B8TalonsFrosthorn", name = "Talons Over Frosthorn", chapter = 1,
		questGiver = "Warden Edda", npcName = "Warden Edda", prerequisites = { "N10MealAboveClouds" }, isMainStory = true,
		description = "Defeat the hostile Wyverns attacking the upper cliffs.",
		lore = "The flying creatures arrived only after the summit disturbance began.",
		hints = "Search the eastern upper cliffs beyond the watch posts.", objective = "Defeat hostile Wyverns", objectiveType = "kill",
		targets = { { type = "enemy", name = "Wyvern", quantity = 5 } }, maxProgress = 5,
		rewards = { gold = 280, experience = 1050, items = { { itemId = "DrakeScale", quantity = 1 }, { itemId = "CrystalShard", quantity = 2 } } },
	},
	B9HighNest = {
		id = "B9HighNest", name = "The High Nest", chapter = 1,
		questGiver = "Warden Edda", npcName = "Warden Edda", prerequisites = { "B8TalonsFrosthorn" }, isMainStory = true,
		description = "Clear the Griffin nest and recover the old Vanguard supply crate.",
		lore = "The crate was placed on Frosthorn before the crater impact and the royal records disappeared.",
		hints = "Search the western upper cliffs after securing the wyvern route.", objective = "Defeat the high-nest Griffins", objectiveType = "kill",
		targets = { { type = "enemy", name = "Griffin", quantity = 4 } }, maxProgress = 4,
		rewards = { gold = 300, experience = 1150, items = { { itemId = "PhoenixFeather", quantity = 1 }, { itemId = "GoldenApple", quantity = 1 } } },
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
		questGiver = "Warden Edda", npcName = "Warden Edda", prerequisites = { "B9HighNest" }, isMainStory = true,
		description = "Reach Frosthorn's summit and defeat Skorvath, the Frostwing.", lore = "At the peak waits the ancient force that has driven the mountain mad.",
		hints = "The summit lies beyond the upper cliffs. Return to Rhessa after the battle.", objective = "Defeat Skorvath", objectiveType = "kill",
		targetEnemy = "Skorvath", targets = { { type = "enemy", name = "Skorvath", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 500, experience = 2200, items = { { itemId = "StarFragment", quantity = 1 }, { itemId = "DragonTear", quantity = 1 }, { itemId = "HerosFeast", quantity = 1 } } },
	},
	N11OldSoldiersQuestion = {
		id = "N11OldSoldiersQuestion", name = "The Old Soldier's Question", chapter = 1,
		questGiver = "Veteran Dain", npcName = "Veteran Dain", prerequisites = { "FrostwingsDomain" }, isMainStory = true,
		description = "Stand at the northern Waygate and listen to the veteran's account of the lost expedition.",
		lore = "The old Vanguard was sent toward the crater twenty-seven years ago, then erased from the reports.",
		hints = "Visit the Frosthorn Waygate and return to Veteran Dain.", objective = "Find the old Vanguard memorial", objectiveType = "reach", targetZone = "FrosthornWaygate",
		targets = { { type = "zone", name = "FrosthornWaygate", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 320, experience = 1300, items = { { itemId = "StarFragment", quantity = 1 } } },
	},
	N12LightForFallen = {
		id = "N12LightForFallen", name = "A Light for the Fallen", chapter = 1,
		questGiver = "Priestess Selene", npcName = "Priestess Selene", prerequisites = { "N11OldSoldiersQuestion" }, isMainStory = true,
		description = "Light the memorial at Frosthorn and honor the Vanguard who never returned.",
		lore = "A remembered name is a small light against a kingdom's silence.",
		hints = "Reach the Frosthorn Memorial Shrine, then return to Priestess Selene.", objective = "Light the memorial shrine", objectiveType = "reach", targetZone = "FrosthornMemorial",
		targets = { { type = "zone", name = "FrosthornMemorial", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 360, experience = 1500, items = { { itemId = "ElixirOfLife", quantity = 1 }, { itemId = "WardingCharm", quantity = 1 } } },
	},
	ReturnToValdris = {
		id = "ReturnToValdris", name = "The Crown's Lie", chapter = 1,
		questGiver = "Commander Rhessa Kael", npcName = "Commander Rhessa Kael", prerequisites = { "N12LightForFallen" }, isMainStory = true,
		description = "Return to Commander Rhessa in Valdris with the Frostwing's final memory.",
		lore = "Skorvath was a guardian, driven out of balance by a royal command etched into the mountain. Rhessa knew enough to fear the truth.", hints = "Return to the marketplace.",
		objective = "Confront Commander Rhessa", objectiveType = "talk", targetNpc = "Commander Rhessa Kael",
		targets = { { type = "npc", name = "Commander Rhessa Kael", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 750, experience = 3000, items = { { itemId = "RoyalSeal", quantity = 1 }, { itemId = "ElixirOfLife", quantity = 1 } } },
	},
	CinderscarWarden = {
		id = "CinderscarWarden", name = "The Cinderwyrm Warden", chapter = 1,
		questGiver = "Commander Rhessa Kael", npcName = "Commander Rhessa Kael",
		prerequisites = { "ReturnToValdris" }, isMainStory = false,
		firstInteractionSceneId = "CinderscarIntro", repeatable = false,
		description = "Travel to the optional Cinderscar Crater and defeat Vaelithra, the Cinderwyrm Warden.",
		lore = "Beneath the crater, an ancient guardian protects a seal connected to the Crown's missing history.",
		hints = "The crater lies beyond the eastern ridge. Prepare before entering the red-lit arena.",
		objective = "Defeat Vaelithra", objectiveType = "kill", targetEnemy = "Vaelithra",
		targets = { { type = "enemy", name = "Vaelithra", quantity = 1 } }, maxProgress = 1,
		rewards = { gold = 600, experience = 1800, items = { { itemId = "RoyalSeal", quantity = 1 }, { itemId = "DragonTear", quantity = 1 } } },
	},
}

-- Comic offer dialogue for every Chapter 1 quest. The first meeting with the
-- six core NPCs uses the longer scenes in QuestService; these lines are used
-- for the quest-specific conversations that follow and keep the full chain
-- aligned with the written storyline instead of using a generic prompt.
local chapterOneDialogue = {
	VanguardAtDawn = {
		{ speaker = "Commander Rhessa Kael", text = "Valdris needs steady hands, recruit. Frosthorn's creatures are climbing toward its summit." },
		{ speaker = "Commander Rhessa Kael", text = "Take the northern road, reopen the Waygate, and report every sign of what drove them there." },
	},
	VillageSupplyLine = {
		{ speaker = "Sister Amara", text = "The refugees brought more than fear. Their wounds carry a strange mountain chill." },
		{ speaker = "Sister Amara", text = "Listen to their story, recruit. If we understand what drove the creatures uphill, we can protect Valdris." },
	},
	NorthernWaygate = {
		{ speaker = "Scout Iven", text = "The northern Waygate has gone quiet. Without it, supplies cannot reach the foothills." },
		{ speaker = "Scout Iven", text = "Reach the gate and wake its old crystal. Then we will know whether the road is safe." },
	},
	N1MissingAtFirstLight = {
		{ speaker = "Elder Mara", text = "Vanguard, the foothill village is frightened. The creatures came down from Frosthorn before sunrise." },
		{ speaker = "Elder Mara", text = "Protect the village while we search for the missing children. Every safe villager is a victory today." },
		{ speaker = "Vanguard Recruit", side = "right", text = "I will protect them and find out why the creatures are running." },
	},
	B1SlimeSupplyRoad = {
		{ speaker = "Commander Rhessa Kael", text = "The supply road is covered in Slimes. They are blocking food and medicine from reaching the foothills." },
		{ speaker = "Commander Rhessa Kael", text = "Clear the road, then look at where the Slimes came from. Their trail may point to the real danger." },
	},
	B2GoblinQuickfingers = {
		{ speaker = "Commander Rhessa Kael", text = "The Goblins followed the Slimes down and are taking supplies from the camp." },
		{ speaker = "Commander Rhessa Kael", text = "Stop the raid without frightening the refugees. Their tracks lead back toward Frosthorn." },
	},
	N2QuartermastersLedger = {
		{ speaker = "Quartermaster Elian", text = "You cleared the camp, but its supply ledger is still missing." },
		{ speaker = "Quartermaster Elian", text = "Recover the records. The patrol numbers may tell us when the mountain trouble began." },
	},
	FoothillDisturbance = {
		{ speaker = "Commander Rhessa Kael", text = "The foothills are still restless. Slimes and Goblins are gathering where the road should be safe." },
		{ speaker = "Commander Rhessa Kael", text = "Drive them back, but watch their movement. Even the smallest creatures seem to be fleeing uphill." },
	},
	FieldMedicRemedy = {
		{ speaker = "Sister Amara", text = "The wounded need a field remedy before we follow the creatures into Frostwood." },
		{ speaker = "Sister Amara", text = "Collect 5 Herbs, then craft 1 Health Potion. Helping people is part of being a Vanguard." },
	},
	FleeingPeak = {
		{ speaker = "Scout Iven", text = "Frostwood's Spiders and Dire Wolves are not hunting. They are running from something above." },
		{ speaker = "Scout Iven", text = "Defeat 7 Spiders in the east and west clearings, then 7 Dire Wolves in the north deep forest. If they are afraid, we need to know what frightened them." },
	},
	B3WebsAcrossRoad = {
		{ speaker = "Scout Iven", text = "The Spider webs are spreading across the patrol route and closing the safe path." },
		{ speaker = "Scout Iven", text = "Clear the webs and watch for poison. The strands all point toward the summit." },
	},
	B4RunningPack = {
		{ speaker = "Scout Iven", text = "The Dire Wolves are running in a pack, but their tracks never turn toward Valdris." },
		{ speaker = "Scout Iven", text = "Drive them away from the road and follow the retreating pack. Their fear may be our first warning." },
	},
	N4AntidoteForPatrol = {
		{ speaker = "Healer Lysa", text = "The Spider venom is slowing the patrol's breathing." },
		{ speaker = "Healer Lysa", text = "Gather Antidote Herbs before the next wave reaches this tent. The poison is stronger than it should be." },
	},
	N5HuntersLastTrail = {
		{ speaker = "Hunter Corren", text = "My hunting partner disappeared while tracking the wolves." },
		{ speaker = "Hunter Corren", text = "Secure the trail and bring me proof that the wolves are fleeing, not hunting. The summit holds the answer." },
	},
	WebsOfWarning = {
		{ speaker = "Scout Iven", text = "These webs were not made to catch prey. They form a warning line around the forest." },
		{ speaker = "Scout Iven", text = "Collect Spider Silk for the patrol map. Every strand points away from the summit." },
	},
	N3GoblinHonestWork = {
		{ speaker = "Nib Quickfinger", text = "I have a business opportunity for a brave and trusting person." },
		{ speaker = "Nib Quickfinger", text = "My people left supply crates in Frostwood. Help me return them, and I will prove Goblins can keep an honest promise." },
	},
	ScholarInRuins = {
		{ speaker = "Magister Toven Ashe", text = "These stones are older than Valdris. Their guardians are protecting a memory, not treasure." },
		{ speaker = "Magister Toven Ashe", text = "Help me study the ruins. The sealed chamber may tell us why Frosthorn is afraid." },
	},
	N6PagesBeneathSnow = {
		{ speaker = "Magister Toven Ashe", text = "Three pages from my field journal vanished beneath the ruins." },
		{ speaker = "Magister Toven Ashe", text = "Recover the arcane dust around them. My notes mention a royal expedition that someone erased." },
	},
	EchoesBelow = {
		{ speaker = "Magister Toven Ashe", text = "The echoes below the ruins have changed. The Skeleton guardians are leaving their old posts." },
		{ speaker = "Magister Toven Ashe", text = "Clear the courtyard and listen for what the sealed chamber is trying to remember." },
	},
	B5BonesAncientSnow = {
		{ speaker = "Magister Toven Ashe", text = "Skeletons are wandering out from the ancient ruins and away from the sealed door." },
		{ speaker = "Magister Toven Ashe", text = "Defeat them before the excavation is lost. Something deeper is calling the guardians away." },
	},
	B6KnightsSealedDoor = {
		{ speaker = "Magister Toven Ashe", text = "The Skeleton Knights still guard the sealed chamber." },
		{ speaker = "Magister Toven Ashe", text = "Their shields carry a royal mark that should not exist here. Keep them away from the excavation." },
	},
	N7BrokenVanguardBlade = {
		{ speaker = "Smith Hadrik", text = "The Skeleton Knights carry old Vanguard steel in their hands." },
		{ speaker = "Smith Hadrik", text = "Bring me the iron they leave behind. I can turn a forgotten weapon into protection for the living." },
	},
	SealedChamber = {
		{ speaker = "Magister Toven Ashe", text = "The chamber door is close now, but its guardians will not let us approach safely." },
		{ speaker = "Magister Toven Ashe", text = "Defeat the Knights and inspect the seal. We may not open it today, but we can learn who closed it." },
	},
	TheBrokenOath = {
		{ speaker = "Magister Toven Ashe", text = "The scratched crest is a royal Vanguard mark. The chamber was sealed by the first expedition." },
		{ speaker = "Magister Toven Ashe", text = "Return to me with your questions. The kingdom has hidden this oath for twenty-seven years." },
	},
	B7AshenSpear = {
		{ speaker = "Commander Rhessa Kael", text = "The Ashen Spear warband has blocked the upper-slope road." },
		{ speaker = "Commander Rhessa Kael", text = "Clear the barricade, but remember: their campfires face the mountain. They may be hiding from the same danger as us." },
	},
	N8OrcsDebt = {
		{ speaker = "Scout Varok", text = "You reached our camp without cruelty. The Ashen Spear owes you a debt." },
		{ speaker = "Scout Varok", text = "Help our trapped scouts, and I will tell you what the Frostwing refused to say: something older waits below." },
	},
	WarbandsRefuge = {
		{ speaker = "Warden Edda", text = "The Orcs have barricaded the upper slope, but their campfires point inward, not toward Valdris." },
		{ speaker = "Warden Edda", text = "Clear a path to their refuge. We may need answers more than trophies." },
	},
	ForgeTheVanguard = {
		{ speaker = "Blacksmith Doran", text = "This ore came from a warband carrying Valdris steel." },
		{ speaker = "Blacksmith Doran", text = "Upgrade your equipment at the forge. A Vanguard cannot face Frosthorn with a rusty blade." },
	},
	SealTheVanguard = {
		{ speaker = "Blacksmith Doran", text = "The old seal answers your equipment, as if it remembers the Vanguard." },
		{ speaker = "Blacksmith Doran", text = "Enhance one piece of gear before you climb into Frosthorn's bitter winds." },
	},
	N9FeathersForSignal = {
		{ speaker = "Scout Iven", text = "The signal hawks will not fly while Wyverns circle the upper cliffs." },
		{ speaker = "Scout Iven", text = "Bring me Drake Scales for a signal arrow. Valdris must know the summit road is in danger." },
	},
	N10MealAboveClouds = {
		{ speaker = "Cook Branna", text = "Soldiers fight better when they eat better." },
		{ speaker = "Cook Branna", text = "Gather Frosthorn Herbs. A warm meal cannot stop the mountain, but it can give the party courage." },
	},
	B8TalonsFrosthorn = {
		{ speaker = "Warden Edda", text = "The Wyverns have claimed the upper cliffs since the summit disturbance began." },
		{ speaker = "Warden Edda", text = "Defeat the hostile fliers and open the road. The summit is close, but the sky will not be kind." },
	},
	B9HighNest = {
		{ speaker = "Warden Edda", text = "A Griffin nest blocks the last safe route to the summit." },
		{ speaker = "Warden Edda", text = "Clear the nest and recover the old Vanguard supply crate. It may contain the final clue." },
	},
	FrostwingsDomain = {
		{ speaker = "Warden Edda", text = "The summit is ahead. Skorvath, the Frostwing, waits where the mountain wind turns white." },
		{ speaker = "Warden Edda", text = "Defeat the guardian and survive the Frost Nova. The truth of Frosthorn is waiting above us." },
	},
	N11OldSoldiersQuestion = {
		{ speaker = "Veteran Dain", text = "I saw the old Vanguard mark you carried down from the summit." },
		{ speaker = "Veteran Dain", text = "Stand with me at the Waygate memorial. Then I will tell you what the commanders refused to say." },
	},
	N12LightForFallen = {
		{ speaker = "Priestess Selene", text = "The mountain has taken many names from the kingdom." },
		{ speaker = "Priestess Selene", text = "Light the Frosthorn memorial. The fallen deserve to be remembered before you return to Valdris." },
	},
	ReturnToValdris = {
		{ speaker = "Commander Rhessa Kael", text = "You survived Frosthorn, but Skorvath's memory is heavier than any trophy." },
		{ speaker = "Commander Rhessa Kael", text = "Return to Valdris. We must decide how much of the Crown's lie the kingdom is ready to hear." },
	},
	CinderscarWarden = {
		{ speaker = "Commander Rhessa Kael", text = "The Crown's secret did not end on Frosthorn. The eastern crater is waking." },
		{ speaker = "Commander Rhessa Kael", text = "The crater is optional, recruit. Go only when you are ready, and return safely." },
	},
}

for questId, dialogue in pairs(chapterOneDialogue) do
	if QuestConfig[questId] then
		QuestConfig[questId].dialogue = dialogue
	end
end

local chapterOneCompletionDialogue = {
	VanguardAtDawn = {
		{ speaker = "Commander Rhessa Kael", text = "The northern road has a new Vanguard on it. You have earned your first report." },
		{ speaker = "Commander Rhessa Kael", text = "Now help the people waiting beyond the market." },
	},
	VillageSupplyLine = {
		{ speaker = "Sister Amara", text = "The refugees have been heard, and their supplies can move again." },
		{ speaker = "Sister Amara", text = "Take this kindness with you. The road ahead will need it." },
	},
	NorthernWaygate = {
		{ speaker = "Scout Iven", text = "The Waygate is awake. Frosthorn's road is open for the first time in days." },
		{ speaker = "Scout Iven", text = "The foothill camp is next. Someone must protect its supplies." },
	},
	N1MissingAtFirstLight = {
		{ speaker = "Elder Mara", text = "The village is safe for now. The children can see another sunrise." },
		{ speaker = "Elder Mara", text = "One of them saw white fire over the peak. Please carry that warning with you." },
	},
	B1SlimeSupplyRoad = {
		{ speaker = "Commander Rhessa Kael", text = "Eight Slimes and one ruined camp. I will call that a victory for today." },
		{ speaker = "Commander Rhessa Kael", text = "The trail says the Goblins came from the north. Keep moving." },
	},
	B2GoblinQuickfingers = {
		{ speaker = "Nib Quickfinger", text = "My pack! My beautiful, slightly damaged pack!" },
		{ speaker = "Nib Quickfinger", text = "White fire came from the summit. It chased every Goblin, wolf, and bird downhill." },
	},
	N2QuartermastersLedger = {
		{ speaker = "Quartermaster Elian", text = "The numbers are damaged, but the warning is clear: the patrol stopped reporting first." },
		{ speaker = "Quartermaster Elian", text = "That is not a supply problem. That is a mountain warning." },
	},
	FoothillDisturbance = {
		{ speaker = "Commander Rhessa Kael", text = "The foothill camps can breathe again." },
		{ speaker = "Commander Rhessa Kael", text = "The creatures are not invading. They are escaping something above us." },
	},
	FieldMedicRemedy = {
		{ speaker = "Sister Amara", text = "The remedy is ready, and the patrol can continue safely." },
		{ speaker = "Sister Amara", text = "The frost in the wounds is not ordinary. Be careful in Frostwood." },
	},
	FleeingPeak = {
		{ speaker = "Scout Iven", text = "The tracks all turn uphill. Even predators are fleeing the peak." },
		{ speaker = "Scout Iven", text = "The ancient ruins are ahead. Someone there may know why." },
	},
	B3WebsAcrossRoad = {
		{ speaker = "Scout Iven", text = "The patrol route is open, and the poison will not reach the next camp." },
		{ speaker = "Scout Iven", text = "The Spiders were fleeing inward. The summit is changing the whole forest." },
	},
	B4RunningPack = {
		{ speaker = "Scout Iven", text = "The pack retreated uphill. Even its alpha refuses to face what waits above." },
		{ speaker = "Scout Iven", text = "We follow the tracks, but we keep formation." },
	},
	N4AntidoteForPatrol = {
		{ speaker = "Healer Lysa", text = "These Antidote Herbs will keep the patrol breathing through the night." },
		{ speaker = "Healer Lysa", text = "The poison is stronger than before. Whatever drives the Spiders is changing them." },
	},
	N5HuntersLastTrail = {
		{ speaker = "Hunter Corren", text = "The trail proves the wolves were running, not hunting." },
		{ speaker = "Hunter Corren", text = "Their fear began near the summit. Do not underestimate what frightened them." },
	},
	WebsOfWarning = {
		{ speaker = "Scout Iven", text = "The silk confirms it. The webs point away from Frosthorn." },
		{ speaker = "Scout Iven", text = "Toven is waiting at the ruins. Take him everything we have learned." },
	},
	N3GoblinHonestWork = {
		{ speaker = "Nib Quickfinger", text = "You saved my reputation and possibly my knees." },
		{ speaker = "Nib Quickfinger", text = "Take this compass. It points toward valuable things—and usually toward danger." },
	},
	ScholarInRuins = {
		{ speaker = "Magister Toven Ashe", text = "You found me before the ruins claimed another traveler." },
		{ speaker = "Magister Toven Ashe", text = "Now we can study the guardians and the memory behind the sealed door." },
	},
	N6PagesBeneathSnow = {
		{ speaker = "Magister Toven Ashe", text = "Page one: binding symbols. Page two: a missing royal expedition." },
		{ speaker = "Magister Toven Ashe", text = "Page three has the leader's name scratched away. That is the question we must ask quietly." },
	},
	EchoesBelow = {
		{ speaker = "Magister Toven Ashe", text = "The lower halls are quiet again, but the seal is not sleeping." },
		{ speaker = "Magister Toven Ashe", text = "The Skeletons were guarding a secret, not treasure. We are close to its door." },
	},
	B5BonesAncientSnow = {
		{ speaker = "Magister Toven Ashe", text = "You protected the excavation. The cracked rune proves this ruin predates Valdris." },
		{ speaker = "Magister Toven Ashe", text = "Something was sealed here long before the current kingdom was born." },
	},
	B6KnightsSealedDoor = {
		{ speaker = "Magister Toven Ashe", text = "The Knights are down, but the door remains sealed." },
		{ speaker = "Magister Toven Ashe", text = "Their shield bears a royal symbol that should not exist in these ruins." },
	},
	N7BrokenVanguardBlade = {
		{ speaker = "Smith Hadrik", text = "This steel remembers a battle. Steel should not remember, but this steel does." },
		{ speaker = "Smith Hadrik", text = "I will forge it into something that protects people instead of guarding a locked door." },
	},
	SealedChamber = {
		{ speaker = "Magister Toven Ashe", text = "The door is still closed, but its crest has spoken clearly enough." },
		{ speaker = "Magister Toven Ashe", text = "The first Vanguard swore an oath against their own king. We must learn why." },
	},
	TheBrokenOath = {
		{ speaker = "Magister Toven Ashe", text = "The oath was not broken by the monsters. It was broken by the Crown." },
		{ speaker = "Magister Toven Ashe", text = "Rhessa must know what happened on the upper slope. Take this truth to her." },
	},
	B7AshenSpear = {
		{ speaker = "Commander Rhessa Kael", text = "The road is open, and the Ashen Spear has lowered its banner." },
		{ speaker = "Commander Rhessa Kael", text = "Varok warned us about the Frostwing. We should listen before we climb higher." },
	},
	N8OrcsDebt = {
		{ speaker = "Scout Varok", text = "You returned our scouts. The Ashen Spear will remember that debt." },
		{ speaker = "Scout Varok", text = "The Frostwing is not the oldest thing beneath this mountain. Do not forget it." },
	},
	WarbandsRefuge = {
		{ speaker = "Warden Edda", text = "The Orc camp is no longer blocking the road." },
		{ speaker = "Warden Edda", text = "They came here to hide, not conquer. The upper cliffs are next." },
	},
	ForgeTheVanguard = {
		{ speaker = "Blacksmith Doran", text = "Your equipment is stronger, and the old Vanguard iron has a new purpose." },
		{ speaker = "Blacksmith Doran", text = "Enhance it once more before the mountain winds grow colder." },
	},
	SealTheVanguard = {
		{ speaker = "Blacksmith Doran", text = "The seal answered your equipment. The old Vanguard would have recognized that sign." },
		{ speaker = "Blacksmith Doran", text = "You are ready for the upper cliffs. Do not waste the warning we have earned." },
	},
	N9FeathersForSignal = {
		{ speaker = "Scout Iven", text = "The signal is ready. Valdris knows the northern road is in danger." },
		{ speaker = "Scout Iven", text = "If the sky turns red, do not wait for another signal. Run." },
	},
	N10MealAboveClouds = {
		{ speaker = "Cook Branna", text = "There. Eat this before the summit." },
		{ speaker = "Cook Branna", text = "If it does not warm you, it will at least keep you too busy chewing to panic." },
	},
	B8TalonsFrosthorn = {
		{ speaker = "Warden Edda", text = "The upper route is open, and the recovered supplies can still help the Vanguard." },
		{ speaker = "Warden Edda", text = "The Wyverns were not here last season. The summit is changing the sky now, too." },
	},
	B9HighNest = {
		{ speaker = "Warden Edda", text = "The old supply crate predates the crater impact." },
		{ speaker = "Warden Edda", text = "Someone prepared for a battle on this mountain long before today's disturbance." },
	},
	FrostwingsDomain = {
		{ speaker = "Skorvath", text = "You have won a moment, not a victory." },
		{ speaker = "Magister Toven Ashe", text = "The dragon's final warning is connected to the crater. We must return and report." },
	},
	N11OldSoldiersQuestion = {
		{ speaker = "Veteran Dain", text = "These soldiers were sent toward the crater twenty-seven years ago." },
		{ speaker = "Veteran Dain", text = "The report says they never returned. It does not say why they were sent." },
	},
	N12LightForFallen = {
		{ speaker = "Priestess Selene", text = "The lamps are lit. The fallen will not be forgotten today." },
		{ speaker = "Priestess Selene", text = "May their names guide you when the next mountain calls." },
	},
	ReturnToValdris = {
		{ speaker = "Commander Rhessa Kael", text = "The Frostwing was not attacking Valdris. It was holding the old royal command at bay." },
		{ speaker = "Commander Rhessa Kael", text = "We are done here. The truth is dangerous, but silence made it worse." },
	},
	CinderscarWarden = {
		{ speaker = "Commander Rhessa Kael", text = "The crater guardian is defeated, but its seal is older than our kingdom." },
		{ speaker = "Commander Rhessa Kael", text = "Keep the fragment safe. The rest of the truth belongs to the chapters ahead." },
	},
}

for questId, dialogue in pairs(chapterOneCompletionDialogue) do
	if QuestConfig[questId] then
		QuestConfig[questId].completionDialogue = dialogue
	end
end

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

-- Plain-language instructions shared by the quest log, tracker, and dialogue
-- offer. Keep these short so younger players can understand them quickly.
function QuestConfig.GetRequirementLines(config)
	local lines = {}
	for _, target in ipairs(config.targets or {}) do
		local quantity = target.quantity or 1
		local name = target.name
		name = name:gsub("(%l)(%u)", "%1 %2")
		local action
		local how
		if target.type == "enemy" then
			action = "Defeat " .. quantity .. " " .. name
			how = "How: Find this enemy in the quest hint area and defeat it."
		elseif target.type == "item" then
			action = "Collect " .. quantity .. " " .. name
			how = "How: Pick it up or get it as a monster drop."
		elseif target.type == "craft" then
			action = "Craft " .. quantity .. " " .. name
			how = "How: Visit the Crafting Master and make it using the recipe."
		elseif target.type == "zone" then
			action = "Reach " .. name
			how = "How: Travel to the place named in the hint."
		elseif target.type == "npc" then
			action = "Talk to " .. name
			how = "How: Find this character and press the Talk prompt."
		elseif target.type == "upgrade" then
			action = "Upgrade 1 piece of gear"
			how = "How: Use the equipment upgrade menu."
		elseif target.type == "enhance" then
			action = "Enhance 1 piece of gear"
			how = "How: Use an Enhancement Scroll on your gear."
		else
			action = tostring(quantity) .. " " .. name
			how = "How: Follow the quest hint."
		end
		table.insert(lines, action .. "\n" .. how)
	end
	return lines
end

function QuestConfig.GetRequirementText(config)
	local lines = QuestConfig.GetRequirementLines(config)
	if #lines == 0 then return config.objective or config.description or "Follow the quest hint." end
	return table.concat(lines, "\n\n")
end

return QuestConfig
