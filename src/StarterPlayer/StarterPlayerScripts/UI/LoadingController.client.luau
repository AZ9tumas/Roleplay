--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DataService = require(ReplicatedStorage.Packages.DataService).client

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gameGui = playerGui:WaitForChild("GameGui")
local loadingFrame = gameGui:WaitForChild("LoadingFrame")

-- Ensure it's visible immediately
loadingFrame.Visible = true
-- Ensure transparency is 0 initially (in case it was left hidden)
if loadingFrame:IsA("GuiObject") then
	loadingFrame.BackgroundTransparency = 0
end

print("LoadingController: Waiting for data...")

-- Yields until data is initialized
-- DataService.init() in Client.client.luau triggers the process, this call waits for it to complete.
DataService:get(nil)

print("LoadingController: Data initialized, hiding loading screen...")

local TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Helper to recursively tween transparency
local function fadeOut(object: Instance)
	if object:IsA("GuiObject") then
		local properties = {}
		
		-- Background
		properties.BackgroundTransparency = 1
		
		-- Image
		if object:IsA("ImageLabel") or object:IsA("ImageButton") then
			properties.ImageTransparency = 1
		end
		
		-- Text
		if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
			properties.TextTransparency = 1
			properties.TextStrokeTransparency = 1
		end
		
		-- UIStroke
		if object:IsA("UIStroke") then
			properties.Transparency = 1
		end
		
		TweenService:Create(object, TWEEN_INFO, properties):Play()
	end
	
	for _, child in object:GetChildren() do
		fadeOut(child)
	end
end

-- Start fade out
fadeOut(loadingFrame)

-- Disable after fade
task.delay(0.5, function()
	loadingFrame.Visible = false
	print("LoadingController: Loading screen hidden")
end)
