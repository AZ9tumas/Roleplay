--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local DataService = require(ReplicatedStorage.Packages.DataService).server
local CoinServiceUtil = require(ReplicatedStorage.Shared.Services.CoinService.CoinServiceUtil)

type CoinData = CoinServiceUtil.CoinData

local CoinServiceServer = {}

-- Store coin data per player: { [Player]: { [coinId]: position } }
local playerCoinData: { [Player]: { [string]: Vector3 } } = {}

local function getCoinPathParts(): { BasePart }
	local coinPathFolder = workspace:FindFirstChild(CoinServiceUtil.COIN_PATH_FOLDER_NAME)
	if not coinPathFolder then
		warn("CoinPath folder not found in workspace")
		return {}
	end

	local parts: { BasePart } = {}
	for _, child in coinPathFolder:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end

	return parts
end

local function createLeaderstats(player: Player): ()
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = 0
	coinsValue.Parent = leaderstats

	-- Wait for player data and update leaderstats
	task.spawn(function()
		local playerData = DataService:waitForData(player)
		if playerData then
			local coins = playerData:get({ "coins" }) or 0
			coinsValue.Value = coins
		end
	end)
end

local function updateLeaderstats(player: Player, coins: number): ()
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins") :: IntValue?
		if coinsValue then
			coinsValue.Value = coins
		end
	end
end

function CoinServiceServer.GenerateCoinPositions(_self: CoinServiceServer, player: Player): { CoinData }
	local coinPathParts = getCoinPathParts()
	local coins: { CoinData } = {}

	-- Clear existing coin data for this player
	playerCoinData[player] = {}

	for _, part in coinPathParts do
		local coinId = HttpService:GenerateGUID(false)
		local coinPosition = part.Position + Vector3.new(0, CoinServiceUtil.HOVER_OFFSET, 0)

		playerCoinData[player][coinId] = coinPosition

		table.insert(coins, {
			id = coinId,
			position = coinPosition,
		})
	end

	return coins
end

function CoinServiceServer.CollectCoin(self: CoinServiceServer, player: Player, coinId: string): boolean
	-- Validate that the coin exists for this player
	local playerCoins = playerCoinData[player]
	if not playerCoins then
		return false
	end

	local coinPosition = playerCoins[coinId]
	if not coinPosition then
		return false
	end

	-- Validate player distance to coin
	local character = player.Character
	if not character then
		return false
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoidRootPart then
		return false
	end

	local distance = (humanoidRootPart.Position - coinPosition).Magnitude
	if distance > CoinServiceUtil.COLLECT_DISTANCE then
		return false
	end

	-- Remove coin from player's data (coin collected)
	playerCoins[coinId] = nil

	-- Add coin to player's data
	local currentCoins = DataService:get(player, { "coins" }) or 0
	local newCoins = currentCoins + 1
	DataService:set(player, { "coins" }, newCoins)
	updateLeaderstats(player, newCoins)

	-- Notify client that coin was collected
	self.networker:fire(player, "onCoinCollected", coinId)

	return true
end

function CoinServiceServer.GetPlayerCoins(_self: CoinServiceServer, player: Player): number
	return DataService:get(player, { "coins" }) or 0
end

function CoinServiceServer.init(self: CoinServiceServer): ()
	self.networker = Networker.server.new("Coin", self, {
		self.CollectCoin :: any,
		self.GetPlayerCoins :: any,
	})

	local function initPlayer(player: Player)
		createLeaderstats(player)
		local coins = self:GenerateCoinPositions(player)
		self.networker:fire(player, "initCoins", coins)
	end

	Players.PlayerAdded:Connect(initPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(initPlayer, player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		playerCoinData[player] = nil
	end)
end

type CoinServiceServer = typeof(CoinServiceServer) & {
	networker: Networker.Server,
}

return CoinServiceServer :: CoinServiceServer
