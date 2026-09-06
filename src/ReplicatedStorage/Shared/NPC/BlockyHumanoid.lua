export type BlockyHumanoidOptions = {
	Name: string,
	Position: Vector3,
	MaxHealth: number,
	TorsoColor: Color3,
}

local BlockyHumanoid = {}

function BlockyHumanoid.Build(options: BlockyHumanoidOptions): Model
	local model = Instance.new("Model")
	model.Name = options.Name

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = options.TorsoColor
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = true
	torso.CFrame = CFrame.new(options.Position)
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Color = Color3.fromRGB(230, 200, 170)
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = torso.CFrame * CFrame.new(0, 1.6, 0)
	head.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = options.MaxHealth
	humanoid.Health = options.MaxHealth
	humanoid.Parent = model

	return model
end

return BlockyHumanoid
