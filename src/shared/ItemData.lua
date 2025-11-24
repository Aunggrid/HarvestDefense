-- src/shared/ItemData.lua
local ItemData = {
	Tools = {
		Sword = {
			Name = "Iron Sword",
			Cost = 0, -- Free starter item (logic handled later)
			Damage = 35,
			Cooldown = 0.6,
			Model = "Sword" -- Name of the tool in ServerStorage
		},
		GoldenSword = {
			Name = "Golden Blade",
			Cost = 10,
			Damage = 100, -- One shots normal zombies
			Cooldown = 0.4,
			Model = "GoldenSword"
		}
	},
	Seeds = {
		Wheat = {
			Name = "Wheat Seeds",
			Cost = 10,
			SellPrice = 20, -- Profit!
			GrowthTime = 5
		},
		Pumpkin = {
			Name = "Pumpkin Seeds",
			Cost = 50,
			SellPrice = 150,
			GrowthTime = 15
		}
	},
	Buildings = {
        WoodFence = {
            Name = "Wooden Fence",
            Cost = 25,
            Health = 100, -- How much damage it can take
            Model = "WoodFence" -- We will create this model soon
        }
    },
	PlantDrops = {
		{ Type = "MoneyPlant", Chance = 50 },  -- 50% Common
		{ Type = "HealPlant",  Chance = 30 },  -- 30% Rare
		{ Type = "TurretPlant", Chance = 20 }  -- 20% Legendary
	},
	Plants = {
		MoneyPlant = { Name = "Golden Corn", Health = 50, Color = Color3.fromRGB(255, 215, 0) },
		HealPlant = { Name = "Healing Aloe", Health = 80, Color = Color3.fromRGB(100, 255, 100) },
		TurretPlant = { Name = "Pea Shooter", Health = 100, Color = Color3.fromRGB(255, 0, 0) }
	},
	Skills = {
        Cleave = {
            Name = "Cleave Master",
            Description = "Deal damage to enemies near your target.",
            Cost = 1, -- Costs 1 Skill Point
            MaxLevel = 1
        },
        Dash = {
            Name = "Dodge Roll",
            Description = "Press Q to roll and avoid damage.",
            Cost = 1,
            MaxLevel = 1
        },
		Reach = {
            Name = "Long Reach",
            Description = "Hit enemies from further away.",
            Cost = 1,
            MaxLevel = 1
        }
    }
}


return ItemData