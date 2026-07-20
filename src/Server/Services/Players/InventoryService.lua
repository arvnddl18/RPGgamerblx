local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)

local InventoryService = {}
InventoryService._playerData = nil
InventoryService._combatService = nil

function InventoryService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._combatService = Framework:GetService("CombatService")
	self._questService = Framework:GetService("QuestService")
	self._remotes = Framework:GetRemotesFolder()
	Framework:GetRemote("DropItem")
end

function InventoryService:SetupPickup(part)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end

	prompt.Triggered:Connect(function(player)
		self:CollectPickup(player, part)
	end)
end

function InventoryService:CollectPickup(player, part)
	if not player or not part or not part.Parent then
		return false
	end

	local itemId = part:GetAttribute("ItemId")
	if not itemId or part:GetAttribute("PickupClaimed") then
		return false
	end
	part:SetAttribute("PickupClaimed", true)

	local itemConfig = Items[itemId]
	local addData = itemId
	if itemConfig and itemConfig.supportsRarity then
		local rarity = part:GetAttribute("MaterialRarity") or "Common"
		addData = { id = itemId, rarity = rarity }
	end

	if not self._playerData:AddItem(player, addData, 1) then
		part:SetAttribute("PickupClaimed", nil)
		return false
	end

	part:Destroy()
	return true
end

function InventoryService:WatchPickups()
	local pickupsFolder = workspace:FindFirstChild("Pickups")
	if pickupsFolder then
		for _, part in pickupsFolder:GetChildren() do
			self:SetupPickup(part)
		end
		pickupsFolder.ChildAdded:Connect(function(child)
			self:SetupPickup(child)
		end)
	end

	workspace.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") and child:GetAttribute("ItemId") then
			self:SetupPickup(child)
		end
	end)

	for _, child in workspace:GetChildren() do
		if child:IsA("BasePart") and child:GetAttribute("ItemId") then
			self:SetupPickup(child)
		end
	end
end

function InventoryService:UseItem(player, itemId)
	local item = Items[itemId]
	if not item or not item.usable then
		return false
	end

	if not self._playerData:HasItem(player, itemId, 1) then
		return false
	end

	if item.type == "consumable" then
		if not self._playerData:RemoveItem(player, itemId, 1) then
			return false
		end
		
		if item.healAmount then
			self._playerData:Heal(player, item.healAmount)
			self._remotes.Notification:FireClient(player, "Used " .. item.name .. " (+" .. item.healAmount .. " HP)")
		end
		
		if item.manaAmount then
			self._playerData:RestoreMana(player, item.manaAmount)
			self._remotes.Notification:FireClient(player, "Used " .. item.name .. " (+" .. item.manaAmount .. " Mana)")
		end

		if item.buffEffectId then
			local Framework = require(ReplicatedStorage.Shared.Framework)
			local buffService = Framework:GetService("BuffService")
			if buffService then
				buffService:ApplyEffect(player, item.buffEffectId, item.buffDuration or 10, player, item.buffIntensity)
			end
		end

		return true
	end

	return false
end

function InventoryService:DropItem(player, uid, itemId, count, rarity)
	local entry = nil
	local removed = false

	if uid then
		local invEntry = self._playerData:GetInventoryEntryByUid(player, uid)
		if invEntry then
			removed, entry = self._playerData:RemoveItemByUid(player, uid)
		else
			local slot = self._playerData:FindEquippedSlotByUid(player, uid)
			if slot then
				local data = self._playerData:GetData(player)
				entry = data and data.equipped[slot]
				if entry then
					data.equipped[slot] = nil
					self._playerData:RecalculateStats(player)
					self._playerData:FireStatsUpdated(player)
					removed = true

					local Framework = require(ReplicatedStorage.Shared.Framework)
					local equipmentService = Framework:GetService("EquipmentService")
					if equipmentService then
						equipmentService:ApplyEquipmentChange(player)
					end
				end
			end
		end
	elseif itemId then
		count = count or 1
		if self._playerData:HasItem(player, itemId, count) then
			for _, invEntry in self._playerData:GetInventory(player) do
				local rarityMatch = not rarity or (invEntry.rarity or "Common") == rarity
				if invEntry.id == itemId and rarityMatch then
					entry = { id = itemId, rarity = invEntry.rarity }
					break
				end
			end
			removed = self._playerData:RemoveItem(player, itemId, count, rarity)
		end
	end

	if not removed or not entry then
		self._remotes.Notification:FireClient(player, "Could not drop item")
		return false
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local Framework = require(ReplicatedStorage.Shared.Framework)
		local enemyService = Framework:GetService("EnemyService")
		if enemyService then
			enemyService:CreatePickup(root.Position, entry.id, entry.rarity)
		end
	end

	self._remotes.Notification:FireClient(player, "Dropped " .. (Items[entry.id] and Items[entry.id].name or entry.id))
	return true
end

function InventoryService:Start()
	self._remotes.UseItem.OnServerEvent:Connect(function(player, itemId)
		self:UseItem(player, itemId)
	end)

	self._remotes.RequestInventory.OnServerEvent:Connect(function(player)
		local inventory = self._playerData:GetInventory(player)
		self._remotes.InventoryUpdated:FireClient(player, inventory)
	end)

	if self._remotes.DropItem then
		self._remotes.DropItem.OnServerEvent:Connect(function(player, uid, itemId, count, rarity)
			self:DropItem(player, uid, itemId, count, rarity)
		end)
	end

	self:WatchPickups()
end

return InventoryService
