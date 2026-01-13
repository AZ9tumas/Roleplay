local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MorphTemplate = require(script.Parent.MorphTemplate)
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local ImageIds = require(ReplicatedStorage.Shared.Modules.Game.ImageIds)
local Morphs = require(ReplicatedStorage.Shared.Modules.Game.Morphs)
local BasicButton = require(ReplicatedStorage.UI.core.components.BasicButton)
local ProductButton = require(ReplicatedStorage.UI.core.components.ProductButton)
local TextLabel = require(ReplicatedStorage.UI.core.components.TextLabel)

local e = React.createElement

local FILTER_LIST = {
	"Name",
	"Date",
	"Owned",
}

local function getFilteredTable(filterType: string, ownedMorphs: {})
	local sorted = {}
	for key, data in Morphs do
		local sortValue
		if filterType == "Name" then
			sortValue = data.displayName or key or ""
		elseif filterType == "Date" then
			sortValue = ownedMorphs[key] and ownedMorphs[key].obtainTime or 0
		else
			sortValue = ownedMorphs[key] and 1 or 0
		end
		table.insert(sorted, {
			key, -- [1]
			sortValue, -- [2]
			data.displayName or key or "", -- [3] for search
		})
	end

	return Sift.Array.sort(sorted, function(a, b)
		if filterType == "Name" then
			return string.lower(tostring(a[2])) < string.lower(tostring(b[2]))
		else
			return a[2] > b[2]
		end
	end)
end

local function matchesSearch(text: string, search: string): boolean
	if search == "" then
		return true
	end
	return string.sub(text:lower(), 1, #search) == search
end

type MorphListProps = {
	Morphs: {},
	EquippedMorph: string,
	SearchState: string,
	FilterState: string,
}

local function MorphList(props: MorphListProps)
	local orderedList = React.useMemo(function()
		return getFilteredTable(props.FilterState, props.Morphs)
	end, { props.FilterState, props.Morphs }) -- Only re-run when FilterState changes

	local elements = React.useMemo(function()
		return {
			UIGridLayout = e("UIGridLayout", {
				CellSize = UDim2.fromOffset(254, 336),
				CellPadding = UDim2.fromOffset(19, 20),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}
	end, {})

	if orderedList then
		local searchLower = props.SearchState and props.SearchState:lower() or ""
		for index, morphProp in orderedList do
			-- Using morphId as key helps React identify which items changed
			local morphId = morphProp[1]
			local isShown = matchesSearch(morphProp[3], searchLower)

			elements[morphId] = e(MorphTemplate, {
				MorphId = morphId,
				Equipped = props.EquippedMorph == morphId,
				Shown = isShown,
				LayoutOrder = index,
				Own = props.Morphs[morphId],
			})
		end
	end

	return e("ScrollingFrame", {
		Size = UDim2.fromScale(0.99, 0.8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, elements)
end

type SearchBarProps = {
	setSearchState: (string) -> (),
}

local function SearchBar(props: SearchBarProps)
	return e("Frame", {
		Size = UDim2.fromOffset(263, 52),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.82, 0.08),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 30),
		}),
		TextBox = e("TextBox", {
			Size = UDim2.fromScale(0.8, 0.8),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			TextSize = 22,
			Text = "Search",
			BackgroundTransparency = 1,

			[React.Change.Text] = function(rbx)
				props.setSearchState(if rbx.Text == "Search" then "" else rbx.Text)
			end,
		}),
	})
end

type FilterProps = {
	filterState: string,
	setFilterState: (string) -> (),
}

local function Filter(props: FilterProps)
	local handleClick = React.useCallback(function()
		local index = Sift.Array.find(FILTER_LIST, props.filterState)
		index += 1
		if index > #FILTER_LIST then
			index = 1
		end
		props.setFilterState(FILTER_LIST[index])
	end, { props.filterState })

	return e(BasicButton, {
		Size = UDim2.fromOffset(200, 52),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.53, 0.08),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0,

		OnActivated = handleClick,
	}, {
		UICorner = e("UICorner", {
			CornerRadius = UDim.new(0, 30),
		}),

		TextLabel = e(TextLabel, {
			Text = `Filter: {props.filterState}`,
			Size = UDim2.fromScale(0.8, 0.8),
			BackgroundTransparency = 1,
		}),
	})
end

local function UnlockButton()
	return e(ProductButton, {
		ImageId = ImageIds.purpleButton,
		Size = UDim2.fromOffset(209, 65),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.13, 0.08),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,

		OnActivated = function() end,
		HidePrice = true,
	}, {

		TextLabel = e(TextLabel, {
			Text = "Unlock All",
			Size = UDim2.fromScale(0.6, 0.6),
			Position = UDim2.fromScale(0.5, 0.45),
			BackgroundTransparency = 1,
		}, {
			Stroke = e("UIStroke", {
				Color = Color3.fromRGB(84, 0, 163),
				Thickness = 3,
			}),
		}),
	})
end

type MorphInventoryProps = {
	unlockedMorphs: {},
	equippedMorph: string,
}

return React.forwardRef(function(props: MorphInventoryProps, ref: React.Ref<any>)
	local searchState, setSearchState = React.useState("")
	local filterState, setFilterState = React.useState(FILTER_LIST[1])

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),

		ref = ref,
	}, {
		SearchBar = e(SearchBar, {
			setSearchState = setSearchState,
		}),

		Filter = e(Filter, {
			filterState = filterState,
			setFilterState = setFilterState,
		}),

		MorphList = e(MorphList, {
			Morphs = props.unlockedMorphs,
			EquippedMorph = props.equippedMorph,
			SearchState = searchState,
			FilterState = filterState,
		}),

		UnlockButton = e(UnlockButton, {}),
	})
end)
