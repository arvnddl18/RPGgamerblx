local MobTypeConfig = {
	Neutral = {
		id = "Neutral",
		aggroBehavior = "Passive", -- Only attacks if attacked
		respawnTime = 30,
	},
	Hostile = {
		id = "Hostile",
		aggroBehavior = "Aggressive", -- Attacks players on sight
		respawnTime = 60,
	},
	Boss = {
		id = "Boss",
		aggroBehavior = "Aggressive",
		respawnTime = 300,
		isBoss = true,
	}
}

return MobTypeConfig
