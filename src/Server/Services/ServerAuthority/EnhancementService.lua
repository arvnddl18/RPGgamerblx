local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Items = require(Shared.Config.Items)
local EnhancementConfig = require(Shared.Config.EnhancementConfig)

local EnhancementService = {}
EnhancementService._playerData = nil
EnhancementService._remotes = nil
EnhancementService._rng = Random.new()

local function copyBonuses(bonuses)
	if not bonuses then
		return nil
	end
	local copy = {}
	for stat, value in pairs(bonuses) do
		copy[stat] = value
	end
	return copy
end

-- An item has one active scroll imprint, not a stack of sequential upgrades.
-- Replacing it must discard every prior bonus so, for example, a Mage Lv. 3
-- scroll cleanly replaces a Fighter Lv. 3 scroll.
local function setImprint(entry, scrollItem, level, bonuses)
	entry.enhanceLevel = math.max(0, level)
	entry.enhancementCategory = scrollItem.enhancementCategory
	entry.enhancementHistory = {}
	entry.enhancementBonuses = copyBonuses(bonuses)
	if entry.enhancementBonuses then
		table.insert(entry.enhancementHistory, copyBonuses(entry.enhancementBonuses))
	end
end

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
	if not scrollTier or scrollTier < 1 then
		return false, { outcome = "error", message = "Invalid enhancement scroll level." }
	end

	-- The selected scroll determines both the risk and the resulting imprint
	-- level. Any scroll rank can be applied directly; there is no player-level
	-- or sequential-enhancement requirement.
	local tier = EnhancementConfig.GetTierForLevel(scrollTier)
	if not self._playerData:TakeCoins(player, tier.applyGoldCost) then
		return false, { outcome = "error", message = "Not enough gold to apply scroll." }
	end

	if not self._playerData:RemoveItem(player, scrollItemId, 1) then
		self._playerData:AddCoins(player, tier.applyGoldCost)
		return false, { outcome = "error", message = "Could not consume scroll." }
	end

	-- Enhancement is deterministic after validation: it never fails, downgrades,
	-- or destroys the item.
	local outcome = "success"
	local resultPayload = {
		outcome = outcome,
		targetUid = targetUid,
		enhanceLevel = enhanceLevel,
		scrollTier = scrollTier,
	}

	if outcome == "success" then
		setImprint(targetEntry, scrollItem, scrollTier, scrollItem.enhancementBonuses)
		resultPayload.enhanceLevel = targetEntry.enhanceLevel
		local Framework = require(ReplicatedStorage.Shared.Framework)
		local questService = Framework:GetService("QuestService")
		if questService then questService:OnEquipmentEnhanced(player) end
	elseif outcome == "downgrade" then
		local downgradedLevel = math.max(0, scrollTier - 1)
		local bonuses = downgradedLevel > 0 and scrollItem.enhancementCategory and EnhancementConfig.GetScrollBonuses(scrollItem.enhancementCategory, downgradedLevel) or nil
		setImprint(targetEntry, scrollItem, downgradedLevel, bonuses)
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
		self._remotes.Notification:FireClient(player, "Enhancement complete! Item is now +" .. resultPayload.enhanceLevel)
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
