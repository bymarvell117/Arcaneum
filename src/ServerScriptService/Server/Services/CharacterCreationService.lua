local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local CharacterClasses = require(ReplicatedStorage.Shared.Character.CharacterClasses)
local PlayerDataService = require(ServerScriptService.Server.Services.PlayerDataService)

local DEFAULT_WALK_SPEED = 16
local DEFAULT_JUMP_POWER = 50
local DATA_WAIT_ATTEMPTS = 50
local DATA_WAIT_INTERVAL = 0.1

local CharacterCreationService = {}

local characterClassAssignedEvent = Net.GetEvent("CharacterClassAssigned")
local selectCharacterClassEvent = Net.GetEvent("SelectCharacterClass")
local getCharacterClassFunction = Net.GetFunction("GetCharacterClass")

local function freezeCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	end
end

local function unfreezeCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = DEFAULT_WALK_SPEED
		humanoid.JumpPower = DEFAULT_JUMP_POWER
	end
end

-- PlayerDataService loads each player's profile asynchronously (a DataStore call) on
-- its own independent PlayerAdded connection, so it may not be populated yet the
-- instant our own PlayerAdded/CharacterAdded handlers run. Poll briefly instead of
-- assuming an ordering between two unrelated Loader-spawned connections.
local function waitForData(player: Player): PlayerDataService.PlayerData?
	for _ = 1, DATA_WAIT_ATTEMPTS do
		local data = PlayerDataService:GetData(player)
		if data then
			return data
		end
		task.wait(DATA_WAIT_INTERVAL)
	end
	return nil
end

local function handleSelectClass(player: Player, classId: unknown)
	if typeof(classId) ~= "string" or not CharacterClasses[classId] then
		return
	end

	local data = PlayerDataService:GetData(player)
	if not data or data.CharacterClass then
		return
	end

	PlayerDataService:SetCharacterClass(player, classId)
	characterClassAssignedEvent:FireClient(player, classId)

	local character = player.Character
	if character then
		unfreezeCharacter(character)
	end
end

-- Testing convenience: lets the admin panel flip a player back to "no class chosen"
-- without needing a second Roblox account to test the Witch Slayer branch.
function CharacterCreationService:ResetClass(player: Player)
	PlayerDataService:ClearCharacterClass(player)
	characterClassAssignedEvent:FireClient(player, nil)

	local character = player.Character
	if character then
		freezeCharacter(character)
	end
end

function CharacterCreationService:Start()
	-- A RemoteFunction the client calls once at startup, rather than the server
	-- firing a RemoteEvent on PlayerAdded: firing on join races the client's own
	-- script startup (Net.GetEvent, WaitForChild, connecting listeners) — if the
	-- server fires first, that one-shot event is lost forever and the client never
	-- learns it should show the picker. Invoking pulls the current state on demand,
	-- whenever the client is actually ready to receive it.
	getCharacterClassFunction.OnServerInvoke = function(player: Player)
		local data = waitForData(player)
		return data and data.CharacterClass or nil
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			-- Freeze immediately so there's no window to move before we know whether
			-- this player already has a class from a previous session.
			freezeCharacter(character)
			task.spawn(function()
				local data = waitForData(player)
				if data and data.CharacterClass then
					unfreezeCharacter(character)
				end
			end)
		end)
	end)

	selectCharacterClassEvent.OnServerEvent:Connect(handleSelectClass)
end

return CharacterCreationService
