local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationIdRegistry = require(script.Parent.AnimationIdRegistry)

local cachedIds = {}
local AnimationBuilder = {}
local warnedMissing = {}

local function createPose(name, cf, weight)
	local pose = Instance.new("Pose")
	pose.Name = name
	pose.CFrame = cf
	pose.Weight = weight or 1
	pose.EasingStyle = Enum.PoseEasingStyle.Linear
	pose.EasingDirection = Enum.PoseEasingDirection.In
	return pose
end

local function withWrist(poses)
	local result = table.clone(poses)
	if result.RightUpperArm and not result.RightHand then
		result.RightHand = CFrame.Angles(math.rad(-12), math.rad(8), math.rad(-15))
	end
	if result.LeftUpperArm and not result.LeftHand then
		result.LeftHand = CFrame.Angles(math.rad(5), 0, math.rad(8))
	end
	return result
end

local function createKeyframe(time, poses)
	poses = withWrist(poses)
	local kf = Instance.new("Keyframe")
	kf.Name = "Keyframe_" .. string.format("%.2f", time)
	kf.Time = time

	local rootPose      = createPose("HumanoidRootPart", CFrame.new())
	local lowerTorso    = createPose("LowerTorso",    poses.LowerTorso    or CFrame.new())
	local upperTorso    = createPose("UpperTorso",    poses.UpperTorso    or CFrame.new())
	local head          = createPose("Head",          poses.Head          or CFrame.new())

	local rightUpperArm = createPose("RightUpperArm", poses.RightUpperArm or CFrame.new())
	local rightLowerArm = createPose("RightLowerArm", poses.RightLowerArm or CFrame.new())
	local rightHand     = createPose("RightHand",     poses.RightHand     or CFrame.new())

	local leftUpperArm  = createPose("LeftUpperArm",  poses.LeftUpperArm  or CFrame.new())
	local leftLowerArm  = createPose("LeftLowerArm",  poses.LeftLowerArm  or CFrame.new())
	local leftHand      = createPose("LeftHand",      poses.LeftHand      or CFrame.new())

	local rightUpperLeg = createPose("RightUpperLeg", poses.RightUpperLeg or CFrame.new())
	local rightLowerLeg = createPose("RightLowerLeg", poses.RightLowerLeg or CFrame.new())
	local rightFoot     = createPose("RightFoot",     poses.RightFoot     or CFrame.new())
	
	local leftUpperLeg  = createPose("LeftUpperLeg",  poses.LeftUpperLeg  or CFrame.new())
	local leftLowerLeg  = createPose("LeftLowerLeg",  poses.LeftLowerLeg  or CFrame.new())
	local leftFoot      = createPose("LeftFoot",      poses.LeftFoot      or CFrame.new())

	rightLowerArm:AddSubPose(rightHand)
	rightUpperArm:AddSubPose(rightLowerArm)
	leftLowerArm:AddSubPose(leftHand)
	leftUpperArm:AddSubPose(leftLowerArm)
	rightLowerLeg:AddSubPose(rightFoot)
	rightUpperLeg:AddSubPose(rightLowerLeg)
	leftLowerLeg:AddSubPose(leftFoot)
	leftUpperLeg:AddSubPose(leftLowerLeg)

	upperTorso:AddSubPose(head)
	upperTorso:AddSubPose(rightUpperArm)
	upperTorso:AddSubPose(leftUpperArm)
	lowerTorso:AddSubPose(upperTorso)
	lowerTorso:AddSubPose(rightUpperLeg)
	lowerTorso:AddSubPose(leftUpperLeg)

	rootPose:AddSubPose(lowerTorso)
	kf:AddPose(rootPose)

	return kf
end

local function getPersistedId(name)
	local folder = ReplicatedStorage:FindFirstChild("Shared")
		and ReplicatedStorage.Shared:FindFirstChild("AnimationIds")
	if folder then
		local v = folder:FindFirstChild(name)
		if v and v:IsA("StringValue") and v.Value ~= "" then
			return v.Value
		end
	end
	return AnimationIdRegistry[name]
end

local function persistId(name, id)
	AnimationIdRegistry[name] = id
	if not RunService:IsStudio() then
		return
	end
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	if not shared then
		return
	end
	local folder = shared:FindFirstChild("AnimationIds")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "AnimationIds"
		folder.Parent = shared
	end
	local v = folder:FindFirstChild(name)
	if not v then
		v = Instance.new("StringValue")
		v.Name = name
		v.Parent = folder
	end
	v.Value = id
end

local function registerSequence(name, keyframes, isLooping)
	if cachedIds[name] then
		return cachedIds[name]
	end

	local persisted = getPersistedId(name)
	if persisted then
		cachedIds[name] = persisted
		return persisted
	end

	local ok, animId = pcall(function()
		local keyframeSequence = Instance.new("KeyframeSequence")
		keyframeSequence.Name = name
		keyframeSequence.Priority = Enum.AnimationPriority.Action
		keyframeSequence.Loop = isLooping or false
		for _, kf in ipairs(keyframes) do
			kf.Parent = keyframeSequence
		end
		return KeyframeSequenceProvider:RegisterKeyframeSequence(keyframeSequence)
	end)

	if ok and type(animId) == "string" and animId ~= "" then
		cachedIds[name] = animId
		persistId(name, animId)
		return animId
	end

	if not warnedMissing[name] then
		warnedMissing[name] = true
		warn("[LocalAnimationBuilder] Animation not registered:", name)
	end
	cachedIds[name] = ""
	return ""
end

function AnimationBuilder.GetAnimId(methodName)
	if type(methodName) ~= "string" then
		return nil
	end
	local fn = AnimationBuilder[methodName]
	if type(fn) ~= "function" then
		return nil
	end
	return fn()
end

local function addMarker(kf, markerName)
	local marker = Instance.new("KeyframeMarker")
	marker.Name = markerName
	marker.Value = markerName
	marker.Parent = kf
end

-- ==========================================
-- KAVALIER 5-HIT AUTO ATTACK COMBO
-- Each animation is exactly 0.7 seconds
-- ==========================================

function AnimationBuilder.GetKavalierAuto1()
	return registerSequence("KavalierAuto1", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(-30), 0),
			RightUpperArm = CFrame.Angles(math.rad(20), math.rad(60), math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(20), math.rad(-20), math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Slash Right
				LowerTorso    = CFrame.Angles(0, math.rad(30), 0),
				RightUpperArm = CFrame.Angles(math.rad(20), math.rad(-60), math.rad(20)),
				LeftUpperArm  = CFrame.Angles(math.rad(20), math.rad(40), math.rad(-20)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetKavalierAuto2()
	return registerSequence("KavalierAuto2", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(30), 0),
			RightUpperArm = CFrame.Angles(math.rad(20), math.rad(-60), math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(20), math.rad(40), math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Slash Left
				LowerTorso    = CFrame.Angles(0, math.rad(-30), 0),
				RightUpperArm = CFrame.Angles(math.rad(20), math.rad(60), math.rad(20)),
				LeftUpperArm  = CFrame.Angles(math.rad(20), math.rad(-20), math.rad(-20)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetKavalierAuto3()
	return registerSequence("KavalierAuto3", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(math.rad(10), math.rad(-20), 0),
			RightUpperArm = CFrame.Angles(math.rad(-40), math.rad(20), math.rad(10)),
			LeftUpperArm  = CFrame.Angles(math.rad(20), math.rad(-10), math.rad(-10)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Thrust High
				LowerTorso    = CFrame.Angles(math.rad(-10), math.rad(20), 0),
				RightUpperArm = CFrame.Angles(math.rad(50), math.rad(-10), math.rad(10)),
				LeftUpperArm  = CFrame.Angles(math.rad(50), math.rad(30), math.rad(-10)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetKavalierAuto4()
	return registerSequence("KavalierAuto4", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(math.rad(-10), math.rad(-20), 0),
			RightUpperArm = CFrame.Angles(math.rad(60), math.rad(20), math.rad(10)),
			LeftUpperArm  = CFrame.Angles(math.rad(60), math.rad(-10), math.rad(-10)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Thrust Low
				LowerTorso    = CFrame.Angles(math.rad(20), math.rad(20), 0),
				RightUpperArm = CFrame.Angles(math.rad(-30), math.rad(-10), math.rad(10)),
				LeftUpperArm  = CFrame.Angles(math.rad(-30), math.rad(30), math.rad(-10)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetKavalierAuto5()
	return registerSequence("KavalierAuto5", {
		createKeyframe(0.00, {
			-- Deep wind up
			LowerTorso    = CFrame.Angles(math.rad(-20), math.rad(-30), 0),
			RightUpperArm = CFrame.Angles(math.rad(-70), math.rad(30), math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(40), math.rad(-20), math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Heavy Lunge
				LowerTorso    = CFrame.Angles(math.rad(15), math.rad(35), 0),
				RightUpperArm = CFrame.Angles(math.rad(60), math.rad(-20), math.rad(10)),
				LeftUpperArm  = CFrame.Angles(math.rad(-30), math.rad(40), math.rad(-10)),
				RightUpperLeg = CFrame.Angles(math.rad(-20), 0, math.rad(10)),
				LeftUpperLeg  = CFrame.Angles(math.rad(30), 0, math.rad(-10)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

-- ==========================================
-- OTHER SKILLS
-- ==========================================

function AnimationBuilder.GetKavalierDashStrike()
	return registerSequence("KavalierDashStrike", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(math.rad(-15), 0, 0),
			UpperTorso    = CFrame.Angles(math.rad(-10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(-40), math.rad(20), 0),
			LeftUpperArm  = CFrame.Angles(math.rad(20), math.rad(-20), 0),
			RightUpperLeg = CFrame.Angles(math.rad(-30), 0, 0),
			LeftUpperLeg  = CFrame.Angles(math.rad(10), 0, 0),
		}),
		createKeyframe(0.20, {
			LowerTorso    = CFrame.Angles(math.rad(20), 0, 0),
			UpperTorso    = CFrame.Angles(math.rad(15), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(-10), 0, 0),
			LeftUpperArm  = CFrame.Angles(math.rad(-30), 0, 0),
			RightUpperLeg = CFrame.Angles(math.rad(20), 0, 0),
			LeftUpperLeg  = CFrame.Angles(math.rad(-40), 0, 0),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				LowerTorso    = CFrame.Angles(math.rad(10), math.rad(15), 0),
				UpperTorso    = CFrame.Angles(math.rad(5), math.rad(15), 0),
				RightUpperArm = CFrame.Angles(math.rad(60), 0, 0),
				LeftUpperArm  = CFrame.Angles(math.rad(-40), 0, 0),
				RightUpperLeg = CFrame.Angles(math.rad(10), 0, 0),
				LeftUpperLeg  = CFrame.Angles(math.rad(-20), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.60, {})
	})
end

function AnimationBuilder.GetKavalierSpearThrow()
	return registerSequence("KavalierSpearThrow", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(-40), 0),
			UpperTorso    = CFrame.Angles(math.rad(-10), math.rad(-30), 0),
			RightUpperArm = CFrame.Angles(math.rad(-80), math.rad(30), math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(60), math.rad(-20), math.rad(-10)),
		}),
		(function()
			local kf = createKeyframe(0.30, {
				LowerTorso    = CFrame.Angles(0, math.rad(30), 0),
				UpperTorso    = CFrame.Angles(math.rad(10), math.rad(30), 0),
				RightUpperArm = CFrame.Angles(math.rad(70), math.rad(-10), math.rad(10)),
				LeftUpperArm  = CFrame.Angles(math.rad(-40), math.rad(10), math.rad(-20)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.50, {
			LowerTorso    = CFrame.Angles(0, math.rad(40), 0),
			UpperTorso    = CFrame.Angles(math.rad(15), math.rad(40), 0),
			RightUpperArm = CFrame.Angles(math.rad(20), math.rad(-20), math.rad(15)),
			LeftUpperArm  = CFrame.Angles(math.rad(-50), math.rad(20), math.rad(-30)),
		}),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetKavalierLanceSpin()
	return registerSequence("KavalierLanceSpin", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(-45), 0),
			UpperTorso    = CFrame.Angles(0, math.rad(-45), 0),
			RightUpperArm = CFrame.Angles(math.rad(20), math.rad(40), math.rad(30)),
			LeftUpperArm  = CFrame.Angles(math.rad(20), math.rad(-40), math.rad(-30)),
		}),
		(function()
			local kf = createKeyframe(0.25, {
				LowerTorso    = CFrame.Angles(0, math.rad(180), 0),
				UpperTorso    = CFrame.Angles(0, math.rad(180), 0),
				RightUpperArm = CFrame.Angles(math.rad(0), math.rad(90), math.rad(45)),
				LeftUpperArm  = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(-45)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		(function()
			local kf = createKeyframe(0.50, {
				LowerTorso    = CFrame.Angles(0, math.rad(360), 0),
				UpperTorso    = CFrame.Angles(0, math.rad(360), 0),
				RightUpperArm = CFrame.Angles(math.rad(20), math.rad(40), math.rad(30)),
				LeftUpperArm  = CFrame.Angles(math.rad(20), math.rad(-40), math.rad(-30)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetKavalierDragonCharge()
	return registerSequence("KavalierDragonCharge", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(math.rad(-20), 0, 0),
			UpperTorso    = CFrame.Angles(math.rad(-20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(120), math.rad(20), math.rad(10)),
			LeftUpperArm  = CFrame.Angles(math.rad(120), math.rad(-20), math.rad(-10)),
			RightUpperLeg = CFrame.Angles(math.rad(-40), 0, 0),
			LeftUpperLeg  = CFrame.Angles(math.rad(-40), 0, 0),
		}),
		createKeyframe(0.30, {
			LowerTorso    = CFrame.Angles(math.rad(30), 0, 0),
			UpperTorso    = CFrame.Angles(math.rad(20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(160), 0, 0),
			LeftUpperArm  = CFrame.Angles(math.rad(160), 0, 0),
			RightUpperLeg = CFrame.Angles(math.rad(20), 0, 0),
			LeftUpperLeg  = CFrame.Angles(math.rad(20), 0, 0),
		}),
		createKeyframe(0.60, {
			LowerTorso    = CFrame.Angles(math.rad(40), 0, 0),
			UpperTorso    = CFrame.Angles(math.rad(20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(160), 0, 0),
			LeftUpperArm  = CFrame.Angles(math.rad(160), 0, 0),
			RightUpperLeg = CFrame.Angles(math.rad(30), 0, 0),
			LeftUpperLeg  = CFrame.Angles(math.rad(30), 0, 0),
		}),
		(function()
			local kf = createKeyframe(0.80, {
				LowerTorso    = CFrame.Angles(math.rad(-30), 0, 0),
				UpperTorso    = CFrame.Angles(math.rad(-20), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(40), math.rad(-20), 0),
				LeftUpperArm  = CFrame.Angles(math.rad(40), math.rad(20), 0),
				RightUpperLeg = CFrame.Angles(math.rad(-30), 0, 0),
				LeftUpperLeg  = CFrame.Angles(math.rad(30), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(1.10, {})
	})
end

-- ==========================================
-- MAGE ANIMATIONS
-- ==========================================

function AnimationBuilder.GetMageAuto1()
	return registerSequence("MageAuto1", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(-20), 0),
			RightUpperArm = CFrame.Angles(math.rad(40), 0, math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(20), 0, math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Right hand push
				LowerTorso    = CFrame.Angles(0, math.rad(20), 0),
				RightUpperArm = CFrame.Angles(math.rad(90), 0, math.rad(-10)),
				RightLowerArm = CFrame.Angles(math.rad(-10), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetMageAuto2()
	return registerSequence("MageAuto2", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(20), 0),
			LeftUpperArm  = CFrame.Angles(math.rad(40), 0, math.rad(-20)),
			RightUpperArm = CFrame.Angles(math.rad(20), 0, math.rad(20)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Left hand push
				LowerTorso    = CFrame.Angles(0, math.rad(-20), 0),
				LeftUpperArm  = CFrame.Angles(math.rad(90), 0, math.rad(10)),
				LeftLowerArm  = CFrame.Angles(math.rad(-10), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetMageAuto3()
	return registerSequence("MageAuto3", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(math.rad(-10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(45), math.rad(30), math.rad(10)),
			LeftUpperArm  = CFrame.Angles(math.rad(45), math.rad(-30), math.rad(-10)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Double push
				LowerTorso    = CFrame.Angles(math.rad(10), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(90), math.rad(-10), 0),
				LeftUpperArm  = CFrame.Angles(math.rad(90), math.rad(10), 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetMageAuto4()
	return registerSequence("MageAuto4", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(30), 0),
			RightUpperArm = CFrame.Angles(math.rad(60), math.rad(-40), math.rad(20)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Horizontal swipe
				LowerTorso    = CFrame.Angles(0, math.rad(-30), 0),
				RightUpperArm = CFrame.Angles(math.rad(60), math.rad(40), math.rad(40)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetMageAuto5()
	return registerSequence("MageAuto5", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(math.rad(-15), 0, 0),
			UpperTorso    = CFrame.Angles(math.rad(-10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(140), 0, math.rad(10)),
			LeftUpperArm  = CFrame.Angles(math.rad(140), 0, math.rad(-10)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Overhead throw
				LowerTorso    = CFrame.Angles(math.rad(15), 0, 0),
				UpperTorso    = CFrame.Angles(math.rad(10), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(20), 0, math.rad(10)),
				LeftUpperArm  = CFrame.Angles(math.rad(20), 0, math.rad(-10)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetMageFireball()
	return registerSequence("MageFireball", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(-45), 0),
			RightUpperArm = CFrame.Angles(math.rad(120), math.rad(45), math.rad(30)),
			LeftUpperArm  = CFrame.Angles(math.rad(45), math.rad(-20), math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.30, {
				LowerTorso    = CFrame.Angles(0, math.rad(30), 0),
				RightUpperArm = CFrame.Angles(math.rad(80), math.rad(-20), 0),
				LeftUpperArm  = CFrame.Angles(math.rad(-20), 0, math.rad(-20)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.60, {})
	})
end

function AnimationBuilder.GetMageIceSpike()
	return registerSequence("MageIceSpike", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(math.rad(-10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(100), 0, math.rad(-10)),
			LeftUpperArm  = CFrame.Angles(math.rad(100), 0, math.rad(10)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Thrust hands downward to ground
				LowerTorso    = CFrame.Angles(math.rad(30), 0, 0),
				UpperTorso    = CFrame.Angles(math.rad(20), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(-20), 0, math.rad(-10)),
				LeftUpperArm  = CFrame.Angles(math.rad(-20), 0, math.rad(10)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetMageLightningStorm()
	return registerSequence("MageLightningStorm", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(math.rad(10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(-20), 0, math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(-20), 0, math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Raise hands to sky
				LowerTorso    = CFrame.Angles(math.rad(-15), 0, 0),
				Head          = CFrame.Angles(math.rad(30), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(160), 0, math.rad(30)),
				LeftUpperArm  = CFrame.Angles(math.rad(160), 0, math.rad(-30)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetMageMeteor()
	return registerSequence("MageMeteor", {
		createKeyframe(0.00, {
			-- Cross arms
			LowerTorso    = CFrame.Angles(math.rad(10), 0, 0),
			Head          = CFrame.Angles(math.rad(-20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(45), 0, math.rad(-30)),
			LeftUpperArm  = CFrame.Angles(math.rad(45), 0, math.rad(30)),
		}),
		createKeyframe(0.50, {
			-- Explode outward/upward
			LowerTorso    = CFrame.Angles(math.rad(-10), 0, 0),
			Head          = CFrame.Angles(math.rad(20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(150), 0, math.rad(45)),
			LeftUpperArm  = CFrame.Angles(math.rad(150), 0, math.rad(-45)),
		}),
		(function()
			local kf = createKeyframe(0.80, {
				-- Slam down to cast
				LowerTorso    = CFrame.Angles(math.rad(30), 0, 0),
				Head          = CFrame.Angles(math.rad(-10), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(10), 0, math.rad(20)),
				LeftUpperArm  = CFrame.Angles(math.rad(10), 0, math.rad(-20)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(1.20, {})
	})
end

-- ==========================================
-- ARCHER ANIMATIONS
-- ==========================================

function AnimationBuilder.GetArcherAuto1()
	return registerSequence("ArcherAuto1", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(-60), 0),
			RightUpperArm = CFrame.Angles(math.rad(90), 0, math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(90), math.rad(45), math.rad(-45)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Release
				LowerTorso    = CFrame.Angles(0, math.rad(-50), 0),
				RightUpperArm = CFrame.Angles(math.rad(90), 0, math.rad(20)),
				LeftUpperArm  = CFrame.Angles(math.rad(90), 0, math.rad(-70)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetArcherAuto2()
	return registerSequence("ArcherAuto2", {
		createKeyframe(0.00, {
			-- Crouched draw
			LowerTorso    = CFrame.Angles(math.rad(-10), math.rad(-50), 0),
			RightUpperLeg = CFrame.Angles(math.rad(10), 0, 0),
			LeftUpperLeg  = CFrame.Angles(math.rad(10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(80), 0, math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(80), math.rad(40), math.rad(-40)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				LowerTorso    = CFrame.Angles(math.rad(-5), math.rad(-45), 0),
				RightUpperLeg = CFrame.Angles(math.rad(5), 0, 0),
				LeftUpperLeg  = CFrame.Angles(math.rad(5), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(80), 0, math.rad(20)),
				LeftUpperArm  = CFrame.Angles(math.rad(80), 0, math.rad(-60)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetArcherAuto3()
	return registerSequence("ArcherAuto3", {
		createKeyframe(0.00, {
			-- Tilted bow
			LowerTorso    = CFrame.Angles(0, math.rad(-60), math.rad(15)),
			RightUpperArm = CFrame.Angles(math.rad(100), math.rad(20), math.rad(30)),
			LeftUpperArm  = CFrame.Angles(math.rad(80), math.rad(45), math.rad(-30)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				LowerTorso    = CFrame.Angles(0, math.rad(-55), math.rad(10)),
				RightUpperArm = CFrame.Angles(math.rad(100), math.rad(20), math.rad(30)),
				LeftUpperArm  = CFrame.Angles(math.rad(80), 0, math.rad(-60)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetArcherAuto4()
	return registerSequence("ArcherAuto4", {
		createKeyframe(0.00, {
			-- Quick draw
			LowerTorso    = CFrame.Angles(0, math.rad(-40), 0),
			RightUpperArm = CFrame.Angles(math.rad(70), 0, math.rad(10)),
			LeftUpperArm  = CFrame.Angles(math.rad(70), math.rad(30), math.rad(-30)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				LowerTorso    = CFrame.Angles(0, math.rad(-30), 0),
				RightUpperArm = CFrame.Angles(math.rad(70), 0, math.rad(10)),
				LeftUpperArm  = CFrame.Angles(math.rad(70), 0, math.rad(-50)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetArcherAuto5()
	return registerSequence("ArcherAuto5", {
		createKeyframe(0.00, {
			-- Deep draw
			LowerTorso    = CFrame.Angles(math.rad(5), math.rad(-70), 0),
			RightUpperArm = CFrame.Angles(math.rad(90), math.rad(-10), math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(90), math.rad(60), math.rad(-60)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				LowerTorso    = CFrame.Angles(math.rad(-5), math.rad(-60), 0),
				RightUpperArm = CFrame.Angles(math.rad(90), math.rad(-10), math.rad(20)),
				LeftUpperArm  = CFrame.Angles(math.rad(90), math.rad(-10), math.rad(-80)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetArcherMultiShot()
	return registerSequence("ArcherMultiShot", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(-40), 0),
			RightUpperArm = CFrame.Angles(math.rad(90), 0, math.rad(40)),
			LeftUpperArm  = CFrame.Angles(math.rad(90), math.rad(45), math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.25, {
				-- Wide sweep release
				LowerTorso    = CFrame.Angles(0, math.rad(20), 0),
				RightUpperArm = CFrame.Angles(math.rad(90), 0, math.rad(-30)),
				LeftUpperArm  = CFrame.Angles(math.rad(90), 0, math.rad(-70)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.50, {})
	})
end

function AnimationBuilder.GetArcherPiercingArrow()
	return registerSequence("ArcherPiercingArrow", {
		createKeyframe(0.00, {
			-- Extreme lean back
			LowerTorso    = CFrame.Angles(math.rad(15), math.rad(-70), 0),
			UpperTorso    = CFrame.Angles(math.rad(10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(100), math.rad(-20), math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(100), math.rad(80), math.rad(-60)),
		}),
		(function()
			local kf = createKeyframe(0.30, {
				-- Explosive snap forward
				LowerTorso    = CFrame.Angles(math.rad(-10), math.rad(-40), 0),
				UpperTorso    = CFrame.Angles(math.rad(-15), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(80), math.rad(10), math.rad(20)),
				LeftUpperArm  = CFrame.Angles(math.rad(80), math.rad(-20), math.rad(-80)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.60, {})
	})
end

function AnimationBuilder.GetArcherRainOfArrows()
	return registerSequence("ArcherRainOfArrows", {
		createKeyframe(0.00, {
			-- Aiming straight up
			LowerTorso    = CFrame.Angles(math.rad(10), math.rad(-45), 0),
			Head          = CFrame.Angles(math.rad(45), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(160), 0, math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(160), math.rad(45), math.rad(-45)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Release up
				LowerTorso    = CFrame.Angles(math.rad(5), math.rad(-35), 0),
				Head          = CFrame.Angles(math.rad(45), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(160), 0, math.rad(20)),
				LeftUpperArm  = CFrame.Angles(math.rad(160), 0, math.rad(-70)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetArcherSniperShot()
	return registerSequence("ArcherSniperShot", {
		createKeyframe(0.00, {
			-- Dropping to one knee
			LowerTorso    = CFrame.Angles(math.rad(-10), math.rad(-80), 0),
			RightUpperLeg = CFrame.Angles(math.rad(40), 0, 0),
			LeftUpperLeg  = CFrame.Angles(math.rad(-60), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(90), 0, math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(90), math.rad(60), math.rad(-50)),
		}),
		createKeyframe(0.40, {
			-- Deep, focused hold
			LowerTorso    = CFrame.Angles(math.rad(-15), math.rad(-85), 0),
			RightUpperLeg = CFrame.Angles(math.rad(45), 0, 0),
			LeftUpperLeg  = CFrame.Angles(math.rad(-65), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(90), math.rad(-10), math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(90), math.rad(70), math.rad(-60)),
		}),
		(function()
			local kf = createKeyframe(0.60, {
				-- Release
				LowerTorso    = CFrame.Angles(math.rad(-10), math.rad(-75), 0),
				RightUpperLeg = CFrame.Angles(math.rad(40), 0, 0),
				LeftUpperLeg  = CFrame.Angles(math.rad(-60), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(90), math.rad(10), math.rad(20)),
				LeftUpperArm  = CFrame.Angles(math.rad(90), math.rad(-20), math.rad(-80)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(1.00, {})
	})
end

-- ==========================================
-- PRIEST ANIMATIONS
-- ==========================================

function AnimationBuilder.GetPriestAuto1()
	return registerSequence("PriestAuto1", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(-15), 0),
			RightUpperArm = CFrame.Angles(math.rad(30), 0, math.rad(10)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Gentle forward sweep
				LowerTorso    = CFrame.Angles(0, math.rad(15), 0),
				RightUpperArm = CFrame.Angles(math.rad(70), math.rad(-20), 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetPriestAuto2()
	return registerSequence("PriestAuto2", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(15), 0),
			LeftUpperArm  = CFrame.Angles(math.rad(30), 0, math.rad(-10)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Left gentle sweep
				LowerTorso    = CFrame.Angles(0, math.rad(-15), 0),
				LeftUpperArm  = CFrame.Angles(math.rad(70), math.rad(20), 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetPriestAuto3()
	return registerSequence("PriestAuto3", {
		createKeyframe(0.00, {
			-- Hands clasped
			LowerTorso    = CFrame.Angles(math.rad(-10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(30), math.rad(-30), math.rad(-10)),
			LeftUpperArm  = CFrame.Angles(math.rad(30), math.rad(30), math.rad(10)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Push forward
				LowerTorso    = CFrame.Angles(math.rad(10), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(80), 0, 0),
				LeftUpperArm  = CFrame.Angles(math.rad(80), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetPriestAuto4()
	return registerSequence("PriestAuto4", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(20), 0),
			RightUpperArm = CFrame.Angles(math.rad(100), math.rad(-20), math.rad(10)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Raise and burst
				LowerTorso    = CFrame.Angles(0, math.rad(-20), 0),
				RightUpperArm = CFrame.Angles(math.rad(60), math.rad(20), math.rad(30)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetPriestAuto5()
	return registerSequence("PriestAuto5", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(math.rad(-15), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(45), math.rad(-45), 0),
			LeftUpperArm  = CFrame.Angles(math.rad(45), math.rad(45), 0),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Dramatic double-hand burst
				LowerTorso    = CFrame.Angles(math.rad(20), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(90), 0, math.rad(20)),
				LeftUpperArm  = CFrame.Angles(math.rad(90), 0, math.rad(-20)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetPriestHeal()
	return registerSequence("PriestHeal", {
		createKeyframe(0.00, {
			-- Arms close to chest
			LowerTorso    = CFrame.Angles(math.rad(-10), 0, 0),
			Head          = CFrame.Angles(math.rad(-20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(30), math.rad(-45), math.rad(-20)),
			LeftUpperArm  = CFrame.Angles(math.rad(30), math.rad(45), math.rad(20)),
		}),
		(function()
			local kf = createKeyframe(0.25, {
				-- Spreading arms open
				LowerTorso    = CFrame.Angles(math.rad(10), 0, 0),
				Head          = CFrame.Angles(math.rad(10), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(45), 0, math.rad(45)),
				LeftUpperArm  = CFrame.Angles(math.rad(45), 0, math.rad(-45)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.50, {})
	})
end

function AnimationBuilder.GetPriestBlessing()
	return registerSequence("PriestBlessing", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, 0, 0),
			Head          = CFrame.Angles(math.rad(-10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(45), 0, math.rad(10)),
		}),
		(function()
			local kf = createKeyframe(0.30, {
				-- Raise hand high to sky
				LowerTorso    = CFrame.Angles(math.rad(-10), 0, 0),
				Head          = CFrame.Angles(math.rad(30), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(160), 0, math.rad(20)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.60, {})
	})
end

function AnimationBuilder.GetPriestHolyNova()
	return registerSequence("PriestHolyNova", {
		createKeyframe(0.00, {
			-- Arms crossed tight
			LowerTorso    = CFrame.Angles(math.rad(15), 0, 0),
			Head          = CFrame.Angles(math.rad(-30), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(45), 0, math.rad(-45)),
			LeftUpperArm  = CFrame.Angles(math.rad(45), 0, math.rad(45)),
		}),
		(function()
			local kf = createKeyframe(0.30, {
				-- Violently thrown open
				LowerTorso    = CFrame.Angles(math.rad(-15), 0, 0),
				Head          = CFrame.Angles(math.rad(45), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(30), math.rad(30), math.rad(90)),
				LeftUpperArm  = CFrame.Angles(math.rad(30), math.rad(-30), math.rad(-90)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.60, {})
	})
end

function AnimationBuilder.GetPriestDivineProtection()
	return registerSequence("PriestDivineProtection", {
		createKeyframe(0.00, {
			-- Gather energy
			LowerTorso    = CFrame.Angles(math.rad(-20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(120), 0, math.rad(10)),
			LeftUpperArm  = CFrame.Angles(math.rad(120), 0, math.rad(-10)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Push downward and outward strongly
				LowerTorso    = CFrame.Angles(math.rad(20), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(20), 0, math.rad(45)),
				LeftUpperArm  = CFrame.Angles(math.rad(20), 0, math.rad(-45)),
				RightUpperLeg = CFrame.Angles(math.rad(-20), 0, math.rad(20)),
				LeftUpperLeg  = CFrame.Angles(math.rad(-20), 0, math.rad(-20)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

-- ==========================================
-- WARRIOR ANIMATIONS
-- ==========================================

function AnimationBuilder.GetWarriorAuto1()
	return registerSequence("WarriorAuto1", {
		createKeyframe(0.00, {
			-- Raise weapon high
			LowerTorso    = CFrame.Angles(0, math.rad(-20), 0),
			RightUpperArm = CFrame.Angles(math.rad(150), math.rad(30), math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(120), math.rad(-30), math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Downward chop
				LowerTorso    = CFrame.Angles(math.rad(20), math.rad(20), 0),
				RightUpperArm = CFrame.Angles(math.rad(20), math.rad(-20), math.rad(10)),
				LeftUpperArm  = CFrame.Angles(math.rad(10), math.rad(20), math.rad(-10)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetWarriorAuto2()
	return registerSequence("WarriorAuto2", {
		createKeyframe(0.00, {
			-- Low crouch, weapon back right
			LowerTorso    = CFrame.Angles(math.rad(10), math.rad(-30), 0),
			RightUpperArm = CFrame.Angles(math.rad(-20), math.rad(40), math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(-10), math.rad(-20), math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Upward diagonal slash
				LowerTorso    = CFrame.Angles(math.rad(-10), math.rad(40), 0),
				RightUpperArm = CFrame.Angles(math.rad(120), math.rad(-20), math.rad(-10)),
				LeftUpperArm  = CFrame.Angles(math.rad(90), math.rad(20), math.rad(10)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetWarriorAuto3()
	return registerSequence("WarriorAuto3", {
		createKeyframe(0.00, {
			-- Twisted right
			LowerTorso    = CFrame.Angles(0, math.rad(-50), 0),
			RightUpperArm = CFrame.Angles(math.rad(40), math.rad(60), math.rad(30)),
			LeftUpperArm  = CFrame.Angles(math.rad(30), math.rad(30), math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Horizontal right-to-left
				LowerTorso    = CFrame.Angles(0, math.rad(50), 0),
				RightUpperArm = CFrame.Angles(math.rad(40), math.rad(-60), math.rad(30)),
				LeftUpperArm  = CFrame.Angles(math.rad(30), math.rad(-30), math.rad(-20)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetWarriorAuto4()
	return registerSequence("WarriorAuto4", {
		createKeyframe(0.00, {
			-- Twisted left
			LowerTorso    = CFrame.Angles(0, math.rad(50), 0),
			RightUpperArm = CFrame.Angles(math.rad(40), math.rad(-60), math.rad(30)),
			LeftUpperArm  = CFrame.Angles(math.rad(30), math.rad(-30), math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Horizontal left-to-right
				LowerTorso    = CFrame.Angles(0, math.rad(-50), 0),
				RightUpperArm = CFrame.Angles(math.rad(40), math.rad(60), math.rad(30)),
				LeftUpperArm  = CFrame.Angles(math.rad(30), math.rad(30), math.rad(-20)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetWarriorAuto5()
	return registerSequence("WarriorAuto5", {
		createKeyframe(0.00, {
			-- Prep jump
			LowerTorso    = CFrame.Angles(math.rad(-20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(160), 0, math.rad(20)),
			LeftUpperArm  = CFrame.Angles(math.rad(160), 0, math.rad(-20)),
			RightUpperLeg = CFrame.Angles(math.rad(-40), 0, 0),
			LeftUpperLeg  = CFrame.Angles(math.rad(-40), 0, 0),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Jumping heavy slam
				LowerTorso    = CFrame.Angles(math.rad(30), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(-10), 0, math.rad(10)),
				LeftUpperArm  = CFrame.Angles(math.rad(-10), 0, math.rad(-10)),
				RightUpperLeg = CFrame.Angles(math.rad(20), 0, 0),
				LeftUpperLeg  = CFrame.Angles(math.rad(20), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetWarriorSlash()
	return registerSequence("WarriorSlash", {
		createKeyframe(0.00, {
			-- Deep crouch, twisted 90 deg right
			LowerTorso    = CFrame.Angles(math.rad(-20), math.rad(-90), 0),
			UpperTorso    = CFrame.Angles(math.rad(-10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(30), math.rad(60), math.rad(30)),
			LeftUpperArm  = CFrame.Angles(math.rad(20), math.rad(30), math.rad(-20)),
			RightUpperLeg = CFrame.Angles(math.rad(-30), 0, 0),
			LeftUpperLeg  = CFrame.Angles(math.rad(10), 0, 0),
		}),
		(function()
			local kf = createKeyframe(0.25, {
				-- Extreme sweeping strike
				LowerTorso    = CFrame.Angles(math.rad(10), math.rad(90), 0),
				RightUpperArm = CFrame.Angles(math.rad(40), math.rad(-60), math.rad(40)),
				LeftUpperArm  = CFrame.Angles(math.rad(30), math.rad(-30), math.rad(-30)),
				RightUpperLeg = CFrame.Angles(math.rad(10), 0, 0),
				LeftUpperLeg  = CFrame.Angles(math.rad(-30), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.50, {})
	})
end

function AnimationBuilder.GetWarriorCharge()
	return registerSequence("WarriorCharge", {
		createKeyframe(0.00, {
			-- Prep charge
			LowerTorso    = CFrame.Angles(math.rad(-10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(-30), math.rad(30), math.rad(10)),
			LeftUpperArm  = CFrame.Angles(math.rad(-20), math.rad(-30), math.rad(-10)),
		}),
		(function()
			local kf = createKeyframe(0.30, {
				-- Deep lean forward, weapon like a ram
				LowerTorso    = CFrame.Angles(math.rad(45), 0, 0),
				UpperTorso    = CFrame.Angles(math.rad(15), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(90), 0, math.rad(10)),
				LeftUpperArm  = CFrame.Angles(math.rad(90), 0, math.rad(-10)),
				RightUpperLeg = CFrame.Angles(math.rad(-30), 0, 0),
				LeftUpperLeg  = CFrame.Angles(math.rad(30), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.60, {})
	})
end

function AnimationBuilder.GetWarriorWhirlwind()
	return registerSequence("WarriorWhirlwind", {
		createKeyframe(0.00, {
			-- Windup left
			LowerTorso    = CFrame.Angles(0, math.rad(90), 0),
			RightUpperArm = CFrame.Angles(math.rad(45), math.rad(45), math.rad(45)),
			LeftUpperArm  = CFrame.Angles(math.rad(45), math.rad(-45), math.rad(-45)),
		}),
		(function()
			local kf = createKeyframe(0.35, {
				-- Spin 360 with arms out
				LowerTorso    = CFrame.Angles(0, math.rad(450), 0),
				RightUpperArm = CFrame.Angles(math.rad(90), math.rad(45), math.rad(60)),
				LeftUpperArm  = CFrame.Angles(math.rad(90), math.rad(-45), math.rad(-60)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

function AnimationBuilder.GetWarriorBerserk()
	return registerSequence("WarriorBerserk", {
		createKeyframe(0.00, {
			-- Crouch
			LowerTorso    = CFrame.Angles(math.rad(-20), 0, 0),
			Head          = CFrame.Angles(math.rad(-30), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(-45), math.rad(20), math.rad(10)),
			LeftUpperArm  = CFrame.Angles(math.rad(-45), math.rad(-20), math.rad(-10)),
			RightUpperLeg = CFrame.Angles(math.rad(-40), 0, 0),
			LeftUpperLeg  = CFrame.Angles(math.rad(-40), 0, 0),
		}),
		(function()
			local kf = createKeyframe(0.50, {
				-- Pump chest, roar to sky
				LowerTorso    = CFrame.Angles(math.rad(10), 0, 0),
				UpperTorso    = CFrame.Angles(math.rad(30), 0, 0),
				Head          = CFrame.Angles(math.rad(45), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(135), 0, math.rad(45)),
				LeftUpperArm  = CFrame.Angles(math.rad(135), 0, math.rad(-45)),
				RightUpperLeg = CFrame.Angles(math.rad(10), 0, 0),
				LeftUpperLeg  = CFrame.Angles(math.rad(10), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(1.00, {})
	})
end

-- ==========================================
-- GOBLIN ANIMATIONS
-- ==========================================
function AnimationBuilder.GetGoblinIdle()
	return registerSequence("GoblinIdle", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(-20), 0, 0),
			Head = CFrame.Angles(math.rad(20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(-10), math.rad(20), math.rad(20)),
			LeftUpperArm = CFrame.Angles(math.rad(-10), math.rad(-20), math.rad(-20)),
			RightUpperLeg = CFrame.Angles(math.rad(-20), 0, math.rad(10)),
			LeftUpperLeg = CFrame.Angles(math.rad(-20), 0, math.rad(-10)),
		}),
		createKeyframe(0.50, {
			LowerTorso = CFrame.Angles(math.rad(-25), 0, 0),
			Head = CFrame.Angles(math.rad(25), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(-15), math.rad(20), math.rad(20)),
			LeftUpperArm = CFrame.Angles(math.rad(-15), math.rad(-20), math.rad(-20)),
			RightUpperLeg = CFrame.Angles(math.rad(-25), 0, math.rad(10)),
			LeftUpperLeg = CFrame.Angles(math.rad(-25), 0, math.rad(-10)),
		}),
		createKeyframe(1.00, {})
	}, true)
end

function AnimationBuilder.GetGoblinWalk()
	return registerSequence("GoblinWalk", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(-20), 0, 0),
			Head = CFrame.Angles(math.rad(20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(-40), 0, math.rad(20)),
			LeftUpperArm = CFrame.Angles(math.rad(40), 0, math.rad(-20)),
			RightUpperLeg = CFrame.Angles(math.rad(30), 0, 0),
			LeftUpperLeg = CFrame.Angles(math.rad(-30), 0, 0),
		}),
		createKeyframe(0.20, {
			LowerTorso = CFrame.Angles(math.rad(-25), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(40), 0, math.rad(20)),
			LeftUpperArm = CFrame.Angles(math.rad(-40), 0, math.rad(-20)),
			RightUpperLeg = CFrame.Angles(math.rad(-30), 0, 0),
			LeftUpperLeg = CFrame.Angles(math.rad(30), 0, 0),
		}),
		createKeyframe(0.40, {})
	}, true)
end

function AnimationBuilder.GetGoblinAttack1()
	return registerSequence("GoblinAttack1", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(-20), math.rad(-45), 0),
			RightUpperArm = CFrame.Angles(math.rad(-30), math.rad(30), math.rad(30)),
		}),
		(function()
			local kf = createKeyframe(0.20, {
				LowerTorso = CFrame.Angles(math.rad(-10), math.rad(45), 0),
				RightUpperArm = CFrame.Angles(math.rad(90), math.rad(-30), math.rad(10)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.50, {})
	})
end

function AnimationBuilder.GetGoblinAttack2()
	return registerSequence("GoblinAttack2", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(-30), math.rad(30), 0),
			RightUpperArm = CFrame.Angles(math.rad(120), 0, math.rad(30)),
		}),
		(function()
			local kf = createKeyframe(0.20, {
				LowerTorso = CFrame.Angles(math.rad(10), math.rad(-30), 0),
				RightUpperArm = CFrame.Angles(math.rad(-20), 0, math.rad(10)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.50, {})
	})
end

-- ==========================================
-- SKELETON ANIMATIONS
-- ==========================================
function AnimationBuilder.GetSkeletonIdle()
	return registerSequence("SkeletonIdle", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(5), 0, 0),
			Head = CFrame.Angles(math.rad(-5), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(10), 0, math.rad(10)),
			LeftUpperArm = CFrame.Angles(math.rad(10), 0, math.rad(-10)),
		}),
		createKeyframe(0.75, {
			LowerTorso = CFrame.Angles(math.rad(-5), 0, 0),
			Head = CFrame.Angles(math.rad(5), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(-10), 0, math.rad(5)),
			LeftUpperArm = CFrame.Angles(math.rad(-10), 0, math.rad(-5)),
		}),
		createKeyframe(1.50, {})
	}, true)
end

function AnimationBuilder.GetSkeletonWalk()
	return registerSequence("SkeletonWalk", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(5), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(-20), 0, math.rad(10)),
			LeftUpperArm = CFrame.Angles(math.rad(20), 0, math.rad(-10)),
			RightUpperLeg = CFrame.Angles(math.rad(20), 0, 0),
			LeftUpperLeg = CFrame.Angles(math.rad(-20), 0, 0),
		}),
		createKeyframe(0.40, {
			LowerTorso = CFrame.Angles(math.rad(-5), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(20), 0, math.rad(10)),
			LeftUpperArm = CFrame.Angles(math.rad(-20), 0, math.rad(-10)),
			RightUpperLeg = CFrame.Angles(math.rad(-20), 0, 0),
			LeftUpperLeg = CFrame.Angles(math.rad(20), 0, 0),
		}),
		createKeyframe(0.80, {})
	}, true)
end

function AnimationBuilder.GetSkeletonAttack1()
	return registerSequence("SkeletonAttack1", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(10), math.rad(-45), 0),
			RightUpperArm = CFrame.Angles(math.rad(45), math.rad(45), math.rad(45)),
		}),
		(function()
			local kf = createKeyframe(0.30, {
				LowerTorso = CFrame.Angles(math.rad(-10), math.rad(45), 0),
				RightUpperArm = CFrame.Angles(math.rad(45), math.rad(-45), math.rad(45)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.60, {})
	})
end

function AnimationBuilder.GetSkeletonAttack2()
	return registerSequence("SkeletonAttack2", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(5), math.rad(-20), 0),
			RightUpperArm = CFrame.Angles(math.rad(90), math.rad(20), math.rad(10)),
		}),
		(function()
			local kf = createKeyframe(0.30, {
				LowerTorso = CFrame.Angles(math.rad(15), math.rad(20), 0),
				RightUpperArm = CFrame.Angles(math.rad(90), math.rad(-20), math.rad(10)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.60, {})
	})
end

-- ==========================================
-- ORC ANIMATIONS
-- ==========================================
function AnimationBuilder.GetOrcIdle()
	return registerSequence("OrcIdle", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(5), 0, 0),
			UpperTorso = CFrame.Angles(math.rad(10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(20), 0, math.rad(20)),
			LeftUpperArm = CFrame.Angles(math.rad(20), 0, math.rad(-20)),
			RightUpperLeg = CFrame.Angles(math.rad(-10), 0, math.rad(10)),
			LeftUpperLeg = CFrame.Angles(math.rad(-10), 0, math.rad(-10)),
		}),
		createKeyframe(0.75, {
			LowerTorso = CFrame.Angles(math.rad(10), 0, 0),
			UpperTorso = CFrame.Angles(math.rad(15), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(30), 0, math.rad(25)),
			LeftUpperArm = CFrame.Angles(math.rad(30), 0, math.rad(-25)),
			RightUpperLeg = CFrame.Angles(math.rad(-15), 0, math.rad(10)),
			LeftUpperLeg = CFrame.Angles(math.rad(-15), 0, math.rad(-10)),
		}),
		createKeyframe(1.50, {})
	}, true)
end

function AnimationBuilder.GetOrcWalk()
	return registerSequence("OrcWalk", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(10), 0, math.rad(5)),
			RightUpperArm = CFrame.Angles(math.rad(-30), 0, math.rad(30)),
			LeftUpperArm = CFrame.Angles(math.rad(30), 0, math.rad(-30)),
			RightUpperLeg = CFrame.Angles(math.rad(20), 0, 0),
			LeftUpperLeg = CFrame.Angles(math.rad(-20), 0, 0),
		}),
		createKeyframe(0.50, {
			LowerTorso = CFrame.Angles(math.rad(10), 0, math.rad(-5)),
			RightUpperArm = CFrame.Angles(math.rad(30), 0, math.rad(30)),
			LeftUpperArm = CFrame.Angles(math.rad(-30), 0, math.rad(-30)),
			RightUpperLeg = CFrame.Angles(math.rad(-20), 0, 0),
			LeftUpperLeg = CFrame.Angles(math.rad(20), 0, 0),
		}),
		createKeyframe(1.00, {})
	}, true)
end

function AnimationBuilder.GetOrcAttack1()
	return registerSequence("OrcAttack1", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(-20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(160), math.rad(30), math.rad(20)),
			LeftUpperArm = CFrame.Angles(math.rad(160), math.rad(-30), math.rad(-20)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Heavy overhead slam
				LowerTorso = CFrame.Angles(math.rad(30), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(10), math.rad(-20), math.rad(10)),
				LeftUpperArm = CFrame.Angles(math.rad(10), math.rad(20), math.rad(-10)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetOrcAttack2()
	return registerSequence("OrcAttack2", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(0, math.rad(-60), 0),
			RightUpperArm = CFrame.Angles(math.rad(45), math.rad(60), math.rad(45)),
		}),
		(function()
			local kf = createKeyframe(0.40, {
				-- Brutal horizontal
				LowerTorso = CFrame.Angles(0, math.rad(60), 0),
				RightUpperArm = CFrame.Angles(math.rad(45), math.rad(-60), math.rad(45)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.80, {})
	})
end

function AnimationBuilder.GetOrcAttack3()
	return registerSequence("OrcAttack3", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(-10), 0, 0),
			Head = CFrame.Angles(math.rad(-30), 0, 0),
		}),
		(function()
			local kf = createKeyframe(0.30, {
				-- Headbutt
				LowerTorso = CFrame.Angles(math.rad(30), 0, 0),
				Head = CFrame.Angles(math.rad(40), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.70, {})
	})
end

-- ==========================================
-- DIREWOLF ANIMATIONS
-- ==========================================
function AnimationBuilder.GetDireWolfIdle()
	return registerSequence("DireWolfIdle", {
		createKeyframe(0.00, {
			-- All fours
			LowerTorso = CFrame.Angles(math.rad(-80), 0, 0),
			Head = CFrame.Angles(math.rad(80), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(80), 0, 0),
			LeftUpperArm = CFrame.Angles(math.rad(80), 0, 0),
			RightUpperLeg = CFrame.Angles(math.rad(40), 0, 0),
			LeftUpperLeg = CFrame.Angles(math.rad(40), 0, 0),
		}),
		createKeyframe(0.50, {
			LowerTorso = CFrame.Angles(math.rad(-85), 0, 0),
			Head = CFrame.Angles(math.rad(85), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(85), 0, 0),
			LeftUpperArm = CFrame.Angles(math.rad(85), 0, 0),
			RightUpperLeg = CFrame.Angles(math.rad(45), 0, 0),
			LeftUpperLeg = CFrame.Angles(math.rad(45), 0, 0),
		}),
		createKeyframe(1.00, {})
	}, true)
end

function AnimationBuilder.GetDireWolfWalk()
	return registerSequence("DireWolfWalk", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(-80), 0, 0),
			Head = CFrame.Angles(math.rad(80), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(60), 0, 0),
			LeftUpperArm = CFrame.Angles(math.rad(100), 0, 0),
			RightUpperLeg = CFrame.Angles(math.rad(60), 0, 0),
			LeftUpperLeg = CFrame.Angles(math.rad(20), 0, 0),
		}),
		createKeyframe(0.30, {
			LowerTorso = CFrame.Angles(math.rad(-80), 0, 0),
			Head = CFrame.Angles(math.rad(80), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(100), 0, 0),
			LeftUpperArm = CFrame.Angles(math.rad(60), 0, 0),
			RightUpperLeg = CFrame.Angles(math.rad(20), 0, 0),
			LeftUpperLeg = CFrame.Angles(math.rad(60), 0, 0),
		}),
		createKeyframe(0.60, {})
	}, true)
end

function AnimationBuilder.GetDireWolfAttack1()
	return registerSequence("DireWolfAttack1", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(-70), 0, 0),
			Head = CFrame.Angles(math.rad(70), 0, 0),
		}),
		(function()
			local kf = createKeyframe(0.20, {
				-- Bite lunge
				LowerTorso = CFrame.Angles(math.rad(-100), 0, 0),
				Head = CFrame.Angles(math.rad(60), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.40, {})
	})
end

function AnimationBuilder.GetDireWolfAttack2()
	return registerSequence("DireWolfAttack2", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(-80), math.rad(30), 0),
			RightUpperArm = CFrame.Angles(math.rad(120), math.rad(-30), math.rad(30)),
		}),
		(function()
			local kf = createKeyframe(0.20, {
				-- Claw slash
				LowerTorso = CFrame.Angles(math.rad(-80), math.rad(-30), 0),
				RightUpperArm = CFrame.Angles(math.rad(40), math.rad(30), math.rad(-30)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.40, {})
	})
end

-- ==========================================
-- SPIDER ANIMATIONS
-- ==========================================
function AnimationBuilder.GetSpiderIdle()
	return registerSequence("SpiderIdle", {
		createKeyframe(0.00, {
			-- Low, wide
			LowerTorso = CFrame.Angles(math.rad(30), 0, 0),
			RightUpperArm = CFrame.Angles(0, 0, math.rad(60)),
			LeftUpperArm = CFrame.Angles(0, 0, math.rad(-60)),
			RightUpperLeg = CFrame.Angles(0, 0, math.rad(60)),
			LeftUpperLeg = CFrame.Angles(0, 0, math.rad(-60)),
		}),
		createKeyframe(0.50, {
			LowerTorso = CFrame.Angles(math.rad(35), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(10), 0, math.rad(65)),
			LeftUpperArm = CFrame.Angles(math.rad(10), 0, math.rad(-65)),
			RightUpperLeg = CFrame.Angles(math.rad(-10), 0, math.rad(65)),
			LeftUpperLeg = CFrame.Angles(math.rad(-10), 0, math.rad(-65)),
		}),
		createKeyframe(1.00, {})
	}, true)
end

function AnimationBuilder.GetSpiderWalk()
	return registerSequence("SpiderWalk", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(30), math.rad(10), 0),
			RightUpperArm = CFrame.Angles(math.rad(30), 0, math.rad(60)),
			LeftUpperArm = CFrame.Angles(math.rad(-30), 0, math.rad(-60)),
			RightUpperLeg = CFrame.Angles(math.rad(-30), 0, math.rad(60)),
			LeftUpperLeg = CFrame.Angles(math.rad(30), 0, math.rad(-60)),
		}),
		createKeyframe(0.25, {
			LowerTorso = CFrame.Angles(math.rad(30), math.rad(-10), 0),
			RightUpperArm = CFrame.Angles(math.rad(-30), 0, math.rad(60)),
			LeftUpperArm = CFrame.Angles(math.rad(30), 0, math.rad(-60)),
			RightUpperLeg = CFrame.Angles(math.rad(30), 0, math.rad(60)),
			LeftUpperLeg = CFrame.Angles(math.rad(-30), 0, math.rad(-60)),
		}),
		createKeyframe(0.50, {})
	}, true)
end

function AnimationBuilder.GetSpiderAttack1()
	return registerSequence("SpiderAttack1", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(10), 0, 0),
			Head = CFrame.Angles(math.rad(-20), 0, 0),
		}),
		(function()
			local kf = createKeyframe(0.20, {
				-- Bite
				LowerTorso = CFrame.Angles(math.rad(60), 0, 0),
				Head = CFrame.Angles(math.rad(30), 0, 0),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.40, {})
	})
end

function AnimationBuilder.GetSpiderAttack2()
	return registerSequence("SpiderAttack2", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(-20), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(90), 0, math.rad(45)),
			LeftUpperArm = CFrame.Angles(math.rad(90), 0, math.rad(-45)),
		}),
		(function()
			local kf = createKeyframe(0.20, {
				-- Two arm strike / web shoot
				LowerTorso = CFrame.Angles(math.rad(40), 0, 0),
				RightUpperArm = CFrame.Angles(math.rad(20), 0, math.rad(20)),
				LeftUpperArm = CFrame.Angles(math.rad(20), 0, math.rad(-20)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.40, {})
	})
end

-- ==========================================
-- SLIME ANIMATIONS
-- ==========================================
function AnimationBuilder.GetSlimeIdle()
	return registerSequence("SlimeIdle", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(0, 0, 0),
			UpperTorso = CFrame.Angles(0, 0, 0),
		}),
		createKeyframe(0.50, {
			-- Squish down
			LowerTorso = CFrame.Angles(math.rad(10), 0, 0),
			UpperTorso = CFrame.Angles(math.rad(20), 0, 0),
		}),
		createKeyframe(1.00, {})
	}, true)
end

function AnimationBuilder.GetSlimeWalk()
	return registerSequence("SlimeWalk", {
		createKeyframe(0.00, {
			LowerTorso = CFrame.Angles(math.rad(20), 0, 0),
		}),
		createKeyframe(0.40, {
			-- Bounce up and forward
			LowerTorso = CFrame.Angles(math.rad(-10), 0, 0) * CFrame.new(0, 2, -2),
		}),
		createKeyframe(0.80, {})
	}, true)
end

function AnimationBuilder.GetSlimeAttack1()
	return registerSequence("SlimeAttack1", {
		createKeyframe(0.00, {
			-- Stretch back
			LowerTorso = CFrame.Angles(math.rad(-30), 0, 0),
		}),
		(function()
			local kf = createKeyframe(0.30, {
				-- Splat forward
				LowerTorso = CFrame.Angles(math.rad(40), 0, 0) * CFrame.new(0, 0, -3),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.60, {})
	})
end

function AnimationBuilder.GetSlimeAttack2()
	return registerSequence("SlimeAttack2", {
		createKeyframe(0.00, {
			-- Lean right
			LowerTorso = CFrame.Angles(0, 0, math.rad(-30)),
		}),
		(function()
			local kf = createKeyframe(0.30, {
				-- Slam left
				LowerTorso = CFrame.Angles(0, 0, math.rad(30)),
			})
			addMarker(kf, "Hit")
			return kf
		end)(),
		createKeyframe(0.60, {})
	})
end

-- ==========================================
-- TOOL HOLD IDLE ANIMATIONS
-- ==========================================
function AnimationBuilder.GetWarriorToolHold()
	return registerSequence("WarriorToolHold", {
		createKeyframe(0.00, {
			RightUpperArm = CFrame.Angles(math.rad(-15), math.rad(-25), math.rad(15)),
			RightLowerArm = CFrame.Angles(math.rad(-25), 0, math.rad(-10)),
			RightHand     = CFrame.Angles(math.rad(-15), math.rad(10), math.rad(-20)),
			LeftUpperArm  = CFrame.Angles(math.rad(8), math.rad(18), math.rad(-8)),
		}),
		createKeyframe(1.00, {
			RightUpperArm = CFrame.Angles(math.rad(-12), math.rad(-22), math.rad(12)),
			RightLowerArm = CFrame.Angles(math.rad(-22), 0, math.rad(-8)),
			RightHand     = CFrame.Angles(math.rad(-12), math.rad(8), math.rad(-18)),
			LeftUpperArm  = CFrame.Angles(math.rad(10), math.rad(15), math.rad(-6)),
		}),
		createKeyframe(2.00, {
			RightUpperArm = CFrame.Angles(math.rad(-15), math.rad(-25), math.rad(15)),
			RightLowerArm = CFrame.Angles(math.rad(-25), 0, math.rad(-10)),
			RightHand     = CFrame.Angles(math.rad(-15), math.rad(10), math.rad(-20)),
			LeftUpperArm  = CFrame.Angles(math.rad(8), math.rad(18), math.rad(-8)),
		}),
	}, true)
end

function AnimationBuilder.GetMageToolHold()
	return registerSequence("MageToolHold", {
		createKeyframe(0.00, {
			RightUpperArm = CFrame.Angles(math.rad(25), math.rad(-15), math.rad(12)),
			RightLowerArm = CFrame.Angles(math.rad(-35), 0, math.rad(-8)),
			RightHand     = CFrame.Angles(math.rad(-10), 0, math.rad(-12)),
			LeftUpperArm  = CFrame.Angles(math.rad(35), math.rad(20), math.rad(-15)),
			LeftLowerArm  = CFrame.Angles(math.rad(-25), 0, math.rad(10)),
			LeftHand      = CFrame.Angles(math.rad(8), 0, math.rad(12)),
		}),
		createKeyframe(1.00, {
			RightUpperArm = CFrame.Angles(math.rad(28), math.rad(-12), math.rad(10)),
			RightLowerArm = CFrame.Angles(math.rad(-32), 0, math.rad(-6)),
			RightHand     = CFrame.Angles(math.rad(-8), 0, math.rad(-10)),
			LeftUpperArm  = CFrame.Angles(math.rad(38), math.rad(18), math.rad(-12)),
			LeftLowerArm  = CFrame.Angles(math.rad(-22), 0, math.rad(8)),
			LeftHand      = CFrame.Angles(math.rad(10), 0, math.rad(10)),
		}),
		createKeyframe(2.00, {
			RightUpperArm = CFrame.Angles(math.rad(25), math.rad(-15), math.rad(12)),
			RightLowerArm = CFrame.Angles(math.rad(-35), 0, math.rad(-8)),
			RightHand     = CFrame.Angles(math.rad(-10), 0, math.rad(-12)),
			LeftUpperArm  = CFrame.Angles(math.rad(35), math.rad(20), math.rad(-15)),
			LeftLowerArm  = CFrame.Angles(math.rad(-25), 0, math.rad(10)),
			LeftHand      = CFrame.Angles(math.rad(8), 0, math.rad(12)),
		}),
	}, true)
end

function AnimationBuilder.GetArcherToolHold()
	return registerSequence("ArcherToolHold", {
		createKeyframe(0.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(-15), 0),
			LeftUpperArm  = CFrame.Angles(math.rad(75), math.rad(35), math.rad(-40)),
			LeftLowerArm  = CFrame.Angles(math.rad(-15), 0, math.rad(-5)),
			LeftHand      = CFrame.Angles(math.rad(5), math.rad(-10), math.rad(-8)),
			RightUpperArm = CFrame.Angles(math.rad(20), math.rad(-10), math.rad(15)),
			RightLowerArm = CFrame.Angles(math.rad(-30), 0, math.rad(5)),
			RightHand     = CFrame.Angles(math.rad(-5), 0, math.rad(10)),
		}),
		createKeyframe(1.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(-12), 0),
			LeftUpperArm  = CFrame.Angles(math.rad(78), math.rad(38), math.rad(-42)),
			LeftLowerArm  = CFrame.Angles(math.rad(-12), 0, math.rad(-4)),
			LeftHand      = CFrame.Angles(math.rad(6), math.rad(-8), math.rad(-6)),
			RightUpperArm = CFrame.Angles(math.rad(18), math.rad(-8), math.rad(12)),
			RightLowerArm = CFrame.Angles(math.rad(-28), 0, math.rad(4)),
			RightHand     = CFrame.Angles(math.rad(-4), 0, math.rad(8)),
		}),
		createKeyframe(2.00, {
			LowerTorso    = CFrame.Angles(0, math.rad(-15), 0),
			LeftUpperArm  = CFrame.Angles(math.rad(75), math.rad(35), math.rad(-40)),
			LeftLowerArm  = CFrame.Angles(math.rad(-15), 0, math.rad(-5)),
			LeftHand      = CFrame.Angles(math.rad(5), math.rad(-10), math.rad(-8)),
			RightUpperArm = CFrame.Angles(math.rad(20), math.rad(-10), math.rad(15)),
			RightLowerArm = CFrame.Angles(math.rad(-30), 0, math.rad(5)),
			RightHand     = CFrame.Angles(math.rad(-5), 0, math.rad(10)),
		}),
	}, true)
end

function AnimationBuilder.GetPriestToolHold()
	return registerSequence("PriestToolHold", {
		createKeyframe(0.00, {
			RightUpperArm = CFrame.Angles(math.rad(-10), math.rad(-15), math.rad(18)),
			RightLowerArm = CFrame.Angles(math.rad(-30), 0, math.rad(-12)),
			RightHand     = CFrame.Angles(math.rad(-18), math.rad(8), math.rad(-22)),
			LeftUpperArm  = CFrame.Angles(math.rad(15), math.rad(20), math.rad(-10)),
		}),
		createKeyframe(1.00, {
			RightUpperArm = CFrame.Angles(math.rad(-8), math.rad(-12), math.rad(15)),
			RightLowerArm = CFrame.Angles(math.rad(-28), 0, math.rad(-10)),
			RightHand     = CFrame.Angles(math.rad(-15), math.rad(6), math.rad(-20)),
			LeftUpperArm  = CFrame.Angles(math.rad(18), math.rad(18), math.rad(-8)),
		}),
		createKeyframe(2.00, {
			RightUpperArm = CFrame.Angles(math.rad(-10), math.rad(-15), math.rad(18)),
			RightLowerArm = CFrame.Angles(math.rad(-30), 0, math.rad(-12)),
			RightHand     = CFrame.Angles(math.rad(-18), math.rad(8), math.rad(-22)),
			LeftUpperArm  = CFrame.Angles(math.rad(15), math.rad(20), math.rad(-10)),
		}),
	}, true)
end

function AnimationBuilder.GetKavalierToolHold()
	return registerSequence("KavalierToolHold", {
		createKeyframe(0.00, {
			RightUpperArm = CFrame.Angles(math.rad(15), math.rad(-20), math.rad(12)),
			RightLowerArm = CFrame.Angles(math.rad(-20), 0, math.rad(-8)),
			RightHand     = CFrame.Angles(math.rad(-10), 0, math.rad(-15)),
			LeftUpperArm  = CFrame.Angles(math.rad(25), math.rad(25), math.rad(-18)),
			LeftLowerArm  = CFrame.Angles(math.rad(-15), 0, math.rad(8)),
			LeftHand      = CFrame.Angles(math.rad(5), 0, math.rad(10)),
		}),
		createKeyframe(1.00, {
			RightUpperArm = CFrame.Angles(math.rad(18), math.rad(-18), math.rad(10)),
			RightLowerArm = CFrame.Angles(math.rad(-18), 0, math.rad(-6)),
			RightHand     = CFrame.Angles(math.rad(-8), 0, math.rad(-12)),
			LeftUpperArm  = CFrame.Angles(math.rad(28), math.rad(22), math.rad(-15)),
			LeftLowerArm  = CFrame.Angles(math.rad(-12), 0, math.rad(6)),
			LeftHand      = CFrame.Angles(math.rad(6), 0, math.rad(8)),
		}),
		createKeyframe(2.00, {
			RightUpperArm = CFrame.Angles(math.rad(15), math.rad(-20), math.rad(12)),
			RightLowerArm = CFrame.Angles(math.rad(-20), 0, math.rad(-8)),
			RightHand     = CFrame.Angles(math.rad(-10), 0, math.rad(-15)),
			LeftUpperArm  = CFrame.Angles(math.rad(25), math.rad(25), math.rad(-18)),
			LeftLowerArm  = CFrame.Angles(math.rad(-15), 0, math.rad(8)),
			LeftHand      = CFrame.Angles(math.rad(5), 0, math.rad(10)),
		}),
	}, true)
end

-- ==========================================
-- REST ANIMATIONS
-- ==========================================
local REST_SIT_POSE = {
	LowerTorso    = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-10), 0, 0),
	RightUpperLeg = CFrame.Angles(math.rad(45), math.rad(45), math.rad(45)),
	RightLowerLeg = CFrame.Angles(math.rad(-90), 0, 0),
	LeftUpperLeg  = CFrame.Angles(math.rad(45), math.rad(-45), math.rad(-45)),
	LeftLowerLeg  = CFrame.Angles(math.rad(-90), 0, 0),
	RightUpperArm = CFrame.Angles(math.rad(10), 0, math.rad(20)),
	LeftUpperArm  = CFrame.Angles(math.rad(10), 0, math.rad(-20)),
}

local REST_KNEEL_POSE = {
	LowerTorso    = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(-15), math.rad(15), 0),
	RightUpperLeg = CFrame.Angles(math.rad(80), 0, math.rad(10)),
	RightLowerLeg = CFrame.Angles(math.rad(-100), 0, 0),
	LeftUpperLeg  = CFrame.Angles(math.rad(20), math.rad(-45), math.rad(-20)),
	LeftLowerLeg  = CFrame.Angles(math.rad(-60), 0, 0),
	RightUpperArm = CFrame.Angles(math.rad(45), 0, math.rad(10)),
	LeftUpperArm  = CFrame.Angles(math.rad(-10), 0, math.rad(-20)),
}

function AnimationBuilder.GetRestLayDown1()
	return registerSequence("RestLayDown1", {
		createKeyframe(0.00, {}),
		createKeyframe(0.50, REST_SIT_POSE),
	})
end

function AnimationBuilder.GetRestLayDown2()
	return registerSequence("RestLayDown2", {
		createKeyframe(0.00, {}),
		createKeyframe(0.50, REST_KNEEL_POSE),
	})
end

function AnimationBuilder.GetRestLoop1()
	return registerSequence("RestLoop1", {
		createKeyframe(0.00, REST_SIT_POSE),
		createKeyframe(1.00, {
			LowerTorso    = CFrame.new(0, -1.45, 0) * CFrame.Angles(math.rad(-5), 0, 0),
			RightUpperLeg = REST_SIT_POSE.RightUpperLeg,
			RightLowerLeg = REST_SIT_POSE.RightLowerLeg,
			LeftUpperLeg  = REST_SIT_POSE.LeftUpperLeg,
			LeftLowerLeg  = REST_SIT_POSE.LeftLowerLeg,
			RightUpperArm = CFrame.Angles(math.rad(15), 0, math.rad(25)),
			LeftUpperArm  = CFrame.Angles(math.rad(15), 0, math.rad(-25)),
			Head          = CFrame.Angles(math.rad(5), 0, 0),
		}),
		createKeyframe(2.00, REST_SIT_POSE),
	}, true)
end

function AnimationBuilder.GetRestLoop2()
	return registerSequence("RestLoop2", {
		createKeyframe(0.00, REST_KNEEL_POSE),
		createKeyframe(1.00, {
			LowerTorso    = CFrame.new(0, -1.45, 0) * CFrame.Angles(math.rad(-10), math.rad(15), 0),
			RightUpperLeg = REST_KNEEL_POSE.RightUpperLeg,
			RightLowerLeg = REST_KNEEL_POSE.RightLowerLeg,
			LeftUpperLeg  = REST_KNEEL_POSE.LeftUpperLeg,
			LeftLowerLeg  = REST_KNEEL_POSE.LeftLowerLeg,
			RightUpperArm = CFrame.Angles(math.rad(50), 0, math.rad(10)),
			LeftUpperArm  = CFrame.Angles(math.rad(-5), 0, math.rad(-25)),
			Head          = CFrame.Angles(math.rad(5), 0, 0),
		}),
		createKeyframe(2.00, REST_KNEEL_POSE),
	}, true)
end

function AnimationBuilder.GetRestStandUp1()
	return registerSequence("RestStandUp1", {
		createKeyframe(0.00, REST_SIT_POSE),
		createKeyframe(0.50, {}),
	})
end

function AnimationBuilder.GetRestStandUp2()
	return registerSequence("RestStandUp2", {
		createKeyframe(0.00, REST_KNEEL_POSE),
		createKeyframe(0.50, {}),
	})
end

-- ==========================================
-- POTION DRINK ANIMATIONS
-- ==========================================
function AnimationBuilder.GetDrinkHealthPotion()
	return registerSequence("DrinkHealthPotion", {
		createKeyframe(0.00, {
			RightUpperArm = CFrame.Angles(math.rad(20), 0, math.rad(15)),
			RightLowerArm = CFrame.Angles(math.rad(-20), 0, 0),
		}),
		createKeyframe(0.25, {
			Head          = CFrame.Angles(math.rad(15), math.rad(-10), 0),
			RightUpperArm = CFrame.Angles(math.rad(110), math.rad(-20), math.rad(20)),
			RightLowerArm = CFrame.Angles(math.rad(-40), 0, 0),
			RightHand     = CFrame.Angles(math.rad(-20), 0, 0),
		}),
		createKeyframe(0.50, {
			Head          = CFrame.Angles(math.rad(20), math.rad(-10), 0),
			RightUpperArm = CFrame.Angles(math.rad(115), math.rad(-15), math.rad(20)),
			RightLowerArm = CFrame.Angles(math.rad(-35), 0, 0),
		}),
		createKeyframe(0.80, {}),
	})
end

function AnimationBuilder.GetDrinkManaPotion()
	return registerSequence("DrinkManaPotion", {
		createKeyframe(0.00, {
			RightUpperArm = CFrame.Angles(math.rad(30), math.rad(-20), math.rad(10)),
			LeftUpperArm  = CFrame.Angles(math.rad(30), math.rad(20), math.rad(-10)),
		}),
		createKeyframe(0.25, {
			Head          = CFrame.Angles(math.rad(10), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(70), math.rad(-30), math.rad(15)),
			RightLowerArm = CFrame.Angles(math.rad(-60), 0, 0),
			LeftUpperArm  = CFrame.Angles(math.rad(70), math.rad(30), math.rad(-15)),
			LeftLowerArm  = CFrame.Angles(math.rad(-60), 0, 0),
		}),
		createKeyframe(0.50, {
			Head          = CFrame.Angles(math.rad(25), 0, 0),
			UpperTorso    = CFrame.Angles(math.rad(-5), 0, 0),
			RightUpperArm = CFrame.Angles(math.rad(90), math.rad(-20), math.rad(15)),
			RightLowerArm = CFrame.Angles(math.rad(-50), 0, 0),
			LeftUpperArm  = CFrame.Angles(math.rad(90), math.rad(20), math.rad(-15)),
			LeftLowerArm  = CFrame.Angles(math.rad(-50), 0, 0),
		}),
		createKeyframe(0.80, {}),
	})
end

local function playPotionAnim(humanoid, animIdGetter)
	if not humanoid then
		return nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	local AnimationController = require(script.Parent.AnimationController)
	local anim = AnimationController.GetAnimation(animIdGetter())
	local track = animator:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false
	track:Play(0.1)
	return track
end

function AnimationBuilder.DrinkHealthPotion(humanoid)
	return playPotionAnim(humanoid, AnimationBuilder.GetDrinkHealthPotion)
end

function AnimationBuilder.DrinkManaPotion(humanoid)
	return playPotionAnim(humanoid, AnimationBuilder.GetDrinkManaPotion)
end

return AnimationBuilder
