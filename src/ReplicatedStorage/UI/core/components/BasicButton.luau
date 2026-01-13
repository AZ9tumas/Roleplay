local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local useSpring = require(ReplicatedStorage.UI.core.hooks.useSpring)
local Button = require(ReplicatedStorage.UI.core.primitives.Button)

type ButtonProps = Button.ButtonProps

local e = React.createElement

return React.forwardRef(function(props: ButtonProps, ref: React.Ref<any>)
	local isHovering, setHover = React.useState(false)
	local isHolding, setHold = React.useState(false)

	local sizeSpring = useSpring(if isHolding then 0.9 else 1, {
		frequency = props.SpringDuration or 0.2,
		damping = props.SpringDamping or 0.8,
	})

	React.useEffect(function()
		if isHolding then
			sizeSpring.setGoal(0.9)
		elseif isHovering then
			sizeSpring.setGoal(1.1)
		else
			sizeSpring.setGoal(1)
		end
	end, { isHolding, isHovering })

	local safeProps = Sift.Dictionary.join(props, {
		SetHold = setHold,
		SetHover = setHover,
		Scale = sizeSpring.binding,

		ref = ref,
	})
	return e(Button, safeProps)
end)
