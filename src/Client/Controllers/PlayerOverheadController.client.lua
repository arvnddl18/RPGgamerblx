local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NameColorResolver = require(Shared.Util.NameColorResolver)

local player = Players.LocalPlayer

local function getAttachPart(character)
	return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function updateOverhead(overhead, targetPlayer)
	local karmaState = targetPlayer:GetAttribute("KarmaState") or "Innocent"
	local pvpMode = targetPlayer:GetAttribute("PvpMode") or "Peaceful"
	local nameLabel = overhead:FindFirstChild("NameLabel", true)
	if nameLabel then
		nameLabel.Text = targetPlayer.DisplayName
		nameLabel.TextColor3 = NameColorResolver.Resolve(karmaState, pvpMode)
	end

	local character = targetPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local fill = overhead:FindFirstChild("HpFill", true)
	if fill and humanoid and humanoid.MaxHealth > 0 then
		local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
	end
end

local function createOverhead(targetPlayer, character)
	local attachPart = getAttachPart(character)
	if not attachPart then
		return nil
	end

	local existing = attachPart:FindFirstChild("PlayerOverhead")
	if existing then
		existing:Destroy()
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlayerOverhead"
	billboard.Size = UDim2.new(0, 120, 0, 36)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = attachPart

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 12
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = container

	local hpBg = Instance.new("Frame")
	hpBg.Name = "HpBg"
	hpBg.Size = UDim2.new(1, 0, 0, 6)
	hpBg.Position = UDim2.new(0, 0, 0, 18)
	hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	hpBg.BorderSizePixel = 0
	hpBg.Parent = container

	local hpFill = Instance.new("Frame")
	hpFill.Name = "HpFill"
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg

	updateOverhead(billboard, targetPlayer)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.HealthChanged:Connect(function()
			if billboard.Parent then
				updateOverhead(billboard, targetPlayer)
			end
		end)
	end

	return billboard
end

local function setupPlayer(targetPlayer)
	local function onCharacter(character)
		task.defer(function()
			createOverhead(targetPlayer, character)
		end)
	end

	if targetPlayer.Character then
		onCharacter(targetPlayer.Character)
	end
	targetPlayer.CharacterAdded:Connect(onCharacter)

	targetPlayer:GetAttributeChangedSignal("KarmaState"):Connect(function()
		local char = targetPlayer.Character
		local attach = char and getAttachPart(char)
		local overhead = attach and attach:FindFirstChild("PlayerOverhead")
		if overhead then
			updateOverhead(overhead, targetPlayer)
		end
	end)

	targetPlayer:GetAttributeChangedSignal("PvpMode"):Connect(function()
		local char = targetPlayer.Character
		local attach = char and getAttachPart(char)
		local overhead = attach and attach:FindFirstChild("PlayerOverhead")
		if overhead then
			updateOverhead(overhead, targetPlayer)
		end
	end)
end

for _, p in Players:GetPlayers() do
	setupPlayer(p)
end
Players.PlayerAdded:Connect(setupPlayer)
