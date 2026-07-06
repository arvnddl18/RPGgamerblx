local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalAnimationBuilder = require(ReplicatedStorage.Shared.Util.LocalAnimationBuilder)
local Enemies = require(ReplicatedStorage.Shared.Config.Enemies)

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
