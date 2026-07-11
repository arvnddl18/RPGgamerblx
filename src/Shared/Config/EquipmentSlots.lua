local EquipmentSlots = {
	ORDER = {
		"weapon",
		"helmet",
		"shoulders",
		"armor",
		"upperArms",
		"gloves",
		"pants",
		"boots",
	},
	LABELS = {
		weapon = "Weapon",
		helmet = "Helmet",
		shoulders = "Shoulders",
		armor = "Armor",
		upperArms = "Upper Arms",
		gloves = "Gloves",
		pants = "Pants",
		boots = "Boots",
	},
	DEFAULT_VISUAL_MODE = {
		helmet = "rigid",
		shoulders = "rigid",
		armor = "layered",
		upperArms = "layered",
		pants = "layered",
		boots = "layered",
		gloves = "rigid",
	},
}

function EquipmentSlots.createEmpty()
	local equipped = {}
	for _, slot in EquipmentSlots.ORDER do
		equipped[slot] = nil
	end
	return equipped
end

return EquipmentSlots
