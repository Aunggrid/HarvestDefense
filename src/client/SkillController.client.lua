-- src/client/SkillController.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local skillGui = playerGui:WaitForChild("SkillGui")
local mainFrame = skillGui:WaitForChild("MainFrame")
local pointsLabel = mainFrame:WaitForChild("PointsLabel")

local events = ReplicatedStorage.Shared.events
local unlockFunc = events:WaitForChild("UnlockSkill")

-- 1. UPDATE UI
local function updatePoints()
	local sp = player.leaderstats.SkillPoints.Value
	pointsLabel.Text = "Skill Points: " .. sp
end

-- 2. BUTTON LOGIC helper
local function setupButton(btnName, skillId)
	local btn = mainFrame:FindFirstChild(btnName)
	if not btn then return end
	
	-- Check if we already have it visually
	if player.UnlockedSkills:FindFirstChild(skillId.."_1") then
		btn.Text = "UNLOCKED"
		btn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	end
	
	btn.MouseButton1Click:Connect(function()
		local success, msg = unlockFunc:InvokeServer(skillId)
		if success then
			btn.Text = "UNLOCKED"
			btn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
			updatePoints()
		else
			local oldText = btn.Text
			btn.Text = msg
			btn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
			task.wait(1)
			btn.Text = oldText
			btn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		end
	end)
end

-- Connect Buttons
setupButton("CleaveButton", "Cleave")
setupButton("DashButton", "Dash")
setupButton("ReachButton", "Reach")
-- 3. TOGGLE MENU (Press K)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.K then
		mainFrame.Visible = not mainFrame.Visible
		updatePoints()
		
		-- Use our Menu Attribute system! (Unlocks mouse automatically)
		player:SetAttribute("IsMenuOpen", mainFrame.Visible)
	end
end)