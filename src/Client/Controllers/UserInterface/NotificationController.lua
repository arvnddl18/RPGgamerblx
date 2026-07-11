local Controller = {}

function Controller:Start()
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotificationUI = require(script.Parent.Parent.Parent.UI.Notification.NotificationUI)

local player = game:GetService("Players").LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local notificationUI = NotificationUI.new(player:WaitForChild("PlayerGui"))

remotes.Notification.OnClientEvent:Connect(function(message)
	if type(message) == "string" and message ~= "" then
		notificationUI:Show(message)
	end
end)

end

return Controller
