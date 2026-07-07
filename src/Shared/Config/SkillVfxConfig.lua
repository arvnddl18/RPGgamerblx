local SkillVfxConfig = {}

SkillVfxConfig.Templates = {
	Dash_VFX = { duration = 0.25, offset = CFrame.new(0, 0, 0), followCharacter = true },
	LeapStrike_VFX = { duration = 1.2, offset = CFrame.new(0, 0, -2) },
	LongShot_VFX = { duration = 1.0, offset = CFrame.new(0, 0, -1) },
	StaffLightning_VFX = { duration = 1.4, offset = CFrame.new(0, 0, -3) },
}

SkillVfxConfig.SkillToVfx = {
	Warrior_Charge = "LeapStrike_VFX",
	Archer_SniperShot = "LongShot_VFX",
	Mage_LightningStorm = "StaffLightning_VFX",
}

SkillVfxConfig.DashVfx = "Dash_VFX"

function SkillVfxConfig.GetForSkill(skillId)
	return SkillVfxConfig.SkillToVfx[skillId]
end

function SkillVfxConfig.GetTemplateConfig(vfxKey)
	return SkillVfxConfig.Templates[vfxKey]
end

return SkillVfxConfig
