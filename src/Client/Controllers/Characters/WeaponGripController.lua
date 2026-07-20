local Controller = {}

function Controller:Start()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponGrips = require(Shared.Config.WeaponGrips)
local SkinToolBuilder = require(Shared.Util.SkinToolBuilder)
local AnimationController = require(Shared.Util.AnimationController)
local LocalAnimationBuilder = require(Shared.Util.LocalAnimationBuilder)

local TOOL_HOLD_ANIMS = {
	sword = LocalAnimationBuilder.GetWarriorToolHold,
	axe = LocalAnimationBuilder.GetWarriorToolHold,
	staff = LocalAnimationBuilder.GetMageToolHold,
	bow = LocalAnimationBuilder.GetArcherToolHold,
	mace = LocalAnimationBuilder.GetPriestToolHold,
	spear = LocalAnimationBuilder.GetKavalierToolHold,
}

local player = Players.LocalPlayer
local holdTrack = nil
local currentTool = nil
local currentStyle = nil
local moveEffectConn = nil

local function setNamedEffects(tool, effectNames, enabled)
	if not tool then
		return
	end
	for _, desc in tool:GetDescendants() do
		if table.find(effectNames, desc.Name) then
			if desc:IsA("Trail") or desc:IsA("ParticleEmitter") then
				desc.Enabled = enabled
			end
		end
	end
end

local function getWeaponTool(character)
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("WeaponId") then
			return child
		end
	end
	return nil
end

local function applyGrip(tool, grip)
	if tool and grip then
		tool.Grip = grip
	end
end

local function attachBowToLeftHand(character, tool, c0, c1)
	if not character then
		return
	end
	local handle = tool:FindFirstChild("Handle")
	local leftHand = character:FindFirstChild("LeftHand")
	if not handle or not leftHand then
		return
	end

	local cfg = WeaponGrips.Styles.bow
	for _, desc in character:GetDescendants() do
		if desc:IsA("Motor6D") and desc.Part1 == handle then
			desc.Part0 = leftHand
			desc.C0 = c0 or cfg.leftC0
			desc.C1 = c1 or cfg.leftC1
			return
		end
	end
end

local function stopHoldTrack()
	if holdTrack then
		holdTrack:Stop(0.2)
		holdTrack = nil
	end
end

local function stopMoveEffects()
	if moveEffectConn then
		moveEffectConn:Disconnect()
		moveEffectConn = nil
	end
	setNamedEffects(currentTool, { "CyanMoveTrail" }, false)
end

local function bindMoveEffects(humanoid, tool)
	stopMoveEffects()
	if not humanoid or not tool then
		return
	end
	moveEffectConn = humanoid.Running:Connect(function(speed)
		setNamedEffects(tool, { "CyanMoveTrail" }, speed > 0.5)
	end)
end

local function playHoldAnim(humanoid, style)
	local getAnim = TOOL_HOLD_ANIMS[style]
	if not getAnim then
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	stopHoldTrack()
	local anim = AnimationController.GetAnimation(getAnim())
	holdTrack = animator:LoadAnimation(anim)
	holdTrack.Priority = Enum.AnimationPriority.Idle
	holdTrack.Looped = true
	holdTrack:Play(0.2)
end

local function onActionAnim(track)
	if not currentTool or not currentStyle then
		return
	end
	if track.Priority.Value < Enum.AnimationPriority.Action.Value then
		return
	end

	local cfg = WeaponGrips.Styles[currentStyle]
	applyGrip(currentTool, cfg.attack)
	if cfg.leftHandAttach then
		local character = player.Character
		attachBowToLeftHand(character, currentTool, cfg.attackLeftC0 or cfg.leftC0, cfg.attackLeftC1 or cfg.leftC1)
	end
	stopHoldTrack()
	SkinToolBuilder.BindAnimationEffects(currentTool, track)

	track.Stopped:Once(function()
		if not currentTool or not currentStyle then
			return
		end
		local character = player.Character
		applyGrip(currentTool, cfg.idle)
		if cfg.leftHandAttach then
			attachBowToLeftHand(character, currentTool, cfg.leftC0, cfg.leftC1)
		end
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and character:GetAttribute("IsResting") ~= true then
			playHoldAnim(humanoid, currentStyle)
		end
	end)
end

local function setupWeapon(character, tool)
	local weaponId = tool:GetAttribute("WeaponId")
	if weaponId then
		SkinToolBuilder.ApplySkin(tool, weaponId)
	end

	currentTool = tool
	currentStyle = tool:GetAttribute("WeaponStyle") or WeaponGrips.GetStyle(weaponId, SkinToolBuilder.GetItem(weaponId))
	local cfg = WeaponGrips.Styles[currentStyle]

	local function applyIdleGrip()
		applyGrip(tool, cfg.idle)
		tool:SetAttribute("GripVersion", WeaponGrips.GRIP_VERSION)
	end

	applyIdleGrip()
	task.delay(0.25, applyIdleGrip)
	task.delay(0.5, applyIdleGrip)

	if cfg.leftHandAttach then
		task.delay(0.25, function()
			attachBowToLeftHand(character, tool, cfg.leftC0, cfg.leftC1)
			applyIdleGrip()
		end)
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and character:GetAttribute("IsResting") ~= true then
		playHoldAnim(humanoid, currentStyle)
	end
	bindMoveEffects(humanoid, tool)
end

local function onCharacter(character)
	stopHoldTrack()
	stopMoveEffects()
	currentTool = nil
	currentStyle = nil

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("WeaponId") then
			task.wait(0.15)
			setupWeapon(character, child)
		end
	end)

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		return
	end

	humanoid.AnimationPlayed:Connect(onActionAnim)

	character:GetAttributeChangedSignal("IsResting"):Connect(function()
		if character:GetAttribute("IsResting") then
			stopHoldTrack()
		elseif currentTool and currentStyle then
			playHoldAnim(humanoid, currentStyle)
		end
	end)

	local existing = getWeaponTool(character)
	if existing then
		task.wait(0.15)
		setupWeapon(character, existing)
	end
end

player.CharacterAdded:Connect(function(character)
	task.spawn(function()
		onCharacter(character)
	end)
end)
if player.Character then
	task.spawn(function()
		onCharacter(player.Character)
	end)
end

end

return Controller
