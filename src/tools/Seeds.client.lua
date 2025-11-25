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
	
	-- CASE 1: Clicked directly on the Box
	if target.Name == "FarmPlot" then
		finalTarget = target
		
	-- CASE 2: Clicked on the Dirt Top inside the box
	elseif target.Name == "DirtTop" and target.Parent.Name == "FarmPlot" then
		finalTarget = target.Parent -- We want the main box, not the dirt sheet
	
	-- CASE 3: Clicked on Terrain (Grass) - Find nearby plot
	elseif target:IsA("Terrain") then
		local hitPos = mouse.Hit.Position
		
		-- Search a 5-stud box around the click
		local parts = workspace:GetPartBoundsInBox(CFrame.new(hitPos), Vector3.new(5, 5, 5))
		
		for _, p in ipairs(parts) do
			if p.Name == "FarmPlot" then
				finalTarget = p
				break
			end
			-- Handle clicking the DirtTop via proximity
			if p.Name == "DirtTop" and p.Parent.Name == "FarmPlot" then
				finalTarget = p.Parent
				break
			end
		end
	end
	
	-- CHECK: Is the plot valid and empty?
	if finalTarget and finalTarget.Name == "FarmPlot" then
		if finalTarget:FindFirstChild("ActivePlant") then
			print("Client: Plot is occupied!")
		else
			print("Client: Planting on valid plot.")
			-- We send the "DirtTop" if possible, or the Plot. 
			-- The server handles both, but sending DirtTop is safer for visuals.
			local dirtTop = finalTarget:FindFirstChild("DirtTop")
			plantSeedEvent:FireServer(dirtTop or finalTarget)
		end
	end
end)