local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Controller = {}
Controller._activeVisuals = {}

local ARROW_LENGTH = 2.4
local ARROW_SHAFT_THICKNESS = 0.08
local ARROW_TIP_LENGTH = 0.4
local ARROW_TIP_THICKNESS = 0.18

local function buildArrowCFrame(origin, direction)
	local lookCF = CFrame.lookAt(origin, origin + direction)
	return lookCF * CFrame.new(0, 0, -ARROW_LENGTH / 2)
end

local function createVisualArrow(data)
	local origin = data.origin
	local direction = data.direction
	local color = data.color or Color3.fromRGB(200, 100, 50)
	local arrowId = data.arrowId

	local shaft = Instance.new("Part")
	shaft.Name = "VisualArrow_" .. tostring(arrowId)
	shaft.Size = Vector3.new(ARROW_SHAFT_THICKNESS, ARROW_SHAFT_THICKNESS, ARROW_LENGTH)
	shaft.Color = color
	shaft.Material = Enum.Material.Wood
	shaft.CanCollide = false
	shaft.CanQuery = false
	shaft.CanTouch = false
	shaft.Massless = true
	shaft.Anchored = true
	shaft.CastShadow = false
	shaft.CFrame = buildArrowCFrame(origin, direction)
	shaft.Parent = workspace

	local tip = Instance.new("Part")
	tip.Name = "Tip"
	tip.Size = Vector3.new(ARROW_TIP_THICKNESS, ARROW_TIP_THICKNESS, ARROW_TIP_LENGTH)
	tip.Shape = Enum.PartType.Ball
	tip.Color = Color3.fromRGB(180, 180, 190)
	tip.Material = Enum.Material.Metal
	tip.CanCollide = false
	tip.CanQuery = false
	tip.CanTouch = false
	tip.Massless = true
	tip.Anchored = true
	tip.CastShadow = false
	tip.CFrame = shaft.CFrame * CFrame.new(0, 0, -(ARROW_LENGTH / 2 + ARROW_TIP_LENGTH / 2))
	tip.Parent = shaft

	local fletching = Instance.new("Part")
	fletching.Name = "Fletching"
	fletching.Size = Vector3.new(0.22, 0.22, 0.15)
	fletching.Color = color
	fletching.Material = Enum.Material.Fabric
	fletching.CanCollide = false
	fletching.CanQuery = false
	fletching.CanTouch = false
	fletching.Massless = true
	fletching.Anchored = true
	fletching.CastShadow = false
	fletching.CFrame = shaft.CFrame * CFrame.new(0, 0, (ARROW_LENGTH / 2 + 0.05))
	fletching.Parent = shaft

	local att0 = Instance.new("Attachment")
	att0.Name = "TrailStart"
	att0.Position = Vector3.new(0, 0, ARROW_LENGTH / 2 - 0.1)
	att0.Parent = shaft

	local att1 = Instance.new("Attachment")
	att1.Name = "TrailEnd"
	att1.Position = Vector3.new(0, 0, -(ARROW_LENGTH / 2 - 0.1))
	att1.Parent = shaft

	local trail = Instance.new("Trail")
	trail.Name = "ArrowTrail"
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.4
	trail.MinLength = 0.01
	trail.LightEmission = 0.15
	trail.Brightness = 0.8
	trail.FaceCamera = true
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 200, 205)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(210, 210, 215)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 185)),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.3, 0.5),
		NumberSequenceKeypoint.new(0.7, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 1.0),
		NumberSequenceKeypoint.new(0.7, 1.4),
		NumberSequenceKeypoint.new(1, 0.6),
	})
	trail.Enabled = true
	trail.Parent = shaft

	local glowAtt0 = Instance.new("Attachment")
	glowAtt0.Name = "GlowTrailStart"
	glowAtt0.Position = Vector3.new(0, 0, ARROW_LENGTH / 2 + 0.15)
	glowAtt0.Parent = shaft

	local glowAtt1 = Instance.new("Attachment")
	glowAtt1.Name = "GlowTrailEnd"
	glowAtt1.Position = Vector3.new(0, 0, -(ARROW_LENGTH / 2 + 0.15))
	glowAtt1.Parent = shaft

	local glowTrail = Instance.new("Trail")
	glowTrail.Name = "ArrowGlowTrail"
	glowTrail.Attachment0 = glowAtt0
	glowTrail.Attachment1 = glowAtt1
	glowTrail.Lifetime = 0.6
	glowTrail.MinLength = 0.01
	glowTrail.LightEmission = 0.05
	glowTrail.Brightness = 0.5
	glowTrail.FaceCamera = true
	glowTrail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 230, 235)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 205)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 170, 175)),
	})
	glowTrail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.3, 0.65),
		NumberSequenceKeypoint.new(0.7, 0.85),
		NumberSequenceKeypoint.new(1, 1),
	})
	glowTrail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.25, 1.2),
		NumberSequenceKeypoint.new(0.6, 1.8),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	glowTrail.Enabled = true
	glowTrail.Parent = shaft

	local tipEmitter = Instance.new("ParticleEmitter")
	tipEmitter.Name = "ArrowTipParticles"
	tipEmitter.Rate = 40
	tipEmitter.Lifetime = NumberRange.new(0.15, 0.35)
	tipEmitter.Speed = NumberRange.new(0.3, 1.5)
	tipEmitter.SpreadAngle = Vector2.new(15, 15)
	tipEmitter.LightEmission = 0.2
	tipEmitter.Brightness = 0.6
	tipEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 220, 225)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 190, 195)),
	})
	tipEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	tipEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	tipEmitter.RotSpeed = NumberRange.new(-90, 90)
	tipEmitter.Rotation = NumberRange.new(0, 360)
	tipEmitter.Parent = tip

	local glow = Instance.new("PointLight")
	glow.Name = "ArrowGlow"
	glow.Color = Color3.fromRGB(230, 230, 235)
	glow.Brightness = 0.8
	glow.Range = 5
	glow.Parent = tip

	return shaft
end

local function destroyVisual(arrowId)
	local visual = Controller._activeVisuals[arrowId]
	if not visual then
		return
	end

	for _, child in visual:GetDescendants() do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false
		end
		if child:IsA("Trail") then
			child.Enabled = false
		end
	end

	task.delay(0.2, function()
		if visual and visual.Parent then
			visual:Destroy()
		end
	end)

	Controller._activeVisuals[arrowId] = nil
end

function Controller:Start()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local Framework = require(Shared:WaitForChild("Framework"))

	local spawnRemote = Framework:GetRemote("SpawnProjectile")
	local destroyRemote = Framework:GetRemote("DestroyProjectile")

	spawnRemote.OnClientEvent:Connect(function(data)
		if not data or not data.arrowId then
			return
		end
		if data.ownerId == Players.LocalPlayer.UserId then
			return
		end

		local visual = createVisualArrow(data)
		Controller._activeVisuals[data.arrowId] = {
			model = visual,
			direction = data.direction,
			speed = data.speed or 120,
			elapsed = 0,
			maxLifetime = 4.0,
		}
	end)

	destroyRemote.OnClientEvent:Connect(function(arrowId)
		destroyVisual(arrowId)
	end)

	RunService.Heartbeat:Connect(function(dt)
		for arrowId, visualData in pairs(Controller._activeVisuals) do
			local model = visualData.model
			if not model or not model.Parent then
				Controller._activeVisuals[arrowId] = nil
				continue
			end

			visualData.elapsed += dt
			if visualData.elapsed > visualData.maxLifetime then
				destroyVisual(arrowId)
				continue
			end

			local moveStep = visualData.speed * dt
			local currentPos = model.Position
			local newPos = currentPos + visualData.direction * moveStep

			model.CFrame = buildArrowCFrame(newPos, visualData.direction)
			if model:FindFirstChild("Tip") then
				model.Tip.CFrame = model.CFrame * CFrame.new(0, 0, -(ARROW_LENGTH / 2 + ARROW_TIP_LENGTH / 2))
			end
			if model:FindFirstChild("Fletching") then
				model.Fletching.CFrame = model.CFrame * CFrame.new(0, 0, (ARROW_LENGTH / 2 + 0.05))
			end
		end
	end)

	Players.LocalPlayer.CharacterRemoving:Connect(function()
		for arrowId, visualData in pairs(Controller._activeVisuals) do
			if visualData.model and visualData.model.Parent then
				visualData.model:Destroy()
			end
		end
		Controller._activeVisuals = {}
	end)
end

return Controller
