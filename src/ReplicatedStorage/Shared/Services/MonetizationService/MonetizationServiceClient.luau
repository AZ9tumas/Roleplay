local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)

local MonetizationServiceClient = {}

function MonetizationServiceClient.promptClosed(_self: MonetizationServiceClient)
	-- Purchase prompt closed - UI updates happen via DataService signals
end

function MonetizationServiceClient.init(self: MonetizationServiceClient): ()
	self.networker = Networker.client.new("Monetization", self)
end

type MonetizationServiceClient = typeof(MonetizationServiceClient) & {
	networker: Networker.Client,
}

return MonetizationServiceClient :: MonetizationServiceClient
