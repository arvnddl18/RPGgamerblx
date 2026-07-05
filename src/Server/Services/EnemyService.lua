local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enemies = require(Shared.Config.Enemies)
local Items = require(Shared.Config.Items)

local EnemyService = {}
EnemyService._playerData = nil
EnemyService._questService = nil
EnemyService._inventoryService = nil
EnemyService._enemies = {}
EnemyService._attackCooldowns = {}

local SPAWN_POSITIONS = {
	Vector3.new(0, 3, 40),
	Vector3.new(20, 3, 45),
	Vector3.new(-20, 3, 45),
	Vector3.new(10, 3, 60),
	Vector3.new(-10, 3, 60),
	Vector3.new(30, 3, 50),
	Vector3.new(-30, 3, 50),
	Vector3.new(0, 3, 70),
}

-- Increased aggro range so enemies actively hunt nearby players
local ACTIVE_AGGRO_RANGE = 40

function EnemyService:Init(playerDataService, questService, inventoryService, mapGeneratorService)
	self._playerData = playerDataService
	self._questService = questService
	self._inventoryService = inventoryService
	self._mapGenerator = mapGeneratorService
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

function EnemyService:CreateGoblin(position)
	local config = Enemies.Goblin
	local model = Instance.new("Model")
	model.Name = config.name

	local skinColor = Color3.fromRGB(80, 160, 60)
	local darkSkin = Color3.fromRGB(60, 130, 45)
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
	humanoid.MaxHealth = config.maxHealth
	humanoid.Health = config.maxHealth
	humanoid.WalkSpeed = 4
	humanoid.HipHeight = 1.5
	humanoid.Parent = model

	model.PrimaryPart = torso
	model:SetAttribute("EnemyType", config.id)
	model:SetAttribute("Health", config.maxHealth)
	model:SetAttribute("MaxHealth", config.maxHealth)

	CollectionService:AddTag(model, "Enemy")
	self:CreateHealthBar(model, config.maxHealth)

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

	for _, position in SPAWN_POSITIONS do
		local y = self._mapGenerator:GetGroundHeight(position.X, position.Z)
		self:CreateGoblin(Vector3.new(position.X, y + 3, position.Z))
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

function EnemyService:DamageEnemy(enemy, amount, attacker)
	if not enemy.Parent then
		return
	end

	local health = enemy:GetAttribute("Health") or 0
	health = math.max(0, health - amount)
	enemy:SetAttribute("Health", health)

	if attacker and attacker:IsA("Player") then
		enemy:SetAttribute("AggroTarget", attacker.UserId)
	end

	self:UpdateHealthBar(enemy)

	if health <= 0 then
		self:OnEnemyKilled(enemy, attacker)
	end
end

function EnemyService:CreatePickup(position, itemId)
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
	local config = Enemies.Goblin
	local root = enemy.PrimaryPart
	local deathPosition = root and root.Position or Vector3.new()

	if killer then
		self._playerData:AddXP(killer, config.xpReward)
		self._playerData:AddCoins(killer, config.coinReward)
		if self._questService then
			self._questService:OnEnemyKilled(killer, config.id)
		end
	end

	if math.random() < config.dropChance and root then
		self:CreatePickup(deathPosition, config.dropItem)
	end

	-- Find the closest original spawn point to respawn at
	local closestSpawn = SPAWN_POSITIONS[1]
	local closestDist = math.huge
	for _, spawnPos in SPAWN_POSITIONS do
		local dist = (Vector3.new(spawnPos.X, 0, spawnPos.Z) - Vector3.new(deathPosition.X, 0, deathPosition.Z)).Magnitude
		if dist < closestDist then
			closestDist = dist
			closestSpawn = spawnPos
		end
	end

	for i, e in self._enemies do
		if e == enemy then
			table.remove(self._enemies, i)
			break
		end
	end

	enemy:Destroy()

	-- Respawn at the closest original spawn point after a delay
	task.delay(5, function()
		local y = self._mapGenerator:GetGroundHeight(closestSpawn.X, closestSpawn.Z)
		self:CreateGoblin(Vector3.new(closestSpawn.X, y + 3, closestSpawn.Z))
	end)
end

function EnemyService:RunAI()
	local config = Enemies.Goblin

	for _, enemy in self._enemies do
		if enemy.Parent and enemy:GetAttribute("Health") > 0 then
			local root = enemy.PrimaryPart
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			if root and humanoid then
				-- First check if we have an aggro target from being attacked
				local aggroTarget = enemy:GetAttribute("AggroTarget")
				local targetPlayer = nil

				if aggroTarget then
					targetPlayer = Players:GetPlayerByUserId(aggroTarget)
					-- Validate the aggro target is still alive and in range
					if targetPlayer and targetPlayer.Character then
						local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
						local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
						if targetRoot and targetHumanoid and targetHumanoid.Health > 0 then
							local distance = (root.Position - targetRoot.Position).Magnitude
							if distance > ACTIVE_AGGRO_RANGE then
								-- Target is too far, clear aggro
								enemy:SetAttribute("AggroTarget", nil)
								targetPlayer = nil
							end
						else
							-- Target is dead or missing root, clear aggro
							enemy:SetAttribute("AggroTarget", nil)
							targetPlayer = nil
						end
					else
						-- Player left or character missing, clear aggro
						enemy:SetAttribute("AggroTarget", nil)
						targetPlayer = nil
					end
				end

				-- If no aggro target, actively search for the nearest player
				if not targetPlayer then
					local nearestPlayer, nearestDist = self:GetNearestPlayer(root.Position, ACTIVE_AGGRO_RANGE)
					if nearestPlayer then
						targetPlayer = nearestPlayer
						enemy:SetAttribute("AggroTarget", nearestPlayer.UserId)
					end
				end

				-- Chase and attack the target
				if targetPlayer and targetPlayer.Character then
					local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
					if targetRoot then
						local distance = (root.Position - targetRoot.Position).Magnitude
						humanoid:MoveTo(targetRoot.Position)

						if distance <= config.attackRange then
							local now = tick()
							local key = enemy
							if not self._attackCooldowns[key] or now - self._attackCooldowns[key] >= config.attackCooldown then
								self._attackCooldowns[key] = now
								self._playerData:Damage(targetPlayer, config.damage)
							end
						end
					end
				end
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
