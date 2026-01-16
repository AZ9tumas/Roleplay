--!strict
-- MenuController module for slide in/out menu animations
-- Replaces the React-based Menu and SlideOutFrame components

local Spring = require(script.Parent.Spring)

export type Menu = {
	show: () -> (),
	hide: () -> (),
	toggle: () -> (),
	isShown: () -> boolean,
	destroy: () -> (),
}

local DEFAULT_SPRING_OPTIONS = { frequency = 0.2, damping = 0.8 }

local MenuController = {}
MenuController._openedMenu = nil :: string?
MenuController._menus = {} :: { [string]: Menu }
MenuController._onMenuChanged = nil :: ((menuId: string?) -> ())?

function MenuController.setOnMenuChanged(callback: (menuId: string?) -> ())
	MenuController._onMenuChanged = callback
end

function MenuController.getOpenedMenu(): string?
	return MenuController._openedMenu
end

function MenuController.setOpenedMenu(id: string?)
	if MenuController._openedMenu == id then
		-- Toggle off if same menu
		MenuController._openedMenu = nil
	else
		MenuController._openedMenu = id
	end
	
	if MenuController._onMenuChanged then
		MenuController._onMenuChanged(MenuController._openedMenu)
	end
end

-- Create a slide out frame controller
function MenuController.createSlideOutFrame(
	frame: Frame,
	fromPosition: UDim2,
	toPosition: UDim2,
	shown: boolean?
): Menu
	local isShown = shown or false
	local posSpring = Spring.create(if isShown then fromPosition else toPosition, DEFAULT_SPRING_OPTIONS)
	
	-- Update position on spring step
	local stepDisconnect = posSpring.onStep(function(value)
		frame.Position = value
	end)
	
	-- Set initial visibility
	frame.Visible = isShown
	frame.Position = if isShown then fromPosition else toPosition
	
	local menu: Menu = {
		show = function()
			isShown = true
			frame.Visible = true
			posSpring.snap(toPosition)
			posSpring.setGoal(fromPosition)
		end,
		
		hide = function()
			isShown = false
			posSpring.setGoal(toPosition)
			-- Hide frame after animation completes
			task.delay(0.3, function()
				if not isShown then
					frame.Visible = false
				end
			end)
		end,
		
		toggle = function()
			if isShown then
				menu.hide()
			else
				menu.show()
			end
		end,
		
		isShown = function()
			return isShown
		end,
		
		destroy = function()
			stepDisconnect()
			posSpring.destroy()
		end,
	}
	
	return menu
end

-- Create a menu with slide animation tied to MenuController state
function MenuController.createMenu(
	menuId: string,
	frame: Frame,
	fromPosition: UDim2,
	toPosition: UDim2
): Menu
	local slideMenu = MenuController.createSlideOutFrame(frame, fromPosition, toPosition, false)
	MenuController._menus[menuId] = slideMenu
	
	-- Override show/hide to work with MenuController
	local originalShow = slideMenu.show
	local originalHide = slideMenu.hide
	
	slideMenu.show = function()
		-- Hide all other menus first
		for id, otherMenu in MenuController._menus do
			if id ~= menuId and otherMenu.isShown() then
				otherMenu.hide()
			end
		end
		originalShow()
	end
	
	return slideMenu
end

-- Update all menus based on current opened menu
function MenuController.updateMenus()
	local openedId = MenuController._openedMenu
	
	for id, menu in MenuController._menus do
		if id == openedId then
			if not menu.isShown() then
				menu.show()
			end
		else
			if menu.isShown() then
				menu.hide()
			end
		end
	end
end

return MenuController
