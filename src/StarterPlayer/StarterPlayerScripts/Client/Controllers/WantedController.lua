local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Framework.Net)

local MAX_STARS = 5
local STAR_SIZE = 24
local STAR_GAP = 2
local FILLED_COLOR = Color3.fromRGB(255, 210, 60)
local EMPTY_COLOR = Color3.fromRGB(80, 80, 90)

local player = Players.LocalPlayer
local wantedUpdatedEvent = Net.GetEvent("WantedUpdated")

local WantedController = {}

local function buildUI(): { TextLabel }
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "WantedGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local totalWidth = MAX_STARS * STAR_SIZE + (MAX_STARS - 1) * STAR_GAP
	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.fromOffset(totalWidth, STAR_SIZE)
	container.Position = UDim2.new(1, -totalWidth - 16, 0, 16)
	container.Parent = screenGui

	local stars = {}
	for i = 1, MAX_STARS do
		local star = Instance.new("TextLabel")
		star.Size = UDim2.fromOffset(STAR_SIZE, STAR_SIZE)
		star.Position = UDim2.fromOffset((i - 1) * (STAR_SIZE + STAR_GAP), 0)
		star.BackgroundTransparency = 1
		star.Font = Enum.Font.GothamBold
		star.TextSize = 22
		star.TextColor3 = EMPTY_COLOR
		star.Text = "★"
		star.Parent = container
		stars[i] = star
	end

	return stars
end

function WantedController:Start()
	local stars = buildUI()

	wantedUpdatedEvent.OnClientEvent:Connect(function(level: number)
		local filled = math.floor(level + 0.5)
		for i, star in stars do
			star.TextColor3 = i <= filled and FILLED_COLOR or EMPTY_COLOR
		end
	end)
end

return WantedController
