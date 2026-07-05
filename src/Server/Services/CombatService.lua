local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)

local CombatService = {}
CombatService._playerData = nil
CombatService._enemyService = nil
CombatService._cooldowns = {}
CombatService._dashCooldowns = {}

local ATTACK_COOLDOWN = 0.6
local ATTACK_RANGE = 10
local DASH_COOLDOWN = 5

function CombatService:Init(playerDataService, enemyService, remotes)
	self._playerData = playerDataService
	self._enemyService = enemyService
	self._remotes = remotes
end

function CombatService:CreateSwordTool(weaponId)
	local weapon = Items[weaponId] or Items.WoodenSword
	local tool = Instance.new("Tool")
	tool.Name = weapon.name
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("WeaponId", weapon.id)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.4, 3.5)
	handle.Color = weapon.color
	handle.Material = Enum.Material.Metal
	handle.Parent = tool

	return tool
end

function CombatService:GiveSword(player, weaponId)
	local data = self._playerData:GetData(player)
	if not data then
		return
	end

	weaponId = weaponId or data.equippedWeapon or "WoodenSword"

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Remove any existing weapon tools from character and backpack
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

	-- Create the weapon and parent it directly to the character
	-- This forces the humanoid to equip it immediately, bypassing the disabled Backpack UI
	local tool = self:CreateSwordTool(weaponId)
	tool.Parent = character
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

function CombatService:HandleDash(player)
	local now = tick()
	if self._dashCooldowns[player] and now - self._dashCooldowns[player] < DASH_COOLDOWN then
		return -- Still on cooldown, reject
	end

	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	self._dashCooldowns[player] = now
end

function CombatService:Start()
	self._remotes.Attack.OnServerEvent:Connect(function(player)
		self:HandleAttack(player)
	end)

	self._remotes.Dash.OnServerEvent:Connect(function(player)
		self:HandleDash(player)
	end)

	-- Give weapon on character spawn
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5) -- Let EquipmentService finish first
			self:GiveSword(player)
		end)
	end)

	-- Handle players already in the game
	for _, player in Players:GetPlayers() do
		if player.Character then
			task.delay(0.5, function()
				self:GiveSword(player)
			end)
		end
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			self:GiveSword(player)
		end)
	end
end

return CombatService
