export type CoinToolData = {
	cost: number,
	displayName: string,
}

-- Tool names must match children of ServerStorage.Assets.Tools
-- and ProductName TextLabels in the CoinShop UI
local CoinTools: { [string]: CoinToolData } = {
	["Teddy"] = {
		cost = 10,
		displayName = "Teddy Bear",
	},
	["BunchOfBalloons"] = {
		cost = 10,
		displayName = "Bunch of Balloons",
	},
	["MoneyBag"] = {
		cost = 10,
		displayName = "Money Bag",
	},
	["Snowball"] = {
		cost = 10,
		displayName = "Snowball",
	},
	["PompousTheCloud"] = {
		cost = 10,
		displayName = "Pompous, The Cloud",
	},
	["Dynamite"] = {
		cost = 10,
		displayName = "Dynamite",
	},
	["Monkey"] = {
		cost = 10,
		displayName = "Monkey",
	},
}

return CoinTools :: { [string]: CoinToolData }
