-- useTime.lua
-- Custom time hook for Roblox React

local React = require(game.ReplicatedStorage.React)
local useState = React.useState
local useEffect = React.useEffect

type TimeData = {
	seconds: number,
	minutes: number,
	hours: number,
	elapsed: number,
	formatted: string,
	timestamp: number
}

--[[
	useTime Hook
	
	Updates time at specified interval
	
	@param updateInterval number? - Update interval in seconds (default 1)
	@return TimeData - Current time information
]]
local function useTime(updateInterval: number?): TimeData
	local interval = updateInterval or 1

	local time, setTime = useState({
		seconds = 0,
		minutes = 0,
		hours = 0,
		elapsed = 0,
		formatted = "00:00:00",
		timestamp = os.time()
	} :: TimeData)

	useEffect(function()
		local startTime = os.clock()
		local connection

		local function updateTime()
			local currentTime = os.clock()
			local elapsed = currentTime - startTime

			local hours = math.floor(elapsed / 3600)
			local minutes = math.floor((elapsed % 3600) / 60)
			local seconds = math.floor(elapsed % 60)

			local formatted = string.format(
				"%02d:%02d:%02d",
				hours,
				minutes,
				seconds
			)

			setTime({
				seconds = seconds,
				minutes = minutes,
				hours = hours,
				elapsed = math.floor(elapsed),
				formatted = formatted,
				timestamp = os.time()
			})
		end

		-- Initial update
		updateTime()

		-- Set up interval using RunService
		local RunService = game:GetService("RunService")
		local lastUpdate = os.clock()

		connection = RunService.Heartbeat:Connect(function()
			if os.clock() - lastUpdate >= interval then
				updateTime()
				lastUpdate = os.clock()
			end
		end)

		-- Cleanup
		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, {interval})

	return time
end

--[[
	useGameTime Hook
	
	Tracks time since game/round started using tick()
	
	@param updateInterval number? - Update interval in seconds (default 1)
	@return TimeData - Current game time
]]
local function useGameTime(updateInterval: number?): TimeData
	local interval = updateInterval or 1

	local time, setTime = useState({
		seconds = 0,
		minutes = 0,
		hours = 0,
		elapsed = 0,
		formatted = "00:00:00",
		timestamp = tick()
	} :: TimeData)

	useEffect(function()
		local startTime = tick()
		local connection

		local function updateTime()
			local elapsed = tick() - startTime

			local hours = math.floor(elapsed / 3600)
			local minutes = math.floor((elapsed % 3600) / 60)
			local seconds = math.floor(elapsed % 60)

			local formatted = string.format(
				"%02d:%02d:%02d",
				hours,
				minutes,
				seconds
			)

			setTime({
				seconds = seconds,
				minutes = minutes,
				hours = hours,
				elapsed = math.floor(elapsed),
				formatted = formatted,
				timestamp = tick()
			})
		end

		updateTime()

		local RunService = game:GetService("RunService")
		local lastUpdate = tick()

		connection = RunService.Heartbeat:Connect(function()
			if tick() - lastUpdate >= interval then
				updateTime()
				lastUpdate = tick()
			end
		end)

		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, {interval})

	return time
end

--[[
	useCountdown Hook
	
	Countdown timer from specified duration
	
	@param duration number - Duration in seconds
	@param onComplete function? - Callback when countdown reaches 0
	@return TimeData - Remaining time
	@return function - Reset function
	@return function - Pause/Resume function
	@return boolean - Is paused
]]
local function useCountdown(duration: number, onComplete: (() -> ())?): (TimeData, () -> (), () -> (), boolean)
	local time, setTime = useState({
		seconds = 0,
		minutes = 0,
		hours = 0,
		elapsed = duration,
		formatted = "00:00:00",
		timestamp = tick()
	} :: TimeData)

	local isPaused, setIsPaused = useState(false)
	local hasCompleted, setHasCompleted = useState(false)

	useEffect(function()
		if isPaused or hasCompleted then
			return
		end

		local startTime = tick()
		local connection

		local function updateCountdown()
			local elapsed = tick() - startTime
			local remaining = math.max(0, duration - elapsed)

			if remaining <= 0 and not hasCompleted then
				setHasCompleted(true)
				if onComplete then
					onComplete()
				end
			end

			local hours = math.floor(remaining / 3600)
			local minutes = math.floor((remaining % 3600) / 60)
			local seconds = math.floor(remaining % 60)

			local formatted = string.format(
				"%02d:%02d:%02d",
				hours,
				minutes,
				seconds
			)

			setTime({
				seconds = seconds,
				minutes = minutes,
				hours = hours,
				elapsed = math.floor(remaining),
				formatted = formatted,
				timestamp = tick()
			})
		end

		updateCountdown()

		local RunService = game:GetService("RunService")
		connection = RunService.Heartbeat:Connect(updateCountdown)

		return function()
			if connection then
				connection:Disconnect()
			end
		end
	end, {duration, isPaused, hasCompleted})

	local function reset()
		setHasCompleted(false)
		setIsPaused(false)
	end

	local function togglePause()
		setIsPaused(not isPaused)
	end

	return time, reset, togglePause, isPaused
end

return {
	useTime = useTime,
	useGameTime = useGameTime,
	useCountdown = useCountdown
}