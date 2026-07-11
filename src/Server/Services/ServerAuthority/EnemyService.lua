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
	-- North forest
	{ type = "Orc", count = 3, center = Vector3.new(0, 3, -900), radius = 40 },
	{ type = "Goblin", count = 4, center = Vector3.new(200, 3, -950), radius = 30 },
	{ type = "Spider", count = 4, center = Vector3.new(-200, 3, -950), radius = 35 },
	{ type = "Skeleton", count = 3, center = Vector3.new(100, 3, -1100), radius = 30 },
	{ type = "DireWolf", count = 2, center = Vector3.new(-100, 3, -1100), radius = 40 },

	-- South forest
	{ type = "Slime", count = 5, center = Vector3.new(0, 3, 900), radius = 25 },
	{ type = "Goblin", count = 3, center = Vector3.new(200, 3, 950), radius = 30 },
	{ type = "DireWolf", count = 3, center = Vector3.new(-200, 3, 950), radius = 35 },

	-- East mountains
	{ type = "Orc", count = 2, center = Vector3.new(900, 3, 0), radius = 40 },
	{ type = "Spider", count = 3, center = Vector3.new(1000, 3, 200), radius = 30 },
	{ type = "Skeleton", count = 4, center = Vector3.new(1000, 3, -200), radius = 35 },

	-- West mountains
	{ type = "Orc", count = 2, center = Vector3.new(-900, 3, 0), radius = 40 },
	{ type = "Goblin", count = 4, center = Vector3.new(-1000, 3, 200), radius = 30 },
	{ type = "Skeleton", count = 3, center = Vector3.new(-1000, 3, -200), radius = 35 },

	-- Wilderness corners
	{ type = "DireWolf", count = 3, center = Vector3.new(700, 3, -700), radius = 40 },
	{ type = "Spider", count = 4, center = Vector3.new(-700, 3, -700), radius = 30 },
	{ type = "Slime", count = 5, center = Vector3.new(700, 3, 700), radius = 25 },
	{ type = "Goblin", count = 4, center = Vector3.new(-700, 3, 700), radius = 30 },
}

-- Increased aggro range so enemies actively hunt nearby players
local ACTIVE_AGGRO_RANGE = 40

function EnemyService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._framework = Framework
	self._playerData = Framework:GetService("PlayerDataService")
	self._questService = Framework:GetService("QuestService")
	self._inventoryService = Framework:GetService("InventoryService")
	self._karmaService = Framework:GetService("KarmaService")
	self._experienceService = Framework:GetService("ExperienceService")
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

	local model = Instance.new("Model")
	model.Name = config.name

	local skinColor = config.color or Color3.fromRGB(80, 160, 60)
	local h, s, v = skinColor:ToHSV()
	local darkSkin = Color3.fromHSV(h, s, math.max(0, v - 0.2))
	local mat = Enum.Material.SmoothPlastic

	-- Torso (main body)
	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2, 2.2, 1.2)
	torso.Position = position
	torso.Anchored = false
	torso.CanCollide = true
	torso.Color = skinColor
	torso.Material = mat
	torso.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2.2, 2.2, 2.2)
	head.Color = skinColor
	head.Material = mat
	head.Anchored = false
	head.CanCollide = false
	head.CFrame = torso.CFrame * CFrame.new(0, 2.1, 0)
	head.Parent = model

	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = torso
	headWeld.Part1 = head
	headWeld.Parent = head

	-- Left Eye
	local leftEye = Instance.new("Part")
	leftEye.Name = "LeftEye"
	leftEye.Shape = Enum.PartType.Ball
	leftEye.Size = Vector3.new(0.5, 0.55, 0.3)
	leftEye.Color = Color3.fromRGB(255, 50, 30)
	leftEye.Material = Enum.Material.Neon
	leftEye.Anchored = false
	leftEye.CanCollide = false
	leftEye.CFrame = head.CFrame * CFrame.new(-0.4, 0.15, -0.85)
	leftEye.Parent = model
	local leWeld = Instance.new("WeldConstraint")
	leWeld.Part0 = head
	leWeld.Part1 = leftEye
	leWeld.Parent = leftEye

	-- Right Eye
	local rightEye = Instance.new("Part")
	rightEye.Name = "RightEye"
	rightEye.Shape = Enum.PartType.Ball
	rightEye.Size = Vector3.new(0.5, 0.55, 0.3)
	rightEye.Color = Color3.fromRGB(255, 50, 30)
	rightEye.Material = Enum.Material.Neon
	rightEye.Anchored = false
	rightEye.CanCollide = false
	rightEye.CFrame = head.CFrame * CFrame.new(0.4, 0.15, -0.85)
	rightEye.Parent = model
	local reWeld = Instance.new("WeldConstraint")
	reWeld.Part0 = head
	reWeld.Part1 = rightEye
	reWeld.Parent = rightEye

	-- Pupils
	for _, eyePart in {leftEye, rightEye} do
		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Shape = Enum.PartType.Ball
		pupil.Size = Vector3.new(0.2, 0.25, 0.15)
		pupil.Color = Color3.fromRGB(20, 20, 20)
		pupil.Material = mat
		pupil.Anchored = false
		pupil.CanCollide = false
		pupil.CFrame = eyePart.CFrame * CFrame.new(0, 0, -0.1)
		pupil.Parent = model
		local pWeld = Instance.new("WeldConstraint")
		pWeld.Part0 = eyePart
		pWeld.Part1 = pupil
		pWeld.Parent = pupil
	end

	-- Mouth (wide grin)
	local mouth = Instance.new("Part")
	mouth.Name = "Mouth"
	mouth.Size = Vector3.new(0.9, 0.2, 0.15)
	mouth.Color = Color3.fromRGB(30, 30, 30)
	mouth.Material = mat
	mouth.Anchored = false
	mouth.CanCollide = false
	mouth.CFrame = head.CFrame * CFrame.new(0, -0.4, -0.95)
	mouth.Parent = model
	local mWeld = Instance.new("WeldConstraint")
	mWeld.Part0 = head
	mWeld.Part1 = mouth
	mWeld.Parent = mouth

	-- Left Ear (pointy)
	local leftEar = Instance.new("WedgePart")
	leftEar.Name = "LeftEar"
	leftEar.Size = Vector3.new(0.3, 0.8, 1.2)
	leftEar.Color = darkSkin
	leftEar.Material = mat
	leftEar.Anchored = false
	leftEar.CanCollide = false
	leftEar.CFrame = head.CFrame * CFrame.new(-1.2, 0.2, 0) * CFrame.Angles(0, 0, math.rad(-30))
	leftEar.Parent = model
	local learWeld = Instance.new("WeldConstraint")
	learWeld.Part0 = head
	learWeld.Part1 = leftEar
	learWeld.Parent = leftEar

	-- Right Ear (pointy)
	local rightEar = Instance.new("WedgePart")
	rightEar.Name = "RightEar"
	rightEar.Size = Vector3.new(0.3, 0.8, 1.2)
	rightEar.Color = darkSkin
	rightEar.Material = mat
	rightEar.Anchored = false
	rightEar.CanCollide = false
	rightEar.CFrame = head.CFrame * CFrame.new(1.2, 0.2, 0) * CFrame.Angles(0, 0, math.rad(30))
	rightEar.Parent = model
	local rearWeld = Instance.new("WeldConstraint")
	rearWeld.Part0 = head
	rearWeld.Part1 = rightEar
	rearWeld.Parent = rightEar

	-- Left Arm
	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftArm"
	leftArm.Size = Vector3.new(0.8, 1.8, 0.8)
	leftArm.Color = skinColor
	leftArm.Material = mat
	leftArm.Anchored = false
	leftArm.CanCollide = false
	leftArm.CFrame = torso.CFrame * CFrame.new(-1.4, -0.2, 0)
	leftArm.Parent = model
	local laWeld = Instance.new("WeldConstraint")
	laWeld.Part0 = torso
	laWeld.Part1 = leftArm
	laWeld.Parent = leftArm

	-- Right Arm
	local rightArm = Instance.new("Part")
	rightArm.Name = "RightArm"
	rightArm.Size = Vector3.new(0.8, 1.8, 0.8)
	rightArm.Color = skinColor
	rightArm.Material = mat
	rightArm.Anchored = false
	rightArm.CanCollide = false
	rightArm.CFrame = torso.CFrame * CFrame.new(1.4, -0.2, 0)
	rightArm.Parent = model
	local raWeld = Instance.new("WeldConstraint")
	raWeld.Part0 = torso
	raWeld.Part1 = rightArm
	raWeld.Parent = rightArm

	-- Club weapon in right hand
	local club = Instance.new("Part")
	club.Name = "Club"
	club.Size = Vector3.new(0.5, 2.5, 0.5)
	club.Color = Color3.fromRGB(100, 70, 40)
	club.Material = Enum.Material.Wood
	club.Anchored = false
	club.CanCollide = false
	club.CFrame = rightArm.CFrame * CFrame.new(0, -1.5, 0)
	club.Parent = model
	local clubWeld = Instance.new("WeldConstraint")
	clubWeld.Part0 = rightArm
	clubWeld.Part1 = club
	clubWeld.Parent = club

	-- Club head (bulge at end)
	local clubHead = Instance.new("Part")
	clubHead.Name = "ClubHead"
	clubHead.Shape = Enum.PartType.Ball
	clubHead.Size = Vector3.new(1, 1, 1)
	clubHead.Color = Color3.fromRGB(80, 55, 30)
	clubHead.Material = Enum.Material.Wood
	clubHead.Anchored = false
	clubHead.CanCollide = false
	clubHead.CFrame = club.CFrame * CFrame.new(0, -1.3, 0)
	clubHead.Parent = model
	local chWeld = Instance.new("WeldConstraint")
	chWeld.Part0 = club
	chWeld.Part1 = clubHead
	chWeld.Parent = clubHead

	-- Left Leg
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "LeftLeg"
	leftLeg.Size = Vector3.new(0.9, 1.4, 0.9)
	leftLeg.Color = darkSkin
	leftLeg.Material = mat
	leftLeg.Anchored = false
	leftLeg.CanCollide = false
	leftLeg.CFrame = torso.CFrame * CFrame.new(-0.55, -1.8, 0)
	leftLeg.Parent = model
	local llWeld = Instance.new("WeldConstraint")
	llWeld.Part0 = torso
	llWeld.Part1 = leftLeg
	llWeld.Parent = leftLeg

	-- Right Leg
	local rightLeg = Instance.new("Part")
	rightLeg.Name = "RightLeg"
	rightLeg.Size = Vector3.new(0.9, 1.4, 0.9)
	rightLeg.Color = darkSkin
	rightLeg.Material = mat
	rightLeg.Anchored = false
	rightLeg.CanCollide = false
	rightLeg.CFrame = torso.CFrame * CFrame.new(0.55, -1.8, 0)
	rightLeg.Parent = model
	local rlWeld = Instance.new("WeldConstraint")
	rlWeld.Part0 = torso
	rlWeld.Part1 = rightLeg
	rlWeld.Parent = rightLeg

	-- Loincloth / Belt
	local belt = Instance.new("Part")
	belt.Name = "Belt"
	belt.Size = Vector3.new(2.2, 0.4, 1.4)
	belt.Color = Color3.fromRGB(120, 80, 40)
	belt.Material = Enum.Material.Leather
	belt.Anchored = false
	belt.CanCollide = false
	belt.CFrame = torso.CFrame * CFrame.new(0, -1.0, 0)
	belt.Parent = model
	local beltWeld = Instance.new("WeldConstraint")
	beltWeld.Part0 = torso
	beltWeld.Part1 = belt
	beltWeld.Parent = belt

	-- Humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
	humanoid.WalkSpeed = config.moveSpeed or 4
	humanoid.HipHeight = 1.5
	humanoid.Parent = model

	model.PrimaryPart = torso
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
		health = math.max(0, health - result.damage)
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

					local attack = enemy:GetAttribute("Attack") or enemyConfig.PhysicalDamage
					self._playerData:Damage(targetPlayer, attack, enemy, false, enemyConfig.damageType)

					if enemyConfig.statusEffect then
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
