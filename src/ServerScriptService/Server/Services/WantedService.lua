local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local PlayerDataService = require(ServerScriptService.Server.Services.PlayerDataService)
local LawEnforcerService = require(ServerScriptService.Server.Services.LawEnforcerService)

local MAX_WANTED_LEVEL = 5
local WANTED_DECAY_INTERVAL = 5
local WANTED_DECAY_AMOUNT = 0.25

local MINOR_PROPERTY_FINE = 10
local MAJOR_PROPERTY_FINE = 100
local MINOR_PROPERTY_WANTED = 0.5
local MAJOR_PROPERTY_WANTED = 2
local CIVILIAN_HIT_WANTED = 1
local CIVILIAN_KILL_WANTED = 3

local WantedService = {}

local wantedUpdatedEvent = Net.GetEvent("WantedUpdated")
local wantedLevels: { [Player]: number } = {}

local function setWantedLevel(player: Player, level: number)
	level = math.clamp(level, 0, MAX_WANTED_LEVEL)
	local previous = wantedLevels[player] or 0
	if previous == level then
		return
	end

	wantedLevels[player] = level
	wantedUpdatedEvent:FireClient(player, level)

	if level > 0 and previous <= 0 then
		LawEnforcerService:SpawnEnforcer(player, level)
	elseif level <= 0 then
		LawEnforcerService:DespawnEnforcer(player)
	end
end

function WantedService:GetWantedLevel(player: Player): number
	return wantedLevels[player] or 0
end

function WantedService:AddWanted(player: Player, amount: number)
	setWantedLevel(player, self:GetWantedLevel(player) + amount)
end

function WantedService:ReportPropertyDamage(player: Player, structureDestroyed: boolean)
	if structureDestroyed then
		PlayerDataService:AddCurrency(player, "Gold", -MAJOR_PROPERTY_FINE)
		self:AddWanted(player, MAJOR_PROPERTY_WANTED)
	else
		PlayerDataService:AddCurrency(player, "Silver", -MINOR_PROPERTY_FINE)
		self:AddWanted(player, MINOR_PROPERTY_WANTED)
	end
end

function WantedService:ReportCivilianDamage(player: Player, killed: boolean)
	self:AddWanted(player, killed and CIVILIAN_KILL_WANTED or CIVILIAN_HIT_WANTED)
end

function WantedService:Start()
	Players.PlayerAdded:Connect(function(player)
		wantedLevels[player] = 0
	end)

	Players.PlayerRemoving:Connect(function(player)
		wantedLevels[player] = nil
		LawEnforcerService:DespawnEnforcer(player)
	end)

	task.spawn(function()
		while true do
			task.wait(WANTED_DECAY_INTERVAL)
			for player, level in wantedLevels do
				if level > 0 then
					setWantedLevel(player, level - WANTED_DECAY_AMOUNT)
				end
			end
		end
	end)
end

return WantedService
