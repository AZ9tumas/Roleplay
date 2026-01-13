local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactCharm = require(ReplicatedStorage.Packages.ReactCharm)
local Sift = require(ReplicatedStorage.Packages.Sift)
local ImageIds = require(ReplicatedStorage.Shared.Modules.Game.ImageIds)
local Morphs = require(ReplicatedStorage.Shared.Modules.Game.Morphs)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)
local Menu = require(ReplicatedStorage.UI.core.components.Menu)
local ProductButton = require(ReplicatedStorage.UI.core.components.ProductButton)
local TextLabel = require(ReplicatedStorage.UI.core.components.TextLabel)
local morphSlice = require(ReplicatedStorage.UI.features.morph.state.morphSlice)
local AmountContainer = require(ReplicatedStorage.UI.features.shop.components.AmountContainer)
local LongContainer = require(ReplicatedStorage.UI.features.shop.components.LongContainer)
local TimedContainer = require(ReplicatedStorage.UI.features.shop.components.TimedContainer)

local e = React.createElement

local function SmallGrid()
	return e("UIGridLayout", {
		CellSize = UDim2.fromOffset(400, 220),
		CellPadding = UDim2.fromOffset(17, 20),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})
end

local function LongList()
	return e("UIListLayout", {
		Padding = UDim.new(0, 20),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})
end

type SmallContainerProps = {
	imageId: string?,
	desc: string?,
}

local function SmallContainer(props: SmallContainerProps)
	return e("ImageLabel", {
		Size = UDim2.fromOffset(400, 220),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 30),
		}),

		BuyButton = e(ProductButton, {
			Size = UDim2.fromOffset(212, 85),
			Position = UDim2.fromScale(0.7, 0.77),
			ImageId = ImageIds.productButton,
			ProductName = "LimitedTimeMorphTest",
		}, {}),

		ProductIcon = e("ImageLabel", {
			Size = UDim2.fromOffset(200, 200),
			Position = UDim2.fromScale(0.2, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = "rbxassetid://93390410",
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
		}),

		Desc = e("TextLabel", {
			Size = UDim2.fromOffset(200, 100),
			Position = UDim2.fromScale(0.7, 0.3),
			AnchorPoint = Vector2.new(0.5, 0.5),
			TextColor3 = Color3.new(1, 1, 1),
			Text = props.desc or "Placeholder text",
			TextScaled = true,
			Font = Enum.Font.SourceSansBold,
			BackgroundTransparency = 1,
		}, {
			UIStroke = e("UIStroke", {
				Thickness = 4,
				Color = Color3.fromHex("#006597"),
			}),
		}),

		UIGradient = e("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("#74E1FF")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("#00BBFF")),
			}),
			Rotation = 90,
		}),
	})
end

type SectionProps = {
	name: string,
	children: React.ReactNode?,
}

local function Section(props: SectionProps)
	return e("Frame", {
		Size = UDim2.fromOffset(200, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		UIListLayout = e("UIListLayout", {
			Padding = UDim.new(0, 20),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
		}),

		TextLabel = e(TextLabel, {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			Text = props.name,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 70,
			Font = Enum.Font.SourceSansBold,
		}),

		Content = e("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
		}, props.children),
	})
end

return function()
	local soldMorphs = ReactCharm.useAtom(morphSlice.states.soldMorphs)

	local templates = {}
	for product, config in Products.ids do
		if not Morphs[product] then
			continue
		end

		if not soldMorphs[product] then
			continue
		end

		if config.limitedTime then
			templates[product] = e(TimedContainer, {
				productId = config.productId,
				productSaleData = soldMorphs,
			})
		elseif config.limitedAmount then
			print("Changed")
			templates[product] = e(AmountContainer, {
				productSaleData = soldMorphs,
				maxQuantity = config.limitedAmount,
				product = product,
			})
		else
			templates[product] = e(LongContainer, {})
		end
	end

	templates = Sift.Dictionary.join(templates, { Grid = e(LongList) })

	return e(Menu.component, {
		id = "Shop",
	}, {
		ShopList = e("ScrollingFrame", {
			Size = UDim2.fromScale(0.99, 0.8),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.55),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			CanvasSize = UDim2.fromOffset(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, {
			UIListLayout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			LimitedMorphs = e(Section, {
				name = "Limited Morphs",
			}, templates),

			Morphs = e(Section, {
				name = "Morphs",
			}, {
				Grid = e(LongList),

				e(LongContainer, {}),
			}),
		}),
	})
end
