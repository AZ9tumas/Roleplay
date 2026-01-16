--!strict
-- ButtonAnimations module for hover/click spring effects
-- Replaces the React-based BasicButton and HudButton components

local Spring = require(script.Parent.Spring)

export type ButtonAnimation = {
	setup: (button: GuiButton) -> (),
	cleanup: () -> (),
}

local DEFAULT_SPRING_OPTIONS = { frequency = 0.2, damping = 0.8 }

local ButtonAnimations = {}

-- Setup button hover/click animations with spring scaling
function ButtonAnimations.setupButton(button: GuiButton, onActivated: (() -> ())?): ButtonAnimation
	local connections: { RBXScriptConnection } = {}
	
	-- Find or create UIScale
	local uiScale = button:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = button
	end
	
	local sizeSpring = Spring.create(1, DEFAULT_SPRING_OPTIONS)
	
	-- Update scale on spring step
	local stepDisconnect = sizeSpring.onStep(function(value)
		uiScale.Scale = value
	end)
	
	-- Mouse/Touch events
	table.insert(connections, button.MouseEnter:Connect(function()
		sizeSpring.setGoal(1.1)
	end))
	
	table.insert(connections, button.MouseLeave:Connect(function()
		sizeSpring.setGoal(1)
	end))
	
	table.insert(connections, button.MouseButton1Down:Connect(function()
		sizeSpring.setGoal(0.9)
	end))
	
	table.insert(connections, button.MouseButton1Up:Connect(function()
		sizeSpring.setGoal(1.1)
	end))
	
	if onActivated then
		table.insert(connections, button.Activated:Connect(function()
			onActivated()
		end))
	end
	
	return {
		setup = function() end,
		cleanup = function()
			stepDisconnect()
			for _, conn in connections do
				conn:Disconnect()
			end
			sizeSpring.destroy()
		end,
	}
end

-- Setup HUD button with icon position animation
function ButtonAnimations.setupHudButton(button: GuiButton, iconLabel: ImageLabel?, onActivated: (() -> ())?): ButtonAnimation
	local connections: { RBXScriptConnection } = {}
	
	local DEFAULT_ICON_POSITION = UDim2.fromScale(0.5, 0.25)
	local CHANGED_ICON_POSITION = UDim2.fromScale(0.5, 0.18)
	
	-- Find or create UIScale
	local uiScale = button:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = button
	end
	
	local sizeSpring = Spring.create(1, DEFAULT_SPRING_OPTIONS)
	local iconPosSpring = iconLabel and Spring.create(DEFAULT_ICON_POSITION, DEFAULT_SPRING_OPTIONS)
	
	-- Update scale on spring step
	local stepDisconnect = sizeSpring.onStep(function(value)
		uiScale.Scale = value
	end)
	
	local iconStepDisconnect
	if iconLabel and iconPosSpring then
		iconStepDisconnect = iconPosSpring.onStep(function(value)
			iconLabel.Position = value
		end)
	end
	
	-- Mouse/Touch events
	table.insert(connections, button.MouseEnter:Connect(function()
		sizeSpring.setGoal(1.1)
		if iconPosSpring then
			iconPosSpring.setGoal(CHANGED_ICON_POSITION)
		end
	end))
	
	table.insert(connections, button.MouseLeave:Connect(function()
		sizeSpring.setGoal(1)
		if iconPosSpring then
			iconPosSpring.setGoal(DEFAULT_ICON_POSITION)
		end
	end))
	
	table.insert(connections, button.MouseButton1Down:Connect(function()
		sizeSpring.setGoal(0.9)
	end))
	
	table.insert(connections, button.MouseButton1Up:Connect(function()
		sizeSpring.setGoal(1.1)
	end))
	
	if onActivated then
		table.insert(connections, button.Activated:Connect(function()
			onActivated()
		end))
	end
	
	return {
		setup = function() end,
		cleanup = function()
			stepDisconnect()
			if iconStepDisconnect then
				iconStepDisconnect()
			end
			for _, conn in connections do
				conn:Disconnect()
			end
			sizeSpring.destroy()
			if iconPosSpring then
				iconPosSpring.destroy()
			end
		end,
	}
end

return ButtonAnimations
