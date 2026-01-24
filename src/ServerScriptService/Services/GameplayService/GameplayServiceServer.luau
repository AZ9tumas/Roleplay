--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)
local DataService = require(ReplicatedStorage.Packages.DataService).server

-- Lazy load MorphServiceServer to avoid circular dependency
local MorphServiceServer = nil
local function getMorphServiceServer()
	if MorphServiceServer == nil then
		MorphServiceServer = require(ServerScriptService.Services.MorphService.MorphServiceServer)
	end
	return MorphServiceServer
end

local goldPack: Folder = ServerStorage:WaitForChild("GoldPack")
local TIMER_DURATION = goldPack:WaitForChild("Time").Value

-- MorphPack configuration - table-based for modularity
local morphPackFolder: Folder = ServerStorage:WaitForChild("MorphPack")
local MORPH_PACK_TIME_LIMITS = {
	[1] = morphPackFolder:WaitForChild("TimeLimit1").Value,
	[2] = morphPackFolder:WaitForChild("TimeLimit2").Value,
}

local GameplayServiceServer = {}

local playerJoinTimes: { [Player]: number } = {}

-- Track if player has already claimed gold pack (saved to data)
local function hasPlayerClaimedGoldPack(player: Player): boolean
	-- Check if DataService is available before accessing
	if DataService == nil then
		return false
	end
	local success, goldPackClaimed = pcall(function()
		return DataService:get(player, { "goldPackClaimed" })
	end)
	if not success then
		return false
	end
	return goldPackClaimed == true
end

local function setPlayerClaimedGoldPack(player: Player): ()
	-- Check if DataService is available before setting
	if DataService == nil then
		warn("DataService not available, cannot save goldPackClaimed")
		return
	end
	pcall(function()
		DataService:set(player, { "goldPackClaimed" }, true)
	end)
end

-- Track claimed trophies per player to prevent duplicates
local claimedTrophies: { [Player]: { [string]: boolean } } = {}

-- Debounce cache to prevent touch spam
local touchDebounce: { [Player]: number } = {}
local TOUCH_DEBOUNCE_TIME = 2 -- seconds

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

function GameplayServiceServer.isMorphPackExpired(_self: GameplayServiceServer, packNumber: number): boolean
	local timeLimit = MORPH_PACK_TIME_LIMITS[packNumber]
	if not timeLimit then
		return true
	end
	return os.time() >= timeLimit
end

function GameplayServiceServer.getPlayerJoinTime(_self: GameplayServiceServer, player: Player): number?
	return playerJoinTimes[player]
end

-- Called when player triggers the proximity prompt after timer is up
function GameplayServiceServer.claimGoldPack(self: GameplayServiceServer, player: Player): ()
	-- Validate that the timer has expired for this player
	if not self:isTimerExpired(player) then
		warn("Player " .. player.Name .. " tried to claim GoldPack before timer expired")
		return
	end
	
	-- Check if already claimed
	if hasPlayerClaimedGoldPack(player) then
		warn("Player " .. player.Name .. " already claimed GoldPack")
		return
	end
	
	-- Save that the player has claimed the gold pack
	setPlayerClaimedGoldPack(player)
	
	-- Notify client that gold pack is claimed (wall lifted, saved)
	self.networker:fire(player, "onGoldPackClaimed")
end

-- Called when player hits the wall while timer is still ongoing (prompts purchase to skip)
function GameplayServiceServer.requestGoldPackPurchase(self: GameplayServiceServer, player: Player): ()
	-- Validate that the timer has NOT expired (can only buy to skip while timer is active)
	if self:isTimerExpired(player) then
		warn("Player " .. player.Name .. " tried to purchase GoldPack after timer expired (use claim instead)")
		return
	end
	
	-- Prompt the BuyGoldPack purchase
	Products.prompt(player, "BuyGoldPack")
end

function GameplayServiceServer.requestMorphPack1Purchase(self: GameplayServiceServer, player: Player): ()
	-- Validate that the morph pack timer has NOT expired (can only buy while timer is active)
	if self:isMorphPackExpired(1) then
		warn("Player " .. player.Name .. " tried to purchase MorphPack1 after timer expired")
		return
	end
	
	-- Prompt the MorphPack1 purchase
	Products.prompt(player, "MorphPack1")
end

function GameplayServiceServer.requestMorphPack2Purchase(self: GameplayServiceServer, player: Player): ()
	-- Validate that the morph pack timer has NOT expired (can only buy while timer is active)
	if self:isMorphPackExpired(2) then
		warn("Player " .. player.Name .. " tried to purchase MorphPack2 after timer expired")
		return
	end
	
	-- Prompt the MorphPack2 purchase
	Products.prompt(player, "MorphPack2")
end

function GameplayServiceServer.claimTrophy(self: GameplayServiceServer, player: Player, trophyName: string): ()
	-- Validate the trophy exists in workspace
	local trophiesFolder = workspace:FindFirstChild("Trophies")
	if not trophiesFolder then
		warn("Trophies folder not found in workspace")
		return
	end
	
	local trophy = trophiesFolder:FindFirstChild(trophyName)
	if not trophy then
		warn("Trophy " .. trophyName .. " not found in workspace.Trophies")
		return
	end
	
	-- Check if player already claimed this trophy
	if not claimedTrophies[player] then
		claimedTrophies[player] = {}
	end
	
	if claimedTrophies[player][trophyName] then
		warn("Player " .. player.Name .. " already claimed trophy: " .. trophyName)
		return
	end
	
	-- Mark trophy as claimed for this player
	claimedTrophies[player][trophyName] = true
	
	-- Give the morph to the player (trophy name = morph name)
	-- Uses MorphServiceServer:addToData(player, morphName) to add to player's unlocked morphs
	local morphService = getMorphServiceServer()
	morphService:addToData(player, trophyName)
	
	-- Notify the client to delete the trophy
	self.networker:fire(player, "onTrophyClaimed", trophyName)
end

function GameplayServiceServer._setupMorphPackStand(self: GameplayServiceServer, standNumber: number): ()
	local standName = "MorphPackStand" .. standNumber
	local stand = workspace:WaitForChild("Map")
		and workspace.Map:WaitForChild("Spawn")
		and workspace.Map.Spawn:FindFirstChild(standName)
	
	if not stand then
		warn("MorphPackStand" .. standNumber .. " not found in workspace")
		return
	end
	
	local packPart = stand:FindFirstChild("PackPart") :: BasePart?
	if not packPart then
		warn("PackPart not found in " .. standName)
		return
	end
	
	-- Setup touched event for the pack part with debouncing
	packPart.Touched:Connect(function(hit: BasePart)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			-- Check debounce
			local currentTime = os.time()
			local lastTouch = touchDebounce[player]
			if lastTouch and (currentTime - lastTouch) < TOUCH_DEBOUNCE_TIME then
				return
			end
			touchDebounce[player] = currentTime
			
			-- Call the appropriate purchase function based on stand number
			if standNumber == 1 then
				self:requestMorphPack1Purchase(player)
			elseif standNumber == 2 then
				self:requestMorphPack2Purchase(player)
			end
		end
	end)
end

function GameplayServiceServer._initPlayer(self: GameplayServiceServer, player: Player): ()
	local joinTime = os.time()
	playerJoinTimes[player] = joinTime
	
	-- Check if player has already claimed gold pack
	local goldPackClaimed = hasPlayerClaimedGoldPack(player)
	
	-- Send join time, timer duration, and claimed status to client so it can initialize its timer
	self.networker:fire(player, "initTimer", joinTime, TIMER_DURATION, goldPackClaimed)
	
	-- Send MorphPack time limits to client as a table
	self.networker:fire(player, "initMorphPackTimers", MORPH_PACK_TIME_LIMITS)
	
	-- Send player's unlocked morphs for trophy cleanup on client
	local unlockedMorphs = DataService:get(player, { "unlockedMorph" }) or {}
	self.networker:fire(player, "initOwnedMorphs", unlockedMorphs)
end

function GameplayServiceServer.init(self: GameplayServiceServer): ()
	self.networker = Networker.server.new("Gameplay", self, {
		self.requestGoldPackPurchase,
		self.claimGoldPack,
		self.requestMorphPack1Purchase,
		self.requestMorphPack2Purchase,
		self.claimTrophy,
	})
	
	self:updateProgressBar()
	
	-- Setup MorphPack stands
	self:_setupMorphPackStand(1)
	self:_setupMorphPackStand(2)
	
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
		touchDebounce[player] = nil
		claimedTrophies[player] = nil
	end)
end

type GameplayServiceServer = typeof(GameplayServiceServer) & {
	networker: Networker.Server,
}

return GameplayServiceServer :: GameplayServiceServer
