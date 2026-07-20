local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TargetingUtil = require(Shared.Combat.TargetingUtil)
local SkillConfig = require(Shared.Config.SkillConfig)
local TargetingIndicator = require(script.Parent.Parent.Parent.UI.Targeting.TargetingIndicator)

local TargetingController = {}
TargetingController._player = Players.LocalPlayer
TargetingController._mouse = nil
TargetingController._indicator = nil
TargetingController._activePreview = nil
TargetingController._renderConnection = nil
TargetingController._initialized = false
TargetingController._lockedTarget = nil
TargetingController._lockHighlight = nil

function TargetingController:Init()
	if self._initialized then
		return
	end
	self._initialized = true

	self._mouse = self._player:GetMouse()
	self._indicator = TargetingIndicator.new(workspace)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("TargetLockUpdated").OnClientEvent:Connect(function(target)
		self:SetLockedTarget(target)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			local target = self:GetEnemyFromInstance(self._mouse.Target)
			if target then
				self:RequestTargetLock(target == self._lockedTarget and nil or target)
			end
		elseif input.KeyCode == Enum.KeyCode.Tab then
			self:CycleTarget()
		end
	end)

	RunService.Heartbeat:Connect(function()
		local target = self._lockedTarget
		if target then
			local health = target:GetAttribute("Health")
			if not health then
				local humanoid = target:FindFirstChild("Humanoid")
				if humanoid then
					health = humanoid.Health
				end
			end
			if not target.Parent or (health or 0) <= 0 then
				self:SetLockedTarget(nil)
				self:RequestTargetLock(nil)
			end
		end
	end)

	self._player.CharacterRemoving:Connect(function()
		self:EndPreview()
	end)
end

function TargetingController:GetEnemyFromInstance(instance)
	while instance and instance ~= workspace do
		if instance:IsA("Model") then
			if CollectionService:HasTag(instance, "Enemy") then
				return instance
			end
			local player = Players:GetPlayerFromCharacter(instance)
			if player and player ~= self._player then
				return instance
			end
		end
		instance = instance.Parent
	end
	return nil
end

function TargetingController:SetLockedTarget(target)
	if self._lockHighlight then
		self._lockHighlight:Destroy()
		self._lockHighlight = nil
	end
	self._lockedTarget = target and self:GetEnemyFromInstance(target) or nil
	if self._lockedTarget then
		local highlight = Instance.new("Highlight")
		highlight.Name = "TargetLockHighlight"
		highlight.FillColor = Color3.fromRGB(255, 70, 70)
		highlight.OutlineColor = Color3.fromRGB(255, 220, 80)
		highlight.FillTransparency = 0.75
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Adornee = self._lockedTarget
		highlight.Parent = self._lockedTarget
		self._lockHighlight = highlight
	end
end

function TargetingController:RequestTargetLock(target)
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	remotes:WaitForChild("TargetLockRequest"):FireServer(target)
end

function TargetingController:CycleTarget()
	local character = self._player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local nearest, nearestDistance

	local function checkTarget(targetModel)
		local targetRoot = targetModel.Parent and (targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart)
		if not targetRoot then return end
		local health = targetModel:GetAttribute("Health")
		if not health then
			local humanoid = targetModel:FindFirstChild("Humanoid")
			if humanoid then
				health = humanoid.Health
			end
		end
		if (health or 0) > 0 then
			local distance = (targetRoot.Position - root.Position).Magnitude
			if distance <= 100 and (not nearestDistance or distance < nearestDistance) then
				nearest, nearestDistance = targetModel, distance
			end
		end
	end

	for _, enemy in CollectionService:GetTagged("Enemy") do
		checkTarget(enemy)
	end
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= self._player and otherPlayer.Character then
			checkTarget(otherPlayer.Character)
		end
	end

	if nearest then
		self:RequestTargetLock(nearest == self._lockedTarget and nil or nearest)
	end
end

function TargetingController:GetIgnoreList()
	local ignore = {}
	local character = self._player.Character
	if character then
		table.insert(ignore, character)
	end
	-- Also ignore the enemies folder so the raycast hits the ground
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
		table.insert(ignore, enemies)
	end
	return ignore
end

function TargetingController:BuildTargetData(skill, character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local range = skill.range or 10
	local targetData = {
		direction = root.CFrame.LookVector,
		attackOrigin = root.Position,
	}

	local lockedTarget = self._lockedTarget
	local lockedRoot = lockedTarget and (lockedTarget:FindFirstChild("HumanoidRootPart") or lockedTarget.PrimaryPart)
	local lockedTargetInRange = false
	if lockedRoot and lockedTarget.Parent then
		local health = lockedTarget:GetAttribute("Health")
		if not health then
			local humanoid = lockedTarget:FindFirstChild("Humanoid")
			if humanoid then
				health = humanoid.Health
			end
		end
		if (health or 0) > 0 then
			local offset = lockedRoot.Position - root.Position
			lockedTargetInRange = Vector3.new(offset.X, 0, offset.Z).Magnitude <= range + 0.5
			if lockedTargetInRange then
				targetData.targetInstance = lockedTarget
				targetData.attackTargetPosition = lockedRoot.Position
				if offset.Magnitude > 0.01 then
					targetData.direction = offset.Unit
				end
				if skill.targetType == SkillConfig.TargetTypes.Ground then
					targetData.groundPosition = lockedRoot.Position
				end
			end
		end
	end

	if skill.slotType == "autoAttack" then
		local nearestTarget = lockedTargetInRange and lockedTarget or nil
		local nearestDistance = range
		local flatLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if flatLook.Magnitude > 0 then
			flatLook = flatLook.Unit
		end

		local function considerTarget(target, targetRoot)
			if not targetRoot then
				return
			end
			local offset = targetRoot.Position - root.Position
			local flatOffset = Vector3.new(offset.X, 0, offset.Z)
			local distance = flatOffset.Magnitude
			if distance > nearestDistance then
				return
			end
			if distance > 0 and flatLook.Magnitude > 0 and flatOffset.Unit:Dot(flatLook) < TargetingUtil.GetConeDotThreshold() then
				return
			end
			nearestTarget = target
			nearestDistance = distance
		end

		if not nearestTarget then
			for _, enemy in CollectionService:GetTagged("Enemy") do
				if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
					considerTarget(enemy, enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart)
				end
			end
			for _, otherPlayer in Players:GetPlayers() do
				if otherPlayer ~= self._player then
					local otherCharacter = otherPlayer.Character
					considerTarget(otherPlayer, otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart"))
				end
			end
		end

		if nearestTarget then
			local targetRoot = nearestTarget:IsA("Player")
				and nearestTarget.Character and nearestTarget.Character:FindFirstChild("HumanoidRootPart")
				or nearestTarget:FindFirstChild("HumanoidRootPart") or nearestTarget.PrimaryPart
			targetData.attackTargetPosition = targetRoot and targetRoot.Position
			if nearestTarget:IsA("Player") then
				targetData.targetUserId = nearestTarget.UserId
			else
				targetData.targetInstance = nearestTarget
			end
		end
	end

	if skill.targetType == SkillConfig.TargetTypes.Ground then
		local groundPos = TargetingUtil.GetMouseGroundPosition(
			self._mouse,
			root.Position,
			range,
			self:GetIgnoreList()
		)

		if groundPos then
			targetData.groundPosition = groundPos
			local offset = groundPos - root.Position
			local flatOffset = Vector3.new(offset.X, 0, offset.Z)
			if flatOffset.Magnitude > 0.001 then
				targetData.direction = flatOffset.Unit
			end
		end
	end

	return targetData
end

function TargetingController:UpdatePreview(skill, character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not self._indicator then
		return
	end

	local targetData = self:BuildTargetData(skill, character)
	if not targetData then
		return
	end

	local range = skill.range or 10
	local isValid = true

	if skill.targetType == SkillConfig.TargetTypes.Ground and targetData.groundPosition then
		isValid = TargetingUtil.IsValidTargetPosition(root.Position, targetData.groundPosition, range)
		if not TargetingUtil.IsInFront(root.Position, root.CFrame.LookVector, targetData.groundPosition) then
			isValid = false
		end
	end

	self._indicator:Update(
		skill,
		root.CFrame,
		targetData.groundPosition or root.Position,
		targetData.direction,
		isValid,
		self:GetIgnoreList()
	)
end

function TargetingController:BeginPreview(skill, castTime)
	self:EndPreview()

	local character = self._player.Character
	if not character or not skill then
		return
	end

	self._activePreview = {
		skill = skill,
		endsAt = tick() + (castTime or 0),
	}

	self:UpdatePreview(skill, character)

	self._renderConnection = RunService.RenderStepped:Connect(function()
		local preview = self._activePreview
		if not preview then
			return
		end

		local currentCharacter = self._player.Character
		if not currentCharacter then
			self:EndPreview()
			return
		end

		self:UpdatePreview(preview.skill, currentCharacter)

		if tick() >= preview.endsAt then
			self:EndPreview(true)
		end
	end)
end

function TargetingController:EndPreview(fadeOut)
	if self._renderConnection then
		self._renderConnection:Disconnect()
		self._renderConnection = nil
	end

	if self._indicator then
		if fadeOut then
			self._indicator:FadeOut()
		else
			self._indicator:Hide()
		end
	end

	self._activePreview = nil
end

function TargetingController:GetTargetDataForCast(skill)
	local character = self._player.Character
	if not character then
		return {}
	end
	return self:BuildTargetData(skill, character) or {}
end

-- Returns true if there is at least one live enemy mob or hostile player
-- within the skill's range. Used to block attack casts with no valid target.
function TargetingController:HasTargetInRange(skill)
	local character = self._player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	local range = (skill.range or 10) + 0.5

	-- Check a locked target first (it is guaranteed to be an enemy/player)
	local lockedTarget = self._lockedTarget
	if lockedTarget and lockedTarget.Parent then
		local lockedRoot = lockedTarget:FindFirstChild("HumanoidRootPart") or lockedTarget.PrimaryPart
		if lockedRoot then
			local health = lockedTarget:GetAttribute("Health")
			if not health then
				local hum = lockedTarget:FindFirstChild("Humanoid")
				if hum then health = hum.Health end
			end
			local dist = Vector3.new(
				lockedRoot.Position.X - root.Position.X,
				0,
				lockedRoot.Position.Z - root.Position.Z
			).Magnitude
			if (health or 0) > 0 then
				return dist <= range
			end
		end
	end

	-- Check tagged enemy mobs
	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and (enemy:GetAttribute("Health") or 0) > 0 then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if enemyRoot then
				local dist = Vector3.new(
					enemyRoot.Position.X - root.Position.X,
					0,
					enemyRoot.Position.Z - root.Position.Z
				).Magnitude
				if dist <= range then
					return true
				end
			end
		end
	end

	-- Check other players
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= self._player then
			local c = otherPlayer.Character
			local otherRoot = c and c:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local health = c:GetAttribute("Health")
				if not health then
					local hum = c:FindFirstChild("Humanoid")
					if hum then health = hum.Health end
				end
				local dist = Vector3.new(
					otherRoot.Position.X - root.Position.X,
					0,
					otherRoot.Position.Z - root.Position.Z
				).Magnitude
				if (health or 0) > 0 and dist <= range then
					return true
				end
			end
		end
	end

	return false
end

return TargetingController
