-- src/client/DeathController.client.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService") -- Added Service

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local deathGui = playerGui:WaitForChild("DeathGui")
local frame = deathGui:WaitForChild("Frame")
local resetButton = frame:WaitForChild("ResetButton")

local events = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("events")
local resetEvent = events:WaitForChild("ResetGame")

local function onCharacterAdded(char)
	deathGui.Enabled = false
	player:SetAttribute("IsMenuOpen", false)
	
	local humanoid = char:WaitForChild("Humanoid")
	
	humanoid.Died:Connect(function()
		task.wait(1)
		deathGui.Enabled = true
		
		-- Force Mouse to appear
		player:SetAttribute("IsMenuOpen", true)
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

resetButton.MouseButton1Click:Connect(function()
	resetEvent:FireServer()
	deathGui.Enabled = false
end)