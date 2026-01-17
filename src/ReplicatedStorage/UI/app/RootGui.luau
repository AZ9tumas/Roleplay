local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local LeftBar = require(ReplicatedStorage.UI.features.hud.screens.LeftBar)
local MorphScreen = require(ReplicatedStorage.UI.features.morph.screens.MorphScreen)
local NewMorph = require(ReplicatedStorage.UI.features.morph.screens.NewMorph)
local PurchaseScreen = require(ReplicatedStorage.UI.features.shop.screens.PurchaseScreen)
local ShopScreen = require(ReplicatedStorage.UI.features.shop.screens.ShopScreen)
local CoinShopScreen = require(ReplicatedStorage.UI.features.coinshop.screens.CoinShopScreen)

local e = React.createElement

return e(React.Fragment, nil, {
	LeftBar = e(LeftBar),
	Morph = e(MorphScreen),
	Shop = e(ShopScreen),
	CoinShop = e(CoinShopScreen),
	PurchaseScreen = e(PurchaseScreen),
	NewMorph = e(NewMorph),
})
