local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SkillBarUI = require(script.Parent.Parent.UI.SkillBar.SkillBarUI)
local AttackAnimations = require(script.Parent.Parent.Util.AttackAnimations)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hasSelectedClass = false
local skillBar = SkillBarUI.new(player:WaitForChild("PlayerGui"))

local KEY_TO_SLOT = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
}

local function playAutoAttackAnimation()
	local character = player.Character
	if not character then
		return
	end
	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		AttackAnimations.play(character, tool)
	end
end

local function castSlot(slotIndex)
	if not hasSelectedClass then
		return
	end
	if slotIndex == 1 then
		playAutoAttackAnimation()
	end
	remotes.CastSkill:FireServer(slotIndex)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not hasSelectedClass then
		return
	end

	local slot = KEY_TO_SLOT[input.KeyCode]
	if slot then
		castSlot(slot)
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		castSlot(1)
	end
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	hasSelectedClass = payload.hasSelectedClass == true
	skillBar:SetVisible(hasSelectedClass)
	if payload.skillLoadout then
		skillBar:UpdateLoadout(payload.skillLoadout)
	end
	if payload.mana ~= nil then
		skillBar:SetMana(payload.mana)
	end
end)

remotes.SkillCooldownUpdated.OnClientEvent:Connect(function(skillId, duration)
	skillBar:StartCooldown(skillId, duration)
end)
