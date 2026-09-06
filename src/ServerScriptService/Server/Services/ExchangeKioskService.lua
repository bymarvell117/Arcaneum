-- Spawns a small physical kiosk with a ProximityPrompt so the currency exchange has a
-- place in the world to test from, instead of just being a hidden remote.
local KIOSK_POSITION = Vector3.new(-15, 2, 25)

local ExchangeKioskService = {}

function ExchangeKioskService:Start()
	local stand = Instance.new("Part")
	stand.Name = "ExchangeKiosk"
	stand.Size = Vector3.new(3, 4, 3)
	stand.Color = Color3.fromRGB(210, 180, 80)
	stand.Material = Enum.Material.Wood
	stand.Anchored = true
	stand.CFrame = CFrame.new(KIOSK_POSITION)
	stand.Parent = workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ExchangePrompt"
	prompt.ActionText = "Exchange Currency"
	prompt.ObjectText = "Kiosk"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.Parent = stand
end

return ExchangeKioskService
