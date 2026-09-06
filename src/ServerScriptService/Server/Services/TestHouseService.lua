local CollectionService = game:GetService("CollectionService")

local HOUSE_POSITION = Vector3.new(-15, 0.5, 15)
local STRUCTURE_ID = "TestHouse1"
local WALL_HEIGHT = 8

local WINDOW_HEALTH = 15
local WALL_HEALTH = 200
local ROOF_HEALTH = 150

local TestHouseService = {}

local function makeDestructible(part: BasePart, health: number, structureId: string)
	part.Anchored = true
	part:SetAttribute("Health", health)
	part:SetAttribute("MaxHealth", health)
	part:SetAttribute("StructureId", structureId)
	CollectionService:AddTag(part, "Destructible")
end

local function buildHouse(): Model
	local model = Instance.new("Model")
	model.Name = "TestHouse"

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(12, 1, 12)
	floor.Color = Color3.fromRGB(150, 120, 90)
	floor.Anchored = true
	floor.CFrame = CFrame.new(HOUSE_POSITION)
	floor.Parent = model

	local wallDefs = {
		{ Name = "WallNorth", Size = Vector3.new(12, WALL_HEIGHT, 1), Offset = Vector3.new(0, WALL_HEIGHT / 2, -5.5) },
		{ Name = "WallSouth", Size = Vector3.new(12, WALL_HEIGHT, 1), Offset = Vector3.new(0, WALL_HEIGHT / 2, 5.5) },
		{ Name = "WallEast", Size = Vector3.new(1, WALL_HEIGHT, 12), Offset = Vector3.new(5.5, WALL_HEIGHT / 2, 0) },
		{ Name = "WallWest", Size = Vector3.new(1, WALL_HEIGHT, 12), Offset = Vector3.new(-5.5, WALL_HEIGHT / 2, 0) },
	}

	for _, def in wallDefs do
		local wall = Instance.new("Part")
		wall.Name = def.Name
		wall.Size = def.Size
		wall.Color = Color3.fromRGB(200, 190, 170)
		wall.CFrame = floor.CFrame * CFrame.new(def.Offset)
		wall.Parent = model
		makeDestructible(wall, WALL_HEALTH, STRUCTURE_ID)
	end

	local window = Instance.new("Part")
	window.Name = "Window"
	window.Size = Vector3.new(0.4, 2.5, 3)
	window.Color = Color3.fromRGB(150, 220, 255)
	window.Material = Enum.Material.Glass
	window.Transparency = 0.3
	window.CFrame = floor.CFrame * CFrame.new(-5.4, WALL_HEIGHT / 2, 0)
	window.Parent = model
	makeDestructible(window, WINDOW_HEALTH, STRUCTURE_ID)

	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(13, 1, 13)
	roof.Color = Color3.fromRGB(120, 60, 50)
	roof.Anchored = true
	roof.CFrame = floor.CFrame * CFrame.new(0, WALL_HEIGHT + 0.5, 0)
	roof.Parent = model
	makeDestructible(roof, ROOF_HEALTH, STRUCTURE_ID)

	return model
end

function TestHouseService:Start()
	buildHouse().Parent = workspace
end

return TestHouseService
