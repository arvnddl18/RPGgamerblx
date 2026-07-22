local SkillVfxConfig = {}

SkillVfxConfig.Templates = {
	Dash_VFX = { duration = 0.25, offset = CFrame.new(0, 0, 0), followCharacter = true },
	LeapStrike_VFX = { duration = 1.2, offset = CFrame.new(0, 0, -2) },
	LongShot_VFX = { duration = 1.0, offset = CFrame.new(0, 0, -1) },
	StaffLightning_VFX = { duration = 1.4, offset = CFrame.new(0, 0, -3) },
	SlashPart = { 
		duration = 2,  
		offset = CFrame.new(0, 0, -3),
		comboAngles = {
			CFrame.Angles(0, 0, math.rad(-180)), 
			CFrame.Angles(0, 0, math.rad(15)), 
			CFrame.Angles(0, 0, math.rad(-90)), 
		},
		emitCount = 1, 
		anchored = true 
	},
	SlashPart_Kavalier = { 
		duration = 2,  
		offset = CFrame.new(0, 0, -3),
		comboAngles = {
			CFrame.Angles(0, 0, math.rad(-180)), 
			CFrame.Angles(0, 0, math.rad(15)), 
			CFrame.Angles(0, 0, math.rad(-90)), 
		},
		emitCount = 1, 
		anchored = true,
		color = Color3.fromRGB(102, 0, 153), -- Dark Purple
		baseVfx = "SlashPart"
	},
	SlashPart_Priest = { 
		duration = 2,  
		offset = CFrame.new(0, 0, -3),
		comboAngles = {
			CFrame.Angles(0, 0, math.rad(-180)), 
			CFrame.Angles(0, 0, math.rad(15)), 
			CFrame.Angles(0, 0, math.rad(-90)), 
		},
		emitCount = 1, 
		anchored = true,
		color = Color3.fromRGB(204, 153, 0), -- Dark Yellow
		baseVfx = "SlashPart"
	},
}

SkillVfxConfig.SkillToVfx = {
	Warrior_Charge = "LeapStrike_VFX",
	Archer_SniperShot = "LongShot_VFX",
	Mage_LightningStorm = "StaffLightning_VFX",
	Warrior_AutoAttack = "SlashPart",
	Kavalier_AutoAttack = "SlashPart_Kavalier",
	Priest_AutoAttack = "SlashPart_Priest",
}

SkillVfxConfig.DashVfx = "Dash_VFX"

function SkillVfxConfig.GetForSkill(skillId)
	return SkillVfxConfig.SkillToVfx[skillId]
end

function SkillVfxConfig.GetTemplateConfig(vfxKey)
	return SkillVfxConfig.Templates[vfxKey]
end

return SkillVfxConfig
