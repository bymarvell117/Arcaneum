local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Framework.Loader)
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

print(("[%s] Client starting"):format(GameConfig.GameName))

local controllersFolder = script.Parent:WaitForChild("Controllers")
Loader.LoadAndStart(controllersFolder)
