local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BlockyHumanoid = require(ReplicatedStorage.Shared.NPC.BlockyHumanoid)

-- Placeholder AI: the enforcer glides straight toward the player every tick with no
-- obstacle avoidance or pathfinding. Good enough to prove "more stars = tougher
-- enforcer"; a real navigation-based AI is a separate future system.
local CHASE_TICK = 0.2
local CHASE_LERP_ALPHA = 0.08
local TOUCH_DAMAGE_COOLDOWN = 1
local DESPAWN_AFTER_DEATH_DELAY = 2
local SPAWN_OFFSET = Vector3.new(6, 0, 6)

local BASE_HEALTH = 50
local HEALTH_PER_STAR = 30
local BASE_DAMAGE = 5
local DAMAGE_PER_STAR = 4

local LawEnforcerService = {}

local enforcersByPlayer: { [Player]: Model } = {}

function LawEnforcerService:DespawnEnforcer(player: Player)
	local enforcer = enforcersByPlayer[player]
	if enforcer then
		enforcersByPlayer[player] = nil
		enforcer:Destroy()
	end
end

function LawEnforcerService:SpawnEnforcer(player: Player, wantedLevel: number)
	self:DespawnEnforcer(player)

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local maxHealth = BASE_HEALTH + HEALTH_PER_STAR * wantedLevel
	local damage = BASE_DAMAGE + DAMAGE_PER_STAR * wantedLevel

	local model = BlockyHumanoid.Build({
		Name = "LawEnforcer",
		Position = rootPart.Position + SPAWN_OFFSET,
		MaxHealth = maxHealth,
		TorsoColor = Color3.fromRGB(40, 60, 140),
	})
	model.Parent = workspace
	enforcersByPlayer[player] = model

	local torso = model:FindFirstChild("Torso") :: BasePart
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid

	local lastTouchDamageAt = 0
	torso.Touched:Connect(function(hit)
		local hitCharacter = hit.Parent
		local hitHumanoid = hitCharacter and hitCharacter:FindFirstChildOfClass("Humanoid")
		if not hitHumanoid or Players:GetPlayerFromCharacter(hitCharacter) ~= player then
			return
		end
		local now = os.clock()
		if now - lastTouchDamageAt >= TOUCH_DAMAGE_COOLDOWN then
			lastTouchDamageAt = now
			hitHumanoid:TakeDamage(damage)
		end
	end)

	humanoid.Died:Connect(function()
		task.wait(DESPAWN_AFTER_DEATH_DELAY)
		if enforcersByPlayer[player] == model then
			enforcersByPlayer[player] = nil
		end
		model:Destroy()
	end)

	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			local targetCharacter = player.Character
			local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local newPosition = torso.Position:Lerp(targetRoot.Position, CHASE_LERP_ALPHA)
				torso.CFrame = CFrame.new(newPosition) * (torso.CFrame - torso.Position)
			end
			task.wait(CHASE_TICK)
		end
	end)
end

return LawEnforcerService
