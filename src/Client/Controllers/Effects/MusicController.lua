local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local MusicController = {}

function MusicController:Init()
	task.spawn(function()
		self:Start8DMusic()
	end)
end

function MusicController:Start8DMusic()
	local audioFolder = Workspace:WaitForChild("Audio", 10)
	if not audioFolder then return end
	
	local songNames = {"Camelot", "Camelot2", "Camelot3", "Camelot4"}
	local songs = {}
	
	-- Create an orbiting part for the 8D effect
	local orbitPart = Instance.new("Part")
	orbitPart.Name = "MusicOrbitPart"
	orbitPart.Transparency = 1
	orbitPart.CanCollide = false
	orbitPart.Anchored = true
	orbitPart.Size = Vector3.new(1, 1, 1)
	orbitPart.Parent = Workspace
	
	-- 1. Ambient Background Music Group (-23 LUFS equivalent)
	local ambientGroup = Instance.new("SoundGroup")
	ambientGroup.Name = "ASMR8DGroup_Ambient"
	ambientGroup.Volume = 0.45 -- Soft, ambient volume
	ambientGroup.Parent = game:GetService("SoundService")
	
	local ambientEq = Instance.new("EqualizerSoundEffect")
	ambientEq.HighGain = -8 -- Highly muted highs for background
	ambientEq.MidGain = 0
	ambientEq.LowGain = 2
	ambientEq.Parent = ambientGroup
	
	local ambientReverb = Instance.new("ReverbSoundEffect")
	ambientReverb.DecayTime = 2.0
	ambientReverb.Density = 1.0
	ambientReverb.DryLevel = -5
	ambientReverb.WetLevel = -10 -- Deep reverb
	ambientReverb.Parent = ambientGroup

	-- 2. SFX Group for Combat/UI (-15 to -10 LUFS equivalent)
	local sfxGroup = Instance.new("SoundGroup")
	sfxGroup.Name = "ASMR8DGroup_SFX"
	sfxGroup.Volume = 1.2 -- Punchier baseline volume
	sfxGroup.Parent = game:GetService("SoundService")

	local sfxEq = Instance.new("EqualizerSoundEffect")
	sfxEq.HighGain = -2 -- Crisp but not harsh
	sfxEq.MidGain = 2 -- Warm mids
	sfxEq.LowGain = 5 -- Punchy bass
	sfxEq.Parent = sfxGroup

	local sfxCompressor = Instance.new("CompressorSoundEffect")
	sfxCompressor.Threshold = -12
	sfxCompressor.Ratio = 4
	sfxCompressor.Attack = 0.01
	sfxCompressor.Release = 0.1
	sfxCompressor.GainMakeup = 3 -- Adds punch to transients
	sfxCompressor.Parent = sfxGroup

	local sfxReverb = Instance.new("ReverbSoundEffect")
	sfxReverb.DecayTime = 0.5
	sfxReverb.Density = 0.5
	sfxReverb.DryLevel = 0
	sfxReverb.WetLevel = -20 -- Very subtle so SFX don't get muddy
	sfxReverb.Parent = sfxGroup
	
	for _, name in ipairs(songNames) do
		local originalSound = audioFolder:FindFirstChild(name)
		if originalSound and originalSound:IsA("Sound") then
			local s = originalSound:Clone()
			s.Parent = orbitPart
			s.SoundGroup = ambientGroup
			s.Volume = 0.35 -- Keep background music quiet
			s.Looped = false
			-- Ensure it's 3D
			s.RollOffMaxDistance = 150
			s.RollOffMinDistance = 10
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			table.insert(songs, s)
		end
	end
	
	if #songs == 0 then return end
	
	local currentSongIndex = 1
	
	-- 8D Orbit logic
	local angle = 0
	local orbitRadius = 6 -- Studs away from the head
	local orbitSpeed = 1.2 -- Radians per second
	
	RunService.RenderStepped:Connect(function(dt)
		local camera = Workspace.CurrentCamera
		if not camera then return end
		
		angle = (angle + orbitSpeed * dt) % (math.pi * 2)
		local offset = Vector3.new(math.cos(angle) * orbitRadius, 0, math.sin(angle) * orbitRadius)
		orbitPart.CFrame = camera.CFrame * CFrame.new(offset)
	end)
	
	-- Loop songs
	while true do
		local currentSong = songs[currentSongIndex]
		currentSong:Play()
		currentSong.Ended:Wait()
		
		currentSongIndex = currentSongIndex + 1
		if currentSongIndex > #songs then
			currentSongIndex = 1
		end
	end
end

function MusicController:Play8DASMR(soundName)
	local workspace = game:GetService("Workspace")
	local audioFolder = workspace:FindFirstChild("Audio")
	local originalSound = audioFolder and audioFolder:FindFirstChild(soundName)
	if originalSound and originalSound:IsA("Sound") then
		local orbitPart = workspace:FindFirstChild("MusicOrbitPart")
		if orbitPart then
			local s = originalSound:Clone()
			s.Parent = orbitPart
			s.RollOffMaxDistance = 150
			s.RollOffMinDistance = 10
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			
			local soundGroup = game:GetService("SoundService"):FindFirstChild("ASMR8DGroup_SFX")
			if soundGroup then
				s.SoundGroup = soundGroup
			end
			
			s:Play()
			game:GetService("Debris"):AddItem(s, math.max(s.TimeLength, 2))
		else
			originalSound:Play()
		end
	end
end
function MusicController:PlayLooped8DASMR(soundName)
	local workspace = game:GetService("Workspace")
	local audioFolder = workspace:FindFirstChild("Audio")
	local originalSound = audioFolder and audioFolder:FindFirstChild(soundName)
	if originalSound and originalSound:IsA("Sound") then
		local orbitPart = workspace:FindFirstChild("MusicOrbitPart")
		if orbitPart then
			local s = originalSound:Clone()
			s.Parent = orbitPart
			s.Looped = true
			s.RollOffMaxDistance = 150
			s.RollOffMinDistance = 10
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			
			local soundGroup = game:GetService("SoundService"):FindFirstChild("ASMR8DGroup_SFX")
			if soundGroup then
				s.SoundGroup = soundGroup
			end
			
			s:Play()
			return s -- caller is responsible for :Stop() and :Destroy()
		end
	end
	return nil
end

return MusicController
