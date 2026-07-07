-- FloatingText.lua
-- Client-side utility for creating floating text popups (damage, healing, skills, gold/exp).

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local FloatingText = {}

local FONT = Enum.Font.FredokaOne

-- Utility function to get the local player's PlayerGui
local function getPlayerGui()
	local player = Players.LocalPlayer
	if not player then return nil end
	return player:WaitForChild("PlayerGui", 5)
end

-- ScreenGui for Gold/Exp
local goldExpGui = nil
local function getGoldExpGui()
	if goldExpGui then return goldExpGui end
	
	local playerGui = getPlayerGui()
	if not playerGui then return nil end
	
	goldExpGui = Instance.new("ScreenGui")
	goldExpGui.Name = "FloatingText_GoldExp"
	goldExpGui.ResetOnSpawn = false
	goldExpGui.DisplayOrder = 100
	goldExpGui.Parent = playerGui
	
	return goldExpGui
end

-- Utility function to add random X/Z offset
local function getRandomOffset()
	local rng = Random.new()
	return Vector3.new(
		rng:NextNumber(-1, 1),
		0,
		rng:NextNumber(-1, 1)
	)
end

-- Helper to animate BillboardGui text
local function animateBillboardText(billboard, textLabel, isCrit, duration)
	duration = duration or 1
	
	-- Start state with offset
	billboard.ExtentsOffset = billboard.ExtentsOffset + getRandomOffset()
	
	local startScale = UDim2.new(0, 0, 0, 0)
	local punchScale = isCrit and UDim2.new(1.5, 0, 1.5, 0) or UDim2.new(1.2, 0, 1.2, 0)
	local normalScale = isCrit and UDim2.new(1.2, 0, 1.2, 0) or UDim2.new(1, 0, 1, 0)
	
	textLabel.Size = startScale
	textLabel.TextTransparency = 0
	textLabel.UIStroke.Transparency = 0
	
	-- Pop in
	local tweenInfoPop = TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local popTween = TweenService:Create(textLabel, tweenInfoPop, {Size = punchScale})
	popTween:Play()
	
	popTween.Completed:Connect(function()
		-- Settle scale
		local settleTween = TweenService:Create(textLabel, TweenInfo.new(0.1), {Size = normalScale})
		settleTween:Play()
		
		-- Float up and fade out
		local floatInfo = TweenInfo.new(duration - 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local endOffset = billboard.ExtentsOffset + Vector3.new(0, 3, 0)
		
		local floatTween = TweenService:Create(billboard, floatInfo, {ExtentsOffset = endOffset})
		local fadeTween = TweenService:Create(textLabel, floatInfo, {TextTransparency = 1})
		local strokeFadeTween = TweenService:Create(textLabel.UIStroke, floatInfo, {Transparency = 1})
		
		-- Also rotate slightly for crits or skills to add emphasis
		if isCrit then
			local rotTween = TweenService:Create(textLabel, floatInfo, {Rotation = Random.new():NextNumber(-15, 15)})
			rotTween:Play()
		end
		
		-- Delay the float/fade slightly so it is readable
		task.delay(0.2, function()
			floatTween:Play()
			fadeTween:Play()
			strokeFadeTween:Play()
		end)
	end)
	
	Debris:AddItem(billboard, duration + 0.5)
end

-- Helper to create a base BillboardGui
local function createBaseBillboard(character, text)
	local head = character:FindFirstChild("Head") or character.PrimaryPart
	if not head then return nil end
	
	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = head
	billboard.Size = UDim2.new(4, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.ExtentsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.Text = text
	textLabel.Font = FONT
	textLabel.TextScaled = true
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Parent = textLabel
	
	textLabel.Parent = billboard
	
	-- Parent to Terrain so it renders but isn't strictly tied to character deletion
	billboard.Parent = workspace.Terrain
	
	return billboard, textLabel
end

--[[ 
	1. DAMAGE NUMBERS
	Shows damage on a character. 
	Crit hits are larger, orange/white, with a punch effect.
]]
function FloatingText.ShowDamage(character, amount, isCritical)
	local text = tostring(math.floor(amount))
	
	local billboard, textLabel = createBaseBillboard(character, text)
	if not billboard then return end
	
	if isCritical then
		textLabel.TextColor3 = Color3.fromRGB(255, 170, 0) -- Orange/Gold
		textLabel.Text = text .. "!"
	else
		textLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Bright Red
	end
	
	animateBillboardText(billboard, textLabel, isCritical, 1.2)
end

--[[ 
	2. HEAL NUMBERS
	Shows healing with a green color and "+" prefix.
]]
function FloatingText.ShowHeal(character, amount)
	local text = "+" .. tostring(math.floor(amount))
	
	local billboard, textLabel = createBaseBillboard(character, text)
	if not billboard then return end
	
	textLabel.TextColor3 = Color3.fromRGB(50, 255, 100) -- Bright Green
	textLabel.Font = Enum.Font.GothamBlack -- Distinct font weight for heal
	
	-- Soft glow effect
	local glow = Instance.new("UIStroke")
	glow.Color = Color3.fromRGB(150, 255, 150)
	glow.Thickness = 1
	glow.Transparency = 0.5
	glow.Parent = textLabel
	
	-- Adjust default stroke
	textLabel.UIStroke.Thickness = 1
	
	animateBillboardText(billboard, textLabel, false, 1.5)
end

--[[ 
	3. BUFF / SKILL CAST LABELS
	Shows skill/buff name with gradient text and outline.
]]
function FloatingText.ShowSkillLabel(character, skillName)
	local billboard, textLabel = createBaseBillboard(character, skillName)
	if not billboard then return end
	
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)), -- Gold
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) -- White
	}
	gradient.Rotation = 90
	gradient.Parent = textLabel
	
	animateBillboardText(billboard, textLabel, true, 1.5)
end

-- Helper for ScreenGui Floating Text (Gold/Exp)
local function animateScreenText(textLabel, baseOffset)
	-- Start state
	local rng = Random.new()
	local startXOffset = baseOffset + rng:NextInteger(-15, 15)
	
	-- Positioned near bottom center (e.g. above main HUD)
	textLabel.Position = UDim2.new(0.5, startXOffset, 0.75, 0)
	
	local startScale = UDim2.new(0, 0, 0, 0)
	local targetScale = UDim2.new(0, 200, 0, 40)
	
	textLabel.Size = startScale
	textLabel.TextTransparency = 0
	textLabel.UIStroke.Transparency = 0
	
	local tweenInfoPop = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local popTween = TweenService:Create(textLabel, tweenInfoPop, {Size = targetScale})
	popTween:Play()
	
	popTween.Completed:Connect(function()
		local floatInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local targetPos = textLabel.Position - UDim2.new(0, 0, 0.15, 0) -- Float up
		
		local floatTween = TweenService:Create(textLabel, floatInfo, {Position = targetPos})
		local fadeTween = TweenService:Create(textLabel, floatInfo, {TextTransparency = 1})
		local strokeFadeTween = TweenService:Create(textLabel.UIStroke, floatInfo, {Transparency = 1})
		
		task.delay(0.5, function()
			floatTween:Play()
			fadeTween:Play()
			strokeFadeTween:Play()
		end)
	end)
	
	Debris:AddItem(textLabel, 2.5)
end

local function createScreenLabel(text)
	local gui = getGoldExpGui()
	if not gui then return nil end
	
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.Text = text
	textLabel.Font = FONT
	textLabel.TextScaled = true
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2
	stroke.Parent = textLabel
	
	textLabel.Parent = gui
	return textLabel
end

--[[ 
	4. GOLD GAIN
	Shows gold near the HUD in yellow.
]]
function FloatingText.ShowGoldGain(amount)
	local text = "+" .. tostring(amount) .. " Gold"
	local textLabel = createScreenLabel(text)
	if not textLabel then return end
	
	textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	animateScreenText(textLabel, -120) -- Offset to the left
end

--[[ 
	5. EXP GAIN
	Shows exp near the HUD in purple/blue.
]]
function FloatingText.ShowExpGain(amount)
	local text = "+" .. tostring(amount) .. " EXP"
	local textLabel = createScreenLabel(text)
	if not textLabel then return end
	
	textLabel.TextColor3 = Color3.fromRGB(150, 100, 255) -- Purple
	animateScreenText(textLabel, 120) -- Offset to the right
end

return FloatingText
