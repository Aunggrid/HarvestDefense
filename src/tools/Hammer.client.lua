-- src/tools/Hammer.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local tool = script.Parent

local events = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("events")
local buildEvent = events:WaitForChild("BuildStructure")

-- CONFIGURATION
local GRID_SIZE = 4
local GHOST_SIZE = Vector3.new(4, 4, 1)

-- STATE
local currentRotation = 0 
local ghostPart = nil

local function createGhost()
	if ghostPart then return end
	ghostPart = Instance.new("Part")
	ghostPart.Name = "GhostFence"
	ghostPart.Size = GHOST_SIZE
	ghostPart.Anchored = true
	ghostPart.CanCollide = false
	ghostPart.Transparency = 0.5
	ghostPart.Color = Color3.fromRGB(0, 255, 0)
	ghostPart.Material = Enum.Material.ForceField
	
	-- [[ FIX IS HERE ]]
	-- Parent to Character so it auto-deletes on death
	ghostPart.Parent = player.Character or workspace
	
	mouse.TargetFilter = ghostPart 
end

local function destroyGhost()
	if ghostPart then ghostPart:Destroy(); ghostPart = nil end
end

local function updateGhost()
	if not ghostPart then return end
	
	local target = mouse.Target
	-- CHECK: Baseplate OR Terrain (or any anchored part)
	if target and (target.Anchored or target:IsA("Terrain")) then
		
		-- 1. Grid Snap
		local x = math.round(mouse.Hit.X / GRID_SIZE) * GRID_SIZE
		local z = math.round(mouse.Hit.Z / GRID_SIZE) * GRID_SIZE
		
		-- 2. Height Fix
		local y
		if target:IsA("Terrain") then
			y = mouse.Hit.Y + (GHOST_SIZE.Y / 2)
		else
			y = target.Position.Y + (target.Size.Y / 2) + (GHOST_SIZE.Y / 2)
		end
		
		local snapPos = Vector3.new(x, y, z)
		
		-- 3. Rotation
		local rotationCFrame = CFrame.Angles(0, math.rad(currentRotation), 0)
		ghostPart.CFrame = CFrame.new(snapPos) * rotationCFrame
		ghostPart.Color = Color3.fromRGB(0, 255, 0) 
	else
		ghostPart.CFrame = CFrame.new(0, -100, 0) 
	end
end

tool.Equipped:Connect(createGhost)
tool.Unequipped:Connect(destroyGhost)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.R and tool.Parent == player.Character then
		currentRotation = currentRotation + 90
		if currentRotation >= 360 then currentRotation = 0 end
	end
end)

RunService.RenderStepped:Connect(function()
	if tool.Parent == player.Character then
		if not ghostPart then createGhost() end
		updateGhost()
	end
end)

tool.Activated:Connect(function()
	local target = mouse.Target
	if ghostPart and target and (target.Anchored or target:IsA("Terrain")) then
		buildEvent:FireServer("WoodFence", ghostPart.Position, currentRotation)
	end
end)