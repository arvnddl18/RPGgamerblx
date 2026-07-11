local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Framework = require(Shared:WaitForChild("Framework"))

local Controllers = script.Parent:WaitForChild("Controllers")

-- 1. Register all controllers
for _, module in Controllers:GetDescendants() do
	if module:IsA("ModuleScript") then
		local controller = require(module)
		Framework:RegisterController(module.Name, controller)
	end
end

-- 2. Init all controllers
for _, controller in Framework:GetControllers() do
	if type(controller.Init) == "function" then
		controller:Init()
	end
end

-- 3. Start all controllers
for name, controller in Framework:GetControllers() do
	if type(controller.Start) == "function" then
		task.spawn(function()
			controller:Start()
		end)
	end
end

print("[SimpleRPG] Client Framework started successfully.")
