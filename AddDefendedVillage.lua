local function getGroundY(x, z)
	local origin = Vector3.new(x, 500, z)
	local direction = Vector3.new(0, -1000, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local existing = workspace:FindFirstChild("DefendedVillage")
	if existing then
		raycastParams.FilterDescendantsInstances = {existing}
	end

	local result = workspace:Raycast(origin, direction, raycastParams)
	if result then
		return result.Position.Y
	end
	return 20
end

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

local function spawnHorse(parent, hx, hz)
	local hy = getGroundY(hx, hz)
	local horse = Instance.new("Model", parent)
	horse.Name = "Horse"
	
	local col = Color3.fromRGB(110, 60, 25) -- Brown
	local mat = Enum.Material.Fabric
	
	-- Rotate horse randomly
	local rot = math.rad(math.random(0, 360))
	local function pos(lx, ly, lz)
		-- rotate local pos around Y
		local rx = lx * math.cos(rot) - lz * math.sin(rot)
		local rz = lx * math.sin(rot) + lz * math.cos(rot)
		return Vector3.new(hx + rx, hy + ly, hz + rz)
	end
	
	-- Body
	local body = createPart("Body", horse, Vector3.new(3, 3, 6), pos(0, 4.5, 0), col, mat)
	body.Orientation = Vector3.new(0, math.deg(rot), 0)
	
	-- Legs
	createPart("Leg1", horse, Vector3.new(1, 4, 1), pos(-1, 2, -2.5), col, mat).Orientation = Vector3.new(0, math.deg(rot), 0)
	createPart("Leg2", horse, Vector3.new(1, 4, 1), pos(1, 2, -2.5), col, mat).Orientation = Vector3.new(0, math.deg(rot), 0)
	createPart("Leg3", horse, Vector3.new(1, 4, 1), pos(-1, 2, 2.5), col, mat).Orientation = Vector3.new(0, math.deg(rot), 0)
	createPart("Leg4", horse, Vector3.new(1, 4, 1), pos(1, 2, 2.5), col, mat).Orientation = Vector3.new(0, math.deg(rot), 0)
	
	-- Neck & Head
	createPart("Neck", horse, Vector3.new(1.5, 3, 1.5), pos(0, 6.5, 2.5), col, mat).Orientation = Vector3.new(0, math.deg(rot), 0)
	createPart("Head", horse, Vector3.new(1.5, 1.5, 2.5), pos(0, 8, 3), col, mat).Orientation = Vector3.new(0, math.deg(rot), 0)
end

-- MAIN GENERATOR
local function generateDefendedVillage(centerX, centerZ)
	-- Cleanup old
	if workspace:FindFirstChild("DefendedVillage") then
		workspace.DefendedVillage:Destroy()
	end
	
	local village = Instance.new("Model", workspace)
	village.Name = "DefendedVillage"
	
	print("Building Spike Walls...")
	local radius = 90
	for angle = 0, math.pi*2, 0.15 do
		-- Leave openings for North and South gates
		local isNorthGate = (angle > math.pi/2 - 0.2 and angle < math.pi/2 + 0.2)
		local isSouthGate = (angle > 3*math.pi/2 - 0.2 and angle < 3*math.pi/2 + 0.2)
		
		if not isNorthGate and not isSouthGate then
			local x = centerX + math.cos(angle) * radius
			local z = centerZ + math.sin(angle) * radius
			local y = getGroundY(x, z)
			
			local height = math.random(14, 20)
			local spike = createPart("SpikeLog", village, Vector3.new(height, 2.5, 2.5), Vector3.new(x, y + height/2 - 3, z), Color3.fromRGB(90, 60, 40), Enum.Material.Wood)
			spike.Shape = Enum.PartType.Cylinder
			-- Stand it up, add a slight tilt outward
			spike.Orientation = Vector3.new(0, 0, 90)
		end
	end
	
	print("Laying Dirt Paths...")
	-- Main path through the village
	for pz = -radius, radius, 8 do
		local px = centerX
		local pzz = centerZ + pz
		local py = getGroundY(px, pzz)
		local path = createPart("Path", village, Vector3.new(12, 1, 10), Vector3.new(px, py + 0.2, pzz), Color3.fromRGB(110, 90, 60), Enum.Material.Sand)
		path.Orientation = Vector3.new(0, math.random(-5, 5), 0)
	end
	
	print("Planting Farm...")
	local farmX, farmZ = centerX + 40, centerZ + 40
	local farmY = getGroundY(farmX, farmZ)
	createPart("FarmDirt", village, Vector3.new(40, 2, 40), Vector3.new(farmX, farmY, farmZ), Color3.fromRGB(60, 40, 20), Enum.Material.Mud)
	
	for i = -16, 16, 4 do
		for j = -16, 16, 4 do
			createPart("Crop", village, Vector3.new(1.5, 3, 1.5), Vector3.new(farmX + i, farmY + 1.5, farmZ + j), Color3.fromRGB(50, 180, 50), Enum.Material.Grass)
		end
	end
	
	print("Spawning Horses...")
	for i = 1, 5 do
		local hx = centerX - 40 + math.random(-20, 20)
		local hz = centerZ + 30 + math.random(-20, 20)
		spawnHorse(village, hx, hz)
	end
	
	-- Houses (Using Toolbox templates if they exist, otherwise basic procedural boxes)
	local mapAssets = game:GetService("ReplicatedStorage"):FindFirstChild("MapAssets")
	local templateHouse = mapAssets and mapAssets:FindFirstChild("House")
	
	local houseLocs = {
		Vector2.new(centerX - 40, centerZ - 40),
		Vector2.new(centerX - 40, centerZ - 10),
		Vector2.new(centerX + 40, centerZ - 40),
		Vector2.new(centerX + 40, centerZ - 10),
	}
	
	for _, loc in ipairs(houseLocs) do
		local hy = getGroundY(loc.X, loc.Y)
		if templateHouse then
			local h = templateHouse:Clone()
			local cf, size = h:GetBoundingBox()
			local pivotY = h:GetPivot().Position.Y
			local offset = pivotY - (cf.Position.Y - size.Y/2)
			h:PivotTo(CFrame.new(loc.X, hy + offset, loc.Y) * CFrame.Angles(0, math.random(0, 360), 0))
			h.Parent = village
		else
			-- Fallback blocky house
			createPart("HouseBase", village, Vector3.new(20, 15, 20), Vector3.new(loc.X, hy + 7.5, loc.Y), Color3.fromRGB(150, 150, 150), Enum.Material.Cobblestone)
			createPart("HouseRoof", village, Vector3.new(22, 5, 22), Vector3.new(loc.X, hy + 17.5, loc.Y), Color3.fromRGB(100, 50, 20), Enum.Material.Wood)
		end
	end
	
	print("Defended Village successfully added at", centerX, centerZ)
end

-- Spawn a village at coordinates 300, 300
generateDefendedVillage(300, 300)
