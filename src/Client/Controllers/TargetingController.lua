local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TargetingUtil = require(Shared.Combat.TargetingUtil)
local SkillConfig = require(Shared.Config.SkillConfig)
local TargetingIndicator = require(script.Parent.Parent.UI.Targeting.TargetingIndicator)

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
	}

	if skill.targetType == SkillConfig.TargetTypes.Ground then
		local groundPos = TargetingUtil.GetMouseGroundPosition(
			self._mouse,
			root.Position,
			range,
			self:GetIgnoreList()
		)
		targetData.groundPosition = groundPos
		targetData.direction = (groundPos - root.Position).Unit
	end

	return targetData
end

function TargetingController:UpdatePreview(skill, character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or not self._indicator then
		return
	end

	local range = skill.range or 10
	local showRange = skill.showRangeIndicator ~= false
	local showAoe = skill.showAoeIndicator == true
		or skill.targetType == SkillConfig.TargetTypes.Ground
		or skill.targetType == SkillConfig.TargetTypes.Circle

	self._indicator:Show(showRange, showAoe)
	self._indicator:SetRangeRing(root.Position, range)

	local isValid = true
	if skill.targetType == SkillConfig.TargetTypes.Ground then
		local groundPos = TargetingUtil.GetMouseGroundPosition(
			self._mouse,
			root.Position,
			range,
			self:GetIgnoreList()
		)
		isValid = TargetingUtil.IsValidTargetPosition(root.Position, groundPos, range)
		self._indicator:SetAoeDisc(groundPos, skill.aoeRadius or range)
	elseif showAoe then
		self._indicator:SetAoeDisc(root.Position, skill.aoeRadius or range)
	end

	self._indicator:SetValid(isValid)
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
