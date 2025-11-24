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
local GROWTH_SPEED = 1.0 -- 1% per second (100s to grow)

-- --- HELPER: Pick a Random Plant ---
local function getRandomPlantType()
	local roll = math.random(1, 100)
	local cumulative = 0
	for _, drop in ipairs(ItemData.PlantDrops) do
		cumulative = cumulative + drop.Chance
		if roll <= cumulative then
			return drop.Type
		end
	end
	return "MoneyPlant"
end

-- --- HELPER: Set Initial Timers ---
local function initializePlantTimer(plant)
	local pType = plant:GetAttribute("Type")
	local now = tick()
	local delayTime = 0
	
	if pType == "MoneyPlant" then
		-- Random between 100 and 200 seconds
		delayTime = math.random(100, 200)
	elseif pType == "HealPlant" then
		-- Random between 200 and 300 seconds
		delayTime = math.random(200, 300)
	else
		return -- Turrets handle their own firing logic elsewhere
	end
	
	-- Save the exact timestamp when this plant should trigger
	plant:SetAttribute("NextEffectTime", now + delayTime)
end

-- --- PLANT EFFECT LOGIC (Timer Based) ---
local function checkPlantTimers()
	local now = tick()
	
	for _, plant in ipairs(CollectionService:GetTagged("MaturePlant")) do
		local nextTime = plant:GetAttribute("NextEffectTime")
		
		-- Only process if it has a timer and it's time to trigger!
		if nextTime and now >= nextTime then
			local pType = plant:GetAttribute("Type")
			local ownerId = plant:GetAttribute("OwnerId")
			local player = Players:GetPlayerByUserId(ownerId)
			
			if pType == "MoneyPlant" and player then
				-- 1. MONEY EFFECT
				local cash = 50 -- Increased payout since it's slower
				player.leaderstats.Money.Value += cash
				
				-- Visual
				local billboard = Instance.new("BillboardGui")
				billboard.Size = UDim2.fromScale(2,2); billboard.Adornee = plant
				local text = Instance.new("TextLabel", billboard)
				text.Size = UDim2.fromScale(1,1); text.BackgroundTransparency = 1
				text.Text = "+$"..cash; text.TextColor3 = Color3.new(1,1,0); text.TextScaled = true
				text.Font = Enum.Font.FredokaOne; billboard.Parent = plant
				game.Debris:AddItem(billboard, 2)
				
				-- Reset Timer (100-200s)
				plant:SetAttribute("NextEffectTime", now + math.random(100, 200))
				
			elseif pType == "HealPlant" then
				-- 2. HEAL EFFECT
				-- Visual Zone
				local zone = Instance.new("Part")
				zone.Shape = Enum.PartType.Ball
				zone.Size = Vector3.new(1, 1, 1) -- Start small
				zone.Position = plant.Position
				zone.Anchored = true
				zone.CanCollide = false
				zone.Transparency = 0.5
				zone.Color = Color3.fromRGB(0, 255, 0)
				zone.Parent = workspace
				game.Debris:AddItem(zone, 30) -- Zone stays for 30 seconds
				
				-- Tween size to indicate active area (Pulse effect)
				local TweenService = game:GetService("TweenService")
				local info = TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
				TweenService:Create(zone, info, {Size = Vector3.new(25, 25, 25)}):Play() -- 25 Studs! (Bigger)
				
				-- Healing Loop (Runs for 30 seconds)
				task.spawn(function()
					for i = 1, 30 do
						if not zone.Parent then break end -- Stop if zone deleted
						
						-- Find players in zone
						for _, char in ipairs(workspace:GetChildren()) do
							local hum = char:FindFirstChild("Humanoid")
							local root = char:FindFirstChild("HumanoidRootPart")
							if hum and root and (root.Position - plant.Position).Magnitude < 12.5 then -- Radius is Size/2
								hum.Health = math.min(hum.Health + 5, hum.MaxHealth) -- Heal 5 HP per second
								
								-- Little heal particles
								local p = Instance.new("Part")
								p.Size = Vector3.new(0.5,0.5,0.5); p.Position = root.Position; p.Anchored = true
								p.CanCollide = false; p.Color = Color3.new(0,1,0); p.Material = Enum.Material.Neon
								p.Parent = workspace; game.Debris:AddItem(p, 0.5)
							end
						end
						task.wait(1)
					end
				end)

				-- Reset Timer (200-300s)
				plant:SetAttribute("NextEffectTime", now + math.random(200, 300))
			end
		end
	end
end


-- --- MAIN LOOP (Growth, Turrets, Effects) ---
local lastShotTime = {}
local FIRE_RATE = 1.0

RunService.Heartbeat:Connect(function(deltaTime)
	local now = tick()
	local time = Lighting.ClockTime
	local isDay = (time >= 6 and time < 18)
	
	-- 0. PLANT EFFECTS (Run constantly)
	checkPlantTimers()
	
	-- 1. GROWTH (Only during Day)
	if isDay then
		for _, sapling in ipairs(CollectionService:GetTagged("Sapling")) do
			local progress = sapling:GetAttribute("GrowthProgress") or 0
			progress = progress + (GROWTH_SPEED * deltaTime)
			
			if progress >= 100 then
				-- MATURE TRANSFORM
				local ownerId = sapling:GetAttribute("OwnerId")
				local soil = sapling.Parent
				local newType = getRandomPlantType()
				
				sapling:Destroy()
				
				if soil and soil.Parent then
					local realPlant = ServerStorage.Plants[newType]:Clone()
					realPlant.Name = "ActivePlant"
					realPlant.CFrame = soil.CFrame + Vector3.new(0, realPlant.Size.Y/2, 0)
					realPlant.Parent = soil
					
					realPlant:SetAttribute("OwnerId", ownerId)
					realPlant:SetAttribute("Type", newType)
					
					-- Tags
					CollectionService:AddTag(realPlant, "Targetable") 
					CollectionService:AddTag(realPlant, "MaturePlant") 
					
					-- INITIALIZE TIMER (New!)
					initializePlantTimer(realPlant)
					
					-- Poof Effect
					local emitter = Instance.new("ParticleEmitter")
					emitter.Texture = "rbxassetid://243098098"
					emitter.Lifetime = NumberRange.new(0.5)
					emitter.Rate = 0
					emitter.Parent = realPlant
					emitter:Emit(10)
					game.Debris:AddItem(emitter, 1)
				end
			else
				-- VISUAL SCALING
				sapling:SetAttribute("GrowthProgress", progress)
				local percent = progress / 100
				local baseSize = Vector3.new(1, 2, 1)
				sapling.Size = baseSize * (0.5 + (0.5 * percent))
				
				if sapling.Parent then
					sapling.CFrame = sapling.Parent.CFrame + Vector3.new(0, sapling.Size.Y/2, 0)
				end
			end
		end
	end

	-- 2. TURRET LOGIC
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
	if targetPart.Name ~= "Baseplate" then return end
	
	-- Enforce Grid Snap (4 Studs)
	local GRID_SIZE = 4
	local x = math.round(position.X / GRID_SIZE) * GRID_SIZE
	local z = math.round(position.Z / GRID_SIZE) * GRID_SIZE
	
	-- Check if soil already exists there (Prevent overlapping)
	local checkPos = Vector3.new(x, 0.5, z)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	-- You might need a folder for soils to check efficiently, 
    -- but for now simple bounds check works:
	local parts = workspace:GetPartBoundsInBox(CFrame.new(checkPos), Vector3.new(3.5, 1, 3.5), overlapParams)
	for _, p in ipairs(parts) do
		if p.Name == "TilledSoil" then return end -- Already tilled!
	end

	local soil = Instance.new("Part")
	soil.Name = "TilledSoil"
	soil.Size = Vector3.new(4, 1, 4)
	soil.Color = Color3.fromRGB(100, 60, 30)
	soil.Anchored = true
	-- Perfect center alignment
	soil.Position = Vector3.new(x, 0.5, z) 
	soil.Parent = workspace
end

local function onPlantSeed(player, targetPart)
	if targetPart.Name ~= "TilledSoil" then return end
	if targetPart:FindFirstChild("ActivePlant") then return end
	
	local sapling = ServerStorage.Plants.Sapling:Clone()
	sapling.Name = "ActivePlant"
	sapling.Size = Vector3.new(1, 2, 1) * 0.5 
	sapling.CFrame = targetPart.CFrame + Vector3.new(0, sapling.Size.Y/2, 0)
	sapling.Parent = targetPart
	
	sapling:SetAttribute("OwnerId", player.UserId)
	sapling:SetAttribute("GrowthProgress", 0)
	CollectionService:AddTag(sapling, "Sapling")
end

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
		print(player.Name .. " built a " .. structureName)
	end
end

tillGroundEvent.OnServerEvent:Connect(onTillGround)
plantSeedEvent.OnServerEvent:Connect(onPlantSeed)
buildEvent.OnServerEvent:Connect(onBuildStructure)

print("🌱 Farming Service V3 (Individual Timers) Online")