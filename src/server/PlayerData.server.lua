-- src/server/PlayerData.server.lua
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- CHANGED to v2 because we are changing the data format from a Number to a Table
local DATA_KEY = "HarvestDefense_Data_v2" 
local myDataStore = DataStoreService:GetDataStore(DATA_KEY)

-- Function to load data when a player joins
local function onPlayerAdded(player)
	
	-- 1. Create the Leaderboard (leaderstats)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- 2. Create Money Stat
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0 
	money.Parent = leaderstats

	-- 3. NEW: Skill Points Stat
	local sp = Instance.new("IntValue")
	sp.Name = "SkillPoints"
	sp.Value = 1 -- Everyone starts with 1 point
	sp.Parent = leaderstats
	
	-- 4. NEW: Folder to track Unlocked Skills
	local skillsFolder = Instance.new("Folder")
	skillsFolder.Name = "UnlockedSkills"
	skillsFolder.Parent = player

	-- 5. Load from Cloud
	local userId = player.UserId
	local success, savedData = pcall(function()
		return myDataStore:GetAsync(userId)
	end)

	if success then
		if savedData then
			-- Check if it's our new Table format
			if type(savedData) == "table" then
				money.Value = savedData.Money or 0
				sp.Value = savedData.SkillPoints or 1
				
				-- Re-create the skill tags
				if savedData.Skills then
					for skillName, _ in pairs(savedData.Skills) do
						local tag = Instance.new("BoolValue")
						tag.Name = skillName
						tag.Parent = skillsFolder
					end
				end
				print("Loaded profile for " .. player.Name)
			else
				-- Fallback for old data types (optional safety)
				money.Value = savedData 
			end
		else
			print("New player " .. player.Name .. " created.")
		end
	else
		warn("Failed to load data for " .. player.Name)
	end
end

-- Function to save data when a player leaves
local function onPlayerRemoving(player)
	local userId = player.UserId
	
	-- Construct the Save Table
	local saveTable = {
		Money = player.leaderstats.Money.Value,
		SkillPoints = player.leaderstats.SkillPoints.Value,
		Skills = {} -- Determine which skills to save
	}
	
	-- Save every skill found in the folder
	for _, tag in ipairs(player.UnlockedSkills:GetChildren()) do
		saveTable.Skills[tag.Name] = true
	end

	local success, err = pcall(function()
		myDataStore:SetAsync(userId, saveTable)
	end)

	if success then
		print("Saved data for " .. player.Name)
	else
		warn("Failed to save data: " .. tostring(err))
	end
end

-- Connect the events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- SAFETY NET
game:BindToClose(function()
	print("Server shutting down, saving all players...")
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerRemoving(player)
	end
end)

print("💾 PlayerData (v2) system online.")