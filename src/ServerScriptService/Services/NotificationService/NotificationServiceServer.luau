--!strict
-- NotificationServiceServer - Server-side notification service
-- Provides SendNotification(player, message) API for server scripts to notify players

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)

local NotificationServiceServer = {}

-- Send a notification to a specific player
-- Usage: NotificationServiceServer:SendNotification(player, "Your message here")
function NotificationServiceServer.SendNotification(self: NotificationServiceServer, player: Player, message: string): ()
	if not player or not player:IsDescendantOf(Players) then
		warn("NotificationService: Invalid player provided")
		return
	end
	
	if not message or message == "" then
		warn("NotificationService: Empty message provided")
		return
	end
	
	self.networker:fire(player, "onNotification", message)
end

-- Send a notification to all players
function NotificationServiceServer.SendNotificationToAll(self: NotificationServiceServer, message: string): ()
	if not message or message == "" then
		warn("NotificationService: Empty message provided")
		return
	end
	
	for _, player in Players:GetPlayers() do
		self.networker:fire(player, "onNotification", message)
	end
end

-- Initialize the service
function NotificationServiceServer.init(self: NotificationServiceServer): ()
	self.networker = Networker.server.new("Notification", self, {})
end

type NotificationServiceServer = typeof(NotificationServiceServer) & {
	networker: Networker.Server,
}

return NotificationServiceServer :: NotificationServiceServer
