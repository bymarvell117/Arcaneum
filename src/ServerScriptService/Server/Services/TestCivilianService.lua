local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockyHumanoid = require(ReplicatedStorage.Shared.NPC.BlockyHumanoid)

local RESPAWN_DELAY = 5
local CIVILIAN_MAX_HEALTH = 40
local SPAWN_POSITION = Vector3.new(-15, 3, 5)

local TestCivilianService = {}

local function buildCivilian(): Model
	local model = BlockyHumanoid.Build({
		Name = "TestCivilian",
		Position = SPAWN_POSITION,
		MaxHealth = CIVILIAN_MAX_HEALTH,
		TorsoColor = Color3.fromRGB(80, 140, 90),
	})
	CollectionService:AddTag(model, "Civilian")

	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		task.wait(RESPAWN_DELAY)
		model:Destroy()
		buildCivilian().Parent = workspace
	end)

	return model
end

function TestCivilianService:Start()
	buildCivilian().Parent = workspace
end

return TestCivilianService
