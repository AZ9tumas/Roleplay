--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)

local GameplayServiceClient = {}
GameplayServiceClient.trophyClaimed = Signal.new()

local timerDuration: number = 0
local remainingTime: number = 0
local timeLabel: TextLabel? = nil
local promptEnabled: boolean = false
local goldPackClaimed: boolean = false

-- MorphPack state - table-based for modularity
local morphPackState: { [number]: {
	timeLimit: number,
	timerLabel: TextLabel?,
	deleted: boolean,
	purchased: boolean,  -- Track if pack has been purchased
} } = {}

-- MorphPack gamepass IDs mapping (packNumber -> product name)
local MORPH_PACK_PRODUCTS = {
	[1] = "MorphPack1",
	[2] = "MorphPack2",
}

-- Track collected trophies to prevent duplicate prompts
local collectedTrophies: { [string]: boolean } = {}

-- Track player's owned morphs (for trophy cleanup)
local ownedMorphs: { [string]: any } = {}

local function getTimeText(seconds: number): string
	local days = math.floor(seconds / 86400) -- 86400 seconds in a day
	local hours = math.floor((seconds % 86400) / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	
	-- Show dd:hh:mm:ss if >= 24 hours, otherwise hh:mm:ss
	if days > 0 then
		return string.format("%02d:%02d:%02d:%02d", days, hours, minutes, secs)
	else
		return string.format("%02d:%02d:%02d", hours, minutes, secs)
	end
end

-- Called when gold pack is claimed (either by timer or purchase)
function GameplayServiceClient.onGoldPackClaimed(_self: GameplayServiceClient): ()
	goldPackClaimed = true
	-- Wall lifted - player can pass through now
	-- The proximity prompt connection already saved the data on the server
end

function GameplayServiceClient._enablePromptAndConnect(self: GameplayServiceClient): ()
	local promptPart = workspace:WaitForChild("Map")
		and workspace.Map:WaitForChild("GoalPack")
		and workspace.Map.GoalPack:WaitForChild("Prompt")
	
	if not promptPart then
		warn("Prompt part not found in workspace")
		return
	end
	
	local prompt = promptPart:FindFirstChild("ProximityPrompt") :: ProximityPrompt?
	if not prompt then
		warn("ProximityPrompt not found in Prompt part")
		return
	end
	
	-- Enable the prompt after timer expires
	prompt.Enabled = true
	promptEnabled = true
	
	-- Connect to the triggered event only after timer expires for security
	prompt.Triggered:Connect(function(_player: Player)
		-- Send request to server to claim the gold pack (saves data)
		self.networker:fire("claimGoldPack")
	end)
end

-- Setup wall touch event for purchase prompt while timer is ongoing
function GameplayServiceClient._setupWallTouchPurchase(self: GameplayServiceClient): ()
	local mainWall = workspace:WaitForChild("Map")
		and workspace.Map:WaitForChild("GoldPack")
		and workspace.Map.GoldPack:WaitForChild("MainWall")
	
	if not mainWall then
		return
	end
	
	local player = Players.LocalPlayer
	local lastTouchTime = 0
	local TOUCH_DEBOUNCE = 2 -- seconds
	
	mainWall.Touched:Connect(function(hit: BasePart)
		-- Check if it's the local player touching
		local character = player.Character
		if not character or not hit:IsDescendantOf(character) then
			return
		end
		
		-- Only prompt purchase if timer is still ongoing
		if remainingTime <= 0 or goldPackClaimed then
			return
		end
		
		-- Debounce to prevent spam
		local currentTime = os.time()
		if currentTime - lastTouchTime < TOUCH_DEBOUNCE then
			return
		end
		lastTouchTime = currentTime
		
		-- Request purchase to skip the timer
		self.networker:fire("requestGoldPackPurchase")
	end)
end

function GameplayServiceClient._getMorphPackTimerLabel(standNumber: number): TextLabel?
	local standName = "MorphPackStand" .. standNumber
	local stand = workspace:WaitForChild("Map")
		and workspace.Map:WaitForChild("Spawn")
		and workspace.Map.Spawn:FindFirstChild(standName)
	
	if not stand then
		return nil
	end
	
	local cube2 = stand:FindFirstChild("Cube2")
	if not cube2 then
		return nil
	end
	
	local timerPart = cube2:FindFirstChild("TimerPart")
	if not timerPart then
		return nil
	end
	
	local face = timerPart:FindFirstChild("Face")
	if not face then
		return nil
	end
	
	return face:FindFirstChild("Timer") :: TextLabel?
end

function GameplayServiceClient._deleteMorphPackModel(standNumber: number): ()
	local standName = "MorphPackStand" .. standNumber
	local stand = workspace:WaitForChild("Map")
		and workspace.Map:WaitForChild("Spawn")
		and workspace.Map.Spawn:FindFirstChild(standName)
	
	if stand then
		stand:Destroy()
	end
end

function GameplayServiceClient.initMorphPackTimers(self: GameplayServiceClient, timeLimits: { [number]: number }): ()
	local currentTime = os.time()
	local player = Players.LocalPlayer
	
	-- Initialize state for each morph pack from the server-provided time limits
	for packNumber, timeLimit in pairs(timeLimits) do
		local timerLabel = self._getMorphPackTimerLabel(packNumber)
		local isExpired = currentTime >= timeLimit
		
		-- Check if player owns the gamepass for this pack
		local productName = MORPH_PACK_PRODUCTS[packNumber]
		local isPurchased = false
		if productName then
			local gamepassId = Products.getProductId(productName)
			if gamepassId and gamepassId > 0 then
				local success, ownsPass = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
				end)
				if success and ownsPass then
					isPurchased = true
				end
			end
		end
		
		morphPackState[packNumber] = {
			timeLimit = timeLimit,
			timerLabel = timerLabel,
			deleted = false,
			purchased = isPurchased,
		}
		
		-- If already purchased, show "Already Purchased" instead of timer
		if isPurchased and timerLabel then
			timerLabel.Text = "Already Purchased"
		-- If timer already expired, delete the model
		elseif isExpired then
			self._deleteMorphPackModel(packNumber)
			morphPackState[packNumber].deleted = true
		elseif timerLabel then
			-- Initial timer text update
			local remaining = math.max(timeLimit - currentTime, 0)
			timerLabel.Text = getTimeText(remaining)
		end
	end
end

function GameplayServiceClient.initTimer(self: GameplayServiceClient, serverJoinTime: number, serverTimerDuration: number, serverGoldPackClaimed: boolean): ()
	-- Set the timer duration from server
	timerDuration = serverTimerDuration
	goldPackClaimed = serverGoldPackClaimed or false
	
	-- Calculate remaining time based on when player joined
	local currentTime = os.time()
	local elapsedTime = currentTime - serverJoinTime
	remainingTime = math.max(timerDuration - elapsedTime, 0)

	local mapGoldPack = workspace:WaitForChild("Map")
		and workspace.Map:WaitForChild("GoldPack")
		and workspace.Map.GoldPack:WaitForChild("MainWall")
		and workspace.Map.GoldPack.MainWall:WaitForChild("SurfaceGui")
		and workspace.Map.GoldPack.MainWall.SurfaceGui:WaitForChild("Frame")
		and workspace.Map.GoldPack.MainWall.SurfaceGui.Frame:WaitForChild("Time")
	if not mapGoldPack then
		warn("Time label not found in workspace")
		return
	end

	timeLabel = mapGoldPack :: TextLabel
	
	-- If already claimed, skip timer display and prompt setup
	if goldPackClaimed then
		timeLabel.Text = "00:00:00"
		remainingTime = 0
		promptEnabled = true -- Don't need to enable prompt, already claimed
		return
	end
	
	timeLabel.Text = getTimeText(remainingTime)
	
	-- Setup wall touch event for purchase prompt while timer is ongoing
	self:_setupWallTouchPurchase()
	
	-- If timer already expired when player joins, enable prompt immediately
	if remainingTime <= 0 and not promptEnabled then
		self:_enablePromptAndConnect()
	end

	print("Connection setup")

	RunService.Heartbeat:Connect(function(dt: number)
		local currentTimeNow = os.time()
		
		-- GoldPack timer (per-player countdown)
		if remainingTime > 0 then
			remainingTime = math.max(remainingTime - dt, 0)
			if timeLabel then
				timeLabel.Text = getTimeText(remainingTime)
			end
			
			-- Enable prompt when timer reaches 0
			if remainingTime <= 0 and not promptEnabled then
				self:_enablePromptAndConnect()
			end
		end
		
		-- MorphPack timers (global countdown to timestamp) - modular iteration
		for packNumber, state in pairs(morphPackState) do
			-- Skip if already purchased (shows "Already Purchased") or deleted
			if not state.deleted and not state.purchased and state.timeLimit > 0 then
				local remaining = math.max(state.timeLimit - currentTimeNow, 0)
				
				if state.timerLabel then
					state.timerLabel.Text = getTimeText(remaining)
				end
				
				if remaining <= 0 then
					self._deleteMorphPackModel(packNumber)
					state.deleted = true
				end
			end
		end
	end)
end

function GameplayServiceClient._setupTrophyPrompt(self: GameplayServiceClient, trophy: Model): ()
	local trophyName = trophy.Name
	
	-- Find the Hitbox part
	local hitbox = trophy:FindFirstChild("Hitbox") :: BasePart?
	if not hitbox then
		warn("Hitbox not found in trophy: " .. trophyName)
		return
	end
	
	-- Find the ProximityPrompt using FindFirstChildWhichIsA
	local prompt = hitbox:FindFirstChildWhichIsA("ProximityPrompt") :: ProximityPrompt?
	if not prompt then
		warn("ProximityPrompt not found in Hitbox of trophy: " .. trophyName)
		return
	end
	
	-- Connect to the Triggered event
	prompt.Triggered:Connect(function(_player: Player)
		-- Prevent duplicate claims
		if collectedTrophies[trophyName] then
			return
		end
		collectedTrophies[trophyName] = true
		
		-- Send request to server to claim the trophy morph
		self.networker:fire("claimTrophy", trophyName)
	end)
end

function GameplayServiceClient._setupTrophies(self: GameplayServiceClient): ()
	print("GameplayServiceClient: Setting up trophies...")
	local trophiesFolder = workspace:WaitForChild("Trophies", 15)
	if not trophiesFolder then
		warn("GameplayServiceClient: Trophies folder not found in workspace (timeout)")
		return
	end
	
	print("GameplayServiceClient: Trophies folder found, checking items...")
	-- Setup prompts for all existing trophies (except those for morphs player already owns)
	for _, trophy in trophiesFolder:GetChildren() do
		if trophy:IsA("Model") then
			local morphName = trophy.Name
			
			-- If player already owns this morph, delete the trophy immediately
			if ownedMorphs[morphName] then
				-- print("GameplayServiceClient: Removing already owned trophy " .. morphName)
				trophy:Destroy()
			else
				self:_setupTrophyPrompt(trophy)
			end
		end
	end
end

-- Called from server when player's owned morphs are received
function GameplayServiceClient.initOwnedMorphs(self: GameplayServiceClient, serverOwnedMorphs: { [string]: any }): ()
	print("GameplayServiceClient: Received owned morphs data")
	ownedMorphs = serverOwnedMorphs or {}
	
	-- Now that we have the owned morphs, setup trophies (with cleanup)
	self:_setupTrophies()
end

function GameplayServiceClient.onTrophyClaimed(_self: GameplayServiceClient, trophyName: string): ()
	print("GameplayServiceClient: Trophy claimed confirmation received for " .. tostring(trophyName))
	-- Add to local owned morphs cache
	ownedMorphs[trophyName] = { obtainTime = os.time() }
	
	-- Delete the trophy model on the client
	local trophiesFolder = workspace:FindFirstChild("Trophies")
	if trophiesFolder then
		local trophy = trophiesFolder:FindFirstChild(trophyName)
		if trophy then
			trophy:Destroy()
		end
	end

	-- Fire signal for UI to handle
	print("GameplayServiceClient: Firing trophyClaimed signal for " .. tostring(trophyName))
	_self.trophyClaimed:Fire(trophyName)
end

function GameplayServiceClient.init(self: GameplayServiceClient): ()
	self.networker = Networker.client.new("Gameplay", self)
	print("GameplayServiceClient: Networker initialized")
	
	-- Trophy setup is now done in initOwnedMorphs after receiving player's owned morphs from server
	-- This ensures we can delete trophies for morphs the player already owns
	
	-- Listen for gamepass purchases to update MorphPack timers to "Already Purchased"
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if player ~= Players.LocalPlayer or not wasPurchased then
			return
		end
		
		-- Check if purchased gamepass matches a morph pack
		for packNumber, productName in pairs(MORPH_PACK_PRODUCTS) do
			local packGamepassId = Products.getProductId(productName)
			if packGamepassId == gamePassId then
				-- Update the state and timer label
				if morphPackState[packNumber] then
					morphPackState[packNumber].purchased = true
					if morphPackState[packNumber].timerLabel then
						morphPackState[packNumber].timerLabel.Text = "Already Purchased"
					end
				end
				break
			end
		end
	end)
end

type GameplayServiceClient = typeof(GameplayServiceClient) & {
	networker: Networker.Client,
}

return GameplayServiceClient :: GameplayServiceClient
