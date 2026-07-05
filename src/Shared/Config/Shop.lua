local Shop = {
	sellPriceRatio = 0.5,
	categories = { "weapons", "armor", "potions", "materials", "scrolls" },
	items = {
		{ itemId = "HealthPotion", price = 25, category = "potions" },
		{ itemId = "ManaPotion", price = 30, category = "potions" },
		{ itemId = "IronSword", price = 100, category = "weapons" },
		{ itemId = "Herb", price = 10, category = "materials" },
		{ itemId = "IronOre", price = 40, category = "materials" },
		{ itemId = "BeastHide", price = 45, category = "materials" },
		{ itemId = "ArcaneDust", price = 50, category = "materials" },
		-- SCROLLS ARE SHOP-ONLY — DO NOT ADD TO LOOT TABLES.
		{ itemId = "EnhanceScroll_5", price = 200, category = "scrolls", requiredLevel = 5 },
		{ itemId = "EnhanceScroll_10", price = 500, category = "scrolls", requiredLevel = 10 },
		{ itemId = "EnhanceScroll_15", price = 1200, category = "scrolls", requiredLevel = 15 },
		{ itemId = "EnhanceScroll_20", price = 3000, category = "scrolls", requiredLevel = 20 },
	},
}

function Shop.GetSellPrice(buyPrice)
	return math.max(1, math.floor(buyPrice * Shop.sellPriceRatio))
end

function Shop.FindEntry(itemId)
	for _, entry in Shop.items do
		if entry.itemId == itemId then
			return entry
		end
	end
	return nil
end

return Shop
