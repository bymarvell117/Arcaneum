local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local SpellWords = require(ReplicatedStorage.Shared.Spells.SpellWords)
local SpellSlots = require(ReplicatedStorage.Shared.Spells.SpellSlots)
local CharacterClasses = require(ReplicatedStorage.Shared.Character.CharacterClasses)
local SpellBuilder = require(ReplicatedStorage.Shared.Spells.SpellBuilder)

local FLASH_TWEEN_TIME = 0.25
local SLOT_SIZE = 56
local SLOT_GAP = 8
local BEAM_TICK_INTERVAL = 0.1
local KEY_TO_SLOT = {
	[Enum.KeyCode.Q] = "Q",
	[Enum.KeyCode.E] = "E",
	[Enum.KeyCode.R] = "R",
	[Enum.KeyCode.F] = "F",
	[Enum.KeyCode.V] = "V",
}
local HAND_OFFSETS = {
	LeftHand = Vector3.new(-1, 0, -2),
	RightHand = Vector3.new(1, 0, -2),
	BothHands = Vector3.new(0, 0, -2),
}

local FAIL_MESSAGE_DURATION = 1
local FAIL_REASON_TEXT = {
	NotEnoughMana = "Not enough mana!",
	OnCooldown = "Still on cooldown!",
}

local player = Players.LocalPlayer
local castSpellEvent = Net.GetEvent("CastSpell")
local castFailedEvent = Net.GetEvent("CastFailed")
local characterClassAssignedEvent = Net.GetEvent("CharacterClassAssigned")
local getCharacterClassFunction = Net.GetFunction("GetCharacterClass")
local spellsUpdatedEvent = Net.GetEvent("SpellsUpdated")
local getSpellsFunction = Net.GetFunction("GetSpells")
local manaUpdatedEvent = Net.GetEvent("ManaUpdated")

local SpellController = {}

local isWitchSlayer = false
local currentWord: string? = nil
local currentSpells: { [string]: SpellBuilder.CustomSpellData } = {}
local slotLabels: { [string]: TextLabel } = {}
local slotFrames: { [string]: Frame } = {}
local heldSlots: { [string]: boolean } = {}
local currentMana = 0
local currentMaxMana = 1
local beamMeterFrame: Frame? = nil
local beamMeterFill: Frame? = nil
local failMessageLabel: TextLabel? = nil

local function getMouseHitPosition(): Vector3?
	local mouse = player:GetMouse()
	return mouse and mouse.Hit and mouse.Hit.Position
end

local function refreshSlotVisual(slot: string)
	local frame = slotFrames[slot]
	local label = slotLabels[slot]
	if not frame or not label then
		return
	end

	local spell = currentSpells[slot]
	if spell and currentWord then
		local word = SpellWords[currentWord]
		frame.BackgroundColor3 = word and word.Color or Color3.fromRGB(80, 80, 90)
		frame.BackgroundTransparency = 0.35
		label.Text = spell.Name
	else
		frame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		frame.BackgroundTransparency = 0.55
		label.Text = "Empty"
	end
end

local function refreshAllSlots()
	for _, slot in SpellSlots.Order do
		refreshSlotVisual(slot)
	end
end

local function buildHotbar(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpellHotbarGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local totalWidth = (#SpellSlots.Order * SLOT_SIZE) + ((#SpellSlots.Order - 1) * SLOT_GAP)
	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromOffset(totalWidth, SLOT_SIZE)
	container.Position = UDim2.new(0.5, -totalWidth / 2, 1, -90)
	container.Parent = screenGui

	for index, slot in SpellSlots.Order do
		local slotFrame = Instance.new("Frame")
		slotFrame.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
		slotFrame.Position = UDim2.fromOffset((index - 1) * (SLOT_SIZE + SLOT_GAP), 0)
		slotFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		slotFrame.BackgroundTransparency = 0.55
		slotFrame.BorderSizePixel = 0
		slotFrame.Parent = container
		slotFrames[slot] = slotFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = slotFrame

		local keyLabel = Instance.new("TextLabel")
		keyLabel.BackgroundTransparency = 1
		keyLabel.Size = UDim2.fromOffset(18, 18)
		keyLabel.Position = UDim2.fromOffset(4, 2)
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.TextSize = 14
		keyLabel.TextColor3 = Color3.new(1, 1, 1)
		keyLabel.Text = slot
		keyLabel.Parent = slotFrame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(1, -4, 0, 28)
		nameLabel.Position = UDim2.new(0, 2, 1, -30)
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextSize = 11
		nameLabel.TextWrapped = true
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Text = "Empty"
		nameLabel.Parent = slotFrame
		slotLabels[slot] = nameLabel
	end

	return screenGui
end

local function buildBeamMeter(screenGui: ScreenGui)
	local background = Instance.new("Frame")
	background.Size = UDim2.fromOffset(220, 14)
	background.Position = UDim2.new(0.5, -110, 1, -108)
	background.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	background.BorderSizePixel = 0
	background.Visible = false
	background.Parent = screenGui
	beamMeterFrame = background

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 150, 60)
	fill.BorderSizePixel = 0
	fill.Parent = background
	beamMeterFill = fill
end

local function buildFailMessage(screenGui: ScreenGui)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(260, 24)
	label.Position = UDim2.new(0.5, -130, 1, -130)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(255, 90, 90)
	label.TextTransparency = 1
	label.Text = ""
	label.Parent = screenGui
	failMessageLabel = label
end

local function showFailMessage(reason: string)
	if not failMessageLabel then
		return
	end
	failMessageLabel.Text = FAIL_REASON_TEXT[reason] or "Can't cast that right now."
	failMessageLabel.TextTransparency = 0
	local tween = TweenService:Create(
		failMessageLabel,
		TweenInfo.new(FAIL_MESSAGE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1 }
	)
	tween:Play()
end

local function updateBeamMeterFill()
	if not beamMeterFill then
		return
	end
	local ratio = currentMaxMana > 0 and math.clamp(currentMana / currentMaxMana, 0, 1) or 0
	beamMeterFill.Size = UDim2.fromScale(ratio, 1)
end

local function isAnySlotHeld(): boolean
	for _, held in heldSlots do
		if held then
			return true
		end
	end
	return false
end

local function setBeamMeterVisible(visible: boolean)
	if beamMeterFrame then
		beamMeterFrame.Visible = visible
	end
end

local function playCastFeedback(spell: SpellBuilder.CustomSpellData)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not currentWord then
		return
	end

	local word = SpellWords[currentWord]
	local offset = HAND_OFFSETS[spell.CastingStyle] or HAND_OFFSETS.BothHands

	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(0.6, 0.6, 0.6)
	flash.Color = word.Color
	flash.Material = Enum.Material.Neon
	flash.CanCollide = false
	flash.Anchored = true
	flash.CFrame = (rootPart :: BasePart).CFrame * CFrame.new(offset)
	flash.Parent = workspace

	local tween = TweenService:Create(flash, TweenInfo.new(FLASH_TWEEN_TIME), {
		Size = Vector3.new(1.4, 1.4, 1.4),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(flash, FLASH_TWEEN_TIME + 0.1)
end

local function castInstant(slot: string, spell: SpellBuilder.CustomSpellData)
	playCastFeedback(spell)
	castSpellEvent:FireServer({
		Slot = slot,
		TargetPosition = getMouseHitPosition(),
	})
end

-- BeamAttack is a hold-to-channel spell: while the key is held we fire one CastSpell
-- message per tick (the server advances the beam by however much time passed since
-- the last one) instead of a single instant cast, and show a live power meter that
-- mirrors remaining mana so the player can see the beam weaken/die as it drains.
local function startChannel(slot: string)
	if heldSlots[slot] then
		return
	end
	heldSlots[slot] = true
	setBeamMeterVisible(true)

	task.spawn(function()
		while heldSlots[slot] do
			castSpellEvent:FireServer({
				Slot = slot,
				TargetPosition = getMouseHitPosition(),
			})
			task.wait(BEAM_TICK_INTERVAL)
		end
	end)
end

local function stopChannel(slot: string)
	if not heldSlots[slot] then
		return
	end
	heldSlots[slot] = false
	castSpellEvent:FireServer({ Slot = slot, Stop = true })
	setBeamMeterVisible(isAnySlotHeld())
end

local function handleSlotPressed(slot: string)
	if isWitchSlayer then
		return
	end
	local spell = currentSpells[slot]
	if not spell then
		return
	end

	if spell.TypeId == "BeamAttack" then
		startChannel(slot)
	else
		castInstant(slot, spell)
	end
end

local function handleSlotReleased(slot: string)
	if heldSlots[slot] then
		stopChannel(slot)
	end
end

function SpellController:Start()
	local hotbarGui = buildHotbar()
	buildBeamMeter(hotbarGui)
	buildFailMessage(hotbarGui)

	manaUpdatedEvent.OnClientEvent:Connect(function(mana: number, maxMana: number)
		currentMana = mana
		currentMaxMana = maxMana
		updateBeamMeterFill()
	end)

	castFailedEvent.OnClientEvent:Connect(showFailMessage)

	characterClassAssignedEvent.OnClientEvent:Connect(function(classId: string?)
		isWitchSlayer = classId == "WitchSlayer"
		currentWord = classId and CharacterClasses[classId] and CharacterClasses[classId].Word or nil
		hotbarGui.Enabled = not isWitchSlayer
		refreshAllSlots()
	end)

	spellsUpdatedEvent.OnClientEvent:Connect(function(spells: { [string]: SpellBuilder.CustomSpellData })
		currentSpells = spells
		refreshAllSlots()
	end)

	-- Pull current state instead of only relying on pushes, which could fire before
	-- this script finished connecting the listeners above.
	local currentClass = getCharacterClassFunction:InvokeServer()
	isWitchSlayer = currentClass == "WitchSlayer"
	currentWord = currentClass and CharacterClasses[currentClass] and CharacterClasses[currentClass].Word or nil
	hotbarGui.Enabled = not isWitchSlayer

	currentSpells = getSpellsFunction:InvokeServer() or {}
	refreshAllSlots()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		local slot = KEY_TO_SLOT[input.KeyCode]
		if slot then
			handleSlotPressed(slot)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		local slot = KEY_TO_SLOT[input.KeyCode]
		if slot then
			handleSlotReleased(slot)
		end
	end)
end

return SpellController
