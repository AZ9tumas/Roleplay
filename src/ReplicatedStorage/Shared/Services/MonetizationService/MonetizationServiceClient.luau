local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local purchaseSlice = require(ReplicatedStorage.UI.features.shop.state.purchaseSlice)

local MonetizationServiceClient = {}

function MonetizationServiceClient.promptClosed(self: MonetizationServiceClient)
	purchaseSlice.actions.setPurchase(false)
end

function MonetizationServiceClient.init(self: MonetizationServiceClient): ()
	self.networker = Networker.client.new("Monetization", self)
end

type MonetizationServiceClient = typeof(MonetizationServiceClient) & {
	networker: Networker.Client,
}

return MonetizationServiceClient :: MonetizationServiceClient
