local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage.Shared.Framework.Net)

local TOGGLE_KEY = Enum.KeyCode.F6

local player = Players.LocalPlayer
local adminAuthorizedEvent = Net.GetEvent("AdminAuthorized")
local adminCommandEvent = Net.GetEvent("AdminCommand")

local AdminController = {}

local function sendCommand(action: string, value: number?)
	adminCommandEvent:FireServer({ Action = action, Value = value })
end

local function createRow(parent: Instance, layoutOrder: number, labelText: string, onSubmit: (number) -> ())
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.BackgroundTransparency = 1
	row.LayoutOrder = layoutOrder
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.45, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = labelText
	label.Parent = row

	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(0.3, -4, 1, 0)
	textBox.Position = UDim2.new(0.45, 4, 0, 0)
	textBox.Text = ""
	textBox.PlaceholderText = "0"
	textBox.ClearTextOnFocus = false
	textBox.Font = Enum.Font.Gotham
	textBox.TextSize = 14
	textBox.Parent = row

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.25, -4, 1, 0)
	button.Position = UDim2.new(0.75, 4, 0, 0)
	button.BackgroundColor3 = Color3.fromRGB(70, 100, 200)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.Text = "Set"
	button.Parent = row

	button.MouseButton1Click:Connect(function()
		local value = tonumber(textBox.Text)
		if value then
			onSubmit(value)
		end
	end)
end

local function buildPanel(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminPanelGui"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(320, 300)
	panel.Position = UDim2.new(0, 20, 0, 20)
	panel.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	panel.BackgroundTransparency = 0.1
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = panel

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 24)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = "Admin Panel (F6 to toggle)"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.LayoutOrder = 0
	title.Parent = panel

	createRow(panel, 1, "Gold", function(value)
		sendCommand("SetGold", value)
	end)
	createRow(panel, 2, "Silver", function(value)
		sendCommand("SetSilver", value)
	end)
	createRow(panel, 3, "Mage Level", function(value)
		sendCommand("SetMageLevel", value)
	end)
	createRow(panel, 4, "Combat Level", function(value)
		sendCommand("SetCombatLevel", value)
	end)
	createRow(panel, 5, "Character Level", function(value)
		sendCommand("SetCharacterLevel", value)
	end)

	local refillButton = Instance.new("TextButton")
	refillButton.Size = UDim2.new(1, 0, 0, 32)
	refillButton.BackgroundColor3 = Color3.fromRGB(90, 140, 255)
	refillButton.TextColor3 = Color3.new(1, 1, 1)
	refillButton.Font = Enum.Font.GothamBold
	refillButton.TextSize = 14
	refillButton.Text = "Refill Mana"
	refillButton.LayoutOrder = 6
	refillButton.Parent = panel

	refillButton.MouseButton1Click:Connect(function()
		sendCommand("RefillMana")
	end)

	local resetClassButton = Instance.new("TextButton")
	resetClassButton.Size = UDim2.new(1, 0, 0, 32)
	resetClassButton.BackgroundColor3 = Color3.fromRGB(150, 90, 90)
	resetClassButton.TextColor3 = Color3.new(1, 1, 1)
	resetClassButton.Font = Enum.Font.GothamBold
	resetClassButton.TextSize = 14
	resetClassButton.Text = "Reset Class (re-pick path)"
	resetClassButton.LayoutOrder = 7
	resetClassButton.Parent = panel

	resetClassButton.MouseButton1Click:Connect(function()
		sendCommand("ResetClass")
	end)

	return screenGui
end

function AdminController:Start()
	local screenGui: ScreenGui? = nil

	adminAuthorizedEvent.OnClientEvent:Connect(function()
		if not screenGui then
			screenGui = buildPanel()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or input.KeyCode ~= TOGGLE_KEY then
			return
		end
		if screenGui then
			screenGui.Enabled = not screenGui.Enabled
		end
	end)
end

return AdminController
