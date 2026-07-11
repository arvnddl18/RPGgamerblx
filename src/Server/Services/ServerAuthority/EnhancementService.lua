local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Items = require(Shared.Config.Items)
local EnhancementConfig = require(Shared.Config.EnhancementConfig)

local EnhancementService = {}
EnhancementService._playerData = nil
EnhancementService._remotes = nil
EnhancementService._rng = Random.new()

function EnhancementService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._remotes = Framework:GetRemotesFolder()
	Framework:GetRemote("EnhancementResult")
	if not self._remotes:FindFirstChild("ApplyEnhancement") then
		local remote = Instance.new("RemoteFunction")
		remote.Name = "ApplyEnhancement"
		remote.Parent = self._remotes
	end
end

function EnhancementService:_rollOutcome(tier)
	local roll = self._rng:NextNumber()
	local cumulative = tier.success
	if roll <= cumulative then
		return "success"
	end
	cumulative += tier.fail
	if roll <= cumulative then
		return "fail"
	end
	cumulative += tier.downgrade
	if roll <= cumulative then
		return "downgrade"
	end
	return "break"
end

function EnhancementService:ApplyEnhancement(player, scrollItemId, targetUid)
	local scrollItem = Items[scrollItemId]
	if not scrollItem or scrollItem.category ~= "scrolls" then
		return false, { outcome = "error", message = "Invalid scroll." }
	end

	if not self._playerData:HasItem(player, scrollItemId, 1) then
		return false, { outcome = "error", message = "Scroll not in inventory." }
	end

	local targetEntry, targetIndex = self._playerData:GetInventoryEntryByUid(player, targetUid)
	local equippedSlot = nil
	if not targetEntry then
		equippedSlot = self._playerData:FindEquippedSlotByUid(player, targetUid)
		if equippedSlot then
			local data = self._playerData:GetData(player)
			targetEntry = data.equipped[equippedSlot]
		end
	end

	if not targetEntry then
		return false, { outcome = "error", message = "Target item not found." }
	end

	local targetItem = Items[targetEntry.id]
	if not targetItem or not targetItem.slot then
		return false, { outcome = "error", message = "Item cannot be enhanced." }
	end

	local scrollTier = scrollItem.scrollTier
	local enhanceLevel = targetEntry.enhanceLevel or 0
	if enhanceLevel >= scrollTier then
		return false, { outcome = "error", message = "Scroll tier too low for this item." }
	end
	if enhanceLevel >= EnhancementConfig.MAX_ENHANCE_LEVEL then
		return false, { outcome = "error", message = "Item is already max enhancement." }
	end

	local tier = EnhancementConfig.GetTierForLevel(enhanceLevel + 1)
	if not self._playerData:TakeCoins(player, tier.applyGoldCost) then
		return false, { outcome = "error", message = "Not enough gold to apply scroll." }
	end

	if not self._playerData:RemoveItem(player, scrollItemId, 1) then
		self._playerData:AddCoins(player, tier.applyGoldCost)
		return false, { outcome = "error", message = "Could not consume scroll." }
	end

	local outcome = self:_rollOutcome(tier)
	local resultPayload = {
		outcome = outcome,
		targetUid = targetUid,
		enhanceLevel = enhanceLevel,
		scrollTier = scrollTier,
	}

	if outcome == "success" then
		targetEntry.enhanceLevel = enhanceLevel + 1
		resultPayload.enhanceLevel = targetEntry.enhanceLevel
	elseif outcome == "downgrade" then
		targetEntry.enhanceLevel = math.max(0, enhanceLevel - 1)
		resultPayload.enhanceLevel = targetEntry.enhanceLevel
	elseif outcome == "break" then
		if equippedSlot then
			local data = self._playerData:GetData(player)
			data.equipped[equippedSlot] = nil
		elseif targetIndex then
			self._playerData:RemoveItemByUid(player, targetUid)
		end
	end

	self._playerData:RecalculateStats(player)
	local data = self._playerData:GetData(player)
	if data then
		self._remotes.InventoryUpdated:FireClient(player, data.inventory)
	end
	self._playerData:FireStatsUpdated(player)

	if outcome == "break" and equippedSlot then
		local Framework = require(ReplicatedStorage.Shared.Framework)
		local equipmentService = Framework:GetService("EquipmentService")
		if equipmentService then
			equipmentService:ApplyEquipmentChange(player)
		end
	end

	self._remotes.EnhancementResult:FireClient(player, resultPayload)
	if outcome == "success" then
		self._remotes.Notification:FireClient(player, "Enhancement success! +" .. resultPayload.enhanceLevel)
	elseif outcome == "fail" then
		self._remotes.Notification:FireClient(player, "Enhancement failed.")
	elseif outcome == "downgrade" then
		self._remotes.Notification:FireClient(player, "Enhancement downgraded to +" .. resultPayload.enhanceLevel)
	elseif outcome == "break" then
		self._remotes.Notification:FireClient(player, "Item destroyed!")
	end
	return true, resultPayload
end

function EnhancementService:Start()
	self._remotes.ApplyEnhancement.OnServerInvoke = function(player, scrollItemId, targetUid)
		return self:ApplyEnhancement(player, scrollItemId, targetUid)
	end
end

return EnhancementService
