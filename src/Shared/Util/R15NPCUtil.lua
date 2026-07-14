-- Creates an actual Roblox R15 avatar rather than a hand-built part model.
local Players = game:GetService("Players")

local R15NPCUtil = {}

function R15NPCUtil.Build(groundCFrame, skinColor, outfitColor, pantsColor)
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = skinColor
	description.LeftArmColor = outfitColor or skinColor
	description.RightArmColor = outfitColor or skinColor
	description.TorsoColor = outfitColor or skinColor
	description.LeftLegColor = pantsColor or outfitColor or skinColor
	description.RightLegColor = pantsColor or outfitColor or skinColor
	description.BodyTypeScale = 0
	description.ProportionScale = 0
	description.HeightScale = 1
	description.WidthScale = 1
	description.DepthScale = 1
	description.HeadScale = 1

	local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:WaitForChild("HumanoidRootPart")
	local head = model:WaitForChild("Head")

	model.Name = "NPC"
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = true
		end
	end

	-- The supplied CFrame is ground level. Derive the root offset from the
	-- generated avatar's real bounds so feet cannot spawn below the terrain.
	local boundsCFrame, boundsSize = model:GetBoundingBox()
	local rootOffsetFromFloor = root.Position.Y - (boundsCFrame.Position.Y - boundsSize.Y / 2)
	root.Anchored = true
	model.PrimaryPart = root
	local floorCFrame = typeof(groundCFrame) == "CFrame" and groundCFrame or CFrame.new(groundCFrame)
	model:PivotTo(floorCFrame * CFrame.new(0, rootOffsetFromFloor, 0))

	return model, root, head, humanoid
end

function R15NPCUtil.AddInteraction(head, actionText, objectText, callback)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = head
	prompt.Triggered:Connect(callback)
	return prompt
end

return R15NPCUtil
