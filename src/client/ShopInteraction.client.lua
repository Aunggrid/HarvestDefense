-- src/client/ShopInteraction.client.lua
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopGui = playerGui:WaitForChild("ShopGui")
local shopFrame = shopGui:WaitForChild("ShopFrame")

-- 1. SETUP VISUALS
-- Create the Blur effect locally (so only THIS player sees it)
local shopBlur = Instance.new("BlurEffect")
shopBlur.Name = "ShopBlur"
shopBlur.Size = 0 -- Start invisible
shopBlur.Parent = Lighting

-- Tween Info (0.5 seconds, Smooth transition)
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Helper to set visibility AND visuals
local function setShopState(isOpen)
	shopFrame.Visible = isOpen
	
	-- Update Camera/Mouse Lock
	player:SetAttribute("IsMenuOpen", isOpen)
	
	-- VISUALS: Tween the Blur
	local targetSize = 0
	if isOpen then
		targetSize = 24 -- How blurry? (0-56)
	end
	
	-- Animate the blur size
	TweenService:Create(shopBlur, tweenInfo, {Size = targetSize}):Play()
end

-- 2. OPENING THE SHOP (Press E)
ProximityPromptService.PromptTriggered:Connect(function(promptObject, playerWhoTriggered)
	if playerWhoTriggered == player and promptObject.Parent.Name == "ShopPart" then
		setShopState(not shopFrame.Visible)
	end
end)

-- 3. WALKING AWAY (Auto-Close)
ProximityPromptService.PromptHidden:Connect(function(promptObject)
	if promptObject.Parent.Name == "ShopPart" then
		if shopFrame.Visible then
			setShopState(false)
		end
	end
end)

-- Initialize
setShopState(false)