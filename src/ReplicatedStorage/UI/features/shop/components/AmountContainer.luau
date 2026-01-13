local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LongContainer = require(script.Parent.LongContainer)
local React = require(ReplicatedStorage.Packages.React)
local TextLabel = require(ReplicatedStorage.UI.core.components.TextLabel)

local e = React.createElement

type TimedContainerProps = {
	productSaleData: { [string]: number },
	maxQuantity: number,
	product: string,
}

return React.forwardRef(function(props: TimedContainerProps, ref: React.Ref<any>)
	local currentSold = React.useMemo(function()
		print(props.productSaleData[props.product])
		return props.productSaleData[props.product]
	end, { props.product, props.productSaleData })

	return e(LongContainer, {
		visible = if currentSold >= props.maxQuantity then false else true,

		ref = ref,
	}, {
		timer = e(TextLabel, {
			Size = UDim2.fromOffset(400, 100),
			Position = UDim2.fromScale(0.7, 0.15),
			Text = `{(props.maxQuantity - currentSold)}/{props.maxQuantity} Available!`,
			DropShadow = 0.4,
			Stroke = 3,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextSize = 45,
		}),
		limitedTag = e(TextLabel, {
			Size = UDim2.fromOffset(400, 100),
			Position = UDim2.fromScale(0.27, 0.15),
			Text = "Limited!",
			DropShadow = 0.4,
			DropShadownColor = Color3.fromRGB(70, 22, 22),
			StrokeColor = Color3.fromRGB(70, 22, 22),
			Stroke = 3,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor = Color3.fromRGB(255, 74, 74),
			TextSize = 30,
		}),
	})
end)
