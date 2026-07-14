local TweenService = game:GetService("TweenService")

local PartyUI = {}
PartyUI.__index = PartyUI

local COLORS = {
	overlay = Color3.fromRGB(0, 0, 0),
	panel = Color3.fromRGB(28, 22, 18),
	panelInner = Color3.fromRGB(36, 30, 24),
	border = Color3.fromRGB(180, 140, 55),
	borderDim = Color3.fromRGB(80, 65, 35),
	text = Color3.fromRGB(245, 235, 215),
	textDim = Color3.fromRGB(180, 170, 150),
	slot = Color3.fromRGB(35, 28, 23),
	slotHover = Color3.fromRGB(50, 42, 34),
	slotSelected = Color3.fromRGB(60, 50, 40),
	gold = Color3.fromRGB(255, 215, 65),
	danger = Color3.fromRGB(180, 70, 60),
	success = Color3.fromRGB(85, 160, 100),
	blue = Color3.fromRGB(100, 150, 200),
}

local FONTS = { Header = Enum.Font.FredokaOne, Body = Enum.Font.Ubuntu, Bold = Enum.Font.GothamBold }

local function corner(parent, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius or 8)
	value.Parent = parent
end

local function stroke(parent, color, thickness)
	local value = Instance.new("UIStroke")
	value.Color = color or COLORS.borderDim
	value.Thickness = thickness or 1.5
	value.Parent = parent
	return value
end

local function button(parent, text, color)
	local value = Instance.new("TextButton")
	value.BackgroundColor3 = color or COLORS.slot
	value.BorderSizePixel = 0
	value.Text = text
	value.TextColor3 = COLORS.text
	value.TextTruncate = Enum.TextTruncate.AtEnd
	value.Font = FONTS.Header
	value.TextSize = 15
	value.AutoButtonColor = false
	value.Parent = parent
	corner(value, 8)
	stroke(value, color == COLORS.danger and Color3.fromRGB(100, 30, 20) or COLORS.borderDim, 2)
	value.MouseEnter:Connect(function()
		TweenService:Create(value, TweenInfo.new(0.16), { BackgroundColor3 = color == COLORS.danger and Color3.fromRGB(220, 90, 80) or COLORS.slotHover }):Play()
	end)
	value.MouseLeave:Connect(function()
		TweenService:Create(value, TweenInfo.new(0.16), { BackgroundColor3 = color or COLORS.slot }):Play()
	end)
	return value
end

local function pane(parent, name, size, position)
	local value = Instance.new("Frame")
	value.Name = name
	value.Size = size
	value.Position = position
	value.BackgroundColor3 = COLORS.panelInner
	value.BorderSizePixel = 0
	value.Parent = parent
	corner(value, 10)
	stroke(value, COLORS.borderDim, 2)
	return value
end

function PartyUI.new(playerGui)
	local self = setmetatable({}, PartyUI)
	self._memberRows = {}
	self._playerButtons = {}
	self._selectedUserId = nil
	self._localUserId = nil
	self._isLeader = false

	local gui = Instance.new("ScreenGui")
	gui.Name = "PartyUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 100
	gui.Parent = playerGui
	self._screenGui = gui

	local overlay = Instance.new("TextButton")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = COLORS.overlay
	overlay.BackgroundTransparency = 0.5
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.Visible = false
	overlay.Parent = gui
	self._overlay = overlay

	local root = Instance.new("Frame")
	root.Name = "PartyPanel"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromScale(0.76, 0.72)
	root.BackgroundColor3 = COLORS.panel
	root.BorderSizePixel = 0
	root.Active = true
	root.Visible = false
	root.Parent = gui
	corner(root, 12)
	stroke(root, COLORS.border, 3)
	self._panel = root
	local constraint = Instance.new("UISizeConstraint")
	constraint.MinSize = Vector2.new(520, 360)
	constraint.MaxSize = Vector2.new(1180, 760)
	constraint.Parent = root

	local close = button(root, "×", COLORS.danger)
	close.Size = UDim2.fromOffset(40, 40)
	close.Position = UDim2.new(1, -50, 0, 10)
	close.TextSize = 22
	close.ZIndex = 5
	close.MouseButton1Click:Connect(function() self:SetVisible(false) end)
	overlay.MouseButton1Click:Connect(function() self:SetVisible(false) end)

	local listPane = pane(root, "MemberPane", UDim2.new(0.38, -16, 1, -24), UDim2.new(0, 12, 0, 12))
	local listTitle = Instance.new("TextLabel")
	listTitle.Size = UDim2.new(1, -24, 0, 40)
	listTitle.Position = UDim2.new(0, 12, 0, 12)
	listTitle.BackgroundTransparency = 1
	listTitle.Text = "PARTY"
	listTitle.TextColor3 = COLORS.gold
	listTitle.Font = FONTS.Header
	listTitle.TextSize = 22
	listTitle.TextXAlignment = Enum.TextXAlignment.Left
	listTitle.Parent = listPane

	local memberList = Instance.new("ScrollingFrame")
	memberList.Name = "MemberList"
	memberList.Size = UDim2.new(1, -24, 1, -78)
	memberList.Position = UDim2.new(0, 12, 0, 58)
	memberList.BackgroundTransparency = 1
	memberList.BorderSizePixel = 0
	memberList.ScrollBarThickness = 8
	memberList.ScrollBarImageColor3 = COLORS.gold
	memberList.CanvasSize = UDim2.new()
	memberList.Parent = listPane
	self._memberList = memberList
	local memberLayout = Instance.new("UIListLayout")
	memberLayout.Padding = UDim.new(0, 9)
	memberLayout.Parent = memberList
	memberLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		memberList.CanvasSize = UDim2.new(0, 0, 0, memberLayout.AbsoluteContentSize.Y + 10)
	end)

	local empty = Instance.new("TextLabel")
	empty.Name = "EmptyLabel"
	empty.Size = UDim2.new(1, 0, 0, 42)
	empty.BackgroundTransparency = 1
	empty.Text = "No party members yet."
	empty.TextColor3 = COLORS.textDim
	empty.Font = FONTS.Body
	empty.TextSize = 16
	empty.Parent = memberList
	self._emptyLabel = empty

	local detailPane = pane(root, "DetailPane", UDim2.new(0.62, -20, 1, -24), UDim2.new(0.38, 4, 0, 12))
	self._detailPane = detailPane
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -82, 0, 40)
	title.Position = UDim2.new(0, 16, 0, 12)
	title.BackgroundTransparency = 1
	title.Text = "PARTY MANAGEMENT"
	title.TextColor3 = COLORS.gold
	title.Font = FONTS.Header
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = detailPane

	local status = Instance.new("TextLabel")
	status.Size = UDim2.new(1, -32, 0, 42)
	status.Position = UDim2.new(0, 16, 0, 56)
	status.BackgroundTransparency = 1
	status.Text = "Invite nearby players and adventure together."
	status.TextColor3 = COLORS.textDim
	status.Font = FONTS.Body
	status.TextSize = 16
	status.TextWrapped = true
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextYAlignment = Enum.TextYAlignment.Top
	status.Parent = detailPane
	self._statusLabel = status

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, -32, 0, 2)
	divider.Position = UDim2.new(0, 16, 0, 108)
	divider.BackgroundColor3 = COLORS.borderDim
	divider.BorderSizePixel = 0
	divider.Parent = detailPane

	local idleLabel = Instance.new("TextLabel")
	idleLabel.Size = UDim2.new(1, -32, 0, 80)
	idleLabel.Position = UDim2.new(0, 16, 0, 128)
	idleLabel.BackgroundTransparency = 1
	idleLabel.Text = "Create a party to invite other players.\nParty members appear in the list on the left."
	idleLabel.TextColor3 = COLORS.textDim
	idleLabel.Font = FONTS.Body
	idleLabel.TextSize = 17
	idleLabel.TextWrapped = true
	idleLabel.TextXAlignment = Enum.TextXAlignment.Left
	idleLabel.TextYAlignment = Enum.TextYAlignment.Top
	idleLabel.Parent = detailPane
	self._idleLabel = idleLabel

	local invitePanel = Instance.new("Frame")
	invitePanel.Name = "InvitePanel"
	invitePanel.Size = UDim2.new(1, -32, 1, -188)
	invitePanel.Position = UDim2.new(0, 16, 0, 118)
	invitePanel.BackgroundTransparency = 1
	invitePanel.Visible = false
	invitePanel.Parent = detailPane
	self._invitePanel = invitePanel

	local inviteTitle = Instance.new("TextLabel")
	inviteTitle.Size = UDim2.new(1, 0, 0, 24)
	inviteTitle.BackgroundTransparency = 1
	inviteTitle.Text = "INVITE A PLAYER"
	inviteTitle.TextColor3 = COLORS.text
	inviteTitle.Font = FONTS.Header
	inviteTitle.TextSize = 17
	inviteTitle.TextXAlignment = Enum.TextXAlignment.Left
	inviteTitle.Parent = invitePanel

	local username = Instance.new("TextBox")
	username.Name = "UsernameBox"
	username.Size = UDim2.new(1, 0, 0, 38)
	username.Position = UDim2.new(0, 0, 0, 31)
	username.BackgroundColor3 = COLORS.slot
	username.BorderSizePixel = 0
	username.PlaceholderText = "Type a username or choose a player below"
	username.PlaceholderColor3 = COLORS.textDim
	username.TextColor3 = COLORS.text
	username.TextTruncate = Enum.TextTruncate.AtEnd
	username.Font = FONTS.Body
	username.TextSize = 15
	username.ClearTextOnFocus = false
	username.Parent = invitePanel
	corner(username, 7)
	stroke(username, COLORS.borderDim, 1.5)
	self._usernameBox = username

	local playerList = Instance.new("ScrollingFrame")
	playerList.Name = "PlayerList"
	playerList.Size = UDim2.new(1, 0, 1, -122)
	playerList.Position = UDim2.new(0, 0, 0, 80)
	playerList.BackgroundTransparency = 1
	playerList.BorderSizePixel = 0
	playerList.ScrollBarThickness = 8
	playerList.ScrollBarImageColor3 = COLORS.gold
	playerList.CanvasSize = UDim2.new()
	playerList.Parent = invitePanel
	self._playerList = playerList
	local playerLayout = Instance.new("UIListLayout")
	playerLayout.Padding = UDim.new(0, 7)
	playerLayout.Parent = playerList
	playerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		playerList.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 8)
	end)

	local footer = Instance.new("Frame")
	footer.Size = UDim2.new(1, -32, 0, 48)
	footer.Position = UDim2.new(0, 16, 1, -64)
	footer.BackgroundTransparency = 1
	footer.Parent = detailPane
	local invite = button(footer, "INVITE PLAYER", COLORS.success)
	invite.Size = UDim2.new(0.48, 0, 1, 0)
	invite.MouseButton1Click:Connect(function()
		if self._invitePanel.Visible then
			if self._onInvite then self._onInvite(self._selectedUserId, username.Text) end
		else
			self:SetInvitePanelVisible(true)
		end
	end)
	self._inviteBtn = invite
	local leave = button(footer, "LEAVE PARTY", COLORS.danger)
	leave.Size = UDim2.new(0.48, 0, 1, 0)
	leave.Position = UDim2.new(0.52, 0, 0, 0)
	leave.MouseButton1Click:Connect(function() if self._onLeave then self._onLeave() end end)
	self._leaveBtn = leave

	local toast = Instance.new("Frame")
	toast.Name = "InviteToast"
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.fromScale(0.5, 0.08)
	toast.Size = UDim2.fromScale(0.34, 0.13)
	toast.BackgroundColor3 = COLORS.panel
	toast.BorderSizePixel = 0
	toast.Visible = false
	toast.Parent = gui
	corner(toast, 10)
	stroke(toast, COLORS.border, 2)
	self._inviteToast = toast
	local toastConstraint = Instance.new("UISizeConstraint")
	toastConstraint.MinSize = Vector2.new(300, 90)
	toastConstraint.MaxSize = Vector2.new(500, 130)
	toastConstraint.Parent = toast
	local toastLabel = Instance.new("TextLabel")
	toastLabel.Size = UDim2.new(1, -24, 0, 38)
	toastLabel.Position = UDim2.new(0, 12, 0, 8)
	toastLabel.BackgroundTransparency = 1
	toastLabel.TextColor3 = COLORS.text
	toastLabel.Font = FONTS.Body
	toastLabel.TextSize = 15
	toastLabel.TextWrapped = true
	toastLabel.TextXAlignment = Enum.TextXAlignment.Left
	toastLabel.Parent = toast
	self._toastLabel = toastLabel
	local accept = button(toast, "ACCEPT", COLORS.success)
	accept.Size = UDim2.new(0.48, -6, 0, 28)
	accept.Position = UDim2.new(0, 12, 1, -36)
	accept.TextSize = 13
	accept.MouseButton1Click:Connect(function()
		if self._pendingInviteFromUserId and self._onAcceptInvite then self._onAcceptInvite(self._pendingInviteFromUserId) end
		self:HideInviteToast()
	end)
	local decline = button(toast, "DECLINE", COLORS.danger)
	decline.Size = UDim2.new(0.48, -6, 0, 28)
	decline.Position = UDim2.new(0.52, -6, 1, -36)
	decline.TextSize = 13
	decline.MouseButton1Click:Connect(function()
		if self._pendingInviteFromUserId and self._onDeclineInvite then self._onDeclineInvite(self._pendingInviteFromUserId) end
		self:HideInviteToast()
	end)

	return self
end

function PartyUI:OnInvite(callback) self._onInvite = callback end
function PartyUI:OnLeave(callback) self._onLeave = callback end
function PartyUI:OnKick(callback) self._onKick = callback end
function PartyUI:OnAcceptInvite(callback) self._onAcceptInvite = callback end
function PartyUI:OnDeclineInvite(callback) self._onDeclineInvite = callback end
function PartyUI:OnRefreshPlayers(callback) self._onRefreshPlayers = callback end

function PartyUI:SetVisible(visible)
	if visible then
		self._overlay.Visible = true
		self._panel.Visible = true
		self._panel.Size = UDim2.fromScale(0.71, 0.67)
		TweenService:Create(self._panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.76, 0.72) }):Play()
	else
		self._overlay.Visible = false
		self._panel.Visible = false
		self:SetInvitePanelVisible(false)
	end
end

function PartyUI:SetInvitePanelVisible(visible)
	self._invitePanel.Visible = visible
	self._idleLabel.Visible = not visible
	if visible and self._onRefreshPlayers then self._onRefreshPlayers() end
end
function PartyUI:IsInvitePanelOpen() return self._invitePanel.Visible end
function PartyUI:ShowStatusMessage(message, isError)
	self._statusLabel.Text = message or ""
	self._statusLabel.TextColor3 = isError and COLORS.danger or COLORS.success
end
function PartyUI:ShowInviteToast(fromUserId, fromName)
	self._pendingInviteFromUserId = fromUserId
	self._toastLabel.Text = fromName .. " invited you to their party."
	self._inviteToast.Visible = true
end
function PartyUI:HideInviteToast() self._pendingInviteFromUserId = nil self._inviteToast.Visible = false end

function PartyUI:ClearMemberRows()
	for _, row in self._memberRows do row.frame:Destroy() end
	self._memberRows = {}
end

function PartyUI:UpdateMemberRow(memberData, isLeader, showKick)
	local userId = memberData.userId
	local row = Instance.new("Frame")
	row.Name = "Member_" .. userId
	row.Size = UDim2.new(1, 0, 0, 70)
	row.BackgroundColor3 = COLORS.slot
	row.BorderSizePixel = 0
	row.Parent = self._memberList
	corner(row, 8)
	stroke(row, isLeader and COLORS.border or COLORS.borderDim, isLeader and 2 or 1.5)
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, showKick and -54 or -20, 0, 24)
	name.Position = UDim2.new(0, 10, 0, 7)
	name.BackgroundTransparency = 1
	name.Text = (isLeader and "★ " or "") .. memberData.displayName .. "  Lv." .. tostring(memberData.level or 0) .. " (" .. (memberData.classId or "?") .. ")"
	name.TextColor3 = isLeader and COLORS.gold or COLORS.text
	name.Font = FONTS.Bold
	name.TextSize = 14
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = row
	local hpBack = Instance.new("Frame")
	hpBack.Size = UDim2.new(1, showKick and -58 or -20, 0, 17)
	hpBack.Position = UDim2.new(0, 10, 0, 39)
	hpBack.BackgroundColor3 = Color3.fromRGB(55, 35, 32)
	hpBack.BorderSizePixel = 0
	hpBack.Parent = row
	corner(hpBack, 5)
	local ratio = math.clamp((memberData.hp or 0) / math.max(memberData.maxHp or 1, 1), 0, 1)
	local hp = Instance.new("Frame")
	hp.Size = UDim2.new(ratio, 0, 1, 0)
	hp.BackgroundColor3 = COLORS.danger
	hp.BorderSizePixel = 0
	hp.Parent = hpBack
	corner(hp, 5)
	local hpText = Instance.new("TextLabel")
	hpText.Size = UDim2.fromScale(1, 1)
	hpText.BackgroundTransparency = 1
	hpText.Text = "HP " .. tostring(memberData.hp or 0) .. " / " .. tostring(memberData.maxHp or 0)
	hpText.TextColor3 = COLORS.text
	hpText.Font = FONTS.Bold
	hpText.TextSize = 10
	hpText.Parent = hpBack
	if showKick then
		local kick = button(row, "×", COLORS.danger)
		kick.Size = UDim2.fromOffset(28, 28)
		kick.Position = UDim2.new(1, -38, 0, 8)
		kick.TextSize = 17
		kick.MouseButton1Click:Connect(function() if self._onKick then self._onKick(userId) end end)
	end
	self._memberRows[userId] = { frame = row }
end

function PartyUI:Update(partyPayload, localUserId)
	self._localUserId = localUserId
	self:ClearMemberRows()
	local members = partyPayload and partyPayload.members
	if not members or #members == 0 then
		self._emptyLabel.Visible = true
		self._leaveBtn.Visible = false
		self._inviteBtn.Text = "CREATE PARTY"
		self._inviteBtn.Visible = true
		return
	end
	self._emptyLabel.Visible = false
	self._isLeader = partyPayload.leaderUserId == localUserId
	self._leaveBtn.Visible = true
	self._inviteBtn.Visible = self._isLeader
	self._inviteBtn.Text = "INVITE PLAYER"
	for _, memberData in members do
		self:UpdateMemberRow(memberData, memberData.userId == partyPayload.leaderUserId, self._isLeader and memberData.userId ~= localUserId)
	end
end

function PartyUI:RefreshPlayerList(players, localPlayer)
	for _, value in self._playerButtons do value:Destroy() end
	self._playerButtons = {}
	self._selectedUserId = nil
	for _, other in players do
		if other ~= localPlayer then
			local value = button(self._playerList, other.DisplayName .. " (@" .. other.Name .. ")", COLORS.slot)
			value.Size = UDim2.new(1, 0, 0, 38)
			value.Font = FONTS.Body
			value.TextSize = 14
			value.TextXAlignment = Enum.TextXAlignment.Left
			value.MouseButton1Click:Connect(function()
				self._selectedUserId = other.UserId
				self._usernameBox.Text = other.Name
				for _, item in self._playerButtons do item.BackgroundColor3 = COLORS.slot end
				value.BackgroundColor3 = COLORS.slotSelected
			end)
			table.insert(self._playerButtons, value)
		end
	end
end

return PartyUI
