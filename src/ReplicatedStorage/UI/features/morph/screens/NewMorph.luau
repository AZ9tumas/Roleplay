local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactCharm = require(ReplicatedStorage.Packages.ReactCharm)
local TextLabel = require(ReplicatedStorage.UI.core.components.TextLabel)
local AutoScaledFrame = require(ReplicatedStorage.UI.core.primitives.AutoScaledFrame)
local morphSlice = require(ReplicatedStorage.UI.features.morph.state.morphSlice)
local playMorphSequence = require(ReplicatedStorage.UI.sequences.playMorphSequence)

local e = React.createElement

local function newMorph(props)
	-- Play sequence for the first morph

	React.useEffect(function()
		if not props.morphName then
			return
		end

		if not props.playSequence then
			return
		end

		local cleanup = props.playSequence(props.morphName)
		return cleanup
	end, { props.morphName })

	return e("Frame", {
		Size = props.morphName and UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),

		BackgroundTransparency = 1,
	}, {
		TextLabel = e(TextLabel, {
			Size = UDim2.fromScale(1, 0.2),
			Position = UDim2.fromScale(0.5, 0.1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = "New Morph!",
			Stroke = 3,
			DropShadow = 1.2,
		}),

		TextLabel2 = e(TextLabel, {
			Size = UDim2.fromScale(1, 0.2),
			Position = UDim2.fromScale(0.5, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = "Click to continue!",
			Stroke = 3,
			TextSize = 30,
			DropShadow = 0.4,
		}),
	})
end

return function()
	local newMorphs = ReactCharm.useAtom(morphSlice.states.newMorphs)

	local children = {}
	for index, morph in newMorphs do
		if index == 1 then
			children[morph] = e(newMorph, {
				morphName = morph,
				playSequence = playMorphSequence,
			})
		end
	end

	return e(AutoScaledFrame, {
		Size = UDim2.fromOffset(300, 500),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, children)
end
