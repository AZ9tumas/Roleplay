local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Packages.Charm)
local Sift = require(ReplicatedStorage.Packages.Sift)

type Atom<T> = Charm.Atom<T>

local atom = Charm.atom

local unlockedMorphs = atom({})
local equippedMorph = atom(nil)
local soldMorphs = atom({})
local newMorphs = atom({})

return {
	states = {
		equippedMorph = equippedMorph,
		unlockedMorphs = unlockedMorphs,
		soldMorphs = soldMorphs,
		newMorphs = newMorphs,
	},
	actions = {
		addUnlockedMorph = function(morphs: {})
			unlockedMorphs(function(_current)
				return morphs
			end)
		end,

		setEquippedMorph = function(morph: string)
			equippedMorph(function(_current: {})
				return morph
			end)
		end,

		setSoldMorph = function(morph)
			soldMorphs(table.clone(morph))
		end,

		setNewMorph = function(morph: string?)
			newMorphs(function(current: {})
				local currentMorphs = table.clone(current)
				if not morph then
					currentMorphs = Sift.Array.removeIndex(currentMorphs, 1)
				else
					currentMorphs = Sift.Array.insert(currentMorphs, 1, morph)
				end

				return currentMorphs
			end)
		end,
	},
}
