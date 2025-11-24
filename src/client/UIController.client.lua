-- src/client/UIController.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for the UI
local screenGui = playerGui:WaitForChild("ScreenGui") 
local stateLabel = screenGui:WaitForChild("StateLabel")

-- NEW: Create a Money Label purely via code (so we don't have to mess with Studio UI)
local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "MoneyLabel"
moneyLabel.Size = UDim2.new(0, 200, 0, 50)
moneyLabel.Position = UDim2.new(0, 20, 0.5, 0) -- Left side of the screen
moneyLabel.AnchorPoint = Vector2.new(0, 0.5)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Font = Enum.Font.FredokaOne -- A nice cartoon font
moneyLabel.TextSize = 30
moneyLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
moneyLabel.TextStrokeTransparency = 0 -- Black outline
moneyLabel.Parent = screenGui

local function updateUI()
    -- 1. Update Game State (Existing Code)
    local state = ReplicatedStorage:GetAttribute("GameState")
    local wave = ReplicatedStorage:GetAttribute("Wave") or 1
    
    if state == "SURVIVE" then
        stateLabel.Text = "⚠️ WAVE " .. wave .. ": SURVIVE! ⚠️"
        stateLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    else
        stateLabel.Text = "🌞 FARMING (Wave " .. wave .. ")"
        stateLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    end

    -- 2. Update Money (New Code)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local money = leaderstats:FindFirstChild("Money")
        if money then
            moneyLabel.Text = "💰 $" .. money.Value
        end
    end
end

-- Listeners
ReplicatedStorage:GetAttributeChangedSignal("GameState"):Connect(updateUI)
ReplicatedStorage:GetAttributeChangedSignal("Wave"):Connect(updateUI)

-- NEW: Listen for Money Changes
local leaderstats = player:WaitForChild("leaderstats")
local money = leaderstats:WaitForChild("Money")
money.Changed:Connect(updateUI) -- Update immediately when money changes

-- Run once to start
updateUI()