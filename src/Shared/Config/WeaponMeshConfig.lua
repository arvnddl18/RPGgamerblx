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
}

function WeaponMeshConfig.Get(style)
	return WeaponMeshConfig.Styles[style]
end

function WeaponMeshConfig.GetTemplate(style)
	local rs = game:GetService("ReplicatedStorage")
	local assets = rs:FindFirstChild("Assets")
	local meshes = assets and assets:FindFirstChild("WeaponMeshes")
	return meshes and meshes:FindFirstChild(style)
end

return WeaponMeshConfig
