local TweenService = game:GetService("TweenService")

local QuestLogUI = {}
QuestLogUI.__index = QuestLogUI

function QuestLogUI.new(playerGui)
	local self = setmetatable({}, QuestLogUI)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuestLogUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Create a container that will handle animations
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Visible = false
	container.Parent = screenGui
	self._container = container

	local panel = Instance.new("CanvasGroup")
	panel.Name = "QuestLogPanel"
	panel.Size = UDim2.new(0, 340, 0, 220)
	panel.Position = UDim2.new(0.5, -170, 0.5, -110)
	panel.BackgroundColor3 = Color3.fromRGB(30, 32, 45)
	panel.BorderSizePixel = 0
	panel.Parent = container
	self._panel = panel

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 48, 65)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 22, 30))
	})
	gradient.Rotation = 45
	gradient.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 85, 110)
	stroke.Thickness = 2
	stroke.Parent = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	-- Glow effect
	local glow = Instance.new("ImageLabel")
	glow.Name = "Glow"
	glow.Size = UDim2.new(1, 40, 1, 40)
	glow.Position = UDim2.new(0, -20, 0, -20)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://5028857472"
	glow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	glow.ImageTransparency = 0.4
	glow.SliceCenter = Rect.new(24, 24, 276, 276)
	glow.ZIndex = 0
	glow.Parent = panel

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 45)
	header.BackgroundColor3 = Color3.fromRGB(25, 27, 40)
	header.BackgroundTransparency = 0.5
	header.BorderSizePixel = 0
	header.Parent = panel

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header

	-- Bottom flat to connect with body
	local headerFlat = Instance.new("Frame")
	headerFlat.Size = UDim2.new(1, 0, 0, 12)
	headerFlat.Position = UDim2.new(0, 0, 1, -12)
	headerFlat.BackgroundColor3 = header.BackgroundColor3
	headerFlat.BackgroundTransparency = header.BackgroundTransparency
	headerFlat.BorderSizePixel = 0
	headerFlat.Parent = header

	local headerStroke = Instance.new("Frame")
	headerStroke.Size = UDim2.new(1, 0, 0, 1)
	headerStroke.Position = UDim2.new(0, 0, 1, -1)
	headerStroke.BackgroundColor3 = Color3.fromRGB(80, 85, 110)
	headerStroke.BorderSizePixel = 0
	headerStroke.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -30, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "QUEST LOG"
	title.TextColor3 = Color3.fromRGB(240, 200, 100)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(0, 100, 1, 0)
	hint.Position = UDim2.new(1, -115, 0, 0)
	hint.BackgroundTransparency = 1
	hint.Text = "Press J to close"
	hint.TextColor3 = Color3.fromRGB(150, 150, 170)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 12
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Parent = header

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -30, 1, -65)
	body.Position = UDim2.new(0, 15, 0, 55)
	body.BackgroundTransparency = 1
	body.Text = "No active quest."
	body.TextColor3 = Color3.fromRGB(220, 220, 230)
	body.Font = Enum.Font.GothamSemibold
	body.TextSize = 15
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.RichText = true
	body.Parent = panel
	self._body = body

	return self
end

function QuestLogUI:SetVisible(visible)
	if visible == self._container.Visible then
		return
	end

	if visible then
		self._container.Visible = true
		self._panel.Size = UDim2.new(0, 300, 0, 180)
		self._panel.Position = UDim2.new(0.5, -150, 0.5, -90)
		self._panel.GroupTransparency = 1

		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(self._panel, tweenInfo, {
			Size = UDim2.new(0, 340, 0, 220),
			Position = UDim2.new(0.5, -170, 0.5, -110),
			GroupTransparency = 0
		}):Play()
	else
		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tween = TweenService:Create(self._panel, tweenInfo, {
			Size = UDim2.new(0, 300, 0, 180),
			Position = UDim2.new(0.5, -150, 0.5, -90),
			GroupTransparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function()
			if self._panel.GroupTransparency >= 0.99 then
				self._container.Visible = false
			end
		end)
	end
end

function QuestLogUI:IsVisible()
	return self._container.Visible
end

function QuestLogUI:Update(quest)
	if not quest or not quest.accepted then
		self._body.Text = "<font color=\"#888899\">No active quest.\n\nVisit NPCs in the village to find quests!</font>"
		return
	end

	local titleColor = "#FFD700"
	if quest.completed then
		self._body.Text = "<font size=\"20\" color=\""..titleColor.."\"><b>" .. (quest.name or "Unknown Quest") .. "</b></font>\n\n<font color=\"#66FF66\">Status: Complete! Return to the quest giver.</font>"
		return
	end

	local progressText = "<font color=\"#88AAFF\">Progress: " .. (quest.progress or 0) .. " / " .. (quest.required or "?") .. "</font>"
	local desc = "<font color=\"#CCCCCC\">" .. (quest.description or "") .. "</font>"
	self._body.Text = "<font size=\"20\" color=\""..titleColor.."\"><b>" .. (quest.name or "Unknown Quest") .. "</b></font>\n\n" .. desc .. "\n\n" .. progressText
end

return QuestLogUI
