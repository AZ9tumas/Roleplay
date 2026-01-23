local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MonetizationServiceServer = require(ServerScriptService.Services.MonetizationService.MonetizationServiceServer)
local DataService = require(ReplicatedStorage.Packages.DataService)
local DataTemplate = require(ReplicatedStorage.Shared.Modules.Main.DataTemplate)
local MorphServiceServer = require(ServerScriptService.Services.MorphService.MorphServiceServer)
local CoinServiceServer = require(ServerScriptService.Services.CoinService.CoinServiceServer)
local GameplayServiceServer = require(ServerScriptService.Services.GameplayService.GameplayServiceServer)
local NotificationServiceServer = require(ServerScriptService.Services.NotificationService.NotificationServiceServer)

DataService.server:init({
	template = DataTemplate,
	profileStoreIndex = "Test#1",
	useMock = false,
})
NotificationServiceServer:init()
MorphServiceServer:init(true)
MonetizationServiceServer:init()
CoinServiceServer:init()
GameplayServiceServer:init()
