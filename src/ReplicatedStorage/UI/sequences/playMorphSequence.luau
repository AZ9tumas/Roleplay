local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local MorphServiceClient = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceClient)

local Assets = ReplicatedStorage.Assets
local Morphs = Assets.Morphs

local camera = workspace.CurrentCamera

local popUpInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
local popDownInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine)

return function(name: string)
	local model = Morphs:FindFirstChild(name)
	if not model then
		return
	end

	if not model.PrimaryPart then
		return
	end

	local modelClone = model:Clone() :: Model
	modelClone:ScaleTo(0.2)
	modelClone.PrimaryPart.Anchored = true

	MorphServiceClient:playAnimation(modelClone)

	local effect = Assets.MorphEffectAttachment:Clone()
	effect.Parent = modelClone
	modelClone.Parent = camera

	local offsetInstance = Instance.new("NumberValue")
	offsetInstance.Value = -10

	local function updateModelCFrame()
		modelClone:PivotTo(
			camera.CFrame * CFrame.new(0, offsetInstance.Value, -5) * CFrame.Angles(math.rad(90), math.rad(180), 0)
		)
	end

	local cammConn = RunService.PreRender:Connect(updateModelCFrame)
	updateModelCFrame()

	local popUpTween = TweenService:Create(offsetInstance, popUpInfo, { Value = 0 })
	local popDownTween = TweenService:Create(offsetInstance, popDownInfo, { Value = -10 })

	popUpTween:Play()

	return function()
		popDownTween:Play()
		popDownTween.Completed:Wait()

		popUpTween:Destroy()
		popUpTween = nil
		popDownTween:Destroy()
		popDownTween = nil
		offsetInstance:Destroy()

		cammConn:Disconnect()
		cammConn = nil

		MorphServiceClient:cleanupAnimation(modelClone)
		modelClone:Destroy()
	end
end
