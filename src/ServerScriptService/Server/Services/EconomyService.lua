local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local PlayerDataService = require(ServerScriptService.Server.Services.PlayerDataService)

-- 1 Gold = 10 Silver, matching the two-currency design (gold is the "bulk" currency).
local SILVER_PER_GOLD = 10

local EconomyService = {}

local exchangeCurrencyEvent = Net.GetEvent("ExchangeCurrency")

local function handleExchange(player: Player, payload: unknown)
	if typeof(payload) ~= "table" then
		return
	end

	local command = payload :: { [string]: any }
	local action = command.Action
	local units = command.Units

	if typeof(units) ~= "number" then
		return
	end
	units = math.floor(units)
	if units < 1 then
		return
	end

	local data = PlayerDataService:GetData(player)
	if not data then
		return
	end

	if action == "SilverToGold" then
		local silverCost = units * SILVER_PER_GOLD
		if data.Silver < silverCost then
			return
		end
		PlayerDataService:AddCurrency(player, "Silver", -silverCost)
		PlayerDataService:AddCurrency(player, "Gold", units)
	elseif action == "GoldToSilver" then
		if data.Gold < units then
			return
		end
		PlayerDataService:AddCurrency(player, "Gold", -units)
		PlayerDataService:AddCurrency(player, "Silver", units * SILVER_PER_GOLD)
	end
end

function EconomyService:Start()
	exchangeCurrencyEvent.OnServerEvent:Connect(handleExchange)
end

return EconomyService
