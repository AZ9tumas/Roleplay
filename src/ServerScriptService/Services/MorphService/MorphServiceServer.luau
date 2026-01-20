--!strict

local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataService = require(ReplicatedStorage.Packages.DataService).server
local Networker = require(ReplicatedStorage.Packages.Networker)
local Morphs = require(ReplicatedStorage.Shared.Modules.Game.Morphs)
local Products = require(ReplicatedStorage.Shared.Modules.Game.Products)
local MorphServiceUtil = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceUtil)

local MORPH_UNLOCKER_TAG = "MorphUnlocker"
local SOLD_MORPH_DATASTORE_NAME = "SoldMorphDataTest7"

local soldMorphStore = DataStoreService:GetDataStore(SOLD_MORPH_DATASTORE_NAME)

type MORPH_DATA_TEMPLATE = MorphServiceUtil.MORPH_DATA_TEMPLATE

local MorphServiceServer = {}
MorphServiceServer.morphPurchaseCache = {}
local morphDataCache: { [string]: any } = {}
local sentDataTo: { [Player]: boolean } = {}

function MorphServiceServer.morph(_self: MorphServiceServer, player: Player, morph: string): ()
	local morphData = Morphs[morph]
	if not morphData then
		return
	end

	local morphModel = ServerStorage.Morphs:FindFirstChild(morph)
	if not morphModel then
		return
	end

	--> Validate current character
	local cachedCharacter = player.Character
	if not cachedCharacter then
		return
	end

	local oldhumanoid = cachedCharacter:FindFirstChild("Humanoid") :: Humanoid
	local oldhumanoidRootPart = cachedCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
	if not oldhumanoid or not oldhumanoidRootPart then
		return
	end

	local cachedCFrame = oldhumanoidRootPart.CFrame

	--> Character Setup
	local newCharacter = morphModel:Clone()
	local humanoidRootPart = newCharacter.PrimaryPart :: BasePart
	local humanoid = newCharacter:FindFirstChild("Humanoid") :: Humanoid
	newCharacter.Name = player.Name

	if not humanoidRootPart or not humanoid then
		warn("Primary part is missing from morph:", morph)
		return newCharacter:Destroy()
	end

	local animateScript = ReplicatedStorage.Assets.Animate:Clone()
	animateScript.Parent = newCharacter
	animateScript.Enabled = true
	for state: any, animationId: any in morphData.animations do
		local stringValue = Instance.new("StringValue")
		stringValue.Name = state
		stringValue.Parent = animateScript
		local animation = Instance.new("Animation")
		animation.AnimationId = animationId
		animation.Name = "Animation1"
		animation.Parent = stringValue
	end

	oldhumanoid.AutoJumpEnabled = false

	player.Character = newCharacter
	newCharacter.Parent = workspace
	humanoidRootPart.CFrame = cachedCFrame
	humanoid.JumpPower = 0

	--> Character cleanup
	task.wait()
	if cachedCharacter:HasTag("MorphModel") then
		cachedCharacter:Destroy()
	else
		local cachedCharacterObject = player:FindFirstChild("CachedCharacter") :: ObjectValue
		if cachedCharacterObject then
			cachedCharacter.Parent = ReplicatedStorage.CachedCharacters
			cachedCharacterObject.Value = cachedCharacter
		end
	end
end

function MorphServiceServer.unmorph(_self: MorphServiceServer, player: Player): ()
	local cachedCharacterObject = player:FindFirstChild("CachedCharacter") :: ObjectValue
	if not cachedCharacterObject or not cachedCharacterObject.Value then
		return
	end

	local cachedCharacter = player.Character
	if not cachedCharacter then
		return
	end

	local oldhumanoidRootPart = cachedCharacter:FindFirstChild("HumanoidRootPart") :: BasePart
	if not oldhumanoidRootPart then
		return
	end

	local cachedCFrame = oldhumanoidRootPart.CFrame

	local newCharacter = cachedCharacterObject.Value :: Model
	local humanoidRootPart = newCharacter.PrimaryPart
	local humanoid = newCharacter:FindFirstChild("Humanoid") :: Humanoid

	if not humanoidRootPart or not humanoid then
		return newCharacter:Destroy()
	end

	player.Character = newCharacter
	newCharacter.Parent = workspace
	humanoidRootPart.CFrame = cachedCFrame
end

function MorphServiceServer.equipMorph(self: MorphServiceServer, player, morph)
	if not morph then
		return
	end

	local morphModel = ServerStorage.Morphs:FindFirstChild(morph)
	if not morphModel then
		return
	end

	DataService:set(player, { "equippedMorph" }, morph)
	self:morph(player, morph)
end

function MorphServiceServer.unequipMorph(self: MorphServiceServer, player)
	DataService:set(player, { "equippedMorph" }, nil)
	self:unmorph(player)
end

function MorphServiceServer.addToData(_self: MorphServiceServer, player: Player, morph: string)
	local morphData = Morphs[morph]
	if not morphData then
		return
	end

	local data = DataService:get(player, { "unlockedMorph" })
	local foundInData = data[morph]
	if foundInData then
		return
	end

	local morphTemplate = {
		obtainTime = os.time(),
	} :: MORPH_DATA_TEMPLATE

	DataService:set(player, { "unlockedMorph", morph }, morphTemplate)
end

function MorphServiceServer.buyLimitedAmountMorph(self, morph, receiptInfo, player)
	print("Buying")
	local config = Products.getById(receiptInfo.ProductId)
	if not config then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	print("Sold")
	local success, newValue = pcall(function()
		return soldMorphStore:UpdateAsync(morph, function(current): number?
			local limit = config.limitedAmount or 0
			local currentValue = current or 0

			-- Changed: <= instead of
			if currentValue < limit then
				return currentValue + 1
			end

			return nil -- Return nil to indicate sold out
		end)
	end)

	print(newValue)

	-- Check for sold out condition explicitly
	if not success or newValue == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	self:_setData(morph, newValue, player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MorphServiceServer.buyLimitedTimeMorph(_self: MorphServiceServer, morph: string, receiptInfo, player)
	local config = Products.getById(receiptInfo.ProductId)
	if not config then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if not config.limitedTime then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local startTime = morphDataCache[morph]
	if startTime == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local timeLimit = config.limitedTime
	if os.time() - startTime < timeLimit then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MorphServiceServer.purchaseMorph(self: MorphServiceServer, player: Player, morph: string): ()
	if not Morphs[morph] then
		return
	end

	self.morphPurchaseCache[player] = morph

	-- Check if this morph has its own product (like LimitedMorphTest)
	local morphProduct = Products.ids[morph]
	if morphProduct then
		-- Use morph-specific product
		MarketplaceService:PromptProductPurchase(player, morphProduct.productId)
	else
		-- Use generic UnlockMorph product
		MarketplaceService:PromptProductPurchase(player, Products.getProductId("UnlockMorph"))
	end
end

function MorphServiceServer.purchaseCoinMorph(self: MorphServiceServer, player: Player, morphName: string): boolean
	local CoinMorphs = require(ReplicatedStorage.Shared.Modules.Game.CoinMorphs)
	local morphData = CoinMorphs[morphName]
	if not morphData then
		return false
	end

	-- Validate morph exists in main Morphs table
	if not Morphs[morphName] then
		return false
	end

	local currentCoins = DataService:get(player, { "coins" }) or 0
	if currentCoins < morphData.cost then
		return false
	end

	-- Check if already unlocked
	local unlockedMorphs = DataService:get(player, { "unlockedMorph" }) or {}
	if unlockedMorphs[morphName] then
		return false
	end

	-- Deduct coins and save to datastore
	local newCoins = currentCoins - morphData.cost
	DataService:set(player, { "coins" }, newCoins)

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coinsValue = leaderstats:FindFirstChild("Coins") :: IntValue?
		if coinsValue then
			coinsValue.Value = newCoins
		end
	end

	-- Unlock morph (saved to datastore via DataService)
	DataService:set(player, { "unlockedMorph", morphName }, {
		obtainTime = os.time(),
	})

	-- Notify client
	self.networker:fire(player, "onCoinMorphPurchased", morphName)

	return true
end

function MorphServiceServer._setupUnlocker(self: MorphServiceServer, unlocker: BasePart): ()
	local morph = unlocker:GetAttribute("Morph") :: string
	if not morph then
		return
	end

	local proximityPrompt = Instance.new("ProximityPrompt")
	proximityPrompt.RequiresLineOfSight = false
	proximityPrompt.MaxActivationDistance = MorphServiceUtil.PROMPT_DISTANCE
	proximityPrompt.Parent = unlocker
	proximityPrompt.Triggered:Connect(function(player: Player)
		self:addToData(player, morph)
	end)
end

function MorphServiceServer._setData(self: MorphServiceServer, key: string, value: any, player: Player?)
	-- Check if value hasn't changed (optional optimization)
	local currentData = morphDataCache[key]
	if currentData and currentData == value then
		return
	end

	-- Ensure player has been initialized
	if player and not sentDataTo[player] then
		self:_initData(player)
	end

	-- Update cache
	morphDataCache[key] = value

	-- Broadcast to all clients
	self.networker:fireAll("_setData", key, value)
end

function MorphServiceServer._initData(self: MorphServiceServer, player)
	if sentDataTo[player] then
		return
	end

	if not next(morphDataCache) then
		return
	end

	print(morphDataCache)

	self.networker:fire(player, "_initData", morphDataCache)
	sentDataTo[player] = true
end

function MorphServiceServer.init(self: MorphServiceServer, resetData: boolean?): ()
	self.networker = Networker.server.new("Morph", self, {
		self.addToData :: any,
		self.equipMorph,
		self.unequipMorph,
		self.purchaseMorph,
		self.purchaseCoinMorph,
	})

	for _, unlocker in CollectionService:GetTagged(MORPH_UNLOCKER_TAG) do
		self:_setupUnlocker(unlocker)
	end

	local function _initPlayer(player: Player)
		local cachedCharacter = Instance.new("ObjectValue")
		cachedCharacter.Name = "CachedCharacter"
		cachedCharacter.Parent = player

		self:_initData(player)
	end

	for key, data in Products.ids do
		if data.type == "DevProduct" and (data.limitedAmount or data.limitedTime) then
			local initialValue = data.limitedAmount and 0 or os.time()
			--> Initialize MemoryStore entries
			local success, value = pcall(function()
				return soldMorphStore:GetAsync(key)
			end)

			if success then
				if value == nil then
					pcall(function()
						soldMorphStore:SetAsync(key, initialValue)
					end)
				else
					if resetData then
						pcall(function()
							soldMorphStore:SetAsync(key, initialValue)
						end)
						value = initialValue
					end
					-- cache any existing value (0, timestamp, or "SoldOut")
					morphDataCache[key] = value
				end
			else
				warn("GetAsync failed for key:", key)
			end
		end
	end

	Players.PlayerAdded:Connect(_initPlayer)
	for _, player in Players:GetPlayers() do
		_initPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		local cachedCharacter = ReplicatedStorage.CachedCharacters:FindFirstChild(player.Name)
		if cachedCharacter then
			cachedCharacter:Destroy()
		end

		if sentDataTo[player] then
			sentDataTo[player] = nil
		end
	end)

	task.spawn(function()
		while true do
			task.wait(5)

			for key, data in Products.ids do
				if data.type == "DevProduct" then
					if data.limitedTime then
						local startTime = morphDataCache[key]
						if startTime then
							if os.time() - startTime >= data.limitedTime then
								print("Sold out")
							end
						end
					else
						local limit = data.limitedAmount
						if morphDataCache[key] and morphDataCache[key] > limit then
							print("Stock finished")
						end
					end
				end
			end
		end
	end)
end

type MorphServiceServer = typeof(MorphServiceServer) & {
	networker: Networker.Server,
	morphPurchaseCache: { [Player]: string },
}

return MorphServiceServer :: MorphServiceServer
