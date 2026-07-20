-- Reference-style comic dialogue overlay.
-- Supports the existing server payload:
-- { title = "...", panels = { { speaker = "...", text = "...", color = Color3 } } }
-- Optional panel fields: side, portrait, leftSpeaker, rightSpeaker, leftColor, rightColor.
local Controller = {}

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addTextConstraint(parent, minSize, maxSize)
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = minSize
	constraint.MaxTextSize = maxSize
	constraint.Parent = parent
	return constraint
end

local function initials(name)
	local result = "?"
	if type(name) == "string" and name ~= "" then
		local first = string.sub(name, 1, 1)
		local last = string.match(name, "%s+(%S+)$")
		result = string.upper(first .. (last and string.sub(last, 1, 1) or ""))
	end
	return result
end

function Controller:Start()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local localPlayer = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local Quests = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Quests"))
	local openScene = remotes:WaitForChild("OpenComicScene")
	local completeScene = remotes:WaitForChild("CompleteComicScene")
	local acceptQuest = remotes:WaitForChild("AcceptQuest")
	local turnInQuest = remotes:WaitForChild("TurnInQuest")

	local gui = Instance.new("ScreenGui")
	gui.Name = "ComicDialogueUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 250
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	-- Keep every dialogue child hidden during startup. Individual children
	-- default to visible, so the whole overlay must be enabled only for an
	-- actual scene.
	gui.Enabled = false
	gui.Parent = playerGui

	-- Dimmed background, matching the supplied visual reference.
	local dim = Instance.new("Frame")
	dim.Name = "DimmedWorld"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.fromRGB(3, 5, 12)
	dim.BackgroundTransparency = 0.22
	dim.Visible = false
	dim.Active = true
	dim.ZIndex = 1
	dim.Parent = gui

	local vignette = Instance.new("Frame")
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.fromRGB(8, 5, 18)
	vignette.BackgroundTransparency = 0.72
	vignette.BorderSizePixel = 0
	vignette.ZIndex = 2
	vignette.Parent = dim

	local title = Instance.new("TextLabel")
	title.Name = "SceneTitle"
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0.055)
	title.Size = UDim2.fromScale(0.6, 0.055)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(232, 203, 134)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextTransparency = 0.05
	title.ZIndex = 8
	title.Parent = gui
	addTextConstraint(title, 16, 30)

	local close = Instance.new("TextButton")
	close.Name = "CloseButton"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -24, 0, 20)
	close.Size = UDim2.fromOffset(46, 46)
	close.BackgroundColor3 = Color3.fromRGB(20, 18, 25)
	close.BackgroundTransparency = 0.15
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(238, 238, 238)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 22
	close.AutoButtonColor = true
	close.ZIndex = 12
	close.Parent = gui
	addCorner(close, 8)
	addStroke(close, Color3.fromRGB(170, 170, 170), 1)

	local function createPortrait(name, anchor, position)
		local frame = Instance.new("Frame")
		frame.Name = name .. "Portrait"
		frame.AnchorPoint = anchor
		frame.Position = position
		frame.Size = UDim2.fromScale(0.30, 0.68)
		frame.BackgroundColor3 = Color3.fromRGB(75, 72, 92)
		frame.BackgroundTransparency = 0.08
		frame.BorderSizePixel = 0
		frame.ZIndex = 4
		frame.Parent = gui
		addCorner(frame, 18)
		local portraitStroke = addStroke(frame, Color3.fromRGB(87, 205, 215), 3)
		portraitStroke.Name = "FocusStroke"
		local focusScale = Instance.new("UIScale")
		focusScale.Name = "FocusScale"
		focusScale.Scale = 1
		focusScale.Parent = frame

		-- Procedural comic bust fallback. This keeps the reference layout
		-- readable even before uploaded Roblox portrait assets are available.
		local portraitArt = Instance.new("Frame")
		portraitArt.Name = "PortraitArt"
		portraitArt.AnchorPoint = Vector2.new(0.5, 0)
		portraitArt.Position = UDim2.fromScale(0.5, 0.04)
		portraitArt.Size = UDim2.fromScale(0.82, 0.82)
		portraitArt.BackgroundColor3 = Color3.fromRGB(43, 47, 72)
		portraitArt.BackgroundTransparency = 0.12
		portraitArt.BorderSizePixel = 0
		portraitArt.ZIndex = 4
		portraitArt.Parent = frame
		addCorner(portraitArt, 16)

		local body = Instance.new("Frame")
		body.Name = "Body"
		body.AnchorPoint = Vector2.new(0.5, 1)
		body.Position = UDim2.new(0.5, 0, 1, 0)
		body.Size = UDim2.fromScale(0.68, 0.56)
		body.BackgroundColor3 = Color3.fromRGB(73, 105, 145)
		body.BorderSizePixel = 0
		body.ZIndex = 4
		body.Parent = portraitArt
		addCorner(body, 28)

		local neck = Instance.new("Frame")
		neck.Name = "Neck"
		neck.AnchorPoint = Vector2.new(0.5, 1)
		neck.Position = UDim2.new(0.5, 0, 0.56, 0)
		neck.Size = UDim2.fromScale(0.18, 0.18)
		neck.BackgroundColor3 = Color3.fromRGB(214, 158, 125)
		neck.BorderSizePixel = 0
		neck.ZIndex = 5
		neck.Parent = portraitArt

		local head = Instance.new("Frame")
		head.Name = "Head"
		head.AnchorPoint = Vector2.new(0.5, 0.5)
		head.Position = UDim2.fromScale(0.5, 0.37)
		head.Size = UDim2.fromScale(0.38, 0.40)
		head.BackgroundColor3 = Color3.fromRGB(236, 182, 145)
		head.BorderSizePixel = 0
		head.ZIndex = 6
		head.Parent = portraitArt
		addCorner(head, 32)

		local hair = Instance.new("Frame")
		hair.Name = "Hair"
		hair.AnchorPoint = Vector2.new(0.5, 1)
		hair.Position = UDim2.new(0.5, 0, 0.27, 0)
		hair.Size = UDim2.fromScale(0.43, 0.18)
		hair.BackgroundColor3 = Color3.fromRGB(48, 35, 43)
		hair.BorderSizePixel = 0
		hair.ZIndex = 7
		hair.Parent = portraitArt
		addCorner(hair, 18)

		for _, x in ipairs({0.39, 0.61}) do
			local eye = Instance.new("Frame")
			eye.Name = "Eye"
			eye.AnchorPoint = Vector2.new(0.5, 0.5)
			eye.Position = UDim2.fromScale(x, 0.38)
			eye.Size = UDim2.fromScale(0.055, 0.055)
			eye.BackgroundColor3 = Color3.fromRGB(40, 35, 45)
			eye.BorderSizePixel = 0
			eye.ZIndex = 8
			eye.Parent = portraitArt
			addCorner(eye, 12)
		end

		local image = Instance.new("ImageLabel")
		image.Name = "PortraitImage"
		image.Size = UDim2.fromScale(1, 1)
		image.BackgroundTransparency = 1
		image.ImageTransparency = 0
		image.ScaleType = Enum.ScaleType.Fit
		image.Visible = false
		image.ZIndex = 9
		image.Parent = frame

		local fallback = Instance.new("TextLabel")
		fallback.Name = "PortraitInitials"
		fallback.AnchorPoint = Vector2.new(0, 0)
		fallback.Position = UDim2.fromScale(0.04, 0.04)
		fallback.Size = UDim2.fromScale(0.20, 0.11)
		fallback.BackgroundColor3 = Color3.fromRGB(20, 17, 24)
		fallback.BackgroundTransparency = 0.12
		fallback.Text = "?"
		fallback.TextColor3 = Color3.fromRGB(245, 238, 221)
		fallback.Font = Enum.Font.GothamBlack
		fallback.TextScaled = true
		fallback.ZIndex = 10
		fallback.Parent = frame
		addCorner(fallback, 6)
		addTextConstraint(fallback, 10, 22)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "CharacterName"
		nameLabel.AnchorPoint = Vector2.new(0.5, 1)
		nameLabel.Position = UDim2.new(0.5, 0, 1, -10)
		nameLabel.Size = UDim2.new(0.9, 0, 0, 28)
		nameLabel.BackgroundColor3 = Color3.fromRGB(20, 17, 24)
		nameLabel.BackgroundTransparency = 0.12
		nameLabel.TextColor3 = Color3.fromRGB(255, 228, 155)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextScaled = true
		nameLabel.Text = ""
		nameLabel.ZIndex = 7
		nameLabel.Parent = frame
		addCorner(nameLabel, 6)
		addTextConstraint(nameLabel, 10, 18)

		return frame, image, fallback, nameLabel
	end

	local leftPortrait, leftImage, leftFallback, leftName = createPortrait("Left", Vector2.new(0, 1), UDim2.fromScale(0.025, 0.89))
	local rightPortrait, rightImage, rightFallback, rightName = createPortrait("Right", Vector2.new(1, 1), UDim2.fromScale(0.975, 0.89))

	local dialogue = Instance.new("Frame")
	dialogue.Name = "DialogueBox"
	dialogue.AnchorPoint = Vector2.new(0.5, 1)
	dialogue.Position = UDim2.fromScale(0.5, 0.89)
	dialogue.Size = UDim2.fromScale(0.44, 0.25)
	dialogue.BackgroundColor3 = Color3.fromRGB(238, 226, 202)
	dialogue.BorderSizePixel = 0
	dialogue.ZIndex = 8
	dialogue.Parent = gui
	addCorner(dialogue, 9)
	addStroke(dialogue, Color3.fromRGB(82, 62, 46), 3)

	local nameplate = Instance.new("TextLabel")
	nameplate.Name = "SpeakerNameplate"
	nameplate.AnchorPoint = Vector2.new(0.5, 0.5)
	nameplate.Position = UDim2.new(0.5, 0, 0, 0)
	nameplate.Size = UDim2.fromScale(0.42, 0.25)
	nameplate.BackgroundColor3 = Color3.fromRGB(166, 119, 55)
	nameplate.TextColor3 = Color3.fromRGB(255, 244, 208)
	nameplate.Font = Enum.Font.GothamBold
	nameplate.TextScaled = true
	nameplate.Text = ""
	nameplate.ZIndex = 10
	nameplate.Parent = dialogue
	addCorner(nameplate, 7)
	addStroke(nameplate, Color3.fromRGB(245, 207, 117), 2)
	addTextConstraint(nameplate, 12, 24)

	local body = Instance.new("TextLabel")
	body.Name = "DialogueText"
	body.Position = UDim2.fromScale(0.06, 0.25)
	body.Size = UDim2.fromScale(0.88, 0.60)
	body.BackgroundTransparency = 1
	body.TextColor3 = Color3.fromRGB(45, 38, 34)
	body.Font = Enum.Font.GothamMedium
	body.TextSize = 22
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Text = ""
	body.ZIndex = 9
	body.Parent = dialogue
	addTextConstraint(body, 14, 25)

	local nextButton = Instance.new("TextButton")
	nextButton.Name = "NextButton"
	nextButton.AnchorPoint = Vector2.new(1, 1)
	nextButton.Position = UDim2.new(1, -12, 1, -10)
	nextButton.Size = UDim2.fromOffset(132, 34)
	nextButton.BackgroundColor3 = Color3.fromRGB(77, 116, 92)
	nextButton.Text = "NEXT  >"
	nextButton.TextColor3 = Color3.new(1, 1, 1)
	nextButton.Font = Enum.Font.GothamBold
	nextButton.TextSize = 16
	nextButton.AutoButtonColor = true
	nextButton.ZIndex = 11
	nextButton.Parent = dialogue
	addCorner(nextButton, 7)

	local questCard = Instance.new("Frame")
	questCard.Name = "QuestAcceptanceCard"
	questCard.Position = UDim2.fromScale(0.04, 0.10)
	questCard.Size = UDim2.fromScale(0.92, 0.82)
	questCard.BackgroundColor3 = Color3.fromRGB(238, 226, 202)
	questCard.BorderSizePixel = 0
	questCard.Visible = false
	questCard.ZIndex = 10
	questCard.Parent = dialogue
	addCorner(questCard, 7)

	local questCardTitle = Instance.new("TextLabel")
	questCardTitle.Size = UDim2.new(1, -24, 0, 30)
	questCardTitle.Position = UDim2.new(0, 12, 0, 8)
	questCardTitle.BackgroundTransparency = 1
	questCardTitle.TextColor3 = Color3.fromRGB(70, 48, 28)
	questCardTitle.Font = Enum.Font.GothamBold
	questCardTitle.TextSize = 19
	questCardTitle.TextXAlignment = Enum.TextXAlignment.Left
	questCardTitle.Text = "QUEST"
	questCardTitle.ZIndex = 11
	questCardTitle.Parent = questCard

	-- Keep the requirement text in a scrollable body with a dedicated footer
	-- area, so long child-friendly instructions never sit underneath buttons.
	local questCardObjectiveScroll = Instance.new("ScrollingFrame")
	questCardObjectiveScroll.Name = "QuestRequirementsScroll"
	questCardObjectiveScroll.Size = UDim2.new(1, -24, 1, -94)
	questCardObjectiveScroll.Position = UDim2.new(0, 12, 0, 38)
	questCardObjectiveScroll.BackgroundTransparency = 1
	questCardObjectiveScroll.BorderSizePixel = 0
	questCardObjectiveScroll.ScrollBarThickness = 5
	questCardObjectiveScroll.ScrollBarImageColor3 = Color3.fromRGB(166, 119, 55)
	questCardObjectiveScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	questCardObjectiveScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	questCardObjectiveScroll.ZIndex = 11
	questCardObjectiveScroll.Parent = questCard

	local questCardObjective = Instance.new("TextLabel")
	questCardObjective.Size = UDim2.new(1, -8, 0, 0)
	questCardObjective.AutomaticSize = Enum.AutomaticSize.Y
	questCardObjective.Position = UDim2.new(0, 0, 0, 0)
	questCardObjective.BackgroundTransparency = 1
	questCardObjective.TextColor3 = Color3.fromRGB(62, 54, 45)
	questCardObjective.Font = Enum.Font.Gotham
	questCardObjective.TextSize = 15
	questCardObjective.TextWrapped = true
	questCardObjective.TextXAlignment = Enum.TextXAlignment.Left
	questCardObjective.TextYAlignment = Enum.TextYAlignment.Top
	questCardObjective.Text = ""
	questCardObjective.ZIndex = 11
	questCardObjective.Parent = questCardObjectiveScroll
	questCardObjectiveScroll.CanvasSize = UDim2.new(0, 0, 0, questCardObjective.TextBounds.Y + 12)
	questCardObjective:GetPropertyChangedSignal("TextBounds"):Connect(function()
		questCardObjectiveScroll.CanvasSize = UDim2.new(0, 0, 0, questCardObjective.TextBounds.Y + 12)
	end)

	local acceptButton = Instance.new("TextButton")
	acceptButton.Name = "AcceptQuestButton"
	acceptButton.AnchorPoint = Vector2.new(0, 1)
	acceptButton.Position = UDim2.new(0, 12, 1, -10)
	acceptButton.Size = UDim2.new(0.48, -16, 0, 34)
	acceptButton.BackgroundColor3 = Color3.fromRGB(77, 126, 84)
	acceptButton.Text = "ACCEPT QUEST"
	acceptButton.TextColor3 = Color3.new(1, 1, 1)
	acceptButton.Font = Enum.Font.GothamBold
	acceptButton.TextSize = 14
	acceptButton.ZIndex = 12
	acceptButton.Parent = questCard
	addCorner(acceptButton, 6)

	local declineButton = Instance.new("TextButton")
	declineButton.Name = "DeclineQuestButton"
	declineButton.AnchorPoint = Vector2.new(1, 1)
	declineButton.Position = UDim2.new(1, -12, 1, -10)
	declineButton.Size = UDim2.new(0.48, -16, 0, 34)
	declineButton.BackgroundColor3 = Color3.fromRGB(95, 82, 72)
	declineButton.Text = "NOT YET"
	declineButton.TextColor3 = Color3.fromRGB(255, 246, 230)
	declineButton.Font = Enum.Font.GothamBold
	declineButton.TextSize = 14
	declineButton.ZIndex = 12
	declineButton.Parent = questCard
	addCorner(declineButton, 6)

	local autoPlay = Instance.new("TextButton")
	autoPlay.Name = "AutoPlay"
	autoPlay.AnchorPoint = Vector2.new(1, 1)
	autoPlay.Position = UDim2.new(1, -22, 1, -18)
	autoPlay.Size = UDim2.fromOffset(118, 26)
	autoPlay.BackgroundTransparency = 1
	autoPlay.Text = "[ ] Auto-Play"
	autoPlay.TextColor3 = Color3.fromRGB(235, 235, 235)
	autoPlay.Font = Enum.Font.Gotham
	autoPlay.TextSize = 13
	autoPlay.ZIndex = 10
	autoPlay.Parent = gui

	local skip = Instance.new("TextButton")
	skip.Name = "SkipButton"
	skip.AnchorPoint = Vector2.new(0, 1)
	skip.Position = UDim2.new(0, 22, 1, -18)
	skip.Size = UDim2.fromOffset(110, 26)
	skip.BackgroundTransparency = 1
	skip.Text = "Skip scene"
	skip.TextColor3 = Color3.fromRGB(220, 215, 205)
	skip.Font = Enum.Font.Gotham
	skip.TextSize = 13
	skip.ZIndex = 10
	skip.Parent = gui

	local activeSceneId, panels, index = nil, nil, 0
	local activeSceneTitle = ""
	local activeSceneNpcName = ""
	local activeQuestId = nil
	local activeTurnInQuestId = nil
	local autoEnabled = false
	local autoToken = 0
	local typingToken = 0
	local isTyping = false
	local fullBodyText = ""
	local dialogueBasePosition = UDim2.fromScale(0.5, 0.89)
	local leftPortraitBasePosition = UDim2.fromScale(0.025, 0.89)
	local rightPortraitBasePosition = UDim2.fromScale(0.975, 0.89)

	local function stopDialogueSounds()
		local workspace = game:GetService("Workspace")
		local audioFolder = workspace:FindFirstChild("Audio")
		if audioFolder then
			local options = {"PVZ Crazy Dave Talking", "PVZ Crazy Dave Talking 2", "PVZ Crazy Dave Talking 3"}
			for _, soundName in ipairs(options) do
				local s = audioFolder:FindFirstChild(soundName)
				if s and s:IsA("Sound") then
					s:Stop()
				end
			end
		end
	end

	local function finishTyping()
		if not isTyping then return false end
		typingToken += 1
		body.Text = fullBodyText
		body.TextTransparency = 0
		isTyping = false
		stopDialogueSounds()
		return true
	end

	local lastTalkSound = 0
	local lastTalkSoundTime = 0
	
	local function typeDialogueText(text, token)
		fullBodyText = text or ""
		body.Text = ""
		body.TextTransparency = 0
		isTyping = true
		for characterIndex = 1, string.len(fullBodyText) do
			if token ~= typingToken or not activeSceneId then return end
			
			local currentCharacter = string.sub(fullBodyText, characterIndex, characterIndex)
			
			-- Play talking sound for NPCs
			if string.match(currentCharacter, "%S") and characterIndex % 3 == 0 then
				local Players = game:GetService("Players")
				if nameplate.Text ~= string.upper(Players.LocalPlayer.Name) then
					local workspace = game:GetService("Workspace")
					local audioFolder = workspace:FindFirstChild("Audio")
					if audioFolder then
						local options = {"PVZ Crazy Dave Talking", "PVZ Crazy Dave Talking 2", "PVZ Crazy Dave Talking 3"}
						
						if tick() - lastTalkSoundTime > 0.45 then
							lastTalkSoundTime = tick()
							local r = math.random(1, 3)
							if r == lastTalkSound then
								r = r % 3 + 1
							end
							lastTalkSound = r
							local MusicController = require(script.Parent.Parent.Effects.MusicController)
							MusicController:Play8DASMR(options[r])
						end
					end
				end
			end
			
			body.Text = string.sub(fullBodyText, 1, characterIndex)
			task.wait(0.026)
		end
		if token == typingToken then
			body.Text = fullBodyText
			isTyping = false
		end
	end

	local function animatePanelIn(side)
		local incomingX = side == "left" and -0.015 or 1.015
		dialogue.Position = UDim2.fromScale(0.5, 0.92)
		leftPortrait.Position = UDim2.fromScale(incomingX, 0.89)
		rightPortrait.Position = UDim2.fromScale(side == "left" and 1.015 or 1.03, 0.89)
		nameplate.Size = UDim2.fromScale(0.34, 0.19)
		TweenService:Create(dialogue, TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = dialogueBasePosition }):Play()
		TweenService:Create(leftPortrait, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = leftPortraitBasePosition }):Play()
		TweenService:Create(rightPortrait, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = rightPortraitBasePosition }):Play()
		TweenService:Create(nameplate, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.42, 0.25) }):Play()
	end

	local function setPortrait(frame, image, fallback, nameLabel, speaker, color, portrait, isActiveSpeaker)
		local active = isActiveSpeaker == true
		-- Keep both comic characters visible like the reference layout. The
		-- inactive side is dimmed instead of disappearing, which helps players
		-- follow who is present in the conversation.
		frame.Visible = true
		local focusColor = color or Color3.fromRGB(75, 72, 92)
		local focusStroke = frame:FindFirstChild("FocusStroke")
		local focusScale = frame:FindFirstChild("FocusScale")
		TweenService:Create(frame, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = active and focusColor or Color3.fromRGB(45, 44, 55),
			BackgroundTransparency = active and 0.02 or 0.58,
		}):Play()
		if focusStroke then
			TweenService:Create(focusStroke, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Color = active and Color3.fromRGB(255, 210, 105) or Color3.fromRGB(70, 72, 88),
				Thickness = active and 4 or 1,
			}):Play()
		end
		if focusScale then
			TweenService:Create(focusScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = active and 1.035 or 0.965,
			}):Play()
		end
		local art = frame:FindFirstChild("PortraitArt")
		if art then
			TweenService:Create(art, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = active and 0.08 or 0.78,
			}):Play()
			for _, child in ipairs(art:GetDescendants()) do
				if child:IsA("GuiObject") then
					child.BackgroundTransparency = active and 0 or 0.78
				end
			end
		end
		nameLabel.Text = speaker
		TweenService:Create(nameLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = active and 0 or 0.62,
			BackgroundTransparency = active and 0.08 or 0.62,
		}):Play()
		fallback.Text = initials(speaker)
		TweenService:Create(fallback, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = active and 0 or 0.72,
			BackgroundTransparency = active and 0.12 or 0.72,
		}):Play()
		TweenService:Create(image, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = active and 0 or 0.72,
			ImageColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(135, 138, 155),
		}):Play()
		if type(portrait) == "string" and portrait ~= "" then
			image.Image = portrait
			image.Visible = true
			fallback.Visible = false
		else
			image.Visible = false
			fallback.Visible = true
		end
	end

	local function closeScene(openQuestPanel)
		stopDialogueSounds()
		if not activeSceneId then return end
		local sceneId = activeSceneId
		activeSceneId, panels, index, activeQuestId, activeTurnInQuestId, activeSceneTitle, activeSceneNpcName = nil, nil, 0, nil, nil, "", ""
		autoToken += 1
		typingToken += 1
		isTyping = false
		gui.Enabled = false
		dim.Visible = false
		title.Visible = false
		close.Visible = false
		dialogue.Visible = false
		questCard.Visible = false
		leftPortrait.Visible = false
		rightPortrait.Visible = false
		autoPlay.Visible = false
		skip.Visible = false
		completeScene:FireServer(sceneId, openQuestPanel ~= false)
	end

	local function showPanel()
		stopDialogueSounds()
		local panel = panels and panels[index]
		if not panel then
			closeScene()
			return
		end

		autoToken += 1
		typingToken += 1
		local token = autoToken
		local textToken = typingToken
		local panelText = panel.text or ""
		title.Text = panel.title or activeSceneTitle
		nameplate.Text = string.upper(panel.speaker or "Unknown")
		body.Text = ""
		nextButton.Text = index >= #panels and "CONTINUE" or "NEXT  >"
		local finalQuestPanel = index >= #panels and (activeQuestId ~= nil or activeTurnInQuestId ~= nil)
		questCard.Visible = finalQuestPanel
		body.Visible = not finalQuestPanel
		nextButton.Visible = not finalQuestPanel
		if finalQuestPanel then
			local questId = activeQuestId or activeTurnInQuestId
			local config = Quests[questId]
			local turningIn = activeTurnInQuestId ~= nil
			questCardTitle.Text = turningIn and ("COMPLETE: " .. (config and config.name or "Quest")) or (config and config.name or "New Quest")
			if config then
				questCardObjective.Text = (config.description or config.objective or "Continue the story.") .. "\n\n" .. Quests.GetRequirementText(config)
			else
				questCardObjective.Text = "Continue the story."
			end
			acceptButton.Text = turningIn and "TURN IN QUEST" or "ACCEPT QUEST"
			declineButton.Text = turningIn and "LATER" or "NOT YET"
		end
		acceptButton.Visible = finalQuestPanel and (activeQuestId ~= nil or activeTurnInQuestId ~= nil)
		declineButton.Visible = finalQuestPanel

		local side = panel.side or "right"
		local playerSpeaker = panel.playerSpeaker or localPlayer.Name
		if playerSpeaker == "Vanguard Recruit" or playerSpeaker == "" then
			playerSpeaker = localPlayer.Name
		end
		if panel.speaker == "Vanguard Recruit" then
			nameplate.Text = string.upper(playerSpeaker)
		end
		local activeSpeaker = panel.speaker or ""
		if activeSpeaker == "Vanguard Recruit" then
			activeSpeaker = playerSpeaker
		end
		local leftSpeaker = panel.leftSpeaker or (side == "left" and panel.speaker or "")
		local rightSpeaker = panel.rightSpeaker or (side == "right" and panel.speaker or "")
		if leftSpeaker == "Vanguard Recruit" then leftSpeaker = playerSpeaker end
		if rightSpeaker == "Vanguard Recruit" then rightSpeaker = playerSpeaker end
		if leftSpeaker == "" then leftSpeaker = playerSpeaker end
		if rightSpeaker == "" then rightSpeaker = playerSpeaker end
		-- A player-response panel can otherwise fill both portrait slots with
		-- the recruit. Prefer the quest giver in the opposite slot, and never
		-- render the same speaker twice.
		if leftSpeaker == rightSpeaker then
			if activeSpeaker == playerSpeaker then
				leftSpeaker = activeSceneNpcName ~= "" and activeSceneNpcName or ""
			else
				rightSpeaker = playerSpeaker
			end
		end
		setPortrait(leftPortrait, leftImage, leftFallback, leftName, leftSpeaker, panel.leftColor or panel.color, panel.leftPortrait, leftSpeaker == activeSpeaker)
		setPortrait(rightPortrait, rightImage, rightFallback, rightName, rightSpeaker, panel.rightColor or panel.color, panel.rightPortrait, rightSpeaker == activeSpeaker)
		animatePanelIn(side)

		if not finalQuestPanel then
			task.spawn(function()
				typeDialogueText(panelText, textToken)
			end)
		else
			isTyping = false
			local Players = game:GetService("Players")
			if nameplate.Text ~= string.upper(Players.LocalPlayer.Name) then
				local workspace = game:GetService("Workspace")
				local audioFolder = workspace:FindFirstChild("Audio")
				if audioFolder then
					local options = {"PVZ Crazy Dave Talking", "PVZ Crazy Dave Talking 2", "PVZ Crazy Dave Talking 3"}
					local r = math.random(1, 3)
					local s = audioFolder:FindFirstChild(options[r])
					if s and s:IsA("Sound") then
						s:Play()
					end
				end
			end
		end

		if side == "left" then
			nameplate.BackgroundColor3 = panel.color or Color3.fromRGB(166, 119, 55)
		else
			nameplate.BackgroundColor3 = panel.color or Color3.fromRGB(166, 119, 55)
		end

		if autoEnabled and not finalQuestPanel then
			task.delay(math.clamp(2.5 + string.len(panelText) * 0.026 + 1.2, 3.5, 10), function()
				if token == autoToken and activeSceneId then
					index += 1
					showPanel()
				end
			end)
		end
	end

	local function open(sceneId, scene)
		if activeSceneId or type(scene) ~= "table" or type(scene.panels) ~= "table" or #scene.panels == 0 then return end
		activeSceneId, panels, index, activeQuestId, activeTurnInQuestId, activeSceneTitle, activeSceneNpcName = sceneId, scene.panels, 1, scene.questId, scene.turnInQuestId, scene.title or "", scene.npcName or ""
		gui.Enabled = true
		dim.BackgroundTransparency = 1
		dim.Visible = true
		title.Visible = scene.title ~= nil
		title.TextTransparency = 1
		close.Visible = true
		dialogue.Visible = true
		leftPortrait.Visible = true
		rightPortrait.Visible = true
		autoPlay.Visible = true
		skip.Visible = true
		TweenService:Create(dim, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.22 }):Play()
		TweenService:Create(title, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0.05 }):Play()
		showPanel()
	end

	nextButton.Activated:Connect(function()
		if activeSceneId then
			if finishTyping() then return end
			index += 1
			showPanel()
		end
	end)
	close.Activated:Connect(closeScene)
	skip.Activated:Connect(closeScene)
	autoPlay.Activated:Connect(function()
		autoEnabled = not autoEnabled
		autoPlay.Text = autoEnabled and "[X] Auto-Play" or "[ ] Auto-Play"
		if activeSceneId then showPanel() end
	end)
	acceptButton.Activated:Connect(function()
		if activeTurnInQuestId then
			turnInQuest:FireServer(activeTurnInQuestId)
			closeScene()
		elseif activeQuestId then
			acceptQuest:FireServer(activeQuestId)
			closeScene()
		end
	end)
	declineButton.Activated:Connect(function()
		closeScene(false)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not activeSceneId then return end
		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
			if finishTyping() then return end
			index += 1
			showPanel()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			closeScene()
		end
	end)

	openScene.OnClientEvent:Connect(open)
end

return Controller
