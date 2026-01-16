--[[
	Components - Native UI Component Factory
	
	This module creates native Roblox UI components that match the structure
	and appearance of the previous React-based components.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local ImageIds = require(ReplicatedStorage.Shared.Modules.Game.ImageIds)
local Morphs = require(ReplicatedStorage.Shared.Modules.Game.Morphs)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)

local AnimationController = require(script.Parent.AnimationController)

local Components = {}

--[[
	Helper function to create a text label with stroke and optional drop shadow
]]
local function createTextLabel(props: {
	Name: string?,
	Text: string?,
	TextColor3: Color3?,
	TextSize: number?,
	Font: Enum.Font?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	BackgroundTransparency: number?,
	TextXAlignment: Enum.TextXAlignment?,
	TextScaled: boolean?,
	RichText: boolean?,
	Stroke: number?,
	StrokeColor: Color3?,
	DropShadow: number?,
	DropShadowColor: Color3?,
	Parent: Instance?,
}): TextLabel
	-- If drop shadow is specified, create a container with shadow effect
	if props.DropShadow then
		-- Create shadow (background) label
		local shadowLabel = Instance.new("TextLabel")
		shadowLabel.Name = props.Name or "TextLabel"
		shadowLabel.Text = props.Text or ""
		shadowLabel.TextColor3 = props.DropShadowColor or Color3.fromRGB(0, 0, 0)
		shadowLabel.Size = props.Size or UDim2.fromScale(1, 1)
		shadowLabel.Position = props.Position or UDim2.fromScale(0.5, 0.5)
		shadowLabel.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
		shadowLabel.BackgroundTransparency = 1
		shadowLabel.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
		shadowLabel.Font = props.Font or Enum.Font.FredokaOne
		shadowLabel.RichText = props.RichText or false
		shadowLabel.ZIndex = 1

		-- Handle text scaling for shadow
		if props.TextSize then
			shadowLabel.TextScaled = false
			shadowLabel.TextSize = props.TextSize
		elseif props.TextScaled == false then
			shadowLabel.TextScaled = false
			shadowLabel.TextSize = 14
		else
			shadowLabel.TextScaled = true
		end

		-- Create the main text label (on top of shadow)
		local mainLabel = Instance.new("TextLabel")
		mainLabel.Name = "MainText"
		mainLabel.Text = props.Text or ""
		mainLabel.TextColor3 = props.TextColor3 or Color3.fromRGB(255, 255, 255)
		mainLabel.Size = UDim2.fromScale(1, 1)
		mainLabel.Position = UDim2.fromScale(0.5, 0.5 - (props.DropShadow / 10))
		mainLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		mainLabel.BackgroundTransparency = 1
		mainLabel.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
		mainLabel.Font = props.Font or Enum.Font.FredokaOne
		mainLabel.RichText = props.RichText or false

		-- Handle text scaling for main label
		if props.TextSize then
			mainLabel.TextScaled = false
			mainLabel.TextSize = props.TextSize
		elseif props.TextScaled == false then
			mainLabel.TextScaled = false
			mainLabel.TextSize = 14
		else
			mainLabel.TextScaled = true
		end

		-- Add stroke to the main label if specified
		if props.Stroke then
			local stroke = Instance.new("UIStroke")
			stroke.Name = "UIStroke"
			stroke.Thickness = props.Stroke
			stroke.Color = props.StrokeColor or Color3.fromRGB(0, 0, 0)
			stroke.Parent = mainLabel
		end

		mainLabel.Parent = shadowLabel

		if props.Parent then
			shadowLabel.Parent = props.Parent
		end

		return shadowLabel
	end

	-- Standard label without drop shadow
	local label = Instance.new("TextLabel")
	label.Name = props.Name or "TextLabel"
	label.Text = props.Text or ""
	label.TextColor3 = props.TextColor3 or Color3.fromRGB(255, 255, 255)
	label.Size = props.Size or UDim2.fromScale(1, 1)
	label.Position = props.Position or UDim2.fromScale(0.5, 0.5)
	label.AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = props.BackgroundTransparency or 1
	label.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center
	label.Font = props.Font or Enum.Font.FredokaOne
	label.RichText = props.RichText or false
	
	-- Handle text scaling - if TextSize is explicitly provided, use fixed size
	if props.TextSize then
		label.TextScaled = false
		label.TextSize = props.TextSize
	elseif props.TextScaled == false then
		label.TextScaled = false
		label.TextSize = 14
	else
		label.TextScaled = true
	end

	-- Add stroke if specified
	if props.Stroke then
		local stroke = Instance.new("UIStroke")
		stroke.Name = "UIStroke"
		stroke.Thickness = props.Stroke
		stroke.Color = props.StrokeColor or Color3.fromRGB(0, 0, 0)
		stroke.Parent = label
	end

	if props.Parent then
		label.Parent = props.Parent
	end

	return label
end

--[[
	Create HUD Button (like MorphButton or ShopButton)
]]
local function createHudButton(props: {
	Name: string,
	ButtonTitle: string,
	ButtonIcon: string,
	ImageId: string,
	TitleStroke: Color3,
	LayoutOrder: number?,
	OnActivated: (() -> ())?,
	Parent: Instance?,
}): ImageButton
	local button = Instance.new("ImageButton")
	button.Name = props.Name
	button.Size = UDim2.fromOffset(188, 155)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromScale(0.5, 0.5)
	button.BackgroundTransparency = 1
	button.Image = props.ImageId
	button.ScaleType = Enum.ScaleType.Fit
	button.LayoutOrder = props.LayoutOrder or 0

	-- Button Icon
	local buttonIcon = Instance.new("ImageLabel")
	buttonIcon.Name = "ButtonIcon"
	buttonIcon.Size = UDim2.fromScale(0.7, 0.7)
	buttonIcon.Position = UDim2.fromScale(0.5, 0.25)
	buttonIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	buttonIcon.Image = props.ButtonIcon
	buttonIcon.ScaleType = Enum.ScaleType.Fit
	buttonIcon.BackgroundTransparency = 1
	buttonIcon.Parent = button

	-- Button Text
	local textLabel = createTextLabel({
		Name = "TextLabel",
		Text = props.ButtonTitle,
		Size = UDim2.fromScale(1, 0.4),
		Position = UDim2.fromScale(0.45, 0.7),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 30,
		Stroke = 4,
		StrokeColor = props.TitleStroke,
		RichText = true,
		Parent = button,
	})

	-- Setup animations
	AnimationController.setupButtonAnimation(button, {
		hoverScale = 1.1,
		clickScale = 0.9,
		iconElement = buttonIcon,
		iconDefaultPosition = UDim2.fromScale(0.5, 0.25),
		iconHoverPosition = UDim2.fromScale(0.5, 0.18),
	})

	-- Connect activation
	if props.OnActivated then
		button.Activated:Connect(props.OnActivated)
	end

	if props.Parent then
		button.Parent = props.Parent
	end

	return button
end

--[[
	Create LeftBar - The HUD bar on the left side with buttons
]]
function Components.createLeftBar(parent: Instance): Frame
	local Menu = require(ReplicatedStorage.UI.core.components.Menu)
	
	local leftBar = Instance.new("Frame")
	leftBar.Name = "LeftBar"
	leftBar.AnchorPoint = Vector2.new(0.5, 0.5)
	leftBar.Size = UDim2.fromOffset(150, 400)
	leftBar.Position = UDim2.fromScale(0.07, 0.5)
	leftBar.BackgroundTransparency = 1

	-- UIListLayout for button arrangement
	local layout = Instance.new("UIListLayout")
	layout.Name = "UIListLayout"
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 20)
	layout.Parent = leftBar

	-- Morph Button
	local morphButton = createHudButton({
		Name = "MorphButton",
		ButtonIcon = ImageIds.box,
		ButtonTitle = "Find the \nmorphs!",
		ImageId = ImageIds.hudbuttons.pink,
		TitleStroke = Color3.fromRGB(105, 0, 100),
		LayoutOrder = 1,
		OnActivated = function()
			Menu.set("Morph")
		end,
		Parent = leftBar,
	})

	-- Shop Button
	local shopButton = createHudButton({
		Name = "ShopButton",
		ButtonIcon = ImageIds.shop,
		ButtonTitle = "Shop",
		ImageId = ImageIds.hudbuttons.yellow,
		TitleStroke = Color3.fromRGB(70, 40, 0),
		LayoutOrder = 2,
		OnActivated = function()
			Menu.set("Shop")
		end,
		Parent = leftBar,
	})

	-- Setup auto-scaling
	AnimationController.setupAutoScaling(leftBar, 1, 0)

	leftBar.Parent = parent
	return leftBar
end

--[[
	Create Basic Button (used in menus)
]]
local function createBasicButton(props: {
	Name: string?,
	Size: UDim2?,
	Position: UDim2?,
	BackgroundColor3: Color3?,
	BackgroundTransparency: number?,
	ImageId: string?,
	LayoutOrder: number?,
	OnActivated: (() -> ())?,
	Parent: Instance?,
}): ImageButton
	local button = Instance.new("ImageButton")
	button.Name = props.Name or "Button"
	button.Size = props.Size or UDim2.fromOffset(100, 40)
	button.Position = props.Position or UDim2.fromScale(0.5, 0.5)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(255, 255, 255)
	button.BackgroundTransparency = props.BackgroundTransparency or 1
	button.Image = props.ImageId or ""
	button.ScaleType = Enum.ScaleType.Fit
	button.LayoutOrder = props.LayoutOrder or 0

	AnimationController.setupButtonAnimation(button, {
		hoverScale = 1.1,
		clickScale = 0.9,
	})

	if props.OnActivated then
		button.Activated:Connect(props.OnActivated)
	end

	if props.Parent then
		button.Parent = props.Parent
	end

	return button
end

--[[
	Create Menu Panel Frame with slide animation
]]
local function createMenuPanel(props: {
	Name: string,
	Id: string,
	Parent: Instance?,
}): Frame
	-- Outer frame (for auto-scaling)
	local outerFrame = Instance.new("Frame")
	outerFrame.Name = props.Name
	outerFrame.Size = UDim2.fromOffset(1044, 714)
	outerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	outerFrame.Position = UDim2.fromScale(0.5, 1.5) -- Start hidden below screen
	outerFrame.BackgroundTransparency = 1
	outerFrame.ZIndex = 2

	-- Content frame (the visible menu background)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.fromOffset(850, 600)
	content.Position = UDim2.fromScale(0.5, 0.5)
	content.AnchorPoint = Vector2.new(0.5, 0.5)
	content.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	content.Parent = outerFrame

	-- UICorner for rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 30)
	corner.Parent = content

	-- UIGradient for visual effect
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	gradient.Rotation = 270
	gradient.Parent = content

	-- Register menu animation
	AnimationController.registerMenu(props.Id, outerFrame, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 1.5))
	AnimationController.setupAutoScaling(outerFrame, 1, 0)

	if props.Parent then
		outerFrame.Parent = props.Parent
	end

	return outerFrame
end

--[[
	Create Morph Menu
]]
function Components.createMorphMenu(parent: Instance): Frame
	local menuPanel = createMenuPanel({
		Name = "Morph",
		Id = "Morph",
		Parent = parent,
	})

	local content = menuPanel:FindFirstChild("Content") :: Frame
	if content then
		-- Add morph inventory content here
		-- This would include the search bar, filter, morph list, etc.
		-- For now, creating a placeholder that shows the menu works
		
		local label = createTextLabel({
			Name = "Title",
			Text = "Morph Inventory",
			Size = UDim2.fromScale(0.8, 0.1),
			Position = UDim2.fromScale(0.5, 0.08),
			TextSize = 40,
			Stroke = 3,
			Parent = content,
		})
	end

	return menuPanel
end

--[[
	Create Shop Menu
]]
function Components.createShopMenu(parent: Instance): Frame
	local menuPanel = createMenuPanel({
		Name = "Shop",
		Id = "Shop",
		Parent = parent,
	})

	local content = menuPanel:FindFirstChild("Content") :: Frame
	if content then
		local label = createTextLabel({
			Name = "Title",
			Text = "Shop",
			Size = UDim2.fromScale(0.8, 0.1),
			Position = UDim2.fromScale(0.5, 0.08),
			TextSize = 40,
			Stroke = 3,
			Parent = content,
		})
	end

	return menuPanel
end

--[[
	Create Purchase Screen (loading overlay)
]]
function Components.createPurchaseScreen(parent: Instance): CanvasGroup
	local canvasGroup = Instance.new("CanvasGroup")
	canvasGroup.Name = "PurchaseScreen"
	canvasGroup.GroupTransparency = 1
	canvasGroup.BackgroundTransparency = 0.5
	canvasGroup.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	canvasGroup.Size = UDim2.fromScale(1, 1)
	canvasGroup.AnchorPoint = Vector2.new(0.5, 0.5)
	canvasGroup.Position = UDim2.fromScale(0.5, 0.5)
	canvasGroup.ZIndex = 30
	canvasGroup.Visible = false

	-- Loading spinner
	local loading = Instance.new("ImageLabel")
	loading.Name = "Loading"
	loading.Size = UDim2.fromScale(0.2, 0.2)
	loading.Position = UDim2.fromScale(0.5, 0.5)
	loading.AnchorPoint = Vector2.new(0.5, 0.5)
	loading.Image = ImageIds.load
	loading.ScaleType = Enum.ScaleType.Fit
	loading.BackgroundTransparency = 1
	loading.Parent = canvasGroup

	-- Setup fade animation with rotation
	AnimationController.setupFadeElement(canvasGroup, loading)

	canvasGroup.Parent = parent
	return canvasGroup
end

--[[
	Create New Morph Notification
]]
function Components.createNewMorphNotification(parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Name = "NewMorph"
	frame.Size = UDim2.fromOffset(300, 500)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1
	frame.Visible = false

	-- "New Morph!" text
	local titleLabel = createTextLabel({
		Name = "Title",
		Text = "New Morph!",
		Size = UDim2.fromScale(1, 0.2),
		Position = UDim2.fromScale(0.5, 0.1),
		Stroke = 3,
		DropShadow = 1.2,
		Parent = frame,
	})

	-- "Click to continue!" text
	local continueLabel = createTextLabel({
		Name = "Continue",
		Text = "Click to continue!",
		Size = UDim2.fromScale(1, 0.2),
		Position = UDim2.fromScale(0.5, 1),
		TextSize = 30,
		Stroke = 3,
		DropShadow = 0.4,
		Parent = frame,
	})

	-- Setup auto-scaling
	AnimationController.setupAutoScaling(frame, 1, 0)

	frame.Parent = parent
	return frame
end

return Components
