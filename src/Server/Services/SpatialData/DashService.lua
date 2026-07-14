local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DashConfig = require(Shared.Config.Dash)
local SkillVfxConfig = require(Shared.Config.SkillVfxConfig)

local DashService = {}
DashService._playerData = nil
DashService._restService = nil
DashService._cooldowns = {}
DashService._remotes = nil

function DashService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._restService = Framework:GetService("RestService")
	self._remotes = Framework:GetRemotesFolder()

	Framework:GetRemote("RequestDash")
	Framework:GetRemote("DashCooldownUpdated")
	Framework:GetRemote("PlaySkillVfx")
end

function DashService:IsOnCooldown(player)
	local expires = self._cooldowns[player]
	return expires and tick() < expires
end

function DashService:ApplyDash(player, direction)
	if not self._playerData:HasSelectedClass(player) then
		return
	end

	if self:IsOnCooldown(player) then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	if character:GetAttribute("IsStunned") or character:GetAttribute("IsKnockedDown") then
		return
	end

	if direction.Magnitude < 0.01 then
		direction = root.CFrame.LookVector
	else
		direction = direction.Unit
	end

	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.01 then
		direction = root.CFrame.LookVector
	end
	direction = direction.Unit

	if self._restService then
		self._restService:CancelRest(player, true)
	end

	character:SetAttribute("IsDashing", true)

	self._remotes.PlaySkillVfx:FireAllClients(player, SkillVfxConfig.DashVfx)

	self._cooldowns[player] = tick() + DashConfig.cooldown
	self._remotes.DashCooldownUpdated:FireClient(player, DashConfig.cooldown)

	local startPos = root.Position
	local targetPos = startPos + direction * DashConfig.distance
	local elapsed = 0

	local existing = root:FindFirstChild("DashVelocity")
	if existing then
		existing:Destroy()
	end

	local attachment = root:FindFirstChild("DashAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "DashAttachment"
		attachment.Parent = root
	end

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "DashVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = direction * DashConfig.speed
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.Parent = root

	while elapsed < DashConfig.duration do
		if not root.Parent or humanoid.Health <= 0 or character:GetAttribute("IsStunned") or character:GetAttribute("IsKnockedDown") then
			break
		end
		elapsed += task.wait()
	end

	if linearVelocity.Parent then
		linearVelocity:Destroy()
	end

	if root.Parent and not character:GetAttribute("IsStunned") and not character:GetAttribute("IsKnockedDown") then
		local flatTarget = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
		root.CFrame = CFrame.new(flatTarget, flatTarget + direction)
	end

	if character.Parent then
		character:SetAttribute("IsDashing", false)
	end
end

function DashService:Start()
	self._remotes.RequestDash.OnServerEvent:Connect(function(player, direction)
		if typeof(direction) == "Vector3" then
			self:ApplyDash(player, direction)
		else
			self:ApplyDash(player, Vector3.zero)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._cooldowns[player] = nil
	end)
end

return DashService
