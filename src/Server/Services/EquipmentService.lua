local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)

local EquipmentService = {}
EquipmentService._playerData = nil
EquipmentService._combatService = nil
EquipmentService._remotes = nil

local SLOT_VISUALS = {
	helmet = { attachPart = "Head", size = Vector3.new(1.1, 1.1, 1.1), offset = CFrame.new(0, 0.1, 0) },
	armor = { attachPartR15 = "UpperTorso", attachPartR6 = "Torso", size = Vector3.new(2.1, 2.1, 1.2), offset = CFrame.new(0, 0, 0) },
	pants = { attachPartR15 = "LowerTorso", attachPartR6 = "Torso", size = Vector3.new(2.0, 1.2, 1.1), offset = CFrame.new(0, -1.0, 0) },
	boots = { attachPartR15 = "LeftLowerLeg", attachPartR6 = "Left Leg", size = Vector3.new(1.1, 0.8, 1.1), offset = CFrame.new(0, -0.6, 0), mirror = true },
	gloves = { attachPartR15 = "LeftLowerArm", attachPartR6 = "Left Arm", size = Vector3.new(1.1, 1.0, 1.1), offset = CFrame.new(0, -0.4, 0), mirror = true },
}

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

local function getAttachPart(character, visualConfig, isR15)
	local partName = isR15 and visualConfig.attachPartR15 or visualConfig.attachPartR6
	if not partName then
		partName = visualConfig.attachPart
	end
	return character:FindFirstChild(partName)
end

local function clearEquipment(character)
	local folder = character:FindFirstChild("ClassEquipment")
	if folder then
		folder:Destroy()
	end
end

function EquipmentService:EquipCharacter(character, equipped)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		return
	end

	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
	task.wait(0.2)
	clearEquipment(character)

	if not equipped then
		return
	end

	local equipmentFolder = Instance.new("Folder")
	equipmentFolder.Name = "ClassEquipment"

	for slot, visualConfig in SLOT_VISUALS do
		local itemId = equipped[slot]
		if itemId then
			local item = Items[itemId]
			if item then
				local attachPart = getAttachPart(character, visualConfig, isR15)
				if attachPart then
					local part = createEquipmentPart(slot .. "Visual", visualConfig.size, item.color, equipmentFolder)
					weldTo(part, attachPart, visualConfig.offset)

					if visualConfig.mirror then
						local mirrorName = isR15 and visualConfig.attachPartR15:gsub("Left", "Right") or visualConfig.attachPartR6:gsub("Left", "Right")
						local mirrorAttach = character:FindFirstChild(mirrorName)
						if mirrorAttach then
							local mirrorPart = createEquipmentPart(slot .. "VisualRight", visualConfig.size, item.color, equipmentFolder)
							weldTo(mirrorPart, mirrorAttach, visualConfig.offset)
						end
					end
				end
			end
		end
	end

	equipmentFolder.Parent = character
end

function EquipmentService:EquipPlayer(player)
	local data = self._playerData:GetData(player)
	if not data or not data.hasSelectedClass then
		return
	end

	local character = player.Character
	if character then
		self:EquipCharacter(character, data.equipped)
	end
end

function EquipmentService:ApplyEquipmentChange(player)
	self:EquipPlayer(player)
	if self._combatService then
		self._combatService:GiveWeapon(player)
	end
end

function EquipmentService:HandleEquipItem(player, itemId)
	local success, message = self._playerData:EquipItem(player, itemId)
	if success then
		self:ApplyEquipmentChange(player)
		self._remotes.Notification:FireClient(player, "Equipped " .. (Items[itemId] and Items[itemId].name or itemId))
	else
		self._remotes.Notification:FireClient(player, message or "Could not equip item")
	end
	return success
end

function EquipmentService:HandleUnequipItem(player, slot)
	local data = self._playerData:GetData(player)
	if not data then
		return false
	end
	local itemId = data.equipped[slot]
	local success, message = self._playerData:UnequipItem(player, slot)
	if success then
		self:ApplyEquipmentChange(player)
		local item = itemId and Items[itemId]
		self._remotes.Notification:FireClient(player, "Unequipped " .. (item and item.name or slot))
	else
		self._remotes.Notification:FireClient(player, message or "Could not unequip")
	end
	return success
end

function EquipmentService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._combatService = Framework:GetService("CombatService")
	self._remotes = Framework:GetRemotesFolder()

	Framework:GetRemote("EquipItem")
	Framework:GetRemote("UnequipItem")
end

function EquipmentService:Start()
	local Players = game:GetService("Players")

	self._remotes.EquipItem.OnServerEvent:Connect(function(player, itemId)
		self:HandleEquipItem(player, itemId)
	end)

	self._remotes.UnequipItem.OnServerEvent:Connect(function(player, slot)
		self:HandleUnequipItem(player, slot)
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			local data = self._playerData:GetData(player)
			if data and data.hasSelectedClass then
				self:EquipCharacter(player.Character, data.equipped)
			end
		end)
	end)

	for _, player in Players:GetPlayers() do
		if player.Character then
			local data = self._playerData:GetData(player)
			if data and data.hasSelectedClass then
				self:EquipCharacter(player.Character, data.equipped)
			end
		end
		player.CharacterAdded:Connect(function(character)
			local data = self._playerData:GetData(player)
			if data and data.hasSelectedClass then
				self:EquipCharacter(character, data.equipped)
			end
		end)
	end
end

return EquipmentService
