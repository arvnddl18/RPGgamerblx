local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skills = require(Shared.Config.Skills)
local Items = require(Shared.Config.Items)
local CooldownOverlay = require(script.Parent.CooldownOverlay)

local SkillBarUI = {}
SkillBarUI.__index = SkillBarUI
SkillBarUI.AutofarmToggleRequested = Instance.new("BindableEvent")
SkillBarUI._active = nil

local SLOT_LABELS = { "1", "2", "3", "4", "5", "6", "7" }
local POTION_NAMES = { [6] = "HP Pot", [7] = "MP Pot" }

-- Desaturate a colour towards 60% gray to visually indicate "disabled" during cooldown.
local function desaturateColor(color, factor)
	factor = factor or 0.6
	local gray = color.R * 0.299 + color.G * 0.587 + color.B * 0.114
	return Color3.new(
		color.R + (gray - color.R) * factor,
		color.G + (gray - color.G) * factor,
		color.B + (gray - color.B) * factor
	)
end

function SkillBarUI.new(playerGui)
	local self = setmetatable({}, SkillBarUI)
	SkillBarUI._active = self
	self._slots = {}
	self._cooldownEnds = {}
	self._mana = 0
	self._masteryRank = 1
	self._hasSelectedClass = false

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SkillBarUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local actionBar = Instance.new("Frame")
	actionBar.Name = "ActionBar"
	actionBar.Size = UDim2.new(0, 400, 0, 60)
	actionBar.Position = UDim2.new(0.5, -200, 1, -70)
	actionBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	actionBar.BackgroundTransparency = 0.5
	actionBar.BorderSizePixel = 0
	actionBar.Visible = false
	actionBar.Parent = screenGui
	self._actionBar = actionBar

	local autofarmButton = Instance.new("TextButton")
	autofarmButton.Name = "AutofarmButton"
	autofarmButton.Size = UDim2.new(0, 46, 0, 46)
	autofarmButton.Position = UDim2.new(0.5, -266, 1, -70)
	autofarmButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	autofarmButton.BackgroundTransparency = 0
	autofarmButton.BorderSizePixel = 0
	autofarmButton.AutoButtonColor = false
	autofarmButton.Text = ""
	autofarmButton.Visible = false
	autofarmButton.ZIndex = 2
	autofarmButton.Parent = screenGui

	local autofarmCorner = Instance.new("UICorner")
	autofarmCorner.CornerRadius = UDim.new(0, 6)
	autofarmCorner.Parent = autofarmButton

	local autofarmStroke = Instance.new("UIStroke")
	autofarmStroke.Color = Color3.fromRGB(85, 85, 105)
	autofarmStroke.Thickness = 1
	autofarmStroke.Parent = autofarmButton

	local autofarmLabel = Instance.new("TextLabel")
	autofarmLabel.Name = "Label"
	autofarmLabel.Size = UDim2.new(1, 0, 1, -14)
	autofarmLabel.Position = UDim2.new(0, 0, 0, 0)
	autofarmLabel.BackgroundTransparency = 1
	autofarmLabel.Text = "AUTO"
	autofarmLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	autofarmLabel.Font = Enum.Font.GothamBold
	autofarmLabel.TextSize = 11
	autofarmLabel.ZIndex = 3
	autofarmLabel.Parent = autofarmButton

	local autofarmKeyLabel = Instance.new("TextLabel")
	autofarmKeyLabel.Name = "KeyLabel"
	autofarmKeyLabel.Size = UDim2.new(1, 0, 0, 14)
	autofarmKeyLabel.Position = UDim2.new(0, 0, 1, -18)
	autofarmKeyLabel.BackgroundTransparency = 1
	autofarmKeyLabel.Text = "F"
	autofarmKeyLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	autofarmKeyLabel.Font = Enum.Font.GothamBold
	autofarmKeyLabel.TextSize = 8
	autofarmKeyLabel.ZIndex = 3
	autofarmKeyLabel.Parent = autofarmButton

	autofarmButton.Activated:Connect(function()
		SkillBarUI.AutofarmToggleRequested:Fire()
	end)

	self._autofarmButton = autofarmButton
	self._autofarmStroke = autofarmStroke

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = actionBar

	for i = 1, 7 do
		local slotFrame = Instance.new("Frame")
		slotFrame.Name = "Slot" .. i
		slotFrame.Size = UDim2.new(0, 46, 0, 46)
		slotFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		slotFrame.BorderSizePixel = 0
		slotFrame.Parent = actionBar

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = slotFrame

		local icon = Instance.new("Frame")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, -6, 1, -6)
		icon.Position = UDim2.new(0, 3, 0, 3)
		icon.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
		icon.BorderSizePixel = 0
		icon.Parent = slotFrame

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0, 4)
		iconCorner.Parent = icon

		local keyLabel = Instance.new("TextLabel")
		keyLabel.Size = UDim2.new(0, 16, 0, 16)
		keyLabel.Position = UDim2.new(0, 2, 0, 2)
		keyLabel.BackgroundTransparency = 1
		keyLabel.Text = SLOT_LABELS[i]
		keyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.TextSize = 10
		keyLabel.TextXAlignment = Enum.TextXAlignment.Left
		keyLabel.Parent = slotFrame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 14)
		nameLabel.Position = UDim2.new(0, 0, 1, -14)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = POTION_NAMES[i] or ("Skill " .. i)
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 8
		nameLabel.Parent = slotFrame

		-- Clock-wipe cooldown overlay (EditableImage-based pie wipe)
		local overlay = CooldownOverlay.Create(slotFrame)

		-- Gray overlay for mana-locked / mastery-locked state (NOT cooldown)
		local grayOverlay = Instance.new("Frame")
		grayOverlay.Name = "Unavailable"
		grayOverlay.Size = UDim2.new(1, 0, 1, 0)
		grayOverlay.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		grayOverlay.BackgroundTransparency = 0.5
		grayOverlay.BorderSizePixel = 0
		grayOverlay.Visible = false
		grayOverlay.ZIndex = 1
		grayOverlay.Parent = slotFrame

		local lockLabel = Instance.new("TextLabel")
		lockLabel.Name = "LockLabel"
		lockLabel.Size = UDim2.new(1, 0, 1, 0)
		lockLabel.BackgroundTransparency = 1
		lockLabel.Text = ""
		lockLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		lockLabel.Font = Enum.Font.GothamBold
		lockLabel.TextSize = 10
		lockLabel.ZIndex = 2
		lockLabel.Visible = false
		lockLabel.Parent = slotFrame

		self._slots[i] = {
			frame = slotFrame,
			icon = icon,
			nameLabel = nameLabel,
			cooldownOverlay = overlay,
			grayOverlay = grayOverlay,
			lockLabel = lockLabel,
			skillId = nil,
			manaCost = 0,
			requiredMasteryRank = 1,
			originalColor = icon.BackgroundColor3,
		}
	end

	return self
end

function SkillBarUI.SetAutofarmState(enabled)
	local self = SkillBarUI._active
	if not self or not self._autofarmButton then
		return
	end

	self._autofarmButton.BackgroundColor3 = enabled
		and Color3.fromRGB(70, 95, 55)
		or Color3.fromRGB(40, 40, 55)
	self._autofarmStroke.Color = enabled
		and Color3.fromRGB(160, 210, 95)
		or Color3.fromRGB(85, 85, 105)
end

function SkillBarUI:GetSkillMeta(skillId)
	if skillId == "HealthPotion" then
		local item = Items.HealthPotion
		return item.name, item.color, 0
	end
	if skillId == "ManaPotion" then
		local item = Items.ManaPotion
		return item.name, item.color, 0
	end
	local skill = Skills[skillId]
	if skill then
		return skill.name, Color3.fromRGB(90, 120, 180), skill.manaCost or 0
	end
	return "?", Color3.fromRGB(60, 60, 60), 0
end

function SkillBarUI:UpdateLoadout(skillLoadout)
	for i = 1, 7 do
		local slot = self._slots[i]
		local skillId = skillLoadout and skillLoadout[i]
		slot.skillId = skillId
		if skillId then
			local name, color, manaCost = self:GetSkillMeta(skillId)
			slot.nameLabel.Text = name
			slot.icon.BackgroundColor3 = color
			slot.originalColor = color
			slot.manaCost = manaCost
			-- Mastery, rather than character level, controls class skill availability.
			local skillConfig = Skills[skillId]
			slot.requiredMasteryRank = skillConfig and skillConfig.requiredMasteryRank or 1
		end
	end
	self:RefreshAvailability()
end

function SkillBarUI:SetMana(mana)
	self._mana = mana
	self:RefreshAvailability()
end

function SkillBarUI:SetMasteryRank(rank)
	self._masteryRank = rank or 1
	self:RefreshAvailability()
end

function SkillBarUI:SetVisible(hasSelectedClass)
	self._hasSelectedClass = hasSelectedClass
	self._actionBar.Visible = hasSelectedClass
	self._autofarmButton.Visible = hasSelectedClass
end

function SkillBarUI:RefreshAvailability()
	for i = 1, 7 do
		local slot = self._slots[i]
		local onCooldown = slot.skillId and self._cooldownEnds[slot.skillId] and tick() < self._cooldownEnds[slot.skillId]
		local locked = slot.requiredMasteryRank > (self._masteryRank or 1)
		local notEnoughMana = slot.manaCost > 0 and self._mana < slot.manaCost

		if locked and self._hasSelectedClass then
			slot.grayOverlay.Visible = true
			slot.lockLabel.Visible = true
			slot.lockLabel.Text = "Rank " .. slot.requiredMasteryRank
		else
			slot.lockLabel.Visible = false
			slot.grayOverlay.Visible = not onCooldown and notEnoughMana and self._hasSelectedClass
		end
	end
end

function SkillBarUI:StartCooldown(skillId, duration, serverTime)
	-- serverTime is the server's tick() when the cooldown started.
	-- Used to reconcile network latency so the visual wipe stays accurate.
	local startTime = serverTime or tick()

	for i, slot in self._slots do
		if slot.skillId == skillId then
			-- Record cooldown end time for RefreshAvailability checks
			self._cooldownEnds[skillId] = startTime + duration

			-- Desaturate the icon to indicate "disabled"
			slot.icon.BackgroundColor3 = desaturateColor(slot.originalColor)

			-- Start the clock-wipe overlay animation
			CooldownOverlay.StartCooldown(slot.cooldownOverlay, startTime, duration, function()
				-- Cooldown finished → restore icon and clear state
				self._cooldownEnds[skillId] = nil
				slot.icon.BackgroundColor3 = slot.originalColor
				self:RefreshAvailability()
			end)
			break
		end
	end
end

return SkillBarUI
