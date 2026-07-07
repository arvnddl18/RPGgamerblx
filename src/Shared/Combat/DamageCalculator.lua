local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CombatConfig = require(Shared.Config.CombatConfig)

local DamageCalculator = {}

local RESISTANCE_HALF_LIFE = CombatConfig.resistanceHalfLife

-- Resolves an attack between an attacker's stats and a target's stats.
-- Returns: { damage = number, isCrit = boolean, isMiss = boolean }
function DamageCalculator.ComputeHit(skillDamage, attackerStats, targetStats, damageType)
	-- 1. Accuracy vs Evasion Check
	local hitChance = attackerStats.accuracy - targetStats.evasion
	if math.random() > hitChance then
		return { damage = 0, isCrit = false, isMiss = true }
	end

	-- 2. Base Damage Calculation
	local baseDamage = skillDamage or 0
	if damageType == "magic" then
		baseDamage += attackerStats.magicAttack
	elseif damageType == "ranged" or damageType == "melee" or damageType == "physical" then
		baseDamage += attackerStats.physicalAttack
	end

	-- 3. Critical Hit Check
	local isCrit = false
	local critChance = attackerStats.critChance - targetStats.critReduction
	if math.random() <= critChance then
		isCrit = true
		baseDamage *= attackerStats.critDamage
	end

	-- 4. Apply Resistance (Diminishing Returns)
	local targetResistance = 0
	if damageType == "magic" then
		targetResistance = targetStats.magicalResistance
	else
		targetResistance = targetStats.defense
	end
	
	-- DR formula: damage = damage * (HALF_LIFE / (HALF_LIFE + Resistance))
	-- If resistance is negative (armor break), increase damage.
	local mitigationFactor = 1.0
	if targetResistance >= 0 then
		mitigationFactor = RESISTANCE_HALF_LIFE / (RESISTANCE_HALF_LIFE + targetResistance)
	else
		-- Negative resistance amplifies damage
		mitigationFactor = 2 - (RESISTANCE_HALF_LIFE / (RESISTANCE_HALF_LIFE - targetResistance))
	end
	
	local finalDamage = math.max(CombatConfig.minDamage, math.floor(baseDamage * mitigationFactor))

	return { damage = finalDamage, isCrit = isCrit, isMiss = false }
end

return DamageCalculator
