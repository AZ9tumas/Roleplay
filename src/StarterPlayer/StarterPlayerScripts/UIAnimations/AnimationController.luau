--[[
	AnimationController - Handles all UI animations
	
	This module provides animation utilities that replicate the React/Ripple-based
	animations from the previous UI system:
	- Spring-like button scaling (hover/click effects)
	- Slide in/out animations for menus
	- Fade animations for overlays
	- Loading spinner rotation
	- Auto-scaling based on viewport size
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Charm = require(ReplicatedStorage.Packages.Charm)

-- Animation TweenInfo presets
local SPRING_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SLIDE_IN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SLIDE_OUT_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FADE_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-- Constants
local STUDIO_SIZE = Vector2.new(1500, 803)
local DEFAULT_HOVER_SCALE = 1.1
local DEFAULT_CLICK_SCALE = 0.9
local DEFAULT_SCALE = 1

-- Default icon positions for HudButtons
local DEFAULT_ICON_POSITION = UDim2.fromScale(0.5, 0.25)
local HOVER_ICON_POSITION = UDim2.fromScale(0.5, 0.18)

local AnimationController = {}

-- Tracking tables
local buttonAnimations: { [GuiButton]: { uiScale: UIScale, isHovering: boolean, isHolding: boolean } } = {}
local menuAnimations: { [string]: { element: Frame, shownPos: UDim2, hiddenPos: UDim2, isShown: boolean } } = {}
local autoScaledElements: { { element: Frame, scaleFactor: number, minScale: number } } = {}
local fadeElements: { [CanvasGroup]: { rotatingElement: ImageLabel?, rotationConn: RBXScriptConnection?, isShown: boolean } } = {}
local connections: { RBXScriptConnection } = {}

-- Menu state atom (standalone, no dependency on UI module)
local openedMenu = Charm.atom(nil :: string?)

--[[
	Get/Set the currently opened menu
]]
function AnimationController.setMenu(menuId: string?)
	openedMenu(if Charm.peek(openedMenu) == menuId then nil else menuId)
end

function AnimationController.getMenuState()
	return openedMenu
end

--[[
	Button Animation System
	Provides hover/click scaling effects similar to BasicButton/HudButton React components
]]

function AnimationController.setupButtonAnimation(button: GuiButton, options: {
	hoverScale: number?,
	clickScale: number?,
	iconElement: ImageLabel?,
	iconHoverPosition: UDim2?,
	iconDefaultPosition: UDim2?,
}?)
	local opts = options or {}
	local hoverScale = opts.hoverScale or DEFAULT_HOVER_SCALE
	local clickScale = opts.clickScale or DEFAULT_CLICK_SCALE

	-- Use existing UIScale or create one
	local uiScale = button:FindFirstChild("UIScale") :: UIScale
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Name = "UIScale"
		uiScale.Parent = button
	end

	local state = {
		uiScale = uiScale,
		isHovering = false,
		isHolding = false,
	}
	buttonAnimations[button] = state

	local function updateScale()
		local targetScale = DEFAULT_SCALE
		if state.isHolding then
			targetScale = clickScale
		elseif state.isHovering then
			targetScale = hoverScale
		end

		local tween = TweenService:Create(uiScale, SPRING_INFO, {
			Scale = targetScale
		})
		tween:Play()
	end

	local function updateIconPosition()
		if not opts.iconElement then return end
		
		local targetPos = state.isHovering and opts.iconHoverPosition or opts.iconDefaultPosition
		if targetPos then
			local tween = TweenService:Create(opts.iconElement, SPRING_INFO, {
				Position = targetPos
			})
			tween:Play()
		end
	end

	table.insert(connections, button.MouseEnter:Connect(function()
		state.isHovering = true
		updateScale()
		updateIconPosition()
	end))

	table.insert(connections, button.MouseLeave:Connect(function()
		state.isHovering = false
		state.isHolding = false
		updateScale()
		updateIconPosition()
	end))

	table.insert(connections, button.MouseButton1Down:Connect(function()
		state.isHolding = true
		updateScale()
	end))

	table.insert(connections, button.MouseButton1Up:Connect(function()
		state.isHolding = false
		updateScale()
	end))
end

--[[
	Menu Slide Animation System
	Provides slide in/out animations for menu panels (similar to SlideOutFrame)
]]

function AnimationController.registerMenu(menuId: string, element: Frame, shownPos: UDim2, hiddenPos: UDim2)
	-- Start hidden
	element.Position = hiddenPos
	element.Visible = false

	menuAnimations[menuId] = {
		element = element,
		shownPos = shownPos,
		hiddenPos = hiddenPos,
		isShown = false,
	}
end

function AnimationController.showMenu(menuId: string)
	local data = menuAnimations[menuId]
	if not data or data.isShown then return end

	data.isShown = true
	data.element.Visible = true

	local tween = TweenService:Create(data.element, SLIDE_IN_INFO, {
		Position = data.shownPos
	})
	tween:Play()
end

function AnimationController.hideMenu(menuId: string)
	local data = menuAnimations[menuId]
	if not data or not data.isShown then return end

	data.isShown = false

	local tween = TweenService:Create(data.element, SLIDE_OUT_INFO, {
		Position = data.hiddenPos
	})
	tween:Play()
	
	tween.Completed:Connect(function()
		if not data.isShown then
			data.element.Visible = false
		end
	end)
end

--[[
	Fade Animation System
	Used for overlays like PurchaseScreen
]]

function AnimationController.setupFadeElement(element: CanvasGroup, rotatingElement: ImageLabel?)
	element.GroupTransparency = 1
	element.Visible = false

	fadeElements[element] = {
		rotatingElement = rotatingElement,
		rotationConn = nil,
		isShown = false,
	}
end

function AnimationController.showFadeElement(element: CanvasGroup)
	local data = fadeElements[element]
	if not data or data.isShown then return end

	data.isShown = true
	element.Visible = true

	local tween = TweenService:Create(element, FADE_INFO, {
		GroupTransparency = 0
	})
	tween:Play()

	-- Start rotation if there's a rotating element
	if data.rotatingElement then
		local rotation = 0
		data.rotationConn = RunService.PreRender:Connect(function(dt: number)
			rotation = rotation + (60 * dt)
			if data.rotatingElement then
				data.rotatingElement.Rotation = rotation
			end
		end)
	end
end

function AnimationController.hideFadeElement(element: CanvasGroup)
	local data = fadeElements[element]
	if not data or not data.isShown then return end

	data.isShown = false

	-- Stop rotation
	if data.rotationConn then
		data.rotationConn:Disconnect()
		data.rotationConn = nil
	end

	local tween = TweenService:Create(element, FADE_INFO, {
		GroupTransparency = 1
	})
	tween:Play()
	
	tween.Completed:Connect(function()
		if not data.isShown then
			element.Visible = false
		end
	end)
end

--[[
	Auto-Scaling System
	Scales UI elements based on viewport size (similar to AutoScaledFrame)
]]

function AnimationController.setupAutoScaling(element: Frame, scaleFactor: number?, minScale: number?)
	local uiScale = element:FindFirstChild("UIScale") :: UIScale
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Name = "UIScale"
		uiScale.Parent = element
	end

	table.insert(autoScaledElements, {
		element = element,
		scaleFactor = scaleFactor or 1,
		minScale = minScale or 0,
	})
end

local function updateAllAutoScaling()
	local camera = workspace.CurrentCamera
	if not camera then return end

	local viewportSize = camera.ViewportSize

	for _, data in autoScaledElements do
		local uiScale = data.element:FindFirstChild("UIScale") :: UIScale
		if uiScale then
			local newScale = data.scaleFactor * math.min(viewportSize.X / STUDIO_SIZE.X, viewportSize.Y / STUDIO_SIZE.Y)
			uiScale.Scale = math.max(newScale, data.minScale)
		end
	end
end

--[[
	Setup animations on an existing HudButton (MorphButton, ShopButton, CoinShopButton, etc.)
]]
local function setupExistingHudButton(button: ImageButton, menuId: string?)
	local buttonIcon = button:FindFirstChild("ButtonIcon") :: ImageLabel
	
	AnimationController.setupButtonAnimation(button, {
		hoverScale = 1.1,
		clickScale = 0.9,
		iconElement = buttonIcon,
		iconDefaultPosition = DEFAULT_ICON_POSITION,
		iconHoverPosition = HOVER_ICON_POSITION,
	})
	
	-- Connect to menu toggle if menuId is provided
	if menuId then
		button.Activated:Connect(function()
			AnimationController.setMenu(menuId)
		end)
	end
end

--[[
	Initialize animations on existing UI elements
	This is the main entry point for the existing UI structure
]]
function AnimationController.initExistingUI(gameGui: ScreenGui)
	-- Setup viewport scaling listener
	local camera = workspace.CurrentCamera
	if camera then
		table.insert(connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateAllAutoScaling))
		updateAllAutoScaling()
	end

	-- Find and setup LeftBar
	local leftBar = gameGui:FindFirstChild("LeftBar") :: Frame
	if leftBar then
		-- Setup auto-scaling for LeftBar
		AnimationController.setupAutoScaling(leftBar, 1, 0)
		
		-- Find and setup buttons in LeftBar
		local morphButton = leftBar:FindFirstChild("MorphButton") :: ImageButton
		if morphButton then
			setupExistingHudButton(morphButton, "Morph")
		end
		
		local shopButton = leftBar:FindFirstChild("ShopButton") :: ImageButton
		if shopButton then
			setupExistingHudButton(shopButton, "Shop")
		end
		
		local coinShopButton = leftBar:FindFirstChild("CoinShopButton") :: ImageButton
		if coinShopButton then
			setupExistingHudButton(coinShopButton, "CoinShop")
		end
	end

	-- Find and setup menu panels (Morph, Shop, CoinShop)
	local morphMenu = gameGui:FindFirstChild("Morph") :: Frame
	if morphMenu then
		AnimationController.registerMenu("Morph", morphMenu, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 1.5))
		AnimationController.setupAutoScaling(morphMenu, 1, 0)
	end

	local shopMenu = gameGui:FindFirstChild("Shop") :: Frame
	if shopMenu then
		AnimationController.registerMenu("Shop", shopMenu, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 1.5))
		AnimationController.setupAutoScaling(shopMenu, 1, 0)
	end
	
	local coinShopMenu = gameGui:FindFirstChild("CoinShop") :: Frame
	if coinShopMenu then
		AnimationController.registerMenu("CoinShop", coinShopMenu, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 1.5))
		AnimationController.setupAutoScaling(coinShopMenu, 1, 0)
	end

	-- Find and setup Purchase Screen
	local purchaseScreen = gameGui:FindFirstChild("PurchaseScreen") :: CanvasGroup
	if purchaseScreen then
		local loadingIcon = purchaseScreen:FindFirstChild("Loading") :: ImageLabel
		AnimationController.setupFadeElement(purchaseScreen, loadingIcon)
	end

	-- Find and setup NewMorph notification
	local newMorph = gameGui:FindFirstChild("NewMorph") :: Frame
	if newMorph then
		AnimationController.setupAutoScaling(newMorph, 1, 0)
	end

	-- Setup all remaining buttons recursively for basic animations
	local function setupAllButtons(parent: Instance)
		for _, child in parent:GetChildren() do
			if (child:IsA("ImageButton") or child:IsA("TextButton")) and not buttonAnimations[child] then
				AnimationController.setupButtonAnimation(child :: GuiButton, {
					hoverScale = 1.1,
					clickScale = 0.9,
				})
			end
			setupAllButtons(child)
		end
	end
	setupAllButtons(gameGui)

	-- Subscribe to menu state changes (using local atom)
	Charm.subscribe(openedMenu, function(currentMenu: string?)
		-- Hide all menus first
		for menuId, _ in menuAnimations do
			if menuId ~= currentMenu then
				AnimationController.hideMenu(menuId)
			end
		end

		-- Show the selected menu
		if currentMenu then
			AnimationController.showMenu(currentMenu)
		end
	end)

	-- Try to subscribe to purchase state if available
	local purchaseStateOk, purchaseSlice = pcall(function()
		return require(ReplicatedStorage.Packages.Charm) -- Just checking if Charm is available
	end)
	
	-- Note: Purchase state subscription would need to be connected externally
	-- since we're removing the UI module dependency
end

--[[
	Cleanup
]]

function AnimationController.cleanup()
	-- Clean up main connections
	for _, conn in connections do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	
	-- Clean up fade element rotation connections
	for _, data in fadeElements do
		if data.rotationConn and data.rotationConn.Connected then
			data.rotationConn:Disconnect()
		end
	end
	
	connections = {}
	buttonAnimations = {}
	menuAnimations = {}
	autoScaledElements = {}
	fadeElements = {}
end

return AnimationController
