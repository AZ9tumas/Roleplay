local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local ImageIds = require(ReplicatedStorage.Shared.Modules.Game.ImageIds)
local TextLabel = require(ReplicatedStorage.UI.core.components.TextLabel)
local useSpring = require(ReplicatedStorage.UI.core.hooks.useSpring)
local Button = require(ReplicatedStorage.UI.core.primitives.Button)

type ButtonSpringProps = Button.SpringProps
type ButtonProps = Button.ButtonProps

local DEFAULT_ICON_POSITION = UDim2.fromScale(0.5, 0.25)
local CHANGED_ICON_POSITION = UDim2.fromScale(0.5, 0.18)

local e = React.createElement

return React.forwardRef(function(
	props: ButtonProps & {
		ButtonTitle: string,
		ButtonIcon: string,
		TitleStroke: Color3,
	},
	ref: React.Ref<any>
)
	local isHovering, setHover = React.useState(false)
	local isHolding, setHold = React.useState(false)

	local sizeSpring = useSpring(if isHolding then 0.9 else 1, {
		frequency = props.SpringDuration or 0.2,
		damping = props.SpringDamping or 0.8,
	})

	local iconPosSpring = useSpring(if isHovering then CHANGED_ICON_POSITION else DEFAULT_ICON_POSITION, {
		frequency = props.SpringDuration or 0.2,
		damping = props.SpringDamping or 0.8,
	})

	React.useEffect(function()
		if isHolding then
			sizeSpring.setGoal(0.9)
		elseif isHovering then
			sizeSpring.setGoal(1.1)
			iconPosSpring.setGoal(CHANGED_ICON_POSITION)
		else
			sizeSpring.setGoal(1)
			iconPosSpring.setGoal(DEFAULT_ICON_POSITION)
		end
	end, { isHolding, isHovering })

	local safeProps = Sift.Dictionary.join(props, {
		SetHold = setHold,
		SetHover = setHover,
		Scale = sizeSpring.binding,

		ref = ref,
	})

	return e(Button, safeProps, {
		ButtonIcon = e("ImageLabel", {
			Size = UDim2.fromScale(0.7, 0.7),
			Position = iconPosSpring.binding,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = props.ButtonIcon,
			ScaleType = "Fit",
			BackgroundTransparency = 1,
		}),

		TextLabel = e(TextLabel, {
			Size = UDim2.fromScale(1, 0.4),
			Position = UDim2.fromScale(0.45, 0.7),
			BackgroundTransparency = 1,
			TextColor = Color3.fromRGB(255, 255, 255),
			Text = props.ButtonTitle,
			TextSize = 30,
			Stroke = 4,
			StrokeColor = props.TitleStroke,
			RichText = true,
		}),
	})
end)
