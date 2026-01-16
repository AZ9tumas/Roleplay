--!strict
-- PurchaseScreenController module for the purchase loading screen
-- Shows during purchase prompts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIState = require(ReplicatedStorage.Shared.Modules.UI.UIState)
local Spring = require(script.Parent.Spring)

local PurchaseScreenController = {}
PurchaseScreenController._frame = nil :: Frame?
PurchaseScreenController._connections = {} :: { RBXScriptConnection }
PurchaseScreenController._posSpring = nil :: any

function PurchaseScreenController.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gameGui = playerGui:WaitForChild("GameGui") :: ScreenGui
	
	-- Find the PurchaseScreen frame
	local purchaseScreen = gameGui:FindFirstChild("PurchaseScreen") :: Frame?
	if not purchaseScreen then
		for _, child in gameGui:GetDescendants() do
			if child.Name == "PurchaseScreen" and child:IsA("Frame") then
				purchaseScreen = child
				break
			end
		end
	end
	
	if not purchaseScreen then
		-- Purchase screen might not exist in all setups
		return
	end
	
	PurchaseScreenController._frame = purchaseScreen
	purchaseScreen.Visible = false
	
	-- Setup spring animation
	local fromPosition = UDim2.fromScale(0.5, 0.5)
	local toPosition = UDim2.fromScale(0.5, 1.5)
	PurchaseScreenController._posSpring = Spring.create(toPosition, { frequency = 0.2, damping = 0.8 })
	
	local stepDisconnect = PurchaseScreenController._posSpring.onStep(function(value)
		if PurchaseScreenController._frame then
			PurchaseScreenController._frame.Position = value
		end
	end)
	table.insert(PurchaseScreenController._connections, { Disconnect = stepDisconnect })
	
	-- Listen for purchase state changes
	PurchaseScreenController._setupPurchaseListener()
end

function PurchaseScreenController._setupPurchaseListener()
	local connection = UIState.onPurchasingChanged:Connect(function(isPurchasing)
		if isPurchasing then
			PurchaseScreenController._show()
		else
			PurchaseScreenController._hide()
		end
	end)
	table.insert(PurchaseScreenController._connections, connection)
end

function PurchaseScreenController._show()
	if not PurchaseScreenController._frame then
		return
	end
	
	PurchaseScreenController._frame.Visible = true
	
	local fromPosition = UDim2.fromScale(0.5, 0.5)
	local toPosition = UDim2.fromScale(0.5, 1.5)
	
	PurchaseScreenController._posSpring.snap(toPosition)
	PurchaseScreenController._posSpring.setGoal(fromPosition)
end

function PurchaseScreenController._hide()
	if not PurchaseScreenController._frame or not PurchaseScreenController._posSpring then
		return
	end
	
	local toPosition = UDim2.fromScale(0.5, 1.5)
	PurchaseScreenController._posSpring.setGoal(toPosition)
	
	task.delay(0.3, function()
		if PurchaseScreenController._frame and not UIState.purchasing then
			PurchaseScreenController._frame.Visible = false
		end
	end)
end

function PurchaseScreenController.cleanup()
	for _, connection in PurchaseScreenController._connections do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		elseif connection.Disconnect then
			connection.Disconnect()
		end
	end
	
	if PurchaseScreenController._posSpring then
		PurchaseScreenController._posSpring.destroy()
	end
end

return PurchaseScreenController
