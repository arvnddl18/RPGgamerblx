local Workspace = game:GetService("Workspace")

local WorldMapTerrainRenderer = {}

local MATERIAL_COLORS = {
	[Enum.Material.Grass] = Color3.fromRGB(62, 118, 52),
	[Enum.Material.LeafyGrass] = Color3.fromRGB(48, 98, 42),
	[Enum.Material.Sand] = Color3.fromRGB(194, 178, 128),
	[Enum.Material.Water] = Color3.fromRGB(42, 92, 142),
	[Enum.Material.Pavement] = Color3.fromRGB(145, 145, 140),
	[Enum.Material.Cobblestone] = Color3.fromRGB(118, 112, 102),
	[Enum.Material.Brick] = Color3.fromRGB(132, 108, 88),
	[Enum.Material.Rock] = Color3.fromRGB(108, 102, 96),
	[Enum.Material.Basalt] = Color3.fromRGB(58, 56, 54),
	[Enum.Material.Snow] = Color3.fromRGB(228, 232, 238),
	[Enum.Material.Mud] = Color3.fromRGB(88, 72, 52),
	[Enum.Material.Wood] = Color3.fromRGB(98, 68, 40),
	[Enum.Material.WoodPlanks] = Color3.fromRGB(118, 82, 48),
	[Enum.Material.Marble] = Color3.fromRGB(210, 208, 200),
	[Enum.Material.Slate] = Color3.fromRGB(78, 86, 98),
	[Enum.Material.Metal] = Color3.fromRGB(96, 98, 104),
	[Enum.Material.Fabric] = Color3.fromRGB(128, 42, 42),
	[Enum.Material.Neon] = Color3.fromRGB(210, 150, 55),
	[Enum.Material.Glass] = Color3.fromRGB(170, 200, 220),
	[Enum.Material.SmoothPlastic] = Color3.fromRGB(120, 120, 120),
	[Enum.Material.DiamondPlate] = Color3.fromRGB(72, 76, 82),
}

local DEFAULT_TERRAIN_COLOR = Color3.fromRGB(36, 52, 34)
local DEFAULT_PART_COLOR = Color3.fromRGB(100, 100, 100)
local RAY_HEIGHT = 800
local ROWS_PER_YIELD = 8

local cachedLayer = nil
local cachedBoundsKey = nil
local generating = false
local waiters = {}

local function waitForWorldReady(timeoutSeconds)
	local deadline = os.clock() + (timeoutSeconds or 30)
	while os.clock() < deadline do
		if Workspace:FindFirstChild("RPG_World") and Workspace.Terrain then
			return true
		end
		task.wait(0.25)
	end
	return Workspace.Terrain ~= nil
end

local function getBoundsKey(bounds, resolution)
	return string.format(
		"%d:%d:%d:%d:%d",
		math.floor(bounds.minX),
		math.floor(bounds.maxX),
		math.floor(bounds.minZ),
		math.floor(bounds.maxZ),
		resolution
	)
end

local function getMapInstances()
	local instances = { Workspace.Terrain }
	local rpgWorld = Workspace:FindFirstChild("RPG_World")
	if rpgWorld then
		table.insert(instances, rpgWorld)
	end
	local fastTravel = Workspace:FindFirstChild("FastTravel")
	if fastTravel then
		table.insert(instances, fastTravel)
	end
	return instances
end

local function sampleColor(worldX, worldZ, rayParams)
	local result = Workspace:Raycast(
		Vector3.new(worldX, RAY_HEIGHT, worldZ),
		Vector3.new(0, -RAY_HEIGHT * 2, 0),
		rayParams
	)
	if not result then
		return DEFAULT_TERRAIN_COLOR
	end

	if result.Instance == Workspace.Terrain then
		local material = result.Material
		return MATERIAL_COLORS[material] or DEFAULT_TERRAIN_COLOR
	end

	if result.Instance:IsA("BasePart") then
		local partColor = result.Instance.Color
		local material = result.Instance.Material
		local materialColor = MATERIAL_COLORS[material]
		if materialColor then
			return partColor:Lerp(materialColor, 0.35)
		end
		return partColor
	end

	return DEFAULT_PART_COLOR
end

local function buildViewportLayer(bounds, resolution)
	local centerX = (bounds.minX + bounds.maxX) / 2
	local centerZ = (bounds.minZ + bounds.maxZ) / 2
	local xRange = bounds.maxX - bounds.minX
	local zRange = bounds.maxZ - bounds.minZ
	local mapSpan = math.max(xRange, zRange)

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "WorldMapTerrain"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(255, 255, 255)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(0, -1, 0)

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	local camera = Instance.new("Camera")
	camera.CFrame = CFrame.new(centerX, 300, centerZ) * CFrame.Angles(-math.pi / 2, 0, 0)
	local orthoOk = pcall(function()
		camera.CameraType = Enum.CameraType.Orthographic
		camera.OrthographicSize = mapSpan / 2
	end)
	if not orthoOk then
		local height = mapSpan
		camera.CameraType = Enum.CameraType.Fixed
		camera.CFrame = CFrame.new(centerX, height, centerZ) * CFrame.Angles(-math.pi / 2, 0, 0)
		camera.FieldOfView = math.clamp(math.deg(2 * math.atan(mapSpan / (2 * height))), 1, 120)
	end
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = getMapInstances()
	rayParams.IgnoreWater = false

	local cellW = xRange / resolution
	local cellD = zRange / resolution

	for py = 0, resolution - 1 do
		local worldZ = bounds.minZ + (py + 0.5) * (zRange / resolution)
		for px = 0, resolution - 1 do
			local worldX = bounds.minX + (px + 0.5) * (xRange / resolution)
			local color = sampleColor(worldX, worldZ, rayParams)

			local cell = Instance.new("Part")
			cell.Name = "MapCell"
			cell.Anchored = true
			cell.CanCollide = false
			cell.CanQuery = false
			cell.CanTouch = false
			cell.CastShadow = false
			cell.Size = Vector3.new(cellW + 0.2, 1, cellD + 0.2)
			cell.CFrame = CFrame.new(worldX, 0, worldZ)
			cell.Color = color
			cell.Material = Enum.Material.SmoothPlastic
			cell.Parent = worldModel
		end

		if py % ROWS_PER_YIELD == 0 then
			task.wait()
		end
	end

	return viewport
end

local function notifyWaiters(layer)
	for _, callback in waiters do
		task.spawn(callback, layer)
	end
	table.clear(waiters)
end

function WorldMapTerrainRenderer.GetTerrainLayer(bounds, resolution, onReady)
	resolution = resolution or 128
	local boundsKey = getBoundsKey(bounds, resolution)

	if cachedLayer and cachedBoundsKey == boundsKey then
		if onReady then
			onReady(cachedLayer)
		end
		return cachedLayer
	end

	if onReady then
		table.insert(waiters, onReady)
	end

	if generating then
		return nil
	end

	generating = true
	task.spawn(function()
		waitForWorldReady(45)
		local ok, layer = pcall(buildViewportLayer, bounds, resolution)
		generating = false

		if ok and layer then
			if cachedLayer then
				cachedLayer:Destroy()
			end
			cachedLayer = layer
			cachedBoundsKey = boundsKey
			notifyWaiters(layer)
		else
			warn("[WorldMapTerrainRenderer] Failed to build terrain map:", layer)
			notifyWaiters(nil)
		end
	end)

	return nil
end

function WorldMapTerrainRenderer.InvalidateCache()
	if cachedLayer then
		cachedLayer:Destroy()
		cachedLayer = nil
	end
	cachedBoundsKey = nil
end

return WorldMapTerrainRenderer
