local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local Services = Server:WaitForChild("Services")

local PlayerDataService = require(Services.PlayerDataService)
local CombatService = require(Services.CombatService)
local EnemyService = require(Services.EnemyService)
local InventoryService = require(Services.InventoryService)
local QuestService = require(Services.QuestService)
local ShopService = require(Services.ShopService)
local MapGeneratorService = require(Services.MapGeneratorService)
local EquipmentService = require(Services.EquipmentService)

local REMOTE_NAMES = {
	"Attack",
	"StatsUpdated",
	"InventoryUpdated",
	"RequestInventory",
	"UseItem",
	"OpenQuest",
	"AcceptQuest",
	"QuestUpdated",
	"OpenShop",
	"PurchaseItem",
	"Notification",
	"Dash",
}

local function createRemotes()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	for _, name in REMOTE_NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end

	return folder
end

local function setupWorld()
	-- Run massive map generator
	MapGeneratorService:Generate()

	local world = workspace:FindFirstChild("RPGWorld")
	if not world then
		world = Instance.new("Folder")
		world.Name = "RPGWorld"
		world.Parent = workspace
	end

	-- Setup Amazing RPG Lighting
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 15.5
	Lighting.Brightness = 2
	Lighting.GlobalShadows = true
	Lighting.Ambient = Color3.fromRGB(70, 70, 90)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 150)
	Lighting.ColorShift_Bottom = Color3.fromRGB(40, 40, 60)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 245, 230)
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1

	-- Atmosphere for depth and fog
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.3
		atmosphere.Offset = 0.25
		atmosphere.Color = Color3.fromRGB(199, 170, 107)
		atmosphere.Decay = Color3.fromRGB(92, 60, 104)
		atmosphere.Glare = 0.4
		atmosphere.Haze = 1.5
		atmosphere.Parent = Lighting
	end

	-- ColorCorrection for cinematic RPG look
	if not Lighting:FindFirstChildOfClass("ColorCorrectionEffect") then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Contrast = 0.15
		cc.Saturation = 0.2
		cc.TintColor = Color3.fromRGB(255, 250, 240)
		cc.Parent = Lighting
	end

	-- Bloom
	if not Lighting:FindFirstChildOfClass("BloomEffect") then
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.3
		bloom.Size = 24
		bloom.Threshold = 2
		bloom.Parent = Lighting
	end

	-- SunRays
	if not Lighting:FindFirstChildOfClass("SunRaysEffect") then
		local rays = Instance.new("SunRaysEffect")
		rays.Intensity = 0.05
		rays.Spread = 0.8
		rays.Parent = Lighting
	end

	local spawnZ = 135
	local spawnY = MapGeneratorService:GetGroundHeight(0, spawnZ)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(6, 1, 6)
	-- PERFECT HEIGHT ADJUSTMENT
	spawn.Position = Vector3.new(0, spawnY + 1.5, spawnZ)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Transparency = 1 -- Make it invisible so it looks seamless
	spawn.CanCollide = false
	spawn.Parent = world

	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		enemiesFolder = Instance.new("Folder")
		enemiesFolder.Name = "Enemies"
		enemiesFolder.Parent = workspace
	end

	local npcsFolder = workspace:FindFirstChild("NPCs")
	if not npcsFolder then
		npcsFolder = Instance.new("Folder")
		npcsFolder.Name = "NPCs"
		npcsFolder.Parent = workspace
	end

	local pickupsFolder = workspace:FindFirstChild("Pickups")
	if not pickupsFolder then
		pickupsFolder = Instance.new("Folder")
		pickupsFolder.Name = "Pickups"
		pickupsFolder.Parent = workspace
	end

	-- Remove default baseplate if present
	local defaultBaseplate = workspace:FindFirstChild("Baseplate")
	if defaultBaseplate then
		defaultBaseplate:Destroy()
	end
end

local remotes = createRemotes()
setupWorld()

PlayerDataService:Init(remotes)
CombatService:Init(PlayerDataService, EnemyService, remotes)
EnemyService:Init(PlayerDataService, QuestService, InventoryService, MapGeneratorService)
InventoryService:Init(PlayerDataService, CombatService, remotes)
QuestService:Init(PlayerDataService, remotes, MapGeneratorService)
ShopService:Init(PlayerDataService, CombatService, remotes, MapGeneratorService)
EquipmentService:Init()

PlayerDataService:Start()
CombatService:Start()
EnemyService:Start()
InventoryService:Start()
QuestService:Start()
ShopService:Start()
EquipmentService:Start()

print("[SimpleRPG] Server started successfully.")

-- Fix for players spawning in the void before the map finishes generating
for _, player in game:GetService("Players"):GetPlayers() do
	player:LoadCharacter()
end
