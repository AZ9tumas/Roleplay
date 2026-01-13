local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local ImageIds = require(ReplicatedStorage.Shared.Modules.Game.ImageIds)
local Morphs = require(ReplicatedStorage.Shared.Modules.Game.Morphs)
local MorphServiceClient = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceClient)
local BasicButton = require(ReplicatedStorage.UI.core.components.BasicButton)
local TextLabel = require(ReplicatedStorage.UI.core.components.TextLabel)

local e = React.createElement

type MorphTemplate = {
	MorphId: string,
	Equipped: boolean,
	Shown: boolean,
	LayoutOrder: number,
	Own: boolean,
}

local MorphTemplate = React.forwardRef(function(props: MorphTemplate, ref: React.Ref<any>)
	local equipped, id = props.Equipped, props.MorphId

	local morphData = React.useMemo(function()
		return Morphs[id]
	end)

	local safeChildren = {
		PurchaseButton = e(BasicButton, {
			Size = UDim2.fromOffset(212, 85),
			Position = UDim2.fromScale(0.5, 0.85),
			ImageId = equipped and ImageIds.redButton or ImageIds.greenButton,

			OnActivated = function()
				if equipped then
					MorphServiceClient:unequipMorph()
				else
					MorphServiceClient:equipMorph(id)
				end
			end,

			Disabled = not props.Own,
		}, {
			TextLabel = e(TextLabel, {
				Size = UDim2.fromScale(0.4, 0.4),
				Position = UDim2.fromScale(0.5, 0.45),
				Text = equipped and "Unequip" or "Equip",
				Stroke = 4,
				StrokeColor = equipped and Color3.fromHex("#860000") or Color3.fromHex("#328300"),
			}),
		}),
		MorphName = e(TextLabel, {
			Size = UDim2.fromScale(0.8, 0.1),
			Position = UDim2.fromScale(0.5, 0.1),
			Text = morphData.displayName,
			Stroke = 4,
			StrokeColor = Color3.fromHex("#000000"),
		}),
	}

	if not props.Own then
		safeChildren = Sift.Dictionary.merge(safeChildren, {
			Locked = e("ImageButton", {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = ImageIds.lock,
				ScaleType = Enum.ScaleType.Fit,
				BackgroundTransparency = 0.3,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				ZIndex = 3,

				[React.Event.Activated] = function()
					MorphServiceClient:purchaseMorph(props.MorphId)
				end,
			}, {
				UICorner = e("UICorner", {
					CornerRadius = UDim.new(0, 19),
				}),
				TextLabel = e(TextLabel, {
					Text = "Click To Unlock!",
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(0.8, 0.2),
					Stroke = 3,
				}),
			}),
		})
	end

	return e("ImageLabel", {
		Image = ImageIds.morphTemplateBackground,
		BackgroundTransparency = 1,
		Visible = props.Shown,
		LayoutOrder = props.LayoutOrder,

		ref = ref,
	}, safeChildren)
end)

return React.memo(MorphTemplate)
