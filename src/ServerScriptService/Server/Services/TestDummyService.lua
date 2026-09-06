local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BlockyHumanoid = require(ReplicatedStorage.Shared.NPC.BlockyHumanoid)
local PlayerDataService = require(ServerScriptService.Server.Services.PlayerDataService)
local QuestService = require(ServerScriptService.Server.Services.QuestService)

local RESPAWN_DELAY = 4
local DUMMY_MAX_HEALTH = 60
local SPAWN_POSITION = Vector3.new(0, 3, 15)
local SILVER_REWARD = 8
local CHARACTER_XP_REWARD = 10

local TestDummyService = {}

local function buildDummy(): Model
	local model = BlockyHumanoid.Build({
		Name = "TrainingDummy",
		Position = SPAWN_POSITION,
		MaxHealth = DUMMY_MAX_HEALTH,
		TorsoColor = Color3.fromRGB(120, 120, 130),
	})

	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		local killerUserId = model:GetAttribute("LastDamagedByUserId")
		if typeof(killerUserId) == "number" then
			local killer = Players:GetPlayerByUserId(killerUserId)
			if killer then
				PlayerDataService:AddCurrency(killer, "Silver", SILVER_REWARD)
				PlayerDataService:AddXP(killer, "Character", CHARACTER_XP_REWARD)
				QuestService:ReportDummyDefeated(killer)
			end
		end

		task.wait(RESPAWN_DELAY)
		model:Destroy()
		buildDummy().Parent = workspace
	end)

	return model
end

function TestDummyService:Start()
	buildDummy().Parent = workspace
end

return TestDummyService
