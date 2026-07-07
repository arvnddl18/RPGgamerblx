local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SkillVfxConfig = require(script.Parent.Parent.Config.SkillVfxConfig)

local SkillVfxUtil = {}

local function getTemplatesFolder()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	return assets and assets:FindFirstChild("VFX")
end

function SkillVfxUtil.GetTemplate(vfxKey)
	local folder = getTemplatesFolder()
	return folder and folder:FindFirstChild(vfxKey)
end

local function enableEffects(root, enabled)
	for _, desc in root:GetDescendants() do
		if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") then
			desc.Enabled = enabled
		end
	end
end

local function prepareVfxClone(root)
	for _, desc in root:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.CanQuery = false
			desc.CanTouch = false
			desc.Massless = true
			desc.Anchored = false
		end
	end
end

local function tryPlayRigAnimation(model)
	local controller = model:FindFirstChildOfClass("AnimationController")
	if not controller then
		return
	end
	local animator = controller:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = controller
	end
	for _, child in model:GetDescendants() do
		if child:IsA("Animation") and child.AnimationId ~= "" then
			local track = animator:LoadAnimation(child)
			track:Play()
			return track
		end
	end
end

function SkillVfxUtil.Play(character, vfxKey)
	if not character or not vfxKey then
		return nil
	end

	local template = SkillVfxUtil.GetTemplate(vfxKey)
	if not template then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local cfg = SkillVfxConfig.GetTemplateConfig(vfxKey) or { duration = 2, offset = CFrame.new() }
	local clone = template:Clone()
	clone.Name = vfxKey .. "_Active"
	prepareVfxClone(clone)

	if clone:IsA("Model") then
		local rootPart = clone:FindFirstChild("RootPart") or clone.PrimaryPart
		if rootPart and rootPart:IsA("BasePart") then
			clone.PrimaryPart = rootPart
		end
	end

	local pivot = root.CFrame * (cfg.offset or CFrame.new())
	local followConnection
	if clone:IsA("Model") then
		clone:PivotTo(pivot)
		clone.Parent = cfg.followCharacter and character or workspace
		if cfg.followCharacter then
			for _, desc in clone:GetDescendants() do
				if desc:IsA("BasePart") then
					desc.Anchored = true
				end
			end
			followConnection = RunService.Heartbeat:Connect(function()
				if clone.Parent and root.Parent then
					clone:PivotTo(root.CFrame * (cfg.offset or CFrame.new()))
				end
			end)
		else
			for _, desc in clone:GetDescendants() do
				if desc:IsA("BasePart") then
					desc.Anchored = true
				end
			end
		end
	elseif clone:IsA("BasePart") then
		clone.CFrame = pivot
		clone.Parent = cfg.followCharacter and character or workspace
	else
		local anchor = Instance.new("Part")
		anchor.Name = "VfxAnchor"
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.2, 0.2, 0.2)
		anchor.CanCollide = false
		anchor.Massless = true
		anchor.Anchored = false
		anchor.CFrame = pivot
		anchor.Parent = cfg.followCharacter and character or workspace
		clone.Parent = anchor
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = anchor
		weld.Parent = anchor
		clone = anchor
	end

	enableEffects(clone, true)
	tryPlayRigAnimation(clone)

	task.delay(cfg.duration or 2, function()
		if followConnection then
			followConnection:Disconnect()
		end
		if clone and clone.Parent then
			clone:Destroy()
		end
	end)

	return clone
end

function SkillVfxUtil.PlayForSkill(character, skillId)
	local vfxKey = SkillVfxConfig.GetForSkill(skillId)
	if vfxKey then
		return SkillVfxUtil.Play(character, vfxKey)
	end
	return nil
end

function SkillVfxUtil.PlayDash(character)
	return SkillVfxUtil.Play(character, SkillVfxConfig.DashVfx)
end

return SkillVfxUtil
