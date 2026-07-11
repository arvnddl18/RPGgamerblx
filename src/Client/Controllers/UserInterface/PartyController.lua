local Controller = {}

function Controller:Start()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local PartyUI = require(script.Parent.Parent.Parent.UI.Party.PartyUI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hasSelectedClass = false
local partyVisible = false
local partyUI = PartyUI.new(player:WaitForChild("PlayerGui"))

local function refreshPlayerList()
	partyUI:RefreshPlayerList(Players:GetPlayers(), player)
end

local function resolveTargetUserId(selectedUserId, usernameText)
	if selectedUserId then
		return selectedUserId
	end

	local trimmed = string.gsub(usernameText or "", "^%s*(.-)%s*$", "%1")
	if trimmed == "" then
		return nil
	end

	for _, otherPlayer in Players:GetPlayers() do
		if string.lower(otherPlayer.Name) == string.lower(trimmed)
			or string.lower(otherPlayer.DisplayName) == string.lower(trimmed) then
			return otherPlayer.UserId
		end
	end

	return nil
end

partyUI:OnRefreshPlayers(refreshPlayerList)

partyUI:OnInvite(function(selectedUserId, usernameText)
	local targetUserId = resolveTargetUserId(selectedUserId, usernameText)
	if not targetUserId then
		partyUI:ShowStatusMessage("Enter a valid username or select a player.", true)
		return
	end

	if targetUserId == player.UserId then
		partyUI:ShowStatusMessage("You cannot invite yourself.", true)
		return
	end

	remotes.PartyInvite:FireServer(targetUserId)
end)

partyUI:OnLeave(function()
	remotes.PartyLeave:FireServer()
end)

partyUI:OnKick(function(targetUserId)
	remotes.PartyKick:FireServer(targetUserId)
end)

partyUI:OnAcceptInvite(function(fromUserId)
	remotes.PartyRespondInvite:FireServer(fromUserId, true)
end)

partyUI:OnDeclineInvite(function(fromUserId)
	remotes.PartyRespondInvite:FireServer(fromUserId, false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not hasSelectedClass then
		return
	end
	if input.KeyCode == Enum.KeyCode.P then
		partyVisible = not partyVisible
		partyUI:SetVisible(partyVisible)
		if partyVisible then
			refreshPlayerList()
		end
	end
end)

Players.PlayerAdded:Connect(function()
	if partyUI:IsInvitePanelOpen() then
		refreshPlayerList()
	end
end)

Players.PlayerRemoving:Connect(function()
	if partyUI:IsInvitePanelOpen() then
		refreshPlayerList()
	end
end)

remotes.StatsUpdated.OnClientEvent:Connect(function(payload)
	hasSelectedClass = payload.hasSelectedClass == true
	if not hasSelectedClass then
		partyVisible = false
		partyUI:SetVisible(false)
		partyUI:HideInviteToast()
	end
end)

remotes.PartyUpdated.OnClientEvent:Connect(function(partyPayload)
	partyUI:Update(partyPayload, player.UserId)
end)

remotes.PartyInviteReceived.OnClientEvent:Connect(function(data)
	if data and data.fromUserId and data.fromName then
		partyUI:ShowInviteToast(data.fromUserId, data.fromName)
	end
end)

remotes.PartyInviteResult.OnClientEvent:Connect(function(result)
	if result and result.message then
		partyUI:ShowStatusMessage(result.message, not result.success)
	end
end)

end

return Controller
