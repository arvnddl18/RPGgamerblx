local Players = game:GetService("Players")

local EquipmentService = {}

local function createEquipmentPart(name, size, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.Massless = true
	part.Parent = parent
	return part
end

local function weldTo(part, target, offset)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = target
	weld.Parent = part
	part.CFrame = target.CFrame * offset
end

local function equipCharacter(character)
	-- Use a retry loop instead of WaitForChild with a hard timeout
	-- CharacterAppearanceLoaded guarantees parts exist, but we still guard
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 10)
	end
	if not humanoid then return end

	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15

	-- Body part references — all should exist since we wait for AppearanceLoaded
	local head = character:WaitForChild("Head", 10)
	local torso = isR15 and character:WaitForChild("UpperTorso", 10) or character:WaitForChild("Torso", 10)
	local leftLeg = isR15 and character:WaitForChild("LeftLowerLeg", 10) or character:WaitForChild("Left Leg", 10)
	local rightLeg = isR15 and character:WaitForChild("RightLowerLeg", 10) or character:WaitForChild("Right Leg", 10)
	local leftArm = isR15 and character:WaitForChild("LeftLowerArm", 10) or character:WaitForChild("Left Arm", 10)
	local rightArm = isR15 and character:WaitForChild("RightLowerArm", 10) or character:WaitForChild("Right Arm", 10)

	if not (head and torso and leftLeg and rightLeg and leftArm and rightArm) then return end

	-- Prevent double-equipping if this runs multiple times
	if character:FindFirstChild("DefaultEquipment") then return end

	local equipmentFolder = Instance.new("Folder")
	equipmentFolder.Name = "DefaultEquipment"
	equipmentFolder.Parent = character

	-- Helm
	local helm = createEquipmentPart("Helm", Vector3.new(1.1, 1.1, 1.1), Color3.fromRGB(150, 150, 160), equipmentFolder)
	weldTo(helm, head, CFrame.new(0, 0.1, 0))
	local visor = createEquipmentPart("Visor", Vector3.new(0.9, 0.3, 0.2), Color3.fromRGB(200, 200, 50), equipmentFolder)
	weldTo(visor, head, CFrame.new(0, 0.2, -0.5))

	-- Armor (Breastplate + Pauldrons)
	local armor = createEquipmentPart("Breastplate", Vector3.new(2.1, 2.1, 1.2), Color3.fromRGB(120, 120, 130), equipmentFolder)
	weldTo(armor, torso, CFrame.new(0, 0, 0))

	local leftPauldron = createEquipmentPart("LeftPauldron", Vector3.new(1.2, 0.8, 1.2), Color3.fromRGB(150, 150, 160), equipmentFolder)
	weldTo(leftPauldron, torso, CFrame.new(-1.2, 0.8, 0))
	local rightPauldron = createEquipmentPart("RightPauldron", Vector3.new(1.2, 0.8, 1.2), Color3.fromRGB(150, 150, 160), equipmentFolder)
	weldTo(rightPauldron, torso, CFrame.new(1.2, 0.8, 0))

	-- Boots
	local leftBoot = createEquipmentPart("LeftBoot", Vector3.new(1.1, 0.8, 1.1), Color3.fromRGB(80, 80, 90), equipmentFolder)
	weldTo(leftBoot, leftLeg, CFrame.new(0, -0.6, 0))
	local rightBoot = createEquipmentPart("RightBoot", Vector3.new(1.1, 0.8, 1.1), Color3.fromRGB(80, 80, 90), equipmentFolder)
	weldTo(rightBoot, rightLeg, CFrame.new(0, -0.6, 0))

	-- Back Equipment (Cape)
	local cape = createEquipmentPart("Cape", Vector3.new(1.8, 3, 0.1), Color3.fromRGB(180, 40, 40), equipmentFolder)
	weldTo(cape, torso, CFrame.new(0, -0.2, 0.65) * CFrame.Angles(math.rad(10), 0, 0))

	-- Hand Equipment (Gauntlets)
	local leftGauntlet = createEquipmentPart("LeftGauntlet", Vector3.new(1.1, 1.0, 1.1), Color3.fromRGB(100, 100, 110), equipmentFolder)
	weldTo(leftGauntlet, leftArm, CFrame.new(0, -0.4, 0))
	local rightGauntlet = createEquipmentPart("RightGauntlet", Vector3.new(1.1, 1.0, 1.1), Color3.fromRGB(100, 100, 110), equipmentFolder)
	weldTo(rightGauntlet, rightArm, CFrame.new(0, -0.4, 0))

	-- NOTE: Weapon is handled by CombatService, not here
end

local function onCharacterAppearanceLoaded(character)
	-- Small delay to let everything settle
	task.wait(0.3)
	if character and character.Parent then
		equipCharacter(character)
	end
end

function EquipmentService:Init()
	-- Nothing required for init
end

function EquipmentService:Start()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAppearanceLoaded:Connect(function(character)
			onCharacterAppearanceLoaded(character)
		end)
	end)

	-- Handle players already in the game
	for _, player in Players:GetPlayers() do
		if player.Character then
			onCharacterAppearanceLoaded(player.Character)
		end
		player.CharacterAppearanceLoaded:Connect(function(character)
			onCharacterAppearanceLoaded(character)
		end)
	end
end

return EquipmentService
