local ServerScriptService = game:GetService("ServerScriptService")

local QuestService = require(ServerScriptService.Server.Services.QuestService)

local QUEST_GIVER_POSITION = Vector3.new(-5, 3, 20)
local SIDE_QUEST_ID = "SideDefeatDummies"

local QuestGiverService = {}

function QuestGiverService:Start()
	local marker = Instance.new("Part")
	marker.Name = "QuestGiver"
	marker.Shape = Enum.PartType.Ball
	marker.Size = Vector3.new(2, 2, 2)
	marker.Color = Color3.fromRGB(230, 200, 60)
	marker.Material = Enum.Material.Neon
	marker.Anchored = true
	marker.CanCollide = false
	marker.CFrame = CFrame.new(QUEST_GIVER_POSITION)
	marker.Parent = workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "QuestPrompt"
	prompt.ActionText = "Accept Quest: Pest Control"
	prompt.ObjectText = "Quest Giver"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.Parent = marker

	prompt.Triggered:Connect(function(player)
		QuestService:TryAcceptSideQuest(player, SIDE_QUEST_ID)
	end)
end

return QuestGiverService
