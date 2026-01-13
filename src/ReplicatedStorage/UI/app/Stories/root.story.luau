local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local RootGui = require(ReplicatedStorage.UI.app.RootGui)
local Menu = require(ReplicatedStorage.UI.core.components.Menu)
local morphSlice = require(ReplicatedStorage.UI.features.morph.state.morphSlice)

local test_morphs = {
	["AbbySaja"] = {
		obtainTime = os.time(),
	},
}

return {
	react = React,

	reactRoblox = ReactRoblox,
	controls = {
		shown = true,
	},
	story = function(_props)
		morphSlice.actions.addUnlockedMorph(test_morphs)
		morphSlice.actions.setEquippedMorph("AbbySaja")

		morphSlice.actions.setSoldMorph({ data = {
			["LimitedTimeMorphTest"] = os.time(),
		} })
		Menu.set("Morph")
		return RootGui
	end,
}
