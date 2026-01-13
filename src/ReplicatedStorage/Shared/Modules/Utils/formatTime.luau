--[[
	Time Formatter
	
	Formats seconds into human-readable time string
	Only shows non-zero units (e.g., "2 days 3 hours" or "45 minutes 30 seconds")
]]

local function formatTime(totalSeconds: number): string
	if totalSeconds <= 0 then
		return "0 seconds"
	end

	local days = math.floor(totalSeconds / 86400)
	local hours = math.floor((totalSeconds % 86400) / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = math.floor(totalSeconds % 60)

	local parts = {}

	if days > 0 then
		table.insert(parts, days .. (days == 1 and " day" or " days"))
	end

	if hours > 0 then
		table.insert(parts, hours .. (hours == 1 and " hour" or " hours"))
	end

	if minutes > 0 then
		table.insert(parts, minutes .. (minutes == 1 and " minute" or " minutes"))
	end

	if seconds > 0 then
		table.insert(parts, seconds .. (seconds == 1 and " second" or " seconds"))
	end

	return table.concat(parts, " ")
end

-- Compact version (shorter format: "2d 3h 45m 30s")
local function formatTimeCompact(totalSeconds: number): string
	if totalSeconds <= 0 then
		return "0s"
	end

	local days = math.floor(totalSeconds / 86400)
	local hours = math.floor((totalSeconds % 86400) / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = math.floor(totalSeconds % 60)

	local parts = {}

	if days > 0 then
		table.insert(parts, days .. "d")
	end

	if hours > 0 then
		table.insert(parts, hours .. "h")
	end

	if minutes > 0 then
		table.insert(parts, minutes .. "m")
	end

	if seconds > 0 then
		table.insert(parts, seconds .. "s")
	end

	return table.concat(parts, " ")
end

-- Limited units version (only show top N units)
local function formatTimeLimited(totalSeconds: number, maxUnits: number?): string
	local limit = maxUnits or 2

	if totalSeconds <= 0 then
		return "0 seconds"
	end

	local days = math.floor(totalSeconds / 86400)
	local hours = math.floor((totalSeconds % 86400) / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = math.floor(totalSeconds % 60)

	local parts = {}

	if days > 0 then
		table.insert(parts, days .. (days == 1 and " day" or " days"))
	end

	if hours > 0 and #parts < limit then
		table.insert(parts, hours .. (hours == 1 and " hour" or " hours"))
	end

	if minutes > 0 and #parts < limit then
		table.insert(parts, minutes .. (minutes == 1 and " minute" or " minutes"))
	end

	if seconds > 0 and #parts < limit then
		table.insert(parts, seconds .. (seconds == 1 and " second" or " seconds"))
	end

	return table.concat(parts, " ")
end

return {
	formatTime = formatTime,
	formatTimeCompact = formatTimeCompact,
	formatTimeLimited = formatTimeLimited,
}
--string.format("%02d:%02d:%02d", hours, minutes, seconds)
