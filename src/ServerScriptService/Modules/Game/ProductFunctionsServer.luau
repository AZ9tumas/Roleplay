local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local MorphServiceServer = require(ServerScriptService.Services.MorphService.MorphServiceServer)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)

-- Configuration for GoldPack rewards - easily changeable for future updates
local GOLD_PACK_REWARD_MODEL = "AbbySaja"

return {
	[Products.getProductId("MorphPack1")] = function()
		print("One time only")
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

	[Products.getProductId("LimitedMorphTest")] = function(player: Player, receiptInfo: any)
		local result = MorphServiceServer:buyLimitedAmountMorph("LimitedMorphTest", receiptInfo, player)
		if result == Enum.ProductPurchaseDecision.PurchaseGranted then
			MorphServiceServer:addToData(player, "LimitedMorphTest")
		end
		return result
	end,

	[Products.getProductId("LimitedTimeMorphTest")] = function(player: Player, receiptInfo: any)
		local result = MorphServiceServer:buyLimitedTimeMorph("LimitedTimeMorphTest", receiptInfo, player)
		if result == Enum.ProductPurchaseDecision.PurchaseGranted then
			MorphServiceServer:addToData(player, "LimitedTimeMorphTest")
		end
		return result
	end,

	[Products.getProductId("BuyGoldPack")] = function(player: Player)
		-- Give the player the reward model (currently AbbySaja)
		local rewardModel = ServerStorage:FindFirstChild("Morphs") and ServerStorage.Morphs:FindFirstChild(GOLD_PACK_REWARD_MODEL)
		
		if not rewardModel then
			warn("Reward model " .. GOLD_PACK_REWARD_MODEL .. " not found in ServerStorage.Morphs")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		
		-- Add the morph to the player's unlocked morphs
		MorphServiceServer:addToData(player, GOLD_PACK_REWARD_MODEL)
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,
} :: { [number]: (Player, any) -> Enum.ProductPurchaseDecision }
