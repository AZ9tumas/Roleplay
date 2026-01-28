local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataService = require(ReplicatedStorage.Packages.DataService) :: any
local Sift = require(ReplicatedStorage.Packages.Sift)

local IS_SERVER = RunService:IsServer()
if IS_SERVER then
	DataService = DataService.server
else
	DataService = DataService.client
end

local FUNCTION_LIST = {
	["Gamepass"] = MarketplaceService.PromptGamePassPurchase,
	["DevProduct"] = MarketplaceService.PromptProductPurchase,
}

export type GamepassData = {
	productId: number,
	type: "DevProduct" | "Gamepass", -- Is the given id a dev product or gamepass
	oneTime: boolean?, -- Can only be purchased one time, only for dev product
	limitedAmount: number?, -- Can only be purchased certain time globally, only for dev product
	limitedTime: number?, -- MUST BE IN SECONDS! Can only be purchased within a certain time frame, only for dev product
}

local ids: {
	[string]: GamepassData,
} = {
	["MorphPack1"] = {
		productId = 3523117726,
		type = "DevProduct",
		oneTime = true,
	},
	["MorphPack2"] = {
		productId = 000010000,
		type = "DevProduct",
		oneTime = true,
	},
	["LimitedMorphTest"] = {
		productId = 3466413824,
		type = "DevProduct",
		oneTime = true,
		limitedAmount = 22,
	},
	["LimitedTimeMorphTest"] = {
		productId = 3467367924,
		type = "DevProduct",
		oneTime = true,
		limitedTime = 120,
	},

	["UnlockMorph"] = {
		productId = 1597265399,
		type = "DevProduct",
		oneTime = false,
	},

	["BuyGoldPack"] = {
		productId = 000010000,
		type = "DevProduct",
		oneTime = false,
	},
	
	["BuySuperCoil"] = {
		productId = 000010000,
		type = "Gamepass",
	},
	["BuySpeedCoil"] = {
		productId = 1686493633,
		type = "Gamepass",
	},
	["BuyRainbowCoil"] = {
		productId = 000010000,
		type = "Gamepass",
	},
	["BuyGravityCoil"] = {
		productId = 000010000,
		type = "Gamepass",
	},
}

local function _getDevProducts(player)
	if IS_SERVER then
		return DataService:get(player, "devProducts")
	else
		return DataService:get({ "devProducts" })
	end
end

local function promptPurchase(player: Player, productName: string): ()
	local data = ids[productName]
	if not data then
		return
	end

	if data.type == "DevProduct" and data.oneTime then
		local devProducts = _getDevProducts(player)
		if devProducts and devProducts[data.productId] then
			return
		end
	end

	FUNCTION_LIST[data.type](MarketplaceService, player, data.productId)
end

local function getById(targetedId: number): (GamepassData & { key: string }) | nil
	for name, prop in ids do
		if prop.productId == targetedId then
			return Sift.Dictionary.merge(prop, {
				key = name,
			})
		end
	end
	return nil
end

local function getByName(name: string): GamepassData
	return ids[name]
end

local function getProductId(productName: string): number
	local data = ids[productName]
	if not data then
		return 0
	end

	return data.productId
end

return {
	ids = ids,
	getByName = getByName,
	getById = getById,
	getProductId = getProductId,
	prompt = promptPurchase,
}
