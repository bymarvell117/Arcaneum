-- Sculpts real Roblox voxel Terrain for the test area (flat ground + a mountain) so
-- players stand on actual destructible terrain instead of Studio's plastic Baseplate
-- part. Real world generation (multiple named landmarks, biomes, etc.) is a much
-- bigger future system — this is just a testable ground for Phase 3/4.
local FLAT_GROUND_CENTER = CFrame.new(10, -2, 10)
local FLAT_GROUND_SIZE = Vector3.new(200, 4, 200)

local MOUNTAIN_POSITION = Vector3.new(40, -5, 0)
local MOUNTAIN_RADIUS = 25

local TerrainGenerationService = {}

local function removeStudioBaseplate()
	-- Only removes it from this live Play session; the saved place file (Edit mode)
	-- is untouched, so this is safe to run unconditionally every time.
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
end

function TerrainGenerationService:Start()
	removeStudioBaseplate()

	-- Flat ground first, then the mountain on top — filling the flat block after the
	-- mountain would slice a flat grass shelf through its base where they overlap.
	workspace.Terrain:FillBlock(FLAT_GROUND_CENTER, FLAT_GROUND_SIZE, Enum.Material.Grass)
	workspace.Terrain:FillBall(MOUNTAIN_POSITION, MOUNTAIN_RADIUS, Enum.Material.Rock)
end

return TerrainGenerationService
