local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)

local QuestService = {}
QuestService._playerData = nil
QuestService._experienceService = nil
QuestService._remotes = nil

function QuestService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._experienceService = Framework:GetService("ExperienceService")
	self._karmaService = Framework:GetService("KarmaService")
	self._remotes = Framework:GetRemotesFolder()
	self._mapGenerator = Framework:GetService("MapGeneratorService")
	Framework:GetRemote("OpenQuestLog")
end

---------------------------------------------------------------------------
-- Shared R15 rig builder (same skeleton structure as monster rigs)
---------------------------------------------------------------------------
function QuestService:_BuildR15Rig(cframe, skinColor)
	local mat = Enum.Material.SmoothPlastic
	local model = Instance.new("Model")

	local function makePart(name, size, canCollide)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Anchored = true
		p.CanCollide = canCollide or false
		p.Color = skinColor
		p.Material = mat
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local function makeMotor(name, part0, part1, c0, c1)
		local motor = Instance.new("Motor6D")
		motor.Name = name
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = c0
		motor.C1 = c1 or CFrame.new()
		motor.Parent = part1
		return motor
	end

	---------------------------------------------------------------------------
	-- Standard R15 part sizes
	---------------------------------------------------------------------------
	local hrp          = makePart("HumanoidRootPart", Vector3.new(2, 2, 1), true)
	hrp.Transparency = 1

	local lowerTorso   = makePart("LowerTorso",      Vector3.new(2, 0.4, 1))
	local upperTorso   = makePart("UpperTorso",       Vector3.new(2, 1.6, 1))
	local head         = makePart("Head",             Vector3.new(2, 1, 1))

	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	headMesh.Parent = head

	local leftUpperArm  = makePart("LeftUpperArm",  Vector3.new(1, 1.2, 1))
	local leftLowerArm  = makePart("LeftLowerArm",  Vector3.new(1, 1.2, 1))
	local leftHand       = makePart("LeftHand",      Vector3.new(1, 0.3, 1))

	local rightUpperArm = makePart("RightUpperArm", Vector3.new(1, 1.2, 1))
	local rightLowerArm = makePart("RightLowerArm", Vector3.new(1, 1.2, 1))
	local rightHand      = makePart("RightHand",     Vector3.new(1, 0.3, 1))

	local leftUpperLeg  = makePart("LeftUpperLeg",  Vector3.new(1, 1.3, 1))
	local leftLowerLeg  = makePart("LeftLowerLeg",  Vector3.new(1, 1.3, 1))
	local leftFoot       = makePart("LeftFoot",      Vector3.new(1, 0.3, 1))

	local rightUpperLeg = makePart("RightUpperLeg", Vector3.new(1, 1.3, 1))
	local rightLowerLeg = makePart("RightLowerLeg", Vector3.new(1, 1.3, 1))
	local rightFoot      = makePart("RightFoot",     Vector3.new(1, 0.3, 1))

	---------------------------------------------------------------------------
	-- Motor6D joints (standard R15 hierarchy)
	---------------------------------------------------------------------------
	makeMotor("Root",          hrp,          lowerTorso,
		CFrame.new(),               CFrame.new())

	makeMotor("Waist",         lowerTorso,   upperTorso,
		CFrame.new(0, 0.2, 0),      CFrame.new(0, -0.8, 0))

	makeMotor("Neck",          upperTorso,   head,
		CFrame.new(0, 0.8, 0),      CFrame.new(0, -0.5, 0))

	-- Left Arm
	makeMotor("LeftShoulder",  upperTorso,   leftUpperArm,
		CFrame.new(-1, 0.5, 0),     CFrame.new(0.5, 0.6, 0))

	makeMotor("LeftElbow",     leftUpperArm, leftLowerArm,
		CFrame.new(0, -0.6, 0),     CFrame.new(0, 0.6, 0))

	makeMotor("LeftWrist",     leftLowerArm, leftHand,
		CFrame.new(0, -0.6, 0),     CFrame.new(0, 0.15, 0))

	-- Right Arm
	makeMotor("RightShoulder", upperTorso,   rightUpperArm,
		CFrame.new(1, 0.5, 0),      CFrame.new(-0.5, 0.6, 0))

	makeMotor("RightElbow",    rightUpperArm, rightLowerArm,
		CFrame.new(0, -0.6, 0),     CFrame.new(0, 0.6, 0))

	makeMotor("RightWrist",    rightLowerArm, rightHand,
		CFrame.new(0, -0.6, 0),     CFrame.new(0, 0.15, 0))

	-- Left Leg
	makeMotor("LeftHip",       lowerTorso,   leftUpperLeg,
		CFrame.new(-0.5, -0.2, 0),  CFrame.new(0, 0.65, 0))

	makeMotor("LeftKnee",      leftUpperLeg, leftLowerLeg,
		CFrame.new(0, -0.65, 0),    CFrame.new(0, 0.65, 0))

	makeMotor("LeftAnkle",     leftLowerLeg, leftFoot,
		CFrame.new(0, -0.65, 0),    CFrame.new(0, 0.15, 0))

	-- Right Leg
	makeMotor("RightHip",      lowerTorso,   rightUpperLeg,
		CFrame.new(0.5, -0.2, 0),   CFrame.new(0, 0.65, 0))

	makeMotor("RightKnee",     rightUpperLeg, rightLowerLeg,
		CFrame.new(0, -0.65, 0),    CFrame.new(0, 0.65, 0))

	makeMotor("RightAnkle",    rightLowerLeg, rightFoot,
		CFrame.new(0, -0.65, 0),    CFrame.new(0, 0.15, 0))

	---------------------------------------------------------------------------
	-- Humanoid (anchored NPC – WalkSpeed 0)
	---------------------------------------------------------------------------
	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = 0
	humanoid.HipHeight = 2
	humanoid.Parent = model

	model.PrimaryPart = hrp

	-- Position the rig
	local cf = typeof(cframe) == "CFrame" and cframe or CFrame.new(cframe)
	hrp.CFrame = cf

	return model, hrp, head, rightHand
end

function QuestService:CreateNPC(cframe)
	local config = Quests.GoblinMenace

	local robeColor = Color3.fromRGB(50, 60, 140)
	local skinColor = Color3.fromRGB(220, 180, 140)

	local model, hrp, head, rHand = self:_BuildR15Rig(cframe, skinColor)
	model.Name = config.npcName

	-- Recolour torso parts to robe colour
	local upperTorso = model:FindFirstChild("UpperTorso")
	local lowerTorso = model:FindFirstChild("LowerTorso")
	if upperTorso then upperTorso.Color = robeColor; upperTorso.Material = Enum.Material.Fabric end
	if lowerTorso then lowerTorso.Color = robeColor; lowerTorso.Material = Enum.Material.Fabric end

	-- Recolour arms to robe
	for _, partName in {"LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm"} do
		local part = model:FindFirstChild(partName)
		if part then part.Color = robeColor; part.Material = Enum.Material.Fabric end
	end

	-- Recolour legs to dark robe
	local robeDark = Color3.fromRGB(35, 40, 100)
	for _, partName in {"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"} do
		local part = model:FindFirstChild(partName)
		if part then part.Color = robeDark; part.Material = Enum.Material.Fabric end
	end

	---------------------------------------------------------------------------
	-- Wizard accessories (welded to head / right hand)
	---------------------------------------------------------------------------
	local function makeAccessory(name, size, color, material, parent, offset)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CFrame = parent.CFrame * offset
		p.Parent = model
		local w = Instance.new("WeldConstraint")
		w.Part0 = parent
		w.Part1 = p
		w.Parent = p
		return p
	end

	-- Beard
	makeAccessory("Beard", Vector3.new(1.2, 1.0, 0.6),
		Color3.fromRGB(200, 200, 210), Enum.Material.Fabric,
		head, CFrame.new(0, -0.8, -0.2))

	-- Wizard Hat
	local hatBrim = makeAccessory("HatBrim", Vector3.new(0.4, 2.8, 2.8),
		Color3.fromRGB(40, 30, 100), Enum.Material.Fabric,
		head, CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)))
	hatBrim.Shape = Enum.PartType.Cylinder

	local hatTop = makeAccessory("HatTop", Vector3.new(1.4, 2.0, 1.4),
		Color3.fromRGB(40, 30, 100), Enum.Material.Fabric,
		head, CFrame.new(0, 1.6, 0))

	local star = makeAccessory("HatStar", Vector3.new(0.5, 0.5, 0.5),
		Color3.fromRGB(255, 220, 80), Enum.Material.Neon,
		hatTop, CFrame.new(0, 1.1, 0))
	star.Shape = Enum.PartType.Ball

	-- Staff in right hand
	local staff = makeAccessory("Staff", Vector3.new(0.3, 4.5, 0.3),
		Color3.fromRGB(110, 80, 50), Enum.Material.Wood,
		rHand, CFrame.new(0, 2.0, 0))

	local crystal = makeAccessory("StaffCrystal", Vector3.new(0.7, 0.7, 0.7),
		Color3.fromRGB(100, 180, 255), Enum.Material.Neon,
		staff, CFrame.new(0, 2.5, 0))
	crystal.Shape = Enum.PartType.Ball

	---------------------------------------------------------------------------
	-- Glowing quest exclamation mark (!)
	---------------------------------------------------------------------------
	local questMarker = Instance.new("BillboardGui")
	questMarker.Name = "QuestMarker"
	questMarker.Size = UDim2.new(0, 40, 0, 50)
	questMarker.StudsOffset = Vector3.new(0, 6, 0)
	questMarker.AlwaysOnTop = true
	questMarker.Parent = hrp

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
	billboard.Parent = hrp

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
	prompt.Parent = hrp

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
		self._remotes.OpenQuest:FireClient(player, config.npcName)
	end)

	return model
end

function QuestService:GetQuestData(player, questId)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return nil end
	return data.quests[questId]
end

function QuestService:CompleteQuest(player, config)
	local data = self._playerData:GetData(player)
	local qData = self:GetQuestData(player, config.id)
	if not data or not qData then
		return
	end

	qData.completed = true
	local rewards = config.rewards or {}
	if self._experienceService then
		self._experienceService:GrantExperience(player, rewards.experience or 0, "quest")
	else
		self._playerData:AddXP(player, rewards.experience or 0)
	end
	self._playerData:AddCoins(player, rewards.gold or 0)

	if rewards.items then
		for _, reward in rewards.items do
			self._playerData:AddItem(player, reward.itemId, reward.quantity or 1)
		end
	end

	self._remotes.Notification:FireClient(player, "Quest complete: " .. config.name)
	self:FireQuestUpdated(player, config.id)
	self._playerData:FireStatsUpdated(player)

	if self._karmaService then
		self._karmaService:OnQuestCompleted(player)
	end
end

function QuestService:AdvanceQuestProgress(player, questId, amount)
	local qData = self:GetQuestData(player, questId)
	if not qData or not qData.accepted or qData.completed then
		return
	end

	local config = Quests[questId]
	if not config then
		return
	end

	qData.progress += amount or 1
	self:FireQuestUpdated(player, questId)
end

function QuestService:AcceptQuest(player, questId)
	local config = Quests[questId]
	local data = self._playerData:GetData(player)
	if not config or not data then
		return false
	end

	if data.level and config.requiredLevel and data.level < config.requiredLevel then
		return false
	end

	local qData = data.quests[questId]
	if qData and qData.completed and not config.repeatable then
		return false
	end

	data.quests[questId] = {
		accepted = true,
		completed = false,
		progress = 0,
	}
	self._playerData:FireStatsUpdated(player)
	self:FireQuestUpdated(player, questId)
	return true
end

function QuestService:TurnInQuest(player, questId)
	local qData = self:GetQuestData(player, questId)
	local config = Quests[questId]
	if not qData or not config then return false end
	
	if qData.accepted and not qData.completed and qData.progress >= Quests.GetRequired(config) then
		self:CompleteQuest(player, config)
		return true
	end
	return false
end

function QuestService:OnEnemyKilled(player, enemyType)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return end
	for qId, qData in pairs(data.quests) do
		local config = Quests[qId]
		if config and config.objectiveType == "kill" and config.targetEnemy == enemyType then
			self:AdvanceQuestProgress(player, qId, 1)
		end
	end
end

function QuestService:OnItemCollected(player, itemId, count)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return end
	for qId, qData in pairs(data.quests) do
		local config = Quests[qId]
		if config and config.objectiveType == "collect" and config.targetItem == itemId then
			self:AdvanceQuestProgress(player, qId, count or 1)
		end
	end
end

function QuestService:OnTalkToNPC(player, npcName)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return end
	for qId, qData in pairs(data.quests) do
		local config = Quests[qId]
		if config and config.objectiveType == "talk" and config.targetNpc == npcName then
			self:AdvanceQuestProgress(player, qId, 1)
		end
	end
end

function QuestService:OnReachZone(player, zoneId)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return end
	for qId, qData in pairs(data.quests) do
		local config = Quests[qId]
		if config and config.objectiveType == "reach" and config.targetZone == zoneId then
			self:AdvanceQuestProgress(player, qId, 1)
		end
	end
end

function QuestService:FireQuestUpdated(player, questId)
	local qData = self:GetQuestData(player, questId)
	if not qData then return end
	local config = Quests[questId]
	if not config then return end

	self._remotes.QuestUpdated:FireClient(player, {
		id = questId,
		name = config.name,
		description = config.description,
		objectiveType = config.objectiveType,
		accepted = qData.accepted,
		completed = qData.completed,
		progress = qData.progress,
		required = Quests.GetRequired(config),
	})
end

function QuestService:CreateSimpleNPC(name, cframe, promptText, color)
	local npcColor = color or Color3.fromRGB(100, 120, 180)
	local model, hrp = self:_BuildR15Rig(cframe, npcColor)
	model.Name = name

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 140, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = hrp

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
	prompt.Parent = hrp

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
	self:CreateNPC(self._mapGenerator:GetMarketplaceNpcCFrame("QuestGiver"))

	local _, herbPrompt = self:CreateSimpleNPC("Herb Master", self._mapGenerator:GetMarketplaceNpcCFrame("HerbMaster"), "Quest")
	herbPrompt.Triggered:Connect(function(player)
		local data = self._playerData:GetData(player)
		if not data then return end
		self._remotes.OpenQuest:FireClient(player, "Herb Master")
	end)

	local _, elderPrompt = self:CreateSimpleNPC("Village Elder", self._mapGenerator:GetMarketplaceNpcCFrame("VillageElder"), "Talk")
	elderPrompt.Triggered:Connect(function(player)
		self:OnTalkToNPC(player, "Village Elder")
		local data = self._playerData:GetData(player)
		if data then
			self._remotes.OpenQuest:FireClient(player, "Village Elder")
		end
	end)

	local monumentPos = Vector3.new(0, 0, 300)
	local monumentY = self._mapGenerator:GetGroundHeight(monumentPos.X, monumentPos.Z)
	self:CreateReachZone("QuestMonumentZone", Vector3.new(monumentPos.X, monumentY + 4, monumentPos.Z), Vector3.new(24, 10, 24))

	local _, scoutPrompt = self:CreateSimpleNPC("Scout", self._mapGenerator:GetMarketplaceNpcCFrame("Scout"), "Quest")
	scoutPrompt.Triggered:Connect(function(player)
		local data = self._playerData:GetData(player)
		if not data then return end
		self._remotes.OpenQuest:FireClient(player, "Scout")
	end)

	self._remotes.AcceptQuest.OnServerEvent:Connect(function(player, questId)
		if self:AcceptQuest(player, questId) then
			self._remotes.Notification:FireClient(player, "Quest accepted!")
		end
	end)

	if not self._remotes:FindFirstChild("TurnInQuest") then
		local remote = Instance.new("RemoteEvent")
		remote.Name = "TurnInQuest"
		remote.Parent = self._remotes
	end
	self._remotes.TurnInQuest.OnServerEvent:Connect(function(player, questId)
		if self:TurnInQuest(player, questId) then
			-- Rewards handled inside CompleteQuest
		end
	end)
end

return QuestService
