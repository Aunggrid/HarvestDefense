-- src/server/classes/Zombie.lua
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
-- Load the Parent Class
local Mob = require(ServerScriptService.Classes.Mob)

local Zombie = {}
Zombie.__index = Zombie
setmetatable(Zombie, Mob)

-- Configuration
local DAMAGE = 15
local ATTACK_COOLDOWN = 1.0
local ATTACK_RANGE = 4 

function Zombie.new(model)
	local self = Mob.new(model)
	setmetatable(self, Zombie)
	
	self.LastAttackTime = 0
	
	self.RootPart.Size = Vector3.new(3, 3, 3)
	self.RootPart.Transparency = 1
	self.Humanoid.WalkSpeed = 11
	
	self.RootPart.Touched:Connect(function(hit)
		self:Attack(hit)
	end)
	
	return self
end

function Zombie:Attack(hitPart)
	if self.IsDead then return end
	
	-- FRIENDLY FIRE CHECK
	local character = hitPart.Parent
	if character and character.Name == "Zombie" then return end -- Don't hit teammates!
	
	local now = tick()
	if (now - self.LastAttackTime) < ATTACK_COOLDOWN then return end

	-- [[ FIX STARTS HERE ]]
	-- We initialize humanoid to nil, and only look for it if character exists
	local humanoid = nil
	if character then
		humanoid = character:FindFirstChild("Humanoid")
	end
	-- [[ FIX ENDS HERE ]]

	local structureHealth = hitPart:GetAttribute("Health")

	if humanoid then
		self.LastAttackTime = now
		humanoid:TakeDamage(DAMAGE)
	elseif structureHealth and structureHealth > 0 then
		self.LastAttackTime = now
		
		local newHealth = structureHealth - DAMAGE
		hitPart:SetAttribute("Health", newHealth)
		
		local hitSound = Instance.new("Sound")
		hitSound.SoundId = "rbxassetid://9126242263" 
		hitSound.Parent = hitPart
		hitSound:Play()
		game.Debris:AddItem(hitSound, 1)

		if newHealth <= 0 then
			hitPart:Destroy()
		end
	end
end

function Zombie:CheckBlocking(targetPosition)
	if self.IsDead then return false end
	local origin = self.RootPart.Position
	local direction = (targetPosition - origin).Unit * ATTACK_RANGE 

	local params = RaycastParams.new()
	-- Ignore self AND other zombies so we don't stop just because a friend is in front
	params.FilterDescendantsInstances = {self.Model, Workspace:FindFirstChild("Zombie")} 
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(origin, direction, params)

	if result and result.Instance then
		if result.Instance:GetAttribute("Health") then
			self:Attack(result.Instance)
			return true
		end
	end

	return false
end

function Zombie:FindTarget()
	local nearestTarget = nil
	local minDistance = math.huge
	local myPos = self.RootPart.Position

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0 then
			local dist = (myPos - char.HumanoidRootPart.Position).Magnitude
			if dist < minDistance then
				minDistance = dist
				nearestTarget = char 
			end
		end
	end

	for _, obj in ipairs(CollectionService:GetTagged("Targetable")) do
		if obj:GetAttribute("Health") and obj:GetAttribute("Health") > 0 then
			local dist = (myPos - obj.Position).Magnitude
			if dist < minDistance then
				minDistance = dist
				nearestTarget = obj 
			end
		end
	end

	return nearestTarget
end

function Zombie:Run()
	task.spawn(function()
		while not self.IsDead and self.Humanoid.Health > 0 do
			local target = self:FindTarget()
			
			if target then
				local targetPos
				if target:IsA("Model") then
					targetPos = target.HumanoidRootPart.Position
				else
					targetPos = target.Position
				end
				
				local isBlocked = self:CheckBlocking(targetPos)
				
				if isBlocked then
					self.Humanoid:MoveTo(self.RootPart.Position)
				else
					self.Humanoid:MoveTo(targetPos)
				end
			end
			task.wait(0.2)
		end
	end)
end

return Zombie