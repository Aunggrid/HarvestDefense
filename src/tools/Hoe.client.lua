-- src/tools/Hoe.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local tool = script.Parent

local events = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("events")
local tillGroundEvent = events:WaitForChild("TillGround")

-- CONFIG
local GRID_SIZE = 4
local GHOST_SIZE = Vector3.new(4, 0.2, 4) 

-- STATE
local ghostPart = nil

local function createGhost()
	if ghostPart then return end
	ghostPart = Instance.new("Part")
	ghostPart.Name = "GhostSoil"
	ghostPart.Size = GHOST_SIZE
	ghostPart.Anchored = true
	ghostPart.CanCollide = false
	ghostPart.Transparency = 0.4
	ghostPart.Color = Color3.fromRGB(130, 90, 50)
	ghostPart.Material = Enum.Material.Neon
	ghostPart.Parent = workspace
	mouse.TargetFilter = ghostPart
end

local function destroyGhost()
	if ghostPart then ghostPart:Destroy(); ghostPart = nil end
end

local function updateGhost()
	if not ghostPart then return end
	
	local target = mouse.Target
	
	-- STRICT CHECK: Only allow Baseplate or Terrain. 
	-- If we hover over existing Soil, existing Fence, or a Zombie, HIDE THE GHOST.
	if target and (target.Name == "Baseplate" or target:IsA("Terrain")) then
		
		-- 1. Grid Snap
		local x = math.round(mouse.Hit.X / GRID_SIZE) * GRID_SIZE
		local z = math.round(mouse.Hit.Z / GRID_SIZE) * GRID_SIZE
		
		-- 2. Height Logic
		local y
		if target:IsA("Terrain") then
			y = mouse.Hit.Y + (GHOST_SIZE.Y / 2)
		else
			y = target.Position.Y + (target.Size.Y / 2) + (GHOST_SIZE.Y / 2)
		end
		
		ghostPart.CFrame = CFrame.new(x, y, z)
		ghostPart.Color = Color3.fromRGB(100, 255, 100) -- Green (Valid)
	else
		-- If aiming at TilledSoil or anything else, Hide it.
		ghostPart.CFrame = CFrame.new(0, -100, 0) 
	end
end

tool.Equipped:Connect(createGhost)
tool.Unequipped:Connect(destroyGhost)

RunService.RenderStepped:Connect(function()
	if tool.Parent == player.Character then
		if not ghostPart then createGhost() end
		updateGhost()
	end
end)

tool.Activated:Connect(function()
	local target = mouse.Target
	-- Same strict check here preventing the click
	if ghostPart and target and (target.Name == "Baseplate" or target:IsA("Terrain")) then
		tillGroundEvent:FireServer(target, ghostPart.Position)
	end
end)