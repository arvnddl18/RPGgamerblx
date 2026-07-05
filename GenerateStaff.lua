local tool = Instance.new("Tool")
tool.Name = "Arcane Staff"
tool.RequiresHandle = true
tool.ToolTip = "A staff pulsing with ancient magic."

-- 1. Main Wooden Pole (Handle)
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.3, 6, 0.3)
handle.Material = Enum.Material.Wood
handle.Color = Color3.fromRGB(70, 45, 25)
handle.Shape = Enum.PartType.Cylinder
-- Cylinders lay flat by default on X axis, so size needs to be X=6, Y=0.3, Z=0.3
handle.Size = Vector3.new(6, 0.3, 0.3)
handle.Orientation = Vector3.new(0, 0, 90)
handle.Parent = tool

-- 2. Metal Base/Cap
local cap = Instance.new("Part")
cap.Name = "Cap"
cap.Size = Vector3.new(0.6, 0.4, 0.4)
cap.Shape = Enum.PartType.Cylinder
cap.Material = Enum.Material.Metal
cap.Color = Color3.fromRGB(200, 200, 150) -- Goldish
cap.CFrame = handle.CFrame * CFrame.new(-3, 0, 0)
cap.Orientation = Vector3.new(0, 0, 90)
cap.Parent = tool

local weld1 = Instance.new("WeldConstraint")
weld1.Part0 = handle
weld1.Part1 = cap
weld1.Parent = handle

-- 3. Headpiece (Claw holding the crystal)
local claw1 = Instance.new("Part")
claw1.Size = Vector3.new(0.2, 1.2, 0.2)
claw1.Material = Enum.Material.Metal
claw1.Color = Color3.fromRGB(200, 200, 150)
claw1.CFrame = handle.CFrame * CFrame.new(3.2, 0.3, 0) * CFrame.Angles(0, 0, math.rad(15))
claw1.Parent = tool

local weld2 = Instance.new("WeldConstraint")
weld2.Part0 = handle
weld2.Part1 = claw1
weld2.Parent = handle

local claw2 = Instance.new("Part")
claw2.Size = Vector3.new(0.2, 1.2, 0.2)
claw2.Material = Enum.Material.Metal
claw2.Color = Color3.fromRGB(200, 200, 150)
claw2.CFrame = handle.CFrame * CFrame.new(3.2, -0.3, 0) * CFrame.Angles(0, 0, math.rad(-15))
claw2.Parent = tool

local weld3 = Instance.new("WeldConstraint")
weld3.Part0 = handle
weld3.Part1 = claw2
weld3.Parent = handle

-- 4. Floating Magical Crystal
local crystal = Instance.new("Part")
crystal.Name = "Crystal"
crystal.Size = Vector3.new(0.8, 1.2, 0.8)
crystal.Material = Enum.Material.Neon
crystal.Color = Color3.fromRGB(150, 0, 255) -- Deep Purple
crystal.Shape = Enum.PartType.Ball
crystal.CFrame = handle.CFrame * CFrame.new(3.8, 0, 0)
crystal.Parent = tool

local weld4 = Instance.new("WeldConstraint")
weld4.Part0 = handle
weld4.Part1 = crystal
weld4.Parent = handle

-- 5. Light Source
local pointLight = Instance.new("PointLight")
pointLight.Color = Color3.fromRGB(180, 50, 255)
pointLight.Range = 12
pointLight.Brightness = 2
pointLight.Parent = crystal

-- 6. Magical Particle Emitter
local attachment = Instance.new("Attachment", crystal)
local particles = Instance.new("ParticleEmitter", attachment)
particles.Color = ColorSequence.new(Color3.fromRGB(150, 0, 255), Color3.fromRGB(255, 100, 255))
particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0)})
particles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
particles.Speed = NumberRange.new(0.5, 1)
particles.Lifetime = NumberRange.new(1, 2)
particles.Rate = 20
particles.EmissionDirection = Enum.NormalId.Top

-- Adjust Handle orientation so the character holds it correctly
-- Standard tools require the Handle to have a specific orientation.
-- Usually, characters hold the Handle pointing outwards along Z or up along Y depending on grip.
tool.Grip = CFrame.new(0, -1.5, 0) * CFrame.Angles(0, 0, math.pi/2)

-- Add to StarterPack
if game:GetService("StarterPack") then
	tool.Parent = game.StarterPack
else
	tool.Parent = workspace
end

print("Arcane Staff successfully generated!")
