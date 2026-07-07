local SkillConfig = {
	TargetTypes = {
		Self = "self",
		Single = "single",
		Ground = "ground",
		Cone = "cone",
		Circle = "circle",
		Rectangle = "rectangle",
		PartyCircle = "party_circle",
		Directional = "directional",
		Projectile = "projectile",
		Beam = "beam",
	},

	Defaults = {
		range = 10,
		aoeRadius = 0,
		coneAngle = 180,
		castTime = 0,
		cooldown = 1,
		manaCost = 0,
		showRangeIndicator = true,
		showAoeIndicator = false,
		requiresGroundTarget = false,
	},

	upgradeTiers = {},
	passiveModifiers = {},
}

function SkillConfig.ApplyDefaults(skill)
	local merged = {}
	for key, value in SkillConfig.Defaults do
		merged[key] = value
	end
	if skill then
		for key, value in skill do
			merged[key] = value
		end
	end

	if not merged.targetType then
		if merged.skillType == "heal" or merged.skillType == "buff" then
			merged.targetType = merged.aoe and SkillConfig.TargetTypes.PartyCircle or SkillConfig.TargetTypes.Self
		elseif merged.aoe then
			merged.targetType = SkillConfig.TargetTypes.Circle
		elseif merged.skillType == "magic" or merged.skillType == "ranged" then
			merged.targetType = SkillConfig.TargetTypes.Single
		elseif merged.skillType == "melee" or merged.slotType == "autoAttack" then
			merged.targetType = SkillConfig.TargetTypes.Cone
		else
			merged.targetType = SkillConfig.TargetTypes.Cone
		end
	end

	if merged.aoe and (merged.aoeRadius or 0) <= 0 then
		merged.aoeRadius = merged.range or SkillConfig.Defaults.range
	end

	if merged.targetType == SkillConfig.TargetTypes.Ground then
		merged.requiresGroundTarget = true
		merged.showAoeIndicator = true
	end

	if merged.targetType == SkillConfig.TargetTypes.Circle or merged.targetType == SkillConfig.TargetTypes.PartyCircle then
		merged.showAoeIndicator = merged.showAoeIndicator ~= false
	end

	if merged.targetType == SkillConfig.TargetTypes.Single and (merged.aoeRadius or 0) > 0 then
		if skill == nil or skill.showAoeIndicator == nil then
			merged.showAoeIndicator = true
		end
	end

	return merged
end

function SkillConfig.Resolve(skill)
	if not skill then
		return nil
	end
	return SkillConfig.ApplyDefaults(skill)
end

return SkillConfig
