local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local useSpring = require(ReplicatedStorage.UI.core.hooks.useSpring)
local AutoScaledFrame = require(ReplicatedStorage.UI.core.primitives.AutoScaledFrame)

local e = React.createElement

type SlideOutProps = AutoScaledFrame.AutoScaledFrameProps & {
	Shown: boolean,
	From: UDim2,
	To: UDim2,
	Duration: number?,
	Damping: number?,
}

local CUSTOM_SLIDE_OUT_PROPS = { "Shown", "From", "To", "Duration", "Damping" }

return React.forwardRef(function(props: SlideOutProps, ref)
	local shown = props.Shown
	local from, to = props.From, props.To
	local mounted, setMounted = React.useState(shown)

	local posSpring = useSpring(if shown then from else to, {
		frequency = props.Duration or 0.2,
		damping = props.Damping or 0.8,
	})

	local safeProps = Sift.Dictionary.removeKeys(props, unpack(CUSTOM_SLIDE_OUT_PROPS))
	safeProps.ref = ref
	safeProps.Position = posSpring.binding

	React.useEffect(function()
		if shown then
			return
		end

		posSpring.setGoal(to)
		local discon = posSpring.onComplete(function()
			if not shown then
				setMounted(false)
			end
		end)

		return discon
	end, { shown, to })

	React.useEffect(function()
		if not shown then
			return
		end

		if not mounted then
			setMounted(true)
			return
		end

		posSpring.snap(to)
		posSpring.setGoal(from)
	end, { shown, mounted, from, to })

	if not mounted then
		return nil
	end

	return e(AutoScaledFrame, safeProps)
end)
