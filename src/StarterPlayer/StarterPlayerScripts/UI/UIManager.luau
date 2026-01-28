--!strict
-- UIManager - Simple UI controller using native TweenService
-- Handles all UI animations and data binding for morphs and coin shop

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService).client
local Morphs = require(ReplicatedStorage.Shared.Modules.Game.Morphs)
local CoinMorphs = require(ReplicatedStorage.Shared.Modules.Game.CoinMorphs)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)
local MorphServiceClient = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceClient)

local UIManager = {}

-- Constants
local TWEEN_INFO_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_INFO_SLIDE = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_INFO_SLIDE_OUT = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local BUTTON_SCALE_NORMAL = 1
local BUTTON_SCALE_HOVER = 1.1
local BUTTON_SCALE_PRESSED = 0.9

-- Info
-- {itemName: string -> productName: string}
local productNames = {
	["1"] = "MorphPack1",
	["UnlockMorph"] = "UnlockMorph",
}

-- State
local currentOpenMenu: string? = nil
local connections: { RBXScriptConnection } = {}

-- UI References
local gameGui: ScreenGui
local leftBar: Frame
local morphScreen: Frame?
local coinShopScreen: Frame?
local shopScreen: Frame?
local newMorphPopup: Frame?

-- Helper: Get player's coins from leaderstats
local function getPlayerCoins(): number
	local player = Players.LocalPlayer
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins and coins:IsA("IntValue") then
			return coins.Value
		end
	end
	return DataService:get({ "coins" }) or 0
end

local function print(msg) end

-- Helper: Setup button hover/click animations
local function setupButtonAnimation(button: GuiButton)
	local uiScale = button:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = button
	end
	
	button.MouseEnter:Connect(function()
		TweenService:Create(uiScale, TWEEN_INFO_FAST, { Scale = BUTTON_SCALE_HOVER }):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(uiScale, TWEEN_INFO_FAST, { Scale = BUTTON_SCALE_NORMAL }):Play()
	end)
	
	button.MouseButton1Down:Connect(function()
		TweenService:Create(uiScale, TWEEN_INFO_FAST, { Scale = BUTTON_SCALE_PRESSED }):Play()
	end)
	
	button.MouseButton1Up:Connect(function()
		TweenService:Create(uiScale, TWEEN_INFO_FAST, { Scale = BUTTON_SCALE_HOVER }):Play()
	end)
end

-- Helper: Slide a frame in from bottom
local function slideIn(frame: Frame)
	frame.Visible = true
	local targetPos = UDim2.fromScale(0.5, 0.5)
	local startPos = UDim2.fromScale(0.5, 1.5)
	frame.Position = startPos
	TweenService:Create(frame, TWEEN_INFO_SLIDE, { Position = targetPos }):Play()
end

-- Helper: Slide a frame out to bottom
local function slideOut(frame: Frame)
	local targetPos = UDim2.fromScale(0.5, 1.5)
	local tween = TweenService:Create(frame, TWEEN_INFO_SLIDE_OUT, { Position = targetPos })
	tween:Play()
	tween.Completed:Connect(function()
		if frame.Position.Y.Scale >= 1.4 then
			frame.Visible = false
		end
	end)
end

-- Open a menu (close others first)
local function openMenu(menuId: string)
	-- Close current menu if different
	if currentOpenMenu and currentOpenMenu ~= menuId then
		if currentOpenMenu == "Morph" and morphScreen then
			slideOut(morphScreen)
		elseif currentOpenMenu == "CoinShop" and coinShopScreen then
			slideOut(coinShopScreen)
		elseif currentOpenMenu == "Shop" and shopScreen then
			slideOut(shopScreen)
		end
	end
	
	-- Open new menu or toggle off
	if currentOpenMenu == menuId then
		-- Toggle off
		if menuId == "Morph" and morphScreen then
			slideOut(morphScreen)
		elseif menuId == "CoinShop" and coinShopScreen then
			slideOut(coinShopScreen)
		elseif menuId == "Shop" and shopScreen then
			slideOut(shopScreen)
		end
		currentOpenMenu = nil
	else
		-- Open
		if menuId == "Morph" and morphScreen then
			slideIn(morphScreen)
		elseif menuId == "CoinShop" and coinShopScreen then
			slideIn(coinShopScreen)
		elseif menuId == "Shop" and shopScreen then
			slideIn(shopScreen)
		end
		currentOpenMenu = menuId
	end
end

-- Setup LeftBar buttons
local function setupLeftBar()
	if not leftBar then return end
	
	local morphButton = leftBar:FindFirstChild("MorphButton") :: GuiButton?
	local coinShopButton = leftBar:FindFirstChild("CoinShopButton") :: GuiButton?
	local shopButton = leftBar:FindFirstChild("ShopButton") :: GuiButton?
	
	if morphButton then
		setupButtonAnimation(morphButton)
		table.insert(connections, morphButton.MouseButton1Click:Connect(function()
			openMenu("Morph")
		end))
	end
	
	if coinShopButton then
		setupButtonAnimation(coinShopButton)
		table.insert(connections, coinShopButton.MouseButton1Click:Connect(function()
			openMenu("CoinShop")
		end))
	end
	
	if shopButton then
		setupButtonAnimation(shopButton)
		table.insert(connections, shopButton.MouseButton1Click:Connect(function()
			openMenu("Shop")
		end))
	end

	-- an addition coin Shop Button and shop button will be found under the shopScreen, they
	-- server the same purpose as the above buttons (coinShopButton and shopButton). These need
	-- to be initialized as well. These buttons have the same names, but are located elsewhere.
	if shopScreen then
		local innerCoinShopButton = shopScreen:FindFirstChild("CoinShopButton", true) :: GuiButton?
		local innerShopButton = coinShopScreen:FindFirstChild("ShopButton", true) :: GuiButton?
		
		if innerCoinShopButton then
			setupButtonAnimation(innerCoinShopButton)
			table.insert(connections, innerCoinShopButton.MouseButton1Click:Connect(function()
				openMenu("CoinShop")
			end))
		end
		
		if innerShopButton then
			setupButtonAnimation(innerShopButton)
			table.insert(connections, innerShopButton.MouseButton1Click:Connect(function()
				openMenu("Shop")
			end))
		end
	end
end

-- Update a morph template's state (locked/unlocked, equipped/unequipped)
local function updateMorphTemplate(template: Instance, morphName: string, isUnlocked: boolean, isEquipped: boolean)
	-- Remove "Locked" ImageLabel to show as unlocked
	local locked = template:FindFirstChild("Locked") :: ImageLabel?
	if locked then
		locked.Visible = not isUnlocked
	end
	
	-- Find PurchaseButton - acts as equip/unequip button when unlocked
	local purchaseButton = template:FindFirstChild("PurchaseButton") :: GuiButton?
	if purchaseButton then
		-- Update button text
		for _, child in purchaseButton:GetDescendants() do
			if child:IsA("TextLabel") then
				if isUnlocked then
					child.Text = if isEquipped then "Unequip" else "Equip"
				else
					-- Show price for locked morphs
					local productData = Products.ids[morphName]
					if productData then
						child.Text = "Buy"
					else
						child.Text = "Locked"
					end
				end
			end
		end
	end
end

-- Update coin shop morph template
local function updateCoinShopMorphTemplate(template: Instance, morphName: string, isUnlocked: boolean)
	local buyButton = template:FindFirstChild("BuyButton") :: GuiButton?
	if buyButton then
		local costLabel = buyButton:FindFirstChild("CostLabel") :: TextLabel?
		if costLabel then
			if isUnlocked then
				costLabel.Text = "Owned"
			else
				local morphData = CoinMorphs[morphName]
				if morphData then
					costLabel.Text = tostring(morphData.cost) .. " Coins"
				end
			end
		end
		
		-- Disable button if owned
		buyButton.Active = not isUnlocked
	end
end

-- Setup Morph Screen
local function setupMorphScreen()
	if not morphScreen then 
		print("UIManager: MorphScreen not found")
		return 
	end
	
	print("UIManager: Setting up MorphScreen")
	
	-- Initially hide
	morphScreen.Visible = false
	morphScreen.Position = UDim2.fromScale(0.5, 1.5)
	
	-- Find MorphList and setup each morph template
	local morphList = morphScreen:FindFirstChild("Page", true)
	print("UIManager: MorphScreen Page found:", morphList ~= nil)
	if morphList then

		local isAscending = false
		local filterButton = morphList:WaitForChild("Filter") :: TextButton
		setupButtonAnimation(filterButton)
		table.insert(connections, filterButton.MouseButton1Click:Connect(function()
			isAscending = not isAscending
			local list = morphList:FindFirstChild("MorphList")
			if list then
				local layout = list:FindFirstChildOfClass("UIGridLayout") or list:FindFirstChildOfClass("UIListLayout")
				if layout then
					layout.SortOrder = Enum.SortOrder.LayoutOrder
				end

				local items = {}
				for _, child in list:GetChildren() do
					if child:IsA("Frame") or child:IsA("ImageLabel") then
						table.insert(items, child)
					end
				end

				table.sort(items, function(a, b)
					if isAscending then
						return a.Name < b.Name
					else
						return a.Name > b.Name
					end
				end)

				for i, item in items do
					item.LayoutOrder = i
				end
			end
		end))

		local list = morphList:FindFirstChild("MorphList")
		if list then
			-- Find template processing
			local template: Instance? = nil
			for _, child in list:GetChildren() do
				if child:IsA("ImageLabel") then
					template = child
					break
				end
			end

			if template then
				local morphTemplate = template:Clone()

				-- Clear existing list items
				for _, child in list:GetChildren() do
					if child:IsA("ImageLabel") then
						child:Destroy()
					end
				end

				-- Sort keys for consistent order
				local morphNames = {}
				for name in pairs(Morphs) do
					table.insert(morphNames, name)
				end
				table.sort(morphNames)

				local unlockedMorphs = DataService:get({ "unlockedMorph" }) or {}

				-- Populate morphs
				for _, morphName in morphNames do
					local item = morphTemplate:Clone()
					item.Name = morphName
					item.Visible = true
					item.Parent = list

					-- Set display name
					local nameLabel = item:FindFirstChild("MorphName")
					if nameLabel and nameLabel:IsA("TextLabel") then
						nameLabel.Text = Morphs[morphName].displayName
					end

					-- Check ownership / Locked status
					local isUnlocked = unlockedMorphs[morphName] ~= nil
					local locked = item:FindFirstChild("Locked")
					if locked then
						locked.Visible = not isUnlocked
					end

					-- Setup interactions
					local purchaseButton = item:FindFirstChild("PurchaseButton") :: GuiButton?
					if purchaseButton then
						setupButtonAnimation(purchaseButton)
						table.insert(connections, purchaseButton.MouseButton1Click:Connect(function()
							local currentUnlocked = DataService:get({ "unlockedMorph" }) or {}
							local currentIsUnlocked = currentUnlocked[morphName] ~= nil
							local equippedMorph = DataService:get({ "equippedMorph" })
							
							print("UIManager: PurchaseButton clicked for morph:", morphName, "isUnlocked:", currentIsUnlocked, "equippedMorph:", equippedMorph)
							
							if currentIsUnlocked then
								-- Equip or unequip
								if equippedMorph == morphName then
									print("UIManager: Calling unequipMorph")
									MorphServiceClient:unequipMorph()
								else
									print("UIManager: Calling equipMorph with", morphName)
									MorphServiceClient:equipMorph(morphName)
								end
							else
								-- Try to purchase
								print("UIManager: Calling purchaseMorph with", morphName)
								MorphServiceClient:purchaseMorph(morphName)
							end
						end))
					end
				end
			else
				warn("UIManager: No template ImageLabel found in MorphList")
			end
		end
	end
end

-- Setup Coin Shop Screen
local function setupCoinShopScreen()
	if not coinShopScreen then 
		print("UIManager: CoinShopScreen not found")
		return 
	end
	
	print("UIManager: Setting up CoinShopScreen")
	
	-- Initially hide
	coinShopScreen.Visible = false
	coinShopScreen.Position = UDim2.fromScale(0.5, 1.5)
	
	-- Find CoinsLabel and update it
	local coinsDisplay = coinShopScreen.Content:FindFirstChild("CoinsDisplay")
	if coinsDisplay then
		local coinsLabel = coinsDisplay:FindFirstChild("CoinsLabel") :: TextLabel?
		if coinsLabel then
			coinsLabel.Text = "Coins: " .. tostring(getPlayerCoins())
		end
	end
	
	-- Find ShopList and Morphs container
	local shopList = coinShopScreen.Content:FindFirstChild("ShopList")
	print("UIManager: CoinShop ShopList found:", shopList ~= nil)
	if shopList then
		local morphsSection = shopList:FindFirstChild("Morphs", true)
		print("UIManager: CoinShop Morphs section found:", morphsSection ~= nil)
		if morphsSection then
			local content = morphsSection:FindFirstChild("Content")
			print("UIManager: CoinShop Content found:", content ~= nil)
			if content then
				-- Check if there's a Grid inside Content
				local itemContainer = content
				print("UIManager: CoinShop using container:", itemContainer.Name, "with", #itemContainer:GetChildren(), "children")
				
				for _, child in itemContainer:GetChildren() do
					print("UIManager: CoinShop child:", child.Name, "IsA Frame/ImageLabel:", child:IsA("Frame") or child:IsA("ImageLabel"))
					if child:IsA("Frame") or child:IsA("ImageLabel") then
						local morphName = child.Name
						-- Also check ProductName label for actual morph name
						local productNameLabel = child:FindFirstChild("ProductName") :: TextLabel?
						if productNameLabel and productNameLabel:IsA("TextLabel") then
							if CoinMorphs[child.Name] then
								morphName = child.Name
							end
						end
						
						print("UIManager: CoinShop checking morphName:", morphName, "inCoinMorphs:", CoinMorphs[morphName] ~= nil)
						if CoinMorphs[morphName] then
							-- Setup BuyButton click and animation
							local buyButton = child:FindFirstChild("BuyButton") :: GuiButton?
							print("UIManager: CoinShop BuyButton found:", buyButton ~= nil)
							if buyButton then
								print("UIManager: Setting up CoinShop BuyButton animation for", morphName)
								setupButtonAnimation(buyButton)
								
								local capturedMorphName = morphName
								table.insert(connections, buyButton.MouseButton1Click:Connect(function()
									local unlockedMorphs = DataService:get({ "unlockedMorph" }) or {}
									local isUnlocked = unlockedMorphs[capturedMorphName] ~= nil
									
									if not isUnlocked then
										print("UIManager: Purchasing coin morph", capturedMorphName)
										MorphServiceClient:purchaseCoinMorph(capturedMorphName)
									else
										print("UIManager: Already owns coin morph", capturedMorphName)
									end
								end))
							end
						end
					end
				end
			end
		end
	end
end

-- Setup NewMorph popup
local function setupNewMorphPopup()
	if not newMorphPopup then return end
	
	-- Initially hide
	newMorphPopup.Visible = false
	newMorphPopup.Position = UDim2.fromScale(0.5, 1.5)
end

-- Helper: Get product name from a shop item (item.Name is directly linked to product name)
local function getProductNameFromItem(item: Instance): string?
	-- Primary: check if item name directly matches a product or morph
	-- (UI items are named after the product/morph they represent)
	if Products.ids[item.Name] then
		return item.Name
	end
	if Morphs[item.Name] then
		return item.Name
	end

	if productNames[item.Name] then
		return productNames[item.Name]
	end
	
	-- Fallback: check ProductName TextLabel if item name doesn't match
	local productNameLabel = item:FindFirstChild("ProductName") :: TextLabel?
	if productNameLabel and productNameLabel:IsA("TextLabel") then
		local labelText = productNameLabel.Text
		if Products.ids[labelText] then
			return labelText
		end
		if Morphs[labelText] then
			return labelText
		end
	end
	
	return nil
end

-- Setup Shop Screen (Robux purchases)
local function setupShopScreen()
	if not shopScreen then return end
	
	-- Initially hide
	shopScreen.Visible = false
	shopScreen.Position = UDim2.fromScale(0.5, 1.5)
	
	-- Find ShopList which contains Morphs and LimitedMorphs sections
	local shopList = shopScreen:FindFirstChild("ShopList", true)
	if not shopList then 
		print("UIManager: ShopList not found in Shop screen")
		return
	end
	
	print("UIManager: Setting up Shop screen, found ShopList")
	
	-- Process both Morphs and LimitedMorphs sections
	for _, section in shopList:GetChildren() do
		if section.Name == "Morphs" or section.Name == "LimitedMorphs" then
			local content = section:FindFirstChild("Content")
			if content then
				local itemContainer = content
				
				print("UIManager: Processing section", section.Name, "with", #itemContainer:GetChildren(), "items")
				
				for _, child in itemContainer:GetChildren() do
					if child:IsA("Frame") or child:IsA("ImageLabel") then
						-- Get the actual product name from ProductName TextLabel or the item name
						local productName = getProductNameFromItem(child)
						print("UIManager: Item", child.Name, "resolved to product:", productName or "nil")
						
						-- Setup BuyButton click and animation
						local buyButton = child:FindFirstChild("BuyButton") :: GuiButton?
						if buyButton then
							print("UIManager: Setting up Shop BuyButton animation for", child.Name)
							setupButtonAnimation(buyButton)
							
							-- Store productName in closure
							local capturedProductName = productName or child.Name
							
							table.insert(connections, buyButton.MouseButton1Click:Connect(function()
								local player = Players.LocalPlayer
								local productData = Products.ids[capturedProductName]
								
								-- Check if already owned
								local unlockedMorphs = DataService:get({ "unlockedMorph" }) or {}
								local isUnlocked = unlockedMorphs[capturedProductName] ~= nil
								
								if not isUnlocked then
									-- Prompt the purchase using Products module (same as ProductButton)
									if productData then
										print("UIManager: Prompting Robux purchase for", capturedProductName, "productId:", productData.productId)
										Products.prompt(player, capturedProductName)
									else
										-- Try generic morph purchase if no specific product
										print("UIManager: No product data for", capturedProductName, "- using UnlockMorph")
										-- For morphs without their own product, use UnlockMorph generic product
										Products.prompt(player, "UnlockMorph")
									end
								else
									print("UIManager: Already owns", capturedProductName)
								end
							end))
							
							print("UIManager: Connected BuyButton for", capturedProductName)
						end
					end
				end
			end
		end
	end
end

-- Show new morph popup
local function showNewMorphPopup(morphName: string)
	if not newMorphPopup then return end
	
	-- Update morph name if there's a label
	for _, child in newMorphPopup:GetDescendants() do
		if child:IsA("TextLabel") and child.Name == "MorphName" then
			child.Text = morphName
		end
	end
	
	slideIn(newMorphPopup)
	
	-- Auto-dismiss on click
	local clickConn: RBXScriptConnection?
	
	local function dismiss()
		if clickConn then
			clickConn:Disconnect()
			clickConn = nil
			slideOut(newMorphPopup)
		end
	end
	
	clickConn = game:GetService("UserInputService").InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dismiss()
		end
	end)
	
	-- Auto-dismiss after 2.5s
	task.delay(2.5, dismiss)
end

-- Update all morph templates based on current data
local function updateAllMorphs()
	local unlockedMorphs = DataService:get({ "unlockedMorph" }) or {}
	local equippedMorph = DataService:get({ "equippedMorph" })
	
	-- Update Morph Screen templates
	if morphScreen then
		local morphList = morphScreen:FindFirstChild("Page", true)
		if morphList then
			local list = morphList:FindFirstChild("MorphList")
			if list then
				for _, child in list:GetChildren() do
					if child:IsA("Frame") or child:IsA("ImageLabel") then
						local morphName = child.Name
						if Morphs[morphName] then
							local isUnlocked = unlockedMorphs[morphName] ~= nil
							local isEquipped = equippedMorph == morphName
							updateMorphTemplate(child, morphName, isUnlocked, isEquipped)
						end
					end
				end
			end
		end
	end
	
	-- Update Coin Shop templates
	if coinShopScreen then
		local shopList = coinShopScreen:FindFirstChild("ShopList", true)
		if shopList then
			local morphsSection = shopList:FindFirstChild("Morphs", true)
			if morphsSection then
				local content = morphsSection:FindFirstChild("Content")
				if content then
					for _, child in content:GetChildren() do
						if child:IsA("Frame") or child:IsA("ImageLabel") then
							local morphName = child.Name
							if CoinMorphs[morphName] then
								local isUnlocked = unlockedMorphs[morphName] ~= nil
								updateCoinShopMorphTemplate(child, morphName, isUnlocked)
							end
						end
					end
				end
			end
		end
	end
	
	-- Update Shop Screen templates (Robux purchases)
	if shopScreen then
		local shopList = shopScreen:FindFirstChild("ShopList", true)
		if shopList then
			for _, section in shopList:GetChildren() do
				if section.Name == "Morphs" or section.Name == "LimitedMorphs" then
					local content = section:FindFirstChild("Content")
					if content then
						local itemContainer = content
						
						for _, child in itemContainer:GetChildren() do
							if child:IsA("Frame") or child:IsA("ImageLabel") then
								local productName = getProductNameFromItem(child) or child.Name
								local isUnlocked = unlockedMorphs[productName] ~= nil
								
								-- Update BuyButton state
								local buyButton = child:FindFirstChild("BuyButton") :: GuiButton?
								if buyButton then
									-- Find text label inside button
									for _, desc in buyButton:GetDescendants() do
										if desc:IsA("TextLabel") and (desc.Name == "CostLabel" or desc.Name == "TextLabel") then
											if isUnlocked then
												desc.Text = "Owned"
											end
										end
									end
									
									-- Disable button if owned
									buyButton.Active = not isUnlocked
								end
							end
						end
					end
				end
			end
		end
	end
end

-- Update coins display
local function updateCoinsDisplay()
	local coins = getPlayerCoins()
	
	if coinShopScreen then
		local coinsDisplay = coinShopScreen:FindFirstChild("CoinsDisplay", true)
		if coinsDisplay then
			local coinsLabel = coinsDisplay:FindFirstChild("CoinsLabel") :: TextLabel?
			if coinsLabel then
				coinsLabel.Text = "Coins: " .. tostring(coins)
			end
		end
	end
end

-- Setup data listeners
local function setupDataListeners()
	-- Listen for unlocked morph changes
	table.insert(connections, DataService:getIndexChangedSignal({ "unlockedMorph" }):Connect(function(index)
		updateAllMorphs()
		if index then
			showNewMorphPopup(index)
		end
	end))
	
	-- Listen for equipped morph changes
	table.insert(connections, DataService:getChangedSignal({ "equippedMorph" }):Connect(function()
		updateAllMorphs()
	end))
	
	-- Listen for coins changes
	table.insert(connections, DataService:getChangedSignal({ "coins" }):Connect(function()
		updateCoinsDisplay()
	end))
	
	-- Also listen to leaderstats changes
	local player = Players.LocalPlayer
	local leaderstats = player:WaitForChild("leaderstats", 5)
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins and coins:IsA("IntValue") then
			table.insert(connections, coins.Changed:Connect(function()
				updateCoinsDisplay()
			end))
		end
	end
end

-- Initialize UI
function UIManager.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	gameGui = playerGui:WaitForChild("GameGui") :: ScreenGui
	
	-- Find UI elements
	leftBar = gameGui:FindFirstChild("LeftBar") :: Frame
	morphScreen = gameGui:FindFirstChild("Morph") :: Frame?
	coinShopScreen = gameGui:FindFirstChild("CoinShop") :: Frame?
	shopScreen = gameGui:FindFirstChild("Shop") :: Frame?
	newMorphPopup = gameGui:FindFirstChild("NewMorph") :: Frame?
	
	-- Setup all UI components
	setupLeftBar()
	setupMorphScreen()
	setupCoinShopScreen()
	setupShopScreen()
	setupNewMorphPopup()
	
	-- Setup data listeners
	setupDataListeners()
	
	-- Initial update
	updateAllMorphs()
	updateCoinsDisplay()
	
	print("UIManager: Initialized")
end

-- Cleanup
function UIManager.cleanup()
	for _, conn in connections do
		conn:Disconnect()
	end
	connections = {}
end

return UIManager
