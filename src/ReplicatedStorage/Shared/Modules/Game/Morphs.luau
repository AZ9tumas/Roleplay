export type Animations = {
	walk: string,
	idle: string,
	jumpscare: string,
	run: string?,
}

export type MorphData = {
	animations: Animations,
	displayName: string,
	imageId: string?,
}

local Morphs: { [string]: MorphData } = {
	["HungryWormDaddy"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Daddy",
		imageId = "rbxassetid://77036451736886",
	},
	["HungryWormDoey"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		imageId = "rbxassetid://106266099018473",
		displayName = "Hungry Worm Doey",
	},
	["HungryWormHamoodHabibi"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		imageId = "rbxassetid://119803265629236",
		displayName = "Hungry Worm Hamood Habibi",
	},
	["HungryWormCatNap"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		imageId = "rbxassetid://106220005831732",
		displayName = "Hungry Worm Cat Nap",
	},
	["HungryWormDogDay"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Dog Day",
		imageId = "rbxassetid://112293379535070",
	},
	["HungryWormHuggy"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Huggy",
		imageId = "rbxassetid://97476082082284",
	},
	["HungryWormSmiley"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		imageId = "rbxassetid://101215419773098",
		displayName = "Hungry Worm Smiley",
	},
	["HungryWormMommy"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		imageId = "rbxassetid://85400225818479",
		displayName = "Hungry Worm Mommy",
	},
	["HungryWormPhase2"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Phase 2",
		imageId = "rbxassetid://80105423819154",
	},
	["HungryWormPhase3"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Phase 3",
		imageId = "rbxassetid://102540871035901",
	},
	["HungryWorm"] = {
		animations = {
			idle = "rbxassetid://99840449575812",
			jumpscare = "rbxassetid://125753152004331",
			run = "rbxassetid://108789971402451",
		},
		displayName = "Hungry Worm",
		imageId = "rbxassetid://134696926768668",
	},
	["HungryWormCat"] = {
		animations = {
			idle = "rbxassetid://108508003683938",
			jumpscare = "rbxassetid://91715548494031",
			run = "rbxassetid://71151334318559",
		},
		displayName = "Hungry Worm Cat",
		imageId = "rbxassetid://133395864974066",
	},
	["HungryWormCatV2"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://138013083967655",
			run = "rbxassetid://78619735950315",
		},
		displayName = "Hungry Worm Cat V2",
		imageId = "rbxassetid://107372693379800",
	},
	["HungryWormGolden"] = {
		animations = {
			idle = "rbxassetid://99840449575812",
			jumpscare = "rbxassetid://125753152004331",
			run = "rbxassetid://108789971402451",
		},
		imageId = "rbxassetid://102240456513870",
		displayName = "Hungry Worm Golden",
	},
	["HungryWormPhase4"] = {
		animations = {
			idle = "rbxassetid://99840449575812",
			jumpscare = "rbxassetid://125753152004331",
			run = "rbxassetid://108789971402451",
		},
		imageId = "rbxassetid://132061398616609",
		displayName = "Hungry Worm Phase 4",
	},
	["HungryWormPibble"] = {
		animations = {
			idle = "rbxassetid://108508003683938",
			jumpscare = "rbxassetid://91715548494031",
			run = "rbxassetid://71151334318559",
		},
		imageId = "rbxassetid://93874762452727",
		displayName = "Hungry Worm Pibble",
	},
	["HungryWormSnake"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://75669641634534",
			run = "rbxassetid://78619735950315",
		},
		displayName = "Hungry Worm Snake",
		imageId = "rbxassetid://107761319198794",
	},
	["HungryWormSnakeDaddy"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://75669641634534",
			run = "rbxassetid://78619735950315",
		},
		imageId = "rbxassetid://95554561696047",
		displayName = "Hungry Worm Snake Daddy",
	},
	["HungryWormSnakeMommy"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://75669641634534",
			run = "rbxassetid://78619735950315",
		},
		displayName = "Hungry Worm Snake Mommy",
		imageId = "rbxassetid://116815900361582",
	},
	["HungryWormSnakePhase2"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://75669641634534",
			run = "rbxassetid://78619735950315",
		},
		displayName = "Hungry Worm Snake Phase 2",
		imageId = "rbxassetid://76325755452889",
	},
	["HungryWormSnakePhase3"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://75669641634534",
			run = "rbxassetid://78619735950315",
		},
		displayName = "Hungry Worm Snake Phase 3",
		imageId = "rbxassetid://117728428854642",
	},
	["HungryWormSonic"] = {
		animations = {
			idle = "rbxassetid://104158264572710",
			jumpscare = "rbxassetid://129741562150981",
			run = "rbxassetid://123090582958115",
		},
		displayName = "Hungry Worm Sonic",
		imageId = "rbxassetid://88694940253856",
	},
	["HungryWormTomato"] = {
		animations = {
			idle = "rbxassetid://99840449575812",
			jumpscare = "rbxassetid://76779218633223",
			run = "rbxassetid://108789971402451",
		},
		displayName = "Hungry Worm Tomato",
		imageId = "rbxassetid://127879105932214",
	},
}

return Morphs :: { [string]: MorphData }
