local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Framework.Net)

local player = Players.LocalPlayer
local exchangeCurrencyEvent = Net.GetEvent("ExchangeCurrency")

local ExchangeController = {}

local function sendExchange(action: string)
	exchangeCurrencyEvent:FireServer({ Action = action, Units = 1 })
end

local function buildPanel(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ExchangeGui"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(280, 140)
	panel.Position = UDim2.new(0.5, -140, 0.5, -70)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.1
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = panel

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 24)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = "Currency Exchange"
	title.LayoutOrder = 0
	title.Parent = panel

	local silverToGoldButton = Instance.new("TextButton")
	silverToGoldButton.Size = UDim2.new(1, 0, 0, 36)
	silverToGoldButton.BackgroundColor3 = Color3.fromRGB(210, 180, 80)
	silverToGoldButton.TextColor3 = Color3.new(0, 0, 0)
	silverToGoldButton.Font = Enum.Font.GothamBold
	silverToGoldButton.TextSize = 14
	silverToGoldButton.Text = "Convert 10 Silver -> 1 Gold"
	silverToGoldButton.LayoutOrder = 1
	silverToGoldButton.Parent = panel
	silverToGoldButton.MouseButton1Click:Connect(function()
		sendExchange("SilverToGold")
	end)

	local goldToSilverButton = Instance.new("TextButton")
	goldToSilverButton.Size = UDim2.new(1, 0, 0, 36)
	goldToSilverButton.BackgroundColor3 = Color3.fromRGB(180, 180, 190)
	goldToSilverButton.TextColor3 = Color3.new(0, 0, 0)
	goldToSilverButton.Font = Enum.Font.GothamBold
	goldToSilverButton.TextSize = 14
	goldToSilverButton.Text = "Convert 1 Gold -> 10 Silver"
	goldToSilverButton.LayoutOrder = 2
	goldToSilverButton.Parent = panel
	goldToSilverButton.MouseButton1Click:Connect(function()
		sendExchange("GoldToSilver")
	end)

	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(1, 0, 0, 28)
	closeButton.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.Font = Enum.Font.Gotham
	closeButton.TextSize = 13
	closeButton.Text = "Close"
	closeButton.LayoutOrder = 3
	closeButton.Parent = panel
	closeButton.MouseButton1Click:Connect(function()
		screenGui.Enabled = false
	end)

	return screenGui
end

function ExchangeController:Start()
	local screenGui = buildPanel()

	local function hookPrompt(prompt: ProximityPrompt)
		prompt.Triggered:Connect(function(triggeringPlayer)
			if triggeringPlayer == player then
				screenGui.Enabled = not screenGui.Enabled
			end
		end)
	end

	local existingKiosk = workspace:FindFirstChild("ExchangeKiosk")
	if existingKiosk then
		local prompt = existingKiosk:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			hookPrompt(prompt)
		end
	end

	workspace.ChildAdded:Connect(function(child)
		if child.Name == "ExchangeKiosk" then
			local prompt = child:WaitForChild("ExchangePrompt")
			hookPrompt(prompt :: ProximityPrompt)
		end
	end)
end

return ExchangeController
