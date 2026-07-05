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
	-- Create UI immediately without waiting for remotes
	self._ui = ClassSelectionUI.new(player:WaitForChild("PlayerGui"))

	-- Connect to remotes asynchronously so UI creation isn't blocked by server map generation
	task.spawn(function()
		self._remotes = ReplicatedStorage:WaitForChild("Remotes")

		self._ui:OnConfirm(function(classId)
			if self._remotes then
				self._remotes.SelectClass:FireServer(classId)
			end
		end)

		self._remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
			self:OnStatsUpdated(payload)
		end)

		self._remotes.ClassSelected.OnClientEvent:Connect(function()
			self._hasSelectedClass = true
			if self._ui then
				self._ui:Hide()
			end
		end)

		-- Now that remotes are connected, show UI if no class selected yet
		if not self._hasSelectedClass and self._ui and not self._ui:IsVisible() then
			self._ui:Show()
		end
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
	-- Show UI immediately if no class selected yet
	if not self._hasSelectedClass and self._ui then
		self._ui:Show()
	end
end

Framework:RegisterController("ClassSelectionController", ClassSelectionController)
ClassSelectionController:Init()
ClassSelectionController:Start()

return ClassSelectionController
