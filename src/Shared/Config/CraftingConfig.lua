local CraftingConfig = {
	UpgradeAttempts = {
		-- Upgrades now have only two outcomes: success or destroy.
		Uncommon = { goldCost = 50, materialMinRarity = "Common", materialAmount = 2, success = 0.75, destroy = 0.25 },
		Rare = { goldCost = 150, materialMinRarity = "Uncommon", materialAmount = 4, success = 0.30, destroy = 0.70 },
		Epic = { goldCost = 500, materialMinRarity = "Rare", materialAmount = 5, success = 0.18, destroy = 0.82 },
		Legendary = { goldCost = 1500, materialMinRarity = "Epic", materialAmount = 6, success = 0.10, destroy = 0.90 },
		Mythic = { goldCost = 5000, materialMinRarity = "Legendary", materialAmount = 8, success = 0.03, destroy = 0.97 },
	},
}

function CraftingConfig.GetUpgradeAttempt(targetRarity)
	return CraftingConfig.UpgradeAttempts[targetRarity]
end

return CraftingConfig
