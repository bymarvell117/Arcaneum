local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Framework.Net)

local player = Players.LocalPlayer
local questUpdatedEvent = Net.GetEvent("QuestUpdated")

local QuestController = {}

type QuestEntry = { Name: string, Progress: number, Target: number }
type QuestUpdatePayload = { Side: QuestEntry?, Story: QuestEntry? }

local function buildUI(): (TextLabel, TextLabel)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuestGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromOffset(280, 60)
	container.Position = UDim2.new(0, 16, 0, 78)
	container.Parent = screenGui

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 4)
	list.Parent = container

	local function makeLabel(layoutOrder: number): TextLabel
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 26)
		label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		label.BackgroundTransparency = 0.3
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = layoutOrder
		label.Visible = false

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = label

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 8)
		padding.Parent = label

		label.Parent = container
		return label
	end

	local storyLabel = makeLabel(1)
	local sideLabel = makeLabel(2)
	return storyLabel, sideLabel
end

function QuestController:Start()
	local storyLabel, sideLabel = buildUI()

	questUpdatedEvent.OnClientEvent:Connect(function(payload: QuestUpdatePayload)
		if payload.Story then
			storyLabel.Text = ("  Story: %s (%d/%d)"):format(payload.Story.Name, payload.Story.Progress, payload.Story.Target)
			storyLabel.Visible = true
		else
			storyLabel.Visible = false
		end

		if payload.Side then
			sideLabel.Text = ("  Quest: %s (%d/%d)"):format(payload.Side.Name, payload.Side.Progress, payload.Side.Target)
			sideLabel.Visible = true
		else
			sideLabel.Visible = false
		end
	end)
end

return QuestController
