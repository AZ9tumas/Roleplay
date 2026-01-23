--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Networker = require(ReplicatedStorage.Packages.Networker)

local GameplayServiceClient = {}

local timerDuration: number = 0
local remainingTime: number = 0
local timeLabel: TextLabel? = nil
local promptEnabled: boolean = false

-- MorphPack state - table-based for modularity
local morphPackState: { [number]: {
	timeLimit: number,
	timerLabel: TextLabel?,
	deleted: boolean,
} } = {}

-- Track collected trophies to prevent duplicate prompts
local collectedTrophies: { [string]: boolean } = {}

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
		-- Send request to server to validate and prompt purchase
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
	
	-- Initialize state for each morph pack from the server-provided time limits
	for packNumber, timeLimit in pairs(timeLimits) do
		local timerLabel = self._getMorphPackTimerLabel(packNumber)
		local isExpired = currentTime >= timeLimit
		
		morphPackState[packNumber] = {
			timeLimit = timeLimit,
			timerLabel = timerLabel,
			deleted = false,
		}
		
		-- If timer already expired, delete the model
		if isExpired then
			self._deleteMorphPackModel(packNumber)
			morphPackState[packNumber].deleted = true
		elseif timerLabel then
			-- Initial timer text update
			local remaining = math.max(timeLimit - currentTime, 0)
			timerLabel.Text = getTimeText(remaining)
		end
	end
end

function GameplayServiceClient.initTimer(self: GameplayServiceClient, serverJoinTime: number, serverTimerDuration: number): ()
	-- Set the timer duration from server
	timerDuration = serverTimerDuration
	
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
	timeLabel.Text = getTimeText(remainingTime)
	
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
			if not state.deleted and state.timeLimit > 0 then
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
	local trophiesFolder = workspace:FindFirstChild("Trophies")
	if not trophiesFolder then
		return
	end
	
	-- Setup prompts for all existing trophies
	for _, trophy in trophiesFolder:GetChildren() do
		if trophy:IsA("Model") then
			self:_setupTrophyPrompt(trophy)
		end
	end
end

function GameplayServiceClient.onTrophyClaimed(_self: GameplayServiceClient, trophyName: string): ()
	-- Delete the trophy model on the client
	local trophiesFolder = workspace:FindFirstChild("Trophies")
	if trophiesFolder then
		local trophy = trophiesFolder:FindFirstChild(trophyName)
		if trophy then
			trophy:Destroy()
		end
	end
end

function GameplayServiceClient.init(self: GameplayServiceClient): ()
	self.networker = Networker.client.new("Gameplay", self)
	
	-- Setup trophy proximity prompts
	self:_setupTrophies()
end

type GameplayServiceClient = typeof(GameplayServiceClient) & {
	networker: Networker.Client,
}

return GameplayServiceClient :: GameplayServiceClient
