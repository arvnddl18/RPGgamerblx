--[[
	CooldownOverlay — MOBA-style clock-wipe cooldown visual using pure Frames.

	TECHNIQUE: Two-wedge rotation inside a circular ClipsDescendants container.

	Two half-width × full-height dark Frames ("wedges") are anchored at the
	center of a circular-clipped slot frame.  Together at rest they cover the
	full circle (100% dark).  The cooldown animation works in two phases:

	  Phase 1 (progress 0 → 0.5):
	    Wedge A rotates clockwise 0° → 180° while Wedge B stays fixed.
	    The leading edge of Wedge A creates a clockwise sweep that clears
	    the right half of the overlay.  Dark area: 100% → 50%.

	  Phase 2 (progress 0.5 → 1.0):
	    Wedge A is hidden.  Wedge B rotates clockwise 0° → 180° AND
	    shrinks from 50% width to 0% width.  The rotation provides the
	    directional sweep while the shrinkage reduces coverage from 50%
	    to 0%.  Dark area: 50% → 0%.

	Combined, the two phases produce a smooth clockwise reveal of the
	icon underneath, starting from 12 o'clock — identical to a classic
	MOBA ability cooldown wipe.

	WHY THIS OVER EditableImage:
	  EditableImage is unavailable in older Roblox Studio versions.
	  This pure-Frame approach works on all versions, uses only GPU-
	  accelerated properties (Rotation, Size, BackgroundTransparency),
	  and performs well with many simultaneous cooldowns.

	USAGE:
	  local overlay = CooldownOverlay.Create(slotFrame)
	  CooldownOverlay.StartCooldown(overlay, startTime, duration, onFinished)
	  -- later, if needed:
	  CooldownOverlay.StopCooldown(overlay)
]]

local RunService = game:GetService("RunService")

local CooldownOverlay = {}

---------------------------------------------------------------------------
-- Configuration
---------------------------------------------------------------------------

local WEDGE_COLOR = Color3.fromRGB(0, 0, 0)  -- dark overlay colour
local WEDGE_TRANSPARENCY = 0.35               -- 0.35 = 65% opaque (within 60–70%)

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--[[
	Creates the clock-wipe overlay GUI elements inside `slotFrame`.
	Returns an opaque handle table used by Start/StopCooldown.

	Hierarchy created:
	  slotFrame
	    ├─ ClockWipeContainer (Frame, ClipsDescendants, UICorner)
	    │    ├─ WedgeA (Frame — right-half semicircle, rotates in Phase 1)
	    │    └─ WedgeB (Frame — left-half semicircle, rotates + shrinks in Phase 2)
	    └─ CooldownText (TextLabel, centred countdown number)
]]
function CooldownOverlay.Create(slotFrame)
	-- Clipping container with circular shape
	local container = Instance.new("Frame")
	container.Name = "ClockWipeContainer"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.Position = UDim2.new(0, 0, 0, 0)
	container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	container.BackgroundTransparency = 1 -- container itself is invisible
	container.BorderSizePixel = 0
	container.ClipsDescendants = true
	container.ZIndex = slotFrame.ZIndex + 5
	container.Visible = false
	container.Parent = slotFrame

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 6)
	containerCorner.Parent = container

	local function createWiper(name, parent, position)
		local clip = Instance.new("Frame")
		clip.Name = name .. "Clip"
		clip.Size = UDim2.new(0.5, 0, 1, 0)
		clip.Position = position
		clip.BackgroundTransparency = 1
		clip.ClipsDescendants = true
		clip.Parent = parent

		local wiper = Instance.new("Frame")
		wiper.Name = name .. "Wiper"
		wiper.Size = UDim2.new(2, 0, 1, 0)
		wiper.Position = UDim2.new(position.X.Scale == 0 and 0 or -1, 0, 0, 0)
		wiper.BackgroundColor3 = WEDGE_COLOR
		wiper.BackgroundTransparency = 0
		wiper.BorderSizePixel = 0
		wiper.Parent = clip

		local gradient = Instance.new("UIGradient")
		gradient.Name = "Gradient"
		-- Rotation 0: Left is fully transparent, Right is opaque (WEDGE_TRANSPARENCY)
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.499, 1),
			NumberSequenceKeypoint.new(0.5, WEDGE_TRANSPARENCY),
			NumberSequenceKeypoint.new(1, WEDGE_TRANSPARENCY)
		})
		gradient.Parent = wiper

		return wiper, gradient
	end

	local leftWiper, leftGradient = createWiper("Left", container, UDim2.new(0, 0, 0, 0))
	local rightWiper, rightGradient = createWiper("Right", container, UDim2.new(0.5, 0, 0, 0))

	-- Numeric countdown label centred on the slot
	local cdLabel = Instance.new("TextLabel")
	cdLabel.Name = "CooldownText"
	cdLabel.Size = UDim2.new(1, 0, 1, 0)
	cdLabel.Position = UDim2.new(0, 0, 0, 0)
	cdLabel.BackgroundTransparency = 1
	cdLabel.Text = ""
	cdLabel.TextColor3 = Color3.new(1, 1, 1)
	cdLabel.TextStrokeTransparency = 0.3
	cdLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	cdLabel.Font = Enum.Font.GothamBold
	cdLabel.TextSize = 16
	cdLabel.ZIndex = container.ZIndex + 2
	cdLabel.Parent = slotFrame

	return {
		container     = container,
		rightGradient = rightGradient,
		leftGradient  = leftGradient,
		cdLabel       = cdLabel,
		connection    = nil :: RBXScriptConnection?,
		active        = false,
	}
end

--[[
	Update the overlay to reflect a given progress.

	  progress = 0    →  full dark circle (cooldown just started)
	  progress = 0.5  →  left semicircle dark (right half cleared)
	  progress = 1    →  fully transparent (cooldown finished)

	Phase 1 (0 → 0.5):  Right gradient rotates CW 0°→180°, Left gradient stays at 180°.
	Phase 2 (0.5 → 1):  Right gradient stays at 180°, Left gradient rotates CW 180°→360°.
]]
function CooldownOverlay.SetProgress(overlay, progress)
	progress = math.clamp(progress, 0, 1)

	if progress <= 0.5 then
		-- Phase 1: Right side sweeps 0 -> 180, left side stays fully dark (180)
		local t = progress / 0.5

		overlay.rightGradient.Rotation = t * 180
		overlay.leftGradient.Rotation = 180
	else
		-- Phase 2: Right side is empty (180), left side sweeps 180 -> 360
		local t = (progress - 0.5) / 0.5

		overlay.rightGradient.Rotation = 180
		overlay.leftGradient.Rotation = 180 + (t * 180)
	end
end

--[[
	Begin the clock-wipe cooldown animation.

	  startTime  : number — the server's tick() when the cooldown began.
	               Using the server timestamp keeps the wipe accurate even
	               with network latency.
	  duration   : number — total cooldown length in seconds.
	  onFinished : (() -> ())? — callback fired once when cooldown ends.
]]
function CooldownOverlay.StartCooldown(overlay, startTime, duration, onFinished)
	-- Tear down any previous cooldown on this slot
	if overlay.connection then
		overlay.connection:Disconnect()
		overlay.connection = nil
	end

	overlay.active = true
	overlay.container.Visible = true
	overlay.cdLabel.Visible = true

	-- Write the initial fully-dark frame
	CooldownOverlay.SetProgress(overlay, 0)

	-- Drive the wipe every render frame
	overlay.connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.clamp(elapsed / duration, 0, 1)

		-- Update the pie wipe visual
		CooldownOverlay.SetProgress(overlay, progress)

		-- Update the countdown text
		local remaining = math.max(0, duration - elapsed)
		if remaining > 0 then
			overlay.cdLabel.Text = string.format("%.1f", remaining)
		else
			overlay.cdLabel.Text = ""
		end

		-- Cooldown complete → clean up
		if progress >= 1 then
			CooldownOverlay.StopCooldown(overlay)
			if onFinished then
				onFinished()
			end
		end
	end)
end

--[[
	Immediately stop the cooldown visual and disconnect the render connection.
]]
function CooldownOverlay.StopCooldown(overlay)
	if overlay.connection then
		overlay.connection:Disconnect()
		overlay.connection = nil
	end
	overlay.active = false
	overlay.container.Visible = false
	overlay.cdLabel.Text = ""
end

return CooldownOverlay
