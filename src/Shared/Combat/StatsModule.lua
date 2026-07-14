local StatsModule = {}

-- Base definition of all supported combat stats.
StatsModule.DefaultStats = {
	-- Offense
	physicalAttack = 0,
	magicAttack = 0,
	critChance = 0,     -- 0.0 to 1.0 (e.g. 0.05 = 5%)
	critDamage = 1.5,   -- Multiplier (e.g. 1.5x)
	accuracy = 1.0,     -- 1.0 = 100% chance before evasion

	-- Defense
	defense = 0,
	magicalResistance = 0,
	critReduction = 0,  -- 0.0 to 1.0
	evasion = 0,        -- 0.0 to 1.0

	-- Utility
	healPower = 1.0,    -- Multiplier for outgoing heals
	physicalLifeSteal = 0, -- Portion of physical damage restored as health
	magicLifeSteal = 0,    -- Portion of magic damage restored as health
	-- Priest/support scaling. These affect only friendly skill buffs in SkillService.
	buffEffectMultiplier = 1.0, -- Multiplies buff stat bonuses and shields granted by the caster
	buffDurationMultiplier = 1.0, -- Multiplies the duration of friendly buffs cast by the caster
	movementSpeed = 16,     -- Base roblox walkspeed
	maxHp = 100,
	maxMana = 50,
	hpRegen = 1,        -- Flat regen per tick
	manaRegen = 1,      -- Flat regen per tick
}

function StatsModule.GetBaseStats()
	local stats = {}
	for k, v in pairs(StatsModule.DefaultStats) do
		stats[k] = v
	end
	return stats
end

-- Combines base class stats, equipment bonuses, active buffs, and generic multipliers.
function StatsModule.CombineStats(baseStats, equipmentBonuses, activeBuffs, statMultipliers)
	local combined = StatsModule.GetBaseStats()
	
	-- Apply base stats override
	if baseStats then
		for k, v in pairs(baseStats) do
			if combined[k] ~= nil then
				combined[k] = v
			end
		end
	end
	
	-- Add equipment flat bonuses
	if equipmentBonuses then
		for k, v in pairs(equipmentBonuses) do
			if combined[k] ~= nil then
				combined[k] += v
			end
		end
	end
	
	-- Add buff flat bonuses
	if activeBuffs then
		for k, v in pairs(activeBuffs) do
			if combined[k] ~= nil then
				combined[k] += v
			end
		end
	end
	
	-- Apply multipliers (from Rarity, special buffs, etc)
	if statMultipliers then
		for k, v in pairs(statMultipliers) do
			if combined[k] ~= nil then
				combined[k] *= v
			end
		end
	end
	
	return combined
end

return StatsModule
