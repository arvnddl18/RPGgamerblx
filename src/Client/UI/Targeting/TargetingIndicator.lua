local TweenService = game:GetService("TweenService")

local TargetingIndicator = {}
TargetingIndicator.__index = TargetingIndicator

local VALID_COLOR = Color3.fromRGB(80, 220, 100)
local INVALID_COLOR = Color3.fromRGB(220, 70, 70)

local function createDisc(name, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Transparency = 0.55
	part.Color = VALID_COLOR
	part.Parent = parent
	return part
end

function TargetingIndicator.new(parentFolder)
	local self = setmetatable({}, TargetingIndicator)

	local folder = Instance.new("Folder")
	folder.Name = "TargetingIndicators"
	folder.Parent = parentFolder or workspace
	self._folder = folder

	self._rangeRing = createDisc("RangeRing", folder)
	self._aoeDisc = createDisc("AoeDisc", folder)
	self._isVisible = false
	self._isValid = true

	self:Hide()
	return self
end

function TargetingIndicator:_setDiscSize(part, radius, thickness)
	local diameter = math.max(radius * 2, 0.5)
	part.Size = Vector3.new(diameter, thickness, diameter)
end

function TargetingIndicator:SetValid(isValid)
	self._isValid = isValid
	local color = isValid and VALID_COLOR or INVALID_COLOR
	self._rangeRing.Color = color
	self._aoeDisc.Color = color
end

function TargetingIndicator:SetRangeRing(position, radius)
	self:_setDiscSize(self._rangeRing, radius, 0.15)
	self._rangeRing.CFrame = CFrame.new(position.X, position.Y + 0.1, position.Z)
end

function TargetingIndicator:SetAoeDisc(position, radius)
	self:_setDiscSize(self._aoeDisc, radius, 0.2)
	self._aoeDisc.CFrame = CFrame.new(position.X, position.Y + 0.15, position.Z)
end

function TargetingIndicator:Show(showRange, showAoe)
	self._isVisible = true
	self._rangeRing.Transparency = showRange and 0.55 or 1
	self._aoeDisc.Transparency = showAoe and 0.5 or 1
end

function TargetingIndicator:Hide()
	self._isVisible = false
	self._rangeRing.Transparency = 1
	self._aoeDisc.Transparency = 1
end

function TargetingIndicator:FadeOut(duration)
	duration = duration or 0.15
	if not self._isVisible then
		return
	end

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(self._rangeRing, tweenInfo, { Transparency = 1 }):Play()
	local tween = TweenService:Create(self._aoeDisc, tweenInfo, { Transparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		self._isVisible = false
	end)
end

function TargetingIndicator:Destroy()
	if self._folder then
		self._folder:Destroy()
	end
end

return TargetingIndicator
