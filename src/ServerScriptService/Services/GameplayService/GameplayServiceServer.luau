--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Networker = require(ReplicatedStorage.Packages.Networker)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)
local DataService
local PackRewards = require(ReplicatedStorage.Shared.Modules.Game.PackRewards)

-- Lazy load MorphServiceServer to avoid circular dependency
local MorphServiceServer = nil
local function getMorphServiceServer()
	if MorphServiceServer == nil then
		MorphServiceServer = require(ServerScriptService.Services.MorphService.MorphServiceServer)
	end
	return MorphServiceServer
end

-- Lazy load NotificationServiceServer
local NotificationServiceServer = nil
local function getNotificationServiceServer()
	if NotificationServiceServer == nil then
		NotificationServiceServer = require(ServerScriptService.Services.NotificationService.NotificationServiceServer)
	end
	return NotificationServiceServer
end

local GROUP_ID = 267245073

local goldPack: Folder = ServerStorage:WaitForChild("GoldPack")
local TIMER_DURATION = goldPack:WaitForChild("Time").Value

-- MorphPack configuration - table-based for modularity
local morphPackFolder: Folder = ServerStorage:WaitForChild("MorphPack")
local MORPH_PACK_TIME_LIMITS = {
	[1] = morphPackFolder:WaitForChild("TimeLimit1").Value,
	[2] = morphPackFolder:WaitForChild("TimeLimit2").Value,
}

-- Coil stand configuration
local COIL_STANDS = {
	["PurpleStand"] = { coilName = "SuperCoil", purchaseName = "BuySuperCoil" },
	["RedStand"] = { coilName = "SpeedCoil", purchaseName = "BuySpeedCoil" },
	["RainbowStand"] = { coilName = "RainbowCoil", purchaseName = "BuyRainbowCoil" },
	["BlueStand"] = { coilName = "GravityCoil", purchaseName = "BuyGravityCoil" },
}

-- Cache which coil a player is purchasing (for product callback)
local coilPurchaseCache: { [Player]: string } = {}

local GameplayServiceServer = {}

local playerJoinTimes: { [Player]: number } = {}

-- Cached likes count from API
local cachedLikesCount: number = 0
local lastLikesFetch: number = 0
local LIKES_UPDATE_INTERVAL = 30 * 60 -- 30 minutes in seconds

-- Fetch likes from Roblox API using allorigins proxy
local function getLikes(): number
	local success, result = pcall(function()
		local url = "https://api.allorigins.win/get?url=" .. HttpService:UrlEncode("https://games.roblox.com/v1/games/votes?universeIds=" .. game.GameId)
		local req = HttpService:JSONDecode(HttpService:GetAsync(url))
		local res = HttpService:JSONDecode(req.contents)
		return res.data[1].upVotes
	end)
	
	if success then
		return result or 0
	else
		warn("Failed to fetch likes from API:", result)
		-- Fall back to ServerStorage value
		local goalStats = ServerStorage:FindFirstChild("GoalStats")
		if goalStats then
			local accomplished = goalStats:FindFirstChild("Accomplished") :: IntValue?
			if accomplished then
				return accomplished.Value
			end
		end
		return 0
	end
end

-- Track if player has already claimed gold pack (saved to data)
local function hasPlayerClaimedGoldPack(player: Player): boolean
	if DataService == nil then
		warn("DataService is nil in GameplayServiceServer!")
		return false
	end
	
	local success, goldPackClaimed = pcall(function() return DataService:get(player, { "goldPackClaimed" }) end)
	if not success then return false end

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

-- Hint purchase cost
local HINT_COST = 5

-- Debounce cache to prevent touch spam
local touchDebounce: { [Player]: number } = {}
local TOUCH_DEBOUNCE_TIME = 2 -- seconds

function GameplayServiceServer.checkUnlockCondition(self: GameplayServiceServer, player: Player): boolean
	if GROUP_ID == 0 then
		warn("GROUP_ID is not set in GameplayServiceServer")
		return false
	end
	
	local success, isInGroup = pcall(function()
		return player:IsInGroupAsync(GROUP_ID)
	end)
	
	if not success then
		warn("Failed to check group membership for " .. player.Name)
		return false
	end
	
	return isInGroup
end

function GameplayServiceServer.updateProgressBar(_self: GameplayServiceServer): ()
	local goalStats = ServerStorage:FindFirstChild("GoalStats")
	if not goalStats then
		warn("GoalStats folder not found in ServerStorage")
		return
	end

	local targetGoal = goalStats:FindFirstChild("TargetGoal") :: IntValue?

	if not targetGoal then
		warn("TargetGoal IntValue not found in GoalStats")
		return
	end

	-- Fetch likes from API if cache expired or not yet fetched
	local currentTime = os.time()
	if currentTime - lastLikesFetch >= LIKES_UPDATE_INTERVAL or cachedLikesCount == 0 then
		cachedLikesCount = getLikes()
		lastLikesFetch = currentTime
	end
	
	local accomplishedValue = cachedLikesCount

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
		percentage = math.min(accomplishedValue / targetGoal.Value, 1)
	end

	local oldSize = mainBar.Size
	mainBar.Size = UDim2.new(oldSize.X.Scale, oldSize.X.Offset, percentage, oldSize.Y.Offset)

	progressValue.Text = accomplishedValue .. "/" .. targetGoal.Value
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
	-- Check if player already owns all rewards
	local unlockedMorphs = DataService:get(player, { "unlockedMorph" }) or {}
	local allOwned = true
	for _, morphName in ipairs(PackRewards.MorphPack1) do
		if not unlockedMorphs[morphName] then
			allOwned = false
			break
		end
	end
	
	if allOwned then
		return
	end

	-- Validate that the morph pack timer has NOT expired (can only buy while timer is active)
	if self:isMorphPackExpired(1) then
		warn("Player " .. player.Name .. " tried to purchase MorphPack1 after timer expired")
		return
	end
	
	-- Prompt the MorphPack1 purchase
	Products.prompt(player, "MorphPack1")
end

function GameplayServiceServer.requestMorphPack2Purchase(self: GameplayServiceServer, player: Player): ()
	-- Check if player already owns all rewards
	local unlockedMorphs = DataService:get(player, { "unlockedMorph" }) or {}
	local allOwned = true
	for _, morphName in ipairs(PackRewards.MorphPack2) do
		if not unlockedMorphs[morphName] then
			allOwned = false
			break
		end
	end
	
	if allOwned then
		return
	end

	-- Validate that the morph pack timer has NOT expired (can only buy while timer is active)
	if self:isMorphPackExpired(2) then
		warn("Player " .. player.Name .. " tried to purchase MorphPack2 after timer expired")
		return
	end
	
	-- Prompt the MorphPack2 purchase
	Products.prompt(player, "MorphPack2")
end

-- Check if player already has a tool in their backpack
function GameplayServiceServer._playerHasTool(_self: GameplayServiceServer, player: Player, toolName: string): boolean
	local backpack = player:FindFirstChild("Backpack")
	if backpack and backpack:FindFirstChild(toolName) then
		return true
	end
	-- Also check if player currently has the tool equipped (in character)
	local character = player.Character
	if character and character:FindFirstChild(toolName) then
		return true
	end
	return false
end

-- Check if player owns a gamepass
function GameplayServiceServer._playerOwnsGamepass(_self: GameplayServiceServer, player: Player, gamepassId: number): boolean
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

-- Give coil tool to player
function GameplayServiceServer.giveCoilToPlayer(_self: GameplayServiceServer, player: Player, coilName: string): boolean
	local gears = ServerStorage:FindFirstChild("Gears")
	if not gears then
		warn("Gears folder not found in ServerStorage")
		return false
	end
	
	local coilTool = gears:FindFirstChild(coilName)
	if not coilTool or not coilTool:IsA("Tool") then
		warn("Coil tool " .. coilName .. " not found in ServerStorage.Gears")
		return false
	end
	
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		warn("Player " .. player.Name .. " has no Backpack")
		return false
	end
	
	local clonedTool = coilTool:Clone()
	clonedTool.Parent = backpack
	return true
end

-- Request coil purchase functions (gamepass-based)
function GameplayServiceServer.requestBuySuperCoil(self: GameplayServiceServer, player: Player): ()
	local coilName = "SuperCoil"
	if self:_playerHasTool(player, coilName) then
		return
	end
	
	-- Check if player owns the gamepass, if yes give coil directly
	local gamepassId = Products.getProductId("BuySuperCoil")
	if self:_playerOwnsGamepass(player, gamepassId) then
		self:giveCoilToPlayer(player, coilName)
		return
	end
	
	-- Player doesn't own gamepass, prompt purchase
	coilPurchaseCache[player] = coilName
	Products.prompt(player, "BuySuperCoil")
end

function GameplayServiceServer.requestBuySpeedCoil(self: GameplayServiceServer, player: Player): ()
	local coilName = "SpeedCoil"
	if self:_playerHasTool(player, coilName) then
		return
	end
	
	-- Check if player owns the gamepass, if yes give coil directly
	local gamepassId = Products.getProductId("BuySpeedCoil")
	if self:_playerOwnsGamepass(player, gamepassId) then
		self:giveCoilToPlayer(player, coilName)
		return
	end
	
	-- Player doesn't own gamepass, prompt purchase
	coilPurchaseCache[player] = coilName
	Products.prompt(player, "BuySpeedCoil")
end

function GameplayServiceServer.requestBuyRainbowCoil(self: GameplayServiceServer, player: Player): ()
	local coilName = "RainbowCoil"
	if self:_playerHasTool(player, coilName) then
		return
	end
	
	-- Check if player owns the gamepass, if yes give coil directly
	local gamepassId = Products.getProductId("BuyRainbowCoil")
	if self:_playerOwnsGamepass(player, gamepassId) then
		self:giveCoilToPlayer(player, coilName)
		return
	end
	
	-- Player doesn't own gamepass, prompt purchase
	coilPurchaseCache[player] = coilName
	Products.prompt(player, "BuyRainbowCoil")
end

function GameplayServiceServer.requestBuyGravityCoil(self: GameplayServiceServer, player: Player): ()
	local coilName = "GravityCoil"
	if self:_playerHasTool(player, coilName) then
		return
	end
	
	-- Check if player owns the gamepass, if yes give coil directly
	local gamepassId = Products.getProductId("BuyGravityCoil")
	if self:_playerOwnsGamepass(player, gamepassId) then
		self:giveCoilToPlayer(player, coilName)
		return
	end
	
	-- Player doesn't own gamepass, prompt purchase
	coilPurchaseCache[player] = coilName
	Products.prompt(player, "BuyGravityCoil")
end

-- Getter for coil purchase cache (used by ProductFunctionsServer)
function GameplayServiceServer.getCoilPurchaseCache(_self: GameplayServiceServer): { [Player]: string }
	return coilPurchaseCache
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

-- Purchase a hint for 5 coins (if morph not unlocked and hint not already purchased)
function GameplayServiceServer.purchaseHint(self: GameplayServiceServer, player: Player, morphName: string): ()
	if DataService == nil then
		warn("DataService is nil in GameplayServiceServer!")
		return
	end
	
	-- Check if player already owns the morph (hints are free if morph is unlocked)
	local unlockedMorphs = DataService:get(player, { "unlockedMorph" }) or {}
	if unlockedMorphs[morphName] then
		-- Morph is unlocked, hint should be shown for free (no purchase needed)
		-- Client will handle showing the hint directly
		self.networker:fire(player, "onHintPurchased", morphName, true)
		return
	end
	
	-- Check if player already purchased this hint
	local unlockedHints = DataService:get(player, { "unlockedHints" }) or {}
	if unlockedHints[morphName] then
		-- Hint already purchased, show it for free
		self.networker:fire(player, "onHintPurchased", morphName, true)
		return
	end
	
	-- Check if player has enough coins
	local coins = DataService:get(player, { "coins" }) or 0
	if coins < HINT_COST then
		getNotificationServiceServer():SendNotification(player, "Not enough coins! You need " .. HINT_COST .. " coins.")
		self.networker:fire(player, "onHintPurchased", morphName, false)
		return
	end
	
	-- Deduct coins
	DataService:set(player, { "coins" }, coins - HINT_COST)
	
	-- Mark hint as unlocked
	unlockedHints[morphName] = true
	DataService:set(player, { "unlockedHints" }, unlockedHints)
	
	-- Update leaderstats display
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins")
		if coinsValue and coinsValue:IsA("IntValue") then
			coinsValue.Value = coins - HINT_COST
		end
	end
	
	-- Notify success
	getNotificationServiceServer():SendNotification(player, "Hint unlocked for " .. HINT_COST .. " coins!")
	self.networker:fire(player, "onHintPurchased", morphName, true)
end

-- Check if a hint is unlocked for a player (morph owned or hint purchased)
function GameplayServiceServer.isHintUnlocked(self: GameplayServiceServer, player: Player, morphName: string): boolean
	if DataService == nil then
		warn("DataService is nil in GameplayServiceServer!")
		return false
	end
	
	-- Check if player owns the morph
	local unlockedMorphs = DataService:get(player, { "unlockedMorph" }) or {}
	if unlockedMorphs[morphName] then
		return true
	end
	
	-- Check if player purchased the hint
	local unlockedHints = DataService:get(player, { "unlockedHints" }) or {}
	return unlockedHints[morphName] == true
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

function GameplayServiceServer._setupCoilStand(self: GameplayServiceServer, standName: string): ()
	local standConfig = COIL_STANDS[standName]
	if not standConfig then
		warn("Unknown coil stand: " .. standName)
		return
	end
	
	local stand = workspace:WaitForChild("Map")
		and workspace.Map:WaitForChild("Spawn")
		and workspace.Map.Spawn:FindFirstChild(standName)
	
	if not stand then
		warn("Coil stand " .. standName .. " not found in workspace.Map.Spawn")
		return
	end
	
	local packPart = stand:FindFirstChild("PackPart") :: BasePart?
	if not packPart then
		warn("PackPart not found in " .. standName)
		return
	end
	
	-- Setup touched event for the coil stand pack part with debouncing
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
			
			-- Call the appropriate coil purchase function based on stand
			if standName == "PurpleStand" then
				self:requestBuySuperCoil(player)
			elseif standName == "RedStand" then
				self:requestBuySpeedCoil(player)
			elseif standName == "RainbowStand" then
				self:requestBuyRainbowCoil(player)
			elseif standName == "BlueStand" then
				self:requestBuyGravityCoil(player)
			end
		end
	end)
end

function GameplayServiceServer._initPlayer(self: GameplayServiceServer, player: Player): ()
	task.spawn(function()
		print("GameplayServiceServer: Initializing player " .. player.Name)
		
		-- Wait for DataService to load the player's profile to prevent nil index errors
		if DataService then
			DataService:waitForData(player)
		else
			warn("GameplayServiceServer: DataService is nil during _initPlayer")
			return
		end

		local joinTime = os.time()
		playerJoinTimes[player] = joinTime
		
		-- Check if player has already claimed gold pack
		local goldPackClaimed = hasPlayerClaimedGoldPack(player)
		print("GameplayServiceServer: Gold pack claimed: " .. tostring(goldPackClaimed))
		
		-- Send join time, timer duration, and claimed status to client so it can initialize its timer
		print("GameplayServiceServer: Firing initTimer")
		self.networker:fire(player, "initTimer", joinTime, TIMER_DURATION, goldPackClaimed)
		
		-- Send MorphPack time limits to client as a table
		print("GameplayServiceServer: Firing initMorphPackTimers")
		self.networker:fire(player, "initMorphPackTimers", MORPH_PACK_TIME_LIMITS)
		
		-- Send player's unlocked morphs for trophy cleanup on client
		print("GameplayServiceServer: Getting unlockedMorphs data...")
		local unlockedMorphs = DataService:get(player, { "unlockedMorph" }) or {}
		print("GameplayServiceServer: Got unlockedMorphs (count: " .. (unlockedMorphs and #unlockedMorphs or 0) .. ")")
		
		-- Check for Group Morph Unlocks
		print("GameplayServiceServer: Checking group membership...")
		local inGroup = self:checkUnlockCondition(player)
		print("GameplayServiceServer: Group member: " .. tostring(inGroup))
	
		local groupMorphs = { "HungryWormSmiley", "HungryWormCatV2" }
		local anyNewUnlocked = false
		local missingGroupMorphs = false
	
		for _, morphName in ipairs(groupMorphs) do
			if unlockedMorphs[morphName] then
				continue
			end
	
			if inGroup then
				print("GameplayServiceServer: Awarding group morph: " .. morphName)
				local morphService = getMorphServiceServer()
				-- Pass true to suppress "You already own this" if we somehow hit a race condition
				morphService:addToData(player, morphName, true)
				unlockedMorphs[morphName] = true -- Update local cache so client gets it
				anyNewUnlocked = true
			else
				missingGroupMorphs = true
			end
		end
	
		if anyNewUnlocked then
			getNotificationServiceServer():SendNotification(player, "You received exclusive morphs for being in the group!")
		elseif missingGroupMorphs and not inGroup then
			getNotificationServiceServer():SendNotification(player, "Join the group to get free morphs!")
		end
		
		-- Get unlocked hints data
		local unlockedHints = DataService:get(player, { "unlockedHints" }) or {}
		
		print("GameplayServiceServer: Firing initOwnedMorphs")
		self.networker:fire(player, "initOwnedMorphs", unlockedMorphs, unlockedHints)
	end)
end

function GameplayServiceServer.init(self: GameplayServiceServer): ()
	-- Initialize DataService here to avoid circular dependency issues
	if not DataService then
		DataService = require(ReplicatedStorage.Packages.DataService).server
	end

	self.networker = Networker.server.new("Gameplay", self, {
		self.requestGoldPackPurchase,
		self.claimGoldPack,
		self.requestMorphPack1Purchase,
		self.requestMorphPack2Purchase,
		self.claimTrophy,
		self.purchaseHint,
		self.isHintUnlocked,
	})
	
	task.spawn(function()
		self:updateProgressBar()
	end)
	
	-- Start periodic update of progress bar (every 30 minutes)
	task.spawn(function()
		while true do
			task.wait(LIKES_UPDATE_INTERVAL)
			self:updateProgressBar()
		end
	end)
	
	-- Setup MorphPack stands
	self:_setupMorphPackStand(1)
	self:_setupMorphPackStand(2)
	
	-- Setup Coil stands
	for standName, _ in COIL_STANDS do
		self:_setupCoilStand(standName)
	end
	
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
		coilPurchaseCache[player] = nil
	end)
end

type GameplayServiceServer = typeof(GameplayServiceServer) & {
	networker: Networker.Server,
}

return GameplayServiceServer :: GameplayServiceServer
