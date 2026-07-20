local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Shop = require(Shared.Config.Shop)
local Items = require(Shared.Config.Items)
local R15NPCUtil = require(Shared.Util.R15NPCUtil)

local ShopService = {}
ShopService._playerData = nil
ShopService._combatService = nil
ShopService._remotes = nil

function ShopService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._combatService = Framework:GetService("CombatService")
	self._remotes = Framework:GetRemotesFolder()
	self._mapGenerator = Framework:GetService("MapGeneratorService")

	Framework:GetRemote("SellItem")
end

function ShopService:BuildShopPayload(shopType)
	local shopItems = {}
	for _, entry in Shop.GetItems(shopType) do
		local item = Items[entry.itemId]
		if item then
			table.insert(shopItems, {
				itemId = entry.itemId,
				name = item.name,
				description = item.description,
				price = entry.price,
				sellPrice = Shop.GetSellPrice(entry.price),
				category = entry.category or item.category or "materials",
				requiredLevel = entry.requiredLevel,
			})
		end
	end
	return shopItems
end

function ShopService:_CreateLegacyNPC(cframe, shopType)
	local model = Instance.new("Model")
	local isEnhancementShop = shopType == "enhancement"
	local merchantName = isEnhancementShop and "Enhancement Scribe" or "Equipment Merchant"
	model.Name = merchantName

	local skinColor = Color3.fromRGB(200, 160, 120)
	local shirtColor = Color3.fromRGB(180, 140, 60)
	local apronColor = Color3.fromRGB(220, 200, 170)
	local pantsColor = Color3.fromRGB(100, 80, 50)
	local mat = Enum.Material.SmoothPlastic

	-- Torso / Shirt
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
	root.Color = shirtColor
	root.Material = Enum.Material.Fabric
	root.Parent = model

	-- Apron (front)
	local apron = Instance.new("Part")
	apron.Name = "Apron"
	apron.Size = Vector3.new(1.8, 3.2, 0.2)
	apron.Color = apronColor
	apron.Material = Enum.Material.Fabric
	apron.Anchored = true
	apron.CanCollide = false
	apron.CFrame = root.CFrame * CFrame.new(0, -0.8, -0.7)
	apron.Parent = model

	-- Apron strap
	local strap = Instance.new("Part")
	strap.Name = "ApronStrap"
	strap.Size = Vector3.new(0.3, 1.5, 0.15)
	strap.Color = apronColor
	strap.Material = Enum.Material.Fabric
	strap.Anchored = true
	strap.CanCollide = false
	strap.CFrame = root.CFrame * CFrame.new(0, 0.8, -0.65)
	strap.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 2, 2)
	head.Color = skinColor
	head.Material = mat
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = root.CFrame * CFrame.new(0, 2.1, 0)
	head.Parent = model

	-- Left Eye
	local leftEye = Instance.new("Part")
	leftEye.Name = "LeftEye"
	leftEye.Shape = Enum.PartType.Ball
	leftEye.Size = Vector3.new(0.3, 0.3, 0.15)
	leftEye.Color = Color3.fromRGB(60, 40, 20)
	leftEye.Material = mat
	leftEye.Anchored = true
	leftEye.CanCollide = false
	leftEye.CFrame = head.CFrame * CFrame.new(-0.35, 0.1, -0.85)
	leftEye.Parent = model

	-- Right Eye
	local rightEye = Instance.new("Part")
	rightEye.Name = "RightEye"
	rightEye.Shape = Enum.PartType.Ball
	rightEye.Size = Vector3.new(0.3, 0.3, 0.15)
	rightEye.Color = Color3.fromRGB(60, 40, 20)
	rightEye.Material = mat
	rightEye.Anchored = true
	rightEye.CanCollide = false
	rightEye.CFrame = head.CFrame * CFrame.new(0.35, 0.1, -0.85)
	rightEye.Parent = model

	-- Friendly smile
	local smile = Instance.new("Part")
	smile.Name = "Smile"
	smile.Size = Vector3.new(0.7, 0.15, 0.1)
	smile.Color = Color3.fromRGB(180, 100, 80)
	smile.Material = mat
	smile.Anchored = true
	smile.CanCollide = false
	smile.CFrame = head.CFrame * CFrame.new(0, -0.35, -0.9)
	smile.Parent = model

	-- Mustache
	local mustache = Instance.new("Part")
	mustache.Name = "Mustache"
	mustache.Size = Vector3.new(1.0, 0.25, 0.2)
	mustache.Color = Color3.fromRGB(80, 55, 30)
	mustache.Material = Enum.Material.Fabric
	mustache.Anchored = true
	mustache.CanCollide = false
	mustache.CFrame = head.CFrame * CFrame.new(0, -0.15, -0.85)
	mustache.Parent = model

	-- Merchant Hat (beret style)
	local hatBase = Instance.new("Part")
	hatBase.Name = "HatBase"
	hatBase.Shape = Enum.PartType.Cylinder
	hatBase.Size = Vector3.new(0.3, 2.6, 2.6)
	hatBase.Color = Color3.fromRGB(140, 50, 40)
	hatBase.Material = Enum.Material.Fabric
	hatBase.Anchored = true
	hatBase.CanCollide = false
	hatBase.CFrame = head.CFrame * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90))
	hatBase.Parent = model

	local hatTop = Instance.new("Part")
	hatTop.Name = "HatTop"
	hatTop.Shape = Enum.PartType.Ball
	hatTop.Size = Vector3.new(2.2, 1.2, 2.2)
	hatTop.Color = Color3.fromRGB(140, 50, 40)
	hatTop.Material = Enum.Material.Fabric
	hatTop.Anchored = true
	hatTop.CanCollide = false
	hatTop.CFrame = head.CFrame * CFrame.new(0, 1.2, 0)
	hatTop.Parent = model

	-- Hat feather
	local feather = Instance.new("Part")
	feather.Name = "Feather"
	feather.Size = Vector3.new(0.15, 1.5, 0.6)
	feather.Color = Color3.fromRGB(255, 220, 80)
	feather.Material = Enum.Material.Fabric
	feather.Anchored = true
	feather.CanCollide = false
	feather.CFrame = hatTop.CFrame * CFrame.new(0.8, 0.5, 0) * CFrame.Angles(0, 0, math.rad(15))
	feather.Parent = model

	-- Left Arm
	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftArm"
	leftArm.Size = Vector3.new(0.9, 2.0, 0.9)
	leftArm.Color = shirtColor
	leftArm.Material = Enum.Material.Fabric
	leftArm.Anchored = true
	leftArm.CanCollide = false
	leftArm.CFrame = root.CFrame * CFrame.new(-1.65, -0.2, 0)
	leftArm.Parent = model

	-- Left Hand
	local leftHand = Instance.new("Part")
	leftHand.Name = "LeftHand"
	leftHand.Shape = Enum.PartType.Ball
	leftHand.Size = Vector3.new(0.7, 0.7, 0.7)
	leftHand.Color = skinColor
	leftHand.Material = mat
	leftHand.Anchored = true
	leftHand.CanCollide = false
	leftHand.CFrame = leftArm.CFrame * CFrame.new(0, -1.2, 0)
	leftHand.Parent = model

	-- Right Arm
	local rightArm = Instance.new("Part")
	rightArm.Name = "RightArm"
	rightArm.Size = Vector3.new(0.9, 2.0, 0.9)
	rightArm.Color = shirtColor
	rightArm.Material = Enum.Material.Fabric
	rightArm.Anchored = true
	rightArm.CanCollide = false
	rightArm.CFrame = root.CFrame * CFrame.new(1.65, -0.2, 0)
	rightArm.Parent = model

	-- Right Hand
	local rightHand = Instance.new("Part")
	rightHand.Name = "RightHand"
	rightHand.Shape = Enum.PartType.Ball
	rightHand.Size = Vector3.new(0.7, 0.7, 0.7)
	rightHand.Color = skinColor
	rightHand.Material = mat
	rightHand.Anchored = true
	rightHand.CanCollide = false
	rightHand.CFrame = rightArm.CFrame * CFrame.new(0, -1.2, 0)
	rightHand.Parent = model

	-- Coin bag in left hand
	local coinBag = Instance.new("Part")
	coinBag.Name = "CoinBag"
	coinBag.Shape = Enum.PartType.Ball
	coinBag.Size = Vector3.new(1.2, 1.0, 1.0)
	coinBag.Color = Color3.fromRGB(160, 120, 60)
	coinBag.Material = Enum.Material.Leather
	coinBag.Anchored = true
	coinBag.CanCollide = false
	coinBag.CFrame = leftHand.CFrame * CFrame.new(0, -0.6, 0)
	coinBag.Parent = model

	-- Coin peeking out of bag
	local coin = Instance.new("Part")
	coin.Name = "Coin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = Vector3.new(0.1, 0.6, 0.6)
	coin.Color = Color3.fromRGB(255, 210, 50)
	coin.Material = Enum.Material.Neon
	coin.Anchored = true
	coin.CanCollide = false
	coin.CFrame = coinBag.CFrame * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	coin.Parent = model

	-- Left Leg
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "LeftLeg"
	leftLeg.Size = Vector3.new(1.0, 2.0, 1.0)
	leftLeg.Color = pantsColor
	leftLeg.Material = Enum.Material.Fabric
	leftLeg.Anchored = true
	leftLeg.CanCollide = false
	leftLeg.CFrame = root.CFrame * CFrame.new(-0.6, -2.3, 0)
	leftLeg.Parent = model

	-- Right Leg
	local rightLeg = Instance.new("Part")
	rightLeg.Name = "RightLeg"
	rightLeg.Size = Vector3.new(1.0, 2.0, 1.0)
	rightLeg.Color = pantsColor
	rightLeg.Material = Enum.Material.Fabric
	rightLeg.Anchored = true
	rightLeg.CanCollide = false
	rightLeg.CFrame = root.CFrame * CFrame.new(0.6, -2.3, 0)
	rightLeg.Parent = model

	-- Boots
	for _, legPart in {leftLeg, rightLeg} do
		local boot = Instance.new("Part")
		boot.Name = "Boot"
		boot.Size = Vector3.new(1.1, 0.6, 1.4)
		boot.Color = Color3.fromRGB(60, 40, 25)
		boot.Material = Enum.Material.Leather
		boot.Anchored = true
		boot.CanCollide = false
		boot.CFrame = legPart.CFrame * CFrame.new(0, -1.1, 0.1)
		boot.Parent = model
	end

	-- Coin icon above head
	local coinMarker = Instance.new("BillboardGui")
	coinMarker.Name = "CoinMarker"
	coinMarker.Size = UDim2.new(0, 36, 0, 36)
	coinMarker.StudsOffset = Vector3.new(0, 6, 0)
	coinMarker.AlwaysOnTop = true
	coinMarker.Parent = root

	local coinIcon = Instance.new("TextLabel")
	coinIcon.Size = UDim2.new(1, 0, 1, 0)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "💰"
	coinIcon.TextSize = 28
	coinIcon.Font = Enum.Font.GothamBold
	coinIcon.Parent = coinMarker

	-- Name billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 140, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 45
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = merchantName
	label.TextColor3 = Color3.fromRGB(255, 210, 80)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Shop"
	prompt.ObjectText = merchantName
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

	local shopItems = self:BuildShopPayload(shopType)

	prompt.Triggered:Connect(function(player)
		self._remotes.OpenShop:FireClient(player, shopItems, shopType)
	end)

	return model
end

-- R15 replacement for the original decorative merchant.  Keeping the prompt on
-- HumanoidRootPart makes its interaction range independent of accessories.
function ShopService:CreateNPC(cframe, shopType)
	local isEnhancementShop = shopType == "enhancement"
	local merchantName = isEnhancementShop and "Enhancement Scribe" or "Equipment Merchant"
	local skinColor = Color3.fromRGB(200, 160, 120)
	local shirtColor = isEnhancementShop and Color3.fromRGB(100, 80, 140) or Color3.fromRGB(180, 140, 60)
	local pantsColor = Color3.fromRGB(100, 80, 50)
	local model, root, head = R15NPCUtil.Build(cframe, skinColor, shirtColor, pantsColor)
	model.Name = merchantName

	local coinMarker = Instance.new("BillboardGui")
	coinMarker.Name = "CoinMarker"
	coinMarker.Size = UDim2.new(0, 36, 0, 36)
	coinMarker.StudsOffset = Vector3.new(0, 6, 0)
	coinMarker.AlwaysOnTop = true
	coinMarker.Parent = root
	local coinIcon = Instance.new("TextLabel")
	coinIcon.Size = UDim2.new(1, 0, 1, 0)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "💰"
	coinIcon.TextSize = 28
	coinIcon.Font = Enum.Font.GothamBold
	coinIcon.Parent = coinMarker

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 170, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 45
	billboard.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = merchantName
	label.TextColor3 = Color3.fromRGB(255, 210, 80)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = billboard

	local npcsFolder = workspace:FindFirstChild("NPCs") or Instance.new("Folder")
	npcsFolder.Name = "NPCs"
	npcsFolder.Parent = workspace
	model.Parent = npcsFolder

	local shopItems = self:BuildShopPayload(shopType)
	R15NPCUtil.AddInteraction(head, "Shop", merchantName, function(player)
		self._remotes.OpenShop:FireClient(player, shopItems, shopType)
	end)
	return model
end

function ShopService:Purchase(player, itemId, quantity)
	quantity = math.clamp(math.floor(quantity or 1), 1, 99)

	local shopEntry = Shop.FindEntry(itemId)
	if not shopEntry then
		return false, "Item not found"
	end

	local item = Items[itemId]
	if not item then
		return false, "Invalid item"
	end

	local data = self._playerData:GetData(player)
	if not data then
		return false, "No player data"
	end

	if shopEntry.requiredLevel and data.level < shopEntry.requiredLevel then
		return false, "Requires Level " .. shopEntry.requiredLevel
	end

	local totalCost = shopEntry.price * quantity
	if not self._playerData:TakeCoins(player, totalCost) then
		return false, "Not enough coins"
	end

	if item.type == "weapon" then
		if quantity > 1 then
			self._playerData:AddCoins(player, totalCost)
			return false, "Can only buy one weapon at a time"
		end
		self._playerData:SetEquippedWeapon(player, itemId)
		self._combatService:GiveWeapon(player, itemId)
		self._remotes.Notification:FireClient(player, "Purchased " .. item.name)
	elseif item.type == "scroll" or item.type == "consumable" or item.type == "material" then
		local addData = itemId
		if item.type == "material" and item.supportsRarity then
			addData = { id = itemId, rarity = "Common" }
		end
		if not self._playerData:AddItem(player, addData, quantity) then
			self._playerData:AddCoins(player, totalCost)
			return false, "Inventory full"
		end
		self._remotes.Notification:FireClient(player, "Purchased " .. quantity .. "x " .. item.name)
	else
		self._playerData:AddCoins(player, totalCost)
		return false, "Cannot purchase this item"
	end

	return true
end

function ShopService:Sell(player, itemId, count)
	count = count or 1
	if count < 1 then
		return false, "Invalid amount"
	end

	local shopEntry = Shop.FindEntry(itemId)
	if not shopEntry then
		return false, "Shop won't buy that item"
	end

	local item = Items[itemId]
	if not item then
		return false, "Invalid item"
	end

	if not self._playerData:HasItem(player, itemId, count) then
		return false, "You don't have enough of that item"
	end

	if not self._playerData:RemoveItem(player, itemId, count) then
		return false, "Could not remove item"
	end

	local sellPrice = Shop.GetSellPrice(shopEntry.price) * count
	self._playerData:AddCoins(player, sellPrice)
	self._remotes.Notification:FireClient(player, "Sold " .. count .. "x " .. item.name .. " for " .. sellPrice .. " gold")
	return true
end

function ShopService:Start()
	local equipmentCFrame = self._mapGenerator:GetMarketplaceNpcCFrame("EquipmentShop")
	local enhancementCFrame = self._mapGenerator:GetMarketplaceNpcCFrame("EnhancementShop")
	if equipmentCFrame then self:CreateNPC(equipmentCFrame, "equipment") end
	if enhancementCFrame then self:CreateNPC(enhancementCFrame, "enhancement") end

	self._remotes.PurchaseItem.OnServerEvent:Connect(function(player, itemId, quantity)
		local success, message = self:Purchase(player, itemId, quantity)
		if not success and message then
			self._remotes.Notification:FireClient(player, message)
		end
	end)

	self._remotes.SellItem.OnServerEvent:Connect(function(player, itemId, count)
		local success, message = self:Sell(player, itemId, count)
		if not success and message then
			self._remotes.Notification:FireClient(player, message)
		end
	end)
end

return ShopService
