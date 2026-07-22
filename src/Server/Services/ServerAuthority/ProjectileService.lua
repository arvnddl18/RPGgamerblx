local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Framework = require(Shared:WaitForChild("Framework"))

local ProjectileService = {}
ProjectileService._remotes = nil
ProjectileService._enemyService = nil
ProjectileService._playerData = nil
ProjectileService._combatService = nil
ProjectileService._buffService = nil
ProjectileService._activeProjectiles = {}

local ARROW_LENGTH = 2.4
local ARROW_SHAFT_THICKNESS = 0.08
local ARROW_TIP_LENGTH = 0.4
local ARROW_TIP_THICKNESS = 0.18
local ARROW_MAX_LIFETIME = 4.0
local ARROW_RAYCAST_THICKNESS = 0.5

local function isEnemy(model)
	return CollectionService:HasTag(model, "Enemy")
end

local function getHealth(model)
	local attr = model:GetAttribute("Health")
	if attr then
		return attr
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid.Health or 0
end

local function dealDamage(projectile, target, skill, attacker)
	if not target or not target.Parent then
		return 0
	end

	local damageType = "physical"
	if skill.skillType == "magic" then
		damageType = "magic"
	elseif skill.skillType == "ranged" then
		damageType = "physical"
	end

	local baseDamage = skill.damage or 0
	local totalDamage = 0

	if isEnemy(target) then
		local enemyService = ProjectileService._enemyService
		if enemyService then
			totalDamage = enemyService:DamageEnemy(target, baseDamage, attacker.combatStats, attacker.player, damageType)
		end
		if ProjectileService._playerData and attacker.player then
			ProjectileService._playerData:ApplyLifeSteal(attacker.player, totalDamage, damageType)
		end
		if skill.statusEffect and ProjectileService._buffService then
			ProjectileService._buffService:ApplyEffect(target, skill.statusEffect, skill.statusDuration or 3, attacker.player, skill.statusIntensity)
		end
	else
		local targetPlayer = Players:GetPlayerFromCharacter(target)
		if targetPlayer and ProjectileService._combatService then
			totalDamage = ProjectileService._combatService:DamagePlayer(attacker.player, targetPlayer, baseDamage, damageType) or 0
			if ProjectileService._playerData and attacker.player then
				ProjectileService._playerData:ApplyLifeSteal(attacker.player, totalDamage, damageType)
			end
			if skill.statusEffect and ProjectileService._buffService then
				ProjectileService._buffService:ApplyEffect(targetPlayer, skill.statusEffect, skill.statusDuration or 3, attacker.player, skill.statusIntensity)
			end
		end
	end

	return totalDamage
end

local function getHitCandidates()
	local candidates = {}

	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and getHealth(enemy) > 0 then
			local root = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if root then
				table.insert(candidates, { model = enemy, root = root })
			end
		end
	end

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			local root = character:FindFirstChild("HumanoidRootPart")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				table.insert(candidates, { model = character, root = root })
			end
		end
	end

	return candidates
end

local function buildArrowCFrame(origin, direction)
	local lookCF = CFrame.lookAt(origin, origin + direction)
	return lookCF * CFrame.new(0, 0, -ARROW_LENGTH / 2)
end

local function createArrowPart(projectileId, origin, direction, color)
	local shaft = Instance.new("Part")
	shaft.Name = "ArrowShaft"
	shaft.Size = Vector3.new(ARROW_SHAFT_THICKNESS, ARROW_SHAFT_THICKNESS, ARROW_LENGTH)
	shaft.Color = color or Color3.fromRGB(139, 90, 43)
	shaft.Material = Enum.Material.Wood
	shaft.CanCollide = false
	shaft.CanQuery = false
	shaft.CanTouch = false
	shaft.Massless = true
	shaft.Anchored = true
	shaft.CastShadow = false
	shaft.CFrame = buildArrowCFrame(origin, direction)
	shaft.Parent = workspace

	local tip = Instance.new("Part")
	tip.Name = "ArrowTip"
	tip.Size = Vector3.new(ARROW_TIP_THICKNESS, ARROW_TIP_THICKNESS, ARROW_TIP_LENGTH)
	tip.Shape = Enum.PartType.Ball
	tip.Color = Color3.fromRGB(180, 180, 190)
	tip.Material = Enum.Material.Metal
	tip.CanCollide = false
	tip.CanQuery = false
	tip.CanTouch = false
	tip.Massless = true
	tip.Anchored = true
	tip.CastShadow = false
	tip.CFrame = shaft.CFrame * CFrame.new(0, 0, -(ARROW_LENGTH / 2 + ARROW_TIP_LENGTH / 2))
	tip.Parent = shaft

	local fletching = Instance.new("Part")
	fletching.Name = "ArrowFletching"
	fletching.Size = Vector3.new(0.22, 0.22, 0.15)
	fletching.Color = color or Color3.fromRGB(200, 60, 60)
	fletching.Material = Enum.Material.Fabric
	fletching.CanCollide = false
	fletching.CanQuery = false
	fletching.CanTouch = false
	fletching.Massless = true
	fletching.Anchored = true
	fletching.CastShadow = false
	fletching.CFrame = shaft.CFrame * CFrame.new(0, 0, (ARROW_LENGTH / 2 + 0.05))
	fletching.Parent = shaft

	local att0 = Instance.new("Attachment")
	att0.Name = "TrailStart"
	att0.Position = Vector3.new(0, 0, ARROW_LENGTH / 2 - 0.1)
	att0.Parent = shaft

	local att1 = Instance.new("Attachment")
	att1.Name = "TrailEnd"
	att1.Position = Vector3.new(0, 0, -(ARROW_LENGTH / 2 - 0.1))
	att1.Parent = shaft

	local trail = Instance.new("Trail")
	trail.Name = "ArrowTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.4
	trail.MinLength = 0.01
	trail.LightEmission = 0.1
	trail.Brightness = 0.7
	trail.FaceCamera = true
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 205)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(210, 210, 215)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 185)),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.3, 0.5),
		NumberSequenceKeypoint.new(0.7, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 1.0),
		NumberSequenceKeypoint.new(0.7, 1.4),
		NumberSequenceKeypoint.new(1, 0.6),
	})
	trail.Enabled = true
	trail.Parent = shaft

	local glowAtt0 = Instance.new("Attachment")
	glowAtt0.Name = "GlowTrailStart"
	glowAtt0.Position = Vector3.new(0, 0, ARROW_LENGTH / 2 + 0.15)
	glowAtt0.Parent = shaft

	local glowAtt1 = Instance.new("Attachment")
	glowAtt1.Name = "GlowTrailEnd"
	glowAtt1.Position = Vector3.new(0, 0, -(ARROW_LENGTH / 2 + 0.15))
	glowAtt1.Parent = shaft

	local glowTrail = Instance.new("Trail")
	glowTrail.Name = "ArrowGlowTrail"
	glowTrail.Attachment0 = glowAtt0
	glowTrail.Attachment1 = glowAtt1
	glowTrail.Lifetime = 0.6
	glowTrail.MinLength = 0.01
	glowTrail.LightEmission = 0.05
	glowTrail.Brightness = 0.5
	glowTrail.FaceCamera = true
	glowTrail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 230, 235)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 205)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 170, 175)),
	})
	glowTrail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 0.65),
		NumberSequenceKeypoint.new(0.7, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})
	glowTrail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.25, 1.2),
		NumberSequenceKeypoint.new(0.6, 1.8),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	glowTrail.Enabled = true
	glowTrail.Parent = shaft

	local tipEmitter = Instance.new("ParticleEmitter")
	tipEmitter.Name = "ArrowTipParticles"
	tipEmitter.Rate = 40
	tipEmitter.Lifetime = NumberRange.new(0.15, 0.35)
	tipEmitter.Speed = NumberRange.new(0.3, 1.5)
	tipEmitter.SpreadAngle = Vector2.new(15, 15)
	tipEmitter.LightEmission = 0.2
	tipEmitter.Brightness = 0.6
	tipEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 220, 225)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 190, 195)),
	})
	tipEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	tipEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	tipEmitter.RotSpeed = NumberRange.new(-90, 90)
	tipEmitter.Rotation = NumberRange.new(0, 360)
	tipEmitter.Parent = tip

	local glow = Instance.new("PointLight")
	glow.Name = "ArrowGlow"
	glow.Color = Color3.fromRGB(230, 230, 235)
	glow.Brightness = 0.8
	glow.Range = 5
	glow.Parent = tip

	return shaft
end

local function spawnImpactVfx(position, direction, color)
	local emitter = Instance.new("Part")
	emitter.Name = "ArrowImpact"
	emitter.Size = Vector3.new(0.2, 0.2, 0.2)
	emitter.Transparency = 1
	emitter.Anchored = true
	emitter.CanCollide = false
	emitter.CanQuery = false
	emitter.CanTouch = false
	emitter.CFrame = CFrame.lookAt(position, position + direction)
	emitter.Parent = workspace

	local spark = Instance.new("ParticleEmitter")
	spark.Name = "ImpactSpark"
	spark.Rate = 0
	spark.Lifetime = NumberRange.new(0.15, 0.35)
	spark.Speed = NumberRange.new(4, 10)
	spark.SpreadAngle = Vector2.new(30, 30)
	spark.Color = ColorSequence.new(color or Color3.fromRGB(255, 180, 80))
	spark.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	spark.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	spark.LightEmission = 0.8
	spark.Parent = emitter
	spark:Emit(12)

	task.delay(0.5, function()
		if emitter and emitter.Parent then
			emitter:Destroy()
		end
	end)
end

local function raycastArrow(position, direction, ignoreList, maxDistance)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignoreList or {}
	rayParams.RespectCanCollide = false
	rayParams.CollisionGroup = ""

	local origin = position + direction * 1.5
	local result = workspace:Raycast(origin, direction * (maxDistance or 3), rayParams)
	return result
end

local function registerProjectile(projectileId, arrowModel, config)
	ProjectileService._activeProjectiles[projectileId] = {
		model = arrowModel,
		config = config,
		elapsed = 0,
		distanceTraveled = 0,
		hitTargets = {},
	}
end

local function unregisterProjectile(projectileId)
	ProjectileService._activeProjectiles[projectileId] = nil
end

local function destroyArrow(arrowModel)
	if arrowModel and arrowModel.Parent then
		for _, child in arrowModel:GetDescendants() do
			if child:IsA("ParticleEmitter") then
				child.Enabled = false
			end
			if child:IsA("Trail") then
				child.Enabled = false
			end
		end
		task.delay(0.25, function()
			if arrowModel and arrowModel.Parent then
				arrowModel:Destroy()
			end
		end)
	end
end

function ProjectileService:Init()
	self._remotes = Framework:GetRemotesFolder()
	self._enemyService = Framework:GetService("EnemyService")
	self._playerData = Framework:GetService("PlayerDataService")
	self._combatService = Framework:GetService("CombatService")
	self._buffService = Framework:GetService("BuffService")

	Framework:GetRemote("SpawnProjectile")
	Framework:GetRemote("DestroyProjectile")
end

function ProjectileService:FireProjectile(player, skill, origin, direction, targetData, visualOnly)
	local speed = skill.projectileSpeed or 120
	local maxDistance = skill.range or 50
	local pierceCount = skill.pierceCount or 0
	local color = skill.arrowColor or Color3.fromRGB(200, 100, 50)

	local projectileId = tick() .. "_" .. player.UserId .. "_" .. math.random(10000, 99999)

	local arrowModel = createArrowPart(projectileId, origin, direction, color)
	arrowModel:SetAttribute("ProjectileId", projectileId)
	arrowModel:SetAttribute("OwnerId", player.UserId)

	local attackerData = {
		player = player,
		combatStats = self:GetAttackerStats(player),
	}

	local config = {
		skill = skill,
		attacker = attackerData,
		speed = speed,
		maxDistance = maxDistance,
		pierceCount = pierceCount,
		pierceRemaining = pierceCount,
		color = color,
		direction = direction,
		origin = origin,
		owner = player,
		targetData = targetData,
		visualOnly = visualOnly == true,
	}

	registerProjectile(projectileId, arrowModel, config)

	self._remotes.SpawnProjectile:FireAllClients({
		arrowId = projectileId,
		ownerId = player.UserId,
		origin = origin,
		direction = direction,
		speed = speed,
		color = color,
		skillId = skill.id,
	})

	return projectileId
end

function ProjectileService:Start()
	local heartbeatConn
	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		for projectileId, projectile in pairs(ProjectileService._activeProjectiles) do
			local arrowModel = projectile.model
			if not arrowModel or not arrowModel.Parent then
				unregisterProjectile(projectileId)
				continue
			end

			projectile.elapsed += dt
			if projectile.elapsed > ARROW_MAX_LIFETIME then
				destroyArrow(arrowModel)
				ProjectileService._remotes.DestroyProjectile:FireAllClients(projectileId)
				unregisterProjectile(projectileId)
				continue
			end

			local cfg = projectile.config
			local direction = cfg.direction
			local moveStep = cfg.speed * dt
			local currentPos = arrowModel.Position
			local newPos = currentPos + direction * moveStep
			local totalDist = projectile.distanceTraveled + moveStep

			if totalDist >= cfg.maxDistance then
				destroyArrow(arrowModel)
				ProjectileService._remotes.DestroyProjectile:FireAllClients(projectileId)
				unregisterProjectile(projectileId)
				continue
			end

			projectile.distanceTraveled = totalDist

			local ignoreList = {}
			if cfg.owner and cfg.owner.Character then
				table.insert(ignoreList, cfg.owner.Character)
			end
			for hitModel, _ in projectile.hitTargets do
				if hitModel and hitModel.Parent then
					table.insert(ignoreList, hitModel)
				end
			end

			local rayResult = raycastArrow(currentPos, direction, ignoreList, moveStep + ARROW_RAYCAST_THICKNESS)

			if rayResult then
				local hitPart = rayResult.Instance
				local hitModel = hitPart and hitPart:FindFirstAncestorWhichIsA("Model")

				if hitModel then
					local isTarget = isEnemy(hitModel) or Players:GetPlayerFromCharacter(hitModel) ~= nil
					if isTarget then
						if not cfg.visualOnly then
							local alreadyHit = projectile.hitTargets[hitModel]
							if not alreadyHit then
								projectile.hitTargets[hitModel] = true
								dealDamage(projectile, hitModel, cfg.skill, cfg.attacker)
							end
						end
						spawnImpactVfx(rayResult.Position, direction, cfg.color)
						destroyArrow(arrowModel)
						ProjectileService._remotes.DestroyProjectile:FireAllClients(projectileId)
						unregisterProjectile(projectileId)
						continue
					else
						spawnImpactVfx(rayResult.Position, direction, cfg.color)
						destroyArrow(arrowModel)
						ProjectileService._remotes.DestroyProjectile:FireAllClients(projectileId)
						unregisterProjectile(projectileId)
						continue
					end
				else
					spawnImpactVfx(rayResult.Position, direction, cfg.color)
					destroyArrow(arrowModel)
					ProjectileService._remotes.DestroyProjectile:FireAllClients(projectileId)
					unregisterProjectile(projectileId)
					continue
				end
			end

			arrowModel.CFrame = buildArrowCFrame(newPos, direction)
			local tip = arrowModel:FindFirstChild("Tip")
			if tip then
				tip.CFrame = arrowModel.CFrame * CFrame.new(0, 0, -(ARROW_LENGTH / 2 + ARROW_TIP_LENGTH / 2))
			end
			local fletching = arrowModel:FindFirstChild("ArrowFletching")
			if fletching then
				fletching.CFrame = arrowModel.CFrame * CFrame.new(0, 0, (ARROW_LENGTH / 2 + 0.05))
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		for projectileId, projectile in pairs(ProjectileService._activeProjectiles) do
			if projectile.config.owner == player then
				destroyArrow(projectile.model)
				ProjectileService._remotes.DestroyProjectile:FireAllClients(projectileId)
				unregisterProjectile(projectileId)
			end
		end
	end)
end

function ProjectileService:GetAttackerStats(player)
	local data = self._playerData and self._playerData:GetData(player)
	if not data then
		return {}
	end
	return data.combatStats
end

return ProjectileService
