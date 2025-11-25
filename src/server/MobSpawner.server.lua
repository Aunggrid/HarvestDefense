-- src/server/MobSpawner.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

-- LOAD BOTH CLASSES
local ZombieClass = require(ServerScriptService.Classes.Zombie)
local RangedZombieClass = require(ServerScriptService.Classes.RangedZombie) -- NEW

local zombieTemplate = ServerStorage:WaitForChild("Zombie")
local spawnPoint = Workspace:WaitForChild("ZombieSpawn")

local function startWave()
    local wave = ReplicatedStorage:GetAttribute("Wave") or 1
    print("Starting Wave " .. wave)

    local zombiesToSpawn = 3 + (wave * 2)
    local spawnDelay = 1.5 

    task.spawn(function()
        for i = 1, zombiesToSpawn do
            if ReplicatedStorage:GetAttribute("GameState") ~= "SURVIVE" then break end
            
            -- 1. DECIDE TYPE
            -- 30% chance to be Ranged, but only after Wave 1
            local isRanged = (wave > 1) and (math.random() < 0.3)
            
            -- 2. Clone the Model (We reuse the same model for now, just recolored by the class)
            local newModel = zombieTemplate:Clone()
            newModel.Parent = Workspace
            newModel:PivotTo(spawnPoint.CFrame) 
            
            -- 3. BUFF HP
            local humanoid = newModel:WaitForChild("Humanoid")
            local healthMulti = 1 + (wave * 0.1)
            humanoid.MaxHealth = humanoid.MaxHealth * healthMulti
            humanoid.Health = humanoid.MaxHealth
            
            -- 4. INITIALIZE CLASS
            local zombieObject
            if isRanged then
                print("Spawned RANGED Zombie!")
                zombieObject = RangedZombieClass.new(newModel)
            else
                zombieObject = ZombieClass.new(newModel)
            end
            
            zombieObject:Run()
            
            task.wait(spawnDelay)
        end
    end)
end

-- (Keep the rest of the file unchanged: onGameStateChanged, Attribute connections, etc.)
local function stopSpawning() end -- Placeholder
local function onGameStateChanged()
    local newState = ReplicatedStorage:GetAttribute("GameState")
    if newState == "SURVIVE" then startWave()
    elseif newState == "FARM" then stopSpawning() end
end
ReplicatedStorage:GetAttributeChangedSignal("GameState"):Connect(onGameStateChanged)