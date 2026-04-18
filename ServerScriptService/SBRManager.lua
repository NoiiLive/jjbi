-- @ScriptType: Script
-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local SBRAction = Network:WaitForChild("SBRAction")
local SBRUpdate = Network:WaitForChild("SBRUpdate")

local cycleOffset = 0

local function GetSBRTime()
	return (math.floor(workspace:GetServerTimeNow()) + cycleOffset) % 3600
end

local function ScaleResource(val)
	if val <= 1000 then return val end
	return 1000 + math.floor((val - 1000) ^ 0.65 * 3)
end

local EventState = {
	IsActive = false,
	Queue = {},
	Racers = {},
	Winners = {},
	EndTime = 0
}

local Regions = {
	{Name = "San Diego Beach", End = 1000},
	{Name = "Arizona Desert", End = 3000},
	{Name = "Rocky Mountains", End = 5000},
	{Name = "Great Plains", End = 7000},
	{Name = "Chicago", End = 9000},
	{Name = "Philadelphia", End = 10000}
}

local Names1 = {
	"Silver","Black","Golden","Midnight","Red","White","Blue","Crimson","Azure","Onyx","Ivory","Ruby","Sapphire","Emerald","Bronze","Copper","Scarlet","Violet",
	"Fast","Swift","Rapid","Lightning","Thunder","Storm","Wild","Blazing","Flying","Charging","Raging","Dashing","Soaring",
	"Brave","Noble","Savage","Fierce","Proud","Grand","Royal","Legendary","Mighty","Valiant","Heroic","Fearless",
	"Fire","Ice","Frost","Solar","Lunar","Iron","Steel","Ghost","Mystic","Holy","Dark","Light","Radiant","Cursed","Blessed","Cosmic","Astral","Arcane","Ancient",
	"Dire","Great","Alpha","Prime","Stormborn","Sunset","Dawn","Dusk","Mountain","Desert","Prairie",
	"Big","Tiny","Massive","Heavy","Thicc","Mini","Giga","Maximum","Ultra","Mega",
	"Slow","Fat","Angry","Derpy","Lazy","Confused","Suspicious","Goofy","Unhinged","Greasy","Wobbly","Crusty","Spicy","Bald","Dank","Certified", "Stupid"
}

local Names2 = {
	"Stallion","Mustang","Bronco","Hoof","Trotter","Galloper","Racer","Trailblazer", "Dancer",
	"Bullet","Runner","Dasher","Sprinter","Chaser","Hunter","Striker","Blade","Arrow","Spear","Crusher","Breaker",
	"Eagle","Falcon","Hawk","Wolf","Tiger","Lion","Bear","Dragon","Cobra","Panther",
	"Comet","Meteor","Nova","Eclipse","Hurricane","Cyclone","Blizzard","Tornado","Storm","Tempest",
	"Knight","Rider","Champ","Hero","Legend","Master","King","Outlaw","Bandit","Marshal",
	"Valkyrie","Phantom","Specter","Wanderer","Drifter","Seeker","Spirit","Fury","Flash",
	"Boi","Unit","Potato","Nugget","Goblin","Meatball","Gremlin","Grandpa","Chungus","Mogger","Goober","Creature","Thing","Lad","Beast", "Idiot", "Chud", "Chad"
}

local SBRRobuxReroll = ReplicatedStorage:WaitForChild("SBRRobuxReroll")

local function RollHorseTrait()
	if math.random(1, 100) <= 60 then return "None" end
	local pool = {"Swift", "Sturdy", "Desert Walker", "Mountain Goat", "City Sprinter", "Lucky", "Enduring"}
	return pool[math.random(1, #pool)]
end

local function RerollHorseTrait(player)
	local newTrait = RollHorseTrait()
	player:SetAttribute("HorseTrait", newTrait)
	Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FFD700'>Horse trait rerolled into [" .. newTrait .. "]!</font>")
end

local function RerollHorseName(player)
	local newName = Names1[math.random(#Names1)] .. " " .. Names2[math.random(#Names2)]
	player:SetAttribute("HorseName", newName)
	Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FFD700'>Horse name rerolled to " .. newName .. "!</font>")
end

SBRRobuxReroll.Event:Connect(function(player)
	if player and player.Parent then
		RerollHorseName(player)
	end
end)

local function GetRegion(dist)
	for _, r in ipairs(Regions) do
		if dist < r.End then return r.Name end
	end
	return "Philadelphia"
end

local function HandleSBRDrop(player, dropCategory, excludeDiscs)
	local targetRarity = dropCategory

	if dropCategory == "Normal" then
		local rng = math.random(1, 100)
		if rng <= 5 then targetRarity = "Legendary"
		elseif rng <= 20 then targetRarity = "Rare"
		elseif rng <= 50 then targetRarity = "Uncommon"
		else targetRarity = "Common" end
	end

	local pool = {}
	for name, data in pairs(ItemData.Equipment) do 
		if data.Rarity == targetRarity then 
			if not (excludeDiscs and string.find(string.lower(name), "disc")) then
				table.insert(pool, name) 
			end
		end 
	end
	for name, data in pairs(ItemData.Consumables) do 
		if data.Rarity == targetRarity then 
			if not (excludeDiscs and string.find(string.lower(name), "disc")) then
				table.insert(pool, name) 
			end
		end 
	end

	if #pool > 0 then
		local itemName = pool[math.random(#pool)]
		local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
		local isIgnored = itemData and (itemData.Rarity == "Unique" or (ItemData.Consumables[itemName] and itemData.Category == "Stand"))

		if player:GetAttribute("AutoSell_" .. targetRarity) and not isIgnored then
			local sellVal = itemData and (itemData.SellPrice or math.floor((itemData.Cost or 50) / 2)) or 25
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Yen") then
				leaderstats.Yen.Value += sellVal
			end
			return itemName .. " <font color='#AAAAAA'>(Auto-Sold: ¥" .. sellVal .. ")</font>"
		else
			local currentInv = GameData.GetInventoryCount(player)
			local maxInv = GameData.GetMaxInventory(player)

			if isIgnored or currentInv < maxInv then
				local attr = itemName:gsub("[^%w]", "") .. "Count"
				player:SetAttribute(attr, (player:GetAttribute(attr) or 0) + 1)
				return itemName
			else
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Inventory Full! " .. itemName .. " was lost.</font>")
				return nil
			end
		end
	end
	return nil
end

local function EndEvent()
	EventState.IsActive = false
	EventState.Queue = {}

	for uid, racer in pairs(EventState.Racers) do
		if racer.Player and racer.Player.Parent then
			SBRUpdate:FireClient(racer.Player, "RaceEnded", EventState.Winners)
		end
	end

	EventState.Racers = {}
	EventState.Winners = {}
	Network.CombatUpdate:FireAllClients("SystemMessage", "<b><font color='#FFD700'>The Steel Ball Run has concluded!</font></b>")
end

local function CheckWinCondition(racer)
	if racer.Distance >= 10000 and not racer.HasFinished then
		racer.HasFinished = true
		table.insert(EventState.Winners, racer.Player.Name)
		local rank = #EventState.Winners

		if rank == 1 then
			racer.Player:SetAttribute("SBRWins", (racer.Player:GetAttribute("SBRWins") or 0) + 1)
		end

		local hName = racer.Player:GetAttribute("HorseName") or "Unknown Steed"
		Network.CombatUpdate:FireAllClients("SystemMessage", "<font color='#55FFFF'><b>" .. racer.Player.Name .. " and " .. hName .. " have finished the SBR race in " .. rank .. " Place!</b></font>")

		local yenReward = 0
		local rewardRarity = "None"
		local rewardQty = 1

		local totalPlayersInServer = #Players:GetPlayers()

		if totalPlayersInServer <= 5 then
			yenReward = rank == 1 and 10000000 or (rank == 2 and 5000000 or 1000000)
			rewardRarity = "Legendary Giftbox"
			rewardQty = 5
		elseif totalPlayersInServer <= 10 then
			yenReward = rank == 1 and 25000000 or (rank == 2 and 10000000 or 5000000)
			rewardRarity = "Mythical Giftbox"
			rewardQty = 1
		else
			yenReward = rank == 1 and 50000000 or (rank == 2 and 25000000 or 10000000)
			rewardRarity = "Mythical Giftbox"
			rewardQty = 1
		end

		local leaderstats = racer.Player:FindFirstChild("leaderstats")
		if leaderstats and leaderstats:FindFirstChild("Yen") then
			leaderstats.Yen.Value += yenReward
		end

		if rewardRarity ~= "None" then
			local attr = rewardRarity:gsub("[^%w]", "") .. "Count"
			racer.Player:SetAttribute(attr, (racer.Player:GetAttribute(attr) or 0) + rewardQty)
			Network.CombatUpdate:FireClient(racer.Player, "SystemMessage", "<font color='#FFD700'>You obtained " .. rewardQty .. "x " .. rewardRarity .. "!</font>")
		end

		SBRUpdate:FireClient(racer.Player, "Finished", rank)

		if #EventState.Winners >= 3 then
			EndEvent()
		end
	end
end

local function StartRace()
	EventState.IsActive = true
	EventState.Winners = {}
	EventState.EndTime = math.floor(workspace:GetServerTimeNow()) + 1800

	for _, player in ipairs(EventState.Queue) do
		if player and player.Parent then
			local speed = player:GetAttribute("HorseSpeed") or 1
			local endur = player:GetAttribute("HorseEndurance") or 1
			local maxStam = 100 + (endur * 2)

			EventState.Racers[player.UserId] = {
				Player = player, Distance = 0, MaxStamina = maxStam, Stamina = maxStam,
				HorseSpeed = speed, HorseEndurance = endur, IsProcessing = false,
				HorseTrait = player:GetAttribute("HorseTrait") or "None",
				HasFinished = false, Battle = nil, LastPathTime = 0
			}
			SBRUpdate:FireClient(player, "RaceStarted", {MaxStamina = maxStam, EndTime = EventState.EndTime})
		end
	end
	EventState.Queue = {}
end

Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	if not player.Parent then return end

	local hName = player:GetAttribute("HorseName")
	if not hName or hName == "" then
		player:SetAttribute("HorseName", Names1[math.random(#Names1)] .. " " .. Names2[math.random(#Names2)])
		player:SetAttribute("HorseSpeed", 1)
		player:SetAttribute("HorseEndurance", 1)
		player:SetAttribute("HorseTrait", RollHorseTrait())
	end

	local upgradeEnd = player:GetAttribute("HorseUpgradeEnd") or 0
	if upgradeEnd > 0 and math.floor(workspace:GetServerTimeNow()) >= upgradeEnd then
		local targetStat = player:GetAttribute("HorseUpgradeStat")
		if targetStat == "Speed" then player:SetAttribute("HorseSpeed", math.min(100, (player:GetAttribute("HorseSpeed") or 1) + 1))
		elseif targetStat == "Endurance" then player:SetAttribute("HorseEndurance", math.min(100, (player:GetAttribute("HorseEndurance") or 1) + 1)) end
		player:SetAttribute("HorseUpgradeEnd", 0); player:SetAttribute("HorseUpgradeStat", "None")
	end
end)

local hasSentWarning = false

task.spawn(function()
	while task.wait(1) do
		local cycleTime = GetSBRTime() 
		local shouldBeActive = (cycleTime < 1800)

		if cycleTime == 1740 and not hasSentWarning then
			hasSentWarning = true
			Network.CombatUpdate:FireAllClients("SystemMessage", "<b><font color='#FFAA00'>The Steel Ball Run Race will begin in 1 Minute!</font></b>")
		elseif cycleTime < 1740 then
			hasSentWarning = false
		end

		if shouldBeActive and not EventState.IsActive then StartRace()
		elseif not shouldBeActive and EventState.IsActive then EndEvent() end

		for _, player in ipairs(Players:GetPlayers()) do
			local upgradeEnd = player:GetAttribute("HorseUpgradeEnd") or 0
			if upgradeEnd > 0 and math.floor(workspace:GetServerTimeNow()) >= upgradeEnd then
				local targetStat = player:GetAttribute("HorseUpgradeStat")
				if targetStat == "Speed" then player:SetAttribute("HorseSpeed", math.min(100, (player:GetAttribute("HorseSpeed") or 1) + 1))
				elseif targetStat == "Endurance" then player:SetAttribute("HorseEndurance", math.min(100, (player:GetAttribute("HorseEndurance") or 1) + 1)) end
				player:SetAttribute("HorseUpgradeEnd", 0); player:SetAttribute("HorseUpgradeStat", "None")
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Horse " .. targetStat .. " upgrade complete!</font>")
			end
		end

		if EventState.IsActive then
			local checked = {}
			for uid, racer in pairs(EventState.Racers) do
				local b = racer.Battle
				if b and not checked[b] and b.TurnDeadline and math.floor(workspace:GetServerTimeNow()) >= b.TurnDeadline and not b.IsProcessing then
					checked[b] = true
					if b.OpponentRacer then
						checked[b.OpponentRacer.Battle] = true
						if not b.PlayerSelectedSkill then b.PlayerSelectedSkill = "Basic Attack" end
						if not b.OpponentRacer.Battle.PlayerSelectedSkill then b.OpponentRacer.Battle.PlayerSelectedSkill = "Basic Attack" end
						b.PlayerReady = true
						b.OpponentRacer.Battle.PlayerReady = true
					else
						if not b.PlayerSelectedSkill then b.PlayerSelectedSkill = "Basic Attack" end
					end
					task.defer(function() ExecuteCombatTurn(racer) end)
				end
			end
		end
	end
end)

local function GeneratePvEMob(player)
	local pMobs = EnemyData.Parts[7] and EnemyData.Parts[7].Mobs or EnemyData.Parts[1].Mobs
	local template = pMobs[math.random(#pMobs)]

	local prestige = player:FindFirstChild("leaderstats") and player.leaderstats.Prestige.Value or 0
	local pCapMult = 1 + (prestige * 0.10)

	local scaleHP = pCapMult * 0.35
	local scaleStr = pCapMult * 1.8
	local scaleDef = pCapMult * 0.3
	local scaleSpd = pCapMult * 0.6
	local scaleWill = pCapMult * 0.6

	local eHP = template.Health * scaleHP
	local calcStam = ScaleResource(150 + (eHP * 0.1))
	local calcNrg = ScaleResource(150 + (eHP * 0.1))

	return {
		IsPlayer = false, Name = template.Name, Trait = "None", IsBoss = false,
		HP = eHP, MaxHP = eHP,
		TotalStrength = template.Strength * scaleStr, TotalDefense = template.Defense * scaleDef,
		TotalSpeed = template.Speed * scaleSpd, TotalWillpower = template.Willpower * scaleWill,
		Stamina = calcStam, MaxStamina = calcStam,
		StandEnergy = calcNrg, MaxStandEnergy = calcNrg,
		TotalRange = 0, TotalPrecision = 0, BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { 
			Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, 
			Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, 
			Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0, 
			StaminaExhausted = 0, EnergyExhausted = 0, Dizzy = 0, Chilly = 0, 
			Acid = 0, Infection = 0, Rupture = 0, Frostburn = 0, Frostbite = 0, Decay = 0, 
			Blight = 0, Miasma = 0, Necrosis = 0, Plague = 0, Calamity = 0, Warded = 0 
		},
		Cooldowns = {}, Skills = template.Skills or {"Basic Attack"}
	}
end

local function FindPvPTarget(racer)
	local myRegion = GetRegion(racer.Distance)

	local valid = {}
	for uid, other in pairs(EventState.Racers) do
		if uid ~= racer.Player.UserId and not other.HasFinished and not other.Battle then
			local oPres = other.Player:FindFirstChild("leaderstats") and other.Player.leaderstats.Prestige.Value or 0
			if GetRegion(other.Distance) == myRegion then
				table.insert(valid, other)
			end
		end
	end
	if #valid > 0 then return valid[math.random(#valid)] end
	return nil
end

local function EliminateRacer(racer, reasonMsg)
	racer.HasFinished = true
	racer.Player:SetAttribute("InCombat", false)
	SBRUpdate:FireClient(racer.Player, "Eliminated", reasonMsg)
	EventState.Racers[racer.Player.UserId] = nil
end

function ExecuteCombatTurn(racer)
	local b = racer.Battle
	if b.IsProcessing then return end
	b.IsProcessing = true
	if b.OpponentRacer then b.OpponentRacer.Battle.IsProcessing = true end

	local p1SkillName = b.PlayerSelectedSkill
	local p2SkillName = b.OpponentRacer and b.OpponentRacer.Battle.PlayerSelectedSkill or CombatCore.ChooseAISkill(b.Enemy)

	local uniModStr = racer.Player:GetAttribute("UniverseModifier") or "None"

	local p1Fled = (p1SkillName == "Flee")
	local p2Fled = (p2SkillName == "Flee")

	if p1Fled or p2Fled then
		if p1Fled then
			racer.Distance = math.max(0, racer.Distance - 1000)
			SBRUpdate:FireClient(racer.Player, "CombatEnd", "You fled the battle and lost 800m!")
		else
			local gain = b.OpponentRacer and 500 or 150
			racer.Distance = racer.Distance + gain
			SBRUpdate:FireClient(racer.Player, "CombatEnd", "Your opponent fled! You pushed forward and gained " .. gain .. "m.")
		end
		racer.Player:SetAttribute("InCombat", false)

		if b.OpponentRacer then
			if p2Fled then
				b.OpponentRacer.Distance = math.max(0, b.OpponentRacer.Distance - 1000)
				SBRUpdate:FireClient(b.OpponentRacer.Player, "CombatEnd", "You fled the battle and lost 800m!")
			else
				local gain = 500
				b.OpponentRacer.Distance = b.OpponentRacer.Distance + gain
				SBRUpdate:FireClient(b.OpponentRacer.Player, "CombatEnd", "Your opponent fled! You pushed forward and gained " .. gain .. "m.")
			end
			b.OpponentRacer.Player:SetAttribute("InCombat", false)
			SBRUpdate:FireClient(b.OpponentRacer.Player, "PathResult", {Log = "", Dist = b.OpponentRacer.Distance, Stam = b.OpponentRacer.Stamina, Region = GetRegion(b.OpponentRacer.Distance)})
			b.OpponentRacer.Battle = nil
			CheckWinCondition(b.OpponentRacer)
		end

		racer.Battle = nil
		SBRUpdate:FireClient(racer.Player, "PathResult", {Log = "", Dist = racer.Distance, Stam = racer.Stamina, Region = GetRegion(racer.Distance)})
		CheckWinCondition(racer)
		return
	end

	local p1Skill = SkillData.Skills[p1SkillName]
	local p2Skill = SkillData.Skills[p2SkillName]

	local stamCost1, nrgCost1 = p1Skill and p1Skill.StaminaCost or 0, p1Skill and p1Skill.EnergyCost or 0
	local stamCost2, nrgCost2 = p2Skill and p2Skill.StaminaCost or 0, p2Skill and p2Skill.EnergyCost or 0

	if p1Skill then
		if CombatCore.HasModifier(uniModStr, "Speed of Light") then stamCost1 *= 1.5; nrgCost1 *= 1.5 end
		if CombatCore.HasModifier(uniModStr, "Endless Stamina") then stamCost1 *= 0.5; nrgCost1 *= 0.5 end
		b.Player.Stamina = math.max(0, b.Player.Stamina - stamCost1)
		b.Player.StandEnergy = math.max(0, b.Player.StandEnergy - nrgCost1)
		if b.Player.Cooldowns then b.Player.Cooldowns[p1SkillName] = p1Skill.Cooldown or 0 end
	end

	if p2Skill then
		if b.OpponentRacer then
			local uniModStr2 = b.OpponentRacer.Player:GetAttribute("UniverseModifier") or "None"
			if CombatCore.HasModifier(uniModStr2, "Speed of Light") then stamCost2 *= 1.5; nrgCost2 *= 1.5 end
			if CombatCore.HasModifier(uniModStr2, "Endless Stamina") then stamCost2 *= 0.5; nrgCost2 *= 0.5 end
			b.Enemy.Stamina = math.max(0, b.Enemy.Stamina - stamCost2)
			b.Enemy.StandEnergy = math.max(0, b.Enemy.StandEnergy - nrgCost2)
		end
		if b.Enemy.Cooldowns then b.Enemy.Cooldowns[p2SkillName] = p2Skill.Cooldown or 0 end
	end

	local waitMultiplier = 0.8
	local function Dispatch(atk, def, skName)
		if atk.HP <= 0 or def.HP <= 0 then return end
		local s, msg, hit, shake = pcall(function() 
			return CombatCore.ExecuteStrike(atk, def, skName, "None", atk.Name, def.Name, atk.IsPlayer and "#FFFFFF" or "#FF5555", def.IsPlayer and "#FFFFFF" or "#FF5555") 
		end)

		if s then
			SBRUpdate:FireClient(racer.Player, "CombatTurn", {LogMsg = msg, ShakeType = shake, P1 = b.Player, P2 = b.Enemy, DidHit = hit, Deadline = b.TurnDeadline})
			if b.OpponentRacer then 
				SBRUpdate:FireClient(b.OpponentRacer.Player, "CombatTurn", {LogMsg = msg, ShakeType = shake, P1 = b.Enemy, P2 = b.Player, DidHit = hit, Deadline = b.TurnDeadline}) 
			end
			task.wait(waitMultiplier)
		else
			warn("SBR Combat Error:", msg)
			local errMsg = "<font color='#FF5555'>[Combat Error] " .. atk.Name .. "'s attack failed.</font>"
			SBRUpdate:FireClient(racer.Player, "CombatTurn", {LogMsg = errMsg, ShakeType = "None", P1 = b.Player, P2 = b.Enemy, DidHit = false, Deadline = b.TurnDeadline})
			if b.OpponentRacer then 
				SBRUpdate:FireClient(b.OpponentRacer.Player, "CombatTurn", {LogMsg = errMsg, ShakeType = "None", P1 = b.Enemy, P2 = b.Player, DidHit = false, Deadline = b.TurnDeadline}) 
			end
			task.wait(waitMultiplier)
		end
	end

	local combatants = {b.Player, b.Enemy}
	table.sort(combatants, function(x, y) return (x.TotalSpeed or 1) > (y.TotalSpeed or 1) end)

	for _, c in ipairs(combatants) do
		if b.Player.HP < 1 or b.Enemy.HP < 1 then break end
		if c.HP < 1 then continue end

		if c.Cooldowns then for sName, cd in pairs(c.Cooldowns) do if cd > 0 then c.Cooldowns[sName] = cd - 1 end end end

		for sName, sVal in pairs(c.Statuses) do 
			if (string.sub(sName, 1, 5) == "Buff_" or string.sub(sName, 1, 7) == "Debuff_" or string.find(sName, "Exhausted") or sName == "Dizzy" or sName == "Warded") and sVal > 0 then 
				c.Statuses[sName] = sVal - 1 
			end 
		end
		if c.StunImmunity > 0 then c.StunImmunity -= 1 end; if c.ConfusionImmunity > 0 then c.ConfusionImmunity -= 1 end
		if c.BlockTurns > 0 then c.BlockTurns -= 1 end
		if c.CounterTurns then c.CounterTurns = math.max(0, c.CounterTurns - 1) end

		local dummyRemote = { FireClient = function(_, plr, ev, data) 
			SBRUpdate:FireClient(plr, "CombatTurn", {LogMsg = data.LogMsg, P1 = b.Player, P2 = b.Enemy, DidHit = data.DidHit, ShakeType = data.ShakeType, Deadline = b.TurnDeadline})
			if b.OpponentRacer then
				SBRUpdate:FireClient(b.OpponentRacer.Player, "CombatTurn", {LogMsg = data.LogMsg, P1 = b.Enemy, P2 = b.Player, DidHit = data.DidHit, ShakeType = data.ShakeType, Deadline = b.TurnDeadline})
			end
		end}

		local fz = CombatCore.ApplyStatusDamage(c, "None", dummyRemote, racer.Player, b, 0)
		if fz == "Frozen" then continue end
		if c.HP < 1 then continue end

		if c.Statuses.Stun > 0 then
			c.Statuses.Stun -= 1
			if c.IsPlayer and not CombatCore.HasModifier(uniModStr, "Endless Stamina") then
				c.Stamina = math.min(c.MaxStamina, c.Stamina + 5)
				c.StandEnergy = math.min(c.MaxStandEnergy, c.StandEnergy + 5)
			end
			local stMsg = "<font color='#AAAAAA'>"..c.Name.." is Stunned and cannot move!</font>"
			dummyRemote:FireClient(racer.Player, "CombatTurn", {LogMsg = stMsg, DidHit = false, ShakeType = "None"})
			continue
		end

		if c == b.Player then 
			Dispatch(b.Player, b.Enemy, p1SkillName)
		else 
			Dispatch(b.Enemy, b.Player, p2SkillName) 
		end
	end

	if b.Player.HP < 1 then
		EliminateRacer(racer, "Defeated in Combat!")
		if b.OpponentRacer then
			b.OpponentRacer.Distance += 1500
			b.OpponentRacer.Battle = nil
			b.OpponentRacer.Player:SetAttribute("InCombat", false)
			SBRUpdate:FireClient(b.OpponentRacer.Player, "CombatEnd", "You survived the ambush and eliminated your opponent! Pushing forward 1500m.")
			CheckWinCondition(b.OpponentRacer)
		end
	elseif b.Enemy.HP < 1 then
		local gain = b.OpponentRacer and 1500 or 800
		racer.Distance += gain
		racer.Battle = nil
		racer.Player:SetAttribute("InCombat", false)
		SBRUpdate:FireClient(racer.Player, "CombatEnd", "Victory! You defeated the enemy and pushed forward " .. gain .. "m.")
		CheckWinCondition(racer)
		if b.OpponentRacer then EliminateRacer(b.OpponentRacer, "Defeated in Combat!") end
	else
		if p1Skill and (p1Skill.StaminaCost or 0) == 0 and not CombatCore.HasModifier(uniModStr, "Endless Stamina") then b.Player.Stamina = math.min(b.Player.MaxStamina, b.Player.Stamina + 5) end
		if p1Skill and (p1Skill.EnergyCost or 0) == 0 and not CombatCore.HasModifier(uniModStr, "Endless Stamina") then b.Player.StandEnergy = math.min(b.Player.MaxStandEnergy, b.Player.StandEnergy + 5) end
		local p1VigCount = CombatCore.CountTrait(b.Player, "Vigorous")
		if p1VigCount > 0 then b.Player.Stamina = math.min(b.Player.MaxStamina, b.Player.Stamina + (10 * p1VigCount)); b.Player.StandEnergy = math.min(b.Player.MaxStandEnergy, b.Player.StandEnergy + (10 * p1VigCount)) end

		b.PlayerReady = false
		b.PlayerSelectedSkill = nil
		b.IsProcessing = false
		b.TurnDeadline = math.floor(workspace:GetServerTimeNow()) + 5

		if b.OpponentRacer then
			local uniModStr2 = b.OpponentRacer.Player:GetAttribute("UniverseModifier") or "None"
			if p2Skill and (p2Skill.StaminaCost or 0) == 0 and not CombatCore.HasModifier(uniModStr2, "Endless Stamina") then b.Enemy.Stamina = math.min(b.Enemy.MaxStamina, b.Enemy.Stamina + 5) end
			if p2Skill and (p2Skill.EnergyCost or 0) == 0 and not CombatCore.HasModifier(uniModStr2, "Endless Stamina") then b.Enemy.StandEnergy = math.min(b.Enemy.MaxStandEnergy, b.Enemy.StandEnergy + 5) end
			local p2VigCount = CombatCore.CountTrait(b.Enemy, "Vigorous")
			if p2VigCount > 0 then b.Enemy.Stamina = math.min(b.Enemy.MaxStamina, b.Enemy.Stamina + (10 * p2VigCount)); b.Enemy.StandEnergy = math.min(b.Enemy.MaxStandEnergy, b.Enemy.StandEnergy + (10 * p2VigCount)) end

			b.OpponentRacer.Battle.PlayerReady = false 
			b.OpponentRacer.Battle.PlayerSelectedSkill = nil
			b.OpponentRacer.Battle.IsProcessing = false
			b.OpponentRacer.Battle.TurnDeadline = b.TurnDeadline
		end

		SBRUpdate:FireClient(racer.Player, "CombatUpdateState", {P1 = b.Player, P2 = b.Enemy, Deadline = b.TurnDeadline})
		if b.OpponentRacer then SBRUpdate:FireClient(b.OpponentRacer.Player, "CombatUpdateState", {P1 = b.Enemy, P2 = b.Player, Deadline = b.TurnDeadline}) end
	end
end

SBRAction.OnServerEvent:Connect(function(player, action, data)
	if action == "RequestSync" then
		SBRUpdate:FireClient(player, "SyncTimer", GetSBRTime())

	elseif action == "SetHorseName" then
		if not player:GetAttribute("HasHorseNamePass") then return end
		if type(data) == "table" and data.Name1 and data.Name2 then
			if table.find(Names1, data.Name1) and table.find(Names2, data.Name2) then
				local newName = data.Name1 .. " " .. data.Name2
				player:SetAttribute("HorseName", newName)
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Horse name updated to " .. newName .. "!</font>")
			end
		end

	elseif action == "RerollHorseYen" then
		local yenObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Yen")
		if not yenObj or yenObj.Value < 1000000 then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Not enough Yen! (Costs 1,000,000)</font>")
			return
		end
		yenObj.Value -= 1000000
		RerollHorseTrait(player)

	elseif action == "UpgradeHorse" then
		local yenObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Yen")
		if not yenObj or yenObj.Value < 100000 then 
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Not enough Yen! (Costs 100,000)</font>")
			return 
		end
		local currentLevel = player:GetAttribute("Horse" .. data) or 1
		if currentLevel >= 100 then 
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Horse " .. data .. " is already maxed!</font>")
			return 
		end
		if (player:GetAttribute("HorseUpgradeEnd") or 0) > math.floor(workspace:GetServerTimeNow()) then 
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Your horse is already undergoing training!</font>")
			return 
		end

		yenObj.Value -= 100000
		player:SetAttribute("HorseUpgradeStat", data)
		player:SetAttribute("HorseUpgradeEnd", math.floor(workspace:GetServerTimeNow()) + 300)
		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>Started upgrading Horse " .. data .. "! Takes 5 minutes.</font>")

	elseif action == "ToggleQueue" then
		if EventState.IsActive then 
			if game:GetService("RunService"):IsStudio() then
				local speed = player:GetAttribute("HorseSpeed") or 1
				local endur = player:GetAttribute("HorseEndurance") or 1
				local maxStam = 100 + (endur * 2)

				EventState.Racers[player.UserId] = {
					Player = player, Distance = 0, MaxStamina = maxStam, Stamina = maxStam,
					HorseSpeed = speed, HorseEndurance = endur, IsProcessing = false,
					HorseTrait = player:GetAttribute("HorseTrait") or "None",
					HasFinished = false, Battle = nil, LastPathTime = 0
				}
				SBRUpdate:FireClient(player, "RaceStarted", {MaxStamina = maxStam, EndTime = EventState.EndTime})
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#55FF55'>[STUDIO] Force-joined active race!</font>")
				return
			else
				Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>The race is already running!</font>")
				return 
			end
		end

		local inQueue = false
		for i, p in ipairs(EventState.Queue) do
			if p == player then table.remove(EventState.Queue, i); inQueue = true; break end
		end
		if not inQueue then table.insert(EventState.Queue, player) end
		SBRUpdate:FireAllClients("SyncQueue", #EventState.Queue)

	elseif action == "ForceStartEvent" then
		if game:GetService("RunService"):IsStudio() then
			cycleOffset = -(math.floor(workspace:GetServerTimeNow()) % 3600)
			SBRUpdate:FireAllClients("SyncTimer", GetSBRTime())
		end

	elseif action == "TakePath" then
		local r = EventState.Racers[player.UserId]
		if not r then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>You are not currently in the active race.</font>")
			return
		end
		if r.HasFinished or r.Battle or r.IsProcessing then return end

		if math.floor(workspace:GetServerTimeNow()) - r.LastPathTime < 1 then
			return
		end

		r.IsProcessing = true
		r.LastPathTime = math.floor(workspace:GetServerTimeNow())

		local path = data
		local logStr = ""
		local distGained = 0

		local region = GetRegion(r.Distance)
		local trait = r.HorseTrait or "None"

		if path == "Safe" then
			local cost = math.max(2, 5 - (r.HorseEndurance * 0.02))
			if trait == "Sturdy" then cost = math.max(1, cost - 1) end

			if r.Stamina < cost then 
				logStr = "<font color='#FF5555'>Not enough stamina! You must rest.</font>"
				r.IsProcessing = false
				SBRUpdate:FireClient(player, "PathResult", {Log = logStr, Dist = r.Distance, Stam = r.Stamina, Region = region})
				return 
			end

			r.Stamina -= cost

			local baseDist = math.floor(20 + (r.HorseSpeed * 0.80))
			local dMult = 1.0
			if trait == "Swift" then dMult += 0.15 end
			if trait == "Desert Walker" and region == "Arizona Desert" then dMult += 0.3 end
			if trait == "Mountain Goat" and region == "Rocky Mountains" then dMult += 0.3 end
			if trait == "City Sprinter" and (region == "Chicago" or region == "Philadelphia") then dMult += 0.3 end

			local rng = math.random(1, 100)
			if trait == "Lucky" then rng = rng + 10 end

			if rng <= 10 then
				distGained = math.floor((100 + (r.HorseSpeed * 1)) * dMult)
				r.Distance += distGained
				logStr = "<font color='#55FF55'>Your horse found a smooth trail! Rode safely for " .. distGained .. "m.</font>"
			elseif rng <= 20 then
				distGained = math.floor(baseDist * dMult)
				r.Distance += distGained
				local i = HandleSBRDrop(player, "Normal", false)
				logStr = "Rode safely for " .. distGained .. "m."
				if i then logStr = logStr .. " Found " .. i .. "!" end
			elseif rng <= 25 then
				distGained = math.floor(baseDist * dMult)
				local p2 = FindPvPTarget(r)
				if p2 then
					r.Distance += distGained
					r.Battle = { Player = CombatCore.BuildPlayerStruct(player, false), Enemy = CombatCore.BuildPlayerStruct(p2.Player, false), OpponentRacer = p2, PlayerReady = false, IsProcessing = false, PlayerSelectedSkill = nil, TurnDeadline = math.floor(workspace:GetServerTimeNow()) + 15 }
					p2.Battle = { Player = r.Battle.Enemy, Enemy = r.Battle.Player, OpponentRacer = r, PlayerReady = false, IsProcessing = false, PlayerSelectedSkill = nil, TurnDeadline = math.floor(workspace:GetServerTimeNow()) + 15 }
					player:SetAttribute("InCombat", true)
					p2.Player:SetAttribute("InCombat", true)
					SBRUpdate:FireClient(player, "CombatStart", {LogMsg = "<font color='#FF5555'>AMBUSHED BY " .. p2.Player.Name .. "!</font>", P1 = r.Battle.Player, P2 = r.Battle.Enemy, Deadline = r.Battle.TurnDeadline})
					SBRUpdate:FireClient(p2.Player, "CombatStart", {LogMsg = "<font color='#FF5555'>YOU AMBUSHED " .. player.Name .. "!</font>", P1 = p2.Battle.Player, P2 = p2.Battle.Enemy, Deadline = p2.Battle.TurnDeadline})
					r.IsProcessing = false
					return
				else
					r.Distance += distGained
					logStr = "Rode safely for " .. distGained .. "m."
				end
			else
				distGained = math.floor(baseDist * dMult)
				r.Distance += distGained
				logStr = "Rode safely for " .. distGained .. "m."
			end

		elseif path == "Rest" then
			local recov = math.floor(30 + (r.HorseEndurance * 0.3))
			if trait == "Enduring" then recov = math.floor(recov * 1.3) end

			r.Stamina = math.min(r.MaxStamina, r.Stamina + recov)
			logStr = "<font color='#55FF55'>Rested and recovered " .. recov .. " Stamina.</font>"

			if math.random() <= 0.1 then
				local p2 = FindPvPTarget(r)
				if p2 then
					r.Battle = { Player = CombatCore.BuildPlayerStruct(player, false), Enemy = CombatCore.BuildPlayerStruct(p2.Player, false), OpponentRacer = p2, PlayerReady = false, IsProcessing = false, PlayerSelectedSkill = nil, TurnDeadline = math.floor(workspace:GetServerTimeNow()) + 15 }
					p2.Battle = { Player = r.Battle.Enemy, Enemy = r.Battle.Player, OpponentRacer = r, PlayerReady = false, IsProcessing = false, PlayerSelectedSkill = nil, TurnDeadline = math.floor(workspace:GetServerTimeNow()) + 15 }
					player:SetAttribute("InCombat", true)
					p2.Player:SetAttribute("InCombat", true)
					SBRUpdate:FireClient(player, "CombatStart", {LogMsg = "<font color='#FF5555'>AMBUSHED BY " .. p2.Player.Name .. "!</font>", P1 = r.Battle.Player, P2 = r.Battle.Enemy, Deadline = r.Battle.TurnDeadline})
					SBRUpdate:FireClient(p2.Player, "CombatStart", {LogMsg = "<font color='#FF5555'>YOU AMBUSHED " .. player.Name .. "!</font>", P1 = p2.Battle.Player, P2 = p2.Battle.Enemy, Deadline = p2.Battle.TurnDeadline})
					r.IsProcessing = false
					return
				end
			end

		elseif path == "Risky" then
			local cost = math.max(5, 15 - (r.HorseEndurance * 0.05))
			if trait == "Sturdy" then cost = math.max(1, cost - 1) end

			if r.Stamina < cost then 
				logStr = "<font color='#FF5555'>Not enough stamina! You must rest.</font>"
				r.IsProcessing = false
				SBRUpdate:FireClient(player, "PathResult", {Log = logStr, Dist = r.Distance, Stam = r.Stamina, Region = region})
				return 
			end

			r.Stamina -= cost

			distGained = math.floor(100 + (r.HorseSpeed * 2))

			local dMult = 1.0
			if trait == "Swift" then dMult += 0.15 end
			if trait == "Desert Walker" and region == "Arizona Desert" then dMult += 0.3 end
			if trait == "Mountain Goat" and region == "Rocky Mountains" then dMult += 0.3 end
			if trait == "City Sprinter" and (region == "Chicago" or region == "Philadelphia") then dMult += 0.3 end
			distGained = math.floor(distGained * dMult)

			local rng = math.random(1, 100)
			if trait == "Lucky" then rng = rng + 15 end 

			if rng <= 20 then
				local distLoss = math.random(50, 150)
				r.Distance = math.max(0, r.Distance + (distGained - distLoss))
				logStr = "<font color='#FFAA00'>Rough terrain! Lost time (" .. (distGained - distLoss) .. "m gained).</font>"
			elseif rng <= 45 then
				local i = HandleSBRDrop(player, "Normal", false)
				r.Distance += distGained
				logStr = "<font color='#55FFFF'>Rode hard for " .. distGained .. "m and found " .. (i or "something") .. "!</font>"
			elseif rng <= 60 then
				r.Distance += distGained
				r.Battle = { Player = CombatCore.BuildPlayerStruct(player, true), Enemy = GeneratePvEMob(player), OpponentRacer = nil, PlayerReady = false, IsProcessing = false, PlayerSelectedSkill = nil, TurnDeadline = math.floor(workspace:GetServerTimeNow()) + 15 }
				player:SetAttribute("InCombat", true)
				SBRUpdate:FireClient(player, "CombatStart", {LogMsg = "<font color='#FF5555'>A bandit blocks the path!</font>", P1 = r.Battle.Player, P2 = r.Battle.Enemy, Deadline = r.Battle.TurnDeadline})
				r.IsProcessing = false
				return
			elseif rng <= 70 then
				local p2 = FindPvPTarget(r)
				if p2 then
					r.Distance += distGained
					r.Battle = { Player = CombatCore.BuildPlayerStruct(player, false), Enemy = CombatCore.BuildPlayerStruct(p2.Player, false), OpponentRacer = p2, PlayerReady = false, IsProcessing = false, PlayerSelectedSkill = nil, TurnDeadline = math.floor(workspace:GetServerTimeNow()) + 15 }
					p2.Battle = { Player = r.Battle.Enemy, Enemy = r.Battle.Player, OpponentRacer = r, PlayerReady = false, IsProcessing = false, PlayerSelectedSkill = nil, TurnDeadline = math.floor(workspace:GetServerTimeNow()) + 15 }
					player:SetAttribute("InCombat", true)
					p2.Player:SetAttribute("InCombat", true)
					SBRUpdate:FireClient(player, "CombatStart", {LogMsg = "<font color='#FF5555'>CROSSED PATHS WITH " .. p2.Player.Name .. "!</font>", P1 = r.Battle.Player, P2 = r.Battle.Enemy, Deadline = r.Battle.TurnDeadline})
					SBRUpdate:FireClient(p2.Player, "CombatStart", {LogMsg = "<font color='#FF5555'>" .. player.Name .. " ATTACKED YOU!</font>", P1 = p2.Battle.Player, P2 = p2.Battle.Enemy, Deadline = p2.Battle.TurnDeadline})
					r.IsProcessing = false
					return
				else
					r.Distance += distGained
					logStr = "Rode fiercely for " .. distGained .. "m."
				end
			else
				r.Distance += distGained
				logStr = "Rode fiercely for " .. distGained .. "m."
			end
		end

		r.IsProcessing = false
		SBRUpdate:FireClient(player, "PathResult", {Log = logStr, Dist = r.Distance, Stam = r.Stamina, Region = GetRegion(r.Distance)})
		CheckWinCondition(r)

	elseif action == "CombatAttack" then
		local r = EventState.Racers[player.UserId]
		if r and r.Battle and not r.Battle.IsProcessing and not r.Battle.PlayerSelectedSkill then
			if not table.find(r.Battle.Player.Skills, data) then return end

			r.Battle.PlayerSelectedSkill = data
			if r.Battle.OpponentRacer then
				r.Battle.PlayerReady = true
				if r.Battle.OpponentRacer.Battle.PlayerReady then ExecuteCombatTurn(r) end
			else
				ExecuteCombatTurn(r)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	for i, p in ipairs(EventState.Queue) do if p == player then table.remove(EventState.Queue, i); break end end
	if EventState.Racers[player.UserId] then
		local r = EventState.Racers[player.UserId]
		if r.Battle and r.Battle.OpponentRacer then
			r.Battle.OpponentRacer.Battle = nil
			r.Battle.OpponentRacer.Player:SetAttribute("InCombat", false)
			SBRUpdate:FireClient(r.Battle.OpponentRacer.Player, "CombatEnd", "Opponent disconnected! Path is clear.")
		end
		EventState.Racers[player.UserId] = nil
	end
	player:SetAttribute("InCombat", false)
end)