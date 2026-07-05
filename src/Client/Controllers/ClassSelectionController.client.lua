local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Framework = require(Shared.Framework)

local ClassSelectionUI = require(script.Parent.Parent.UI.ClassSelection.ClassSelectionUI)

local ClassSelectionController = {}
ClassSelectionController._ui = nil
ClassSelectionController._hasSelectedClass = false
ClassSelectionController._remotes = nil

function ClassSelectionController:Init()
	local player = Players.LocalPlayer
	self._remotes = ReplicatedStorage:WaitForChild("Remotes")
	self._ui = ClassSelectionUI.new(player:WaitForChild("PlayerGui"))

	self._ui:OnConfirm(function(classId)
		self._remotes.SelectClass:FireServer(classId)
	end)

	self._remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
		self:OnStatsUpdated(payload)
	end)

	self._remotes.ClassSelected.OnClientEvent:Connect(function()
		self._hasSelectedClass = true
		self._ui:Hide()
	end)
end

function ClassSelectionController:OnStatsUpdated(payload)
	if payload.hasSelectedClass then
		self._hasSelectedClass = true
		self._ui:Hide()
	elseif not self._hasSelectedClass and not self._ui:IsVisible() then
		self._ui:Show()
	end
end

function ClassSelectionController:Start()
	task.defer(function()
		if not self._hasSelectedClass then
			self._ui:Show()
		end
	end)
end

Framework:RegisterController("ClassSelectionController", ClassSelectionController)
ClassSelectionController:Init()
ClassSelectionController:Start()

return ClassSelectionController
