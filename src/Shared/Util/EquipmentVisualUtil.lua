local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EquipmentVisualUtil = {}

EquipmentVisualUtil.RPG_EQUIPMENT_ATTR = "RPGEquipment"
EquipmentVisualUtil.RPG_EQUIPMENT_SLOT_ATTR = "RPGEquipmentSlot"

EquipmentVisualUtil.SLOT_VISUALS = {
	helmet = {
		visualMode = "rigid",
		attachPart = "Head",
		size = Vector3.new(1.1, 1.1, 1.1),
		offset = CFrame.new(0, 0.1, 0),
		clearTypes = { "Hat", "Face" },
	},
	armor = {
		visualMode = "layered",
		attachPartR15 = "UpperTorso",
		attachPartR6 = "Torso",
		size = Vector3.new(2.1, 2.1, 1.2),
		offset = CFrame.new(0, 0, 0),
		clearTypes = { "Shirt", "Jacket", "Sweater", "TShirt" },
		clearClassic = "shirt",
	},
	shoulders = {
		visualMode = "rigid",
		attachPartR15 = "UpperTorso",
		attachPartR6 = "Torso",
		size = Vector3.new(0.9, 0.55, 1.15),
		offset = CFrame.new(-1.05, 0.85, 0),
		mirror = true,
		mirrorOffset = CFrame.new(1.05, 0.85, 0),
		clearTypes = { "Shoulder" },
	},
	upperArms = {
		visualMode = "layered",
		attachPartR15 = "LeftUpperArm",
		attachPartR6 = "Left Arm",
		size = Vector3.new(1.08, 1.2, 1.08),
		offset = CFrame.new(0, 0, 0),
		mirror = true,
	},
	pants = {
		visualMode = "layered",
		attachPartR15 = "LowerTorso",
		attachPartR6 = "Torso",
		size = Vector3.new(2.0, 1.2, 1.1),
		offset = CFrame.new(0, -1.0, 0),
		clearTypes = { "Pants", "Shorts", "DressSkirt" },
		clearClassic = "pants",
	},
	boots = {
		visualMode = "layered",
		attachPartR15 = "LeftLowerLeg",
		attachPartR6 = "Left Leg",
		size = Vector3.new(1.1, 0.8, 1.1),
		offset = CFrame.new(0, -0.6, 0),
		mirror = true,
		clearTypes = { "LeftShoe", "RightShoe" },
	},
	gloves = {
		visualMode = "rigid",
		attachPartR15 = "LeftLowerArm",
		attachPartR6 = "Left Arm",
		size = Vector3.new(1.1, 1.0, 1.1),
		offset = CFrame.new(0, -0.4, 0),
		mirror = true,
		clearTypes = { "LeftGlove", "RightGlove" },
	},
}

local accessoryTypeCache = {}

local function getAccessoryType(name)
	if accessoryTypeCache[name] ~= nil then
		return accessoryTypeCache[name]
	end
	local ok, value = pcall(function()
		return Enum.AccessoryType[name]
	end)
	accessoryTypeCache[name] = ok and value or false
	return accessoryTypeCache[name] or nil
end

function EquipmentVisualUtil.resolveItemId(equippedEntry)
	if not equippedEntry then
		return nil
	end
	if type(equippedEntry) == "table" then
		return equippedEntry.id
	end
	if type(equippedEntry) == "string" then
		return equippedEntry
	end
	return nil
end

function EquipmentVisualUtil.resolveItemName(equippedEntry, items)
	local itemId = EquipmentVisualUtil.resolveItemId(equippedEntry)
	if not itemId then
		return nil
	end
	local item = items[itemId]
	return item and item.name or itemId
end

local function getAttachPartName(visualConfig, isR15)
	local partName = isR15 and visualConfig.attachPartR15 or visualConfig.attachPartR6
	if not partName then
		partName = visualConfig.attachPart
	end
	return partName
end

local function createPartVisual(name, size, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.Massless = true
	part.Anchored = false
	part.Parent = parent
	return part
end

local function weldPart(part, target, offset)
	part.CFrame = target.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = target
	weld.Parent = part
end

function EquipmentVisualUtil.clearEquipment(character)
	local folder = character:FindFirstChild("ClassEquipment")
	if folder then
		folder:Destroy()
	end

	for _, child in character:GetChildren() do
		if child:IsA("Accessory") and child:GetAttribute(EquipmentVisualUtil.RPG_EQUIPMENT_ATTR) then
			child:Destroy()
		end
	end
end

local function clearClassicClothing(character, kind)
	if kind == "shirt" then
		local shirt = character:FindFirstChildOfClass("Shirt")
		if shirt then
			shirt:Destroy()
		end
		local graphic = character:FindFirstChildOfClass("ShirtGraphic")
		if graphic then
			graphic:Destroy()
		end
	elseif kind == "pants" then
		local pants = character:FindFirstChildOfClass("Pants")
		if pants then
			pants:Destroy()
		end
	end
end

local function clearConflictingAccessories(character, visualConfig)
	if not visualConfig.clearTypes then
		return
	end

	local clearSet = {}
	for _, typeName in visualConfig.clearTypes do
		local accessoryType = getAccessoryType(typeName)
		if accessoryType then
			clearSet[accessoryType] = true
		end
	end

	for _, child in character:GetChildren() do
		if child:IsA("Accessory") and not child:GetAttribute(EquipmentVisualUtil.RPG_EQUIPMENT_ATTR) then
			if clearSet[child.AccessoryType] then
				child:Destroy()
			end
		end
	end

	if visualConfig.clearClassic then
		clearClassicClothing(character, visualConfig.clearClassic)
	end
end

local function loadAccessoryFromCatalog(assetId)
	local ok, container = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not container then
		return nil
	end

	local accessory = container:FindFirstChildWhichIsA("Accessory", true)
	if accessory then
		accessory = accessory:Clone()
	end
	container:Destroy()
	return accessory
end

local function loadAccessoryFromProject(itemId)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Equipment")
	if not folder then
		return nil
	end

	local template = folder:FindFirstChild(itemId)
	if not template then
		return nil
	end

	if template:IsA("Accessory") then
		return template:Clone()
	end

	if template:IsA("Model") then
		local accessory = template:FindFirstChildWhichIsA("Accessory", true)
		if accessory then
			return accessory:Clone()
		end
	end

	return nil
end

local function resolveAccessoryClone(item)
	if item.accessoryAssetId then
		local catalogAccessory = loadAccessoryFromCatalog(item.accessoryAssetId)
		if catalogAccessory then
			return catalogAccessory
		end
	end
	return loadAccessoryFromProject(item.id)
end

local function attachAccessory(humanoid, accessory, slot, side)
	accessory:SetAttribute(EquipmentVisualUtil.RPG_EQUIPMENT_ATTR, true)
	accessory:SetAttribute(EquipmentVisualUtil.RPG_EQUIPMENT_SLOT_ATTR, side and (slot .. side) or slot)

	local ok = pcall(function()
		humanoid:AddAccessory(accessory)
	end)
	if not ok then
		accessory:Destroy()
		return false
	end
	return true
end

local function applyPartVisuals(character, slot, visualConfig, item, isR15, equipmentFolder)
	local attachPart = character:FindFirstChild(getAttachPartName(visualConfig, isR15))
	if not attachPart then
		return
	end

	local part = createPartVisual(slot .. "Visual", visualConfig.size, item.color, equipmentFolder)
	weldPart(part, attachPart, visualConfig.offset)

	if visualConfig.mirror then
		if visualConfig.mirrorOffset then
			local mirrorPart = createPartVisual(slot .. "VisualRight", visualConfig.size, item.color, equipmentFolder)
			weldPart(mirrorPart, attachPart, visualConfig.mirrorOffset)
		else
			local mirrorName = getAttachPartName(visualConfig, isR15):gsub("Left", "Right")
			local mirrorAttach = character:FindFirstChild(mirrorName)
			if mirrorAttach then
				local mirrorPart = createPartVisual(slot .. "VisualRight", visualConfig.size, item.color, equipmentFolder)
				weldPart(mirrorPart, mirrorAttach, visualConfig.offset)
			end
		end
	end
end

function EquipmentVisualUtil.applySlotVisual(character, humanoid, slot, equippedEntry, items)
	local visualConfig = EquipmentVisualUtil.SLOT_VISUALS[slot]
	if not visualConfig then
		return
	end

	local itemId = EquipmentVisualUtil.resolveItemId(equippedEntry)
	if not itemId then
		return
	end

	local item = items[itemId]
	if not item then
		return
	end

	clearConflictingAccessories(character, visualConfig)

	local accessory = resolveAccessoryClone(item)
	if accessory then
		if attachAccessory(humanoid, accessory, slot, nil) then
			if visualConfig.mirror and item.mirrorAccessoryAssetId then
				local mirrorAccessory = loadAccessoryFromCatalog(item.mirrorAccessoryAssetId)
				if mirrorAccessory then
					attachAccessory(humanoid, mirrorAccessory, slot, "Right")
				end
			end
			return
		end
		accessory:Destroy()
	end

	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
	local equipmentFolder = character:FindFirstChild("ClassEquipment")
	if not equipmentFolder then
		equipmentFolder = Instance.new("Folder")
		equipmentFolder.Name = "ClassEquipment"
		equipmentFolder.Parent = character
	end

	applyPartVisuals(character, slot, visualConfig, item, isR15, equipmentFolder)
end

function EquipmentVisualUtil.applyAllVisuals(character, equipped, items)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not equipped then
		return
	end

	EquipmentVisualUtil.clearEquipment(character)

	for slot in EquipmentVisualUtil.SLOT_VISUALS do
		if equipped[slot] then
			EquipmentVisualUtil.applySlotVisual(character, humanoid, slot, equipped[slot], items)
		end
	end
end

return EquipmentVisualUtil
