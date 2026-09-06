local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local DESTRUCTIBLE_TAG = "Destructible"
local DEFAULT_OVERKILL_MULTIPLIER = 3
local DEBRIS_LIFETIME = 6
local DEBRIS_PIECES = 6

local DestructionService = {}

local function isDestroyed(part: BasePart): boolean
	return part:GetAttribute("Destroyed") == true
end

local function spawnDebris(part: BasePart)
	for _ = 1, DEBRIS_PIECES do
		local chunk = Instance.new("Part")
		chunk.Size = part.Size / 3
		chunk.Color = part.Color
		chunk.Material = part.Material
		chunk.CFrame = part.CFrame
			* CFrame.new(
				(math.random(-100, 100) / 100) * part.Size.X / 2,
				(math.random(-100, 100) / 100) * part.Size.Y / 2,
				(math.random(-100, 100) / 100) * part.Size.Z / 2
			)
		chunk.Anchored = false
		chunk.CanCollide = true
		chunk.Parent = workspace
		chunk.AssemblyLinearVelocity = Vector3.new(math.random(-10, 10), math.random(5, 15), math.random(-10, 10))

		Debris:AddItem(chunk, DEBRIS_LIFETIME)
	end
end

local function breakPart(part: BasePart)
	if isDestroyed(part) then
		return
	end
	part:SetAttribute("Destroyed", true)
	spawnDebris(part)
	part.Transparency = 1
	part.CanCollide = false
	CollectionService:RemoveTag(part, DESTRUCTIBLE_TAG)
	Debris:AddItem(part, DEBRIS_LIFETIME)
end

function DestructionService:DestroyStructure(structureId: string, cause: BasePart?)
	for _, instance in CollectionService:GetTagged(DESTRUCTIBLE_TAG) do
		if instance ~= cause and instance:GetAttribute("StructureId") == structureId then
			breakPart(instance :: BasePart)
		end
	end
	if cause then
		breakPart(cause)
	end
end

function DestructionService:Damage(part: Instance, amount: number)
	if not part:IsA("BasePart") or not CollectionService:HasTag(part, DESTRUCTIBLE_TAG) then
		return
	end
	if isDestroyed(part) then
		return
	end

	local health = part:GetAttribute("Health")
	if typeof(health) ~= "number" then
		return
	end

	local overkillMultiplier = part:GetAttribute("ShatterOverkillMultiplier") or DEFAULT_OVERKILL_MULTIPLIER
	local isOverkill = amount >= health * overkillMultiplier

	health -= amount
	part:SetAttribute("Health", health)

	if health <= 0 then
		local structureId = part:GetAttribute("StructureId")
		if isOverkill and structureId then
			self:DestroyStructure(structureId, part)
		else
			breakPart(part)
		end
	end
end

return DestructionService
