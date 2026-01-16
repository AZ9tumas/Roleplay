--!strict
-- CoinShopController module for the Coins Shop screen
-- Replaces the React-based CoinShopScreen component

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService).client
local CoinMorphs = require(ReplicatedStorage.Shared.Modules.Game.CoinMorphs)
local MorphServiceClient = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceClient)
local ButtonAnimations = require(script.Parent.ButtonAnimations)
local MenuController = require(script.Parent.MenuController)

local CoinShopController = {}
CoinShopController._menu = nil :: any
CoinShopController._buttonAnimations = {} :: { [string]: any }
CoinShopController._connections = {} :: { RBXScriptConnection }
CoinShopController._coinsLabel = nil :: TextLabel?

function CoinShopController.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gameGui = playerGui:WaitForChild("GameGui") :: ScreenGui
	
	-- Find the CoinShop frame (might be named differently based on the structure)
	local coinShop = gameGui:FindFirstChild("CoinShop") :: Frame?
	if not coinShop then
		-- Try to find it as a child of some container
		for _, child in gameGui:GetDescendants() do
			if child.Name == "CoinShop" and child:IsA("Frame") then
				coinShop = child
				break
			end
		end
	end
	
	if not coinShop then
		warn("CoinShopController: Could not find CoinShop frame")
		return
	end
	
	-- Setup slide animation for CoinShop menu
	local fromPosition = UDim2.fromScale(0.5, 0.5)
	local toPosition = UDim2.fromScale(0.5, 1.5)
	CoinShopController._menu = MenuController.createMenu("CoinShop", coinShop, fromPosition, toPosition)
	
	-- Find coins display label
	CoinShopController._findCoinsLabel(coinShop)
	
	-- Setup purchase buttons
	CoinShopController._setupPurchaseButtons(coinShop)
	
	-- Listen for coins changes
	CoinShopController._setupDataListeners()
	
	-- Initial coins update
	CoinShopController._updateCoinsDisplay()
end

function CoinShopController._findCoinsLabel(container: Frame)
	-- Look for a TextLabel that displays coins
	for _, child in container:GetDescendants() do
		if child:IsA("TextLabel") and (child.Name == "CoinsLabel" or string.find(child.Text, "Coins")) then
			CoinShopController._coinsLabel = child
			break
		end
	end
end

function CoinShopController._updateCoinsDisplay()
	if not CoinShopController._coinsLabel then
		return
	end
	
	local coins = DataService:get({ "coins" }) or 0
	CoinShopController._coinsLabel.Text = "Coins: " .. tostring(coins)
end

function CoinShopController._setupDataListeners()
	local coinsConnection = DataService:getChangedSignal({ "coins" }):Connect(function()
		CoinShopController._updateCoinsDisplay()
	end)
	table.insert(CoinShopController._connections, coinsConnection)
	
	-- Listen for morph unlock changes to update button states
	local morphConnection = DataService:getIndexChangedSignal({ "unlockedMorph" }):Connect(function()
		CoinShopController._updateButtonStates()
	end)
	table.insert(CoinShopController._connections, morphConnection)
end

function CoinShopController._setupPurchaseButtons(container: Frame)
	-- Find purchase buttons for each coin morph
	for morphName, morphData in CoinMorphs do
		-- Look for a button associated with this morph
		local button = container:FindFirstChild(morphName .. "Button") :: GuiButton?
		if not button then
			-- Try finding by looking at descendants
			for _, child in container:GetDescendants() do
				if child:IsA("GuiButton") and string.find(child.Name, morphName) then
					button = child
					break
				end
			end
		end
		
		if button then
			local animation = ButtonAnimations.setupButton(button, function()
				MorphServiceClient:purchaseCoinMorph(morphName)
			end)
			CoinShopController._buttonAnimations[morphName] = animation
		end
	end
end

function CoinShopController._updateButtonStates()
	local unlockedMorphs = DataService:get({ "unlockedMorph" }) or {}
	
	for morphName, _ in CoinMorphs do
		local button = CoinShopController._buttonAnimations[morphName]
		if button then
			-- Update button appearance based on unlock state
			local isUnlocked = unlockedMorphs[morphName] ~= nil
			-- Visual update would be done here if needed
		end
	end
end

function CoinShopController.cleanup()
	for _, animation in CoinShopController._buttonAnimations do
		animation.cleanup()
	end
	
	for _, connection in CoinShopController._connections do
		connection:Disconnect()
	end
	
	if CoinShopController._menu then
		CoinShopController._menu.destroy()
	end
end

return CoinShopController
