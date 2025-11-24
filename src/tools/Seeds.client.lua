-- src/tools/Seeds.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local tool = script:FindFirstAncestorWhichIsA("Tool")

-- Get the events folder
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local eventsFolder = sharedFolder:WaitForChild("events")

-- Get a NEW event that we are about to create
local plantSeedEvent = eventsFolder:WaitForChild("PlantSeed")

print("Seeds Client Script Loaded. Found PlantSeed event.")

tool.Activated:Connect(function()
	local mouse = player:GetMouse()
	local mouseTarget = mouse.Target

	-- We only care about the part we clicked, not the exact position
	if mouseTarget then
		print("Client: Firing PlantSeed event to server.")
		plantSeedEvent:FireServer(mouseTarget)
	else
		print("Client: Clicked the sky, not firing.")
	end
end)