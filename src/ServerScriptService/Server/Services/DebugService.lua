local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local DestructionService = require(ServerScriptService.Server.Services.DestructionService)
local WantedService = require(ServerScriptService.Server.Services.WantedService)

-- TEMPORARY testing tool: deals a large fixed hit to whatever the client is
-- pointing at, bypassing mana/cooldown/level checks entirely. Meant to be
-- folded into the real admin panel once that exists.
local DEBUG_DAMAGE = 1000

local DebugService = {}

local debugDealDamageEvent = Net.GetEvent("DebugDealDamage")

local function handleDebugDealDamage(player: Player, target: unknown)
	if typeof(target) ~= "Instance" or not target:IsA("BasePart") then
		return
	end
	if not target:IsDescendantOf(workspace) then
		return
	end

	local humanoid = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:TakeDamage(DEBUG_DAMAGE)
		if CollectionService:HasTag(target.Parent, "Civilian") then
			WantedService:ReportCivilianDamage(player, humanoid.Health <= 0)
		end
	else
		local result = DestructionService:Damage(target, DEBUG_DAMAGE)
		if result and result.Broke then
			WantedService:ReportPropertyDamage(player, result.StructureDestroyed)
		end
	end
end

function DebugService:Start()
	debugDealDamageEvent.OnServerEvent:Connect(handleDebugDealDamage)
end

return DebugService
