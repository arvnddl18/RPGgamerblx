local WeaponGrips = require(script.Parent.Parent.Config.WeaponGrips)
local WeaponTextures = require(script.Parent.Parent.Config.WeaponTextures)
local WeaponMeshConfig = require(script.Parent.Parent.Config.WeaponMeshConfig)
local Items = require(script.Parent.Parent.Config.Items)

local SkinToolBuilder = {}

local SCALE = 1.75
local function sz(x, y, z)
	return Vector3.new(x * SCALE, y * SCALE, z * SCALE)
end
-- Tip at -Z (forward), grip/pommel at +Z (toward hand)
local function pos(x, y, z)
	return CFrame.new(x * SCALE, y * SCALE, -z * SCALE)
end

local function makePart(props)
	local p = Instance.new("Part")
	p.CanCollide = false
	p.Massless = true
	p.Anchored = false
	p.CastShadow = true
	for key, value in props do
		p[key] = value
	end
	return p
end

local function weldTo(handle, part, offset)
	part.Parent = handle
	part.CFrame = handle.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = part
	weld.Parent = part
	return part
end

local function addEmitter(parent, name, color, rate, lifetime)
	local att = Instance.new("Attachment")
	att.Name = name .. "Att"
	att.Parent = parent

	local em = Instance.new("ParticleEmitter")
	em.Name = name
	em.Enabled = false
	em.Rate = rate or 30
	em.Lifetime = NumberRange.new(lifetime or 0.3, (lifetime or 0.3) + 0.2)
	em.Speed = NumberRange.new(1, 3)
	em.SpreadAngle = Vector2.new(20, 20)
	em.Color = ColorSequence.new(color)
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Parent = att
	return em
end

local function addTrail(blade, color)
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA0"
	a0.Position = Vector3.new(0, 0, -0.5)
	a0.Parent = blade

	local a1 = Instance.new("Attachment")
	a1.Name = "TrailA1"
	a1.Position = Vector3.new(0, 0, 0.5)
	a1.Parent = blade

	local trail = Instance.new("Trail")
	trail.Name = "SlashTrail"
	trail.Enabled = false
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.25
	trail.MinLength = 0.05
	trail.Color = ColorSequence.new(color)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Parent = blade
	return trail
end

local function setupEffectsFolder(tool)
	local folder = Instance.new("Folder")
	folder.Name = "WeaponEffects"
	folder.Parent = tool
	return folder
end

local function buildWarriorVisuals(handle, color)
	local metal = Color3.fromRGB(170, 170, 180)
	local guard = weldTo(handle, makePart({
		Name = "Crossguard",
		Size = sz(1.2, 0.25, 0.3),
		Color = metal,
		Material = Enum.Material.Metal,
	}), pos(0, 0, 0.5))

	local blade = weldTo(handle, makePart({
		Name = "Blade",
		Size = sz(0.22, 0.85, 3.0),
		Color = color,
		Material = Enum.Material.Metal,
	}), pos(0, 0, 2.2))

	weldTo(handle, makePart({
		Name = "Pommel",
		Size = sz(0.45, 0.45, 0.45),
		Shape = Enum.PartType.Ball,
		Color = metal,
		Material = Enum.Material.Metal,
	}), pos(0, 0, -0.35))

	addTrail(blade, color)
	addEmitter(blade, "SlashSpark", color, 40, 0.2)
	handle:SetAttribute("EffectBlade", blade.Name)
end

local function buildMageVisuals(handle, color)
	local wood = Color3.fromRGB(65, 42, 24)
	weldTo(handle, makePart({
		Name = "Shaft",
		Size = sz(0.28, 0.28, 5.0),
		Color = wood,
		Material = Enum.Material.Wood,
	}), pos(0, 0, 2.8))

	local crystal = weldTo(handle, makePart({
		Name = "Crystal",
		Size = sz(0.8, 1.1, 0.8),
		Shape = Enum.PartType.Ball,
		Color = color,
		Material = Enum.Material.Neon,
	}), pos(0, 0, 5.8))

	local light = Instance.new("PointLight")
	light.Name = "CastLight"
	light.Color = color
	light.Brightness = 0
	light.Range = 10
	light.Parent = crystal

	addEmitter(crystal, "ArcaneBurst", color, 50, 0.4)
	addEmitter(crystal, "CastMist", Color3.fromRGB(140, 160, 255), 25, 0.6)
	handle:SetAttribute("EffectCrystal", crystal.Name)
end

local function buildArcherVisuals(handle, color)
	local limb = Color3.fromRGB(90, 60, 35)
	local topLimb = weldTo(handle, makePart({
		Name = "BowTop",
		Size = sz(0.16, 1.4, 0.16),
		Color = limb,
		Material = Enum.Material.Wood,
	}), pos(0, 0.7, 0))

	local botLimb = weldTo(handle, makePart({
		Name = "BowBottom",
		Size = sz(0.16, 1.4, 0.16),
		Color = limb,
		Material = Enum.Material.Wood,
	}), pos(0, -0.7, 0))

	weldTo(handle, makePart({
		Name = "BowGrip",
		Size = sz(0.24, 0.45, 0.24),
		Color = color,
		Material = Enum.Material.Fabric,
	}), CFrame.new())

	weldTo(handle, makePart({
		Name = "BowString",
		Size = sz(0.04, 2.6, 0.04),
		Color = Color3.fromRGB(230, 230, 220),
		Material = Enum.Material.SmoothPlastic,
	}), pos(0, 0, -0.1))

	addEmitter(topLimb, "ArrowGlow", color, 20, 0.15)
	addEmitter(botLimb, "ReleaseFlash", Color3.fromRGB(255, 220, 120), 35, 0.2)
	handle:SetAttribute("EffectBowTop", topLimb.Name)
end

local function buildPriestVisuals(handle, color)
	local metal = Color3.fromRGB(210, 200, 140)
	weldTo(handle, makePart({
		Name = "MaceShaft",
		Size = sz(0.26, 0.26, 2.0),
		Color = metal,
		Material = Enum.Material.Metal,
	}), pos(0, 0, 1.1))

	local head = weldTo(handle, makePart({
		Name = "MaceHead",
		Size = sz(1.0, 1.0, 1.0),
		Shape = Enum.PartType.Ball,
		Color = color,
		Material = Enum.Material.Metal,
	}), pos(0, 0, 2.4))

	weldTo(handle, makePart({
		Name = "HolyRing",
		Size = sz(1.1, 0.16, 1.1),
		Color = Color3.fromRGB(255, 240, 160),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
	}), pos(0, 0, 2.4) * CFrame.Angles(math.rad(90), 0, 0))

	addEmitter(head, "HolyBurst", Color3.fromRGB(255, 230, 120), 30, 0.35)
	addEmitter(head, "HealGlow", color, 20, 0.5)
	handle:SetAttribute("EffectMaceHead", head.Name)
end

local function buildSpearVisuals(handle, color)
	local metal = Color3.fromRGB(160, 160, 170)
	weldTo(handle, makePart({
		Name = "SpearShaft",
		Size = sz(0.24, 0.24, 5.5),
		Color = Color3.fromRGB(75, 50, 30),
		Material = Enum.Material.Wood,
	}), pos(0, 0, 3.0))

	local tip = weldTo(handle, makePart({
		Name = "SpearTip",
		Size = sz(0.35, 0.35, 1.4),
		Color = metal,
		Material = Enum.Material.Metal,
	}), pos(0, 0, 6.2))

	weldTo(handle, makePart({
		Name = "SpearPennant",
		Size = sz(0.06, 0.65, 0.45),
		Color = color,
		Material = Enum.Material.Fabric,
	}), pos(0, 0.3, 4.0))

	addTrail(tip, color)
	addEmitter(tip, "ThrustSpark", color, 45, 0.2)
	handle:SetAttribute("EffectSpearTip", tip.Name)
end

local BUILDERS = {
	sword = buildWarriorVisuals,
	staff = buildMageVisuals,
	bow = buildArcherVisuals,
	mace = buildPriestVisuals,
	spear = buildSpearVisuals,
}

local function setEmitters(tool, enabled, names)
	for _, desc in tool:GetDescendants() do
		if desc:IsA("ParticleEmitter") then
			if not names or table.find(names, desc.Name) then
				desc.Enabled = enabled
			end
		end
		if desc:IsA("Trail") then
			if not names or table.find(names, desc.Name) then
				desc.Enabled = enabled
			end
		end
		if desc:IsA("PointLight") and desc.Name == "CastLight" then
			if not names or table.find(names, "CastLight") then
				desc.Brightness = enabled and 2 or 0
			end
		end
	end
end

function SkinToolBuilder.PlayEffect(tool, style, phase)
	if not tool then
		return
	end
	phase = phase or "hit"
	local names = nil
	if style == "sword" or style == "spear" then
		names = phase == "swing" and { "SlashTrail" } or { "SlashTrail", "SlashSpark", "ThrustSpark" }
	elseif style == "staff" then
		names = { "ArcaneBurst", "CastMist", "CastLight" }
	elseif style == "bow" then
		names = phase == "swing" and { "ArrowGlow" } or { "ArrowGlow", "ReleaseFlash" }
	elseif style == "mace" then
		names = { "HolyBurst", "HealGlow" }
	end
	setEmitters(tool, true, names)
	if phase == "hit" then
		task.delay(0.35, function()
			if tool.Parent then
				setEmitters(tool, false)
			end
		end)
	end
end

function SkinToolBuilder.StopEffects(tool)
	if tool then
		setEmitters(tool, false)
	end
end

function SkinToolBuilder.BindAnimationEffects(tool, track)
	if not tool or not track then
		return
	end
	local style = tool:GetAttribute("WeaponStyle")
	if not style then
		return
	end

	SkinToolBuilder.PlayEffect(tool, style, "swing")

	local hitConn
	pcall(function()
		hitConn = track:GetMarkerReachedSignal("Hit"):Connect(function()
			SkinToolBuilder.PlayEffect(tool, style, "hit")
		end)
	end)

	track.Stopped:Once(function()
		if hitConn then
			hitConn:Disconnect()
		end
		SkinToolBuilder.StopEffects(tool)
	end)
end

function SkinToolBuilder.GetItem(weaponId, itemConfig)
	return itemConfig or Items[weaponId]
end

local function hasVisuals(handle)
	for _, child in handle:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "Handle" then
			return true
		end
	end
	return false
end

local function addMeshEffects(meshPart, style, color)
	if style == "sword" or style == "spear" or style == "axe" then
		addTrail(meshPart, color)
		addEmitter(meshPart, "SlashSpark", color, 40, 0.2)
	elseif style == "staff" then
		addEmitter(meshPart, "ArcaneBurst", color, 50, 0.4)
		addEmitter(meshPart, "CastMist", Color3.fromRGB(140, 160, 255), 25, 0.6)
	elseif style == "bow" then
		addEmitter(meshPart, "ArrowGlow", color, 20, 0.15)
		addEmitter(meshPart, "ReleaseFlash", Color3.fromRGB(255, 220, 120), 35, 0.2)
	elseif style == "mace" then
		addEmitter(meshPart, "HolyBurst", Color3.fromRGB(255, 230, 120), 30, 0.35)
		addEmitter(meshPart, "HealGlow", color, 20, 0.5)
	end
end

local function buildMeshVisuals(handle, style, color)
	local template = WeaponMeshConfig.GetTemplate(style)
	local cfg = WeaponMeshConfig.Get(style)
	if not cfg and not template then
		return false
	end

	local srcHandle = template and template:FindFirstChild("Handle")
	local visualFolder = srcHandle and srcHandle:FindFirstChild("WeaponVisual")
	if visualFolder then
		for _, part in visualFolder:GetChildren() do
			if part:IsA("BasePart") then
				local p = part:Clone()
				p.CanCollide = false
				p.Massless = true
				p.Anchored = false
				local localCF = part:GetAttribute("LocalCF")
				p.Parent = handle
				if typeof(localCF) == "CFrame" then
					p.CFrame = handle.CFrame * localCF
				end
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = p
				weld.Parent = p
			end
		end
		local fxPart = handle:FindFirstChildWhichIsA("MeshPart", true) or handle:FindFirstChildWhichIsA("BasePart", true)
		if fxPart then
			addMeshEffects(fxPart, style, color)
		end
		return true
	end

	local meshPart
	local srcMesh = srcHandle and srcHandle:FindFirstChild("WeaponMesh")
	if srcMesh and srcMesh:IsA("MeshPart") then
		meshPart = srcMesh:Clone()
	elseif cfg then
		meshPart = Instance.new("MeshPart")
		meshPart.MeshId = cfg.meshId
	else
		return false
	end

	meshPart.Name = "WeaponMesh"
	meshPart.CanCollide = false
	meshPart.Massless = true
	meshPart.Anchored = false
	meshPart.CastShadow = true
	meshPart.Parent = handle

	local gripOffset = template and template:GetAttribute("GripOffset")
	if typeof(gripOffset) ~= "Vector3" and cfg then
		gripOffset = cfg.gripOffset
	end
	if typeof(gripOffset) == "Vector3" then
		meshPart.CFrame = CFrame.new(-gripOffset)
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = meshPart
	weld.Parent = meshPart

	if not meshPart:FindFirstChildOfClass("SurfaceAppearance") or meshPart.TextureID == "" then
		WeaponTextures.Apply(meshPart, style)
	end
	addMeshEffects(meshPart, style, color)
	return true
end

function SkinToolBuilder.ApplySkin(tool, weaponId, itemConfig)
	if not tool then
		return tool
	end

	local item = SkinToolBuilder.GetItem(weaponId, itemConfig)
	if not item then
		return tool
	end

	local handle = tool:FindFirstChild("Handle")
	if not handle then
		handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Parent = tool
	end

	local SKIN_VERSION = 8

	local skin = item.weaponSkin or {}
	local style = WeaponGrips.GetStyle(weaponId, item)
	local gripCfg = WeaponGrips.Styles[style]
	local meshStyles = { sword = true, staff = true, bow = true, axe = true }

	local function applyGripMeta()
		tool.Grip = gripCfg.idle
		tool:SetAttribute("WeaponStyle", style)
		tool:SetAttribute("ToolHold", skin.toolHold or item.classRestriction)
		tool:SetAttribute("GripVersion", WeaponGrips.GRIP_VERSION)
	end

	local forceRebuild = tool:GetAttribute("SkinVersion") ~= SKIN_VERSION
	if tool:GetAttribute("Skinned") and hasVisuals(handle) and not forceRebuild then
		applyGripMeta()
		return tool
	end

	for _, child in handle:GetChildren() do
		if child:IsA("BasePart") and child ~= handle then
			child:Destroy()
		end
	end

	local color = skin.effectColor or item.color or Color3.fromRGB(200, 200, 200)

	handle.Size = gripCfg.handleSize
	handle.CanCollide = false
	handle.Massless = true
	handle.Transparency = 1
	handle.Color = color
	handle.Material = Enum.Material.SmoothPlastic

	local usedMesh = meshStyles[style] and buildMeshVisuals(handle, style, color)
	if not usedMesh then
		local builder = BUILDERS[style]
		if builder then
			builder(handle, color)
		end
	end

	setupEffectsFolder(tool)
	applyGripMeta()
	tool:SetAttribute("Skinned", true)
	tool:SetAttribute("SkinVersion", SKIN_VERSION)
	return tool
end

function SkinToolBuilder.BuildWeaponTool(weaponId)
	local item = Items[weaponId]
	if not item or item.type ~= "weapon" then
		return nil
	end

	local tool = Instance.new("Tool")
	tool.Name = item.name or weaponId
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("WeaponId", weaponId)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Parent = tool

	SkinToolBuilder.ApplySkin(tool, weaponId, item)
	return tool
end

return SkinToolBuilder
