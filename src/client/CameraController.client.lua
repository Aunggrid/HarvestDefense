-- src/client/CameraController.client.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = game.Workspace.CurrentCamera

-- Configuration
local TOGGLE_KEY = Enum.KeyCode.LeftAlt
local isLocked = true -- Default to locked (Combat Mode)

local function updateState()
	-- 1. Check if the shop/menu is open
	local isMenuOpen = player:GetAttribute("IsMenuOpen")

	-- 2. LOGIC FIX:
	-- We only lock the mouse if Combat Mode is ON (isLocked) AND the Menu is OFF (not isMenuOpen)
	if isLocked and not isMenuOpen then
		-- COMBAT MODE
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false -- Hide cursor
		
		-- Disable Roblox auto-turning so we can strafe
		local character = player.Character
		if character and character:FindFirstChild("Humanoid") then
			character.Humanoid.AutoRotate = false
		end
	else
		-- MENU MODE or UNLOCKED
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true -- Show cursor
		
		-- Let Roblox handle turning again
		local character = player.Character
		if character and character:FindFirstChild("Humanoid") then
			character.Humanoid.AutoRotate = true
		end
	end
end

-- Listen for the Attribute changing (This lets the Shop script control the Camera!)
player:GetAttributeChangedSignal("IsMenuOpen"):Connect(updateState)

-- 1. Handle the Toggle Key (Alt)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == TOGGLE_KEY then
		isLocked = not isLocked
		updateState()
	end
end)

-- 2. Enforce the state (Roblox likes to unlock the mouse when you click menus)
UserInputService.WindowFocused:Connect(updateState)

-- 3. The "Strafing" Loop (Runs every single frame)
RunService.RenderStepped:Connect(function()
	local isMenuOpen = player:GetAttribute("IsMenuOpen")

	-- STOP strafing if the menu is open OR if we unlocked the mouse with Alt
	if not isLocked or isMenuOpen then return end
	
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChild("Humanoid")
		
		if rootPart and humanoid then
			-- Ensure AutoRotate is off so Roblox doesn't fight us
			humanoid.AutoRotate = false
			
			-- Calculate the Camera's direction (Flattened)
			local cameraLook = camera.CFrame.LookVector
			local lookDirection = Vector3.new(cameraLook.X, 0, cameraLook.Z).Unit
			
			-- Create a new rotation looking at (Current Pos + Camera Direction)
			local targetRotation = CFrame.lookAt(rootPart.Position, rootPart.Position + lookDirection)
			
			-- Apply it! (Lerp makes it smoother, 0.5 is snappy)
			rootPart.CFrame = rootPart.CFrame:Lerp(targetRotation, 0.5)
		end
	end
end)

-- Handle Respawning (Reset settings when you get a new body)
player.CharacterAdded:Connect(function()
	task.wait(0.1) -- Wait for body to load
	updateState()
end)

-- Run once at start
task.wait()
updateState()