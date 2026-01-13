local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)
local BasicButton = require(script.Parent.BasicButton)
local Button = require(ReplicatedStorage.UI.core.primitives.Button)
local purchaseSlice = require(ReplicatedStorage.UI.features.shop.state.purchaseSlice)

local e = React.createElement

type ProductButtonProps = {
	ProductName: string,
	HidePrice: boolean?,
}

local CUSTOM_PROPS = { "ProductId", "ProductType" }

return function(props: Button.ButtonProps & ProductButtonProps)
	local productInfo = React.useMemo(function()
		local productData = Products.getByName(props.ProductName)
		if not productData then
			return
		end

		local productType = productData.type == "DevProduct" and "Product" or "GamePass"

		return MarketplaceService:GetProductInfo(productData.productId, productType)
	end, {})

	local children = props.children or {}
	if not props.HidePrice then
		children = Sift.Dictionary.merge(children, {
			Price = e("TextLabel", {
				Size = UDim2.fromScale(0.6, 0.6),
				Position = UDim2.fromScale(0.5, 0.45),
				AnchorPoint = Vector2.new(0.5, 0.5),
				TextColor3 = Color3.new(1, 1, 1),
				Text = productInfo and productInfo.PriceInRobux .. "" or "Error",
				TextScaled = true,
				Font = Enum.Font.FredokaOne,
				BackgroundTransparency = 1,
			}, {
				UIStroke = e("UIStroke", {
					Color = Color3.fromRGB(48, 119, 0),
					Thickness = 4,
				}),
			}),
		})
	end

	local safeProps = Sift.Dictionary.removeKeys(props, table.unpack(CUSTOM_PROPS))
	local joinedProps = Sift.Dictionary.join(safeProps, {
		OnActivated = function()
			purchaseSlice.actions.setPurchase(true)

			Products.prompt(Players.LocalPlayer, props.ProductName)
		end,
	})

	return e(BasicButton, joinedProps, children)
end
