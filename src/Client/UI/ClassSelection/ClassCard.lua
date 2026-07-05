local ClassCard = {}
ClassCard.__index = ClassCard

function ClassCard.new(parent, classConfig, onSelect)
	local self = setmetatable({}, ClassCard)
	self._classConfig = classConfig
	self._onSelect = onSelect
	self._selected = false
	self._frame = ClassCard._build(parent, classConfig, function()
		onSelect(classConfig.id)
	end)
	return self
end

function ClassCard._build(parent, classConfig, onClick)
	local card = Instance.new("TextButton")
	card.Name = classConfig.id .. "Card"
	card.Size = UDim2.new(0, 180, 0, 260)
	card.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	card.BorderSizePixel = 0
	card.AutoButtonColor = true
	card.Text = ""
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(1, 0, 0, 4)
	accent.BackgroundColor3 = classConfig.accentColor
	accent.BorderSizePixel = 0
	accent.Parent = card

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 10)
	accentCorner.Parent = accent

	local icon = Instance.new("Frame")
	icon.Size = UDim2.new(0, 56, 0, 56)
	icon.Position = UDim2.new(0.5, -28, 0, 16)
	icon.BackgroundColor3 = classConfig.accentColor
	icon.BorderSizePixel = 0
	icon.Parent = card

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = icon

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -16, 0, 28)
	nameLabel.Position = UDim2.new(0, 8, 0, 80)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = classConfig.displayName
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 18
	nameLabel.Parent = card

	local roleLabel = Instance.new("TextLabel")
	roleLabel.Size = UDim2.new(1, -16, 0, 18)
	roleLabel.Position = UDim2.new(0, 8, 0, 108)
	roleLabel.BackgroundTransparency = 1
	roleLabel.Text = classConfig.role
	roleLabel.TextColor3 = classConfig.accentColor
	roleLabel.Font = Enum.Font.Gotham
	roleLabel.TextSize = 12
	roleLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -16, 0, 48)
	descLabel.Position = UDim2.new(0, 8, 0, 130)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = classConfig.description
	descLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 11
	descLabel.TextWrapped = true
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Parent = card

	local stats = classConfig.baseStats
	local statsText = string.format(
		"HP: %d  Mana: %d\nATK: %d  MAG: %d\nDEF: %d  SPD: %d",
		stats.maxHp,
		stats.maxMana,
		stats.physicalAttack,
		stats.magicAttack,
		stats.defense,
		stats.movementSpeed
	)

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.new(1, -16, 0, 56)
	statsLabel.Position = UDim2.new(0, 8, 0, 182)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = statsText
	statsLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	statsLabel.Font = Enum.Font.Gotham
	statsLabel.TextSize = 11
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.TextYAlignment = Enum.TextYAlignment.Top
	statsLabel.Parent = card

	card.MouseButton1Click:Connect(onClick)
	return card
end

function ClassCard:SetSelected(selected)
	self._selected = selected
	if selected then
		self._frame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	else
		self._frame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	end
end

function ClassCard:Destroy()
	if self._frame then
		self._frame:Destroy()
	end
end

return ClassCard
