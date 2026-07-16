local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CombatConfig = require(Shared.Config.CombatConfig)

local TargetingUtil = {}

local DEFAULT_RAY_LENGTH = 500

function TargetingUtil.GetConeDotThreshold()
	return CombatConfig.coneDotThreshold or 0.2
end

function TargetingUtil.ClampGroundPosition(casterPos, targetPos, maxRange)
	local offset = targetPos - casterPos
	local flatOffset = Vector3.new(offset.X, 0, offset.Z)
	local distance = flatOffset.Magnitude
	if distance > maxRange then
		flatOffset = flatOffset.Unit * maxRange
	end
	return casterPos + flatOffset
end

function TargetingUtil.IsInFront(origin, lookVector, targetPos)
	local offset = targetPos - origin
	local flatOffset = Vector3.new(offset.X, 0, offset.Z)
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flatOffset.Magnitude > 0 and flatLook.Magnitude > 0 then
		-- Dot product > 0 means the target is in the 180-degree forward arc
		return flatOffset.Unit:Dot(flatLook.Unit) > 0
	end
	return true -- If overlapping exactly, allow it
end

function TargetingUtil.IsValidTargetPosition(casterPos, targetPos, maxRange)
	if not casterPos or not targetPos then
		return false
	end
	if targetPos.X ~= targetPos.X or targetPos.Y ~= targetPos.Y or targetPos.Z ~= targetPos.Z then
		return false
	end

	local offset = targetPos - casterPos
	local flatDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude
	return flatDistance <= (maxRange or 0) + 0.5
end

function TargetingUtil.RaycastGround(origin, direction, maxRange, ignoreList)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = ignoreList or {}

	local unitDirection = direction.Magnitude > 0 and direction.Unit or Vector3.new(0, 0, -1)
	local result = workspace:Raycast(origin, unitDirection * (maxRange or DEFAULT_RAY_LENGTH), rayParams)
	if result then
		return result.Position, result
	end

	local fallback = origin + unitDirection * (maxRange or DEFAULT_RAY_LENGTH)
	return fallback, nil
end

-- Ground targeting must resolve against Terrain only. This keeps previews and
-- casts off of tree canopies, buildings, characters, and other raised parts.
function TargetingUtil.RaycastTerrainGround(origin, direction, maxRange)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { workspace.Terrain }

	local unitDirection = direction.Magnitude > 0 and direction.Unit or Vector3.new(0, -1, 0)
	local result = workspace:Raycast(origin, unitDirection * (maxRange or DEFAULT_RAY_LENGTH), rayParams)
	if result then
		return result.Position, result
	end

	local fallback = origin + unitDirection * (maxRange or DEFAULT_RAY_LENGTH)
	return fallback, nil
end

function TargetingUtil.GetMouseGroundPosition(mouse, casterPos, maxRange, ignoreList)
	if not mouse then
		return casterPos
	end

	local unitRay = mouse.UnitRay
	local hitPos = casterPos + unitRay.Direction * (maxRange or DEFAULT_RAY_LENGTH)
	local rayPos, _ = TargetingUtil.RaycastTerrainGround(unitRay.Origin, unitRay.Direction, maxRange or DEFAULT_RAY_LENGTH)
	if rayPos then
		hitPos = rayPos
	end
	return TargetingUtil.ClampGroundPosition(casterPos, hitPos, maxRange or DEFAULT_RAY_LENGTH)
end

function TargetingUtil.GetTargetsInRadius(origin, radius, filterFn)
	local targets = {}
	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if enemyRoot then
				local offset = enemyRoot.Position - origin
				local flatDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if flatDistance <= radius and (not filterFn or filterFn(enemy)) then
					table.insert(targets, enemy)
				end
			end
		end
	end
	return targets
end

function TargetingUtil.GetPlayersInRadius(origin, radius, filterFn)
	local targets = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local offset = root.Position - origin
			local flatDistance = Vector3.new(offset.X, 0, offset.Z).Magnitude
			if flatDistance <= radius and (not filterFn or filterFn(player)) then
				table.insert(targets, player)
			end
		end
	end
	return targets
end

function TargetingUtil.GetTargetsInCone(origin, lookVector, range, angleDegrees, filterFn)
	local targets = {}
	local halfAngle = math.rad((angleDegrees or 60) / 2)
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flatLook.Magnitude <= 0 then
		return targets
	end
	flatLook = flatLook.Unit

	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if enemyRoot then
				local offset = enemyRoot.Position - origin
				local flatOffset = Vector3.new(offset.X, 0, offset.Z)
				local flatDistance = flatOffset.Magnitude
				if flatDistance <= range then
					if flatDistance > 0 then
						local dot = flatOffset.Unit:Dot(flatLook)
						local angle = math.acos(math.clamp(dot, -1, 1))
						if angle <= halfAngle and (not filterFn or filterFn(enemy)) then
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
	end

	return targets
end

function TargetingUtil.GetPlayersInCone(origin, lookVector, range, angleDegrees, filterFn)
	local targets = {}
	local halfAngle = math.rad((angleDegrees or 60) / 2)
	local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
	if flatLook.Magnitude <= 0 then
		return targets
	end
	flatLook = flatLook.Unit

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local offset = root.Position - origin
			local flatOffset = Vector3.new(offset.X, 0, offset.Z)
			local flatDistance = flatOffset.Magnitude
			if flatDistance <= range then
				if flatDistance > 0 then
					local dot = flatOffset.Unit:Dot(flatLook)
					local angle = math.acos(math.clamp(dot, -1, 1))
					if angle <= halfAngle and (not filterFn or filterFn(player)) then
						table.insert(targets, player)
					end
				end
			end
		end
	end

	return targets
end

function TargetingUtil.GetNearestEnemy(origin, range, filterFn)
	local nearest = nil
	local nearestDist = range

	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if enemyRoot and (not filterFn or filterFn(enemy)) then
				local distance = (enemyRoot.Position - origin).Magnitude
				if distance <= nearestDist then
					nearestDist = distance
					nearest = enemy
				end
			end
		end
	end

	return nearest, nearestDist
end

function TargetingUtil.GetNearestPlayer(origin, range, filterFn)
	local nearest = nil
	local nearestDist = range

	for _, player in Players:GetPlayers() do
		if not filterFn or filterFn(player) then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local distance = (root.Position - origin).Magnitude
				if distance <= nearestDist then
					nearestDist = distance
					nearest = player
				end
			end
		end
	end

	return nearest, nearestDist
end

function TargetingUtil.SanitizeTargetData(targetData)
	if typeof(targetData) ~= "table" then
		return {}
	end

	local sanitized = {}
	if typeof(targetData.groundPosition) == "Vector3" then
		sanitized.groundPosition = targetData.groundPosition
	end
	if typeof(targetData.direction) == "Vector3" and targetData.direction.Magnitude > 0 then
		sanitized.direction = targetData.direction.Unit
	end
	if typeof(targetData.attackOrigin) == "Vector3" then
		sanitized.attackOrigin = targetData.attackOrigin
	end
	if typeof(targetData.attackTargetPosition) == "Vector3" then
		sanitized.attackTargetPosition = targetData.attackTargetPosition
	end
	if typeof(targetData.targetInstance) == "Instance" then
		sanitized.targetInstance = targetData.targetInstance
	end
	if typeof(targetData.targetUserId) == "number" then
		sanitized.targetUserId = math.floor(targetData.targetUserId)
	end
	return sanitized
end

return TargetingUtil
