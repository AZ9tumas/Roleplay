--[[
	UIAnimations - LocalScript Entry Point
	
	This script initializes animations on the existing UI elements in GameGui.
	It adds hover/click effects, menu slide animations, and other visual effects
	that were previously provided by the React/Ripple framework.
]]

local Players = game:GetService("Players")

local AnimationController = require(script.AnimationController)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the existing GameGui to be available (it comes from StarterGui)
local gameGui = playerGui:WaitForChild("GameGui", 10)

if not gameGui then
	warn("UIAnimations: GameGui not found in PlayerGui. Make sure it exists in StarterGui.")
	return
end

-- Initialize animation controller on the existing UI
AnimationController.initExistingUI(gameGui)
