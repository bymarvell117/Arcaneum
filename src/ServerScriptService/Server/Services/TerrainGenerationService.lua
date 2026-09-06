-- Sculpts a small test mountain out of Roblox voxel Terrain so there's rock to test
-- spells against. Real world generation (multiple named landmarks, biomes, etc.) is a
-- much bigger future system — this is just a testable target for Phase 3.
local MOUNTAIN_POSITION = Vector3.new(40, -5, 0)
local MOUNTAIN_RADIUS = 25

local TerrainGenerationService = {}

function TerrainGenerationService:Start()
	workspace.Terrain:FillBall(MOUNTAIN_POSITION, MOUNTAIN_RADIUS, Enum.Material.Rock)
end

return TerrainGenerationService
