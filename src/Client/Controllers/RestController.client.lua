local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = game:GetService("Players").LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local isResting = false

local function syncRestFromCharacter(character)
	if not character then
		isResting = false
		return
	end
	isResting = character:GetAttribute("IsResting") == true
	character:GetAttributeChangedSignal("IsResting"):Connect(function()
		isResting = character:GetAttribute("IsResting") == true
	end)
end

player.CharacterAdded:Connect(syncRestFromCharacter)
if player.Character then
	syncRestFromCharacter(player.Character)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode ~= Enum.KeyCode.M then
		return
	end

	remotes.SetResting:FireServer(not isResting)
end)
