-- src/server/GameLoop.server.lua
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local events = ReplicatedStorage.Shared.events
local resetEvent = events:WaitForChild("ResetGame")

local DAY_LENGTH_SECONDS = 300 
local START_TIME = 6 

-- HELPER: Clean the Map
local function cleanMap()
	print("🧹 Cleaning Map...")
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name == "Zombie" then child:Destroy() end
	end
	for _, obj in ipairs(CollectionService:GetTagged("Targetable")) do
		obj:Destroy()
	end
	for _, obj in ipairs(CollectionService:GetTagged("Sapling")) do
		obj:Destroy()
	end
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name == "WoodFence" then child:Destroy() end
	end
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name == "TilledSoil" then child:Destroy() end
	end
end

-- LISTEN FOR RESET
-- LISTEN FOR RESET
resetEvent.OnServerEvent:Connect(function(player)
	print("🔄 Soft Reset triggered by " .. player.Name)
	
	-- 1. Global Game State Reset
	ReplicatedStorage:SetAttribute("Wave", 0)
	ReplicatedStorage:SetAttribute("DaysSurvived", 1)
	ReplicatedStorage:SetAttribute("GameState", "Booting")
	Lighting.ClockTime = START_TIME
	
	-- 2. Clean up entities
	cleanMap()
	
	-- 3. RESET PLAYER STATS
	for _, p in ipairs(Players:GetPlayers()) do
		local leaderstats = p:FindFirstChild("leaderstats")
		if leaderstats then
			-- Reset Cash
			local money = leaderstats:FindFirstChild("Money")
			if money then money.Value = 0 end
			
			-- Reset Skill Points to 1
			local sp = leaderstats:FindFirstChild("SkillPoints")
			if sp then sp.Value = 1 end
			
			-- [[ NEW: Reset Wood ]]
			local wood = leaderstats:FindFirstChild("Wood")
			if wood then wood.Value = 10 end -- Reset to starting amount
		end
		
		-- Remove Unlocked Skills
		local skills = p:FindFirstChild("UnlockedSkills")
		if skills then
			skills:ClearAllChildren() 
		end
		
		-- Respawn to fix health
		p:LoadCharacter()
	end
end)

Players.PlayerAdded:Connect(function(player)
	player:LoadCharacter()
end)

-- Initialize State
ReplicatedStorage:SetAttribute("GameState", "Booting")
ReplicatedStorage:SetAttribute("Wave", 0)
ReplicatedStorage:SetAttribute("DaysSurvived", 1) -- Start on Day 1

print("🌞 Game Loop Started")

while true do
    local deltaTime = task.wait(1/30)
    local timeToAdd = (24 / DAY_LENGTH_SECONDS) * deltaTime
    Lighting.ClockTime = (Lighting.ClockTime + timeToAdd) % 24

    local currentState
    if Lighting.ClockTime >= 6 and Lighting.ClockTime < 18 then
        currentState = "FARM"
    else
        currentState = "SURVIVE"
    end

    if ReplicatedStorage:GetAttribute("GameState") ~= currentState then
        ReplicatedStorage:SetAttribute("GameState", currentState)
        
        if currentState == "FARM" then
            -- NEW: WEEKLY SKILL POINTS LOGIC
            local currentWave = ReplicatedStorage:GetAttribute("Wave") or 0
            local currentDay = ReplicatedStorage:GetAttribute("DaysSurvived") or 1
            
            ReplicatedStorage:SetAttribute("Wave", currentWave + 1)
            ReplicatedStorage:SetAttribute("DaysSurvived", currentDay + 1)
            
            -- Check if a week has passed
            if currentDay % 7 == 0 then
                print("🎉 WEEK SURVIVED! Granting Skill Points to all players.")
                for _, p in ipairs(Players:GetPlayers()) do
                    local leaderstats = p:FindFirstChild("leaderstats")
                    if leaderstats then
                        local sp = leaderstats:FindFirstChild("SkillPoints")
                        if sp then
                            sp.Value = sp.Value + 1
                            -- Optional: Play a "Level Up" sound here
                        end
                    end
                end
            end
            
            print("🌅 Daybreak! Day " .. (currentDay + 1))
            
        elseif currentState == "SURVIVE" then
             print("🌑 Nightfall! Wave " .. ReplicatedStorage:GetAttribute("Wave") .. " begins!")
        end
    end
end