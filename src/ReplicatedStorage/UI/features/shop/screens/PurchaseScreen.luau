local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local React = require(ReplicatedStorage.Packages.React)
local ReactCharm = require(ReplicatedStorage.Packages.ReactCharm)
local ImageIds = require(ReplicatedStorage.Shared.Modules.Game.ImageIds)
local useSpring = require(ReplicatedStorage.UI.core.hooks.useSpring)
local purchaseSlice = require(ReplicatedStorage.UI.features.shop.state.purchaseSlice)

local e = React.createElement

local SHOWN_TRANSPARENCY = 0
local HIDE_TRANSPARENCY = 1

return function()
	local shown = ReactCharm.useAtom(purchaseSlice.states.purchasing)

	local rotation, setRotation = React.useBinding(0)
	local mounted, setMounted = React.useState(shown)

	local transparencySpring = useSpring(shown and HIDE_TRANSPARENCY or SHOWN_TRANSPARENCY, {
		frequency = 0.5,
		damping = 0.8,
	})

	React.useEffect(function()
		if shown then
			return
		end

		transparencySpring.setGoal(HIDE_TRANSPARENCY)
		local conn = transparencySpring.onComplete(function()
			if not shown then
				setMounted(false)
			end
		end)

		return conn
	end, { shown })

	React.useEffect(function()
		if not shown then
			return
		end

		if not mounted then
			setMounted(true)
			return
		end

		transparencySpring.setGoal(SHOWN_TRANSPARENCY)
	end, { shown, mounted })

	React.useEffect(function()
		if not shown then
			return
		end

		local conn = RunService.PreRender:Connect(function(dt: number)
			setRotation(rotation:getValue() + (60 * dt))
		end)

		return function()
			conn:Disconnect()
		end
	end, { shown })

	if not mounted then
		return nil
	end

	return e("CanvasGroup", {
		GroupTransparency = transparencySpring.binding,
		BackgroundTransparency = 0.5,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 30,
	}, {
		Loading = e("ImageLabel", {
			Size = UDim2.fromScale(0.2, 0.2),
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = rotation:map(function(value: number)
				return value
			end),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Image = ImageIds.load,
			ScaleType = "Fit",
			BackgroundTransparency = 1,
		}),
	})
end
