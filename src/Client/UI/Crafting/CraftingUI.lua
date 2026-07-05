local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Items = require(Shared.Config.Items)
local CraftingConfig = require(Shared.Config.CraftingConfig)
local RarityConfig = require(Shared.Config.RarityConfig)

local CraftingUI = {}
CraftingUI.__index = CraftingUI

function CraftingUI.new(playerGui)
	local self = setmetatable({}, CraftingUI)
	self._recipes = {}
	self._inventory = {}
	self._equipped = {}
	self._classId = nil
	self._onCraft = nil
	self._onUpgrade = nil
	self._selectedRecipe = nil
	self._selectedTargetUid = nil
	self._activeTab = "upgrade"
	self._busy = false

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CraftingUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 440, 0, 460)
	panel.Position = UDim2.new(0.5, -220, 0.5, -230)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = screenGui
	self._panel = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 0, 36)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "Crafting"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -42, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = panel
	closeBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	self._preview = Instance.new("TextLabel")
	self._preview.Size = UDim2.new(1, -20, 0, 80)
	self._preview.Position = UDim2.new(0, 10, 1, -90)
	self._preview.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	self._preview.Text = "Select a recipe and item."
	self._preview.TextColor3 = Color3.fromRGB(200, 200, 200)
	self._preview.Font = Enum.Font.Gotham
	self._preview.TextSize = 12
	self._preview.TextWrapped = true
	self._preview.TextYAlignment = Enum.TextYAlignment.Top
	self._preview.Parent = panel

	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 6)
	previewCorner.Parent = self._preview

	self._confirmBtn = Instance.new("TextButton")
	self._confirmBtn.Size = UDim2.new(0, 120, 0, 32)
	self._confirmBtn.Position = UDim2.new(1, -130, 1, -42)
	self._confirmBtn.BackgroundColor3 = Color3.fromRGB(80, 140, 80)
	self._confirmBtn.Text = "Confirm"
	self._confirmBtn.TextColor3 = Color3.new(1, 1, 1)
	self._confirmBtn.Font = Enum.Font.GothamBold
	self._confirmBtn.Parent = panel
	self._confirmBtn.MouseButton1Click:Connect(function()
		if self._busy then
			return
		end
		if self._activeTab == "potions" and self._selectedRecipe and self._onCraft then
			self._busy = true
			self._confirmBtn.Text = "..."
			self._onCraft(self._selectedRecipe.id)
		elseif self._activeTab == "upgrade" and self._selectedRecipe and self._selectedTargetUid and self._onUpgrade then
			self._busy = true
			self._confirmBtn.Text = "..."
			self._onUpgrade(self._selectedRecipe.id, self._selectedTargetUid)
		end
	end)

	local list = Instance.new("ScrollingFrame")
	list.Size = UDim2.new(1, -20, 1, -180)
	list.Position = UDim2.new(0, 10, 0, 92)
	list.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.Parent = panel
	self._list = list

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list

	local tabBar = Instance.new("Frame")
	tabBar.Size = UDim2.new(1, -20, 0, 36)
	tabBar.Position = UDim2.new(0, 10, 0, 48)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent = panel
	self._tabBar = tabBar

	self._tabButtons = {}
	for i, tabId in { "upgrade", "potions" } do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.5, -4, 1, 0)
		btn.Position = UDim2.new((i - 1) * 0.5, (i - 1) * 4, 0, 0)
		btn.BackgroundColor3 = tabId == self._activeTab and Color3.fromRGB(80, 100, 180) or Color3.fromRGB(45, 45, 60)
		btn.Text = tabId == "upgrade" and "Rarity Upgrade" or "Potions"
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.Parent = tabBar
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn
		btn.MouseButton1Click:Connect(function()
			self:SetTab(tabId)
		end)
		self._tabButtons[tabId] = btn
	end

	return self
end

function CraftingUI:SetTab(tabId)
	self._activeTab = tabId
	self._selectedRecipe = nil
	self._selectedTargetUid = nil
	for id, btn in self._tabButtons do
		btn.BackgroundColor3 = id == tabId and Color3.fromRGB(80, 100, 180) or Color3.fromRGB(45, 45, 60)
	end
	self:_render()
end

function CraftingUI:OnCraft(callback)
	self._onCraft = callback
end

function CraftingUI:OnUpgrade(callback)
	self._onUpgrade = callback
end

function CraftingUI:SetBusy(busy)
	self._busy = busy
	self._confirmBtn.Text = busy and "..." or "Confirm"
end

function CraftingUI:SetEquipped(equipped)
	self._equipped = equipped or {}
	self:_render()
end

function CraftingUI:SetInventory(inventory)
	self._inventory = inventory or {}
	self:_render()
end

function CraftingUI:SetClassId(classId)
	self._classId = classId
	self:_render()
end

function CraftingUI:SetRecipes(recipes)
	self._recipes = recipes or {}
	self:_render()
end

function CraftingUI:SetVisible(visible)
	self._panel.Visible = visible
	if visible then
		self:_render()
	end
end

function CraftingUI:_updatePreview()
	if not self._selectedRecipe then
		self._preview.Text = "Select a recipe and item."
		return
	end

	if self._selectedRecipe.type == "consumable" then
		local mats = ""
		for _, mat in self._selectedRecipe.materials or {} do
			mats ..= mat.amount .. "x " .. mat.itemId .. "  "
		end
		self._preview.Text = "Craft " .. (self._selectedRecipe.resultItem or "") .. "\nMaterials: " .. mats .. "\n(No destroy risk)"
		return
	end

	if not self._selectedTargetUid then
		self._preview.Text = "Select gear to upgrade rarity."
		return
	end

	local targetEntry = nil
	for _, entry in self._inventory do
		if entry.uid == self._selectedTargetUid then
			targetEntry = entry
			break
		end
	end
	if not targetEntry then
		for _, slot in { "weapon", "helmet", "armor", "pants", "boots", "gloves" } do
			local e = self._equipped[slot]
			if type(e) == "table" and e.uid == self._selectedTargetUid then
				targetEntry = e
				break
			end
		end
	end
	if not targetEntry then
		self._preview.Text = "Item not found."
		return
	end

	local currentRarity = targetEntry.rarity or "Common"
	local targetRarity = RarityConfig.GetNextRarity(currentRarity)
	if not targetRarity then
		self._preview.Text = "Already max rarity."
		return
	end

	local attempt = CraftingConfig.GetUpgradeAttempt(targetRarity)
	if not attempt then
		self._preview.Text = "No upgrade data."
		return
	end

	local matId = self._selectedRecipe.materials[1] and self._selectedRecipe.materials[1].itemId or "?"
	self._preview.Text = string.format(
		"%s → %s\n%d x %s (%s+)\nGold: %d\nSuccess: %d%%  Fail: %d%%  Destroy: %d%%",
		currentRarity,
		targetRarity,
		attempt.materialAmount,
		matId,
		attempt.materialMinRarity,
		attempt.goldCost,
		math.floor(attempt.success * 100),
		math.floor(attempt.fail * 100),
		math.floor(attempt.destroy * 100)
	)
end

function CraftingUI:_render()
	for _, child in self._list:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for _, recipe in self._recipes do
		local isUpgrade = recipe.type == "equipmentUpgrade"
		if isUpgrade and self._activeTab ~= "upgrade" then
			-- skip
		elseif not isUpgrade and self._activeTab ~= "potions" then
			-- skip
		elseif isUpgrade and recipe.classRestriction and recipe.classRestriction ~= self._classId then
			-- skip class-mismatched upgrade recipes
		elseif isUpgrade then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -8, 0, 36)
			btn.BackgroundColor3 = self._selectedRecipe == recipe and Color3.fromRGB(80, 100, 180) or Color3.fromRGB(45, 45, 60)
			btn.Text = "Upgrade " .. (recipe.slot or "gear") .. " (" .. (recipe.classRestriction or "any") .. ")"
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 13
			btn.Parent = self._list
			btn.MouseButton1Click:Connect(function()
				self._selectedRecipe = recipe
				self._activeTab = "upgrade"
				self._selectedTargetUid = nil
				self:_render()
			end)

			if self._selectedRecipe == recipe then
				local function addTargetRow(entry)
					local item = Items[entry.id]
					if not item then return end
					local row = Instance.new("TextButton")
					row.Size = UDim2.new(1, -8, 0, 40)
					row.BackgroundColor3 = self._selectedTargetUid == entry.uid and Color3.fromRGB(60, 120, 80) or Color3.fromRGB(35, 35, 50)
					local rarity = entry.rarity or "Common"
					local mult = entry.statMultiplier and string.format("%.2f", entry.statMultiplier) or "?"
					row.Text = item.name .. "  [" .. rarity .. " x" .. mult .. "]"
					row.TextColor3 = RarityConfig.GetColor(rarity)
					row.Font = Enum.Font.Gotham
					row.TextSize = 12
					row.Parent = self._list
					row.MouseButton1Click:Connect(function()
						self._selectedTargetUid = entry.uid
						self:_updatePreview()
						self:_render()
					end)
				end

				for _, entry in self._inventory do
					local item = Items[entry.id]
					if item and item.slot == recipe.slot
						and (not recipe.classRestriction or item.classRestriction == recipe.classRestriction)
						and entry.uid
					then
						addTargetRow(entry)
					end
				end
				for _, slot in { "weapon", "helmet", "armor", "pants", "boots", "gloves" } do
					local entry = self._equipped[slot]
					if type(entry) == "table" and entry.uid then
						local item = Items[entry.id]
						if item and item.slot == recipe.slot
							and (not recipe.classRestriction or item.classRestriction == recipe.classRestriction)
						then
							local row = Instance.new("TextButton")
							row.Size = UDim2.new(1, -8, 0, 40)
							row.BackgroundColor3 = self._selectedTargetUid == entry.uid and Color3.fromRGB(60, 120, 80) or Color3.fromRGB(35, 35, 50)
							local rarity = entry.rarity or "Common"
							local mult = entry.statMultiplier and string.format("%.2f", entry.statMultiplier) or "?"
							row.Text = "(Equipped) " .. item.name .. "  [" .. rarity .. " x" .. mult .. "]"
							row.TextColor3 = RarityConfig.GetColor(rarity)
							row.Font = Enum.Font.Gotham
							row.TextSize = 12
							row.Parent = self._list
							row.MouseButton1Click:Connect(function()
								self._selectedTargetUid = entry.uid
								self:_updatePreview()
								self:_render()
							end)
						end
					end
				end
			end
		else
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -8, 0, 36)
			btn.BackgroundColor3 = self._selectedRecipe == recipe and Color3.fromRGB(80, 100, 180) or Color3.fromRGB(45, 45, 60)
			btn.Text = "Craft " .. (recipe.resultItem or recipe.id)
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 13
			btn.Parent = self._list
			btn.MouseButton1Click:Connect(function()
				self._selectedRecipe = recipe
				self._activeTab = "potions"
				self:_updatePreview()
				self:_render()
			end)
		end
	end

	self:_updatePreview()
	task.defer(function()
		local layout = self._list:FindFirstChildOfClass("UIListLayout")
		if layout then
			self._list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
		end
	end)
end

return CraftingUI
