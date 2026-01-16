--!strict
-- LeftBarController module for the sidebar HUD buttons
-- Replaces the React-based LeftBar component

local Players = game:GetService("Players")
local ButtonAnimations = require(script.Parent.ButtonAnimations)
local MenuController = require(script.Parent.MenuController)

local LeftBarController = {}
LeftBarController._buttonAnimations = {} :: { [string]: any }
LeftBarController._slideMenu = nil :: any

function LeftBarController.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gameGui = playerGui:WaitForChild("GameGui") :: ScreenGui
	local leftBar = gameGui:WaitForChild("LeftBar") :: Frame
	
	-- Setup slide animation for LeftBar
	local fromPosition = UDim2.fromScale(0.07, 0.5)
	local toPosition = UDim2.fromScale(-0.1, 0.5)
	LeftBarController._slideMenu = MenuController.createSlideOutFrame(leftBar, fromPosition, toPosition, true)
	
	-- Setup button animations for each HUD button
	LeftBarController._setupButtons(leftBar)
end

function LeftBarController._setupButtons(leftBar: Frame)
	-- Find all buttons in the LeftBar
	local buttonConfigs = {
		{ name = "MorphButton", menuId = "Morph" },
		{ name = "ShopButton", menuId = "Shop" },
		{ name = "CoinShopButton", menuId = "CoinShop" },
	}
	
	for _, config in buttonConfigs do
		local button = leftBar:FindFirstChild(config.name) :: ImageButton?
		if button then
			local iconLabel = button:FindFirstChild("ButtonIcon") :: ImageLabel?
			
			local animation = ButtonAnimations.setupHudButton(button, iconLabel, function()
				MenuController.setOpenedMenu(config.menuId)
				MenuController.updateMenus()
			end)
			
			LeftBarController._buttonAnimations[config.name] = animation
		end
	end
end

function LeftBarController.cleanup()
	for _, animation in LeftBarController._buttonAnimations do
		animation.cleanup()
	end
	
	if LeftBarController._slideMenu then
		LeftBarController._slideMenu.destroy()
	end
end

return LeftBarController
