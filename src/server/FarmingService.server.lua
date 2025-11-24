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
local GROWTH_SPEED = 1.0 
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
				local ownerId = sapling:GetAttribute("OwnerId")
				local soil = sapling.Parent
				local newType = getRandomPlantType()
				local plantTemplate = ServerStorage.Plants:FindFirstChild(newType)
				
				if plantTemplate and soil and soil.Parent then
					sapling:Destroy()
					local realPlant = plantTemplate:Clone()
					realPlant.Name = "ActivePlant"
					
					-- Raycast to find exact floor for Mature Plant
					local rayOrigin = soil.Position + Vector3.new(0, 5, 0)
					local rayDir = Vector3.new(0, -10, 0)
					local result = workspace:Raycast(rayOrigin, rayDir)
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
					local emitter = Instance.new("ParticleEmitter")
					emitter.Texture = "rbxassetid://243098098"; emitter.Lifetime = NumberRange.new(0.5)
					emitter.Rate = 0; emitter.Parent = realPlant; emitter:Emit(10)
					game.Debris:AddItem(emitter, 1)
				end
			else
				sapling:SetAttribute("GrowthProgress", progress)
				local percent = progress / 100
				
				-- GROWTH VISUALS: Start BIG (0.8 scale)
				sapling.Size = MATURE_SIZE * (0.8 + (0.2 * percent))
				
				-- Keep sapling anchored to the floor visually
				if sapling.Parent then
					local rayOrigin = sapling.Parent.Position + Vector3.new(0, 5, 0)
					local rayDir = Vector3.new(0, -10, 0)
					local result = workspace:Raycast(rayOrigin, rayDir)
					
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
	local isValid = (targetPart.Name == "Baseplate" or targetPart:IsA("Terrain"))
	if not isValid then return end
	
	local GRID_SIZE = 4
	local x = math.round(position.X / GRID_SIZE) * GRID_SIZE
	local z = math.round(position.Z / GRID_SIZE) * GRID_SIZE
	local y = position.Y 
	
	local parts = workspace:GetPartBoundsInBox(CFrame.new(x, y, z), Vector3.new(2, 10, 2))
	for _, p in ipairs(parts) do
		if p.Name == "TilledSoil" then warn("Soil exists!"); return end
	end

	local soil = Instance.new("Part")
	soil.Name = "TilledSoil"
	soil.Size = Vector3.new(4, 0.2, 4)
	soil.Transparency = 1 
	soil.CanCollide = false 
	soil.Anchored = true
	soil.Position = Vector3.new(x, y, z) 
	soil.Parent = workspace
	
	-- FIX: Move fill box DOWN by 2 studs.
	-- This keeps the surface at the same level but changes the material to Ground.
	local terrain = workspace.Terrain
	terrain:FillBlock(soil.CFrame * CFrame.new(0, -2, 0), Vector3.new(4, 4, 4), Enum.Material.Ground)
end

local function onPlantSeed(player, targetPart)
	if targetPart.Name ~= "TilledSoil" then return end
	if targetPart:FindFirstChild("ActivePlant") then return end
	
	local sapling = ServerStorage.Plants.Sapling:Clone()
	sapling.Name = "ActivePlant"
	
	-- SIZE: Start at 80% of full size (Huge)
	sapling.Size = MATURE_SIZE * 0.8
	
	-- FIX: Raycast to find true surface height
	-- Shoot a ray down from above the soil to find exactly where the dirt is
	local rayOrigin = targetPart.Position + Vector3.new(0, 5, 0)
	local rayDir = Vector3.new(0, -10, 0)
	local result = workspace:Raycast(rayOrigin, rayDir)
	
	local floorY = targetPart.Position.Y
	if result then
		floorY = result.Position.Y
	end
	
	-- Place on top of the found floor
	local offset = (sapling.Size.Y / 2)
	sapling.CFrame = CFrame.new(targetPart.Position.X, floorY + offset, targetPart.Position.Z)
	
	sapling.Parent = targetPart
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