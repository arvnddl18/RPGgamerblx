local TweenService = game:GetService("TweenService")

local FastTravelFadeUI = {}
FastTravelFadeUI.__index = FastTravelFadeUI

function FastTravelFadeUI.new(playerGui)
	local self = setmetatable({}, FastTravelFadeUI)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FastTravelFadeUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = playerGui
	self._screenGui = screenGui

	local overlay = Instance.new("Frame")
	overlay.Name = "FadeOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.Visible = false
	overlay.ZIndex = 100
	overlay.Parent = screenGui
	self._overlay = overlay

	return self
end

function FastTravelFadeUI:FadeOut(duration, callback)
	duration = duration or 0.4
	self._overlay.Visible = true
	self._overlay.BackgroundTransparency = 1

	local tween = TweenService:Create(self._overlay, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	})
	tween:Play()
	tween.Completed:Connect(function()
		if callback then
			callback()
		end
	end)
end

function FastTravelFadeUI:FadeIn(duration, callback)
	duration = duration or 0.4
	self._overlay.BackgroundTransparency = 0
	self._overlay.Visible = true

	local tween = TweenService:Create(self._overlay, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		self._overlay.Visible = false
		if callback then
			callback()
		end
	end)
end

return FastTravelFadeUI
