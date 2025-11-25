-- src/server/FarmingService.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local eventsFolder = ReplicatedStorage.Shared.events
local tillGroundEvent = eventsFolder:WaitForChild("TillGround")
local plantSeedEvent = eventsFolder:WaitForChild("PlantSeed")
local buildEvent = eventsFolder:WaitForChild("BuildStructure")

local ItemData = require(ReplicatedStorage.Shared.ItemData)

-- CONFIG
local GROWTH_SPEED = 2.0 
-- Giant Sapling Size (2x2x4) to be unmissable
local MATURE_SIZE = Vector3.new(2, 4, 2) 

-- HELPERS
local function getRandomPlantType()
	local roll = math.random(1, 100)
	local cumulative = 0
	for _, drop in ipairs(ItemData.PlantDrops) do
		cumulative = cumulative + drop.Chance
		if roll <= cumulative then return drop.Type end
	end
	return "MoneyPlant"
end

local function initializePlantTimer(plant)
	local pType = plant:GetAttribute("Type")
	local now = tick()
	local delayTime = 0
	if pType == "MoneyPlant" then delayTime = math.random(100, 200)
	elseif pType == "HealPlant" then delayTime = math.random(200, 300)
	else return end
	plant:SetAttribute("NextEffectTime", now + delayTime)
end

local function checkPlantTimers()
	local now = tick()
	for _, plant in ipairs(CollectionService:GetTagged("MaturePlant")) do
		local nextTime = plant:GetAttribute("NextEffectTime")
		if nextTime and now >= nextTime then
			local pType = plant:GetAttribute("Type")
			local ownerId = plant:GetAttribute("OwnerId")
			local player = Players:GetPlayerByUserId(ownerId)
			
			if pType == "MoneyPlant" and player then
				player.leaderstats.Money.Value += 50
				local billboard = Instance.new("BillboardGui")
				billboard.Size = UDim2.fromScale(2,2); billboard.Adornee = plant
				local text = Instance.new("TextLabel", billboard)
				text.Size = UDim2.fromScale(1,1); text.BackgroundTransparency = 1
				text.Text = "+$50"; text.TextColor3 = Color3.new(1,1,0); text.TextScaled = true
				text.Font = Enum.Font.FredokaOne; billboard.Parent = plant
				game.Debris:AddItem(billboard, 2)
				plant:SetAttribute("NextEffectTime", now + math.random(100, 200))
			elseif pType == "HealPlant" then
				local zone = Instance.new("Part")
				zone.Shape = Enum.PartType.Ball; zone.Size = Vector3.new(1, 1, 1)
				zone.Position = plant.Position; zone.Anchored = true
				zone.CanCollide = false; zone.Transparency = 0.5
				zone.Color = Color3.fromRGB(0, 255, 0); zone.Parent = workspace
				game.Debris:AddItem(zone, 30)
				local TweenService = game:GetService("TweenService")
				local info = TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
				TweenService:Create(zone, info, {Size = Vector3.new(25, 25, 25)}):Play()
				task.spawn(function()
					for i = 1, 30 do
						if not zone.Parent then break end
						for _, char in ipairs(workspace:GetChildren()) do
							local hum = char:FindFirstChild("Humanoid")
							local root = char:FindFirstChild("HumanoidRootPart")
							if hum and root and (root.Position - plant.Position).Magnitude < 12.5 then
								hum.Health = math.min(hum.Health + 5, hum.MaxHealth)
							end
						end
						task.wait(1)
					end
				end)
				plant:SetAttribute("NextEffectTime", now + math.random(200, 300))
			end
		end
	end
end

-- --- MAIN LOOP ---
local lastShotTime = {}
local FIRE_RATE = 1.0

-- Create params once to reuse (Optimization)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

RunService.Heartbeat:Connect(function(deltaTime)
	local now = tick()
	local time = Lighting.ClockTime
	local isDay = (time >= 6 and time < 18)
	
	checkPlantTimers()
	
	if isDay then
		for _, sapling in ipairs(CollectionService:GetTagged("Sapling")) do
			local progress = sapling:GetAttribute("GrowthProgress") or 0
			progress = progress + (GROWTH_SPEED * deltaTime)
			
			if progress >= 100 then
                -- (Keep your existing planting logic here, it is fine)
				local ownerId = sapling:GetAttribute("OwnerId")
				local soil = sapling.Parent
				local newType = getRandomPlantType()
				local plantTemplate = ServerStorage.Plants:FindFirstChild(newType)
				
				if plantTemplate and soil and soil.Parent then
					sapling:Destroy()
					local realPlant = plantTemplate:Clone()
					realPlant.Name = "ActivePlant"
					
					-- Raycast for Mature Plant (Fixed)
                    rayParams.FilterDescendantsInstances = {realPlant, soil, sapling} -- Ignore self
					local rayOrigin = soil.Position + Vector3.new(0, 5, 0)
					local rayDir = Vector3.new(0, -10, 0)
					local result = workspace:Raycast(rayOrigin, rayDir, rayParams) -- PASS PARAMS
					
                    local floorY = soil.Position.Y
					if result then floorY = result.Position.Y end
					
					local offset = (realPlant.Size.Y/2)
					realPlant.CFrame = CFrame.new(soil.Position.X, floorY + offset, soil.Position.Z)
					realPlant.Parent = soil
					realPlant:SetAttribute("OwnerId", ownerId)
					realPlant:SetAttribute("Type", newType)
					CollectionService:AddTag(realPlant, "Targetable")
					CollectionService:AddTag(realPlant, "MaturePlant")
					initializePlantTimer(realPlant)
					
                    -- VFX
                    local emitter = Instance.new("ParticleEmitter")
					emitter.Texture = "rbxassetid://243098098"; emitter.Lifetime = NumberRange.new(0.5)
					emitter.Rate = 0; emitter.Parent = realPlant; emitter:Emit(10)
					game.Debris:AddItem(emitter, 1)
				end
			else
                -- UPDATE GROWING SAPLING
				sapling:SetAttribute("GrowthProgress", progress)
				local percent = progress / 100
				
				-- GROWTH VISUALS
				sapling.Size = MATURE_SIZE * (0.8 + (0.2 * percent))
				
				-- KEEP ANCHORED (THE FIX IS HERE)
				if sapling.Parent then
                    -- Update the filter list to ignore THIS sapling
                    rayParams.FilterDescendantsInstances = {sapling, sapling.Parent}

					local rayOrigin = sapling.Parent.Position + Vector3.new(0, 5, 0)
					local rayDir = Vector3.new(0, -10, 0)
					
                    -- Pass rayParams here!
					local result = workspace:Raycast(rayOrigin, rayDir, rayParams)
					
					if result then
						local floorY = result.Position.Y
						local offset = (sapling.Size.Y/2)
						sapling.CFrame = CFrame.new(sapling.Parent.Position.X, floorY + offset, sapling.Parent.Position.Z)
					end
				end
			end
		end
	end
	
	-- TURRET (Simplified)
	for _, plant in ipairs(CollectionService:GetTagged("Targetable")) do
		if plant:GetAttribute("Type") == "TurretPlant" then
			local last = lastShotTime[plant] or 0
			if now - last > FIRE_RATE then
				local nearestZ = nil
				local minDst = 30
				for _, enemy in ipairs(workspace:GetChildren()) do
					if enemy.Name == "Zombie" and enemy:FindFirstChild("HumanoidRootPart") then
						local dist = (plant.Position - enemy.HumanoidRootPart.Position).Magnitude
						if dist < minDst then minDst = dist; nearestZ = enemy end
					end
				end
				if nearestZ then
					lastShotTime[plant] = now
					local beam = Instance.new("Part")
					beam.Size = Vector3.new(0.2, 0.2, (plant.Position - nearestZ.HumanoidRootPart.Position).Magnitude)
					beam.CFrame = CFrame.lookAt(plant.Position, nearestZ.HumanoidRootPart.Position) * CFrame.new(0, 0, -beam.Size.Z/2)
					beam.Anchored = true; beam.CanCollide = false; beam.Color = Color3.fromRGB(255, 0, 0)
					beam.Material = Enum.Material.Neon; beam.Parent = workspace; game.Debris:AddItem(beam, 0.1)
					nearestZ.Humanoid:TakeDamage(20)
					local sfx = Instance.new("Sound"); sfx.SoundId = "rbxassetid://2691586"; sfx.Parent = plant; sfx:Play(); game.Debris:AddItem(sfx, 1)
				end
			end
		end
	end
end)

-- --- EVENT HANDLERS ---

local function onTillGround(player, targetPart, position)
	-- 1. Check Target Validity
	local isValid = (targetPart.Name == "Baseplate" or targetPart:IsA("Terrain"))
	if not isValid then return end
	
	-- 2. Check Resources
	local woodStat = player.leaderstats:FindFirstChild("Wood")
	if not woodStat or woodStat.Value < 5 then
		warn("Not enough wood!")
		return
	end

	-- 3. Grid Calculation
	local GRID_SIZE = 4
	local x = math.round(position.X / GRID_SIZE) * GRID_SIZE
	local z = math.round(position.Z / GRID_SIZE) * GRID_SIZE
	
	-- We use the clicked height, but ensure it sits ON TOP of the floor.
	-- If clicking terrain, position.Y is the surface.
	local y = position.Y + 0.5 -- Shift up by half the plot height (1/2 = 0.5)
	
	-- 4. Overlap Check
	local checkSize = Vector3.new(3.5, 5, 3.5)
	local checkCFrame = CFrame.new(x, y, z)
	
	local parts = workspace:GetPartBoundsInBox(checkCFrame, checkSize)
	for _, p in ipairs(parts) do
		if p.Name == "FarmPlot" or p.Name == "WoodFence" or p.Name == "TilledSoil" then
			warn("Something is already here!")
			return 
		end
	end
    
	-- 5. Place the Plot
	woodStat.Value -= 5
	
	local plot = Instance.new("Part")
	plot.Name = "FarmPlot"
	plot.Size = Vector3.new(3.8, 1, 3.8) -- The Box
	plot.Material = Enum.Material.Wood
	plot.Color = Color3.fromRGB(100, 60, 30)
	plot.Anchored = true
	plot.CanCollide = true
	plot.CFrame = CFrame.new(x, y, z) -- Use CFrame for safer positioning
	plot.Parent = workspace
	
	local dirt = Instance.new("Part")
	dirt.Name = "DirtTop"
	dirt.Size = Vector3.new(3.4, 0.2, 3.4)
	dirt.Color = Color3.fromRGB(50, 30, 10)
	dirt.Material = Enum.Material.Grass
	dirt.Anchored = true
	dirt.CanCollide = false
	dirt.CFrame = plot.CFrame * CFrame.new(0, 0.51, 0)
	dirt.Parent = plot
	
	-- [[ DELETED THE TERRAIN FILLBLOCK CODE TO STOP MOUNDS ]]

    local sfx = Instance.new("Sound")
    sfx.SoundId = "rbxassetid://4512214349"
    sfx.Parent = plot
    sfx:Play()
	
	print("✅ Placed FarmPlot at " .. tostring(plot.Position))
end

local function onPlantSeed(player, targetPart)
	-- Support planting on the new FarmPlot (or its dirt top)
	local finalTarget = targetPart
	
	-- If they clicked the DirtTop, get the main Plot
	if targetPart.Name == "DirtTop" then
		finalTarget = targetPart.Parent
	end
	
	if finalTarget.Name ~= "FarmPlot" then return end
	if finalTarget:FindFirstChild("ActivePlant") then return end
	
	-- ... (The rest of your planting logic is fine, just ensure it sets parent to finalTarget) ...
	local sapling = ServerStorage.Plants.Sapling:Clone()
	sapling.Name = "ActivePlant"
	sapling.Size = MATURE_SIZE * 0.8
	
	-- Simple positioning on top of the plot
	sapling.CFrame = finalTarget.CFrame * CFrame.new(0, (finalTarget.Size.Y/2) + (sapling.Size.Y/2), 0)
	
	sapling.Parent = finalTarget
	sapling:SetAttribute("OwnerId", player.UserId)
	sapling:SetAttribute("GrowthProgress", 0)
	CollectionService:AddTag(sapling, "Sapling")
end

-- (Keep BuildStructure Logic)
local function onBuildStructure(player, structureName, position, rotationY)
	if not ServerStorage:FindFirstChild("Buildings") then return end
	local data = ItemData.Buildings and ItemData.Buildings[structureName]
	if not data then return end
	if player.leaderstats.Money.Value < data.Cost then return end
	player.leaderstats.Money.Value -= data.Cost
	local template = ServerStorage.Buildings:FindFirstChild(structureName)
	if template then
		local newBuild = template:Clone()
		local rot = math.rad(rotationY or 0)
		newBuild.CFrame = CFrame.new(position) * CFrame.Angles(0, rot, 0)
		newBuild.Parent = workspace
		CollectionService:AddTag(newBuild, "Targetable")
	end
end

tillGroundEvent.OnServerEvent:Connect(onTillGround)

plantSeedEvent.OnServerEvent:Connect(onPlantSeed)
buildEvent.OnServerEvent:Connect(onBuildStructure)

print("🌱 Farming Service V10 (Mound Fix & Raycast Plant) Online")