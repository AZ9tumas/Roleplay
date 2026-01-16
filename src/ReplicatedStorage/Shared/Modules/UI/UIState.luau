--!strict
-- UIState module - Central state management for UI
-- Replaces the Charm-based slices from the React UI system

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local Sift = require(ReplicatedStorage.Packages.Sift)

export type UIState = {
	-- Purchase state
	purchasing: boolean,
	setPurchasing: (value: boolean) -> (),
	onPurchasingChanged: Signal.Signal<boolean>,
	
	-- Morph state
	equippedMorph: string?,
	unlockedMorphs: { [string]: any },
	soldMorphs: { [string]: any },
	newMorphs: { string },
	
	setEquippedMorph: (morph: string?) -> (),
	setUnlockedMorphs: (morphs: { [string]: any }) -> (),
	setSoldMorphs: (morphs: { [string]: any }) -> (),
	addNewMorph: (morph: string) -> (),
	removeFirstNewMorph: () -> (),
	
	onEquippedMorphChanged: Signal.Signal<string?>,
	onUnlockedMorphsChanged: Signal.Signal<{ [string]: any }>,
	onSoldMorphsChanged: Signal.Signal<{ [string]: any }>,
	onNewMorphsChanged: Signal.Signal<{ string }>,
}

local UIState = {} :: UIState

-- Purchase state
UIState.purchasing = false
UIState.onPurchasingChanged = Signal.new()

function UIState.setPurchasing(value: boolean)
	UIState.purchasing = value
	UIState.onPurchasingChanged:Fire(value)
end

-- Morph state
UIState.equippedMorph = nil
UIState.unlockedMorphs = {}
UIState.soldMorphs = {}
UIState.newMorphs = {}

UIState.onEquippedMorphChanged = Signal.new()
UIState.onUnlockedMorphsChanged = Signal.new()
UIState.onSoldMorphsChanged = Signal.new()
UIState.onNewMorphsChanged = Signal.new()

function UIState.setEquippedMorph(morph: string?)
	UIState.equippedMorph = morph
	UIState.onEquippedMorphChanged:Fire(morph)
end

function UIState.setUnlockedMorphs(morphs: { [string]: any })
	UIState.unlockedMorphs = morphs
	UIState.onUnlockedMorphsChanged:Fire(morphs)
end

function UIState.setSoldMorphs(morphs: { [string]: any })
	UIState.soldMorphs = table.clone(morphs)
	UIState.onSoldMorphsChanged:Fire(UIState.soldMorphs)
end

function UIState.addNewMorph(morph: string)
	local currentMorphs = table.clone(UIState.newMorphs)
	currentMorphs = Sift.Array.insert(currentMorphs, 1, morph)
	UIState.newMorphs = currentMorphs
	UIState.onNewMorphsChanged:Fire(UIState.newMorphs)
end

function UIState.removeFirstNewMorph()
	local currentMorphs = table.clone(UIState.newMorphs)
	currentMorphs = Sift.Array.removeIndex(currentMorphs, 1)
	UIState.newMorphs = currentMorphs
	UIState.onNewMorphsChanged:Fire(UIState.newMorphs)
end

return UIState
