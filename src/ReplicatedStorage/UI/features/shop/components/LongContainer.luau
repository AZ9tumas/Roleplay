local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local ImageIds = require(ReplicatedStorage.Shared.Modules.Game.ImageIds)
local ProductButton = require(ReplicatedStorage.UI.core.components.ProductButton)
local TextLabel = require(ReplicatedStorage.UI.core.components.TextLabel)

local e = React.createElement

type LongContainerProps = {
	name: string?,
	imageId: string?,
	desc: string?,
	visible: boolean?,
	children: React.ReactNode?,
}

local LongContainer = React.forwardRef(function(props: LongContainerProps, ref: React.Ref<any>)
	local children = props.children or {}

	children = Sift.Dictionary.merge({
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 30),
		}),

		BuyButton = e(ProductButton, {
			Size = UDim2.fromOffset(212, 85),
			Position = UDim2.fromScale(0.83, 0.77),
			ImageId = ImageIds.productButton,
			ProductName = "LimitedMorphTest",
		}, {}),

		ProductIcon = e("ImageLabel", {
			Size = UDim2.fromOffset(200, 200),
			Position = UDim2.fromScale(0.15, 0.55),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://93390410",
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 2,
		}),

		SunBurst = e("ImageLabel", {
			Size = UDim2.fromOffset(270, 270),
			Position = UDim2.fromScale(0.15, 0.55),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = ImageIds.sunBurst,
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 1,
		}),

		ProductName = e(TextLabel, {
			Text = "Test Product",
			Size = UDim2.fromOffset(300, 100),
			Position = UDim2.fromScale(0.768, 0.4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			TextColor3 = Color3.new(1, 1, 1),
			Stroke = 2.5,
			StrokeColor = Color3.fromHex("#006597"),
			DropShadow = 0.4,
			DropShadowColor = Color3.fromHex("#006597"),
			Font = Enum.Font.SourceSansBold,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextSize = 50,
		}),

		Desc = e(TextLabel, {
			Text = "The best morph in-game!",
			Size = UDim2.fromScale(0.4, 0.2),
			Position = UDim2.fromScale(0.45, 0.77),
			AnchorPoint = Vector2.new(0.5, 0.5),
			TextColor3 = Color3.new(1, 1, 1),
			Stroke = 3,
			StrokeColor = Color3.fromHex("#006597"),
			DropShadow = 0.8,
			DropShadowColor = Color3.fromHex("#006597"),
			Font = Enum.Font.SourceSansBold,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),

		UIGradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("#74E1FF")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("#00BBFF")),
			}),
			Rotation = 90,
		}),
	}, children)

	return e("ImageLabel", {
		Size = UDim2.fromOffset(800, 220),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0,
		Visible = props.visible == nil and true or props.visible,
		Image = ImageIds.wavePattern,
		ImageTransparency = 0.9,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromScale(1, 3),
	}, children)
end)

return React.memo(LongContainer)
