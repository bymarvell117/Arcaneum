local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatFormulas = require(ReplicatedStorage.Shared.Combat.StatFormulas)
local Net = require(ReplicatedStorage.Shared.Framework.Net)
local ColorSerialization = require(ReplicatedStorage.Shared.Util.ColorSerialization)

local DATASTORE_NAME = "ArcaneumPlayerData_v1"
local MANA_REGEN_INTERVAL = 2
local MANA_REGEN_FRACTION = 0.05
local DATA_WAIT_ATTEMPTS = 50
local DATA_WAIT_INTERVAL = 0.1
local DEFAULT_BODY_COLOR = Color3.fromRGB(163, 162, 165)

export type PlayerData = {
	Silver: number,
	Gold: number,
	MageXP: number,
	CombatXP: number,
	CharacterXP: number,
	Mana: number,
	CharacterClass: string?,
	SkinColor: ColorSerialization.SerializedColor,
	ShirtColor: ColorSerialization.SerializedColor,
	PantsColor: ColorSerialization.SerializedColor,
}

local PlayerDataService = {}

local dataStore = nil
local profiles: { [Player]: PlayerData } = {}

local manaUpdated = Net.GetEvent("ManaUpdated")
local currencyUpdated = Net.GetEvent("CurrencyUpdated")

local function defaultData(): PlayerData
	return {
		Silver = 0,
		Gold = 0,
		MageXP = 0,
		CombatXP = 0,
		CharacterXP = 0,
		Mana = StatFormulas.MaxManaForLevel(1),
		CharacterClass = nil,
		SkinColor = ColorSerialization.ToTable(DEFAULT_BODY_COLOR),
		ShirtColor = ColorSerialization.ToTable(DEFAULT_BODY_COLOR),
		PantsColor = ColorSerialization.ToTable(DEFAULT_BODY_COLOR),
	}
end

function PlayerDataService:Init()
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if ok then
		dataStore = store
	else
		warn("[PlayerDataService] DataStore unavailable, using in-memory data only")
	end
end

local function loadProfile(player: Player): PlayerData
	if dataStore then
		local ok, saved = pcall(function()
			return dataStore:GetAsync("Player_" .. player.UserId)
		end)
		if ok and saved then
			return saved
		end
	end
	return defaultData()
end

local function saveProfile(player: Player)
	local data = profiles[player]
	if not data or not dataStore then
		return
	end
	pcall(function()
		dataStore:SetAsync("Player_" .. player.UserId, data)
	end)
end

function PlayerDataService:GetMageLevel(player: Player): number
	local data = profiles[player]
	if not data then
		return 1
	end
	return StatFormulas.LevelFromXP(data.MageXP)
end

function PlayerDataService:GetCombatLevel(player: Player): number
	local data = profiles[player]
	if not data then
		return 1
	end
	return StatFormulas.LevelFromXP(data.CombatXP)
end

function PlayerDataService:Start()
	Players.PlayerAdded:Connect(function(player)
		profiles[player] = loadProfile(player)
		local data = profiles[player]
		manaUpdated:FireClient(player, data.Mana, StatFormulas.MaxManaForLevel(self:GetMageLevel(player)))
		currencyUpdated:FireClient(player, data.Silver, data.Gold)
	end)

	Players.PlayerRemoving:Connect(function(player)
		saveProfile(player)
		profiles[player] = nil
	end)

	game:BindToClose(function()
		for player in profiles do
			saveProfile(player)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(MANA_REGEN_INTERVAL)
			for player, data in profiles do
				local maxMana = StatFormulas.MaxManaForLevel(self:GetMageLevel(player))
				if data.Mana < maxMana then
					data.Mana = math.min(maxMana, data.Mana + maxMana * MANA_REGEN_FRACTION)
					manaUpdated:FireClient(player, data.Mana, maxMana)
				end
			end
		end
	end)
end

function PlayerDataService:GetData(player: Player): PlayerData?
	return profiles[player]
end

-- PlayerDataService loads each player's profile asynchronously (a DataStore call),
-- so it may not be populated the instant another Loader-spawned service's own
-- PlayerAdded/CharacterAdded connections run. Poll briefly rather than assuming an
-- ordering between two unrelated connections on the same signal.
function PlayerDataService:WaitForData(player: Player): PlayerData?
	for _ = 1, DATA_WAIT_ATTEMPTS do
		local data = profiles[player]
		if data then
			return data
		end
		task.wait(DATA_WAIT_INTERVAL)
	end
	return nil
end

function PlayerDataService:TrySpendMana(player: Player, amount: number): boolean
	local data = profiles[player]
	if not data or data.Mana < amount then
		return false
	end
	data.Mana -= amount
	local maxMana = StatFormulas.MaxManaForLevel(self:GetMageLevel(player))
	manaUpdated:FireClient(player, data.Mana, maxMana)
	return true
end

function PlayerDataService:AddXP(player: Player, track: "Mage" | "Combat" | "Character", amount: number)
	local data = profiles[player]
	if not data then
		return
	end
	if track == "Mage" then
		data.MageXP += amount
	elseif track == "Combat" then
		data.CombatXP += amount
	else
		data.CharacterXP += amount
	end
end

function PlayerDataService:SetXP(player: Player, track: "Mage" | "Combat" | "Character", amount: number)
	local data = profiles[player]
	if not data then
		return
	end
	if track == "Mage" then
		data.MageXP = amount
	elseif track == "Combat" then
		data.CombatXP = amount
	else
		data.CharacterXP = amount
	end
end

function PlayerDataService:AddCurrency(player: Player, currency: "Silver" | "Gold", amount: number)
	local data = profiles[player]
	if not data then
		return
	end
	data[currency] = math.max(0, data[currency] + amount)
	currencyUpdated:FireClient(player, data.Silver, data.Gold)
end

function PlayerDataService:SetCurrency(player: Player, currency: "Silver" | "Gold", amount: number)
	local data = profiles[player]
	if not data then
		return
	end
	data[currency] = amount
	currencyUpdated:FireClient(player, data.Silver, data.Gold)
end

function PlayerDataService:SetCharacterClass(player: Player, classId: string)
	local data = profiles[player]
	if not data then
		return
	end
	data.CharacterClass = classId
end

function PlayerDataService:ClearCharacterClass(player: Player)
	local data = profiles[player]
	if not data then
		return
	end
	data.CharacterClass = nil
end

function PlayerDataService:SetAppearance(player: Player, skin: Color3, shirt: Color3, pants: Color3)
	local data = profiles[player]
	if not data then
		return
	end
	data.SkinColor = ColorSerialization.ToTable(skin)
	data.ShirtColor = ColorSerialization.ToTable(shirt)
	data.PantsColor = ColorSerialization.ToTable(pants)
end

function PlayerDataService:GetAppearanceColors(player: Player): (Color3, Color3, Color3)
	local data = profiles[player]
	if not data then
		return DEFAULT_BODY_COLOR, DEFAULT_BODY_COLOR, DEFAULT_BODY_COLOR
	end
	return ColorSerialization.FromTable(data.SkinColor),
		ColorSerialization.FromTable(data.ShirtColor),
		ColorSerialization.FromTable(data.PantsColor)
end

function PlayerDataService:RefillMana(player: Player)
	local data = profiles[player]
	if not data then
		return
	end
	local maxMana = StatFormulas.MaxManaForLevel(self:GetMageLevel(player))
	data.Mana = maxMana
	manaUpdated:FireClient(player, data.Mana, maxMana)
end

return PlayerDataService
