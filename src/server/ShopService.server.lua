-- src/server/ShopService.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local ItemData = require(ReplicatedStorage.Shared.ItemData) -- Load our price list
local buyItemFunction = ReplicatedStorage.Shared.events:WaitForChild("BuyItem")

-- Helper to find item info
local function getItemInfo(category, itemName)
	if ItemData[category] and ItemData[category][itemName] then
		return ItemData[category][itemName]
	end
	return nil
end

local function onBuyRequest(player, category, itemName)
	-- 1. Validation: Does item exist?
	local itemInfo = getItemInfo(category, itemName)
	if not itemInfo then return false, "Item does not exist" end

	-- 2. Validation: Can afford?
	local moneyStat = player.leaderstats.Money
	if moneyStat.Value < itemInfo.Cost then
		return false, "Not enough money!"
	end

	-- 3. Validation: Do they already have it? (For tools)
	if category == "Tools" and player.Backpack:FindFirstChild(itemName) then
		return false, "You already own this!"
	end

	-- 4. TRANSACTION
	moneyStat.Value = moneyStat.Value - itemInfo.Cost
	
	-- 5. DELIVERY
	if category == "Tools" then
		-- We clone the tool from ServerStorage -> Tools -> [ItemName]
		local toolTemplate = ServerStorage.Tools:FindFirstChild(itemInfo.Model)
		if toolTemplate then
			local newTool = toolTemplate:Clone()
			newTool.Parent = player.Backpack
			print("Giving " .. itemName .. " to " .. player.Name)
		else
			warn("Could not find tool model: " .. itemInfo.Model)
		end
    end

	print(player.Name .. " bought " .. itemName)
	return true, "Purchase successful!"
end

buyItemFunction.OnServerInvoke = onBuyRequest
print("💰 ShopService Online")