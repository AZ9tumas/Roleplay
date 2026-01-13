local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LongContainer = require(script.Parent.LongContainer)
local React = require(ReplicatedStorage.Packages.React)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)
local TextLabel = require(ReplicatedStorage.UI.core.components.TextLabel)
local useCountdown = require(ReplicatedStorage.UI.core.hooks.useCountdown)

local e = React.createElement

type TimedContainerProps = {
	productId: number,
	productSaleData: { [string]: number },
}

return React.forwardRef(function(props: TimedContainerProps, ref: React.Ref<any>)
	local config = React.useMemo(function()
		local product = Products.getById(props.productId)
		local timeLimit = product and product.limitedTime
		local saleTime = product and props.productSaleData[product.key]

		return {
			timeLimit = timeLimit,
			saleTime = saleTime,
		}
	end, { props.productId, props.productSaleData })

	if config.timeLimit and config.saleTime then
		local countdown = useCountdown(config.saleTime, config.timeLimit)

		return e(LongContainer, {
			visible = not countdown.completed,
		}, {
			timer = e(TextLabel, {
				Size = UDim2.fromOffset(400, 100),
				Position = UDim2.fromScale(0.7, 0.15),
				Text = countdown.timer.formatted .. " Left!",
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
	end

	return {}
end)
