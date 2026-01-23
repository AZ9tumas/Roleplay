--!strict
-- NotificationServiceClient - Handles smooth animated notifications on the client
-- Provides a clean, professional notification system with slide and fade animations

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Networker = require(ReplicatedStorage.Packages.Networker)

local NotificationServiceClient = {}

-- Animation Constants
local SLIDE_IN_DURATION = 0.4
local DISPLAY_DURATION = 3.0
local FADE_OUT_DURATION = 0.5

local TWEEN_INFO_SLIDE_IN = TweenInfo.new(
	SLIDE_IN_DURATION,
	Enum.EasingStyle.Back,
	Enum.EasingDirection.Out
)

local TWEEN_INFO_FADE_OUT = TweenInfo.new(
	FADE_OUT_DURATION,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

-- State
local notificationFrame: Frame? = nil
local textLabel: TextLabel? = nil
local isAnimating: boolean = false
local notificationQueue: { string } = {}

-- Get the notification UI elements
local function getNotificationUI(): (Frame?, TextLabel?)
	if notificationFrame and textLabel then
		return notificationFrame, textLabel
	end
	
	local player = Players.LocalPlayer
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then
		return nil, nil
	end
	
	local gameGui = playerGui:FindFirstChild("GameGui") :: ScreenGui?
	if not gameGui then
		return nil, nil
	end
	
	local notification = gameGui:FindFirstChild("Notification") :: Frame?
	if not notification then
		return nil, nil
	end
	
	local label = notification:FindFirstChild("TextLabel") :: TextLabel?
	if not label then
		return nil, nil
	end
	
	notificationFrame = notification
	textLabel = label
	
	-- Set initial state (hidden above screen)
	notification.Position = UDim2.new(0.5, 0, -0.15, 0)
	notification.AnchorPoint = Vector2.new(0.5, 0)
	notification.Visible = false
	
	-- Ensure transparency properties are set for animations
	notification.BackgroundTransparency = 0
	label.TextTransparency = 0
	
	return notification, label
end

-- Animate a single notification
local function animateNotification(message: string): ()
	local frame, label = getNotificationUI()
	if not frame or not label then
		warn("NotificationService: UI elements not found")
		return
	end
	
	isAnimating = true
	
	-- Set message text
	label.Text = message
	
	-- Reset to initial state
	frame.Position = UDim2.new(0.5, 0, -0.15, 0)
	frame.BackgroundTransparency = 0
	label.TextTransparency = 0
	
	-- Handle UIStroke if present
	local uiStroke = label:FindFirstChildOfClass("UIStroke")
	if uiStroke then
		uiStroke.Transparency = 0
	end
	
	frame.Visible = true
	
	-- Phase 1: Slide in from top with bounce
	local slideInTween = TweenService:Create(frame, TWEEN_INFO_SLIDE_IN, {
		Position = UDim2.new(0.5, 0, 0.08, 0)
	})
	slideInTween:Play()
	slideInTween.Completed:Wait()
	
	-- Phase 2: Hold for display duration
	task.wait(DISPLAY_DURATION)
	
	-- Phase 3: Fade out smoothly
	local fadeOutFrame = TweenService:Create(frame, TWEEN_INFO_FADE_OUT, {
		BackgroundTransparency = 1
	})
	local fadeOutText = TweenService:Create(label, TWEEN_INFO_FADE_OUT, {
		TextTransparency = 1
	})
	
	fadeOutFrame:Play()
	fadeOutText:Play()
	
	if uiStroke then
		local fadeOutStroke = TweenService:Create(uiStroke, TWEEN_INFO_FADE_OUT, {
			Transparency = 1
		})
		fadeOutStroke:Play()
	end
	
	fadeOutFrame.Completed:Wait()
	
	-- Hide and reset
	frame.Visible = false
	frame.Position = UDim2.new(0.5, 0, -0.15, 0)
	frame.BackgroundTransparency = 0
	label.TextTransparency = 0
	if uiStroke then
		uiStroke.Transparency = 0
	end
	
	isAnimating = false
	
	-- Process next notification in queue
	if #notificationQueue > 0 then
		local nextMessage = table.remove(notificationQueue, 1)
		if nextMessage then
			task.spawn(animateNotification, nextMessage)
		end
	end
end

-- Show a notification (queues if one is already showing)
function NotificationServiceClient.showNotification(_self: NotificationServiceClient, message: string): ()
	if isAnimating then
		table.insert(notificationQueue, message)
	else
		task.spawn(animateNotification, message)
	end
end

-- Called by server via Networker
function NotificationServiceClient.onNotification(self: NotificationServiceClient, message: string): ()
	self:showNotification(message)
end

-- Initialize the service
function NotificationServiceClient.init(self: NotificationServiceClient): ()
	self.networker = Networker.client.new("Notification", self)
	
	-- Pre-initialize UI references
	getNotificationUI()
end

type NotificationServiceClient = typeof(NotificationServiceClient) & {
	networker: Networker.Client,
}

return NotificationServiceClient :: NotificationServiceClient
