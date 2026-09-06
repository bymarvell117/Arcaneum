local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local SpellWords = require(ReplicatedStorage.Shared.Spells.SpellWords)
local SpellSlots = require(ReplicatedStorage.Shared.Spells.SpellSlots)
local SpellTypesModule = require(ReplicatedStorage.Shared.Spells.SpellTypes)
local CastingStyles = require(ReplicatedStorage.Shared.Spells.CastingStyles)
local CharacterClasses = require(ReplicatedStorage.Shared.Character.CharacterClasses)

local TOGGLE_KEY = Enum.KeyCode.M
local PERCENT_OPTIONS = { 0.2, 0.4, 0.6, 0.8, 1.0 }
local AMOUNT_OPTIONS = { 1, 2, 3, 4, 5 }
local DURATION_OPTIONS = { 1, 2, 3, 4, 5, 6 }
local AMOUNT_UNLOCK_LEVEL = 30
local ULTIMATE_ART_UNLOCK_LEVEL = 100
local DEFAULT_DURATION = 2
local DEFAULT_THICKNESS = 0.5
local EXPLOSION_MIN_PERCENT = 20
local EXPLOSION_MAX_PERCENT = 1000

local player = Players.LocalPlayer
local characterClassAssignedEvent = Net.GetEvent("CharacterClassAssigned")
local getCharacterClassFunction = Net.GetFunction("GetCharacterClass")
local getMageLevelFunction = Net.GetFunction("GetMageLevel")
local getSpellsFunction = Net.GetFunction("GetSpells")
local spellsUpdatedEvent = Net.GetEvent("SpellsUpdated")
local saveSpellEvent = Net.GetEvent("SaveSpell")
local forgetSpellEvent = Net.GetEvent("ForgetSpell")

local MagicMenuController = {}

local currentWord: string? = nil
local isWitchSlayer = false
local currentMageLevel = 1
local currentSpells: { [string]: any } = {}

local currentPage = "SlotList"
local editingSlot: string? = nil
local editingIsNew = false
local pendingSpell: { [string]: any } = {}

local function makeButton(parent: Instance, text: string, size: UDim2, position: UDim2?): TextButton
	local button = Instance.new("TextButton")
	button.Text = text
	button.Size = size
	if position then
		button.Position = position
	end
	button.BackgroundColor3 = Color3.fromRGB(70, 100, 200)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	return button
end

local function makeRow(parent: Instance, layoutOrder: number, height: number): Frame
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, height)
	row.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	row.LayoutOrder = layoutOrder
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = row

	return row
end

local function makeLabel(parent: Instance, size: UDim2, position: UDim2?, text: string, textSize: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = size
	if position then
		label.Position = position
	end
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextSize = textSize or 14
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = parent
	return label
end

-- ===== Screen chrome =====

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MagicMenuGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.4
backdrop.Parent = screenGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(560, 460)
panel.Position = UDim2.new(0.5, -280, 0.5, -230)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
panel.Parent = backdrop

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(28, 28)
closeButton.Position = UDim2.new(1, -38, 0, 10)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(90, 40, 40)
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = panel
do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = closeButton
end
closeButton.MouseButton1Click:Connect(function()
	screenGui.Enabled = false
end)

local body = Instance.new("ScrollingFrame")
body.Size = UDim2.new(1, -32, 1, -56)
body.Position = UDim2.new(0, 16, 0, 48)
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.ScrollBarThickness = 6
body.CanvasSize = UDim2.new(0, 0, 0, 0)
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.Parent = panel

local bodyList = Instance.new("UIListLayout")
bodyList.Padding = UDim.new(0, 8)
bodyList.Parent = body

local function clearBody()
	for _, child in body:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

-- ===== Pages (forward-declared so their button closures can call `render`, which
-- itself calls them — see the character-creation self-reference bug writeup for why
-- this ordering matters in Lua) =====

local render: () -> ()

local function renderSlotList()
	local wordDisplay = currentWord and SpellWords[currentWord].DisplayName or "None"
	local filled = 0
	for _, slot in SpellSlots.Order do
		if currentSpells[slot] then
			filled += 1
		end
	end

	local header = makeLabel(body, UDim2.new(1, 0, 0, 26), nil, ("%s Magic — %d/%d Spells"):format(wordDisplay, filled, #SpellSlots.Order), 18)
	header.Font = Enum.Font.GothamBold
	header.LayoutOrder = 0

	for index, slot in SpellSlots.Order do
		local row = makeRow(body, index, 56)

		makeLabel(row, UDim2.fromOffset(36, 56), UDim2.fromOffset(8, 0), slot, 18).Font = Enum.Font.GothamBold

		local unlocked = SpellSlots.IsUnlocked(slot, currentMageLevel)
		if not unlocked then
			local lockedLabel = makeLabel(
				row,
				UDim2.new(1, -50, 1, 0),
				UDim2.fromOffset(46, 0),
				("Progress further to unlock (Level %d+)"):format(SpellSlots.UnlockLevel[slot]),
				13
			)
			lockedLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
		else
			local spell = currentSpells[slot]
			makeLabel(row, UDim2.new(1, -190, 1, 0), UDim2.fromOffset(46, 0), spell and spell.Name or "Empty", 14)

			if spell then
				local editButton = makeButton(row, "EDIT", UDim2.fromOffset(64, 28), UDim2.new(1, -160, 0.5, -14))
				editButton.MouseButton1Click:Connect(function()
					editingSlot = slot
					editingIsNew = false
					pendingSpell = {
						TypeId = spell.TypeId,
						Amount = spell.Amount,
						BlastSize = spell.BlastSize,
						ExplosionSize = spell.ExplosionSize,
						UltimateArt = spell.UltimateArt,
						CastingStyle = spell.CastingStyle,
						Name = spell.Name,
						Duration = spell.Duration or DEFAULT_DURATION,
						Thickness = spell.Thickness or DEFAULT_THICKNESS,
					}
					currentPage = "Editor"
					render()
				end)

				local forgetButton = makeButton(row, "FORGET", UDim2.fromOffset(80, 28), UDim2.new(1, -85, 0.5, -14))
				forgetButton.BackgroundColor3 = Color3.fromRGB(120, 50, 50)
				forgetButton.MouseButton1Click:Connect(function()
					forgetSpellEvent:FireServer(slot)
				end)
			else
				local createButton = makeButton(row, "CREATE", UDim2.fromOffset(80, 28), UDim2.new(1, -90, 0.5, -14))
				createButton.MouseButton1Click:Connect(function()
					editingSlot = slot
					editingIsNew = true
					currentPage = "TypePicker"
					render()
				end)
			end
		end
	end
end

local function renderTypePicker()
	local title = makeLabel(body, UDim2.new(1, 0, 0, 26), nil, "Choose the type of spell you want to create", 18)
	title.Font = Enum.Font.GothamBold
	title.LayoutOrder = 0

	for index, typeId in SpellTypesModule.Order do
		local definition = SpellTypesModule.Definitions[typeId]
		local row = makeRow(body, index, 60)

		makeLabel(row, UDim2.new(0.6, 0, 0, 22), UDim2.fromOffset(10, 4), definition.Name, 16).Font = Enum.Font.GothamBold
		local descLabel = makeLabel(row, UDim2.new(0.6, 0, 0, 30), UDim2.fromOffset(10, 26), definition.Description, 12)
		descLabel.TextWrapped = true
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

		if definition.Implemented and currentMageLevel >= definition.MinMageLevel then
			local chooseButton = makeButton(row, "CHOOSE", UDim2.fromOffset(80, 28), UDim2.new(1, -90, 0.5, -14))
			chooseButton.MouseButton1Click:Connect(function()
				pendingSpell = {
					TypeId = typeId,
					Amount = 1,
					BlastSize = 0.5,
					ExplosionSize = 0.5,
					UltimateArt = false,
					CastingStyle = CastingStyles[1].Id,
					Name = definition.Name,
					Duration = DEFAULT_DURATION,
					Thickness = DEFAULT_THICKNESS,
				}
				currentPage = "Editor"
				render()
			end)
		else
			local reason = not definition.Implemented and "Coming soon" or ("Level %d+"):format(definition.MinMageLevel)
			local lockLabel = makeLabel(row, UDim2.fromOffset(90, 28), UDim2.new(1, -95, 0.5, -14), reason, 13)
			lockLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
		end
	end

	local backButton = makeButton(body, "BACK", UDim2.fromOffset(80, 30))
	backButton.LayoutOrder = 999
	backButton.MouseButton1Click:Connect(function()
		currentPage = "SlotList"
		render()
	end)
end

local function buildOptionRow(
	layoutOrder: number,
	labelText: string,
	options: { number },
	formatOption: (number) -> string,
	currentValue: number,
	locked: boolean,
	lockedText: string?,
	onPick: (number) -> ()
)
	local row = makeRow(body, layoutOrder, 56)
	makeLabel(row, UDim2.new(0.35, 0, 1, 0), UDim2.fromOffset(10, 0), labelText, 14)

	if locked then
		local lockedLabel = makeLabel(row, UDim2.new(0.6, 0, 1, 0), UDim2.new(0.35, 0, 0, 0), lockedText or "Locked", 13)
		lockedLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
		return
	end

	local optionsFrame = Instance.new("Frame")
	optionsFrame.Size = UDim2.new(0.6, 0, 1, -16)
	optionsFrame.Position = UDim2.new(0.35, 0, 0, 8)
	optionsFrame.BackgroundTransparency = 1
	optionsFrame.Parent = row

	local optionsList = Instance.new("UIListLayout")
	optionsList.FillDirection = Enum.FillDirection.Horizontal
	optionsList.Padding = UDim.new(0, 6)
	optionsList.Parent = optionsFrame

	for _, value in options do
		local optionButton = Instance.new("TextButton")
		optionButton.Size = UDim2.fromOffset(48, 32)
		optionButton.Text = formatOption(value)
		optionButton.TextSize = 12
		optionButton.Font = Enum.Font.GothamBold
		optionButton.TextColor3 = Color3.new(1, 1, 1)
		optionButton.BackgroundColor3 = value == currentValue and Color3.fromRGB(90, 140, 255) or Color3.fromRGB(50, 50, 60)
		optionButton.Parent = optionsFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = optionButton

		optionButton.MouseButton1Click:Connect(function()
			onPick(value)
		end)
	end
end

-- A free-typed number field instead of preset buttons — used for Power, which is
-- meant to go far beyond the other sliders' 100% ceiling so genuinely "super
-- powerful" spells are possible (mana cost scales right along with it, so it's
-- self-balancing rather than needing an artificial cap).
local function buildNumberRow(
	layoutOrder: number,
	labelText: string,
	currentPercent: number,
	minPercent: number,
	maxPercent: number,
	onApply: (number) -> ()
)
	local row = makeRow(body, layoutOrder, 56)
	makeLabel(row, UDim2.new(0.35, 0, 1, 0), UDim2.fromOffset(10, 0), labelText, 14)

	local inputBox = Instance.new("TextBox")
	inputBox.Size = UDim2.fromOffset(90, 32)
	inputBox.Position = UDim2.new(0.35, 0, 0.5, -16)
	inputBox.Text = tostring(math.floor(currentPercent + 0.5))
	inputBox.Font = Enum.Font.GothamBold
	inputBox.TextSize = 14
	inputBox.TextColor3 = Color3.new(1, 1, 1)
	inputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	inputBox.ClearTextOnFocus = false
	inputBox.Parent = row

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = inputBox

	local suffixLabel = makeLabel(
		row,
		UDim2.fromOffset(160, 32),
		UDim2.new(0.35, 96, 0.5, -16),
		("% (%d-%d)"):format(minPercent, maxPercent),
		13
	)
	suffixLabel.TextColor3 = Color3.fromRGB(170, 170, 170)

	inputBox.FocusLost:Connect(function()
		local parsed = tonumber(inputBox.Text)
		if not parsed then
			inputBox.Text = tostring(math.floor(currentPercent + 0.5))
			return
		end
		local clamped = math.clamp(parsed, minPercent, maxPercent)
		onApply(clamped / 100)
		render()
	end)
end

local function renderEditor()
	local title = makeLabel(body, UDim2.new(1, 0, 0, 26), nil, editingIsNew and "Create your spell" or "Edit your spell", 18)
	title.Font = Enum.Font.GothamBold
	title.LayoutOrder = 0

	if pendingSpell.TypeId == "BeamAttack" then
		buildOptionRow(1, "Duration (sec)", DURATION_OPTIONS, function(v)
			return tostring(v)
		end, pendingSpell.Duration, false, nil, function(value)
			pendingSpell.Duration = value
			render()
		end)

		buildOptionRow(2, "Thickness", PERCENT_OPTIONS, function(v)
			return math.floor(v * 100) .. "%"
		end, pendingSpell.Thickness, false, nil, function(value)
			pendingSpell.Thickness = value
			render()
		end)
	else
		buildOptionRow(1, "Amount", AMOUNT_OPTIONS, function(v)
			return tostring(v)
		end, pendingSpell.Amount, currentMageLevel < AMOUNT_UNLOCK_LEVEL, ("Level %d+"):format(AMOUNT_UNLOCK_LEVEL), function(value)
			pendingSpell.Amount = value
			render()
		end)

		buildOptionRow(2, "Blast Size", PERCENT_OPTIONS, function(v)
			return math.floor(v * 100) .. "%"
		end, pendingSpell.BlastSize, false, nil, function(value)
			pendingSpell.BlastSize = value
			render()
		end)
	end

	local powerLabel = pendingSpell.TypeId == "BeamAttack" and "Power" or "Explosion Size"
	buildNumberRow(3, powerLabel, pendingSpell.ExplosionSize * 100, EXPLOSION_MIN_PERCENT, EXPLOSION_MAX_PERCENT, function(value)
		pendingSpell.ExplosionSize = value
	end)

	local ultimateRow = makeRow(body, 4, 56)
	makeLabel(ultimateRow, UDim2.new(0.5, 0, 1, 0), UDim2.fromOffset(10, 0), "Ultimate Art", 14)
	if currentMageLevel < ULTIMATE_ART_UNLOCK_LEVEL then
		local lockedLabel = makeLabel(ultimateRow, UDim2.new(0.4, 0, 1, 0), UDim2.new(0.5, 0, 0, 0), ("Level %d+"):format(ULTIMATE_ART_UNLOCK_LEVEL), 13)
		lockedLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
	else
		local toggleButton = makeButton(
			ultimateRow,
			pendingSpell.UltimateArt and "ON" or "OFF",
			UDim2.fromOffset(70, 32),
			UDim2.new(0.5, 0, 0.5, -16)
		)
		toggleButton.BackgroundColor3 = pendingSpell.UltimateArt and Color3.fromRGB(230, 190, 60) or Color3.fromRGB(50, 50, 60)
		toggleButton.MouseButton1Click:Connect(function()
			pendingSpell.UltimateArt = not pendingSpell.UltimateArt
			render()
		end)
	end

	local styleRow = makeRow(body, 5, 56)
	makeLabel(styleRow, UDim2.new(0.5, 0, 1, 0), UDim2.fromOffset(10, 0), "Casting Style", 14)
	local currentStyleName = "Left Hand Punch"
	for _, style in CastingStyles do
		if style.Id == pendingSpell.CastingStyle then
			currentStyleName = style.Name
		end
	end
	local styleButton = makeButton(styleRow, currentStyleName, UDim2.fromOffset(160, 32), UDim2.new(0.5, 0, 0.5, -16))
	styleButton.MouseButton1Click:Connect(function()
		local currentIndex = 1
		for i, style in CastingStyles do
			if style.Id == pendingSpell.CastingStyle then
				currentIndex = i
			end
		end
		local nextStyle = CastingStyles[(currentIndex % #CastingStyles) + 1]
		pendingSpell.CastingStyle = nextStyle.Id
		render()
	end)

	local nameRow = makeRow(body, 6, 56)
	makeLabel(nameRow, UDim2.new(0.3, 0, 1, 0), UDim2.fromOffset(10, 0), "Name", 14)
	local nameBox = Instance.new("TextBox")
	nameBox.Size = UDim2.new(0.65, 0, 0, 32)
	nameBox.Position = UDim2.new(0.3, 0, 0.5, -16)
	nameBox.Text = pendingSpell.Name or ""
	nameBox.ClearTextOnFocus = false
	nameBox.Font = Enum.Font.Gotham
	nameBox.TextSize = 13
	nameBox.Parent = nameRow
	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		pendingSpell.Name = nameBox.Text
	end)

	local buttonRow = Instance.new("Frame")
	buttonRow.Size = UDim2.new(1, 0, 0, 40)
	buttonRow.BackgroundTransparency = 1
	buttonRow.LayoutOrder = 7
	buttonRow.Parent = body

	local backButton = makeButton(buttonRow, "BACK", UDim2.fromOffset(100, 34))
	backButton.MouseButton1Click:Connect(function()
		currentPage = editingIsNew and "TypePicker" or "SlotList"
		render()
	end)

	local saveButton = makeButton(buttonRow, "SAVE", UDim2.fromOffset(100, 34), UDim2.new(1, -100, 0, 0))
	saveButton.BackgroundColor3 = Color3.fromRGB(80, 160, 90)
	saveButton.MouseButton1Click:Connect(function()
		saveSpellEvent:FireServer({
			Slot = editingSlot,
			TypeId = pendingSpell.TypeId,
			Amount = pendingSpell.Amount,
			BlastSize = pendingSpell.BlastSize,
			ExplosionSize = pendingSpell.ExplosionSize,
			UltimateArt = pendingSpell.UltimateArt,
			CastingStyle = pendingSpell.CastingStyle,
			Name = nameBox.Text,
			Duration = pendingSpell.Duration,
			Thickness = pendingSpell.Thickness,
		})
		currentPage = "SlotList"
		render()
	end)
end

render = function()
	-- Refetched on every render (not just when the menu is toggled open) so that
	-- leveling up via the admin panel while the menu is already open — e.g. clicking
	-- straight from SlotList into an Editor without closing/reopening with M — can't
	-- leave Amount/Ultimate Art/spell-type gates stuck showing a stale locked state.
	currentMageLevel = getMageLevelFunction:InvokeServer()
	clearBody()
	if currentPage == "SlotList" then
		renderSlotList()
	elseif currentPage == "TypePicker" then
		renderTypePicker()
	elseif currentPage == "Editor" then
		renderEditor()
	end
end

-- ===== Wiring =====

function MagicMenuController:Start()
	screenGui.Parent = player:WaitForChild("PlayerGui")

	characterClassAssignedEvent.OnClientEvent:Connect(function(classId: string?)
		isWitchSlayer = classId == "WitchSlayer"
		currentWord = classId and CharacterClasses[classId] and CharacterClasses[classId].Word or nil
	end)

	spellsUpdatedEvent.OnClientEvent:Connect(function(spells: { [string]: any })
		currentSpells = spells
		if screenGui.Enabled and currentPage == "SlotList" then
			render()
		end
	end)

	local currentClass = getCharacterClassFunction:InvokeServer()
	isWitchSlayer = currentClass == "WitchSlayer"
	currentWord = currentClass and CharacterClasses[currentClass] and CharacterClasses[currentClass].Word or nil
	currentSpells = getSpellsFunction:InvokeServer() or {}

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or input.KeyCode ~= TOGGLE_KEY then
			return
		end
		if isWitchSlayer then
			return
		end

		screenGui.Enabled = not screenGui.Enabled
		if screenGui.Enabled then
			currentPage = "SlotList"
			render()
		end
	end)
end

return MagicMenuController
