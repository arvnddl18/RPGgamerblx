local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SkinToolBuilder = require(Shared.Util.SkinToolBuilder)
local DamageCalculator = require(Shared.Combat.DamageCalculator)

local CombatService = {}
CombatService._playerData = nil
CombatService._enemyService = nil
CombatService._pvpService = nil
CombatService._restService = nil
CombatService._cooldowns = {}

local ATTACK_COOLDOWN = 0.6
local ATTACK_RANGE = 10

function CombatService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._enemyService = Framework:GetService("EnemyService")
	self._pvpService = Framework:GetService("PvpService")
	self._restService = Framework:GetService("RestService")
	self._remotes = Framework:GetRemotesFolder()
end

function CombatService:CreateWeaponTool(weaponId)
	return SkinToolBuilder.BuildWeaponTool(weaponId)
end

function CombatService:GiveWeapon(player, weaponId)
	local data = self._playerData:GetData(player)
	if not data or not data.hasSelectedClass then
		return
	end

	weaponId = weaponId or data.equippedWeapon
	if type(weaponId) == "table" then
		weaponId = weaponId.id
	end
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

function CombatService:CanDamagePlayer(attacker, target)
	if not self._pvpService then
		return false
	end
	return self._pvpService:CanDamagePlayer(attacker, target)
end

function CombatService:DamagePlayer(attacker, target, baseDamage, damageType)
	if not self:CanDamagePlayer(attacker, target) then
		return false
	end

	local attackerData = self._playerData:GetData(attacker)
	local targetData = self._playerData:GetData(target)
	if not attackerData or not targetData or targetData.hp <= 0 then
		return false
	end

	local hit = DamageCalculator.ComputeHit(baseDamage, attackerData.combatStats, targetData.combatStats, damageType or "physical")
	self._playerData:Damage(target, hit.damage, attacker, true)
	return true
end

function CombatService:FindAttackTargets(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return { enemies = {}, players = {} }
	end

	local origin = root.Position
	local look = root.CFrame.LookVector
	local enemies = {}
	local hostilePlayers = {}

	for _, enemy in CollectionService:GetTagged("Enemy") do
		if enemy.Parent and enemy:GetAttribute("Health") and enemy:GetAttribute("Health") > 0 then
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart
			if enemyRoot then
				local offset = enemyRoot.Position - origin
				local distance = offset.Magnitude
				if distance <= ATTACK_RANGE then
					local direction = offset.Unit
					if direction:Dot(look) > 0.3 then
						table.insert(enemies, enemy)
					end
				end
			end
		end
	end

	local attacker = Players:GetPlayerFromCharacter(character)
	if attacker then
		for _, otherPlayer in Players:GetPlayers() do
			if otherPlayer ~= attacker and self:CanDamagePlayer(attacker, otherPlayer) then
				local otherCharacter = otherPlayer.Character
				local otherRoot = otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
				local otherData = self._playerData:GetData(otherPlayer)
				if otherRoot and otherData and otherData.hp > 0 then
					local offset = otherRoot.Position - origin
					local distance = offset.Magnitude
					if distance <= ATTACK_RANGE then
						local direction = offset.Unit
						if direction:Dot(look) > 0.3 then
							table.insert(hostilePlayers, otherPlayer)
						end
					end
				end
			end
		end
	end

	return { enemies = enemies, players = hostilePlayers }
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

	if character:GetAttribute("IsStunned") or character:GetAttribute("IsKnockedDown") then
		return
	end

	if self._restService then
		self._restService:CancelRest(player, true)
	end

	self._cooldowns[player] = now
	local data = self._playerData:GetData(player)
	local attackerStats = data.combatStats
	local targets = self:FindAttackTargets(character)

	for _, enemy in targets.enemies do
		self._enemyService:DamageEnemy(enemy, 0, attackerStats, player, "physical")
	end

	for _, targetPlayer in targets.players do
		self:DamagePlayer(player, targetPlayer, 0, "physical")
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
