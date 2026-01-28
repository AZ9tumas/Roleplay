local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local MorphServiceServer = require(ServerScriptService.Services.MorphService.MorphServiceServer)
local GameplayServiceServer = require(ServerScriptService.Services.GameplayService.GameplayServiceServer)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)
local PackRewards = require(ReplicatedStorage.Shared.Modules.Game.PackRewards)

-- Helper function to handle coil gamepass purchase (used for both dev product and gamepass callbacks)
local function handleCoilPurchase(player: Player): boolean
	local coilPurchaseCache = GameplayServiceServer:getCoilPurchaseCache()
	local coilName = coilPurchaseCache[player]
	if coilName then
		coilPurchaseCache[player] = nil
		return GameplayServiceServer:giveCoilToPlayer(player, coilName)
	end
	return false
end

return {
	[Products.getProductId("MorphPack1")] = function(player: Player)
		-- Give the player the MorphPack1 reward morphs
		for _, morphName in ipairs(PackRewards.MorphPack1) do
			MorphServiceServer:addToData(player, morphName)
		end
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,

	[Products.getProductId("MorphPack2")] = function(player: Player)
		-- Give the player the MorphPack2 reward morphs
		for _, morphName in ipairs(PackRewards.MorphPack2) do
			MorphServiceServer:addToData(player, morphName)
		end
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,
	
	[Products.getProductId("PoppyPlayTimePack")] = function(player: Player)
		for _, morphName in ipairs(PackRewards.PoppyPlayTimePack) do
			MorphServiceServer:addToData(player, morphName)
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,

	[Products.getProductId("SnakePhasePack")] = function(player: Player)
		for _, morphName in ipairs(PackRewards.SnakePhasePack) do
			MorphServiceServer:addToData(player, morphName)
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
		-- Check if this is a coil gamepass purchase (using the cache)
		if handleCoilPurchase(player) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		
		-- Otherwise, this is a Gold Pack purchase - give the reward morph
		local rewardModel = ServerStorage:FindFirstChild("Morphs") and ServerStorage.Morphs:FindFirstChild(PackRewards.GoldPack)
		
		if not rewardModel then
			warn("Reward model " .. PackRewards.GoldPack .. " not found in ServerStorage.Morphs")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		
		-- Add the morph to the player's unlocked morphs
		MorphServiceServer:addToData(player, PackRewards.GoldPack)
		
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,
} :: { [number]: (Player, any) -> Enum.ProductPurchaseDecision }
