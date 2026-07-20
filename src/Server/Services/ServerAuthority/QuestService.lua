local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)
local R15NPCUtil = require(Shared.Util.R15NPCUtil)

local QuestService = {}
QuestService._playerData = nil
QuestService._experienceService = nil
QuestService._remotes = nil
QuestService._teleportCooldown = {}

function QuestService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._experienceService = Framework:GetService("ExperienceService")
	self._karmaService = Framework:GetService("KarmaService")
	self._enemyService = Framework:GetService("EnemyService")
	self._remotes = Framework:GetRemotesFolder()
	self._mapGenerator = Framework:GetService("MapGeneratorService")
	Framework:GetRemote("OpenQuestLog")
	Framework:GetRemote("OpenComicScene")
	Framework:GetRemote("CompleteComicScene")
	Framework:GetRemote("TeleportToQuestGiver")
	self._activeScenes = {}
end

---------------------------------------------------------------------------
-- Shared R15 rig builder (same skeleton structure as monster rigs)
---------------------------------------------------------------------------
function QuestService:_BuildLegacyR15Rig(cframe, skinColor)
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

-- Reuse the stationary rig builder so all NPCs share the same R15 skeleton.
-- This replaces the older inline builder above, which anchored every limb.
function QuestService:_BuildR15Rig(cframe, skinColor, outfitColor, pantsColor)
	return R15NPCUtil.Build(cframe, skinColor, outfitColor, pantsColor)
end

function QuestService:CreateNPC(cframe)
	-- Legacy compatibility helper. The original GoblinMenace quest was
	-- replaced by the Chapter 1 Vanguard chain, so never assume that old
	-- configuration still exists if another service calls this method.
	local config = Quests.VanguardAtDawn or {
		npcName = "Commander Rhessa Kael",
	}

	local robeColor = Color3.fromRGB(50, 60, 140)
	local skinColor = Color3.fromRGB(220, 180, 140)

	local model, hrp, head = self:_BuildR15Rig(cframe, skinColor, robeColor, Color3.fromRGB(35, 40, 100))
	model.Name = config.npcName

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
	billboard.MaxDistance = 45
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

	local prompt = R15NPCUtil.AddInteraction(head, "Talk", config.npcName, function(player)
		local data = self._playerData:GetData(player)
		if data then
			self._remotes.OpenQuest:FireClient(player, config.npcName)
		end
	end)

	local npcsFolder = workspace:FindFirstChild("NPCs")
	if not npcsFolder then
		npcsFolder = Instance.new("Folder")
		npcsFolder.Name = "NPCs"
		npcsFolder.Parent = workspace
	end
	model.Parent = npcsFolder

	return model
end

function QuestService:GetQuestData(player, questId)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return nil end
	return data.quests[questId]
end

function QuestService:ArePrerequisitesComplete(player, config)
	for _, prerequisiteId in ipairs(config.prerequisites or {}) do
		local prerequisite = self:GetQuestData(player, prerequisiteId)
		if not prerequisite or not prerequisite.completed then
			return false, prerequisiteId
		end
	end
	return true
end

function QuestService:GetQuestStatus(player, questId)
	local config = Quests[questId]
	if not config then return "Locked" end
	local qData = self:GetQuestData(player, questId)
	if qData then
		if qData.completed and not config.repeatable then return "Completed" end
		if qData.accepted then
			return qData.progress >= Quests.GetRequired(config) and "Ready" or "Accepted"
		end
	end
	local allowed = self:ArePrerequisitesComplete(player, config)
	return allowed and "Available" or "Locked"
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
		self._playerData:AddClassMasteryXP(player, rewards.experience or 0)
	end
	self._playerData:AddCoins(player, rewards.gold or 0)

	if rewards.items then
		for _, reward in rewards.items do
			self._playerData:AddItem(player, reward.itemId, reward.quantity or 1)
		end
	end
	if self._remotes.QuestReward then
		self._remotes.QuestReward:FireClient(player, {
			name = config.name,
			gold = rewards.gold or 0,
			experience = rewards.experience or 0,
			items = rewards.items or {},
		})
	end

	self._remotes.Notification:FireClient(player, "Quest complete: " .. config.name)
	local nextStoryQuest
	for nextQuestId, nextConfig in pairs(Quests) do
		if type(nextConfig) == "table" and nextConfig.id and nextConfig.isMainStory then
			for _, prerequisiteId in ipairs(nextConfig.prerequisites or {}) do
				if prerequisiteId == config.id and self:GetQuestStatus(player, nextQuestId) == "Available" then
					nextStoryQuest = nextConfig
					break
				end
			end
		end
		if nextStoryQuest then break end
	end
	if nextStoryQuest then
		self._remotes.Notification:FireClient(player, "New story quest: " .. nextStoryQuest.name .. " — Talk to " .. (nextStoryQuest.questGiver or "the next guide") .. ".")
	end
	self:FireQuestUpdated(player, config.id)
	self._playerData:FireStatsUpdated(player)

	if self._karmaService then
		self._karmaService:OnQuestCompleted(player)
	end

	if config.id == "FrostwingsDomain" and self._scenes then
		local flags = data.storyFlags or {}
		data.storyFlags = flags
		if not flags.FrostwingEpilogue then
			self._activeScenes[player] = { sceneId = "FrostwingEpilogue", epilogue = true }
			self._remotes.OpenComicScene:FireClient(player, "FrostwingEpilogue", self._scenes.FrostwingEpilogue)
		end
	elseif config.id == "ReturnToValdris" and self._scenes then
		local flags = data.storyFlags or {}
		data.storyFlags = flags
		if not flags.CrownLieEpilogue then
			self._activeScenes[player] = { sceneId = "CrownLieEpilogue", epilogue = true }
			self._remotes.OpenComicScene:FireClient(player, "CrownLieEpilogue", self._scenes.CrownLieEpilogue)
		end
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

	qData.progress = math.min(Quests.GetRequired(config), qData.progress + (amount or 1))
	self:FireQuestUpdated(player, questId)
end

function QuestService:AdvanceTargetProgress(player, questId, targetType, targetName)
	local qData = self:GetQuestData(player, questId)
	local config = Quests[questId]
	if not qData or not config or not qData.accepted or qData.completed then return end
	local target = nil
	for _, candidate in ipairs(config.targets or {}) do
		if candidate.type == targetType and candidate.name == targetName then
			target = candidate
			break
		end
	end
	if not target then return end
	qData.targetProgress = qData.targetProgress or {}
	local key = targetType .. ":" .. targetName
	local current = qData.targetProgress[key] or 0
	if current >= (target.quantity or 1) then return end
	qData.targetProgress[key] = current + 1
	local total = 0
	for _, candidate in ipairs(config.targets or {}) do
		total += qData.targetProgress[candidate.type .. ":" .. candidate.name] or 0
	end
	qData.progress = total
	self:FireQuestUpdated(player, questId)
end

-- Count materials the player already owns when an item quest is accepted.
-- Progress is never reduced if the material is later used or dropped.
function QuestService:SyncInventoryTargetProgress(player, questId)
	local qData = self:GetQuestData(player, questId)
	local config = Quests[questId]
	local data = self._playerData:GetData(player)
	if not qData or not config or not data or not qData.accepted or qData.completed then return false end
	if config.objectiveType ~= "collect" and config.objectiveType ~= "collectcraft" then return false end
	local counts = {}
	for _, entry in ipairs(data.inventory or {}) do
		if entry and entry.id then counts[entry.id] = (counts[entry.id] or 0) + (entry.count or 1) end
	end
	qData.targetProgress = qData.targetProgress or {}
	local changed = false
	for _, target in ipairs(config.targets or {}) do
		if target.type == "item" then
			local key = target.type .. ":" .. target.name
			local owned = math.min(counts[target.name] or 0, target.quantity or 1)
			if owned > (qData.targetProgress[key] or 0) then
				qData.targetProgress[key] = owned
				changed = true
			end
		end
	end
	if changed then
		local total = 0
		for _, target in ipairs(config.targets or {}) do
			total += math.min(qData.targetProgress[target.type .. ":" .. target.name] or 0, target.quantity or 1)
		end
		qData.progress = total
	end
	return changed
end

function QuestService:AcceptQuest(player, questId)
	local config = Quests[questId]
	local data = self._playerData:GetData(player)
	if not config or not data then
		return false
	end
	local prerequisitesComplete, missingQuestId = self:ArePrerequisitesComplete(player, config)
	if not prerequisitesComplete then
		self._remotes.Notification:FireClient(player, "Locked: complete " .. (Quests[missingQuestId].name or missingQuestId) .. " first.")
		return false
	end

	if data.level and config.requiredLevel and data.level < config.requiredLevel then
		return false
	end

	data.quests = data.quests or {}
	local qData = data.quests[questId]
	if qData and qData.accepted and not qData.completed then
		return false
	end
	if qData and qData.completed and not config.repeatable then
		return false
	end

	data.quests[questId] = {
		accepted = true,
		completed = false,
		progress = 0,
		targetProgress = {},
	}
	self:SyncInventoryTargetProgress(player, questId)
	if questId == "CinderscarWarden" and self._enemyService then
		self._enemyService:SpawnQuestBoss("Vaelithra", Vector3.new(800, 0, -600), 40)
		self._remotes.Notification:FireClient(player, "The Cinderscar Crater is now active. Follow the eastern ridge.")
	end
	-- A conversation quest is completed by accepting it from its named speaker.
	if config.objectiveType == "talk" and config.targetNpc == config.questGiver then
		self:AdvanceTargetProgress(player, questId, "npc", config.targetNpc)
	end
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
		if config and (config.objectiveType == "kill" or config.objectiveType == "killreach") and Quests.IsTarget(config, "enemy", enemyType) then
			self:AdvanceTargetProgress(player, qId, "enemy", enemyType)
		end
	end
end

function QuestService:OnItemCollected(player, itemId, count)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return end
	for qId, qData in pairs(data.quests) do
		local config = Quests[qId]
		if config and (config.objectiveType == "collect" or config.objectiveType == "collectcraft") and Quests.IsTarget(config, "item", itemId) then
			for _ = 1, count or 1 do self:AdvanceTargetProgress(player, qId, "item", itemId) end
		end
	end
end

function QuestService:OnCrafted(player, recipeId)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return end
	for qId, qData in pairs(data.quests) do
		local config = Quests[qId]
		if config and config.objectiveType == "collectcraft" and Quests.IsTarget(config, "craft", recipeId) then
			self:AdvanceTargetProgress(player, qId, "craft", recipeId)
		end
	end
end

function QuestService:OnEquipmentUpgraded(player)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return end
	for qId, qData in pairs(data.quests) do
		local config = Quests[qId]
		if config and config.objectiveType == "upgrade" and Quests.IsTarget(config, "upgrade", "equipment") then self:AdvanceTargetProgress(player, qId, "upgrade", "equipment") end
	end
end

function QuestService:OnEquipmentEnhanced(player)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return end
	for qId, qData in pairs(data.quests) do
		local config = Quests[qId]
		if config and config.objectiveType == "enhance" and Quests.IsTarget(config, "enhance", "equipment") then self:AdvanceTargetProgress(player, qId, "enhance", "equipment") end
	end
end

function QuestService:OnTalkToNPC(player, npcName)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return end
	for qId, qData in pairs(data.quests) do
		local config = Quests[qId]
		if config and config.objectiveType == "talk" and Quests.IsTarget(config, "npc", npcName) then
			self:AdvanceTargetProgress(player, qId, "npc", npcName)
		end
	end
end

function QuestService:OnReachZone(player, zoneId)
	local data = self._playerData:GetData(player)
	if not data or not data.quests then return end
	for qId, qData in pairs(data.quests) do
		local config = Quests[qId]
		if config and (config.objectiveType == "reach" or config.objectiveType == "killreach") and Quests.IsTarget(config, "zone", zoneId) then
			self:AdvanceTargetProgress(player, qId, "zone", zoneId)
		end
	end
end

function QuestService:FireQuestUpdated(player, questId)
	local qData = self:GetQuestData(player, questId)
	if not qData then return end
	local config = Quests[questId]
	if not config then return end
	self:SyncInventoryTargetProgress(player, questId)

	self._remotes.QuestUpdated:FireClient(player, {
		id = questId,
		name = config.name,
		description = config.description,
		objectiveType = config.objectiveType,
		accepted = qData.accepted,
		completed = qData.completed,
		progress = qData.progress,
		targetProgress = qData.targetProgress or {},
		required = Quests.GetRequired(config),
		status = self:GetQuestStatus(player, questId),
	})
end

function QuestService:TeleportToQuestGiver(player, questId)
	local now = os.clock()
	if self._teleportCooldown[player] and now - self._teleportCooldown[player] < 1 then
		return
	end

	local config = Quests[questId]
	if not config or self:GetQuestStatus(player, questId) ~= "Ready" then
		return
	end

	local npcsFolder = workspace:FindFirstChild("NPCs")
	local npc = npcsFolder and npcsFolder:FindFirstChild(config.npcName)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not npc or not character or not humanoid or humanoid.Health <= 0 then
		return
	end

	local npcPivot = npc:GetPivot()
	local destination = npcPivot.Position + npcPivot.LookVector * 7
	local target = Vector3.new(npcPivot.Position.X, destination.Y, npcPivot.Position.Z)
	self._teleportCooldown[player] = now
	character:PivotTo(CFrame.lookAt(destination, target))
	self._remotes.Notification:FireClient(player, "Arrived at " .. (config.questGiver or config.npcName) .. ".")
end

-- Every non-repeatable story quest uses the same comic offer flow after its
-- NPC's one-time introduction has been seen. This keeps the interaction
-- consistent for the long Chapter 1 chain without requiring a hand-written
-- scene table entry for every combat beat.
function QuestService:GetNextQuestOffer(player, npcName)
	local bestConfig = nil
	for _, config in pairs(Quests) do
		if type(config) == "table" and config.id and config.npcName == npcName and not config.repeatable then
			if self:GetQuestStatus(player, config.id) == "Available" then
				if not bestConfig
					or (config.isMainStory and not bestConfig.isMainStory)
					or (config.isMainStory == bestConfig.isMainStory and config.id < bestConfig.id) then
					bestConfig = config
				end
			end
		end
	end
	return bestConfig
end

function QuestService:GetReadyQuest(player, npcName)
	local bestConfig = nil
	for _, config in pairs(Quests) do
		if type(config) == "table" and config.id and config.npcName == npcName then
			if self:GetQuestStatus(player, config.id) == "Ready" then
				if not bestConfig
					or (config.isMainStory and not bestConfig.isMainStory)
					or (config.isMainStory == bestConfig.isMainStory and config.id < bestConfig.id) then
					bestConfig = config
				end
			end
		end
	end
	return bestConfig
end

function QuestService:OpenQuestCompletion(player, npcName)
	local config = self:GetReadyQuest(player, npcName)
	if not config then
		return false
	end

	local panels = {}
	for _, line in ipairs(config.completionDialogue or {}) do
		if type(line) == "table" and line.text then
			table.insert(panels, {
				speaker = line.speaker or npcName,
				side = line.side or "left",
				color = line.color or Color3.fromRGB(166, 119, 55),
				text = line.text,
			})
		elseif type(line) == "string" then
			table.insert(panels, {
				speaker = npcName,
				side = "left",
				color = Color3.fromRGB(166, 119, 55),
				text = line,
			})
		end
	end
	if #panels == 0 then
		panels = {
			{
				speaker = npcName,
				side = "left",
				color = Color3.fromRGB(166, 119, 55),
				text = "You completed the mission. Thank you for helping the people of Frosthorn.",
			},
		}
	end
	local sceneId = "QuestComplete_" .. config.id
	self._activeScenes[player] = { npcName = npcName, sceneId = sceneId, turnInQuestId = config.id }
	self._remotes.OpenComicScene:FireClient(player, sceneId, {
		title = config.name,
		npcName = npcName,
		turnInQuestId = config.id,
		panels = panels,
	})
	return true
end

function QuestService:OpenQuestOffer(player, npcName)
	local config = self:GetNextQuestOffer(player, npcName)
	if not config then
		return false
	end

	local sceneId = "QuestOffer_" .. config.id
	local panels = {}
	for _, line in ipairs(config.dialogue or {}) do
		if type(line) == "table" and line.text then
			table.insert(panels, {
				speaker = line.speaker or npcName,
				side = line.side or "left",
				color = line.color or Color3.fromRGB(166, 119, 55),
				text = line.text,
			})
		elseif type(line) == "string" then
			table.insert(panels, {
				speaker = npcName,
				side = "left",
				color = Color3.fromRGB(166, 119, 55),
				text = line,
			})
		end
	end
	if #panels == 0 then
		panels = {
			{
				speaker = npcName,
				side = "left",
				color = Color3.fromRGB(166, 119, 55),
				text = config.description or "Help us with the next step.",
			},
		}
	end
	local scene = { title = config.name, npcName = npcName, questId = config.id, panels = panels }
	self._activeScenes[player] = { npcName = npcName, sceneId = sceneId }
	self._remotes.OpenComicScene:FireClient(player, sceneId, scene)
	return true
end

function QuestService:CreateSimpleNPC(name, cframe, promptText, color, onTriggered, showQuestMarker)
	local npcColor = color or Color3.fromRGB(100, 120, 180)
	local model, hrp, head = self:_BuildR15Rig(cframe, npcColor, npcColor)
	model.Name = name

	if showQuestMarker then
		local questMarker = Instance.new("BillboardGui")
		questMarker.Name = "QuestMarker"
		questMarker.Size = UDim2.new(0, 42, 0, 48)
		questMarker.StudsOffset = Vector3.new(0, 5.8, 0)
		questMarker.AlwaysOnTop = true
		questMarker.Parent = hrp

		local markerLabel = Instance.new("TextLabel")
		markerLabel.Size = UDim2.fromScale(1, 1)
		markerLabel.BackgroundTransparency = 1
		markerLabel.Text = "!"
		markerLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
		markerLabel.TextStrokeColor3 = Color3.fromRGB(120, 75, 0)
		markerLabel.TextStrokeTransparency = 0
		markerLabel.Font = Enum.Font.GothamBlack
		markerLabel.TextSize = 36
		markerLabel.Parent = questMarker
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 140, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 45
	billboard.Parent = hrp

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Color3.fromRGB(255, 220, 100)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.Parent = billboard

	local prompt = R15NPCUtil.AddInteraction(head, promptText or "Talk", name, onTriggered or function() end)

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
	local Players = game:GetService("Players")
	local function worldCFrame(position, yaw)
		local y = self._mapGenerator:GetGroundHeight(position.X, position.Z)
		return CFrame.new(position.X, y, position.Z) * CFrame.Angles(0, yaw or 0, 0)
	end

	local scenes = {
		RhessaIntro = {
			title = "A Vanguard at Dawn", questId = "VanguardAtDawn", panels = {
				{ speaker = "Commander Rhessa Kael", color = Color3.fromRGB(173, 72, 62), text = "Valdris needs steady hands, recruit. Frosthorn's creatures are climbing toward its summit." },
				{ speaker = "Commander Rhessa Kael", color = Color3.fromRGB(173, 72, 62), text = "Take the northern road. Reopen the Waygate, then report every sign of what drove them there." },
			}
		},
		TovenIntro = {
			title = "The Scholar in the Ruins", questId = "ScholarInRuins", panels = {
				{ speaker = "Magister Toven Ashe", color = Color3.fromRGB(90, 116, 178), text = "These stones are older than Valdris. Their guardians are not protecting treasure — they are protecting a memory." },
				{ speaker = "Magister Toven Ashe", color = Color3.fromRGB(90, 116, 178), text = "Help me clear the courtyard. The sealed chamber may tell us why Frosthorn is afraid." },
			}
		},
		AmaraIntro = {
			title = "A Village Worth Saving", questId = "VillageSupplyLine", panels = {
				{ speaker = "Sister Amara", side = "left", color = Color3.fromRGB(212, 180, 104), text = "The refugees brought more than fear. Their wounds carry a strange mountain chill." },
				{ speaker = "Sister Amara", side = "left", color = Color3.fromRGB(212, 180, 104), text = "Listen to their story, recruit. If we understand what drove the creatures uphill, we can protect Valdris." },
			}
		},
		IvenIntro = {
			title = "The Northern Road", questId = "NorthernWaygate", panels = {
				{ speaker = "Scout Iven", side = "right", color = Color3.fromRGB(92, 160, 112), text = "The northern Waygate has gone quiet. Without it, supplies cannot reach the foothills." },
				{ speaker = "Scout Iven", side = "right", color = Color3.fromRGB(92, 160, 112), text = "Reach the gate and wake its old crystal. Then we will know whether the road is safe." },
			}
		},
		DoranIntro = {
			title = "Forge the Vanguard", questId = "ForgeTheVanguard", panels = {
				{ speaker = "Blacksmith Doran", side = "left", color = Color3.fromRGB(178, 104, 62), text = "This ore came from a warband carrying Valdris steel. Someone is reusing the Crown's old weapons." },
				{ speaker = "Blacksmith Doran", side = "left", color = Color3.fromRGB(178, 104, 62), text = "Bring your equipment to the forge. A Vanguard cannot face Frosthorn with a rusty blade." },
			}
		},
		EddaIntro = {
			title = "The Warband's Refuge", questId = "WarbandsRefuge", panels = {
				{ speaker = "Warden Edda", side = "right", color = Color3.fromRGB(110, 135, 165), text = "The Orcs have barricaded the upper slope, but their campfires point inward, not toward Valdris." },
				{ speaker = "Warden Edda", side = "right", color = Color3.fromRGB(110, 135, 165), text = "Clear a path to their refuge. If they are hiding from the same danger as us, we may need answers more than trophies." },
			}
		},
		FrostwingEpilogue = {
			title = "The Frostwing's Hoard", panels = {
				{ speaker = "Magister Toven Ashe", color = Color3.fromRGB(90, 116, 178), text = "Scorched Vanguard gear... decades old. This royal seal should never have been on Frosthorn." },
				{ speaker = "Commander Rhessa Kael", color = Color3.fromRGB(173, 72, 62), text = "We are done here. Return to Valdris. Now." },
			}
		},
		CrownLieEpilogue = {
			title = "The Crown's Lie", panels = {
				{ speaker = "Commander Rhessa Kael", color = Color3.fromRGB(173, 72, 62), text = "The Frostwing was not attacking Valdris. It was holding the old royal command beneath Frosthorn at bay." },
				{ speaker = "Commander Rhessa Kael", color = Color3.fromRGB(173, 72, 62), text = "I served the Crown because I believed silence kept the kingdom safe. I was wrong." },
				{ speaker = "Magister Toven Ashe", color = Color3.fromRGB(90, 116, 178), text = "Three Waygates remain sealed. Their maps hold the rest of the shattered history — and someone is already trying to open them." },
			}
		},
		CinderscarIntro = {
			title = "The Cinderwyrm Warden", questId = "CinderscarWarden", panels = {
				{ speaker = "Commander Rhessa Kael", side = "left", color = Color3.fromRGB(173, 72, 62), text = "The Crown's secret did not end on Frosthorn. The eastern crater is waking, and its guardian remembers the old seal." },
				{ speaker = "Commander Rhessa Kael", side = "left", color = Color3.fromRGB(173, 72, 62), text = "The crater is optional, recruit. Go only when you are ready, learn what you can, and return safely." },
			}
		},
	}
	self._scenes = scenes
	Players.PlayerRemoving:Connect(function(player)
		self._activeScenes[player] = nil
	end)

	function self:OpenNpc(player, npcName, sceneId)
		local data = self._playerData:GetData(player)
		if not data then return end
		if self._activeScenes[player] then return end
		data.storyFlags = data.storyFlags or {}
		if sceneId and not data.storyFlags[sceneId] and not self._activeScenes[player] then
			self._activeScenes[player] = { npcName = npcName, sceneId = sceneId }
			self._remotes.OpenComicScene:FireClient(player, sceneId, scenes[sceneId])
			return
		end
		if self:OpenQuestCompletion(player, npcName) then
			return
		end
		if not self._activeScenes[player] and self:OpenQuestOffer(player, npcName) then
			return
		end
		self:OnTalkToNPC(player, npcName)
		self._remotes.OpenQuest:FireClient(player, npcName)
	end

	local _, rhessaPrompt = self:CreateSimpleNPC("Commander Rhessa Kael", self._mapGenerator:GetMarketplaceNpcCFrame("QuestGiver"), "Speak", Color3.fromRGB(173, 72, 62), nil, true)
	rhessaPrompt.Triggered:Connect(function(player)
		local sceneId = "RhessaIntro"
		if self:GetQuestStatus(player, "CinderscarWarden") == "Available" then
			sceneId = "CinderscarIntro"
		end
		self:OpenNpc(player, "Commander Rhessa Kael", sceneId)
	end)

	local _, tovenPrompt = self:CreateSimpleNPC("Magister Toven Ashe", self._mapGenerator:GetMarketplaceNpcCFrame("Magister"), "Speak", Color3.fromRGB(90, 116, 178), nil, true)
	tovenPrompt.Triggered:Connect(function(player)
		if self:GetQuestStatus(player, "ScholarInRuins") == "Locked" then
			self._remotes.Notification:FireClient(player, "Toven is studying alone. Complete Fleeing the Peak first.")
			return
		end
		self:OpenNpc(player, "Magister Toven Ashe", "TovenIntro")
	end)

	local function storyNpc(name, marketplaceSlot, color, requiredQuest, sceneId)
		local _, prompt = self:CreateSimpleNPC(name, self._mapGenerator:GetMarketplaceNpcCFrame(marketplaceSlot), "Speak", color, nil, true)
		prompt.Triggered:Connect(function(player)
			if requiredQuest and self:GetQuestStatus(player, requiredQuest) == "Locked" then
				self._remotes.Notification:FireClient(player, "This person is focused on the crisis ahead. Continue the Chapter 1 story.")
				return
			end
			self:OpenNpc(player, name, sceneId)
		end)
	end
	local function storyNpcAt(name, position, color, requiredQuest)
		local _, prompt = self:CreateSimpleNPC(name, worldCFrame(position, 0), "Speak", color, nil, true)
		prompt.Triggered:Connect(function(player)
			if requiredQuest and self:GetQuestStatus(player, requiredQuest) == "Locked" then
				self._remotes.Notification:FireClient(player, "Continue the story to find out how to help " .. name .. ".")
				return
			end
			self:OpenNpc(player, name)
		end)
	end
	storyNpc("Sister Amara", "HerbMaster", Color3.fromRGB(212, 180, 104), "VillageSupplyLine", "AmaraIntro")
	storyNpc("Scout Iven", "Scout", Color3.fromRGB(92, 160, 112), "NorthernWaygate", "IvenIntro")
	storyNpc("Blacksmith Doran", "Blacksmith", Color3.fromRGB(178, 104, 62), "ForgeTheVanguard", "DoranIntro")
	storyNpc("Warden Edda", "Warden", Color3.fromRGB(110, 135, 165), "WarbandsRefuge", "EddaIntro")
	-- Current-map NPCs for the expanded Chapter 1 story. They use the same
	-- comic offer flow as the original six quest givers and do not require
	-- future-map assets.
	storyNpcAt("Elder Mara", Vector3.new(-110, 0, -650), Color3.fromRGB(168, 120, 82), "NorthernWaygate")
	storyNpcAt("Quartermaster Elian", Vector3.new(90, 0, -760), Color3.fromRGB(120, 145, 175), "B2GoblinQuickfingers")
	storyNpcAt("Nib Quickfinger", Vector3.new(-90, 0, -800), Color3.fromRGB(130, 170, 105), "WebsOfWarning")
	storyNpcAt("Healer Lysa", Vector3.new(120, 0, -1080), Color3.fromRGB(210, 150, 145), "B4RunningPack")
	storyNpcAt("Hunter Corren", Vector3.new(-120, 0, -1220), Color3.fromRGB(112, 150, 105), "N4AntidoteForPatrol")
	storyNpcAt("Smith Hadrik", Vector3.new(110, 0, -1450), Color3.fromRGB(176, 108, 68), "B6KnightsSealedDoor")
	storyNpcAt("Scout Varok", Vector3.new(-120, 0, -1650), Color3.fromRGB(105, 138, 105), "B7AshenSpear")
	storyNpcAt("Cook Branna", Vector3.new(350, 0, -1450), Color3.fromRGB(202, 146, 90), "N9FeathersForSignal")
	storyNpcAt("Veteran Dain", Vector3.new(10, 0, -900), Color3.fromRGB(124, 124, 142), "FrostwingsDomain")
	storyNpcAt("Priestess Selene", Vector3.new(0, 0, -1650), Color3.fromRGB(180, 155, 210), "N11OldSoldiersQuestion")

	local waygatePosition = Vector3.new(0, 0, -920)
	local waygate = self:CreateReachZone("FrosthornWaygate", Vector3.new(waygatePosition.X, self._mapGenerator:GetGroundHeight(waygatePosition.X, waygatePosition.Z) + 8, waygatePosition.Z), Vector3.new(36, 18, 16))
	waygate.Name = "Northern Frosthorn Waygate"
	waygate.Transparency = 0.35
	waygate.Material = Enum.Material.Neon
	waygate.Color = Color3.fromRGB(90, 190, 255)

	local chamberPosition = Vector3.new(70, 0, -1500)
	local chamber = self:CreateReachZone("SealedChamberDoor", Vector3.new(chamberPosition.X, self._mapGenerator:GetGroundHeight(chamberPosition.X, chamberPosition.Z) + 7, chamberPosition.Z), Vector3.new(30, 14, 4))
	chamber.Name = "Sealed Royal Chamber"
	chamber.Transparency = 0.2
	chamber.Material = Enum.Material.Slate
	chamber.Color = Color3.fromRGB(55, 60, 75)

	self:CreateReachZone("WesternWatch", Vector3.new(-520, self._mapGenerator:GetGroundHeight(-520, -1390) + 7, -1390), Vector3.new(38, 14, 38)).Name = "Western Frosthorn Watch"
	self:CreateReachZone("EasternWatch", Vector3.new(520, self._mapGenerator:GetGroundHeight(520, -1420) + 7, -1420), Vector3.new(38, 14, 38)).Name = "Eastern Frosthorn Watch"
	local memorialPosition = Vector3.new(0, 0, -1650)
	local memorial = self:CreateReachZone("FrosthornMemorial", Vector3.new(memorialPosition.X, self._mapGenerator:GetGroundHeight(memorialPosition.X, memorialPosition.Z) + 7, memorialPosition.Z), Vector3.new(30, 14, 30))
	memorial.Name = "Frosthorn Memorial Shrine"
	memorial.Transparency = 0.35
	memorial.Material = Enum.Material.Neon
	memorial.Color = Color3.fromRGB(190, 160, 255)

	for _, gate in ipairs({
		{ name = "Emberfang Waygate", slot = "EmberfangSentry" },
		{ name = "Duskroot Waygate", slot = "DuskrootSentry" },
		{ name = "Stormpeak Waygate", slot = "StormpeakSentry" },
	}) do
		local _, prompt = self:CreateSimpleNPC(gate.name .. " Sentry", self._mapGenerator:GetMarketplaceNpcCFrame(gate.slot), "Inspect", Color3.fromRGB(85, 85, 105))
		prompt.Triggered:Connect(function(player)
			self._remotes.Notification:FireClient(player, "This Waygate is sealed. Its chapter is coming soon.")
		end)
	end

	self._remotes.AcceptQuest.OnServerEvent:Connect(function(player, questId)
		if self:AcceptQuest(player, questId) then
			self._remotes.Notification:FireClient(player, "Quest accepted!")
		end
	end)

	self._remotes.TeleportToQuestGiver.OnServerEvent:Connect(function(player, questId)
		self:TeleportToQuestGiver(player, questId)
	end)

	self._remotes.CompleteComicScene.OnServerEvent:Connect(function(player, sceneId, openQuestPanel)
		local active = self._activeScenes[player]
		if not active or active.sceneId ~= sceneId then return end
		local data = self._playerData:GetData(player)
		if data then
			data.storyFlags = data.storyFlags or {}
			local isQuestOffer = string.sub(sceneId, 1, 11) == "QuestOffer_"
			local isQuestCompletion = string.sub(sceneId, 1, 14) == "QuestComplete_"
			if not isQuestOffer and not isQuestCompletion then
				data.storyFlags[sceneId] = true
			end
			self._playerData:FireStatsUpdated(player)
			if not active.epilogue then
				local completedFromScene = active.turnInQuestId ~= nil
					and self:GetQuestStatus(player, active.turnInQuestId) == "Completed"
				if not completedFromScene then
					self:OnTalkToNPC(player, active.npcName)
					if openQuestPanel ~= false then
						self._remotes.OpenQuest:FireClient(player, active.npcName)
					end
				end
			end
		end
		self._activeScenes[player] = nil
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
