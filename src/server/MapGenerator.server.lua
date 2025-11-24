-- src/server/MapGenerator.server.lua
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

-- CONFIGURATION
local MAP_SIZE = 512      -- Total size (Studs)
local GRID_SIZE = 4       -- Match your building grid!
local SEED = os.time()    -- Random seed every time
local AMP = 40            -- How high the hills are
local FREQ = 120          -- How "zoomed in" the noise is (Bigger = wider hills)
local SAFE_ZONE_RADIUS = 60 -- Flat area in middle

-- WAIT FOR EVENTS (Using WaitForChild in case script runs before folders sync)
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local events = sharedFolder:WaitForChild("events")
local mapReadyEvent = events:WaitForChild("MapLoaded")

local function generateMap()
    print("🌍 Generating Terrain with Seed: " .. SEED)
    math.randomseed(SEED)
    
    -- 1. Delete Baseplate
    if Workspace:FindFirstChild("Baseplate") then
        Workspace.Baseplate:Destroy()
    end
    
    -- 2. Setup Terrain
    local terrain = Workspace.Terrain
    terrain:Clear()
    
    -- We use a buffer to make writing faster
    -- Loop through the map in 4x4 chunks
    local startX = -MAP_SIZE / 2
    local startZ = -MAP_SIZE / 2
    local endX = MAP_SIZE / 2
    local endZ = MAP_SIZE / 2
    
    for x = startX, endX, GRID_SIZE do
        for z = startZ, endZ, GRID_SIZE do
            -- A. Check Safe Zone (Distance from 0,0)
            local dist = math.sqrt(x^2 + z^2)
            local height = 0
            
            if dist > SAFE_ZONE_RADIUS then
                -- B. Calculate Perlin Noise
                -- math.noise returns -0.5 to 0.5. We multiply by AMP to get height.
                local noise = math.noise(x/FREQ, z/FREQ, SEED)
                height = math.abs(noise * AMP) -- Hills go UP only
                
                -- C. Snap Height to Grid (Minecraft Style Steps)
                height = math.floor(height / GRID_SIZE) * GRID_SIZE
            end
            
            -- D. Fill the Block
            -- We fill from deep down (-20) up to the calculated height
            -- CFrame must be centered on the block
            local cframe = CFrame.new(x, (height/2) - 10, z)
            local size = Vector3.new(GRID_SIZE, height + 20, GRID_SIZE)
            
            -- Material Logic: High = Stone, Low = Grass
            local mat = Enum.Material.Grass
            if height > 20 then mat = Enum.Material.Rock end
            
            terrain:FillBlock(cframe, size, mat)
            
            -- E. Random Decoration (Trees/Flowers)
            if dist > SAFE_ZONE_RADIUS and height < 15 and math.random() > 0.98 then
                -- Add a Tree? (We can do this later)
            end
        end
        
        -- Optional: Wait every few rows to prevent lag spike
        if x % 40 == 0 then task.wait() end
    end
    
    -- 3. Finalize
    print("✅ Map Generation Complete!")
    mapReadyEvent:FireAllClients()
end

-- Run immediately
task.spawn(generateMap)