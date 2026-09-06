local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HouseBuilder = require(ReplicatedStorage.Shared.Buildings.HouseBuilder)

-- Players can't steal from each other's houses (no shared inventory to steal from
-- yet), but anyone can still destroy one — it rebuilds on its own after a delay once
-- it fully collapses, at the same plot, for the same owner. A real building/placement
-- tool (choosing layout, furniture, etc.) is future work; this is "claim a plot, get a
-- starter house" for now.
local PLOTS = {
	{ Id = "Plot1", Position = Vector3.new(-40, 0.5, 15) },
	{ Id = "Plot2", Position = Vector3.new(-40, 0.5, 35) },
}

local REBUILD_CHECK_INTERVAL = 3
local REBUILD_DELAY = 30

local HousingService = {}

local plotOwners: { [string]: number } = {}

local function structureIdFor(plotId: string): string
	return "PlayerHouse_" .. plotId
end

local function monitorAndRebuild(plotId: string, position: Vector3, ownerUserId: number)
	local house = HouseBuilder.Build({
		Name = "PlayerHouse",
		Position = position,
		StructureId = structureIdFor(plotId),
		OwnerUserId = ownerUserId,
	})
	house.Parent = workspace

	task.spawn(function()
		while HouseBuilder.CountStanding(house) > 0 do
			task.wait(REBUILD_CHECK_INTERVAL)
		end

		task.wait(REBUILD_DELAY)
		house:Destroy()

		if plotOwners[plotId] == ownerUserId then
			monitorAndRebuild(plotId, position, ownerUserId)
		end
	end)
end

local function buildClaimMarker(plotDef: { Id: string, Position: Vector3 }, onClaim: (Player) -> ())
	local marker = Instance.new("Part")
	marker.Name = "PlotMarker_" .. plotDef.Id
	marker.Size = Vector3.new(1, 6, 1)
	marker.Color = Color3.fromRGB(90, 200, 120)
	marker.Material = Enum.Material.Neon
	marker.Anchored = true
	marker.CanCollide = false
	marker.CFrame = CFrame.new(plotDef.Position + Vector3.new(0, 3, -7))
	marker.Parent = workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClaimPrompt"
	prompt.ActionText = "Claim Plot"
	prompt.ObjectText = "Empty Plot"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.Parent = marker

	prompt.Triggered:Connect(function(player)
		if plotOwners[plotDef.Id] then
			return
		end
		marker:Destroy()
		onClaim(player)
	end)
end

function HousingService:Start()
	for _, plotDef in PLOTS do
		buildClaimMarker(plotDef, function(player)
			plotOwners[plotDef.Id] = player.UserId
			monitorAndRebuild(plotDef.Id, plotDef.Position, player.UserId)
		end)
	end
end

return HousingService
