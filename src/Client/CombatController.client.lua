local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local lastAttack = 0
local ATTACK_COOLDOWN = 0.7

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
	end
end)
