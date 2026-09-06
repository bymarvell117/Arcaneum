local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Framework.Net)

local player = Players.LocalPlayer
local currencyUpdatedEvent = Net.GetEvent("CurrencyUpdated")

local CurrencyController = {}

local function buildUI(): TextLabel
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CurrencyGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(220, 24)
	label.Position = UDim2.new(0, 16, 0, 48)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	label.BackgroundTransparency = 0.3
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "  Silver: 0    Gold: 0"
	label.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label

	return label
end

function CurrencyController:Start()
	local label = buildUI()

	currencyUpdatedEvent.OnClientEvent:Connect(function(silver: number, gold: number)
		label.Text = ("  Silver: %d    Gold: %d"):format(silver, gold)
	end)
end

return CurrencyController
