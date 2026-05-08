-- @ScriptType: ModuleScript
local ItemData = {}

ItemData.Equipment = {

	-- Raid Equipment
	["Luck and Pluck"] = { Slot = "Weapon", Bonus = { Strength = 35, Willpower = 40, Health = 25 }, Rarity = "Mythical", Cost = 5000 },
	["Kars' Arm Blade"] = { Slot = "Weapon", Bonus = { Strength = 45, Speed = 45, Stand_Range = 15 }, Rarity = "Mythical", Cost = 5500 },
	["DIO's Road Sign"] = { Slot = "Weapon", Bonus = { Strength = 100, Defense = 30, Stand_Power = 20 }, Rarity = "Mythical", Cost = 7500 },
	["Stray Cat"] = { Slot = "Weapon", Bonus = { Stand_Speed = 80, Speed = 40 }, Rarity = "Mythical", Cost = 8000 },
	["Doppio's Phone"] = { Slot = "Weapon", Bonus = { Stand_Precision = 100, Stand_Potential = 50 }, Rarity = "Mythical", Cost = 9000 },
	["DIO's Bone"] = { Slot = "Weapon", Bonus = { Stand_Potential = 150, Willpower = 100 }, Rarity = "Mythical", Cost = 12500 },
	["Valentine's Revolver"] = { Slot = "Weapon", Bonus = { Stand_Precision = 150, Stand_Power = 100, Speed = 80 }, Rarity = "Mythical", Cost = 15000 },
	["Wonder of U's Cane"] = { Slot = "Weapon", Bonus = { Stand_Speed = 150, Stand_Power = 120, Defense = 80 }, Rarity = "Mythical", Cost = 17500 },

	["Dio's Head Jar"] = { Slot = "Accessory", Bonus = { Defense = 60, Willpower = 40 }, Rarity = "Mythical", Cost = 5000 },
	["Kars' Horn"] = { Slot = "Accessory", Bonus = { Stand_Range = 60, Stand_Precision = 40, Speed = 20 }, Rarity = "Mythical", Cost = 5500 },
	["DIO's Headband"] = { Slot = "Accessory", Bonus = { Stand_Power = 60, Strength = 40, Willpower = 20 }, Rarity = "Mythical", Cost = 7500 },
	["Kira's Wristwatch"] = { Slot = "Accessory", Bonus = { Stand_Durability = 50, Defense = 50, Willpower = 40 }, Rarity = "Mythical", Cost = 8000 },
	["Passione Badge"] = { Slot = "Accessory", Bonus = { Stand_Power = 50, Stand_Potential = 50, Health = 40 }, Rarity = "Mythical", Cost = 9000 },
	["Priest's Rosary"] = { Slot = "Accessory", Bonus = { Stand_Durability = 100, Willpower = 50, Defense = 30 }, Rarity = "Mythical", Cost = 12500 },
	["The First Napkin"] = { Slot = "Accessory", Bonus = { Stand_Power = 100, Stand_Durability = 100, Defense = 80 }, Rarity = "Mythical", Cost = 15000 },
	["Rock Insect"] = { Slot = "Accessory", Bonus = { Stand_Durability = 150, Defense = 100, Strength = 80 }, Rarity = "Mythical", Cost = 17500 },

}

ItemData.Consumables = {
	-- Style Items

	["Perfect Aja Mask"] = { Category = "Player", Description = "A stone mask with the Red Stone embedded. Evolves Pillarman into the Ultimate Lifeform.", Rarity = "Mythical", Cost = 4500 },
	["Golden Spin Scroll"] = { Category = "Player", Description = "The secret of infinite rotation. Evolves the Spin style into Golden Spin.", Rarity = "Mythical", Cost = 4500 },
	["Rokakaka Fruit"] = { Category = "Player", Description = "A mysterious fruit from the Higashikata orchard. Consuming it transforms your biology into that of a Rock Human.", Rarity = "Mythical", Cost = 4500 },

	["Saint's Pelvis"] = { Category = "Stand", Description = "A mummified pelvis. Evolves Tusk Act 3 into Act 4.", Rarity = "Mythical", Cost = 5000 },
	["Saint's Heart"] = { Category = "Stand", Description = "A mummified heart. Evolves Dirty Deeds Done Dirt Cheap into Love Train.", Rarity = "Mythical", Cost = 5000 },
	["Saint's Spine"] = { Category = "Stand", Description = "A mummified spine. Evolves The World and Star Platinum into Over Heaven!", Rarity = "Mythical", Cost = 5000 },
	["Rokakaka Branch"] = { Category = "Stand", Description = "A miraculously grafted branch. Evolves Soft & Wet to push its bubbles beyond logic.", Rarity = "Mythical", Cost = 5000},

	-- Misc Items
	["Requiem Arrow"] = { Category = "Stand", Description = "An arrow with a bizzare beetle design. Pushes your stand beyond anything ever seen.", Rarity = "Mythical", Cost = 5000},
	["New Rokakaka"] = { Category = "Stand", Description = "The ultimate fruit of equivalent exchange. Fuses two of your Stands into a powerful hybrid.", Rarity = "Mythical", Cost = 5000},
	["Inversion Medicine"] = { Category = "Stand", Description = "The ultimate medicine. Reverts your Fused Stand back to its original forms.", Rarity = "Mythical", Cost = 5000},

	-- Advanced Training Manuals
	["Advanced Style Training Manual"] = { Category = "Player", Description = "A mythical manual containing the pinnacle of physical arts. Grants all Player Stats.", Rarity = "Mythical", Cost = 10000 },
	["Advanced Stand Training Manual"] = { Category = "Stand", Description = "A mythical manual detailing the apex of spiritual manifestation. Grants all Stand Stats.", Rarity = "Mythical", Cost = 10000 },
	["Master Training Manual"] = { Category = "Stand", Description = "A mythical manual that unifies the body and spirit perfectly. Grants all Player and Stand Stats.", Rarity = "Mythical", Cost = 15000 },

}

return ItemData