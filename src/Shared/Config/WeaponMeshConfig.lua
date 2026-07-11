local WeaponMeshConfig = {}

-- Grip offset: local position on mesh aligned to invisible Handle (origin = hand)
WeaponMeshConfig.Styles = {
	sword = {
		gripOffset = Vector3.new(0, 0, 0),
		scale = 0.039,
	},
	staff = {
		gripOffset = Vector3.new(0, 0, 0),
		scale = 0.036,
	},
	bow = {
		gripOffset = Vector3.new(0, 0, 0),
		scale = 0.012,
	},
	mace = {
		gripOffset = Vector3.new(0, 0, 0),
		scale = 0.1,
	},
	spear = {
		gripOffset = Vector3.new(0, 0, 0),
		scale = 0.22,
	},
}

function WeaponMeshConfig.Get(style)
	return WeaponMeshConfig.Styles[style]
end

function WeaponMeshConfig.GetTemplate(style)
	local rs = game:GetService("ReplicatedStorage")
	local assets = rs:FindFirstChild("Assets")
	if not assets then
		return nil
	end
	local meshes = assets:FindFirstChild("WeaponMeshes")
	local template = meshes and meshes:FindFirstChild(style)
	if template then
		return template
	end
	local weapons = assets:FindFirstChild("Weapons")
	return weapons and weapons:FindFirstChild(style)
end

return WeaponMeshConfig
