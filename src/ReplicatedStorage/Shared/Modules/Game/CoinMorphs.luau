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

-- Using existing morph templates that work with Robux purchases as base templates
local CoinMorphs: { [string]: CoinMorphData } = {
	["LimitedMorphTest"] = {
		cost = 10,
		displayName = "Limited Morph Test",
		animations = {
			walk = "rbxassetid://118681492030786",
			run = "rbxassetid://118681492030786",
			idle = "rbxassetid://126415726327787",
			jumpscare = "rbxassetid://126415726327787",
		},
	},
	["Trapper"] = {
		cost = 10,
		displayName = "Trapper",
		animations = {
			walk = "rbxassetid://118681492030786",
			run = "rbxassetid://118681492030786",
			idle = "rbxassetid://126415726327787",
			jumpscare = "rbxassetid://126415726327787",
		},
	},
}

return CoinMorphs :: { [string]: CoinMorphData }
