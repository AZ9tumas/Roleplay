local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local RootGui = require(script.app.RootGui)

local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local e = React.createElement

local handle = Instance.new("ScreenGui")
handle.Name = "GameGui"
handle.IgnoreGuiInset = true
handle.ResetOnSpawn = false
handle.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
handle.Parent = Players.LocalPlayer.PlayerGui

return function()
	local root = ReactRoblox.createRoot(handle)
	root:render(RootGui) -- Wrap it in createElement
end
