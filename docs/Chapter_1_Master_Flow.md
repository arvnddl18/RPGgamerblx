# THE SHATTERED CROWN
## Chapter 1 Master Flow, Plot, and Quest List

This document is the quick-reference version of [MMORPG_Storyline_Script.md](MMORPG_Storyline_Script.md). It describes the current-map Chapter 1 experience and separates live game quests from planned expansion quests.

---

## 1. Current Story Scope

**Current map:** Valdris, the northern road, Frosthorn Peak, and optional Cinderscar Crater content.

**Active story:** Chapter 1 - *The Frostwing's Domain*.

**Future maps:**

- Chapter 2 - Emberfang Ridge
- Chapter 3 - Duskroot Mountain
- Chapter 4 - Stormpeak Crest

Chapters 2-4 are future-map story planning. They are not current-map quests.

---

## 2. Main Plot Summary

The player is a new recruit of the Valdris Vanguard. Strange attacks begin in the northern foothills, but the monsters are not invading Valdris. Slimes, Goblins, Spiders, Dire Wolves, Orcs, Wyverns, and Griffins are all moving away from Frosthorn Peak.

The player climbs Frosthorn and discovers that the disturbance is connected to ancient ruins, a sealed chamber, and a royal expedition from twenty-seven years ago. Magister Toven finds evidence that the old Vanguard was involved in hiding something beneath the mountain.

The Orc warband confirms that it fled the summit because of an ancient dragon. At the summit, the player defeats Skorvath, the Frostwing, but learns that he was a guardian rather than the true source of the danger.

In Skorvath's hoard, the player finds old Vanguard equipment bearing a royal seal. Commander Rhessa knows more than she admits and orders the player to return to Valdris without investigating further.

The chapter ends with King Aldric receiving a report that hides the truth about the crater. The player wins the immediate battle but discovers a much larger conspiracy.

### What the player learns in Chapter 1

- The creatures are fleeing from Frosthorn's summit.
- The mountain contains an ancient sealed danger.
- The old Vanguard visited Frosthorn twenty-seven years ago.
- A royal seal was deliberately hidden or damaged.
- Rhessa knows more about the old expedition than she admits.
- Skorvath was guarding something beneath the mountain.
- The Cinderscar Crater is connected to the mystery.

### What remains secret

- The Hollow King is Prince Cael.
- Aldric buried Cael beneath the crater.
- Rhessa helped seal Cael.
- The true power beneath Vaelithra.

---

## 3. Complete Act Flow

### Act I - The Road Calls

**Purpose:** Introduce Valdris, the Vanguard, basic combat, and the first mystery.

**Flow:**

1. The player joins the Vanguard.
2. Rhessa sends the player to Frosthorn.
3. The player reaches the Northern Waygate.
4. Slimes overrun a supply camp.
5. Goblins are found fleeing from the summit.
6. The player rescues Nib Quickfinger.
7. The player learns that the monsters are escaping something above.

**Act ending:** A trail leads uphill toward Frostwood.

### Act II - The Forest Flees

**Purpose:** Teach status effects, tracking, and environmental investigation.

**Flow:**

1. The player gathers materials for the field medic.
2. Spiders and webs block the forest road.
3. The player collects Spider Silk and antidote materials.
4. Dire Wolves flee instead of attacking.
5. A hunter confirms that the animals are escaping the summit.
6. Toven's investigation points toward ancient ruins.

**Act ending:** The fleeing wolves stop outside the ruins.

### Act III - The Door That Remembers

**Purpose:** Turn the story from monster survival into royal mystery.

**Flow:**

1. The player meets Toven.
2. Skeletons emerge around the ruins.
3. Skeleton Knights protect a sealed chamber.
4. The player discovers an old royal crest.
5. Toven learns that the ruins predate Valdris.
6. Rhessa becomes defensive when questioned.

**Act ending:** The sealed door reacts to the player's Vanguard badge.

### Act IV - Those Who Hide

**Purpose:** Reveal that the Orcs are refugees and challenge the player's assumptions.

**Flow:**

1. The player reaches the Ashen Spear war camp.
2. Varok explains that the Orcs are escaping the summit.
3. The player may fight, force surrender, or help the warband.
4. The Orcs confirm that the Frostwing is driving creatures away.
5. The player upgrades equipment using recovered materials.

**Act ending:** Varok says the kingdom was already afraid before the Orcs arrived.

### Act V - Wings Over Frosthorn

**Purpose:** Prepare the player for the summit boss.

**Flow:**

1. The player may secure the Western and Eastern Watch posts.
2. The player gathers supplies and signal materials.
3. Wyverns attack the upper cliffs.
4. Griffins guard the final supply cache.
5. The player reaches the summit.
6. Skorvath challenges the player.
7. The player defeats Skorvath and survives Frost Nova.

**Act ending:** Skorvath warns that the player has awakened the buried fire's attention.

### Act VI - The Report

**Purpose:** Give the victory consequences and end the chapter with a mystery.

**Flow:**

1. The player searches Skorvath's hoard.
2. The old Vanguard armor and royal seal are discovered.
3. The fallen soldiers are remembered.
4. The player returns to Valdris.
5. Rhessa gives a carefully incomplete report.
6. Aldric orders the truth to remain hidden.

**Chapter ending:** The player is sent toward the next danger while the royal cover-up continues.

---

## 4. Live Main-Story Quests

These quests currently exist in `src/Shared/Config/Quests.lua`.

| # | Quest ID | Quest name | Giver | Main objective |
|---:|---|---|---|---|
| 1 | `VanguardAtDawn` | A Vanguard at Dawn | Commander Rhessa Kael | Speak with Rhessa |
| 2 | `VillageSupplyLine` | A Village Worth Saving | Sister Amara | Hear the refugees' account |
| 3 | `NorthernWaygate` | The Northern Waygate | Scout Iven | Reach the Frosthorn Waygate |
| 4 | `N1MissingAtFirstLight` | Missing at First Light | Elder Mara | Protect the foothill village |
| 5 | `B1SlimeSupplyRoad` | Slime on the Supply Road | Commander Rhessa Kael | Defeat Slimes |
| 6 | `B2GoblinQuickfingers` | Goblin Quickfingers | Commander Rhessa Kael | Defeat Goblins |
| 7 | `N2QuartermastersLedger` | The Quartermaster's Ledger | Quartermaster Elian | Recover the supply records |
| 8 | `FoothillDisturbance` | Foothill Disturbance | Commander Rhessa Kael | Defeat Slimes and Goblins |
| 9 | `FieldMedicRemedy` | The Field Medic's Lesson | Sister Amara | Collect 5 Herbs; craft 1 Health Potion |
| 10 | `FleeingPeak` | Fleeing the Peak | Scout Iven | Defeat 7 Spiders in east/west clearings and 7 Dire Wolves in the north deep forest |
| 11 | `B3WebsAcrossRoad` | Webs Across the Road | Scout Iven | Defeat Spiders |
| 12 | `B4RunningPack` | The Running Pack | Scout Iven | Defeat Dire Wolves |
| 13 | `N4AntidoteForPatrol` | Antidote for the Patrol | Healer Lysa | Prepare patrol antidotes |
| 14 | `N5HuntersLastTrail` | The Hunter's Last Trail | Hunter Corren | Follow the hunter's trail |
| 15 | `WebsOfWarning` | Webs of Warning | Scout Iven | Collect Spider Silk |
| 16 | `N3GoblinHonestWork` | A Goblin's Honest Work | Nib Quickfinger | Recover the missing crates |
| 17 | `ScholarInRuins` | The Scholar in the Ruins | Magister Toven Ashe | Speak with Toven |
| 18 | `N6PagesBeneathSnow` | Pages Beneath the Snow | Magister Toven Ashe | Recover Toven's lost pages |
| 19 | `EchoesBelow` | Echoes Below | Magister Toven Ashe | Defeat Skeletons |
| 20 | `B5BonesAncientSnow` | Bones in Ancient Snow | Magister Toven Ashe | Defeat wandering Skeletons |
| 21 | `B6KnightsSealedDoor` | Knights of the Sealed Door | Magister Toven Ashe | Defeat Skeleton Knights |
| 22 | `N7BrokenVanguardBlade` | The Broken Vanguard Blade | Smith Hadrik | Recover Vanguard steel |
| 23 | `SealedChamber` | The Sealed Chamber | Magister Toven Ashe | Defeat Skeleton Knights and reach the chamber door |
| 24 | `TheBrokenOath` | The Broken Oath | Magister Toven Ashe | Question Toven about the royal crest |
| 25 | `B7AshenSpear` | The Ashen Spear | Commander Rhessa Kael | Defeat the Ashen Spear warband |
| 26 | `N8OrcsDebt` | An Orc's Debt | Scout Varok | Help the Ashen Spear scouts |
| 27 | `WarbandsRefuge` | The Warband's Refuge | Warden Edda | Defeat the Orc warband |
| 28 | `ForgeTheVanguard` | Forge the Vanguard | Blacksmith Doran | Upgrade one piece of equipment |
| 29 | `SealTheVanguard` | Seal of the Vanguard | Blacksmith Doran | Enhance one piece of equipment |
| 30 | `N9FeathersForSignal` | Feathers for the Signal | Scout Iven | Prepare the cliff signal |
| 31 | `N10MealAboveClouds` | A Meal Above the Clouds | Cook Branna | Prepare the summit meal |
| 32 | `B8TalonsFrosthorn` | Talons Over Frosthorn | Warden Edda | Defeat hostile Wyverns |
| 33 | `B9HighNest` | The High Nest | Warden Edda | Defeat the high-nest Griffins |
| 34 | `FrostwingsDomain` | The Frostwing's Domain | Warden Edda | Defeat Skorvath |
| 35 | `N11OldSoldiersQuestion` | The Old Soldier's Question | Veteran Dain | Find the old Vanguard memorial |
| 36 | `N12LightForFallen` | A Light for the Fallen | Priestess Selene | Light the memorial shrine |
| 37 | `ReturnToValdris` | The Crown's Lie | Commander Rhessa Kael | Return to Rhessa in Valdris |

**Live main-story total:** 37 quests. The existing `FrostwingsDomain` quest fulfills the B10 summit battle, so Skorvath is fought only once.

---

## 5. Live Optional Repeatable Quests

These quests provide additional rewards but do not block the main story.

| Quest ID | Quest name | Giver | Objective |
|---|---|---|---|
| `WesternWatch` | The Western Watch | Warden Edda | Defeat Dire Wolves and secure the Western Watch |
| `EasternWatch` | The Eastern Watch | Warden Edda | Defeat Wyverns and secure the Eastern Watch |
| `WingsOverFrosthorn` | Wings over Frosthorn | Warden Edda | Defeat Wyverns and Griffins |

**Live optional total:** 3 quests.

---

## 6. Integrated Main-Story Battle Quests

These battle beats are now integrated into the live main-story chain. They are accepted from the listed NPCs through the normal comic dialogue flow and use exact monster/item IDs from the game configuration.

| Quest | Monster | Story function |
|---|---|---|
| **B1 - Slime on the Supply Road** | Slime | Teach movement, attacks, and loot |
| **B2 - Goblin Quickfingers** | Goblin | Rescue Nib and reveal the fleeing-monster mystery |
| **B3 - Webs Across the Road** | Spider | Teach poison and web hazards |
| **B4 - The Running Pack** | Dire Wolf | Teach tracking and enemy movement |
| **B5 - Bones in Ancient Snow** | Skeleton | Protect Toven's excavation |
| **B6 - Knights of the Sealed Door** | Skeleton Knight | Introduce elite enemies and the royal seal |
| **B7 - The Ashen Spear** | Orc | Create the Orc choice and moral conflict |
| **B8 - Talons Over Frosthorn** | Wyvern | Teach aerial combat and cliff danger |
| **B9 - The High Nest** | Griffin | Recover the final summit supplies |
| **B10 - The Frostwing's Challenge** | Skorvath | Chapter 1 boss battle; represented by the live `FrostwingsDomain` quest |

**Integrated battle total:** 10 story beats across 9 new quest IDs plus the existing `FrostwingsDomain` boss quest.

---

## 7. Integrated Main-Story NPC Quests

These quests are implemented on the current map. They connect the battles and provide evidence, character development, and lore through the same comic NPC offer flow.

| Quest | NPC | Story function |
|---|---|---|
| **N1 - Missing at First Light** | Elder Mara | Rescue a village child and show the human cost |
| **N2 - The Quartermaster's Ledger** | Quartermaster Elian | Reveal missing patrol reports |
| **N3 - A Goblin's Honest Work** | Nib Quickfinger | Recover supplies and deepen Nib's role |
| **N4 - Antidote for the Patrol** | Healer Lysa | Help poisoned patrol members |
| **N5 - The Hunter's Last Trail** | Hunter Corren | Confirm that the wolves are fleeing |
| **N6 - Pages Beneath the Snow** | Magister Toven Ashe | Recover evidence from the ruins |
| **N7 - The Broken Vanguard Blade** | Smith Hadrik | Turn old Vanguard steel into useful equipment |
| **N8 - An Orc's Debt** | Scout Varok | Rescue the Ashen Spear scouts and reveal the deeper danger |
| **N9 - Feathers for the Signal** | Scout Iven (falconer duty) | Warn Valdris about the summit danger |
| **N10 - A Meal Above the Clouds** | Cook Branna | Prepare the party for the summit |
| **N11 - The Old Soldier's Question** | Veteran Dain | Identify the fallen Vanguard expedition |
| **N12 - A Light for the Fallen** | Priestess Selene | Honor the dead after Skorvath's defeat |

**Integrated NPC total:** 12 quests.

---

## 8. Monster Progression

| Stage | Monsters | Lesson |
|---|---|---|
| Foothills | Slime, Goblin | Basic combat and group awareness |
| Frostwood | Spider, Dire Wolf | Status effects, movement, tracking |

### Current-map quest alignment notes

The live spawn layout is the source of truth for Chapter 1 directions:

- Spiders are available in the east and west forest clearings, with an additional north-west deep-forest group.
- Dire Wolves are available in the north deep forest and the east/west deep-forest groups.
- Orcs are not a Frostwood Spider objective; they belong to the deep-wilderness and mountain routes used by the later warband quests.
- `FleeingPeak` therefore requires **7 Spiders and 7 Dire Wolves**, shown as separate counters.
- `FieldMedicRemedy` requires **5 Herbs and 1 crafted Health Potion**. The potion’s recipe consumes 2 Herbs, but the quest tracks the 5 collected Herbs and the completed craft as separate requirements.
- Item requirements count qualifying items already in the player inventory when the quest is accepted, and remain recorded after the item objective is satisfied.
| Ancient Ruins | Skeleton, Skeleton Knight | Defense and elite enemies |
| Upper Slope | Orc | Dialogue choice and moral conflict |
| Upper Cliffs | Wyvern, Griffin | Aerial attacks and environmental danger |
| Summit | Skorvath | Full boss encounter |

---

## 9. Optional Cinderscar Crater

The crater is not the Chapter 1 final boss location.

**Optional encounter:** Vaelithra, the Cinderwyrm Warden.

**Purpose:** Exploration reward, foreshadowing, and early lore.

**Chapter 1 final boss:** Skorvath, the Frostwing, at the Frosthorn summit.

**Chapter 1 final quest:** `ReturnToValdris` - The Crown's Lie.

The optional quest `CinderscarWarden` becomes available from Commander Rhessa after `ReturnToValdris`. Accepting it activates Vaelithra at the crater and keeps the encounter separate from the main chain.

---

## 10. Quest Count Summary

| Category | Count | Status |
|---|---:|---|
| Live main-story quests | 37 | Configured in the game |
| Live optional repeatable quests | 3 | Configured in the game |
| Live optional crater quest | 1 | Configured in the game |
| Planned battle quests | 0 | All B1-B10 battle beats are integrated; B10 uses `FrostwingsDomain` |
| Planned NPC quests | 0 | N1-N12 are configured and playable on the current map |
| Future-map Chapters 2-4 | Not counted | Planning only |

**Live total:** 41 configured Chapter 1 quests.

**Expanded main-story total:** 37 configured main-story quests. Chapters 2-4 remain future-map planning only.

---

## 11. Final New-Player Goal

By the end of Chapter 1, a new player should be able to say:

> "The monsters were running from Frosthorn. We found an old royal secret, defeated a dragon guardian, and discovered that Rhessa and the king are hiding something."

That is the complete Chapter 1 story in one sentence.
