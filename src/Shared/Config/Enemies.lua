local Enemies = {
	Goblin = {
		id = "Goblin",
		name = "Slime",
		maxHealth = 50,
		damage = 8,
		defense = 3,
		movementSpeed = 4,
		attackCooldown = 3,
		aggroRange = 40,
		attackRange = 6,
		xpReward = 20,
		coinReward = 20,
		dropChance = 0.35,
		dropItem = "Herb",
		lootTableId = "GoblinDrops",
		color = Color3.fromRGB(60, 140, 60),
	},
}

return Enemies
