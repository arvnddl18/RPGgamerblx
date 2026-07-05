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
		local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
		if not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
			enemy:SetAttribute("AggroTarget", nil)
			targetPlayer = nil
		else
			local distance = getDistance(root.Position, targetRoot.Position)
			if distance > (config.aggroRange or 40) * 1.5 then
				enemy:SetAttribute("AggroTarget", nil)
				enemy:SetAttribute("AIState", STATES.ReturnHome)
				targetPlayer = nil
			elseif distance <= config.attackRange then
				enemy:SetAttribute("AIState", STATES.Attack)
				context.tryAttack(enemy, targetPlayer, config)
			else
				enemy:SetAttribute("AIState", STATES.Chase)
				humanoid:MoveTo(targetRoot.Position)
			end
		end
	end

	if not targetPlayer then
		if state == STATES.ReturnHome then
			local flatSpawn = Vector3.new(spawnPos.X, root.Position.Y, spawnPos.Z)
			if getDistance(root.Position, flatSpawn) > 4 then
				humanoid:MoveTo(flatSpawn)
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
			humanoid:MoveTo(Vector3.new(patrolTarget.X, root.Position.Y, patrolTarget.Z))
		else
			enemy:SetAttribute("AIState", STATES.Idle)
		end
	end
end

return EnemyStateMachine
