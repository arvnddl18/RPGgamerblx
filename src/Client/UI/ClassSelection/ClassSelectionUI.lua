local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Classes = require(Shared.Config.Classes)
local ClassCard = require(script.Parent.ClassCard)

local ClassSelectionUI = {}
ClassSelectionUI.__index = ClassSelectionUI

function ClassSelectionUI.new(playerGui)
	local self = setmetatable({}, ClassSelectionUI)
	self._selectedClassId = nil
	self._cards = {}
	self._onConfirm = nil

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ClassSelectionUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
	overlay.BackgroundTransparency = 0.15
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui
	self._overlay = overlay

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 48)
	title.Position = UDim2.new(0, 0, 0, 24)
	title.BackgroundTransparency = 1
	title.Text = "Choose Your Class"
	title.TextColor3 = Color3.fromRGB(255, 220, 100)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 32
	title.Parent = overlay

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0, 24)
	subtitle.Position = UDim2.new(0, 0, 0, 72)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Your class determines your stats, equipment, and skills."
	subtitle.TextColor3 = Color3.fromRGB(180, 180, 200)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 14
	subtitle.Parent = overlay

	local cardContainer = Instance.new("Frame")
	cardContainer.Name = "CardContainer"
	cardContainer.Size = UDim2.new(1, -40, 0, 280)
	cardContainer.Position = UDim2.new(0, 20, 0.5, -120)
	cardContainer.BackgroundTransparency = 1
	cardContainer.Parent = overlay

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 12)
	layout.Parent = cardContainer

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = "ConfirmButton"
	confirmBtn.Size = UDim2.new(0, 200, 0, 44)
	confirmBtn.Position = UDim2.new(0.5, -100, 1, -80)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 80)
	confirmBtn.Text = "Confirm Class"
	confirmBtn.TextColor3 = Color3.new(1, 1, 1)
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.TextSize = 16
	confirmBtn.Visible = false
	confirmBtn.Parent = overlay
	self._confirmBtn = confirmBtn

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 8)
	confirmCorner.Parent = confirmBtn

	for _, classConfig in Classes.GetAll() do
		local card = ClassCard.new(cardContainer, classConfig, function(classId)
			self:SelectClass(classId)
		end)
		self._cards[classConfig.id] = card
	end

	confirmBtn.MouseButton1Click:Connect(function()
		if self._selectedClassId and self._onConfirm then
			self._onConfirm(self._selectedClassId)
		end
	end)

	self:Hide()
	return self
end

function ClassSelectionUI:SelectClass(classId)
	self._selectedClassId = classId
	for id, card in self._cards do
		card:SetSelected(id == classId)
	end
	self._confirmBtn.Visible = true
end

function ClassSelectionUI:OnConfirm(callback)
	self._onConfirm = callback
end

function ClassSelectionUI:Show()
	self._overlay.Visible = true
	self._selectedClassId = nil
	self._confirmBtn.Visible = false
	for _, card in self._cards do
		card:SetSelected(false)
	end
end

function ClassSelectionUI:Hide()
	self._overlay.Visible = false
end

function ClassSelectionUI:IsVisible()
	return self._overlay.Visible
end

return ClassSelectionUI
