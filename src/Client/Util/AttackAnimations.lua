local TweenService = game:GetService("TweenService")

local AttackAnimations = {}
local comboStep = 1
local loadedAnims = {}

function AttackAnimations.play(character, tool)
	if not character or not tool then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local isR6 = humanoid.RigType == Enum.HumanoidRigType.R6
	local animId = isR6 and "rbxassetid://1299689" or "rbxassetid://522635514"
	local track = loadedAnims[animId]
	if not track then
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		track = animator:LoadAnimation(anim)
		loadedAnims[animId] = track
	end
	track:Play(0.1, 1, 1.5)

	if not tool:GetAttribute("OriginalGrip") then
		tool:SetAttribute("OriginalGrip", tool.Grip)
	end
	local origGrip = tool:GetAttribute("OriginalGrip")
	local isStaff = tool.Name:lower():find("staff")
	local windUpGrip, strikeGrip

	if comboStep == 1 then
		windUpGrip = origGrip * CFrame.new(-1, 0, 0) * CFrame.Angles(0, 0, math.rad(-45))
		strikeGrip = origGrip * CFrame.new(1, 0, 0) * CFrame.Angles(0, 0, math.rad(45))
	elseif comboStep == 2 then
		windUpGrip = origGrip * CFrame.new(1, 0, 0) * CFrame.Angles(0, 0, math.rad(45))
		strikeGrip = origGrip * CFrame.new(-1, 0, 0) * CFrame.Angles(0, 0, math.rad(-45))
	else
		if isStaff then
			windUpGrip = origGrip * CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(45), 0, 0)
			strikeGrip = origGrip * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-45), 0, 0)
		else
			windUpGrip = origGrip * CFrame.new(0, -1, -1) * CFrame.Angles(math.rad(90), 0, 0)
			strikeGrip = origGrip * CFrame.new(0, 1, 1) * CFrame.Angles(math.rad(-90), 0, 0)
		end
	end

	comboStep = comboStep + 1
	if comboStep > 3 then
		comboStep = 1
	end

	local windupTween = TweenService:Create(tool, TweenInfo.new(0.1, Enum.EasingStyle.Sine), { Grip = windUpGrip })
	local strikeTween = TweenService:Create(tool, TweenInfo.new(0.1, Enum.EasingStyle.Back), { Grip = strikeGrip })
	local recoverTween = TweenService:Create(tool, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Grip = origGrip })

	windupTween:Play()
	windupTween.Completed:Connect(function()
		strikeTween:Play()
		strikeTween.Completed:Connect(function()
			recoverTween:Play()
		end)
	end)
end

return AttackAnimations
