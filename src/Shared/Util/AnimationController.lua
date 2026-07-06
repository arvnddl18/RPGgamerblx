-- AnimationController
-- Shared animation system for players and monsters.
-- Handles combo cycling, speed-sync to cooldowns/castTimes, hit-marker signals,
-- and walk/idle management for non-player characters.
--
-- Usage (client-side):
--   local AnimationController = require(ReplicatedStorage.Shared.Util.AnimationController)
--   local ctrl = AnimationController.new(humanoid)
--   local track, hitSignal = ctrl:PlayAutoAttack(skillConfig)
--   local track, hitSignal = ctrl:PlaySkillCast(skillConfig)
--   local track = ctrl:PlayMonsterAttack(enemyConfig)
--   ctrl:PlayWalk(walkAnimId) / ctrl:PlayIdle(idleAnimId)
--   ctrl:Destroy()

local AnimationController = {}
AnimationController.__index = AnimationController

-- Static cache of Animation objects (keyed by animation ID)
local _animCache = {}

---------------------------------------------------------------------------
-- Static API
---------------------------------------------------------------------------

--- Get or create a cached Animation instance for the given ID.
--- Caching avoids re-creating Animation objects for frequently used IDs.
function AnimationController.GetAnimation(animId)
	if not _animCache[animId] then
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		_animCache[animId] = anim
	end
	return _animCache[animId]
end

--- Preload a list of animation IDs into the static cache.
--- Call this at startup with the player's class skill animations
--- and/or all monster animation IDs to avoid first-play hitches.
--- animIds: array of animation ID strings (e.g. {"rbxassetid://90000001", ...})
function AnimationController.PreloadAnimations(animIds)
	for _, animId in animIds do
		AnimationController.GetAnimation(animId)
	end
end

--- Calculate the playback speed multiplier so an animation of `trackLength`
--- seconds fits exactly into `targetDuration` seconds.
--- Formula: speed = trackLength / targetDuration
--- Example: a 1.5s clip played at speed 3.0 completes in 0.5s.
function AnimationController.CalcSpeed(trackLength, targetDuration)
	if targetDuration <= 0 or trackLength <= 0 then
		return 1
	end
	return trackLength / targetDuration
end

---------------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------------

--- Create a new AnimationController bound to a specific Humanoid.
--- The Humanoid must have an Animator child (created automatically by the engine
--- when the Humanoid enters the Workspace).
function AnimationController.new(humanoid)
	local self = setmetatable({}, AnimationController)
	self.humanoid = humanoid
	self.animator = humanoid:FindFirstChildOfClass("Animator")
	self._comboIndex = 0
	self._lastComboAnimId = ""
	self._activeActionTrack = nil
	self._activeWalkTrack = nil
	self._activeIdleTrack = nil
	self._destroyed = false
	return self
end

---------------------------------------------------------------------------
-- Internal helpers
---------------------------------------------------------------------------

function AnimationController:_loadAndPlay(animId, priority, targetDuration, looped)
	if self._destroyed then
		return nil
	end

	-- Re-acquire animator if we lost the reference
	if not self.animator then
		self.animator = self.humanoid
			and self.humanoid:FindFirstChildOfClass("Animator")
	end
	if not self.animator then
		return nil
	end

	local anim = AnimationController.GetAnimation(animId)
	local track = self.animator:LoadAnimation(anim)

	track.Priority = priority
	track.Looped = looped or false
	track:Play()

	-- Adjust speed so the clip fits exactly into targetDuration
	if targetDuration and targetDuration > 0 and track.Length > 0 then
		track:AdjustSpeed(AnimationController.CalcSpeed(track.Length, targetDuration))
	end

	return track
end

---------------------------------------------------------------------------
-- Action animations (skill casts, auto-attacks, monster attacks)
---------------------------------------------------------------------------

--- Stop the currently playing action-priority animation.
function AnimationController:StopAction(fadeTime)
	if self._activeActionTrack and self._activeActionTrack.IsPlaying then
		self._activeActionTrack:Stop(fadeTime or 0.1)
	end
	self._activeActionTrack = nil
end

--- Play a skill cast animation with speed synced to skill.castTime.
--- Returns: track, hitMarkerSignal (or nil if no marker configured)
function AnimationController:PlaySkillCast(skillConfig)
	if not skillConfig or not skillConfig.castAnimId then
		return nil, nil
	end

	self:StopAction()

	local track = self:_loadAndPlay(
		skillConfig.castAnimId,
		Enum.AnimationPriority.Action,
		skillConfig.castTime
	)
	self._activeActionTrack = track

	local hitSignal = nil
	if track and skillConfig.hitAnimMarker then
		hitSignal = track:GetMarkerReachedSignal(skillConfig.hitAnimMarker)
	end

	return track, hitSignal
end

--- Play the next auto-attack animation in the combo sequence.
--- Sequential cycling advances 1→2→3→4→5→1… avoiding immediate repeats.
--- Random mode also avoids playing the same anim twice in a row.
--- Returns: track, hitMarkerSignal
function AnimationController:PlayAutoAttack(skillConfig)
	if not skillConfig then
		return nil, nil
	end

	local comboAnims = skillConfig.comboAnims
	if not comboAnims or #comboAnims == 0 then
		-- Fallback to castAnimId if no combo array defined
		return self:PlaySkillCast(skillConfig)
	end

	self:StopAction()

	-- Determine which combo animation to play
	local animId
	if skillConfig.comboAdvance == "sequential" then
		self._comboIndex = (self._comboIndex % #comboAnims) + 1
		animId = comboAnims[self._comboIndex]
	else
		-- Random selection, avoid immediate repeat
		local attempts = 0
		repeat
			animId = comboAnims[math.random(1, #comboAnims)]
			attempts += 1
		until animId ~= self._lastComboAnimId or #comboAnims == 1 or attempts > 10
	end

	self._lastComboAnimId = animId

	local track = self:_loadAndPlay(
		animId,
		Enum.AnimationPriority.Action,
		skillConfig.castTime
	)
	self._activeActionTrack = track

	local hitSignal = nil
	if track and skillConfig.hitAnimMarker then
		hitSignal = track:GetMarkerReachedSignal(skillConfig.hitAnimMarker)
	end

	return track, hitSignal
end

--- Reset the combo counter (call when the player stops attacking).
function AnimationController:ResetCombo()
	self._comboIndex = 0
	self._lastComboAnimId = ""
end

--- Get the current 1-based combo index (0 if no combo has been started).
function AnimationController:GetComboIndex()
	return self._comboIndex
end

--- Play an action-priority animation by its specific ID.
--- Used when the server has already chosen which animation to play
--- (e.g. monster attack variants selected server-side for sync).
--- Returns: track
function AnimationController:PlayActionById(animId, targetDuration)
	if not animId then
		return nil
	end

	self:StopAction()

	local track = self:_loadAndPlay(animId, Enum.AnimationPriority.Action, targetDuration)
	self._activeActionTrack = track

	return track
end

--- Play a monster attack animation (random variant from enemyConfig.attackAnims).
--- Returns: track
function AnimationController:PlayMonsterAttack(enemyConfig)
	if not enemyConfig
		or not enemyConfig.attackAnims
		or #enemyConfig.attackAnims == 0
	then
		return nil
	end

	self:StopAction()

	local animId = enemyConfig.attackAnims[math.random(1, #enemyConfig.attackAnims)]
	local track = self:_loadAndPlay(animId, Enum.AnimationPriority.Action, nil)
	self._activeActionTrack = track

	return track
end

---------------------------------------------------------------------------
-- Movement animations (walk / idle — primarily for monsters)
---------------------------------------------------------------------------

--- Play a looping walk animation. Stops idle if playing.
--- Returns: track
function AnimationController:PlayWalk(walkAnimId)
	if not walkAnimId then
		return nil
	end

	-- Stop idle when walking
	if self._activeIdleTrack and self._activeIdleTrack.IsPlaying then
		self._activeIdleTrack:Stop(0.2)
	end
	self._activeIdleTrack = nil

	-- Don't restart if the same walk is already playing
	if self._activeWalkTrack and self._activeWalkTrack.IsPlaying then
		return self._activeWalkTrack
	end

	local track = self:_loadAndPlay(
		walkAnimId,
		Enum.AnimationPriority.Movement,
		nil,
		true -- looped
	)
	self._activeWalkTrack = track
	return track
end

--- Play a looping idle animation. Stops walk if playing.
--- Returns: track
function AnimationController:PlayIdle(idleAnimId)
	if not idleAnimId then
		return nil
	end

	-- Stop walk when idling
	if self._activeWalkTrack and self._activeWalkTrack.IsPlaying then
		self._activeWalkTrack:Stop(0.2)
	end
	self._activeWalkTrack = nil

	-- Don't restart if the same idle is already playing
	if self._activeIdleTrack and self._activeIdleTrack.IsPlaying then
		return self._activeIdleTrack
	end

	local track = self:_loadAndPlay(
		idleAnimId,
		Enum.AnimationPriority.Idle,
		nil,
		true -- looped
	)
	self._activeIdleTrack = track
	return track
end

--- Stop walk and idle tracks.
function AnimationController:StopMovement(fadeTime)
	fadeTime = fadeTime or 0.2

	if self._activeWalkTrack and self._activeWalkTrack.IsPlaying then
		self._activeWalkTrack:Stop(fadeTime)
	end
	self._activeWalkTrack = nil

	if self._activeIdleTrack and self._activeIdleTrack.IsPlaying then
		self._activeIdleTrack:Stop(fadeTime)
	end
	self._activeIdleTrack = nil
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------

--- Stop all managed animations (action + movement).
function AnimationController:StopAll(fadeTime)
	fadeTime = fadeTime or 0.1
	self:StopAction(fadeTime)
	self:StopMovement(fadeTime)
end

--- Clean up references. Call when the humanoid is being removed.
function AnimationController:Destroy()
	self:StopAll(0)
	self._destroyed = true
	self.humanoid = nil
	self.animator = nil
end

return AnimationController