local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Classes = require(Shared.Config.Classes)
local Skills = require(Shared.Config.Skills)

local ClassService = {}
ClassService._playerData = nil
ClassService._combatService = nil
ClassService._equipmentService = nil
ClassService._remotes = nil

function ClassService:Init()
	local Framework = require(ReplicatedStorage.Shared.Framework)
	self._playerData = Framework:GetService("PlayerDataService")
	self._combatService = Framework:GetService("CombatService")
	self._equipmentService = Framework:GetService("EquipmentService")
	self._remotes = Framework:GetRemotesFolder()

	Framework:GetRemote("SelectClass")
	Framework:GetRemote("ClassSelected")
end

function ClassService:BuildClassPayload(classId)
	local classConfig = Classes[classId]
	if not classConfig then
		return nil
	end

	local skillNames = {}
	for slotKey, skillId in classConfig.skills do
		local skill = Skills[skillId]
		skillNames[slotKey] = skill and skill.name or skillId
	end

	return {
		classId = classConfig.id,
		displayName = classConfig.displayName,
		description = classConfig.description,
		role = classConfig.role,
		accentColor = classConfig.accentColor,
		baseStats = classConfig.baseStats,
		skills = skillNames,
		masteryPassive = classConfig.masteryPassive and {
			name = classConfig.masteryPassive.name,
			description = classConfig.masteryPassive.description,
		},
	}
end

function ClassService:HandleSelectClass(player, classId)
	if type(classId) ~= "string" then
		return
	end

	if self._playerData:HasSelectedClass(player) then
		return
	end

	if not Classes[classId] then
		self._remotes.Notification:FireClient(player, "Invalid class selection.")
		return
	end

	local applied = self._playerData:ApplyClass(player, classId)
	if not applied then
		return
	end

	if self._equipmentService then
		self._equipmentService:EquipPlayer(player)
	end

	if self._combatService then
		self._combatService:GiveWeapon(player)
	end

	local payload = self:BuildClassPayload(classId)
	self._remotes.ClassSelected:FireClient(player, payload)
	self._remotes.Notification:FireClient(player, "You are now a " .. Classes[classId].displayName .. "!")
end

function ClassService:Start()
	self._remotes.SelectClass.OnServerEvent:Connect(function(player, classId)
		self:HandleSelectClass(player, classId)
	end)
end

return ClassService
