--!strict

local ServerStorage = game:GetService("ServerStorage")

local GoalServiceServer = {}

function GoalServiceServer.updateProgressBar(_self: GoalServiceServer): ()
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

	local mainBar = workspace:FindFirstChild("Map")
		and workspace.Map:FindFirstChild("Spawn")
		and workspace.Map.Spawn:FindFirstChild("Info")
		and workspace.Map.Spawn.Info:FindFirstChild("Untitled")
		and workspace.Map.Spawn.Info.Untitled:FindFirstChild("Progressbar")
		and workspace.Map.Spawn.Info.Untitled.Progressbar:FindFirstChild("SurfaceGui")
		and workspace.Map.Spawn.Info.Untitled.Progressbar.SurfaceGui:FindFirstChild("Container")
		and workspace.Map.Spawn.Info.Untitled.Progressbar.SurfaceGui.Container:FindFirstChild("ProgressBar")
		and workspace.Map.Spawn.Info.Untitled.Progressbar.SurfaceGui.Container.ProgressBar:FindFirstChild("Bar")

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
end

function GoalServiceServer.init(self: GoalServiceServer): ()
	self:updateProgressBar()
end

type GoalServiceServer = typeof(GoalServiceServer)

return GoalServiceServer :: GoalServiceServer
