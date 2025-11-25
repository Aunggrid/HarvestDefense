-- src/client/UIController.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variables to hold our current UI elements
local screenGui = nil
local stateLabel = nil
local moneyLabel = nil

-- Function to setup UI (Runs on Join AND Respawn)
local function setupUI()
	screenGui = playerGui:WaitForChild("ScreenGui") 
	stateLabel = screenGui:WaitForChild("StateLabel")

	-- Re-create Money Label if missing (Standard studio setup might wipe it)
	moneyLabel = screenGui:FindFirstChild("MoneyLabel")
	if not moneyLabel then
		moneyLabel = Instance.new("TextLabel")
		moneyLabel.Name = "MoneyLabel"
		moneyLabel.Size = UDim2.new(0, 200, 0, 50)
		moneyLabel.Position = UDim2.new(0, 20, 0.5, 0) 
		moneyLabel.AnchorPoint = Vector2.new(0, 0.5)
		moneyLabel.BackgroundTransparency = 1
		moneyLabel.Font = Enum.Font.FredokaOne 
		moneyLabel.TextSize = 30
		moneyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		moneyLabel.TextStrokeTransparency = 0 
		moneyLabel.Parent = screenGui
	end
	
	-- Force an update immediately so it doesn't say "WAITING..."
	updateUI()
end

-- Make updateUI global so setupUI can call it
function updateUI()
	if not stateLabel or not moneyLabel then return end

	-- 1. Update Game State
	local state = ReplicatedStorage:GetAttribute("GameState")
	local wave = ReplicatedStorage:GetAttribute("Wave") or 1
	
	if state == "SURVIVE" then
		stateLabel.Text = "⚠️ WAVE " .. wave .. ": SURVIVE! ⚠️"
		stateLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
	else
		stateLabel.Text = "🌞 FARMING (Wave " .. wave .. ")"
		stateLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	end

	-- 2. Update Money
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local money = leaderstats:FindFirstChild("Money")
		if money then
			moneyLabel.Text = "💰 $" .. money.Value
		end
	end
end

-- LISTENERS
ReplicatedStorage:GetAttributeChangedSignal("GameState"):Connect(updateUI)
ReplicatedStorage:GetAttributeChangedSignal("Wave"):Connect(updateUI)

-- Money Listener (Needs to re-hook on respawn too)
player.CharacterAdded:Connect(function(char)
	-- Wait for UI to reload
	task.wait(0.5) 
	setupUI()
	
	-- Re-connect money listener
	local leaderstats = player:WaitForChild("leaderstats")
	local money = leaderstats:WaitForChild("Money")
	money.Changed:Connect(updateUI)
end)

-- Run once on first join
task.wait(1) -- Small wait to ensure loading is done
setupUI()