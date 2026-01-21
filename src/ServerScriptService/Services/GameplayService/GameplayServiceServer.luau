--!strict

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local GameplayServiceServer = {}

local remainingTime: number = 0
local timeLabel: TextLabel? = nil

local function getTimeText(seconds: number): string
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

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

function GameplayServiceServer.initTimer(_self: GameplayServiceServer): ()
	local goalPack = ServerStorage:FindFirstChild("GoalPack")
	if not goalPack then
		warn("GoalPack folder not found in ServerStorage")
		return
	end

	local timeValue = goalPack:FindFirstChild("Time") :: IntValue?
	if not timeValue then
		warn("Time IntValue not found in GoalPack")
		return
	end

	remainingTime = timeValue.Value

	local mapGoalPack = workspace:WaitForChild("Map")
		and workspace.Map:WaitForChild("GoalPack")
		and workspace.Map.GoalPack:WaitForChild("MainWall")
		and workspace.Map.GoalPack.MainWall:WaitForChild("SurfaceGui")
		and workspace.Map.GoalPack.MainWall.SurfaceGui:WaitForChild("Frame")
		and workspace.Map.GoalPack.MainWall.SurfaceGui.Frame:WaitForChild("Time")

	if not mapGoalPack then
		warn("Time label not found in workspace")
		return
	end

	timeLabel = mapGoalPack :: TextLabel
	timeLabel.Text = getTimeText(remainingTime)

	RunService.Heartbeat:Connect(function(dt: number)
		if remainingTime > 0 then
			remainingTime = math.max(remainingTime - dt, 0)
			if timeLabel then
				timeLabel.Text = getTimeText(remainingTime)
			end
		end
	end)
end

function GameplayServiceServer.init(self: GameplayServiceServer): ()
	self:updateProgressBar()
	self:initTimer()
end

type GameplayServiceServer = typeof(GameplayServiceServer)

return GameplayServiceServer :: GameplayServiceServer
