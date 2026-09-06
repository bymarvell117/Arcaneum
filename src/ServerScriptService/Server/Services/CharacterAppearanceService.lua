local Players = game:GetService("Players")

-- Forces every character onto a plain default R15 body instead of the player's own
-- Roblox avatar, so everyone starts from the same clean base — ready for the future
-- custom character art (Disney-Infinity-style) and the separate armor/clothing layer
-- system to build on top of, without fighting whatever accessories a player happens
-- to already be wearing.
local BLANK_DESCRIPTION = Instance.new("HumanoidDescription")

local CharacterAppearanceService = {}

local function applyBlankAppearance(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid:ApplyDescription(BLANK_DESCRIPTION, Enum.HumanoidRigType.R15)
end

function CharacterAppearanceService:Start()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(applyBlankAppearance)
	end)
end

return CharacterAppearanceService
