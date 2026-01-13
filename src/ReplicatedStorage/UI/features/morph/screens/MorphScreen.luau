local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactCharm = require(ReplicatedStorage.Packages.ReactCharm)
local Menu = require(ReplicatedStorage.UI.core.components.Menu)
local MorphHint = require(ReplicatedStorage.UI.features.morph.components.MorphHint)
local MorphInventory = require(ReplicatedStorage.UI.features.morph.components.MorphInventory)
local morphSlice = require(ReplicatedStorage.UI.features.morph.state.morphSlice)

local e = React.createElement

return function()
	local unlockedMorphs = ReactCharm.useAtom(morphSlice.states.unlockedMorphs)
	local equippedMorph = ReactCharm.useAtom(morphSlice.states.equippedMorph)

	return e(Menu.component, {
		id = "Morph",
		actionButtons = {
			{
				name = "Morphs",
				imageId = "rbxassetid://13749780813",
			},
			{
				name = "Hints",
				imageId = "rbxassetid://13749780813",
			},
		},
		pages = {
			defaultPage = "Morphs",
			Morphs = e(MorphInventory, {
				unlockedMorphs = unlockedMorphs,
				equippedMorph = equippedMorph,
			}),
			Hint = e(MorphHint, {}),
		},
	})
end
