local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local MiningService = {}
MiningService._framework = nil
MiningService._playerData = nil
MiningService._mapGenerator = nil
MiningService._nodes = {}

local NODE_TYPES = {
	RegularStone = {
		name = "Regular Stone",
		capacity = 20,
		cycleTime = 3,
		respawnTime = 30,
		color = Color3.fromRGB(150, 150, 150),
		material = Enum.Material.Slate,
		size = Vector3.new(4, 4, 4),
		drops = { {itemId = "CopperOre", weight = 80}, {itemId = "IronOre", weight = 20} }
	},
	GlimmeringRock = {
		name = "Glimmering Rock",
		capacity = 15,
		cycleTime = 4,
		respawnTime = 60,
		color = Color3.fromRGB(200, 200, 180),
		material = Enum.Material.Foil,
		size = Vector3.new(3.5, 3.5, 3.5),
		drops = { {itemId = "SilverOre", weight = 60}, {itemId = "GoldOre", weight = 40} }
	},
	GlowingCrystal = {
		name = "Glowing Crystal",
		capacity = 10,
		cycleTime = 5,
		respawnTime = 120,
		color = Color3.fromRGB(150, 200, 255),
		material = Enum.Material.Neon,
		size = Vector3.new(3, 5, 3),
		drops = { {itemId = "CrystalShard", weight = 70}, {itemId = "Ruby", weight = 15}, {itemId = "Sapphire", weight = 15} }
	},
	MeteoriteCore = {
		name = "Meteorite Core",
		capacity = 8,
		cycleTime = 6,
		respawnTime = 180,
		color = Color3.fromRGB(80, 50, 50),
		material = Enum.Material.CrackedLava,
		size = Vector3.new(4, 5, 4),
		drops = { {itemId = "Emerald", weight = 40}, {itemId = "Diamond", weight = 40}, {itemId = "StarFragment", weight = 20} }
	},
	VoidRiftCrystal = {
		name = "Void Rift Crystal",
		capacity = 5,
		cycleTime = 7,
		respawnTime = 300,
		color = Color3.fromRGB(100, 50, 150),
		material = Enum.Material.Neon,
		size = Vector3.new(5, 7, 5),
		drops = { {itemId = "PrismaticGeode", weight = 50}, {itemId = "CosmicSpark", weight = 50} }
	},
}

local SPAWN_GROUPS = {
	-- Outside the village walls (the village radius is 700 studs).
	-- These groups stay at least 800 studs from the village center.
	{ type = "RegularStone", count = 5, center = Vector3.new(0, 0, -900), radius = 100 },
	{ type = "RegularStone", count = 5, center = Vector3.new(900, 0, 0), radius = 100 },
	{ type = "RegularStone", count = 5, center = Vector3.new(-900, 0, 0), radius = 100 },
	
	-- Mid-range forests
	{ type = "GlimmeringRock", count = 4, center = Vector3.new(700, 0, -900), radius = 100 },
	{ type = "GlimmeringRock", count = 4, center = Vector3.new(-700, 0, 900), radius = 100 },
	
	-- Deep wilderness / caves
	{ type = "GlowingCrystal", count = 3, center = Vector3.new(0, 0, -1100), radius = 80 },
	{ type = "GlowingCrystal", count = 3, center = Vector3.new(1100, 0, 0), radius = 80 },
	
	-- Mountains
	{ type = "MeteoriteCore", count = 2, center = Vector3.new(0, 0, -1400), radius = 50 },
	{ type = "MeteoriteCore", count = 2, center = Vector3.new(-1400, 0, 0), radius = 50 },
	
	-- Crater (Boss area)
	{ type = "VoidRiftCrystal", count = 2, center = Vector3.new(800, 0, -600), radius = 40 },
}

local function RollDrop(dropsTable)
	local totalWeight = 0
	for _, entry in pairs(dropsTable) do
		totalWeight += entry.weight
	end

	local roll = math.random(1, totalWeight)
	local cumulative = 0
	for _, entry in pairs(dropsTable) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.itemId
		end
	end
	return nil
end

function MiningService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._framework = Framework
	self._playerData = Framework:GetService("PlayerDataService")
	self._mapGenerator = Framework:GetService("MapGeneratorService")
end

function MiningService:SpawnNode(nodeTypeKey, center, radius)
	local nodeType = NODE_TYPES[nodeTypeKey]
	if not nodeType then return end

	local offsetX = (math.random() - 0.5) * 2 * radius
	local offsetZ = (math.random() - 0.5) * 2 * radius
	local posX = center.X + offsetX
	local posZ = center.Z + offsetZ
	
	-- Check if mapGenerator exists (it might not be fully loaded or mocked)
	local posY = 0
	if self._mapGenerator and self._mapGenerator.GetGroundHeight then
		posY = self._mapGenerator:GetGroundHeight(posX, posZ)
	end

	local part = Instance.new("Part")
	part.Name = nodeType.name
	part.Size = nodeType.size
	part.Position = Vector3.new(posX, posY + (nodeType.size.Y / 2), posZ)
	part.Anchored = true
	part.Color = nodeType.color
	part.Material = nodeType.material
	part:SetAttribute("NodeType", nodeTypeKey)
	part:SetAttribute("Capacity", nodeType.capacity)
	part:SetAttribute("SpawnCenter", center)
	part:SetAttribute("SpawnRadius", radius)
	CollectionService:AddTag(part, "MiningNode")

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hold E to Mine continuously"
	prompt.ObjectText = string.format("%s (%d/%d)", nodeType.name, nodeType.capacity, nodeType.capacity)
	prompt.HoldDuration = 9999 -- Extremely high so it acts purely as a state toggle for Began/Ended
	prompt.MaxActivationDistance = 10
	prompt.Parent = part

	local nodesFolder = workspace:FindFirstChild("MiningNodes")
	if not nodesFolder then
		nodesFolder = Instance.new("Folder")
		nodesFolder.Name = "MiningNodes"
		nodesFolder.Parent = workspace
	end
	part.Parent = nodesFolder

	local barBg = Instance.new("BillboardGui")
	barBg.Name = "MiningBar"
	barBg.Size = UDim2.new(4, 0, 0.5, 0)
	barBg.StudsOffset = Vector3.new(0, (nodeType.size.Y / 2) + 2, 0)
	barBg.AlwaysOnTop = true
	barBg.Enabled = false
	
	local bg = Instance.new("Frame", barBg)
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bg.BorderSizePixel = 0
	
	local fill = Instance.new("Frame", bg)
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(200, 200, 50)
	fill.BorderSizePixel = 0
	barBg.Parent = part
	


	prompt.PromptButtonHoldBegan:Connect(function(player)
		if part:GetAttribute("Capacity") <= 0 then return end
		part:SetAttribute("MiningBy", player.UserId)
		barBg.Enabled = true
		
		task.spawn(function()
			while part:GetAttribute("MiningBy") == player.UserId do
				local elapsed = 0
				fill.Size = UDim2.new(0, 0, 1, 0)
				
				while elapsed < nodeType.cycleTime and part:GetAttribute("MiningBy") == player.UserId do
					local dt = task.wait(0.1)
					elapsed += dt
					fill.Size = UDim2.new(math.clamp(elapsed / nodeType.cycleTime, 0, 1), 0, 1, 0)
				end
				
				if part:GetAttribute("MiningBy") ~= player.UserId or not part.Parent then break end
				
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if not root or (root.Position - part.Position).Magnitude > 15 then
					part:SetAttribute("MiningBy", nil)
					break
				end

				local currentCap = part:GetAttribute("Capacity")
				if currentCap > 0 then
					currentCap -= 1
					part:SetAttribute("Capacity", currentCap)
					prompt.ObjectText = string.format("%s (%d/%d)", nodeType.name, currentCap, nodeType.capacity)
					
					-- Give item
					local dropId = RollDrop(nodeType.drops)
					if dropId and self._playerData then
						self._playerData:AddItem(player, dropId, 1)
					end

					if currentCap <= 0 then
						part:SetAttribute("MiningBy", nil)
						self:BreakNode(part, nodeTypeKey, center, radius)
						break
					end
				else
					part:SetAttribute("MiningBy", nil)
					break
				end
			end
			
			if part and part.Parent then
				barBg.Enabled = false
			end
		end)
	end)

	prompt.PromptButtonHoldEnded:Connect(function(player)
		if part:GetAttribute("MiningBy") == player.UserId then
			part:SetAttribute("MiningBy", nil)
		end
	end)

	table.insert(self._nodes, part)
	return part
end

function MiningService:BreakNode(part, nodeTypeKey, center, radius)
	local nodeType = NODE_TYPES[nodeTypeKey]
	if not nodeType then return end

	for i, n in pairs(self._nodes) do
		if n == part then
			table.remove(self._nodes, i)
			break
		end
	end

	part:Destroy()

	task.delay(nodeType.respawnTime, function()
		self:SpawnNode(nodeTypeKey, center, radius)
	end)
end

function MiningService:Start()
	for _, group in pairs(SPAWN_GROUPS) do
		for i = 1, group.count do
			self:SpawnNode(group.type, group.center, group.radius)
		end
	end
end

return MiningService
