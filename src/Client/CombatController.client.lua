local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local lastAttack = 0
local ATTACK_COOLDOWN = 0.7

local lastDash = 0
local DASH_COOLDOWN = 5
local DASH_SPEED = 100
local DASH_DURATION = 0.2
local isDashing = false

local comboStep = 1

local loadedAnims = {}

local function playAttackAnimation(character, tool)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	local isR6 = humanoid.RigType == Enum.HumanoidRigType.R6
	
	-- Base Arm Swing Animation (ensures the arm moves reliably!)
	local animId = isR6 and "rbxassetid://1299689" or "rbxassetid://522635514"
	local track = loadedAnims[animId]
	if not track then
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		track = animator:LoadAnimation(anim)
		loadedAnims[animId] = track
	end
	track:Play(0.1, 1, 1.5)
	
	-- 3-Hit Combo: Procedural Tool.Grip swing (very visible and satisfying)
	if not tool:GetAttribute("OriginalGrip") then
		tool:SetAttribute("OriginalGrip", tool.Grip)
	end
	local origGrip = tool:GetAttribute("OriginalGrip")
	
	local isStaff = tool.Name:lower():find("staff")
	local windUpGrip, strikeGrip
	local slashAngleX, slashAngleY, slashAngleZ
	
	if comboStep == 1 then
		-- Move 1: Right to Left Swing
		windUpGrip = origGrip * CFrame.new(-1, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-45))
		strikeGrip = origGrip * CFrame.new(1, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(45))
		slashAngleX, slashAngleY, slashAngleZ = 0, 90, 45 
	elseif comboStep == 2 then
		-- Move 2: Left to Right Swing
		windUpGrip = origGrip * CFrame.new(1, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(45))
		strikeGrip = origGrip * CFrame.new(-1, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-45))
		slashAngleX, slashAngleY, slashAngleZ = 0, 90, -45 
	else
		-- Move 3: Overhead / Thrust
		if isStaff then
			windUpGrip = origGrip * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(45), 0, 0)
			strikeGrip = origGrip * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-45), 0, 0)
		else
			windUpGrip = origGrip * CFrame.new(0, -1, -1) * CFrame.Angles(math.rad(90), 0, 0)
			strikeGrip = origGrip * CFrame.new(0, 1, 1) * CFrame.Angles(math.rad(-90), 0, 0)
		end
		slashAngleX, slashAngleY, slashAngleZ = 0, 90, 0
	end
	
	comboStep = comboStep + 1
	if comboStep > 3 then comboStep = 1 end
	
	local windupTween = TweenService:Create(tool, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Grip = windUpGrip})
	local strikeTween = TweenService:Create(tool, TweenInfo.new(0.1, Enum.EasingStyle.Back), {Grip = strikeGrip})
	local recoverTween = TweenService:Create(tool, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Grip = origGrip})
	
	windupTween:Play()
	windupTween.Completed:Connect(function()
		strikeTween:Play()
		
		-- Slash Visual Effect
		local handle = tool:FindFirstChild("Handle")
		if handle then
			local slash = Instance.new("Part")
			slash.Name = "SlashEffect"
			slash.Size = Vector3.new(0.2, 4, 4)
			slash.Transparency = 0.3
			slash.Color = isStaff and Color3.fromRGB(150, 50, 255) or Color3.fromRGB(200, 220, 255)
			slash.Material = Enum.Material.Neon
			slash.CanCollide = false
			slash.Anchored = true
			
			local root = character.PrimaryPart
			if root then
				local cframe = root.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(math.rad(slashAngleX), math.rad(slashAngleY), math.rad(slashAngleZ))
				slash.CFrame = cframe
				slash.Parent = workspace
				
				local tween = TweenService:Create(slash, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(0, 8, 8),
					Transparency = 1,
					CFrame = cframe * CFrame.new(0, 0, -2)
				})
				tween:Play()
				tween.Completed:Connect(function() slash:Destroy() end)
			end
		end
		
		strikeTween.Completed:Connect(function()
			recoverTween:Play()
		end)
	end)
end

local function attack()
	local now = tick()
	if now - lastAttack < ATTACK_COOLDOWN then
		return
	end
	
	local character = player.Character
	if character then
		local tool = character:FindFirstChildOfClass("Tool")
		if tool then
			playAttackAnimation(character, tool)
		end
	end
	
	lastAttack = now
	remotes.Attack:FireServer()
end

local function performDash()
	local now = tick()
	if isDashing then return end
	if now - lastDash < DASH_COOLDOWN then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart or humanoid.Health <= 0 then return end

	isDashing = true
	lastDash = now

	-- Store cooldown info as attributes so the UI can read them
	character:SetAttribute("DashCooldownStart", now)
	character:SetAttribute("DashCooldown", DASH_COOLDOWN)

	-- Determine dash direction: use movement direction if moving, otherwise face forward
	local moveDir = humanoid.MoveDirection
	if moveDir.Magnitude < 0.1 then
		moveDir = rootPart.CFrame.LookVector
	end
	moveDir = moveDir.Unit

	-- Create BodyVelocity for the dash impulse
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
	bodyVelocity.Velocity = moveDir * DASH_SPEED
	bodyVelocity.P = 1e5
	bodyVelocity.Parent = rootPart

	-- Ghost transparency effect on character parts
	local originalTransparencies = {}
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			originalTransparencies[part] = part.Transparency
			part.Transparency = math.max(part.Transparency, 0.6)
		end
	end

	-- Trail / afterimage effect: spawn fading clones behind the character
	local trailPart = Instance.new("Part")
	trailPart.Name = "DashTrail"
	trailPart.Size = Vector3.new(3, 5, 1)
	trailPart.Anchored = true
	trailPart.CanCollide = false
	trailPart.Material = Enum.Material.Neon
	trailPart.Color = Color3.fromRGB(100, 180, 255)
	trailPart.CFrame = rootPart.CFrame
	trailPart.Transparency = 0.4
	trailPart.Parent = workspace

	local trailTween = TweenService:Create(trailPart, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(5, 7, 0.2),
	})
	trailTween:Play()
	trailTween.Completed:Connect(function()
		trailPart:Destroy()
	end)

	-- End the dash after DASH_DURATION
	task.delay(DASH_DURATION, function()
		bodyVelocity:Destroy()

		-- Restore original transparency
		for part, orig in originalTransparencies do
			if part and part.Parent then
				TweenService:Create(part, TweenInfo.new(0.2), {Transparency = orig}):Play()
			end
		end

		isDashing = false
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		attack()
	elseif input.KeyCode == Enum.KeyCode.One then
		attack()
	elseif input.KeyCode == Enum.KeyCode.Two then
		print("Skill 1 triggered")
		-- TODO: Implement Skill 1
	elseif input.KeyCode == Enum.KeyCode.Three then
		print("Skill 2 triggered")
		-- TODO: Implement Skill 2
	elseif input.KeyCode == Enum.KeyCode.Four then
		print("Skill 3 triggered")
		-- TODO: Implement Skill 3
	elseif input.KeyCode == Enum.KeyCode.Five then
		print("Ultimate triggered")
		-- TODO: Implement Ultimate
	elseif input.KeyCode == Enum.KeyCode.Six then
		remotes.UseItem:FireServer("HealthPotion")
	elseif input.KeyCode == Enum.KeyCode.Seven then
		remotes.UseItem:FireServer("ManaPotion")
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		performDash()
	end
end)
