local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local CharacterClasses = require(ReplicatedStorage.Shared.Character.CharacterClasses)

local CLASS_ORDER = { "FireMage", "IceMage", "StormMage", "WitchSlayer" }

local player = Players.LocalPlayer
local characterClassAssignedEvent = Net.GetEvent("CharacterClassAssigned")
local selectCharacterClassEvent = Net.GetEvent("SelectCharacterClass")

local CharacterCreationController = {}

CharacterCreationController.SelectedClass = nil :: string?

local function buildCard(parent: Instance, classId: string, onPick: (string) -> ())
	local definition = CharacterClasses[classId]

	local card = Instance.new("TextButton")
	card.Text = ""
	card.BackgroundColor3 = definition.IsMage and Color3.fromRGB(50, 60, 100) or Color3.fromRGB(90, 40, 40)
	card.AutoButtonColor = true
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = definition.Name
	nameLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, 0, 1, -26)
	descLabel.Position = UDim2.new(0, 0, 0, 26)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 13
	descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Text = definition.Description
	descLabel.Parent = card

	card.MouseButton1Click:Connect(function()
		onPick(classId)
	end)
end

local function buildUI(onPick: (string) -> ()): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CharacterCreationGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.Enabled = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.35
	backdrop.Parent = screenGui

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(560, 320)
	panel.Position = UDim2.new(0.5, -280, 0.5, -160)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.Parent = backdrop

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = "Choose Your Path"
	title.Parent = panel

	local cardsContainer = Instance.new("Frame")
	cardsContainer.Size = UDim2.new(1, -32, 1, -56)
	cardsContainer.Position = UDim2.new(0, 16, 0, 48)
	cardsContainer.BackgroundTransparency = 1
	cardsContainer.Parent = panel

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(256, 110)
	grid.CellPadding = UDim2.fromOffset(16, 16)
	grid.Parent = cardsContainer

	for _, classId in CLASS_ORDER do
		buildCard(cardsContainer, classId, onPick)
	end

	return screenGui
end

function CharacterCreationController:Start()
	local screenGui = buildUI(function(classId: string)
		selectCharacterClassEvent:FireServer(classId)
		screenGui.Enabled = false
	end)

	characterClassAssignedEvent.OnClientEvent:Connect(function(classId: string?)
		CharacterCreationController.SelectedClass = classId
		screenGui.Enabled = (classId == nil)
	end)
end

return CharacterCreationController
