local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Framework.Net)
local AppearancePalette = require(ReplicatedStorage.Shared.Character.AppearancePalette)
local MagicTypes = require(ReplicatedStorage.Shared.Character.MagicTypes)

local MAGIC_GRID_WIDTH = 640
local MAGIC_GRID_HEIGHT = 560
local MAGIC_CARD_SIZE = UDim2.fromOffset(112, 74)
local MAGIC_CARD_PADDING = UDim2.fromOffset(10, 10)
local DEFAULT_SKIN_INDEX = 3
local DEFAULT_SHIRT_INDEX = 3
local DEFAULT_PANTS_INDEX = 11
local SWATCH_SIZE = 28
local SWATCH_GAP = 6

local player = Players.LocalPlayer
local characterClassAssignedEvent = Net.GetEvent("CharacterClassAssigned")
local selectCharacterClassEvent = Net.GetEvent("SelectCharacterClass")
local getCharacterClassFunction = Net.GetFunction("GetCharacterClass")
local setAppearanceEvent = Net.GetEvent("SetAppearance")

local CharacterCreationController = {}

CharacterCreationController.SelectedClass = nil :: string?

-- ===== Shared panel chrome =====

local function buildPanel(parent: Instance, titleText: string, width: number?, height: number?): (Frame, Frame)
	local panelWidth = width or 560
	local panelHeight = height or 420

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
	panel.Position = UDim2.new(0.5, -panelWidth / 2, 0.5, -panelHeight / 2)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = titleText
	title.Parent = panel

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, -32, 1, -56)
	body.Position = UDim2.new(0, 16, 0, 48)
	body.BackgroundTransparency = 1
	body.Parent = panel

	return panel, body
end

-- ===== Step 2: magic type picker =====

-- Cards for the ~20 magic types shown here always carry their intended color (matching
-- the full-catalog reference), but only the ones with a real ClassId behind them
-- (Fire/Ice/Lightning/Earth right now) are clickable — the rest are washed out and
-- tagged "Soon", same pattern as the spell-type picker in MagicMenuController.
local function buildMagicTypeCard(parent: Instance, magicType: MagicTypes.MagicTypeDefinition, onPick: (string) -> ())
	local card = Instance.new("TextButton")
	card.Text = ""
	card.BackgroundColor3 = magicType.Color
	card.BackgroundTransparency = magicType.Implemented and 0 or 0.6
	card.AutoButtonColor = magicType.Implemented
	card.Parent = parent

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -8, 0, 20)
	nameLabel.Position = UDim2.new(0, 4, 1, -24)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = magicType.Implemented and Color3.new(0, 0, 0) or Color3.fromRGB(230, 230, 230)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = magicType.DisplayName
	nameLabel.Parent = card

	if magicType.Implemented and magicType.ClassId then
		local classId = magicType.ClassId :: string
		card.MouseButton1Click:Connect(function()
			onPick(classId)
		end)
	else
		local soonLabel = Instance.new("TextLabel")
		soonLabel.Size = UDim2.new(1, -8, 0, 16)
		soonLabel.Position = UDim2.new(0, 4, 0, 6)
		soonLabel.BackgroundTransparency = 1
		soonLabel.Font = Enum.Font.Gotham
		soonLabel.TextSize = 10
		soonLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
		soonLabel.TextXAlignment = Enum.TextXAlignment.Left
		soonLabel.Text = "Soon"
		soonLabel.Parent = card
	end
end

local function buildMagicGridPage(parent: Instance, onPick: (string) -> ()): Frame
	local panel, body = buildPanel(parent, "Choose a Magic", MAGIC_GRID_WIDTH, MAGIC_GRID_HEIGHT)

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, 0, 1, -48)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = body

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = MAGIC_CARD_SIZE
	grid.CellPadding = MAGIC_CARD_PADDING
	grid.Parent = scrollFrame

	for _, typeId in MagicTypes.Order do
		buildMagicTypeCard(scrollFrame, MagicTypes.Definitions[typeId], onPick)
	end

	local witchSlayerButton = Instance.new("TextButton")
	witchSlayerButton.Size = UDim2.new(1, 0, 0, 40)
	witchSlayerButton.Position = UDim2.new(0, 0, 1, -40)
	witchSlayerButton.BackgroundColor3 = Color3.fromRGB(90, 40, 40)
	witchSlayerButton.TextColor3 = Color3.new(1, 1, 1)
	witchSlayerButton.Font = Enum.Font.GothamBold
	witchSlayerButton.TextSize = 15
	witchSlayerButton.Text = "No Magic — Witch Slayer"
	witchSlayerButton.Parent = body

	local witchSlayerCorner = Instance.new("UICorner")
	witchSlayerCorner.CornerRadius = UDim.new(0, 6)
	witchSlayerCorner.Parent = witchSlayerButton

	witchSlayerButton.MouseButton1Click:Connect(function()
		onPick("WitchSlayer")
	end)

	return panel
end

-- ===== Step 1: appearance customizer =====

local function buildPreviewViewport(parent: Instance): (ViewportFrame, (Color3, Color3, Color3) -> ())
	local viewportFrame = Instance.new("ViewportFrame")
	viewportFrame.Size = UDim2.new(0.4, 0, 1, 0)
	viewportFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
	viewportFrame.LightColor = Color3.new(1, 1, 1)
	viewportFrame.Ambient = Color3.fromRGB(140, 140, 140)
	viewportFrame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = viewportFrame

	local previewModel = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	for _, descendant in previewModel:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	previewModel.Parent = viewportFrame

	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	-- Framing distance from height (size.Y), not depth (size.Z) — a humanoid is only
	-- ~1-2 studs deep front-to-back, so using that put the camera far too close and
	-- clipped through the model.
	local center, size = previewModel:GetBoundingBox()
	camera.CFrame = CFrame.new(center.Position + Vector3.new(0, 0, size.Y + 3), center.Position)

	local humanoid = previewModel:WaitForChild("Humanoid") :: Humanoid

	local function refresh(skin: Color3, shirt: Color3, pants: Color3)
		local description = Instance.new("HumanoidDescription")
		description.HeadColor = skin
		description.TorsoColor = shirt
		description.LeftArmColor = shirt
		description.RightArmColor = shirt
		description.LeftLegColor = pants
		description.RightLegColor = pants
		humanoid:ApplyDescription(description)
	end

	return viewportFrame, refresh
end

local function buildColorRow(
	parent: Instance,
	layoutOrder: number,
	labelText: string,
	palette: { Color3 },
	initialIndex: number,
	onPick: (Color3) -> ()
): { [number]: TextButton }
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 56)
	row.BackgroundTransparency = 1
	row.LayoutOrder = layoutOrder
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = labelText
	label.Parent = row

	local swatchContainer = Instance.new("Frame")
	swatchContainer.Size = UDim2.new(1, 0, 0, SWATCH_SIZE)
	swatchContainer.Position = UDim2.new(0, 0, 0, 22)
	swatchContainer.BackgroundTransparency = 1
	swatchContainer.Parent = row

	local swatches: { [number]: TextButton } = {}

	for index, color in palette do
		local swatch = Instance.new("TextButton")
		swatch.Text = ""
		swatch.Size = UDim2.fromOffset(SWATCH_SIZE, SWATCH_SIZE)
		swatch.Position = UDim2.fromOffset((index - 1) * (SWATCH_SIZE + SWATCH_GAP), 0)
		swatch.BackgroundColor3 = color
		swatch.AutoButtonColor = false
		swatch.Parent = swatchContainer

		local swatchCorner = Instance.new("UICorner")
		swatchCorner.CornerRadius = UDim.new(0, 6)
		swatchCorner.Parent = swatch

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = index == initialIndex and 0 or 1
		stroke.Parent = swatch

		swatches[index] = swatch

		swatch.MouseButton1Click:Connect(function()
			for otherIndex, otherSwatch in swatches do
				local otherStroke = otherSwatch:FindFirstChildOfClass("UIStroke")
				if otherStroke then
					otherStroke.Transparency = otherIndex == index and 0 or 1
				end
			end
			onPick(color)
		end)
	end

	return swatches
end

local function buildAppearancePage(parent: Instance, onNext: (Color3, Color3, Color3) -> ()): Frame
	local panel, body = buildPanel(parent, "Customize Your Character")

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 16)
	layout.Parent = body

	local viewportFrame, refreshPreview = buildPreviewViewport(body)
	viewportFrame.LayoutOrder = 1

	local controls = Instance.new("Frame")
	controls.Size = UDim2.new(0.6, -16, 1, 0)
	controls.BackgroundTransparency = 1
	controls.LayoutOrder = 2
	controls.Parent = body

	local controlsList = Instance.new("UIListLayout")
	controlsList.Padding = UDim.new(0, 10)
	controlsList.Parent = controls

	local selectedSkin = AppearancePalette.SkinColors[DEFAULT_SKIN_INDEX]
	local selectedShirt = AppearancePalette.OutfitColors[DEFAULT_SHIRT_INDEX]
	local selectedPants = AppearancePalette.OutfitColors[DEFAULT_PANTS_INDEX]
	refreshPreview(selectedSkin, selectedShirt, selectedPants)

	buildColorRow(controls, 1, "Skin Color", AppearancePalette.SkinColors, DEFAULT_SKIN_INDEX, function(color)
		selectedSkin = color
		refreshPreview(selectedSkin, selectedShirt, selectedPants)
	end)
	buildColorRow(controls, 2, "Shirt Color", AppearancePalette.OutfitColors, DEFAULT_SHIRT_INDEX, function(color)
		selectedShirt = color
		refreshPreview(selectedSkin, selectedShirt, selectedPants)
	end)
	buildColorRow(controls, 3, "Pants Color", AppearancePalette.OutfitColors, DEFAULT_PANTS_INDEX, function(color)
		selectedPants = color
		refreshPreview(selectedSkin, selectedShirt, selectedPants)
	end)

	local nextButton = Instance.new("TextButton")
	nextButton.Size = UDim2.new(1, 0, 0, 36)
	nextButton.BackgroundColor3 = Color3.fromRGB(80, 160, 90)
	nextButton.TextColor3 = Color3.new(1, 1, 1)
	nextButton.Font = Enum.Font.GothamBold
	nextButton.TextSize = 15
	nextButton.Text = "Next"
	nextButton.LayoutOrder = 4
	nextButton.Parent = controls

	nextButton.MouseButton1Click:Connect(function()
		onNext(selectedSkin, selectedShirt, selectedPants)
	end)

	return panel
end

-- ===== Wizard wiring =====

function CharacterCreationController:Start()
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

	-- Declared before assignment (not `local classPage = buildMagicGridPage(...)`) because
	-- the appearance page's own "Next" button closure below needs to reference
	-- `appearancePage` from inside its own initializing expression — in Lua, a local
	-- only becomes visible to closures created *after* its declaration statement
	-- finishes, so referencing it from within that same statement would silently
	-- resolve to an unrelated global (nil) instead of erroring loudly.
	local classPage: Frame
	local appearancePage: Frame

	classPage = buildMagicGridPage(backdrop, function(classId: string)
		selectCharacterClassEvent:FireServer(classId)
		screenGui.Enabled = false
	end)
	classPage.Visible = false

	appearancePage = buildAppearancePage(backdrop, function(skin: Color3, shirt: Color3, pants: Color3)
		setAppearanceEvent:FireServer({
			Skin = { R = skin.R, G = skin.G, B = skin.B },
			Shirt = { R = shirt.R, G = shirt.G, B = shirt.B },
			Pants = { R = pants.R, G = pants.G, B = pants.B },
		})
		appearancePage.Visible = false
		classPage.Visible = true
	end)

	characterClassAssignedEvent.OnClientEvent:Connect(function(classId: string?)
		CharacterCreationController.SelectedClass = classId
		screenGui.Enabled = (classId == nil)
		if classId == nil then
			appearancePage.Visible = true
			classPage.Visible = false
		end
	end)

	-- Pull the current state instead of only relying on the server's push: a push
	-- fired before this script finished connecting would otherwise be lost forever.
	local currentClass = getCharacterClassFunction:InvokeServer()
	CharacterCreationController.SelectedClass = currentClass
	screenGui.Enabled = (currentClass == nil)
	if currentClass == nil then
		appearancePage.Visible = true
		classPage.Visible = false
	end
end

return CharacterCreationController
