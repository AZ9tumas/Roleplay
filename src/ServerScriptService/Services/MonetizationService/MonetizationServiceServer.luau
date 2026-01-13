--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Networker = require(ReplicatedStorage.Packages.Networker)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)
local ProductFunctionsServer = require(ServerScriptService.Modules.Game.ProductFunctionsServer)
local DataService = require(ReplicatedStorage.Packages.DataService).server

local PURCHASE_ID_CACHE_SIZE = 100

local MonetizationServiceServer = {}

local function playerOwnsGamepass(player: Player, gamepassId: number)
	local success, ownsGamepass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)

	if success then
		return ownsGamepass
	else
		warn("Error checking gamepass ownership:", ownsGamepass)
		return false
	end
end

function MonetizationServiceServer.initializeGamepass(
	_self: MonetizationServiceServer,
	player: Player,
	gamepassId: number
)
	local gamepassFunction = ProductFunctionsServer[gamepassId]
	if not gamepassFunction then
		return
	end

	gamepassFunction(player)
end

function MonetizationServiceServer.onGamepassPurchase(
	self: MonetizationServiceServer,
	player: Player,
	gamepassId: number
)
	self:initializeGamepass(player, gamepassId)

	DataService:arrayInsert(player, { "gamepasses" }, gamepassId)
end

function MonetizationServiceServer.checkOnJoin(self: MonetizationServiceServer, player: Player)
	local playerData = DataService:waitForData(player)
	local playerGamepasses = playerData:get({ "gamepasses" })

	for _gamepassName, prop in Products.ids do
		local gamepassId = prop.productId

		if Sift.Array.contains(playerGamepasses, gamepassId) then
			self:initializeGamepass(player, gamepassId)
		else
			if playerOwnsGamepass(player, gamepassId) then
				self:initializeGamepass(player, gamepassId)
			end
		end
	end
end

function MonetizationServiceServer._purchaseIdCheckAsync(
	profile: any,
	purchaseId: number,
	productFunction
): Enum.ProductPurchaseDecision
	if profile:IsActive() == true then
		local purchaseIdCache = profile.Data.purchaseIdCache
		if purchaseIdCache == nil then
			purchaseIdCache = {}
			profile.Data.purchaseIdCache = purchaseIdCache
		end

		if table.find(purchaseIdCache, purchaseId) == nil then
			local success, result = pcall(productFunction)
			if not success or result ~= Enum.ProductPurchaseDecision.PurchaseGranted then
				warn(`Failed to process:`, profile.Key, purchaseId)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			while #purchaseIdCache >= PURCHASE_ID_CACHE_SIZE do
				table.remove(purchaseIdCache, 1)
			end

			table.insert(purchaseIdCache, purchaseId)
		end

		local function isPurchaseSaved()
			local saved_cache = profile.LastSavedData.purchaseIdCache
			return if saved_cache ~= nil then table.find(saved_cache, purchaseId) ~= nil else false
		end

		if isPurchaseSaved() == true then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		while profile:IsActive() == true do
			local last_saved_data = profile.LastSavedData

			profile:Save()

			if profile.LastSavedData == last_saved_data then
				profile.OnAfterSave:Wait()
			end

			if isPurchaseSaved() == true then
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end

			if profile:IsActive() == true then
				task.wait(10)
			end
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationServiceServer._processReceipt(self: MonetizationServiceServer, receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if player ~= nil then
		local profile = DataService:getProfile(player)
		while profile == nil and player.Parent == Players do
			profile = DataService:getProfile(player)
			if profile ~= nil then
				break
			end
			task.wait()
		end

		if profile ~= nil then
			if ProductFunctionsServer[receiptInfo.ProductId] == nil then
				warn(`No product function defined for ProductId {receiptInfo.ProductId}; Player: {player.Name}`)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			local productData = Products.getById(receiptInfo.ProductId)
			if productData == nil then
				warn(`No product data defined for ProductId {receiptInfo.ProductId}; Player: {player.Name}`)
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			if productData.oneTime then
				local devProducts = DataService:get(player, { "devProducts" })
				if devProducts == nil or devProducts[productData.key] then
					return Enum.ProductPurchaseDecision.NotProcessedYet
				end
			end

			local result = self._purchaseIdCheckAsync(profile, receiptInfo.PurchaseId, function()
				return ProductFunctionsServer[receiptInfo.ProductId](player, receiptInfo)
			end)

			if result == Enum.ProductPurchaseDecision.PurchaseGranted and productData.oneTime then
				DataService:set(player, { "devProducts", productData.key }, true)
			end

			return result
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationServiceServer.init(self: MonetizationServiceServer)
	self.networker = Networker.server.new("Monetization", self, {})

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, gamepassId: number, purchased: boolean)
			self.networker:fire(player, "promptClosed")
			if not purchased then
				return
			end

			self:onGamepassPurchase(player, gamepassId)
		end
	)

	MarketplaceService.PromptProductPurchaseFinished:Connect(
		function(userId: number, _productId: number, _purchased: boolean)
			local player = Players:GetPlayerByUserId(userId)
			if not player then
				return
			end

			self.networker:fire(player, "promptClosed")
		end
	)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		self:_processReceipt(receiptInfo)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		self:checkOnJoin(player)
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(self.checkOnJoin, self, player)
	end
end

type MonetizationServiceServer = typeof(MonetizationServiceServer) & {
	networker: Networker.Server,
}

return MonetizationServiceServer :: MonetizationServiceServer
