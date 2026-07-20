local Controller = {}

function Controller:Start()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")

	local AnimationController = require(ReplicatedStorage.Shared.Util.AnimationController)
	local Skills = require(ReplicatedStorage.Shared.Config.Skills)
	local SkillBarUI = require(script.Parent.Parent.Parent.UI.SkillBar.SkillBarUI)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	local hasSelectedClass = false
	local autoFarmEnabled = false
	local animCtrl
	local autoAttackSkill
	local movementKeys = {
		[Enum.KeyCode.W] = true,
		[Enum.KeyCode.A] = true,
		[Enum.KeyCode.S] = true,
		[Enum.KeyCode.D] = true,
		[Enum.KeyCode.Up] = true,
		[Enum.KeyCode.Down] = true,
		[Enum.KeyCode.Left] = true,
		[Enum.KeyCode.Right] = true,
		[Enum.KeyCode.Space] = true,
	}

	SkillBarUI.AutofarmToggleRequested.Event:Connect(function()
		if hasSelectedClass then
			remotes.AutoFarmToggle:FireServer(not autoFarmEnabled)
		end
	end)

	local function setCharacter(character)
		if animCtrl then
			animCtrl:Destroy()
		end
		local humanoid = character:WaitForChild("Humanoid", 5)
		animCtrl = humanoid and AnimationController.new(humanoid) or nil
	end

	player.CharacterAdded:Connect(setCharacter)
	player.CharacterRemoving:Connect(function()
		if animCtrl then
			animCtrl:Destroy()
			animCtrl = nil
		end
	end)
	if player.Character then
		setCharacter(player.Character)
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if autoFarmEnabled and movementKeys[input.KeyCode] then
			remotes.AutoFarmToggle:FireServer(false)
			return
		end
		if not hasSelectedClass then
			return
		end
		if input.KeyCode == Enum.KeyCode.F then
			remotes.AutoFarmToggle:FireServer(not autoFarmEnabled)
		end
	end)

	UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if gameProcessed or not autoFarmEnabled then
			return
		end
		if input.UserInputType == Enum.UserInputType.Gamepad1
			and input.KeyCode == Enum.KeyCode.Thumbstick1
			and input.Position.Magnitude > 0.2 then
			remotes.AutoFarmToggle:FireServer(false)
		end
	end)

	remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
		hasSelectedClass = payload.hasSelectedClass == true
		if payload.skillLoadout then
			local skill = Skills.Get(payload.skillLoadout[1])
			autoAttackSkill = skill and skill.slotType == "autoAttack" and skill or nil
		end
		if not hasSelectedClass and autoFarmEnabled then
			autoFarmEnabled = false
		end
	end)

	remotes.AutoFarmState.OnClientEvent:Connect(function(enabled)
		autoFarmEnabled = enabled == true
		SkillBarUI.SetAutofarmState(autoFarmEnabled)
	end)

	remotes.AutoFarmSkillPerformed.OnClientEvent:Connect(function(skillId)
		if not autoFarmEnabled or not animCtrl then
			return
		end
		
		local function play8DASMR(soundName)
			local workspace = game:GetService("Workspace")
			local audioFolder = workspace:FindFirstChild("Audio")
			local originalSound = audioFolder and audioFolder:FindFirstChild(soundName)
			if originalSound and originalSound:IsA("Sound") then
				local orbitPart = workspace:FindFirstChild("MusicOrbitPart")
				if orbitPart then
					local s = originalSound:Clone()
					s.Parent = orbitPart
					s.RollOffMaxDistance = 150
					s.RollOffMinDistance = 10
					s.RollOffMode = Enum.RollOffMode.InverseTapered
					
					local soundGroup = game:GetService("SoundService"):FindFirstChild("ASMR8DGroup_SFX")
					if soundGroup then
						s.SoundGroup = soundGroup
					end
					
					s:Play()
					game:GetService("Debris"):AddItem(s, math.max(s.TimeLength, 2))
				else
					originalSound:Play()
				end
			end
		end

		-- Play sounds for auto-farm normal attacks
		if skillId == "Warrior_AutoAttack" or skillId == "Kavalier_AutoAttack" then
			play8DASMR("swordswing")
		elseif skillId == "Archer_AutoAttack" then
			play8DASMR("Bow_shoot")
		elseif skillId == "Mage_AutoAttack" then
			play8DASMR("Magic (S)")
		elseif skillId == "Priest_AutoAttack" then
			play8DASMR("Regret Hammer Swing")
		end

		local skill = Skills.Get(skillId) or autoAttackSkill
		if skill and skill.slotType == "autoAttack" then
			animCtrl:PlayAutoAttack(skill)
		elseif skill then
			animCtrl:PlaySkillCast(skill)
		end
	end)
end

return Controller
