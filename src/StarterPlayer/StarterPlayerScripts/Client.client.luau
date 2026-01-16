local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService)
local MonetizationServiceClient =
	require(ReplicatedStorage.Shared.Services.MonetizationService.MonetizationServiceClient)
local MorphServiceClient = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceClient)

DataService.client:init()
MorphServiceClient:init()
MonetizationServiceClient:init()

-- Note: UI animations are now handled by UIAnimations LocalScript
-- The React UI module has been replaced with native animations on existing UI elements
