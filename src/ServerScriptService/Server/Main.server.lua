local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Framework.Loader)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

print(("[%s] Server starting"):format(GameConfig.GameName))

local servicesFolder = script.Parent:WaitForChild("Services")
Loader.LoadAndStart(servicesFolder)
