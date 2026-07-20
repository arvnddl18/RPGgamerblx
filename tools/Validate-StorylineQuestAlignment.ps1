$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$questText = Get-Content (Join-Path $root "src/Shared/Config/Quests.lua") -Raw
$monsterText = Get-Content (Join-Path $root "src/Shared/Config/MonsterConfig.lua") -Raw
$itemText = Get-Content (Join-Path $root "src/Shared/Config/Items.lua") -Raw
$serviceText = Get-Content (Join-Path $root "src/Server/Services/ServerAuthority/QuestService.lua") -Raw
$comicText = Get-Content (Join-Path $root "src/Client/Controllers/UserInterface/ComicDialogueController.lua") -Raw
$trackerText = Get-Content (Join-Path $root "src/Client/Controllers/UserInterface/QuestLogController.lua") -Raw
$dialogueStart = $questText.IndexOf("local chapterOneDialogue")
$dialogueText = if ($dialogueStart -ge 0) { $questText.Substring($dialogueStart) } else { "" }
$completionStart = $questText.IndexOf("local chapterOneCompletionDialogue")
$completionText = if ($completionStart -ge 0) { $questText.Substring($completionStart) } else { "" }

$failures = [System.Collections.Generic.List[string]]::new()
function Require-Match([string]$text, [string]$pattern, [string]$message) {
	if ($text -notmatch $pattern) { $failures.Add($message) }
}

$mainQuestIds = @(
	"VanguardAtDawn", "VillageSupplyLine", "NorthernWaygate", "N1MissingAtFirstLight",
	"B1SlimeSupplyRoad", "B2GoblinQuickfingers", "N2QuartermastersLedger", "FoothillDisturbance",
	"FieldMedicRemedy", "FleeingPeak", "B3WebsAcrossRoad", "B4RunningPack",
	"N4AntidoteForPatrol", "N5HuntersLastTrail", "WebsOfWarning", "N3GoblinHonestWork",
	"ScholarInRuins", "N6PagesBeneathSnow", "EchoesBelow", "B5BonesAncientSnow",
	"B6KnightsSealedDoor", "N7BrokenVanguardBlade", "SealedChamber", "TheBrokenOath",
	"B7AshenSpear", "N8OrcsDebt", "WarbandsRefuge", "ForgeTheVanguard", "SealTheVanguard",
	"N9FeathersForSignal", "N10MealAboveClouds", "B8TalonsFrosthorn", "B9HighNest",
	"FrostwingsDomain", "N11OldSoldiersQuestion", "N12LightForFallen", "ReturnToValdris"
)

foreach ($questId in $mainQuestIds) {
	Require-Match $questText "(?m)^\s*$questId\s*=\s*\{" "Missing main quest config: $questId"
}
Require-Match $questText '(?m)^\s*CinderscarWarden\s*=\s*\{' "Missing optional crater quest config: CinderscarWarden"

$supportedObjectiveTypes = @("talk", "kill", "collect", "collectcraft", "reach", "killreach", "upgrade", "enhance")
foreach ($match in [regex]::Matches($questText, 'objectiveType\s*=\s*"([^"]+)"')) {
	if ($supportedObjectiveTypes -notcontains $match.Groups[1].Value) {
		$failures.Add("Unsupported objective type: $($match.Groups[1].Value)")
	}
}

foreach ($match in [regex]::Matches($questText, 'type\s*=\s*"enemy"\s*,\s*name\s*=\s*"([^"]+)"')) {
	$enemyId = $match.Groups[1].Value
	Require-Match $monsterText "(?m)^\s*$enemyId\s*=\s*\{" "Quest enemy is missing from MonsterConfig: $enemyId"
}

foreach ($match in [regex]::Matches($questText, 'itemId\s*=\s*"([^"]+)"')) {
	$itemId = $match.Groups[1].Value
	Require-Match $itemText "(?m)^\s*$itemId\s*=\s*\{" "Quest item/reward is missing from Items: $itemId"
}

foreach ($match in [regex]::Matches($questText, 'type\s*=\s*"zone"\s*,\s*name\s*=\s*"([^"]+)"')) {
	$zoneId = $match.Groups[1].Value
	Require-Match $serviceText "CreateReachZone\(\s*""$zoneId""" "Quest zone is not created by QuestService: $zoneId"
}

foreach ($handler in @("OnEnemyKilled", "OnItemCollected", "OnCrafted", "OnEquipmentUpgraded", "OnEquipmentEnhanced", "OnTalkToNPC", "OnReachZone")) {
	Require-Match $serviceText "function QuestService:$handler" "Missing QuestService handler: $handler"
}

foreach ($sceneQuest in [regex]::Matches($serviceText, 'questId\s*=\s*"([^"]+)"')) {
	$sceneQuestId = $sceneQuest.Groups[1].Value
	Require-Match $questText "(?m)^\s*$sceneQuestId\s*=\s*\{" "Dialogue scene references missing quest: $sceneQuestId"
}

foreach ($sceneId in @("RhessaIntro", "TovenIntro", "AmaraIntro", "IvenIntro", "DoranIntro", "EddaIntro", "CinderscarIntro")) {
	Require-Match $serviceText "(?m)^\s*$sceneId\s*=\s*\{" "Missing comic dialogue scene: $sceneId"
}

Require-Match $serviceText 'QuestReward:FireClient' "Quest completion does not send reward feedback"
Require-Match $serviceText 'SpawnQuestBoss\("Vaelithra"' "Optional crater quest does not activate Vaelithra"
Require-Match $serviceText 'function QuestService:GetNextQuestOffer' "Story NPCs do not provide comic offers for later quests"
Require-Match $serviceText 'function QuestService:OpenQuestOffer' "Story NPC comic offer flow is missing"
Require-Match $serviceText 'QuestOffer_' "Dynamic quest offer scenes are not wired"
foreach ($npcName in @("Elder Mara", "Quartermaster Elian", "Nib Quickfinger", "Healer Lysa", "Hunter Corren", "Smith Hadrik", "Scout Varok", "Cook Branna", "Veteran Dain", "Priestess Selene")) {
	Require-Match $serviceText ('storyNpcAt\("' + [regex]::Escape($npcName) + '"') "Current-map NPC is not created: $npcName"
}
Require-Match $serviceText 'CreateReachZone\("FrosthornMemorial"' "Memorial reach zone is missing"
foreach ($uiElement in @("DimmedWorld", "DialogueBox", "SpeakerNameplate", "AcceptQuestButton", "AutoPlay", "SkipButton")) {
	Require-Match $comicText ('(?m)Name\s*=\s*"' + [regex]::Escape($uiElement) + '"') "Comic dialogue UI element is missing: $uiElement"
}
Require-Match $comicText 'createPortrait\("Left"' "Left comic portrait is missing"
Require-Match $comicText 'createPortrait\("Right"' "Right comic portrait is missing"
foreach ($questId in $mainQuestIds) {
	Require-Match $trackerText ([regex]::Escape($questId)) "Main quest is missing from the child-friendly tracker: $questId"
	Require-Match $dialogueText ("(?m)^\s*" + [regex]::Escape($questId) + "\s*=\s*\{") "Main quest is missing scripted comic dialogue: $questId"
	Require-Match $completionText ("(?m)^\s*" + [regex]::Escape($questId) + "\s*=\s*\{") "Main quest is missing scripted completion dialogue: $questId"
}
Require-Match $dialogueText '(?m)^\s*CinderscarWarden\s*=\s*\{' "Optional crater quest is missing scripted comic dialogue"
Require-Match $completionText '(?m)^\s*CinderscarWarden\s*=\s*\{' "Optional crater quest is missing scripted completion dialogue"

if ($failures.Count -gt 0) {
	$failures | ForEach-Object { Write-Error $_ }
	exit 1
}

Write-Output "Storyline quest alignment passed: $($mainQuestIds.Count) main quests plus CinderscarWarden."
