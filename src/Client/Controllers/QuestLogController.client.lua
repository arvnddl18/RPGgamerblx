local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local QuestLogUI = require(script.Parent.Parent.UI.Quest.QuestLogUI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hasSelectedClass = false
local questData = {}
local questLog = QuestLogUI.new(player:WaitForChild("PlayerGui"))

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not hasSelectedClass then
		return
	end
	if input.KeyCode == Enum.KeyCode.J then
		questLog:SetVisible(not questLog:IsVisible())
	end
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	hasSelectedClass = payload.hasSelectedClass == true
	if payload.quest then
		questData.accepted = payload.quest.accepted
		questData.completed = payload.quest.completed
		questData.progress = payload.quest.progress
	end
	questLog:Update(questData)
end)

remotes.QuestUpdated.OnClientEvent:Connect(function(payload)
	questData = payload
	questLog:Update(questData)
end)
