--!strict
-- ShopController module for the Shop screen
-- Replaces the React-based ShopScreen component

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService).client
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)
local Morphs = require(ReplicatedStorage.Shared.Modules.Game.Morphs)
local MorphServiceClient = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceClient)
local UIState = require(ReplicatedStorage.Shared.Modules.UI.UIState)
local ButtonAnimations = require(script.Parent.ButtonAnimations)
local MenuController = require(script.Parent.MenuController)

local ShopController = {}
ShopController._menu = nil :: any
ShopController._buttonAnimations = {} :: { [string]: any }
ShopController._connections = {} :: { RBXScriptConnection }
ShopController._productContainers = {} :: { [string]: Frame }
ShopController._soldMorphs = {} :: { [string]: any }

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
	
	-- Find product containers
	ShopController._findProductContainers(shop)
	
	-- Setup purchase buttons
	ShopController._setupButtons(shop)
	
	-- Setup data listeners
	ShopController._setupDataListeners()
	
	-- Load initial data
	ShopController._loadInitialData()
end

function ShopController._findProductContainers(container: Frame)
	-- Find containers for each product
	for productName, productData in Products.ids do
		if not Morphs[productName] then
			continue
		end
		
		for _, child in container:GetDescendants() do
			if child:IsA("Frame") or child:IsA("ImageLabel") then
				if child:GetAttribute("ProductId") == productName or child.Name == productName then
					ShopController._productContainers[productName] = child
					break
				end
			end
		end
	end
end

function ShopController._loadInitialData()
	-- Load sold morphs data
	ShopController._soldMorphs = UIState.soldMorphs or {}
	
	-- Update all containers
	ShopController._updateAllContainers()
end

function ShopController._setupDataListeners()
	-- Listen for sold morphs changes via UIState
	local soldConnection = UIState.onSoldMorphsChanged:Connect(function(soldMorphs)
		ShopController._soldMorphs = soldMorphs or {}
		ShopController._updateAllContainers()
	end)
	table.insert(ShopController._connections, soldConnection)
end

function ShopController._setupButtons(container: Frame)
	-- Find all purchase buttons in the shop
	for _, child in container:GetDescendants() do
		if child:IsA("GuiButton") then
			local productName = child:GetAttribute("ProductName") or child.Parent and child.Parent.Name
			
			if productName and Products.ids[productName] then
				local animation = ButtonAnimations.setupButton(child, function()
					ShopController._onPurchaseButtonClicked(productName)
				end)
				ShopController._buttonAnimations[productName] = animation
			else
				-- Generic button animation without purchase action
				local animation = ButtonAnimations.setupButton(child)
				ShopController._buttonAnimations[child.Name] = animation
			end
		end
	end
end

function ShopController._onPurchaseButtonClicked(productName: string)
	local productData = Products.ids[productName]
	if not productData then
		return
	end
	
	-- Check if product is sold out
	if productData.limitedAmount then
		local soldCount = ShopController._soldMorphs[productName] or 0
		if soldCount >= productData.limitedAmount then
			return -- Sold out
		end
	end
	
	if productData.limitedTime then
		local startTime = ShopController._soldMorphs[productName]
		if startTime then
			local elapsed = os.time() - startTime
			if elapsed >= productData.limitedTime then
				return -- Time expired
			end
		end
	end
	
	-- Prompt purchase
	MorphServiceClient:purchaseMorph(productName)
end

function ShopController._updateAllContainers()
	for productName, container in ShopController._productContainers do
		ShopController._updateProductContainer(productName)
	end
end

function ShopController._updateProductContainer(productName: string)
	local container = ShopController._productContainers[productName]
	if not container then
		return
	end
	
	local productData = Products.ids[productName]
	if not productData then
		return
	end
	
	local isSoldOut = false
	local remainingText = ""
	
	-- Check limited amount
	if productData.limitedAmount then
		local soldCount = ShopController._soldMorphs[productName] or 0
		local remaining = productData.limitedAmount - soldCount
		isSoldOut = remaining <= 0
		remainingText = tostring(remaining) .. " / " .. tostring(productData.limitedAmount)
	end
	
	-- Check limited time
	if productData.limitedTime then
		local startTime = ShopController._soldMorphs[productName]
		if startTime then
			local elapsed = os.time() - startTime
			local remaining = productData.limitedTime - elapsed
			isSoldOut = remaining <= 0
			
			if remaining > 0 then
				local minutes = math.floor(remaining / 60)
				local seconds = remaining % 60
				remainingText = string.format("%d:%02d", minutes, seconds)
			else
				remainingText = "Expired"
			end
		end
	end
	
	-- Update container appearance
	for _, child in container:GetDescendants() do
		-- Update remaining text labels
		if child:IsA("TextLabel") then
			if child.Name == "RemainingLabel" or child:GetAttribute("IsRemainingLabel") then
				child.Text = remainingText
			end
		end
		
		-- Update button state
		if child:IsA("GuiButton") then
			child.Active = not isSoldOut
			
			if isSoldOut then
				-- Grey out the button
				if child:IsA("ImageButton") then
					child.ImageColor3 = Color3.fromRGB(100, 100, 100)
				end
			end
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
