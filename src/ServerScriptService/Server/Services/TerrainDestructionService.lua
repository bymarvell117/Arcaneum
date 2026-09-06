-- Carving uses Roblox's voxel Terrain directly (FillBall with Air) rather than a
-- health-tracked component like DestructionService, since terrain isn't made of
-- discrete parts. Crater size scales with damage, so a weak hit barely dents rock
-- while a very large hit (e.g. the debug damage key) can punch clean through it.
local MIN_RADIUS = 1
local MAX_RADIUS = 40
local RADIUS_PER_DAMAGE = 0.05

local TerrainDestructionService = {}

function TerrainDestructionService:Carve(position: Vector3, damageAmount: number)
	local radius = math.clamp(MIN_RADIUS + damageAmount * RADIUS_PER_DAMAGE, MIN_RADIUS, MAX_RADIUS)
	workspace.Terrain:FillBall(position, radius, Enum.Material.Air)
end

return TerrainDestructionService
