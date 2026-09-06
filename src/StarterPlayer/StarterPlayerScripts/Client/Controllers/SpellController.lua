local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local SpellWords = require(ReplicatedStorage.Shared.Spells.SpellWords)

local FLASH_TWEEN_TIME = 0.25
local SLOT_WORDS = { "Ignis", "Glacies", "Fulgur" }
local DEFAULT_LOADOUT = {
	Intensity = 2,
	Quantity = 1,
	ProjectileCount = 1,
}
local SLOT_SIZE = 56
local SLOT_GAP = 8

local player = Players.LocalPlayer
local castSpellEvent = Net.GetEvent("CastSpell")

local SpellController = {}

local selectedSlot = 1
local slotStrokes: { [number]: UIStroke } = {}

local function getMouseHitPosition(): Vector3?
	local mouse = player:GetMouse()
	return mouse and mouse.Hit and mouse.Hit.Position
end

local function buildHotbar()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpellHotbarGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local totalWidth = (#SLOT_WORDS * SLOT_SIZE) + ((#SLOT_WORDS - 1) * SLOT_GAP)
	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromOffset(totalWidth, SLOT_SIZE)
	container.Position = UDim2.new(0.5, -totalWidth / 2, 1, -90)
	container.Parent = screenGui

	for index, wordId in SLOT_WORDS do
		local word = SpellWords[wordId]

		local slot = Instance.new("Frame")
		slot.Size = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
		slot.Position = UDim2.fromOffset((index - 1) * (SLOT_SIZE + SLOT_GAP), 0)
		slot.BackgroundColor3 = word.Color
		slot.BackgroundTransparency = 0.35
		slot.BorderSizePixel = 0
		slot.Parent = container

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = slot

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = 1
		stroke.Parent = slot
		slotStrokes[index] = stroke

		local keyLabel = Instance.new("TextLabel")
		keyLabel.BackgroundTransparency = 1
		keyLabel.Size = UDim2.fromOffset(18, 18)
		keyLabel.Position = UDim2.fromOffset(4, 2)
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.TextSize = 14
		keyLabel.TextColor3 = Color3.new(1, 1, 1)
		keyLabel.Text = tostring(index)
		keyLabel.Parent = slot

		local nameLabel = Instance.new("TextLabel")
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(1, 0, 0, 16)
		nameLabel.Position = UDim2.new(0, 0, 1, -18)
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextSize = 12
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Text = word.DisplayName
		nameLabel.Parent = slot
	end
end

local function refreshHotbarSelection()
	for index, stroke in slotStrokes do
		stroke.Transparency = index == selectedSlot and 0 or 1
	end
end

local function selectSlot(index: number)
	if not SLOT_WORDS[index] then
		return
	end
	selectedSlot = index
	refreshHotbarSelection()
end

local function playCastFeedback(wordId: string)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	local word = SpellWords[wordId]
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Size = Vector3.new(0.6, 0.6, 0.6)
	flash.Color = word.Color
	flash.Material = Enum.Material.Neon
	flash.CanCollide = false
	flash.Anchored = true
	flash.CFrame = (rootPart :: BasePart).CFrame * CFrame.new(0, 0, -2)
	flash.Parent = workspace

	local tween = TweenService:Create(flash, TweenInfo.new(FLASH_TWEEN_TIME), {
		Size = Vector3.new(1.4, 1.4, 1.4),
		Transparency = 1,
	})
	tween:Play()
	Debris:AddItem(flash, FLASH_TWEEN_TIME + 0.1)
end

local function castSelectedSpell()
	local wordId = SLOT_WORDS[selectedSlot]
	if not wordId then
		return
	end

	playCastFeedback(wordId)

	castSpellEvent:FireServer({
		WordId = wordId,
		Intensity = DEFAULT_LOADOUT.Intensity,
		Quantity = DEFAULT_LOADOUT.Quantity,
		ProjectileCount = DEFAULT_LOADOUT.ProjectileCount,
		TargetPosition = getMouseHitPosition(),
	})
end

function SpellController:Start()
	buildHotbar()
	refreshHotbarSelection()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.One then
			selectSlot(1)
		elseif input.KeyCode == Enum.KeyCode.Two then
			selectSlot(2)
		elseif input.KeyCode == Enum.KeyCode.Three then
			selectSlot(3)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			castSelectedSpell()
		end
	end)
end

return SpellController
