type GamepassData = {
	productId: number,
}

local gamepasses: {
	[string]: GamepassData,
} = {
	["MorphPack1"] = {
		productId = 1597265399,
		oneTime = true,
	},
}

local function getById(targetedId: number)
	for name, prop in gamepasses do
		if prop.productId == targetedId then
			return name, prop
		end
	end

	return nil, nil
end

local function getByName(name: string): GamepassData
	return gamepasses[name]
end

return {
	all = gamepasses,
	getByName = getByName,
	getById = getById,
}
