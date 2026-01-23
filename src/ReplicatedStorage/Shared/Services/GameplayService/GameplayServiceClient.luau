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

-- MorphPack state
local morphPackTimeLimit1: number = 0
local morphPackTimeLimit2: number = 0
local morphPackTimerLabel1: TextLabel? = nil
local morphPackTimerLabel2: TextLabel? = nil
local morphPack1Deleted: boolean = false
local morphPack2Deleted: boolean = false

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

function GameplayServiceClient.initMorphPackTimers(self: GameplayServiceClient, timeLimit1: number, timeLimit2: number): ()
	morphPackTimeLimit1 = timeLimit1
	morphPackTimeLimit2 = timeLimit2
	
	-- Get timer labels
	morphPackTimerLabel1 = self._getMorphPackTimerLabel(1)
	morphPackTimerLabel2 = self._getMorphPackTimerLabel(2)
	
	local currentTime = os.time()
	
	-- Check if timers already expired
	if currentTime >= morphPackTimeLimit1 and not morphPack1Deleted then
		self._deleteMorphPackModel(1)
		morphPack1Deleted = true
	end
	
	if currentTime >= morphPackTimeLimit2 and not morphPack2Deleted then
		self._deleteMorphPackModel(2)
		morphPack2Deleted = true
	end
	
	-- Initial timer text update
	if morphPackTimerLabel1 and not morphPack1Deleted then
		local remaining1 = math.max(morphPackTimeLimit1 - currentTime, 0)
		morphPackTimerLabel1.Text = getTimeText(remaining1)
	end
	
	if morphPackTimerLabel2 and not morphPack2Deleted then
		local remaining2 = math.max(morphPackTimeLimit2 - currentTime, 0)
		morphPackTimerLabel2.Text = getTimeText(remaining2)
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
		
		-- MorphPack1 timer (global countdown to timestamp)
		if not morphPack1Deleted and morphPackTimeLimit1 > 0 then
			local remaining1 = math.max(morphPackTimeLimit1 - currentTimeNow, 0)
			if morphPackTimerLabel1 then
				morphPackTimerLabel1.Text = getTimeText(remaining1)
			end
			
			if remaining1 <= 0 then
				self._deleteMorphPackModel(1)
				morphPack1Deleted = true
			end
		end
		
		-- MorphPack2 timer (global countdown to timestamp)
		if not morphPack2Deleted and morphPackTimeLimit2 > 0 then
			local remaining2 = math.max(morphPackTimeLimit2 - currentTimeNow, 0)
			if morphPackTimerLabel2 then
				morphPackTimerLabel2.Text = getTimeText(remaining2)
			end
			
			if remaining2 <= 0 then
				self._deleteMorphPackModel(2)
				morphPack2Deleted = true
			end
		end
	end)
end

function GameplayServiceClient.init(self: GameplayServiceClient): ()
	self.networker = Networker.client.new("Gameplay", self)
end

type GameplayServiceClient = typeof(GameplayServiceClient) & {
	networker: Networker.Client,
}

return GameplayServiceClient :: GameplayServiceClient
