local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)

local CombatService = {}
CombatService._playerData = nil
CombatService._enemyService = nil
CombatService._cooldowns = {}

local ATTACK_COOLDOWN = 0.6
local ATTACK_RANGE = 10

function CombatService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._enemyService = Framework:GetService("EnemyService")
	self._remotes = Framework:GetRemotesFolder()
end

function CombatService:CreateWeaponTool(weaponId)
	local weapon = Items[weaponId]
	if not weapon then
		return nil
	end

	local tool = Instance.new("Tool")
	tool.Name = weapon.name
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("WeaponId", weapon.id)

	local handle = Instance.new("Part")
	handle.Name = "Handle"

	local weaponType = weapon.type
	if weaponType == "weapon" and weapon.id:find("Staff") then
		handle.Size = Vector3.new(0.35, 0.35, 4.5)
	elseif weaponType == "weapon" and weapon.id:find("Bow") then
		handle.Size = Vector3.new(0.3, 2.5, 0.3)
	elseif weaponType == "weapon" and weapon.id:find("Spear") then
		handle.Size = Vector3.new(0.35, 0.35, 5.0)
	elseif weaponType == "weapon" and weapon.id:find("Mace") then
		handle.Size = Vector3.new(0.6, 0.6, 2.5)
	else
		handle.Size = Vector3.new(0.4, 0.4, 3.5)
	end

	handle.Color = weapon.color
	handle.Material = Enum.Material.Metal
	handle.Parent = tool

	return tool
end

function CombatService:GiveWeapon(player, weaponId)
	local data = self._playerData:GetData(player)
	if not data or not data.hasSelectedClass then
		return
	end

	weaponId = weaponId or data.equippedWeapon
	if not weaponId then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, child in backpack:GetChildren() do
			if child:IsA("Tool") and child:GetAttribute("WeaponId") then
				child:Destroy()
			end
		end
	end

	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("WeaponId") then
			child:Destroy()
		end
	end

	local tool = self:CreateWeaponTool(weaponId)
	if tool then
		tool.Parent = character
	end
end

function CombatService:FindAttackTargets(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return {}
	end

	local origin = root.Position
	local look = root.CFrame.LookVector
	local targets = {}

	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and enemy:GetAttribute("Health") and enemy:GetAttribute("Health") > 0 then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if enemyRoot then
				local offset = enemyRoot.Position - origin
				local distance = offset.Magnitude
				if distance <= ATTACK_RANGE then
					local direction = offset.Unit
					if direction:Dot(look) > 0.3 then
						table.insert(targets, enemy)
					end
				end
			end
		end
	end

	return targets
end

function CombatService:HandleAttack(player)
	if not self._playerData:HasSelectedClass(player) then
		return
	end

	local now = tick()
	if self._cooldowns[player] and now - self._cooldowns[player] < ATTACK_COOLDOWN then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	self._cooldowns[player] = now
	local damage = self._playerData:GetWeaponDamage(player)
	local targets = self:FindAttackTargets(character)

	for _, enemy in targets do
		self._enemyService:DamageEnemy(enemy, damage, player)
	end
end

function CombatService:Start()
	self._remotes.Attack.OnServerEvent:Connect(function(player)
		self:HandleAttack(player)
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			self:GiveWeapon(player)
		end)
	end)

	for _, player in Players:GetPlayers() do
		if player.Character then
			task.delay(0.5, function()
				self:GiveWeapon(player)
			end)
		end
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			self:GiveWeapon(player)
		end)
	end
end

return CombatService
