local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LoadingScreenUI = {}
LoadingScreenUI.__index = LoadingScreenUI

function LoadingScreenUI.new(parent)
	local self = setmetatable({}, LoadingScreenUI)
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LoadingScreenGui"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 9999 -- Ensure it is on top of everything
	
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	background.BorderSizePixel = 0
	background.Parent = screenGui
	self.background = background
	
	local centerContainer = Instance.new("Frame")
	centerContainer.Name = "CenterContainer"
	centerContainer.Size = UDim2.fromOffset(400, 200)
	centerContainer.Position = UDim2.fromScale(0.5, 0.5)
	centerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	centerContainer.BackgroundTransparency = 1
	centerContainer.Parent = background
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.fromScale(0.5, 0.2)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.BackgroundTransparency = 1
	title.Text = "RPG REALM"
	title.TextColor3 = Color3.fromRGB(240, 240, 240)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 48
	title.Parent = centerContainer
	self.title = title
	
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, 0, 0, 30)
	subtitle.Position = UDim2.fromScale(0.5, 0.5)
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Generating World..."
	subtitle.TextColor3 = Color3.fromRGB(180, 180, 190)
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 24
	subtitle.Parent = centerContainer
	self.subtitle = subtitle
	
	local spinner = Instance.new("Frame")
	spinner.Name = "Spinner"
	spinner.Size = UDim2.fromOffset(40, 40)
	spinner.Position = UDim2.fromScale(0.5, 0.85)
	spinner.AnchorPoint = Vector2.new(0.5, 0.5)
	spinner.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
	spinner.BackgroundTransparency = 0.5
	spinner.BorderSizePixel = 0
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.5, 0)
	uiCorner.Parent = spinner
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(200, 220, 255)
	uiStroke.Thickness = 2
	uiStroke.Parent = spinner
	
	spinner.Parent = centerContainer
	self.spinner = spinner
	
	-- Loading Animation loop
	self.isAnimating = true
	task.spawn(function()
		while self.isAnimating do
			local tween = TweenService:Create(spinner, TweenInfo.new(1, Enum.EasingStyle.Linear), {Rotation = 360})
			tween:Play()
			tween.Completed:Wait()
			spinner.Rotation = 0
		end
	end)
	
	-- Pulsing text animation
	task.spawn(function()
		while self.isAnimating do
			local tween1 = TweenService:Create(subtitle, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0.5})
			tween1:Play()
			tween1.Completed:Wait()
			if not self.isAnimating then break end
			local tween2 = TweenService:Create(subtitle, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {TextTransparency = 0})
			tween2:Play()
			tween2.Completed:Wait()
		end
	end)
	
	screenGui.Parent = parent
	self.gui = screenGui
	
	return self
end

function LoadingScreenUI:FadeOutAndDestroy()
	self.isAnimating = false
	self.subtitle.Text = "World Ready!"
	
	local fadeInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	TweenService:Create(self.background, fadeInfo, {BackgroundTransparency = 1}):Play()
	TweenService:Create(self.title, fadeInfo, {TextTransparency = 1}):Play()
	TweenService:Create(self.subtitle, fadeInfo, {TextTransparency = 1}):Play()
	TweenService:Create(self.spinner, fadeInfo, {BackgroundTransparency = 1}):Play()
	
	if self.spinner:FindFirstChild("UIStroke") then
		TweenService:Create(self.spinner.UIStroke, fadeInfo, {Transparency = 1}):Play()
	end
	
	task.wait(1.5)
	self.gui:Destroy()
end

return LoadingScreenUI
