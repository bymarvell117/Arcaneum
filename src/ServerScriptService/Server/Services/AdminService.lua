local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local StatFormulas = require(ReplicatedStorage.Shared.Combat.StatFormulas)
local PlayerDataService = require(ServerScriptService.Server.Services.PlayerDataService)
local CharacterCreationService = require(ServerScriptService.Server.Services.CharacterCreationService)

local AdminService = {}

local adminAuthorizedEvent = Net.GetEvent("AdminAuthorized")
local adminCommandEvent = Net.GetEvent("AdminCommand")

local function isAdmin(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	return table.find(GameConfig.AdminUserIds, player.UserId) ~= nil
end

local function handleAdminCommand(player: Player, payload: unknown)
	if not isAdmin(player) or typeof(payload) ~= "table" then
		return
	end

	local command = payload :: { [string]: any }
	local action = command.Action
	local value = command.Value

	if action == "SetGold" and typeof(value) == "number" then
		PlayerDataService:SetCurrency(player, "Gold", value)
	elseif action == "SetSilver" and typeof(value) == "number" then
		PlayerDataService:SetCurrency(player, "Silver", value)
	elseif action == "SetMageLevel" and typeof(value) == "number" then
		PlayerDataService:SetXP(player, "Mage", StatFormulas.XPForLevel(value))
		PlayerDataService:RefillMana(player)
	elseif action == "SetCombatLevel" and typeof(value) == "number" then
		PlayerDataService:SetXP(player, "Combat", StatFormulas.XPForLevel(value))
	elseif action == "SetCharacterLevel" and typeof(value) == "number" then
		PlayerDataService:SetXP(player, "Character", StatFormulas.XPForLevel(value))
	elseif action == "RefillMana" then
		PlayerDataService:RefillMana(player)
	elseif action == "ResetClass" then
		CharacterCreationService:ResetClass(player)
	end
end

function AdminService:Start()
	Players.PlayerAdded:Connect(function(player)
		if isAdmin(player) then
			adminAuthorizedEvent:FireClient(player)
		end
	end)

	adminCommandEvent.OnServerEvent:Connect(handleAdminCommand)
end

return AdminService
