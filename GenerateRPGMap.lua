local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mapAssets = ReplicatedStorage:FindFirstChild("MapAssets")

-- 1. Check for Toolbox Assets
if not mapAssets then
	mapAssets = Instance.new("Folder")
	mapAssets.Name = "MapAssets"
	mapAssets.Parent = ReplicatedStorage
	warn("--- SETUP REQUIRED ---")
	warn("1. I created a folder named 'MapAssets' in your ReplicatedStorage.")
	warn("2. Open the Toolbox and find a 3D Tree, House, and Temple you like.")
	warn("3. Drag them into 'ReplicatedStorage.MapAssets'.")
	warn("4. Rename them exactly to: 'Tree', 'House', and 'Temple'.")
	warn("5. Run this script again!")
	return
end

local templateTree = mapAssets:FindFirstChild("Tree")
local templateHouse = mapAssets:FindFirstChild("House")
local templateTemple = mapAssets:FindFirstChild("Temple")

if not (templateTree and templateHouse and templateTemple) then
	warn("Missing assets! Please make sure you have models named exactly 'Tree', 'House', and 'Temple' inside ReplicatedStorage.MapAssets.")
	return
end

-- Clear previous map if it exists
if workspace:FindFirstChild("Countryside_Province_Map") then
	workspace.Countryside_Province_Map:Destroy()
end

local mapFolder = Instance.new("Folder")
mapFolder.Name = "Countryside_Province_Map"
mapFolder.Parent = workspace

local terrainFolder = Instance.new("Folder", mapFolder)
terrainFolder.Name = "Terrain"

local waterFolder = Instance.new("Folder", mapFolder)
waterFolder.Name = "Water"

local natureFolder = Instance.new("Folder", mapFolder)
natureFolder.Name = "Nature"

local structuresFolder = Instance.new("Folder", mapFolder)
structuresFolder.Name = "Structures"

-- Constants
local GRID_SIZE = 220 
local SCALE = 16
local SEED = math.random(1, 100000)
local WATER_LEVEL = 18

local heightMap = {}

-- Terrain Generation Helper
local function createPart(name, parent, size, position, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.Anchored = true
	part.CastShadow = true
	part.Parent = parent
	return part
end

-- Toolbox Model Placement Helper
local function placeModelOnGround(model, x, y, z)
	local cf, size = model:GetBoundingBox()
	
	if not model.PrimaryPart then
		local tempPart = Instance.new("Part")
		tempPart.Transparency = 1
		tempPart.CanCollide = false
		tempPart.Anchored = true
		tempPart.Size = size
		tempPart.CFrame = cf
		tempPart.Parent = model
		model.PrimaryPart = tempPart
	end
	
	local pivotY = model:GetPivot().Position.Y
	local bottomY = cf.Position.Y - (size.Y / 2)
	local offset = pivotY - bottomY
	
	local randomRot = CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
	model:PivotTo(CFrame.new(x, y + offset, z) * randomRot)
end

local function spawnTree(x, y, z)
	local tree = templateTree:Clone()
	placeModelOnGround(tree, x, y, z)
	tree.Parent = natureFolder
end

local function spawnHouse(x, y, z)
	local house = templateHouse:Clone()
	placeModelOnGround(house, x, y, z)
	house.Parent = structuresFolder
end

local function spawnTemple(x, y, z)
	local temple = templateTemple:Clone()
	placeModelOnGround(temple, x, y, z)
	temple.Parent = structuresFolder
end

local function spawnGrandMonument(x, y, z)
	local monument = Instance.new("Model", structuresFolder)
	monument.Name = "GrandMonument"
	
	-- Base Steps (Circular)
	local baseRadius = 40
	local baseMat = Enum.Material.Slate
	local baseCol = Color3.fromRGB(50, 50, 55)
	
	for i = 1, 4 do
		local r = baseRadius - (i*6)
		local step = createPart("Step"..i, monument, Vector3.new(4, r, r), Vector3.new(x, y + (i*4) - 2, z), baseCol, baseMat)
		step.Shape = Enum.PartType.Cylinder
		step.Orientation = Vector3.new(0, 0, 90)
	end
	
	-- Central Giant Floating Crystal
	local crystal = createPart("GiantCrystal", monument, Vector3.new(16, 40, 16), Vector3.new(x, y + 45, z), Color3.fromRGB(0, 255, 200), Enum.Material.Neon)
	crystal.Orientation = Vector3.new(45, 45, 0)
	
	-- Floating Pillars
	for i = 1, 4 do
		local angle = (i * math.pi / 2)
		local px = x + math.cos(angle) * 25
		local pz = z + math.sin(angle) * 25
		
		local pillar = createPart("FloatingPillar", monument, Vector3.new(5, 25, 5), Vector3.new(px, y + 35, pz), Color3.fromRGB(220, 220, 220), Enum.Material.Marble)
		local pillarGlow = createPart("PillarGlow", monument, Vector3.new(5.2, 2, 5.2), Vector3.new(px, y + 35, pz), Color3.fromRGB(0, 255, 200), Enum.Material.Neon)
	end
	
	-- Animation Script
	local scriptStr = [[
		local crystal = script.Parent.GiantCrystal
		local startY = crystal.Position.Y
		local tick = 0
		while true do
			task.wait()
			tick = tick + 0.03
			crystal.CFrame = CFrame.new(crystal.Position.X, startY + math.sin(tick) * 4, crystal.Position.Z) * CFrame.Angles(math.rad(45), tick * 0.5, 0)
		end
	]]
	local animScript = Instance.new("Script", monument)
	animScript.Name = "AnimateMonument"
	animScript.Source = scriptStr
end

-- 1. Generate Terrain Grid & HeightMap
print("Generating Terrain...")
for cx = -GRID_SIZE/2, GRID_SIZE/2 do
	heightMap[cx] = {}
	for cz = -GRID_SIZE/2, GRID_SIZE/2 do
		local worldX = cx * SCALE
		local worldZ = cz * SCALE
		
		local noise1 = math.noise(cx/30, cz/30, SEED)
		local noise2 = math.noise(cx/10, cz/10, SEED + 100) * 0.3
		local height = 20 + ((noise1 + noise2) * 15)
		
		local craterDist = math.sqrt((worldX - 800)^2 + (worldZ + 600)^2)
		local distFromCenter = math.sqrt(worldX^2 + worldZ^2)
		
		-- Clear center area for Grand Monument
		if distFromCenter < 120 then
			height = 25 -- Flat plain in the center
		elseif distFromCenter > 1300 then
			height = height + ((distFromCenter - 1300) * 0.25)
		end
		
		local isCrater = false
		if craterDist < 250 then
			isCrater = true
			if craterDist < 120 then
				height = height - (120 - craterDist) * 0.5 
			else
				height = height + (250 - craterDist) * 0.2 
			end
		end

		height = math.floor(height)
		heightMap[cx][cz] = height
		
		local color = Color3.fromRGB(90, 150, 60)
		local material = Enum.Material.Grass
		
		if height <= WATER_LEVEL then
			color = Color3.fromRGB(200, 180, 140)
			material = Enum.Material.Sand
		elseif isCrater then
			color = Color3.fromRGB(80, 75, 70)
			material = Enum.Material.Basalt
		elseif height > 80 then
			color = Color3.fromRGB(110, 110, 115)
			material = Enum.Material.Rock
			if height > 160 then
				color = Color3.fromRGB(240, 245, 255)
				material = Enum.Material.Snow
			end
		end
		
		createPart("Tile", terrainFolder, Vector3.new(SCALE, height + 100, SCALE), Vector3.new(worldX, (height + 100)/2 - 100, worldZ), color, material)
		
		if height < WATER_LEVEL then
			local wDepth = WATER_LEVEL - height
			local wPart = createPart("LakeWater", waterFolder, Vector3.new(SCALE, wDepth, SCALE), Vector3.new(worldX, height + wDepth/2, worldZ), Color3.fromRGB(60, 140, 210), Enum.Material.Glass)
			wPart.Transparency = 0.6
			wPart.CanCollide = false
		end
	end
	if cx % 20 == 0 then task.wait() end 
end

local function getGroundHeight(wx, wz)
	local cx = math.floor((wx / SCALE) + 0.5)
	local cz = math.floor((wz / SCALE) + 0.5)
	if heightMap[cx] and heightMap[cx][cz] then
		return heightMap[cx][cz]
	end
	return 20
end

print("Spawning Toolbox Assets & Structures...")

-- Spawn Grand Monument at the center of the map
local centerHeight = getGroundHeight(0, 0)
spawnGrandMonument(0, centerHeight, 0)

-- 2. Forests
for i = 1, 600 do
	local tx = math.random(-1500, 1500)
	local tz = math.random(-1500, 1500)
	local ty = getGroundHeight(tx, tz)
	
	local craterDist = math.sqrt((tx - 800)^2 + (tz + 600)^2)
	local distFromCenter = math.sqrt(tx^2 + tz^2)
	
	-- Keep trees away from the central monument
	if ty > WATER_LEVEL and ty < 70 and craterDist > 260 and distFromCenter > 150 then
		spawnTree(tx, ty, tz)
	end
end

-- 3. Villages
local villageCenters = { Vector2.new(-600, -400), Vector2.new(500, 800) }
for _, center in ipairs(villageCenters) do
	for i = 1, 8 do
		local hx = center.X + math.random(-150, 150)
		local hz = center.Y + math.random(-150, 150)
		local hy = getGroundHeight(hx, hz)
		
		if hy > WATER_LEVEL and hy < 60 then
			spawnHouse(hx, hy, hz)
		end
	end
end

-- 4. Temples
local templeLocations = { Vector2.new(-900, 900), Vector2.new(0, -1000) }
for _, loc in ipairs(templeLocations) do
	local ty = getGroundHeight(loc.X, loc.Y)
	if ty > WATER_LEVEL then
		spawnTemple(loc.X, ty, loc.Y)
	end
end

print("Generation Complete! Your high-quality toolbox map is ready.")
