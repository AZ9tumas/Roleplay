local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local MorphServiceServer = require(ServerScriptService.Services.MorphService.MorphServiceServer)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)

-- Configuration for pack rewards - easily changeable for future updates
local GOLD_PACK_REWARD_MODEL = "AbbySaja"
local MORPH_PACK_1_REWARD = "AbbySaja"
local MORPH_PACK_2_REWARD = "LimitedTimeMorphTest"

return {
	[Products.getProductId("MorphPack1")] = function(player: Player)
		-- Give the player the MorphPack1 reward morph
		local rewardModel = ServerStorage:FindFirstChild("Morphs") and ServerStorage.Morphs:FindFirstChild(MORPH_PACK_1_REWARD)
		
		if not rewardModel then
			warn("Reward model " .. MORPH_PACK_1_REWARD .. " not found in ServerStorage.Morphs")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		
		-- Add the morph to the player's unlocked morphs
		MorphServiceServer:addToData(player, MORPH_PACK_1_REWARD)
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,

	[Products.getProductId("MorphPack2")] = function(player: Player)
		-- Give the player the MorphPack2 reward morph
		local rewardModel = ServerStorage:FindFirstChild("Morphs") and ServerStorage.Morphs:FindFirstChild(MORPH_PACK_2_REWARD)
		
		if not rewardModel then
			warn("Reward model " .. MORPH_PACK_2_REWARD .. " not found in ServerStorage.Morphs")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		
		-- Add the morph to the player's unlocked morphs
		MorphServiceServer:addToData(player, MORPH_PACK_2_REWARD)
		
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
