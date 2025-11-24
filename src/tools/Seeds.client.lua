-- src/tools/Seeds.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local tool = script:FindFirstAncestorWhichIsA("Tool")

local eventsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("events")
local plantSeedEvent = eventsFolder:WaitForChild("PlantSeed")

tool.Activated:Connect(function()
	local mouse = player:GetMouse()
	local target = mouse.Target
	
	if not target then return end
	
	local finalTarget = nil
	
	-- CASE 1: Clicked directly on Soil
	if target.Name == "TilledSoil" then
		finalTarget = target
	
	-- CASE 2: Clicked on Terrain (Grass)
	elseif target:IsA("Terrain") then
		local hitPos = mouse.Hit.Position
		
		-- Search a 5-stud box around the click
		local parts = workspace:GetPartBoundsInBox(CFrame.new(hitPos), Vector3.new(5, 5, 5))
		
		for _, p in ipairs(parts) do
			if p.Name == "TilledSoil" then
				finalTarget = p
				break
			end
		end
	end
	
	-- CHECK: Is the soil actually valid and empty?
	if finalTarget and finalTarget.Name == "TilledSoil" then
		if finalTarget:FindFirstChild("ActivePlant") then
			print("Client: Soil is occupied!")
		else
			print("Client: Planting on valid soil.")
			plantSeedEvent:FireServer(finalTarget)
		end
	end
end)