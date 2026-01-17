--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Networker = require(ReplicatedStorage.Packages.Networker)
local CoinServiceUtil = require(ReplicatedStorage.Shared.Services.CoinService.CoinServiceUtil)

type CoinData = CoinServiceUtil.CoinData

local CoinServiceClient = {}

-- Store spawned coin instances: { [coinId]: coin instance }
local spawnedCoins: { [string]: BasePart } = {}

-- Store original positions for breathing animation
local coinBasePositions: { [string]: Vector3 } = {}
local coinBaseSize: Vector3?

local function getCoinsFolder(): Folder
	local coinsFolder = workspace:FindFirstChild(CoinServiceUtil.COINS_FOLDER_NAME)
	if not coinsFolder then
		coinsFolder = Instance.new("Folder")
		coinsFolder.Name = CoinServiceUtil.COINS_FOLDER_NAME
		coinsFolder.Parent = workspace
	end
	return coinsFolder :: Folder
end

local function getCoinTemplate(): BasePart?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		warn("Assets folder not found in ReplicatedStorage")
		return nil
	end

	local coinTemplate = assets:FindFirstChild("Coin")
	if not coinTemplate or not coinTemplate:IsA("BasePart") then
		warn("Coin template not found or is not a BasePart in ReplicatedStorage.Assets")
		return nil
	end

	return coinTemplate :: BasePart
end

local function spawnCoin(coinData: CoinData): BasePart?
	local template = getCoinTemplate()
	if not template then
		return nil
	end

	local coin = template:Clone()
	coin.Name = coinData.id
	coin.Position = coinData.position
	coin.Anchored = true
	coin.CanCollide = false
	coin.Parent = getCoinsFolder()

	-- Store base position and size for breathing animation
	coinBasePositions[coinData.id] = coinData.position
	if not coinBaseSize then
		coinBaseSize = coin.Size
	end

	spawnedCoins[coinData.id] = coin

	return coin
end

local function destroyCoin(coinId: string): ()
	local coin = spawnedCoins[coinId]
	if coin then
		coin:Destroy()
		spawnedCoins[coinId] = nil
		coinBasePositions[coinId] = nil
	end
end

local function setupCoinTouch(coin: BasePart, coinId: string, self: any): ()
	coin.Touched:Connect(function(hit: BasePart)
		local player = Players.LocalPlayer
		local character = player.Character
		if not character then
			return
		end

		-- Check if the touching part belongs to the local player
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid and hit:IsDescendantOf(character) then
			self.networker:fire("CollectCoin", coinId)
		end
	end)
end

function CoinServiceClient.initCoins(self: CoinServiceClient, coins: { CoinData }): ()
	-- Clear any existing coins
	for coinId, _ in spawnedCoins do
		destroyCoin(coinId)
	end

	-- Spawn all coins
	for _, coinData in coins do
		local coin = spawnCoin(coinData)
		if coin then
			setupCoinTouch(coin, coinData.id, self)
		end
	end
end

function CoinServiceClient.onCoinCollected(_self: CoinServiceClient, coinId: string): ()
	destroyCoin(coinId)
end

function CoinServiceClient.init(self: CoinServiceClient): ()
	self.networker = Networker.client.new("Coin", self)

	-- Breathing animation using sin waves
	local startTime = os.clock()
	RunService.Heartbeat:Connect(function(_dt: number)
		local elapsed = os.clock() - startTime
		local breathPhase = math.sin(elapsed * CoinServiceUtil.BREATH_SPEED)

		-- Size oscillation
		local sizeMultiplier = 1 + breathPhase * CoinServiceUtil.BREATH_SIZE_AMPLITUDE

		-- Hover oscillation
		local hoverOffset = breathPhase * CoinServiceUtil.BREATH_HOVER_AMPLITUDE

		for coinId, coin in spawnedCoins do
			if not coin or not coin.Parent then
				continue
			end

			local basePosition = coinBasePositions[coinId]
			if basePosition and coinBaseSize then
				-- Apply breathing effect to position
				coin.Position = basePosition + Vector3.new(0, hoverOffset, 0)

				-- Apply breathing effect to size
				coin.Size = coinBaseSize * sizeMultiplier
			end
		end
	end)
end

type CoinServiceClient = typeof(CoinServiceClient) & {
	networker: Networker.Client,
}

return CoinServiceClient :: CoinServiceClient
