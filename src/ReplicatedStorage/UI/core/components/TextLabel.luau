local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)

export type TextLabelProps = {
	Text: string?,
	TextColor: Color3?,
	Font: Font?,
	Size: UDim2,
	Position: UDim2?,
	Rotation: number?,
	AnchorPoint: Vector2?,
	BackgroundTransparency: number?,
	ZIndex: number?,
	TextXAlignment: Enum.TextXAlignment,
	AutomaticSize: Enum.AutomaticSize,
	TextSize: number,
	RichText: boolean,

	Stroke: number?,
	StrokeColor: Color3?,
	StrokeTransparency: number?,

	DropShadow: number?,
	DropShadowColor: Color3?,
	DropShadowTransparency: number?,

	children: React.ReactNode?,
}

local e = React.createElement

return React.forwardRef(function(props: TextLabelProps, ref: React.Ref<any>)
	local children = props.children or {}

	-- Add stroke if specified
	if props.Stroke then
		children = Sift.Dictionary.join(children, {
			UIStroke = e("UIStroke", {
				Thickness = props.Stroke,
				Transparency = props.StrokeTransparency or 0,
				Color = props.StrokeColor or Color3.new(0, 0, 0),
			}),
		})
	end

	-- Add drop shadow if specified
	if props.DropShadow then
		children = Sift.Dictionary.join(children, {
			TextLabel = e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0.5, 0.5 - (props.DropShadow / 10)),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Rotation = props.Rotation,
				BackgroundTransparency = props.BackgroundTransparency or 1,
				ZIndex = props.ZIndex,
				TextScaled = if props.TextSize then false else true,
				Text = props.Text or "",
				Font = props.Font or Enum.Font.FredokaOne,
				TextColor3 = props.TextColor or Color3.fromRGB(255, 255, 255),
				TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
				TextSize = props.TextSize or 1,
				AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.None,
				RichText = props.RichText,
			}, children),
		})
		return e("TextLabel", {
			Size = props.Size,
			Position = props.Position or UDim2.fromScale(0.5, 0.5),
			AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
			Rotation = props.Rotation,
			BackgroundTransparency = 1,
			TextColor3 = props.DropShadowColor or Color3.new(0, 0, 0),
			ZIndex = 1,
			Text = props.Text or "",
			RichText = props.RichText,

			Font = props.Font or Enum.Font.FredokaOne,
			TextScaled = if props.TextSize then false else true,
			TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
			TextSize = props.TextSize or 1,
			AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.None,

			ref = ref,
		}, children)
	end

	return e("TextLabel", {
		Size = props.Size,
		Position = props.Position or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = props.AnchorPoint or Vector2.new(0.5, 0.5),
		Rotation = props.Rotation,
		BackgroundTransparency = props.BackgroundTransparency or 1,
		ZIndex = props.ZIndex,
		TextScaled = if props.TextSize then false else true,
		Text = props.Text or "",
		Font = props.Font or Enum.Font.FredokaOne,
		TextColor3 = props.TextColor or Color3.fromRGB(255, 255, 255),
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
		TextSize = props.TextSize or 1,
		AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.None,
		RichText = props.RichText,
		ref = ref,
	}, children)
end)
