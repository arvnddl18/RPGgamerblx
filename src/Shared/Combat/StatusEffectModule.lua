local StatusEffectModule = {}

-- Defines behavior when an effect is reapplied:
-- "Refresh": Resets the duration.
-- "Stack": Adds a new instance or increments intensity.
-- "Ignore": The new application fails if already active.

StatusEffectModule.EffectTypes = {
	Stun = {
		id = "Stun",
		stackBehavior = "Refresh",
		disablesInput = true,
		disablesSkills = true,
	},
	Knockdown = {
		id = "Knockdown",
		stackBehavior = "Ignore",
		disablesInput = true,
		disablesSkills = true,
		forceRagdoll = true,
	},
	Slow = {
		id = "Slow",
		stackBehavior = "Refresh",
		-- The exact % reduction is defined by the skill/buff applying it
	},
	Silence = {
		id = "Silence",
		stackBehavior = "Refresh",
		disablesSkills = true,
	},
	Poison = {
		id = "Poison",
		stackBehavior = "Stack",
		isDoT = true,
		tickRate = 1.0, -- ticks every 1 second
		damageType = "magic",
	},
	Burn = {
		id = "Burn",
		stackBehavior = "Refresh",
		isDoT = true,
		tickRate = 0.5,
		damageType = "magic",
	},
	Bleed = {
		id = "Bleed",
		stackBehavior = "Stack",
		isDoT = true,
		tickRate = 1.0,
		damageType = "physical",
	},
	-- Generic Stat Buffs (for food/potions/skills)
	StatBuff = {
		id = "StatBuff",
		stackBehavior = "Refresh",
	},
	Blessing = {
		id = "Blessing",
		stackBehavior = "Refresh",
	},
	DivineShield = {
		id = "DivineShield",
		stackBehavior = "Refresh",
		isShield = true,
	},
}

return StatusEffectModule
