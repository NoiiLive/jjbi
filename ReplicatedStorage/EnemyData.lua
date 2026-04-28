-- @ScriptType: ModuleScript
local EnemyData = {}

local emptyStands = {Power="None", Speed="None", Range="None",
	Durability="None", Precision="None", Potential="None"}

EnemyData.Allies = {
	["Will A. Zeppeli"] = { Name = "Will A. Zeppeli", Icon = "", Health = 80, Strength = 12, Defense = 5, Speed = 8, Willpower = 10, StandStats = emptyStands, Stand = "None", Style = "Hamon" },
	["Caesar Zeppeli"] = { Name = "Caesar Zeppeli", Icon = "", Health = 150, Strength = 20, Defense = 10, Speed = 15, Willpower = 15, StandStats = emptyStands, Stand = "None", Style = "Hamon" },
	["Polnareff"] = { Name = "Jean Pierre Polnareff", Icon = "", Health = 250, Strength = 35, Defense = 15, Speed = 35, Willpower = 20, StandStats = {Power="C", Speed="A", Range="C", Durability="B", Precision="B", Potential="C"}, Stand = "Silver Chariot", Style = "None" },
	["Okuyasu"] = { Name = "Okuyasu Nijimura", Icon = "rbxassetid://95630365107580", Health = 400, Strength = 50, Defense = 30, Speed = 25, Willpower = 25, StandStats = {Power="B", Speed="B", Range="D", Durability="C", Precision="C", Potential="C"}, Stand = "The Hand", Style = "None" },
	["Gyro"] = { Name = "Gyro Zeppeli", Icon = "", Health = 1000, Strength = 150, Defense = 80, Speed = 65, Willpower = 125, Stand = "None", Style = "Spin" },
	["Yasuho"] = { Name = "Yasuho Hirose", Icon = "", Health = 8000, Strength = 200, Defense = 150, Speed = 200, Willpower = 150, StandStats = {Power="E", Speed="E", Range="A", Durability="A", Precision="D", Potential="C"}, Stand = "Paisley Park", Style = "None" }
}

EnemyData.RaidBosses = {
	["Raid_Part1"] = { 
		IsBoss = true, Name = "Vampire King", Req = 1, Icon = "rbxassetid://86531285156337",
		Health = 5000, Strength = 60, Defense = 50, Speed = 45, Willpower = 60, StandStats = emptyStands, 
		Stand = "None", Style = "Vampirism", 
		Drops = { Yen = 1000, XP = 2500, ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 5, ["Luck and Pluck"] = 1, ["Dio's Head Jar"] = 1, ["Vampire Mask"] = 25, ["Dio's Throwing Knives"] = 25, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } } 
	},
	["Raid_Part2"] = { 
		IsBoss = true, Name = "Ultimate Lifeform", Req = 1, Icon = "rbxassetid://132306871638759",
		Health = 10000, Strength = 80, Defense = 65, Speed = 60, Willpower = 70, StandStats = emptyStands, 
		Stand = "None", Style = "Ultimate Lifeform", 
		Drops = { Yen = 2500, XP = 5000, ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 6, ["Perfect Aja Mask"] = 1, ["Kars' Arm Blade"] = 1, ["Kars' Horn"] = 1, ["Red Stone of Aja"] = 15, ["Ancient Mask"] = 15, ["Aja Stone Amulet"] = 25, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } } 
	},
	["Raid_Part3"] = { 
		IsBoss = true, Name = "Time Stop Vampire", Req = 1, Icon = "rbxassetid://84790385900886", 
		Health = 15000, Strength = 100, Defense = 80, Speed = 80, Willpower = 95, StandStats = {Power="A", Speed="A", Range="C", Durability="A", Precision="B", Potential="B"}, 
		Stand = "The World", Style = "Vampirism", 
		Drops = { Yen = 5000, XP = 10000, ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 7, ["DIO's Road Sign"] = 1, ["DIO's Headband"] = 1, ["Dio's Diary"] = 5, ["Jotaro's Hat"] = 25, ["Anubis Sword"] = 25, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } } 
	},
	["Raid_Part4"] = { 
		IsBoss = true, Name = "Serial Killer", Req = 1, Icon = "rbxassetid://78559266675698", 
		Health = 20000, Strength = 150, Defense = 125, Speed = 125, Willpower = 110, StandStats = {Power="A", Speed="B", Range="D", Durability="B", Precision="B", Potential="A"}, 
		Stand = "Killer Queen", Style = "None", 
		Drops = { Yen = 8000, XP = 15000, ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 8, ["Stray Cat"] = 1, ["Kira's Wristwatch"] = 1, ["Strange Arrow"] = 10, ["Kira's Tie"] = 25, ["Josuke's Peace Badge"] = 25, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } } 
	},
	["Raid_Part5"] = { 
		IsBoss = true, Name = "Mafia Boss", Req = 1, Icon = "rbxassetid://86941295205734",
		Health = 25000, Strength = 200, Defense = 140, Speed = 150, Willpower = 155, StandStats = {Power="A", Speed="A", Range="E", Durability="E", Precision="B", Potential="A"}, 
		Stand = "King Crimson", Style = "None", 
		Drops = { Yen = 12000, XP = 22000, ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 9, ["Doppio's Phone"] = 1, ["Passione Badge"] = 1, ["Strange Arrow"] = 15, ["Giorno's Ladybug Brooch"] = 25, ["Mista's Pistol"] = 25, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } } 
	},
	["Raid_Part6"] = { 
		IsBoss = true, Name = "Gravity Priest", Req = 1, Icon = "rbxassetid://80960379225409",
		Health = 30000, Strength = 250, Defense = 180, Speed = 210, Willpower = 210, StandStats = {Power="B", Speed="A", Range="C", Durability="A", Precision="C", Potential="A"}, 
		Stand = "Made in Heaven", Style = "None", 
		Drops = { Yen = 20000, XP = 35000, ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 10, ["Heavenly Stand Disc"] = 5, ["DIO's Bone"] = 1, ["Priest's Rosary"] = 1, ["Green Baby"] = 10, ["Pucci's Disc"] = 25, ["Jolyne's String"] = 25, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } } 
	},
	["Raid_Part7"] = { 
		IsBoss = true, Name = "23rd President", Req = 1, Icon = "",
		Health = 35000, Strength = 300, Defense = 220, Speed = 260, Willpower = 260, StandStats = {Power="A", Speed="A", Range="C", Durability="A", Precision="A", Potential="A"}, 
		Stand = "D4C Love Train", Style = "None", 
		Drops = { Yen = 30000, XP = 50000, ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 15, ["Steel Ball"] = 20, ["Saint's Corpse Part"] = 20, ["Saint's Left Arm"] = 10, ["Saint's Right Eye"] = 10, ["Saint's Heart"] = 1, ["Saint's Spine"] = 1, ["Saint's Pelvis"] = 1, ["Golden Spin Scroll"] = 1, ["Valentine's Revolver"] = 1, ["The First Napkin"] = 1, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } } 
	},
	["Raid_Part8"] = { 
		IsBoss = true, Name = "The Head Doctor", Req = 1, Icon = "rbxassetid://107039057776207",
		Health = 40000, Strength = 350, Defense = 260, Speed = 350, Willpower = 300, StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"}, 
		Stand = "Wonder of U", Style = "None", 
		Drops = { Yen = 40000, XP = 75000, ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 20, ["Saint's Corpse Part"] = 25, ["Wonder of U's Cane"] = 1, ["Rock Insect"] = 1, ["Rokakaka Branch"] = 1, ["Rokakaka Fruit"] = 1, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } } 
	}
}

EnemyData.WorldBosses = {
	["Weather Report"] = {
		Name = "Weather Report", IsBoss = true, Icon = "rbxassetid://125669897777686",
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="E", Potential="A"},
		Stand = "Weather Report", Style = "None",
		Drops = { 
			XP = 25000, Yen = 10000, 
			ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 5, ["Weather Report Disc"] = 1, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } 
		}
	},
	["Rohan Kishibe"] = {
		Name = "Rohan Kishibe", IsBoss = true, Icon = "rbxassetid://104201942548364", 
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="D", Speed="B", Range="B", Durability="D", Precision="C", Potential="A"},
		Stand = "Heaven's Door", Style = "None",
		Drops = { 
			XP = 25000, Yen = 10000, 
			ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 5, ["Heaven's Door Disc"] = 1, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } 
		}
	},
	["Okuyasu Nijimura"] = {
		Name = "Okuyasu Nijimura", IsBoss = true, Icon = "rbxassetid://95630365107580", 
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="B", Speed="B", Range="D", Durability="C", Precision="C", Potential="C"},
		Stand = "The Hand", Style = "None",
		Drops = { 
			XP = 25000, Yen = 10000, 
			ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 5, ["The Hand Disc"] = 1, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } 
		}
	},
	["Risotto Nero"] = {
		Name = "Risotto Nero", IsBoss = true, Icon = "rbxassetid://105116104427033",
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="C", Speed="C", Range="C", Durability="A", Precision="C", Potential="C"},
		Stand = "Metallica", Style = "None",
		Drops = { 
			XP = 25000, Yen = 10000, 
			ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 5, ["Metallica Disc"] = 1, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } 
		}
	},
	["Giorno Giovanna"] = {
		Name = "Giorno Giovanna", IsBoss = true, Icon = "rbxassetid://115852687905113", 
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"},
		Stand = "Gold Experience Requiem", Style = "None",
		Drops = { 
			XP = 25000, Yen = 10000, 
			ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 5, ["Requiem Arrow"] = 1, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } 
		}
	},
	["DIO"] = {
		Name = "DIO", IsBoss = true, Icon = "rbxassetid://84790385900886", 
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"},
		Stand = "The World", Style = "Vampirism",
		Drops = { 
			XP = 25000, Yen = 10000, 
			ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 5, ["The World Disc"] = 1, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } 
		}
	},
	["Jotaro Kujo"] = {
		Name = "Jotaro Kujo", IsBoss = true, Icon = "rbxassetid://79124723802203", 
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"},
		Stand = "Star Platinum", Style = "None",
		Drops = { 
			XP = 25000, Yen = 10000, 
			ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 5, ["Star Platinum Disc"] = 1, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } 
		}
	},
	["Wonder of U"] = {
		Name = "Wonder of U", IsBoss = true, Icon = "rbxassetid://71731455259515", 
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"},
		Stand = "Wonder of U", Style = "None",
		Drops = { 
			XP = 35000, Yen = 15000, 
			ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 5, ["Wonder of U Disc"] = 1, ["New Rokakaka"] = 1, ["Inversion Medicine"] = 1, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 } 
		}
	},
	["Easter Bunny"] = {
		Name = "Easter Bunny", IsBoss = true, Icon = "rbxassetid://85162561703221", 
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"},
		Stand = "None", Style = "None",
		Drops = {
			XP = 35000, Yen = 15000, 
			ItemChance = { ["Easter Egg"] = 100, ["Lucky Egg"] = 1, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 }
		}
	},
	["Chiikawa"] = {
		Name = "Chiikawa", IsBoss = true, Icon = "rbxassetid://110637525741731", 
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"},
		Stand = "Chiikawa", Style = "None",
		Drops = {
			XP = 35000, Yen = 15000, 
			ItemChance = { ["Chiikawa Mascot"] = 1, ["Pink Sasumata"] = 1, ["Pochette's Armor"] = 1, ["Scratch-Off Ticket"] = 1, ["Mythical Giftbox"] = 20, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 }
		}
	},
	["Satoru Gojo"] = {
		Name = "Satoru Gojo", IsBoss = true, Icon = "",
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"},
		Stand = "None", Style = "Limitless",
		Drops = {
			XP = 35000, Yen = 15000, 
			ItemChance = { ["Limitless Manual"] = 1, ["Playful Cloud"] = 1, ["Gojo's Blindfold"] = 1, ["Scratch-Off Ticket"] = 1, ["Mythical Giftbox"] = 20, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 }
		}
	},
	["Ryomen Sukuna"] = {
		Name = "Ryomen Sukuna", IsBoss = true, Icon = "", 
		Health = 1000000, Strength = 500, Defense = 100, Speed = 400, Willpower = 500, StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"},
		Stand = "None", Style = "Shrine",
		Drops = {
			XP = 35000, Yen = 15000, 
			ItemChance = { ["Cursed Finger"] = 1, ["Kamutoke"] = 1, ["Heian Era Robes"] = 1, ["Scratch-Off Ticket"] = 1, ["Mythical Giftbox"] = 20, ["Advanced Style Training Manual"] = 5, ["Advanced Stand Training Manual"] = 5, ["Master Training Manual"] = 1 }
		}
	},
}

EnemyData.Parts = {
	[1] = {
		Boss = { IsBoss = true, Name = "Dio Brando (Vampire)", Icon = "rbxassetid://86531285156337", Health = 150, Strength = 15, Defense = 8, Speed = 10, Willpower = 12, StandStats = emptyStands, Stand = "None", Style = "Vampirism", Drops = { Yen = 80, XP = 150, ItemChance={["Vampire Mask"]=10, ["Dio's Throwing Knives"]=15, ["Strength Training Manual"]=5} } },
		RandomFlavor = {"You wander the streets of London, and encounter a %s!", "A %s steps out from the shadows!", "You are ambushed by a %s!"},
		Mobs = {
			{ Name = "Zombie Thug", Icon = "", 
				Health = 20, Strength = 3, Defense = 1, Speed = 2, Willpower = 2, StandStats = emptyStands, 
				Stand = "None", Style = "None", 
				Drops = { Yen = 5, XP = 10, ItemChance = { ["Brass Knuckles"] = 2, ["Wooden Bat"] = 5, ["Strength Training Manual"] = 1 } } },
			{ Name = "Vampire Minion", Icon = "",
				Health = 30, Strength = 4, Defense = 2, Speed = 3, Willpower = 3, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 8, XP = 20, ItemChance = { ["Boxing Manual"] = 2, ["Zeppeli's Scarf"] = 2, ["Speed Training Manual"] = 1 } } },
			{ Name = "Street Thug", Icon = "",
				Health = 15, Strength = 2, Defense = 1, Speed = 1, Willpower = 1, StandStats = emptyStands, 
				Stand = "None", Style = "None", 
				Drops = { Yen = 6, XP = 12, ItemChance = { ["Steel Pipe"] = 5, ["Leather Jacket"] = 5, ["Stamina Training Manual"] = 1 } } }
		},
		Templates = {
			["Boxer"] = { Name = "Local Boxer", Icon = "",
				Health = 20, Strength = 3, Defense = 1, Speed = 2, Willpower = 2, StandStats = emptyStands, 
				Stand = "None", Style = "Boxing", 
				Drops = { Yen = 5, XP = 10, ItemChance = { ["Stamina Training Manual"] = 1 } } },
			["Young Dio"] = { Name = "Young Dio", Icon = "",
				Health = 50, Strength = 5, Defense = 3, Speed = 5, Willpower = 5, StandStats = emptyStands, 
				Stand = "None", Style = "Boxing", 
				Drops = { Yen = 20, XP = 40, ItemChance={["Boxing Manual"]=10, ["Willpower Training Manual"] = 1} } },
			["Dio's Grunt"] = { Name = "Dio's Grunt", Icon = "",
				Health = 15, Strength = 2, Defense = 1, Speed = 1, Willpower = 1, StandStats = emptyStands, 
				Stand = "None", Style = "None", 
				Drops = { Yen = 4, XP = 8, ItemChance={["Combat Knife"] = 5, ["Strength Training Manual"] = 1} } },
			["Street Thug"] = { Name = "Street Thug", Icon = "",
				Health = 25, Strength = 3, Defense = 1, Speed = 2, Willpower = 2, StandStats = emptyStands, 
				Stand = "None", Style = "None", 
				Drops = { Yen = 6, XP = 12, ItemChance={["Steel Pipe"] = 5, ["Stamina Training Manual"] = 1} } },
			["Speedwagon"] = { Name = "R.E.O. Speedwagon", Icon = "",
				Health = 40, Strength = 4, Defense = 2, Speed = 4, Willpower = 5, StandStats = emptyStands, 
				Stand = "None", Style = "None", 
				Drops = { Yen = 15, XP = 30, ItemChance={["Boxing Manual"]=10, ["Speed Training Manual"] = 1} } },
			["Zombie Thrall"] = { Name = "Zombie Thrall", Icon = "",
				Health = 25, Strength = 4, Defense = 1, Speed = 2, Willpower = 1, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 5, XP = 15, ItemChance={ ["Health Training Manual"] = 1 } } },
			["Fresh Vampire Dio"] = { Name = "Dio Brando", Icon = "rbxassetid://102982650003498",
				Health = 80, Strength = 8, Defense = 4, Speed = 6, Willpower = 8, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 30, XP = 60, ItemChance={["Vampire Mask"]=5, ["Strength Training Manual"] = 1} } },
			["Zombie Jack"] = { Name = "Jack the Ripper", Icon = "",
				Health = 60, Strength = 7, Defense = 2, Speed = 8, Willpower = 4, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 25, XP = 50, ItemChance={ ["Speed Training Manual"] = 1 } } },
			["Bruford"] = { Name = "Bruford", Icon = "",
				Health = 90, Strength = 9, Defense = 5, Speed = 7, Willpower = 6, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 35, XP = 70, ItemChance={["Luck Sword"]=20, ["Willpower Training Manual"] = 1} } },
			["Tarkus"] = { Name = "Tarkus", Icon = "",
				Health = 100, Strength = 10, Defense = 6, Speed = 3, Willpower = 8, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 40, XP = 80, ItemChance={["Zeppeli's Scarf"] = 10, ["Strength Training Manual"] = 1} } },
			["Wang Chan"] = { Name = "Wang Chan", Icon = "",
				Health = 80, Strength = 8, Defense = 4, Speed = 8, Willpower = 5, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 30, XP = 60, ItemChance={ ["Speed Training Manual"] = 1 } } },
			["Head Dio"] = { IsBoss = true, Name = "Dio Brando (Head)", Icon = "rbxassetid://82000644585448",
				Health = 120, Strength = 12, Defense = 5, Speed = 10, Willpower = 10, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 60, XP = 100, ItemChance={["Vampire Mask"]=10, ["Willpower Training Manual"] = 5} } },
			["Vampire Dio"] = { IsBoss = true, Name = "Dio Brando (Vampire)", Icon = "rbxassetid://86531285156337",
				Health = 150, Strength = 15, Defense = 8, Speed = 10, Willpower = 12, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 80, XP = 150, ItemChance={["Vampire Mask"]=10, ["Dio's Throwing Knives"]=20, ["Strength Training Manual"] = 5} } }
		},
		Missions = {
			[1] = { Name = "Fateful Encounter", Waves = { { Template = "Young Dio", Flavor = "A young man arrives at your estate..." } } },
			[2] = { Name = "Boxing Ring", Waves = { { Template = "Boxer", Flavor = "You step into the ring against a local boxer!" }, { Template = "Boxer", Flavor = "Another challenger approaches!" }, { Template = "Young Dio", Flavor = "Dio steps into the ring. 'I'll beat you to a pulp!'" } } },
			[3] = { Name = "Revenge Plot", Waves = { { Template = "Dio's Grunt", Flavor = "You find some of Dio's grunts causing trouble." }, { Template = "Young Dio", Flavor = "You corner Young Dio to get revenge for him kissing your girl!" } } },
			[4] = { Name = "London Streets", Waves = { { Template = "Street Thug", Flavor = "You wander Ogre Street searching for a poison dealer." }, { Template = "Speedwagon", Flavor = "A man with a blade-bowler hat leaps at you. It's Speedwagon!" } } },
			[5] = { Name = "Joestar Mansion", Waves = { { Template = "Zombie Thrall", Flavor = "Dio used the mask! A zombie thrall attacks!" }, { Template = "Fresh Vampire Dio", Flavor = "Dio walks through the flames, reborn as a vampire!" } } },
			[6] = { Name = "Enclosed Tunnel", Waves = { { Template = "Zombie Thrall", Flavor = "You ride through a dark tunnel..." }, { Template = "Zombie Jack", Flavor = "A horrific zombie bursts from a horse! It's Jack the Ripper!" } } },
			[7] = { Name = "Windknight's Lot", Waves = { { Template = "Zombie Thrall", Flavor = "The village is overrun by zombies." }, { Template = "Bruford", Flavor = "A legendary dark knight emerges. Bruford!" } } },
			[8] = { Name = "Chained Lion", Waves = { { Template = "Tarkus", Flavor = "You are locked in a chained deathmatch against Tarkus!", Ally = "Will A. Zeppeli" } } },
			[9] = { Name = "Vampire Castle", Waves = { { Template = "Zombie Thrall", Flavor = "You breach Dio's castle. Guards attack." }, { Template = "Zombie Thrall", Flavor = "The horde is endless..." }, { Template = "Vampire Dio", Flavor = "You reach the top tower. Dio waits for you. 'WRYYYY!'" } } },
			[10] = { Name = "Burning Ship", Waves = { { Template = "Wang Chan", Flavor = "You take a ride to America, but Wang Chan is here!" }, { Template = "Head Dio", Flavor = "Dio's severed head shoots lasers from the shadows! The ship is going down!" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Estate Rivalry", Waves = { { Template = "Young Dio", Flavor = "You already know his tricks. You intercept Dio immediately." }, { Template = "Young Dio", Flavor = "He tries to use the knife, but you are prepared." } } },
			[2] = { Name = "Ogre Street Skirmish", Waves = { { Template = "Street Thug", Flavor = "You skip the search and head straight for the poison dealer." }, { Template = "Speedwagon", Flavor = "You block Speedwagon's hat perfectly. He joins your side." } } },
			[3] = { Name = "Mansion Incident", Waves = { { Template = "Fresh Vampire Dio", Flavor = "You didn't let him monologue. The fight begins in the burning hall." }, { Template = "Zombie Jack", Flavor = "Jack the Ripper tries to ambush you, but you expected it." } } },
			[4] = { Name = "The Dark Knights", Waves = { { Template = "Bruford", Flavor = "You meet Bruford at the lake. His sword dance is familiar." }, { Template = "Tarkus", Flavor = "You dodge the chain room trap and fight Tarkus head-on!", Ally = "Will A. Zeppeli" } } },
			[5] = { Name = "Fate Averted", Waves = { { Template = "Wang Chan", Flavor = "You intercept Wang Chan before the boat leaves." }, { Template = "Vampire Dio", Flavor = "Dio is waiting. This time, you won't let him take your body!" }, { Template = "Head Dio", Flavor = "You crush the head before he can fire!" } } }
		}
	},

	[2] = {
		Boss = { IsBoss = true, Name = "Kars (ULF)", Icon = "", Health = 350, Strength = 32, Defense = 22, Speed = 28, Willpower = 30, StandStats = emptyStands, Stand = "None", Style = "Ultimate Lifeform", Drops = { Yen = 150, XP = 300, ItemChance = { ["Red Stone of Aja"] = 20, ["Breathing Mask"] = 50, ["Hamon Clackers"] = 50, ["Ancient Mask"] = 20, ["Speed Training Manual"] = 5 } } },
		RandomFlavor = {"You encounter a %s in the wasteland!", "A %s jumps out from the ruins!"},
		Mobs = {
			{ Name = "Vampire Soldier", Icon = "",
				Health = 80, Strength = 10, Defense = 5, Speed = 8, Willpower = 8, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 15, XP = 40, ItemChance = { ["Aja Stone Amulet"] = 5, ["Hamon Clackers"] = 5, ["Strength Training Manual"] = 1 } } },
			{ Name = "Pillar Man Thrall", Icon = "",
				Health = 120, Strength = 14, Defense = 8, Speed = 10, Willpower = 12, StandStats = emptyStands, 
				Stand = "None", Style = "Pillarman", 
				Drops = { Yen = 25, XP = 60, ItemChance = { ["Breathing Mask"] = 2, ["Iron Ring"] = 5, ["Defense Training Manual"] = 1 } } }
		},
		Templates = {
			["Vampire Soldier"] = { Name = "Vampire Soldier", Icon = "",
				Health = 80, Strength = 10, Defense = 5, Speed = 8, Willpower = 8, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 15, XP = 40, ItemChance = { ["Strength Training Manual"] = 1 } } },
			["Pillar Man Thrall"] = { Name = "Pillar Man Thrall", Icon = "", 
				Health = 120, Strength = 14, Defense = 8, Speed = 10, Willpower = 12, StandStats = emptyStands, 
				Stand = "None", Style = "Pillarman", 
				Drops = { Yen = 25, XP = 60, ItemChance = { ["Defense Training Manual"] = 1 } } },
			["Straizo"] = { Name = "Straizo", Icon = "",
				Health = 150, Strength = 15, Defense = 10, Speed = 12, Willpower = 15, StandStats = emptyStands, 
				Stand = "None", Style = "Vampirism", 
				Drops = { Yen = 40, XP = 80, ItemChance = { ["Speed Training Manual"] = 1 } } },
			["Santana"] = { Name = "Santana", Icon = "",
				Health = 200, Strength = 20, Defense = 15, Speed = 12, Willpower = 18, StandStats = emptyStands, 
				Stand = "None", Style = "Pillarman", 
				Drops = { Yen = 50, XP = 120, ItemChance = { ["Ancient Mask"] = 5, ["Cyborg Blueprints"] = 5, ["Defense Training Manual"] = 1 } } },
			["Wamuu Base"] = { Name = "Wamuu (Awakened)", Icon = "",
				Health = 240, Strength = 24, Defense = 18, Speed = 16, Willpower = 22, StandStats = emptyStands, 
				Stand = "None", Style = "Pillarman", 
				Drops = { Yen = 60, XP = 150, ItemChance = { ["Strength Training Manual"] = 1 } } },
			["Loggins"] = { Name = "Loggins", Icon = "",
				Health = 180, Strength = 18, Defense = 12, Speed = 15, Willpower = 15, StandStats = emptyStands, 
				Stand = "None", Style = "Hamon", 
				Drops = { Yen = 45, XP = 100, ItemChance = { ["Hamon Manual"] = 5, ["Stamina Training Manual"] = 1 } } },
			["Esidisi"] = { Name = "Esidisi", Icon = "",
				Health = 260, Strength = 26, Defense = 15, Speed = 20, Willpower = 24, StandStats = emptyStands, 
				Stand = "None", Style = "Pillarman", 
				Drops = { Yen = 75, XP = 180, ItemChance = { ["Health Training Manual"] = 1 } } },
			["Kars Base"] = { Name = "Kars", Icon = "rbxassetid://119492217139174",
				Health = 280, Strength = 28, Defense = 18, Speed = 25, Willpower = 26, StandStats = emptyStands, 
				Stand = "None", Style = "Pillarman", 
				Drops = { Yen = 90, XP = 200, ItemChance = { ["Speed Training Manual"] = 1 } } },
			["Wamuu Chariot"] = { Name = "Wamuu (Chariot)", Icon = "",
				Health = 300, Strength = 30, Defense = 20, Speed = 22, Willpower = 28, StandStats = emptyStands, 
				Stand = "None", Style = "Pillarman", 
				Drops = { Yen = 110, XP = 250, ItemChance = { ["Speed Training Manual"] = 1 } } },
			["Ultimate Kars"] = { IsBoss = true, Name = "Kars (ULF)", Icon = "rbxassetid://132306871638759",
				Health = 350, Strength = 32, Defense = 22, Speed = 28, Willpower = 30, StandStats = emptyStands, 
				Stand = "None", Style = "Ultimate Lifeformn", 
				Drops = { Yen = 150, XP = 300, ItemChance = { ["Red Stone of Aja"] = 20, ["Breathing Mask"] = 50, ["Hamon Clackers"] = 50, ["Ancient Mask"] = 20, ["Speed Training Manual"] = 5 } } }
		},
		Missions = {
			[1] = { Name = "New York Cafe", Waves = { { Template = "Straizo", Flavor = "Straizo betrays you! He fires his stingy eyes across the cafe." } } },
			[2] = { Name = "Mexican Base", Waves = { { Template = "Pillar Man Thrall", Flavor = "The soldiers have awakened a monster." }, { Template = "Santana", Flavor = "Santana absorbs a soldier and targets you!" } } },
			[3] = { Name = "Rome Underground", Waves = { { Template = "Vampire Soldier", Flavor = "Vampires block the ancient entrance." }, { Template = "Wamuu Base", Flavor = "The masters awaken. Wamuu steps forward to test your strength.", Ally = "Caesar Zeppeli" } } },
			[4] = { Name = "Hell Climb Pillar", Waves = { { Template = "Pillar Man Thrall", Flavor = "A rogue thrall attacks during your climb!" }, { Template = "Loggins", Flavor = "Your master Loggins tests your Hamon control!" } } },
			[5] = { Name = "Air Tights Training", Waves = { { Template = "Esidisi", Flavor = "Esidisi infiltrates the island! He cries uncontrollably, then attacks with boiling blood!" } } },
			[6] = { Name = "Swiss Alps Retreat", Waves = { { Template = "Vampire Soldier", Flavor = "Kars' scouts have found your hideout." }, { Template = "Vampire Soldier", Flavor = "More vampires pour into the cabin." } } },
			[7] = { Name = "Cliffside Skirmish", Waves = { { Template = "Kars Base", Flavor = "Kars confronts you on the icy cliff edge! His light blades shine." } } },
			[8] = { Name = "Skeleton Heel Stone", Waves = { { Template = "Wamuu Chariot", Flavor = "Wamuu honors you with a chariot battle! The arena cheers." } } },
			[9] = { Name = "Volcano Base", Waves = { { Template = "Vampire Soldier", Flavor = "Kars' army stands in your way." }, { Template = "Pillar Man Thrall", Flavor = "A massive thrall blocks the Red Stone!" } } },
			[10] = { Name = "The Ultimate Being", Waves = { { Template = "Ultimate Kars", Flavor = "Kars dons the mask with the Red Stone! He is the Ultimate Being!" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Old Friends", Waves = { { Template = "Straizo", Flavor = "You knew he'd betray you. You deflect his lasers with a shot glass." }, { Template = "Santana", Flavor = "You bypass the guards and face Santana directly." } } },
			[2] = { Name = "Rome's Awakening", Waves = { { Template = "Wamuu Base", Flavor = "You warn Caesar about the rings. You both fight Wamuu!", Ally = "Caesar Zeppeli" }, { Template = "Esidisi", Flavor = "Esidisi tries to interrupt, but you strike his boiling veins." } } },
			[3] = { Name = "Skipping Training", Waves = { { Template = "Loggins", Flavor = "You master the Hell Climb Pillar in record time. Loggins attacks." }, { Template = "Kars Base", Flavor = "You corner Kars at the cliff before he can prepare." } } },
			[4] = { Name = "The Chariot Race", Waves = { { Template = "Wamuu Chariot", Flavor = "You know his atmospheric rift trick. The race is a breeze." }, { Template = "Vampire Soldier", Flavor = "Kars' army tries to cheat the duel, but you slaughter them." } } },
			[5] = { Name = "Red Stone Secured", Waves = { { Template = "Kars Base", Flavor = "You steal the stone from Kars before he can use it." }, { Template = "Ultimate Kars", Flavor = "Somehow, he still activated it! The volcano erupts again!" } } }
		}
	},

	[3] = {
		Boss = { IsBoss = true, Name = "DIO", Icon = "rbxassetid://84790385900886", Health = 600, Strength = 60, Defense = 35, Speed = 50, Willpower = 45, StandStats = {Power="A", Speed="A", Range="C", Durability="A", Precision="B", Potential="B"}, Stand = "The World", Style = "Vampirism", Drops = { Yen = 400, XP = 800, ItemChance = { ["Stand Arrow"] = 100, ["Anubis Sword"] = 30, ["Dio's Diary"] = 5, ["Jotaro's Hat"] = 30, ["Dio's Throwing Knives"] = 25, ["Stand Power Training Manual"] = 5 } } },
		RandomFlavor = {"A %s attacks you in Egypt!", "An enemy Stand User, %s, blocks the path!"},
		Mobs = {
			{ Name = "Stand User", Icon = "",
				Health = 200, Strength = 25, Defense = 15, Speed = 20, Willpower = 18, StandStats = {Power="C", Speed="C", Range="C", Durability="C", Precision="C", Potential="C"}, 
				Stand = "Star Platinum", Style = "None", 
				Drops = { Yen = 40, XP = 150, ItemChance = { ["Stand Arrow"] = 5, ["Tinted Sunglasses"] = 5, ["Stand Potential Training Manual"] = 1 } } }
		},
		Templates = {
			["Kakyoin"] = { Name = "Noriaki Kakyoin", Icon = "",
				Health = 220, Strength = 28, Defense = 16, Speed = 25, Willpower = 20, StandStats = {Power="C", Speed="B", Range="A", Durability="B", Precision="C", Potential="D"}, 
				Stand = "Hierophant Green", Style = "None", 
				Drops = { Yen = 60, XP = 180, ItemChance={["Kakyoin's Sunglasses"] = 10, ["Stand Range Training Manual"] = 1} } },
			["Gray Fly"] = { Name = "Tower of Gray", Icon = "",
				Health = 240, Strength = 30, Defense = 15, Speed = 30, Willpower = 20, StandStats = {Power="E", Speed="A", Range="A", Durability="C", Precision="E", Potential="E"}, 
				Stand = "Tower of Gray", Style = "None", 
				Drops = { Yen = 65, XP = 200, ItemChance = { ["Stand Speed Training Manual"] = 1 } } },
			["Devo"] = { Name = "Ebony Devil", Icon = "",
				Health = 260, Strength = 32, Defense = 18, Speed = 28, Willpower = 22, StandStats = {Power="D", Speed="D", Range="A", Durability="B", Precision="D", Potential="B"}, 
				Stand = "Ebony Devil", Style = "None", 
				Drops = { Yen = 70, XP = 220, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Hol Horse"] = { Name = "Hol Horse", Icon = "",
				Health = 280, Strength = 35, Defense = 18, Speed = 30, Willpower = 25, StandStats = {Power="B", Speed="B", Range="B", Durability="C", Precision="E", Potential="E"}, 
				Stand = "Emperor", Style = "None", 
				Drops = { Yen = 80, XP = 250, ItemChance={["Emperor Gun"] = 10, ["Heavy Revolver"] = 15, ["Stand Precision Training Manual"] = 1} } },
			["Steely Dan"] = { Name = "The Lovers", Icon = "",
				Health = 300, Strength = 20, Defense = 25, Speed = 40, Willpower = 25, StandStats = {Power="E", Speed="D", Range="A", Durability="A", Precision="D", Potential="E"}, 
				Stand = "The Lovers", Style = "None", 
				Drops = { Yen = 90, XP = 280, ItemChance = { ["Stand Durability Training Manual"] = 1 } } },
			["Death 13"] = { Name = "Death 13", Icon = "",
				Health = 320, Strength = 38, Defense = 22, Speed = 32, Willpower = 28, StandStats = {Power="C", Speed="C", Range="E", Durability="B", Precision="D", Potential="B"}, 
				Stand = "Death Thirteen", Style = "None", 
				Drops = { Yen = 100, XP = 300, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["N'Doul"] = { Name = "N'Doul", Icon = "",
				Health = 350, Strength = 40, Defense = 22, Speed = 30, Willpower = 30, StandStats = {Power="C", Speed="B", Range="A", Durability="B", Precision="A", Potential="D"}, 
				Stand = "Geb", Style = "None", 
				Drops = { Yen = 100, XP = 300, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Pet Shop"] = { Name = "Pet Shop", Icon = "",
				Health = 400, Strength = 45, Defense = 25, Speed = 35, Willpower = 35, StandStats = {Power="B", Speed="B", Range="A", Durability="C", Precision="E", Potential="C"}, 
				Stand = "Horus", Style = "None", 
				Drops = { Yen = 120, XP = 350, ItemChance = { ["Stand Speed Training Manual"] = 1 } } },
			["Vanilla Ice"] = { Name = "Vanilla Ice", Icon = "",
				Health = 450, Strength = 50, Defense = 28, Speed = 40, Willpower = 38, StandStats = {Power="B", Speed="B", Range="D", Durability="C", Precision="C", Potential="D"}, 
				Stand = "Cream", Style = "Vampirism", 
				Drops = { Yen = 150, XP = 400, ItemChance = { ["Stand Power Training Manual"] = 1 } } },
			["DIO"] = { IsBoss = true, Name = "DIO", Icon = "rbxassetid://84790385900886",
				Health = 600, Strength = 60, Defense = 35, Speed = 50, Willpower = 45, StandStats = {Power="A", Speed="A", Range="C", Durability="A", Precision="B", Potential="B"}, 
				Stand = "The World", Style = "Vampirism", 
				Drops = { Yen = 400, XP = 800, ItemChance = { ["Stand Arrow"] = 100, ["Anubis Sword"] = 30, ["Dio's Diary"] = 5, ["Jotaro's Hat"] = 30, ["Dio's Throwing Knives"] = 25, ["Stand Power Training Manual"] = 5 } } }
		},
		Missions = {
			[1] = { Name = "High School Nurse", Waves = { { Template = "Kakyoin", Flavor = "The nurse's office is a trap. Kakyoin strikes with Hierophant Green!" } } },
			[2] = { Name = "Hong Kong Flight", Waves = { { Template = "Gray Fly", Flavor = "A massive stag beetle Stand attacks the plane!" } } },
			[3] = { Name = "Singapore Hotel", Waves = { { Template = "Devo", Flavor = "A cursed doll lunges from under the bed. It's Ebony Devil!", Ally = "Polnareff" } } },
			[4] = { Name = "Calcutta Streets", Waves = { { Template = "Hol Horse", Flavor = "The Emperor's bullet bends around the corner!" } } },
			[5] = { Name = "Karachi Town", Waves = { { Template = "Steely Dan", Flavor = "Steely Dan has planted The Lovers in your brain! You must defeat him!" } } },
			[6] = { Name = "Arabian Desert", Waves = { { Template = "Death 13", Flavor = "You fall asleep. A grim reaper with a scythe welcomes you to his dream world." } } },
			[7] = { Name = "Egyptian Desert", Waves = { { Template = "N'Doul", Flavor = "Geb attacks from beneath the sands. N'Doul is waiting." } } },
			[8] = { Name = "Cairo Streets", Waves = { { Template = "Pet Shop", Flavor = "An ice falcon dives from the sky. Horus freezes the air!" } } },
			[9] = { Name = "DIO's Mansion", Waves = { { Template = "Vanilla Ice", Flavor = "Cream erases everything in its path. Vanilla Ice strikes!" } } },
			[10] = { Name = "Cairo Bridge", Waves = { { Template = "Vanilla Ice", Flavor = "Vanilla Ice refuses to stay down." }, { Template = "DIO", Flavor = "DIO descends from the sky. 'ZA WARUDO!'" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Quick Recruit", Waves = { { Template = "Kakyoin", Flavor = "You remove the flesh bud before Kakyoin can even blink." }, { Template = "Gray Fly", Flavor = "You crush the bug on the plane before it crashes." } } },
			[2] = { Name = "Skipping Borders", Waves = { { Template = "Devo", Flavor = "You find Devo hiding before he can possess the doll.", Ally = "Polnareff" }, { Template = "Hol Horse", Flavor = "You predict the bullet's path and counterattack." } } },
			[3] = { Name = "No Nonsense", Waves = { { Template = "Steely Dan", Flavor = "You catch Steely Dan before he plants the spore." }, { Template = "Death 13", Flavor = "You go to sleep with your Stand active. Death 13 is powerless." } } },
			[4] = { Name = "Egypt Arrival", Waves = { { Template = "N'Doul", Flavor = "You walk softly on the sand, dodging the water strikes." }, { Template = "Pet Shop", Flavor = "You shoot the ice falcon out of the sky without hesitation." } } },
			[5] = { Name = "The World Reborn", Waves = { { Template = "Vanilla Ice", Flavor = "You see through the void. Vanilla Ice is eliminated." }, { Template = "DIO", Flavor = "You step into DIO's stopped time. 'I've seen this before...'" } } }
		}
	},

	[4] = {
		Boss = { IsBoss = true, Name = "Kira (Bites the Dust)", Icon = "rbxassetid://78559266675698", Health = 1100, Strength = 90, Defense = 50, Speed = 75, Willpower = 65, StandStats = {Power="A", Speed="B", Range="D", Durability="B", Precision="C", Potential="A"}, Stand = "Killer Queen", Style = "None", Drops = { Yen = 600, XP = 1200, ItemChance = { ["Stand Arrow"] = 50, ["Strange Arrow"] = 5, ["Bite the Dust Detonator"] = 25, ["Kira's Tie"] = 25, ["Josuke's Peace Badge"] = 15, ["Stand Power Training Manual"] = 5 } } },
		RandomFlavor = {"You run into a %s in Morioh!"},
		Mobs = { { Name = "Morioh Delinquent", Icon = "",
			Health = 350, Strength = 40, Defense = 25, Speed = 35, Willpower = 25, StandStats = {Power="B", Speed="C", Range="D", Durability="C", Precision="C", Potential="C"}, 
			Stand = "None", Style = "None", 
			Drops = { Yen = 60, XP = 200, ItemChance = { ["Stand Arrow"] = 8, ["Wooden Bat"] = 10, ["Running Shoes"] = 5, ["Strength Training Manual"] = 1 } } } 
		},
		Templates = {
			["Angelo"] = { Name = "Angelo", Icon = "",
				Health = 400, Strength = 45, Defense = 30, Speed = 35, Willpower = 28, StandStats = {Power="C", Speed="C", Range="A", Durability="A", Precision="C", Potential="E"}, 
				Stand = "Aqua Necklace", Style = "None", 
				Drops = { Yen = 70, XP = 250, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Okuyasu"] = { Name = "Okuyasu", Icon = "rbxassetid://95630365107580",
				Health = 450, Strength = 55, Defense = 35, Speed = 40, Willpower = 35, StandStats = {Power="B", Speed="B", Range="D", Durability="C", Precision="C", Potential="C"}, 
				Stand = "The Hand", Style = "None", 
				Drops = { Yen = 120, XP = 350, ItemChance = { ["Stand Power Training Manual"] = 1 } } },
			["Akira"] = { Name = "Akira Otoishi", Icon = "",
				Health = 500, Strength = 60, Defense = 35, Speed = 50, Willpower = 38, StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="C", Potential="A"}, 
				Stand = "Red Hot Chili Pepper", Style = "None", 
				Drops = { Yen = 150, XP = 400, ItemChance = { ["Stand Speed Training Manual"] = 1 } } },
			["Shigechi"] = { Name = "Shigechi", Icon = "",
				Health = 550, Strength = 55, Defense = 40, Speed = 45, Willpower = 40, StandStats = {Power="E", Speed="B", Range="A", Durability="A", Precision="E", Potential="C"}, 
				Stand = "Harvest", Style = "None", 
				Drops = { Yen = 160, XP = 450, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Kira Base"] = { Name = "Yoshikage Kira", Icon = "rbxassetid://112623512172737",
				Health = 650, Strength = 70, Defense = 45, Speed = 50, Willpower = 42, StandStats = {Power="A", Speed="B", Range="D", Durability="B", Precision="B", Potential="A"}, 
				Stand = "Killer Queen", Style = "None", 
				Drops = { Yen = 180, XP = 500, ItemChance = { ["Stand Power Training Manual"] = 1 } } },
			["Sheer Heart Attack"] = { Name = "Sheer Heart Attack", Icon = "",
				Health = 700, Strength = 80, Defense = 70, Speed = 30, Willpower = 45, StandStats = {Power="A", Speed="C", Range="A", Durability="A", Precision="E", Potential="A"}, 
				Stand = "Killer Queen", Style = "None", 
				Drops = { Yen = 200, XP = 550, ItemChance = { ["Stand Durability Training Manual"] = 1 } } },
			["Toyohiro"] = { Name = "Toyohiro", Icon = "",
				Health = 750, Strength = 65, Defense = 50, Speed = 45, Willpower = 45, StandStats = {Power="E", Speed="E", Range="E", Durability="A", Precision="E", Potential="E"}, 
				Stand = "Super Fly", Style = "None", 
				Drops = { Yen = 220, XP = 600, ItemChance = { ["Stand Durability Training Manual"] = 1 } } },
			["Terunosuke"] = { Name = "Terunosuke", Icon = "",
				Health = 800, Strength = 70, Defense = 50, Speed = 50, Willpower = 48, StandStats = {Power="E", Speed="E", Range="C", Durability="A", Precision="C", Potential="C"}, 
				Stand = "Enigma", Style = "None", 
				Drops = { Yen = 250, XP = 700, ItemChance = { ["Stand Speed Training Manual"] = 1 } } },
			["Stray Cat"] = { Name = "Stray Cat", Icon = "",
				Health = 850, Strength = 75, Defense = 50, Speed = 60, Willpower = 50, StandStats = {Power="B", Speed="E", Range="None", Durability="A", Precision="E", Potential="C"}, 
				Stand = "Stray Cat", Style = "None", 
				Drops = { Yen = 300, XP = 800, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Kira BTD"] = { IsBoss = true, Name = "Yoshikage Kira (BTD)", Icon = "rbxassetid://78559266675698",
				Health = 1100, Strength = 90, Defense = 55, Speed = 75, Willpower = 60, StandStats = {Power="A", Speed="B", Range="D", Durability="B", Precision="B", Potential="A"}, 
				Stand = "Killer Queen BTD", Style = "None", 
				Drops = { Yen = 600, XP = 1200, ItemChance = { ["Stand Arrow"] = 50, ["Strange Arrow"] = 5, ["Bite the Dust Detonator"] = 25, ["Kira's Tie"] = 25, ["Stand Power Training Manual"] = 5 } } }
		},
		Missions = {
			[1] = { Name = "Aqua Necklace", Waves = { { Template = "Angelo", Flavor = "Angelo tries to drown you from the inside!" } } },
			[2] = { Name = "The Hand", Waves = { { Template = "Okuyasu", Flavor = "Okuyasu erases the space between you to attack!" } } },
			[3] = { Name = "Chili Pepper", Waves = { { Template = "Akira", Flavor = "Red Hot Chili Pepper steals the electricity and strikes!", Ally = "Okuyasu" } } },
			[4] = { Name = "Harvest", Waves = { { Template = "Shigechi", Flavor = "Shigechi's Harvest swarms you over a stolen sandwich!" } } },
			[5] = { Name = "Centipede Shoes", Waves = { { Template = "Kira Base", Flavor = "Kira just wants a quiet life. You disrupted it." } } },
			[6] = { Name = "Heart Attack", Waves = { { Template = "Sheer Heart Attack", Flavor = "'Look over here!' An indestructible tank rushes you." } } },
			[7] = { Name = "Super Fly", Waves = { { Template = "Toyohiro", Flavor = "You are trapped inside an electrical pylon!" } } },
			[8] = { Name = "Enigma", Waves = { { Template = "Terunosuke", Flavor = "Don't show fear, or Enigma will fold you into paper!" } } },
			[9] = { Name = "Air Plant", Waves = { { Template = "Stray Cat", Flavor = "An invisible air bubble explodes near you. Stray Cat attacks." } } },
			[10] = { Name = "Bites the Dust", Waves = { { Template = "Kira BTD", Flavor = "Time rewinds! Kira has activated Bites the Dust!" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Town Cleanup", Waves = { { Template = "Angelo", Flavor = "You don't let Angelo anywhere near the water." }, { Template = "Okuyasu", Flavor = "You dodge Okuyasu's slow swipe and recruit him instantly." } } },
			[2] = { Name = "Electrical Hazard", Waves = { { Template = "Akira", Flavor = "You ground the electricity. Akira is helpless.", Ally = "Okuyasu" }, { Template = "Shigechi", Flavor = "You give Shigechi back his sandwich to avoid the fight." } } },
			[3] = { Name = "The Killer's Trail", Waves = { { Template = "Kira Base", Flavor = "You intercept Kira at the tailor shop before he can hide." }, { Template = "Sheer Heart Attack", Flavor = "You already know its weakness. You trap the tank." } } },
			[4] = { Name = "Traps Bypassed", Waves = { { Template = "Toyohiro", Flavor = "You refuse to step into the pylon." }, { Template = "Terunosuke", Flavor = "You show absolutely no fear. Enigma folds itself." } } },
			[5] = { Name = "Dust Settles", Waves = { { Template = "Stray Cat", Flavor = "You deflect the air bullets with precision." }, { Template = "Kira BTD", Flavor = "Kira tries to rewind time, but you break his hand first." } } }
		}
	},

	[5] = {
		Boss = { IsBoss = true, Name = "Diavolo", Icon = "rbxassetid://86941295205734", Health = 1600, Strength = 120, Defense = 70, Speed = 95, Willpower = 85, StandStats = {Power="A", Speed="A", Range="E", Durability="E", Precision="B", Potential="A"}, Stand = "King Crimson", Style = "None", Drops = { Yen = 1000, XP = 2000, ItemChance = { ["Stand Arrow"] = 50, ["Strange Arrow"] = 5, ["Vampire Cape"] = 5, ["Stand Power Training Manual"] = 5 } } },
		RandomFlavor = {"A %s steps out of a dark alley in Italy!"},
		Mobs = { { Name = "Passione Grunt", Icon = "",
			Health = 500, Strength = 55, Defense = 40, Speed = 45, Willpower = 35, StandStats = {Power="B", Speed="B", Range="C", Durability="C", Precision="B", Potential="C"}, 
			Stand = "None", Style = "None", 
			Drops = { Yen = 100, XP = 300, ItemChance = { ["Stand Arrow"] = 10, ["Heavy Revolver"] = 5, ["Iron Ring"] = 5, ["Stand Precision Training Manual"] = 1 } } } 
		},
		Templates = {
			["Bruno"] = { Name = "Bruno Bucciarati", Icon = "",
				Health = 650, Strength = 70, Defense = 50, Speed = 60, Willpower = 45, StandStats = {Power="A", Speed="A", Range="E", Durability="D", Precision="C", Potential="D"}, 
				Stand = "Sticky Fingers", Style = "None", 
				Drops = { Yen = 150, XP = 500, ItemChance={["Giorno's Ladybug Brooch"] = 15, ["Stand Speed Training Manual"] = 1} } },
			["Zucchero"] = { Name = "Zucchero", Icon = "",
				Health = 680, Strength = 72, Defense = 50, Speed = 55, Willpower = 48, StandStats = {Power="A", Speed="C", Range="E", Durability="A", Precision="E", Potential="E"}, 
				Stand = "Soft Machine", Style = "None", 
				Drops = { Yen = 160, XP = 520, ItemChance = { ["Stand Durability Training Manual"] = 1 } } },
			["Formaggio"] = { Name = "Formaggio", Icon = "",
				Health = 720, Strength = 75, Defense = 55, Speed = 65, Willpower = 50, StandStats = {Power="D", Speed="B", Range="E", Durability="A", Precision="D", Potential="C"}, 
				Stand = "Little Feet", Style = "None", 
				Drops = { Yen = 180, XP = 550, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Illuso"] = { Name = "Illuso", Icon = "",
				Health = 780, Strength = 80, Defense = 55, Speed = 60, Willpower = 52, StandStats = {Power="C", Speed="C", Range="C", Durability="D", Precision="C", Potential="E"}, 
				Stand = "Man in the Mirror", Style = "None", 
				Drops = { Yen = 200, XP = 600, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Pesci"] = { Name = "Pesci", Icon = "",
				Health = 850, Strength = 85, Defense = 60, Speed = 55, Willpower = 55, StandStats = {Power="C", Speed="B", Range="B", Durability="C", Precision="C", Potential="A"}, 
				Stand = "Beach Boy", Style = "None", 
				Drops = { Yen = 250, XP = 700, ItemChance={["Mista's Pistol"] = 10, ["Stand Range Training Manual"] = 1} } },
			["Melone"] = { Name = "Melone", Icon = "",
				Health = 900, Strength = 90, Defense = 60, Speed = 65, Willpower = 58, StandStats = {Power="A", Speed="B", Range="A", Durability="A", Precision="None", Potential="None"}, 
				Stand = "Baby Face", Style = "None", 
				Drops = { Yen = 280, XP = 800, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Ghiaccio"] = { Name = "Ghiaccio", Icon = "",
				Health = 1000, Strength = 95, Defense = 75, Speed = 70, Willpower = 60, StandStats = {Power="A", Speed="C", Range="C", Durability="A", Precision="E", Potential="E"}, 
				Stand = "White Album", Style = "None", 
				Drops = { Yen = 350, XP = 900, ItemChance = { ["Stand Durability Training Manual"] = 1 } } },
			["KC Base"] = { Name = "King Crimson", Icon = "",
				Health = 1150, Strength = 105, Defense = 65, Speed = 80, Willpower = 70, StandStats = {Power="A", Speed="A", Range="E", Durability="E", Precision="B", Potential="A"}, 
				Stand = "King Crimson", Style = "None", 
				Drops = { Yen = 400, XP = 1100, ItemChance = { ["Stand Power Training Manual"] = 1 } } },
			["Cioccolata"] = { Name = "Cioccolata", Icon = "",
				Health = 1250, Strength = 105, Defense = 65, Speed = 75, Willpower = 75, StandStats = {Power="A", Speed="C", Range="A", Durability="A", Precision="E", Potential="A"}, 
				Stand = "Green Day", Style = "None", 
				Drops = { Yen = 450, XP = 1300, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Diavolo"] = { IsBoss = true, Name = "Diavolo", Icon = "rbxassetid://86941295205734",
				Health = 1600, Strength = 120, Defense = 70, Speed = 95, Willpower = 85, StandStats = {Power="A", Speed="A", Range="E", Durability="E", Precision="B", Potential="A"}, 
				Stand = "King Crimson", Style = "None", 
				Drops = { Yen = 1000, XP = 2000, ItemChance = { ["Stand Arrow"] = 50, ["Strange Arrow"] = 5, ["Vampire Cape"] = 5, ["Stand Power Training Manual"] = 5 } } }
		},
		Missions = {
			[1] = { Name = "Naples Station", Waves = { { Template = "Bruno", Flavor = "Bruno Bucciarati unzips the train car and interrogates you!" } } },
			[2] = { Name = "Capri Boat", Waves = { { Template = "Zucchero", Flavor = "The boat is shrinking! Zucchero deflates your allies." } } },
			[3] = { Name = "Little Feet", Waves = { { Template = "Formaggio", Flavor = "Formaggio shrinks you down to size!" } } },
			[4] = { Name = "Man in the Mirror", Waves = { { Template = "Illuso", Flavor = "You are pulled into the mirror world where your Stand can't reach." } } },
			[5] = { Name = "The Grateful Death", Waves = { { Template = "Pesci", Flavor = "Pesci hooks your heart with Beach Boy!" } } },
			[6] = { Name = "Baby Face", Waves = { { Template = "Melone", Flavor = "A homunculus tracks you down via your DNA. Baby Face attacks." } } },
			[7] = { Name = "White Album", Waves = { { Template = "White Album", Flavor = "The air freezes around you. Ghiaccio glides in!" } } },
			[8] = { Name = "Venice Church", Waves = { { Template = "KC Base", Flavor = "Time skips. A hole is punched through your ally. The Boss is here." } } },
			[9] = { Name = "Green Day", Waves = { { Template = "Cioccolata", Flavor = "Mold consumes Rome. Cioccolata looks down on you." } } },
			[10] = { Name = "The Arrow", Waves = { { Template = "Diavolo", Flavor = "Time is erased. Diavolo approaches the Requiem Arrow!" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Passione's Test", Waves = { { Template = "Bruno", Flavor = "You counter Bruno's zipper strike immediately." }, { Template = "Zucchero", Flavor = "You find the second boat before it deflates." } } },
			[2] = { Name = "Assassin Squad", Waves = { { Template = "Formaggio", Flavor = "You crush Formaggio before he shrinks." }, { Template = "Illuso", Flavor = "You shatter the mirror before he drags you in." } } },
			[3] = { Name = "Train Express", Waves = { { Template = "Pesci", Flavor = "You snap the fishing line. Pesci panics." }, { Template = "Melone", Flavor = "You trace the homunculus back to Melone." } } },
			[4] = { Name = "Chilling Truth", Waves = { { Template = "Ghiaccio", Flavor = "You melt his ice armor instantly." }, { Template = "KC Base", Flavor = "You predict the time skip in Venice and counterattack!" } } },
			[5] = { Name = "Arrow Reclaimed", Waves = { { Template = "Cioccolata", Flavor = "You avoid the lower ground and strike Cioccolata from above." }, { Template = "Diavolo", Flavor = "Epitaph couldn't predict this. Diavolo falls." } } }
		}
	},

	[6] = {
		Boss = { IsBoss = true, Name = "Enrico Pucci", Icon = "rbxassetid://80960379225409", Health = 2400, Strength = 150, Defense = 95, Speed = 140, Willpower = 110, StandStats = {Power="B", Speed="A", Range="C", Durability="A", Precision="C", Potential="A"}, Stand = "Made in Heaven", Style = "None", Drops = { Yen = 2000, XP = 5000, ItemChance = { ["Stand Arrow"] = 50, ["Strange Arrow"] = 5, ["Green Baby"] = 10, ["Pucci's Disc"] = 30, ["Stand Speed Training Manual"] = 5 } } },
		RandomFlavor = {"A %s tries to stop you in the prison!"},
		Mobs = { { Name = "Prison Guards", Icon = "",
			Health = 750, Strength = 75, Defense = 55, Speed = 60, Willpower = 50, StandStats = {Power="C", Speed="C", Range="B", Durability="B", Precision="C", Potential="C"}, 
			Stand = "None", Style = "None", 
			Drops = { Yen = 150, XP = 500, ItemChance = { ["Stand Arrow"] = 15, ["Steel Pipe"] = 10, ["Strength Training Manual"] = 1 } } } 
		},
		Templates = {
			["Gwess"] = { Name = "Gwess", Icon = "",
				Health = 900, Strength = 80, Defense = 60, Speed = 65, Willpower = 60, StandStats = {Power="D", Speed="C", Range="B", Durability="D", Precision="B", Potential="B"}, 
				Stand = "Goo Goo Dolls", Style = "None", 
				Drops = { Yen = 200, XP = 600, ItemChance={["Jolyne's String"] = 15, ["Stand Range Training Manual"] = 1} } },
			["Johngalli A"] = { Name = "Johngalli A.", Icon = "",
				Health = 1000, Strength = 90, Defense = 65, Speed = 75, Willpower = 65, StandStats = {Power="E", Speed="E", Range="A", Durability="A", Precision="A", Potential="C"}, 
				Stand = "Manhattan Transfer", Style = "None", 
				Drops = { Yen = 250, XP = 800, ItemChance = { ["Stand Precision Training Manual"] = 1 } } },
			["Miraschon"] = { Name = "Miraschon", Icon = "",
				Health = 1100, Strength = 95, Defense = 70, Speed = 80, Willpower = 70, StandStats = {Power="E", Speed="A", Range="A", Durability="A", Precision="A", Potential="C"}, 
				Stand = "Marilyn Manson", Style = "None", 
				Drops = { Yen = 300, XP = 1000, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Lang Rangler"] = { Name = "Lang Rangler", Icon = "",
				Health = 1200, Strength = 100, Defense = 75, Speed = 85, Willpower = 75, StandStats = {Power="B", Speed="C", Range="B", Durability="A", Precision="D", Potential="B"}, 
				Stand = "Jumpin' Jack Flash", Style = "None", 
				Drops = { Yen = 350, XP = 1100, ItemChance = { ["Stand Durability Training Manual"] = 1 } } },
			["Sports Maxx"] = { Name = "Sports Maxx", Icon = "",
				Health = 1350, Strength = 105, Defense = 75, Speed = 90, Willpower = 80, StandStats = {Power="None", Speed="None", Range="None", Durability="None", Precision="None", Potential="None"}, 
				Stand = "Limp Bizkit", Style = "None", 
				Drops = { Yen = 400, XP = 1200, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Guccio"] = { Name = "Guccio", Icon = "",
				Health = 1450, Strength = 110, Defense = 80, Speed = 95, Willpower = 85, StandStats = {Power="E", Speed="E", Range="E", Durability="C", Precision="E", Potential="E"}, 
				Stand = "Survivor", Style = "None", 
				Drops = { Yen = 450, XP = 1300, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Westwood"] = { Name = "Viviano Westwood", Icon = "",
				Health = 1600, Strength = 120, Defense = 80, Speed = 100, Willpower = 90, StandStats = {Power="A", Speed="B", Range="A", Durability="A", Precision="E", Potential="E"}, 
				Stand = "Planet Waves", Style = "None", 
				Drops = { Yen = 500, XP = 1500, ItemChance = { ["Strength Training Manual"] = 1 } } },
			["Miu Miu"] = { Name = "Miu Miu", Icon = "",
				Health = 1750, Strength = 125, Defense = 85, Speed = 110, Willpower = 95, StandStats = {Power="None", Speed="C", Range="A", Durability="A", Precision="None", Potential="None"}, 
				Stand = "Jail House Lock", Style = "None", 
				Drops = { Yen = 550, XP = 1800, ItemChance = { ["Stand Range Training Manual"] = 1 } } },
			["Pucci C-Moon"] = { Name = "Enrico Pucci", Icon = "rbxassetid://138993866592031",
				Health = 1900, Strength = 135, Defense = 90, Speed = 120, Willpower = 100, StandStats = {Power="B", Speed="D", Range="C", Durability="A", Precision="None", Potential="None"}, 
				Stand = "C-Moon", Style = "None", 
				Drops = { Yen = 600, XP = 2200, ItemChance = { ["Stand Durability Training Manual"] = 1 } } },
			["Pucci MiH"] = { IsBoss = true, Name = "Enrico Pucci (MiH)", Icon = "rbxassetid://80960379225409",
				Health = 2400, Strength = 150, Defense = 95, Speed = 140, Willpower = 110, StandStats = {Power="B", Speed="A", Range="C", Durability="A", Precision="C", Potential="A"}, 
				Stand = "Made in Heaven", Style = "None", 
				Drops = { Yen = 2000, XP = 5000, ItemChance = { ["Stand Arrow"] = 50, ["Strange Arrow"] = 5, ["Green Baby"] = 10, ["Pucci's Disc"] = 30, ["Stand Speed Training Manual"] = 5 } } }
		},
		Missions = {
			[1] = { Name = "Prison Cell", Waves = { { Template = "Gwess", Flavor = "Gwess shrinks you down and puts you in a parrot corpse!" } } },
			[2] = { Name = "Manhattan Transfer", Waves = { { Template = "Johngalli A", Flavor = "Bullets ricochet around the room. Johngalli A strikes!" } } },
			[3] = { Name = "Debt Collector", Waves = { { Template = "Miraschon", Flavor = "Miraschon comes to collect your liver!" } } },
			[4] = { Name = "Zero Gravity", Waves = { { Template = "Lang Rangler", Flavor = "You float uncontrollably. Lang Rangler attacks in the vacuum!" } } },
			[5] = { Name = "Flaccid Pancake", Waves = { { Template = "Sports Maxx", Flavor = "Invisible zombies rise from the dead. Sports Maxx is here." } } },
			[6] = { Name = "Survivor", Waves = { { Template = "Guccio", Flavor = "An irrational anger fills the room. Guccio sparks a brawl." } } },
			[7] = { Name = "Planet Waves", Waves = { { Template = "Westwood", Flavor = "Meteors crash through the ceiling. Guard Westwood attacks!" } } },
			[8] = { Name = "Jail House Lock", Waves = { { Template = "Miu Miu", Flavor = "You can only remember three things. You must defeat Miu Miu." } } },
			[9] = { Name = "Gravity Shift", Waves = { { Template = "Pucci C-Moon", Flavor = "Gravity inverts. Pucci floats above you with C-Moon!" } } },
			[10] = { Name = "Made In Heaven", Waves = { { Template = "Pucci MiH", Flavor = "Time accelerates instantly. 'MADE IN HEAVEN!'" } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Cell Block Control", Waves = { { Template = "Gwess", Flavor = "You refuse to put on the parrot suit." }, { Template = "Johngalli A", Flavor = "You calculate the ricochet and dodge the bullet completely." } } },
			[2] = { Name = "Courtyard Brawl", Waves = { { Template = "Miraschon", Flavor = "You refuse to gamble. You just attack." }, { Template = "Lang Rangler", Flavor = "You adapt to zero gravity instantly." } } },
			[3] = { Name = "Maximum Security", Waves = { { Template = "Sports Maxx", Flavor = "You strike the invisible zombies before they bite." }, { Template = "Guccio", Flavor = "You ignore the anger and take out Guccio directly." } } },
			[4] = { Name = "Lockdown", Waves = { { Template = "Westwood", Flavor = "You dodge the meteors perfectly." }, { Template = "Miu Miu", Flavor = "You already memorized her ability. You don't forget." } } },
			[5] = { Name = "Heaven Averted", Waves = { { Template = "Pucci C-Moon", Flavor = "You counter the inverted gravity." }, { Template = "Pucci MiH", Flavor = "Time accelerates, but your speed matches his! A clash of titans!" } } }
		}
	},

	[7] = {
		Boss = { 
			IsBoss = true, Name = "Funny Valentine", Icon = "", 
			Health = 15000, Strength = 500, Defense = 300, Speed = 250, Willpower = 250, 
			StandStats = {Power="A", Speed="A", Range="C", Durability="A", Precision="A", Potential="A"}, 
			Stand = "D4C Love Train", Style = "None", 
			Drops = { Yen = 15000, XP = 50000, ItemChance = { ["Stand Arrow"] = 100, ["Saint's Corpse Part"] = 10, ["Stand Durability Training Manual"] = 5 } } 
		},
		RandomFlavor = {"A %s ambushes you in the cross-country race!"},
		Mobs = { 
			{ Name = "Rogue Jockey", Icon = "",
				Health = 4000, Strength = 150, Defense = 100, Speed = 100, Willpower = 100, 
				StandStats = {Power="B", Speed="B", Range="B", Durability="C", Precision="B", Potential="C"}, 
				Stand = "None", Style = "Spin", 
				Drops = { Yen = 1500, XP = 8000, ItemChance = { ["Stand Arrow"] = 25, ["Steel Ball"] = 1, ["Speed Training Manual"] = 1 } } } 
		},
		Templates = {
			["Oyecomova"] = { Name = "Oyecomova", Icon = "",
				Health = 5000, Strength = 200, Defense = 120, Speed = 120, Willpower = 120, 
				StandStats = {Power="B", Speed="B", Range="B", Durability="B", Precision="C", Potential="C"}, 
				Stand = "Boku no Rhythm wo Kiitekure", Style = "None", 
				Drops = { Yen = 2500, XP = 12000, ItemChance = { ["Stand Range Training Manual"] = 1 } } },

			["Pork Pie Hat"] = { Name = "Pork Pie Hat Kid", Icon = "",
				Health = 5500, Strength = 220, Defense = 130, Speed = 130, Willpower = 130, 
				StandStats = {Power="C", Speed="C", Range="A", Durability="B", Precision="B", Potential="C"}, 
				Stand = "Wired", Style = "None", 
				Drops = { Yen = 3000, XP = 13500, ItemChance = { ["Stand Range Training Manual"] = 1 } } },

			["Sandman"] = { Name = "Sandman", Icon = "",
				Health = 6000, Strength = 250, Defense = 150, Speed = 150, Willpower = 150, 
				StandStats = {Power="C", Speed="C", Range="D", Durability="A", Precision="D", Potential="B"}, 
				Stand = "In a Silent Way", Style = "None", 
				Drops = { Yen = 3500, XP = 15000, ItemChance = { ["Stand Speed Training Manual"] = 1 } } },

			["Eleven Men"] = { Name = "Eleven Men", Icon = "",
				Health = 6500, Strength = 270, Defense = 160, Speed = 160, Willpower = 160, 
				StandStats = {Power="None", Speed="E", Range="C", Durability="B", Precision="E", Potential="E"}, 
				Stand = "Tattoo You!", Style = "None", 
				Drops = { Yen = 4000, XP = 17000, ItemChance = { ["Saint's Left Arm"] = 10, ["Stand Range Training Manual"] = 1 } } },

			["Blackmore"] = { Name = "Blackmore", Icon = "",
				Health = 7000, Strength = 300, Defense = 180, Speed = 180, Willpower = 180, 
				StandStats = {Power="C", Speed="C", Range="B", Durability="B", Precision="B", Potential="D"}, 
				Stand = "Catch the Rainbow", Style = "None", 
				Drops = { Yen = 5000, XP = 20000, ItemChance = { ["Stand Precision Training Manual"] = 1 } } },

			["Ringo"] = { Name = "Ringo Roadagain", Icon = "",
				Health = 7500, Strength = 320, Defense = 200, Speed = 200, Willpower = 200, 
				StandStats = {Power="None", Speed="A", Range="None", Durability="E", Precision="None", Potential="C"}, 
				Stand = "Mandom", Style = "None", 
				Drops = { Yen = 7000, XP = 25000, ItemChance = { ["Stand Precision Training Manual"] = 1 } } },

			["Wekapipo"] = { Name = "Wekapipo", Icon = "",
				Health = 8000, Strength = 350, Defense = 220, Speed = 210, Willpower = 210, 
				StandStats = {Power="None", Speed="None", Range="None", Durability="None", Precision="None", Potential="None"}, 
				Stand = "None", Style = "Spin", 
				Drops = { Yen = 8000, XP = 28000, ItemChance = { ["Steel Ball"] = 15, ["Stand Precision Training Manual"] = 1 } } },

			["Magenta"] = { Name = "Magenta Magenta", Icon = "",
				Health = 9000, Strength = 380, Defense = 500, Speed = 100, Willpower = 220, 
				StandStats = {Power="None", Speed="C", Range="None", Durability="A", Precision="D", Potential="C"}, 
				Stand = "20th Century Boy", Style = "None", 
				Drops = { Yen = 9000, XP = 30000, ItemChance = { ["Stand Durability Training Manual"] = 1 } } },

			["Diego"] = { Name = "Diego Brando", Icon = "",
				Health = 10000, Strength = 400, Defense = 250, Speed = 220, Willpower = 220, 
				StandStats = {Power="B", Speed="B", Range="B", Durability="A", Precision="C", Potential="B"}, 
				Stand = "Scary Monsters", Style = "None", 
				Drops = { Yen = 10000, XP = 35000, ItemChance = { ["Saint's Right Eye"] = 10, ["Stand Speed Training Manual"] = 1 } } },

			["Valentine"] = { IsBoss = true, Name = "Funny Valentine", Icon = "",
				Health = 12500, Strength = 420, Defense = 300, Speed = 250, Willpower = 250, 
				StandStats = {Power="A", Speed="A", Range="C", Durability="A", Precision="A", Potential="A"}, 
				Stand = "D4C Love Train", Style = "None", 
				Drops = { Yen = 15000, XP = 50000, ItemChance = { ["Stand Arrow"] = 100, ["Saint's Corpse Part"] = 10, ["Stand Durability Training Manual"] = 5 } } }
		},
		Missions = {
			[1] = { Name = "Boku no Rhythm", Waves = { { Template = "Oyecomova", Flavor = "A terrorist with clockwork bombs attacks!" } } },
			[2] = { Name = "Wired", Waves = { { Template = "Pork Pie Hat", Flavor = "Hooks drop from the sky! Pork Pie Hat Kid attacks." } } },
			[3] = { Name = "In a Silent Way", Waves = { { Template = "Sandman", Flavor = "Sound becomes a weapon!" } } },
			[4] = { Name = "Tattoo You!", Waves = { { Template = "Eleven Men", Flavor = "Assassins share a single body and attack in unison!" } } },
			[5] = { Name = "Catch the Rainbow", Waves = { { Template = "Blackmore", Flavor = "The rain stops mid-air. Blackmore walks on water." } } },
			[6] = { Name = "True Man's World", Waves = { { Template = "Ringo", Flavor = "Welcome to the True Man's World. Draw your weapon.", Ally = "Gyro Zeppeli" } } },
			[7] = { Name = "Wrecking Ball", Waves = { { Template = "Wekapipo", Flavor = "Your left side goes numb. Wekapipo throws his steel balls!", Ally = "Gyro Zeppeli" } } },
			[8] = { Name = "20th Century Boy", Waves = { { Template = "Magenta", Flavor = "Magenta Magenta drops to the ground, becoming completely invincible!" } } },
			[9] = { Name = "Scary Monsters", Waves = { { Template = "Diego", Flavor = "Diego unleashes his raptors! 'USHAAA!'" } } },
			[10] = { Name = "D4C", Waves = { { Template = "Valentine", Flavor = "Suppose that you were sitting down at this table..." } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Boku no Rhythm", Waves = { { Template = "Oyecomova", Flavor = "A terrorist with clockwork bombs attacks!" } } },
			[2] = { Name = "Wired", Waves = { { Template = "Pork Pie Hat", Flavor = "Hooks drop from the sky! Pork Pie Hat Kid attacks." } } },
			[3] = { Name = "In a Silent Way", Waves = { { Template = "Sandman", Flavor = "Sound becomes a weapon!" } } },
			[4] = { Name = "Tattoo You!", Waves = { { Template = "Eleven Men", Flavor = "Assassins share a single body and attack in unison!" } } },
			[5] = { Name = "Catch the Rainbow", Waves = { { Template = "Blackmore", Flavor = "The rain stops mid-air. Blackmore walks on water." } } },
			[6] = { Name = "True Man's World", Waves = { { Template = "Ringo", Flavor = "Welcome to the True Man's World. Draw your weapon.", Ally = "Gyro Zeppeli" } } },
			[7] = { Name = "Wrecking Ball", Waves = { { Template = "Wekapipo", Flavor = "Your left side goes numb. Wekapipo throws his steel balls!", Ally = "Gyro Zeppeli" } } },
			[8] = { Name = "20th Century Boy", Waves = { { Template = "Magenta", Flavor = "Magenta Magenta drops to the ground, becoming completely invincible!" } } },
			[9] = { Name = "Scary Monsters", Waves = { { Template = "Diego", Flavor = "Diego unleashes his raptors! 'USHAAA!'"} } },
			[10] = { Name = "D4C", Waves = { { Template = "Valentine", Flavor = "Suppose that you were sitting down at this table..." } } }
		}
	},

	[8] = {
		Boss = { 
			IsBoss = true, Name = "Tooru", Icon = "",
			Health = 18000, Strength = 550, Defense = 350, Speed = 350, Willpower = 300, 
			StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"}, 
			Stand = "Wonder of U", Style = "None", 
			Drops = { Yen = 20000, XP = 60000, ItemChance = { ["Stand Arrow"] = 100, ["Rokakaka"] = 50, ["Stand Range Training Manual"] = 5 } } 
		},
		RandomFlavor = {"A %s appears in Morioh!", "A %s steps out from the fruit parlor!"},
		Mobs = { 
			{ Name = "Rock Human Thug", Icon = "",
				Health = 5000, Strength = 200, Defense = 150, Speed = 120, Willpower = 150, 
				StandStats = {Power="C", Speed="C", Range="D", Durability="B", Precision="D", Potential="E"}, 
				Stand = "None", Style = "None", 
				Drops = { Yen = 2000, XP = 10000, ItemChance = { ["Stand Arrow"] = 25, ["Rokakaka"] = 2, ["Defense Training Manual"] = 1 } } } 
		},
		Templates = {
			["Ojiro"] = { Name = "Ojiro Sasame", Icon = "",
				Health = 5500, Strength = 200, Defense = 150, Speed = 150, Willpower = 150, 
				StandStats = {Power="D", Speed="C", Range="D", Durability="A", Precision="E", Potential="E"}, 
				Stand = "Fun Fun Fun", Style = "None", 
				Drops = { Yen = 3000, XP = 14000, ItemChance = { ["Stand Range Training Manual"] = 1 } } },

			["Daiya"] = { Name = "Daiya Higashikata", Icon = "",
				Health = 6000, Strength = 220, Defense = 160, Speed = 160, Willpower = 160, 
				StandStats = {Power="E", Speed="E", Range="E", Durability="B", Precision="E", Potential="E"}, 
				Stand = "California King Bed", Style = "None", 
				Drops = { Yen = 3500, XP = 15500, ItemChance = { ["Stand Range Training Manual"] = 1 } } },

			["Tsurugi"] = { Name = "Tsurugi Higashikata", Icon = "",
				Health = 6500, Strength = 240, Defense = 170, Speed = 170, Willpower = 170, 
				StandStats = {Power="E", Speed="E", Range="C", Durability="C", Precision="C", Potential="E"}, 
				Stand = "Paper Moon King", Style = "None", 
				Drops = { Yen = 4000, XP = 17000, ItemChance = { ["Stand Range Training Manual"] = 1 } } },

			["Yotsuyu"] = { Name = "Yotsuyu Yagiyama", Icon = "",
				Health = 7000, Strength = 260, Defense = 180, Speed = 180, Willpower = 180, 
				StandStats = {Power="C", Speed="C", Range="C", Durability="A", Precision="E", Potential="E"}, 
				Stand = "I Am a Rock", Style = "None", 
				Drops = { Yen = 4500, XP = 18500, ItemChance = { ["Stand Durability Training Manual"] = 1 } } },

			["Aisho"] = { Name = "Aisho Dainenjiyama", Icon = "",
				Health = 7500, Strength = 280, Defense = 190, Speed = 190, Willpower = 190, 
				StandStats = {Power="C", Speed="C", Range="A", Durability="A", Precision="E", Potential="E"}, 
				Stand = "Doobie Wah!", Style = "None", 
				Drops = { Yen = 5000, XP = 20000, ItemChance = { ["Stand Range Training Manual"] = 1 } } },

			["Damo"] = { Name = "Tamaki Damo", Icon = "",
				Health = 8500, Strength = 320, Defense = 220, Speed = 210, Willpower = 210, 
				StandStats = {Power="E", Speed="E", Range="C", Durability="A", Precision="E", Potential="E"}, 
				Stand = "Vitamin C", Style = "None", 
				Drops = { Yen = 6500, XP = 24000, ItemChance = { ["Stand Durability Training Manual"] = 1 } } },

			["Urban"] = { Name = "Urban Guerrilla", Icon = "",
				Health = 9500, Strength = 350, Defense = 240, Speed = 230, Willpower = 230, 
				StandStats = {Power="C", Speed="C", Range="C", Durability="A", Precision="E", Potential="E"}, 
				Stand = "Brain Storm", Style = "None", 
				Drops = { Yen = 7500, XP = 27000, ItemChance = { ["Stand Range Training Manual"] = 1 } } },

			["Dolomite"] = { Name = "Dolomite", Icon = "",
				Health = 10500, Strength = 380, Defense = 260, Speed = 240, Willpower = 240, 
				StandStats = {Power="E", Speed="E", Range="A", Durability="A", Precision="E", Potential="E"}, 
				Stand = "Blue Hawaii", Style = "None", 
				Drops = { Yen = 8500, XP = 30000, ItemChance = { ["Stand Range Training Manual"] = 1 } } },

			["Jobin"] = { Name = "Jobin Higashikata", Icon = "",
				Health = 12500, Strength = 420, Defense = 280, Speed = 280, Willpower = 280, 
				StandStats = {Power="C", Speed="B", Range="D", Durability="A", Precision="C", Potential="C"}, 
				Stand = "Speed King", Style = "None", 
				Drops = { Yen = 10000, XP = 35000, ItemChance = { ["Stand Power Training Manual"] = 1 } } },

			["Tooru"] = { IsBoss = true, Name = "Tooru", Icon = "",
				Health = 18000, Strength = 550, Defense = 350, Speed = 350, Willpower = 300, 
				StandStats = {Power="A", Speed="A", Range="A", Durability="A", Precision="A", Potential="A"}, 
				Stand = "Wonder of U", Style = "None", 
				Drops = { Yen = 20000, XP = 60000, ItemChance = { ["Saint's Corpse Part"] = 100, ["Rokakaka"] = 50, ["Stand Range Training Manual"] = 5 } } }
		},
		Missions = {
			[1] = { Name = "Fun Fun Fun", Waves = { { Template = "Ojiro", Flavor = "You are ambushed in the apartment! Fun Fun Fun takes control." } } },
			[2] = { Name = "California King Bed", Waves = { { Template = "Daiya", Flavor = "You broke a rule. Daiya attempts to steal your memories." } } },
			[3] = { Name = "Paper Moon King", Waves = { { Template = "Tsurugi", Flavor = "Everything looks the same! An origami frog attacks!" } } },
			[4] = { Name = "I Am a Rock", Waves = { { Template = "Yotsuyu", Flavor = "A rock human surfaces! The architect attacks." } } },
			[5] = { Name = "Doobie Wah!", Waves = { { Template = "Aisho", Flavor = "A tornado chases your every breath. Survive!" } } },
			[6] = { Name = "Vitamin C", Waves = { { Template = "Damo", Flavor = "The room is melting. Tamaki Damo reveals himself!" } } },
			[7] = { Name = "Brain Storm", Waves = { { Template = "Urban", Flavor = "Cells pop like bubbles! The doctor strikes.", Ally = "Yasuho" } } },
			[8] = { Name = "Blue Hawaii", Waves = { { Template = "Dolomite", Flavor = "Zombies are relentlessly pursuing you. Find the source!" } } },
			[9] = { Name = "Speed King", Waves = { { Template = "Jobin", Flavor = "The temperature rises drastically. Jobin stands in your way." } } },
			[10] = { Name = "Wonder of U", Waves = { { Template = "Tooru", Flavor = "You shouldn't have pursued him. A calamity approaches." } } }
		},
		PrestigeMissions = {
			[1] = { Name = "Fun Fun Fun", Waves = { { Template = "Ojiro", Flavor = "You are ambushed in the apartment! Fun Fun Fun takes control." } } },
			[2] = { Name = "California King Bed", Waves = { { Template = "Daiya", Flavor = "You broke a rule. Daiya attempts to steal your memories." } } },
			[3] = { Name = "Paper Moon King", Waves = { { Template = "Tsurugi", Flavor = "Everything looks the same! An origami frog attacks!" } } },
			[4] = { Name = "I Am a Rock", Waves = { { Template = "Yotsuyu", Flavor = "A rock human surfaces! The architect attacks." } } },
			[5] = { Name = "Doobie Wah!", Waves = { { Template = "Aisho", Flavor = "A tornado chases your every breath. Survive!" } } },
			[6] = { Name = "Vitamin C", Waves = { { Template = "Damo", Flavor = "The room is melting. Tamaki Damo reveals himself!" } } },
			[7] = { Name = "Brain Storm", Waves = { { Template = "Urban", Flavor = "Cells pop like bubbles! The doctor strikes.", Ally = "Yasuho" } } },
			[8] = { Name = "Blue Hawaii", Waves = { { Template = "Dolomite", Flavor = "Zombies are relentlessly pursuing you. Find the source!" } } },
			[9] = { Name = "Speed King", Waves = { { Template = "Jobin", Flavor = "The temperature rises drastically. Jobin stands in your way." } } },
			[10] = { Name = "Wonder of U", Waves = { { Template = "Tooru", Flavor = "You shouldn't have pursued him. A calamity approaches." } } }
		}
	}
}

return EnemyData