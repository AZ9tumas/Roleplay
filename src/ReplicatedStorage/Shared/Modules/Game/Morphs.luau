export type Animations = {
	walk: string,
	idle: string,
	jumpscare: string,
	run: string?,
}

export type MorphData = {
	animations: Animations,
	displayName: string,
}

local Morphs: { [string]: MorphData } = {
	["AbbySaja"] = {
		animations = {
			walk = "rbxassetid://118681492030786",
			run = "rbxassetid://118681492030786",
			idle = "rbxassetid://126415726327787",
			jumpscare = "rbxassetid://126415726327787",
		},
		displayName = "Abby Saja",
	},
	["AbbySaja2"] = {
		animations = {
			walk = "rbxassetid://118681492030786",
			run = "rbxassetid://118681492030786",
			idle = "rbxassetid://126415726327787",
			jumpscare = "rbxassetid://126415726327787",
		},
		displayName = "Abby Saja2",
	},
	["LimitedMorphTest"] = {
		animations = {
			walk = "rbxassetid://118681492030786",
			run = "rbxassetid://118681492030786",
			idle = "rbxassetid://126415726327787",
			jumpscare = "rbxassetid://126415726327787",
		},
		displayName = "Limited Morph Test",
	},
	["LimitedTimeMorphTest"] = {
		animations = {
			walk = "rbxassetid://118681492030786",
			run = "rbxassetid://118681492030786",
			idle = "rbxassetid://126415726327787",
			jumpscare = "rbxassetid://126415726327787",
		},
		displayName = "Limited Time Morph Test",
	},
	["Trapper"] = {
		animations = {
			walk = "rbxassetid://118681492030786",
			run = "rbxassetid://118681492030786",
			idle = "rbxassetid://126415726327787",
			jumpscare = "rbxassetid://126415726327787",
		},
		displayName = "Trapper",
	},
}

return Morphs :: { [string]: MorphData }
