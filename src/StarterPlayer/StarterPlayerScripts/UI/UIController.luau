--!strict
-- UIController module - Main controller for all UI
-- This replaces the React-based UI system

local LeftBarController = require(script.Parent.LeftBarController)
local MenuController = require(script.Parent.MenuController)
local CoinShopController = require(script.Parent.CoinShopController)
local ShopController = require(script.Parent.ShopController)
local MorphScreenController = require(script.Parent.MorphScreenController)
local NewMorphController = require(script.Parent.NewMorphController)

local UIController = {}

function UIController.init()
	-- Initialize menu controller callback
	MenuController.setOnMenuChanged(function(menuId)
		MenuController.updateMenus()
	end)
	
	-- Initialize all UI controllers
	LeftBarController.init()
	CoinShopController.init()
	ShopController.init()
	MorphScreenController.init()
	NewMorphController.init()
	
	print("UIController: All UI modules initialized")
end

function UIController.cleanup()
	LeftBarController.cleanup()
	CoinShopController.cleanup()
	ShopController.cleanup()
	MorphScreenController.cleanup()
	NewMorphController.cleanup()
end

return UIController
