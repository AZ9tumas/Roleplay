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
	["HungryWormDaddy"] = {
		animations = {
			walk = "rbxassetid://107989195745842",
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Daddy",
	},
	["HungryWormDoey"] = {
		animations = {
			walk = "rbxassetid://107989195745842",
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Doey",
	},
	["HungryWormHamoodHabibi"] = {
		animations = {
			walk = "rbxassetid://107989195745842",
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Hamood Habibi",
	},
	["HungryWormCatNap"] = {
		animations = {
			walk = "rbxassetid://107989195745842",
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Cat Nap",
	},
	["HungryWormDogDay"] = {
		animations = {
			walk = "rbxassetid://107989195745842",
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Dog Day",
	},
	["HungryWormHuggy"] = {
		animations = {
			walk = "rbxassetid://107989195745842",
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Huggy",
	},
	["HungryWormSmiley"] = {
		animations = {
			walk = "rbxassetid://107989195745842",
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Smiley",
	},
	["HungryWormMommy"] = {
		animations = {
			walk = "rbxassetid://107989195745842",
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Mommy",
	},
	["HungryWormPhase2"] = {
		animations = {
			walk = "rbxassetid://107989195745842",
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Phase 2",
	},
	["HungryWormPhase3"] = {
		animations = {
			walk = "rbxassetid://107989195745842",
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Phase 3",
	},
}

return Morphs :: { [string]: MorphData }
