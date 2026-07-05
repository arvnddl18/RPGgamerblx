local CraftingConfig = {
	UpgradeAttempts = {
		Uncommon = { goldCost = 50, materialMinRarity = "Common", materialAmount = 2, success = 0.50, fail = 0.45, destroy = 0.05 },
		Rare = { goldCost = 150, materialMinRarity = "Uncommon", materialAmount = 4, success = 0.30, fail = 0.60, destroy = 0.10 },
		Epic = { goldCost = 500, materialMinRarity = "Rare", materialAmount = 5, success = 0.18, fail = 0.67, destroy = 0.15 },
		Legendary = { goldCost = 1500, materialMinRarity = "Epic", materialAmount = 6, success = 0.10, fail = 0.70, destroy = 0.20 },
		Mythic = { goldCost = 5000, materialMinRarity = "Legendary", materialAmount = 8, success = 0.03, fail = 0.62, destroy = 0.35 },
	},
}

function CraftingConfig.GetUpgradeAttempt(targetRarity)
	return CraftingConfig.UpgradeAttempts[targetRarity]
end

return CraftingConfig
