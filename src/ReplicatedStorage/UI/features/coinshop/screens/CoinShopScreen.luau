local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactCharm = require(ReplicatedStorage.Packages.ReactCharm)
local DataService = require(ReplicatedStorage.Packages.DataService).client
local CoinMorphs = require(ReplicatedStorage.Shared.Modules.Game.CoinMorphs)
local Menu = require(ReplicatedStorage.UI.core.components.Menu)
local TextLabel = require(ReplicatedStorage.UI.core.components.TextLabel)
local CoinMorphContainer = require(ReplicatedStorage.UI.features.coinshop.components.CoinMorphContainer)
local MorphServiceClient = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceClient)

local e = React.createElement

local function LongList()
	return e("UIListLayout", {
		Padding = UDim.new(0, 20),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})
end

type SectionProps = {
	name: string,
	children: React.ReactNode?,
}

local function Section(props: SectionProps)
	return e("Frame", {
		Size = UDim2.fromOffset(200, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, {
		UIListLayout = e("UIListLayout", {
			Padding = UDim.new(0, 20),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
		}),

		TextLabel = e(TextLabel, {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			Text = props.name,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 70,
			Font = Enum.Font.SourceSansBold,
		}),

		Content = e("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
		}, props.children),
	})
end

return function()
	local unlockedMorphs, setUnlockedMorphs = React.useState({})
	local playerCoins, setPlayerCoins = React.useState(0)

	React.useEffect(function()
		-- Get initial unlocked morphs
		local data = DataService:get({ "unlockedMorph" })
		if data then
			setUnlockedMorphs(data)
		end

		-- Get initial coins
		local coins = DataService:get({ "coins" })
		if coins then
			setPlayerCoins(coins)
		end

		-- Listen for changes
		local unlockedConnection = DataService:getIndexChangedSignal({ "unlockedMorph" }):Connect(function()
			local newData = DataService:get({ "unlockedMorph" })
			if newData then
				setUnlockedMorphs(newData)
			end
		end)

		local coinsConnection = DataService:getChangedSignal({ "coins" }):Connect(function(newCoins)
			setPlayerCoins(newCoins or 0)
		end)

		return function()
			unlockedConnection:Disconnect()
			coinsConnection:Disconnect()
		end
	end, {})

	local templates = {}
	local layoutOrder = 0
	for morphName, morphData in CoinMorphs do
		layoutOrder = layoutOrder + 1
		local isUnlocked = unlockedMorphs[morphName] ~= nil

		templates[morphName] = e(CoinMorphContainer, {
			morphName = morphName,
			displayName = morphData.displayName,
			cost = morphData.cost,
			isUnlocked = isUnlocked,
			onPurchase = function()
				MorphServiceClient:purchaseCoinMorph(morphName)
			end,
		})
	end

	templates.Grid = e(LongList)

	return e(Menu.component, {
		id = "CoinShop",
	}, {
		CoinsDisplay = e("Frame", {
			Size = UDim2.fromOffset(200, 50),
			Position = UDim2.fromScale(0.5, 0.08),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 200, 50),
		}, {
			UICorner = e("UICorner", {
				CornerRadius = UDim.new(0, 15),
			}),
			CoinsLabel = e(TextLabel, {
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Text = "Coins: " .. tostring(playerCoins),
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.SourceSansBold,
				TextSize = 28,
				Stroke = 2,
				StrokeColor = Color3.fromRGB(100, 70, 0),
			}),
		}),

		ShopList = e("ScrollingFrame", {
			Size = UDim2.fromScale(0.99, 0.75),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.58),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 5,
			CanvasSize = UDim2.fromOffset(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, {
			UIListLayout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),

			Morphs = e(Section, {
				name = "Morphs",
			}, templates),
		}),
	})
end
