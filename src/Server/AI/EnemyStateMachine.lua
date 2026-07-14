local EnemyStateMachine = {}

local STATES = {
	Idle = "Idle",
	Patrol = "Patrol",
	Chase = "Chase",
	Attack = "Attack",
	ReturnHome = "ReturnHome",
}

EnemyStateMachine.STATES = STATES

local function getDistance(a, b)
	return (a - b).Magnitude
end

local function getFlatDistance(a, b)
	local v = a - b
	return math.sqrt(v.X^2 + v.Z^2)
end

function EnemyStateMachine.InitEnemy(enemy, spawnPosition, config)
	enemy:SetAttribute("AIState", STATES.Idle)
	enemy:SetAttribute("SpawnX", spawnPosition.X)
	enemy:SetAttribute("SpawnY", spawnPosition.Y)
	enemy:SetAttribute("SpawnZ", spawnPosition.Z)
	enemy:SetAttribute("PatrolTargetX", spawnPosition.X)
	enemy:SetAttribute("PatrolTargetZ", spawnPosition.Z)
	enemy:SetAttribute("NextPatrolTime", tick() + math.random(3, 8))
end

function EnemyStateMachine.GetSpawnPosition(enemy)
	return Vector3.new(
		enemy:GetAttribute("SpawnX") or 0,
		enemy:GetAttribute("SpawnY") or 3,
		enemy:GetAttribute("SpawnZ") or 0
	)
end

function EnemyStateMachine.Tick(enemy, humanoid, root, config, context)
	if not enemy.Parent or (enemy:GetAttribute("Health") or 0) <= 0 then
		return
	end
	if enemy:GetAttribute("IsStunned") or enemy:GetAttribute("IsKnockedDown") then
		humanoid:Move(Vector3.zero)
		humanoid.WalkSpeed = 0
		return
	end

	local state = enemy:GetAttribute("AIState") or STATES.Idle
	local spawnPos = EnemyStateMachine.GetSpawnPosition(enemy)
	local now = tick()

	local targetPlayer = nil
	local aggroId = enemy:GetAttribute("AggroTarget")
	if aggroId then
		targetPlayer = context.getPlayerByUserId(aggroId)
	end

	if not targetPlayer then
		targetPlayer = context.getNearestPlayer(root.Position, config.aggroRange or 40)
		if targetPlayer then
			enemy:SetAttribute("AggroTarget", targetPlayer.UserId)
		end
	end

	if targetPlayer and targetPlayer.Character then
		local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		-- PlayerDataService owns RPG life state.  Do not make enemy targeting
		-- depend on the Humanoid state, which can transiently change while a
		-- control effect updates movement properties.
		if not targetRoot then
			enemy:SetAttribute("AggroTarget", nil)
			targetPlayer = nil
		else
			local distance = getDistance(root.Position, targetRoot.Position)
			local flatDistance = getFlatDistance(root.Position, targetRoot.Position)
			local vertDistance = math.abs(root.Position.Y - targetRoot.Position.Y)

			if distance > (config.aggroRange or 40) * 1.5 then
				enemy:SetAttribute("AggroTarget", nil)
				enemy:SetAttribute("AIState", STATES.ReturnHome)
				targetPlayer = nil
			elseif flatDistance <= config.attackRange and vertDistance < 15 then
				enemy:SetAttribute("AIState", STATES.Attack)
				context.tryAttack(enemy, targetPlayer, config)
				-- Stop moving while attacking to prevent pushing the player constantly
				if config.isFlying then
					local alignPos = root:FindFirstChild("FlyAlignPosition")
					local alignOri = root:FindFirstChild("FlyAlignOrientation")
					if alignPos and alignOri then
						alignPos.Position = root.Position
						alignOri.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
					end
				else
					humanoid:MoveTo(root.Position)
				end
			else
				enemy:SetAttribute("AIState", STATES.Chase)
				if config.isFlying then
					local alignPos = root:FindFirstChild("FlyAlignPosition")
					local alignOri = root:FindFirstChild("FlyAlignOrientation")
					if alignPos and alignOri then
						alignPos.Position = targetRoot.Position
						alignOri.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
					end
				else
					humanoid:MoveTo(targetRoot.Position)
				end
			end
		end
	end

	if not targetPlayer then
		if state == STATES.ReturnHome then
			local flatSpawn = Vector3.new(spawnPos.X, root.Position.Y, spawnPos.Z)
			if getDistance(root.Position, flatSpawn) > 4 then
				if config.isFlying then
					local alignPos = root:FindFirstChild("FlyAlignPosition")
					local alignOri = root:FindFirstChild("FlyAlignOrientation")
					if alignPos and alignOri then
						local targetHome = Vector3.new(spawnPos.X, spawnPos.Y, spawnPos.Z)
						alignPos.Position = targetHome
						alignOri.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetHome.X, root.Position.Y, targetHome.Z))
					end
				else
					humanoid:MoveTo(flatSpawn)
				end
			else
				enemy:SetAttribute("AIState", STATES.Idle)
			end
		elseif now >= (enemy:GetAttribute("NextPatrolTime") or 0) then
			enemy:SetAttribute("AIState", STATES.Patrol)
			local offset = Vector3.new(math.random(-12, 12), 0, math.random(-12, 12))
			local patrolTarget = spawnPos + offset
			enemy:SetAttribute("PatrolTargetX", patrolTarget.X)
			enemy:SetAttribute("PatrolTargetZ", patrolTarget.Z)
			enemy:SetAttribute("NextPatrolTime", now + math.random(5, 12))
			
			if config.isFlying then
				local alignPos = root:FindFirstChild("FlyAlignPosition")
				local alignOri = root:FindFirstChild("FlyAlignOrientation")
				if alignPos and alignOri then
					local targetPatrol = Vector3.new(patrolTarget.X, spawnPos.Y, patrolTarget.Z)
					alignPos.Position = targetPatrol
					alignOri.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPatrol.X, root.Position.Y, targetPatrol.Z))
				end
			else
				humanoid:MoveTo(Vector3.new(patrolTarget.X, root.Position.Y, patrolTarget.Z))
			end
		else
			enemy:SetAttribute("AIState", STATES.Idle)
		end
	end
end

return EnemyStateMachine
