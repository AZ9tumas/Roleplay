export type CoinMorphData = {
	cost: number,
	displayName: string,
	animations: {
		walk: string,
		idle: string,
		jumpscare: string,
		run: string?,
	},
}

local CoinMorphs: { [string]: CoinMorphData } = {
	["CoinMorph1"] = {
		cost = 10,
		displayName = "Coin Morph 1",
		animations = {
			walk = "rbxassetid://118681492030786",
			run = "rbxassetid://118681492030786",
			idle = "rbxassetid://126415726327787",
			jumpscare = "rbxassetid://126415726327787",
		},
	},
	["CoinMorph2"] = {
		cost = 10,
		displayName = "Coin Morph 2",
		animations = {
			walk = "rbxassetid://118681492030786",
			run = "rbxassetid://118681492030786",
			idle = "rbxassetid://126415726327787",
			jumpscare = "rbxassetid://126415726327787",
		},
	},
}

return CoinMorphs :: { [string]: CoinMorphData }
