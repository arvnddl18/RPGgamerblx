local QuestLogUI = {}
QuestLogUI.__index = QuestLogUI

function QuestLogUI.new(playerGui)
	local self = setmetatable({}, QuestLogUI)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuestLogUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "QuestLogPanel"
	panel.Size = UDim2.new(0, 320, 0, 180)
	panel.Position = UDim2.new(0.5, -160, 0.5, -90)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui
	self._panel = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 32)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "Quest Log (J to close)"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -20, 1, -50)
	body.Position = UDim2.new(0, 10, 0, 44)
	body.BackgroundTransparency = 1
	body.Text = "No active quest."
	body.TextColor3 = Color3.fromRGB(200, 200, 210)
	body.Font = Enum.Font.Gotham
	body.TextSize = 14
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Parent = panel
	self._body = body

	return self
end

function QuestLogUI:SetVisible(visible)
	self._panel.Visible = visible
end

function QuestLogUI:IsVisible()
	return self._panel.Visible
end

function QuestLogUI:Update(quest)
	if not quest or not quest.accepted then
		self._body.Text = "No active quest.\n\nVisit NPCs to find quests!"
		return
	end

	if quest.completed then
		self._body.Text = quest.name .. "\n\nStatus: Complete!"
		return
	end

	local progressText = "Progress: " .. (quest.progress or 0) .. "/" .. (quest.required or "?")
	self._body.Text = quest.name .. "\n\n" .. (quest.description or "") .. "\n\n" .. progressText
end

return QuestLogUI
