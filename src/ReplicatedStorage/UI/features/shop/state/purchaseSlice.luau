local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Charm = require(ReplicatedStorage.Packages.Charm)

type Atom<T> = Charm.Atom<T>

local purchasing: Atom<boolean> = Charm.atom(false)

return {
	states = {
		purchasing = purchasing,
	},

	actions = {
		setPurchase = function(value: boolean)
			purchasing(function(_current)
				return value
			end)
		end,
	},
}
