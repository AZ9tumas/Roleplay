local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local MorphServiceServer = require(ServerScriptService.Services.MorphService.MorphServiceServer)
local GameplayServiceServer = require(ServerScriptService.Services.GameplayService.GameplayServiceServer)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)
local PackRewards = require(ReplicatedStorage.Shared.Modules.Game.PackRewards)
local DataService = require(ReplicatedStorage.Packages.DataService).server

-- Mapping from gamepass purchase name to coil tool name
local COIL_GAMEPASS_MAP = {
	["BuySuperCoil"] = "SuperCoil",
	["BuySpeedCoil"] = "SpeedCoil",
	["BuyRainbowCoil"] = "RainbowCoil",
	["BuyGravityCoil"] = "GravityCoil",
}

-- Helper: give coil to player on gamepass purchase
local function handleCoilGamepassPurchase(player: Player, coilName: string)
	if not GameplayServiceServer:_playerHasTool(player, coilName) then
		print("ProductFunctionsServer: Giving " .. coilName .. " to " .. player.Name .. " after gamepass purchase")
		GameplayServiceServer:giveCoilToPlayer(player, coilName)
	end
end

-- Build the product functions table
local productFunctions: { [number]: (Player, any) -> Enum.ProductPurchaseDecision } = {
	[Products.getProductId("MorphPack1")] = function(player: Player)
		-- Skip if player already owns all morphs in this pack
		local unlockedMorphs = DataService:get(player, { "unlockedMorph" }) or {}
		local allOwned = true
		for _, morphName in ipairs(PackRewards.MorphPack1) do
			if not unlockedMorphs[morphName] then
				allOwned = false
				break
			end
		end
		if not allOwned then
			for _, morphName in ipairs(PackRewards.MorphPack1) do
				MorphServiceServer:addToData(player, morphName)
			end
		end
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,

	[Products.getProductId("MorphPack2")] = function(player: Player)
		-- Skip if player already owns all morphs in this pack
		local unlockedMorphs = DataService:get(player, { "unlockedMorph" }) or {}
		local allOwned = true
		for _, morphName in ipairs(PackRewards.MorphPack2) do
			if not unlockedMorphs[morphName] then
				allOwned = false
				break
			end
		end
		if not allOwned then
			for _, morphName in ipairs(PackRewards.MorphPack2) do
				MorphServiceServer:addToData(player, morphName)
			end
		end
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,

	[Products.getProductId("UnlockMorph")] = function(player: Player)
		local morph = MorphServiceServer.morphPurchaseCache[player]
		if morph then
			MorphServiceServer:addToData(player, morph)
			MorphServiceServer.morphPurchaseCache[player] = nil
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end,


	[Products.getProductId("BuyGoldPack")] = function(player: Player)
		-- Gold Pack purchase = skip timer only (morphs are given via the proximity prompt claim)
		local GameplayService = require(ServerScriptService.Services.GameplayService.GameplayServiceServer)
		GameplayService:onGoldPackPurchased(player)
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,
}

-- Register coil gamepass handlers dynamically
for purchaseName, coilName in COIL_GAMEPASS_MAP do
	local gamepassId = Products.getProductId(purchaseName)
	if gamepassId and gamepassId > 0 then
		productFunctions[gamepassId] = function(player: Player)
			handleCoilGamepassPurchase(player, coilName)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
end

return productFunctions
