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
local PLOT_SIZE = Vector3.new(3.8, 1, 3.8) -- Slightly smaller than 4 to leave gaps
local GHOST_SIZE = PLOT_SIZE

local ghostPart = nil

local function createGhost()
	if ghostPart then return end
	ghostPart = Instance.new("Part")
	ghostPart.Name = "GhostPlot"
	ghostPart.Size = GHOST_SIZE
	ghostPart.Anchored = true
	ghostPart.CanCollide = false
	ghostPart.Transparency = 0.4
	ghostPart.Color = Color3.fromRGB(139, 69, 19) -- Brown (Wood/Dirt)
	ghostPart.Material = Enum.Material.Wood
	ghostPart.Parent = workspace
	mouse.TargetFilter = ghostPart
end

local function destroyGhost()
	if ghostPart then ghostPart:Destroy(); ghostPart = nil end
end

local function updateGhost()
	if not ghostPart then return end
	local target = mouse.Target
	
	-- Only build on Terrain or Baseplate
	if target and (target.Name == "Baseplate" or target:IsA("Terrain")) then
		local x = math.round(mouse.Hit.X / GRID_SIZE) * GRID_SIZE
		local z = math.round(mouse.Hit.Z / GRID_SIZE) * GRID_SIZE
		
		-- Place ON TOP of the ground
		local y = mouse.Hit.Y + (GHOST_SIZE.Y / 2)
		
		ghostPart.CFrame = CFrame.new(x, y, z)
		ghostPart.Color = Color3.fromRGB(100, 255, 100) -- Green
	else
		ghostPart.CFrame = CFrame.new(0, -100, 0) -- Hide
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
	if ghostPart and target and (target.Name == "Baseplate" or target:IsA("Terrain")) then
		-- Send the position to server
		tillGroundEvent:FireServer(target, ghostPart.Position)
	end
end)