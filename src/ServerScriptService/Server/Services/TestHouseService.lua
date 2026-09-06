local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HouseBuilder = require(ReplicatedStorage.Shared.Buildings.HouseBuilder)

local HOUSE_POSITION = Vector3.new(-15, 0.5, 15)

local TestHouseService = {}

function TestHouseService:Start()
	HouseBuilder.Build({
		Name = "TestHouse",
		Position = HOUSE_POSITION,
		StructureId = "TestHouse1",
	}).Parent = workspace
end

return TestHouseService
