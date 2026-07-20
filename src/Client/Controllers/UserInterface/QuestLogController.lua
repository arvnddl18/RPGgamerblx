local Controller = {}

function Controller:Start()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")

	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local Quests = require(Shared.Config.Quests)
	local Items = require(Shared.Config.Items)
	local MonsterConfig = require(Shared.Config.MonsterConfig)
	local QuestUI = require(script.Parent.Parent.Parent.UI.Quest.QuestUI)
	local MusicController = require(script.Parent.Parent.Effects.MusicController)

	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	local hasSelectedClass = false
	local playerLevel = 1
	local questsData = {}

	-- Child-friendly primary quest tracker. Keep the main path visible without
	-- forcing the player to open the full quest log.
	local mainQuestOrder = {
		"VanguardAtDawn", "VillageSupplyLine", "NorthernWaygate", "N1MissingAtFirstLight",
		"B1SlimeSupplyRoad", "B2GoblinQuickfingers", "N2QuartermastersLedger", "FoothillDisturbance",
		"FieldMedicRemedy", "FleeingPeak", "B3WebsAcrossRoad", "B4RunningPack",
		"N4AntidoteForPatrol", "N5HuntersLastTrail", "WebsOfWarning", "N3GoblinHonestWork",
		"ScholarInRuins", "N6PagesBeneathSnow", "EchoesBelow", "B5BonesAncientSnow",
		"B6KnightsSealedDoor", "N7BrokenVanguardBlade", "SealedChamber", "TheBrokenOath",
		"B7AshenSpear", "N8OrcsDebt", "WarbandsRefuge", "ForgeTheVanguard", "SealTheVanguard",
		"N9FeathersForSignal", "N10MealAboveClouds", "B8TalonsFrosthorn", "B9HighNest",
		"FrostwingsDomain", "N11OldSoldiersQuestion", "N12LightForFallen", "ReturnToValdris",
	}

	local trackerGui = Instance.new("ScreenGui")
	trackerGui.Name = "MainQuestTracker"
	trackerGui.ResetOnSpawn = false
	trackerGui.DisplayOrder = 20
	trackerGui.IgnoreGuiInset = true
	trackerGui.Parent = player:WaitForChild("PlayerGui")

	local tracker = Instance.new("Frame")
	tracker.Name = "MainQuestCard"
	-- Keep the tracker on the top-left HUD edge, below Roblox's top-left menu.
	tracker.Position = UDim2.new(0, 16, 0, 72)
	tracker.Size = UDim2.new(0, 300, 0, 184)
	tracker.BackgroundColor3 = Color3.fromRGB(22, 18, 28)
	tracker.BackgroundTransparency = 0.08
	tracker.BorderSizePixel = 0
	tracker.Visible = false
	tracker.Parent = trackerGui

	local trackerCorner = Instance.new("UICorner")
	trackerCorner.CornerRadius = UDim.new(0, 10)
	trackerCorner.Parent = tracker
	local trackerStroke = Instance.new("UIStroke")
	trackerStroke.Color = Color3.fromRGB(226, 187, 84)
	trackerStroke.Thickness = 2
	trackerStroke.Parent = tracker

	local trackerExpanded = true
	local expandedTrackerSize = UDim2.new(0, 300, 0, 184)
	local collapsedTrackerSize = UDim2.new(0, 300, 0, 44)

	local trackerToggle = Instance.new("TextButton")
	trackerToggle.Name = "ToggleButton"
	trackerToggle.Size = UDim2.new(1, 0, 0, 42)
	trackerToggle.BackgroundTransparency = 1
	trackerToggle.Text = ""
	trackerToggle.AutoButtonColor = false
	trackerToggle.ZIndex = 2
	trackerToggle.Parent = tracker

	local trackerHeader = Instance.new("TextLabel")
	trackerHeader.Size = UDim2.new(1, -24, 0, 23)
	trackerHeader.Position = UDim2.new(0, 12, 0, 8)
	trackerHeader.BackgroundTransparency = 1
	trackerHeader.Text = "MAIN QUEST"
	trackerHeader.TextColor3 = Color3.fromRGB(255, 218, 102)
	trackerHeader.Font = Enum.Font.GothamBold
	trackerHeader.TextSize = 14
	trackerHeader.TextXAlignment = Enum.TextXAlignment.Left
	trackerHeader.ZIndex = 3
	trackerHeader.Parent = tracker

	local trackerTitle = Instance.new("TextLabel")
	trackerTitle.Size = UDim2.new(1, -24, 0, 25)
	trackerTitle.Position = UDim2.new(0, 12, 0, 31)
	trackerTitle.BackgroundTransparency = 1
	trackerTitle.Text = ""
	trackerTitle.TextColor3 = Color3.fromRGB(250, 245, 232)
	trackerTitle.Font = Enum.Font.GothamBold
	trackerTitle.TextSize = 16
	trackerTitle.TextXAlignment = Enum.TextXAlignment.Left
	trackerTitle.TextTruncate = Enum.TextTruncate.AtEnd
	trackerTitle.ZIndex = 3
	trackerTitle.Parent = tracker

	local trackerToggleIcon = Instance.new("TextLabel")
	trackerToggleIcon.Name = "ToggleIcon"
	trackerToggleIcon.AnchorPoint = Vector2.new(1, 0)
	trackerToggleIcon.Position = UDim2.new(1, -12, 0, 10)
	trackerToggleIcon.Size = UDim2.fromOffset(20, 20)
	trackerToggleIcon.BackgroundTransparency = 1
	trackerToggleIcon.Text = "−"
	trackerToggleIcon.TextColor3 = Color3.fromRGB(255, 218, 102)
	trackerToggleIcon.Font = Enum.Font.GothamBold
	trackerToggleIcon.TextSize = 18
	trackerToggleIcon.ZIndex = 3
	trackerToggleIcon.Parent = tracker

	local trackerObjective = Instance.new("TextLabel")
	trackerObjective.Size = UDim2.new(1, -24, 0, 38)
	trackerObjective.Position = UDim2.new(0, 12, 0, 58)
	trackerObjective.BackgroundTransparency = 1
	trackerObjective.Text = ""
	trackerObjective.TextColor3 = Color3.fromRGB(212, 205, 193)
	trackerObjective.Font = Enum.Font.Gotham
	trackerObjective.TextSize = 14
	trackerObjective.TextWrapped = true
	trackerObjective.TextXAlignment = Enum.TextXAlignment.Left
	trackerObjective.TextYAlignment = Enum.TextYAlignment.Top
	trackerObjective.Parent = tracker

	local trackerHelp = Instance.new("TextButton")
	trackerHelp.Name = "WhatDoIDoButton"
	trackerHelp.Position = UDim2.new(0, 12, 0, 116)
	trackerHelp.Size = UDim2.new(0, 126, 0, 25)
	trackerHelp.BackgroundColor3 = Color3.fromRGB(67, 91, 122)
	trackerHelp.Text = "WHAT DO I DO?"
	trackerHelp.TextColor3 = Color3.fromRGB(245, 245, 235)
	trackerHelp.Font = Enum.Font.GothamBold
	trackerHelp.TextSize = 11
	trackerHelp.AutoButtonColor = true
	trackerHelp.Visible = false
	trackerHelp.Parent = tracker
	local trackerHelpCorner = Instance.new("UICorner")
	trackerHelpCorner.CornerRadius = UDim.new(0, 6)
	trackerHelpCorner.Parent = trackerHelp

	local teleportButton = Instance.new("TextButton")
	teleportButton.Name = "TeleportToQuestGiverButton"
	teleportButton.Position = UDim2.new(0, 146, 0, 116)
	teleportButton.Size = UDim2.new(1, -158, 0, 25)
	teleportButton.BackgroundColor3 = Color3.fromRGB(99, 83, 54)
	teleportButton.Text = "TELEPORT TO NPC"
	teleportButton.TextColor3 = Color3.fromRGB(255, 239, 190)
	teleportButton.Font = Enum.Font.GothamBold
	teleportButton.TextSize = 10
	teleportButton.AutoButtonColor = true
	teleportButton.Visible = false
	teleportButton.Parent = tracker
	local teleportCorner = Instance.new("UICorner")
	teleportCorner.CornerRadius = UDim.new(0, 6)
	teleportCorner.Parent = teleportButton

	local trackerHint = Instance.new("TextLabel")
	trackerHint.Name = "QuestHint"
	trackerHint.Position = UDim2.new(0, 12, 0, 145)
	trackerHint.Size = UDim2.new(1, -24, 0, 30)
	trackerHint.BackgroundTransparency = 1
	trackerHint.Text = ""
	trackerHint.TextColor3 = Color3.fromRGB(246, 220, 142)
	trackerHint.Font = Enum.Font.Gotham
	trackerHint.TextSize = 12
	trackerHint.TextWrapped = true
	trackerHint.TextXAlignment = Enum.TextXAlignment.Left
	trackerHint.TextYAlignment = Enum.TextYAlignment.Top
	trackerHint.Visible = false
	trackerHint.Parent = tracker

	local trackerReadyToTurnIn = false
	local function setTrackerExpanded(expanded)
		trackerExpanded = expanded
		tracker.Size = expanded and expandedTrackerSize or collapsedTrackerSize
		trackerObjective.Visible = expanded
		trackerHelp.Visible = expanded and trackerHint.Text ~= ""
		teleportButton.Visible = expanded and trackerReadyToTurnIn
		trackerHint.Visible = false
		trackerToggleIcon.Text = expanded and "−" or "+"
	end

	trackerToggle.Activated:Connect(function()
		setTrackerExpanded(not trackerExpanded)
	end)

	local rewardGui = Instance.new("ScreenGui")
	rewardGui.Name = "QuestRewardPopup"
	rewardGui.ResetOnSpawn = false
	rewardGui.DisplayOrder = 210
	rewardGui.Parent = player:WaitForChild("PlayerGui")

	local rewardCard = Instance.new("Frame")
	-- Keep quest-completion announcements above the skill bar instead of
	-- covering the center of the game view.
	rewardCard.AnchorPoint = Vector2.new(0.5, 1)
	rewardCard.Position = UDim2.new(0.5, 0, 1, -82)
	rewardCard.Size = UDim2.new(0, 420, 0, 150)
	rewardCard.BackgroundColor3 = Color3.fromRGB(238, 226, 202)
	rewardCard.BorderSizePixel = 0
	rewardCard.Visible = false
	rewardCard.Parent = rewardGui
	local rewardCorner = Instance.new("UICorner")
	rewardCorner.CornerRadius = UDim.new(0, 12)
	rewardCorner.Parent = rewardCard
	local rewardStroke = Instance.new("UIStroke")
	rewardStroke.Color = Color3.fromRGB(225, 180, 70)
	rewardStroke.Thickness = 3
	rewardStroke.Parent = rewardCard

	local rewardTitle = Instance.new("TextLabel")
	rewardTitle.Size = UDim2.new(1, -60, 0, 30)
	rewardTitle.Position = UDim2.new(0, 18, 0, 12)
	rewardTitle.BackgroundTransparency = 1
	rewardTitle.Text = "QUEST COMPLETE"
	rewardTitle.TextColor3 = Color3.fromRGB(91, 61, 28)
	rewardTitle.Font = Enum.Font.GothamBold
	rewardTitle.TextSize = 20
	rewardTitle.TextXAlignment = Enum.TextXAlignment.Left
	rewardTitle.Parent = rewardCard

	local rewardClose = Instance.new("TextButton")
	rewardClose.AnchorPoint = Vector2.new(1, 0)
	rewardClose.Position = UDim2.new(1, -10, 0, 10)
	rewardClose.Size = UDim2.fromOffset(32, 32)
	rewardClose.BackgroundTransparency = 1
	rewardClose.Text = "X"
	rewardClose.TextColor3 = Color3.fromRGB(91, 61, 28)
	rewardClose.Font = Enum.Font.GothamBold
	rewardClose.TextSize = 18
	rewardClose.Parent = rewardCard

	local rewardName = Instance.new("TextLabel")
	rewardName.Size = UDim2.new(1, -36, 0, 28)
	rewardName.Position = UDim2.new(0, 18, 0, 43)
	rewardName.BackgroundTransparency = 1
	rewardName.Text = ""
	rewardName.TextColor3 = Color3.fromRGB(50, 42, 36)
	rewardName.Font = Enum.Font.GothamBold
	rewardName.TextSize = 16
	rewardName.TextXAlignment = Enum.TextXAlignment.Left
	rewardName.TextTruncate = Enum.TextTruncate.AtEnd
	rewardName.Parent = rewardCard

	local rewardDetails = Instance.new("TextLabel")
	rewardDetails.Size = UDim2.new(1, -36, 0, 52)
	rewardDetails.Position = UDim2.new(0, 18, 0, 76)
	rewardDetails.BackgroundTransparency = 1
	rewardDetails.Text = ""
	rewardDetails.TextColor3 = Color3.fromRGB(75, 64, 54)
	rewardDetails.Font = Enum.Font.Gotham
	rewardDetails.TextSize = 15
	rewardDetails.TextWrapped = true
	rewardDetails.TextXAlignment = Enum.TextXAlignment.Left
	rewardDetails.TextYAlignment = Enum.TextYAlignment.Top
	rewardDetails.Parent = rewardCard

	local rewardToken = 0
	local function showReward(payload)
		if type(payload) ~= "table" then return end
		rewardToken += 1
		local token = rewardToken
		rewardName.Text = payload.name or "Quest"
		local parts = {}
		if (payload.gold or 0) > 0 then table.insert(parts, "Gold: " .. tostring(payload.gold)) end
		if (payload.experience or 0) > 0 then table.insert(parts, "Experience: " .. tostring(payload.experience)) end
		for _, reward in ipairs(payload.items or {}) do
			local item = Items[reward.itemId]
			local itemName = item and item.name or reward.itemId or "Item"
			table.insert(parts, itemName .. " x" .. tostring(reward.quantity or 1))
		end
		rewardDetails.Text = #parts > 0 and table.concat(parts, "   |   ") or "Reward received!"
		rewardCard.Visible = true
		task.delay(3, function()
			if token == rewardToken then rewardCard.Visible = false end
		end)
	end
	rewardClose.Activated:Connect(function()
		rewardToken += 1
		rewardCard.Visible = false
	end)

	local function getPrimaryQuest()
		for _, questId in ipairs(mainQuestOrder) do
			local config = Quests[questId]
			local qData = questsData[questId]
			if config and qData and qData.accepted and not qData.completed then
				return config, qData
			end
		end
		return nil, nil
	end

	local function targetLabel(target)
		if target.type == "enemy" then
			local enemy = MonsterConfig[target.name]
			return enemy and enemy.name or target.name
		elseif target.type == "item" then
			local item = Items[target.name]
			return item and item.name or target.name
		elseif target.type == "craft" then
			local item = Items[target.name]
			return "Craft " .. (item and item.name or target.name)
		elseif target.type == "zone" then
			return "Reach " .. target.name
		elseif target.type == "npc" then
			return "Talk to " .. target.name
		end
		return target.name
	end

	local function formatTargets(config, qData)
		local parts = {}
		for _, target in ipairs(config.targets or {}) do
			local key = target.type .. ":" .. target.name
			local current = (qData.targetProgress and qData.targetProgress[key]) or 0
			table.insert(parts, targetLabel(target) .. " " .. tostring(math.min(current, target.quantity or 1)) .. "/" .. tostring(target.quantity or 1))
		end
		return #parts > 0 and table.concat(parts, "\n") or (config.objective or config.description or "Continue the story.")
	end

	local function refreshTracker()
		local config, qData = getPrimaryQuest()
		if not hasSelectedClass or not config or not qData then
			tracker.Visible = false
			trackerHelp.Visible = false
			teleportButton.Visible = false
			trackerHint.Visible = false
			trackerReadyToTurnIn = false
			return
		end
		tracker.Visible = true
		trackerObjective.Visible = trackerExpanded
		trackerTitle.Text = config.name or "Main Quest"
		local objective = formatTargets(config, qData)
		local required = Quests.GetRequired(config)
		trackerReadyToTurnIn = qData.progress and required and qData.progress >= required
		if trackerReadyToTurnIn then
			objective = "Return to " .. (config.questGiver or "the quest giver") .. " for your reward!"
		elseif qData.progress and required and required > 1 then
			objective = objective .. "\nTotal: " .. tostring(qData.progress) .. "/" .. tostring(required)
		end
		trackerObjective.Text = objective
		trackerHint.Text = config.hints or "Follow the objective and return to the quest giver."
		trackerHelp.Visible = trackerExpanded and trackerHint.Text ~= ""
		teleportButton.Visible = trackerExpanded and trackerReadyToTurnIn
		trackerHint.Visible = false
	end
	teleportButton.Activated:Connect(function()
		local config = getPrimaryQuest()
		if config and trackerReadyToTurnIn then
			remotes.TeleportToQuestGiver:FireServer(config.id)
		end
	end)
	trackerHelp.Activated:Connect(function()
		if tracker.Visible then
			trackerHint.Visible = not trackerHint.Visible
		end
	end)
	
	local ui = QuestUI.new(player:WaitForChild("PlayerGui"))
	
	ui.OnAccept = function(questId)
		remotes.AcceptQuest:FireServer(questId)
	end
	
	ui.OnTurnIn = function(questId)
		remotes.TurnInQuest:FireServer(questId)
	end

	local function getQuestStatus(config, qData)
		if qData then
			if qData.completed then
				if config.repeatable then
					return "Available" 
				end
				return "Completed"
			elseif qData.accepted then
				if qData.progress >= Quests.GetRequired(config) then
					return "Ready"
				else
					return "Accepted"
				end
			end
		end
		
		if config.requiredLevel and playerLevel < config.requiredLevel then
			return "Locked"
		end
		for _, prerequisiteId in ipairs(config.prerequisites or {}) do
			local prerequisite = questsData[prerequisiteId]
			if not prerequisite or not prerequisite.completed then
				return "Locked"
			end
		end
		
		return "Available"
	end

	local npcFolderConnection
	local function refreshNpcMarkers()
		local npcsFolder = workspace:FindFirstChild("NPCs")
		if not npcsFolder then return end
		if not npcFolderConnection then
			npcFolderConnection = npcsFolder.ChildAdded:Connect(function()
				task.defer(refreshNpcMarkers)
			end)
		end

		local markerByNpc = {}
		for _, config in pairs(Quests) do
			if type(config) == "table" and config.id and config.npcName then
				local status = getQuestStatus(config, questsData[config.id])
				local current = markerByNpc[config.npcName]
				local priority = {
					Ready = 1,
					Available = config.isMainStory and 2 or 3,
					Accepted = 4,
				}
				if priority[status] and (not current or priority[status] < current.priority) then
					markerByNpc[config.npcName] = {
						priority = priority[status],
						status = status,
						isMainStory = config.isMainStory == true,
					}
				end
			end
		end

		for _, npc in ipairs(npcsFolder:GetChildren()) do
			local marker = npc:FindFirstChild("QuestMarker", true)
			local label = marker and marker:FindFirstChildWhichIsA("TextLabel", true)
			if marker and label then
				local state = hasSelectedClass and markerByNpc[npc.Name] or nil
				marker.Enabled = state ~= nil
				if state then
					if state.status == "Ready" then
						label.Text = "?"
						label.TextColor3 = Color3.fromRGB(105, 190, 255)
						label.TextStrokeColor3 = Color3.fromRGB(35, 85, 135)
					elseif state.status == "Accepted" then
						label.Text = "..."
						label.TextColor3 = Color3.fromRGB(190, 190, 200)
						label.TextStrokeColor3 = Color3.fromRGB(70, 70, 80)
					elseif state.isMainStory then
						label.Text = "!"
						label.TextColor3 = Color3.fromRGB(255, 220, 50)
						label.TextStrokeColor3 = Color3.fromRGB(120, 75, 0)
					else
						label.Text = "!"
						label.TextColor3 = Color3.fromRGB(195, 120, 255)
						label.TextStrokeColor3 = Color3.fromRGB(75, 35, 120)
					end
				end
			end
		end
	end

	local function buildQuestList(mode, npcName)
		local list = {}
		for qId, config in pairs(Quests) do
			if type(config) == "table" and config.id then
				local qData = questsData[qId]
				local status = getQuestStatus(config, qData)
				
				local include = false
				if mode == "npc" then
					if config.npcName == npcName and status ~= "Completed" then
						if status ~= "Locked" then
							include = true
						else
							-- Show only the direct next locked step, never the whole future chain.
							local prerequisiteId = (config.prerequisites or {})[1]
							local prerequisite = prerequisiteId and questsData[prerequisiteId]
							include = prerequisite ~= nil
						end
					end
				else -- log
					if status == "Accepted" or status == "Ready" then
						include = true
					end
				end
				
				if include then
					local progText = ""
					if qData and qData.accepted and not qData.completed then
						progText = qData.progress .. "/" .. Quests.GetRequired(config)
					end
					table.insert(list, {
						config = config,
						status = status,
						progressText = progText,
						targetProgress = qData and qData.targetProgress or {},
						sortOrder = (status == "Ready" and 1) or (status == "Available" and 2) or (status == "Accepted" and 3) or (status == "Locked" and 4) or 5
					})
				end
			end
		end

		if mode == "log" then
			for _, futureChapter in ipairs(Quests.FutureChapters or {}) do
				table.insert(list, {
					config = { id = "FutureChapter" .. futureChapter.chapter, name = futureChapter.name, description = futureChapter.lockedReason, chapter = futureChapter.chapter },
					status = "Locked",
					progressText = "",
					sortOrder = 99,
				})
			end
		end
		
		table.sort(list, function(a, b)
			local lvlA = a.config.requiredLevel or 1
			local lvlB = b.config.requiredLevel or 1
			if a.sortOrder == b.sortOrder then
				return lvlA < lvlB
			end
			return a.sortOrder < b.sortOrder
		end)
		
		return list
	end

	local function refreshUI()
		refreshTracker()
		refreshNpcMarkers()
		if ui:IsVisible() then
			local list = buildQuestList(ui._mode, ui._lastNpcName)
			ui:Populate(ui._mode, list, ui._lastNpcName)
		end
	end

	player:WaitForChild("PlayerGui"):WaitForChild("HUDAction").Event:Connect(function(actionId)
		if actionId ~= "QuestLog" or not hasSelectedClass then
			return
		end
		if ui:IsVisible() then
			ui:SetVisible(false)
		else
			ui._lastNpcName = nil
			ui:Populate("log", buildQuestList("log"))
			MusicController:Play8DASMR("Open")
			ui:SetVisible(true)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not hasSelectedClass then
			return
		end
		if input.KeyCode == Enum.KeyCode.J then
			if ui:IsVisible() then
				ui:SetVisible(false)
			else
				ui._lastNpcName = nil
				ui:Populate("log", buildQuestList("log"))
				MusicController:Play8DASMR("Open")
				ui:SetVisible(true)
			end
		end
	end)

	remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
		hasSelectedClass = payload.hasSelectedClass == true
		if payload.level then playerLevel = payload.level end
		if payload.quests then
			questsData = payload.quests
		end
		refreshUI()
	end)

	remotes.QuestUpdated.OnClientEvent:Connect(function(payload)
		if payload.id then
			questsData[payload.id] = {
				accepted = payload.accepted,
				completed = payload.completed,
				progress = payload.progress,
				targetProgress = payload.targetProgress or {}
			}
		end
		refreshTracker()
		refreshNpcMarkers()
		refreshUI()
	end)

	remotes.QuestReward.OnClientEvent:Connect(showReward)
	
	remotes.OpenQuest.OnClientEvent:Connect(function(npcName)
		ui._lastNpcName = npcName
		ui:Populate("npc", buildQuestList("npc", npcName), npcName)
		MusicController:Play8DASMR("Open")
		ui:SetVisible(true)
	end)
end

return Controller
