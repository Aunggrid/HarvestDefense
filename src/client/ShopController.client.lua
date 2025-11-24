-- src/client/ShopController.client.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. FIND THE UI
-- We wait for the ScreenGui, Frame, and Button you created in Studio
local shopGui = playerGui:WaitForChild("ShopGui")
local shopFrame = shopGui:WaitForChild("ShopFrame")
local buyButton = shopFrame:WaitForChild("BuyButton")

-- 2. GET THE NETWORK FUNCTION
-- Note: We use "BuyItem" from the events folder
local eventsFolder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("events")
local buyItemFunction = eventsFolder:WaitForChild("BuyItem")

print("🛒 ShopController loaded. Ready to spend money.")

-- 3. THE INTERACTION
buyButton.MouseButton1Click:Connect(function()
	print("Requesting purchase: Golden Sword...")
	
	-- InvokeServer pauses this script until the Server replies!
	-- It returns whatever the Server returned (success bool, message string)
	local success, message = buyItemFunction:InvokeServer("Tools", "GoldenSword")
	
	if success then
		print("✅ PURCHASE SUCCESSFUL!")
		
		-- Visual Feedback (Pro Polish)
		buyButton.Text = "OWNED!"
		buyButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100) -- Green
		buyButton.Active = false -- Prevent clicking again
	else
		warn("❌ PURCHASE FAILED: " .. message)
		
		-- Visual Feedback for Failure
		local oldText = buyButton.Text
		buyButton.Text = message:upper()
		buyButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Red
		
		-- Reset text after 1 second
		task.wait(1)
		buyButton.Text = oldText
		buyButton.BackgroundColor3 = Color3.fromRGB(255, 255, 0) -- Back to Yellow (or whatever it was)
	end
end)