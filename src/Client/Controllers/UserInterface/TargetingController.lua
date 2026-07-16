local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

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

function TargetingController:Init()
	if self._initialized then
		return
	end
	self._initialized = true

	self._mouse = self._player:GetMouse()
	self._indicator = TargetingIndicator.new(workspace)

	self._player.CharacterRemoving:Connect(function()
		self:EndPreview()
	end)
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

	if skill.slotType == "autoAttack" then
		local nearestTarget = nil
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

return TargetingController
