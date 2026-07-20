local WeaponGrips = {}

WeaponGrips.GRIP_VERSION = 8

-- Tip extends -Z from handle. Yaw -90 aligns -Z to character forward.
local function fwd(y, pitch, yaw, roll)
	return CFrame.new(0, y, 0)
		* CFrame.Angles(math.rad(pitch), math.rad(yaw), math.rad(roll or 0))
end

WeaponGrips.Styles = {
	sword = {
		idle = fwd(-0.25, -95, -90, 0),
		attack = fwd(-0.2, -80, -90, 8),
		handleSize = Vector3.new(0.25, 0.25, 0.5),
	},
	axe = {
		idle = CFrame.new(0, -0.45, -0.15) * CFrame.Angles(math.rad(90), 0, math.rad(90)),
		attack = fwd(-0.2, -80, -90, 8),
		handleSize = Vector3.new(0.25, 0.25, 0.5),
	},
	staff = {
		idle = fwd(-0.35, -70, -90, 0),
		attack = fwd(-0.25, -55, -90, -10),
		handleSize = Vector3.new(0.25, 0.25, 0.6),
	},
	bow = {
		idle = CFrame.new(0, 0, 0),
		attack = CFrame.new(0, 0, 0),
		handleSize = Vector3.new(0.2, 0.2, 0.4),
		leftHandAttach = true,
		leftC0 = CFrame.new(-0.08, -0.2, -0.25) * CFrame.Angles(math.rad(-90), 0, 0),
		leftC1 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(150), math.rad(-90), 0),
		attackLeftC0 = CFrame.new(-0.08, -0.08, -0.35) * CFrame.Angles(math.rad(-90), 0, 0),
		attackLeftC1 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(15), math.rad(-90), 0),
	},
	mace = {
		idle = fwd(-0.3, -95, -90, 5),
		attack = fwd(-0.2, -75, -90, 0),
		handleSize = Vector3.new(0.55, 0.55, 1.1),
	},
	spear = {
		idle = fwd(-0.3, -88, -90, 0),
		attack = fwd(-0.2, -72, -90, 10),
		handleSize = Vector3.new(0.5, 0.5, 1.2),
	},
}

function WeaponGrips.GetStyle(weaponId, itemConfig)
	if itemConfig and itemConfig.weaponSkin and itemConfig.weaponSkin.style then
		return itemConfig.weaponSkin.style
	end
	if not weaponId then return "sword" end
	if weaponId:find("Staff") then return "staff" end
	if weaponId:find("Bow") then return "bow" end
	if weaponId:find("Spear") then return "spear" end
	if weaponId:find("Mace") then return "mace" end
	return "sword"
end

function WeaponGrips.GetStyleConfig(weaponId, itemConfig)
	return WeaponGrips.Styles[WeaponGrips.GetStyle(weaponId, itemConfig)]
end

return WeaponGrips
