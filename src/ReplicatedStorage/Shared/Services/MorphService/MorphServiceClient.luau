local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local DataService = require(ReplicatedStorage.Packages.DataService).client
local Networker = require(ReplicatedStorage.Packages.Networker)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Morphs = require(ReplicatedStorage.Shared.Modules.Game.Morphs)
local morphSlice = require(ReplicatedStorage.UI.features.morph.state.morphSlice)
local purchaseSlice = require(ReplicatedStorage.UI.features.shop.state.purchaseSlice)
local MORPH_TAG = "Morph"

local MorphServiceClient = {}
MorphServiceClient._loadedAnimations = {}

local function bindTag(tag: string, addCallback, removeCallback)
	for _, instance: any in CollectionService:GetTagged(tag) do
		addCallback(instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(addCallback)
	if removeCallback then
		CollectionService:GetInstanceRemovedSignal(tag):Connect(removeCallback)
	end
end

function MorphServiceClient._loadAnimation(self: MorphServiceClient, morph: Model): AnimationTrack?
	local morphData = Morphs[morph.Name]
	if not morphData then
		warn(`No morph data found for {morph.Name}`)
		return
	end

	local humanoid = morph:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("No Humanoid found in character")
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = morphData.animations.idle
	local track = animator:LoadAnimation(animation)
	self._loadedAnimations[morph] = track
	return track
end

function MorphServiceClient.playAnimation(self: MorphServiceClient, morph: Model): ()
	local track = self:_loadAnimation(morph)
	if track then
		track:Play()
	end
end

function MorphServiceClient.cleanupAnimation(self: MorphServiceClient, morph: Model): ()
	if self._loadedAnimations[morph] then
		self._loadedAnimations[morph]:Stop()
		self._loadedAnimations[morph]:Destroy()
		self._loadedAnimations[morph] = nil
	end
end

function MorphServiceClient.equipMorph(self: MorphServiceClient, morph: string): ()
	self.networker:fire("equipMorph", morph)
end

function MorphServiceClient.unequipMorph(self: MorphServiceClient): ()
	self.networker:fire("unequipMorph")
end

function MorphServiceClient.purchaseMorph(self: MorphServiceClient, morph: string): ()
	purchaseSlice.actions.setPurchase(true)
	self.networker:fire("purchaseMorph", morph)
end

function MorphServiceClient._initData(self: MorphServiceClient, data): ()
	self.morphData = data

	morphSlice.actions.setSoldMorph(self.morphData)
end

function MorphServiceClient._setData(self: MorphServiceClient, key, value): ()
	if not self.morphData then
		self.morphData = {}
	end

	self.morphData[key] = value
	morphSlice.actions.setSoldMorph(self.morphData)
end

function MorphServiceClient.init(self: MorphServiceClient)
	self.networker = Networker.client.new("Morph", self)

	bindTag(MORPH_TAG, function(morph: Model)
		self:playAnimation(morph)
	end, function(morph: Model)
		self:cleanupAnimation(morph)
	end)

	DataService:getIndexChangedSignal({ "unlockedMorph" }):Connect(function(index, _newValue)
		morphSlice.actions.addUnlockedMorph(DataService:get({ "unlockedMorph" }))
		morphSlice.actions.setNewMorph(index)
	end)

	DataService:getChangedSignal({ "equippedMorph" }):Connect(function(value: string)
		morphSlice.actions.setEquippedMorph(value)
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, gp: boolean)
		if gp then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			morphSlice.actions.setNewMorph()
		end
	end)
end

type MorphServiceClient = typeof(MorphServiceClient) & {
	networker: Networker.Client,
	morphData: {},
}

return MorphServiceClient :: MorphServiceClient
