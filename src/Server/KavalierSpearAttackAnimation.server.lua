--[[
	KavalierSpearAttackAnimation
	============================
	Builds a Spear Thrust attack KeyframeSequence for the Kavalier class.
	
	Animation Breakdown:
	  KF1 (t=0.00) – Wind-up: Spear pulled back, torso rotated, weight on back leg
	  KF2 (t=0.10) – Thrust initiation: Torso rotates forward, arm begins extending
	  KF3 (t=0.17) – IMPACT: Full lunge, maximum extension. "Hit" marker fires here.
	  KF4 (t=0.27) – Follow-through: Slight overshoot, body settling
	  KF5 (t=0.40) – Return to idle: All poses neutral
	
	Rig: R15 (full body: torso, arms, legs, head)
	Priority: Action
	Duration: 0.4 seconds
	Loop: false
	
	The resulting KeyframeSequence is saved to ServerScriptService.Animations.
	To use in-game, upload via the Animation Editor and update
	the Skills config with the resulting rbxassetid.
--]]

local ServerScriptService = game:GetService("ServerScriptService")

----------------------------------------------------------------------
-- Guard: only create once
----------------------------------------------------------------------
local animFolder = ServerScriptService:FindFirstChild("Animations")
if animFolder and animFolder:FindFirstChild("KavalierSpearAttack") then
	print("[KavalierSpearAttack] Animation already exists, skipping creation.")
	return
end

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function createPose(name: string, cf: CFrame, weight: number?): Pose
	local pose = Instance.new("Pose")
	pose.Name = name
	pose.CFrame = cf
	pose.Weight = weight or 1
	pose.EasingStyle = Enum.PoseEasingStyle.Linear
	pose.EasingDirection = Enum.PoseEasingDirection.In
	return pose
end

local function createKeyframe(time: number, poses: {[string]: CFrame}): Keyframe
	local kf = Instance.new("Keyframe")
	kf.Name = "Keyframe_" .. string.format("%.2f", time)
	kf.Time = time

	-- Build R15 pose hierarchy
	local rootPose      = createPose("HumanoidRootPart", CFrame.new())
	local lowerTorso    = createPose("LowerTorso",    poses.LowerTorso    or CFrame.new())
	local upperTorso    = createPose("UpperTorso",    poses.UpperTorso    or CFrame.new())
	local head          = createPose("Head",          poses.Head          or CFrame.new())

	-- Right arm (weapon hand)
	local rightUpperArm = createPose("RightUpperArm", poses.RightUpperArm or CFrame.new())
	local rightLowerArm = createPose("RightLowerArm", poses.RightLowerArm or CFrame.new())
	local rightHand     = createPose("RightHand",     poses.RightHand     or CFrame.new())

	-- Left arm (guide / support hand)
	local leftUpperArm  = createPose("LeftUpperArm",  poses.LeftUpperArm  or CFrame.new())
	local leftLowerArm  = createPose("LeftLowerArm",  poses.LeftLowerArm  or CFrame.new())
	local leftHand      = createPose("LeftHand",      poses.LeftHand      or CFrame.new())

	-- Legs
	local rightUpperLeg = createPose("RightUpperLeg", poses.RightUpperLeg or CFrame.new())
	local rightLowerLeg = createPose("RightLowerLeg", poses.RightLowerLeg or CFrame.new())
	local rightFoot     = createPose("RightFoot",     poses.RightFoot     or CFrame.new())
	local leftUpperLeg  = createPose("LeftUpperLeg",  poses.LeftUpperLeg  or CFrame.new())
	local leftLowerLeg  = createPose("LeftLowerLeg",  poses.LeftLowerLeg  or CFrame.new())
	local leftFoot      = createPose("LeftFoot",      poses.LeftFoot      or CFrame.new())

	-- Assemble limb chains
	rightLowerArm:AddSubPose(rightHand)
	rightUpperArm:AddSubPose(rightLowerArm)
	leftLowerArm:AddSubPose(leftHand)
	leftUpperArm:AddSubPose(leftLowerArm)
	rightLowerLeg:AddSubPose(rightFoot)
	rightUpperLeg:AddSubPose(rightLowerLeg)
	leftLowerLeg:AddSubPose(leftFoot)
	leftUpperLeg:AddSubPose(leftLowerLeg)

	-- Assemble torso → limbs
	upperTorso:AddSubPose(head)
	upperTorso:AddSubPose(rightUpperArm)
	upperTorso:AddSubPose(leftUpperArm)
	lowerTorso:AddSubPose(upperTorso)
	lowerTorso:AddSubPose(rightUpperLeg)
	lowerTorso:AddSubPose(leftUpperLeg)

	-- Root → lowerTorso
	rootPose:AddSubPose(lowerTorso)
	kf:AddPose(rootPose)

	return kf
end

----------------------------------------------------------------------
-- Build KeyframeSequence
----------------------------------------------------------------------
local keyframeSequence = Instance.new("KeyframeSequence")
keyframeSequence.Name = "KavalierSpearAttack"
keyframeSequence.Priority = Enum.AnimationPriority.Action
keyframeSequence.Loop = false

-- ============================================================
-- KF1: Wind-up / Ready Stance  (t = 0.00)
-- Spear drawn back, torso rotated away, weight on rear foot
-- ============================================================
local kf1 = createKeyframe(0.00, {
	LowerTorso    = CFrame.Angles(0, math.rad(-25), 0),
	UpperTorso    = CFrame.Angles(math.rad(-8), math.rad(-20), 0),
	Head          = CFrame.Angles(0, math.rad(15), 0),
	-- Right arm pulled back (weapon arm)
	RightUpperArm = CFrame.Angles(math.rad(-60), math.rad(15), math.rad(10)),
	RightLowerArm = CFrame.Angles(math.rad(-30), 0, 0),
	RightHand     = CFrame.Angles(math.rad(-10), 0, 0),
	-- Left arm extended forward as guide
	LeftUpperArm  = CFrame.Angles(math.rad(30), math.rad(-10), math.rad(-15)),
	LeftLowerArm  = CFrame.Angles(math.rad(-20), 0, 0),
	LeftHand      = CFrame.Angles(math.rad(5), 0, 0),
	-- Back leg (right) weighted
	RightUpperLeg = CFrame.Angles(math.rad(-15), 0, math.rad(5)),
	RightLowerLeg = CFrame.Angles(math.rad(20), 0, 0),
	RightFoot     = CFrame.Angles(math.rad(5), 0, 0),
	-- Front leg (left) forward
	LeftUpperLeg  = CFrame.Angles(math.rad(20), 0, math.rad(-5)),
	LeftLowerLeg  = CFrame.Angles(math.rad(-10), 0, 0),
	LeftFoot      = CFrame.Angles(math.rad(-5), 0, 0),
})

-- ============================================================
-- KF2: Thrust Initiation  (t = 0.10)
-- Torso begins rotating forward, arm driving spear forward
-- ============================================================
local kf2 = createKeyframe(0.10, {
	LowerTorso    = CFrame.Angles(0, math.rad(5), 0),
	UpperTorso    = CFrame.Angles(math.rad(5), math.rad(10), 0),
	Head          = CFrame.Angles(0, math.rad(-5), 0),
	RightUpperArm = CFrame.Angles(math.rad(-20), math.rad(5), math.rad(5)),
	RightLowerArm = CFrame.Angles(math.rad(-15), 0, 0),
	RightHand     = CFrame.Angles(math.rad(-5), 0, 0),
	LeftUpperArm  = CFrame.Angles(math.rad(10), math.rad(-5), math.rad(-10)),
	LeftLowerArm  = CFrame.Angles(math.rad(-25), 0, 0),
	LeftHand      = CFrame.Angles(0, 0, 0),
	RightUpperLeg = CFrame.Angles(math.rad(-5), 0, math.rad(3)),
	RightLowerLeg = CFrame.Angles(math.rad(10), 0, 0),
	RightFoot     = CFrame.Angles(math.rad(3), 0, 0),
	LeftUpperLeg  = CFrame.Angles(math.rad(10), 0, math.rad(-3)),
	LeftLowerLeg  = CFrame.Angles(math.rad(-5), 0, 0),
	LeftFoot      = CFrame.Angles(math.rad(-3), 0, 0),
})

-- ============================================================
-- KF3: Full Thrust / IMPACT  (t = 0.17)
-- Maximum lunge extension — spear fully forward
-- "Hit" KeyframeMarker fires here for damage timing
-- ============================================================
local kf3 = createKeyframe(0.17, {
	LowerTorso    = CFrame.Angles(math.rad(5), math.rad(25), 0),
	UpperTorso    = CFrame.Angles(math.rad(12), math.rad(25), 0),
	Head          = CFrame.Angles(math.rad(-5), math.rad(-10), 0),
	-- Right arm FULLY extended forward (THRUST!)
	RightUpperArm = CFrame.Angles(math.rad(45), math.rad(-5), 0),
	RightLowerArm = CFrame.Angles(math.rad(-8), 0, 0),
	RightHand     = CFrame.Angles(math.rad(10), 0, math.rad(5)),
	-- Left arm swung back for balance
	LeftUpperArm  = CFrame.Angles(math.rad(-40), math.rad(10), math.rad(-20)),
	LeftLowerArm  = CFrame.Angles(math.rad(-35), 0, 0),
	LeftHand      = CFrame.Angles(math.rad(-5), 0, 0),
	-- Deep lunge: left leg forward, right leg bracing
	RightUpperLeg = CFrame.Angles(math.rad(-20), 0, math.rad(8)),
	RightLowerLeg = CFrame.Angles(math.rad(30), 0, 0),
	RightFoot     = CFrame.Angles(math.rad(8), 0, 0),
	LeftUpperLeg  = CFrame.Angles(math.rad(35), 0, math.rad(-8)),
	LeftLowerLeg  = CFrame.Angles(math.rad(-25), 0, 0),
	LeftFoot      = CFrame.Angles(math.rad(-8), 0, 0),
})

-- Add "Hit" event marker at the impact frame
local hitMarker = Instance.new("KeyframeMarker")
hitMarker.Name = "Hit"
hitMarker.Value = "Hit"
hitMarker.Parent = kf3

-- ============================================================
-- KF4: Follow-through  (t = 0.27)
-- Slight overshoot past impact, body settling
-- ============================================================
local kf4 = createKeyframe(0.27, {
	LowerTorso    = CFrame.Angles(math.rad(3), math.rad(20), 0),
	UpperTorso    = CFrame.Angles(math.rad(8), math.rad(18), 0),
	Head          = CFrame.Angles(math.rad(-3), math.rad(-5), 0),
	RightUpperArm = CFrame.Angles(math.rad(35), math.rad(-3), 0),
	RightLowerArm = CFrame.Angles(math.rad(-12), 0, 0),
	RightHand     = CFrame.Angles(math.rad(5), 0, math.rad(3)),
	LeftUpperArm  = CFrame.Angles(math.rad(-20), math.rad(5), math.rad(-12)),
	LeftLowerArm  = CFrame.Angles(math.rad(-20), 0, 0),
	LeftHand      = CFrame.Angles(0, 0, 0),
	RightUpperLeg = CFrame.Angles(math.rad(-10), 0, math.rad(5)),
	RightLowerLeg = CFrame.Angles(math.rad(18), 0, 0),
	RightFoot     = CFrame.Angles(math.rad(5), 0, 0),
	LeftUpperLeg  = CFrame.Angles(math.rad(20), 0, math.rad(-5)),
	LeftLowerLeg  = CFrame.Angles(math.rad(-15), 0, 0),
	LeftFoot      = CFrame.Angles(math.rad(-5), 0, 0),
})

-- ============================================================
-- KF5: Return to Idle  (t = 0.40)
-- All body parts back to neutral pose
-- ============================================================
local kf5 = createKeyframe(0.40, {
	LowerTorso    = CFrame.new(),
	UpperTorso    = CFrame.new(),
	Head          = CFrame.new(),
	RightUpperArm = CFrame.new(),
	RightLowerArm = CFrame.new(),
	RightHand     = CFrame.new(),
	LeftUpperArm  = CFrame.new(),
	LeftLowerArm  = CFrame.new(),
	LeftHand      = CFrame.new(),
	RightUpperLeg = CFrame.new(),
	RightLowerLeg = CFrame.new(),
	RightFoot     = CFrame.new(),
	LeftUpperLeg  = CFrame.new(),
	LeftLowerLeg  = CFrame.new(),
	LeftFoot      = CFrame.new(),
})

----------------------------------------------------------------------
-- Assemble & Save
----------------------------------------------------------------------
kf1.Parent = keyframeSequence
kf2.Parent = keyframeSequence
kf3.Parent = keyframeSequence
kf4.Parent = keyframeSequence
kf5.Parent = keyframeSequence

-- Create or find the Animations folder under ServerScriptService
if not animFolder then
	animFolder = Instance.new("Folder")
	animFolder.Name = "Animations"
	animFolder.Parent = ServerScriptService
end

keyframeSequence.Parent = animFolder

----------------------------------------------------------------------
-- Done!
----------------------------------------------------------------------
print("=== Kavalier Spear Attack Animation ===")
print("  Saved to: ServerScriptService.Animations.KavalierSpearAttack")
print("  Priority: Action")
print("  Duration: 0.4s")
print("  Keyframes: 5 (Wind-up → Thrust → Impact → Follow-through → Idle)")
print("  Hit Marker: t = 0.17s")
print("  Rig: R15 full body")
print("")
print("  To use in-game:")
print("    1. Open Animation Editor → Load from Explorer → KavalierSpearAttack")
print("    2. Publish to Roblox to get an rbxassetid")
print("    3. Update Kavalier_AutoAttack comboAnims in Skills config")
print("========================================")
