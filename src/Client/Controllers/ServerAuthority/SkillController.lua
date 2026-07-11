local Controller = {}

function Controller:Start()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SkillBarUI = require(script.Parent.Parent.Parent.UI.SkillBar.SkillBarUI)
local AnimationController = require(ReplicatedStorage.Shared.Util.AnimationController)
local LocalAnimationBuilder = require(ReplicatedStorage.Shared.Util.LocalAnimationBuilder)
local Skills = require(ReplicatedStorage.Shared.Config.Skills)
local TargetingController = require(script.Parent.Parent.UserInterface.TargetingController)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hasSelectedClass = false
local playerLevel = 1
local skillBar = SkillBarUI.new(player:WaitForChild("PlayerGui"))
local currentLoadout = {} -- slotIndex → skillId
local localCooldowns = {} -- skillId → tick() when cooldown expires
local animCtrl = nil -- AnimationController for the current character
local comboResetTimer = nil -- thread that resets the auto-attack combo

local KEY_TO_SLOT = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
}

---------------------------------------------------------------------------
-- Character lifecycle
---------------------------------------------------------------------------

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	if animCtrl then
		animCtrl:Destroy()
	end

	animCtrl = AnimationController.new(humanoid)
end

local function onCharacterRemoving()
	if comboResetTimer then
		task.cancel(comboResetTimer)
		comboResetTimer = nil
	end
	if animCtrl then
		animCtrl:Destroy()
		animCtrl = nil
	end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterRemoving:Connect(onCharacterRemoving)

---------------------------------------------------------------------------
-- Animation playback
---------------------------------------------------------------------------

local function playSkillAnimation(slotIndex)
	if not animCtrl then return end

	local skillId = currentLoadout[slotIndex]
	if not skillId then return end

	local skillConfig = Skills[skillId]
	if not skillConfig then return end

	if skillConfig.slotType == "autoAttack" then
		animCtrl:PlayAutoAttack(skillConfig)

		-- Reset the combo if the player stops auto-attacking for 2 seconds
		if comboResetTimer then
			task.cancel(comboResetTimer)
		end
		comboResetTimer = task.delay(2, function()
			if animCtrl then
				animCtrl:ResetCombo()
			end
			comboResetTimer = nil
		end)
	else
		animCtrl:PlaySkillCast(skillConfig)
	end
end

---------------------------------------------------------------------------
-- Skill casting
---------------------------------------------------------------------------

local POTION_SLOTS = {
	[6] = { id = "HealthPotion", drink = LocalAnimationBuilder.DrinkHealthPotion },
	[7] = { id = "ManaPotion", drink = LocalAnimationBuilder.DrinkManaPotion },
}

TargetingController:Init()

local function castSlot(slotIndex)
	if not hasSelectedClass then
		return
	end

	local potion = POTION_SLOTS[slotIndex]
	if potion then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		potion.drink(humanoid)
		remotes.CastSkill:FireServer(slotIndex)
		return
	end

	local skillId = currentLoadout[slotIndex]
	if not skillId then return end

	local skillConfig = Skills.Get(skillId)
	if not skillConfig then return end

	local now = tick()
	if localCooldowns[skillId] and now < localCooldowns[skillId] then
		return
	end

	local requiredLevel = skillConfig.requiredLevel or 1
	if playerLevel < requiredLevel then
		return
	end

	local targetData = TargetingController:GetTargetDataForCast(skillConfig)
	TargetingController:BeginPreview(skillConfig, skillConfig.castTime or 0)

	localCooldowns[skillId] = now + (skillConfig.cooldown or 0)
	playSkillAnimation(slotIndex)
	remotes.CastSkill:FireServer(slotIndex, targetData)
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

---------------------------------------------------------------------------
-- Server events
---------------------------------------------------------------------------

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	hasSelectedClass = payload.hasSelectedClass == true
	skillBar:SetVisible(hasSelectedClass)
	if payload.skillLoadout then
		currentLoadout = payload.skillLoadout
		skillBar:UpdateLoadout(payload.skillLoadout)

		-- Preload all skill animations for the current loadout into cache
		local preloadIds = {}
		for _, skillId in currentLoadout do
			local cfg = Skills[skillId]
			if cfg then
				if cfg.castAnimId then
					table.insert(preloadIds, cfg.castAnimId)
				end
				if cfg.comboAnims then
					for _, comboId in cfg.comboAnims do
						table.insert(preloadIds, comboId)
					end
				end
			end
		end
		AnimationController.PreloadAnimations(preloadIds)
	end
	if payload.mana ~= nil then
		skillBar:SetMana(payload.mana)
	end
	if payload.level ~= nil then
		playerLevel = payload.level
		skillBar:SetLevel(payload.level)
	end
end)

remotes.SkillCooldownUpdated.OnClientEvent:Connect(function(skillId, duration)
	skillBar:StartCooldown(skillId, duration)
end)

end

return Controller
