--[[
	UI Entry Point
	
	This module initializes the game's UI system.
	
	The UI has been migrated from React to native Roblox UI with TweenService-based
	animations that replicate the same effects as the original React/Ripple implementation:
	- Spring-like button scaling (hover/click effects)
	- Slide in/out animations for menus
	- Fade animations for overlays
	- Loading spinner rotation
	- Viewport-responsive auto-scaling
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Use the native UI system instead of React
local NativeUI = require(script.NativeUI)

return function()
	NativeUI()
end
