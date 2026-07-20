# THE SHATTERED CROWN
## Comic-Style Storyline Script

**Format:** In-game comic panels, cutscenes, NPC dialogue, and quest transitions
**Current arc:** Chapter 1 active; Chapters 2-4 future-map planning
**Player role:** A newly inducted recruit of the Valdris Vanguard

## Current Map Scope

**Current production map:** Valdris, the northern road, Frosthorn Peak, and the current-map portion of Cinderscar Crater.

**Currently active storyline:** Prologue and Chapter 1 - *The Frostwing's Domain*.

**Future-map storyline:** Chapters 2, 3, and 4 are planned for separate maps that are still under construction:

- Chapter 2: Emberfang Ridge
- Chapter 3: Duskroot Mountain
- Chapter 4: Stormpeak Crest

The Chapter 2-4 material remains in this document as future narrative planning only. It must not be used as current-map quest requirements, NPC placement, monster placement, zone IDs, or progression gates until those maps are built and their game configuration exists.

---

## HOW TO USE THIS SCRIPT

Each scene is written as a sequence of comic panels. A panel can be shown as a static illustration, a short camera move, or a gameplay transition. Text in brackets is direction for the game team. Text in quotation marks is spoken dialogue. Quest prompts are written as player-facing UI text.

The player character is intentionally silent during most cinematic panels. Their response is represented through an emote, a camera turn, a weapon draw, or a dialogue choice.

## NPC Dialogue Visual Reference

The attached screenshots are the visual reference for the quest NPC interaction. The game should use a polished comic-panel presentation rather than a small floating chat bubble.

### Target screen layout

```text
┌─────────────────────────────────────────────────────────────────────┐
│                         Dimmed game world                           │
│                                                                     │
│   Active character art                              Supporting art  │
│   bright and large                                  darker or dimmed │
│                                                                     │
│              ┌──────────── Speaker name ────────────┐              │
│              │                                      │              │
│              │  Short dialogue text.                │              │
│              │  Easy to read in 1-3 lines.          │              │
│              │                                      │              │
│              └──────────────────────────────────────┘              │
│                 [NEXT]                 [Auto-Play]     [X]          │
└─────────────────────────────────────────────────────────────────────┘
```

### Required visual elements

- Full-screen dark or blurred background so the player focuses on the conversation.
- Large illustrated character art on the left and/or right side of the screen.
- The speaking character is bright, while the listening character is slightly dimmed.
- A wide parchment, cream, or faction-colored dialogue box near the bottom center.
- A decorative nameplate attached to the top edge of the dialogue box.
- Speaker names in a large, readable font.
- One to three short lines of dialogue per panel.
- A clear `NEXT` or `CONTINUE` button.
- A visible `X` close button in the upper-right corner.
- Optional `AUTO-PLAY` control in the lower-right corner.
- Screen-safe margins so the UI works on desktop, tablet, and mobile screens.

### NPC quest interaction flow

The player should experience an NPC quest in this order:

1. The player approaches an NPC with a gold `!` marker.
2. The interaction prompt says **Talk** or **Speak**.
3. The comic dialogue overlay opens with the NPC's portrait and nameplate.
4. The NPC explains the situation in short panels.
5. The final panel presents the quest card with **Accept**, **Decline**, and **View Objectives**.
6. After acceptance, the dialogue closes and the main quest marker appears.
7. When objectives are complete, the NPC receives a blue `?` marker.
8. The player talks to the NPC again and sees a short completion comic.
9. The reward panel shows the item icon, item name, quantity, experience, and gold.

### Example: Rhessa gives the first quest

**Panel 1 - Rhessa active, recruit art dimmed**

**Speaker nameplate:** COMMANDER RHESSA KAEL

**RHESSA:** Recruit. The northern villages are under attack.

**RHESSA:** Follow the road to Frosthorn and find out what is driving the creatures downhill.

**Button:** NEXT

**Panel 2 - Rhessa remains active**

**RHESSA:** Your first order is simple: reach the Northern Waygate and report what you find.

**Button:** NEXT

**Panel 3 - Quest card**

**QUEST TITLE:** A Bell in the North

**OBJECTIVE:** Reach the Northern Waygate.

**REWARD PREVIEW:** 25 Gold, 100 Experience, 1 Health Potion

**Buttons:** ACCEPT / DECLINE / VIEW OBJECTIVES

### Example: Toven introduces the ruins

**Panel 1 - Toven active, Rhessa dimmed**

**Speaker nameplate:** MAGISTER TOVEN ASHE

**TOVEN:** These stones are older than Valdris.

**TOVEN:** The Skeletons are not guarding treasure. They are guarding a memory.

**Button:** NEXT

**Panel 2 - Toven points toward the sealed door**

**TOVEN:** Help me clear the courtyard, and we may learn who built this seal.

**Button:** VIEW OBJECTIVES

**QUEST TITLE:** Echoes Below

**OBJECTIVE:** Defeat 10 Skeletons.

### Implementation checklist

`ComicDialogueController.lua` provides the dim overlay, dialogue card, speaker name, text, next button, skip button, procedural portrait fallback, and optional uploaded image support. The implementation includes:

- Procedural child-friendly character busts when no uploaded portrait asset is available.
- Optional uploaded portrait images through each panel's portrait field.
- Left and right character-art positions with active-speaker lighting and inactive-speaker dimming.
- Decorative nameplate styling and cream dialogue panel.
- Quest accept and decline controls inside the dialogue flow.
- Auto-play, close, skip, and keyboard controls.
- Quest objective and reward presentation.
- Responsive scaling constraints for different screen sizes.

The screenshots are a style reference, not a requirement to copy the original characters or artwork. The game's characters, colors, and artwork must remain original to **The Shattered Crown**.

### Implementation status

- **Implemented:** Reference-style comic overlay with dimmed background, left/right speaker frames, active-speaker emphasis, nameplate, cream dialogue box, next/continue, skip, close, keyboard controls, and auto-play.
- **Implemented:** Quest-specific comic offer and completion dialogue for every Chapter 1 quest, including Accept Quest, Later, and Turn In Quest actions.
- **Implemented:** Child-friendly main quest tracker with one prioritized Chapter 1 objective and progress text.
- **External/future scope:** Optional custom portrait uploads can replace the procedural art. B1-B9, the B10 summit beat, and N1-N12 are implemented on the current map using the existing quest, monster, item, and zone systems. Chapters 2-4 remain reserved for future maps and assets.

---

## PROLOGUE - THE CITY OF RINGS

### Scene 0.1 - Dawn Over Valdris

**Panel 1 - Establishing shot**

[A wide view of Valdris at dawn. The city is built in concentric rings. Emberholt Castle rises at the exact center. Four sealed Waygates stand at the ends of the cardinal roads. Beyond the walls, the Cinderscar Crater smolders faintly in the northeast.]

**CAPTION:** Thal'Kareth. The Broken Ring.

**CAPTION:** For twenty-seven years, the kingdom of Valdris has called the crater a falling star.

**Panel 2 - The Vanguard courtyard**

[New recruits stand in formation. Commander Rhessa Kael walks along the line, inspecting them.]

**RHESSA:** Stand straight, recruit. A Vanguard badge is not decoration.

**RHESSA:** It is a promise that when the kingdom calls, you answer.

**Panel 3 - Close-up**

[Rhessa stops in front of the player character.]

**RHESSA:** Your name is the one I remember.

**PLAYER RESPONSE:** Nod / salute / remain silent.

**RHESSA:** Good. You will be my eyes beyond the walls.

**Panel 4 - The castle balcony**

[King Aldric Varn addresses citizens below. He looks warm, composed, and beloved.]

**ALDRIC:** Valdris stands because its people stand together.

**ALDRIC:** No beast, raider, or ghost will break the kingdom we built.

**CROWD:** For Valdris! For King Aldric!

**Panel 5 - The northeast horizon**

[The crater flashes with a distant red pulse. Nobody in the crowd notices. On a high tower, Magister Toven Ashe watches it through a brass spyglass.]

**TOVEN:** That was not a falling star.

**Panel 6 - Back to the courtyard**

[A bell begins ringing from the northern gate. Soldiers hurry through the courtyard. Rhessa turns toward the sound.]

**RHESSA:** The northern foothills are under attack.

**RHESSA:** Recruit, report to the Frosthorn road. Your first assignment begins now.

**QUEST ACCEPTED:** A Bell in the North

---

## CHAPTER 1 - THE FROSTWING'S DOMAIN

### Chapter 1 Dialogue Guide

This chapter is written as a complete dialogue pass. Each scene contains the recommended trigger, the full exchange, and the gameplay handoff. The player may use a silent protagonist, with the listed player responses shown as dialogue buttons, emotes, or animation choices.

### Chapter 1 Quest Index

The quests are located in the script in the sections listed below. The chapter is designed as one connected quest chain, with each quest leading directly into the next one.

| Quest | Quest section in this script | Starts when | Main objectives | Ends when |
|---|---|---|---|---|
| **1.1 - A Bell in the North** | `Quest 1.1 - A Bell in the North` and `Scene 1.1 - The Northern Waygate` | The player speaks to Rhessa in the Vanguard courtyard | Travel to Frosthorn, investigate the disturbance, and reach the northern Waygate | The player arrives at the Waygate and receives the foothill-camp assignment |
| **1.2 - Mud and Mucus** | `Quest 1.2 - Mud and Mucus` | The player enters the abandoned supply camp | Defeat the slimes, rescue Nib, and learn what drove the goblins from the mountain | Nib is escorted toward the southern road |
| **1.3 - Webs in the Frostwood** | `Quest 1.3 - Webs in the Frostwood` | The player enters Frostwood | Clear spider nests and follow the fleeing dire wolves toward the ancient ruins | The player reaches the ruins |
| **1.4 - The Old Stone Door** | `Quest 1.4 - The Old Stone Door` | The player finds Toven at the ancient ruins | Protect Toven, defeat the Skeletons and Skeleton Knights, and inspect the sealed chamber | Toven confirms the ruins are older than Valdris |
| **1.5 - The War Camp** | `Quest 1.5 - The War Camp` | The player reaches the upper-slope orc barricade | Negotiate with or defeat the Ashen Spear warband and clear the road | Varok warns the player about the Frostwing |
| **1.6 - Wings Over the Cliffs** | `Quest 1.6 - Wings Over the Cliffs` | The player reaches the upper cliffs | Cross the aerial-beast territory; optionally clear the nests for supplies and gear | The player reaches the summit approach |
| **1.7 - Skorvath, the Frostwing** | `Quest 1.7 - Skorvath, the Frostwing` | The player enters the summit arena | Defeat Skorvath and survive the Frost Nova | Skorvath dies and warns about the buried fire |
| **1.8 - The Old Vanguard Seal** | `Quest 1.8 - The Old Vanguard Seal` | The player searches Skorvath's hoard | Recover the old Vanguard armor, investigate its royal seal, and observe the Cinderscar Crater | The player returns to Valdris and Chapter 1 ends |

**Quest flow:** `1.1 -> 1.2 -> 1.3 -> 1.4 -> 1.5 -> 1.6 -> 1.7 -> 1.8`

**Existing quest coverage:** All major Chapter 1 gameplay sections now have a quest. The optional aerial-nest route is part of Quest 1.6, not a separate quest, so players who skip it can continue the main story without losing progression.

**Main-story expansion:** The B1-B10 battle beats and N1-N12 NPC quests below are all registered as current-map main-story content. B1-B9 are separate live battle quests, while B10 is fulfilled by the existing `FrostwingsDomain` quest so the Skorvath battle is never duplicated. Cinderscar Crater remains optional.

**Expanded Chapter 1 count:** **37 live main-story quests**. The compact `1.1-1.8` flow above is the chapter outline; the B and N quests are the detailed objectives inserted between those outline beats.

### Recommended Expanded Chapter 1 Story Flow

The expanded quests should follow this order. The battle quests create immediate gameplay goals, while the NPC quests provide evidence, human consequences, and transitions between story locations.

| Act | Quest sequence | Story purpose and reveal |
|---|---|---|
| **Act I - The Road Calls** | `VanguardAtDawn -> VillageSupplyLine -> NorthernWaygate -> N1 -> B1 -> B2 -> N2 -> FoothillDisturbance` | The player leaves Valdris, rescues villagers, meets Nib, and learns that the creatures are fleeing from the summit rather than invading. |
| **Act II - The Forest Flees** | `FieldMedicRemedy -> FleeingPeak -> B3 -> B4 -> N4 -> N5 -> WebsOfWarning -> N3` | Poison, damaged wildlife, and Spider Silk show that the disturbance is changing normal creatures. The first clues point upward, toward something powerful enough to frighten predators. |
| **Act III - The Door That Remembers** | `ScholarInRuins -> N6 -> EchoesBelow -> B5 -> B6 -> N7 -> SealedChamber -> TheBrokenOath` | Toven becomes a recurring ally. The player recovers the missing pages, protects the excavation, discovers the sealed chamber, and finds the first scratched royal crest. |
| **Act IV - Those Who Hide** | `TheBrokenOath -> B7 -> N8 -> WarbandsRefuge -> ForgeTheVanguard -> SealTheVanguard` | The Ashen Spear barricade falls, and the Orcs confirm that they are refugees, not invaders. Their testimony and the reforged Vanguard equipment connect the old expedition to the current royal command. |
| **Act V - Wings Over Frosthorn** | `[optional: WesternWatch, EasternWatch, WingsOverFrosthorn] -> N9 -> N10 -> B8 -> B9 -> FrostwingsDomain` | The player may secure the optional watch posts, then prepares the party, defeats the aerial elites, and confronts Skorvath. The dragon names the buried fire and warns that the player has only awakened its attention. |
| **Act VI - The Report** | `N11 -> N12 -> ReturnToValdris` | The old soldiers are remembered, the fallen are honored, and Rhessa's silence becomes the final mystery of Chapter 1. |

**Pacing rule:** N1-N12 should not all be presented as unrelated errands. Each NPC quest must be placed immediately after a relevant battle or discovery, and its completion must answer one question while creating the next one.

**Plot rule:** The player should not learn that Cael is involved, or receive the full crater truth, during Chapter 1. Chapter 1 should end with evidence of a royal cover-up, not the complete explanation. That preserves the later reveal in the future-map chapters.

**Optional content rule:** The Cinderscar Crater may be visited after Chapter 1 and can foreshadow the truth, but its lore drops should remain incomplete enough that the player still needs Chapters 2-4 to understand the whole conspiracy.

### Chapter 1 Act Pacing Plan - 100% Quality Target

This pacing plan is the quality target for the final Chapter 1 experience. The goal is not merely to add more quests. Every quest must either teach the player a mechanic, deepen a character, reveal a clue, create an emotional consequence, or move the player to a new location.

#### Act I - The Road Calls

**Purpose:** Teach the player how the world, combat, quests, and Vanguard work.

**Recommended length:** 20-30 minutes

**Quest rhythm:** Dialogue -> movement tutorial -> Slime battle -> Goblin battle -> rescue -> short return conversation.

**Main quests:** `VanguardAtDawn`, `VillageSupplyLine`, `NorthernWaygate`, `N1`, `B1`, `B2`, `N2`, `FoothillDisturbance`

**Player experience:** The player should feel useful and capable, but not yet powerful. Slimes teach basic attacks and movement. Goblins teach groups, positioning, and rescuing an NPC during combat.

**Lore reveal:** The monsters are not invading. They are fleeing from Frosthorn.

**Character beat:** Rhessa is protective and confident. Toven is only a distant mystery. Nib gives the player a lighter, humorous voice after the serious opening.

**Act ending:** The player finds a trail leading uphill. Rhessa says, "We are not chasing an army. We are following a fear."

#### Act II - The Forest Flees

**Purpose:** Introduce status effects, exploration, tracking, and the first signs that the disturbance is changing nature.

**Recommended length:** 25-35 minutes

**Quest rhythm:** Healing objective -> Spider battle -> poison recovery -> Dire Wolf pursuit -> tracking conversation -> item investigation.

**Main quests:** `FieldMedicRemedy`, `FleeingPeak`, `B3`, `B4`, `N4`, `N5`, `WebsOfWarning`, `N3`

**Player experience:** The player learns to respond to Poison, use healing items, avoid web hazards, and read monster movement. There should be one short safe area between the Spider and Dire Wolf encounters so the act does not become a continuous combat corridor.

**Lore reveal:** The Spider Silk is woven in one direction, away from the summit. The wolves are not hunting; they are escaping.

**Character beat:** Scout Iven becomes the practical field guide. Nib's side of the story confirms that multiple species are reacting to the same unseen threat.

**Act ending:** The fleeing wolf pack stops outside the ancient ruins. The player sees that even predators will not cross the shadow of the old stones.

#### Act III - The Door That Remembers

**Purpose:** Shift the story from survival to investigation and establish the old Vanguard conspiracy.

**Recommended length:** 30-40 minutes

**Quest rhythm:** Toven dialogue -> ruin exploration -> Skeleton battle -> protected investigation -> Skeleton Knight elite battle -> sealed-door discovery.

**Main quests:** `ScholarInRuins`, `N6`, `EchoesBelow`, `B5`, `B6`, `N7`, `SealedChamber`, `TheBrokenOath`

**Player experience:** Combat slows slightly and the environment becomes more important. The player should have time to inspect statues, shields, runes, and old expedition marks between battles.

**Lore reveal:** A royal expedition came to Frosthorn twenty-seven years ago. Its records were erased, and the sealed chamber bears a damaged royal crest.

**Character beat:** Toven stops being comic relief and becomes the first person willing to question the crown. Rhessa becomes noticeably more controlling when the player asks about the crest.

**Act ending:** The sealed door does not open, but it reacts to the player's Vanguard badge. Toven says, "It remembers the people who closed it."

#### Act IV - Those Who Hide

**Purpose:** Challenge the player's assumptions by revealing that the Orcs are refugees, not simple villains.

**Recommended length:** 25-35 minutes

**Quest rhythm:** Approach and dialogue choice -> Orc battle or surrender objective -> rescue scouts -> testimony -> equipment upgrade.

**Main quests:** `WarbandsRefuge`, `B7`, `N8`, `ForgeTheVanguard`, `SealTheVanguard`

**Player experience:** This act must allow a meaningful choice. The player can defeat the warband, force a surrender, or complete the rescue objective with minimal bloodshed. The story continues either way, but Varok's later dialogue and reputation should reflect the choice.

**Lore reveal:** The Orcs came to Frosthorn because something in the summit drove them away. Their warband has found the same royal crest on old Vanguard supplies.

**Character beat:** Rhessa orders the player to clear the camp even after hearing the Orcs' explanation. This is the first moment when the player can reasonably doubt her judgment.

**Act ending:** Varok gives the player the old warband banner and says, "Your kingdom was here before us. It was already afraid."

#### Act V - Wings Over Frosthorn

**Purpose:** Build toward the boss with preparation, vertical traversal, elite encounters, and rising danger.

**Recommended length:** 30-45 minutes

**Quest rhythm:** Optional preparation -> Wyvern encounter -> recovery break -> Griffin encounter -> final climb -> dragon boss.

**Main quests:** `N9`, `N10`, `WingsOverFrosthorn`, `B8`, `B9`, `FrostwingsDomain`, `B10`

**Optional preparation:** `WesternWatch` and `EasternWatch` may be completed for rewards, but they must never block the main story.

**Player experience:** The player should feel the mountain becoming hostile. Wind, narrow ledges, aerial enemies, and falling-snow warnings should increase tension without making the route frustrating.

**Lore reveal:** Skorvath is not the source of the disturbance. He is an ancient guardian who has been keeping something below the mountain contained.

**Character beat:** Rhessa insists that Skorvath is only a threat. Toven recognizes that the dragon's words match the old ruins.

**Act ending:** Skorvath dies after warning, "You have only taught the buried fire your names."

#### Act VI - The Report

**Purpose:** Give the boss victory a consequence and end the chapter with a personal mystery instead of immediately starting the next map.

**Recommended length:** 15-20 minutes

**Quest rhythm:** Search the hoard -> recover evidence -> memorial moment -> return journey -> tense report to Rhessa.

**Main quests:** `N11`, `N12`, `ReturnToValdris`

**Player experience:** Combat stops. The player processes what happened, honors the fallen, and realizes that the victory did not solve the mystery.

**Lore reveal:** The old Vanguard was involved in the crater's original secret, but Chapter 1 does not yet reveal Cael or the complete truth.

**Character beat:** Rhessa's loyalty becomes uncertain. She protects the player from immediate danger while also hiding information from them.

**Chapter ending:** King Aldric receives a report that omits the crater. The player is sent toward the next problem before they can investigate the truth.

### Chapter 1 Pacing Rules

1. No more than two consecutive combat quests without dialogue, exploration, or a meaningful NPC interaction.
2. Every act must contain one quiet scene where the player can understand the characters and lore.
3. Every new monster must teach a different gameplay lesson: Slimes teach movement, Goblins teach group combat, Spiders teach status effects, Dire Wolves teach tracking, Skeletons teach defense, Skeleton Knights teach elites, Orcs teach choices, Wyverns and Griffins teach vertical combat, and Skorvath tests everything together.
4. Every act must answer one question and create one stronger question.
5. Do not reveal Cael, Aldric's full betrayal, or the god-fragment in Chapter 1. Show evidence, not the complete explanation.
6. The player's first clear view of Vaelithra should feel like a discovery, not a required checkpoint.
7. Rewards must support the next act: healing after Act I, status protection after Act II, defensive materials after Act III, upgrade materials after Act IV, mobility or survival rewards before Act V, and lore or memorial rewards in Act VI.
8. If the player skips optional content, the main plot must remain fully understandable.

### Final New-Player Quality Pass

The expanded quest count must not create grind or confusion. These rules are required for the 9.7/10 target.

#### No duplicate combat

The B quests are detailed story beats, not extra kill grinds layered on top of the live quests. When the expanded quests are implemented, the game must use shared progress:

| Existing configured quest | Expanded story quests that share its progress | Player-facing result |
|---|---|---|
| `FoothillDisturbance` | B1 and B2 | Slime and Goblin kills count once; the parent quest completes after both battle beats. |
| `FleeingPeak` | B3 and B4 | Spider and Dire Wolf kills count once; the player never repeats the same packs. |
| `EchoesBelow` | B5 | Skeleton kills advance both the battle beat and the parent story quest. |
| `SealedChamber` | B6 | Skeleton Knight kills and the chamber interaction are one encounter. |
| `WarbandsRefuge` | B7 and N8 | The Orc battle, surrender choice, and follow-up rescue are one story sequence. |
| `WingsOverFrosthorn` | B8 and B9 | Wyvern and Griffin kills count once for the cliff approach. |
| `FrostwingsDomain` | B10 | Skorvath is fought once and completes both the battle beat and the summit quest. |

**Implementation rule:** Do not add a second kill counter for a B quest if the parent quest already tracks that monster. Use one shared target-progress key, then unlock the next dialogue beat when the target is complete.

#### One primary quest at a time

The player should have one highlighted main quest and no more than two nearby supporting objectives. N1-N12 should not all appear as simultaneous golden markers. The next NPC becomes available only after the previous story beat is complete.

**Quest UI labels:**

- **MAIN:** Required to advance the Chapter 1 story.
- **BATTLE:** The combat scene currently active in the main quest.
- **EVIDENCE:** A short NPC or investigation objective that advances the mystery.
- **OPTIONAL:** Extra rewards and lore; never blocks the story.
- **FUTURE:** Not available on the current map.

#### Clue and payoff tracking

The player should encounter the mystery in a clear sequence:

1. **Act I clue:** Creatures flee downhill from the summit.
2. **Act II clue:** Poison, webs, and animal behavior are abnormal.
3. **Act III clue:** The ruins and sealed chamber predate Valdris.
4. **Act IV clue:** The old Vanguard and Orc refugees mention the same summit threat.
5. **Act V clue:** Skorvath reveals that he is guarding something buried.
6. **Act VI payoff:** The royal seal proves that the crown was involved twenty-seven years ago.

The player should always understand the current question: **What is driving the mountain's creatures away?** The answer at the end of Chapter 1 is: **an ancient danger beneath Frosthorn, protected by a royal secret.**

#### New-player acceptance test

Chapter 1 passes its story test when a new player can answer these questions without reading the proposal document:

- Why am I going to Frosthorn? **To investigate the fleeing creatures and protect the villages.**
- Why are the monsters attacking? **They are displaced and frightened by something above them.**
- Who is Toven? **A scholar investigating ruins older than Valdris.**
- Why are the Orcs on the mountain? **They are refugees from the same threat.**
- Who is Skorvath? **A guardian who has been protecting a buried danger.**
- Why is Rhessa suspicious? **She recognizes old royal evidence and refuses to explain it.**
- What happens next? **The player returns to Valdris while the royal cover-up continues.**

If the player cannot answer one of these questions, the next dialogue scene should add a short recap before introducing new lore.

### Chapter 1 Lore Quality Standard

By the end of Chapter 1, a new player should understand:

- Frosthorn's creatures are fleeing from something at the summit.
- The summit is connected to an older secret beneath the mountain.
- The old Vanguard was involved twenty-seven years ago.
- A royal seal was deliberately damaged or hidden.
- Rhessa knows more than she admits.
- Skorvath was a guardian, not the true source of the danger.
- The Cinderscar Crater is connected to the secret, but its full truth is still unknown.

The player should not yet know:

- That the Hollow King is Prince Cael.
- That Aldric buried Cael alive.
- That Rhessa helped seal Cael.
- What lies beneath Vaelithra.

This preserves mystery for the future-map chapters while making Chapter 1 feel complete on its own.

### Audience-Balanced Quality Pass

Chapter 1 should work for children, teenagers, and adults at the same time. The story uses a layered presentation: the main path is simple and exciting, while optional dialogue and lore items provide deeper meaning for players who want it.

| Audience | What they need | How Chapter 1 provides it |
|---|---|---|
| **Children** | Clear goals, visible rewards, humor, simple dialogue, and frequent action | One highlighted objective, short comic panels, Nib's humor, readable monster behavior, and a boss at the end of each major adventure beat |
| **Teenagers** | Character conflict, choices, mystery, progression, and emotional consequences | Varok's surrender choice, Rhessa's suspicious orders, Toven's investigation, reputation changes, and the royal-cover-up mystery |
| **Adults** | Foreshadowing, layered motivations, world history, and payoff | The twenty-seven-year timeline, damaged royal crest, Skorvath's guardian role, Rhessa's omissions, and the crater's connection to future chapters |

#### Three-layer dialogue rule

Every important scene should communicate three things in order:

1. **Immediate meaning:** What the player needs to do next. Example: "Clear the camp and rescue the survivor."
2. **Character meaning:** What the speaker feels or wants. Example: Rhessa is trying to stay calm while Toven is suspicious.
3. **Lore meaning:** What the scene quietly suggests about the larger plot. Example: the royal seal is older than the current story says it should be.

Children can understand the first layer, teenagers can engage with the second, and adults can notice the third without requiring separate versions of the story.

#### Dialogue length limits

- Standard comic panel: 1-2 short sentences.
- Boss dialogue: no more than 3 lines before combat resumes.
- Lore explanation: 3-5 lines, followed by gameplay or a visual clue.
- Optional lore: placed in journals, item descriptions, or repeat conversations rather than blocking progress.
- Every conversation ends with a clear action button: **Accept**, **Continue**, **Inspect**, **Follow**, **Fight**, or **Return**.

#### Age-balanced quest presentation

- The quest tracker shows one main objective in plain language: **Reach Frostwood** or **Defeat 8 Spiders**.
- The comic panel shows the dramatic version: **The forest is fleeing from something above.**
- The lore journal stores the deeper version: **Every strand of Spider Silk points away from the summit.**
- The map highlights the next location and uses a different icon for battle, NPC, collection, and story objectives.
- Quest rewards are shown before acceptance so younger players understand why they are helping.
- A short recap appears when the player returns after being away.

#### Emotional balance

The story should alternate between tension, humor, discovery, and victory:

`danger -> action -> humor -> discovery -> quiet character moment -> action -> reward`

Nib provides humor after the opening danger. Toven provides curiosity during the ruins. Varok provides moral tension during the Orc act. Skorvath provides awe and tragedy at the climax. This keeps the story accessible without making the serious plot feel childish.

#### Choice design for all ages

Choices should be easy to understand but meaningful in tone:

- **Help the Orcs** or **force them away** changes Varok's dialogue and reputation.
- **Study the crater** or **follow Rhessa** changes the player's immediate lore discovery, but never permanently blocks the main story.
- **Spare Rhessa** or **demand answers** is reserved for a future chapter; Chapter 1 should build the player's trust before challenging it.

No choice should punish a young or inexperienced player with an unwinnable story branch. Choices change relationships, dialogue, and rewards while preserving the main plot.

#### Audience acceptance test

Before calling the story complete, test the chapter with three questions for each audience:

- **Child test:** Can the player explain where to go and what monster to defeat without adult help?
- **Teen test:** Can the player identify which character they trust and explain why?
- **Adult test:** Can the player identify at least three clues that point toward the royal conspiracy?

The target is a minimum **9.7/10 experience across all three audiences**, achieved through clarity on the main path and depth in optional presentation—not by forcing every player to read every lore detail.

### Child-Friendly Game Implementation Checklist

This is the work required in the actual game to turn the script's child-friendly design into a playable experience. The story should not depend on a child reading the full design document to understand what to do.

#### 1. Quest guidance

- Show only one highlighted **MAIN QUEST** objective at a time.
- Display objectives in simple language: **Go to Frostwood**, **Defeat 8 Spiders**, or **Talk to Toven**.
- Add a large world marker above the current quest NPC.
- Add a map marker and a light trail to the next objective.
- Show distance to the next objective in the HUD.
- Automatically update the objective after a battle, conversation, or cutscene.
- Add a **What do I do?** button that repeats the current objective in one sentence.
- Prevent future-map quests from appearing on the current map.

**Relevant systems:** `QuestService.lua`, `QuestLogController.lua`, `QuestPromptController.lua`, and the map/fast-travel UI.

#### 2. NPC and quest markers

- Gold `!` means a new main quest.
- Blue `?` means a quest is ready to turn in.
- Gray `...` means an NPC has an active conversation or clue.
- Purple `!` means optional lore.
- Locked future NPCs should have no quest marker.
- The marker must remain visible from a reasonable distance.
- NPC names must use simple, readable labels above their heads.

The current quest system creates per-player markers for live quest NPCs: gold `!` for a new main quest, purple `!` for an optional quest, gray `...` for an active quest, and blue `?` for a ready-to-turn-in quest. Sealed Waygate sentries remain marker-free.

#### 3. Comic dialogue presentation

- Use one or two short sentences per panel.
- Highlight the most important word in a sentence, such as **Frostwood**, **Crater**, or **Dragon**.
- Add a voice or text sound effect for important moments without requiring voice acting.
- Include a **Continue** button that children can easily see.
- Allow the player to skip a panel but never skip required quest instructions.
- Add a **Recap** button after every major scene.
- Show the speaker's name, portrait, and emotional expression.
- Use different colors for Rhessa, Toven, Nib, Varok, and Skorvath.

**Relevant system:** `ComicDialogueController.lua`.

#### 4. Beginner combat teaching

Each monster must teach one simple mechanic through a short tutorial prompt:

| Monster | Child-friendly lesson |
|---|---|
| Slime | Move, attack, and collect loot |
| Goblin | Watch for groups and protect an NPC |
| Spider | Move away from poison and webs |
| Dire Wolf | Follow tracks and avoid the pack's surround attack |
| Skeleton | Block or dodge slow attacks |
| Skeleton Knight | Recognize an elite enemy and its warning effect |
| Orc | Read the enemy's behavior and choose dialogue before fighting |
| Wyvern | Watch the sky and move away from marked landing zones |
| Griffin | Avoid screech attacks and stay away from ledges |
| Skorvath | Combine movement, positioning, and boss warnings |

Combat prompts must appear before the mechanic is required. Never punish a new player for not knowing a mechanic that has not been explained.

#### 5. Clear combat warnings

- Use large colored circles for area attacks.
- Use a sound and screen-edge warning before a boss attack.
- Never use only color to communicate danger; pair color with an icon or pattern.
- Make ledges and safe zones visually obvious.
- Pause or slow the first special attack so the player can learn it.
- Add a retry explanation after defeat: **Move away from the blue circle before the Frost Nova lands.**

#### 6. Rewards children understand

- Show the reward icon and name before accepting a quest.
- Use a short reward explanation: **Health Potion - restores health**.
- Give a visible reward after every major battle.
- Use current item IDs from `Items.lua`; do not show placeholder items that cannot be received.
- Give beginner rewards that help with the next section, such as Health Potions before Frostwood and Warm Soup before the summit.
- Avoid rewards that require children to understand complicated crafting systems before they are introduced.

#### 7. Map and exploration support

- Mark the current act on the world map.
- Show Frosthorn locations in order: Waygate, foothills, Frostwood, ruins, war camp, cliffs, summit.
- Add a simple map legend for quest, NPC, shop, boss, and optional locations.
- Make the Cinderscar Crater visibly optional so children do not mistake it for the required final boss.
- Do not place future-map quest markers on the current map.
- Add a return marker after every major boss.

#### 8. Safe and accessible presentation

- Include text speed controls.
- Include subtitles for every voice line or sound cue.
- Add a text-size option.
- Add colorblind-friendly icons and patterns.
- Avoid flashing effects that are unnecessarily intense.
- Keep combat warnings visible on smaller screens.
- Do not require fast reading to make a story decision.
- Make dialogue choices clear and non-punishing for first-time players.

#### 9. Child-friendly quest failure

- A failed escort quest should restart nearby rather than delete progress.
- A defeated player should receive a simple explanation of what happened.
- Do not permanently lock the main story because of a wrong dialogue choice.
- Let players retry boss fights without replaying every conversation.
- Preserve collected quest items and completed objectives where appropriate.

#### 10. Playtest requirements

Before calling the child-friendly version complete, run a guided test with players who have not read the script. Ask them to complete Chapter 1 and record:

- Whether they know where to go without adult help.
- Whether they understand why the monsters are attacking.
- Whether they can identify the next quest objective.
- Whether they can explain who Rhessa and Toven are.
- Whether they understand that Skorvath is the Chapter 1 boss.
- Whether they understand that Cinderscar Crater is optional.
- Which dialogue scenes they skip.
- Where they become lost, bored, or confused.

**Child-friendly completion standard:** At least 90% of test players should complete the main objective without an adult explaining the quest, and at least 80% should correctly explain the basic Chapter 1 mystery afterward. If the test fails, simplify the affected quest or add a recap before adding more lore.

### Chapter 1 Game Implementation Alignment

This section is the canonical bridge between the comic script and the current Roblox implementation. The game code uses `src/Shared/Config/Quests.lua`, `MonsterConfig.lua`, `Items.lua`, `LootTables.lua`, and the NPC setup in `QuestService.lua` as the source of truth.

#### Live NPC quest givers

These are the NPCs currently created by the game. All Chapter 1 NPCs listed below use the shared R15 rig, quest markers, ProximityPrompt, and comic offer flow.

| Live NPC | Current quest IDs | Script responsibility |
|---|---|---|
| Commander Rhessa Kael | `VanguardAtDawn`, `B7AshenSpear`, `ReturnToValdris` | Opening assignment, warband clearance, final Chapter 1 report |
| Elder Mara | `N1MissingAtFirstLight` | Foothill village safety |
| Quartermaster Elian | `N2QuartermastersLedger` | Supply records and patrol warning |
| Sister Amara | `VillageSupplyLine`, `FieldMedicRemedy` | Refugees, healing supplies, potion crafting |
| Scout Iven | `NorthernWaygate`, `FleeingPeak`, `B3WebsAcrossRoad`, `B4RunningPack`, `WebsOfWarning`, `N9FeathersForSignal` | Waygate, displaced creatures, Spider and Dire Wolf battles, cliff signal |
| Nib Quickfinger | `N3GoblinHonestWork` | Goblin supply recovery |
| Healer Lysa | `N4AntidoteForPatrol` | Patrol antidotes |
| Hunter Corren | `N5HuntersLastTrail` | Frostwood tracking |
| Magister Toven Ashe | `ScholarInRuins`, `N6PagesBeneathSnow`, `EchoesBelow`, `B5BonesAncientSnow`, `B6KnightsSealedDoor`, `SealedChamber`, `TheBrokenOath` | Ruins, Skeletons, Skeleton Knights, royal crest |
| Smith Hadrik | `N7BrokenVanguardBlade` | Vanguard steel recovery |
| Scout Varok | `N8OrcsDebt` | Orc scout rescue and warning |
| Warden Edda | `WarbandsRefuge`, `WesternWatch`, `EasternWatch`, `WingsOverFrosthorn`, `B8TalonsFrosthorn`, `B9HighNest`, `FrostwingsDomain` | Orcs, watch zones, cliff elites, Wyverns, Griffins, Skorvath |
| Blacksmith Doran | `ForgeTheVanguard`, `SealTheVanguard` | Equipment upgrade and enhancement |
| Cook Branna | `N10MealAboveClouds` | Summit preparation |
| Veteran Dain | `N11OldSoldiersQuestion` | Lost Vanguard history |
| Priestess Selene | `N12LightForFallen` | Memorial and remembrance |

#### Live Chapter 1 quest chain

The actual configured chain is:

`VanguardAtDawn -> VillageSupplyLine -> NorthernWaygate -> N1MissingAtFirstLight -> B1SlimeSupplyRoad -> B2GoblinQuickfingers -> N2QuartermastersLedger -> FoothillDisturbance -> FieldMedicRemedy -> FleeingPeak -> B3WebsAcrossRoad -> B4RunningPack -> N4AntidoteForPatrol -> N5HuntersLastTrail -> WebsOfWarning -> N3GoblinHonestWork -> ScholarInRuins -> N6PagesBeneathSnow -> EchoesBelow -> B5BonesAncientSnow -> B6KnightsSealedDoor -> N7BrokenVanguardBlade -> SealedChamber -> TheBrokenOath -> B7AshenSpear -> N8OrcsDebt -> WarbandsRefuge -> ForgeTheVanguard -> SealTheVanguard -> N9FeathersForSignal -> N10MealAboveClouds -> B8TalonsFrosthorn -> B9HighNest -> FrostwingsDomain -> N11OldSoldiersQuestion -> N12LightForFallen -> ReturnToValdris`

`WesternWatch`, `EasternWatch`, and `WingsOverFrosthorn` are optional repeatable quests. They should appear as side quests from Warden Edda and must not block the main chain.

`CinderscarWarden` is a separate optional quest from Commander Rhessa after `ReturnToValdris`. It activates Vaelithra at the Cinderscar Crater and does not replace or extend the required Frosthorn finale.

#### Live monster and item requirements

Quest objectives must use the exact monster IDs and item IDs below. These names are case-sensitive because `QuestService` matches them directly.

| Encounter | Exact monster ID | Existing loot table | Valid item IDs for quest requirements |
|---|---|---|---|
| Slime | `Slime` | `SlimeDrops` | `SlimeGel`, `Herb`, `ArcaneDust`, `ManaPotion` |
| Goblin | `Goblin` | `GoblinDrops` | `GoblinCloth`, `Herb`, `HealthPotion`, `IronSword`, `WolfFang` |
| Spider | `Spider` | `SpiderDrops` | `SpiderSilk`, `ArcaneDust`, `AntidoteHerb`, `ManaPotion` |
| Dire Wolf | `DireWolf` | `WolfDrops` | `BeastHide`, `WolfFang`, `Herb`, `SpeedyBootsPotion` |
| Skeleton | `Skeleton` | `SkeletonDrops` | `Herb`, `IronOre`, `ArcaneDust`, `ManaPotion` |
| Skeleton Knight | `SkeletonKnight` | `SkeletonDrops` | `Herb`, `IronOre`, `ArcaneDust`, `ManaPotion` |
| Orc | `Orc` | `OrcDrops` | `IronOre`, `BeastHide`, `BearClaw`, `HealthPotion`, `WarriorSword` |
| Wyvern | `Wyvern` | `WyvernDrops` | `DrakeScale`, `CrystalShard`, `GoldenApple`, `AegisPlate` |
| Griffin | `Griffin` | `GriffinDrops` | `PhoenixFeather`, `MagicCore`, `Hero's Feast`, `Windpiercer` |
| Skorvath | `Skorvath` | `DragonDrops` | `DragonHorn`, `DragonTear`, `StarFragment`, `Starcaller`, `DragonLance` |

#### Requirements corrected in the script

The following story terms are now treated as narrative descriptions, not implementation item IDs:

- “Frost-antidote sacs” becomes `AntidoteHerb` from Spider drops.
- “Wolf-fang charm” becomes `WolfFang` as a material or `SpeedyBootsPotion` as the usable reward.
- “Wyvern feathers” becomes `DrakeScale` or `CrystalShard`; Wyverns do not currently drop a feather item.
- “Griffin eggshells” becomes `PhoenixFeather`; no eggshell item exists.
- “Knight blade” and “enchanted armor pieces” become `IronOre` and `ArcaneDust` from `SkeletonDrops`.
- “Vanguard supply bundles,” “old nameplates,” “journal pages,” and “memorial lamps” are world objectives, not inventory items. They must be implemented as quest objects or reach/interact zones before being used as item requirements.

#### World and zone requirements

The current quest service exposes these relevant objective zones: `FrosthornWaygate`, `SealedChamberDoor`, `WesternWatch`, and `EasternWatch`. The comic script may describe foothills, Frostwood, the upper slope, and the summit as locations, but a quest should use one of those exact zone IDs—or a new zone must be added to `QuestService:CreateReachZone`.

#### Implementation warning

The `GriffinDrops` table and quest rewards now use the item-config ID `HerosFeast`; the display name remains `Hero's Feast`.

### Chapter 1 Battle Quest Expansion

These are the integrated main-story combat beats. Every major monster battle has a clear quest name, objective, reward, and completion dialogue. B1-B9 are registered in `Quests.lua` and appear in the in-game QuestLog; B10 is represented by the existing `FrostwingsDomain` quest so the final boss has one canonical objective. After each NPC's one-time introduction, the next non-repeatable story quest is presented through the same comic-style offer card before acceptance.

| Battle quest | Monster encounter | Location | Quest objective | Completion point |
|---|---|---|---|---|
| **B1 - Slime on the Supply Road** | Slime | Foothill supply camp | Defeat the slimes and recover the camp's supply ledger | After the final slime is defeated |
| **B2 - Goblin Quickfingers** | Goblin | Abandoned supply camp | Stop the goblin raid and rescue Nib Quickfinger | After Nib leaves the wagon |
| **B3 - Webs Across the Road** | Spider | Frostwood | Destroy the spider nests and collect antidote sacs | After the final nest is cleared |
| **B4 - The Running Pack** | Dire Wolf | Frostwood clearing | Drive the dire wolves away from the road and follow their tracks | When the pack retreats uphill |
| **B5 - Bones in Ancient Snow** | Skeleton | Ancient ruins | Defeat the wandering Skeletons and protect Toven's excavation | After the basic Skeleton wave ends |
| **B6 - Knights of the Sealed Door** | Skeleton Knight | Ancient ruins | Defeat the Skeleton Knights and keep them away from Toven | After all Skeleton Knights fall |
| **B7 - The Ashen Spear** | Orc | Upper-slope war camp | Clear the barricade or force the Ashen Spear warband to surrender | When Varok yields or the camp is cleared |
| **B8 - Talons Over Frosthorn** | Wyvern | Upper cliffs | Defeat the hostile wyverns and recover their stolen Vanguard supplies | After the wyvern nest is cleared |
| **B9 - The High Nest** | Griffin | Upper cliffs | Defeat or calm the griffins and retrieve the old supply crate | When the crate is recovered |
| **B10 - The Frostwing's Challenge** | Dragon: Skorvath | Frosthorn summit | Defeat Skorvath and survive the summit's Frost Nova | When `FrostwingsDomain` completes |

**Battle quest order:** `B1 -> B2 -> B3 -> B4 -> B5 -> B6 -> B7 -> B8/B9 -> B10`

#### B1 - Slime on the Supply Road

**Quest giver:** Commander Rhessa

**Trigger dialogue:**

**RHESSA:** The camp is crawling with slimes. They are not dangerous alone, but they are blocking the supply road.

**RHESSA:** Clear them out before they spread into the village wells.

**QUEST ACCEPTED:** Slime on the Supply Road

**Objectives:** Defeat 8 Slimes; recover the supply ledger; report to Rhessa.

**Completion dialogue:**

**RHESSA:** Eight slimes and one ruined camp. I will call that a victory until the quartermaster sees the damage.

**RHESSA:** The ledger is covered in slime, but the final entry is clear: the goblins came from the north.

**QUEST COMPLETE:** Slime on the Supply Road

**Reward suggestion:** Vanguard field rations, basic weapon upgrade, experience.

#### B2 - Goblin Quickfingers

**Quest giver:** Nib Quickfinger, after the player finds him under the wagon.

**Trigger dialogue:**

**NIB:** I am not a raider. I am a visitor who was aggressively separated from his belongings.

**NIB:** Help me recover my stolen pack and I will tell you exactly what drove us off the mountain.

**QUEST ACCEPTED:** Goblin Quickfingers

**Objectives:** Defeat the goblin raiders; recover Nib's pack; escort Nib to the southern road.

**Completion dialogue:**

**NIB:** My pack! My beautiful, slightly damaged pack!

**NIB:** The white fire came from the summit. It chased every goblin, wolf, and bird downhill.

**NIB:** If you are going up there, bring a rope. A very long rope.

**QUEST COMPLETE:** Goblin Quickfingers

**Reward suggestion:** Nib's lucky coin, small bag upgrade, experience.

#### B3 - Webs Across the Road

**Quest giver:** Rhessa, at the Frostwood entrance.

**Trigger dialogue:**

**RHESSA:** The webs are spreading across the road. Burn the nests before the poison reaches the patrol route.

**QUEST ACCEPTED:** Webs Across the Road

**Objectives:** Defeat 10 Spiders; destroy 5 spider nests; collect 3 frost-antidote sacs.

**Completion dialogue:**

**RHESSA:** Good. The road is open, and the antidote sacs may save the next patrol.

**RHESSA:** The spiders were not hunting outward. They were fleeing inward.

**QUEST COMPLETE:** Webs Across the Road

**Reward suggestion:** Frost-antidote potion, poison resistance charm, experience.

#### B4 - The Running Pack

**Quest giver:** Rhessa, after the spider battle.

**Trigger dialogue:**

**RHESSA:** The dire wolves are circling the clearing. Drive them away from the road, but do not chase them blindly.

**RHESSA:** Watch where they run. Their tracks may lead us to the cause of the disturbance.

**QUEST ACCEPTED:** The Running Pack

**Objectives:** Defeat or drive away 6 Dire Wolves; mark the alpha's tracks; follow the pack to the ancient ruins.

**Completion dialogue:**

**RHESSA:** The pack is retreating uphill. Even the alpha refuses to face whatever is above.

**RHESSA:** We follow the tracks, but we do not lose formation.

**QUEST COMPLETE:** The Running Pack

**Reward suggestion:** Wolf-fang charm, movement-speed food, experience.

#### B5 - Bones in Ancient Snow

**Quest giver:** Magister Toven, at the ancient ruins.

**Trigger dialogue:**

**TOVEN:** The Skeletons are not guarding the door. They are wandering out from it.

**TOVEN:** Defeat them before they surround the excavation.

**QUEST ACCEPTED:** Bones in Ancient Snow

**Objectives:** Defeat 12 Skeletons; protect 3 excavation markers; recover the cracked rune stone.

**Completion dialogue:**

**TOVEN:** You protected the markers! Excellent. I can now prove that this ruin predates Valdris.

**TOVEN:** The cracked rune stone also confirms that something was sealed here.

**QUEST COMPLETE:** Bones in Ancient Snow

**Reward suggestion:** Ancient rune fragment, minor armor upgrade, experience.

#### B6 - Knights of the Sealed Door

**Quest giver:** Toven, after the basic Skeleton wave.

**Trigger dialogue:**

**TOVEN:** The ordinary Skeletons were only the lock's first defense.

**TOVEN:** Those armored figures are the real guardians. Keep them away from the door and away from me.

**QUEST ACCEPTED:** Knights of the Sealed Door

**Objectives:** Defeat 3 Skeleton Knights; interrupt their seal-breaking attack; inspect the fallen knight's shield.

**Completion dialogue:**

**TOVEN:** The Knights are down, but the door remains sealed.

**TOVEN:** Their shield bears a royal symbol that should not exist in these ruins.

**QUEST COMPLETE:** Knights of the Sealed Door

**Reward suggestion:** Knight's shield fragment, defensive skill scroll, experience.

#### B7 - The Ashen Spear

**Quest giver:** Rhessa, at the orc barricade.

**Trigger dialogue:**

**RHESSA:** The Ashen Spear warband blocks the road. Give them one chance to lower their weapons.

**RHESSA:** If they refuse, clear the barricade.

**QUEST ACCEPTED:** The Ashen Spear

**Objectives:** Speak with Scout Varok; destroy 4 barricades; defeat or disarm the orc defenders; recover the warband banner.

**Completion dialogue:**

**VAROK:** You fight like someone who has not yet learned what fear is.

**VAROK:** Take the banner. We will not use it again on this mountain.

**RHESSA:** The road is open. We continue to the cliffs.

**QUEST COMPLETE:** The Ashen Spear

**Reward suggestion:** Ashen Spear banner, orc weapon component, experience.

#### B8 - Talons Over Frosthorn

**Quest giver:** Rhessa, at the upper cliffs.

**Trigger dialogue:**

**RHESSA:** The wyverns have torn through the old supply lines. Bring down the hostile ones and recover whatever they carried away.

**QUEST ACCEPTED:** Talons Over Frosthorn

**Objectives:** Defeat 5 Wyverns; recover 3 Vanguard supply bundles; avoid the cliff edges during the aerial assault.

**Completion dialogue:**

**RHESSA:** The supplies are damaged, but usable. The Vanguard will remember this recovery.

**TOVEN:** The wyverns were not nesting here last season.

**RHESSA:** Then we have another sign that the summit is changing.

**QUEST COMPLETE:** Talons Over Frosthorn

**Reward suggestion:** Wyvern-scale armor piece, aerial-defense potion, experience.

#### B9 - The High Nest

**Quest giver:** Toven, beside the griffin nesting ledge.

**Trigger dialogue:**

**TOVEN:** The griffins have a Vanguard supply crate in their nest.

**TOVEN:** We can fight them, or we can approach carefully and leave the nestlings unharmed.

**QUEST ACCEPTED:** The High Nest

**Objectives:** Reach the griffin nest; defeat or calm the adult griffins; retrieve the old supply crate.

**Completion dialogue:**

**TOVEN:** The crate is older than I expected. These supplies were placed here before the crater impact.

**TOVEN:** Someone was preparing for a battle on this mountain long before today's disturbance.

**QUEST COMPLETE:** The High Nest

**Reward suggestion:** Griffin-feather accessory, old Vanguard map, experience.

#### B10 - The Frostwing's Challenge

**Quest giver:** Rhessa, at the summit entrance.

**Trigger dialogue:**

**RHESSA:** We have crossed the mountain. We have cleared its camps. Now we face the thing that drove everything else downhill.

**RHESSA:** Stay together. Watch the ledges. Do not let the dragon separate us.

**QUEST ACCEPTED:** The Frostwing's Challenge

**Objectives:** Defeat Skorvath; survive the aerial bombardment; survive Frost Nova; search the dragon's hoard.

**Completion dialogue:**

**SKORVATH:** You have won a moment, not a victory.

**TOVEN:** The dragon's final warning is connected to the crater.

**RHESSA:** Search the hoard. We leave before the mountain changes its mind.

**QUEST COMPLETE:** The Frostwing's Challenge

**Reward suggestion:** Frostwing weapon, Skorvath's scale, summit access, experience.

### Chapter 1 NPC Quest Board

The following NPC quests are integrated main-story content. They expand the main quest chain through current-map NPCs and exact quest configs. NPCs display a gold quest icon when they have a new quest, a gray icon when a quest is in progress, and a blue icon when a quest is ready to turn in.

**Status:** N1-N12 are registered quests with current-map NPCs, exact item/monster requirements, reach zones where needed, rewards, and comic offer flow.

| Quest | NPC quest giver | NPC location | Quest type | Unlock condition |
|---|---|---|---|---|
| **N1 - Missing at First Light** | Elder Mara | Frosthorn foothill village | Rescue | Available after reaching the northern Waygate |
| **N2 - The Quartermaster's Ledger** | Quartermaster Elian | Abandoned supply camp | Collection | Available after clearing the Slimes |
| **N3 - A Goblin's Honest Work** | Nib Quickfinger | Southern road camp | Delivery and recovery | Complete B2 - Goblin Quickfingers |
| **N4 - Antidote for the Patrol** | Healer Lysa | Frostwood field tent | Collection | Discover the Spider nests |
| **N5 - The Hunter's Last Trail** | Hunter Corren | Frostwood watchpost | Tracking | Complete B4 - The Running Pack |
| **N6 - Pages Beneath the Snow** | Magister Toven Ashe | Ancient ruins | Exploration | Meet Toven at the ruins |
| **N7 - The Broken Vanguard Blade** | Smith Hadrik | Upper-slope repair camp | Recovery | Defeat the Skeleton Knights |
| **N8 - An Orc's Debt** | Scout Varok | Ashen Spear camp | Choice and diplomacy | Complete B7 - The Ashen Spear |
| **N9 - Feathers for the Signal** | Scout Iven (falconer duty) | Upper cliffs | Collection | Complete `SealTheVanguard` |
| **N10 - A Meal Above the Clouds** | Cook Branna | Upper-cliff camp | Hunting and cooking | Reach the upper cliffs |
| **N11 - The Old Soldier's Question** | Veteran Dain | Frosthorn Waygate | Lore and investigation | Recover the old Vanguard armor |
| **N12 - A Light for the Fallen** | Priestess Selene | Frosthorn memorial shrine | Ritual and remembrance | Defeat Skorvath |

These NPC quests give the chapter more activity without changing the main plot. Some choices also change later dialogue. For example, helping Varok peacefully causes him to mention the player if they meet him again in a later chapter.

#### N1 - Missing at First Light

**NPC:** Elder Mara, foothill village square

**Quest start dialogue:**

**MARA:** Vanguard! Please, my grandson Talen ran toward the old watchtower when the creatures came down from the mountain.

**MARA:** He is brave, but bravery does not stop a slime from swallowing a boot.

**QUEST ACCEPTED:** Missing at First Light

**Objectives:** Search the watchtower; defeat the creatures around it; rescue Talen; escort him back to Mara.

**Rescue dialogue:**

**TALEN:** I was not hiding. I was conducting a very quiet defense.

**PLAYER RESPONSE:** Ask what he saw / tell him to follow.

**TALEN:** Something white flew over the peak. The animals ran before it even arrived.

**Turn-in dialogue:**

**MARA:** Talen! Thank the old gods you are safe.

**TALEN:** I helped the Vanguard.

**MARA:** You helped by staying alive. That is enough for one day.

**QUEST COMPLETE:** Missing at First Light

**Reward:** Village bread, minor healing potion, experience.

#### N2 - The Quartermaster's Ledger

**NPC:** Quartermaster Elian, abandoned supply camp

**Quest start dialogue:**

**ELIAN:** You cleared the slimes, but the camp ledger is still missing.

**ELIAN:** Without it, I cannot tell which villages are short on food, arrows, or medicine.

**QUEST ACCEPTED:** The Quartermaster's Ledger

**Objectives:** Search 5 broken crates; recover the ledger; mark the three supply wagons that can still be salvaged.

**Turn-in dialogue:**

**ELIAN:** Most of these numbers are ruined, but I can read the important part.

**ELIAN:** The northern patrol stopped sending reports two days before the raids began.

**ELIAN:** That is not a supply problem. That is a warning.

**QUEST COMPLETE:** The Quartermaster's Ledger

**Reward:** Ammunition or spell supplies, Vanguard ration bundle, experience.

#### N3 - A Goblin's Honest Work

**NPC:** Nib Quickfinger, southern road camp

**Quest start dialogue:**

**NIB:** I have a business opportunity for a brave and trusting person.

**PLAYER RESPONSE:** That sounds dangerous. / What kind of business?

**NIB:** My people left three crates in the Frostwood. Technically, the crates belong to a caravan that technically belongs to someone else.

**NIB:** I want them returned to their rightful temporary owner.

**QUEST ACCEPTED:** A Goblin's Honest Work

**Objectives:** Recover 3 goblin supply crates; defeat the creatures guarding them; deliver the crates to Nib.

**Turn-in dialogue:**

**NIB:** Wonderful! You have saved my reputation and possibly my knees.

**NIB:** Take this compass. It points toward valuable things.

**NIB:** It also points toward danger, but that is usually where valuable things are.

**QUEST COMPLETE:** A Goblin's Honest Work

**Reward:** Nib's compass, coin pouch, experience.

#### N4 - Antidote for the Patrol

**NPC:** Healer Lysa, Frostwood field tent

**Quest start dialogue:**

**LYSA:** The spider venom is slowing the patrol's breathing.

**LYSA:** I need frost-antidote sacs before the next wave reaches this tent.

**QUEST ACCEPTED:** Antidote for the Patrol

**Objectives:** Collect 6 frost-antidote sacs; protect Lysa's field tent; deliver the sacs to her.

**Turn-in dialogue:**

**LYSA:** These will keep the patrol alive through the night.

**LYSA:** The poison is unusually strong. Whatever is driving the spiders has changed them.

**QUEST COMPLETE:** Antidote for the Patrol

**Reward:** 3 frost antidotes, poison resistance buff, experience.

#### N5 - The Hunter's Last Trail

**NPC:** Hunter Corren, Frostwood watchpost

**Quest start dialogue:**

**CORREN:** My hunting partner disappeared while tracking the wolves.

**CORREN:** Find his traps. If the traps are untouched, he is alive. If they are broken...

**CORREN:** Bring me his bow.

**QUEST ACCEPTED:** The Hunter's Last Trail

**Objectives:** Find 4 hunting traps; follow the dire-wolf trail; rescue or recover Corren's partner; return the hunting bow.

**Turn-in dialogue if rescued:**

**CORREN:** You found him alive. I owe you more than coin.

**CORREN:** The wolves were not hunting. They were running from the summit.

**Turn-in dialogue if the hunter is found dead:**

**CORREN:** Then his bow returns home. Thank you for bringing me the truth.

**QUEST COMPLETE:** The Hunter's Last Trail

**Reward:** Hunter's cloak, tracking skill bonus, experience.

#### N6 - Pages Beneath the Snow

**NPC:** Magister Toven Ashe, ancient ruins

**Quest start dialogue:**

**TOVEN:** I need three pages from my field journal. The wind carried them beneath the ruins.

**TOVEN:** Do not read them. They contain unfinished theories and one excellent insult aimed at the royal archive.

**QUEST ACCEPTED:** Pages Beneath the Snow

**Objectives:** Recover 3 journal pages; examine the broken statue; return the pages to Toven.

**Turn-in dialogue:**

**TOVEN:** Page one: binding symbols. Page two: a missing royal expedition. Page three...

**TOVEN:** Someone scratched out the name of the expedition leader.

**PLAYER RESPONSE:** Ask who erased it.

**TOVEN:** That is the question I am trying not to ask too loudly.

**QUEST COMPLETE:** Pages Beneath the Snow

**Reward:** Ancient rune scroll, lore entry, experience.

#### N7 - The Broken Vanguard Blade

**NPC:** Smith Hadrik, upper-slope repair camp

**Quest start dialogue:**

**HADRIK:** The Skeleton Knights carry old Vanguard steel in their hands.

**HADRIK:** Bring me a broken Knight blade. I can melt it down and make weapons for the living.

**QUEST ACCEPTED:** The Broken Vanguard Blade

**Objectives:** Recover 2 Skeleton Knight blades; collect 5 pieces of enchanted armor; deliver the materials to Hadrik.

**Turn-in dialogue:**

**HADRIK:** This metal remembers a battle. Steel should not remember, but this steel does.

**HADRIK:** I will forge it into something that protects people instead of guarding a locked door.

**QUEST COMPLETE:** The Broken Vanguard Blade

**Reward:** Reforged Vanguard weapon component, armor repair, experience.

#### N8 - An Orc's Debt

**NPC:** Scout Varok, Ashen Spear camp

**Quest start dialogue:**

**VAROK:** You spared my people or defeated them without cruelty. Either way, you have earned a debt.

**VAROK:** Three of our scouts are trapped below the camp. Help them, and the Ashen Spear will leave your road.

**QUEST ACCEPTED:** An Orc's Debt

**Objectives:** Find the 3 missing orc scouts; defeat the creatures surrounding them; choose whether to give Varok the recovered Vanguard supplies.

**Turn-in dialogue:**

**VAROK:** You returned our scouts. The supplies may remain with your people.

**PLAYER RESPONSE:** Return the supplies / keep the supplies.

**VAROK:** Then remember this: the Frostwing is not the oldest thing beneath the mountain.

**QUEST COMPLETE:** An Orc's Debt

**Reward:** Orcish war token, reputation with the Ashen Spear, experience.

#### N9 - Feathers for the Signal

**NPC:** Falconer Iven, upper cliffs

**Quest start dialogue:**

**IVEN:** The signal hawks will not fly while the wyverns circle overhead.

**IVEN:** Bring me five unbroken wyvern feathers. I can use them to make a signal arrow that reaches the valley.

**QUEST ACCEPTED:** Feathers for the Signal

**Objectives:** Collect 5 wyvern feathers; light the cliff signal brazier; send the emergency signal to Valdris.

**Turn-in dialogue:**

**IVEN:** The signal is away. Valdris knows the northern road is in danger.

**IVEN:** If the sky turns red, do not wait for another signal. Run.

**QUEST COMPLETE:** Feathers for the Signal

**Reward:** Signal flare, ranged damage buff, experience.

#### N10 - A Meal Above the Clouds

**NPC:** Cook Branna, upper-cliff camp

**Quest start dialogue:**

**BRANNA:** Soldiers fight better when they eat better.

**BRANNA:** Bring me three griffin eggshells and a bundle of frost herbs. I will make a stew strong enough to frighten the cold.

**QUEST ACCEPTED:** A Meal Above the Clouds

**Objectives:** Collect 3 griffin eggshells; gather 5 frost herbs; deliver the ingredients to Branna.

**Turn-in dialogue:**

**BRANNA:** There. Eat this before the summit.

**BRANNA:** If it does not warm you, it will at least make you too busy chewing to panic.

**QUEST COMPLETE:** A Meal Above the Clouds

**Reward:** Frosthorn stew, temporary health and stamina bonus, experience.

#### N11 - The Old Soldier's Question

**NPC:** Veteran Dain, northern Waygate

**Quest start dialogue:**

**DAIN:** I saw the old armor you carried down from the summit.

**DAIN:** My unit wore that mark twenty-seven years ago. Find the names of the fallen and I will tell you what the commanders refused to say.

**QUEST ACCEPTED:** The Old Soldier's Question

**Objectives:** Find 4 old Vanguard nameplates; place them at the Waygate memorial; return to Dain.

**Turn-in dialogue:**

**DAIN:** These soldiers were not lost in a patrol. They were sent toward the crater.

**DAIN:** The report says they never returned. It does not say why they were sent.

**QUEST COMPLETE:** The Old Soldier's Question

**Reward:** Veteran's insignia, hidden lore entry, experience.

#### N12 - A Light for the Fallen

**NPC:** Priestess Selene, Frosthorn memorial shrine

**Quest start dialogue:**

**SELENE:** The mountain has taken many names from the kingdom.

**SELENE:** After the dragon falls, light the memorial lamps so the dead are not forgotten.

**QUEST ACCEPTED:** A Light for the Fallen

**Objectives:** Light 7 memorial lamps; place Skorvath's scale at the shrine; speak the names of the fallen.

**Turn-in dialogue:**

**SELENE:** The lamps are lit. Even a dragon's death can become a warning instead of a legend.

**SELENE:** May the fallen guide your steps when the next mountain calls.

**QUEST COMPLETE:** A Light for the Fallen

**Reward:** Memorial blessing, cold resistance buff, experience.

### Quest 1.1 - A Bell in the North

**Trigger:** The player completes Vanguard induction and approaches Commander Rhessa in the courtyard.

**RHESSA:** Recruit. Step forward.

**PLAYER RESPONSE:** Salute / nod / step forward.

**RHESSA:** Good. You know how to follow an order. That will keep you alive longer than bravery will.

**RHESSA:** What do you know about Frosthorn Peak?

**PLAYER RESPONSE:** It is the northern mountain. / It is dangerous. / I do not know.

**RHESSA:** All three answers are correct.

**RHESSA:** Three nights ago, the northern villages reported raids. Slimes crawled out of the foothills. Goblins hit the supply road. Wolves abandoned their hunting grounds.

**RHESSA:** The attacks are not random. Every creature is moving away from the summit.

**PLAYER RESPONSE:** What is driving them? / How many soldiers are missing? / Why send me?

**RHESSA:** That is what you are going to find out.

**RHESSA:** The northern Waygate is sealed. If you can reach it, investigate the mountain, and reactivate it, we can send reinforcements without losing a week on the road.

**PLAYER RESPONSE:** And if I cannot?

**RHESSA:** Then come back alive and tell me why.

**RHESSA:** One more thing. If you find civilians, bring them home. If you find Vanguard soldiers, bring them home. If you find something that should not be alive...

**RHESSA:** Do not try to be a hero. Call for help.

**PLAYER RESPONSE:** Accept the assignment.

**RHESSA:** Take the northern road. I will meet you at the Waygate.

**QUEST ACCEPTED:** A Bell in the North

### Scene 1.1 - The Northern Waygate

**Trigger:** The player reaches the frozen Waygate at the base of Frosthorn Peak.

**[The Waygate is covered in ice. Its runes flicker once, then go dark.]**

**RHESSA:** You made good time.

**PLAYER RESPONSE:** The road was attacked. / I found tracks. / Where are the villagers?

**RHESSA:** The survivors fled south. The ones who could run, at least.

**RHESSA:** Look at the snow around the gate.

**PLAYER RESPONSE:** Examine the tracks.

**RHESSA:** Slime trails. Goblin boots. Wolf prints. All pointing downhill.

**RHESSA:** Something is forcing the mountain's creatures out of their territory.

**PLAYER RESPONSE:** Could it be an army?

**RHESSA:** An army leaves banners, campfires, and dead bodies.

**RHESSA:** This leaves silence.

**[A distant roar rolls down from the summit. Snow falls from the cliffs.]**

**PLAYER RESPONSE:** Draw weapon / look toward the summit.

**RHESSA:** That was not thunder.

**RHESSA:** We begin at the foothills. Clear the abandoned supply camp and find anyone still hiding there.

**QUEST OBJECTIVE:** Reach the northern Waygate and begin the Frosthorn investigation.

**QUEST COMPLETE:** A Bell in the North

**QUEST ACCEPTED:** Mud and Mucus

**QUEST OBJECTIVE:** Clear the abandoned foothill camp and rescue anyone hiding there.

### Quest 1.2 - Mud and Mucus

**Trigger:** The player enters the abandoned supply camp.

**[Slimes move between overturned crates. A broken lantern swings from a post.]**

**RHESSA:** There. The camp was abandoned in a hurry.

**PLAYER RESPONSE:** Why are the slimes here?

**RHESSA:** They usually stay near the wet caves below the tree line.

**RHESSA:** If they are this far down the road, something pushed them out too.

**RHESSA:** Clear the camp. Search the crates after.

**[Combat begins. After the last slime is defeated, a goblin shouts from under a wagon.]**

**GOBLIN:** Do not hit me! I am already having a terrible morning!

**PLAYER RESPONSE:** Pull the goblin out / point weapon at the wagon.

**GOBLIN:** Slowly! Slowly is a very respectful speed!

**[The player pulls the goblin from hiding.]

**RHESSA:** Name.

**GOBLIN:** Nib. Nib Quickfinger. Honest trader, occasional fence, never a murderer before breakfast.

**RHESSA:** Why were you in the camp?

**NIB:** We came for supplies. Then the mountain started screaming.

**RHESSA:** Mountains do not scream.

**NIB:** This one does! White fire came down from the summit. It chased our whole camp into the trees.

**PLAYER RESPONSE:** What did you see in the fire? / How many goblins survived?

**NIB:** Wings. Big wings. Bigger than a watchtower.

**NIB:** The snow turned blue wherever it landed.

**RHESSA:** You are certain it came from the summit?

**NIB:** I am certain because I was looking at it while running in the opposite direction.

**RHESSA:** Take this man to the southern road.

**NIB:** Wait! You are going up there?

**RHESSA:** We are.

**NIB:** Then take a piece of advice from Nib Quickfinger: do not wake anything.

**RHESSA:** Keep moving, Nib.

**NIB:** That was my plan from the beginning!

**QUEST UPDATE:** Rescue Nib and investigate the Frostwood.

### Quest 1.3 - Webs in the Frostwood

**Trigger:** The player and Rhessa enter the Frostwood.

**[Spider webs cover the trees. A dead wolf is wrapped in silk.]

**RHESSA:** Stay close. The forest is too quiet.

**PLAYER RESPONSE:** Point at the webs / inspect the wolf.

**RHESSA:** Spider nests. Fresh.

**RHESSA:** The spiders have moved closer to the road.

**PLAYER RESPONSE:** Are they attacking because of the dragon?

**RHESSA:** We do not know that there is a dragon.

**PLAYER RESPONSE:** Nib saw one.

**RHESSA:** Nib saw something with wings while running for his life.

**RHESSA:** Fear makes poor witnesses.

**[A spider drops from a branch. More nests begin to move.]**

**RHESSA:** Enough discussion. Cut through the nests.

**[Combat begins. After the spiders are defeated, a dire wolf pack appears at the edge of the clearing.]**

**QUEST OBJECTIVES:** Defeat 7 Spiders in the east and west forest clearings; defeat 7 Dire Wolves in the north deep forest. The north deep forest is a Dire Wolf route, not the Spider route.

**RHESSA:** Wolves.

**PLAYER RESPONSE:** Ready weapon / wait.

**[The wolves growl, then turn and run uphill.]**

**RHESSA:** That is the second time today an animal has chosen to flee from us.

**PLAYER RESPONSE:** Follow them / examine their tracks.

**RHESSA:** No. We follow the trail only as far as the ruins.

**RHESSA:** Whatever is above is driving predators toward the lower slopes. We do not know what happens when they have nowhere left to run.

**QUEST COMPLETE:** Webs in the Frostwood

### Quest 1.4 - The Old Stone Door

**Trigger:** The player reaches the ancient ruins.

**[Magister Toven Ashe is kneeling beside a half-buried statue. He has three open books, two broken instruments, and one very cold cup of tea.]**

**TOVEN:** Ah. Vanguard boots.

**TOVEN:** Loud, polished, and usually followed by explosions.

**RHESSA:** Magister Ashe.

**TOVEN:** Commander Kael. Still escorting young soldiers into dangerous places?

**RHESSA:** Still digging where no one asked you to dig?

**TOVEN:** Someone has to preserve history.

**RHESSA:** History is not our concern. The summit is.

**TOVEN:** The summit is precisely why history is our concern.

**PLAYER RESPONSE:** What are you studying? / Why are you here alone?

**TOVEN:** These ruins predate Valdris. The stones were placed by a people who understood binding magic better than our court magisters do.

**TOVEN:** Something was sealed here long before the first Varn king wore a crown.

**[The black stone door behind Toven groans. Skeletons climb from the snow.]**

**TOVEN:** Ah. There is the explosion I was promised.

**RHESSA:** Recruit, protect the Magister.

**TOVEN:** And the notes! Protect the notes!

**RHESSA:** Your notes can wait.

**TOVEN:** They have waited three hundred years. They are not good at it.

**[Combat begins. Skeleton Knights emerge after the basic skeletons are defeated.]**

**RHESSA:** Knights! Their armor is enchanted!

**TOVEN:** Aim for the joints! Skeletons have very few weaknesses, but they have many joints!

**[After combat, Toven examines a fallen shield.]**

**TOVEN:** There. Do you see this mark?

**PLAYER RESPONSE:** Examine the shield.

**TOVEN:** It is a royal sigil, but not the current crest. This version was abandoned before the crater appeared.

**RHESSA:** Then it is irrelevant.

**TOVEN:** Commander, you did not even look at it.

**RHESSA:** I know what I am looking at.

**TOVEN:** That is a very different statement from knowing what it means.

**[The sealed door flashes with pale light.]**

**PLAYER RESPONSE:** Touch the door / step back.

**TOVEN:** Do not touch it!

**RHESSA:** Why not?

**TOVEN:** Because I have no idea what it does.

**RHESSA:** At least you are honest.

**TOVEN:** It is a rare quality among scholars.

**RHESSA:** We are moving. The door stays closed.

**TOVEN:** For now.

**QUEST UPDATE:** The ruins are older than Valdris. The sealed chamber cannot be opened yet.

**QUEST COMPLETE:** The Old Stone Door

**QUEST ACCEPTED:** The War Camp

**QUEST OBJECTIVE:** Clear the upper-slope barricade and determine why the orc warband is hiding on Frosthorn.

### Quest 1.5 - The War Camp

**Trigger:** The player reaches the upper slope and sees the orc barricades.

**[Orcs aim bows from behind a wall of timber and ice. They look exhausted, with frost on their armor.]**

**ORC SCOUT:** Stop! We do not want a fight!

**RHESSA:** You built a wall across a royal road.

**ORC SCOUT:** Because your royal road leads straight into death!

**RHESSA:** Identify yourself.

**ORC SCOUT:** Scout Varok of the Ashen Spear warband.

**RHESSA:** Your people raided the foothills.

**VAROK:** We took food. We did not burn the villages.

**RHESSA:** You expect me to believe that?

**VAROK:** I expect you to look at my camp. Does this look like a conquering army?

**[The player sees wounded orcs, empty food sacks, and weapons abandoned beside the fire.]**

**VAROK:** We came up the mountain to escape the thing at the summit.

**PLAYER RESPONSE:** What thing? / How long has it been there?

**VAROK:** A dragon. An old one. Its scales shine like frozen iron.

**VAROK:** It screams when the moon rises. Afterward, the peak shakes and the snow falls upward.

**TOVEN:** That sounds like a territorial response.

**VAROK:** It sounds like death.

**RHESSA:** Lower your weapons and move away from the road.

**VAROK:** You are going to the summit?

**RHESSA:** Yes.

**VAROK:** Then you are either brave or too young to understand the question.

**RHESSA:** Recruit, clear the barricade.

**VAROK:** Commander, wait!

**RHESSA:** You were given an opportunity to stand aside.

**VAROK:** We are not your enemy!

**RHESSA:** Then survive long enough to prove it.

**[Combat begins. The player may defeat the warband or force the surrender objective, depending on the quest design.]**

**VAROK:** Enough! Enough! We yield!

**PLAYER RESPONSE:** Lower weapon / continue attacking.

**RHESSA:** Stand down.

**[If the player spared the warband, Varok drops his weapon. If not, Rhessa finds his insignia among the defeated.]**

**VAROK:** You will learn what we learned.

**VAROK:** The sky belongs to the Frostwing.

**TOVEN:** Frostwing. Is that a name or a title?

**VAROK:** It is the last sound many warriors ever hear.

**RHESSA:** We continue upward.

**QUEST COMPLETE:** The War Camp

### Quest 1.6 - Wings Over the Cliffs

**Trigger:** The player reaches the upper cliffs.

**[Wyverns and griffins circle narrow ledges. Their shadows pass over the player.]**

**RHESSA:** The summit is close.

**PLAYER RESPONSE:** The creatures are guarding it.

**RHESSA:** Or fleeing from it. At this height, the difference is difficult to see.

**TOVEN:** The nests contain supplies. Ancient hunters used these cliffs as a staging point.

**RHESSA:** We have enough supplies.

**TOVEN:** We have enough supplies for a careful retreat. I recommend supplies for an angry dragon.

**PLAYER CHOICE:**

- **Take the direct route:** Continue immediately to the summit.
- **Clear the high nests:** Defeat the aerial elites and collect optional gear.

**If the player takes the direct route:**

**RHESSA:** Stay low and keep moving. Do not give the creatures a clean angle.

**TOVEN:** Excellent advice. I will be following it from behind you.

**If the player clears the high nests:**

**TOVEN:** That griffin has a Vanguard supply strap around its leg.

**RHESSA:** Then recover it without hurting the animal.

**TOVEN:** I was planning to recover it after hurting the animal slightly.

**RHESSA:** Try the first plan.

**[After the optional encounters, the player finds an old supply crate.]**

**TOVEN:** These supplies are also decades old.

**RHESSA:** Leave them.

**TOVEN:** You said we needed supplies.

**RHESSA:** I changed my mind.

**PLAYER RESPONSE:** Look toward the summit.

**[The summit sky turns white. A low growl vibrates through the cliffs.]**

**RHESSA:** Enough. We finish this now.

**QUEST OBJECTIVES:** Cross the upper cliffs; defeat or avoid the wyverns and griffins; reach the Frosthorn summit.

**[When the player reaches the summit path, the objective completes.]**

**RHESSA:** The summit is ahead. Whatever is waiting for us has heard us coming.

**QUEST COMPLETE:** Wings Over the Cliffs

### Quest 1.7 - Skorvath, the Frostwing

**Trigger:** The player steps onto the summit arena.

**QUEST OBJECTIVE:** Defeat Skorvath, survive the summit, and discover what is disturbing Frosthorn Peak.

**[The summit is a ring of ice above the clouds. A colossal dragon lies atop a frozen hoard. As the player approaches, Skorvath opens one eye.]**

**SKORVATH:** More little sparks.

**RHESSA:** Vanguard! Form up!

**SKORVATH:** You climb into my winter wearing the colors of thieves.

**PLAYER RESPONSE:** Who are you? / We came for the villages. / Draw weapon.

**SKORVATH:** I am Skorvath, last claw of the Frostwing brood.

**SKORVATH:** I have watched your kingdom grow fat beneath these mountains.

**TOVEN:** You have been here for twenty-seven years?

**SKORVATH:** I have been here longer than your kingdom's oldest lie.

**RHESSA:** Skorvath, the villages below are under attack.

**SKORVATH:** The villages are not my concern.

**RHESSA:** Then let us pass and the fighting ends.

**SKORVATH:** No.

**RHESSA:** Why?

**SKORVATH:** Because something beneath the mountain has begun to breathe.

**[The ice cracks around Skorvath.]**

**SKORVATH:** I will not allow your kind to wake it.

**TOVEN:** We are not trying to wake anything!

**SKORVATH:** You carry crowns in your blood. You always wake what should sleep.

**RHESSA:** Recruit, ignore the dragon's words. Protect the party.

**SKORVATH:** Yes. Protect them.

**SKORVATH:** Protect them as your commander protected the truth.

**[Skorvath spreads his wings. Boss encounter begins.]**

**BOSS INTRODUCTION:** Skorvath, the Frostwing

**COMBAT CALLOUTS:**

- **Skorvath:** You cannot outrun winter!
- **RHESSA:** Move left! The ice is breaking!
- **TOVEN:** The marked ground is about to freeze! Move!
- **SKORVATH:** Fall from my sky!
- **RHESSA:** Hold the center! Do not get pushed over the ledge!
- **SKORVATH:** Kneel beneath the storm!
- **TOVEN:** The whole platform is freezing! There must be a safe path!

**[At low health, Skorvath lands and gathers frost around his body.]**

**SKORVATH:** You mistake survival for victory.

**RHESSA:** Everyone behind cover!

**SKORVATH:** When the buried fire opens its eye, it will remember you.

**[Skorvath unleashes Frost Nova. The player survives the final phase and defeats him.]**

### Scene 1.8 - The Dragon's Last Warning

**[Skorvath collapses. The ice around the summit begins to melt.]**

**RHESSA:** Is everyone alive?

**PLAYER RESPONSE:** Nod / gesture toward Skorvath.

**TOVEN:** The dragon is dying.

**SKORVATH:** Do not celebrate, little sparks.

**SKORVATH:** I was not the master of this mountain.

**RHESSA:** What is beneath it?

**SKORVATH:** You know.

**RHESSA:** Answer me!

**SKORVATH:** The buried fire wakes.

**SKORVATH:** You have only taught it your names.

**[Skorvath dies. A deep pulse travels through the mountain.]**

**TOVEN:** Commander...

**RHESSA:** Search the hoard.

**TOVEN:** That is your response?

**RHESSA:** It is the response that keeps us moving.

**QUEST COMPLETE:** Skorvath, the Frostwing

### Quest 1.8 - The Old Vanguard Seal

**Trigger:** The player searches Skorvath's hoard.

**[The player uncovers a scorched Vanguard shoulder guard, a broken sword, and a royal seal.]**

**TOVEN:** Stop. Do not touch that.

**PLAYER RESPONSE:** Pick up the shoulder guard.

**TOVEN:** The metal is old. At least twenty-seven years.

**RHESSA:** Then it belonged to a soldier who died here.

**TOVEN:** This seal is not a soldier's mark. It is a private royal seal.

**RHESSA:** You are certain?

**TOVEN:** I am a scholar. Certainty is the reward people give us after ignoring every warning.

**TOVEN:** This belonged to someone acting under the crown.

**PLAYER RESPONSE:** Ask Rhessa if she knows the soldier.

**RHESSA:** No.

**TOVEN:** You answered too quickly.

**RHESSA:** I answered clearly.

**TOVEN:** That is not the same thing.

**[The Cinderscar Crater glows on the distant horizon. A huge shape moves inside it.]**

**PLAYER RESPONSE:** Point toward the crater.

**TOVEN:** There. Do you see it?

**RHESSA:** Yes.

**TOVEN:** You recognized it before the player pointed.

**RHESSA:** I recognized a dangerous place.

**TOVEN:** What is in the crater?

**RHESSA:** Something we are not ready to fight.

**PLAYER RESPONSE:** Then why is it moving?

**RHESSA:** Because we disturbed the mountain.

**TOVEN:** Or because it felt the dragon die.

**RHESSA:** Enough. We return to Valdris.

**TOVEN:** You are not going to report the crater?

**RHESSA:** I will report what matters.

**TOVEN:** And who decides what matters?

**RHESSA:** The king.

**[Rhessa starts down the mountain. Toven remains beside the player for a moment.]**

**TOVEN:** Remember what you saw here.

**TOVEN:** A dragon warned us about a buried fire. A royal soldier died protecting a secret. And your commander wants both forgotten.

**PLAYER RESPONSE:** Follow Rhessa / study the crater.

**TOVEN:** Come. Questions are dangerous when asked alone.

**QUEST COMPLETE:** The Old Vanguard Seal

**QUEST COMPLETE:** The Frostwing's Domain

**QUEST ACCEPTED:** The Crown's Lie

**[The player, Rhessa, and Toven return to the northern Waygate. The Waygate opens, revealing the road back to Valdris.]**

**RHESSA:** The Frostwing is dead. The northern road is secure.

**TOVEN:** That is not what happened.

**RHESSA:** It is what the report will say.

**TOVEN:** The report will also say that the royal seal in the hoard is twenty-seven years old.

**RHESSA:** The recruit is exhausted. So are you.

**TOVEN:** Exhaustion does not explain why you knew the crater's name before we reached the summit.

**RHESSA:** Return to Valdris. We will discuss this where the walls have ears we understand.

**QUEST OBJECTIVE:** Return to Commander Rhessa in Valdris.

**[At the Valdris marketplace, Rhessa waits beneath the Vanguard banner.]

**RHESSA:** You completed your assignment.

**PLAYER RESPONSE:** Ask about the old armor / ask about the crater / remain silent.

**RHESSA:** Some questions belong to soldiers. Others belong to kings.

**TOVEN:** That is a convenient distinction.

**RHESSA:** The kingdom needs time before it needs answers.

**TOVEN:** No. The kingdom needs answers before someone buries them again.

**RHESSA:** Enough, Magister.

**[A messenger arrives with a sealed order from King Aldric. Rhessa reads it and hides her reaction.]**

**RHESSA:** The king requests a full report.

**PLAYER RESPONSE:** Hand over the royal seal / keep it visible.

**RHESSA:** What happened on Frosthorn will remain under Vanguard protection until I say otherwise.

**TOVEN:** There. That is the first honest thing you have said.

**RHESSA:** Do not mistake honesty for permission.

**QUEST COMPLETE:** The Crown's Lie

**CHAPTER 1 ENDING CUTSCENE:**

**[The party descends Frosthorn. Far behind them, beneath the Cinderscar Crater, something pulses again.]**

**[In Emberholt Castle, King Aldric stands at a window facing the northeast.]**

**ALDRIC:** The Frostwing is dead.

**[Rhessa kneels in the darkened throne room.]**

**RHESSA:** The recruit found the old armor.

**ALDRIC:** Did the recruit see the crater?

**RHESSA:** Yes.

**ALDRIC:** Then the mountain has chosen a new witness.

**RHESSA:** Should I silence them?

**ALDRIC:** No.

**ALDRIC:** Send them southeast when the ash begins to spread.

**ALDRIC:** Let the next danger point them away from the truth.

**[Cut to the player standing outside Valdris. The crater glows faintly beyond the walls.]**

**TITLE CARD:** CHAPTER 1 COMPLETE - THE FROSTWING'S DOMAIN

**UNLOCKED:** Northern Waygate; Frosthorn Peak travel; optional Cinderscar Crater exploration.

---

## CURRENT-MAP OPTIONAL CONTENT - CINDERSCAR CRATER

**Quest status:** This is an optional side encounter, not the final Chapter 1 quest. It does not complete Chapter 1, unlock Chapters 2-4, or replace the Frosthorn story finale. Its purpose is to reward exploration and provide early foreshadowing.

### Scene C.1 - The Warden (Current-Map Optional Encounter)

**Panel 1 - The crater rim**

[The player may approach the crater at any time after Chapter 1. The ground is cracked, and red light pulses beneath the ash.]

**PLAYER UI:** Optional Area Discovered: Cinderscar Crater

**Panel 2 - The chained dragon**

[Vaelithra, a colossal cinderwyrm, thrashes against invisible chains. Fel fire glows through her scales.]

**VAELITHRA:** Leave...

**VAELITHRA:** Leave before the seal remembers you.

**Panel 3 - Combat**

[Corruption cracks spread across the arena floor. Vaelithra's chains flare with ancient magic.]

**BOSS INTRODUCTION:** Vaelithra, the Cinderwyrm Warden

**COMBAT CALLOUTS:**

- Fel-fire breath cone.
- Tail sweep and wing buffet.
- Corruption cracks punish players who stand still.
- Periodic chain pulses root Vaelithra while the arena becomes unstable.

**Panel 4 - Loot hint**

[The player finds a torn Vanguard banner, a scorched royal seal, and a fragment of a binding ritual.]

**TOVEN:** These were not left here by accident.

**TOVEN:** Someone built a prison beneath this crater.

**OPTIONAL ENCOUNTER COMPLETE:** The Warden

**PLAYER UI:** Optional encounter complete. Return to the Chapter 1 quest chain.

### Chapter 1 Final Quest Order

The current-map Chapter 1 ending is:

1. **`FrostwingsDomain` - The Frostwing's Domain:** Defeat Skorvath at the Frosthorn summit.
2. **`ReturnToValdris` - The Crown's Lie:** Return to Commander Rhessa in Valdris and trigger the Chapter 1 epilogue.
3. **Optional:** Explore Cinderscar Crater and fight Vaelithra, the Cinderwyrm Warden.

The crater can be completed before or after `ReturnToValdris`, depending on the intended progression. It should remain a side quest unless the game design later makes it a required Chapter 1 finale.

---

## FUTURE MAP CHAPTER 2 - THE ASHBOUND MARCH

**Map status:** Planned content for Emberfang Ridge. This map is not part of the current playable-map scope.

**Implementation status:** Story and quest concepts only. Do not register these quests against current Chapter 1 zones or current NPCs.

### Scene 2.1 - The Southeast Ridge

**Panel 1 - Emberfang Ridge**

[The player stands on a red, ash-covered ridge. Far away, the crater smolders.]

**RHESSA:** The ash is spreading toward the farmlands.

**RHESSA:** Contain it before the wind carries it to Valdris.

**TOVEN:** And the old Vanguard gear?

**RHESSA:** A coincidence.

**Panel 2 - A distant roar**

[A deep roar rolls across the ridge. Birds burst from the rocks.]

**PLAYER RESPONSE:** Look toward the crater.

**RHESSA:** Wind through the rocks.

**TOVEN:** Wind does not breathe.

**Panel 3 - Old banners**

[The party finds faded Vanguard banners buried in ash. Rhessa reaches for one before the player can.]

**PLAYER UI:** The banner is twenty-seven years old.

**RHESSA:** We used this ridge as a containment line.

**TOVEN:** You were here.

**RHESSA:** Everyone was somewhere twenty-seven years ago.

### Scene 2.2 - The Ashbound

**Panel 1 - Corrupted camp**

[Ashbound orcs fortify a camp around a demonic rift. Fel fire leaks from the ground.]

**ASHBOUND SOLDIER:** We are not invading your kingdom!

**ASHBOUND SOLDIER:** We are running from the Wyrm!

**RHESSA:** Then stop running through our farms.

**Panel 2 - Kruzgar enters**

[Kruzgar the Ashbound steps through the rift, carrying a burning cleaver.]

**KRUZGAR:** Your banners stood here before my grandfather was born.

**KRUZGAR:** Your soldiers watched the crater. Your king knows what sleeps below.

**RHESSA:** Enough.

**BOSS INTRODUCTION:** Kruzgar the Ashbound

**COMBAT CALLOUTS:**

- Heavy cleave attacks create burning arcs.
- Fel-fire pools deny sections of the arena.
- At half health, Kruzgar charms Ashbound survivors and turns them against the party.

**Panel 3 - Kruzgar's defeat**

[Kruzgar falls to one knee, laughing bitterly.]

**KRUZGAR:** We did not choose this ridge.

**KRUZGAR:** The Wyrm drove us out.

**KRUZGAR:** Ask your commander what she buried.

### Scene 2.3 - The First Sighting

**Panel 1 - Crater overlook**

[The player reaches the ridge edge. The crater is visible below. Vaelithra is coiled around a black shape buried in the center.]

**TOVEN:** That is no ordinary dragon.

**RHESSA:** Step away from the ledge.

**TOVEN:** What is she guarding?

**RHESSA:** Something that must never wake.

**Panel 2 - Rhessa grabs the player**

[Rhessa physically pulls the player back from the overlook as Vaelithra opens one glowing eye.]

**RHESSA:** That is not your fight.

**RHESSA:** Not yet.

**Panel 3 - Vaelithra's eye**

[The dragon watches the party leave. Beneath her, the buried seal pulses once.]

**VAELITHRA:** The crown returns...

**QUEST COMPLETE:** The Ashbound March

---

## FUTURE MAP CHAPTER 3 - THE HOLLOW KING

**Map status:** Planned content for Duskroot Mountain. This map is not part of the current playable-map scope.

**Implementation status:** Story and quest concepts only. The undead, cultist, necropolis, and Hollow King encounters require their future-map assets and configurations.

### Scene 3.1 - Refugees at the Gate

**Panel 1 - Valdris in panic**

[Refugees crowd the southern gate. Vanguard healers carry the sick. Black mist drifts between the wagons.]

**REFUGEE:** The dead are walking in Duskroot!

**REFUGEE:** They speak of a king beneath the mountain!

**Panel 2 - Aldric's address**

[King Aldric stands above the crowd, illuminated by torchlight. Rhessa and the player stand below him.]

**ALDRIC:** You came to Valdris seeking shelter. You will find it.

**ALDRIC:** The dead may cross our roads, but they will not cross our walls.

**ALDRIC:** We will face the dark together.

**CROWD:** King Aldric! King Aldric!

**Panel 3 - Private exchange**

[Aldric turns to Rhessa once the crowd disperses.]

**ALDRIC:** Send the recruit south.

**RHESSA:** The crater is worsening.

**ALDRIC:** The crater can wait.

**ALDRIC:** The Hollow King cannot.

### Scene 3.2 - Duskroot Mountain

**Panel 1 - The necropolis road**

[Fog fills a dead forest. Lanterns burn with pale blue flame.]

**DEAD VILLAGER:** The second prince remembers.

**DEAD VILLAGER:** The first prince took the crown.

**PLAYER RESPONSE:** Question the dead / draw weapon.

**RHESSA:** Do not listen to them. The plague makes puppets of memory.

**Panel 2 - Cultist shrine**

[Forsaken cultists kneel before a cracked statue of a crowned figure.]

**CULTIST:** The Hollow King is not a monster.

**CULTIST:** He is the king who was denied his grave.

**RHESSA:** Clear the shrine.

**CULTIST:** Your commander knows the truth.

### Scene 3.3 - Toven's Letter

**Panel 1 - Camp at night**

[The player finds a raven carrying a coded letter. The royal seal has been scratched away.]

**TOVEN'S LETTER:** The archives confirm a missing royal heir.

**TOVEN'S LETTER:** King Aldric had an older brother: Prince Cael Varn.

**TOVEN'S LETTER:** Every record of him was erased after the Cinderscar impact.

**TOVEN'S LETTER:** Meet me before the summit. Trust no one who tells you to forget the crater.

### Scene 3.4 - The Hollow King

**Panel 1 - Summit necropolis**

[The Hollow King stands among thousands of silent dead. His armor is royal beneath layers of decay.]

**HOLLOW KING:** Vanguard...

**HOLLOW KING:** Still carrying his words.

**RHESSA:** Recruit, prepare yourself.

**HOLLOW KING:** She taught you to bury questions.

**Panel 2 - First phase**

[The Hollow King raises a hand. The dead rise, but he hesitates before striking.]

**HOLLOW KING:** I did not call them.

**HOLLOW KING:** They called me.

**Panel 3 - Mid-fight**

[The player damages the Hollow King's crown-mask. A human face is briefly visible.]

**HOLLOW KING:** Aldric...

**HOLLOW KING:** Tell him I remember the dark.

**Panel 4 - Retreat**

[The Hollow King drops his weapon and disappears into the fog instead of killing the player. His hood slips.]

**TOVEN:** Gods above...

**TOVEN:** That is Prince Cael.

**Panel 5 - Rhessa arrives**

[Rhessa steps into the ruined courtyard. She sees Cael's discarded crown-mask.]

**PLAYER RESPONSE:** Turn toward Rhessa.

**RHESSA:** ...

**TOVEN:** Commander?

**RHESSA:** We return to Valdris.

**TOVEN:** You knew.

**RHESSA:** We return. Now.

**QUEST COMPLETE:** The Hollow King

---

## FUTURE MAP CHAPTER 4 - THE SHATTERED CROWN

**Map status:** Planned content for Stormpeak Crest and the future return to Emberholt Castle.

**Implementation status:** Story and quest concepts only. The naga archive, Rhessa confrontation, Aldric finale, and chapter choices should remain disabled until the future maps and progression systems are ready.

### Scene 4.1 - Stormpeak Expedition

**Panel 1 - The western road**

[Storm clouds coil around Stormpeak Crest. Toven rides beside the player with a pack full of stolen archive pages.]

**TOVEN:** The naga kept records before Valdris had a name.

**TOVEN:** If the truth survived anywhere, it survived beneath those waters.

**Panel 2 - Rhessa blocks the road**

[Rhessa and Vanguard soldiers stand across the western road.]

**RHESSA:** Turn back.

**PLAYER RESPONSE:**

- Lower weapon and demand an explanation.
- Draw weapon and continue forward.

**TOVEN:** At last. An honest order.

**RHESSA:** You do not understand what you are opening.

**TOVEN:** Then let the records speak.

### Scene 4.2 - The Drowned Archive

**Panel 1 - Flooded ruins**

[Storm giants move through the shallows. Naga tide-callers guard a submerged stone archive.]

**NAGA SENTINEL:** Surface kings carve lies into stone.

**NAGA SENTINEL:** The tide remembers what they erase.

**Panel 2 - Naz'kiraa appears**

[Naz'kiraa rises from the water, surrounded by drowned warriors. Lightning travels through her staff.]

**NAZ'KIRAA:** No land-born hand will touch the Tide-Record.

**BOSS INTRODUCTION:** Naz'kiraa, Tide-Caller

**COMBAT CALLOUTS:**

- Tidal waves sweep across the arena in marked lanes.
- Drowned adds emerge from flooded pools.
- Lightning chains between wet players.
- The archive platform periodically submerges, forcing movement.

**Panel 3 - The record**

[The player retrieves a blue-black tablet covered in moving script. Toven reads it.]

**TOVEN:** The crater held a fragment of a dead god.

**TOVEN:** It chose Cael as its vessel.

**TOVEN:** Aldric sealed Cael beneath the crater to take the throne.

**TOVEN:** Rhessa helped him do it.

**Panel 4 - The final line**

[The tablet shows an image of young Aldric, young Rhessa, and Vaelithra bound in chains.]

**TOVEN:** The dragon was bound as the seal's warden.

**TOVEN:** She was never told what she guarded.

### Scene 4.3 - Mentor and Recruit

**Panel 1 - Archive exit**

[Rhessa waits in the rain. Her Vanguard soldiers are gone. She carries her sword but has removed her helmet.]

**RHESSA:** Give me the record.

**PLAYER RESPONSE:** Refuse / present the record.

**TOVEN:** You cannot erase the truth twice.

**RHESSA:** I did what was necessary.

**RHESSA:** I protected this kingdom for twenty-seven years.

**PLAYER UI:** Commander Rhessa Kael has become hostile.

**Panel 2 - Boss fight**

[Rhessa takes the same stance she taught the player in the opening tutorial.]

**RHESSA:** You know every technique I use.

**RHESSA:** I know every mistake I taught you to make.

**BOSS INTRODUCTION:** Rhessa Kael, Vanguard Commander

**COMBAT CALLOUTS:**

- Rhessa uses Vanguard counterattacks and guard breaks.
- She marks the player with the same training signal used in Chapter 1.
- At low health, she uses a forbidden royal technique.
- The player can interrupt the final strike rather than kill her.

**Panel 3 - After the fight**

[Rhessa is defeated, kneeling in the rain. The player lowers their weapon.]

**RHESSA:** Why did you hesitate?

**PLAYER RESPONSE:** Spare Rhessa / demand surrender.

**RHESSA:** Because you still believe people can choose differently.

**RHESSA:** Do not mistake that belief for proof that I was wrong.

[Rhessa disappears into the storm.]

**TOVEN:** She could have killed us.

**TOVEN:** I do not know whether that was mercy or another lie.

### Scene 4.4 - Return to Emberholt

**Panel 1 - The castle gates**

[The player and Toven return to Valdris. Citizens hold copies of the Tide-Record. The city is divided.]

**CITIZEN:** The king erased his own brother!

**VANGUARD SOLDIER:** Stand aside! By order of the crown!

**Panel 2 - The throne room**

[King Aldric stands alone beneath the royal crest. His warm expression is gone. A shard of red-black light is embedded in his gauntlet.]

**ALDRIC:** Toven. You always did confuse knowledge with wisdom.

**TOVEN:** And you confused a crown with a right to murder.

**ALDRIC:** Cael was chosen by the fragment. I was chosen by history.

**ALDRIC:** I made the choice a king must make.

**Panel 3 - Aldric reveals the plan**

[The castle floor cracks. Red light flows beneath the city toward the crater.]

**ALDRIC:** Cael cannot be saved.

**ALDRIC:** But he can be ended.

**ALDRIC:** I will burn the crater, the fragment, and every creature near it if that is the price of a lasting seal.

**TOVEN:** You would sacrifice the entire region to keep your stolen crown.

**ALDRIC:** I would sacrifice anything to keep the dead from ruling the living.

### Scene 4.5 - Final Battle

**Panel 1 - The throne room transforms**

[Aldric raises the shard. His royal armor fuses with black-red crystal. The throne splits behind him.]

**ALDRIC:** Kneel, recruit.

**ALDRIC:** You are looking at the reason Valdris still stands.

**PLAYER RESPONSE:** Attack.

**BOSS INTRODUCTION:** King Aldric Varn, the Shattered King

**COMBAT CALLOUTS:**

- Sword-and-shard melee combinations.
- Royal commands summon corrupted Vanguard echoes.
- The throne room fractures as the crater seal destabilizes.
- At low health, the god-fragment consumes part of Aldric's body and changes his attack pattern.

**Panel 2 - Cael's voice**

[As Aldric weakens, every window in the throne room fills with black mist.]

**CAEL'S VOICE:** Brother...

**ALDRIC:** You should have stayed buried!

**CAEL'S VOICE:** I tried.

**Panel 3 - The choice**

[Aldric falls. The shard hovers above the cracked floor. Far below, Cael reaches toward the surface through the broken seal.]

**TOVEN:** We have one chance.

**TOVEN:** Destroy the fragment and Cael dies with it.

**TOVEN:** Or break the last lock and let Cael return to the throne.

**PLAYER CHOICE:**

1. **End the Bloodline** - Help Aldric destroy Cael and reinforce the seal.
2. **Expose the Crown** - Break the seal and allow Cael to reclaim his name.

---

## FUTURE MAP CHAPTER 4 ENDINGS

### Ending A - End the Bloodline

**Panel 1**

[The player drives the shard into the throne. Light erupts through the castle foundations.]

**ALDRIC:** At last...

**CAEL:** I remember you.

**Panel 2**

[The crater begins collapsing. The undead fall silent. The light fades from Aldric's armor.]

**TOVEN:** The seal is holding.

**TOVEN:** For now.

**Panel 3**

[Aldric dies without a crown on his head. The player looks toward the crater.]

**CAPTION:** The kingdom survives, but its history is buried beneath another layer of ash.

### Ending B - Expose the Crown

**Panel 1**

[The player breaks the shard instead. A wave of black light tears through the throne room.]

**ALDRIC:** No!

**CAEL:** The crown was never yours.

**Panel 2**

[Cael's spirit rises through the castle floor. He takes the broken royal crest from Aldric's hand.]

**CAEL:** Let every living soul hear what you did.

**Panel 3**

[The undead in Duskroot lower their weapons. The people of Valdris gather beneath the castle.]

**CAPTION:** The truth returns to Valdris, but truth does not restore what twenty-seven years destroyed.

---

## FUTURE SEASON 2 HOOK - THE UNBOUND

### Scene S2.1 - The Crater Opens

**Panel 1 - Cinderscar Crater**

[The final shockwave reaches the crater. Vaelithra's ancient chains snap one by one.]

**VAELITHRA:** No more orders.

**VAELITHRA:** No more crowns.

**Panel 2 - Vaelithra takes flight**

[Vaelithra erupts into the sky above Valdris. Her body is fused with brilliant fel fire. Citizens flee below.]

**CAPTION:** The Warden is free.

**Panel 3 - Beneath the crater**

[The crater floor opens into a glowing chasm. Something far larger than Vaelithra shifts in the darkness.]

**TOVEN:** That was not the source of the corruption.

**TOVEN:** It was the lock.

**Panel 4 - The tree line**

[Rhessa watches the dragon from the shadows, alive and unclaimed.]

**RHESSA:** Choose carefully, recruit.

**RHESSA:** The next war will not be between kings.

**TITLE CARD:** THE SHATTERED CROWN WILL RETURN

---

## OPTIONAL WORLD-BOSS FINALE - VAELITHRA, THE UNBOUND

**Availability:** After Chapter 4

**Encounter framing:** A raid party enters the opened crater while Vaelithra circles above the broken seal.

**VAELITHRA:** I guarded your prison.

**VAELITHRA:** Now guard yourselves.

**Raid mechanics:**

- All Warden abilities return with increased damage and larger warning zones.
- Crater Quake reshapes the arena and destroys portions of the floor.
- The raid must move between shrinking platforms above the chasm.
- The final enrage opens the crater completely, revealing the ancient presence below.

**Final raid panel:**

[The raid defeats Vaelithra. Her body falls against the crater rim. Below, a single enormous eye opens in the dark.] 

**UNKNOWN VOICE:** At last...

**UNKNOWN VOICE:** The little kings are gone.

**QUEST COMPLETE:** The Warden Unbound
