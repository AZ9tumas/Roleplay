local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local UIState = require(ReplicatedStorage.Shared.Modules.UI.UIState)

local MonetizationServiceClient = {}

function MonetizationServiceClient.promptClosed(self: MonetizationServiceClient)
	UIState.setPurchasing(false)
end

function MonetizationServiceClient.init(self: MonetizationServiceClient): ()
	self.networker = Networker.client.new("Monetization", self)
end

type MonetizationServiceClient = typeof(MonetizationServiceClient) & {
	networker: Networker.Client,
}

return MonetizationServiceClient :: MonetizationServiceClient
