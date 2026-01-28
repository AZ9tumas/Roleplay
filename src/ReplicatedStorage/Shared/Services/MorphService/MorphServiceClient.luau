local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService).client
local Networker = require(ReplicatedStorage.Packages.Networker)
local Morphs = require(ReplicatedStorage.Shared.Modules.Game.Morphs)
local MORPH_TAG = "Morph"

local MorphServiceClient = {}
MorphServiceClient._loadedAnimations = {}
MorphServiceClient._connections = {}

local function bindTag(tag: string, addCallback, removeCallback)
	for _, instance: any in CollectionService:GetTagged(tag) do
		addCallback(instance)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(addCallback)
	if removeCallback then
		CollectionService:GetInstanceRemovedSignal(tag):Connect(removeCallback)
	end
end

function MorphServiceClient.setupAnimationController(self: MorphServiceClient, morph: Model): ()
	print(morph.Name)
	local morphName = morph:GetAttribute("MorphName")
	
	-- Fallback to model name if attribute is missing
	-- (Should not happen with updated server code, but good for safety)
	if not morphName then
		morphName = morph.Name
	end
	
	local morphData = Morphs[morphName]
	
	if not morphData or not morphData.animations then
		warn(`No morph data found for {morphName}`)
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

	local tracks = {}
	for name, id in pairs(morphData.animations) do
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local track = animator:LoadAnimation(animation)

		if name == "idle" or name == "walk" or name == "run" then
			track.Looped = true
		else
			track.Looped = false
		end

		tracks[name] = track
	end

	self._loadedAnimations[morph] = tracks
	self._connections[morph] = {}

	local function play(animName, fadeTime)
		local track = tracks[animName]
		-- Fallback to walk if run is missing, or walk if run is missing
		if not track then
			if animName == "run" then track = tracks["walk"] end
		end
		
		if not track then return end

		-- If it's already playing, we're good
		if track.IsPlaying then return end

		print(`[MorphService] Playing animation: {animName} for {morph.Name}`)

		-- Stop all other tracks from *this* morph system
		for name, t in pairs(tracks) do
			if name ~= animName and t.IsPlaying then
				t:Stop(fadeTime)
			end
		end
		track:Play(fadeTime)
	end
	
	-- State Management
	local function update()
		local moveDirection = humanoid.MoveDirection
		local isMoving = moveDirection.Magnitude > 0.1
		
		if isMoving then
			local speed = (humanoid.RootPart and humanoid.RootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude or 0
			-- Only use run if we're moving fairly fast, otherwise default to walk
			if tracks.run and speed > 12 then
				play("run", 0.2)
			else
				play("walk", 0.2)
			end
		else
			play("idle", 0.2)
		end
	end

	table.insert(self._connections[morph], humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(update))
	table.insert(self._connections[morph], humanoid.Running:Connect(function(speed)
		update()
	end))
	
	-- Initial update
	update()
end

function MorphServiceClient.cleanupAnimation(self: MorphServiceClient, morph: Model): ()
	if self._connections[morph] then
		for _, conn in self._connections[morph] do
			conn:Disconnect()
		end
		self._connections[morph] = nil
	end

	if self._loadedAnimations[morph] then
		for _, track in pairs(self._loadedAnimations[morph]) do
			track:Stop()
			track:Destroy()
		end
		self._loadedAnimations[morph] = nil
	end
end

function MorphServiceClient.equipMorph(self: MorphServiceClient, morph: string): ()
	print("[MorphService] Sending equip request for:", morph)
	self.networker:fire("equipMorph", morph)
end

function MorphServiceClient.unequipMorph(self: MorphServiceClient): ()
	self.networker:fire("unequipMorph")
end

function MorphServiceClient.purchaseMorph(self: MorphServiceClient, morph: string): ()
	self.networker:fire("purchaseMorph", morph)
end

function MorphServiceClient.purchaseCoinMorph(self: MorphServiceClient, morphName: string): ()
	self.networker:fire("purchaseCoinMorph", morphName)
end

function MorphServiceClient.onCoinMorphPurchased(_self: MorphServiceClient, morphName: string): ()
	-- Morph was successfully purchased with coins - DataService will handle the update
	print("Purchased coin morph: " .. morphName)
end

function MorphServiceClient._initData(self: MorphServiceClient, data): ()
	self.morphData = data
end

function MorphServiceClient._setData(self: MorphServiceClient, key, value): ()
	if not self.morphData then
		self.morphData = {}
	end

	self.morphData[key] = value
end

function MorphServiceClient.init(self: MorphServiceClient)
	self.networker = Networker.client.new("Morph", self)

	bindTag(MORPH_TAG, function(morph: Model)
		print("[MorphService] Morph model detected on client:", morph.Name)
		self:setupAnimationController(morph)
	end, function(morph: Model)
		print("[MorphService] Morph model removed from client:", morph.Name)
		self:cleanupAnimation(morph)
	end)
end

type MorphServiceClient = typeof(MorphServiceClient) & {
	networker: Networker.Client,
	morphData: {},
}

return MorphServiceClient :: MorphServiceClient
