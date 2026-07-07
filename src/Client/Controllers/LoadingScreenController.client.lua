local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Attempt to disable CoreGui loading screen if possible
pcall(function()
	StarterGui:SetCore("TopbarEnabled", false)
end)

local LoadingScreenUI = require(script.Parent.Parent.UI.Loading.LoadingScreenUI)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Initialize and display loading screen immediately
local loadingScreen = LoadingScreenUI.new(playerGui)

-- Wait for the RPGWorld to be generated
-- MapGeneratorService creates the RPG_World folder and then at the very end
-- the GameServer creates a SpawnLocation inside of it.
task.spawn(function()
	local rpgWorld = Workspace:WaitForChild("RPGWorld", 60)
	if not rpgWorld then
		-- Fallback if RPGWorld is named differently or doesn't generate
		rpgWorld = Workspace:WaitForChild("RPG_World", 60)
	end
	
	if rpgWorld then
		-- Wait for SpawnLocation which means generation is 100% complete
		rpgWorld:WaitForChild("SpawnLocation", 60)
	end
	
	-- Now that the server map is generated, let's render the UI Map!
	if loadingScreen and loadingScreen.subtitle then
		loadingScreen.subtitle.Text = "Rendering Terrain Map..."
	end
	
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local FastTravelConfig = require(Shared.Config.FastTravel)
	local WorldMapTerrainRenderer = require(script.Parent.Parent.UI.FastTravel.WorldMapTerrainRenderer)
	
	-- We pass 160 resolution to match FastTravelWorldMapUI
	WorldMapTerrainRenderer.GetTerrainLayer(FastTravelConfig.MapBounds, 160, function(layer)
		-- Give it a tiny bit of extra time to render visually
		task.wait(1)
		
		-- Re-enable topbar
		pcall(function()
			StarterGui:SetCore("TopbarEnabled", true)
		end)
		
		-- Fade out the loading screen smoothly
		loadingScreen:FadeOutAndDestroy()
	end)
end)
