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
	print(self, player, message)
	if not player or not player:IsDescendantOf(Players) then
		warn("NotificationService: Invalid player provided")
		return
	end
	
	if not message or message == "" then
		warn("NotificationService: Empty message provided")
		return
	end
	
	if not self.networker then
		warn("NotificationService: Networker not initialized. Initializing now...")
		self:init()
	end
	
	if self.networker then
		self.networker:fire(player, "onNotification", message)
	end
end

-- Send a notification to all players
function NotificationServiceServer.SendNotificationToAll(self: NotificationServiceServer, message: string): ()
	if not message or message == "" then
		warn("NotificationService: Empty message provided")
		return
	end
	
	if not self.networker then
		warn("NotificationService: Networker not initialized. Initializing now...")
		self:init()
	end
	
	if self.networker then
		for _, player in Players:GetPlayers() do
			self.networker:fire(player, "onNotification", message)
		end
	end
end

-- Initialize the service
function NotificationServiceServer.init(self: NotificationServiceServer): ()
	if self.networker then return end
	self.networker = Networker.server.new("Notification", self, {})
end

type NotificationServiceServer = typeof(NotificationServiceServer) & {
	networker: Networker.Server,
}

return NotificationServiceServer :: NotificationServiceServer
