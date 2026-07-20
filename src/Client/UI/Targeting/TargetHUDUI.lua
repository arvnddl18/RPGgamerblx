local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local TargetHUDUI = {}
TargetHUDUI.__index = TargetHUDUI

local ACTIVE_TIME = 8 -- How long the target UI stays up after taking damage

function TargetHUDUI.new(playerGui)
	local self = setmetatable({}, TargetHUDUI)
	self._targets = {}
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TargetHUDUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.Parent = playerGui
	self._screenGui = screenGui
	
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 240, 1, -200)
	container.AnchorPoint = Vector2.new(1, 0)
	-- Positioned below the minimap (Minimap is top right, around 160px size)
	container.Position = UDim2.new(1, -20, 0, 180)
	container.BackgroundTransparency = 1
	container.Parent = screenGui
	self._container = container
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = container
	
	-- Render loop to keep checking the targets' health or hide if dead/expired
	game:GetService("RunService").RenderStepped:Connect(function()
		self:_update()
	end)
	
	return self
end

function TargetHUDUI:_createTargetFrame(target)
	local root = Instance.new("Frame")
	root.Name = "TargetFrame"
	root.Size = UDim2.new(1, 0, 0, 50)
	root.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	root.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = root
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 100, 180)
	stroke.Thickness = 2
	stroke.Parent = root
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "TargetName"
	nameLabel.Size = UDim2.new(1, -16, 0, 20)
	nameLabel.Position = UDim2.new(0, 8, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "Enemy Name"
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = root
	
	local hpBg = Instance.new("Frame")
	hpBg.Name = "HpBg"
	hpBg.Size = UDim2.new(1, -16, 0, 14)
	hpBg.Position = UDim2.new(0, 8, 0, 28)
	hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	hpBg.BorderSizePixel = 0
	hpBg.Parent = root
	local hpCorner1 = Instance.new("UICorner")
	hpCorner1.CornerRadius = UDim.new(0, 4)
	hpCorner1.Parent = hpBg
	
	local hpFill = Instance.new("Frame")
	hpFill.Name = "HpFill"
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg
	local hpCorner2 = Instance.new("UICorner")
	hpCorner2.CornerRadius = UDim.new(0, 4)
	hpCorner2.Parent = hpFill
	
	local hpText = Instance.new("TextLabel")
	hpText.Name = "HpText"
	hpText.Size = UDim2.new(1, 0, 1, 0)
	hpText.BackgroundTransparency = 1
	hpText.Text = "100 / 100"
	hpText.TextColor3 = Color3.new(1, 1, 1)
	hpText.Font = Enum.Font.GothamBold
	hpText.TextSize = 10
	hpText.TextStrokeTransparency = 0.5
	hpText.Parent = hpBg
	
	return root, nameLabel, hpFill, hpText
end

function TargetHUDUI:SetTarget(target)
	if not target or not target:IsA("Model") then return end
	
	for _, data in self._targets do
		if data.target == target then
			data.lastUpdate = tick()
			return
		end
	end
	
	local frame, nameLabel, hpFill, hpText = self:_createTargetFrame(target)
	frame.Parent = self._container
	
	-- Determine name
	local name = target.Name
	local isEnemy = false
	if target:GetAttribute("EnemyType") then
		local lvl = target:GetAttribute("Level") or 1
		name = "Lv." .. tostring(lvl) .. " " .. name
		isEnemy = true
	else
		local player = Players:GetPlayerFromCharacter(target)
		if player then
			name = player.DisplayName
			local karmaState = player:GetAttribute("KarmaState") or "Innocent"
			local pvpMode = player:GetAttribute("PvpMode") or "Peaceful"
			if karmaState == "Chaotic" or pvpMode == "Hostile" then
				isEnemy = true
			end
		end
	end
	
	if isEnemy then
		hpFill.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
	else
		hpFill.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
	end

	nameLabel.Text = name
	
	table.insert(self._targets, {
		target = target,
		frame = frame,
		hpFill = hpFill,
		hpText = hpText,
		lastUpdate = tick()
	})
end

function TargetHUDUI:_update()
	local now = tick()
	for i = #self._targets, 1, -1 do
		local data = self._targets[i]
		
		if not data.target.Parent or now - data.lastUpdate > ACTIVE_TIME then
			data.frame:Destroy()
			table.remove(self._targets, i)
			continue
		end
		
		local currentHp = 0
		local maxHp = 100
		
		if data.target:GetAttribute("Health") then
			currentHp = data.target:GetAttribute("Health") or 0
			maxHp = data.target:GetAttribute("MaxHealth") or 100
		else
			local humanoid = data.target:FindFirstChildOfClass("Humanoid")
			if humanoid then
				currentHp = humanoid.Health
				maxHp = humanoid.MaxHealth
			end
		end
		
		if currentHp <= 0 then
			data.frame:Destroy()
			table.remove(self._targets, i)
			continue
		end
		
		local ratio = maxHp > 0 and math.clamp(currentHp / maxHp, 0, 1) or 0
		
		-- Smooth tween
		TweenService:Create(data.hpFill, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
			Size = UDim2.new(ratio, 0, 1, 0)
		}):Play()
		
		data.hpText.Text = string.format("%d / %d", math.floor(currentHp), math.floor(maxHp))
	end
end

return TargetHUDUI
