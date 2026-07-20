local WeaponGrips = require(script.Parent.Parent.Config.WeaponGrips)
local WeaponTextures = require(script.Parent.Parent.Config.WeaponTextures)
local WeaponMeshConfig = require(script.Parent.Parent.Config.WeaponMeshConfig)
local Items = require(script.Parent.Parent.Config.Items)

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local function addSlashArc(parent, color)
	local arc = Instance.new("Part")
	arc.Name = "CyanSlashArc"
	arc.Size = Vector3.new(3.8, 0.08, 2.2)
	arc.Transparency = 1
	arc.CanCollide = false
	arc.CanTouch = false
	arc.CanQuery = false
	arc.Massless = true
	arc.Anchored = false
	arc.Parent = parent

	local a0 = Instance.new("Attachment")
	a0.Name = "SlashArcA0"
	a0.Position = Vector3.new(-1.9, 0, -1.1)
	a0.Parent = arc

	local a1 = Instance.new("Attachment")
	a1.Name = "SlashArcA1"
	a1.Position = Vector3.new(1.9, 0, 1.1)
	a1.Parent = arc

	local trail = Instance.new("Trail")
	trail.Name = "CyanSlashTrail"
	trail.Enabled = false
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.28
	trail.MinLength = 0.02
	trail.LightEmission = 1
	trail.Color = ColorSequence.new(color)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.65, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	trail.Parent = arc

	addEmitter(arc, "CyanSlashSpark", color, 75, 0.22)
	return arc
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
	if style == "axe" then
		names = phase == "swing"
			and { "SlashTrail", "CyanSlashTrail" }
			or { "SlashTrail", "SlashSpark", "ThrustSpark", "CyanSlashTrail", "CyanSlashSpark" }
	elseif style == "sword" or style == "spear" then
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
	if style == "sword" or style == "spear" then
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
	elseif cfg and cfg.meshId and cfg.meshId ~= "" then
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

	-- Catalog tools already contain their own weapon model.  Do not replace it
	-- with the procedural class skin when the tool is equipped on the client.
	if tool:GetAttribute("PreserveCatalogAppearance") then
		local skin = item.weaponSkin or {}
		local style = WeaponGrips.GetStyle(weaponId, item)
		local gripCfg = WeaponGrips.Styles[style]
		tool.Grip = gripCfg.idle
		tool:SetAttribute("WeaponStyle", style)
		tool:SetAttribute("ToolHold", skin.toolHold or item.classRestriction)
		tool:SetAttribute("GripVersion", WeaponGrips.GRIP_VERSION)
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
	local meshStyles = { sword = true, staff = true, bow = true, mace = true, spear = true }

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

function SkinToolBuilder.LoadWeaponTemplate(weaponId, item)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Weapons")
	if not folder then
		return nil
	end

	local byId = folder:FindFirstChild(weaponId)
	if byId and byId:IsA("Tool") then
		return byId:Clone()
	end

	local style = WeaponGrips.GetStyle(weaponId, item)
	local byStyle = folder:FindFirstChild(style)
	if byStyle and byStyle:IsA("Tool") then
		return byStyle:Clone()
	end

	return nil
end

local wrapCatalogVisualAsTool

local function loadToolFromCatalog(toolAssetId)
	local ok, container = pcall(function()
		return InsertService:LoadAsset(toolAssetId)
	end)
	if not ok or not container then
		return nil
	end

	local tool = container:FindFirstChildWhichIsA("Tool", true)
	if tool then
		tool = tool:Clone()
	else
		-- Toolbox weapon assets are often published as Models or Accessories,
		-- rather than Tools. Wrap their visible handle in a Tool so they can be
		-- equipped by the combat system as well.
		local source = container:FindFirstChildWhichIsA("Model", true)
			or container:FindFirstChildWhichIsA("Accessory", true)
			or container:FindFirstChildWhichIsA("BasePart", true)
		if source then
			tool = wrapCatalogVisualAsTool(source)
		end
	end
	container:Destroy()
	return tool
end

local function getVisualReferencePart(visual)
	if visual:IsA("BasePart") then
		return visual
	end
	return visual:FindFirstChild("Handle", true) or visual:FindFirstChildWhichIsA("BasePart", true)
end

wrapCatalogVisualAsTool = function(source)
	local visual = source:Clone()
	local referencePart = getVisualReferencePart(visual)
	if not referencePart or not referencePart:IsA("BasePart") then
		visual:Destroy()
		return nil
	end

	local tool = Instance.new("Tool")
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, 0.2, 0.4)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Anchored = false
	handle.CFrame = referencePart.CFrame
	handle.Parent = tool

	visual.Parent = tool
	if visual:IsA("BasePart") then
		visual.Anchored = false
		visual.CanCollide = false
		visual.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = visual
		weld.Parent = visual
	end
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = descendant
			weld.Parent = descendant
		end
	end

	return tool
end

local function scaleCatalogTool(tool, scale)
	if not scale or scale == 1 then
		return
	end

	local handle = tool:FindFirstChild("Handle", true)
	if not handle or not handle:IsA("BasePart") then
		return
	end

	local transforms = {}
	for _, descendant in tool:GetDescendants() do
		if descendant:IsA("BasePart") then
			transforms[descendant] = handle.CFrame:ToObjectSpace(descendant.CFrame)
		end
	end

	for part, relative in transforms do
		local rotation = relative - relative.Position
		part.Size *= scale
		part.CFrame = handle.CFrame * CFrame.new(relative.Position * scale) * rotation
	end

	for _, descendant in tool:GetDescendants() do
		if descendant:IsA("SpecialMesh") then
			descendant.Scale *= scale
			descendant.Offset *= scale
		elseif descendant:IsA("Attachment") then
			descendant.Position *= scale
		elseif descendant:IsA("Weld") or descendant:IsA("Motor6D") then
			descendant.C0 = CFrame.new(descendant.C0.Position * scale) * (descendant.C0 - descendant.C0.Position)
			descendant.C1 = CFrame.new(descendant.C1.Position * scale) * (descendant.C1 - descendant.C1.Position)
		end
	end
end

local function transformCatalogTool(tool, rotation, offset)
	if not rotation and not offset then
		return
	end

	local handle = tool:FindFirstChild("Handle", true)
	if not handle or not handle:IsA("BasePart") then
		return
	end

	local transform = CFrame.new(offset or Vector3.zero)
	if rotation then
		transform *= CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))
	end

	for _, descendant in tool:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= handle then
			local relative = handle.CFrame:ToObjectSpace(descendant.CFrame)
			descendant.CFrame = handle.CFrame * transform * relative
		end
	end
end

local function addCatalogWeaponEffects(tool, style)
	if style ~= "axe" and style ~= "sword" then
		return
	end

	local handle = tool:FindFirstChild("Handle", true)
	if not handle or not handle:IsA("BasePart") then
		return
	end

	local existing = tool:FindFirstChild("CyanSlashArc", true)
	if existing then
		return
	end

	local color = Color3.fromRGB(20, 230, 255)
	local arc = addSlashArc(tool, color)
	arc.CFrame = handle.CFrame * CFrame.new(0, 1.65, -0.35) * CFrame.Angles(0, 0, math.rad(25))

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = arc
	weld.Parent = arc

	local moveA0 = Instance.new("Attachment")
	moveA0.Name = "MoveGlowA0"
	moveA0.Position = Vector3.new(0, 1.1, 0)
	moveA0.Parent = handle

	local moveA1 = Instance.new("Attachment")
	moveA1.Name = "MoveGlowA1"
	moveA1.Position = Vector3.new(0, -1.1, 0)
	moveA1.Parent = handle

	local moveTrail = Instance.new("Trail")
	moveTrail.Name = "CyanMoveTrail"
	moveTrail.Enabled = false
	moveTrail.Attachment0 = moveA0
	moveTrail.Attachment1 = moveA1
	moveTrail.Lifetime = 0.16
	moveTrail.MinLength = 0.04
	moveTrail.LightEmission = 0.8
	moveTrail.Color = ColorSequence.new(color)
	moveTrail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	moveTrail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	moveTrail.Parent = handle
end

local function prepareTool(tool, weaponId, item, preserveCatalogAppearance)
	tool.Name = item.name or weaponId
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("WeaponId", weaponId)
	if preserveCatalogAppearance then
		tool:SetAttribute("PreserveCatalogAppearance", true)
		scaleCatalogTool(tool, item.toolAssetScale)
		transformCatalogTool(tool, item.toolAssetRotation, item.toolAssetOffset)
		addCatalogWeaponEffects(tool, WeaponGrips.GetStyle(weaponId, item))
	end
	SkinToolBuilder.ApplySkin(tool, weaponId, item)
	return tool
end

function SkinToolBuilder.BuildWeaponTool(weaponId)
	local item = Items[weaponId]
	if not item or item.type ~= "weapon" then
		return nil
	end

	if item.toolAssetId then
		local catalogTool = loadToolFromCatalog(item.toolAssetId)
		if catalogTool then
			return prepareTool(catalogTool, weaponId, item, true)
		end
		warn(string.format("Unable to load catalog weapon asset %s for %s; using the fallback skin.", item.toolAssetId, weaponId))
	end

	local template = SkinToolBuilder.LoadWeaponTemplate(weaponId, item)
	if template then
		return prepareTool(template, weaponId, item)
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
