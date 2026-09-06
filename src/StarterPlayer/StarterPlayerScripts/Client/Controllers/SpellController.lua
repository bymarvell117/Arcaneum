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

local player = Players.LocalPlayer
local castSpellEvent = Net.GetEvent("CastSpell")

local SpellController = {}

local selectedSlot = 1

local function getMouseHitPosition(): Vector3?
	local mouse = player:GetMouse()
	return mouse and mouse.Hit and mouse.Hit.Position
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
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.One then
			selectedSlot = 1
		elseif input.KeyCode == Enum.KeyCode.Two then
			selectedSlot = 2
		elseif input.KeyCode == Enum.KeyCode.Three then
			selectedSlot = 3
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			castSelectedSpell()
		end
	end)
end

return SpellController
