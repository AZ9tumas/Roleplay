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

local function getstuff()
	local stuff = {}
	for i, v in pairs(workspace.Morphs.NewMorphs:GetChildren()) do
		local morphName = v.Name
		local morphStuff = {animations = {}}

		for _, v2 in pairs(v.Animate:GetChildren()) do
			for _, v3 in pairs(v2:GetChildren()) do
				if not v3:IsA("Animation") then continue end
				
				morphStuff.animations[v2.Name] = v3.AnimationId
			end

			stuff[morphName] = morphStuff
		end
	end

	print(stuff, 'hey')
end

task.delay(1, getstuff)