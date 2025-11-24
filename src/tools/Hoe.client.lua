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
local GHOST_SIZE = Vector3.new(4, 1, 4) 

-- STATE
local ghostPart = nil

local function createGhost()
	if ghostPart then return end
	ghostPart = Instance.new("Part")
	ghostPart.Name = "GhostSoil"
	ghostPart.Size = GHOST_SIZE
	ghostPart.Anchored = true
	ghostPart.CanCollide = false
	
	-- UPDATED VISUALS: Make it 'Neon' so it glows and is easy to see
	ghostPart.Transparency = 0.4 -- More solid (was 0.5)
	ghostPart.Color = Color3.fromRGB(130, 90, 50) -- Lighter Brown for visibility
	ghostPart.Material = Enum.Material.Neon -- Neon makes it stand out in the dark!
	
	ghostPart.Parent = workspace
	mouse.TargetFilter = ghostPart
end

local function destroyGhost()
	if ghostPart then ghostPart:Destroy(); ghostPart = nil end
end

local function updateGhost()
	if not ghostPart then return end
	
	local target = mouse.Target
	-- Only show ghost on valid ground (Baseplate)
	--if target and target.Name == "Baseplate" then
	if target and (target.Name == "Baseplate" or target:IsA("Terrain")) then
		-- SNAP TO GRID
		local x = math.round(mouse.Hit.X / GRID_SIZE) * GRID_SIZE
		local z = math.round(mouse.Hit.Z / GRID_SIZE) * GRID_SIZE
		local y = target.Position.Y + (target.Size.Y / 2) + (GHOST_SIZE.Y / 2)
		
		ghostPart.CFrame = CFrame.new(x, y, z)
		-- Keep it visible Green/Brown to show "You can place here"
		ghostPart.Color = Color3.fromRGB(100, 255, 100) -- Bright Green means "Valid Spot"
		ghostPart.Transparency = 0.4
	else
		-- Hide it (or turn red)
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
	--if ghostPart and mouse.Target and mouse.Target.Name == "Baseplate" then
	if ghostPart and mouse.Target and (mouse.Target.Name == "Baseplate" or mouse.Target:IsA("Terrain")) then
		tillGroundEvent:FireServer(mouse.Target, ghostPart.Position)
	end
end)