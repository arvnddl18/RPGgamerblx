local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SkillVfxConfig = require(script.Parent.Parent.Config.SkillVfxConfig)

local SkillVfxUtil = {}

local function getTemplatesFolder()
	return ReplicatedStorage:FindFirstChild("Effects")
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

local function emitEffects(root, count)
	for _, desc in root:GetDescendants() do
		if desc:IsA("ParticleEmitter") then
			desc:Emit(count)
		end
	end
end

local function preparePart(part)
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.Anchored = false
end

local function prepareVfxClone(root)
	if root:IsA("BasePart") then
		preparePart(root)
	end
	for _, desc in root:GetDescendants() do
		if desc:IsA("BasePart") then
			preparePart(desc)
		end
	end
end

local function applyColor(instance, color)
	if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") then
		instance.Color = ColorSequence.new(color)
	elseif instance:IsA("BasePart") then
		instance.Color = color
	elseif instance:IsA("Light") then
		instance.Color = color
	end
end

local function applyColorOverride(root, color)
	if not color then return end
	applyColor(root, color)
	for _, desc in root:GetDescendants() do
		applyColor(desc, color)
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

function SkillVfxUtil.Play(character, vfxKey, comboIndex)
	if not character or not vfxKey then
		return nil
	end

	local cfg = SkillVfxConfig.GetTemplateConfig(vfxKey) or { duration = 2, offset = CFrame.new() }

	local template = SkillVfxUtil.GetTemplate(cfg.baseVfx or vfxKey)
	if not template then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local clone = template:Clone()
	if cfg.color then
		applyColorOverride(clone, cfg.color)
	end
	clone.Name = vfxKey .. "_Active"
	prepareVfxClone(clone)

	if clone:IsA("Model") then
		local rootPart = clone:FindFirstChild("RootPart") or clone.PrimaryPart
		if rootPart and rootPart:IsA("BasePart") then
			clone.PrimaryPart = rootPart
		end
	end

	local angleOffset = CFrame.new()
	if cfg.comboAngles and comboIndex and cfg.comboAngles[comboIndex] then
		angleOffset = cfg.comboAngles[comboIndex]
	end
	
	local pivot = root.CFrame * (cfg.offset or CFrame.new()) * angleOffset
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
		clone.Transparency = 1
		clone.CanCollide = false
		clone.Anchored = true
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

	if cfg.emitCount then
		enableEffects(clone, false)
		emitEffects(clone, cfg.emitCount)
	else
		enableEffects(clone, true)
	end
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

function SkillVfxUtil.PlayForSkill(character, skillId, comboIndex)
	local vfxKey = SkillVfxConfig.GetForSkill(skillId)
	if vfxKey then
		return SkillVfxUtil.Play(character, vfxKey, comboIndex)
	end
	return nil
end

function SkillVfxUtil.PlayDash(character)
	return SkillVfxUtil.Play(character, SkillVfxConfig.DashVfx)
end

return SkillVfxUtil
