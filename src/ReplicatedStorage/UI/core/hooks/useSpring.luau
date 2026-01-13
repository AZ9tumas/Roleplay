local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Ripple = require(ReplicatedStorage.Packages.Ripple)

type SpringOptions = { frequency: number?, damping: number? }

return function<T>(initial: T, opts: SpringOptions, goal: T?)
	local binding, setBinding = React.useBinding(initial)

	local motion = React.useMemo(function()
		local rippleMotion = Ripple.createMotion(initial)
		rippleMotion:onStep(setBinding)
		if goal then
			rippleMotion:spring(goal, opts)
			if goal ~= initial then
				rippleMotion:start()
			end
		end
		return rippleMotion
	end, {})

	React.useEffect(function()
		motion:onComplete(function()
			motion:stop()
		end)

		return function()
			motion:destroy()
		end
	end, {})

	local setGoal = React.useCallback(function(newGoal: T, newOpts: SpringOptions?)
		motion:spring(newGoal, newOpts or opts)
		motion:start()
	end, {})

	local snap = React.useCallback(function(val: T, velocity: T?)
		if velocity then
			motion:setVelocity(velocity)
		end
		motion:set(val)
		setBinding(val)
		motion:start()
	end, {})

	local impulse = React.useCallback(function(val: T)
		motion:start()
		motion:impulse(val)
	end, {})

	local onStep = React.useCallback(function(callback: (T) -> ())
		return motion:onStep(callback)
	end, {})

	local onComplete = React.useCallback(function(callback: (T) -> ())
		return motion:onComplete(callback)
	end, {})

	return {
		binding = binding,
		setGoal = setGoal,
		snap = snap,
		impulse = impulse,
		onStep = onStep,
		onComplete = onComplete,
	}
end
