local StatBar = require(script.Parent.Parent.HUD.StatBar)

local PartyUI = {}
PartyUI.__index = PartyUI

local function makeButton(parent, text, size, position, color)
	local btn = Instance.new("TextButton")
	btn.Size = size
	btn.Position = position
	btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 70)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.BorderSizePixel = 0
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	return btn
end

function PartyUI.new(playerGui)
	local self = setmetatable({}, PartyUI)
	self._memberRows = {}
	self._selectedUserId = nil
	self._localUserId = nil
	self._isLeader = false
	self._inParty = false

	self._onInvite = nil
	self._onLeave = nil
	self._onKick = nil
	self._onAcceptInvite = nil
	self._onDeclineInvite = nil

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PartyUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "PartyPanel"
	panel.Size = UDim2.new(0, 260, 0, 320)
	panel.Position = UDim2.new(0, 16, 0, 176)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui
	self._panel = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Position = UDim2.new(0, 8, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "Party (P)"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local memberList = Instance.new("ScrollingFrame")
	memberList.Name = "MemberList"
	memberList.Size = UDim2.new(1, -16, 0, 180)
	memberList.Position = UDim2.new(0, 8, 0, 40)
	memberList.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	memberList.BackgroundTransparency = 0.3
	memberList.BorderSizePixel = 0
	memberList.ScrollBarThickness = 4
	memberList.CanvasSize = UDim2.new(0, 0, 0, 0)
	memberList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	memberList.Parent = panel
	self._memberList = memberList

	local memberCorner = Instance.new("UICorner")
	memberCorner.CornerRadius = UDim.new(0, 6)
	memberCorner.Parent = memberList

	local memberLayout = Instance.new("UIListLayout")
	memberLayout.Padding = UDim.new(0, 4)
	memberLayout.SortOrder = Enum.SortOrder.LayoutOrder
	memberLayout.Parent = memberList

	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = "EmptyLabel"
	emptyLabel.Size = UDim2.new(1, -8, 0, 40)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Text = "No party members"
	emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
	emptyLabel.Font = Enum.Font.Gotham
	emptyLabel.TextSize = 12
	emptyLabel.Parent = memberList
	self._emptyLabel = emptyLabel

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, -16, 0, 18)
	statusLabel.Position = UDim2.new(0, 8, 0, 224)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = ""
	statusLabel.TextColor3 = Color3.fromRGB(180, 220, 180)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 11
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextWrapped = true
	statusLabel.Parent = panel
	self._statusLabel = statusLabel

	local inviteBtn = makeButton(panel, "Invite", UDim2.new(0.32, -4, 0, 28), UDim2.new(0, 8, 1, -36))
	self._inviteBtn = inviteBtn
	inviteBtn.MouseButton1Click:Connect(function()
		self:SetInvitePanelVisible(not self._invitePanel.Visible)
	end)

	local leaveBtn = makeButton(panel, "Leave", UDim2.new(0.32, -4, 0, 28), UDim2.new(0.34, 0, 1, -36), Color3.fromRGB(120, 50, 50))
	self._leaveBtn = leaveBtn
	leaveBtn.MouseButton1Click:Connect(function()
		if self._onLeave then
			self._onLeave()
		end
	end)

	local closeBtn = makeButton(panel, "Close", UDim2.new(0.32, -4, 0, 28), UDim2.new(0.68, -4, 1, -36), Color3.fromRGB(60, 60, 80))
	closeBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	local invitePanel = Instance.new("Frame")
	invitePanel.Name = "InvitePanel"
	invitePanel.Size = UDim2.new(0, 240, 0, 280)
	invitePanel.Position = UDim2.new(0, 280, 0, 176)
	invitePanel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	invitePanel.BackgroundTransparency = 0.1
	invitePanel.BorderSizePixel = 0
	invitePanel.Visible = false
	invitePanel.Parent = screenGui
	self._invitePanel = invitePanel

	local inviteCorner = Instance.new("UICorner")
	inviteCorner.CornerRadius = UDim.new(0, 8)
	inviteCorner.Parent = invitePanel

	local inviteTitle = Instance.new("TextLabel")
	inviteTitle.Size = UDim2.new(1, -16, 0, 24)
	inviteTitle.Position = UDim2.new(0, 8, 0, 8)
	inviteTitle.BackgroundTransparency = 1
	inviteTitle.Text = "Invite Player"
	inviteTitle.TextColor3 = Color3.new(1, 1, 1)
	inviteTitle.Font = Enum.Font.GothamBold
	inviteTitle.TextSize = 14
	inviteTitle.TextXAlignment = Enum.TextXAlignment.Left
	inviteTitle.Parent = invitePanel

	local usernameBox = Instance.new("TextBox")
	usernameBox.Name = "UsernameBox"
	usernameBox.Size = UDim2.new(1, -16, 0, 28)
	usernameBox.Position = UDim2.new(0, 8, 0, 36)
	usernameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	usernameBox.Text = ""
	usernameBox.PlaceholderText = "Type username..."
	usernameBox.TextColor3 = Color3.new(1, 1, 1)
	usernameBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 160)
	usernameBox.Font = Enum.Font.Gotham
	usernameBox.TextSize = 12
	usernameBox.ClearTextOnFocus = false
	usernameBox.Parent = invitePanel
	self._usernameBox = usernameBox

	local usernameCorner = Instance.new("UICorner")
	usernameCorner.CornerRadius = UDim.new(0, 6)
	usernameCorner.Parent = usernameBox

	local playerList = Instance.new("ScrollingFrame")
	playerList.Name = "PlayerList"
	playerList.Size = UDim2.new(1, -16, 0, 160)
	playerList.Position = UDim2.new(0, 8, 0, 72)
	playerList.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	playerList.BackgroundTransparency = 0.3
	playerList.BorderSizePixel = 0
	playerList.ScrollBarThickness = 4
	playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
	playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playerList.Parent = invitePanel
	self._playerList = playerList

	local playerListCorner = Instance.new("UICorner")
	playerListCorner.CornerRadius = UDim.new(0, 6)
	playerListCorner.Parent = playerList

	local playerLayout = Instance.new("UIListLayout")
	playerLayout.Padding = UDim.new(0, 4)
	playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playerLayout.Parent = playerList

	self._playerButtons = {}

	local sendInviteBtn = makeButton(invitePanel, "Send Invite", UDim2.new(1, -16, 0, 30), UDim2.new(0, 8, 1, -38), Color3.fromRGB(50, 100, 70))
	sendInviteBtn.MouseButton1Click:Connect(function()
		if self._onInvite then
			self._onInvite(self._selectedUserId, usernameBox.Text)
		end
	end)

	local inviteCloseBtn = makeButton(invitePanel, "Cancel", UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 1, -72), Color3.fromRGB(60, 60, 80))
	inviteCloseBtn.MouseButton1Click:Connect(function()
		self:SetInvitePanelVisible(false)
	end)

	local inviteToast = Instance.new("Frame")
	inviteToast.Name = "InviteToast"
	inviteToast.Size = UDim2.new(0, 320, 0, 72)
	inviteToast.Position = UDim2.new(0.5, -160, 0, 120)
	inviteToast.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	inviteToast.BackgroundTransparency = 0.1
	inviteToast.BorderSizePixel = 0
	inviteToast.Visible = false
	inviteToast.Parent = screenGui
	self._inviteToast = inviteToast

	local toastCorner = Instance.new("UICorner")
	toastCorner.CornerRadius = UDim.new(0, 8)
	toastCorner.Parent = inviteToast

	local toastLabel = Instance.new("TextLabel")
	toastLabel.Size = UDim2.new(1, -16, 0, 32)
	toastLabel.Position = UDim2.new(0, 8, 0, 8)
	toastLabel.BackgroundTransparency = 1
	toastLabel.Text = "Party invite"
	toastLabel.TextColor3 = Color3.new(1, 1, 1)
	toastLabel.Font = Enum.Font.GothamBold
	toastLabel.TextSize = 14
	toastLabel.TextXAlignment = Enum.TextXAlignment.Left
	toastLabel.Parent = inviteToast
	self._toastLabel = toastLabel

	local acceptBtn = makeButton(inviteToast, "Accept", UDim2.new(0.45, -8, 0, 24), UDim2.new(0, 8, 1, -32), Color3.fromRGB(50, 120, 70))
	acceptBtn.MouseButton1Click:Connect(function()
		if self._pendingInviteFromUserId and self._onAcceptInvite then
			self._onAcceptInvite(self._pendingInviteFromUserId)
		end
		self:HideInviteToast()
	end)

	local declineBtn = makeButton(inviteToast, "Decline", UDim2.new(0.45, -8, 0, 24), UDim2.new(0.55, 0, 1, -32), Color3.fromRGB(120, 50, 50))
	declineBtn.MouseButton1Click:Connect(function()
		if self._pendingInviteFromUserId and self._onDeclineInvite then
			self._onDeclineInvite(self._pendingInviteFromUserId)
		end
		self:HideInviteToast()
	end)

	self._pendingInviteFromUserId = nil

	return self
end

function PartyUI:OnInvite(callback)
	self._onInvite = callback
end

function PartyUI:OnLeave(callback)
	self._onLeave = callback
end

function PartyUI:OnKick(callback)
	self._onKick = callback
end

function PartyUI:OnAcceptInvite(callback)
	self._onAcceptInvite = callback
end

function PartyUI:OnDeclineInvite(callback)
	self._onDeclineInvite = callback
end

function PartyUI:SetVisible(visible)
	self._panel.Visible = visible
	if not visible then
		self:SetInvitePanelVisible(false)
	end
end

function PartyUI:SetInvitePanelVisible(visible)
	self._invitePanel.Visible = visible
	if visible and self._onRefreshPlayers then
		self._onRefreshPlayers()
	end
end

function PartyUI:OnRefreshPlayers(callback)
	self._onRefreshPlayers = callback
end

function PartyUI:IsInvitePanelOpen()
	return self._invitePanel.Visible
end

function PartyUI:ShowStatusMessage(message, isError)
	self._statusLabel.Text = message or ""
	self._statusLabel.TextColor3 = isError and Color3.fromRGB(220, 120, 120) or Color3.fromRGB(180, 220, 180)
end

function PartyUI:ShowInviteToast(fromUserId, fromName)
	self._pendingInviteFromUserId = fromUserId
	self._toastLabel.Text = fromName .. " invited you to their party"
	self._inviteToast.Visible = true
end

function PartyUI:HideInviteToast()
	self._pendingInviteFromUserId = nil
	self._inviteToast.Visible = false
end

function PartyUI:ClearMemberRows()
	for _, row in self._memberRows do
		row.frame:Destroy()
	end
	self._memberRows = {}
end

function PartyUI:UpdateMemberRow(memberData, isLeader, showKick)
	local userId = memberData.userId
	local row = self._memberRows[userId]

	if not row then
		local frame = Instance.new("Frame")
		frame.Name = "Member_" .. userId
		frame.Size = UDim2.new(1, -8, 0, 52)
		frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
		frame.BorderSizePixel = 0
		frame.Parent = self._memberList

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = frame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, showKick and -56 or -8, 0, 16)
		nameLabel.Position = UDim2.new(0, 6, 0, 4)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 11
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = frame

		local hpBar = StatBar.new(frame, {
			name = "HP",
			position = UDim2.new(0, 6, 0, 22),
			size = UDim2.new(1, showKick and -62 or -12, 0, 14),
			fillColor = Color3.fromRGB(220, 60, 60),
			textSize = 10,
		})

		local kickBtn = makeButton(frame, "X", UDim2.new(0, 24, 0, 24), UDim2.new(1, -30, 0, 4), Color3.fromRGB(120, 50, 50))
		kickBtn.Visible = showKick
		kickBtn.MouseButton1Click:Connect(function()
			if self._onKick then
				self._onKick(userId)
			end
		end)

		row = {
			frame = frame,
			nameLabel = nameLabel,
			hpBar = hpBar,
			kickBtn = kickBtn,
		}
		self._memberRows[userId] = row
	end

	local classText = memberData.classId or "?"
	local leaderPrefix = isLeader and "[L] " or ""
	row.nameLabel.Text = string.format("%s%s  Lv.%d (%s)", leaderPrefix, memberData.displayName, memberData.level, classText)
	row.hpBar:Update(memberData.hp, memberData.maxHp)
	row.kickBtn.Visible = showKick and userId ~= self._localUserId
end

function PartyUI:Update(partyPayload, localUserId)
	self._localUserId = localUserId
	self:ClearMemberRows()

	if not partyPayload or not partyPayload.members or #partyPayload.members == 0 then
		self._inParty = false
		self._isLeader = false
		self._emptyLabel.Visible = true
		self._leaveBtn.Visible = false
		self._inviteBtn.Visible = true
		return
	end

	self._inParty = true
	self._isLeader = partyPayload.leaderUserId == localUserId
	self._emptyLabel.Visible = false
	self._leaveBtn.Visible = true
	self._inviteBtn.Visible = self._isLeader or not self._inParty

	for _, memberData in partyPayload.members do
		local isLeader = memberData.userId == partyPayload.leaderUserId
		local showKick = self._isLeader and memberData.userId ~= localUserId
		self:UpdateMemberRow(memberData, isLeader, showKick)
	end
end

function PartyUI:RefreshPlayerList(players, localPlayer)
	for _, btn in self._playerButtons do
		btn:Destroy()
	end
	self._playerButtons = {}
	self._selectedUserId = nil

	for _, otherPlayer in players do
		if otherPlayer ~= localPlayer then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -8, 0, 28)
			btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
			btn.Text = otherPlayer.DisplayName .. " (@" .. otherPlayer.Name .. ")"
			btn.TextColor3 = Color3.fromRGB(200, 200, 220)
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 11
			btn.BorderSizePixel = 0
			btn.Parent = self._playerList

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = btn

			btn.MouseButton1Click:Connect(function()
				self._selectedUserId = otherPlayer.UserId
				self._usernameBox.Text = otherPlayer.Name
				for _, otherBtn in self._playerButtons do
					otherBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
				end
				btn.BackgroundColor3 = Color3.fromRGB(60, 80, 110)
			end)

			table.insert(self._playerButtons, btn)
		end
	end
end

return PartyUI
