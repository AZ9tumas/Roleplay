local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BasicButton = require(script.Parent.BasicButton)
local Charm = require(ReplicatedStorage.Packages.Charm)
local React = require(ReplicatedStorage.Packages.React)
local ReactCharm = require(ReplicatedStorage.Packages.ReactCharm)
local Sift = require(ReplicatedStorage.Packages.Sift)
local SlideOutFrame = require(script.Parent.SlideOutFrame)
local TextLabel = require(script.Parent.TextLabel)

type Atom<T> = Charm.Atom<T>

local e, atom = React.createElement, Charm.atom
local openedMenu: Atom<string?> = atom(nil)

type CustomAction = {
	name: string,
	onActivated: () -> (),
}

export type MenuProps = {
	id: string,
	pages: { [string]: React.Node }?,
	actionButtons: { string | CustomAction }?,
	children: React.Node?,
}

local function setOpenedMenu(id: string?)
	openedMenu(if Charm.peek(openedMenu) == id then nil else id)
end

type ActionButtonProps = {
	name: string,
	order: number,
	action: () -> (),
}

local function actionButton(props: ActionButtonProps)
	return e(BasicButton, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.fromOffset(125, 125),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		LayoutOrder = props.order,
		OnActivated = function()
			props.action()
		end,
	}, {
		TextLabel = e(TextLabel, {
			Size = UDim2.fromScale(0.8, 0.3),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.8),
			Text = props.name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 24,
		}),
		ImageLabel = e("ImageLabel", {
			Size = UDim2.fromScale(0.6, 0.6),
			AnchorPoint = Vector2.new(0.5, 0.3),
			Position = UDim2.fromScale(0.5, 0.3),
			BackgroundTransparency = 1,
			Image = "rbxassetid://6023426915", -- Placeholder icon
		}),
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 30),
		}),
		UIGradient = e("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 0.2),
			}),
			Rotation = 270,
		}),
	})
end

type ActionButtonsPorps = {
	actionButtons: { string | CustomAction }?,
	pages: { [string]: React.Node }?,
	setPage: (string?) -> (),
}

local function actionButtons(props: ActionButtonsPorps)
	local buttons = React.useMemo(function()
		if not props.actionButtons then
			return {}
		end

		local newTable = {}
		for i, prop in ipairs(props.actionButtons) do
			newTable[prop.name] = e(actionButton, {
				name = prop.name,
				order = i,
				action = if prop.onActivated
					then prop.onActivated
					else function()
						props.setPage(prop.name)
					end,
			})
		end
		return newTable
	end, { props.pages, props.actionButtons })

	local childrens = Sift.Dictionary.join(buttons, {
		UIListLayout = e("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),
	})

	return e("Frame", {
		Size = UDim2.fromOffset(77, 500),
		Position = UDim2.fromScale(0.99, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
	}, childrens)
end

local component = React.forwardRef(function(props: MenuProps, ref: React.Ref<any>)
	local currentOpenMenu = ReactCharm.useAtom(openedMenu)

	-- Change: Initialize page as the first page's name if pages exist
	local page, setPage = React.useState(props.pages and props.pages.defaultPage or nil)

	local pageContent = React.useMemo(function()
		if not page or not props.pages then
			return
		end

		local content = props.pages[page]
		if not content then
			return
		end

		return content
	end, { page, props.pages })

	local children = props.children or {}
	if pageContent then
		children = {
			Page = pageContent,
		}
	end

	children = Sift.Dictionary.join(children, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 30),
		}),
		UIGradient = e("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 0.2),
			}),
			Rotation = 270,
		}),
	})

	return e(SlideOutFrame, {
		Size = UDim2.fromOffset(1044, 714),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 2,

		Shown = currentOpenMenu == props.id,
		From = UDim2.fromScale(0.5, 0.5),
		To = UDim2.fromScale(0.5, 1.5),

		ref = ref,
	}, {
		Content = e("Frame", {
			Size = UDim2.fromOffset(850, 600),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		}, children),

		Buttons = props.pages and e(actionButtons, {
			actionButtons = props.actionButtons,
			pages = props.pages,
			setPage = setPage,
		}),
	})
end)

return {
	set = setOpenedMenu,
	component = component,
	state = openedMenu,
}
