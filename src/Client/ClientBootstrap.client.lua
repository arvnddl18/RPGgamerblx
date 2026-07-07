local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

local Shared = ReplicatedStorage:WaitForChild("Shared")
require(Shared.Framework)

-- Controllers in Controllers/ are LocalScripts that self-start via *.client.lua suffix.
