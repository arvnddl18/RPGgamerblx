local DamageCalculator = {}

function DamageCalculator.Compute(baseDamage, attackerStats, skillType)
	local damage = baseDamage or 0

	if skillType == "magic" then
		damage += attackerStats.magicAttack or 0
	elseif skillType == "ranged" or skillType == "melee" then
		damage += attackerStats.physicalAttack or 0
	end

	return math.max(1, math.floor(damage))
end

function DamageCalculator.ApplyDefense(damage, targetDefense)
	local defense = targetDefense or 0
	return math.max(1, damage - math.floor(defense * 0.5))
end

return DamageCalculator
