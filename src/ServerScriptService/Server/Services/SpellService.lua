local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local SpellBuilder = require(ReplicatedStorage.Shared.Spells.SpellBuilder)

local PlayerDataService = require(ServerScriptService.Server.Services.PlayerDataService)
local DestructionService = require(ServerScriptService.Server.Services.DestructionService)
local WantedService = require(ServerScriptService.Server.Services.WantedService)
local TerrainDestructionService = require(ServerScriptService.Server.Services.TerrainDestructionService)

local MAGE_XP_PER_MANA_SPENT = 0.5
local COMBAT_XP_PER_HIT = 4
local PROJECTILE_LIFETIME = 4
local BASE_PROJECTILE_SIZE = Vector3.new(1, 1, 1)
local SPREAD_ANGLE_DEGREES = 6
local BURST_CAST_DELAY = 0.15

local SpellService = {}

local castSpellEvent = Net.GetEvent("CastSpell")
local lastCastAt: { [Player]: number } = {}

local function spawnProjectile(origin: Vector3, direction: Vector3, resolved: SpellBuilder.ResolvedSpell, caster: Player)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = BASE_PROJECTILE_SIZE * (0.6 + resolved.Intensity * 0.15)
	part.Color = resolved.Word.Color
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.Anchored = false
	part.CFrame = CFrame.new(origin, origin + direction)
	part.Parent = workspace

	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = direction * resolved.Word.ProjectileSpeed
	velocity.Parent = part

	local hitConnection: RBXScriptConnection
	hitConnection = part.Touched:Connect(function(hit)
		local casterCharacter = caster.Character
		if casterCharacter and hit:IsDescendantOf(casterCharacter) then
			return
		end

		if hit == workspace.Terrain then
			TerrainDestructionService:Carve(part.Position, resolved.DamagePerProjectile)
		else
			local humanoid = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				hit.Parent:SetAttribute("LastDamagedByUserId", caster.UserId)
				humanoid:TakeDamage(resolved.DamagePerProjectile)
				PlayerDataService:AddXP(caster, "Combat", COMBAT_XP_PER_HIT)
				if CollectionService:HasTag(hit.Parent, "Civilian") then
					WantedService:ReportCivilianDamage(caster, humanoid.Health <= 0)
				end
			else
				local result = DestructionService:Damage(hit, resolved.DamagePerProjectile)
				if result and result.Broke and hit:GetAttribute("OwnerId") ~= caster.UserId then
					WantedService:ReportPropertyDamage(caster, result.StructureDestroyed)
				end
			end
		end

		hitConnection:Disconnect()
		part:Destroy()
	end)

	Debris:AddItem(part, PROJECTILE_LIFETIME)
end

local function spreadDirection(baseDirection: Vector3, index: number, total: number): Vector3
	if total <= 1 then
		return baseDirection
	end
	local angle = math.rad(SPREAD_ANGLE_DEGREES) * (index - (total + 1) / 2)
	local rotation = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), angle)
	return rotation * baseDirection.Unit
end

local function handleCastSpell(player: Player, loadoutRaw: unknown)
	if typeof(loadoutRaw) ~= "table" then
		return
	end
	local loadout = loadoutRaw :: { [string]: any }

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local resolved = SpellBuilder.Resolve(loadout :: SpellBuilder.SpellLoadout)
	if not resolved then
		return
	end

	local mageLevel = PlayerDataService:GetMageLevel(player)
	if mageLevel < resolved.Word.MinMageLevel then
		return
	end

	local now = os.clock()
	if lastCastAt[player] and now - lastCastAt[player] < resolved.Word.Cooldown then
		return
	end

	if not PlayerDataService:TrySpendMana(player, resolved.TotalManaCost) then
		return
	end
	lastCastAt[player] = now

	PlayerDataService:AddXP(player, "Mage", resolved.TotalManaCost * MAGE_XP_PER_MANA_SPENT)

	local origin = rootPart.Position + Vector3.new(0, 1, 0)
	local baseDirection = rootPart.CFrame.LookVector
	if typeof(loadout.TargetPosition) == "Vector3" then
		local toTarget = (loadout.TargetPosition :: Vector3) - origin
		if toTarget.Magnitude > 0.1 then
			baseDirection = toTarget.Unit
		end
	end

	for castIndex = 1, resolved.Quantity do
		for projectileIndex = 1, resolved.ProjectileCount do
			local direction = spreadDirection(baseDirection, projectileIndex, resolved.ProjectileCount)
			spawnProjectile(origin, direction, resolved, player)
		end
		if castIndex < resolved.Quantity then
			task.wait(BURST_CAST_DELAY)
		end
	end
end

function SpellService:Start()
	castSpellEvent.OnServerEvent:Connect(handleCastSpell)

	Players.PlayerRemoving:Connect(function(player)
		lastCastAt[player] = nil
	end)
end

return SpellService
