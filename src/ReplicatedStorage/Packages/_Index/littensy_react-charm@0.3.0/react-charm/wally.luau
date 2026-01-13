return {
	dependencies = {
		React = "jsdotlua/react@^17",
		charm = "littensy/charm@^0.10",
	},
	package = {
		exclude = {"package.json", "node_modules"},
		include = {"LICENSE.md"},
		name = "littensy/react-charm",
		realm = "shared",
		registry = "https://github.com/UpliftGames/wally-index",
		version = "0.3.0",
	},
}