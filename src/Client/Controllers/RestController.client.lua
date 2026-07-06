local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = game:GetService("Players").LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LocalAnimationBuilder = require(Shared:WaitForChild("Util"):WaitForChild("LocalAnimationBuilder"))
local AnimationController = require(Shared:WaitForChild("Util"):WaitForChild("AnimationController"))

local isResting = false
local restVariants = {
	{
		layDown = LocalAnimationBuilder.GetRestLayDown1(),
		loop = LocalAnimationBuilder.GetRestLoop1(),
		standUp = LocalAnimationBuilder.GetRestStandUp1(),
	},
	{
		layDown = LocalAnimationBuilder.GetRestLayDown2(),
		loop = LocalAnimationBuilder.GetRestLoop2(),
		standUp = LocalAnimationBuilder.GetRestStandUp2(),
	},
}

local currentVariant = nil
local layDownTrack = nil
local loopTrack = nil

local function stopTracks(fade)
	if layDownTrack then
		layDownTrack:Stop(fade or 0.1)
		layDownTrack = nil
	end
	if loopTrack then
		loopTrack:Stop(fade or 0.1)
		loopTrack = nil
	end
end

local function playRestLoop(animator)
	if not currentVariant or not isResting then
		return
	end
	local anim = AnimationController.GetAnimation(currentVariant.loop)
	loopTrack = animator:LoadAnimation(anim)
	loopTrack.Priority = Enum.AnimationPriority.Action
	loopTrack.Looped = true
	loopTrack:Play(0.2)
end

local function startRestAnim(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end

	stopTracks(0)
	currentVariant = restVariants[math.random(1, #restVariants)]

	local anim = AnimationController.GetAnimation(currentVariant.layDown)
	layDownTrack = animator:LoadAnimation(anim)
	layDownTrack.Priority = Enum.AnimationPriority.Action
	layDownTrack.Looped = false
	layDownTrack:Play(0.3)
	layDownTrack.Stopped:Once(function()
		layDownTrack = nil
		if isResting then
			playRestLoop(animator)
		end
	end)
end

local function endRestAnim(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator or not currentVariant then
		stopTracks(0.2)
		currentVariant = nil
		return
	end

	stopTracks(0.1)

	local anim = AnimationController.GetAnimation(currentVariant.standUp)
	local standTrack = animator:LoadAnimation(anim)
	standTrack.Priority = Enum.AnimationPriority.Action
	standTrack.Looped = false
	standTrack:Play(0.3)
	currentVariant = nil
end

local function syncRestFromCharacter(character)
	if not character then
		isResting = false
		stopTracks(0.2)
		currentVariant = nil
		return
	end

	local function updateRestState()
		local wasResting = isResting
		isResting = character:GetAttribute("IsResting") == true

		if isResting and not wasResting then
			startRestAnim(character)
		elseif not isResting and wasResting then
			endRestAnim(character)
		end
	end

	updateRestState()
	character:GetAttributeChangedSignal("IsResting"):Connect(updateRestState)
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
