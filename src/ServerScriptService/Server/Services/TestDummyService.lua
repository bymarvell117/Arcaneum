local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockyHumanoid = require(ReplicatedStorage.Shared.NPC.BlockyHumanoid)

local RESPAWN_DELAY = 4
local DUMMY_MAX_HEALTH = 60
local SPAWN_POSITION = Vector3.new(0, 3, 15)

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
