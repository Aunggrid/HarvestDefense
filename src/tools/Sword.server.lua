-- src/tools/Sword.server.lua
local tool = script.Parent
local handle = tool:WaitForChild("Handle")
local Debris = game:GetService("Debris") -- Need this for cleanup

local DAMAGE = tool:GetAttribute("Damage") or 10
local COOLDOWN = 0.6
local canAttack = true

local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://111995201371273"
local loadedAnimationTrack = nil

-- HELPER: Check Skill Level
local function getPlayerSkillLevel(player, skillName)
	local folder = player:FindFirstChild("UnlockedSkills")
	if folder then
		if folder:FindFirstChild(skillName.."_2") then return 2 end
		if folder:FindFirstChild(skillName.."_1") then return 1 end
	end
	return 0
end

-- Initialize Animation
tool.Equipped:Connect(function()
    local character = tool.Parent
    local humanoid = character:FindFirstChild("Humanoid")
    local animator = humanoid:FindFirstChild("Animator")
    if animator then
        loadedAnimationTrack = animator:LoadAnimation(animation)
    end
end)

tool.Unequipped:Connect(function()
    if loadedAnimationTrack then loadedAnimationTrack:Stop(); loadedAnimationTrack = nil end
end)

local hitSound = Instance.new("Sound")
hitSound.SoundId = "rbxassetid://3932505023"
hitSound.Volume = 1
hitSound.Parent = handle

-- LOGIC: Process the hit
local function processHit(otherPart)
    local character = otherPart.Parent
    local humanoid = character:FindFirstChild("Humanoid")
    
    if humanoid then
        local myPlayer = game.Players:GetPlayerFromCharacter(tool.Parent)
        local hitPlayer = game.Players:GetPlayerFromCharacter(character)
        
        if myPlayer and hitPlayer then return end -- No PVP
        
        -- 1. DEAL MAIN DAMAGE
        humanoid:TakeDamage(DAMAGE)
        
        -- 2. CLEAVE SKILL CHECK
        if myPlayer then
            local cleaveLevel = getPlayerSkillLevel(myPlayer, "Cleave")
            if cleaveLevel > 0 then
                local radius = 6 + (cleaveLevel * 2)
                local cleaveDmg = DAMAGE * 0.25
                
                local overlapParams = OverlapParams.new()
                overlapParams.FilterDescendantsInstances = {tool.Parent, character}
                overlapParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local parts = workspace:GetPartBoundsInRadius(otherPart.Position, radius, overlapParams)
                local hitHumanoids = {} 
                
                for _, part in ipairs(parts) do
                    local otherChar = part.Parent
                    local otherHum = otherChar:FindFirstChild("Humanoid")
                    if otherHum and otherHum.Health > 0 and not hitHumanoids[otherHum] then
                        hitHumanoids[otherHum] = true
                        otherHum:TakeDamage(cleaveDmg)
                        
                        -- Visual
                        local vfx = Instance.new("Part")
                        vfx.Size = Vector3.new(1,1,1); vfx.Position = otherHum.RootPart.Position
                        vfx.Anchored = true; vfx.CanCollide = false; vfx.Transparency = 1
                        vfx.Parent = workspace; Debris:AddItem(vfx, 1)
                    end
                end
            end
        end
        
        -- 3. PLAY SOUND
        local sfx = hitSound:Clone()
        sfx.Parent = handle
        sfx.PlaybackSpeed = math.random(90, 110) / 100 
        sfx:Play()
        Debris:AddItem(sfx, 1) 
    end
end

tool.Activated:Connect(function()
    if not canAttack then return end
    
    local character = tool.Parent
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local myPlayer = game.Players:GetPlayerFromCharacter(character)
    
    -- NEW: RANGE SKILL CALCULATION
    local reachLevel = 0
    if myPlayer then
        reachLevel = getPlayerSkillLevel(myPlayer, "Reach") -- You need to add "Reach" to ItemData!
    end
    
    -- Base size 4, +2 studs per skill level
    local hitboxSize = Vector3.new(4, 4, 4) + Vector3.new(reachLevel*2, reachLevel*2, reachLevel*2)
    
    -- CREATE TEMPORARY HITBOX
    local hitbox = Instance.new("Part")
    hitbox.Name = "SwordHitbox"
    hitbox.Size = hitboxSize
    hitbox.Transparency = 1 -- Invisible (Set to 0.5 to debug and see how big it is!)
    hitbox.CanCollide = false
    hitbox.Massless = true
    hitbox.CFrame = rootPart.CFrame * CFrame.new(0, 0, -hitboxSize.Z/2 - 2) -- Project in front of player
    hitbox.Parent = workspace
    
    -- Weld it to the player so it moves with the swing
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rootPart
    weld.Part1 = hitbox
    weld.Parent = hitbox

    -- Cleanup after swing
    Debris:AddItem(hitbox, 0.3)

    if loadedAnimationTrack then loadedAnimationTrack:Play() end
    
    -- Listen for touches on the HITBOX, not the handle
    local connection = hitbox.Touched:Connect(function(hit)
        processHit(hit)
    end)
    
    canAttack = false
    tool.Enabled = false
    task.wait(COOLDOWN)
    if connection then connection:Disconnect() end
    canAttack = true
    tool.Enabled = true
end)