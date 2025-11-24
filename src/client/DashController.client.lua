-- src/client/DashController.client.lua
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local DASH_COOLDOWN = 2
local lastDash = 0

local function dash(actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		local now = tick()
		if now - lastDash < DASH_COOLDOWN then return end
		
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChild("Humanoid")
		
		-- Check Skill
		local hasSkill = player:WaitForChild("UnlockedSkills"):FindFirstChild("DodgeRoll_1")
		if not hasSkill then return end -- Must unlock skill first!
		
		lastDash = now
		
		-- Apply Force (The Roll)
		local vel = Instance.new("BodyVelocity")
		vel.MaxForce = Vector3.new(100000, 0, 100000)
		-- Dash in movement direction
		vel.Velocity = root.CFrame.LookVector * 50 
		vel.Parent = root
		Debris:AddItem(vel, 0.2) -- Short burst
		
		-- I-Frame (God Mode)
		local oldHealth = hum.Health
		local conn = hum.HealthChanged:Connect(function(newHp)
			if newHp < oldHealth then
				hum.Health = oldHealth -- Refund damage (Invincible!)
			end
		end)
		
		-- Play Animation
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://1014663274" -- Generic roll ID (might need to find one)
		local track = hum:LoadAnimation(anim)
		track:Play()
		
		task.wait(0.5)
		conn:Disconnect() -- End God Mode
	end
end

ContextActionService:BindAction("Dash", dash, true, Enum.KeyCode.Q)