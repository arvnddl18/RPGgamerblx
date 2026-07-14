local EnhancementConfig = require(script.Parent.EnhancementConfig)

local Shop = {
	sellPriceRatio = 0.5,
	categories = { "weapons", "armor", "potions", "materials" },
	equipmentItems = {
		{ itemId = "HealthPotion", price = 25, category = "potions" },
		{ itemId = "ManaPotion", price = 30, category = "potions" },
		{ itemId = "IronSword", price = 100, category = "weapons" },
		{ itemId = "Herb", price = 10, category = "materials" },
		{ itemId = "IronOre", price = 40, category = "materials" },
		{ itemId = "BeastHide", price = 45, category = "materials" },
		{ itemId = "ArcaneDust", price = 50, category = "materials" },
	},
	scrollItems = {},
}

-- A rank is unlocked at its matching player level. Price growth follows the
-- rising enhancement risk and keeps early experimentation affordable.
local scrollPriceMultiplier = { Fighter = 1.0, Mage = 1.05, Healer = 1.1, Lucky = 1.15, Guardian = 1.0 }
for category, multiplier in pairs(scrollPriceMultiplier) do
	for level = 1, EnhancementConfig.MAX_ENHANCE_LEVEL do
		table.insert(Shop.scrollItems, {
			itemId = string.format("EnhanceScroll_%s_%d", category, level),
			price = math.floor((20 + level * level * 5) * multiplier),
			category = category,
			requiredLevel = level,
		})
	end
end

-- Compatibility for systems that still read Shop.items.
Shop.items = Shop.equipmentItems

function Shop.GetItems(shopType)
	return shopType == "enhancement" and Shop.scrollItems or Shop.equipmentItems
end

function Shop.GetSellPrice(buyPrice)
	return math.max(1, math.floor(buyPrice * Shop.sellPriceRatio))
end

function Shop.FindEntry(itemId)
	for _, list in { Shop.equipmentItems, Shop.scrollItems } do
		for _, entry in list do
			if entry.itemId == itemId then
				return entry
			end
		end
	end
	return nil
end

return Shop
