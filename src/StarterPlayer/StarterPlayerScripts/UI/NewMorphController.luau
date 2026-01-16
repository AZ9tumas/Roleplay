--!strict
-- NewMorphController module for the New Morph popup
-- Replaces the React-based NewMorph component

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService).client
local Spring = require(script.Parent.Spring)

local NewMorphController = {}
NewMorphController._frame = nil :: Frame?
NewMorphController._connections = {} :: { RBXScriptConnection }
NewMorphController._newMorphs = {} :: { string }
NewMorphController._posSpring = nil :: any

function NewMorphController.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gameGui = playerGui:WaitForChild("GameGui") :: ScreenGui
	
	-- Find the NewMorph frame
	local newMorph = gameGui:FindFirstChild("NewMorph") :: Frame?
	if not newMorph then
		for _, child in gameGui:GetDescendants() do
			if child.Name == "NewMorph" and child:IsA("Frame") then
				newMorph = child
				break
			end
		end
	end
	
	if not newMorph then
		warn("NewMorphController: Could not find NewMorph frame")
		return
	end
	
	NewMorphController._frame = newMorph
	newMorph.Visible = false
	
	-- Setup spring animation
	local fromPosition = UDim2.fromScale(0.5, 0.5)
	local toPosition = UDim2.fromScale(0.5, 1.5)
	NewMorphController._posSpring = Spring.create(toPosition, { frequency = 0.2, damping = 0.8 })
	
	local stepDisconnect = NewMorphController._posSpring.onStep(function(value)
		if NewMorphController._frame then
			NewMorphController._frame.Position = value
		end
	end)
	table.insert(NewMorphController._connections, { Disconnect = stepDisconnect })
	
	-- Listen for new morph unlocks
	NewMorphController._setupDataListeners()
	
	-- Click to dismiss
	NewMorphController._setupClickToDismiss()
end

function NewMorphController._setupDataListeners()
	local connection = DataService:getIndexChangedSignal({ "unlockedMorph" }):Connect(function(index)
		if index then
			NewMorphController._showNewMorph(index)
		end
	end)
	table.insert(NewMorphController._connections, connection)
end

function NewMorphController._setupClickToDismiss()
	local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		
		if input.UserInputType == Enum.UserInputType.MouseButton1 
			or input.UserInputType == Enum.UserInputType.Touch then
			if #NewMorphController._newMorphs > 0 then
				NewMorphController._dismissCurrentMorph()
			end
		end
	end)
	table.insert(NewMorphController._connections, inputConnection)
end

function NewMorphController._showNewMorph(morphName: string)
	table.insert(NewMorphController._newMorphs, morphName)
	
	if #NewMorphController._newMorphs == 1 then
		NewMorphController._displayMorph(morphName)
	end
end

function NewMorphController._displayMorph(morphName: string)
	if not NewMorphController._frame then
		return
	end
	
	NewMorphController._frame.Visible = true
	
	-- Animate in
	local fromPosition = UDim2.fromScale(0.5, 0.5)
	local toPosition = UDim2.fromScale(0.5, 1.5)
	
	NewMorphController._posSpring.snap(toPosition)
	NewMorphController._posSpring.setGoal(fromPosition)
end

function NewMorphController._dismissCurrentMorph()
	if #NewMorphController._newMorphs == 0 then
		return
	end
	
	-- Remove current morph from queue
	table.remove(NewMorphController._newMorphs, 1)
	
	-- Animate out
	local toPosition = UDim2.fromScale(0.5, 1.5)
	NewMorphController._posSpring.setGoal(toPosition)
	
	-- Check if more morphs to show
	task.delay(0.3, function()
		if #NewMorphController._newMorphs > 0 then
			NewMorphController._displayMorph(NewMorphController._newMorphs[1])
		else
			if NewMorphController._frame then
				NewMorphController._frame.Visible = false
			end
		end
	end)
end

function NewMorphController.cleanup()
	for _, connection in NewMorphController._connections do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		elseif connection.Disconnect then
			connection.Disconnect()
		end
	end
	
	if NewMorphController._posSpring then
		NewMorphController._posSpring.destroy()
	end
end

return NewMorphController
