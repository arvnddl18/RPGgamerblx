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
	self._remotes = Framework:GetRemotesFolder()
end

function InventoryService:SetupPickup(part)
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		return
	end

	prompt.Triggered:Connect(function(player)
		local itemId = part:GetAttribute("ItemId")
		if not itemId then
			return
		end

		if self._playerData:AddItem(player, itemId, 1) then
			part:Destroy()
		end
	end)
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

	if item.type == "consumable" and item.healAmount then
		if not self._playerData:RemoveItem(player, itemId, 1) then
			return false
		end
		self._playerData:Heal(player, item.healAmount)
		self._remotes.Notification:FireClient(player, "Used " .. item.name .. " (+" .. item.healAmount .. " HP)")
		return true
	end

	return false
end

function InventoryService:Start()
	self._remotes.UseItem.OnServerEvent:Connect(function(player, itemId)
		self:UseItem(player, itemId)
	end)

	self._remotes.RequestInventory.OnServerEvent:Connect(function(player)
		local inventory = self._playerData:GetInventory(player)
		self._remotes.InventoryUpdated:FireClient(player, inventory)
	end)

	self:WatchPickups()
end

return InventoryService
