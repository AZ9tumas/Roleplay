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
	hint: string,
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
		hint = "Check next to a tree!",
	},
	["HungryWormDoey"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		imageId = "rbxassetid://106266099018473",
		displayName = "Hungry Worm Doey",
		hint = "Check next to a tree!",
	},
	["HungryWormHamoodHabibi"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		imageId = "rbxassetid://119803265629236",
		displayName = "Check next to a tree!",
		hint = "Sample hint",
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
		hint = "Check next to a tree!",
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
		hint = "It was right in front of you the whole time!",
	},
	["HungryWormPhase2"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Phase 2",
		imageId = "rbxassetid://80105423819154",
		hint = "I welcome you to the tunnel of mystery!",
	},
	["HungryWormPhase3"] = {
		animations = {
			
			run = "rbxassetid://107989195745842",
			idle = "rbxassetid://98781033980114",
			jumpscare = "rbxassetid://96137844701964",
		},
		displayName = "Hungry Worm Phase 3",
		imageId = "rbxassetid://102540871035901",
		hint = "Check next to a tree!",
	},
	["HungryWorm"] = {
		animations = {
			idle = "rbxassetid://99840449575812",
			jumpscare = "rbxassetid://125753152004331",
			run = "rbxassetid://108789971402451",
		},
		displayName = "Hungry Worm",
		imageId = "rbxassetid://134696926768668",
		hint = "I'm in the spawn, behind something you walk past every time you play!",
	},
	["HungryWormCat"] = {
		animations = {
			idle = "rbxassetid://108508003683938",
			jumpscare = "rbxassetid://91715548494031",
			run = "rbxassetid://71151334318559",
		},
		displayName = "Hungry Worm Cat",
		imageId = "rbxassetid://133395864974066",
		hint = "You really need to start looking around more carefully!",
	},
	["HungryWormCatV2"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://138013083967655",
			run = "rbxassetid://78619735950315",
		},
		displayName = "Hungry Worm Cat V2",
		imageId = "rbxassetid://107372693379800",
		hint = "Chillin' at the beach, catchin' some rays!",
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
		hint = "I'm in the way. You will run into me.",
	},
	["HungryWormPibble"] = {
		animations = {
			idle = "rbxassetid://108508003683938",
			jumpscare = "rbxassetid://91715548494031",
			run = "rbxassetid://71151334318559",
		},
		imageId = "rbxassetid://93874762452727",
		displayName = "Hungry Worm Pibble",
		hint = "I love trees! I'm probably chilling next to one!",
	},
	["HungryWormSnake"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://75669641634534",
			run = "rbxassetid://78619735950315",
		},
		displayName = "Hungry Worm Snake",
		imageId = "rbxassetid://107761319198794",
		hint = "I like to stay around corners! Check next to one!",
	},
	["HungryWormSnakeDaddy"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://75669641634534",
			run = "rbxassetid://78619735950315",
		},
		imageId = "rbxassetid://95554561696047",
		displayName = "Hungry Worm Snake Daddy",
		hint = "The waves are nice this time of year!",
	},
	["HungryWormSnakeMommy"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://75669641634534",
			run = "rbxassetid://78619735950315",
		},
		displayName = "Hungry Worm Snake Mommy",
		imageId = "rbxassetid://116815900361582",
		hint = "The avatar shop is a great place to find me!",
	},
	["HungryWormSnakePhase2"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://75669641634534",
			run = "rbxassetid://78619735950315",
		},
		displayName = "Hungry Worm Snake Phase 2",
		imageId = "rbxassetid://76325755452889",
		--hint = "Sample hint",
	},
	["HungryWormSnakePhase3"] = {
		animations = {
			idle = "rbxassetid://128584606912953",
			jumpscare = "rbxassetid://75669641634534",
			run = "rbxassetid://78619735950315",
		},
		displayName = "Hungry Worm Snake Phase 3",
		imageId = "rbxassetid://117728428854642",
		--hint = "Sample hint",
	},
	["HungryWormSonic"] = {
		animations = {
			idle = "rbxassetid://104158264572710",
			jumpscare = "rbxassetid://129741562150981",
			run = "rbxassetid://123090582958115",
		},
		displayName = "Hungry Worm Sonic",
		imageId = "rbxassetid://88694940253856",
		hint = "I was going to the beach, but I got lost on the way.",
	},
	["HungryWormTomato"] = {
		animations = {
			idle = "rbxassetid://99840449575812",
			jumpscare = "rbxassetid://76779218633223",
			run = "rbxassetid://108789971402451",
		},
		displayName = "Hungry Worm Tomato",
		imageId = "rbxassetid://127879105932214",
		hint = "These trees feel like a second home to me!",
	},
}

return Morphs :: { [string]: MorphData }
