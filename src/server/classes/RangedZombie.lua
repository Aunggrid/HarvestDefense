-- src/server/classes/RangedZombie.lua
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

-- 1. Load the Base Zombie Class
local Zombie = require(ServerScriptService.Classes.Zombie)

local RangedZombie = {}
RangedZombie.__index = RangedZombie
setmetatable(RangedZombie, Zombie) -- Inherit functionality

-- CONFIG
local ATTACK_RANGE = 30     -- Stops walking at this distance
local DAMAGE = 10           -- Less damage than melee zombie
local PROJECTILE_SPEED = 60 -- Studs per second

function RangedZombie.new(model)
	local self = Zombie.new(model) -- Call parent constructor
	setmetatable(self, RangedZombie)
	
	-- Visuals: Make it Green so we know it's special
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			part.Color = Color3.fromRGB(100, 200, 100) -- Acid Green
		end
	end
    -- Keep it weaker (Glass Cannon)
    self.Humanoid.MaxHealth = 30 
    self.Humanoid.Health = 30
	
	return self
end

-- 2. THE PROJECTILE SYSTEM (Embedded Logic)
function RangedZombie:FireProjectile(targetPos)
	local startPos = self.RootPart.Position + Vector3.new(0, 2, 0) -- Shoot from chest height
	
	-- Create the "Acid Ball"
	local bullet = Instance.new("Part")
	bullet.Name = "AcidSpit"
	bullet.Shape = Enum.PartType.Ball
	bullet.Size = Vector3.new(1.5, 1.5, 1.5)
	bullet.Material = Enum.Material.Neon
	bullet.Color = Color3.fromRGB(0, 255, 100)
	bullet.CanCollide = false
	bullet.Anchored = true -- We will move it manually with Tween
	bullet.CFrame = CFrame.new(startPos, targetPos)
	bullet.Parent = workspace
	
	-- Calculate flight time
	local distance = (targetPos - startPos).Magnitude
	local flightTime = distance / PROJECTILE_SPEED
	
	-- Animate the flight
	local tweenInfo = TweenInfo.new(flightTime, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(bullet, tweenInfo, {Position = targetPos})
	tween:Play()
	
	-- Hit Logic
	tween.Completed:Connect(function()
        if not bullet.Parent then return end -- Bullet already destroyed

		-- Explosion Effect (Visual)
        local blast = Instance.new("Part")
        blast.Size = Vector3.new(4,4,4); blast.Shape = Enum.PartType.Ball
        blast.Color = bullet.Color; blast.Material = Enum.Material.Neon
        blast.Anchored = true; blast.CanCollide = false
        blast.Transparency = 0.5; blast.Position = bullet.Position
        blast.Parent = workspace
        Debris:AddItem(blast, 0.2)

		-- Detect Hit (Small Area Damage)
		local parts = workspace:GetPartBoundsInRadius(bullet.Position, 4)
		local hitHumanoids = {}
		
		for _, hit in ipairs(parts) do
			local char = hit.Parent
			local hum = char:FindFirstChild("Humanoid")
            
            -- Don't hit self or other zombies
			if hum and char.Name ~= "Zombie" and not hitHumanoids[hum] then
				hitHumanoids[hum] = true
				hum:TakeDamage(DAMAGE)
			elseif hit.Name == "WoodFence" or hit.Name == "FarmPlot" then
                -- Damage Buildings
                local hp = hit:GetAttribute("Health")
                if hp then
                    hit:SetAttribute("Health", hp - DAMAGE)
                    if hp - DAMAGE <= 0 then hit:Destroy() end
                end
            end
		end
		
		bullet:Destroy()
	end)
end

-- 3. OVERRIDE THE ATTACK (Ranged instead of Melee)
function RangedZombie:Attack(target)
	local now = tick()
	if (now - self.LastAttackTime) < 2.0 then return end -- Slower attack speed
	self.LastAttackTime = now
	
	-- Get target position
	local targetPos = nil
	if target:IsA("Model") and target.PrimaryPart then
		targetPos = target.PrimaryPart.Position
	elseif target:IsA("BasePart") then
		targetPos = target.Position
	end
	
	if targetPos then
		self:FireProjectile(targetPos)
	end
end

-- 4. OVERRIDE THE BRAIN (Stop at distance)
function RangedZombie:Run()
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
				
				local distance = (self.RootPart.Position - targetPos).Magnitude
				
				-- LOGIC CHANGE:
				-- If far away? Walk closer.
				-- If close enough? STOP and SHOOT.
				if distance > ATTACK_RANGE then
					self.Humanoid:MoveTo(targetPos)
				else
					self.Humanoid:MoveTo(self.RootPart.Position) -- Stop moving
					-- Rotate to face target (Optional cosmetic)
					self.RootPart.CFrame = CFrame.lookAt(self.RootPart.Position, Vector3.new(targetPos.X, self.RootPart.Position.Y, targetPos.Z))
					self:Attack(target)
				end
			end
			task.wait(0.2)
		end
	end)
end

return RangedZombie