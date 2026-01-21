--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)

local goldPack: Folder = ServerStorage:WaitForChild("GoldPack")
local TIMER_DURATION = goldPack:WaitForChild("Time").Value

local GameplayServiceServer = {}

local playerJoinTimes: { [Player]: number } = {}

function GameplayServiceServer.updateProgressBar(_self: GameplayServiceServer): ()
	local goalStats = ServerStorage:FindFirstChild("GoalStats")
	if not goalStats then
		warn("GoalStats folder not found in ServerStorage")
		return
	end

	local accomplished = goalStats:FindFirstChild("Accomplished") :: IntValue?
	local targetGoal = goalStats:FindFirstChild("TargetGoal") :: IntValue?

	if not accomplished or not targetGoal then
		warn("Accomplished or TargetGoal IntValue not found in GoalStats")
		return
	end

	local mainBar = workspace:WaitForChild("Map")
		and workspace.Map:WaitForChild("Spawn")
		and workspace.Map.Spawn:WaitForChild("Info")
		and workspace.Map.Spawn.Info:WaitForChild("Untitled")
		and workspace.Map.Spawn.Info.Untitled:WaitForChild("Progressbar")
		and workspace.Map.Spawn.Info.Untitled.Progressbar:WaitForChild("SurfaceGui")
		and workspace.Map.Spawn.Info.Untitled.Progressbar.SurfaceGui:WaitForChild("Container")
		and workspace.Map.Spawn.Info.Untitled.Progressbar.SurfaceGui.Container:WaitForChild("ProgressBar")
		and workspace.Map.Spawn.Info.Untitled.Progressbar.SurfaceGui.Container.ProgressBar:WaitForChild("Bar")
	
	local progressValue: TextLabel = mainBar.Parent:WaitForChild("ProgressValue")

	if not mainBar then
		warn("Progress bar not found in workspace")
		return
	end

	local percentage = 0
	if targetGoal.Value > 0 then
		percentage = math.min(accomplished.Value / targetGoal.Value, 1)
	end

	local oldSize = mainBar.Size
	mainBar.Size = UDim2.new(oldSize.X.Scale, oldSize.X.Offset, percentage, oldSize.Y.Offset)

	progressValue.Text = accomplished.Value .. "/" .. targetGoal.Value
end

function GameplayServiceServer.isTimerExpired(_self: GameplayServiceServer, player: Player): boolean
	local joinTime = playerJoinTimes[player]
	if not joinTime then
		return false
	end
	
	local currentTime = os.time()
	local elapsedTime = currentTime - joinTime
	return elapsedTime >= TIMER_DURATION
end

function GameplayServiceServer.getPlayerJoinTime(_self: GameplayServiceServer, player: Player): number?
	return playerJoinTimes[player]
end

function GameplayServiceServer.requestGoldPackPurchase(self: GameplayServiceServer, player: Player): ()
	-- Validate that the timer has expired for this player
	if not self:isTimerExpired(player) then
		warn("Player " .. player.Name .. " tried to purchase GoldPack before timer expired")
		return
	end
	
	-- Prompt the BuyGoldPack purchase
	Products.prompt(player, "BuyGoldPack")
end

function GameplayServiceServer._initPlayer(self: GameplayServiceServer, player: Player): ()
	local joinTime = os.time()
	playerJoinTimes[player] = joinTime
	
	-- Send join time to client so it can initialize its timer
	self.networker:fire(player, "initTimer", joinTime)
end

function GameplayServiceServer.init(self: GameplayServiceServer): ()
	self.networker = Networker.server.new("Gameplay", self, {
		self.requestGoldPackPurchase,
	})
	
	self:updateProgressBar()
	
	-- Initialize timer for existing players
	for _, player in Players:GetPlayers() do
		self:_initPlayer(player)
	end
	
	-- Initialize timer for new players
	Players.PlayerAdded:Connect(function(player: Player)
		self:_initPlayer(player)
	end)
	
	-- Cleanup on player leave
	Players.PlayerRemoving:Connect(function(player: Player)
		playerJoinTimes[player] = nil
	end)
end

type GameplayServiceServer = typeof(GameplayServiceServer) & {
	networker: Networker.Server,
}

return GameplayServiceServer :: GameplayServiceServer
