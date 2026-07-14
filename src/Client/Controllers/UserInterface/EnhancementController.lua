local Controller = {}

function Controller:Start()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local EnhancementUI = require(script.Parent.Parent.Parent.UI.Enhancement.EnhancementUI)
	local player = Players.LocalPlayer
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local ui = EnhancementUI.new(player:WaitForChild("PlayerGui"))
	local busy = false

	ui:OnApply(function(scrollId, targetUid)
		if busy or not remotes:FindFirstChild("ApplyEnhancement") then return end
		busy = true
		local invoked, ok, result = pcall(function()
			return remotes.ApplyEnhancement:InvokeServer(scrollId, targetUid)
		end)
		busy = false
		if not invoked then
			ui:ShowMessage("Enhancement request failed. Please try again.", true)
		elseif not ok then
			ui:ShowMessage((result and result.message) or "Enhancement could not be applied.", true)
		else
			remotes.RequestInventory:FireServer()
		end
	end)
	remotes.InventoryUpdated.OnClientEvent:Connect(function(inventory) ui:SetInventory(inventory) end)
	remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
		ui:SetGold(payload.gold or payload.coins or 0)
		ui:SetEquipped(payload.equipped or {})
	end)
	remotes.EnhancementResult.OnClientEvent:Connect(function() busy = false end)

	local openEvent = Instance.new("BindableEvent")
	openEvent.Name = "OpenEnhancementUI"
	openEvent.Parent = ui:GetScreenGui()
	openEvent.Event:Connect(function(targetUid) ui:Open(targetUid) end)
end

return Controller
