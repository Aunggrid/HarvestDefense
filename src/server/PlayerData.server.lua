-- src/server/PlayerData.server.lua
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DATA_KEY = "HarvestDefense_Data_v3" -- BUMP VERSION to reset data for new stats!
local myDataStore = DataStoreService:GetDataStore(DATA_KEY)

local function onPlayerAdded(player)
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0 
	money.Parent = leaderstats

	local sp = Instance.new("IntValue")
	sp.Name = "SkillPoints"
	sp.Value = 1
	sp.Parent = leaderstats
	
	-- [[ NEW: WOOD RESOURCE ]]
	local wood = Instance.new("IntValue")
	wood.Name = "Wood"
	wood.Value = 10 -- Start with 10 as requested
	wood.Parent = leaderstats
	
	local skillsFolder = Instance.new("Folder")
	skillsFolder.Name = "UnlockedSkills"
	skillsFolder.Parent = player

	local success, savedData = pcall(function()
		return myDataStore:GetAsync(player.UserId)
	end)

	if success and savedData and type(savedData) == "table" then
		money.Value = savedData.Money or 0
		sp.Value = savedData.SkillPoints or 1
		wood.Value = savedData.Wood or 10 -- Load Wood
		
		if savedData.Skills then
			for skillName, _ in pairs(savedData.Skills) do
				local tag = Instance.new("BoolValue"); tag.Name = skillName; tag.Parent = skillsFolder
			end
		end
		print("Loaded profile for " .. player.Name)
	else
		print("New player " .. player.Name .. " created.")
	end
end

local function onPlayerRemoving(player)
	local saveTable = {
		Money = player.leaderstats.Money.Value,
		SkillPoints = player.leaderstats.SkillPoints.Value,
		Wood = player.leaderstats.Wood.Value, -- Save Wood
		Skills = {}
	}
	
	for _, tag in ipairs(player.UnlockedSkills:GetChildren()) do
		saveTable.Skills[tag.Name] = true
	end

	pcall(function() myDataStore:SetAsync(player.UserId, saveTable) end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
game:BindToClose(function() for _, p in ipairs(Players:GetPlayers()) do onPlayerRemoving(p) end end)