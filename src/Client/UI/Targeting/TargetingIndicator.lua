local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CombatConfig = require(Shared.Config.CombatConfig)
local TargetingUtil = require(Shared.Combat.TargetingUtil)

local TargetingIndicator = {}
TargetingIndicator.__index = TargetingIndicator

local RANGE_COLOR = Color3.fromRGB(100, 200, 255)
local AFFECTED_COLOR = Color3.fromRGB(255, 80, 80)
local AOE_COLOR = Color3.fromRGB(80, 220, 100)
local INVALID_COLOR = Color3.fromRGB(220, 70, 70)

local MAX_HIGHLIGHT_POOL = 20
local HIGHLIGHT_RADIUS = 2.5

local GROUND_RAY_HEIGHT = 200
local GROUND_LIFT = 0.12
local ARC_SEGMENTS = 36
local LINE_SEGMENTS = 20
local HIGHLIGHT_SEGMENTS = 12

local function flatUnit(vector, fallback)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude > 0.001 then
		return flat.Unit
	end
	return fallback or Vector3.new(0, 0, -1)
end

local function createBeamSegment(parent, name)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.Parent = parent

	local att0 = Instance.new("Attachment")
	att0.Parent = part
	local att1 = Instance.new("Attachment")
	att1.Parent = part

	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.FaceCamera = false
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Segments = 1
	beam.Enabled = false
	beam.Parent = part

	return {
		part = part,
		att0 = att0,
		att1 = att1,
		beam = beam,
	}
end

local function createTerrainDrawer(parent, segmentCount, name)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent

	local segments = table.create(segmentCount)
	for i = 1, segmentCount do
		segments[i] = createBeamSegment(folder, "Segment_" .. i)
	end

	return {
		folder = folder,
		segments = segments,
		activeCount = 0,
	}
end

local function getGroundPoint(xzPosition, referenceY, ignoreList)
	local origin = Vector3.new(xzPosition.X, referenceY + GROUND_RAY_HEIGHT, xzPosition.Z)
	local hitPos = TargetingUtil.RaycastTerrainGround(origin, Vector3.new(0, -1, 0), GROUND_RAY_HEIGHT * 2)
	return hitPos + Vector3.new(0, GROUND_LIFT, 0)
end

local function sampleArcXZ(center, forward, radius, angleDeg, sampleIndex, sampleCount)
	local halfAngle = math.rad(angleDeg / 2)
	local t = sampleIndex / sampleCount
	local angle = -halfAngle + (2 * halfAngle) * t
	local forwardFlat = flatUnit(forward)
	local offset = (CFrame.fromAxisAngle(Vector3.yAxis, angle) * forwardFlat) * radius
	return center + Vector3.new(offset.X, 0, offset.Z)
end

local function setSegment(segment, pointA, pointB, color, transparency, width)
	segment.att0.WorldPosition = pointA
	segment.att1.WorldPosition = pointB
	segment.beam.Color = ColorSequence.new(color)
	segment.beam.Transparency = NumberSequence.new(transparency)
	segment.beam.Width0 = width
	segment.beam.Width1 = width
	segment.beam.Enabled = true
end

local function hideDrawer(drawer)
	for _, segment in drawer.segments do
		segment.beam.Enabled = false
	end
	drawer.activeCount = 0
end

local function renderPath(drawer, points, color, transparency, width)
	local segmentIndex = 0
	for i = 1, #points - 1 do
		if segmentIndex >= #drawer.segments then
			break
		end
		segmentIndex += 1
		setSegment(drawer.segments[segmentIndex], points[i], points[i + 1], color, transparency, width)
	end

	for i = segmentIndex + 1, #drawer.segments do
		drawer.segments[i].beam.Enabled = false
	end
	drawer.activeCount = segmentIndex
end

local function sampleArcGroundPoints(center, forward, radius, angleDeg, referenceY, ignoreList, sampleCount)
	local points = table.create(sampleCount + 1)
	for i = 0, sampleCount do
		local xz = sampleArcXZ(center, forward, radius, angleDeg, i, sampleCount)
		points[i + 1] = getGroundPoint(xz, referenceY, ignoreList)
	end
	return points
end

local function renderTerrainRing(drawer, center, forward, outerRadius, innerRadius, angleDeg, referenceY, ignoreList, color, transparency, lineWidth, sampleCount)
	sampleCount = sampleCount or ARC_SEGMENTS

	if innerRadius <= 0.01 then
		local width = lineWidth or 0.3
		local outerPoints = sampleArcGroundPoints(center, forward, outerRadius, angleDeg, referenceY, ignoreList, sampleCount)
		renderPath(drawer, outerPoints, color, transparency, width)
		return
	end

	lineWidth = lineWidth or math.max(0.1, outerRadius - innerRadius)
	local midRadius = (outerRadius + innerRadius) * 0.5
	local width = lineWidth
	local outerPoints = sampleArcGroundPoints(center, forward, outerRadius, angleDeg, referenceY, ignoreList, sampleCount)
	local innerPoints = sampleArcGroundPoints(center, forward, innerRadius, angleDeg, referenceY, ignoreList, sampleCount)
	local midPoints = sampleArcGroundPoints(center, forward, midRadius, angleDeg, referenceY, ignoreList, sampleCount)

	local segmentIndex = 0
	local function useSegment(pointA, pointB)
		if segmentIndex >= #drawer.segments then
			return
		end
		segmentIndex += 1
		setSegment(drawer.segments[segmentIndex], pointA, pointB, color, transparency, width)
	end

	for i = 1, #midPoints - 1 do
		useSegment(midPoints[i], midPoints[i + 1])
	end

	if angleDeg >= 359 and #midPoints > 1 then
		useSegment(midPoints[#midPoints], midPoints[1])
	end

	if angleDeg < 359 then
		useSegment(innerPoints[1], outerPoints[1])
		useSegment(innerPoints[#innerPoints], outerPoints[#outerPoints])
	end

	for i = segmentIndex + 1, #drawer.segments do
		drawer.segments[i].beam.Enabled = false
	end
	drawer.activeCount = segmentIndex
end

local function renderTerrainLine(drawer, startPos, endPos, width, referenceY, ignoreList, color, transparency)
	local direction = flatUnit(endPos - startPos)
	local right = Vector3.new(-direction.Z, 0, direction.X)
	local halfWidth = width * 0.5

	local corners = {
		startPos + right * halfWidth,
		startPos - right * halfWidth,
		endPos - right * halfWidth,
		endPos + right * halfWidth,
	}

	local groundCorners = table.create(4)
	for i, corner in corners do
		groundCorners[i] = getGroundPoint(corner, referenceY, ignoreList)
	end

	local points = table.create(LINE_SEGMENTS * 4 + 1)
	local edgeIndex = 0
	for edge = 1, 4 do
		local fromCorner = groundCorners[edge]
		local toCorner = groundCorners[(edge % 4) + 1]
		for step = 0, LINE_SEGMENTS - 1 do
			edgeIndex += 1
			local t = step / LINE_SEGMENTS
			points[edgeIndex] = fromCorner:Lerp(toCorner, t)
		end
	end
	points[#points + 1] = groundCorners[1]

	renderPath(drawer, points, color, transparency, 0.15)
end

local function getAffectedEnemies(skill, rootCFrame, direction, groundPosition)
	local affected = {}
	local range = skill.range or 10
	local targetType = skill.targetType
	local rootPosition = rootCFrame.Position
	local lookVector = rootCFrame.LookVector

	local function IsInFront(targetPos)
		local offset = targetPos - rootPosition
		local flatOffset = Vector3.new(offset.X, 0, offset.Z)
		local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
		if flatOffset.Magnitude > 0 and flatLook.Magnitude > 0 then
			return flatOffset.Unit:Dot(flatLook.Unit) > 0
		end
		return true
	end

	if targetType == "single" then
		local nearest = nil
		local nearestDist = range
		for _, enemy in CollectionService:GetTagged("Enemy") do
			if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
				if enemyRoot and IsInFront(enemyRoot.Position) then
					local dist = (enemyRoot.Position - rootPosition).Magnitude
					if dist <= nearestDist then
						nearestDist = dist
						nearest = enemyRoot
					end
				end
			end
		end
		if nearest then
			table.insert(affected, nearest)
			local aoeRadius = skill.aoeRadius or 0
			if aoeRadius > 0 then
				for _, enemy in CollectionService:GetTagged("Enemy") do
					if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
						local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
						if enemyRoot and enemyRoot ~= nearest then
							local distance = (enemyRoot.Position - nearest.Position).Magnitude
							if distance <= aoeRadius then
								table.insert(affected, enemyRoot)
							end
						end
					end
				end
			end
		end
		return affected
	end

	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if enemyRoot and IsInFront(enemyRoot.Position) then
				local include = false

				if targetType == "ground" then
					local aoeRadius = skill.aoeRadius or range
					local distance = (enemyRoot.Position - groundPosition).Magnitude
					include = distance <= aoeRadius

				elseif targetType == "circle" or targetType == "party_circle" then
					local aoeRadius = skill.aoeRadius or range
					local distance = (enemyRoot.Position - rootPosition).Magnitude
					include = distance <= aoeRadius

				elseif targetType == "cone" or targetType == "directional" then
					local halfAngle = math.rad((skill.coneAngle or 180) / 2)
					local offset = enemyRoot.Position - rootPosition
					local flatOffset = Vector3.new(offset.X, 0, offset.Z)
					local flatDistance = flatOffset.Magnitude
					if flatDistance <= range then
						local flatLook = Vector3.new(direction.X, 0, direction.Z)
						if flatDistance > 0 and flatLook.Magnitude > 0 then
							local dot = flatOffset.Unit:Dot(flatLook.Unit)
							local angle = math.acos(math.clamp(dot, -1, 1))
							include = angle <= halfAngle
						end
					end

				else
					local offset = enemyRoot.Position - rootPosition
					local flatOffset = Vector3.new(offset.X, 0, offset.Z)
					local flatDistance = flatOffset.Magnitude
					if flatDistance <= range then
						local flatLook = Vector3.new(direction.X, 0, direction.Z)
						if flatDistance > 0 and flatLook.Magnitude > 0 then
							local dot = flatOffset.Unit:Dot(flatLook.Unit)
							include = dot >= (CombatConfig.coneDotThreshold or 0)
						end
					end
				end

				if include then
					table.insert(affected, enemyRoot)
				end
			end
		end
	end

	return affected
end

function TargetingIndicator.new(parentFolder)
	local self = setmetatable({}, TargetingIndicator)

	local folder = Instance.new("Folder")
	folder.Name = "TargetingIndicators"
	folder.Parent = parentFolder or workspace
	self._folder = folder

	self._rangeDrawer = createTerrainDrawer(folder, ARC_SEGMENTS + 2, "RangeRing")
	self._aoeDrawer = createTerrainDrawer(folder, ARC_SEGMENTS + 2, "AoeZone")
	self._coneDrawer = createTerrainDrawer(folder, ARC_SEGMENTS + 2, "ConeIndicator")
	self._lineDrawer = createTerrainDrawer(folder, LINE_SEGMENTS * 4 + 1, "LineIndicator")

	self._highlightDrawers = {}
	for i = 1, MAX_HIGHLIGHT_POOL do
		self._highlightDrawers[i] = createTerrainDrawer(folder, HIGHLIGHT_SEGMENTS + 2, "EnemyHighlight_" .. i)
	end

	self._isVisible = false
	self._fadeConnection = nil
	return self
end

local function cancelFade(self)
	if self._fadeConnection then
		self._fadeConnection:Disconnect()
		self._fadeConnection = nil
	end
end

function TargetingIndicator:Update(skill, rootCFrame, groundPosition, direction, isValid, ignoreList)
	cancelFade(self)
	self._isVisible = true

	local rootPosition = rootCFrame.Position
	local referenceY = rootPosition.Y
	local range = skill.range or 10
	local targetType = skill.targetType
	local color = isValid and AOE_COLOR or INVALID_COLOR
	local centerXZ = Vector3.new(rootPosition.X, 0, rootPosition.Z)
	local lookForward = rootCFrame.LookVector

	hideDrawer(self._aoeDrawer)
	hideDrawer(self._coneDrawer)
	hideDrawer(self._lineDrawer)

	local affectedRoots = getAffectedEnemies(skill, rootCFrame, direction, groundPosition or rootPosition)

	if skill.showRangeIndicator ~= false then
		local angle = skill.coneAngle or 180
		local thickness = 0.3
		renderTerrainRing(
			self._rangeDrawer,
			centerXZ,
			lookForward,
			range,
			math.max(0, range - thickness),
			angle,
			referenceY,
			ignoreList,
			RANGE_COLOR,
			0.3
		)
	else
		hideDrawer(self._rangeDrawer)
	end

	if skill.showAoeIndicator then
		if targetType == "ground" then
			local aoeRadius = skill.aoeRadius or range
			local groundXZ = Vector3.new(groundPosition.X, 0, groundPosition.Z)
			renderTerrainRing(
				self._aoeDrawer,
				groundXZ,
				lookForward,
				aoeRadius,
				math.max(0, aoeRadius - 0.4),
				360,
				groundPosition.Y,
				ignoreList,
				color,
				0.4
			)

		elseif targetType == "circle" or targetType == "party_circle" then
			local aoeRadius = skill.aoeRadius or range
			renderTerrainRing(
				self._aoeDrawer,
				centerXZ,
				lookForward,
				aoeRadius,
				math.max(0, aoeRadius - 0.4),
				360,
				referenceY,
				ignoreList,
				color,
				0.4
			)

		elseif targetType == "cone" then
			local angle = skill.coneAngle or 180
			renderTerrainRing(
				self._coneDrawer,
				centerXZ,
				direction,
				range,
				0,
				angle,
				referenceY,
				ignoreList,
				color,
				0.5
			)

		elseif targetType == "single" or targetType == "projectile" or targetType == "directional" then
			local aoeRadius = skill.aoeRadius or 0
			local primaryTarget = affectedRoots[1]
			if aoeRadius > 0 and primaryTarget then
				local targetXZ = Vector3.new(primaryTarget.Position.X, 0, primaryTarget.Position.Z)
				renderTerrainRing(
					self._aoeDrawer,
					targetXZ,
					lookForward,
					aoeRadius,
					math.max(0, aoeRadius - 0.4),
					360,
					primaryTarget.Position.Y,
					ignoreList,
					color,
					0.4
				)
			elseif targetType == "directional" then
				local width = skill.aoeRadius and (skill.aoeRadius * 2) or 3
				local flatDirection = flatUnit(direction)
				local startPos = Vector3.new(rootPosition.X, 0, rootPosition.Z)
				local endPos = startPos + flatDirection * range
				renderTerrainLine(self._lineDrawer, startPos, endPos, width, referenceY, ignoreList, color, 0.5)
			end
		end
	end

	for i = 1, MAX_HIGHLIGHT_POOL do
		local drawer = self._highlightDrawers[i]
		local enemyRoot = affectedRoots[i]

		if enemyRoot then
			local enemyXZ = Vector3.new(enemyRoot.Position.X, 0, enemyRoot.Position.Z)
			renderTerrainRing(
				drawer,
				enemyXZ,
				lookForward,
				HIGHLIGHT_RADIUS,
				0,
				360,
				enemyRoot.Position.Y,
				ignoreList,
				AFFECTED_COLOR,
				0.35,
				0.25,
				HIGHLIGHT_SEGMENTS
			)
		else
			hideDrawer(drawer)
		end
	end
end

local function forEachActiveSegment(self, callback)
	local drawers = {
		self._rangeDrawer,
		self._aoeDrawer,
		self._coneDrawer,
		self._lineDrawer,
	}
	for _, drawer in drawers do
		local count = math.min(drawer.activeCount, #drawer.segments)
		for i = 1, count do
			local segment = drawer.segments[i]
			if segment then
				callback(segment.beam)
			end
		end
	end
	for _, drawer in self._highlightDrawers do
		local count = math.min(drawer.activeCount, #drawer.segments)
		for i = 1, count do
			local segment = drawer.segments[i]
			if segment then
				callback(segment.beam)
			end
		end
	end
end

function TargetingIndicator:Hide()
	cancelFade(self)
	self._isVisible = false
	hideDrawer(self._rangeDrawer)
	hideDrawer(self._aoeDrawer)
	hideDrawer(self._coneDrawer)
	hideDrawer(self._lineDrawer)
	for _, drawer in self._highlightDrawers do
		hideDrawer(drawer)
	end
end

function TargetingIndicator:FadeOut(duration)
	duration = duration or 0.2
	if not self._isVisible then
		return
	end

	cancelFade(self)

	local fadeEntries = {}
	forEachActiveSegment(self, function(beam)
		table.insert(fadeEntries, {
			beam = beam,
			startValue = beam.Transparency.Keypoints[1].Value,
		})
	end)

	if #fadeEntries == 0 then
		self:Hide()
		return
	end

	local startTime = tick()
	self._fadeConnection = RunService.Heartbeat:Connect(function()
		local alpha = math.min(1, (tick() - startTime) / duration)
		for _, entry in fadeEntries do
			local value = entry.startValue + (1 - entry.startValue) * alpha
			entry.beam.Transparency = NumberSequence.new(value)
		end
		if alpha >= 1 then
			cancelFade(self)
			self:Hide()
		end
	end)
end

function TargetingIndicator:Destroy()
	if self._folder then
		self._folder:Destroy()
	end
end

return TargetingIndicator
