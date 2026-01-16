--!strict
-- MorphScreenController module for the Morph screen
-- Replaces the React-based MorphScreen component

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService).client
local MorphServiceClient = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceClient)
local ButtonAnimations = require(script.Parent.ButtonAnimations)
local MenuController = require(script.Parent.MenuController)

local MorphScreenController = {}
MorphScreenController._menu = nil :: any
MorphScreenController._buttonAnimations = {} :: { [string]: any }
MorphScreenController._connections = {} :: { RBXScriptConnection }

function MorphScreenController.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gameGui = playerGui:WaitForChild("GameGui") :: ScreenGui
	
	-- Find the Morph frame
	local morph = gameGui:FindFirstChild("Morph") :: Frame?
	if not morph then
		for _, child in gameGui:GetDescendants() do
			if child.Name == "Morph" and child:IsA("Frame") then
				morph = child
				break
			end
		end
	end
	
	if not morph then
		warn("MorphScreenController: Could not find Morph frame")
		return
	end
	
	-- Setup slide animation for Morph menu
	local fromPosition = UDim2.fromScale(0.5, 0.5)
	local toPosition = UDim2.fromScale(0.5, 1.5)
	MorphScreenController._menu = MenuController.createMenu("Morph", morph, fromPosition, toPosition)
	
	-- Setup morph buttons
	MorphScreenController._setupButtons(morph)
	
	-- Setup data listeners
	MorphScreenController._setupDataListeners()
end

function MorphScreenController._setupButtons(container: Frame)
	-- Find all morph-related buttons
	for _, child in container:GetDescendants() do
		if child:IsA("GuiButton") then
			local animation = ButtonAnimations.setupButton(child)
			MorphScreenController._buttonAnimations[child.Name] = animation
		end
	end
end

function MorphScreenController._setupDataListeners()
	-- Listen for equipped morph changes
	local equippedConnection = DataService:getChangedSignal({ "equippedMorph" }):Connect(function(value)
		MorphScreenController._updateEquippedState(value)
	end)
	table.insert(MorphScreenController._connections, equippedConnection)
	
	-- Listen for unlocked morph changes
	local unlockedConnection = DataService:getIndexChangedSignal({ "unlockedMorph" }):Connect(function()
		MorphScreenController._updateUnlockedMorphs()
	end)
	table.insert(MorphScreenController._connections, unlockedConnection)
end

function MorphScreenController._updateEquippedState(equippedMorph: string?)
	-- Update visual state of equipped morph button
	-- This would update the UI to show which morph is currently equipped
end

function MorphScreenController._updateUnlockedMorphs()
	-- Update which morphs are shown as unlocked
	-- This would update the UI to show newly unlocked morphs
end

function MorphScreenController.cleanup()
	for _, animation in MorphScreenController._buttonAnimations do
		animation.cleanup()
	end
	
	for _, connection in MorphScreenController._connections do
		connection:Disconnect()
	end
	
	if MorphScreenController._menu then
		MorphScreenController._menu.destroy()
	end
end

return MorphScreenController
