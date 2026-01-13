local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Charm = require(ReplicatedStorage.Packages.Charm)
local React = require(ReplicatedStorage.Packages.React)
local ImageIds = require(ReplicatedStorage.Shared.Modules.Game.ImageIds)
local Menu = require(ReplicatedStorage.UI.core.components.Menu)
local SlideOutFrame = require(ReplicatedStorage.UI.core.components.SlideOutFrame)
local HudButton = require(ReplicatedStorage.UI.features.hud.components.HudButton)
local purchaseSlice = require(ReplicatedStorage.UI.features.shop.state.purchaseSlice)

local e = React.createElement

local function morphButton()
	return e(HudButton, {
		ButtonIcon = ImageIds.box,
		ButtonTitle = "Find the \nmorphs!",
		ImageId = ImageIds.hudbuttons.pink,
		TitleStroke = Color3.fromRGB(105, 0, 100),

		Size = UDim2.fromOffset(188, 155),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,

		OnActivated = function()
			Menu.set("Morph")
		end,
	})
end

local function shopButton()
	return e(HudButton, {
		ButtonIcon = ImageIds.shop,
		ButtonTitle = "Shop",
		ImageId = ImageIds.hudbuttons.yellow,
		TitleStroke = Color3.fromRGB(70, 40, 0),

		Size = UDim2.fromOffset(188, 155),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,

		OnActivated = function()
			Menu.set("Shop")
		end,
	})
end

return function()
	local shown, setShown = React.useState(true)
	return e(SlideOutFrame, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(150, 400),
		BackgroundTransparency = 1,

		From = UDim2.fromScale(0.07, 0.5),
		To = UDim2.fromScale(-0.1, 0.5),
		Shown = shown,
	}, {
		UIListLayout = e("UIListLayout", {
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 20),
		}),
		MorphButton = e(morphButton),
		ShopButton = e(shopButton),
	})
end
