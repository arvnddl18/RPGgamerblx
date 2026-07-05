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
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15

	-- Wait a moment for body parts to spawn natively
	task.wait(0.5)

	-- Prevent double-equipping if this runs multiple times
	if character:FindFirstChild("DefaultEquipment") then return end

	local equipmentFolder = Instance.new("Folder")
	equipmentFolder.Name = "DefaultEquipment"

	local head = character:FindFirstChild("Head")
	if head then
		local helm = createEquipmentPart("Helm", Vector3.new(1.1, 1.1, 1.1), Color3.fromRGB(150, 150, 160), equipmentFolder)
		weldTo(helm, head, CFrame.new(0, 0.1, 0))
		local visor = createEquipmentPart("Visor", Vector3.new(0.9, 0.3, 0.2), Color3.fromRGB(200, 200, 50), equipmentFolder)
		weldTo(visor, head, CFrame.new(0, 0.2, -0.5))
	end

	local torso = isR15 and character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if torso then
		local armor = createEquipmentPart("Breastplate", Vector3.new(2.1, 2.1, 1.2), Color3.fromRGB(120, 120, 130), equipmentFolder)
		weldTo(armor, torso, CFrame.new(0, 0, 0))

		local leftPauldron = createEquipmentPart("LeftPauldron", Vector3.new(1.2, 0.8, 1.2), Color3.fromRGB(150, 150, 160), equipmentFolder)
		weldTo(leftPauldron, torso, CFrame.new(-1.2, 0.8, 0))
		local rightPauldron = createEquipmentPart("RightPauldron", Vector3.new(1.2, 0.8, 1.2), Color3.fromRGB(150, 150, 160), equipmentFolder)
		weldTo(rightPauldron, torso, CFrame.new(1.2, 0.8, 0))
		
		local cape = createEquipmentPart("Cape", Vector3.new(1.8, 3, 0.1), Color3.fromRGB(180, 40, 40), equipmentFolder)
		weldTo(cape, torso, CFrame.new(0, -0.2, 0.65) * CFrame.Angles(math.rad(10), 0, 0))
	end

	local leftLeg = isR15 and character:FindFirstChild("LeftLowerLeg") or character:FindFirstChild("Left Leg")
	if leftLeg then
		local leftBoot = createEquipmentPart("LeftBoot", Vector3.new(1.1, 0.8, 1.1), Color3.fromRGB(80, 80, 90), equipmentFolder)
		weldTo(leftBoot, leftLeg, CFrame.new(0, -0.6, 0))
	end

	local rightLeg = isR15 and character:FindFirstChild("RightLowerLeg") or character:FindFirstChild("Right Leg")
	if rightLeg then
		local rightBoot = createEquipmentPart("RightBoot", Vector3.new(1.1, 0.8, 1.1), Color3.fromRGB(80, 80, 90), equipmentFolder)
		weldTo(rightBoot, rightLeg, CFrame.new(0, -0.6, 0))
	end

	local leftArm = isR15 and character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm")
	if leftArm then
		local leftGauntlet = createEquipmentPart("LeftGauntlet", Vector3.new(1.1, 1.0, 1.1), Color3.fromRGB(100, 100, 110), equipmentFolder)
		weldTo(leftGauntlet, leftArm, CFrame.new(0, -0.4, 0))
	end

	local rightArm = isR15 and character:FindFirstChild("RightLowerArm") or character:FindFirstChild("Right Arm")
	if rightArm then
		local rightGauntlet = createEquipmentPart("RightGauntlet", Vector3.new(1.1, 1.0, 1.1), Color3.fromRGB(100, 100, 110), equipmentFolder)
		weldTo(rightGauntlet, rightArm, CFrame.new(0, -0.4, 0))
	end

	equipmentFolder.Parent = character
end

function EquipmentService:Init()
end

function EquipmentService:Start()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			equipCharacter(character)
		end)
	end)

	-- Handle players already in the game
	for _, player in Players:GetPlayers() do
		if player.Character then
			equipCharacter(player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			equipCharacter(character)
		end)
	end
end

return EquipmentService
