-- src/server/SkillService.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemData = require(ReplicatedStorage.Shared.ItemData)

local events = ReplicatedStorage.Shared.events
local unlockSkillFunc = events:WaitForChild("UnlockSkill")

local function onUnlockRequest(player, skillId)
	-- 1. Validate Skill Exists
	local skillInfo = ItemData.Skills[skillId]
	if not skillInfo then return false, "Unknown Skill" end
	
	-- 2. Check Paths
	local leaderstats = player:FindFirstChild("leaderstats")
	local skillsFolder = player:FindFirstChild("UnlockedSkills")
	if not leaderstats or not skillsFolder then return false, "Data Error" end
	
	-- 3. Check if already unlocked (Max Level Check)
	-- We check for "Cleave_1" tag
	local tagName = skillId .. "_1"
	if skillsFolder:FindFirstChild(tagName) then
		return false, "Already Unlocked!"
	end
	
	-- 4. Check Cost
	local sp = leaderstats.SkillPoints
	if sp.Value < skillInfo.Cost then
		return false, "Need " .. skillInfo.Cost .. " Skill Point!"
	end
	
	-- 5. TRANSACTION
	sp.Value = sp.Value - skillInfo.Cost
	
	-- 6. Grant Skill (Create the tag)
	local tag = Instance.new("BoolValue")
	tag.Name = tagName
	tag.Parent = skillsFolder
	
	print(player.Name .. " learned " .. skillId)
	return true, "Learned " .. skillInfo.Name
end

unlockSkillFunc.OnServerInvoke = onUnlockRequest
print("🧠 SkillService Online")