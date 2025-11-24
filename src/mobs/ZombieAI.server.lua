-- src/mobs/ZombieAI.server.lua
local ServerScriptService = game:GetService("ServerScriptService")

-- 1. Load the Class
local ZombieClass = require(ServerScriptService.Classes.Zombie)

-- 2. Create a new Zombie Object using this model
local newZombie = ZombieClass.new(script.Parent)

-- 3. Start its brain
newZombie:Run()