local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local SpellBuilder = require(ReplicatedStorage.Shared.Spells.SpellBuilder)
local SpellSlots = require(ReplicatedStorage.Shared.Spells.SpellSlots)
local CharacterClasses = require(ReplicatedStorage.Shared.Character.CharacterClasses)

local PlayerDataService = require(ServerScriptService.Server.Services.PlayerDataService)
local DestructionService = require(ServerScriptService.Server.Services.DestructionService)
local WantedService = require(ServerScriptService.Server.Services.WantedService)
local TerrainDestructionService = require(ServerScriptService.Server.Services.TerrainDestructionService)

local MAGE_XP_PER_MANA_SPENT = 0.5
local COMBAT_XP_PER_HIT = 4
local PROJECTILE_LIFETIME = 4
local BASE_PROJECTILE_SIZE = Vector3.new(1, 1, 1)
local SPREAD_ANGLE_DEGREES = 14
local BEAM_MAX_RANGE = 100
local BEAM_STALE_TIMEOUT = 0.3
local BEAM_SWEEP_INTERVAL = 0.5
local BEAM_MAX_TICK_DT = 0.5

local SpellService = {}

local castSpellEvent = Net.GetEvent("CastSpell")
local castFailedEvent = Net.GetEvent("CastFailed")
local lastCastAt: { [Player]: { [string]: number } } = {}

type BeamSession = { Part: BasePart, StartedAt: number, LastTickAt: number, TerrainDamage: number }
local activeBeams: { [Player]: { [string]: BeamSession } } = {}

local function spawnProjectile(origin: Vector3, direction: Vector3, resolved: SpellBuilder.ResolvedSpell, caster: Player)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = BASE_PROJECTILE_SIZE * resolved.ProjectileScale
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

	print((
		"[SpellService] spawned projectile at %s size=%s velocity=%s"
	):format(tostring(part.Position), tostring(part.Size), tostring(velocity.VectorVelocity)))

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

local function fireBlast(player: Player, resolved: SpellBuilder.ResolvedSpell, slot: string, origin: Vector3, baseDirection: Vector3)
	local now = os.clock()
	local playerCooldowns = lastCastAt[player]
	if playerCooldowns and playerCooldowns[slot] and now - playerCooldowns[slot] < resolved.Cooldown then
		castFailedEvent:FireClient(player, "OnCooldown")
		return
	end

	local dataBeforeSpend = PlayerDataService:GetData(player)
	if not PlayerDataService:TrySpendMana(player, resolved.ManaCostPerCast) then
		castFailedEvent:FireClient(player, "NotEnoughMana", resolved.ManaCostPerCast, dataBeforeSpend and dataBeforeSpend.Mana or 0)
		return
	end

	if not playerCooldowns then
		playerCooldowns = {}
		lastCastAt[player] = playerCooldowns
	end
	playerCooldowns[slot] = now

	PlayerDataService:AddXP(player, "Mage", resolved.ManaCostPerCast * MAGE_XP_PER_MANA_SPENT)

	print((
		"[SpellService] %s cast %s in slot %s: Amount=%d Origin=%s Direction=%s"
	):format(player.Name, resolved.TypeId, slot, resolved.Amount, tostring(origin), tostring(baseDirection)))

	for projectileIndex = 1, resolved.Amount do
		local direction = spreadDirection(baseDirection, projectileIndex, resolved.Amount)
		spawnProjectile(origin, direction, resolved, player)
	end
end

-- ===== Beam Attack: a channeled, hit-scan beam. The client sends one CastSpell
-- message per tick (~10/sec) while its key is held instead of one message per cast,
-- so each incoming message here just advances an ongoing session by however much
-- time passed since the last one (dt-based), rather than needing a separate
-- server-side loop per beam. =====

local function destroyBeamSession(player: Player, slot: string)
	local sessions = activeBeams[player]
	if not sessions then
		return
	end
	local session = sessions[slot]
	if not session then
		return
	end
	session.Part:Destroy()
	sessions[slot] = nil
end

-- Cooldown is measured from when the beam ends, not when it started, so a full
-- Duration-length channel doesn't also make the player wait Cooldown starting from
-- the very beginning of the channel.
local function markCooldown(player: Player, slot: string)
	local playerCooldowns = lastCastAt[player]
	if not playerCooldowns then
		playerCooldowns = {}
		lastCastAt[player] = playerCooldowns
	end
	playerCooldowns[slot] = os.clock()
end

local function tickBeam(player: Player, resolved: SpellBuilder.ResolvedSpell, slot: string, origin: Vector3, direction: Vector3)
	local sessions = activeBeams[player]
	if not sessions then
		sessions = {}
		activeBeams[player] = sessions
	end

	local now = os.clock()
	local session = sessions[slot]
	if not session then
		local playerCooldowns = lastCastAt[player]
		if playerCooldowns and playerCooldowns[slot] and now - playerCooldowns[slot] < resolved.Cooldown then
			castFailedEvent:FireClient(player, "OnCooldown")
			return
		end

		local data = PlayerDataService:GetData(player)
		if not data or data.Mana <= 0 then
			castFailedEvent:FireClient(player, "NotEnoughMana", resolved.ManaCostPerSecond, data and data.Mana or 0)
			return
		end

		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		-- Without this, the beam's own visual is solid enough for raycasts to hit —
		-- both the server's damage raycast below (hitting last tick's beam instead of
		-- the real target) and the client's Mouse.Hit used to aim it — causing the
		-- beam to visibly bend toward/into itself as each tick re-aims off its own tail.
		part.CanQuery = false
		part.Shape = Enum.PartType.Cylinder
		part.Material = Enum.Material.Neon
		part.Color = resolved.Word.Color
		part.Transparency = 0.15
		part.Parent = workspace

		session = { Part = part, StartedAt = now, LastTickAt = now, TerrainDamage = 0 }
		sessions[slot] = session

		print((
			"[SpellService] %s started channeling %s in slot %s: Duration=%.1f ThicknessStuds=%.2f DamagePerSecond=%.1f Origin=%s Direction=%s"
		):format(player.Name, resolved.TypeId, slot, resolved.Duration, resolved.ThicknessStuds, resolved.DamagePerSecond, tostring(origin), tostring(direction)))
	end

	if now - session.StartedAt > resolved.Duration then
		destroyBeamSession(player, slot)
		markCooldown(player, slot)
		return
	end

	local dt = math.min(now - session.LastTickAt, BEAM_MAX_TICK_DT)
	session.LastTickAt = now

	local manaCost = resolved.ManaCostPerSecond * dt
	local dataBeforeSpend = PlayerDataService:GetData(player)
	if not PlayerDataService:TrySpendMana(player, manaCost) then
		castFailedEvent:FireClient(player, "NotEnoughMana", manaCost, dataBeforeSpend and dataBeforeSpend.Mana or 0)
		destroyBeamSession(player, slot)
		markCooldown(player, slot)
		return
	end

	PlayerDataService:AddXP(player, "Mage", manaCost * MAGE_XP_PER_MANA_SPENT)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local character = player.Character
	raycastParams.FilterDescendantsInstances = character and { character } or {}
	local result = workspace:Raycast(origin, direction * BEAM_MAX_RANGE, raycastParams)
	local endPoint = result and result.Position or (origin + direction * BEAM_MAX_RANGE)

	local distance = (endPoint - origin).Magnitude
	-- A cylinder's long axis is local X (not Z like a Block), so after centering the
	-- part at the midpoint the same way as before, an extra 90-degree spin around Y
	-- swaps what was pointing along -Z (the lookAt direction) onto the X axis.
	session.Part.Size = Vector3.new(distance, resolved.ThicknessStuds, resolved.ThicknessStuds)
	session.Part.CFrame = CFrame.new(origin, endPoint) * CFrame.new(0, 0, -distance / 2) * CFrame.Angles(0, math.rad(90), 0)

	print((
		"[SpellService] beam tick slot=%s distance=%.1f endPoint=%s hit=%s"
	):format(slot, distance, tostring(endPoint), result and result.Instance:GetFullName() or "nothing"))

	if result then
		local hitInstance = result.Instance
		local damageThisTick = resolved.DamagePerSecond * dt

		if hitInstance == workspace.Terrain then
			-- Carve with the beam's total accumulated terrain damage this session (not
			-- just this tick's sliver) so holding the beam on the same spot visibly
			-- grows the crater over time instead of re-carving the same tiny radius
			-- every 0.1s — the intended way to eventually punch through a mountain.
			session.TerrainDamage += damageThisTick
			TerrainDestructionService:Carve(result.Position, session.TerrainDamage)
		else
			local humanoid = hitInstance.Parent and hitInstance.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				hitInstance.Parent:SetAttribute("LastDamagedByUserId", player.UserId)
				humanoid:TakeDamage(damageThisTick)
				PlayerDataService:AddXP(player, "Combat", damageThisTick)
				if CollectionService:HasTag(hitInstance.Parent, "Civilian") then
					WantedService:ReportCivilianDamage(player, humanoid.Health <= 0)
				end
			else
				local destructionResult = DestructionService:Damage(hitInstance, damageThisTick)
				if destructionResult and destructionResult.Broke and hitInstance:GetAttribute("OwnerId") ~= player.UserId then
					WantedService:ReportPropertyDamage(player, destructionResult.StructureDestroyed)
				end
			end
		end
	end
end

local function handleCastSpell(player: Player, payload: unknown)
	if typeof(payload) ~= "table" then
		return
	end
	local command = payload :: { [string]: any }
	local slot = command.Slot
	if typeof(slot) ~= "string" or not table.find(SpellSlots.Order, slot) then
		return
	end

	if command.Stop == true then
		destroyBeamSession(player, slot)
		return
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		warn(("[SpellService] %s tried to cast %s with no HumanoidRootPart"):format(player.Name, slot))
		return
	end

	local playerData = PlayerDataService:GetData(player)
	if not playerData or not playerData.CharacterClass then
		warn(("[SpellService] %s tried to cast %s with no CharacterClass assigned"):format(player.Name, slot))
		return
	end

	local classDef = CharacterClasses[playerData.CharacterClass]
	local word = classDef and classDef.Word
	if not word then
		warn(("[SpellService] %s's class %s has no Word mapped"):format(player.Name, tostring(playerData.CharacterClass)))
		return
	end

	local mageLevel = PlayerDataService:GetMageLevel(player)
	if not SpellSlots.IsUnlocked(slot, mageLevel) then
		warn(("[SpellService] %s tried to cast slot %s, locked until a higher mage level"):format(player.Name, slot))
		return
	end

	local spellData = playerData.Spells[slot]
	if not spellData then
		warn(("[SpellService] %s tried to cast slot %s, which has no saved spell"):format(player.Name, slot))
		return
	end

	local resolved = SpellBuilder.Resolve(word, spellData, mageLevel)
	if not resolved then
		warn(("[SpellService] %s's spell in slot %s failed to resolve (unknown Word %s)"):format(player.Name, slot, word))
		return
	end

	local origin = rootPart.Position + Vector3.new(0, 1, 0)
	local baseDirection = rootPart.CFrame.LookVector
	if typeof(command.TargetPosition) == "Vector3" then
		local toTarget = (command.TargetPosition :: Vector3) - origin
		if toTarget.Magnitude > 0.1 then
			baseDirection = toTarget.Unit
		end
	end

	if resolved.TypeId == "BeamAttack" then
		tickBeam(player, resolved, slot, origin, baseDirection)
	else
		fireBlast(player, resolved, slot, origin, baseDirection)
	end
end

function SpellService:Start()
	castSpellEvent.OnServerEvent:Connect(handleCastSpell)

	Players.PlayerRemoving:Connect(function(player)
		lastCastAt[player] = nil
		local sessions = activeBeams[player]
		if sessions then
			for slot in sessions do
				destroyBeamSession(player, slot)
			end
			activeBeams[player] = nil
		end
	end)

	-- Safety net: if a client stops sending ticks without an explicit Stop (e.g. a
	-- dropped connection) the beam would otherwise persist forever.
	task.spawn(function()
		while true do
			task.wait(BEAM_SWEEP_INTERVAL)
			local now = os.clock()
			for player, sessions in activeBeams do
				for slot, session in sessions do
					if now - session.LastTickAt > BEAM_STALE_TIMEOUT then
						destroyBeamSession(player, slot)
					end
				end
			end
		end
	end)
end

return SpellService
