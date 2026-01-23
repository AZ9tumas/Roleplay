local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local MorphServiceServer = require(ServerScriptService.Services.MorphService.MorphServiceServer)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)

-- Configuration for pack rewards - easily changeable for future updates
local GOLD_PACK_REWARD_MODEL = "AbbySaja"
local MORPH_PACK_REWARDS = {
	[1] = "AbbySaja",
	[2] = "LimitedTimeMorphTest",
}

-- Note: This will be initialized after GameplayServiceServer is required
local GameplayServiceServer = nil
local function getGameplayServiceServer()
	if GameplayServiceServer == nil then
		GameplayServiceServer = require(ServerScriptService.Services.GameplayService.GameplayServiceServer)
	end
	return GameplayServiceServer
end

return {
	[Products.getProductId("MorphPack1")] = function(player: Player)
		-- Get which pack the player was purchasing from the cache
		local gameplayService = getGameplayServiceServer()
		local packNumber = gameplayService.morphPackPurchaseCache[player] or 1
		local rewardMorph = MORPH_PACK_REWARDS[packNumber] or MORPH_PACK_REWARDS[1]
		
		-- Give the player the reward morph
		local rewardModel = ServerStorage:FindFirstChild("Morphs") and ServerStorage.Morphs:FindFirstChild(rewardMorph)
		
		if not rewardModel then
			warn("Reward model " .. rewardMorph .. " not found in ServerStorage.Morphs")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		
		-- Add the morph to the player's unlocked morphs
		MorphServiceServer:addToData(player, rewardMorph)
		
		-- Clear the cache
		gameplayService.morphPackPurchaseCache[player] = nil
		
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
