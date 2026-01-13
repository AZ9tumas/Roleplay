local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TouchInputService = game:GetService("TouchInputService")
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)

local e = React.createElement

export type ButtonProps = {
	Size: UDim2,
	Position: UDim2?,
	Rotation: number?,
	AnchorPoint: Vector2?,
	BackgroundTransparency: number?,
	BackgroundColor3: Color3,
	ZIndex: number?,
	ImageId: string?,

	SpringDuration: number?,
	SpringDamping: number?,

	OnActivated: () -> (),
	ClickSound: Sound?,
	Disabled: boolean?,

	children: React.ReactNode?,
}

export type SpringProps = {
	SetHold: () -> (),
	SetHover: () -> (),
	Scale: React.Binding<UDim2>,
}

return React.forwardRef(function(props: ButtonProps & SpringProps, ref: React.Ref<any>)
	local setHold, setHover = props.SetHold, props.SetHover
	local children = props.children or {}

	local safeChildren = Sift.Dictionary.join(children, {
		UIScale = e("UIScale", {
			Scale = props.Scale,
		}),
	})

	local safeProperty = {
		Size = props.Size,
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		BackgroundTransparency = props.BackgroundTransparency or 1,
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(255, 255, 255),
		Image = props.ImageId or "",
		ScaleType = "Fit",

		ref = ref,
	}

	if not props.Disabled then
		safeProperty = Sift.Dictionary.merge(safeProperty, {
			[React.Event.MouseButton1Down] = function()
				setHold(true)
			end,

			[React.Event.MouseButton1Up] = function()
				setHold(false)
			end,

			[React.Event.MouseEnter] = function()
				setHover(true)
			end,

			[React.Event.MouseLeave] = function()
				setHover(false)
				setHold(false)
			end,

			[React.Event.Activated] = function()
				if props.OnActivated then
					props.OnActivated()
				end
			end,
		})
	end

	return e("ImageButton", safeProperty, safeChildren)
end)
