-- src/client/LoadingController.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local loadingGui = playerGui:WaitForChild("LoadingGui")

local events = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("events")
local mapReadyEvent = events:WaitForChild("MapLoaded")

-- 1. FORCE SHOW UI (Since we hid it in Studio)
loadingGui.Enabled = true

-- 2. DISABLE CONTROLS
local controls = require(player.PlayerScripts.PlayerModule):GetControls()
controls:Disable()

-- Helper to free the player
local function releasePlayer()
	if loadingGui.Parent then 
		loadingGui:Destroy() 
	end
	controls:Enable()
end

-- 3. LISTEN FOR SUCCESS
mapReadyEvent.OnClientEvent:Connect(function()
	task.wait(1) -- Wait for chunks to render visually
	releasePlayer()
	
	-- Sound
	local sfx = Instance.new("Sound")
	sfx.SoundId = "rbxassetid://9116394545" 
	sfx.Parent = workspace
	sfx:Play()
end)

-- 4. SAFETY TIMEOUT (Fixes "Stuck Frozen" bug)
-- If the map generator fails or takes too long, let the player move anyway.
task.delay(8, function()
	if loadingGui.Parent then
		warn("⚠️ Map Generation Timed Out! Releasing controls forcefully.")
		releasePlayer()
	end
end)