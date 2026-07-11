local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PartyConfig = require(Shared.Config.Party)

local PartyService = {}
PartyService._parties = {}
PartyService._playerToParty = {}
PartyService._pendingInvites = {}
PartyService._nextPartyId = 1
PartyService._playerData = nil
PartyService._remotes = nil

local function getPlayerByUserId(userId)
	return Players:GetPlayerByUserId(userId)
end

function PartyService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._remotes = Framework:GetRemotesFolder()

	Framework:GetRemote("PartyInvite")
	Framework:GetRemote("PartyInviteReceived")
	Framework:GetRemote("PartyRespondInvite")
	Framework:GetRemote("PartyLeave")
	Framework:GetRemote("PartyKick")
	Framework:GetRemote("PartyUpdated")
	Framework:GetRemote("PartyInviteResult")
end

function PartyService:GetPartyId(player)
	return self._playerToParty[player.UserId]
end

function PartyService:GetParty(player)
	local partyId = self:GetPartyId(player)
	if not partyId then
		return nil
	end
	return self._parties[partyId]
end

function PartyService:GetPartyMembers(player)
	local party = self:GetParty(player)
	if not party then
		return { player }
	end

	local members = {}
	for _, userId in party.memberUserIds do
		local member = getPlayerByUserId(userId)
		if member then
			table.insert(members, member)
		end
	end
	return members
end

function PartyService:AreInSameParty(player1, player2)
	if not player1 or not player2 then
		return false
	end
	if player1 == player2 then
		return true
	end

	local partyId1 = self._playerToParty[player1.UserId]
	local partyId2 = self._playerToParty[player2.UserId]
	return partyId1 ~= nil and partyId1 == partyId2
end

function PartyService:IsLeader(player)
	local party = self:GetParty(player)
	if not party then
		return false
	end
	return party.leaderUserId == player.UserId
end

function PartyService:BuildMemberSnapshot(member)
	local data = self._playerData:GetData(member)
	if not data then
		return {
			userId = member.UserId,
			displayName = member.DisplayName,
			hp = 0,
			maxHp = 1,
			mana = 0,
			maxMana = 1,
			level = 1,
			classId = nil,
		}
	end

	return {
		userId = member.UserId,
		displayName = member.DisplayName,
		hp = data.hp,
		maxHp = data.combatStats.maxHp,
		mana = data.mana,
		maxMana = data.combatStats.maxMana,
		level = data.level,
		classId = data.classId,
	}
end

function PartyService:BuildPartyPayload(partyId)
	local party = self._parties[partyId]
	if not party then
		return nil
	end

	local members = {}
	for _, userId in party.memberUserIds do
		local member = getPlayerByUserId(userId)
		if member then
			table.insert(members, self:BuildMemberSnapshot(member))
		end
	end

	return {
		partyId = partyId,
		leaderUserId = party.leaderUserId,
		members = members,
	}
end

function PartyService:ClearPartyForPlayer(player)
	self._playerToParty[player.UserId] = nil
	self._remotes.PartyUpdated:FireClient(player, nil)
end

function PartyService:BroadcastPartyUpdate(partyId)
	local party = self._parties[partyId]
	if not party then
		return
	end

	local payload = self:BuildPartyPayload(partyId)
	for _, userId in party.memberUserIds do
		local member = getPlayerByUserId(userId)
		if member then
			self._remotes.PartyUpdated:FireClient(member, payload)
		end
	end
end

function PartyService:OnMemberStatsChanged(player)
	local partyId = self._playerToParty[player.UserId]
	if partyId then
		self:BroadcastPartyUpdate(partyId)
	end
end

function PartyService:CreateParty(leader, newMember)
	local partyId = "party_" .. self._nextPartyId
	self._nextPartyId += 1

	self._parties[partyId] = {
		leaderUserId = leader.UserId,
		memberUserIds = { leader.UserId, newMember.UserId },
	}

	self._playerToParty[leader.UserId] = partyId
	self._playerToParty[newMember.UserId] = partyId
	self:BroadcastPartyUpdate(partyId)
end

function PartyService:AddMember(partyId, player)
	local party = self._parties[partyId]
	if not party then
		return false
	end

	table.insert(party.memberUserIds, player.UserId)
	self._playerToParty[player.UserId] = partyId
	self:BroadcastPartyUpdate(partyId)
	return true
end

function PartyService:DisbandParty(partyId)
	local party = self._parties[partyId]
	if not party then
		return
	end

	for _, userId in party.memberUserIds do
		self._playerToParty[userId] = nil
		local member = getPlayerByUserId(userId)
		if member then
			self._remotes.PartyUpdated:FireClient(member, nil)
		end
	end

	self._parties[partyId] = nil
end

function PartyService:PromoteLeader(partyId)
	local party = self._parties[partyId]
	if not party or #party.memberUserIds == 0 then
		return
	end

	party.leaderUserId = party.memberUserIds[1]
end

function PartyService:RemoveMember(player)
	local partyId = self._playerToParty[player.UserId]
	if not partyId then
		return
	end

	local party = self._parties[partyId]
	if not party then
		self._playerToParty[player.UserId] = nil
		return
	end

	local wasLeader = party.leaderUserId == player.UserId
	local newMemberUserIds = {}

	for _, userId in party.memberUserIds do
		if userId ~= player.UserId then
			table.insert(newMemberUserIds, userId)
		end
	end

	self._playerToParty[player.UserId] = nil
	self._remotes.PartyUpdated:FireClient(player, nil)

	if #newMemberUserIds == 0 then
		self._parties[partyId] = nil
		return
	end

	party.memberUserIds = newMemberUserIds
	if wasLeader then
		self:PromoteLeader(partyId)
	end
	self:BroadcastPartyUpdate(partyId)
end

function PartyService:ClearInvitesForUser(userId)
	self._pendingInvites[userId] = nil

	for targetUserId, invite in self._pendingInvites do
		if invite.fromUserId == userId then
			self._pendingInvites[targetUserId] = nil
		end
	end
end

function PartyService:GetValidInvite(targetUserId)
	local invite = self._pendingInvites[targetUserId]
	if not invite then
		return nil
	end

	if tick() - invite.sentAt > PartyConfig.InviteTimeoutSeconds then
		self._pendingInvites[targetUserId] = nil
		return nil
	end

	return invite
end

function PartyService:NotifyInviteResult(player, success, message)
	self._remotes.PartyInviteResult:FireClient(player, {
		success = success,
		message = message,
	})
end

function PartyService:HandleInvite(inviter, targetUserId)
	if type(targetUserId) ~= "number" then
		self:NotifyInviteResult(inviter, false, "Invalid invite target.")
		return
	end

	if targetUserId == inviter.UserId then
		self:NotifyInviteResult(inviter, false, "You cannot invite yourself.")
		return
	end

	local target = getPlayerByUserId(targetUserId)
	if not target then
		self:NotifyInviteResult(inviter, false, "Player is not in this server.")
		return
	end

	if self._playerToParty[targetUserId] then
		self:NotifyInviteResult(inviter, false, "That player is already in a party.")
		return
	end

	if self._pendingInvites[targetUserId] then
		self:NotifyInviteResult(inviter, false, "That player already has a pending invite.")
		return
	end

	local inviterPartyId = self._playerToParty[inviter.UserId]
	if inviterPartyId then
		if not self:IsLeader(inviter) then
			self:NotifyInviteResult(inviter, false, "Only the party leader can invite.")
			return
		end

		local party = self._parties[inviterPartyId]
		if party and #party.memberUserIds >= PartyConfig.MaxSize then
			self:NotifyInviteResult(inviter, false, "Your party is full.")
			return
		end
	else
		if self._playerToParty[inviter.UserId] then
			self:NotifyInviteResult(inviter, false, "You are already in a party.")
			return
		end
	end

	self._pendingInvites[targetUserId] = {
		fromUserId = inviter.UserId,
		sentAt = tick(),
	}

	self._remotes.PartyInviteReceived:FireClient(target, {
		fromUserId = inviter.UserId,
		fromName = inviter.DisplayName,
	})

	self:NotifyInviteResult(inviter, true, "Invite sent to " .. target.DisplayName .. ".")
end

function PartyService:HandleRespondInvite(target, fromUserId, accept)
	if type(fromUserId) ~= "number" then
		return
	end

	local invite = self:GetValidInvite(target.UserId)
	if not invite or invite.fromUserId ~= fromUserId then
		self._remotes.Notification:FireClient(target, "Invite expired or invalid.")
		return
	end

	self._pendingInvites[target.UserId] = nil

	if not accept then
		local inviter = getPlayerByUserId(fromUserId)
		if inviter then
			self:NotifyInviteResult(inviter, false, target.DisplayName .. " declined your invite.")
		end
		return
	end

	if self._playerToParty[target.UserId] then
		self._remotes.Notification:FireClient(target, "You are already in a party.")
		return
	end

	local inviter = getPlayerByUserId(fromUserId)
	if not inviter then
		self._remotes.Notification:FireClient(target, "Inviter is no longer in this server.")
		return
	end

	local inviterPartyId = self._playerToParty[inviter.UserId]
	if inviterPartyId then
		local party = self._parties[inviterPartyId]
		if not party then
			self._remotes.Notification:FireClient(target, "Party no longer exists.")
			return
		end

		if party.leaderUserId ~= inviter.UserId then
			self._remotes.Notification:FireClient(target, "Inviter is no longer the party leader.")
			return
		end

		if #party.memberUserIds >= PartyConfig.MaxSize then
			self._remotes.Notification:FireClient(target, "That party is full.")
			self:NotifyInviteResult(inviter, false, "Your party is full.")
			return
		end

		self:AddMember(inviterPartyId, target)
	else
		if self._playerToParty[inviter.UserId] then
			self._remotes.Notification:FireClient(target, "Inviter is already in another party.")
			return
		end

		self:CreateParty(inviter, target)
	end

	self:NotifyInviteResult(inviter, true, target.DisplayName .. " joined your party.")
end

function PartyService:HandleLeave(player)
	if not self._playerToParty[player.UserId] then
		return
	end
	self:RemoveMember(player)
end

function PartyService:HandleKick(leader, targetUserId)
	if type(targetUserId) ~= "number" then
		return
	end

	if not self:IsLeader(leader) then
		self._remotes.Notification:FireClient(leader, "Only the party leader can kick.")
		return
	end

	if targetUserId == leader.UserId then
		self._remotes.Notification:FireClient(leader, "You cannot kick yourself. Use Leave.")
		return
	end

	local partyId = self._playerToParty[leader.UserId]
	local party = partyId and self._parties[partyId]
	if not party then
		return
	end

	local isMember = false
	for _, userId in party.memberUserIds do
		if userId == targetUserId then
			isMember = true
			break
		end
	end

	if not isMember then
		self._remotes.Notification:FireClient(leader, "That player is not in your party.")
		return
	end

	local target = getPlayerByUserId(targetUserId)
	if target then
		self:RemoveMember(target)
		self._remotes.Notification:FireClient(target, "You were removed from the party.")
	else
		self._playerToParty[targetUserId] = nil
		local newMemberUserIds = {}
		for _, userId in party.memberUserIds do
			if userId ~= targetUserId then
				table.insert(newMemberUserIds, userId)
			end
		end
		party.memberUserIds = newMemberUserIds
		if #newMemberUserIds == 0 then
			self._parties[partyId] = nil
		else
			self:BroadcastPartyUpdate(partyId)
		end
	end
end

function PartyService:Start()
	self._remotes.PartyInvite.OnServerEvent:Connect(function(player, targetUserId)
		self:HandleInvite(player, targetUserId)
	end)

	self._remotes.PartyRespondInvite.OnServerEvent:Connect(function(player, fromUserId, accept)
		self:HandleRespondInvite(player, fromUserId, accept == true)
	end)

	self._remotes.PartyLeave.OnServerEvent:Connect(function(player)
		self:HandleLeave(player)
	end)

	self._remotes.PartyKick.OnServerEvent:Connect(function(player, targetUserId)
		self:HandleKick(player, targetUserId)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:ClearInvitesForUser(player.UserId)
		self:RemoveMember(player)
	end)
end

return PartyService
