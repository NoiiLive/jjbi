-- @ScriptType: ModuleScript
local ItemData = {}

ItemData.Equipment = {
	["Brass Knuckles"] = { Slot = "Weapon", Bonus = { Strength = 5, Stamina = 5 }, Rarity = "Common", Cost = 100 },
	["Wooden Bat"] = { Slot = "Weapon", Bonus = { Strength = 8, Speed = -2 }, Rarity = "Common", Cost = 150 },
	["Steel Pipe"] = { Slot = "Weapon", Bonus = { Strength = 12, Defense = 2 }, Rarity = "Common", Cost = 200 },
	["Combat Knife"] = { Slot = "Weapon", Bonus = { Strength = 10, Speed = 5 }, Rarity = "Uncommon", Cost = 1500 },
	["Hamon Clackers"] = { Slot = "Weapon", Bonus = { Strength = 8, Stamina = 10, Speed = 5 }, Rarity = "Uncommon", Cost = 2000 },
	["Heavy Revolver"] = { Slot = "Weapon", Bonus = { Strength = 15, Stand_Precision = 10 }, Rarity = "Uncommon", Cost = 3500 },
	["Luck Sword"] = { Slot = "Weapon", Bonus = { Strength = 15, Speed = 10 }, Rarity = "Rare", Cost = 15000 },
	["Tommy Gun"] = { Slot = "Weapon", Bonus = { Strength = 20, Speed = 15 }, Rarity = "Rare", Cost = 25000 },
	["Road Roller"] = { Slot = "Weapon", Bonus = { Strength = 80, Defense = 20, Speed = -10 }, Rarity = "Legendary", Cost = 120000 },

	["Dio's Throwing Knives"] = { Slot = "Weapon", Bonus = { Strength = 15, Stand_Speed = 20 }, Rarity = "Uncommon", Cost = 4000 },
	["Jolyne's String"] = { Slot = "Weapon", Bonus = { Stand_Range = 25, Stand_Speed = 15 }, Rarity = "Rare", Cost = 28000 },
	["Mista's Pistol"] = { Slot = "Weapon", Bonus = { Stand_Precision = 35, Stand_Speed = 15 }, Rarity = "Rare", Cost = 28000 },
	["Anubis Sword"] = { Slot = "Weapon", Bonus = { Stand_Power = 30, Stand_Speed = 20 }, Rarity = "Rare", Cost = 30000 },
	["Emperor Gun"] = { Slot = "Weapon", Bonus = { Stand_Precision = 40, Stand_Range = 20 }, Rarity = "Rare", Cost = 30000 },
	["Bite the Dust Detonator"] = { Slot = "Weapon", Bonus = { Stand_Power = 60, Defense = 10 }, Rarity = "Legendary", Cost = 100000 },

	["Tinted Sunglasses"] = { Slot = "Accessory", Bonus = { Willpower = 10, Defense = 2 }, Rarity = "Common", Cost = 100 },
	["Heart Memento"] = { Slot = "Accessory", Bonus = { Health = 8, Defense = 10 }, Rarity = "Common", Cost = 100 },
	["Leather Jacket"] = { Slot = "Accessory", Bonus = { Defense = 8, Health = 5 }, Rarity = "Common", Cost = 150 },
	["Breathing Mask"] = { Slot = "Accessory", Bonus = { Health = 5, Defense = 12, Stamina = 15 }, Rarity = "Common", Cost = 150 },
	["Running Shoes"] = { Slot = "Accessory", Bonus = { Speed = 10, Stamina = 15 }, Rarity = "Common", Cost = 200 },
	["Iggy's Coffee Gum"] = { Slot = "Accessory", Bonus = { Stamina = 25, Speed = 10 }, Rarity = "Uncommon", Cost = 1500 },
	["Aja Stone Amulet"] = { Slot = "Accessory", Bonus = { Health = 2, Defense = 5 }, Rarity = "Uncommon", Cost = 1800 },
	["Iron Ring"] = { Slot = "Accessory", Bonus = { Defense = 12, Strength = 5 }, Rarity = "Uncommon", Cost = 2000 },
	["Zeppeli's Scarf"] = { Slot = "Accessory", Bonus = { Stamina = 25, Health = 5 }, Rarity = "Uncommon", Cost = 2500 },
	["Vampire Cape"] = { Slot = "Accessory", Bonus = { Strength = 40, Health = 20, Speed = 20 }, Rarity = "Rare", Cost = 35000 },
	["Red Stone of Aja"] = { Slot = "Accessory", Bonus = { Health = 10, Stamina = 20, Strength = 15 }, Rarity = "Legendary", Cost = 125000 },

	["Kakyoin's Sunglasses"] = { Slot = "Accessory", Bonus = { Stand_Precision = 15, Defense = 8 }, Rarity = "Uncommon", Cost = 2500 },
	["Polnareff's Earrings"] = { Slot = "Accessory", Bonus = { Stand_Speed = 15, Defense = 5 }, Rarity = "Uncommon", Cost = 3000 },
	["Arrow Shard"] = { Slot = "Accessory", Bonus = { Stand_Potential = 15, Stand_Power = 10 }, Rarity = "Uncommon", Cost = 3500 },
	["Rohan's Headband"] = { Slot = "Accessory", Bonus = { Stand_Precision = 20, Stand_Potential = 15 }, Rarity = "Rare", Cost = 28000 },
	["Jotaro's Hat"] = { Slot = "Accessory", Bonus = { Stand_Durability = 20, Stand_Power = 15 }, Rarity = "Rare", Cost = 30000 },
	["Kira's Tie"] = { Slot = "Accessory", Bonus = { Stand_Speed = 30, Stand_Power = 15 }, Rarity = "Rare", Cost = 32000 },
	["Josuke's Peace Badge"] = { Slot = "Accessory", Bonus = { Stand_Durability = 25, Health = 15 }, Rarity = "Rare", Cost = 32000 },
	["Giorno's Ladybug Brooch"] = { Slot = "Accessory", Bonus = { Stand_Potential = 30, Health = 20 }, Rarity = "Rare", Cost = 35000 },
	["Pucci's Disc"] = { Slot = "Accessory", Bonus = { Stand_Speed = 50, Stand_Potential = 40 }, Rarity = "Legendary", Cost = 150000 },

	-- Raid Equipment
	["Luck and Pluck"] = { Slot = "Weapon", Bonus = { Strength = 35, Willpower = 40, Health = 25 }, Rarity = "Mythical", Cost = 500000 },
	["Kars' Arm Blade"] = { Slot = "Weapon", Bonus = { Strength = 45, Speed = 45, Stand_Range = 15 }, Rarity = "Mythical", Cost = 550000 },
	["DIO's Road Sign"] = { Slot = "Weapon", Bonus = { Strength = 100, Defense = 30, Stand_Power = 20 }, Rarity = "Mythical", Cost = 750000 },
	["Stray Cat"] = { Slot = "Weapon", Bonus = { Stand_Speed = 80, Speed = 40 }, Rarity = "Mythical", Cost = 800000 },
	["Doppio's Phone"] = { Slot = "Weapon", Bonus = { Stand_Precision = 100, Stand_Potential = 50 }, Rarity = "Mythical", Cost = 900000 },
	["DIO's Bone"] = { Slot = "Weapon", Bonus = { Stand_Potential = 150, Willpower = 100 }, Rarity = "Mythical", Cost = 1250000 },
	["Valentine's Revolver"] = { Slot = "Weapon", Bonus = { Stand_Precision = 150, Stand_Power = 100, Speed = 80 }, Rarity = "Mythical", Cost = 1500000 },
	["Wonder of U's Cane"] = { Slot = "Weapon", Bonus = { Stand_Speed = 150, Stand_Power = 120, Defense = 80 }, Rarity = "Mythical", Cost = 1750000 },

	["Dio's Head Jar"] = { Slot = "Accessory", Bonus = { Defense = 60, Willpower = 40 }, Rarity = "Mythical", Cost = 500000 },
	["Kars' Horn"] = { Slot = "Accessory", Bonus = { Stand_Range = 60, Stand_Precision = 40, Speed = 20 }, Rarity = "Mythical", Cost = 550000 },
	["DIO's Headband"] = { Slot = "Accessory", Bonus = { Stand_Power = 60, Strength = 40, Willpower = 20 }, Rarity = "Mythical", Cost = 750000 },
	["Kira's Wristwatch"] = { Slot = "Accessory", Bonus = { Stand_Durability = 50, Defense = 50, Willpower = 40 }, Rarity = "Mythical", Cost = 800000 },
	["Passione Badge"] = { Slot = "Accessory", Bonus = { Stand_Power = 50, Stand_Potential = 50, Health = 40 }, Rarity = "Mythical", Cost = 900000 },
	["Priest's Rosary"] = { Slot = "Accessory", Bonus = { Stand_Durability = 100, Willpower = 50, Defense = 30 }, Rarity = "Mythical", Cost = 1250000 },
	["The First Napkin"] = { Slot = "Accessory", Bonus = { Stand_Power = 100, Stand_Durability = 100, Defense = 80 }, Rarity = "Mythical", Cost = 1500000 },
	["Rock Insect"] = { Slot = "Accessory", Bonus = { Stand_Durability = 150, Defense = 100, Strength = 80 }, Rarity = "Mythical", Cost = 1750000 },

	-- Special 
	["Steel Pipe (x400)"] = { Slot = "Weapon", Bonus = { Strength = -9999 }, Rarity = "Special", Cost = 0 },
	["Trusty Steel Pipe"] = { Slot = "Weapon", Bonus = { Strength = 99 }, Rarity = "Special", Cost = 0 },
	["Obliterator"] = { Slot = "Weapon", Bonus = { Strength = 99999, Stand_Power = 99999, Speed = 99999 }, Rarity = "Special", Cost = 0 },

	-- April Fools Equipment
	["Pink Sasumata"] = { Slot = "Weapon", Bonus = { Strength = 120, Speed = 120, Defense = 80 }, Rarity = "Unique", Cost = 2000000 },
	["Playful Cloud"] = { Slot = "Weapon", Bonus = { Strength = 180, Speed = 80, Stand_Power = 80 }, Rarity = "Unique", Cost = 2000000 },
	["Kamutoke"] = { Slot = "Weapon", Bonus = { Strength = 150, Stand_Power = 150, Stand_Range = 50 }, Rarity = "Unique", Cost = 2000000 },

	["Pochette's Armor"] = { Slot = "Accessory", Bonus = { Strength = 150, Defense = 150, Willpower = 100 }, Rarity = "Unique", Cost = 2000000 },
	["Gojo's Blindfold"] = { Slot = "Accessory", Bonus = { Stand_Power = 200, Speed = 100, Willpower = 80 }, Rarity = "Unique", Cost = 2000000 },
	["Heian Era Robes"] = { Slot = "Accessory", Bonus = { Health = 100, Defense = 100, Stand_Power = 150 }, Rarity = "Unique", Cost = 2000000 },

	-- Easter Equipment
	["Kakyoin's Paintbrush"] = { Slot = "Weapon", Bonus = { Stand_Power = 120, Stand_Precision = 100, Stand_Range = 80 }, Rarity = "Unique", Cost = 2000000 },
	["Baoh Arm Blade"] = { Slot = "Weapon", Bonus = { Strength = 200, Speed = 120, Willpower = 80 }, Rarity = "Unique", Cost = 2000000 },

	["Shoshinsha Mark"] = { Slot = "Accessory", Bonus = { Stand_Power = 120, Health = 30, Strength = 70 }, Rarity = "Unique", Cost = 2000000 },
	["Ikuro's Jacket"] = { Slot = "Accessory", Bonus = { Strength = 180, Defense = 150, Health = 50 }, Rarity = "Unique", Cost = 2000000 },
}

ItemData.Consumables = {
	-- Style Items
	["Boxing Manual"] = { Category = "Player", Description = "Learn the fundamentals. Grants the Boxing style.", Rarity = "Common", Cost = 250 },
	["Hamon Manual"] = { Category = "Player", Description = "Master your breathing. Grants the Hamon style.", Rarity = "Uncommon", Cost = 4000 },
	["Cyborg Blueprints"] = { Category = "Player", Description = "German science is the best! Grants the Cyborg style.", Rarity = "Uncommon", Cost = 5000 },
	["Vampire Mask"] = { Category = "Player", Description = "I REJECT MY HUMANITY! Grants the Vampirism style.", Rarity = "Rare", Cost = 25000 },
	["Ancient Mask"] = { Category = "Player", Description = "Awaken ancient biology. Grants the Pillarman style.", Rarity = "Legendary", Cost = 100000 },
	["Steel Ball"] = { Category = "Player", Description = "A perfect sphere. Unlocks the Spin fighting style.", Rarity = "Legendary", Cost = 400000 },
	["Perfect Aja Mask"] = { Category = "Player", Description = "A stone mask with the Red Stone embedded. Evolves Pillarman into the Ultimate Lifeform.", Rarity = "Mythical", Cost = 450000 },
	["Golden Spin Scroll"] = { Category = "Player", Description = "The secret of infinite rotation. Evolves the Spin style into Golden Spin.", Rarity = "Mythical", Cost = 450000 },
	["Rokakaka Fruit"] = { Category = "Player", Description = "A mysterious fruit from the Higashikata orchard. Consuming it transforms your biology into that of a Rock Human.", Rarity = "Mythical", Cost = 450000 },

	-- Evolution Items
	["Dio's Diary"] = { Category = "Stand", Description = "Read the path to heaven. Grants massive XP or Evolves certain Stands.", Rarity = "Legendary", Cost = 80000 },
	["Green Baby"] = { Category = "Stand", Description = "Fuse with the Green Baby. Evolves Whitesnake or gives massive stats.", Rarity = "Legendary", Cost = 120000 },
	["Strange Arrow"] = { Category = "Stand", Description = "A mysterious arrow. Evolves your Stand's potential beyond limits!", Rarity = "Legendary", Cost = 150000 },
	["Saint's Left Arm"] = { Category = "Stand", Description = "A mummified left arm. Evolves Tusk Act 1 into Act 2.", Rarity = "Legendary", Cost = 150000 },
	["Saint's Right Eye"] = { Category = "Stand", Description = "A mummified right eye. Evolves Tusk Act 2 into Act 3.", Rarity = "Legendary", Cost = 250000 },
	["Saint's Pelvis"] = { Category = "Stand", Description = "A mummified pelvis. Evolves Tusk Act 3 into Act 4.", Rarity = "Mythical", Cost = 500000 },
	["Saint's Heart"] = { Category = "Stand", Description = "A mummified heart. Evolves Dirty Deeds Done Dirt Cheap into Love Train.", Rarity = "Mythical", Cost = 500000 },
	["Saint's Spine"] = { Category = "Stand", Description = "A mummified spine. Evolves The World and Star Platinum into Over Heaven!", Rarity = "Mythical", Cost = 500000 },
	["Rokakaka Branch"] = { Category = "Stand", Description = "A miraculously grafted branch. Evolves Soft & Wet to push its bubbles beyond logic.", Rarity = "Mythical", Cost = 500000},

	-- Reroll Items
	["Stand Arrow"] = { Category = "Stand", Description = "Pierce yourself to awaken a random Stand.", Rarity = "Legendary", Cost = 35000 },
	["Rokakaka"] = { Category = "Stand", Description = "An equivalent exchange fruit. Rerolls your Stand's trait.", Rarity = "Legendary", Cost = 300000 },
	["Saint's Corpse Part"] = { Category = "Stand", Description = "A holy relic. Rolls a Stand from an alternate universe.", Rarity = "Legendary", Cost = 500000 },

	-- Misc Items
	["Heavenly Stand Disc"] = { Category = "Stand", Description = "Call upon the powers of Made in Heaven to reset the universe and its modifiers.", Rarity = "Legendary", Cost = 350000},
	["Stand Disc"] = { Category = "Stand", Description = "Wipes your soul. Removes your current Stand and Trait.", Rarity = "Uncommon", Cost = 15000 },
	["Memory Disc"] = { Category = "Player", Description = "Wipes your memory. Removes your current Fighting Style.", Rarity = "Uncommon", Cost = 5000 },
	["Requiem Arrow"] = { Category = "Stand", Description = "An arrow with a bizzare beetle design. Pushes your stand beyond anything ever seen.", Rarity = "Mythical", Cost = 500000},
	["New Rokakaka"] = { Category = "Stand", Description = "The ultimate fruit of equivalent exchange. Fuses two of your Stands into a powerful hybrid.", Rarity = "Mythical", Cost = 500000},
	["Inversion Medicine"] = { Category = "Stand", Description = "The ultimate medicine. Reverts your Fused Stand back to its original forms.", Rarity = "Mythical", Cost = 500000},
	
	-- Stat Manuals (Player)
	["Health Training Manual"] = { Category = "Player", Description = "A legendary manual detailing rigorous bodily conditioning. Grants Health.", Rarity = "Legendary", Cost = 250000 },
	["Strength Training Manual"] = { Category = "Player", Description = "A legendary manual detailing advanced combat techniques. Grants Strength.", Rarity = "Legendary", Cost = 250000 },
	["Defense Training Manual"] = { Category = "Player", Description = "A legendary manual detailing impenetrable guard stances. Grants Defense.", Rarity = "Legendary", Cost = 250000 },
	["Speed Training Manual"] = { Category = "Player", Description = "A legendary manual detailing weightless footwork. Grants Speed.", Rarity = "Legendary", Cost = 250000 },
	["Stamina Training Manual"] = { Category = "Player", Description = "A legendary manual detailing deep stamina reserves. Grants Stamina.", Rarity = "Legendary", Cost = 250000 },
	["Willpower Training Manual"] = { Category = "Player", Description = "A legendary manual detailing unbreakable resolve. Grants Willpower.", Rarity = "Legendary", Cost = 250000 },

	-- Stat Manuals (Stand)
	["Stand Power Training Manual"] = { Category = "Stand", Description = "A legendary manual on spiritual destruction. Grants Stand Power.", Rarity = "Legendary", Cost = 250000 },
	["Stand Speed Training Manual"] = { Category = "Stand", Description = "A legendary manual on spiritual velocity. Grants Stand Speed.", Rarity = "Legendary", Cost = 250000 },
	["Stand Range Training Manual"] = { Category = "Stand", Description = "A legendary manual on spiritual projection. Grants Stand Range.", Rarity = "Legendary", Cost = 250000 },
	["Stand Durability Training Manual"] = { Category = "Stand", Description = "A legendary manual on spiritual resilience. Grants Stand Durability.", Rarity = "Legendary", Cost = 250000 },
	["Stand Precision Training Manual"] = { Category = "Stand", Description = "A legendary manual on spiritual accuracy. Grants Stand Precision.", Rarity = "Legendary", Cost = 250000 },
	["Stand Potential Training Manual"] = { Category = "Stand", Description = "A legendary manual on spiritual growth. Grants Stand Potential.", Rarity = "Legendary", Cost = 250000 },

	-- Advanced Training Manuals
	["Advanced Style Training Manual"] = { Category = "Player", Description = "A mythical manual containing the pinnacle of physical arts. Grants all Player Stats.", Rarity = "Mythical", Cost = 1000000 },
	["Advanced Stand Training Manual"] = { Category = "Stand", Description = "A mythical manual detailing the apex of spiritual manifestation. Grants +all Stand Stats.", Rarity = "Mythical", Cost = 1000000 },
	["Master Training Manual"] = { Category = "Player", Description = "A mythical manual that unifies the body and spirit perfectly. Grants all Player and Stand Stats.", Rarity = "Mythical", Cost = 1500000 },
	
	-- Stand Discs
	["Weather Report Disc"] = { Category = "Stand", Description = "This disc hums with a menacing power. Awakens the stand, Weather Report.", Rarity = "Unique", Cost = 300000},
	["Heaven's Door Disc"] = { Category = "Stand", Description = "This disc hums with a menacing power. Awakens the stand, Heaven's Door.", Rarity = "Unique", Cost = 300000},
	["The Hand Disc"] = { Category = "Stand", Description = "This disc hums with a menacing power. Awakens the stand, The Hand.", Rarity = "Unique", Cost = 300000},
	["Metallica Disc"] = { Category = "Stand", Description = "This disc hums with a menacing power. Awakens the stand, Metallica.", Rarity = "Unique", Cost = 300000},
	["The World Disc"] = { Category = "Stand", Description = "This disc hums with a menacing power. Awakens the stand, The World.", Rarity = "Unique", Cost = 300000},
	["Star Platinum Disc"] = { Category = "Stand", Description = "This disc hums with a menacing power. Awakens the stand, Star Platinum.", Rarity = "Unique", Cost = 300000},
	["Wonder of U Disc"] = { Category = "Stand", Description = "This disc hums with a menacing power. Awakens the stand, Wonder of U.", Rarity = "Unique", Cost = 300000},

	-- Passes
	["2x Battle Speed Pass"] = { Category = "Player", Description = "Consumable gamepass. Unlocks 2x Battle Speed.", Rarity = "Special", Cost = 0 },
	["2x Inventory Pass"] = { Category = "Player", Description = "Consumable gamepass. Doubles your inventory capacity.", Rarity = "Special", Cost = 0 },
	["2x Drop Chance Pass"] = { Category = "Player", Description = "Consumable gamepass. Doubles all item drop rates.", Rarity = "Special", Cost = 0 },
	["VIP"] = { Category = "Player", Description = "Consumable gamepass. Permanently unlocks 2x Training Speed, a VIP Stand Slot, and VIP Style Slot!", Rarity = "Special", Cost = 0 },
	["Auto Training Pass"] = { Category = "Player", Description = "Consumable gamepass. Unlocks Auto Training.", Rarity = "Special", Cost = 0 },
	["Stand Storage Slot 2"] = { Category = "Player", Description = "Consumable gamepass. Unlocks Stand Storage Slot 2.", Rarity = "Special", Cost = 0 },
	["Stand Storage Slot 3"] = { Category = "Player", Description = "Consumable gamepass. Unlocks Stand Storage Slot 3.", Rarity = "Special", Cost = 0 },
	["Style Storage Slot 2"] = { Category = "Player", Description = "Consumable gamepass. Unlocks Style Storage Slot 2.", Rarity = "Special", Cost = 0 },
	["Style Storage Slot 3"] = { Category = "Player", Description = "Consumable gamepass. Unlocks Style Storage Slot 3.", Rarity = "Special", Cost = 0 },
	["Auto-Roll Pass"] = { Category = "Player", Description = "Consumable gamepass. Unlocks the Auto-Roll feature.", Rarity = "Special", Cost = 0 },
	["Auto-Stat Invest"] = { Category = "Player", Description = "Consumable gamepass. Unlocks the Auto-Stat Invest feature.", Rarity = "Special", Cost = 0 },
	["Custom Horse Name"] = { Category = "Player", Description = "Consumable gamepass. Unlocks the Custom Horse Name feature.", Rarity = "Special", Cost = 0 },
	
	-- Rewards
	["Legendary Giftbox"] = { Category = "Player", Description = "Supplies you with a random Legendary-tier item!", Rarity = "Special", Cost = 30000 },
	["Mythical Giftbox"] = { Category = "Player", Description = "Supplies you with a random Mythical-tier item!", Rarity = "Special", Cost = 50000 },
	["Unique Giftbox"] = { Category = "Player", Description = "Supplies you with a random Unique-tier item!", Rarity = "Special", Cost = 100000 },

	-- April Fools
	["Chiikawa Mascot"] = { Category = "Stand", Description = "A strange little creature. Awakens the stand, Chiikawa.", Rarity = "Unique", Cost = 500000 },
	["Limitless Manual"] = { Category = "Player", Description = "Learn the concept of infinity. Grants the Limitless style.", Rarity = "Unique", Cost = 500000 },
	["Cursed Finger"] = { Category = "Player", Description = "A mummified finger radiating evil. Grants the Shrine style.", Rarity = "Unique", Cost = 500000 },
	["Scratch-Off Ticket"] = { Category = "Stand", Description = "99% of gamblers quit right before they hit the jackpot. (Replaces your Stand's Trait)", Rarity = "Unique", Cost = 777777 },

	-- Easter
	["Easter Egg"] = { Category = "Player", Description = "A decorative egg dropped from battles. Currency for the Easter Shop.", Rarity = "Special", Cost = 0 },
	["Lucky Egg"] = { Category = "Player", Description = "A shiny egg, opening it provides a random amount of Easter Eggs, or even a Limited item!", Rarity = "Unique", Cost = 0 },
	["Kakyoin's Egg"] = { Category = "Stand", Description = "A mysterious egg, presumably laid by Kakyoin. Awakens the stand, Charmy Green.", Rarity = "Unique", Cost = 500000 },
	["Parasitic Egg"] = { Category = "Player", Description = "A mysterious egg containing a bio-engineered parasite. Grants the Baoh fighting style.", Rarity = "Unique", Cost = 500000 },	
}

return ItemData