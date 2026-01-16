--!strict
-- MorphScreenController module for the Morph screen
-- Replaces the React-based MorphScreen component

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(ReplicatedStorage.Packages.DataService).client
local Morphs = require(ReplicatedStorage.Shared.Modules.Game.Morphs)
local ImageIds = require(ReplicatedStorage.Shared.Modules.Game.ImageIds)
local MorphServiceClient = require(ReplicatedStorage.Shared.Services.MorphService.MorphServiceClient)
local ButtonAnimations = require(script.Parent.ButtonAnimations)
local MenuController = require(script.Parent.MenuController)

local MorphScreenController = {}
MorphScreenController._menu = nil :: any
MorphScreenController._buttonAnimations = {} :: { [string]: any }
MorphScreenController._connections = {} :: { RBXScriptConnection }
MorphScreenController._morphContainer = nil :: Frame?
MorphScreenController._morphTemplates = {} :: { [string]: Frame }
MorphScreenController._equippedMorph = nil :: string?
MorphScreenController._unlockedMorphs = {} :: { [string]: any }
MorphScreenController._morphFrame = nil :: Frame?

function MorphScreenController.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	local gameGui = playerGui:WaitForChild("GameGui") :: ScreenGui
	
	-- Find the Morph frame
	local morph = gameGui:FindFirstChild("Morph") :: Frame?
	if not morph then
		for _, child in gameGui:GetDescendants() do
			if child.Name == "Morph" and child:IsA("Frame") then
				morph = child
				break
			end
		end
	end
	
	if not morph then
		warn("MorphScreenController: Could not find Morph frame")
		return
	end
	
	MorphScreenController._morphFrame = morph
	
	-- Setup slide animation for Morph menu
	local fromPosition = UDim2.fromScale(0.5, 0.5)
	local toPosition = UDim2.fromScale(0.5, 1.5)
	MorphScreenController._menu = MenuController.createMenu("Morph", morph, fromPosition, toPosition)
	
	-- Find morph container (scrolling frame with morph templates)
	MorphScreenController._findMorphContainer(morph)
	
	-- Setup all buttons in the morph screen
	MorphScreenController._setupAllButtons(morph)
	
	-- Setup data listeners
	MorphScreenController._setupDataListeners()
	
	-- Load initial data
	MorphScreenController._loadInitialData()
end

function MorphScreenController._findMorphContainer(container: Frame)
	-- Find scrolling frame that contains morph templates
	for _, child in container:GetDescendants() do
		if child:IsA("ScrollingFrame") then
			MorphScreenController._morphContainer = child
			break
		end
	end
end

function MorphScreenController._setupAllButtons(container: Frame)
	-- Find all buttons and connect them
	for _, child in container:GetDescendants() do
		if child:IsA("GuiButton") then
			local buttonName = child.Name:lower()
			local morphId = child:GetAttribute("MorphId")
			local parent = child.Parent
			
			-- Try to determine morphId from parent if not set
			if not morphId and parent then
				morphId = parent:GetAttribute("MorphId") or parent.Name
				if not Morphs[morphId] then
					morphId = nil
				end
			end
			
			if morphId then
				-- This is a morph-related button
				if string.find(buttonName, "lock") or child:GetAttribute("IsLockButton") then
					-- Lock button for purchasing
					local animation = ButtonAnimations.setupButton(child, function()
						MorphServiceClient:purchaseMorph(morphId)
					end)
					MorphScreenController._buttonAnimations[morphId .. "_lock"] = animation
					
					-- Store template reference
					if parent and parent:IsA("Frame") or parent:IsA("ImageLabel") then
						MorphScreenController._morphTemplates[morphId] = parent :: Frame
					end
				elseif string.find(buttonName, "equip") or string.find(buttonName, "purchase") then
					-- Equip/Unequip button
					local animation = ButtonAnimations.setupButton(child, function()
						MorphScreenController._onEquipButtonClicked(morphId)
					end)
					MorphScreenController._buttonAnimations[morphId .. "_equip"] = animation
					
					-- Store template reference
					if parent and parent:IsA("Frame") or parent:IsA("ImageLabel") then
						MorphScreenController._morphTemplates[morphId] = parent :: Frame
					end
				end
			else
				-- Generic button - just add animation
				local animation = ButtonAnimations.setupButton(child)
				MorphScreenController._buttonAnimations[child:GetFullName()] = animation
			end
		end
	end
end

function MorphScreenController._onEquipButtonClicked(morphName: string)
	local isOwned = MorphScreenController._unlockedMorphs[morphName] ~= nil
	if not isOwned then
		return
	end
	
	if MorphScreenController._equippedMorph == morphName then
		MorphServiceClient:unequipMorph()
	else
		MorphServiceClient:equipMorph(morphName)
	end
end

function MorphScreenController._setupDataListeners()
	-- Listen for equipped morph changes
	local equippedConnection = DataService:getChangedSignal({ "equippedMorph" }):Connect(function(value)
		MorphScreenController._equippedMorph = value
		MorphScreenController._updateAllMorphTemplates()
	end)
	table.insert(MorphScreenController._connections, equippedConnection)
	
	-- Listen for unlocked morph changes
	local unlockedConnection = DataService:getIndexChangedSignal({ "unlockedMorph" }):Connect(function(index, newValue)
		MorphScreenController._unlockedMorphs = DataService:get({ "unlockedMorph" }) or {}
		if index then
			MorphScreenController._updateMorphTemplate(index)
		else
			MorphScreenController._updateAllMorphTemplates()
		end
	end)
	table.insert(MorphScreenController._connections, unlockedConnection)
end

function MorphScreenController._loadInitialData()
	-- Load initial equipped morph
	MorphScreenController._equippedMorph = DataService:get({ "equippedMorph" })
	
	-- Load initial unlocked morphs
	MorphScreenController._unlockedMorphs = DataService:get({ "unlockedMorph" }) or {}
	
	-- Update all templates
	MorphScreenController._updateAllMorphTemplates()
end

function MorphScreenController._updateAllMorphTemplates()
	-- Update templates we know about
	for morphName, template in MorphScreenController._morphTemplates do
		MorphScreenController._updateMorphTemplate(morphName)
	end
	
	-- Also try to find and update any templates in the container
	if MorphScreenController._morphContainer then
		for _, child in MorphScreenController._morphContainer:GetChildren() do
			local morphId = child:GetAttribute("MorphId") or child.Name
			if Morphs[morphId] then
				MorphScreenController._updateMorphTemplateUI(child, morphId)
			end
		end
	end
end

function MorphScreenController._updateMorphTemplate(morphName: string)
	local template = MorphScreenController._morphTemplates[morphName]
	if template then
		MorphScreenController._updateMorphTemplateUI(template, morphName)
	end
end

function MorphScreenController._updateMorphTemplateUI(template: Instance, morphName: string)
	local isOwned = MorphScreenController._unlockedMorphs[morphName] ~= nil
	local isEquipped = MorphScreenController._equippedMorph == morphName
	
	-- Update all children
	for _, child in template:GetDescendants() do
		local childName = child.Name:lower()
		
		-- Update lock button visibility
		if child:IsA("GuiButton") then
			if string.find(childName, "lock") or child:GetAttribute("IsLockButton") then
				child.Visible = not isOwned
			end
		end
		
		-- Update equip button appearance
		if child:IsA("ImageButton") then
			if string.find(childName, "equip") or string.find(childName, "purchase") then
				-- Update button image based on equipped state
				if isOwned then
					child.Image = if isEquipped then ImageIds.redButton else ImageIds.greenButton
				end
			end
		end
		
		-- Update text labels
		if child:IsA("TextLabel") then
			-- Check if this is an equip/unequip text
			local parent = child.Parent
			if parent and parent:IsA("GuiButton") then
				local parentName = parent.Name:lower()
				if string.find(parentName, "equip") or string.find(parentName, "purchase") then
					if isOwned then
						child.Text = if isEquipped then "Unequip" else "Equip"
					end
					
					-- Update stroke color
					local stroke = child:FindFirstChildOfClass("UIStroke")
					if stroke and isOwned then
						stroke.Color = if isEquipped 
							then Color3.fromHex("#860000") 
							else Color3.fromHex("#328300")
					end
				end
			end
		end
	end
end

function MorphScreenController.cleanup()
	for _, animation in MorphScreenController._buttonAnimations do
		if animation and animation.cleanup then
			animation.cleanup()
		end
	end
	
	for _, connection in MorphScreenController._connections do
		connection:Disconnect()
	end
	
	if MorphScreenController._menu then
		MorphScreenController._menu.destroy()
	end
end

return MorphScreenController
