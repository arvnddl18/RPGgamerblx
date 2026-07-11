local Controller = {}

function Controller:Start()
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalancingConfig = require(Shared.Config.BalancingConfig)

local player = Players.LocalPlayer
local playerLevel = 1
local overheadByEnemy = {}

local function getAttachPart(enemy)
	return enemy:FindFirstChild("Head") or enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
end

local function updateOverhead(overhead, enemy)
	local level = enemy:GetAttribute("Level") or 1
	local rarity = enemy:GetAttribute("Rarity") or "Common"
	local displayName = enemy:GetAttribute("DisplayName") or enemy.Name

	local levelLabel = overhead:FindFirstChild("LevelLabel", true)
	local nameLabel = overhead:FindFirstChild("NameLabel", true)
	local color = BalancingConfig.GetDifficultyColor(level, playerLevel, rarity)

	if levelLabel then
		levelLabel.Text = "Lv." .. tostring(level)
		levelLabel.TextColor3 = color
	end
	if nameLabel then
		nameLabel.Text = displayName
		nameLabel.TextColor3 = color
	end
end

local function createOverhead(enemy)
	local attachPart = getAttachPart(enemy)
	if not attachPart then
		return nil
	end

	local existing = attachPart:FindFirstChild("EnemyOverhead")
	if existing then
		existing:Destroy()
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EnemyOverhead"
	billboard.Size = UDim2.new(0, 120, 0, 36)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 120
	billboard.Parent = attachPart

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = billboard

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(1, 0, 0, 14)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.TextSize = 11
	levelLabel.TextStrokeTransparency = 0.5
	levelLabel.Parent = container

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.Position = UDim2.new(0, 0, 0, 14)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = container

	updateOverhead(billboard, enemy)

	enemy:GetAttributeChangedSignal("Level"):Connect(function()
		updateOverhead(billboard, enemy)
	end)
	enemy:GetAttributeChangedSignal("Rarity"):Connect(function()
		updateOverhead(billboard, enemy)
	end)
	enemy:GetAttributeChangedSignal("DisplayName"):Connect(function()
		updateOverhead(billboard, enemy)
	end)

	overheadByEnemy[enemy] = billboard
	return billboard
end

local function onEnemyAdded(enemy)
	if not enemy:IsA("Model") then
		return
	end
	task.defer(function()
		if enemy.Parent then
			createOverhead(enemy)
		end
	end)
end

local function onEnemyRemoved(enemy)
	local overhead = overheadByEnemy[enemy]
	if overhead then
		overhead:Destroy()
		overheadByEnemy[enemy] = nil
	end
end

for _, enemy in CollectionService:GetTagged("Enemy") do
	onEnemyAdded(enemy)
end

CollectionService:GetInstanceAddedSignal("Enemy"):Connect(onEnemyAdded)
CollectionService:GetInstanceRemovedSignal("Enemy"):Connect(onEnemyRemoved)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	if payload.level then
		playerLevel = payload.level
		for enemy, overhead in overheadByEnemy do
			if enemy.Parent then
				updateOverhead(overhead, enemy)
			end
		end
	end
end)

end

return Controller
