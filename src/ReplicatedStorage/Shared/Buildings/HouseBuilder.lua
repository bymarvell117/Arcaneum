local CollectionService = game:GetService("CollectionService")

export type HouseBuilderOptions = {
	Name: string,
	Position: Vector3,
	StructureId: string,
	OwnerUserId: number?,
}

local WALL_HEIGHT = 8
local WALL_HEALTH = 200
local WINDOW_HEALTH = 15
local ROOF_HEALTH = 150

local HouseBuilder = {}

local function makeDestructible(part: BasePart, health: number, options: HouseBuilderOptions)
	part.Anchored = true
	part:SetAttribute("Health", health)
	part:SetAttribute("MaxHealth", health)
	part:SetAttribute("StructureId", options.StructureId)
	if options.OwnerUserId then
		part:SetAttribute("OwnerId", options.OwnerUserId)
	end
	CollectionService:AddTag(part, "Destructible")
end

-- Builds a single-room house with a real window opening (not a window buried inside a
-- solid wall) out of Studio primitive parts. Used both for the fixed Phase 2 test house
-- and for player-owned houses spawned by HousingService.
function HouseBuilder.Build(options: HouseBuilderOptions): Model
	local model = Instance.new("Model")
	model.Name = options.Name

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(12, 1, 12)
	floor.Color = Color3.fromRGB(150, 120, 90)
	floor.Anchored = true
	floor.CFrame = CFrame.new(options.Position)
	floor.Parent = model

	local wallDefs = {
		{ Name = "WallNorth", Size = Vector3.new(12, WALL_HEIGHT, 1), Offset = Vector3.new(0, WALL_HEIGHT / 2, -5.5) },
		{ Name = "WallSouth", Size = Vector3.new(12, WALL_HEIGHT, 1), Offset = Vector3.new(0, WALL_HEIGHT / 2, 5.5) },
		{ Name = "WallEast", Size = Vector3.new(1, WALL_HEIGHT, 12), Offset = Vector3.new(5.5, WALL_HEIGHT / 2, 0) },
		{ Name = "WallWestLeft", Size = Vector3.new(1, WALL_HEIGHT, 4.5), Offset = Vector3.new(-5.5, WALL_HEIGHT / 2, -3.75) },
		{ Name = "WallWestRight", Size = Vector3.new(1, WALL_HEIGHT, 4.5), Offset = Vector3.new(-5.5, WALL_HEIGHT / 2, 3.75) },
		{ Name = "WallWestSill", Size = Vector3.new(1, 2, 3), Offset = Vector3.new(-5.5, 1, 0) },
		{ Name = "WallWestLintel", Size = Vector3.new(1, 3.5, 3), Offset = Vector3.new(-5.5, 6.25, 0) },
	}

	for _, def in wallDefs do
		local wall = Instance.new("Part")
		wall.Name = def.Name
		wall.Size = def.Size
		wall.Color = Color3.fromRGB(200, 190, 170)
		wall.CFrame = floor.CFrame * CFrame.new(def.Offset)
		wall.Parent = model
		makeDestructible(wall, WALL_HEALTH, options)
	end

	local window = Instance.new("Part")
	window.Name = "Window"
	window.Size = Vector3.new(0.3, 2.5, 3)
	window.Color = Color3.fromRGB(150, 220, 255)
	window.Material = Enum.Material.Glass
	window.Transparency = 0.3
	window.CFrame = floor.CFrame * CFrame.new(-5.5, 3.25, 0)
	window.Parent = model
	makeDestructible(window, WINDOW_HEALTH, options)

	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(13, 1, 13)
	roof.Color = Color3.fromRGB(120, 60, 50)
	roof.Anchored = true
	roof.CFrame = floor.CFrame * CFrame.new(0, WALL_HEIGHT + 0.5, 0)
	roof.Parent = model
	makeDestructible(roof, ROOF_HEALTH, options)

	return model
end

-- Counts how many of the house's parts are still standing (tagged Destructible).
-- Callers use this to detect a full collapse (0 remaining) without tracking health
-- centrally themselves.
function HouseBuilder.CountStanding(model: Model): number
	local count = 0
	for _, part in model:GetDescendants() do
		if CollectionService:HasTag(part, "Destructible") then
			count += 1
		end
	end
	return count
end

return HouseBuilder
