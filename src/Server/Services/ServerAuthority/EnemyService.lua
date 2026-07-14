local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MonsterConfig = require(Shared.Config.MonsterConfig)
local MobRarityConfig = require(Shared.Config.MobRarityConfig)
local Items = require(Shared.Config.Items)
local LootTables = require(Shared.Config.LootTables)

local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local EnemyStateMachine = require(Server.AI.EnemyStateMachine)

local EnemyService = {}
EnemyService._playerData = nil
EnemyService._questService = nil
EnemyService._inventoryService = nil
EnemyService._experienceService = nil
EnemyService._framework = nil
EnemyService._playMonsterAnimRemote = nil
EnemyService._enemies = {}
EnemyService._attackCooldowns = {}

local SPAWN_GROUPS = {
	---------------------------------------------------------------------------
	-- ZONE 1: Village outskirts (just outside gates, dist ~750-900)
	-- Low-level mobs for beginners leaving the village
	---------------------------------------------------------------------------
	-- North gate area
	{ type = "Slime", count = 4, center = Vector3.new(0, 3, -800), radius = 30 },
	{ type = "Slime", count = 3, center = Vector3.new(80, 3, -820), radius = 25 },
	-- South gate area
	{ type = "Slime", count = 4, center = Vector3.new(0, 3, 800), radius = 30 },
	{ type = "Goblin", count = 3, center = Vector3.new(-80, 3, 820), radius = 25 },
	-- East gate area
	{ type = "Slime", count = 3, center = Vector3.new(800, 3, 0), radius = 25 },
	{ type = "Goblin", count = 3, center = Vector3.new(820, 3, 80), radius = 25 },
	-- West gate area
	{ type = "Goblin", count = 4, center = Vector3.new(-800, 3, 0), radius = 30 },
	{ type = "Slime", count = 3, center = Vector3.new(-820, 3, -80), radius = 25 },

	---------------------------------------------------------------------------
	-- ZONE 2: Near forests (dist ~900-1100)
	-- Mid-level mobs roaming the tree lines
	---------------------------------------------------------------------------
	-- Northeast forest
	{ type = "Goblin", count = 3, center = Vector3.new(700, 3, -900), radius = 35 },
	{ type = "Spider", count = 4, center = Vector3.new(900, 3, -700), radius = 30 },
	-- Northwest forest
	{ type = "Spider", count = 3, center = Vector3.new(-700, 3, -900), radius = 30 },
	{ type = "Goblin", count = 3, center = Vector3.new(-900, 3, -700), radius = 35 },
	-- Southeast forest
	{ type = "Goblin", count = 3, center = Vector3.new(700, 3, 900), radius = 35 },
	{ type = "Spider", count = 4, center = Vector3.new(900, 3, 700), radius = 30 },
	-- Southwest forest
	{ type = "Spider", count = 3, center = Vector3.new(-700, 3, 900), radius = 30 },
	{ type = "Goblin", count = 3, center = Vector3.new(-900, 3, 700), radius = 35 },

	---------------------------------------------------------------------------
	-- ZONE 3: Deep wilderness (dist ~1000-1300)
	-- Higher-level mobs in the thick forests
	---------------------------------------------------------------------------
	-- North deep forest
	{ type = "DireWolf", count = 3, center = Vector3.new(0, 3, -1100), radius = 50 },
	{ type = "Skeleton", count = 3, center = Vector3.new(300, 3, -1050), radius = 35 },
	{ type = "Spider", count = 3, center = Vector3.new(-300, 3, -1050), radius = 35 },
	-- South deep forest
	{ type = "DireWolf", count = 3, center = Vector3.new(0, 3, 1100), radius = 50 },
	{ type = "Skeleton", count = 3, center = Vector3.new(-300, 3, 1050), radius = 35 },
	{ type = "Orc", count = 2, center = Vector3.new(300, 3, 1050), radius = 40 },
	-- East deep forest
	{ type = "Orc", count = 3, center = Vector3.new(1100, 3, 0), radius = 45 },
	{ type = "Skeleton", count = 3, center = Vector3.new(1050, 3, 300), radius = 35 },
	{ type = "DireWolf", count = 2, center = Vector3.new(1050, 3, -300), radius = 40 },
	-- West deep forest
	{ type = "Orc", count = 3, center = Vector3.new(-1100, 3, 0), radius = 45 },
	{ type = "Skeleton", count = 3, center = Vector3.new(-1050, 3, -300), radius = 35 },
	{ type = "DireWolf", count = 2, center = Vector3.new(-1050, 3, 300), radius = 40 },

	---------------------------------------------------------------------------
	-- ZONE 4: Mountain foothills & highlands (dist ~1300-1600)
	-- Elite mobs where terrain gets rocky and high
	---------------------------------------------------------------------------
	-- North mountains
	{ type = "SkeletonKnight", count = 2, center = Vector3.new(0, 3, -1400), radius = 50 },
	{ type = "Orc", count = 3, center = Vector3.new(400, 3, -1350), radius = 40 },
	{ type = "Skeleton", count = 3, center = Vector3.new(-400, 3, -1350), radius = 40 },
	-- South mountains
	{ type = "SkeletonKnight", count = 2, center = Vector3.new(0, 3, 1400), radius = 50 },
	{ type = "Orc", count = 3, center = Vector3.new(-400, 3, 1350), radius = 40 },
	{ type = "DireWolf", count = 3, center = Vector3.new(400, 3, 1350), radius = 40 },
	-- East mountains
	{ type = "SkeletonKnight", count = 2, center = Vector3.new(1400, 3, 0), radius = 50 },
	{ type = "Orc", count = 3, center = Vector3.new(1350, 3, 400), radius = 40 },
	-- West mountains
	{ type = "SkeletonKnight", count = 2, center = Vector3.new(-1400, 3, 0), radius = 50 },
	{ type = "Orc", count = 3, center = Vector3.new(-1350, 3, -400), radius = 40 },

	---------------------------------------------------------------------------
	-- ZONE 5: Flying monsters (open sky above forests & mountains)
	-- Wyverns patrol the eastern skies, Griffins the western skies
	---------------------------------------------------------------------------
	-- Wyverns — eastern sky (above the east mountains & forests)
	{ type = "Wyvern", count = 2, center = Vector3.new(1200, 3, -200), radius = 80 },
	{ type = "Wyvern", count = 2, center = Vector3.new(1000, 3, 500), radius = 70 },
	-- Griffins — western sky (above the west forests, visible in daylight)
	{ type = "Griffin", count = 2, center = Vector3.new(-1200, 3, 200), radius = 80 },
	{ type = "Griffin", count = 2, center = Vector3.new(-1000, 3, -500), radius = 70 },
	-- Wyvern & Griffin roaming the far corners
	{ type = "Wyvern", count = 1, center = Vector3.new(600, 3, -1400), radius = 60 },
	{ type = "Griffin", count = 1, center = Vector3.new(-600, 3, 1400), radius = 60 },

	---------------------------------------------------------------------------
	-- ZONE 6: Boss area — The Crater (centered at ~800, -600, radius 250)
	-- The Dragon guards this ancient volcanic crater
	---------------------------------------------------------------------------
	{ type = "Dragon", count = 1, center = Vector3.new(800, 3, -600), radius = 40 },
	-- Minions guarding the crater rim
	{ type = "SkeletonKnight", count = 2, center = Vector3.new(650, 3, -500), radius = 30 },
	{ type = "Orc", count = 2, center = Vector3.new(950, 3, -700), radius = 30 },
}


function EnemyService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._framework = Framework
	self._playerData = Framework:GetService("PlayerDataService")
	self._questService = Framework:GetService("QuestService")
	self._inventoryService = Framework:GetService("InventoryService")
	self._karmaService = Framework:GetService("KarmaService")
	self._experienceService = Framework:GetService("ExperienceService")
	self._treasureChestService = Framework:GetService("TreasureChestService")
	self._mapGenerator = Framework:GetService("MapGeneratorService")
	self._playMonsterAnimRemote = Framework:GetRemote("PlayMonsterAnimation")
end

function EnemyService:CreateHealthBar(enemy, maxHealth)
	local root = enemy.PrimaryPart
	if not root then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBar"
	billboard.Size = UDim2.new(4, 0, 0.5, 0)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bg.BorderSizePixel = 0
	bg.Parent = billboard

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	fill.BorderSizePixel = 0
	fill.Parent = bg
end

function EnemyService:UpdateHealthBar(enemy)
	local health = enemy:GetAttribute("Health") or 0
	local maxHealth = enemy:GetAttribute("MaxHealth") or 1
	local root = enemy.PrimaryPart
	if not root then
		return
	end

	local billboard = root:FindFirstChild("HealthBar")
	if billboard then
		local fill = billboard.Background.Fill
		fill.Size = UDim2.new(math.clamp(health / maxHealth, 0, 1), 0, 1, 0)
	end
end

function EnemyService:CreateEnemy(enemyId, position, spawnCenter, spawnRadius)
	local config = MonsterConfig.Get(enemyId)
	if not config then return nil end

	local rarityConfig = MobRarityConfig[config.rarity] or MobRarityConfig.Common
	local maxHealth = math.floor(config.maxHealth * rarityConfig.hpScale)
	local damage = math.floor(config.damage * rarityConfig.damageScale)
	local defense = math.floor(config.defense * rarityConfig.defenseScale)
	local xpReward = math.floor(config.experienceReward * rarityConfig.xpScale)

	local skinColor = config.color or Color3.fromRGB(80, 160, 60)
	local mat = Enum.Material.SmoothPlastic

	local model = Instance.new("Model")
	model.Name = config.name

	---------------------------------------------------------------------------
	-- Helper: create a part with standard properties
	---------------------------------------------------------------------------
	local function makePart(name, size, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Anchored = false
		p.CanCollide = canCollide or false
		p.Color = skinColor
		p.Material = mat
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	---------------------------------------------------------------------------
	-- Helper: create a Motor6D joint
	---------------------------------------------------------------------------
	local function makeMotor(name, part0, part1, c0, c1)
		local motor = Instance.new("Motor6D")
		motor.Name = name
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = c0
		motor.C1 = c1 or CFrame.new()
		motor.Parent = part1
		return motor
	end

	---------------------------------------------------------------------------
	-- Standard R15 part sizes
	---------------------------------------------------------------------------
	local hrp       = makePart("HumanoidRootPart", Vector3.new(2, 2, 1), true)
	hrp.Transparency = 1

	local lowerTorso  = makePart("LowerTorso",      Vector3.new(2, 0.4, 1))
	local upperTorso  = makePart("UpperTorso",       Vector3.new(2, 1.6, 1))
	local head        = makePart("Head",             Vector3.new(2, 1, 1))

	-- Add a face mesh so it looks like a standard head
	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	headMesh.Parent = head

	local leftUpperArm  = makePart("LeftUpperArm",  Vector3.new(1, 1.2, 1))
	local leftLowerArm  = makePart("LeftLowerArm",  Vector3.new(1, 1.2, 1))
	local leftHand       = makePart("LeftHand",      Vector3.new(1, 0.3, 1))

	local rightUpperArm = makePart("RightUpperArm", Vector3.new(1, 1.2, 1))
	local rightLowerArm = makePart("RightLowerArm", Vector3.new(1, 1.2, 1))
	local rightHand      = makePart("RightHand",     Vector3.new(1, 0.3, 1))

	local leftUpperLeg  = makePart("LeftUpperLeg",  Vector3.new(1, 1.3, 1))
	local leftLowerLeg  = makePart("LeftLowerLeg",  Vector3.new(1, 1.3, 1))
	local leftFoot       = makePart("LeftFoot",      Vector3.new(1, 0.3, 1))

	local rightUpperLeg = makePart("RightUpperLeg", Vector3.new(1, 1.3, 1))
	local rightLowerLeg = makePart("RightLowerLeg", Vector3.new(1, 1.3, 1))
	local rightFoot      = makePart("RightFoot",     Vector3.new(1, 0.3, 1))

	---------------------------------------------------------------------------
	-- Motor6D joints (standard R15 hierarchy)
	---------------------------------------------------------------------------
	makeMotor("Root",          hrp,          lowerTorso,
		CFrame.new(),               CFrame.new())

	makeMotor("Waist",         lowerTorso,   upperTorso,
		CFrame.new(0, 0.2, 0),      CFrame.new(0, -0.8, 0))

	makeMotor("Neck",          upperTorso,   head,
		CFrame.new(0, 0.8, 0),      CFrame.new(0, -0.5, 0))

	-- Left Arm
	makeMotor("LeftShoulder",  upperTorso,   leftUpperArm,
		CFrame.new(-1, 0.5, 0),     CFrame.new(0.5, 0.6, 0))

	makeMotor("LeftElbow",     leftUpperArm, leftLowerArm,
		CFrame.new(0, -0.6, 0),     CFrame.new(0, 0.6, 0))

	makeMotor("LeftWrist",     leftLowerArm, leftHand,
		CFrame.new(0, -0.6, 0),     CFrame.new(0, 0.15, 0))

	-- Right Arm
	makeMotor("RightShoulder", upperTorso,   rightUpperArm,
		CFrame.new(1, 0.5, 0),      CFrame.new(-0.5, 0.6, 0))

	makeMotor("RightElbow",    rightUpperArm, rightLowerArm,
		CFrame.new(0, -0.6, 0),     CFrame.new(0, 0.6, 0))

	makeMotor("RightWrist",    rightLowerArm, rightHand,
		CFrame.new(0, -0.6, 0),     CFrame.new(0, 0.15, 0))

	-- Left Leg
	makeMotor("LeftHip",       lowerTorso,   leftUpperLeg,
		CFrame.new(-0.5, -0.2, 0),  CFrame.new(0, 0.65, 0))

	makeMotor("LeftKnee",      leftUpperLeg, leftLowerLeg,
		CFrame.new(0, -0.65, 0),    CFrame.new(0, 0.65, 0))

	makeMotor("LeftAnkle",     leftLowerLeg, leftFoot,
		CFrame.new(0, -0.65, 0),    CFrame.new(0, 0.15, 0))

	-- Right Leg
	makeMotor("RightHip",      lowerTorso,   rightUpperLeg,
		CFrame.new(0.5, -0.2, 0),   CFrame.new(0, 0.65, 0))

	makeMotor("RightKnee",     rightUpperLeg, rightLowerLeg,
		CFrame.new(0, -0.65, 0),    CFrame.new(0, 0.65, 0))

	makeMotor("RightAnkle",    rightLowerLeg, rightFoot,
		CFrame.new(0, -0.65, 0),    CFrame.new(0, 0.15, 0))

	---------------------------------------------------------------------------
	-- Humanoid
	---------------------------------------------------------------------------
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
	humanoid.WalkSpeed = config.moveSpeed or 12
	humanoid.HipHeight = config.isFlying and 12 or 2
	humanoid.Parent = model

	-- Animator is required for animations; create explicitly to avoid race conditions
	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	model.PrimaryPart = hrp

	-- Position the model
	hrp.CFrame = CFrame.new(position)

	if config.isFlying then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		humanoid.AutoRotate = false

		local attachment = Instance.new("Attachment")
		attachment.Name = "AlignAttachment"
		attachment.Parent = hrp

		local alignPos = Instance.new("AlignPosition")
		alignPos.Name = "FlyAlignPosition"
		alignPos.Attachment0 = attachment
		alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
		alignPos.MaxForce = 100000
		alignPos.MaxVelocity = config.moveSpeed or 12
		alignPos.Responsiveness = 20
		alignPos.Position = position
		alignPos.Parent = hrp

		local alignOri = Instance.new("AlignOrientation")
		alignOri.Name = "FlyAlignOrientation"
		alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
		alignOri.Attachment0 = attachment
		alignOri.MaxTorque = 100000
		alignOri.Responsiveness = 20
		alignOri.CFrame = hrp.CFrame
		alignOri.Parent = hrp
	end

	model:SetAttribute("EnemyType", config.id)
	model:SetAttribute("Level", config.level or 1)
	model:SetAttribute("Rarity", config.rarity or "Common")
	model:SetAttribute("DisplayName", config.name)
	model:SetAttribute("Health", maxHealth)
	model:SetAttribute("MaxHealth", maxHealth)
	model:SetAttribute("PhysicalResistance", defense)
	model:SetAttribute("MagicalResistance", config.magicalResistance or defense)
	model:SetAttribute("Evasion", config.evasion or 0)
	model:SetAttribute("CritReduction", config.critReduction or 0)
	model:SetAttribute("Attack", damage)
	model:SetAttribute("XpReward", xpReward)
	model:SetAttribute("GoldReward", config.goldReward or 0)
	model:SetAttribute("RespawnTime", config.respawnTime or 5)

	model:SetAttribute("SpawnCenter", spawnCenter or position)
	model:SetAttribute("SpawnRadius", spawnRadius or 10)

	CollectionService:AddTag(model, "Enemy")
	self:CreateHealthBar(model, maxHealth)

	EnemyStateMachine.InitEnemy(model, position, config)

	model.Parent = workspace:FindFirstChild("Enemies") or workspace
	table.insert(self._enemies, model)
	return model
end

function EnemyService:SpawnEnemies()
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		enemiesFolder = Instance.new("Folder")
		enemiesFolder.Name = "Enemies"
		enemiesFolder.Parent = workspace
	end

	for _, group in SPAWN_GROUPS do
		for i = 1, group.count do
			local offsetX = (math.random() - 0.5) * 2 * group.radius
			local offsetZ = (math.random() - 0.5) * 2 * group.radius
			local posX = group.center.X + offsetX
			local posZ = group.center.Z + offsetZ
			local y = self._mapGenerator:GetGroundHeight(posX, posZ)
			self:CreateEnemy(group.type, Vector3.new(posX, y + 3, posZ), group.center, group.radius)
		end
	end
end

function EnemyService:GetNearestPlayer(position, range)
	local nearestPlayer = nil
	local nearestDistance = range

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local distance = (root.Position - position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestPlayer = player
			end
		end
	end

	return nearestPlayer, nearestDistance
end

function EnemyService:DamageEnemy(enemy, baseDamage, attackerStats, attacker, damageType)
	if not enemy.Parent then
		return
	end

	local health = enemy:GetAttribute("Health") or 0
	if health <= 0 then return end

	local targetStats = {
		maxHp = enemy:GetAttribute("MaxHealth") or 50,
		defense = enemy:GetAttribute("PhysicalResistance") or 0,
		magicalResistance = enemy:GetAttribute("MagicalResistance") or 0,
		evasion = enemy:GetAttribute("Evasion") or 0,
		critReduction = enemy:GetAttribute("CritReduction") or 0,
	}

	local DamageCalculator = require(ReplicatedStorage.Shared.Combat.DamageCalculator)
	local result = DamageCalculator.ComputeHit(baseDamage, attackerStats, targetStats, damageType or "physical")

	if not result.isMiss then
		local finalDamage = result.damage
		if enemy:GetAttribute("IsStunned") then
			finalDamage = math.floor(finalDamage * 1.2)
		end
		health = math.max(0, health - finalDamage)
		enemy:SetAttribute("Health", health)

		if attacker and attacker:IsA("Player") then
			enemy:SetAttribute("AggroTarget", attacker.UserId)
		end

		self:UpdateHealthBar(enemy)
		
		local ok, Framework = pcall(function() return require(game:GetService("ReplicatedStorage").Shared.Framework) end)
		if ok then
			local combatEvent = Framework:GetRemote("CombatEvents")
			combatEvent:FireAllClients("Damage", enemy, result.damage, result.isCrit, attacker)
		end
		
		-- Optionally fire a remote to show damage numbers here
		
		if health <= 0 then
			self:OnEnemyKilled(enemy, attacker)
		end
	end
end

function EnemyService:CreatePickup(position, itemId, rarity)
	local item = Items[itemId]
	if not item then
		return
	end

	local part = Instance.new("Part")
	part.Name = itemId .. "Pickup"
	part.Size = Vector3.new(1.2, 1.2, 1.2)
	part.Position = position + Vector3.new(0, 1, 0)
	part.Anchored = true
	part.CanCollide = false
	part.Color = item.color
	part.Material = Enum.Material.Neon
	part:SetAttribute("ItemId", itemId)
	if rarity then
		part:SetAttribute("MaterialRarity", rarity)
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = item.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.Parent = part

	local pickupsFolder = workspace:FindFirstChild("Pickups")
	if not pickupsFolder then
		pickupsFolder = Instance.new("Folder")
		pickupsFolder.Name = "Pickups"
		pickupsFolder.Parent = workspace
	end
	part.Parent = pickupsFolder
	return part
end

function EnemyService:OnEnemyKilled(enemy, killer)
	local enemyId = enemy:GetAttribute("EnemyType") or "Goblin"
	local config = MonsterConfig.Get(enemyId)
	local root = enemy.PrimaryPart
	local deathPosition = root and root.Position or Vector3.new()

	if killer and config then
		local xpReward = enemy:GetAttribute("XpReward") or config.experienceReward or 0
		local goldReward = enemy:GetAttribute("GoldReward") or config.goldReward or 0

		if self._experienceService then
			self._experienceService:GrantExperience(killer, xpReward, "monster")
		else
			self._playerData:AddXP(killer, xpReward)
		end
		self._playerData:AddCoins(killer, goldReward)
		if self._questService then
			self._questService:OnEnemyKilled(killer, config.id)
		end
		if self._karmaService then
			self._karmaService:OnMobKilled(killer)
		end
	end

	if config and math.random() < config.dropChance and root then
		local lootItem = nil
		if config.lootTableId then
			lootItem = LootTables.Roll(config.lootTableId)
		end
		lootItem = lootItem or config.dropItem
		if lootItem then
			local itemConfig = Items[lootItem]
			if itemConfig and itemConfig.supportsRarity then
				local MaterialRarityConfig = require(Shared.Config.MaterialRarityConfig)
				local rarity = MaterialRarityConfig.Roll()
				self:CreatePickup(deathPosition, lootItem, rarity)
			else
				self:CreatePickup(deathPosition, lootItem)
			end
		end
	end

	if config and config.mobType == "Boss" then
		if self._treasureChestService then
			self._treasureChestService:SpawnBossChest(deathPosition, enemyId)
		end
	end

	local spawnCenter = enemy:GetAttribute("SpawnCenter") or Vector3.new()
	local spawnRadius = enemy:GetAttribute("SpawnRadius") or 10
	local respawnTime = enemy:GetAttribute("RespawnTime") or (config and config.respawnTime) or 5

	for i, e in self._enemies do
		if e == enemy then
			table.remove(self._enemies, i)
			break
		end
	end

	enemy:Destroy()

	-- Respawn near the original group spawn point after a delay
	task.delay(respawnTime, function()
		local offsetX = (math.random() - 0.5) * 2 * spawnRadius
		local offsetZ = (math.random() - 0.5) * 2 * spawnRadius
		local posX = spawnCenter.X + offsetX
		local posZ = spawnCenter.Z + offsetZ
		local y = self._mapGenerator:GetGroundHeight(posX, posZ)
		self:CreateEnemy(enemyId, Vector3.new(posX, y + 3, posZ), spawnCenter, spawnRadius)
	end)
end

function EnemyService:RunAI()
	local context = {
		getPlayerByUserId = function(userId)
			return Players:GetPlayerByUserId(userId)
		end,
		getNearestPlayer = function(position, range)
			return self:GetNearestPlayer(position, range)
		end,
		tryAttack = function(enemy, targetPlayer, enemyConfig)
			local now = tick()
			local key = enemy
			if not self._attackCooldowns[key] or now - self._attackCooldowns[key] >= enemyConfig.attackCooldown then
				self._attackCooldowns[key] = now

				-- Pick a random attack animation and broadcast to all clients
				local attackKeys = enemyConfig.attackAnimKeys
				local animKey = attackKeys and #attackKeys > 0
					and attackKeys[math.random(#attackKeys)] or nil
				if animKey and self._playMonsterAnimRemote then
					self._playMonsterAnimRemote:FireAllClients(enemy, animKey)
				end

				-- Delay damage by attackHitTime so it syncs with the animation hit moment
				local hitTime = enemyConfig.attackHitTime or 0.3
				task.delay(hitTime, function()
					-- Guard: enemy or target may have been removed during the delay
					if not enemy.Parent then return end
					if not targetPlayer.Parent then return end
					local targetChar = targetPlayer.Character
					local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
					local enemyRoot = enemy.PrimaryPart
					if not targetRoot or not enemyRoot then return end
					
					local flatDist = math.sqrt((enemyRoot.Position.X - targetRoot.Position.X)^2 + (enemyRoot.Position.Z - targetRoot.Position.Z)^2)
					local vertDist = math.abs(enemyRoot.Position.Y - targetRoot.Position.Y)

					-- If the player ran completely out of a reasonable dodge range, the attack misses
					if flatDist > (enemyConfig.attackRange or 6) * 1.5 or vertDist > 20 then
						return
					end

					local attack = enemy:GetAttribute("Attack") or enemyConfig.PhysicalDamage
					self._playerData:Damage(targetPlayer, attack, enemy, false, enemyConfig.damageType)

					if enemyConfig.passiveSkill and enemyConfig.passiveSkill.statusEffect then
						local skill = enemyConfig.passiveSkill
						local lastProcTime = enemy:GetAttribute("LastPassiveProc") or 0
						local currentTime = os.time()
						if currentTime - lastProcTime >= (skill.cooldown or 5) then
							if math.random(1, 100) <= (skill.procChance or 3) then
								local BuffService = self._framework:GetService("BuffService")
								if BuffService then
									local customIntensity = 1
									local targetHumanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
									if targetHumanoid then
										local maxHp = targetHumanoid.MaxHealth
										if skill.statusEffect == "Burn" then
											customIntensity = math.max(1, math.floor(maxHp * 0.05))
										elseif skill.statusEffect == "Poison" then
											customIntensity = math.max(1, math.floor(maxHp * 0.02))
										elseif skill.statusEffect == "Bleed" then
											customIntensity = math.max(1, math.floor(maxHp * 0.01))
										elseif skill.statusEffect == "WindGust" then
											local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
											local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
											if targetRoot and enemyRoot then
												local direction = (targetRoot.Position - enemyRoot.Position).Unit
												targetRoot:ApplyImpulse(direction * 1500 + Vector3.new(0, 1000, 0))
											end
										end
									end
									
									if skill.statusEffect == "Screech" then
										BuffService:ApplyEffect(targetPlayer, "Stun", 3, enemy, customIntensity)
									elseif skill.statusEffect ~= "WindGust" then
										BuffService:ApplyEffect(targetPlayer, skill.statusEffect, 3, enemy, customIntensity)
									end
									enemy:SetAttribute("LastPassiveProc", currentTime)
								end
							end
						end
					elseif enemyConfig.statusEffect then
						local BuffService = self._framework:GetService("BuffService")
						if BuffService then
							BuffService:ApplyEffect(targetPlayer, enemyConfig.statusEffect, 3, enemy, 1)
						end
					end
				end)
			end
		end,
	}

	for _, enemy in self._enemies do
		if enemy.Parent and enemy:GetAttribute("Health") > 0 then
			local root = enemy.PrimaryPart
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			local enemyId = enemy:GetAttribute("EnemyType") or "Goblin"
			local enemyConfig = MonsterConfig.Get(enemyId)
			if root and humanoid and enemyConfig then
				EnemyStateMachine.Tick(enemy, humanoid, root, enemyConfig, context)
			end
		end
	end
end

function EnemyService:Start()
	self:SpawnEnemies()

	task.spawn(function()
		while true do
			self:RunAI()
			task.wait(0.25)
		end
	end)
end

return EnemyService
