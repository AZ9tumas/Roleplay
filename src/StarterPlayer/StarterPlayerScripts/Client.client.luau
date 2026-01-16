local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService)
local MonetizationServiceClient =
	require(ReplicatedStorage.Shared.Services.MonetizationService.MonetizationServiceClient)
local MorphServiceClient = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceClient)
local UI = require(ReplicatedStorage.UI)

DataService.client:init()
MorphServiceClient:init()
MonetizationServiceClient:init()

-- Initialize UI (now uses native UI with TweenService animations instead of React)
UI()
