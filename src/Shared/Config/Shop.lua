local Shop = {
	sellPriceRatio = 0.5,
	categories = { "weapons", "armor", "potions", "materials" },
	items = {
		{ itemId = "HealthPotion", price = 25, category = "potions" },
		{ itemId = "ManaPotion", price = 30, category = "potions" },
		{ itemId = "IronSword", price = 100, category = "weapons" },
		{ itemId = "Herb", price = 10, category = "materials" },
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
