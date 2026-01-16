--!strict
-- CoinShopController module for the Coins Shop screen
-- Replaces the React-based CoinShopScreen component

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService).client
local CoinMorphs = require(ReplicatedStorage.Shared.Modules.Game.CoinMorphs)
local ImageIds = require(ReplicatedStorage.Shared.Modules.Game.ImageIds)
local MorphServiceClient = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceClient)
local ButtonAnimations = require(script.Parent.ButtonAnimations)
local MenuController = require(script.Parent.MenuController)

local CoinShopController = {}
CoinShopController._menu = nil :: any
CoinShopController._buttonAnimations = {} :: { [string]: any }
CoinShopController._connections = {} :: { RBXScriptConnection }
CoinShopController._coinsLabel = nil :: TextLabel?
CoinShopController._morphContainers = {} :: { [string]: Frame }
CoinShopController._unlockedMorphs = {} :: { [string]: any }

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
	
	-- Find morph containers
	CoinShopController._findMorphContainers(coinShop)
	
	-- Setup purchase buttons
	CoinShopController._setupPurchaseButtons(coinShop)
	
	-- Listen for coins changes
	CoinShopController._setupDataListeners()
	
	-- Load initial data
	CoinShopController._loadInitialData()
end

function CoinShopController._findCoinsLabel(container: Frame)
	-- Look for a TextLabel that displays coins
	for _, child in container:GetDescendants() do
		if child:IsA("TextLabel") then
			if child.Name == "CoinsLabel" or string.find(child.Text, "Coins") then
				CoinShopController._coinsLabel = child
				break
			end
		end
	end
end

function CoinShopController._findMorphContainers(container: Frame)
	-- Find containers for each coin morph
	for morphName, morphData in CoinMorphs do
		for _, child in container:GetDescendants() do
			if child:IsA("Frame") or child:IsA("ImageLabel") then
				if child:GetAttribute("MorphId") == morphName or child.Name == morphName then
					CoinShopController._morphContainers[morphName] = child
					break
				end
			end
		end
	end
end

function CoinShopController._loadInitialData()
	-- Load initial unlocked morphs
	CoinShopController._unlockedMorphs = DataService:get({ "unlockedMorph" }) or {}
	
	-- Update coins display
	CoinShopController._updateCoinsDisplay()
	
	-- Update all morph containers
	CoinShopController._updateAllMorphContainers()
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
	local morphConnection = DataService:getIndexChangedSignal({ "unlockedMorph" }):Connect(function(index)
		CoinShopController._unlockedMorphs = DataService:get({ "unlockedMorph" }) or {}
		CoinShopController._updateMorphContainer(index)
	end)
	table.insert(CoinShopController._connections, morphConnection)
end

function CoinShopController._setupPurchaseButtons(container: Frame)
	-- Find purchase buttons for each coin morph
	for morphName, morphData in CoinMorphs do
		-- Look for any button that might be associated with this morph
		for _, child in container:GetDescendants() do
			if child:IsA("GuiButton") then
				local parent = child.Parent
				local matchesMorph = false
				
				-- Check if button or parent is associated with this morph
				if string.find(child.Name, morphName) then
					matchesMorph = true
				elseif parent and (parent.Name == morphName or parent:GetAttribute("MorphId") == morphName) then
					matchesMorph = true
				end
				
				if matchesMorph then
					local animation = ButtonAnimations.setupButton(child, function()
						CoinShopController._onPurchaseButtonClicked(morphName)
					end)
					CoinShopController._buttonAnimations[morphName] = animation
				end
			end
		end
	end
end

function CoinShopController._onPurchaseButtonClicked(morphName: string)
	-- Check if already unlocked
	if CoinShopController._unlockedMorphs[morphName] then
		return
	end
	
	-- Request purchase from MorphService
	MorphServiceClient:purchaseCoinMorph(morphName)
end

function CoinShopController._updateAllMorphContainers()
	for morphName, _ in CoinMorphs do
		CoinShopController._updateMorphContainer(morphName)
	end
end

function CoinShopController._updateMorphContainer(morphName: string)
	local container = CoinShopController._morphContainers[morphName]
	if not container then
		return
	end
	
	local isUnlocked = CoinShopController._unlockedMorphs[morphName] ~= nil
	
	-- Update buy button state
	for _, child in container:GetDescendants() do
		if child:IsA("GuiButton") then
			-- Update button appearance based on unlock state
			if isUnlocked then
				-- Show as purchased
				if child:IsA("ImageButton") then
					child.Image = ImageIds.greenButton
				end
				
				-- Update text to show "Owned"
				for _, textChild in child:GetDescendants() do
					if textChild:IsA("TextLabel") then
						if string.find(textChild.Text:lower(), "buy") or string.find(textChild.Text:lower(), "coins") then
							textChild.Text = "Owned"
						end
					end
				end
				
				-- Disable button interaction
				child.Active = false
			end
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
