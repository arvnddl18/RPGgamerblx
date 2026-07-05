--[[
	DashController.client.lua
	Handles the Dash/Evade mechanic:
	  - Left Shift to dash in movement (or facing) direction
	  - 5-second cooldown with radial UI indicator
	  - Subtle speed-line visual effect during dash
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- ── Constants ──────────────────────────────────────────────────────────────────
local DASH_SPEED = 100        -- Studs per second impulse
local DASH_DURATION = 0.2     -- How long the impulse lasts (seconds)
local DASH_COOLDOWN = 5       -- Cooldown duration (seconds)

-- ── State ──────────────────────────────────────────────────────────────────────
local lastDashTime = -DASH_COOLDOWN  -- Start ready
local isDashing = false

-- ── Remotes ────────────────────────────────────────────────────────────────────
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local dashRemote = remotes and remotes:WaitForChild("Dash", 10)

-- ══════════════════════════════════════════════════════════════════════════════
-- UI CREATION
-- ══════════════════════════════════════════════════════════════════════════════

local function createDashUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DashCooldownUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = false

	-- Container frame (bottom-right)
	local container = Instance.new("Frame")
	container.Name = "DashContainer"
	container.Size = UDim2.new(0, 64, 0, 64)
	container.Position = UDim2.new(1, -90, 1, -90)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	-- Outer glow ring
	local glowRing = Instance.new("Frame")
	glowRing.Name = "GlowRing"
	glowRing.Size = UDim2.new(1, 8, 1, 8)
	glowRing.Position = UDim2.new(0.5, 0, 0.5, 0)
	glowRing.AnchorPoint = Vector2.new(0.5, 0.5)
	glowRing.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	glowRing.BackgroundTransparency = 0.5
	glowRing.Parent = container

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent = glowRing

	-- Background circle
	local bgCircle = Instance.new("Frame")
	bgCircle.Name = "Background"
	bgCircle.Size = UDim2.new(1, 0, 1, 0)
	bgCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
	bgCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	bgCircle.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
	bgCircle.BorderSizePixel = 0
	bgCircle.Parent = container

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(1, 0)
	bgCorner.Parent = bgCircle

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Color = Color3.fromRGB(0, 180, 240)
	bgStroke.Thickness = 2.5
	bgStroke.Transparency = 0.2
	bgStroke.Parent = bgCircle

	-- Icon label (wind/dash symbol)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "DashIcon"
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.Position = UDim2.new(0, 0, 0, -2)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = "⟐"
	iconLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
	iconLabel.TextSize = 32
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextTransparency = 0
	iconLabel.Parent = bgCircle

	-- "SHIFT" key hint below icon
	local keyHint = Instance.new("TextLabel")
	keyHint.Name = "KeyHint"
	keyHint.Size = UDim2.new(1, 0, 0, 16)
	keyHint.Position = UDim2.new(0.5, 0, 1, 6)
	keyHint.AnchorPoint = Vector2.new(0.5, 0)
	keyHint.BackgroundTransparency = 1
	keyHint.Text = "SHIFT"
	keyHint.TextColor3 = Color3.fromRGB(180, 200, 220)
	keyHint.TextSize = 11
	keyHint.Font = Enum.Font.GothamBold
	keyHint.TextTransparency = 0.3
	keyHint.Parent = container

	-- Cooldown overlay (darkening circle)
	local cooldownOverlay = Instance.new("Frame")
	cooldownOverlay.Name = "CooldownOverlay"
	cooldownOverlay.Size = UDim2.new(1, -4, 1, -4)
	cooldownOverlay.Position = UDim2.new(0.5, 0, 0.5, 0)
	cooldownOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
	cooldownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cooldownOverlay.BackgroundTransparency = 1 -- hidden when ready
	cooldownOverlay.ZIndex = 3
	cooldownOverlay.Parent = bgCircle

	local overlayCorner = Instance.new("UICorner")
	overlayCorner.CornerRadius = UDim.new(1, 0)
	overlayCorner.Parent = cooldownOverlay

	-- Cooldown progress bar (bottom sweep)
	local cooldownBar = Instance.new("Frame")
	cooldownBar.Name = "CooldownBar"
	cooldownBar.Size = UDim2.new(1, 0, 0, 0) -- starts at 0 height
	cooldownBar.Position = UDim2.new(0, 0, 1, 0)
	cooldownBar.AnchorPoint = Vector2.new(0, 1)
	cooldownBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	cooldownBar.BackgroundTransparency = 0.6
	cooldownBar.ZIndex = 4
	cooldownBar.Parent = bgCircle

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = cooldownBar

	-- Countdown text
	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "Countdown"
	countdownLabel.Size = UDim2.new(1, 0, 1, 0)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Text = ""
	countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	countdownLabel.TextSize = 22
	countdownLabel.Font = Enum.Font.GothamBold
	countdownLabel.TextTransparency = 0
	countdownLabel.ZIndex = 5
	countdownLabel.Visible = false
	countdownLabel.Parent = bgCircle

	screenGui.Parent = player.PlayerGui

	return {
		screenGui = screenGui,
		container = container,
		glowRing = glowRing,
		bgCircle = bgCircle,
		bgStroke = bgStroke,
		iconLabel = iconLabel,
		cooldownOverlay = cooldownOverlay,
		cooldownBar = cooldownBar,
		countdownLabel = countdownLabel,
	}
end

-- ══════════════════════════════════════════════════════════════════════════════
-- UI UPDATE
-- ══════════════════════════════════════════════════════════════════════════════

local ui = createDashUI()

local function setReadyState()
	-- Icon bright
	ui.iconLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
	ui.iconLabel.TextTransparency = 0
	ui.iconLabel.Visible = true

	-- Overlay hidden
	ui.cooldownOverlay.BackgroundTransparency = 1

	-- Bar reset
	ui.cooldownBar.Size = UDim2.new(1, 0, 0, 0)

	-- Countdown hidden
	ui.countdownLabel.Visible = false

	-- Glow visible
	ui.glowRing.BackgroundTransparency = 0.5
	ui.glowRing.BackgroundColor3 = Color3.fromRGB(0, 200, 255)

	-- Stroke bright
	ui.bgStroke.Color = Color3.fromRGB(0, 180, 240)
	ui.bgStroke.Transparency = 0.2
end

local function setCooldownState(fraction, remaining)
	-- fraction: 0 = just used, 1 = ready again
	-- remaining: seconds left

	-- Icon dimmed
	ui.iconLabel.TextColor3 = Color3.fromRGB(60, 80, 100)
	ui.iconLabel.TextTransparency = 0.5
	ui.iconLabel.Visible = true

	-- Overlay darkening
	ui.cooldownOverlay.BackgroundTransparency = 0.3 + (fraction * 0.7)

	-- Bar sweeps up as cooldown recovers
	ui.cooldownBar.Size = UDim2.new(1, 0, fraction, 0)

	-- Countdown text
	ui.countdownLabel.Visible = true
	ui.countdownLabel.Text = tostring(math.ceil(remaining))

	-- Glow dimmed
	ui.glowRing.BackgroundTransparency = 0.85
	ui.glowRing.BackgroundColor3 = Color3.fromRGB(40, 60, 80)

	-- Stroke dimmed
	ui.bgStroke.Color = Color3.fromRGB(40, 60, 80)
	ui.bgStroke.Transparency = 0.6
end

local function playReadyPulse()
	-- Brief scale-up pulse when dash becomes available
	local originalSize = UDim2.new(0, 64, 0, 64)
	local pulseSize = UDim2.new(0, 78, 0, 78)

	ui.container.Size = pulseSize
	local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(ui.container, tweenInfo, { Size = originalSize })
	tween:Play()

	-- Flash the glow ring
	ui.glowRing.BackgroundTransparency = 0
	ui.glowRing.BackgroundColor3 = Color3.fromRGB(100, 255, 255)
	local glowTween = TweenService:Create(ui.glowRing, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.5,
		BackgroundColor3 = Color3.fromRGB(0, 200, 255),
	})
	glowTween:Play()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- DASH MOVEMENT
-- ══════════════════════════════════════════════════════════════════════════════

local function createSpeedLines(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Create a temporary attachment for the trail
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 1, 0)
	attachment0.Parent = rootPart

	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, -1, 0)
	attachment1.Parent = rootPart

	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Lifetime = 0.15
	trail.MinLength = 0.1
	trail.FaceCamera = true
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 200)),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Parent = rootPart

	-- Clean up after dash
	task.delay(DASH_DURATION + 0.3, function()
		trail:Destroy()
		attachment0:Destroy()
		attachment1:Destroy()
	end)
end

local function performDash()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Determine dash direction: movement direction first, else facing direction
	local moveDir = humanoid.MoveDirection
	local dashDirection
	if moveDir.Magnitude > 0.1 then
		dashDirection = moveDir.Unit
	else
		dashDirection = rootPart.CFrame.LookVector
	end

	isDashing = true

	-- Create speed-line visual effect
	createSpeedLines(character)

	-- Apply impulse using BodyVelocity
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge) -- No vertical impulse
	bodyVelocity.Velocity = dashDirection * DASH_SPEED
	bodyVelocity.P = 10000
	bodyVelocity.Parent = rootPart

	-- Fire server remote for validation
	if dashRemote then
		dashRemote:FireServer()
	end

	-- Remove impulse after duration
	task.delay(DASH_DURATION, function()
		bodyVelocity:Destroy()
		isDashing = false
	end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- INPUT HANDLING
-- ══════════════════════════════════════════════════════════════════════════════

local function canDash()
	local now = tick()
	return (now - lastDashTime) >= DASH_COOLDOWN and not isDashing
end

local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode ~= Enum.KeyCode.LeftShift then return end
	if not canDash() then return end

	lastDashTime = tick()
	performDash()
end

UserInputService.InputBegan:Connect(onInputBegan)

-- ══════════════════════════════════════════════════════════════════════════════
-- COOLDOWN UI UPDATE LOOP
-- ══════════════════════════════════════════════════════════════════════════════

local wasOnCooldown = false

RunService.Heartbeat:Connect(function()
	local now = tick()
	local elapsed = now - lastDashTime
	local remaining = DASH_COOLDOWN - elapsed

	if remaining > 0 then
		-- On cooldown
		local fraction = elapsed / DASH_COOLDOWN
		setCooldownState(fraction, remaining)
		wasOnCooldown = true
	else
		-- Ready
		if wasOnCooldown then
			setReadyState()
			playReadyPulse()
			wasOnCooldown = false
		end
	end
end)

-- Initialize as ready
setReadyState()

print("[DashController] Dash mechanic initialized — press Left Shift to dash!")
