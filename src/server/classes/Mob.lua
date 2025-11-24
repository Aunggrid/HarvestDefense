-- src/server/classes/Mob.lua
local Mob = {}
Mob.__index = Mob

-- Constructor: Creates a new Mob object
function Mob.new(model)
	local self = setmetatable({}, Mob)
	
	self.Model = model
	self.Humanoid = model:WaitForChild("Humanoid")
	self.RootPart = model:WaitForChild("HumanoidRootPart")
	self.IsDead = false
	
	-- Listen for death automatically
	self.Humanoid.Died:Connect(function()
		self:Die()
	end)
	
	return self
end

-- Method: Move to a position
function Mob:MoveTo(position)
	if self.IsDead then return end
	self.Humanoid:MoveTo(position)
end

-- Method: Die (Clean up and visual effects)
function Mob:Die()
	if self.IsDead then return end
	self.IsDead = true
	
	print(self.Model.Name .. " has died (Base Class Logic)")
	
	-- Stop moving
	self.Humanoid.WalkSpeed = 0
	self.RootPart.Anchored = true
	
	-- Particle Effect (Refactored from your old script!)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://243098098" -- Smoke
	emitter.Color = ColorSequence.new(Color3.fromRGB(87, 146, 76))
	emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0)})
	emitter.Lifetime = NumberRange.new(0.5, 1)
	emitter.Speed = NumberRange.new(5, 10)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Rate = 0
	emitter.Parent = self.RootPart
	emitter:Emit(20)
	
	-- Sound
	local deathSound = Instance.new("Sound")
	deathSound.SoundId = "rbxassetid://75221355097604" -- Slime Splat
	deathSound.Parent = self.RootPart
	deathSound:Play()
	
	-- Cleanup
	game.Debris:AddItem(self.Model, 1.5)
end

return Mob