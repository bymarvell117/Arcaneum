local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local SpellSlots = require(ReplicatedStorage.Shared.Spells.SpellSlots)
local SpellTypesModule = require(ReplicatedStorage.Shared.Spells.SpellTypes)
local CastingStyles = require(ReplicatedStorage.Shared.Spells.CastingStyles)
local CharacterClasses = require(ReplicatedStorage.Shared.Character.CharacterClasses)
local PlayerDataService = require(ServerScriptService.Server.Services.PlayerDataService)

local NAME_MAX_LENGTH = 24
local AMOUNT_UNLOCK_LEVEL = 30
local ULTIMATE_ART_UNLOCK_LEVEL = 100
local MIN_AMOUNT = 1
local MAX_AMOUNT = 5
local MIN_SIZE_FRACTION = 0.2
local MAX_SIZE_FRACTION = 1
local MIN_EXPLOSION_FRACTION = 0.2
local MAX_EXPLOSION_FRACTION = 10
local MIN_DURATION = 1
local MAX_DURATION = 6

local SpellSlotService = {}

local getSpellsFunction = Net.GetFunction("GetSpells")
local getMageLevelFunction = Net.GetFunction("GetMageLevel")
local spellsUpdatedEvent = Net.GetEvent("SpellsUpdated")
local saveSpellEvent = Net.GetEvent("SaveSpell")
local forgetSpellEvent = Net.GetEvent("ForgetSpell")

local function isValidCastingStyle(styleId: unknown): boolean
	if typeof(styleId) ~= "string" then
		return false
	end
	for _, style in CastingStyles do
		if style.Id == styleId then
			return true
		end
	end
	return false
end

local function sanitizeName(name: unknown, fallback: string): string
	if typeof(name) ~= "string" then
		return fallback
	end
	local trimmed = (name:gsub("^%s+", ""):gsub("%s+$", ""))
	if #trimmed == 0 then
		return fallback
	end
	return trimmed:sub(1, NAME_MAX_LENGTH)
end

local function getPlayerWord(player: Player): string?
	local data = PlayerDataService:GetData(player)
	if not data or not data.CharacterClass then
		return nil
	end
	local classDef = CharacterClasses[data.CharacterClass]
	return classDef and classDef.Word
end

local function pushSpells(player: Player)
	spellsUpdatedEvent:FireClient(player, PlayerDataService:GetSpells(player))
end

-- Gives a fresh mage one working spell in slot Q so they're never stuck with nothing
-- to cast. Called by CharacterCreationService right after a mage class is picked.
function SpellSlotService:CreateDefaultSpell(player: Player, word: string)
	PlayerDataService:SetSpell(player, "Q", {
		TypeId = "BlastAttack",
		Amount = 1,
		BlastSize = 0.5,
		ExplosionSize = 1.0,
		Duration = MIN_DURATION,
		Thickness = 0.5,
		UltimateArt = false,
		CastingStyle = CastingStyles[1].Id,
		Name = word .. " Blast",
	})
	pushSpells(player)
end

local function handleSaveSpell(player: Player, payload: unknown)
	if typeof(payload) ~= "table" then
		return
	end
	local command = payload :: { [string]: any }

	local slot = command.Slot
	if typeof(slot) ~= "string" or not table.find(SpellSlots.Order, slot) then
		return
	end

	local mageLevel = PlayerDataService:GetMageLevel(player)
	if not SpellSlots.IsUnlocked(slot, mageLevel) then
		return
	end

	local word = getPlayerWord(player)
	if not word then
		return
	end

	local typeId = command.TypeId
	local typeDef = typeof(typeId) == "string" and SpellTypesModule.Definitions[typeId]
	if not typeDef or not typeDef.Implemented or mageLevel < typeDef.MinMageLevel then
		return
	end

	local amount = typeof(command.Amount) == "number" and math.floor(command.Amount) or MIN_AMOUNT
	amount = math.clamp(amount, MIN_AMOUNT, MAX_AMOUNT)
	if mageLevel < AMOUNT_UNLOCK_LEVEL then
		amount = MIN_AMOUNT
	end

	local blastSize = typeof(command.BlastSize) == "number" and command.BlastSize or 0.5
	local explosionSize = typeof(command.ExplosionSize) == "number" and command.ExplosionSize or 0.5
	local duration = typeof(command.Duration) == "number" and command.Duration or MIN_DURATION
	local thickness = typeof(command.Thickness) == "number" and command.Thickness or 0.5

	local spell = {
		TypeId = typeId,
		Amount = amount,
		BlastSize = math.clamp(blastSize, MIN_SIZE_FRACTION, MAX_SIZE_FRACTION),
		ExplosionSize = math.clamp(explosionSize, MIN_EXPLOSION_FRACTION, MAX_EXPLOSION_FRACTION),
		UltimateArt = command.UltimateArt == true and mageLevel >= ULTIMATE_ART_UNLOCK_LEVEL,
		CastingStyle = isValidCastingStyle(command.CastingStyle) and command.CastingStyle or CastingStyles[1].Id,
		Name = sanitizeName(command.Name, typeDef.Name),
		Duration = math.clamp(duration, MIN_DURATION, MAX_DURATION),
		Thickness = math.clamp(thickness, MIN_SIZE_FRACTION, MAX_SIZE_FRACTION),
	}

	PlayerDataService:SetSpell(player, slot, spell)
	pushSpells(player)
end

local function handleForgetSpell(player: Player, slot: unknown)
	if typeof(slot) ~= "string" or not table.find(SpellSlots.Order, slot) then
		return
	end
	PlayerDataService:ClearSpell(player, slot)
	pushSpells(player)
end

function SpellSlotService:Start()
	-- Pulled by the client once at startup (see the character-creation race writeup
	-- in the README for why this is a RemoteFunction rather than a push).
	getSpellsFunction.OnServerInvoke = function(player: Player)
		PlayerDataService:WaitForData(player)
		return PlayerDataService:GetSpells(player)
	end

	getMageLevelFunction.OnServerInvoke = function(player: Player)
		PlayerDataService:WaitForData(player)
		return PlayerDataService:GetMageLevel(player)
	end

	saveSpellEvent.OnServerEvent:Connect(handleSaveSpell)
	forgetSpellEvent.OnServerEvent:Connect(handleForgetSpell)
end

return SpellSlotService
