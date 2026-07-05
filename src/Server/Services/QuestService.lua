local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)

local QuestService = {}
QuestService._playerData = nil
QuestService._remotes = nil

function QuestService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._remotes = Framework:GetRemotesFolder()
	self._mapGenerator = Framework:GetService("MapGeneratorService")
	Framework:GetRemote("OpenQuestLog")
end

function QuestService:CreateNPC(cframe)
	local config = Quests.KillGoblins
	local model = Instance.new("Model")
	model.Name = config.npcName

	local skinColor = Color3.fromRGB(220, 180, 140)
	local robeColor = Color3.fromRGB(50, 60, 140)
	local robeDark = Color3.fromRGB(35, 40, 100)
	local mat = Enum.Material.SmoothPlastic

	-- Torso / Robe Body
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2.2, 2.8, 1.4)
	if typeof(cframe) == "CFrame" then
		root.CFrame = cframe
	else
		root.Position = cframe
	end
	root.Anchored = true
	root.CanCollide = true
	root.Color = robeColor
	root.Material = Enum.Material.Fabric
	root.Parent = model

	-- Robe skirt (lower half)
	local skirt = Instance.new("Part")
	skirt.Name = "RobeSkirt"
	skirt.Size = Vector3.new(2.6, 2.0, 1.6)
	skirt.Color = robeDark
	skirt.Material = Enum.Material.Fabric
	skirt.Anchored = true
	skirt.CanCollide = false
	skirt.CFrame = root.CFrame * CFrame.new(0, -2.4, 0)
	skirt.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 2, 2)
	head.Color = skinColor
	head.Material = mat
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = root.CFrame * CFrame.new(0, 2.2, 0)
	head.Parent = model

	-- Left Eye
	local leftEye = Instance.new("Part")
	leftEye.Name = "LeftEye"
	leftEye.Shape = Enum.PartType.Ball
	leftEye.Size = Vector3.new(0.3, 0.35, 0.15)
	leftEye.Color = Color3.fromRGB(60, 100, 200)
	leftEye.Material = Enum.Material.Neon
	leftEye.Anchored = true
	leftEye.CanCollide = false
	leftEye.CFrame = head.CFrame * CFrame.new(-0.35, 0.1, -0.85)
	leftEye.Parent = model

	-- Right Eye
	local rightEye = Instance.new("Part")
	rightEye.Name = "RightEye"
	rightEye.Shape = Enum.PartType.Ball
	rightEye.Size = Vector3.new(0.3, 0.35, 0.15)
	rightEye.Color = Color3.fromRGB(60, 100, 200)
	rightEye.Material = Enum.Material.Neon
	rightEye.Anchored = true
	rightEye.CanCollide = false
	rightEye.CFrame = head.CFrame * CFrame.new(0.35, 0.1, -0.85)
	rightEye.Parent = model

	-- Smile
	local smile = Instance.new("Part")
	smile.Name = "Smile"
	smile.Size = Vector3.new(0.6, 0.12, 0.1)
	smile.Color = Color3.fromRGB(160, 100, 80)
	smile.Material = mat
	smile.Anchored = true
	smile.CanCollide = false
	smile.CFrame = head.CFrame * CFrame.new(0, -0.35, -0.9)
	smile.Parent = model

	-- Beard
	local beard = Instance.new("Part")
	beard.Name = "Beard"
	beard.Size = Vector3.new(1.2, 1.8, 0.6)
	beard.Color = Color3.fromRGB(200, 200, 210)
	beard.Material = Enum.Material.Fabric
	beard.Anchored = true
	beard.CanCollide = false
	beard.CFrame = head.CFrame * CFrame.new(0, -1.3, -0.3)
	beard.Parent = model

	-- Wizard Hat (cone shape using 2 parts)
	local hatBrim = Instance.new("Part")
	hatBrim.Name = "HatBrim"
	hatBrim.Shape = Enum.PartType.Cylinder
	hatBrim.Size = Vector3.new(0.4, 3.2, 3.2)
	hatBrim.Color = Color3.fromRGB(40, 30, 100)
	hatBrim.Material = Enum.Material.Fabric
	hatBrim.Anchored = true
	hatBrim.CanCollide = false
	hatBrim.CFrame = head.CFrame * CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.rad(90))
	hatBrim.Parent = model

	local hatTop = Instance.new("Part")
	hatTop.Name = "HatTop"
	hatTop.Size = Vector3.new(1.6, 2.5, 1.6)
	hatTop.Color = Color3.fromRGB(40, 30, 100)
	hatTop.Material = Enum.Material.Fabric
	hatTop.Anchored = true
	hatTop.CanCollide = false
	hatTop.CFrame = head.CFrame * CFrame.new(0, 2.2, 0)
	hatTop.Parent = model

	-- Hat star decoration
	local star = Instance.new("Part")
	star.Name = "HatStar"
	star.Shape = Enum.PartType.Ball
	star.Size = Vector3.new(0.5, 0.5, 0.5)
	star.Color = Color3.fromRGB(255, 220, 80)
	star.Material = Enum.Material.Neon
	star.Anchored = true
	star.CanCollide = false
	star.CFrame = hatTop.CFrame * CFrame.new(0, 1.3, 0)
	star.Parent = model

	-- Left Arm
	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftArm"
	leftArm.Size = Vector3.new(0.9, 2.0, 0.9)
	leftArm.Color = robeColor
	leftArm.Material = Enum.Material.Fabric
	leftArm.Anchored = true
	leftArm.CanCollide = false
	leftArm.CFrame = root.CFrame * CFrame.new(-1.55, -0.3, 0)
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
	rightArm.Color = robeColor
	rightArm.Material = Enum.Material.Fabric
	rightArm.Anchored = true
	rightArm.CanCollide = false
	rightArm.CFrame = root.CFrame * CFrame.new(1.55, -0.3, 0)
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

	-- Staff in right hand
	local staff = Instance.new("Part")
	staff.Name = "Staff"
	staff.Size = Vector3.new(0.35, 5, 0.35)
	staff.Color = Color3.fromRGB(110, 80, 50)
	staff.Material = Enum.Material.Wood
	staff.Anchored = true
	staff.CanCollide = false
	staff.CFrame = rightHand.CFrame * CFrame.new(0, 1.5, 0)
	staff.Parent = model

	-- Staff crystal
	local crystal = Instance.new("Part")
	crystal.Name = "StaffCrystal"
	crystal.Shape = Enum.PartType.Ball
	crystal.Size = Vector3.new(0.8, 0.8, 0.8)
	crystal.Color = Color3.fromRGB(100, 180, 255)
	crystal.Material = Enum.Material.Neon
	crystal.Anchored = true
	crystal.CanCollide = false
	crystal.CFrame = staff.CFrame * CFrame.new(0, 2.8, 0)
	crystal.Parent = model

	-- Glowing quest exclamation mark (!)
	local questMarker = Instance.new("BillboardGui")
	questMarker.Name = "QuestMarker"
	questMarker.Size = UDim2.new(0, 40, 0, 50)
	questMarker.StudsOffset = Vector3.new(0, 6, 0)
	questMarker.AlwaysOnTop = true
	questMarker.Parent = root

	local markerLabel = Instance.new("TextLabel")
	markerLabel.Size = UDim2.new(1, 0, 1, 0)
	markerLabel.BackgroundTransparency = 1
	markerLabel.Text = "!"
	markerLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
	markerLabel.TextStrokeColor3 = Color3.fromRGB(180, 120, 0)
	markerLabel.TextStrokeTransparency = 0
	markerLabel.Font = Enum.Font.GothamBold
	markerLabel.TextSize = 36
	markerLabel.Parent = questMarker

	-- Name billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 140, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = config.npcName
	label.TextColor3 = Color3.fromRGB(255, 220, 100)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk"
	prompt.ObjectText = config.npcName
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

	prompt.Triggered:Connect(function(player)
		local data = self._playerData:GetData(player)
		if not data then
			return
		end

		self._remotes.OpenQuest:FireClient(player, {
			id = config.id,
			name = config.name,
			description = config.description,
			accepted = data.quest.accepted,
			completed = data.quest.completed,
			progress = data.quest.progress,
			required = Quests.GetRequired(config),
		})
	end)

	return model
end

function QuestService:GetQuestConfig(data)
	if not data or not data.quest.id then
		return nil
	end
	return Quests[data.quest.id]
end

function QuestService:CompleteQuest(player, config)
	local data = self._playerData:GetData(player)
	if not data then
		return
	end

	data.quest.completed = true
	self._playerData:AddXP(player, config.xpReward or 0)
	self._playerData:AddCoins(player, config.coinReward or 0)

	if config.itemRewards then
		for _, reward in config.itemRewards do
			self._playerData:AddItem(player, reward.itemId, reward.count or 1)
		end
	end

	self._remotes.Notification:FireClient(player, "Quest complete: " .. config.name)
	self:FireQuestUpdated(player)
	self._playerData:FireStatsUpdated(player)
end

function QuestService:AdvanceQuestProgress(player, amount)
	local data = self._playerData:GetData(player)
	if not data or not data.quest.accepted or data.quest.completed then
		return
	end

	local config = self:GetQuestConfig(data)
	if not config then
		return
	end

	data.quest.progress += amount or 1
	self:FireQuestUpdated(player)

	if data.quest.progress >= Quests.GetRequired(config) then
		self:CompleteQuest(player, config)
	end
end

function QuestService:AcceptQuest(player, questId)
	local config = Quests[questId]
	local data = self._playerData:GetData(player)
	if not config or not data then
		return false
	end

	if data.quest.id == questId and data.quest.completed then
		return false
	end

	data.quest.id = questId
	data.quest.accepted = true
	data.quest.completed = false
	data.quest.progress = 0
	self._playerData:FireStatsUpdated(player)
	self:FireQuestUpdated(player)
	return true
end

function QuestService:OnEnemyKilled(player, enemyType)
	local data = self._playerData:GetData(player)
	if not data or not data.quest.accepted or data.quest.completed then
		return
	end

	local config = self:GetQuestConfig(data)
	if not config or config.objectiveType ~= "kill" or config.targetEnemy ~= enemyType then
		return
	end

	self:AdvanceQuestProgress(player, 1)
end

function QuestService:OnItemCollected(player, itemId, count)
	local data = self._playerData:GetData(player)
	if not data or not data.quest.accepted or data.quest.completed then
		return
	end

	local config = self:GetQuestConfig(data)
	if not config or config.objectiveType ~= "collect" or config.targetItem ~= itemId then
		return
	end

	self:AdvanceQuestProgress(player, count or 1)
end

function QuestService:OnTalkToNPC(player, npcName)
	local data = self._playerData:GetData(player)
	if not data or not data.quest.accepted or data.quest.completed then
		return
	end

	local config = self:GetQuestConfig(data)
	if not config or config.objectiveType ~= "talk" or config.targetNpc ~= npcName then
		return
	end

	self:AdvanceQuestProgress(player, 1)
end

function QuestService:OnReachZone(player, zoneId)
	local data = self._playerData:GetData(player)
	if not data or not data.quest.accepted or data.quest.completed then
		return
	end

	local config = self:GetQuestConfig(data)
	if not config or config.objectiveType ~= "reach" or config.targetZone ~= zoneId then
		return
	end

	self:AdvanceQuestProgress(player, 1)
end

function QuestService:FireQuestUpdated(player)
	local data = self._playerData:GetData(player)
	if not data or not data.quest.id then
		return
	end

	local config = Quests[data.quest.id]
	if not config then
		return
	end

	self._remotes.QuestUpdated:FireClient(player, {
		id = data.quest.id,
		name = config.name,
		description = config.description,
		objectiveType = config.objectiveType,
		accepted = data.quest.accepted,
		completed = data.quest.completed,
		progress = data.quest.progress,
		required = Quests.GetRequired(config),
	})
end

function QuestService:CreateSimpleNPC(name, cframe, promptText)
	local model = Instance.new("Model")
	model.Name = name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 3, 1.5)
	root.CFrame = typeof(cframe) == "CFrame" and cframe or CFrame.new(cframe)
	root.Anchored = true
	root.CanCollide = true
	root.Color = Color3.fromRGB(100, 120, 180)
	root.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 140, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(255, 220, 100)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = promptText or "Talk"
	prompt.ObjectText = name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.Parent = root

	model.PrimaryPart = root
	local npcsFolder = workspace:FindFirstChild("NPCs") or Instance.new("Folder")
	npcsFolder.Name = "NPCs"
	npcsFolder.Parent = workspace
	model.Parent = npcsFolder
	return model, prompt
end

function QuestService:CreateReachZone(zoneId, position, size)
	local zone = Instance.new("Part")
	zone.Name = zoneId
	zone.Size = size or Vector3.new(20, 8, 20)
	zone.Position = position
	zone.Anchored = true
	zone.CanCollide = false
	zone.Transparency = 0.85
	zone.Color = Color3.fromRGB(100, 200, 255)
	zone:SetAttribute("ZoneId", zoneId)

	local folder = workspace:FindFirstChild("QuestZones") or Instance.new("Folder")
	folder.Name = "QuestZones"
	folder.Parent = workspace
	zone.Parent = folder

	zone.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and game:GetService("Players"):GetPlayerFromCharacter(character)
		if player then
			self:OnReachZone(player, zoneId)
		end
	end)

	return zone
end

function QuestService:Start()
	local pos = Vector3.new(50, 0, 237)
	local y = self._mapGenerator:GetGroundHeight(pos.X, pos.Z)
	self:CreateNPC(CFrame.new(pos.X, y + 2, pos.Z) * CFrame.Angles(0, math.pi, 0))

	local herbPos = Vector3.new(80, 0, 200)
	local herbY = self._mapGenerator:GetGroundHeight(herbPos.X, herbPos.Z)
	local _, herbPrompt = self:CreateSimpleNPC("Herb Master", CFrame.new(herbPos.X, herbY + 2, herbPos.Z), "Quest")
	herbPrompt.Triggered:Connect(function(player)
		local data = self._playerData:GetData(player)
		if not data then return end
		self._remotes.OpenQuest:FireClient(player, {
			id = Quests.CollectHerbs.id,
			name = Quests.CollectHerbs.name,
			description = Quests.CollectHerbs.description,
			accepted = data.quest.accepted and data.quest.id == Quests.CollectHerbs.id,
			completed = data.quest.completed and data.quest.id == Quests.CollectHerbs.id,
			progress = data.quest.progress,
			required = Quests.GetRequired(Quests.CollectHerbs),
		})
	end)

	local elderPos = Vector3.new(-40, 0, 220)
	local elderY = self._mapGenerator:GetGroundHeight(elderPos.X, elderPos.Z)
	local _, elderPrompt = self:CreateSimpleNPC("Village Elder", CFrame.new(elderPos.X, elderY + 2, elderPos.Z), "Talk")
	elderPrompt.Triggered:Connect(function(player)
		self:OnTalkToNPC(player, "Village Elder")
		local data = self._playerData:GetData(player)
		if data and not data.quest.accepted then
			self._remotes.OpenQuest:FireClient(player, {
				id = Quests.TalkToElder.id,
				name = Quests.TalkToElder.name,
				description = Quests.TalkToElder.description,
				accepted = false,
				completed = data.quest.completed and data.quest.id == Quests.TalkToElder.id,
				progress = data.quest.progress,
				required = Quests.GetRequired(Quests.TalkToElder),
			})
		end
	end)

	local monumentPos = Vector3.new(0, 0, 300)
	local monumentY = self._mapGenerator:GetGroundHeight(monumentPos.X, monumentPos.Z)
	self:CreateReachZone("QuestMonumentZone", Vector3.new(monumentPos.X, monumentY + 4, monumentPos.Z), Vector3.new(24, 10, 24))

	local _, scoutPrompt = self:CreateSimpleNPC(
		"Scout",
		CFrame.new(monumentPos.X - 8, monumentY + 2, monumentPos.Z),
		"Quest"
	)
	scoutPrompt.Triggered:Connect(function(player)
		local data = self._playerData:GetData(player)
		if not data then
			return
		end
		self._remotes.OpenQuest:FireClient(player, {
			id = Quests.ReachMonument.id,
			name = Quests.ReachMonument.name,
			description = Quests.ReachMonument.description,
			accepted = data.quest.accepted and data.quest.id == Quests.ReachMonument.id,
			completed = data.quest.completed and data.quest.id == Quests.ReachMonument.id,
			progress = data.quest.progress,
			required = Quests.GetRequired(Quests.ReachMonument),
		})
	end)

	self._remotes.AcceptQuest.OnServerEvent:Connect(function(player, questId)
		if self:AcceptQuest(player, questId) then
			self._remotes.Notification:FireClient(player, "Quest accepted!")
		end
	end)
end

return QuestService
