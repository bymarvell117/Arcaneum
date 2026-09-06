local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Framework.Net)

-- TEMPORARY testing tool, see Server/Services/DebugService.lua.
local DEBUG_KEY = Enum.KeyCode.P

local player = Players.LocalPlayer
local debugDealDamageEvent = Net.GetEvent("DebugDealDamage")

local DebugController = {}

function DebugController:Start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or input.KeyCode ~= DEBUG_KEY then
			return
		end

		local mouse = player:GetMouse()
		local target = mouse and mouse.Target
		if target then
			debugDealDamageEvent:FireServer(target, mouse.Hit.Position)
		end
	end)
end

return DebugController
