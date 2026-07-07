local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkillVfxUtil = require(ReplicatedStorage.Shared.Util.SkillVfxUtil)

local remotes = ReplicatedStorage:WaitForChild("Remotes")

remotes.PlaySkillVfx.OnClientEvent:Connect(function(player, vfxKey)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end
	if typeof(vfxKey) ~= "string" then
		return
	end
	local character = player.Character
	if character then
		SkillVfxUtil.Play(character, vfxKey)
	end
end)
