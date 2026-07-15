-- Reusable first-meeting comic overlay. The server supplies dialogue panels
-- and is notified only when the player advances or skips the scene.
local Controller = {}

function Controller:Start()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local openScene = remotes:WaitForChild("OpenComicScene")
	local completeScene = remotes:WaitForChild("CompleteComicScene")

	local gui = Instance.new("ScreenGui")
	gui.Name = "ComicDialogueUI"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 250
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.28
	dim.Visible = false
	dim.Parent = gui

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.72)
	card.Size = UDim2.fromScale(0.76, 0.32)
	card.BackgroundColor3 = Color3.fromRGB(26, 22, 31)
	card.Visible = false
	card.Parent = gui
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(225, 195, 110)
	stroke.Parent = card

	local portrait = Instance.new("Frame")
	portrait.Name = "Portrait"
	portrait.AnchorPoint = Vector2.new(0, 0.5)
	portrait.Position = UDim2.new(0, 24, 0.5, 0)
	portrait.Size = UDim2.new(0, 128, 1, -48)
	portrait.BackgroundColor3 = Color3.fromRGB(110, 110, 140)
	portrait.Parent = card
	Instance.new("UICorner", portrait).CornerRadius = UDim.new(0, 12)
	local silhouette = Instance.new("TextLabel")
	silhouette.Size = UDim2.fromScale(1, 1)
	silhouette.BackgroundTransparency = 1
	silhouette.Text = "✦"
	silhouette.TextSize = 72
	silhouette.Font = Enum.Font.GothamBlack
	silhouette.TextColor3 = Color3.fromRGB(255, 245, 220)
	silhouette.Parent = portrait

	local speaker = Instance.new("TextLabel")
	speaker.Position = UDim2.new(0, 176, 0, 30)
	speaker.Size = UDim2.new(1, -210, 0, 34)
	speaker.BackgroundTransparency = 1
	speaker.Font = Enum.Font.GothamBold
	speaker.TextSize = 25
	speaker.TextXAlignment = Enum.TextXAlignment.Left
	speaker.TextColor3 = Color3.fromRGB(255, 222, 140)
	speaker.Parent = card

	local body = Instance.new("TextLabel")
	body.Position = UDim2.new(0, 176, 0, 70)
	body.Size = UDim2.new(1, -210, 1, -130)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.GothamMedium
	body.TextSize = 20
	body.TextWrapped = true
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextColor3 = Color3.fromRGB(245, 239, 226)
	body.Parent = card

	local advance = Instance.new("TextButton")
	advance.AnchorPoint = Vector2.new(1, 1)
	advance.Position = UDim2.new(1, -20, 1, -18)
	advance.Size = UDim2.fromOffset(150, 40)
	advance.BackgroundColor3 = Color3.fromRGB(77, 116, 92)
	advance.Text = "NEXT  ›"
	advance.Font = Enum.Font.GothamBold
	advance.TextSize = 16
	advance.TextColor3 = Color3.new(1, 1, 1)
	advance.Parent = card
	Instance.new("UICorner", advance).CornerRadius = UDim.new(0, 8)

	local skip = Instance.new("TextButton")
	skip.Position = UDim2.new(0, 20, 1, -58)
	skip.Size = UDim2.fromOffset(92, 28)
	skip.BackgroundTransparency = 1
	skip.Text = "Skip scene"
	skip.Font = Enum.Font.Gotham
	skip.TextSize = 14
	skip.TextColor3 = Color3.fromRGB(200, 195, 185)
	skip.Parent = card

	local activeSceneId, panels, index = nil, nil, 0
	local function closeScene()
		if not activeSceneId then return end
		local sceneId = activeSceneId
		activeSceneId, panels, index = nil, nil, 0
		dim.Visible = false
		card.Visible = false
		completeScene:FireServer(sceneId)
	end
	local function showPanel()
		local panel = panels[index]
		if not panel then closeScene() return end
		portrait.BackgroundColor3 = panel.color or Color3.fromRGB(110, 110, 140)
		speaker.Text = panel.speaker or "Unknown"
		body.Text = panel.text or ""
		advance.Text = index >= #panels and "CONTINUE" or "NEXT  ›"
		card.Size = UDim2.fromScale(0.72, 0.30)
		TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.76, 0.32) }):Play()
	end
	advance.Activated:Connect(function()
		if activeSceneId then index += 1; showPanel() end
	end)
	skip.Activated:Connect(closeScene)
	openScene.OnClientEvent:Connect(function(sceneId, scene)
		if activeSceneId or type(scene) ~= "table" or type(scene.panels) ~= "table" then return end
		activeSceneId, panels, index = sceneId, scene.panels, 1
		dim.Visible, card.Visible = true, true
		showPanel()
	end)
end

return Controller
