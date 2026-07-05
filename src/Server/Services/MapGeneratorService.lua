local Terrain = workspace.Terrain
Terrain:Clear()

if workspace:FindFirstChild("RPG_World") then
	workspace.RPG_World:Destroy()
end
if workspace:FindFirstChild("Countryside_Province_Map") then
	workspace.Countryside_Province_Map:Destroy()
end
if workspace:FindFirstChild("DefendedVillage") then
	workspace.DefendedVillage:Destroy()
end

local mapFolder = Instance.new("Folder", workspace)
mapFolder.Name = "RPG_World"
local structuresFolder = Instance.new("Folder", mapFolder)
structuresFolder.Name = "Structures"
local natureFolder = Instance.new("Folder", mapFolder)
natureFolder.Name = "Nature"

local GRID_SIZE = 220 
local SCALE = 16
local SEED = math.random(1, 100000)
local WATER_LEVEL = 18
local VILLAGE_RADIUS = 700 

local function createPart(name, parent, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CastShadow = true
	part.Parent = parent
	return part
end

print("1/4 Generating Terrain (With Smooth Gate Blending)...")
for cx = -GRID_SIZE/2, GRID_SIZE/2 do
	for cz = -GRID_SIZE/2, GRID_SIZE/2 do
		local worldX = cx * SCALE
		local worldZ = cz * SCALE
		
		local dist = math.sqrt(worldX^2 + worldZ^2)
		local craterDist = math.sqrt((worldX - 800)^2 + (worldZ + 600)^2)
		
		-- Calculate Wilderness Height
		local n1 = math.noise(worldX/500, worldZ/500, SEED) * 40
		local n2 = math.noise(worldX/100, worldZ/100, SEED+1) * 10
		local wildernessHeight = 20 + n1 + n2
		if dist > 1400 then wildernessHeight = wildernessHeight + (dist - 1400) * 0.3 end
		
		if craterDist < 250 then
			if craterDist < 120 then
				wildernessHeight = wildernessHeight - (120 - craterDist) * 0.5 
			else
				wildernessHeight = wildernessHeight + (250 - craterDist) * 0.2 
			end
		end
		
		local baseVillageHeight = 22
		local height = 0
		
		-- Smooth gradient (lerp) at the gates to prevent humps
		if dist < 600 then
			height = baseVillageHeight
		elseif dist > 800 then
			height = wildernessHeight
		else
			-- Smoothstep interpolation between 600 and 800
			local alpha = (dist - 600) / 200
			alpha = alpha * alpha * (3 - 2 * alpha)
			height = baseVillageHeight + (wildernessHeight - baseVillageHeight) * alpha
		end
		
		local mat = Enum.Material.Grass
		local isPath = false
		local roadMat = nil
		
		-- Roman Road Grid connecting gates and organizing the village
		if dist < VILLAGE_RADIUS + 50 then
			-- Main roads (Cardo Maximus and Decumanus Maximus)
			if math.abs(worldX) <= 16 or math.abs(worldZ) <= 16 then
				isPath = true
				roadMat = Enum.Material.Pavement
			-- Secondary grid roads (Insulae borders)
			elseif math.abs(worldX) % 160 == 0 or math.abs(worldZ) % 160 == 0 then
				isPath = true
				roadMat = Enum.Material.Cobblestone
			end
		end
		
		if isPath and height >= WATER_LEVEL then
			mat = roadMat
		elseif height < WATER_LEVEL then
			mat = Enum.Material.Sand
		elseif craterDist < 250 then
			mat = Enum.Material.Basalt
		elseif height > 100 then
			mat = Enum.Material.Rock
			if height > 160 then mat = Enum.Material.Snow end
		end
		
		local columnHeight = height + 100
		Terrain:FillBlock(CFrame.new(worldX, (height-100)/2, worldZ), Vector3.new(SCALE, columnHeight, SCALE), mat)
		
		if height < WATER_LEVEL then
			local wH = WATER_LEVEL - height
			Terrain:FillBlock(CFrame.new(worldX, height + wH/2, worldZ), Vector3.new(SCALE, wH, SCALE), Enum.Material.Water)
		end
	end
	if cx % 15 == 0 then task.wait() end
end

local function getGroundY(x, z)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	if mapFolder then
		rayParams.FilterDescendantsInstances = {mapFolder}
	end
	
	local ray = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -1000, 0), rayParams)
	if ray then return ray.Position.Y, ray.Material end
	return 22, Enum.Material.Grass
end

print("2/4 Building Medieval Fortification Wall & Central Castle...")

-- ==========================================
-- Medieval Stone Fortification Wall
-- ==========================================
local WALL_HEIGHT = 50          -- Taller imposing wall
local WALL_THICKNESS = 10       -- Thick stone wall
local RAMPART_WIDTH = 8         -- Walkway width on top
local MERLON_HEIGHT = 8         -- Crenellation height
local MERLON_WIDTH = 4          -- Crenellation width
local MERLON_DEPTH = 3          -- Crenellation depth
local MERLON_SPACING = 8        -- Gap between merlons
local PARAPET_HEIGHT = 4        -- Inner railing height
local BUTTRESS_SPACING = 60     -- Distance between buttresses
local TORCH_SPACING = 40        -- Distance between torches
local GATE_HALF_WIDTH = 18      -- Half-width of each gate opening
local GATE_TOWER_RADIUS = 10    -- Radius of gate flanking towers
local GATE_TOWER_HEIGHT = 65    -- Height of gate flanking towers

-- Wall color palette
local wallStoneMain  = Color3.fromRGB(160, 150, 130)  -- Main wall stone
local wallStoneDark  = Color3.fromRGB(110, 100, 85)   -- Darker accent / base
local wallStoneLight = Color3.fromRGB(185, 175, 155)  -- Lighter trim
local wallRoofSlate  = Color3.fromRGB(55, 65, 80)     -- Gate tower roofs
local wallTorchGlow  = Color3.fromRGB(255, 160, 40)   -- Torch fire color
local wallTorchPole  = Color3.fromRGB(50, 35, 20)     -- Dark wood torch pole
local wallBannerRed  = Color3.fromRGB(140, 30, 30)    -- Banner / flag color

-- Gate angles (0 = East, pi/2 = North, pi = West, 3pi/2 = South)
local gateAngles = {0, math.pi/2, math.pi, 3*math.pi/2}

-- Helper: Check if an angle is within a gate opening
local function isInGateOpening(angle)
	for _, ga in ipairs(gateAngles) do
		local diff = math.abs(angle - ga)
		if diff > math.pi then diff = 2 * math.pi - diff end
		-- Gate angular width based on GATE_HALF_WIDTH at VILLAGE_RADIUS
		local gateAngle = math.atan2(GATE_HALF_WIDTH, VILLAGE_RADIUS)
		if diff < gateAngle then
			return true
		end
	end
	return false
end

-- === MAIN WALL SEGMENTS (Stone blocks placed around circumference) ===
local wallSegWidth = 8  -- Width of each wall segment
local numSegments = math.floor((2 * math.pi * VILLAGE_RADIUS) / wallSegWidth)
local segAngleStep = (2 * math.pi) / numSegments

for i = 1, numSegments do
	local angle = i * segAngleStep
	
	if not isInGateOpening(angle) then
		local wx = math.cos(angle) * VILLAGE_RADIUS
		local wz = math.sin(angle) * VILLAGE_RADIUS
		local wy = getGroundY(wx, wz)
		
		-- Use CFrame for precise placement and rotation.
		local wallCFrame = CFrame.new(wx, wy + WALL_HEIGHT/2 - 3, wz) * CFrame.Angles(0, -angle + math.pi/2, 0)
		
		-- Main wall body (thick stone). Width slightly increased to overlap perfectly without rendering gaps.
		local wallSeg = createPart("WallSegment", structuresFolder,
			Vector3.new(wallSegWidth + 0.5, WALL_HEIGHT, WALL_THICKNESS),
			Vector3.new(0,0,0),
			wallStoneMain, Enum.Material.Cobblestone)
		wallSeg.CFrame = wallCFrame
		
		-- Stone base / foundation
		local baseH = 8
		local baseCFrame = CFrame.new(wx, wy + baseH/2 - 3, wz) * CFrame.Angles(0, -angle + math.pi/2, 0)
		local baseSeg = createPart("WallBase", structuresFolder,
			Vector3.new(wallSegWidth + 0.5, baseH, WALL_THICKNESS + 4),
			Vector3.new(0,0,0),
			wallStoneDark, Enum.Material.Brick)
		baseSeg.CFrame = baseCFrame
		
		-- Rampart walkway
		local rampartInnerOffset = VILLAGE_RADIUS - RAMPART_WIDTH/2 - 1
		local rx = math.cos(angle) * rampartInnerOffset
		local rz = math.sin(angle) * rampartInnerOffset
		local rampartCFrame = CFrame.new(rx, wy + WALL_HEIGHT - 4, rz) * CFrame.Angles(0, -angle + math.pi/2, 0)
		local rampart = createPart("Rampart", structuresFolder,
			Vector3.new(wallSegWidth + 0.5, 2, RAMPART_WIDTH),
			Vector3.new(0,0,0),
			wallStoneLight, Enum.Material.Slate)
		rampart.CFrame = rampartCFrame
	end
	if i % 80 == 0 then task.wait() end
end

-- === CRENELLATIONS (Merlons on top of the outer edge) ===
-- Fix merlon spacing to make it continuous rather than leaving huge floating gaps
local MERLON_ADJUSTED_SPACING = 5
local merlonAngularStep = MERLON_ADJUSTED_SPACING / VILLAGE_RADIUS
local merlonCount = math.floor((2 * math.pi) / merlonAngularStep)

for i = 1, merlonCount do
	local angle = i * merlonAngularStep
	
	if not isInGateOpening(angle) then
		-- Skip every other for crenel gap
		if i % 2 == 0 then
			local mx = math.cos(angle) * (VILLAGE_RADIUS + 1)
			local mz = math.sin(angle) * (VILLAGE_RADIUS + 1)
			local my = getGroundY(math.cos(angle) * VILLAGE_RADIUS, math.sin(angle) * VILLAGE_RADIUS)
			
			local mCFrame = CFrame.new(mx, my + WALL_HEIGHT + MERLON_HEIGHT/2 - 4, mz) * CFrame.Angles(0, -angle + math.pi/2, 0)
			local merlon = createPart("Merlon", structuresFolder,
				Vector3.new(MERLON_WIDTH, MERLON_HEIGHT, MERLON_DEPTH),
				Vector3.new(0,0,0),
				wallStoneDark, Enum.Material.Cobblestone)
			merlon.CFrame = mCFrame
		end
	end
	if i % 80 == 0 then task.wait() end
end

-- === INNER PARAPET (low railing on the inside of the walkway) ===
local paraAngleStep = (wallSegWidth * 2) / VILLAGE_RADIUS
local paraCount = math.floor((2 * math.pi) / paraAngleStep)
local paraInnerOffset = VILLAGE_RADIUS - RAMPART_WIDTH - 1

for i = 1, paraCount do
	local angle = i * paraAngleStep
	if not isInGateOpening(angle) then
		local px = math.cos(angle) * paraInnerOffset
		local pz = math.sin(angle) * paraInnerOffset
		local py = getGroundY(math.cos(angle) * VILLAGE_RADIUS, math.sin(angle) * VILLAGE_RADIUS)
		
		local pCFrame = CFrame.new(px, py + WALL_HEIGHT - 1, pz) * CFrame.Angles(0, -angle + math.pi/2, 0)
		local parapet = createPart("Parapet", structuresFolder,
			Vector3.new(wallSegWidth * 2 + 0.5, PARAPET_HEIGHT, 2),
			Vector3.new(0,0,0),
			wallStoneLight, Enum.Material.Cobblestone)
		parapet.CFrame = pCFrame
	end
	if i % 50 == 0 then task.wait() end
end

-- === BUTTRESSES (structural supports on the outer face) ===
local buttAngleStep = BUTTRESS_SPACING / VILLAGE_RADIUS
local buttCount = math.floor((2 * math.pi) / buttAngleStep)

for i = 1, buttCount do
	local angle = i * buttAngleStep
	if not isInGateOpening(angle) then
		local bx = math.cos(angle) * (VILLAGE_RADIUS + WALL_THICKNESS/2 + 1)
		local bz = math.sin(angle) * (VILLAGE_RADIUS + WALL_THICKNESS/2 + 1)
		local by = getGroundY(math.cos(angle) * VILLAGE_RADIUS, math.sin(angle) * VILLAGE_RADIUS)
		
		local buttressH = WALL_HEIGHT * 0.7
		local bCFrame = CFrame.new(bx, by + buttressH/2 - 3, bz) * CFrame.Angles(0, -angle + math.pi/2, 0)
		local buttress = createPart("Buttress", structuresFolder,
			Vector3.new(5, buttressH, 6),
			Vector3.new(0,0,0),
			wallStoneDark, Enum.Material.Brick)
		buttress.CFrame = bCFrame
		
		local capX = math.cos(angle) * (VILLAGE_RADIUS + WALL_THICKNESS/2 + 1)
		local capZ = math.sin(angle) * (VILLAGE_RADIUS + WALL_THICKNESS/2 + 1)
		local cCFrame = CFrame.new(capX, by + buttressH - 1.5, capZ) * CFrame.Angles(0, -angle + math.pi/2, 0)
		local buttressCap = createPart("ButtressCap", structuresFolder,
			Vector3.new(7, 3, 8),
			Vector3.new(0,0,0),
			wallStoneLight, Enum.Material.Cobblestone)
		buttressCap.CFrame = cCFrame
	end
end

-- === WALL TORCHES (mounted on outer wall face with PointLights) ===
local torchAngleStep = TORCH_SPACING / VILLAGE_RADIUS
local torchCount = math.floor((2 * math.pi) / torchAngleStep)

for i = 1, torchCount do
	local angle = i * torchAngleStep
	if not isInGateOpening(angle) then
		local outerDist = VILLAGE_RADIUS + WALL_THICKNESS/2 + 1.5
		local tx = math.cos(angle) * outerDist
		local tz = math.sin(angle) * outerDist
		local ty = getGroundY(math.cos(angle) * VILLAGE_RADIUS, math.sin(angle) * VILLAGE_RADIUS)
		
		-- Torch pole (vertical dark wood stick)
		local torchPoleH = 8
		local pole = createPart("TorchPole", structuresFolder,
			Vector3.new(1, torchPoleH, 1),
			Vector3.new(tx, ty + WALL_HEIGHT * 0.65, tz),
			wallTorchPole, Enum.Material.Wood)
		pole.Orientation = Vector3.new(0, math.deg(-angle), 0)
		
		-- Torch flame (glowing ball at the top)
		local flame = createPart("TorchFlame", structuresFolder,
			Vector3.new(2.5, 3, 2.5),
			Vector3.new(tx, ty + WALL_HEIGHT * 0.65 + torchPoleH/2 + 1, tz),
			wallTorchGlow, Enum.Material.Neon)
		flame.Shape = Enum.PartType.Ball
		
		-- PointLight for warm ambient glow
		local light = Instance.new("PointLight")
		light.Color = wallTorchGlow
		light.Brightness = 1.8
		light.Range = 45
		light.Parent = flame
		
		-- Fire particle effect
		local fire = Instance.new("Fire")
		fire.Size = 4
		fire.Heat = 8
		fire.Color = Color3.fromRGB(255, 180, 60)
		fire.SecondaryColor = Color3.fromRGB(255, 80, 20)
		fire.Parent = flame
	end
end

-- === GATE TOWERS (Flanking each of the 4 gate openings) ===
for _, ga in ipairs(gateAngles) do
	local gateX = math.cos(ga) * VILLAGE_RADIUS
	local gateZ = math.sin(ga) * VILLAGE_RADIUS
	local gateY = getGroundY(gateX, gateZ)
	
	-- Perpendicular direction for tower placement (left and right of gate)
	local perpAngle = ga + math.pi/2
	
	for side = -1, 1, 2 do
		local towerX = gateX + math.cos(perpAngle) * (GATE_HALF_WIDTH + GATE_TOWER_RADIUS/2)  * side
		local towerZ = gateZ + math.sin(perpAngle) * (GATE_HALF_WIDTH + GATE_TOWER_RADIUS/2) * side
		local towerY = getGroundY(towerX, towerZ)
		
		-- Tower body (cylindrical stone tower)
		local tower = createPart("GateTower", structuresFolder,
			Vector3.new(GATE_TOWER_HEIGHT, GATE_TOWER_RADIUS * 2, GATE_TOWER_RADIUS * 2),
			Vector3.new(towerX, towerY + GATE_TOWER_HEIGHT/2 - 3, towerZ),
			wallStoneMain, Enum.Material.Cobblestone)
		tower.Shape = Enum.PartType.Cylinder
		tower.Orientation = Vector3.new(0, 0, 90)
		
		-- Tower rim (decorative ring at the top)
		local rim = createPart("GateTowerRim", structuresFolder,
			Vector3.new(4, GATE_TOWER_RADIUS * 2 + 4, GATE_TOWER_RADIUS * 2 + 4),
			Vector3.new(towerX, towerY + GATE_TOWER_HEIGHT - 1, towerZ),
			wallStoneDark, Enum.Material.Cobblestone)
		rim.Shape = Enum.PartType.Cylinder
		rim.Orientation = Vector3.new(0, 0, 90)
		
		-- Tower battlements (small merlons on top)
		local towerMerlonCount = 8
		for mi = 0, towerMerlonCount - 1, 2 do
			local mAngle = mi / towerMerlonCount * math.pi * 2
			local mDist = GATE_TOWER_RADIUS + 0.5
			local mmx = towerX + math.cos(mAngle) * mDist
			local mmz = towerZ + math.sin(mAngle) * mDist
			createPart("TowerMerlon", structuresFolder,
				Vector3.new(3, 5, 3),
				Vector3.new(mmx, towerY + GATE_TOWER_HEIGHT + 3, mmz),
				wallStoneDark, Enum.Material.Cobblestone)
		end
		
		-- Conical roof on tower
		local roofLayers = 8
		local roofH = 20
		local roofBaseR = GATE_TOWER_RADIUS + 2
		for li = 0, roofLayers do
			local frac = li / roofLayers
			local layerR = roofBaseR * (1 - frac * 0.92)
			local layerH = roofH / roofLayers
			local layerY = towerY + GATE_TOWER_HEIGHT + 1 + li * layerH + layerH/2
			local roofLayer = createPart("GateTowerRoofLayer", structuresFolder,
				Vector3.new(layerH, layerR * 2, layerR * 2),
				Vector3.new(towerX, layerY, towerZ),
				wallRoofSlate, Enum.Material.Slate)
			roofLayer.Shape = Enum.PartType.Cylinder
			roofLayer.Orientation = Vector3.new(0, 0, 90)
		end
		
		-- Arrow slits on the tower (3 levels)
		for level = 1, 3 do
			local slitY = towerY + level * (GATE_TOWER_HEIGHT / 4)
			-- Facing outward
			local outDir = Vector3.new(math.cos(ga), 0, math.sin(ga))
			local slitX = towerX + outDir.X * (GATE_TOWER_RADIUS + 0.5)
			local slitZ = towerZ + outDir.Z * (GATE_TOWER_RADIUS + 0.5)
			createPart("ArrowSlit", structuresFolder,
				Vector3.new(1.5, 5, 1),
				Vector3.new(slitX, slitY, slitZ),
				wallTorchGlow, Enum.Material.Neon)
		end
		
		-- Torch on gate tower (one on the outside face)
		local torchOutDist = GATE_TOWER_RADIUS + 2
		local gtFlameX = towerX + math.cos(ga) * torchOutDist
		local gtFlameZ = towerZ + math.sin(ga) * torchOutDist
		local gtFlame = createPart("GateTowerTorch", structuresFolder,
			Vector3.new(2.5, 3, 2.5),
			Vector3.new(gtFlameX, towerY + GATE_TOWER_HEIGHT * 0.6, gtFlameZ),
			wallTorchGlow, Enum.Material.Neon)
		gtFlame.Shape = Enum.PartType.Ball
		
		local gtLight = Instance.new("PointLight")
		gtLight.Color = wallTorchGlow
		gtLight.Brightness = 2
		gtLight.Range = 50
		gtLight.Parent = gtFlame
		
		local gtFire = Instance.new("Fire")
		gtFire.Size = 5
		gtFire.Heat = 10
		gtFire.Color = Color3.fromRGB(255, 180, 60)
		gtFire.SecondaryColor = Color3.fromRGB(255, 80, 20)
		gtFire.Parent = gtFlame
	end
	
	-- === ENHANCED GATE ARCH & INTERACTIVE DOORS ===
	local gatehouseH = WALL_HEIGHT
	local doorH = 24
	local doorW = GATE_HALF_WIDTH -- 18 studs wide
	local doorThick = 2
	
	-- The solid stone wall above the doors filling the gap
	local archWallH = gatehouseH - doorH
	local archCFrame = CFrame.new(gateX, gateY + doorH + archWallH/2, gateZ) * CFrame.Angles(0, -ga + math.pi/2, 0)
	local archWall = createPart("GateArchWall", structuresFolder,
		Vector3.new(GATE_HALF_WIDTH * 2, archWallH, WALL_THICKNESS),
		Vector3.new(0,0,0),
		wallStoneMain, Enum.Material.Cobblestone)
	archWall.CFrame = archCFrame
	
	-- Decorative Lintel (trim above the doors)
	local lintelCFrame = CFrame.new(gateX, gateY + doorH + 2, gateZ) * CFrame.Angles(0, -ga + math.pi/2, 0)
	local lintel = createPart("GateLintel", structuresFolder,
		Vector3.new(GATE_HALF_WIDTH * 2 + 2, 4, WALL_THICKNESS + 2),
		Vector3.new(0,0,0),
		wallStoneDark, Enum.Material.Cobblestone)
	lintel.CFrame = lintelCFrame
	
	-- Interactive Wooden Doors (Enhanced double doors with details)
	local doorPartsLeft = {}
	local doorPartsRight = {}
	
	-- Calculate exact hinges (doorW = 18, so total opening is 36. Hinges are at -18 and +18)
	local leftDoorPivot = CFrame.new(gateX, gateY + doorH/2, gateZ) * CFrame.Angles(0, -ga + math.pi/2, 0) * CFrame.new(-doorW, 0, 0)
	local rightDoorPivot = CFrame.new(gateX, gateY + doorH/2, gateZ) * CFrame.Angles(0, -ga + math.pi/2, 0) * CFrame.new(doorW, 0, 0)
	
	-- Function to create door elements
	local function addDoorPart(name, size, cframeOffset, pivot, color, mat, collection)
		local part = createPart(name, structuresFolder, size, Vector3.new(), color, mat)
		part.CFrame = pivot * cframeOffset
		table.insert(collection, part)
		return part
	end
	
	local woodColor = Color3.fromRGB(65, 40, 20)
	local metalColor = Color3.fromRGB(40, 40, 40)
	
	-- LEFT DOOR
	local leftMain = addDoorPart("GateDoorLeft", Vector3.new(doorW, doorH, doorThick), CFrame.new(doorW/2, 0, 0), leftDoorPivot, woodColor, Enum.Material.WoodPlanks, doorPartsLeft)
	addDoorPart("MetalBand", Vector3.new(doorW + 0.2, 3, doorThick + 0.2), CFrame.new(doorW/2, doorH/2 - 5, 0), leftDoorPivot, metalColor, Enum.Material.Metal, doorPartsLeft)
	addDoorPart("MetalBand", Vector3.new(doorW + 0.2, 3, doorThick + 0.2), CFrame.new(doorW/2, -doorH/2 + 5, 0), leftDoorPivot, metalColor, Enum.Material.Metal, doorPartsLeft)
	addDoorPart("CenterStrip", Vector3.new(1.5, doorH + 0.2, doorThick + 0.4), CFrame.new(doorW - 0.75, 0, 0), leftDoorPivot, metalColor, Enum.Material.Metal, doorPartsLeft)
	
	-- RIGHT DOOR
	local rightMain = addDoorPart("GateDoorRight", Vector3.new(doorW, doorH, doorThick), CFrame.new(-doorW/2, 0, 0), rightDoorPivot, woodColor, Enum.Material.WoodPlanks, doorPartsRight)
	addDoorPart("MetalBand", Vector3.new(doorW + 0.2, 3, doorThick + 0.2), CFrame.new(-doorW/2, doorH/2 - 5, 0), rightDoorPivot, metalColor, Enum.Material.Metal, doorPartsRight)
	addDoorPart("MetalBand", Vector3.new(doorW + 0.2, 3, doorThick + 0.2), CFrame.new(-doorW/2, -doorH/2 + 5, 0), rightDoorPivot, metalColor, Enum.Material.Metal, doorPartsRight)
	addDoorPart("CenterStrip", Vector3.new(1.5, doorH + 0.2, doorThick + 0.4), CFrame.new(-doorW + 0.75, 0, 0), rightDoorPivot, metalColor, Enum.Material.Metal, doorPartsRight)
	
	-- Add ProximityPrompt to the gate
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open Gates"
	prompt.ObjectText = "Castle Gate"
	prompt.MaxActivationDistance = 25
	prompt.RequiresLineOfSight = false
	prompt.Parent = leftMain
	
	-- Animate gates smoothly
	local isOpen = false
	local TweenService = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	
	-- Store initial relative CFrames
	local leftOffsets = {}
	for _, p in ipairs(doorPartsLeft) do leftOffsets[p] = leftDoorPivot:ToObjectSpace(p.CFrame) end
	local rightOffsets = {}
	for _, p in ipairs(doorPartsRight) do rightOffsets[p] = rightDoorPivot:ToObjectSpace(p.CFrame) end
	
	prompt.Triggered:Connect(function()
		if prompt.ActionText == "Opening..." or prompt.ActionText == "Closing..." then return end
		isOpen = not isOpen
		prompt.ActionText = isOpen and "Closing..." or "Opening..."
		
		-- Swing doors 90 degrees inwards
		local targetAngle = isOpen and math.pi/2 or 0
		local newLeftPivot = leftDoorPivot * CFrame.Angles(0, targetAngle, 0)
		local newRightPivot = rightDoorPivot * CFrame.Angles(0, -targetAngle, 0)
		
		for _, p in ipairs(doorPartsLeft) do
			TweenService:Create(p, tweenInfo, { CFrame = newLeftPivot * leftOffsets[p] }):Play()
		end
		for _, p in ipairs(doorPartsRight) do
			TweenService:Create(p, tweenInfo, { CFrame = newRightPivot * rightOffsets[p] }):Play()
		end
		
		task.delay(1.5, function()
			prompt.ActionText = isOpen and "Close Gates" or "Open Gates"
		end)
	end)
	
	-- Banner / flag at each gate
	for side = -1, 1, 2 do
		local bannerX = gateX + math.cos(perpAngle) * (GATE_HALF_WIDTH + GATE_TOWER_RADIUS/2) * side
		local bannerZ = gateZ + math.sin(perpAngle) * (GATE_HALF_WIDTH + GATE_TOWER_RADIUS/2) * side
		local bannerY = getGroundY(bannerX, bannerZ)
		
		-- Flag pole
		createPart("FlagPole", structuresFolder,
			Vector3.new(1, 15, 1),
			Vector3.new(bannerX, bannerY + GATE_TOWER_HEIGHT + 10, bannerZ),
			wallTorchPole, Enum.Material.Metal)
		
		-- Flag fabric
		local flagW, flagD
		if math.abs(math.cos(ga)) > 0.5 then
			flagW = 8; flagD = 1
		else
			flagW = 1; flagD = 8
		end
		createPart("GateFlag", structuresFolder,
			Vector3.new(flagW, 6, flagD),
			Vector3.new(bannerX, bannerY + GATE_TOWER_HEIGHT + 20, bannerZ),
			wallBannerRed, Enum.Material.Fabric)
	end
end

-- ==========================================
-- Central Castle (Enhanced Medieval Fortress)
-- ==========================================
local function spawnCastle(x, z)
	local y = getGroundY(x, z)
	local castle = Instance.new("Model", structuresFolder)
	castle.Name = "CentralCastle"

	-- Color Palette
	local stoneMain   = Color3.fromRGB(175, 155, 125)   -- Warm sandstone walls
	local stoneDark   = Color3.fromRGB(120, 105, 85)     -- Darker accent stone
	local stoneLight  = Color3.fromRGB(200, 185, 160)    -- Light trim stone
	local roofSlate   = Color3.fromRGB(55, 65, 80)       -- Blue-grey slate roofs
	local roofDark    = Color3.fromRGB(40, 48, 60)       -- Darker roof accent
	local woodDark    = Color3.fromRGB(60, 40, 22)       -- Dark timber
	local goldAccent  = Color3.fromRGB(210, 175, 55)     -- Gold decorative tips
	local torchGlow   = Color3.fromRGB(255, 160, 40)     -- Warm torch light
	local gateIron    = Color3.fromRGB(50, 50, 55)       -- Iron portcullis

	local matStone    = Enum.Material.Cobblestone
	local matBrick    = Enum.Material.Brick
	local matSlate    = Enum.Material.Slate
	local matWood     = Enum.Material.WoodPlanks

	-- ===== RAISED STONE PLATFORM / FOUNDATION =====
	createPart("CastlePlatform", castle, Vector3.new(250, 6, 250), Vector3.new(x, y + 3, z), stoneDark, matStone)
	createPart("PlatformTrim", castle, Vector3.new(254, 2, 254), Vector3.new(x, y + 1, z), stoneLight, matBrick)

	-- ===== OUTER CURTAIN WALLS =====
	local wallH = 50
	local wallThick = 8
	local outerHalf = 110 -- Half-width of the outer wall square

	-- Wall segments (leaving gaps for gatehouses)
	-- Each wall side: two segments flanking the central gate opening (gate gap = 20 studs)
	local gateGap = 10 -- half the gate opening
	local segLen = outerHalf - gateGap -- length of each wall segment

	-- North wall (+Z side) - two segments
	createPart("WallN_L", castle, Vector3.new(segLen, wallH, wallThick), Vector3.new(x - outerHalf + segLen/2, y + wallH/2 + 6, z + outerHalf), stoneMain, matBrick)
	createPart("WallN_R", castle, Vector3.new(segLen, wallH, wallThick), Vector3.new(x + outerHalf - segLen/2, y + wallH/2 + 6, z + outerHalf), stoneMain, matBrick)
	-- South wall (-Z side)
	createPart("WallS_L", castle, Vector3.new(segLen, wallH, wallThick), Vector3.new(x - outerHalf + segLen/2, y + wallH/2 + 6, z - outerHalf), stoneMain, matBrick)
	createPart("WallS_R", castle, Vector3.new(segLen, wallH, wallThick), Vector3.new(x + outerHalf - segLen/2, y + wallH/2 + 6, z - outerHalf), stoneMain, matBrick)
	-- East wall (+X side)
	createPart("WallE_L", castle, Vector3.new(wallThick, wallH, segLen), Vector3.new(x + outerHalf, y + wallH/2 + 6, z - outerHalf + segLen/2), stoneMain, matBrick)
	createPart("WallE_R", castle, Vector3.new(wallThick, wallH, segLen), Vector3.new(x + outerHalf, y + wallH/2 + 6, z + outerHalf - segLen/2), stoneMain, matBrick)
	-- West wall (-X side)
	createPart("WallW_L", castle, Vector3.new(wallThick, wallH, segLen), Vector3.new(x - outerHalf, y + wallH/2 + 6, z - outerHalf + segLen/2), stoneMain, matBrick)
	createPart("WallW_R", castle, Vector3.new(wallThick, wallH, segLen), Vector3.new(x - outerHalf, y + wallH/2 + 6, z + outerHalf - segLen/2), stoneMain, matBrick)

	-- ===== BATTLEMENTS / CRENELLATIONS on outer walls =====
	local merlonW = 4
	local merlonH = 6
	local merlonD = wallThick + 1
	local merlonSpacing = 8

	-- Add crenellations along each wall segment
	for side = 1, 4 do
		for seg = 1, 2 do
			local segStart, segEnd
			if seg == 1 then
				segStart = -outerHalf
				segEnd = -gateGap
			else
				segStart = gateGap
				segEnd = outerHalf
			end

			for pos = segStart + merlonW/2, segEnd - merlonW/2, merlonSpacing do
				local mx, mz
				if side == 1 then     -- North
					mx = x + pos; mz = z + outerHalf
				elseif side == 2 then -- South
					mx = x + pos; mz = z - outerHalf
				elseif side == 3 then -- East
					mx = x + outerHalf; mz = z + pos
				else                  -- West
					mx = x - outerHalf; mz = z + pos
				end
				local mSize
				if side <= 2 then
					mSize = Vector3.new(merlonW, merlonH, merlonD)
				else
					mSize = Vector3.new(merlonD, merlonH, merlonW)
				end
				createPart("Merlon", castle, mSize, Vector3.new(mx, y + wallH + 6 + merlonH/2, mz), stoneDark, matStone)
			end
		end
	end

	-- ===== CORNER TOWERS (4 large round towers) =====
	local towerR = 12
	local towerH = 60
	local cornerPositions = {
		{-1, -1}, {-1, 1}, {1, -1}, {1, 1}
	}
	for _, cp in ipairs(cornerPositions) do
		local tx = x + cp[1] * outerHalf
		local tz = z + cp[2] * outerHalf

		-- Tower body (cylinder)
		local tower = createPart("CornerTower", castle, Vector3.new(towerH, towerR * 2, towerR * 2), Vector3.new(tx, y + towerH/2 + 6, tz), stoneMain, matBrick)
		tower.Shape = Enum.PartType.Cylinder
		tower.Orientation = Vector3.new(0, 0, 90)

		-- Tower top rim
		local rim = createPart("TowerRim", castle, Vector3.new(4, towerR * 2 + 4, towerR * 2 + 4), Vector3.new(tx, y + towerH + 4, tz), stoneDark, matStone)
		rim.Shape = Enum.PartType.Cylinder
		rim.Orientation = Vector3.new(0, 0, 90)

		-- Conical roof (cone made from stacked cylinders getting smaller)
		local roofBaseR = towerR + 2
		local roofH = 28
		local roofLayers = 10
		for li = 0, roofLayers do
			local frac = li / roofLayers
			local layerR = roofBaseR * (1 - frac * 0.92)
			local layerH = roofH / roofLayers
			local layerY = y + towerH + 6 + li * layerH + layerH/2
			local roofLayer = createPart("TowerRoofLayer", castle, Vector3.new(layerH, layerR * 2, layerR * 2), Vector3.new(tx, layerY, tz), roofSlate, matSlate)
			roofLayer.Shape = Enum.PartType.Cylinder
			roofLayer.Orientation = Vector3.new(0, 0, 90)
		end

		-- Gold finial on top
		local finial = createPart("Finial", castle, Vector3.new(2, 2, 2), Vector3.new(tx, y + towerH + 6 + roofH + 2, tz), goldAccent, Enum.Material.Neon)
		finial.Shape = Enum.PartType.Ball

		-- Tower windows (arrow slits) - 3 levels
		for level = 1, 3 do
			local winY = y + 6 + level * (towerH / 4)
			-- Place a slit facing outward
			local slitDir = Vector3.new(cp[1], 0, cp[2]).Unit
			local slitX = tx + slitDir.X * (towerR + 0.5)
			local slitZ = tz + slitDir.Z * (towerR + 0.5)
			createPart("ArrowSlit", castle, Vector3.new(1.5, 5, 1), Vector3.new(slitX, winY, slitZ), torchGlow, Enum.Material.Neon)
		end
	end

	-- ===== 4 GATEHOUSES (aligned to the 4 roads) =====
	local gatePositions = {
		{dir = "N", dx = 0,  dz = 1,  rotY = 0},
		{dir = "S", dx = 0,  dz = -1, rotY = 0},
		{dir = "E", dx = 1,  dz = 0,  rotY = 90},
		{dir = "W", dx = -1, dz = 0,  rotY = 90},
	}

	for _, gp in ipairs(gatePositions) do
		local gx = x + gp.dx * outerHalf
		local gz = z + gp.dz * outerHalf

		-- Gate arch top (lintel)
		local lintelW, lintelH, lintelD
		if gp.rotY == 0 then
			lintelW = gateGap * 2 + 4
			lintelH = 8
			lintelD = wallThick + 4
		else
			lintelW = wallThick + 4
			lintelH = 8
			lintelD = gateGap * 2 + 4
		end
		createPart("GateLintel", castle, Vector3.new(lintelW, lintelH, lintelD), Vector3.new(gx, y + wallH + 2, gz), stoneDark, matStone)

		-- Gate flanking pillars (two small towers beside each gate)
		for side = -1, 1, 2 do
			local px, pz
			if gp.rotY == 0 then
				px = gx + side * (gateGap + 3)
				pz = gz
			else
				px = gx
				pz = gz + side * (gateGap + 3)
			end

			local pillarH = 50
			local pillarR = 5
			local pillar = createPart("GatePillar", castle, Vector3.new(pillarH, pillarR * 2, pillarR * 2), Vector3.new(px, y + pillarH/2 + 6, pz), stoneMain, matBrick)
			pillar.Shape = Enum.PartType.Cylinder
			pillar.Orientation = Vector3.new(0, 0, 90)

			-- Small conical roof on gate pillar
			local pRoofLayers = 6
			local pRoofH = 14
			for li = 0, pRoofLayers do
				local frac = li / pRoofLayers
				local lr = (pillarR + 1) * (1 - frac * 0.9)
				local lh = pRoofH / pRoofLayers
				local ly = y + pillarH + 6 + li * lh + lh/2
				local prl = createPart("GateRoofLayer", castle, Vector3.new(lh, lr * 2, lr * 2), Vector3.new(px, ly, pz), roofDark, matSlate)
				prl.Shape = Enum.PartType.Cylinder
				prl.Orientation = Vector3.new(0, 0, 90)
			end
		end

		-- Iron portcullis (gate grid)
		local portW, portH, portD
		if gp.rotY == 0 then
			portW = gateGap * 2 - 2
			portH = wallH - 10
			portD = 1.5
		else
			portW = 1.5
			portH = wallH - 10
			portD = gateGap * 2 - 2
		end
		createPart("Portcullis", castle, Vector3.new(portW, portH, portD), Vector3.new(gx, y + portH/2 + 6, gz), gateIron, Enum.Material.DiamondPlate)

		-- Torch lights at each gate
		for side = -1, 1, 2 do
			local tlx, tlz
			if gp.rotY == 0 then
				tlx = gx + side * (gateGap - 1)
				tlz = gz
			else
				tlx = gx
				tlz = gz + side * (gateGap - 1)
			end
			local torch = createPart("GateTorch", castle, Vector3.new(2, 2, 2), Vector3.new(tlx, y + wallH - 4, tlz), torchGlow, Enum.Material.Neon)
			torch.Shape = Enum.PartType.Ball

			-- Add a PointLight for atmosphere
			local light = Instance.new("PointLight")
			light.Color = torchGlow
			light.Brightness = 2
			light.Range = 30
			light.Parent = torch
		end
	end

	-- ===== INNER BAILEY WALLS =====
	local innerHalf = 60
	local innerWallH = 35
	local innerWallThick = 6

	-- Inner walls (solid, no gaps - the keep courtyard)
	createPart("InnerWallN", castle, Vector3.new(innerHalf * 2, innerWallH, innerWallThick), Vector3.new(x, y + innerWallH/2 + 6, z + innerHalf), stoneDark, matStone)
	createPart("InnerWallS", castle, Vector3.new(innerHalf * 2, innerWallH, innerWallThick), Vector3.new(x, y + innerWallH/2 + 6, z - innerHalf), stoneDark, matStone)
	createPart("InnerWallE", castle, Vector3.new(innerWallThick, innerWallH, innerHalf * 2), Vector3.new(x + innerHalf, y + innerWallH/2 + 6, z), stoneDark, matStone)
	createPart("InnerWallW", castle, Vector3.new(innerWallThick, innerWallH, innerHalf * 2), Vector3.new(x - innerHalf, y + innerWallH/2 + 6, z), stoneDark, matStone)

	-- Inner corner turrets (smaller)
	for _, cp in ipairs(cornerPositions) do
		local itx = x + cp[1] * innerHalf
		local itz = z + cp[2] * innerHalf
		local itH = 42
		local itR = 5

		local it = createPart("InnerTurret", castle, Vector3.new(itH, itR * 2, itR * 2), Vector3.new(itx, y + itH/2 + 6, itz), stoneDark, matStone)
		it.Shape = Enum.PartType.Cylinder
		it.Orientation = Vector3.new(0, 0, 90)

		-- Tiny conical roof
		for li = 0, 5 do
			local frac = li / 5
			local lr = (itR + 1) * (1 - frac * 0.9)
			local lh = 10 / 5
			local ly = y + itH + 6 + li * lh + lh/2
			local trl = createPart("InnerTurretRoof", castle, Vector3.new(lh, lr * 2, lr * 2), Vector3.new(itx, ly, itz), roofSlate, matSlate)
			trl.Shape = Enum.PartType.Cylinder
			trl.Orientation = Vector3.new(0, 0, 90)
		end
	end

	-- ===== GRAND CENTRAL KEEP (Multi-tiered) =====
	-- Tier 1: Base (widest)
	local keepW1 = 70
	local keepH1 = 55
	createPart("KeepBase", castle, Vector3.new(keepW1, keepH1, keepW1), Vector3.new(x, y + keepH1/2 + 6, z), stoneLight, matBrick)
	-- Decorative band
	createPart("KeepBand1", castle, Vector3.new(keepW1 + 2, 3, keepW1 + 2), Vector3.new(x, y + keepH1 + 6, z), stoneDark, matStone)

	-- Tier 2: Middle
	local keepW2 = 50
	local keepH2 = 45
	createPart("KeepMid", castle, Vector3.new(keepW2, keepH2, keepW2), Vector3.new(x, y + keepH1 + keepH2/2 + 6, z), stoneMain, matBrick)
	createPart("KeepBand2", castle, Vector3.new(keepW2 + 2, 3, keepW2 + 2), Vector3.new(x, y + keepH1 + keepH2 + 6, z), stoneDark, matStone)

	-- Tier 3: Upper
	local keepW3 = 34
	local keepH3 = 35
	createPart("KeepUpper", castle, Vector3.new(keepW3, keepH3, keepW3), Vector3.new(x, y + keepH1 + keepH2 + keepH3/2 + 6, z), stoneLight, matBrick)
	createPart("KeepBand3", castle, Vector3.new(keepW3 + 2, 3, keepW3 + 2), Vector3.new(x, y + keepH1 + keepH2 + keepH3 + 6, z), stoneDark, matStone)

	-- Grand spire on top of keep (tall conical)
	local spireBaseR = 10
	local spireH = 40
	local spireLayers = 14
	for li = 0, spireLayers do
		local frac = li / spireLayers
		local lr = spireBaseR * (1 - frac * 0.95)
		local lh = spireH / spireLayers
		local ly = y + keepH1 + keepH2 + keepH3 + 6 + li * lh + lh/2
		local sl = createPart("SpireLayer", castle, Vector3.new(lh, lr * 2, lr * 2), Vector3.new(x, ly, z), roofSlate, matSlate)
		sl.Shape = Enum.PartType.Cylinder
		sl.Orientation = Vector3.new(0, 0, 90)
	end

	-- Gold orb at the very top
	local topY = y + keepH1 + keepH2 + keepH3 + spireH + 8
	local orb = createPart("GoldOrb", castle, Vector3.new(4, 4, 4), Vector3.new(x, topY, z), goldAccent, Enum.Material.Neon)
	orb.Shape = Enum.PartType.Ball

	-- ===== KEEP CORNER SPIRES (4 mini towers on keep base) =====
	local keepSpireDist = keepW1/2 - 2
	for _, cp in ipairs(cornerPositions) do
		local ksx = x + cp[1] * keepSpireDist
		local ksz = z + cp[2] * keepSpireDist
		local ksH = 55

		local ks = createPart("KeepSpire", castle, Vector3.new(ksH, 8, 8), Vector3.new(ksx, y + ksH/2 + 6, ksz), stoneMain, matBrick)
		ks.Shape = Enum.PartType.Cylinder
		ks.Orientation = Vector3.new(0, 0, 90)

		-- Mini conical roof
		for li = 0, 5 do
			local frac = li / 5
			local lr = 5.5 * (1 - frac * 0.9)
			local lh = 12 / 5
			local ly = y + ksH + 6 + li * lh + lh/2
			local krl = createPart("KeepSpireRoof", castle, Vector3.new(lh, lr * 2, lr * 2), Vector3.new(ksx, ly, ksz), roofDark, matSlate)
			krl.Shape = Enum.PartType.Cylinder
			krl.Orientation = Vector3.new(0, 0, 90)
		end

		-- Gold finial
		createPart("KeepSpireFinial", castle, Vector3.new(1.5, 1.5, 1.5), Vector3.new(ksx, y + ksH + 6 + 13, ksz), goldAccent, Enum.Material.Neon)
	end

	-- ===== KEEP WINDOWS (Warm glowing) =====
	-- Windows on each side of each tier
	local tiers = {
		{h = keepH1, w = keepW1, baseY = y + 6},
		{h = keepH2, w = keepW2, baseY = y + keepH1 + 6},
		{h = keepH3, w = keepW3, baseY = y + keepH1 + keepH2 + 6},
	}
	for _, tier in ipairs(tiers) do
		local numWin = math.max(2, math.floor(tier.w / 12))
		local winSpacing = tier.w / (numWin + 1)
		for winIdx = 1, numWin do
			local winOffset = -tier.w/2 + winIdx * winSpacing
			local winY = tier.baseY + tier.h * 0.6
			-- North and South facing windows
			for _, faceZ in ipairs({1, -1}) do
				createPart("KeepWindow", castle, Vector3.new(3, 5, 1), Vector3.new(x + winOffset, winY, z + faceZ * (tier.w/2 + 0.5)), torchGlow, Enum.Material.Neon)
			end
			-- East and West facing windows
			for _, faceX in ipairs({1, -1}) do
				createPart("KeepWindow", castle, Vector3.new(1, 5, 3), Vector3.new(x + faceX * (tier.w/2 + 0.5), winY, z + winOffset), torchGlow, Enum.Material.Neon)
			end
		end
	end

	-- ===== WALL-MOUNTED TORCHES =====
	local torchPositions = {
		-- Outer wall torches (midpoints of each wall segment)
		{x - outerHalf/2, z + outerHalf},
		{x + outerHalf/2, z + outerHalf},
		{x - outerHalf/2, z - outerHalf},
		{x + outerHalf/2, z - outerHalf},
		{x + outerHalf, z - outerHalf/2},
		{x + outerHalf, z + outerHalf/2},
		{x - outerHalf, z - outerHalf/2},
		{x - outerHalf, z + outerHalf/2},
	}
	for _, tp in ipairs(torchPositions) do
		local torch = createPart("WallTorch", castle, Vector3.new(2, 2, 2), Vector3.new(tp[1], y + wallH + 4, tp[2]), torchGlow, Enum.Material.Neon)
		torch.Shape = Enum.PartType.Ball

		local light = Instance.new("PointLight")
		light.Color = torchGlow
		light.Brightness = 1.5
		light.Range = 40
		light.Parent = torch
	end

	-- ===== DECORATIVE BANNERS (colored blocks on walls) =====
	local bannerCol = Color3.fromRGB(140, 30, 30) -- Deep crimson
	for _, gp in ipairs(gatePositions) do
		local bx = x + gp.dx * outerHalf
		local bz = z + gp.dz * outerHalf
		local bW, bH, bD
		if gp.rotY == 0 then
			bW = 5; bH = 12; bD = 0.5
		else
			bW = 0.5; bH = 12; bD = 5
		end
		-- Banner on each side of gate
		for side = -1, 1, 2 do
			local banX, banZ
			if gp.rotY == 0 then
				banX = bx + side * (gateGap + 10)
				banZ = bz
			else
				banX = bx
				banZ = bz + side * (gateGap + 10)
			end
			createPart("Banner", castle, Vector3.new(bW, bH, bD), Vector3.new(banX, y + wallH - 2, banZ), bannerCol, Enum.Material.Fabric)
		end
	end
end
spawnCastle(0, 0)

print("3/4 Generating Procedural Houses (With Perfect Roofs & Roman Layout)...")
local function spawnHouse(hx, hz, rotationAngle)
	local hy, hMat = getGroundY(hx, hz)
	
	-- Avoid roads and water
	if hMat == Enum.Material.Pavement or hMat == Enum.Material.Cobblestone or hMat == Enum.Material.Mud or hy <= WATER_LEVEL then return end
	
	local houseModel = Instance.new("Model", structuresFolder)
	houseModel.Name = "House"
	
	local type = math.random(1, 3)
	local colBase = Color3.fromRGB(math.random(140, 180), math.random(130, 170), math.random(120, 160))
	local colRoof = Color3.fromRGB(math.random(80, 120), math.random(40, 60), math.random(30, 50))
	local rot = CFrame.Angles(0, rotationAngle, 0)
	
	-- Roof generation helper (perfect A-frame using tilted blocks with Viking crosses)
	local function createAFrameRoof(w, h, d, roofAngle)
		local rW = (w/2) / math.cos(roofAngle) + 2
		-- More overhang (d+4 instead of d+2)
		local r1 = createPart("Roof1", houseModel, Vector3.new(rW, 2, d+4), Vector3.new(0,0,0), colRoof, Enum.Material.Wood)
		local r2 = createPart("Roof2", houseModel, Vector3.new(rW, 2, d+4), Vector3.new(0,0,0), colRoof, Enum.Material.Wood)
		
		local yShift = (rW / 2) * math.sin(roofAngle)
		local xShift = (w / 4) + 0.5
		
		local p1 = rot * Vector3.new(-xShift, h + yShift, 0)
		local p2 = rot * Vector3.new(xShift, h + yShift, 0)
		
		r1.CFrame = CFrame.new(hx + p1.X, hy + p1.Y, hz + p1.Z) * rot * CFrame.Angles(0, 0, roofAngle)
		r2.CFrame = CFrame.new(hx + p2.X, hy + p2.Y, hz + p2.Z) * rot * CFrame.Angles(0, 0, -roofAngle)
		
		-- Viking Roof Cross Beams at the gables (front and back)
		local beamW = 1.2
		local crossLength = rW + 6 -- Extend past the roof for the classic X shape
		for _, zDir in ipairs({1, -1}) do
			local beam1 = createPart("CrossBeam", houseModel, Vector3.new(beamW, crossLength, beamW), Vector3.new(0,0,0), Color3.fromRGB(50, 30, 15), Enum.Material.Wood)
			local beam2 = createPart("CrossBeam", houseModel, Vector3.new(beamW, crossLength, beamW), Vector3.new(0,0,0), Color3.fromRGB(50, 30, 15), Enum.Material.Wood)
			
			local cZ = (d/2 + 1.8) * zDir
			local bp1 = rot * Vector3.new(-xShift, h + yShift, cZ)
			local bp2 = rot * Vector3.new(xShift, h + yShift, cZ)
			
			beam1.CFrame = CFrame.new(hx + bp1.X, hy + bp1.Y, hz + bp1.Z) * rot * CFrame.Angles(0, 0, roofAngle)
			beam2.CFrame = CFrame.new(hx + bp2.X, hy + bp2.Y, hz + bp2.Z) * rot * CFrame.Angles(0, 0, -roofAngle)
		end
	end
	
	local function createVikingBase(w, h, d, baseMat)
		-- 1. Main body (wooden planks)
		local base = createPart("Base", houseModel, Vector3.new(w, h, d), Vector3.new(0,0,0), colBase, baseMat)
		local bP = rot * Vector3.new(0, h/2, 0)
		base.CFrame = CFrame.new(hx + bP.X, hy + bP.Y, hz + bP.Z) * rot
		
		-- 2. Foundation (wider stone base)
		local foundH = 3
		local foundation = createPart("Foundation", houseModel, Vector3.new(w+1, foundH, d+1), Vector3.new(0,0,0), Color3.fromRGB(90, 95, 100), Enum.Material.Cobblestone)
		local fP = rot * Vector3.new(0, foundH/2, 0)
		foundation.CFrame = CFrame.new(hx + fP.X, hy + fP.Y, hz + fP.Z) * rot
		
		-- 3. Timber Framing (Corner Pillars and Horizontal Beams)
		local logCol = Color3.fromRGB(60, 40, 25)
		local pW = 1.8
		
		-- Vertical corner pillars
		for _, px in ipairs({1, -1}) do
			for _, pz in ipairs({1, -1}) do
				local pillar = createPart("Pillar", houseModel, Vector3.new(pW, h, pW), Vector3.new(0,0,0), logCol, Enum.Material.Wood)
				local pPos = rot * Vector3.new((w/2 + 0.1) * px, h/2, (d/2 + 0.1) * pz)
				pillar.CFrame = CFrame.new(hx + pPos.X, hy + pPos.Y, hz + pPos.Z) * rot
			end
		end
		
		-- Horizontal beams (top and bottom)
		for _, hzY in ipairs({foundH + 0.5, h - 0.5}) do
			-- Along X axis (front and back)
			for _, pz in ipairs({1, -1}) do
				local hBeamX = createPart("BeamX", houseModel, Vector3.new(w, pW, pW), Vector3.new(0,0,0), logCol, Enum.Material.Wood)
				local bpX = rot * Vector3.new(0, hzY, (d/2 + 0.1) * pz)
				hBeamX.CFrame = CFrame.new(hx + bpX.X, hy + bpX.Y, hz + bpX.Z) * rot
			end
			-- Along Z axis (sides)
			for _, px in ipairs({1, -1}) do
				local hBeamZ = createPart("BeamZ", houseModel, Vector3.new(pW, pW, d), Vector3.new(0,0,0), logCol, Enum.Material.Wood)
				local bpZ = rot * Vector3.new((w/2 + 0.1) * px, hzY, 0)
				hBeamZ.CFrame = CFrame.new(hx + bpZ.X, hy + bpZ.Y, hz + bpZ.Z) * rot
			end
		end
		
		-- 4. Door (Facing local +Z)
		local doorW, doorH = 4.5, 7.5
		local door = createPart("Door", houseModel, Vector3.new(doorW, doorH, 1), Vector3.new(0,0,0), Color3.fromRGB(45, 25, 10), Enum.Material.WoodPlanks)
		local doorPos = rot * Vector3.new(0, foundH + doorH/2, d/2 + 0.6)
		door.CFrame = CFrame.new(hx + doorPos.X, hy + doorPos.Y, hz + doorPos.Z) * rot
		
		-- 5. Windows (Glowing warm light)
		local winW, winH = 2.5, 3
		local winCol = Color3.fromRGB(255, 180, 50)
		local winMat = Enum.Material.Neon
		-- Front windows
		for _, wx in ipairs({1, -1}) do
			local win = createPart("Window", houseModel, Vector3.new(winW, winH, 1), Vector3.new(0,0,0), winCol, winMat)
			local wPos = rot * Vector3.new((w/3.5) * wx, foundH + doorH/2 + 1, d/2 + 0.51)
			win.CFrame = CFrame.new(hx + wPos.X, hy + wPos.Y, hz + wPos.Z) * rot
		end
	end
	
	if type == 1 then
		-- Standard Square House
		local w, h, d = 20, 16, 20
		createVikingBase(w, h, d, Enum.Material.WoodPlanks)
		createAFrameRoof(w, h, d, math.rad(42))
		
	elseif type == 2 then
		-- Longhouse
		local w, h, d = 20, 14, 34
		createVikingBase(w, h, d, Enum.Material.WoodPlanks)
		createAFrameRoof(w, h, d, math.rad(40))
		
	elseif type == 3 then
		-- Two Story
		local w, h, d = 24, 28, 24
		createVikingBase(w, h, d, Enum.Material.WoodPlanks)
		createAFrameRoof(w, h, d, math.rad(35))
	end
end

local function spawnHouseLine(startX, startZ, endX, endZ, stepSize, rotationAngle)
	if endX < startX or endZ < startZ then return end
	
	local cx, cz = startX, startZ
	local dist = math.sqrt((endX - startX)^2 + (endZ - startZ)^2)
	local steps = math.floor(dist / stepSize)
	
	local dx = (endX == startX) and 0 or (endX - startX) / dist * stepSize
	local dz = (endZ == startZ) and 0 or (endZ - startZ) / dist * stepSize
	
	for i = 0, steps do
		local hx = cx + i * dx
		local hz = cz + i * dz
		
		local vDist = math.sqrt(hx^2 + hz^2)
		-- Clear a larger 260 stud radius for the Expanded Central Castle
		if vDist > 260 and vDist < VILLAGE_RADIUS - 60 then
			if math.random() < 0.9 then -- 90% chance to spawn to leave some organic gaps
				local rx = hx + math.random(-1, 1)
				local rz = hz + math.random(-1, 1)
				spawnHouse(rx, rz, rotationAngle)
			end
		end
	end
end

local function spawnRomanMarketplace(cx, cz)
	local mSize = 140
	local y, _ = getGroundY(cx, cz)
	if y <= WATER_LEVEL then return end
	
	local market = Instance.new("Model", structuresFolder)
	market.Name = "RomanMarketplace"
	
	-- Plaza Floor (Marble/Smooth stone)
	local floorCol = Color3.fromRGB(220, 220, 215)
	local plaza = createPart("PlazaFloor", market, Vector3.new(mSize, 2, mSize), Vector3.new(cx, y + 1, cz), floorCol, Enum.Material.Marble)
	
	-- Colonnades (Perimeter columns)
	local colH = 18
	local colR = 1.5
	local colSpacing = 16
	for px = -mSize/2 + 5, mSize/2 - 5, colSpacing do
		for pz = -mSize/2 + 5, mSize/2 - 5, colSpacing do
			if px == -mSize/2 + 5 or px >= mSize/2 - 10 or pz == -mSize/2 + 5 or pz >= mSize/2 - 10 then
				local col = createPart("Column", market, Vector3.new(colH, colR*2, colR*2), Vector3.new(cx + px, y + 2 + colH/2, cz + pz), Color3.fromRGB(230, 230, 225), Enum.Material.Marble)
				col.Shape = Enum.PartType.Cylinder
				col.Orientation = Vector3.new(0, 0, 90)
				createPart("ColBase", market, Vector3.new(4, 2, 4), Vector3.new(cx + px, y + 3, cz + pz), Color3.fromRGB(200, 200, 195), Enum.Material.Marble)
				createPart("ColCapital", market, Vector3.new(4.5, 2, 4.5), Vector3.new(cx + px, y + 2 + colH, cz + pz), Color3.fromRGB(200, 200, 195), Enum.Material.Marble)
			end
		end
	end
	
	-- Roof over colonnade
	local roofThick = 2
	local roofDepth = 12
	createPart("ColRoofN", market, Vector3.new(mSize, roofThick, roofDepth), Vector3.new(cx, y + 2 + colH + 1, cz - mSize/2 + 5), Color3.fromRGB(150, 70, 50), Enum.Material.Brick)
	createPart("ColRoofS", market, Vector3.new(mSize, roofThick, roofDepth), Vector3.new(cx, y + 2 + colH + 1, cz + mSize/2 - 5), Color3.fromRGB(150, 70, 50), Enum.Material.Brick)
	createPart("ColRoofW", market, Vector3.new(roofDepth, roofThick, mSize - roofDepth*2), Vector3.new(cx - mSize/2 + 5, y + 2 + colH + 1, cz), Color3.fromRGB(150, 70, 50), Enum.Material.Brick)
	createPart("ColRoofE", market, Vector3.new(roofDepth, roofThick, mSize - roofDepth*2), Vector3.new(cx + mSize/2 - 5, y + 2 + colH + 1, cz), Color3.fromRGB(150, 70, 50), Enum.Material.Brick)

	-- Central Fountain
	local fR = 12
	local fBase = createPart("FountainBase", market, Vector3.new(3, fR*2, fR*2), Vector3.new(cx, y + 3.5, cz), Color3.fromRGB(180, 180, 170), Enum.Material.Cobblestone)
	fBase.Shape = Enum.PartType.Cylinder
	fBase.Orientation = Vector3.new(0, 0, 90)
	local fWater = createPart("FountainWater", market, Vector3.new(2.5, fR*2-2, fR*2-2), Vector3.new(cx, y + 4, cz), Color3.fromRGB(50, 150, 255), Enum.Material.Water)
	fWater.Shape = Enum.PartType.Cylinder
	fWater.Orientation = Vector3.new(0, 0, 90)
	local fPedestal = createPart("FountainPedestal", market, Vector3.new(12, 4, 4), Vector3.new(cx, y + 8, cz), Color3.fromRGB(200, 200, 190), Enum.Material.Marble)
	fPedestal.Shape = Enum.PartType.Cylinder
	fPedestal.Orientation = Vector3.new(0, 0, 90)
	local fTopWater = createPart("FountainTopWater", market, Vector3.new(1, 6, 6), Vector3.new(cx, y + 14, cz), Color3.fromRGB(50, 150, 255), Enum.Material.Water)
	fTopWater.Shape = Enum.PartType.Cylinder
	fTopWater.Orientation = Vector3.new(0, 0, 90)

	-- Market Stalls
	for _, sx in ipairs({-30, 30}) do
		for _, sz in ipairs({-30, 0, 30}) do
			local stallCol = Color3.fromRGB(math.random(100, 200), math.random(50, 150), math.random(50, 100))
			createPart("StallTable", market, Vector3.new(10, 3, 6), Vector3.new(cx + sx, y + 3.5, cz + sz), Color3.fromRGB(120, 80, 50), Enum.Material.WoodPlanks)
			local awning = createPart("StallAwning", market, Vector3.new(12, 1, 10), Vector3.new(cx + sx, y + 12, cz + sz + 2), stallCol, Enum.Material.Fabric)
			awning.Orientation = Vector3.new(-15, 0, 0)
			createPart("StallPole", market, Vector3.new(1, 10, 1), Vector3.new(cx + sx - 5, y + 7, cz + sz - 2), Color3.fromRGB(80, 50, 30), Enum.Material.Wood)
			createPart("StallPole", market, Vector3.new(1, 10, 1), Vector3.new(cx + sx + 5, y + 7, cz + sz - 2), Color3.fromRGB(80, 50, 30), Enum.Material.Wood)
		end
	end
end

-- Organize village into Roman Insulae (City Blocks) based on the 160-stud grid
for bx = -800, 800, 160 do
	for bz = -800, 800, 160 do
		
		local function getPadding(val)
			if val == 0 then return 32 end -- Main road is wider
			return 16 -- Secondary road
		end
		
		local minX = bx + getPadding(bx)
		local maxX = bx + 160 - getPadding(bx + 160)
		
		local minZ = bz + getPadding(bz)
		local maxZ = bz + 160 - getPadding(bz + 160)
		
		-- Only build in valid blocks
		if maxX > minX and maxZ > minZ then
			if (bx == -160 or bx == 0) and bz == 160 then
				spawnRomanMarketplace(bx + 80, bz + 80)
			else
				local step = 32
				-- South border of the block (Facing -Z / South)
				spawnHouseLine(minX + 20, minZ + 20, maxX - 20, minZ + 20, step, math.pi)
				-- North border of the block (Facing +Z / North)
				spawnHouseLine(minX + 20, maxZ - 20, maxX - 20, maxZ - 20, step, 0)
				-- West border of the block (Facing -X / West)
				spawnHouseLine(minX + 20, minZ + 52, minX + 20, maxZ - 52, step, -math.pi/2)
				-- East border of the block (Facing +X / East)
				spawnHouseLine(maxX - 20, minZ + 52, maxX - 20, maxZ - 52, step, math.pi/2)
			end
		end
	end
	task.wait()
end

print("4/4 Growing Organized Forest (Oak, Birch, Apple, Pine)...")

local function createPineTree(treeModel, tx, ty, tz)
	local trunkH = math.random(25, 40)
	local trunkBaseW = math.random(2.5, 4)
	local trunkCol = Color3.fromRGB(45, 30, 20)
	
	-- Tapered 3D Trunk
	local numSegments = 4
	local segH = trunkH / numSegments
	local currentY = ty
	local lastW = trunkBaseW
	
	for i = 1, numSegments do
		local nextW = trunkBaseW * (1 - (i/numSegments)*0.6)
		local trunk = createPart("TrunkSeg", treeModel, Vector3.new(segH, (lastW+nextW)/2, (lastW+nextW)/2), Vector3.new(tx + math.random(-1,1)*0.2, currentY + segH/2, tz + math.random(-1,1)*0.2), trunkCol, Enum.Material.Wood)
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Orientation = Vector3.new(0, 0, 90)
		currentY = currentY + segH
		lastW = nextW
	end
	
	local leafColBase = Color3.fromRGB(35, 75, 45)
	local leafMat = Enum.Material.LeafyGrass
	local numLayers = 5
	local layerH = trunkH * 0.6 / numLayers
	local startY = ty + trunkH * 0.4
	
	for i = 1, numLayers do
		local layerW = 24 - (i * 4)
		-- Multiple intersecting blocks per layer for 3D needle effect
		for j = 1, 3 do
			local colOffset = math.random(-10, 10)
			local lCol = Color3.fromRGB(math.clamp(35+colOffset,0,255), math.clamp(75+colOffset,0,255), math.clamp(45+colOffset,0,255))
			local layer = createPart("Leaves", treeModel, Vector3.new(layerW, layerW*0.6, layerW), Vector3.new(tx, startY + (i-1)*layerH, tz), lCol, leafMat)
			layer.Orientation = Vector3.new(math.random(-15,15), math.random(0,360), math.random(-15,15))
			-- Add a slight neon core to simulate subsurface scattering / shaders
			if j == 1 then
				local core = createPart("LeafCore", treeModel, Vector3.new(layerW*0.5, layerW*0.3, layerW*0.5), Vector3.new(tx, startY + (i-1)*layerH, tz), lCol, Enum.Material.Neon)
				core.Transparency = 0.5
			end
		end
	end
end

local function createBirchTree(treeModel, tx, ty, tz)
	local trunkH = math.random(20, 35)
	local trunkW = math.random(1.5, 2.5)
	local trunkCol = Color3.fromRGB(220, 225, 220) -- White bark
	
	local trunk = createPart("Trunk", treeModel, Vector3.new(trunkH, trunkW, trunkW), Vector3.new(tx, ty + trunkH/2, tz), trunkCol, Enum.Material.Wood)
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Orientation = Vector3.new(math.random(-5,5), 0, 90 + math.random(-5,5))
	
	local leafMat = Enum.Material.LeafyGrass
	
	-- 3D canopy with shader-like falling leaves
	for i = 1, 6 do
		local colOffset = math.random(-15, 15)
		local lCol = Color3.fromRGB(math.clamp(150+colOffset,0,255), math.clamp(180+colOffset,0,255), math.clamp(50+colOffset,0,255))
		local lx = tx + math.random(-6, 6)
		local lz = tz + math.random(-6, 6)
		local ly = ty + trunkH - math.random(0, 10)
		
		local lPart = createPart("Leaves", treeModel, Vector3.new(12, 12, 12), Vector3.new(lx, ly, lz), lCol, leafMat)
		lPart.Shape = Enum.PartType.Ball
		lPart.Orientation = Vector3.new(math.random(0,360), math.random(0,360), math.random(0,360))
		
		if i == 1 then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Color = ColorSequence.new(lCol)
			emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.2)})
			emitter.Rate = 2
			emitter.Lifetime = NumberRange.new(4, 6)
			emitter.Speed = NumberRange.new(2, 4)
			emitter.VelocitySpread = 45
			emitter.EmissionDirection = Enum.NormalId.Bottom
			emitter.Parent = lPart
		end
	end
end

local function createOakTree(treeModel, tx, ty, tz)
	local trunkH = math.random(15, 25)
	local trunkBaseW = math.random(3.5, 5.5)
	local trunkCol = Color3.fromRGB(70, 50, 30)
	
	-- Tapered 3D Trunk
	local numSegments = 3
	local segH = trunkH / numSegments
	local currentY = ty
	local lastW = trunkBaseW
	
	for i = 1, numSegments do
		local nextW = trunkBaseW * (1 - (i/numSegments)*0.5)
		local trunk = createPart("TrunkSeg", treeModel, Vector3.new(segH, (lastW+nextW)/2, (lastW+nextW)/2), Vector3.new(tx + math.random(-1,1)*0.5, currentY + segH/2, tz + math.random(-1,1)*0.5), trunkCol, Enum.Material.Wood)
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Orientation = Vector3.new(math.random(-3,3), 0, 90 + math.random(-3,3))
		currentY = currentY + segH
		lastW = nextW
	end
	
	local leafMat = Enum.Material.LeafyGrass
	
	-- Massive 3D overlapping canopy
	for i = 1, 12 do
		local colOffset = math.random(-20, 20)
		local lCol = Color3.fromRGB(math.clamp(45+colOffset,0,255), math.clamp(105+colOffset,0,255), math.clamp(45+colOffset,0,255))
		
		local angle = math.random(0, 360)
		local dist = math.random(0, 12)
		local lx = tx + math.cos(math.rad(angle)) * dist
		local lz = tz + math.sin(math.rad(angle)) * dist
		local ly = ty + trunkH + math.random(-6, 6)
		
		local s = math.random(14, 22)
		local lPart = createPart("Leaves", treeModel, Vector3.new(s, s*0.8, s), Vector3.new(lx, ly, lz), lCol, leafMat)
		lPart.Shape = Enum.PartType.Ball
		lPart.Orientation = Vector3.new(math.random(0,360), math.random(0,360), math.random(0,360))
		
		-- Fake subsurface scattering for rich realistic shading
		local core = createPart("LeafCore", treeModel, Vector3.new(s*0.6, s*0.6, s*0.6), Vector3.new(lx, ly, lz), lCol, Enum.Material.Neon)
		core.Shape = Enum.PartType.Ball
		core.Transparency = 0.6
	end
end

local function createAppleTree(treeModel, tx, ty, tz)
	local trunkH = math.random(12, 18)
	local trunkW = math.random(2, 3.5)
	local trunkCol = Color3.fromRGB(80, 60, 40)
	
	local trunk = createPart("Trunk", treeModel, Vector3.new(trunkH, trunkW, trunkW), Vector3.new(tx, ty + trunkH/2, tz), trunkCol, Enum.Material.Wood)
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Orientation = Vector3.new(math.random(-5,5), 0, 90 + math.random(-5,5))
	
	local leafMat = Enum.Material.LeafyGrass
	
	local leafClusters = {}
	for i = 1, 5 do
		local colOffset = math.random(-15, 15)
		local lCol = Color3.fromRGB(math.clamp(55+colOffset,0,255), math.clamp(125+colOffset,0,255), math.clamp(55+colOffset,0,255))
		local lx = tx + math.random(-5, 5)
		local lz = tz + math.random(-5, 5)
		local ly = ty + trunkH - math.random(0, 5)
		
		local s = math.random(12, 18)
		local lPart = createPart("Leaves", treeModel, Vector3.new(s, s, s), Vector3.new(lx, ly, lz), lCol, leafMat)
		lPart.Shape = Enum.PartType.Ball
		table.insert(leafClusters, lPart)
		
		-- Add slight glowing core
		local core = createPart("LeafCore", treeModel, Vector3.new(s*0.5, s*0.5, s*0.5), Vector3.new(lx, ly, lz), lCol, Enum.Material.Neon)
		core.Shape = Enum.PartType.Ball
		core.Transparency = 0.5
	end
	
	local appleCol = Color3.fromRGB(200, 40, 40)
	for i = 1, math.random(8, 15) do
		local cluster = leafClusters[math.random(1, #leafClusters)]
		local angle = math.random(0, 360)
		local heightAngle = math.random(0, 180)
		local dir = CFrame.Angles(math.rad(heightAngle), math.rad(angle), 0) * Vector3.new(0, 0, -cluster.Size.X/2.2)
		local aPos = cluster.Position + dir
		
		local apple = createPart("Apple", treeModel, Vector3.new(1.8, 1.8, 1.8), aPos, appleCol, Enum.Material.SmoothPlastic)
		apple.Shape = Enum.PartType.Ball
		
		-- Specular highlight for 3D shader look on apple
		local hl = createPart("AppleHighlight", treeModel, Vector3.new(1.9, 1.9, 1.9), aPos, Color3.new(1,1,1), Enum.Material.Glass)
		hl.Shape = Enum.PartType.Ball
		hl.Transparency = 0.7
	end
end

local ServerStorage = game:GetService("ServerStorage")

local function spawnModelFromStorage(modelName, tx, ty, tz, parent)
	local natureModels = ServerStorage:FindFirstChild("NatureModels")
	if natureModels then
		local possibleModels = {}
		for _, child in ipairs(natureModels:GetChildren()) do
			if string.find(string.lower(child.Name), string.lower(modelName)) then
				table.insert(possibleModels, child)
			end
		end
		
		if #possibleModels > 0 then
			local template = possibleModels[math.random(1, #possibleModels)]
			local clone = template:Clone()
			clone.Parent = parent
			
			local randomRot = CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
			
			if clone:IsA("Model") then
				local cframe, size = clone:GetBoundingBox()
				-- Heuristic: if pivot is in the center, creator didn't set it. Shift it up by half height.
				local isDefaultPivot = math.abs(clone:GetPivot().Y - cframe.Y) < 1
				local yOffset = isDefaultPivot and (size.Y / 2) or 0
				
				clone:PivotTo(CFrame.new(tx, ty + yOffset, tz) * randomRot)
				
				-- Random scale (newer API)
				local scale = math.random(80, 150) / 100
				pcall(function() clone:ScaleTo(clone:GetScale() * scale) end)
			elseif clone:IsA("BasePart") then
				clone.CFrame = CFrame.new(tx, ty + clone.Size.Y/2, tz) * randomRot
			end
			return true
		end
	end
	return false
end

local function spawnBush(tx, tz)
	local ty, mat = getGroundY(tx, tz)
	
	if math.sqrt(tx^2 + tz^2) <= VILLAGE_RADIUS + 30 then return end
	if mat ~= Enum.Material.Grass and mat ~= Enum.Material.Mud then return end
	
	local loaded = spawnModelFromStorage("Bush", tx, ty, tz, natureFolder)
	if loaded then return end
	
	-- Fallback procedural bush
	local bush = Instance.new("Model", natureFolder)
	bush.Name = "ProceduralBush"
	local bSize = math.random(8, 14)
	local bCol = Color3.fromRGB(math.random(40, 60), math.random(90, 120), math.random(30, 50))
	local part = createPart("Leaves", bush, Vector3.new(bSize, bSize*0.7, bSize), Vector3.new(tx, ty + bSize*0.35, tz), bCol, Enum.Material.LeafyGrass)
	part.Shape = Enum.PartType.Ball
	part.Orientation = Vector3.new(math.random(0,360), math.random(0,360), math.random(0,360))
end

local function spawnTree(tx, tz)
	local ty, mat = getGroundY(tx, tz)
	
	if math.sqrt(tx^2 + tz^2) <= VILLAGE_RADIUS + 30 then return end
	if mat ~= Enum.Material.Grass and mat ~= Enum.Material.Mud then return end
	
	-- Organize by biomes using Perlin Noise
	local noiseVal = math.noise(tx/400, tz/400, SEED + 5)
	
	local treeName = "BirchTree"
	if noiseVal < -0.2 then
		treeName = "PineTree"
	elseif noiseVal < 0.05 then
		treeName = "OakTree"
	elseif noiseVal < 0.25 then
		treeName = "AppleTree"
	end
	
	-- Try to load from user's custom models first
	local loaded = spawnModelFromStorage(treeName, tx, ty, tz, natureFolder)
	if not loaded then
		-- Fallback if they just put a generic "Tree" model
		loaded = spawnModelFromStorage("Tree", tx, ty, tz, natureFolder)
	end
	
	if loaded then return end
	
	-- Fallback to the generated 3D trees
	local tree = Instance.new("Model", natureFolder)
	tree.Name = treeName
	
	if treeName == "PineTree" then
		createPineTree(tree, tx, ty, tz)
	elseif treeName == "OakTree" then
		createOakTree(tree, tx, ty, tz)
	elseif treeName == "AppleTree" then
		createAppleTree(tree, tx, ty, tz)
	else
		createBirchTree(tree, tx, ty, tz)
	end
end

for i = 1, 3500 do
	local tx = math.random(-1700, 1700)
	local tz = math.random(-1700, 1700)
	spawnTree(tx, tz)
	
	-- Spawn some bushes alongside trees
	if i % 3 == 0 then
		local bx = tx + math.random(-15, 15)
		local bz = tz + math.random(-15, 15)
		spawnBush(bx, bz)
	end
	
	if i % 100 == 0 then task.wait() end
end

print("Map Generation 100% Complete! The Castle, Paths, and Fixed Trees are ready.")

local MapGeneratorService = {
	_generated = true,
}

function MapGeneratorService:Generate()
	-- Map generates at module load time; this method exists for GameServer compatibility.
end

function MapGeneratorService:GetGroundHeight(x, z)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local mapFolder = workspace:FindFirstChild("RPG_World")
	if mapFolder then
		rayParams.FilterDescendantsInstances = { mapFolder }
	end

	local ray = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -1000, 0), rayParams)
	if ray then
		return ray.Position.Y
	end
	return 22
end

return MapGeneratorService