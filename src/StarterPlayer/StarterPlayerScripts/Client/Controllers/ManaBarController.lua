local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Framework.Net)

local player = Players.LocalPlayer
local manaUpdated = Net.GetEvent("ManaUpdated")
local characterClassAssignedEvent = Net.GetEvent("CharacterClassAssigned")
local getCharacterClassFunction = Net.GetFunction("GetCharacterClass")

local ManaBarController = {}

local function buildUI(): (ScreenGui, Frame, TextLabel)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ManaBarGui"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local background = Instance.new("Frame")
	background.Size = UDim2.fromOffset(220, 22)
	background.Position = UDim2.new(0.5, -110, 1, -50)
	background.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	background.BorderSizePixel = 0
	background.Parent = screenGui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(90, 140, 255)
	fill.BorderSizePixel = 0
	fill.Parent = background

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Text = ""
	label.Parent = background

	return screenGui, fill, label
end

function ManaBarController:Start()
	local screenGui, fill, label = buildUI()

	manaUpdated.OnClientEvent:Connect(function(currentMana: number, maxMana: number)
		local ratio = maxMana > 0 and math.clamp(currentMana / maxMana, 0, 1) or 0
		fill.Size = UDim2.fromScale(ratio, 1)
		label.Text = ("%d / %d"):format(math.floor(currentMana), math.floor(maxMana))
	end)

	characterClassAssignedEvent.OnClientEvent:Connect(function(classId: string?)
		screenGui.Enabled = classId ~= "WitchSlayer"
	end)

	-- Pull the current class instead of only relying on the server's push, which
	-- could fire before this script had connected the listener above.
	screenGui.Enabled = getCharacterClassFunction:InvokeServer() ~= "WitchSlayer"
end

return ManaBarController
