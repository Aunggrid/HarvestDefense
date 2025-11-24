-- src/server/MobSpawner.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")

-- LOAD THE CLASS (We need this to create zombies correctly!)
local ZombieClass = require(ServerScriptService.Classes.Zombie)

local zombieTemplate = ServerStorage:WaitForChild("Zombie")
local spawnPoint = Workspace:WaitForChild("ZombieSpawn")

local function stopSpawning()
    -- Optional: You could kill all remaining zombies here if you want
    -- For now, we let them persist until killed
end

local function startWave()
    local wave = ReplicatedStorage:GetAttribute("Wave") or 1
    print("Starting Wave " .. wave)

    -- DIFFICULTY FORMULA:
    -- 3 base zombies, plus 2 for every wave level
    local zombiesToSpawn = 3 + (wave * 2)
    local spawnDelay = 1.5 -- Time between each spawn

    -- Spawn Loop
    task.spawn(function()
        for i = 1, zombiesToSpawn do
            -- Stop if day breaks early
            if ReplicatedStorage:GetAttribute("GameState") ~= "SURVIVE" then break end
            
            -- 1. Clone the Model
            local newModel = zombieTemplate:Clone()
            newModel.Parent = Workspace
            newModel:PivotTo(spawnPoint.CFrame) -- Better than setting HumanoidRootPart directly
            
            -- 2. BUFF THE ZOMBIE (Scaling HP)
            local humanoid = newModel:WaitForChild("Humanoid")
            local healthMulti = 1 + (wave * 0.1) -- +10% HP per wave
            humanoid.MaxHealth = humanoid.MaxHealth * healthMulti
            humanoid.Health = humanoid.MaxHealth
            
            -- 3. Initialize OOP Class
            -- Since we removed the script inside the zombie, WE must initialize it here!
            local newZombieObject = ZombieClass.new(newModel)
            newZombieObject:Run()
            
            print("Spawned Zombie " .. i .. "/" .. zombiesToSpawn .. " (HP: " .. humanoid.MaxHealth .. ")")
            
            task.wait(spawnDelay)
        end
    end)
end

local function onGameStateChanged()
    local newState = ReplicatedStorage:GetAttribute("GameState")
    if newState == "SURVIVE" then
        startWave()
    elseif newState == "FARM" then
        stopSpawning()
    end
end

ReplicatedStorage:GetAttributeChangedSignal("GameState"):Connect(onGameStateChanged)