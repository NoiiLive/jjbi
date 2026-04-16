-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local DungeonAction = Network:WaitForChild("DungeonAction")
local DungeonUpdate = Network:WaitForChild("DungeonUpdate")

local ActiveDungeons = {}

local EndlessPool = {}
for p = 1, 6 do
	if EnemyData.Parts[p] then
		if EnemyData.Parts[p].Templates then for _, t in pairs(EnemyData.Parts[p].Templates) do table.insert(EndlessPool, t) end end
		if EnemyData.Parts[p].Mobs then for _, m in pairs(EnemyData.Parts[p].Mobs) do table.insert(EndlessPool, m) end end
	end
end

local AllStandNames = {}
for standName, _ in pairs(StandData.Stands) do
	if standName ~= "Fused Stand" then
		table.insert(AllStandNames, standName)
	end
end

local AllTraitNames = {}
for traitName, _ in pairs(StandData.Traits) do
	if traitName ~= "None" then
		table.insert(AllTraitNames, traitName)
	end
end

local function GenerateDungeonEnemy(template, dungeonId)
	local fixedPrestige = tonumber(dungeonId) and (tonumber(dungeonId) + 9) or 10
	local scaleMult = 1 + (fixedPrestige * 0.10)
	local minorScaleMult = 1 + ((scaleMult - 1) * 0.33) 

	local eHP = template.Health * scaleMult
	local eStr = (template.Strength + (GameData.StandRanks[template.StandStats.Power] or 0)) * scaleMult
	local eDef = (template.Defense + (GameData.StandRanks[template.StandStats.Durability] or 0)) * scaleMult
	local eSpd = (template.Speed + (GameData.StandRanks[template.StandStats.Speed] or 0)) * minorScaleMult

	local dYen = math.floor((template.Drops and template.Drops.Yen or 0) * scaleMult)
	local dXP = math.floor((template.Drops and template.Drops.XP or 0) * scaleMult)

	return {
		IsPlayer = false, Name = template.Name, Icon = template.Icon or "", Trait = "None",
		IsBoss = template.IsBoss or false,
		HP = eHP, MaxHP = eHP, TotalStrength = eStr, TotalDefense = eDef, TotalSpeed = eSpd,
		TotalWillpower = (template.Willpower or 1) * minorScaleMult,
		Stamina = 150 + (eHP * 0.1), MaxStamina = 150 + (eHP * 0.1),
		StandEnergy = 150 + (eHP * 0.1), MaxStandEnergy = 150 + (eHP * 0.1),
		TotalRange = (GameData.StandRanks[template.StandStats.Range] or 0),
		TotalPrecision = (GameData.StandRanks[template.StandStats.Precision] or 0),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { 
			Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, 
			Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, 
			Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0,
			StaminaExhausted = 0, EnergyExhausted = 0, Dizzy = 0, Chilly = 0,
			Acid = 0, Infection = 0, Rupture = 0, Frostburn = 0, Frostbite = 0, Decay = 0,
			Blight = 0, Miasma = 0, Necrosis = 0, Plague = 0, Calamity = 0, Warded = 0 
		},
		Cooldowns = {}, Skills = template.Skills or {"Basic Attack"},
		RawDrops = { Yen = dYen, XP = dXP, ItemChance = template.Drops and template.Drops.ItemChance or {} }
	}
end

local function GenerateRandomEndlessEnemy(floor)
	local FirstNames = {
		"Crazed", "Menacing", "Wandering", "Furious", "Stoic", "Bizarre", "Ruthless", "Phantom", "Savage", "Silent",
		"Angry", "Cold", "Wild", "Calm", "Serious", "Rough", "Sharp", "Loud", "Quiet", "Fast",
		"Slow", "Dirty", "Clean", "Bloody", "Scarred", "Tough", "Slick", "Lazy", "Focused", "Nervous",
		"Shady", "Suspicious", "Unknown", "Strange", "Odd", "Weird", "Unlucky", "Lucky", "Fearless", "Reckless",
		"Brutal", "Harsh", "Mean", "Proud", "Greedy", "Desperate", "Broken", "Lost", "Lone", "Masked",
		"Street", "Backstreet", "Downtown", "Night", "Late-Night", "Early", "Noisy", "Restless"
	}

	local LastNames = {
		"Thug", "Brawler", "Stand User", "Delinquent", "Fighter", "Vampire", "Warrior", "Assassin", "Mercenary",
		"Gangster", "Punk", "Hoodlum", "Enforcer", "Hitman", "Bodyguard", "Outlaw", "Criminal", "Troublemaker",
		"Gunman", "Street Fighter", "Boxer", "Berserker", "Bruiser",
		"Stand User", "Stand Fighter", "Ability User",
		"Dealer", "Smuggler", "Fixer", "Informant", "Driver", "Guard", "Lookout",
		"Snitch", "Traitor", "Liar", "Cheater", "Gambler",
	}

	local Styles = {"None"}
	for styleName, _ in pairs(GameData.StyleBonuses) do table.insert(Styles, styleName) end

	local isBossFloor = (floor % 10 == 0)
	local eName = FirstNames[math.random(#FirstNames)] .. " " .. LastNames[math.random(#LastNames)]
	if isBossFloor then eName = "Floor " .. floor .. " Guardian" end

	local hasStand = false
	local isFused = false

	if floor >= 250 then
		hasStand = true
		isFused = true
	elseif floor >= 100 then
		hasStand = math.random(1, 100) <= 80
		local fusionChance = math.floor(((floor - 100) / 150) * 100)
		if math.random(1, 100) <= fusionChance then
			isFused = true
			hasStand = true
		end
	elseif floor >= 50 then
		hasStand = math.random(1, 100) <= 70
	end

	local eStand = "None"
	local eStand1 = "None"
	local eStand2 = "None"
	local eTrait = "None"
	local eTrait2 = "None"

	local traitChance = math.clamp((floor / 250) * 100, 0, 100)

	if hasStand then
		if isFused then
			eStand1 = AllStandNames[math.random(1, #AllStandNames)]
			eStand2 = AllStandNames[math.random(1, #AllStandNames)]
			while eStand1 == eStand2 do eStand2 = AllStandNames[math.random(1, #AllStandNames)] end

			if math.random(1, 100) <= traitChance then eTrait = AllTraitNames[math.random(1, #AllTraitNames)] end
			if math.random(1, 100) <= traitChance then eTrait2 = AllTraitNames[math.random(1, #AllTraitNames)] end
		else
			eStand = AllStandNames[math.random(1, #AllStandNames)]

			if math.random(1, 100) <= traitChance then eTrait = AllTraitNames[math.random(1, #AllTraitNames)] end
		end
	end

	local eStyle = Styles[math.random(#Styles)]

	local standardScale = (math.floor(1 + (floor/10))) * 0.3
	local utilityScale = (math.floor(1 + (floor/10))) * 0.05

	local bHP, bStr, bDef, bSpd, bWill = math.random(250, 2000), math.random(15, 150), math.random(10, 100), math.random(15, 150), math.random(10, 100)
	local standPower, standSpeed, standDur, standRan, standPre = "None", "None", "None", "None", "None"

	if hasStand then
		if isFused then
			local s1Stats = StandData.Stands[eStand1] and StandData.Stands[eStand1].Stats or {Power="None", Speed="None", Durability="None", Range="None", Precision="None"}
			local s2Stats = StandData.Stands[eStand2] and StandData.Stands[eStand2].Stats or {Power="None", Speed="None", Durability="None", Range="None", Precision="None"}

			local function getRankVal(rank) return GameData.StandRanks[rank] or 0 end
			local function getBestRank(r1, r2)
				if getRankVal(r1) > getRankVal(r2) then return r1 else return r2 end
			end

			standPower = getBestRank(s1Stats.Power, s2Stats.Power)
			standSpeed = getBestRank(s1Stats.Speed, s2Stats.Speed)
			standDur = getBestRank(s1Stats.Durability, s2Stats.Durability)
			standRan = getBestRank(s1Stats.Range, s2Stats.Range)
			standPre = getBestRank(s1Stats.Precision, s2Stats.Precision)

			bStr += math.floor((getRankVal(s1Stats.Power) + getRankVal(s2Stats.Power)) * 0.75)
			bSpd += math.floor((getRankVal(s1Stats.Speed) + getRankVal(s2Stats.Speed)) * 0.75)
			bDef += math.floor((getRankVal(s1Stats.Durability) + getRankVal(s2Stats.Durability)) * 0.75)
		else
			if StandData.Stands[eStand] then
				local sStats = StandData.Stands[eStand].Stats
				standPower, standSpeed, standDur, standRan, standPre = sStats.Power, sStats.Speed, sStats.Durability, sStats.Range, sStats.Precision
				bStr += GameData.StandRanks[sStats.Power] or 0
				bSpd += GameData.StandRanks[sStats.Speed] or 0
				bDef += GameData.StandRanks[sStats.Durability] or 0
			end
		end
	end

	local bossMult = isBossFloor and 2 or 1
	local eHP = math.floor(bHP + (bHP * standardScale)) * bossMult
	local eStr = math.floor(bStr + (bStr * standardScale)) * bossMult
	local eDef = math.floor(bDef + (bDef * standardScale)) * bossMult
	local eSpd = math.floor(bSpd + (bSpd * utilityScale)) * bossMult
	local finalWill = math.floor(bWill + (bWill * utilityScale)) * bossMult

	local dYen = math.floor((15 + (bHP * 0.1)) * (1 + standardScale)) * bossMult * 10
	local dXP = math.floor((50 + (bHP * 0.4)) * (1 + standardScale)) * bossMult * 10

	local eSkills = {"Basic Attack", "Heavy Strike", "Block"}
	local addedSkills = {["Basic Attack"]=true, ["Heavy Strike"]=true, ["Block"]=true}

	local function addSkill(name)
		if not addedSkills[name] then
			table.insert(eSkills, name)
			addedSkills[name] = true
		end
	end

	for skillName, skillInfo in pairs(SkillData.Skills) do
		local req = skillInfo.Requirement
		if req == eStyle and eStyle ~= "None" then addSkill(skillName) end
		if hasStand and req == "AnyStand" then addSkill(skillName) end
		if hasStand and not isFused and req == eStand and eStand ~= "None" then addSkill(skillName) end
	end

	if isFused then
		local fusedAbilities = FusionUtility.CalculateFusedAbilities(eStand1, eStand2, SkillData)
		for _, sObj in ipairs(fusedAbilities) do
			addSkill(sObj.Name)
		end
	end

	local displayTrait = ""
	if isFused and eTrait ~= "None" and eTrait2 ~= "None" then
		displayTrait = " [" .. eTrait .. " + " .. eTrait2 .. "]"
	elseif eTrait ~= "None" then
		displayTrait = " [" .. eTrait .. "]"
	end

	local fullName = eName
	if hasStand then 
		if isFused then
			local fusedName = FusionUtility.CalculateFusedName(eStand1, eStand2)
			fullName = fullName .. " (" .. fusedName .. ")" .. displayTrait
		else
			fullName = fullName .. " (" .. eStand .. ")" .. displayTrait
		end
	end

	return {
		IsPlayer = false, Name = fullName, Icon = "", Trait = eTrait, Trait2 = eTrait2,
		IsBoss = isBossFloor,
		HP = eHP, MaxHP = eHP, TotalStrength = eStr, TotalDefense = eDef, TotalSpeed = eSpd, TotalWillpower = finalWill,
		Stamina = 150 + (eHP * 0.1), MaxStamina = 150 + (eHP * 0.1),
		StandEnergy = 150 + (eHP * 0.1), MaxStandEnergy = 150 + (eHP * 0.1),
		TotalRange = (GameData.StandRanks[standRan] or 0), TotalPrecision = (GameData.StandRanks[standPre] or 0),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { 
			Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, 
			Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, 
			Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0,
			StaminaExhausted = 0, EnergyExhausted = 0, Dizzy = 0, Chilly = 0,
			Acid = 0, Infection = 0, Rupture = 0, Frostburn = 0, Frostbite = 0, Decay = 0,
			Blight = 0, Miasma = 0, Necrosis = 0, Plague = 0, Calamity = 0, Warded = 0 
		},
		Cooldowns = {}, Skills = eSkills, RawDrops = { Yen = dYen, XP = dXP, ItemChance = {} }
	}
end

local function CompilePartWaves(partId)
	local waves = {}
	local pData = EnemyData.Parts[partId]
	if not pData then return waves end

	if pData.Mobs and #pData.Mobs > 0 then
		for i = 1, 5 do table.insert(waves, pData.Mobs[math.random(1, #pData.Mobs)]) end
	end

	local templateList = {}
	if pData.Templates then for _, t in pairs(pData.Templates) do table.insert(templateList, t) end end
	table.sort(templateList, function(a,b) return (a.Health or 0) < (b.Health or 0) end)
	for _, t in ipairs(templateList) do table.insert(waves, t) end

	return waves
end

local function StartDungeon(player, dungeonId)
	local isEndless = (dungeonId == "Endless")
	local waves = {}
	if not isEndless then
		waves = CompilePartWaves(dungeonId)
		if #waves == 0 then return end
	end

	local pData = CombatCore.BuildPlayerStruct(player, true)
	local firstEnemy = isEndless and GenerateRandomEndlessEnemy(1) or GenerateDungeonEnemy(waves[1], dungeonId)

	ActiveDungeons[player.UserId] = {
		DungeonId = dungeonId, IsEndless = isEndless, CurrentWave = 1, TotalWaves = isEndless and "8" or #waves, Waves = waves,
		MasterDrops = { Yen = 0, XP = 0, ItemChance = {} }, IsProcessing = false, Boosts = pData.Boosts, 
		Player = pData,
		Enemy = firstEnemy
	}

	if not isEndless then
		local fixedPrestige = tonumber(dungeonId) and (tonumber(dungeonId) + 9) or 10
		local scaleMult = 1 + (fixedPrestige * 0.10)
		for _, waveTemplate in ipairs(waves) do
			if waveTemplate.Drops then
				ActiveDungeons[player.UserId].MasterDrops.Yen += math.floor((waveTemplate.Drops.Yen or 0) * scaleMult)
				ActiveDungeons[player.UserId].MasterDrops.XP += math.floor((waveTemplate.Drops.XP or 0) * scaleMult)

				if waveTemplate.Drops.ItemChance then
					for item, ch in pairs(waveTemplate.Drops.ItemChance) do 
						local current = ActiveDungeons[player.UserId].MasterDrops.ItemChance[item]
						local addChance = type(ch) == "table" and ch.Chance or ch
						local currentChance = type(current) == "table" and current.Chance or (current or 0)

						local newChance = math.min(100, currentChance + addChance)

						if type(ch) == "table" then
							ActiveDungeons[player.UserId].MasterDrops.ItemChance[item] = { Chance = newChance, Min = ch.Min, Max = ch.Max }
						elseif type(current) == "table" then
							current.Chance = newChance
						else
							ActiveDungeons[player.UserId].MasterDrops.ItemChance[item] = newChance
						end
					end
				end
			end
		end
	end

	player:SetAttribute("InCombat", true)
	local startMsg = isEndless and "<font color='#FFD700'>Descending into the Endless Dungeon...</font>" or "<font color='#FFD700'>Starting Part " .. dungeonId .. " Gauntlet!</font>"
	local waveStr = isEndless and "Floor 1" or "Wave 1/" .. #waves
	DungeonUpdate:FireClient(player, "Start", { Battle = ActiveDungeons[player.UserId], LogMsg = startMsg, WaveStr = waveStr })
end

DungeonAction.OnServerEvent:Connect(function(player, actionType, actionData)
	if actionType == "StartDungeon" then StartDungeon(player, actionData); return end

	local dungeon = ActiveDungeons[player.UserId]
	if not dungeon or dungeon.IsProcessing or actionType ~= "Attack" then return end

	local skillName = actionData
	local skill = SkillData.Skills[skillName]

	if not table.find(dungeon.Player.Skills, skillName) then return end

	if not skill or dungeon.Player.Stamina < (skill.StaminaCost or 0) or dungeon.Player.StandEnergy < (skill.EnergyCost or 0) then return end
	if dungeon.Player.Cooldowns[skillName] and dungeon.Player.Cooldowns[skillName] > 0 then return end

	dungeon.IsProcessing = true
	local waitMultiplier = player:GetAttribute("Has2xBattleSpeed") and 0.6 or 1.2

	local function DispatchStrike(attacker, defender, strikeSkill)
		if not attacker or not defender or attacker.HP <= 0 or defender.HP <= 0 then return end
		local success, msg, didHit, shakeType = pcall(function() 
			local lColor = attacker.IsPlayer and "#FFFFFF" or "#FF5555"
			local dColor = defender.IsPlayer and "#FFFFFF" or "#FF5555"
			local lName = attacker.IsPlayer and "You" or attacker.Name
			local dName = defender.IsPlayer and "you" or defender.Name
			return CombatCore.ExecuteStrike(attacker, defender, strikeSkill, "None", lName, dName, lColor, dColor) 
		end)
		if success then
			DungeonUpdate:FireClient(player, "TurnStrike", {Battle = dungeon, LogMsg = msg, DidHit = didHit, ShakeType = shakeType})
			task.wait(waitMultiplier)
		end
	end

	local combatants = { dungeon.Player, dungeon.Enemy }
	table.sort(combatants, function(a, b) 
		local aSpd = a.TotalSpeed * (((a.Statuses and a.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((a.Statuses and a.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		local bSpd = b.TotalSpeed * (((b.Statuses and b.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((b.Statuses and b.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		return aSpd > bSpd 
	end)

	for _, combatant in ipairs(combatants) do
		if dungeon.Player.HP < 1 or dungeon.Enemy.HP < 1 then break end
		if combatant.HP < 1 then continue end

		if combatant.Cooldowns then for sName, cd in pairs(combatant.Cooldowns) do if cd > 0 then combatant.Cooldowns[sName] = cd - 1 end end end
		for sName, sVal in pairs(combatant.Statuses) do 
			if (string.sub(sName, 1, 5) == "Buff_" or string.sub(sName, 1, 7) == "Debuff_" or string.find(sName, "Exhausted") or sName == "Dizzy" or sName == "Warded") and sVal > 0 then combatant.Statuses[sName] = sVal - 1 end 
		end
		if combatant.StunImmunity and combatant.StunImmunity > 0 then combatant.StunImmunity -= 1 end
		if combatant.ConfusionImmunity and combatant.ConfusionImmunity > 0 then combatant.ConfusionImmunity -= 1 end
		if combatant.BlockTurns then combatant.BlockTurns = math.max(0, combatant.BlockTurns - 1) end
		if combatant.CounterTurns then combatant.CounterTurns = math.max(0, combatant.CounterTurns - 1) end

		local freezeResult = CombatCore.ApplyStatusDamage(combatant, "None", DungeonUpdate, player, dungeon, waitMultiplier)
		if freezeResult == "Frozen" then continue end
		if combatant.HP < 1 then continue end

		if combatant.Statuses.Stun > 0 then
			combatant.Statuses.Stun -= 1
			if combatant.IsPlayer then
				combatant.Stamina = math.min(combatant.MaxStamina, combatant.Stamina + 5)
				combatant.StandEnergy = math.min(combatant.MaxStandEnergy, combatant.StandEnergy + 5)
			end
			DungeonUpdate:FireClient(player, "TurnStrike", {Battle = dungeon, LogMsg = "<font color='#AAAAAA'>"..combatant.Name.." is Stunned and cannot move!</font>", DidHit = false, ShakeType = "None"})
			task.wait(waitMultiplier); continue
		end

		if combatant.IsPlayer then
			if skill.Effect == "Flee" then
				DungeonUpdate:FireClient(player, "TurnStrike", {Battle = dungeon, LogMsg = "<font color='#AAAAAA'>You fled the dungeon!</font>", DidHit = false, ShakeType = "None"})
				task.wait(waitMultiplier)
				DungeonUpdate:FireClient(player, "Fled", {Battle = dungeon})
				ActiveDungeons[player.UserId] = nil
				player:SetAttribute("InCombat", false)
				return
			end
			DispatchStrike(dungeon.Player, dungeon.Enemy, skillName)
		else
			local eSkill = CombatCore.ChooseAISkill(combatant)
			DispatchStrike(dungeon.Enemy, dungeon.Player, eSkill)
		end

		if combatant.Statuses.Confusion > 0 then combatant.Statuses.Confusion -= 1 end
	end

	if dungeon.Player.HP < 1 then
		local dropPack = { XP = 0, Yen = 0, Items = {} }
		if dungeon.IsEndless then
			local hs = player:GetAttribute("EndlessHighScore") or 0
			local clearedFloors = dungeon.CurrentWave - 1
			if clearedFloors > hs then player:SetAttribute("EndlessHighScore", clearedFloors) end
			local clearedTens = math.floor(clearedFloors / 10)
			if clearedTens > 0 then
				local bonusArrows = math.random(0, clearedTens)
				if bonusArrows > 0 then
					player:SetAttribute("StandArrowCount", (player:GetAttribute("StandArrowCount") or 0) + bonusArrows)
					table.insert(dropPack.Items, "<font color='#55FFFF'>" .. bonusArrows .. "x Bonus Stand Arrow(s)</font>")
				end
			end
		end
		DungeonUpdate:FireClient(player, "Defeat", {Battle = dungeon, Drops = dropPack})
		ActiveDungeons[player.UserId] = nil
		player:SetAttribute("InCombat", false)

	elseif dungeon.Enemy.HP < 1 then
		local gangEvent = Network:FindFirstChild("AddGangOrderProgress")
		if gangEvent then gangEvent:Fire(player:GetAttribute("Gang"), "Dungeons", 1) end

		if dungeon.IsEndless then
			local fXP = math.floor(dungeon.Enemy.RawDrops.XP * dungeon.Boosts.XP)
			local fYen = math.floor(dungeon.Enemy.RawDrops.Yen * dungeon.Boosts.Yen)
			player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + fXP)
			player.leaderstats.Yen.Value += fYen

			local droppedItems = {}
			local baseDropMult = player:GetAttribute("Has2xDropChance") and 2 or 1
			local depthDropMult = 1 + (math.floor(dungeon.CurrentWave / 20) * 0.25)
			local dropMultiplier = baseDropMult * depthDropMult

			for itemName, chanceData in pairs(dungeon.Enemy.RawDrops.ItemChance) do
				local baseChance = type(chanceData) == "table" and chanceData.Chance or chanceData
				local boostedChance = (baseChance + dungeon.Boosts.Luck) * dropMultiplier
				if math.random(1, 100) <= boostedChance then
					local amount = type(chanceData) == "table" and math.random(chanceData.Min, chanceData.Max) or 1
					local attrName = itemName:gsub("[^%w]", "") .. "Count"
					player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + amount)
					table.insert(droppedItems, "<font color='#FFFF55'>" .. amount .. "x " .. itemName .. "</font>")
				end
			end

			local now = math.floor(workspace:GetServerTimeNow())
			local currentDay = tostring(math.floor(now / 86400))
			local savedDate = player:GetAttribute("DailyEndlessDate")

			if savedDate ~= currentDay then
				player:SetAttribute("DailyEndlessDate", currentDay)
				player:SetAttribute("DailyEndlessFloor", 0)
			end

			local floor = dungeon.CurrentWave
			local highestToday = player:GetAttribute("DailyEndlessFloor") or 0

			if floor > highestToday then
				player:SetAttribute("DailyEndlessFloor", floor)
			end

			if floor % 10 == 0 then
				local baseAmt = 1 + math.floor(floor / 100)
				local corpseAmt = math.floor(floor / 100)

				player:SetAttribute("RokakakaCount", (player:GetAttribute("RokakakaCount") or 0) + baseAmt)
				player:SetAttribute("StandArrowCount", (player:GetAttribute("StandArrowCount") or 0) + baseAmt)
				table.insert(droppedItems, "<font color='#55FFFF'>[MILESTONE] " .. baseAmt .. "x Rokakaka, " .. baseAmt .. "x Stand Arrow</font>")

				if corpseAmt > 0 then
					local attr = "SaintsCorpsePartCount"
					player:SetAttribute(attr, (player:GetAttribute(attr) or 0) + corpseAmt)
					table.insert(droppedItems, "<font color='#FF55FF'>[MILESTONE] " .. corpseAmt .. "x Saint's Corpse Part</font>")
				end

				if floor > highestToday then
					if floor % 50 == 0 and floor % 100 ~= 0 then
						player:SetAttribute("LegendaryGiftboxCount", (player:GetAttribute("LegendaryGiftboxCount") or 0) + 1)
						table.insert(droppedItems, "<font color='#FFD700'>[FLOOR " .. floor .. " DAILY BONUS] 1x Legendary Giftbox</font>")
					end

					if floor % 100 == 0 and floor % 1000 ~= 0 then
						player:SetAttribute("MythicalGiftboxCount", (player:GetAttribute("MythicalGiftboxCount") or 0) + 1)
						table.insert(droppedItems, "<font color='#FF5555'>[CENTURY DAILY BONUS] 1x Mythical Giftbox</font>")
					end

					if floor % 1000 == 0 then
						player:SetAttribute("UniqueGiftboxCount", (player:GetAttribute("UniqueGiftboxCount") or 0) + 1)
						table.insert(droppedItems, "<font color='#D745FF'>[MILLENNIUM DAILY BONUS] 1x Unique Giftbox</font>")
					end
				else
					if floor % 50 == 0 then
						table.insert(droppedItems, "<font color='#AAAAAA'>[DAILY BONUS ALREADY CLAIMED FOR FLOOR " .. floor .. "]</font>")
					end
				end
			end

			local hs = player:GetAttribute("EndlessHighScore") or 0
			if floor > hs then player:SetAttribute("EndlessHighScore", floor) end
			local maxMilestone = player:GetAttribute("EndlessMaxMilestone") or 0
			if floor > maxMilestone then player:SetAttribute("EndlessMaxMilestone", floor) end

			dungeon.CurrentWave += 1
			dungeon.Enemy = GenerateRandomEndlessEnemy(dungeon.CurrentWave)
			dungeon.IsProcessing = false

			local descendMsg = "<font color='#FFD700'>Descending to Floor " .. dungeon.CurrentWave .. "...</font>\n<font color='#55FF55'>Gained " .. fXP .. " XP and ¥" .. fYen .. "!</font>"
			if #droppedItems > 0 then descendMsg = descendMsg .. "\n<font color='#FFFF55'>Loot Secured: " .. table.concat(droppedItems, ", ") .. "</font>" end
			DungeonUpdate:FireClient(player, "WaveComplete", { Battle = dungeon, LogMsg = descendMsg, WaveStr = "Floor " .. dungeon.CurrentWave })
			return
		else
			if dungeon.CurrentWave < dungeon.TotalWaves then
				dungeon.CurrentWave += 1
				local nextTemplate = dungeon.Waves[dungeon.CurrentWave]
				dungeon.Enemy = GenerateDungeonEnemy(nextTemplate, dungeon.DungeonId)
				dungeon.IsProcessing = false
				DungeonUpdate:FireClient(player, "WaveComplete", { Battle = dungeon, LogMsg = "<font color='#FFD700'>A new enemy approaches!</font>", WaveStr = "Wave " .. dungeon.CurrentWave .. "/" .. dungeon.TotalWaves })
				return
			else
				local fXP = math.floor(dungeon.MasterDrops.XP * dungeon.Boosts.XP)
				local fYen = math.floor(dungeon.MasterDrops.Yen * dungeon.Boosts.Yen)
				player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + fXP)
				player.leaderstats.Yen.Value += fYen

				local dropMultiplier = player:GetAttribute("Has2xDropChance") and 2 or 1
				local currentInv = GameData.GetInventoryCount(player)
				local maxInv = GameData.GetMaxInventory(player)
				local droppedItems = {}

				for itemName, chanceData in pairs(dungeon.MasterDrops.ItemChance) do
					local baseChance = type(chanceData) == "table" and chanceData.Chance or chanceData
					local boostedChance = (baseChance + dungeon.Boosts.Luck) * dropMultiplier

					if math.random(1, 100) <= boostedChance then
						local amount = type(chanceData) == "table" and math.random(chanceData.Min, chanceData.Max) or 1
						local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
						local itemRarity = itemData and itemData.Rarity or "Common"
						local isIgnored = itemData and (itemData.Rarity == "Unique" or (ItemData.Consumables[itemName] and itemData.Category == "Stand") or itemData.Rarity == "Special")

						if player:GetAttribute("AutoSell_" .. itemRarity) and not isIgnored then
							local sellVal = itemData and (itemData.SellPrice or math.floor((itemData.Cost or 50) / 2)) or 25
							player.leaderstats.Yen.Value += (sellVal * amount)
							table.insert(droppedItems, amount .. "x " .. itemName .. " <font color='#AAAAAA'>(Auto-Sold: ¥" .. (sellVal * amount) .. ")</font>")
						else
							if isIgnored then
								local attrName = itemName:gsub("[^%w]", "") .. "Count"
								player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + amount)
								table.insert(droppedItems, amount .. "x " .. itemName)
							elseif currentInv < maxInv then
								local attrName = itemName:gsub("[^%w]", "") .. "Count"
								player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + amount)
								table.insert(droppedItems, amount .. "x " .. itemName)
								currentInv += 1
							else
								Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Inventory Full! " .. itemName .. " was lost.</font>")
							end
						end
					end
				end

				local clearAttr = "DungeonClear_Part" .. dungeon.DungeonId
				if not player:GetAttribute(clearAttr) then
					player:SetAttribute(clearAttr, true)
					player:SetAttribute("RokakakaCount", (player:GetAttribute("RokakakaCount") or 0) + 1)
					table.insert(droppedItems, "<font color='#FF55FF'>[FIRST CLEAR] Rokakaka</font>")
				end

				local finalPack = { XP = fXP, Yen = fYen, Items = droppedItems }
				DungeonUpdate:FireClient(player, "Victory", {Battle = dungeon, Drops = finalPack})
				ActiveDungeons[player.UserId] = nil
				player:SetAttribute("InCombat", false)
			end
		end
	else
		if skill.StaminaCost == 0 then dungeon.Player.Stamina = math.min(dungeon.Player.MaxStamina, dungeon.Player.Stamina + 5) end
		if skill.EnergyCost == 0 then dungeon.Player.StandEnergy = math.min(dungeon.Player.MaxStandEnergy, dungeon.Player.StandEnergy + 5) end

		local vigCount = CombatCore.CountTrait(dungeon.Player, "Vigorous")
		if vigCount > 0 then
			dungeon.Player.Stamina = math.min(dungeon.Player.MaxStamina, dungeon.Player.Stamina + (10 * vigCount))
			dungeon.Player.StandEnergy = math.min(dungeon.Player.MaxStandEnergy, dungeon.Player.StandEnergy + (10 * vigCount))
		end

		dungeon.IsProcessing = false
		DungeonUpdate:FireClient(player, "Update", {Battle = dungeon})
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	ActiveDungeons[player.UserId] = nil
	player:SetAttribute("InCombat", false)
end)