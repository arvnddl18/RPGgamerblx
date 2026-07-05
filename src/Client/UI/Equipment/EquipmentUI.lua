local EquipmentUI = {}
EquipmentUI.__index = EquipmentUI

local SLOT_ORDER = { "weapon", "helmet", "armor", "pants", "boots", "gloves" }
local SLOT_LABELS = {
	weapon = "Weapon",
	helmet = "Helmet",
	armor = "Armor",
	pants = "Pants",
	boots = "Boots",
	gloves = "Gloves",
}

function EquipmentUI.new(playerGui)
	local self = setmetatable({}, EquipmentUI)
	self._slots = {}
	self._onUnequip = nil

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EquipmentUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local panel = Instance.new("Frame")
	panel.Name = "EquipmentPanel"
	panel.Size = UDim2.new(0, 200, 0, 260)
	panel.Position = UDim2.new(1, -216, 0.5, -130)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui
	self._panel = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Position = UDim2.new(0, 8, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "Equipment (C)"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = panel

	for i, slot in SLOT_ORDER do
		local row = Instance.new("TextButton")
		row.Name = slot
		row.Size = UDim2.new(1, -16, 0, 34)
		row.Position = UDim2.new(0, 8, 0, 36 + (i - 1) * 36)
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		row.Text = SLOT_LABELS[slot] .. ": Empty"
		row.TextColor3 = Color3.fromRGB(200, 200, 220)
		row.Font = Enum.Font.Gotham
		row.TextSize = 12
		row.Parent = panel

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		row.MouseButton1Click:Connect(function()
			if self._onUnequip then
				self._onUnequip(slot)
			end
		end)

		self._slots[slot] = row
	end

	return self
end

function EquipmentUI:OnUnequip(callback)
	self._onUnequip = callback
end

function EquipmentUI:SetVisible(visible)
	self._panel.Visible = visible
end

function EquipmentUI:Update(equipped, itemsConfig)
	for slot, row in self._slots do
		local equippedEntry = equipped and equipped[slot]
		local itemId = type(equippedEntry) == "table" and equippedEntry.id or equippedEntry
		if itemId and itemsConfig[itemId] then
			local label = SLOT_LABELS[slot] .. ": " .. itemsConfig[itemId].name
			if type(equippedEntry) == "table" then
				if equippedEntry.rarity then
					label ..= " [" .. equippedEntry.rarity .. "]"
				end
				if equippedEntry.enhanceLevel and equippedEntry.enhanceLevel > 0 then
					label ..= " +" .. equippedEntry.enhanceLevel
				end
			end
			row.Text = label
		else
			row.Text = SLOT_LABELS[slot] .. ": Empty"
		end
	end
end

return EquipmentUI
