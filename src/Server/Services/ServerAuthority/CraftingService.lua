local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local CraftingRecipes = require(Shared.Config.CraftingRecipes)
local CraftingConfig = require(Shared.Config.CraftingConfig)
local RarityConfig = require(Shared.Config.RarityConfig)
local Items = require(Shared.Config.Items)
local R15NPCUtil = require(Shared.Util.R15NPCUtil)

local CraftingService = {}
CraftingService._playerData = nil
CraftingService._remotes = nil
CraftingService._mapGenerator = nil
CraftingService._rng = Random.new()

function CraftingService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._remotes = Framework:GetRemotesFolder()
	self._mapGenerator = Framework:GetService("MapGeneratorService")

	if not self._remotes:FindFirstChild("CraftItem") then
		local remote = Instance.new("RemoteFunction")
		remote.Name = "CraftItem"
		remote.Parent = self._remotes
	end
	if not self._remotes:FindFirstChild("UpgradeEquipment") then
		local remote = Instance.new("RemoteFunction")
		remote.Name = "UpgradeEquipment"
		remote.Parent = self._remotes
	end
	Framework:GetRemote("CraftResult")
	Framework:GetRemote("OpenCrafting")
	Framework:GetRemote("RequestCrafting")
end

function CraftingService:_itemMatchesRecipe(targetEntry, recipe)
	local itemConfig = Items[targetEntry.id]
	if not itemConfig then
		return false
	end
	if recipe.slot and itemConfig.slot ~= recipe.slot then
		return false
	end
	if recipe.classRestriction and itemConfig.classRestriction ~= recipe.classRestriction then
		return false
	end
	if recipe.allowedBaseItems then
		local allowed = false
		for _, id in recipe.allowedBaseItems do
			if id == targetEntry.id then
				allowed = true
				break
			end
		end
		if not allowed then
			return false
		end
	end
	return true
end

function CraftingService:_rollUpgradeOutcome(attemptConfig)
	local roll = self._rng:NextNumber()
	local cumulative = attemptConfig.success
	if roll <= cumulative then
		return "success"
	end
	cumulative += attemptConfig.fail
	if roll <= cumulative then
		return "fail"
	end
	return "destroy"
end

function CraftingService:CraftItem(player, recipeId)
	local recipe = CraftingRecipes[recipeId]
	if not recipe or recipe.type == "equipmentUpgrade" then
		return false, { outcome = "error", message = "Invalid recipe." }
	end

	local data = self._playerData:GetData(player)
	if not data or data.level < (recipe.requiredLevel or 1) then
		return false, { outcome = "error", message = "Level too low." }
	end

	for _, mat in recipe.materials do
		local matItem = Items[mat.itemId]
		if matItem and matItem.category == "scrolls" then
			return false, { outcome = "error", message = "Scrolls cannot be used in crafting." }
		end
		if not self._playerData:HasItem(player, mat.itemId, mat.amount) then
			return false, { outcome = "error", message = "Missing materials." }
		end
	end

	for _, mat in recipe.materials do
		self._playerData:RemoveItem(player, mat.itemId, mat.amount)
	end

	local resultId = recipe.resultItem
	local itemConfig = Items[resultId]
	if self._playerData:AddItem(player, resultId, recipe.resultAmount) then
		local Framework = require(ReplicatedStorage.Shared.Framework)
		local questService = Framework:GetService("QuestService")
		if questService then questService:OnCrafted(player, recipeId) end
		local payload = { outcome = "success", recipeId = recipeId, resultItem = resultId }
		self._remotes.CraftResult:FireClient(player, payload)
		self._remotes.Notification:FireClient(player, "Crafted " .. (recipe.resultAmount or 1) .. "x " .. itemConfig.name .. "!")
		return true, payload
	else
		for _, mat in recipe.materials do
			self._playerData:AddItem(player, mat.itemId, mat.amount)
		end
		return false, { outcome = "error", message = "Inventory error." }
	end
end

function CraftingService:UpgradeEquipment(player, recipeId, targetUid)
	local recipe = CraftingRecipes[recipeId]
	if not recipe or recipe.type ~= "equipmentUpgrade" then
		return false, { outcome = "error", message = "Invalid upgrade recipe." }
	end

	local data = self._playerData:GetData(player)
	if not data then
		return false, { outcome = "error", message = "No player data." }
	end

	local targetEntry, targetIndex = self._playerData:GetInventoryEntryByUid(player, targetUid)
	local equippedSlot = nil
	if not targetEntry then
		equippedSlot = self._playerData:FindEquippedSlotByUid(player, targetUid)
		if equippedSlot then
			targetEntry = data.equipped[equippedSlot]
		end
	end

	if not targetEntry or not self:_itemMatchesRecipe(targetEntry, recipe) then
		return false, { outcome = "error", message = "Item does not match recipe." }
	end

	local currentRarity = targetEntry.rarity or "Common"
	local targetRarity = RarityConfig.GetNextRarity(currentRarity)
	if not targetRarity then
		return false, { outcome = "error", message = "Item is already max rarity." }
	end

	local attemptConfig = CraftingConfig.GetUpgradeAttempt(targetRarity)
	if not attemptConfig then
		return false, { outcome = "error", message = "No upgrade config for this tier." }
	end

	local materialDef = recipe.materials[1]
	if not materialDef then
		return false, { outcome = "error", message = "Recipe has no materials." }
	end

	local matItem = Items[materialDef.itemId]
	if matItem and matItem.category == "scrolls" then
		return false, { outcome = "error", message = "Scrolls cannot be used in crafting." }
	end

	if not self._playerData:HasMaterial(player, materialDef.itemId, attemptConfig.materialAmount, attemptConfig.materialMinRarity) then
		return false, { outcome = "error", message = "Missing required materials." }
	end

	if not self._playerData:TakeCoins(player, attemptConfig.goldCost) then
		return false, { outcome = "error", message = "Not enough gold." }
	end

	if not self._playerData:RemoveMaterial(player, materialDef.itemId, attemptConfig.materialAmount, attemptConfig.materialMinRarity) then
		self._playerData:AddCoins(player, attemptConfig.goldCost)
		return false, { outcome = "error", message = "Could not consume materials." }
	end

	local outcome = self:_rollUpgradeOutcome(attemptConfig)
	local payload = {
		outcome = outcome,
		recipeId = recipeId,
		targetUid = targetUid,
		currentRarity = currentRarity,
		targetRarity = targetRarity,
	}

	if outcome == "success" then
		targetEntry.rarity = targetRarity
		targetEntry.statMultiplier = RarityConfig.RollMultiplier(targetRarity)
		payload.newRarity = targetRarity
		payload.statMultiplier = targetEntry.statMultiplier
	elseif outcome == "destroy" then
		if equippedSlot then
			data.equipped[equippedSlot] = nil
		elseif targetIndex then
			self._playerData:RemoveItemByUid(player, targetUid)
		end
	end
	if outcome == "success" then
		local Framework = require(ReplicatedStorage.Shared.Framework)
		local questService = Framework:GetService("QuestService")
		if questService then questService:OnEquipmentUpgraded(player) end
	end

	self._playerData:RecalculateStats(player)
	self._remotes.InventoryUpdated:FireClient(player, data.inventory)
	self._playerData:FireStatsUpdated(player)

	if outcome == "destroy" and equippedSlot then
		local Framework = require(ReplicatedStorage.Shared.Framework)
		local equipmentService = Framework:GetService("EquipmentService")
		if equipmentService then
			equipmentService:ApplyEquipmentChange(player)
		end
	end

	self._remotes.CraftResult:FireClient(player, payload)
	local outcomeMsg = {
		success = "Upgrade success!",
		fail = "Upgrade failed.",
		destroy = "Item destroyed!",
	}
	if outcomeMsg[payload.outcome] then
		self._remotes.Notification:FireClient(player, outcomeMsg[payload.outcome])
	end
	return true, payload
end

function CraftingService:BuildRecipePayload()
	local list = {}
	for id, recipe in CraftingRecipes do
		table.insert(list, {
			id = id,
			type = recipe.type or "consumable",
			slot = recipe.slot,
			classRestriction = recipe.classRestriction,
			requiredLevel = recipe.requiredLevel,
			resultItem = recipe.resultItem,
			materials = recipe.materials,
		})
	end
	return list
end

function CraftingService:_CreateLegacyNPC(cframe)
	local model = Instance.new("Model")
	model.Name = "Crafting Master"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2.4, 2.6, 1.4)
	if typeof(cframe) == "CFrame" then
		root.CFrame = cframe
	else
		root.Position = cframe
	end
	root.Anchored = true
	root.CanCollide = true
	root.Color = Color3.fromRGB(100, 80, 140)
	root.Material = Enum.Material.Fabric
	root.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 2, 2)
	head.Color = Color3.fromRGB(200, 160, 120)
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = root.CFrame * CFrame.new(0, 2.1, 0)
	head.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 140, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "Crafting Master"
	label.TextColor3 = Color3.fromRGB(180, 140, 255)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Craft"
	prompt.ObjectText = "Crafting Master"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.Parent = root

	model.PrimaryPart = root
	local npcsFolder = workspace:FindFirstChild("NPCs")
	if not npcsFolder then
		npcsFolder = Instance.new("Folder")
		npcsFolder.Name = "NPCs"
		npcsFolder.Parent = workspace
	end
	model.Parent = npcsFolder

	local recipes = self:BuildRecipePayload()
	prompt.Triggered:Connect(function(player)
		self._remotes.OpenCrafting:FireClient(player, recipes)
	end)

	return model
end

-- R15 replacement for the previous torso-and-head-only crafting NPC.
function CraftingService:CreateNPC(cframe)
	local model, root, head = R15NPCUtil.Build(cframe, Color3.fromRGB(200, 160, 120), Color3.fromRGB(100, 80, 140), Color3.fromRGB(65, 50, 90))
	model.Name = "Crafting Master"

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 140, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "Crafting Master"
	label.TextColor3 = Color3.fromRGB(180, 140, 255)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = billboard

	local npcsFolder = workspace:FindFirstChild("NPCs") or Instance.new("Folder")
	npcsFolder.Name = "NPCs"
	npcsFolder.Parent = workspace
	model.Parent = npcsFolder

	local recipes = self:BuildRecipePayload()
	R15NPCUtil.AddInteraction(head, "Craft", "Crafting Master", function(player)
		self._remotes.OpenCrafting:FireClient(player, recipes)
	end)
	return model
end

function CraftingService:Start()
	local cframe = self._mapGenerator and self._mapGenerator:GetMarketplaceNpcCFrame("Crafting")
	if cframe then
		self:CreateNPC(cframe)
	end

	self._remotes.CraftItem.OnServerInvoke = function(player, recipeId)
		return self:CraftItem(player, recipeId)
	end

	self._remotes.UpgradeEquipment.OnServerInvoke = function(player, recipeId, targetUid)
		return self:UpgradeEquipment(player, recipeId, targetUid)
	end

	self._remotes.RequestCrafting.OnServerEvent:Connect(function(player, context)
		local recipes = self:BuildRecipePayload()
		self._remotes.OpenCrafting:FireClient(player, recipes, context)
	end)
end

return CraftingService
