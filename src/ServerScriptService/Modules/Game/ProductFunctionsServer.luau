local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MorphServiceServer = require(ServerScriptService.Services.MorphService.MorphServiceServer)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)

return {
	[Products.getProductId("MorphPack1")] = function()
		print("One time only")
	end,

	[Products.getProductId("UnlockMorph")] = function(player: Player)
		local morph = MorphServiceServer.morphPurchaseCache[player]
		if morph then
			MorphServiceServer:addToData(player, morph)
		end
	end,

	[Products.getProductId("LimitedMorphTest")] = function(player: Player, receiptInfo: any)
		return MorphServiceServer:buyLimitedAmountMorph("LimitedMorphTest", receiptInfo, player)
	end,

	[Products.getProductId("LimitedTimeMorphTest")] = function(player: Player, receiptInfo: any)
		return MorphServiceServer:buyLimitedTimeMorph("LimitedTimeMorphTest", receiptInfo, player)
	end,
} :: { [number]: (Player, any) -> () }
