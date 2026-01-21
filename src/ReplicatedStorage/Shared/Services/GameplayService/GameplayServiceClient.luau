--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Networker = require(ReplicatedStorage.Packages.Networker)

local TIMER_DURATION = 30 * 60 -- 30 minutes in seconds

local GameplayServiceClient = {}

local remainingTime: number = TIMER_DURATION
local timeLabel: TextLabel? = nil
local promptEnabled: boolean = false

local function getTimeText(seconds: number): string
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
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

function GameplayServiceClient.initTimer(self: GameplayServiceClient, serverJoinTime: number): ()
	-- Calculate remaining time based on when player joined
	local currentTime = os.time()
	local elapsedTime = currentTime - serverJoinTime
	remainingTime = math.max(TIMER_DURATION - elapsedTime, 0)

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
	end)
end

function GameplayServiceClient.init(self: GameplayServiceClient): ()
	self.networker = Networker.client.new("Gameplay", self)
end

type GameplayServiceClient = typeof(GameplayServiceClient) & {
	networker: Networker.Client,
}

return GameplayServiceClient :: GameplayServiceClient
