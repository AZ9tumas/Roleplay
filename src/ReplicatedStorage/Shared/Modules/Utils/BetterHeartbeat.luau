local RunService = game:GetService("RunService")

local callbacks = {}
local connection = nil

local function register(id: number, callback: () -> ())
	callbacks[id] = callback
	if not connection then
		connection = RunService.Heartbeat:Connect(function()
			for _, cb in callbacks do
				cb()
			end
		end)
	end
end

function unregister(id)
	callbacks[id] = nil
	if next(callbacks) == nil and connection then
		connection:Disconnect()
		connection = nil
	end
end

return {
	register = register,
	unregister = unregister,
}
