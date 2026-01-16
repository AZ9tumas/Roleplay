--!strict
-- Spring utility module for UI animations using Ripple
-- Replaces the React-based useSpring hook

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ripple = require(ReplicatedStorage.Packages.Ripple)

export type SpringOptions = {
	frequency: number?,
	damping: number?,
}

export type Spring<T> = {
	getValue: () -> T,
	setGoal: (goal: T, opts: SpringOptions?) -> (),
	snap: (value: T) -> (),
	onStep: (callback: (T) -> ()) -> () -> (),
	onComplete: (callback: () -> ()) -> () -> (),
	destroy: () -> (),
}

local Spring = {}

function Spring.create<T>(initial: T, opts: SpringOptions?): Spring<T>
	local motion = Ripple.createMotion(initial)
	local currentValue = initial
	local options = opts or { frequency = 0.2, damping = 0.8 }
	
	motion:onStep(function(value)
		currentValue = value
	end)
	
	return {
		getValue = function()
			return currentValue
		end,
		
		setGoal = function(goal: T, newOpts: SpringOptions?)
			local springOpts = newOpts or options
			motion:spring(goal, springOpts)
			motion:start()
		end,
		
		snap = function(value: T)
			motion:set(value)
			currentValue = value
		end,
		
		onStep = function(callback: (T) -> ())
			return motion:onStep(callback)
		end,
		
		onComplete = function(callback: () -> ())
			return motion:onComplete(callback)
		end,
		
		destroy = function()
			motion:destroy()
		end,
	}
end

return Spring
