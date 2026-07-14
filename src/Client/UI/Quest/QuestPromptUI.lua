local QuestPromptUI = {}
QuestPromptUI.__index = QuestPromptUI

local COLORS = {
	bg = Color3.fromRGB(15, 12, 10),
	border = Color3.fromRGB(150, 115, 45),
	title = Color3.fromRGB(235, 200, 100),
	text = Color3.fromRGB(235, 225, 205),
	button = Color3.fromRGB(40, 60, 40),
	buttonHover = Color3.fromRGB(50, 80, 50),
	buttonDecline = Color3.fromRGB(80, 40, 40),
	buttonDeclineHover = Color3.fromRGB(100, 50, 50),
}

function QuestPromptUI.new(playerGui)
	local self = setmetatable({}, QuestPromptUI)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuestPromptUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui
	self.Instance = screenGui

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 400, 0, 300)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = COLORS.bg
	container.Parent = screenGui

	local uic = Instance.new("UICorner")
	uic.CornerRadius = UDim.new(0, 8)
	uic.Parent = container

	local uis = Instance.new("UIStroke")
	uis.Color = COLORS.border
	uis.Thickness = 2
	uis.Parent = container

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "Quest"
	title.TextColor3 = COLORS.title
	title.Font = Enum.Font.GothamBold
	title.TextSize = 24
	title.Parent = container

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -40, 1, -120)
	body.Position = UDim2.new(0, 20, 0, 50)
	body.BackgroundTransparency = 1
	body.Text = "Quest Description"
	body.TextColor3 = COLORS.text
	body.Font = Enum.Font.GothamMedium
	body.TextSize = 16
	body.TextWrapped = true
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.RichText = true
	body.Parent = container

	local acceptBtn = Instance.new("TextButton")
	acceptBtn.Name = "AcceptBtn"
	acceptBtn.Size = UDim2.new(0.4, 0, 0, 40)
	acceptBtn.Position = UDim2.new(0.1, 0, 1, -50)
	acceptBtn.BackgroundColor3 = COLORS.button
	acceptBtn.Text = "Accept"
	acceptBtn.TextColor3 = COLORS.text
	acceptBtn.Font = Enum.Font.GothamBold
	acceptBtn.TextSize = 18
	acceptBtn.Parent = container

	local acceptUic = Instance.new("UICorner")
	acceptUic.CornerRadius = UDim.new(0, 6)
	acceptUic.Parent = acceptBtn
	
	local acceptUis = Instance.new("UIStroke")
	acceptUis.Color = COLORS.border
	acceptUis.Thickness = 1
	acceptUis.Parent = acceptBtn

	local declineBtn = Instance.new("TextButton")
	declineBtn.Name = "DeclineBtn"
	declineBtn.Size = UDim2.new(0.4, 0, 0, 40)
	declineBtn.Position = UDim2.new(0.5, 0, 1, -50)
	declineBtn.BackgroundColor3 = COLORS.buttonDecline
	declineBtn.Text = "Close"
	declineBtn.TextColor3 = COLORS.text
	declineBtn.Font = Enum.Font.GothamBold
	declineBtn.TextSize = 18
	declineBtn.Parent = container

	local declineUic = Instance.new("UICorner")
	declineUic.CornerRadius = UDim.new(0, 6)
	declineUic.Parent = declineBtn

	local declineUis = Instance.new("UIStroke")
	declineUis.Color = COLORS.border
	declineUis.Thickness = 1
	declineUis.Parent = declineBtn

	self._title = title
	self._body = body
	self._acceptBtn = acceptBtn
	self._declineBtn = declineBtn
	self._questId = nil

	self.OnAccept = nil

	acceptBtn.Activated:Connect(function()
		if self.OnAccept and self._questId then
			self.OnAccept(self._questId)
			self:SetVisible(false)
		end
	end)

	declineBtn.Activated:Connect(function()
		self:SetVisible(false)
	end)

	acceptBtn.MouseEnter:Connect(function() acceptBtn.BackgroundColor3 = COLORS.buttonHover end)
	acceptBtn.MouseLeave:Connect(function() acceptBtn.BackgroundColor3 = COLORS.button end)

	declineBtn.MouseEnter:Connect(function() declineBtn.BackgroundColor3 = COLORS.buttonDeclineHover end)
	declineBtn.MouseLeave:Connect(function() declineBtn.BackgroundColor3 = COLORS.buttonDecline end)

	return self
end

function QuestPromptUI:SetVisible(visible)
	self.Instance.Enabled = visible
end

function QuestPromptUI:Prompt(questData)
	self._questId = questData.id
	self._title.Text = questData.name or "Unknown Quest"
	
	local desc = questData.description or ""
	
	if questData.completed then
		desc = desc .. "\n\n<font color=\"#66FF66\">Status: Complete! You have already finished this quest.</font>"
		self._acceptBtn.Visible = false
		self._declineBtn.Size = UDim2.new(0.8, 0, 0, 40)
		self._declineBtn.Position = UDim2.new(0.1, 0, 1, -50)
	elseif questData.accepted then
		local prog = questData.progress or 0
		local req = questData.required or "?"
		desc = desc .. "\n\n<font color=\"#88AAFF\">Progress: " .. prog .. " / " .. req .. "</font>"
		
		self._acceptBtn.Visible = false
		self._declineBtn.Size = UDim2.new(0.8, 0, 0, 40)
		self._declineBtn.Position = UDim2.new(0.1, 0, 1, -50)
	else
		self._acceptBtn.Visible = true
		self._acceptBtn.Text = "Accept"
		self._declineBtn.Size = UDim2.new(0.4, 0, 0, 40)
		self._declineBtn.Position = UDim2.new(0.5, 0, 1, -50)
		self._declineBtn.Text = "Decline"
	end
	
	self._body.Text = desc
	self:SetVisible(true)
end

return QuestPromptUI
