local Controller = {}

function Controller:Start()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local LocalAnimationBuilder = require(Shared.Util.LocalAnimationBuilder)
local InventoryEquipmentUI = require(script.Parent.Parent.Parent.UI.Inventory.InventoryEquipmentUI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local inventory = {}
local equipped = {}
local classId = nil
local visible = false
local hasSelectedClass = false
local enhanceBusy = false
local setVisible

local ui = InventoryEquipmentUI.new(player:WaitForChild("PlayerGui"))

local function optimisticEquip(entry, uid)
	local item = Items[entry.id]
	if not item or not item.slot then
		return
	end
	local slot = item.slot
	local current = equipped[slot]
	equipped[slot] = {
		id = entry.id,
		uid = entry.uid or uid,
		rarity = entry.rarity,
		statMultiplier = entry.statMultiplier,
		enhanceLevel = entry.enhanceLevel or 0,
	}
	for i, invEntry in inventory do
		if invEntry.uid == uid then
			if invEntry.count and invEntry.count > 1 then
				invEntry.count -= 1
			else
				table.remove(inventory, i)
			end
			break
		end
	end
	if current then
		table.insert(inventory, current)
	end
	ui:SetInventory(inventory)
	ui:SetEquipped(equipped)
end

local function optimisticUnequip(slot)
	local entry = equipped[slot]
	if not entry then
		return
	end
	equipped[slot] = nil
	table.insert(inventory, entry)
	ui:SetInventory(inventory)
	ui:SetEquipped(equipped)
end

local function optimisticRemoveEntry(entry)
	if entry.uid then
		for i, invEntry in inventory do
			if invEntry.uid == entry.uid then
				if invEntry.count and invEntry.count > 1 then
					invEntry.count -= 1
				else
					table.remove(inventory, i)
				end
				ui:SetInventory(inventory)
				return
			end
		end
		for slot, equippedEntry in equipped do
			if type(equippedEntry) == "table" and equippedEntry.uid == entry.uid then
				equipped[slot] = nil
				ui:SetEquipped(equipped)
				return
			end
		end
		return
	end

	for i, invEntry in inventory do
		local rarityMatch = not entry.rarity or (invEntry.rarity or "Common") == entry.rarity
		if invEntry.id == entry.id and rarityMatch then
			if invEntry.count and invEntry.count > 1 then
				invEntry.count -= 1
			else
				table.remove(inventory, i)
			end
			ui:SetInventory(inventory)
			return
		end
	end
end

ui:OnEquip(function(slotData)
	local entry = slotData.entry
	if not entry or not entry.uid then
		return
	end
	optimisticEquip(entry, entry.uid)
	remotes.EquipItem:FireServer(entry.id, entry.uid)
end)

ui:OnUnequip(function(slotData)
	if slotData.config.kind ~= "equipment" then
		return
	end
	local slot = slotData.config.slotId
	if not equipped[slot] then
		return
	end
	optimisticUnequip(slot)
	remotes.UnequipItem:FireServer(slot)
end)

ui:OnUse(function(slotData)
	local entry = slotData.entry
	if not entry then
		return
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if entry.id == "HealthPotion" then
		LocalAnimationBuilder.DrinkHealthPotion(humanoid)
	elseif entry.id == "ManaPotion" then
		LocalAnimationBuilder.DrinkManaPotion(humanoid)
	end
	remotes.UseItem:FireServer(entry.id)
end)

ui:OnDropItem(function(slotData)
	local entry = slotData.entry
	if not entry or not remotes:FindFirstChild("DropItem") then
		return
	end
	optimisticRemoveEntry(entry)
	if entry.uid then
		remotes.DropItem:FireServer(entry.uid)
	else
		remotes.DropItem:FireServer(nil, entry.id, 1, entry.rarity)
	end
end)

ui:OnEnhance(function(slotData)
	local entry = slotData.entry
	if not entry then
		return
	end
	local targetUid = entry.uid
	if not targetUid and slotData.config.kind == "equipment" then
		local equippedEntry = equipped[slotData.config.slotId]
		targetUid = type(equippedEntry) == "table" and equippedEntry.uid or nil
	end
	if not targetUid then
		return
	end
	local enhancementGui = player.PlayerGui:FindFirstChild("EnhancementUI")
	local openEvent = enhancementGui and enhancementGui:FindFirstChild("OpenEnhancementUI")
	if openEvent then
		setVisible(false)
		openEvent:Fire(targetUid)
	end
end)

ui:OnCraft(function(slotData)
	local entry = slotData.entry
	if not entry then
		return
	end
	local item = Items[entry.id]
	if not item then
		return
	end

	local context = { tab = "potions" }
	if item.slot then
		context.tab = "upgrade"
		context.targetUid = entry.uid
		context.slot = item.slot
		context.classId = classId
	elseif item.category == "materials" then
		context.tab = "upgrade"
	end

	setVisible(false)
	if remotes:FindFirstChild("RequestCrafting") then
		remotes.RequestCrafting:FireServer(context)
	end
end)

ui:OnEnhanceApply(function(scrollId, targetUid)
	if enhanceBusy or not scrollId or not targetUid then
		return
	end
	if not remotes:FindFirstChild("ApplyEnhancement") then
		return
	end
	enhanceBusy = true
	local ok = remotes.ApplyEnhancement:InvokeServer(scrollId, targetUid)
	enhanceBusy = false
	if ok then
		ui:SetEnhanceMode(false)
	end
end)

ui:OnEnhanceCancel(function()
	ui:SetEnhanceMode(false)
end)

ui:OnDragDrop(function(sourceSlot, targetSlot)
	local sourceEntry = sourceSlot.entry
	if not sourceEntry then
		return
	end

	if sourceSlot.config.kind == "inventory" and targetSlot.config.kind == "equipment" then
		local item = Items[sourceEntry.id]
		if not item or item.slot ~= targetSlot.config.slotId or not sourceEntry.uid then
			return
		end
		optimisticEquip(sourceEntry, sourceEntry.uid)
		remotes.EquipItem:FireServer(sourceEntry.id, sourceEntry.uid)
	elseif sourceSlot.config.kind == "equipment" and targetSlot.config.kind == "inventory" then
		local slot = sourceSlot.config.slotId
		if not equipped[slot] then
			return
		end
		optimisticUnequip(slot)
		remotes.UnequipItem:FireServer(slot)
	elseif sourceSlot.config.kind == "equipment" and targetSlot.config.kind == "equipment" then
		local fromSlot = sourceSlot.config.slotId
		local toSlot = targetSlot.config.slotId
		local fromEntry = equipped[fromSlot]
		if not fromEntry then
			return
		end
		local fromItem = Items[fromEntry.id]
		if not fromItem or fromItem.slot ~= toSlot then
			return
		end
		local toEntry = equipped[toSlot]
		equipped[fromSlot] = toEntry
		equipped[toSlot] = fromEntry
		ui:SetEquipped(equipped)
		remotes.UnequipItem:FireServer(fromSlot)
		remotes.EquipItem:FireServer(fromEntry.id, fromEntry.uid)
	end
end)

setVisible = function(value)
	if not hasSelectedClass then
		return
	end
	visible = value
	ui:SetVisible(visible)
	if visible then
		remotes.RequestInventory:FireServer()
	else
		ui:SetEnhanceMode(false)
	end
end

local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleInventory"
toggleEvent.Parent = ui:GetScreenGui()
toggleEvent.Event:Connect(function()
	setVisible(not visible)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not hasSelectedClass then
		return
	end
	if input.KeyCode == Enum.KeyCode.L or input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.C then
		setVisible(not visible)
	end
end)

remotes.InventoryUpdated.OnClientEvent:Connect(function(newInventory)
	inventory = newInventory or {}
	ui:SetInventory(inventory)
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	hasSelectedClass = payload.hasSelectedClass == true
	classId = payload.classId
	equipped = payload.equipped or {}
	ui:SetEquipped(equipped)
	if not hasSelectedClass then
		setVisible(false)
	end
end)

remotes.EnhancementResult.OnClientEvent:Connect(function()
	enhanceBusy = false
	ui:SetEnhanceMode(false)
end)

end

return Controller
