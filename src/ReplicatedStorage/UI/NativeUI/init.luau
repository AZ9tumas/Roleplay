--[[
	NativeUI - Non-React UI System
	
	This module creates and manages the game UI without React,
	while providing the same animations and effects that the React version had.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationController = require(script.AnimationController)
local Components = require(script.Components)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--[[
	Create the main GameGui ScreenGui
]]
local function createGameGui(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameGui"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	return screenGui
end

--[[
	Initialize and mount all UI components
]]
local function init()
	local gameGui = createGameGui()
	
	-- Create LeftBar with HUD buttons
	Components.createLeftBar(gameGui)
	
	-- Create Menu panels (Morph and Shop)
	Components.createMorphMenu(gameGui)
	Components.createShopMenu(gameGui)
	
	-- Create Purchase Screen
	Components.createPurchaseScreen(gameGui)
	
	-- Create NewMorph notification
	Components.createNewMorphNotification(gameGui)
	
	-- Initialize animation controller
	AnimationController.init(gameGui)
end

return init
