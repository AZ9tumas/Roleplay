local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MorphServiceServer = require(ServerScriptService.Services.MorphService.MorphServiceServer)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)

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
} :: { [number]: (Player, any) -> Enum.ProductPurchaseDecision }
