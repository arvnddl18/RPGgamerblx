local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local LocalAnimationBuilder = require(Shared.Util.LocalAnimationBuilder)
local Enemies = require(Shared.Config.Enemies)
local Skills = require(Shared.Config.Skills)

local AnimationPrecacheController = {}

function AnimationPrecacheController:Init()
	-- Precache enemy animations
	for _, config in Enemies do
		if type(config) ~= "table" or not config.id then
			continue
		end
		if config.walkAnimKey then LocalAnimationBuilder.GetAnimId(config.walkAnimKey) end
		if config.idleAnimKey then LocalAnimationBuilder.GetAnimId(config.idleAnimKey) end
		if config.attackAnimKeys then
			for _, key in config.attackAnimKeys do
				LocalAnimationBuilder.GetAnimId(key)
			end
		end
	end

	-- Precache skill animations
	for _, skill in Skills do
		if type(skill) ~= "table" or not skill.id then
			continue
		end
		if skill.castAnimKey then
			Skills.GetAnimId(skill.castAnimKey)
		end
		if skill.comboAnimKeys then
			for _, key in skill.comboAnimKeys do
				Skills.GetAnimId(key)
			end
		end
	end

	-- Precache tool hold animations
	local TOOL_HOLD_KEYS = {
		"GetWarriorToolHold", "GetMageToolHold", "GetArcherToolHold",
		"GetPriestToolHold", "GetKavalierToolHold",
	}
	for _, key in TOOL_HOLD_KEYS do
		LocalAnimationBuilder.GetAnimId(key)
	end

	-- Precache rest animations
	local REST_KEYS = {
		"GetRestLayDown1", "GetRestLayDown2", "GetRestLoop1", "GetRestLoop2",
		"GetRestStandUp1", "GetRestStandUp2",
		"GetDrinkHealthPotion", "GetDrinkManaPotion",
	}
	for _, key in REST_KEYS do
		LocalAnimationBuilder.GetAnimId(key)
	end
end

function AnimationPrecacheController:Start()
	-- All precaching is done in Init
end

return AnimationPrecacheController
