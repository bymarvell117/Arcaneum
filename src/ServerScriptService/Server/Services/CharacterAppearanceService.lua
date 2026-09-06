local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local AppearancePalette = require(ReplicatedStorage.Shared.Character.AppearancePalette)
local PlayerDataService = require(ServerScriptService.Server.Services.PlayerDataService)

-- Recolors every character to a plain body (no accessories, since we don't have
-- verified real catalog asset IDs to offer yet) per the player's saved
-- skin/shirt/pants choice, instead of showing their own Roblox avatar. A clean base
-- ready for the future custom character art (Disney-Infinity-style) and the separate
-- armor/clothing layer system to build on top of.
--
-- NOTE: ApplyDescription's second parameter is Enum.AssetTypeVerification, not a rig
-- type override — there's no scriptable way to force R15 here. Everyone spawning on
-- R15 (rather than whatever rig their own account defaults to) requires setting this
-- place's Avatar Type to "R15" in Studio's Game Settings > Avatar tab, which is a
-- project setting Rojo doesn't sync (like the Baseplate part, it lives outside the
-- src/ tree).
local CharacterAppearanceService = {}

local setAppearanceEvent = Net.GetEvent("SetAppearance")

local function buildDescription(player: Player): HumanoidDescription
	local skin, shirt, pants = PlayerDataService:GetAppearanceColors(player)
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = skin
	description.TorsoColor = shirt
	description.LeftArmColor = shirt
	description.RightArmColor = shirt
	description.LeftLegColor = pants
	description.RightLegColor = pants
	return description
end

local function applyAppearance(player: Player, character: Model)
	PlayerDataService:WaitForData(player)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid:ApplyDescription(buildDescription(player))
end

local function isKnownPaletteColor(value: unknown, palette: { Color3 }): boolean
	if typeof(value) ~= "table" then
		return false
	end
	local candidate = value :: { R: unknown, G: unknown, B: unknown }
	if typeof(candidate.R) ~= "number" or typeof(candidate.G) ~= "number" or typeof(candidate.B) ~= "number" then
		return false
	end
	for _, option in palette do
		if math.abs(option.R - candidate.R) < 0.01 and math.abs(option.G - candidate.G) < 0.01 and math.abs(option.B - candidate.B) < 0.01 then
			return true
		end
	end
	return false
end

local function toColor3(value: { R: number, G: number, B: number }): Color3
	return Color3.new(value.R, value.G, value.B)
end

local function handleSetAppearance(player: Player, payload: unknown)
	if typeof(payload) ~= "table" then
		return
	end
	local command = payload :: { [string]: any }

	if
		not isKnownPaletteColor(command.Skin, AppearancePalette.SkinColors)
		or not isKnownPaletteColor(command.Shirt, AppearancePalette.OutfitColors)
		or not isKnownPaletteColor(command.Pants, AppearancePalette.OutfitColors)
	then
		return
	end

	PlayerDataService:SetAppearance(player, toColor3(command.Skin), toColor3(command.Shirt), toColor3(command.Pants))

	local character = player.Character
	if character then
		applyAppearance(player, character)
	end
end

function CharacterAppearanceService:Start()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			applyAppearance(player, character)
		end)
	end)

	setAppearanceEvent.OnServerEvent:Connect(handleSetAppearance)
end

return CharacterAppearanceService
