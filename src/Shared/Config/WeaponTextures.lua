local WeaponTextures = {}

WeaponTextures.Styles = {
	sword = "Longsword",
	staff = "MageStaff",
	bow = "RecurveBow",
	axe = "WarriorAxe",
}

WeaponTextures.MapNames = {
	ColorMap = { "BaseColor", "Color", "Albedo" },
	NormalMap = { "Normal" },
	MetalnessMap = { "Metallic", "Metalness" },
	RoughnessMap = { "Roughness" },
}

function WeaponTextures.GetFolder(style)
	local rs = game:GetService("ReplicatedStorage")
	local assets = rs:FindFirstChild("Assets")
	if not assets then
		return nil
	end
	local textures = assets:FindFirstChild("Textures")
	if not textures then
		return nil
	end
	local weapons = textures:FindFirstChild("Weapons")
	if not weapons then
		return nil
	end
	local folderName = WeaponTextures.Styles[style]
	return folderName and weapons:FindFirstChild(folderName)
end

local function findMap(folder, keys)
	for _, key in keys do
		local inst = folder:FindFirstChild(key)
		if inst then
			if inst:IsA("Decal") then
				return inst.Texture
			end
			if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
				return inst.Image
			end
			if inst:IsA("StringValue") then
				return inst.Value
			end
		end
		for _, child in folder:GetChildren() do
			if child.Name:find(key, 1, true) then
				if child:IsA("Decal") then
					return child.Texture
				end
				if child:IsA("ImageLabel") or child:IsA("ImageButton") then
					return child.Image
				end
				if child:IsA("StringValue") then
					return child.Value
				end
			end
		end
	end
	return nil
end

function WeaponTextures.GetMaps(style)
	local folder = WeaponTextures.GetFolder(style)
	if not folder then
		return nil
	end
	local maps = {}
	for prop, keys in WeaponTextures.MapNames do
		maps[prop] = findMap(folder, keys)
	end
	return maps
end

function WeaponTextures.Apply(meshPart, style)
	if not meshPart or not meshPart:IsA("MeshPart") then
		return
	end
	local maps = WeaponTextures.GetMaps(style)
	if not maps then
		return
	end
	local sa = meshPart:FindFirstChildOfClass("SurfaceAppearance")
	if not sa then
		sa = Instance.new("SurfaceAppearance")
		sa.Parent = meshPart
	end
	for prop, id in maps do
		if id and id ~= "" then
			sa[prop] = id
			if prop == "ColorMap" then
				meshPart.TextureID = id
			end
		end
	end
end

return WeaponTextures
