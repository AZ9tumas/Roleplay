local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local BetterHeartbeat = require(ReplicatedStorage.Shared.Modules.Utils.BetterHeartbeat)
local formatTime = require(ReplicatedStorage.Shared.Modules.Utils.formatTime)

type TimeData = {
	seconds: number,
	minutes: number,
	hours: number,
	elapsed: number,
	formatted: string,
	timestamp: number,
}

return function(
	startTime: number,
	endTime: number,
	onComplete: (() -> ())?
): { timer: TimeData, completed: boolean, togglePause: (boolean?) -> () }
	local duration = React.useMemo(function()
		local elapsed = os.time() - startTime
		local remaining = endTime - elapsed

		return remaining
	end, { startTime, endTime })

	local timer, setTime = React.useState({
		seconds = 0,
		minutes = 0,
		hours = 0,
		elapsed = duration,
		formatted = "00:00:00",
		timestamp = os.time(),
	} :: TimeData)
	local isPaused, setIsPaused = React.useState(false)
	local hasCompleted, setHasCompleted = React.useState(false)

	React.useEffect(function()
		if isPaused or hasCompleted then
			return
		end
		local timerId = HttpService:GenerateGUID(false)
		local startTick = tick()
		local lastUpdate = 0

		local function updateCountdown()
			local elapsed = tick() - startTick
			local remaining = math.max(0, duration - elapsed)

			if remaining <= 0 then
				setHasCompleted(true)

				-- Set final time values to zero
				setTime({
					seconds = 0,
					minutes = 0,
					hours = 0,
					elapsed = 0,
					formatted = formatTime.formatTimeLimited(0),
					timestamp = tick(),
				})

				if onComplete then
					onComplete()
				end
				return
			end

			local hours = math.floor(remaining / 3600)
			local minutes = math.floor((remaining % 3600) / 60)
			local seconds = math.floor(remaining % 60)

			local formatted = formatTime.formatTimeLimited(remaining)

			setTime({
				seconds = seconds,
				minutes = minutes,
				hours = hours,
				elapsed = math.floor(remaining),
				formatted = formatted,
				timestamp = tick(),
			})
		end

		BetterHeartbeat.register(timerId, function()
			local now = tick()
			if now - lastUpdate < 0.1 then
				return
			end
			lastUpdate = now

			updateCountdown()
		end)

		return function()
			BetterHeartbeat.unregister(timerId)
		end
	end, { duration, isPaused })

	local function togglePause()
		setIsPaused(not isPaused)
	end

	return {
		timer = timer,
		completed = hasCompleted,
		togglePause = togglePause,
	}
end
