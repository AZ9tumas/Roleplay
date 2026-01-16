--!strict
-- ShopController module for the Shop screen
-- Replaces the React-based ShopScreen component

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService).client
local ButtonAnimations = require(script.Parent.ButtonAnimations)
local MenuController = require(script.Parent.MenuController)

local ShopController = {}
ShopController._menu = nil :: any
ShopController._buttonAnimations = {} :: { [string]: any }
ShopController._connections = {} :: { RBXScriptConnection }

function ShopController.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gameGui = playerGui:WaitForChild("GameGui") :: ScreenGui
	
	-- Find the Shop frame
	local shop = gameGui:FindFirstChild("Shop") :: Frame?
	if not shop then
		for _, child in gameGui:GetDescendants() do
			if child.Name == "Shop" and child:IsA("Frame") then
				shop = child
				break
			end
		end
	end
	
	if not shop then
		warn("ShopController: Could not find Shop frame")
		return
	end
	
	-- Setup slide animation for Shop menu
	local fromPosition = UDim2.fromScale(0.5, 0.5)
	local toPosition = UDim2.fromScale(0.5, 1.5)
	ShopController._menu = MenuController.createMenu("Shop", shop, fromPosition, toPosition)
	
	-- Setup purchase buttons
	ShopController._setupButtons(shop)
end

function ShopController._setupButtons(container: Frame)
	-- Find all purchase buttons in the shop
	for _, child in container:GetDescendants() do
		if child:IsA("GuiButton") then
			local animation = ButtonAnimations.setupButton(child)
			ShopController._buttonAnimations[child.Name] = animation
		end
	end
end

function ShopController.cleanup()
	for _, animation in ShopController._buttonAnimations do
		animation.cleanup()
	end
	
	for _, connection in ShopController._connections do
		connection:Disconnect()
	end
	
	if ShopController._menu then
		ShopController._menu.destroy()
	end
end

return ShopController
