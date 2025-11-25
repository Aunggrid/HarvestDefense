-- src/server/MapGenerator.server.lua
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

-- CONFIGURATION
local MAP_SIZE = 512      
local GRID_SIZE = 4       
local SEED = os.time()    
local AMP = 40            
local FREQ = 120          
local SAFE_ZONE_RADIUS = 60 

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
    
    -- [[ REMOVED THE FAILING LINE (Decoration is not scriptable) ]]
    
    -- Loop through the map
    local startX = -MAP_SIZE / 2
    local startZ = -MAP_SIZE / 2
    local endX = MAP_SIZE / 2
    local endZ = MAP_SIZE / 2
    
    for x = startX, endX, GRID_SIZE do
        for z = startZ, endZ, GRID_SIZE do
            local dist = math.sqrt(x^2 + z^2)
            local height = 0
            
            if dist > SAFE_ZONE_RADIUS then
                local noise = math.noise(x/FREQ, z/FREQ, SEED)
                height = math.abs(noise * AMP) 
                height = math.floor(height / GRID_SIZE) * GRID_SIZE
            end
            
            local cframe = CFrame.new(x, (height/2) - 10, z)
            local size = Vector3.new(GRID_SIZE, height + 20, GRID_SIZE)
            
            -- [[ FIX: USE LEAFYGRASS INSTEAD OF GRASS ]]
            -- LeafyGrass is green but has NO 3D blades.
            local mat = Enum.Material.LeafyGrass 
            if height > 20 then mat = Enum.Material.Rock end
            
            terrain:FillBlock(cframe, size, mat)
        end
        if x % 40 == 0 then task.wait() end
    end
    
    print("✅ Map Generation Complete!")
    mapReadyEvent:FireAllClients()
end

task.spawn(generateMap)