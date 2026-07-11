local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local EquipmentVisualUtil = require(Shared.Util.EquipmentVisualUtil)

local EquipmentService = {}
EquipmentService._playerData = nil
EquipmentService._combatService = nil
EquipmentService._remotes = nil

function EquipmentService:EquipCharacter(character, equipped)
	if not character or not equipped then
		if character then
			EquipmentVisualUtil.clearEquipment(character)
		end
		return
	end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		return
	end

	for slot, visualConfig in EquipmentVisualUtil.SLOT_VISUALS do
		if not equipped[slot] then
			continue
		end

		local partName = visualConfig.attachPart
			or (humanoid.RigType == Enum.HumanoidRigType.R15 and visualConfig.attachPartR15 or visualConfig.attachPartR6)
		if partName then
			character:WaitForChild(partName, 5)
		end

		if visualConfig.mirror and not visualConfig.mirrorOffset and partName then
			local mirrorName = partName:gsub("Left", "Right")
			if mirrorName ~= partName then
				character:WaitForChild(mirrorName, 5)
			end
		end
	end

	EquipmentVisualUtil.applyAllVisuals(character, equipped, Items)
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

function EquipmentService:HandleEquipItem(player, itemId, uid)
	local success, message = self._playerData:EquipItem(player, itemId, uid)
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

	local equippedEntry = data.equipped[slot]
	local success, message = self._playerData:UnequipItem(player, slot)
	if success then
		self:ApplyEquipmentChange(player)
		local itemName = EquipmentVisualUtil.resolveItemName(equippedEntry, Items) or slot
		self._remotes.Notification:FireClient(player, "Unequipped " .. itemName)
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
	self._remotes.EquipItem.OnServerEvent:Connect(function(player, itemId, uid)
		self:HandleEquipItem(player, itemId, uid)
	end)

	self._remotes.UnequipItem.OnServerEvent:Connect(function(player, slot)
		self:HandleUnequipItem(player, slot)
	end)
end

return EquipmentService
