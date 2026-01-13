local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)

return function(updateInterval: number?)
	local interval = updateInterval or 1

	local seconds, setSecond = React.useState(0)
	local startTimeRef = React.useRef(os.clock())
	local lastUpdateRef = React.useRef(os.clock())

	React.useEffect(function()
		print("Effect running - setting up connection")

		local connection = RunService.PostSimulation:Connect(function()
			print("running")
			local now = os.clock()
			local timeSinceLastUpdate = now - lastUpdateRef.current

			-- Only update if interval has passed
			if timeSinceLastUpdate >= interval then
				local totalElapsed = math.floor(now - startTimeRef.current)
				lastUpdateRef.current = now

				-- Only call setState if the value actually changed
				setSecond(function(prev)
					if prev ~= totalElapsed then
						return totalElapsed
					end
					return prev
				end)
			end
		end)

		return function()
			print("Effect cleanup - disconnecting")
			connection:Disconnect()
		end
	end, { interval }) -- Only re-run if interval changes

	return seconds
end
