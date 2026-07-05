local function getGroundY(x, z)
	local origin = Vector3.new(x, 500, z)
	local direction = Vector3.new(0, -1000, 0)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	-- We want to ignore the monument if it already exists so we don't stack them
	local existing = workspace:FindFirstChild("GrandMonument")
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

local function spawnGrandMonument(x, z)
	local y = getGroundY(x, z)
	
	-- Clean up old monument if it exists
	if workspace:FindFirstChild("GrandMonument") then
		workspace.GrandMonument:Destroy()
	end
	
	local monument = Instance.new("Model", workspace)
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
	
	print("Grand Monument successfully added to the map at", x, y, z)
end

-- Spawn right in the center!
spawnGrandMonument(0, 0)
