--[[
	NativeUI - Animation System for Existing UI
	
	This module adds animations and effects to the existing UI that was
	exported from the React-based system. The UI structure already exists
	in StarterGui, so this module only handles:
	- Button hover/click scaling effects
	- Menu slide in/out animations
	- Loading spinner rotation
	- Viewport-responsive scaling
	- State integration (Charm)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationController = require(script.AnimationController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--[[
	Initialize animations on existing UI elements
]]
local function init()
	-- Wait for the existing GameGui to be available (it comes from StarterGui)
	local gameGui = playerGui:WaitForChild("GameGui", 10)
	
	if not gameGui then
		warn("NativeUI: GameGui not found in PlayerGui. Make sure it exists in StarterGui.")
		return
	end
	
	-- Initialize animation controller on the existing UI
	AnimationController.initExistingUI(gameGui)
end

return init
