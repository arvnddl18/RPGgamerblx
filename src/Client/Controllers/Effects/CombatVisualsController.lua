local Controller = {}

function Controller:Start()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Framework = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"))
local FloatingText = require(script.Parent.Parent.Parent.Util.FloatingText)
local TargetHUDUI = require(script.Parent.Parent.Parent.UI.Targeting.TargetHUDUI)

local targetHud = TargetHUDUI.new(Players.LocalPlayer:WaitForChild("PlayerGui"))
local combatEvent = Framework:GetRemote("CombatEvents")

combatEvent.OnClientEvent:Connect(function(eventType, ...)
	local args = {...}
	
	if eventType == "Damage" then
		local character = args[1]
		local amount = args[2]
		local isCrit = args[3]
		local attacker = args[4]
		FloatingText.ShowDamage(character, amount, isCrit)
		
		if attacker == Players.LocalPlayer then
			targetHud:SetTarget(character)
		end
		
	elseif eventType == "Heal" then
		local character = args[1]
		local amount = args[2]
		FloatingText.ShowHeal(character, amount)
		
	elseif eventType == "Skill" then
		local character = args[1]
		local skillName = args[2]
		FloatingText.ShowSkillLabel(character, skillName)
		
	elseif eventType == "Gold" then
		local amount = args[1]
		FloatingText.ShowGoldGain(amount)
		
	elseif eventType == "Exp" then
		local amount = args[1]
		FloatingText.ShowExpGain(amount)
	end
end)

end

return Controller
