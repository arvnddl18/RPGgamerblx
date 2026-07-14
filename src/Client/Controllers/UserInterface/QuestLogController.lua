local Controller = {}

function Controller:Start()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")

	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local Quests = require(Shared.Config.Quests)
	local QuestUI = require(script.Parent.Parent.Parent.UI.Quest.QuestUI)

	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	local hasSelectedClass = false
	local playerLevel = 1
	local questsData = {}
	
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
		
		return "Available"
	end

	local function buildQuestList(mode, npcName)
		local list = {}
		for qId, config in pairs(Quests) do
			if type(config) == "table" and config.id then
				local qData = questsData[qId]
				local status = getQuestStatus(config, qData)
				
				local include = false
				if mode == "npc" then
					if config.npcName == npcName then
						include = true
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
						sortOrder = (status == "Ready" and 1) or (status == "Available" and 2) or (status == "Accepted" and 3) or (status == "Locked" and 4) or 5
					})
				end
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
		if ui:IsVisible() then
			local list = buildQuestList(ui._mode, ui._lastNpcName)
			ui:Populate(ui._mode, list, ui._lastNpcName)
		end
	end

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
				progress = payload.progress
			}
		end
		refreshUI()
	end)
	
	remotes.OpenQuest.OnClientEvent:Connect(function(npcName)
		ui._lastNpcName = npcName
		ui:Populate("npc", buildQuestList("npc", npcName), npcName)
		ui:SetVisible(true)
	end)
end

return Controller
