-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local CombatCore = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))
local SkillTreeHandler = require(ReplicatedStorage:WaitForChild("SkillTreeHandler"))
local PassiveSkillData = require(ReplicatedStorage:WaitForChild("PassiveSkillData"))

local TotalValidFusions = nil
local ValidStandsForFusion = nil

local function ScaleResource(val)
	if val <= 1000 then return val end
	return 1000 + math.floor((val - 1000) ^ 0.65 * 3)
end

function CombatCore.HasModifier(modStr, modName)
	if not modStr or modStr == "None" or modStr == "" then return false end
	for _, m in ipairs(string.split(modStr, ",")) do
		if m == modName then return true end
	end
	return false
end

function CombatCore.CountTrait(combatant, traitName)
	local count = 0

	if type(combatant.Traits) == "table" and #combatant.Traits > 0 then
		for _, t in ipairs(combatant.Traits) do
			if t == traitName then count += 1 end
		end
	elseif combatant.Trait == traitName then
		count += 1
	end

	return count
end

function CombatCore.HasTrait(combatant, traitName)
	return CombatCore.CountTrait(combatant, traitName) > 0
end

function CombatCore.GetEquipBonus(player, statName)
	local wpn = player:GetAttribute("EquippedWeapon") or "None"
	local acc = player:GetAttribute("EquippedAccessory") or "None"
	local style = player:GetAttribute("FightingStyle") or "None"
	local bonus = 0

	if ItemData.Equipment[wpn] and ItemData.Equipment[wpn].Bonus[statName] then bonus += ItemData.Equipment[wpn].Bonus[statName] end
	if ItemData.Equipment[acc] and ItemData.Equipment[acc].Bonus[statName] then bonus += ItemData.Equipment[acc].Bonus[statName] end
	if GameData.StyleBonuses and GameData.StyleBonuses[style] and GameData.StyleBonuses[style][statName] then bonus += GameData.StyleBonuses[style][statName] end

	return bonus
end

function CombatCore.GetPlayerBoosts(player)
	local boosts = { XP = 1.0, Yen = 1.0, Luck = 0, Damage = 1.0 }
	if not player then return boosts end

	local friends = math.min(player:GetAttribute("ServerFriends") or 0, 4)
	boosts.XP += (friends * 0.05)
	boosts.Yen += (friends * 0.05)

	if player.MembershipType == Enum.MembershipType.Premium then boosts.XP += 0.05 end
	if player:GetAttribute("IsSupporter") then boosts.XP += 0.05; boosts.Luck += 1 end

	local elo = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Elo") and player.leaderstats.Elo.Value or 1000
	if elo >= 1500 then boosts.Yen += 0.05 end
	if elo >= 2000 then boosts.XP += 0.05 end
	if elo >= 3000 then boosts.Luck += 1 end
	if elo >= 5000 then boosts.Damage *= 1.05 end

	boosts.Yen *= (player:GetAttribute("GangYenBoost") or 1.0)
	boosts.XP *= (player:GetAttribute("GangXPBoost") or 1.0)
	local gLuck = player:GetAttribute("GangLuckBoost") or 1.0
	if gLuck > 1.0 then boosts.Luck += 1 end 
	boosts.Damage *= (player:GetAttribute("GangDmgBoost") or 1.0)

	local uniModStr = player:GetAttribute("UniverseModifier") or "None"
	if CombatCore.HasModifier(uniModStr, "Lucky Star") then boosts.Luck += 1 end
	if CombatCore.HasModifier(uniModStr, "Unlucky Aura") then boosts.Luck -= 1 end

	local indexBoosts = GameData.GetIndexBoosts(player)
	boosts.XP += (indexBoosts.XP - 1.0)
	boosts.Yen += (indexBoosts.Yen - 1.0)
	boosts.Luck += indexBoosts.Luck
	boosts.Damage *= indexBoosts.GlobalDamage

	return boosts
end

function CombatCore.BuildPlayerStruct(player, isRawStats)
	if not TotalValidFusions then
		TotalValidFusions = 0
		ValidStandsForFusion = {}
		for sName, sData in pairs(StandData.Stands) do
			if sData.Part and sData.Part ~= "" and sData.Part ~= "None" then
				ValidStandsForFusion[sName] = true
				TotalValidFusions += 1
			end
		end
	end

	local playerTrait = player:GetAttribute("StandTrait") or "None"
	local hasStand = (player:GetAttribute("Stand") or "None") ~= "None"
	local sName = player:GetAttribute("Stand") or "None"

	local treeDamageMult = 1.0
	if hasStand and player and player:IsA("Player") then
		treeDamageMult = SkillTreeHandler.GetDamageMultiplier(player, sName)
	end

	local sPow = hasStand and (player:GetAttribute("Stand_Power_Val") or 0) or 0
	local sDur = hasStand and (player:GetAttribute("Stand_Durability_Val") or 0) or 0
	local sSpd = hasStand and (player:GetAttribute("Stand_Speed_Val") or 0) or 0
	local sPot = hasStand and (player:GetAttribute("Stand_Potential_Val") or 0) or 0
	local sRan = hasStand and (player:GetAttribute("Stand_Range_Val") or 0) or 0
	local sPre = hasStand and (player:GetAttribute("Stand_Precision_Val") or 0) or 0

	local activeTraits = {playerTrait}
	if sName == "Fused Stand" then
		activeTraits = {}
		local t1 = player:GetAttribute("Active_FusedTrait1") or "None"
		local t2 = player:GetAttribute("Active_FusedTrait2") or "None"
		if t1 ~= "None" then table.insert(activeTraits, t1) end
		if t2 ~= "None" then table.insert(activeTraits, t2) end
	end

	local function cT(tName)
		local c = 0
		for _, t in ipairs(activeTraits) do if t == tName then c += 1 end end
		return c
	end

	local pHP, pStyleStr, pStandStr, pDef, pSpd, pWill, pStamina, pStandEnergy

	if isRawStats then
		pHP = (player:GetAttribute("Health") or 1) + CombatCore.GetEquipBonus(player, "Health")
		pStyleStr = (player:GetAttribute("Strength") or 1) + CombatCore.GetEquipBonus(player, "Strength")
		pStandStr = sPow + CombatCore.GetEquipBonus(player, "Stand_Power")
		pDef = (player:GetAttribute("Defense") or 1) + sDur + CombatCore.GetEquipBonus(player, "Defense") + CombatCore.GetEquipBonus(player, "Stand_Durability")
		pSpd = (player:GetAttribute("Speed") or 1) + sSpd + CombatCore.GetEquipBonus(player, "Speed") + CombatCore.GetEquipBonus(player, "Stand_Speed")
		pWill = (player:GetAttribute("Willpower") or 1) + CombatCore.GetEquipBonus(player, "Willpower")
		pStamina = ScaleResource((player:GetAttribute("Stamina") or 1) + CombatCore.GetEquipBonus(player, "Stamina"))
		pStandEnergy = ScaleResource(10 + sPot + CombatCore.GetEquipBonus(player, "Stand_Potential"))
	else
		pHP = 500 + CombatCore.GetEquipBonus(player, "Health")
		pStyleStr = 500 + CombatCore.GetEquipBonus(player, "Strength")
		pStandStr = 500 + CombatCore.GetEquipBonus(player, "Stand_Power")
		pDef = 500 + 500 + CombatCore.GetEquipBonus(player, "Defense") + CombatCore.GetEquipBonus(player, "Stand_Durability")
		pSpd = 500 + 500 + CombatCore.GetEquipBonus(player, "Speed") + CombatCore.GetEquipBonus(player, "Stand_Speed")
		pWill = 500 + CombatCore.GetEquipBonus(player, "Willpower")
		pStamina = 500 + CombatCore.GetEquipBonus(player, "Stamina")
		pStandEnergy = 10 + 500 + CombatCore.GetEquipBonus(player, "Stand_Potential")

		sRan = 500
		sPre = 500
	end

	local fStyle = player:GetAttribute("FightingStyle") or "None"
	local sType = (StandData.Stands[sName] and StandData.Stands[sName].Type) or "None"

	local toughCount, fierceCount, persCount = cT("Tough"), cT("Fierce"), cT("Perseverance")
	if toughCount > 0 then pHP *= (1.1 ^ toughCount) end
	if fierceCount > 0 then 
		pStyleStr *= (1.1 ^ fierceCount) 
		pStandStr *= (1.1 ^ fierceCount) 
	end
	if persCount > 0 then pHP *= (1.5 ^ persCount); pWill *= (1.5 ^ persCount) end

	local focCount = cT("Focused")
	if focCount > 0 then pStamina *= (1.1 ^ focCount); pStandEnergy *= (1.1 ^ focCount) end

	local activeBoosts = CombatCore.GetPlayerBoosts(player)
	local validSkills = {}
	local activePassives = {}

	local unlockedFusionsStr = player:GetAttribute("UnlockedFusions") or ""
	local fusionBonusMult = 0

	if TotalValidFusions > 0 and unlockedFusionsStr ~= "" then
		local fusionCounts = {}
		for _, fStr in ipairs(string.split(unlockedFusionsStr, ",")) do
			if fStr ~= "" then
				local parts = string.split(fStr, "|")
				local s1, s2 = parts[1], parts[2]
				if s1 and s2 and ValidStandsForFusion[s1] and ValidStandsForFusion[s2] then
					fusionCounts[s1] = fusionCounts[s1] or { Count = 0 }
					if not fusionCounts[s1][s2] then
						fusionCounts[s1][s2] = true
						fusionCounts[s1].Count += 1
					end
				end
			end
		end

		local completedStandsSet = {}
		for s1, data in pairs(fusionCounts) do
			local completionRatio = math.clamp(data.Count / TotalValidFusions, 0, 1)
			fusionBonusMult += (completionRatio * 0.01)

			if data.Count >= TotalValidFusions then
				completedStandsSet[s1] = true
			end
		end

		if sName == "Fused Stand" then
			local fs1 = player:GetAttribute("Active_FusedStand1") or "None"
			local fs2 = player:GetAttribute("Active_FusedStand2") or "None"
			if completedStandsSet[fs1] then fusionBonusMult += 0.25 end
			if completedStandsSet[fs2] then fusionBonusMult += 0.25 end
		else
			if completedStandsSet[sName] then fusionBonusMult += 0.25 end
		end
	end

	if sName == "Fused Stand" then
		local fs1 = player:GetAttribute("Active_FusedStand1") or "None"
		local fs2 = player:GetAttribute("Active_FusedStand2") or "None"
		local fusedSkills = FusionUtility.CalculateFusedAbilities(fs1, fs2, SkillData)
		for _, sk in ipairs(fusedSkills) do table.insert(validSkills, sk.Name) end
	end

	local HttpService = game:GetService("HttpService")
	local treeStrProg = player:GetAttribute("SkillTreeProgress") or "{}"
	local _, tDict = pcall(function() return HttpService:JSONDecode(treeStrProg) end)

	if tDict and tDict[sName] and tDict[sName].UnlockedSkills then
		if PassiveSkillData.Passives[sName] then
			for pKey, pData in pairs(PassiveSkillData.Passives[sName]) do
				if tDict[sName].UnlockedSkills[pKey] or tDict[sName].UnlockedSkills["Passive_" .. pKey] then
					table.insert(activePassives, pData)
				end
			end
		end
	end

	for n, s in pairs(SkillData.Skills) do
		local isStandReq = (s.Requirement == sName and sName ~= "Fused Stand")

		if s.RequiresTreeUnlock then
			local hasBoughtSkill = tDict and tDict[sName] and tDict[sName].UnlockedSkills["Skill_" .. n]
			if not hasBoughtSkill then continue end
		end

		if s.Requirement == "None" or isStandReq or s.Requirement == fStyle or (s.Requirement == "AnyStand" and sName ~= "None") then
			table.insert(validSkills, n)
		end
	end

	return {
		Player = player, UserId = player.UserId, Name = player.Name, IsPlayer = true, PlayerObj = player,
		Trait = playerTrait, Traits = activeTraits, GlobalDmgBoost = activeBoosts.Damage, Boosts = activeBoosts,
		Stand = sName, Style = fStyle, StandType = sType, FusionDamageBonus = fusionBonusMult, TreeDamageMult = treeDamageMult,
		HP = pHP * 20, MaxHP = pHP * 20, Stamina = pStamina, MaxStamina = pStamina, StandEnergy = pStandEnergy, MaxStandEnergy = pStandEnergy,

		StyleStrength = pStyleStr, StandStrength = pStandStr, 
		TotalStrength = pStyleStr + pStandStr,

		TotalDefense = pDef, TotalSpeed = pSpd,
		TotalWillpower = pWill,
		TotalRange = sRan + CombatCore.GetEquipBonus(player, "Stand_Range"), TotalPrecision = sPre + CombatCore.GetEquipBonus(player, "Stand_Precision"),
		BlockTurns = 0, CounterTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { 
			Stun = 0, Freeze = 0, Confusion = 0, Dizzy = 0, Warded = 0,
			Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, 
			Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0, 
			StaminaExhausted = 0, EnergyExhausted = 0, 
			Burn = 0, Sick = 0, Bleed = 0, Chill = 0,
			Scorch = 0, Poison = 0, Hemorrhage = 0, Frost = 0,
			Acid = 0, Infection = 0, Rupture = 0, Frostburn = 0, Frostbite = 0, Decay = 0, 
			Blight = 0, Miasma = 0, Necrosis = 0, Plague = 0, Calamity = 0
		}, 
		Cooldowns = {}, SelectedSkill = nil, Skills = validSkills, ActivePassives = activePassives
	}
end

function CombatCore.CalculateDamage(attacker, defender, skillMult, isDefenderBlocking, uniModStr, skill)
	local skillType = skill and skill.Type or "Basic"
	local offensiveStat = attacker.TotalStrength or 1
	if skillType == "Stand" then
		offensiveStat = attacker.StandStrength or (attacker.TotalStrength or 1)
	elseif skillType == "Style" then
		offensiveStat = attacker.StyleStrength or (attacker.TotalStrength or 1)
	end

	local junkieCount = CombatCore.CountTrait(attacker, "Junkie")
	if junkieCount > 0 and attacker.Statuses then
		local debuffCount = 0
		local negStats = {"Sick", "Poison", "Burn", "Scorch", "Bleed", "Hemorrhage", "Chill", "Frost", "Freeze", "Confusion", "Stun", "Dizzy", "Acid", "Infection", "Rupture", "Frostburn", "Frostbite", "Decay", "Blight", "Miasma", "Necrosis", "Plague", "Calamity", "Debuff_Strength", "Debuff_Defense", "Debuff_Speed", "Debuff_Willpower", "StaminaExhausted", "EnergyExhausted"}
		for _, stat in ipairs(negStats) do
			if (attacker.Statuses[stat] or 0) > 0 then
				debuffCount += 1
			end
		end
		if debuffCount > 0 then
			skillMult *= (1 + (0.15 * junkieCount * debuffCount))
		end
	end

	local atkBuff = (attacker.Statuses and (attacker.Statuses.Buff_Strength or 0) > 0) and 1.5 or 1.0
	local atkDebuff = (attacker.Statuses and (attacker.Statuses.Debuff_Strength or 0) > 0) and 0.5 or 1.0

	local defBuff = (defender.Statuses and (defender.Statuses.Buff_Defense or 0) > 0) and 1.5 or 1.0
	local defDebuff = (defender.Statuses and (defender.Statuses.Debuff_Defense or 0) > 0) and 0.5 or 1.0

	local baseDmg = offensiveStat * atkBuff * atkDebuff * skillMult

	if skillType == "Stand" and attacker.StandType and defender.StandType then
		local aType = attacker.StandType
		local dType = defender.StandType

		if aType == "Power" then
			if dType == "Automatic" then baseDmg *= 1.25
			elseif dType == "Ranged" then baseDmg *= 0.80 end
		elseif aType == "Automatic" then
			if dType == "Ranged" then baseDmg *= 1.25
			elseif dType == "Power" then baseDmg *= 0.80 end
		elseif aType == "Ranged" then
			if dType == "Power" then baseDmg *= 1.25
			elseif dType == "Automatic" then baseDmg *= 0.80 end
		end
	end

	if attacker.IsPlayer then
		if CombatCore.HasModifier(uniModStr, "Heavy Gravity") then baseDmg *= 1.25 end
		if CombatCore.HasModifier(uniModStr, "Glass Cannon") then baseDmg *= 1.50 end
		if CombatCore.HasModifier(uniModStr, "Sharpened Weapons") then baseDmg *= 1.10 end
		if CombatCore.HasModifier(uniModStr, "Dull Blades") then baseDmg *= 0.90 end
		if CombatCore.HasModifier(uniModStr, "Desperate Struggle") and (attacker.HP / attacker.MaxHP) <= 0.3 then baseDmg *= 1.50 end
	else
		if CombatCore.HasModifier(uniModStr, "Experience Surge") then baseDmg *= 1.25 end
	end

	local overCount = CombatCore.CountTrait(attacker, "Overwhelming")
	local traitBypass = math.min(0.60, overCount * 0.30)
	local rangeBypass = math.min(0.40, (attacker.TotalRange or 0) / 5000)

	local passiveBypass = 0
	if attacker.ActivePassives then
		for _, p in ipairs(attacker.ActivePassives) do
			if p.Effects then
				for _, eff in ipairs(p.Effects) do
					if eff.Type == "ArmorBypass" then
						passiveBypass += (eff.Value / 100)
					end
				end
			end
		end
	end

	local totalBypass = math.min(0.9, traitBypass + rangeBypass + passiveBypass)
	local effectiveArmor = ((defender.TotalDefense or 0) * defBuff * defDebuff) * (1 - totalBypass)

	local scaledDef = math.max(0, effectiveArmor)
	if scaledDef > 250 then
		scaledDef = 250 + ((scaledDef - 250) ^ 0.8)
	end

	local defenseMultiplier = 100 / (100 + scaledDef)

	local exhaustVuln = 0
	if (defender.Statuses.StaminaExhausted or 0) > 0 then exhaustVuln += 0.25 end
	if (defender.Statuses.EnergyExhausted or 0) > 0 then exhaustVuln += 0.25 end

	local passiveReduction = 0
	if defender.ActivePassives then
		for _, p in ipairs(defender.ActivePassives) do
			if p.Effects then
				for _, eff in ipairs(p.Effects) do
					if eff.Type == "DamageReduction" then
						local applies = false
						if eff.Elements then
							if table.find(eff.Elements, "All") then applies = true end
							if skill then
								if table.find(eff.Elements, "Physical") and (skillType == "Basic" or skillType == "Style" or not skill.Effect) then applies = true end
								if table.find(eff.Elements, "Fire") and (skill.Effect == "Burn" or skill.Effect == "Scorch") then applies = true end
								if table.find(eff.Elements, "Explosive") and (string.match(string.lower(skill.Description or ""), "explod") or string.match(string.lower(skill.Description or ""), "bomb")) then applies = true end
							end
						end
						if applies then
							passiveReduction += (eff.Value / 100)
						end
					end
				end
			end
		end
	end

	local finalDmg = baseDmg * defenseMultiplier * (1 + exhaustVuln)

	local armCount = CombatCore.CountTrait(defender, "Armored")
	if armCount > 0 then finalDmg *= (0.85 ^ armCount) end

	local indomCount = CombatCore.CountTrait(defender, "Indomitable")
	if indomCount > 0 and (defender.HP / defender.MaxHP) <= 0.3 then finalDmg *= (0.75 ^ indomCount) end

	if CombatCore.HasModifier(uniModStr, "Fragile Mortality") then finalDmg *= 1.50 end
	if CombatCore.HasModifier(uniModStr, "Iron Skin") then finalDmg *= 0.75 end

	if isDefenderBlocking then finalDmg *= 0.5 end

	finalDmg = finalDmg * (1 - math.min(0.8, passiveReduction))

	if attacker.GlobalDmgBoost then finalDmg *= attacker.GlobalDmgBoost end

	return math.max(1, finalDmg)
end

function CombatCore.ChooseAISkill(combatant)
	local validSkills = {}
	local categorized = { Attack = {}, Debuff = {}, Buff = {}, Block = {}, Rest = {} }

	local statusCount = 0
	if combatant.Statuses then
		for k, v in pairs(combatant.Statuses) do
			if v > 0 and k ~= "Warded" and not string.match(k, "Buff_") and not string.match(k, "Immunity") then
				statusCount += 1
			end
		end
	end

	local cHP = tonumber(combatant.HP) or 1
	local cMaxHP = tonumber(combatant.MaxHP) or 1
	local hpPct = cHP / math.max(1, cMaxHP)

	local cStam = tonumber(combatant.Stamina) or 1
	local cMaxStam = tonumber(combatant.MaxStamina) or 1
	local stamPct = cStam / math.max(1, cMaxStam)

	local cNrg = tonumber(combatant.StandEnergy) or 1
	local cMaxNrg = tonumber(combatant.MaxStandEnergy) or 1
	local nrgPct = cNrg / math.max(1, cMaxNrg)

	local needsRest = statusCount >= 3 or stamPct < 0.3 or nrgPct < 0.3
	local isLowHp = hpPct < 0.4

	if combatant.Skills then
		for _, sName in ipairs(combatant.Skills) do
			local cd = combatant.Cooldowns and combatant.Cooldowns[sName] or 0
			if cd > 0 then continue end
			local sData = SkillData.Skills[sName]
			if sData then
				if sData.Type == "Stand" and ((combatant.StandEnergy or 0) < (sData.EnergyCost or 0) or (combatant.Statuses.EnergyExhausted or 0) > 0) then continue end
				if sData.Type == "Style" and ((combatant.Stamina or 0) < (sData.StaminaCost or 0) or (combatant.Statuses.StaminaExhausted or 0) > 0) then continue end

				if sData.Effect == "Block" and (combatant.BlockTurns or 0) > 0 then continue end

				table.insert(validSkills, sName)

				if sData.Effect == "Rest" or sData.Effect == "CleanseRest" then
					table.insert(categorized.Rest, sName)
				elseif sData.Effect == "Block" or sData.Effect == "Counter" then
					table.insert(categorized.Block, sName)
				elseif string.match(sData.Effect or "", "Buff_") then
					table.insert(categorized.Buff, sName)
				elseif string.match(sData.Effect or "", "Debuff_") or sData.Effect == "Stun" or sData.Effect == "Freeze" or sData.Effect == "Confusion" or sData.Effect == "Scorch" or sData.Effect == "Burn" or sData.Effect == "Poison" or sData.Effect == "Sick" or sData.Effect == "Hemorrhage" or sData.Effect == "Bleed" or sData.Effect == "Frost" or sData.Effect == "Chill" or sData.Effect == "Status_Random" then
					table.insert(categorized.Debuff, sName)
				else
					table.insert(categorized.Attack, sName)
				end
			end
		end
	end

	if #validSkills == 0 then return "Basic Attack" end

	if needsRest and #categorized.Rest > 0 and math.random() < 0.5 then
		return categorized.Rest[math.random(1, #categorized.Rest)]
	end

	if isLowHp then
		local lowHpPool = {}
		for _, s in ipairs(categorized.Block) do table.insert(lowHpPool, s) end
		for _, s in ipairs(categorized.Buff) do table.insert(lowHpPool, s) end
		if #lowHpPool > 0 and math.random() < 0.4 then
			return lowHpPool[math.random(1, #lowHpPool)]
		end
	else
		local highHpPool = {}
		for _, s in ipairs(categorized.Debuff) do table.insert(highHpPool, s) end
		for _, s in ipairs(categorized.Attack) do table.insert(highHpPool, s) end
		if #highHpPool > 0 and math.random() < 0.8 then
			return highHpPool[math.random(1, #highHpPool)]
		end
	end

	return validSkills[math.random(1, #validSkills)]
end

function CombatCore.HandleInfectiousSpread(attacker, defender)
	if not attacker or not defender then return end
	if defender.HP < 1 and attacker.IsPlayer and attacker.PlayerObj then
		local infectCount = CombatCore.CountTrait(attacker, "Infectious")
		if infectCount > 0 and defender.Statuses then
			local carryOver = {}
			local dots = {"Burn", "Sick", "Bleed", "Chill", "Scorch", "Poison", "Hemorrhage", "Frost", "Acid", "Infection", "Rupture", "Frostburn", "Frostbite", "Decay", "Blight", "Miasma", "Necrosis", "Plague", "Calamity"}
			local hasAny = false
			for _, stat in ipairs(dots) do
				if (defender.Statuses[stat] or 0) > 0 then
					table.insert(carryOver, stat .. ":" .. math.max(1, math.ceil((defender.Statuses[stat] or 1) / 2)))
					hasAny = true
				end
			end
			if hasAny then
				attacker.PlayerObj:SetAttribute("InfectiousCarryover", table.concat(carryOver, ","))
			end
		end
	end
end

function CombatCore.ApplyInfectiousCarryover(playerObj, newEnemyStruct)
	if not playerObj or not newEnemyStruct or not newEnemyStruct.Statuses then return end
	local carry = playerObj:GetAttribute("InfectiousCarryover")
	if carry and carry ~= "" then
		local appliedAny = false
		for _, part in ipairs(string.split(carry, ",")) do
			local split = string.split(part, ":")
			local stat = split[1]
			local dur = tonumber(split[2])
			if stat and dur and newEnemyStruct.Statuses[stat] ~= nil then
				newEnemyStruct.Statuses[stat] = math.max(newEnemyStruct.Statuses[stat] or 0, dur)
				appliedAny = true
			end
		end
		if appliedAny then
			playerObj:SetAttribute("InfectiousCarryover", "")
		end
	end
end

function CombatCore.TakeDamageWithWillpower(combatant, damage)
	if (combatant.HP - damage) < 1 then
		local defWillBuff = (((combatant.Statuses and combatant.Statuses.Buff_Willpower or 0) > 0) and 1.5 or 1.0) * (((combatant.Statuses and combatant.Statuses.Debuff_Willpower or 0) > 0) and 0.5 or 1.0)
		local defWill = (combatant.TotalWillpower or 1) * defWillBuff

		if combatant.IsPlayer then
			local uniModStr = combatant.PlayerObj and combatant.PlayerObj:GetAttribute("UniverseModifier") or "None"
			if CombatCore.HasModifier(uniModStr, "Determined") then defWill *= 1.1 end
			if CombatCore.HasModifier(uniModStr, "Faltering") then defWill *= 0.9 end
		end

		local survivalChance = math.clamp(defWill * 0.7, 0, 45)

		if (combatant.WillpowerSurvivals or 0) < 1 and math.random(1, 100) <= survivalChance then
			local persCount = CombatCore.CountTrait(combatant, "Perseverance")
			if persCount > 0 then
				combatant.HP = math.max(1, combatant.MaxHP * math.min(1, 0.25 * persCount))
			else
				combatant.HP = 1
			end
			combatant.WillpowerSurvivals = (combatant.WillpowerSurvivals or 0) + 1
			return true 
		end
	end
	combatant.HP -= damage
	return false
end

function CombatCore.ApplyStatusDamage(combatant, uniModStr, CombatUpdate, player, battle, waitMultiplier)
	local statusDmgMod = CombatCore.HasModifier(uniModStr, "Cursed Wounds") and 0.25 or 0.15 

	if combatant.IsBoss then
		statusDmgMod = statusDmgMod * 0.75
	end

	local opponent = nil
	if battle then
		opponent = (combatant == battle.Player) and battle.Enemy or battle.Player
	end
	local domCount = opponent and CombatCore.CountTrait(opponent, "Dominating") or 0
	local armorIgnore = math.min(0.9, domCount * 0.5)

	local defBuff = (combatant.Statuses and (combatant.Statuses.Buff_Defense or 0) > 0) and 1.5 or 1.0
	local defDebuff = (combatant.Statuses and (combatant.Statuses.Debuff_Defense or 0) > 0) and 0.5 or 1.0
	local effectiveArmor = ((combatant.TotalDefense or 0) * defBuff * defDebuff) * (1 - armorIgnore)

	local scaledDef = effectiveArmor
	if scaledDef > 250 then
		scaledDef = 250 + ((scaledDef - 250) ^ 0.8)
	end

	local defMult = 100 / (100 + math.max(0, scaledDef))
	local persCount = CombatCore.CountTrait(combatant, "Perseverance")
	local unstableMult = CombatCore.HasModifier(uniModStr, "Unstable") and 2.0 or 1.0

	local isBlocking = (combatant.BlockTurns or 0) > 0
	local blockMult = isBlocking and 0.5 or 1.0
	local statusBlockMult = isBlocking and 0.25 or 1.0

	local function CheckDeath()
		if combatant.HP < 1 then
			if opponent then CombatCore.HandleInfectiousSpread(opponent, combatant) end
			return true
		end
		return false
	end

	local function ProcessDoT(statusName, hexColor, mult)
		if (combatant.Statuses[statusName] or 0) > 0 then
			local attackerOffense = opponent and (math.max(opponent.TotalStrength or 0, opponent.StyleStrength or 0, opponent.StandStrength or 0)) or 1
			local pctDmg = combatant.MaxHP * statusDmgMod * mult
			local statCap = (attackerOffense * 2.5) * mult
			local minPctDmg = combatant.MaxHP * (combatant.IsBoss and 0.025 or 0.05) * mult

			local cappedStatDmg = math.min(pctDmg, statCap)
			local rawDmg = math.max(minPctDmg, cappedStatDmg)

			local dmg = math.max(1, rawDmg * defMult) * unstableMult * statusBlockMult
			local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
			combatant.Statuses[statusName] -= 1
			local svMsg = survived and (persCount > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
			local blockMsg = isBlocking and " <font color='#AAAAAA'>(Blocked)</font>" or ""
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='"..hexColor.."'>"..combatant.Name.." took "..math.floor(dmg).." "..statusName.." damage!"..svMsg..blockMsg.."</font>", DidHit = true, ShakeType = "Light"})
			task.wait(waitMultiplier)
		end
	end

	ProcessDoT("Calamity", "#CC00FF", 5.0)
	if CheckDeath() then return end

	ProcessDoT("Blight", "#4B0082", 4.0)
	if CheckDeath() then return end
	ProcessDoT("Miasma", "#2E8B57", 4.0)
	if CheckDeath() then return end
	ProcessDoT("Necrosis", "#8B4513", 4.0)
	if CheckDeath() then return end
	ProcessDoT("Plague", "#556B2F", 4.0)
	if CheckDeath() then return end

	ProcessDoT("Acid", "#80FF00", 3.0)
	if CheckDeath() then return end
	ProcessDoT("Infection", "#800000", 3.0)
	if CheckDeath() then return end
	ProcessDoT("Rupture", "#FF4400", 3.0)
	if CheckDeath() then return end
	ProcessDoT("Frostburn", "#55AAFF", 3.0)
	if CheckDeath() then return end
	ProcessDoT("Frostbite", "#0055FF", 3.0)
	if CheckDeath() then return end
	ProcessDoT("Decay", "#00AA55", 3.0)
	if CheckDeath() then return end

	ProcessDoT("Scorch", "#FF5500", 2.0)
	if CheckDeath() then return end
	ProcessDoT("Poison", "#AA00AA", 2.0)
	if CheckDeath() then return end
	ProcessDoT("Hemorrhage", "#FF0000", 2.0)
	if CheckDeath() then return end
	ProcessDoT("Frost", "#66CCFF", 2.0)
	if CheckDeath() then return end

	ProcessDoT("Burn", "#FF8844", 1.0)
	if CheckDeath() then return end
	ProcessDoT("Sick", "#CC55CC", 1.0)
	if CheckDeath() then return end
	ProcessDoT("Bleed", "#FF5555", 1.0)
	if CheckDeath() then return end
	ProcessDoT("Chill", "#99DDFF", 1.0)
	if CheckDeath() then return end

	if combatant.Statuses.Freeze > 0 then
		local attackerOffense = opponent and (math.max(opponent.TotalStrength or 0, opponent.StyleStrength or 0, opponent.StandStrength or 0)) or 1
		local pctDmg = combatant.MaxHP * statusDmgMod
		local statCap = attackerOffense * 2.5
		local minPctDmg = combatant.MaxHP * (combatant.IsBoss and 0.025 or 0.05)
		local cappedStatDmg = math.min(pctDmg, statCap)
		local rawDmg = math.max(minPctDmg, cappedStatDmg)

		local dmg = math.max(1, rawDmg * defMult * blockMult)
		local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
		combatant.Statuses.Freeze -= 1
		local svMsg = survived and (persCount > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
		local blockMsg = isBlocking and " <font color='#AAAAAA'>(Blocked)</font>" or ""
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#00FFFF'>"..combatant.Name.." took "..math.floor(dmg).." Freeze damage and is frozen solid!"..svMsg..blockMsg.."</font>", DidHit = true, ShakeType = "Light"})
		task.wait(waitMultiplier)
		if CheckDeath() then return end
		if combatant.IsPlayer and not CombatCore.HasModifier(uniModStr, "Endless Stamina") then
			combatant.Stamina = math.min(combatant.MaxStamina, combatant.Stamina + 5)
			combatant.StandEnergy = math.min(combatant.MaxStandEnergy, combatant.StandEnergy + 5)
		end
		return "Frozen"
	end
end

function CombatCore.ExecuteStrike(attacker, defender, skillName, uniModStr, logName, defName, logColor, defColor)
	local skill = SkillData.Skills[skillName] or SkillData.Skills["Basic Attack"]
	uniModStr = uniModStr or "None"

	local fLogName = "<font color='" .. (logColor or "#FFFFFF") .. "'>" .. logName .. "</font>"
	local fDefName = "<font color='" .. (defColor or "#FF5555") .. "'>" .. defName .. "</font>"
	local msgPrefix = ""

	local t = defender
	local tName = fDefName
	local b = attacker
	local bName = fLogName
	local isSkippingFromDizzy = false

	if attacker.Statuses and (attacker.Statuses.Dizzy or 0) > 0 then
		local dizzyRoll = math.random(1, 100)
		if dizzyRoll <= 15 then
			msgPrefix = "<font color='#E6E600'>[DIZZY] </font>"
			t = attacker; tName = fLogName; b = defender; bName = fDefName
		elseif dizzyRoll <= 35 then
			msgPrefix = "<font color='#E6E600'>[DIZZY] </font>"
			isSkippingFromDizzy = true
		end
	end

	if not isSkippingFromDizzy and attacker.Statuses and (attacker.Statuses.Confusion or 0) > 0 then
		msgPrefix = "<font color='#FF55FF'>[CONFUSED] </font>"
		if skill.Effect ~= "Block" and skill.Effect ~= "Counter" and skill.Effect ~= "Rest" and skill.Effect ~= "CleanseRest" then
			t = attacker; tName = fLogName; b = defender; bName = fDefName
		end
	end

	if isSkippingFromDizzy then
		return msgPrefix .. fLogName .. " attempted to use <b>" .. skillName .. "</b>... but was too dizzy, missing the attack entirely!", false, "None"
	end

	if skill.Effect ~= "Flee" then
		local stamCost = skill.StaminaCost or 0
		local nrgCost = skill.EnergyCost or 0
		if CombatCore.HasModifier(uniModStr, "Resource Drought") then stamCost *= 1.5; nrgCost *= 1.5 end

		if attacker.IsPlayer then
			if CombatCore.HasModifier(uniModStr, "Speed of Light") then stamCost *= 1.5; nrgCost *= 1.5 end
			if CombatCore.HasModifier(uniModStr, "Endless Stamina") then stamCost *= 0.5; nrgCost *= 0.5 end
		end

		if attacker.Stamina then 
			attacker.Stamina = math.max(0, attacker.Stamina - stamCost) 
			if attacker.Stamina == 0 and (attacker.Statuses.StaminaExhausted or 0) == 0 then
				attacker.Statuses.StaminaExhausted = 3
				msgPrefix = msgPrefix .. "<font color='#AAAAAA'>[STAMINA EXHAUSTED!] </font>"
			end
		end

		if attacker.StandEnergy then 
			attacker.StandEnergy = math.max(0, attacker.StandEnergy - nrgCost)
			if attacker.StandEnergy == 0 and (attacker.Statuses.EnergyExhausted or 0) == 0 then
				attacker.Statuses.EnergyExhausted = 3
				msgPrefix = msgPrefix .. "<font color='#A020F0'>[ENERGY EXHAUSTED!] </font>"
			end
		end

		if attacker.Cooldowns then attacker.Cooldowns[skillName] = skill.Cooldown or 0 end
	end

	local DOT_MASKS = {
		Scorch = 1, Poison = 2, Hemorrhage = 4, Frost = 8,
		Acid = 3, Rupture = 5, Infection = 6, Frostburn = 9,
		Decay = 10, Frostbite = 12, Blight = 7, Miasma = 11,
		Necrosis = 13, Plague = 14, Calamity = 15
	}

	local MASK_TO_DOT = {
		[1] = {"Scorch", "#FF5500"}, [2] = {"Poison", "#AA00AA"}, [3] = {"Acid", "#80FF00"},
		[4] = {"Hemorrhage", "#FF0000"}, [5] = {"Rupture", "#FF4400"}, [6] = {"Infection", "#800000"},
		[7] = {"Blight", "#4B0082"}, [8] = {"Frost", "#66CCFF"}, [9] = {"Frostburn", "#55AAFF"},
		[10] = {"Decay", "#00AA55"}, [11] = {"Miasma", "#2E8B57"}, [12] = {"Frostbite", "#0055FF"},
		[13] = {"Necrosis", "#8B4513"}, [14] = {"Plague", "#556B2F"}, [15] = {"Calamity", "#CC00FF"}
	}

	local T0_TO_MASK = {
		Burn = 1, Sick = 2, Bleed = 4, Chill = 8
	}

	local T0_COLORS = {
		Burn = "#FF8844", Sick = "#CC55CC", Bleed = "#FF5555", Chill = "#99DDFF"
	}

	local function CheckElementMatch(elements, eName)
		if not elements or type(elements) ~= "table" then return false end
		if table.find(elements, "All") then return true end
		if table.find(elements, eName) then return true end
		if table.find(elements, "Debuffs") and string.match(eName, "Debuff_") then return true end
		if table.find(elements, "SpeedDebuff") and eName == "Debuff_Speed" then return true end
		return false
	end

	local function ApplyCC(effectName, duration, tgt, colorHex, overrideMsg)
		if effectName == "Chilly" then effectName = "Chill" end

		local originAttacker = b
		if originAttacker and originAttacker.ActivePassives then
			for _, p in ipairs(originAttacker.ActivePassives) do
				if p.Effects then
					for _, effData in ipairs(p.Effects) do
						if effData.Type == "StatusUpgrade" and effData.From == effectName then
							effectName = effData.To
						end
					end
				end
			end

			for _, p in ipairs(originAttacker.ActivePassives) do
				if p.Effects then
					for _, effData in ipairs(p.Effects) do
						if effData.Type == "OutgoingStatusDuration" and CheckElementMatch(effData.Elements, effectName) then
							duration += effData.Value
						end
					end
				end
			end
		end

		if tgt and tgt.ActivePassives then
			for _, p in ipairs(tgt.ActivePassives) do
				if p.Effects then
					for _, effData in ipairs(p.Effects) do
						if effData.Type == "IncomingStatusDuration" and CheckElementMatch(effData.Elements, effectName) then
							duration += effData.Value
						end
					end
				end
			end
		end

		duration = math.max(1, duration)

		if (tgt.Statuses.Warded or 0) > 0 then
			return " <font color='#AAAAAA'>(Warded! Status Blocked!)</font>"
		end

		if CombatCore.HasModifier(uniModStr, "Unstable") and (T0_TO_MASK[effectName] or DOT_MASKS[effectName]) then
			duration = 1
		end

		if effectName == "Stun" then
			if (tgt.StunImmunity and tgt.StunImmunity > 0) or (tgt.Statuses.Stun and tgt.Statuses.Stun > 0) then
				tgt.Statuses.Dizzy = math.max(tgt.Statuses.Dizzy or 0, duration)
				return " <font color='#AAAAAA'>(Stun Resisted! Applied <font color='#E6E600'>Dizzy</font> instead!)</font>"
			else
				tgt.Statuses.Stun = duration; tgt.StunImmunity = duration + (tgt.IsBoss and 4 or 2)
				return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end

		elseif effectName == "Freeze" then
			if (tgt.StunImmunity and tgt.StunImmunity > 0) or (tgt.Statuses.Freeze and tgt.Statuses.Freeze > 0) then
				return ApplyCC("Frost", duration, tgt, "#66CCFF", "Frost")
			else
				local active_mask = 8
				local maxDuration = duration
				local willMerge = false

				for dot, mask in pairs(DOT_MASKS) do
					if (tgt.Statuses[dot] or 0) > 0 then
						maxDuration = math.max(maxDuration, tgt.Statuses[dot])
						active_mask = bit32.bor(active_mask, mask)
						willMerge = true
					end
				end

				if active_mask > 8 then
					for dot, mask in pairs(DOT_MASKS) do
						if (tgt.Statuses[dot] or 0) > 0 then tgt.Statuses[dot] = 0 end
					end

					local newEffectData = MASK_TO_DOT[active_mask]
					local resultEffect = newEffectData[1]
					local resultColor = newEffectData[2]

					tgt.Statuses[resultEffect] = maxDuration
					tgt.Statuses.Stun = math.max(tgt.Statuses.Stun or 0, duration)
					tgt.StunImmunity = duration + (tgt.IsBoss and 4 or 2)

					if bit32.band(active_mask, 1) > 0 then tgt.Statuses.Burn = 0 end
					if bit32.band(active_mask, 2) > 0 then tgt.Statuses.Sick = 0 end
					if bit32.band(active_mask, 4) > 0 then tgt.Statuses.Bleed = 0 end
					if bit32.band(active_mask, 8) > 0 then tgt.Statuses.Chill = 0 end

					return " <font color='" .. resultColor .. "'>(" .. resultEffect .. " + Stun!)</font>"
				else
					tgt.Statuses.Freeze = duration; tgt.StunImmunity = duration + (tgt.IsBoss and 4 or 2)
					return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
				end
			end

		elseif effectName == "Confusion" then
			if (tgt.ConfusionImmunity and tgt.ConfusionImmunity > 0) or (tgt.Statuses.Confusion and tgt.Statuses.Confusion > 0) then
				tgt.Statuses.Dizzy = math.max(tgt.Statuses.Dizzy or 0, duration)
				return " <font color='#AAAAAA'>(Confusion Resisted! Applied <font color='#E6E600'>Dizzy</font> instead!)</font>"
			else
				tgt.Statuses.Confusion = duration; tgt.ConfusionImmunity = duration + (tgt.IsBoss and 6 or 3)
				return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end

		elseif T0_TO_MASK[effectName] then
			local active_mask = 0
			for dot, mask in pairs(DOT_MASKS) do
				if (tgt.Statuses[dot] or 0) > 0 then
					active_mask = bit32.bor(active_mask, mask)
				end
			end

			if (tgt.Statuses.Freeze or 0) > 0 then
				active_mask = bit32.bor(active_mask, 8)
			end

			if bit32.band(active_mask, T0_TO_MASK[effectName]) > 0 then
				return ""
			else
				tgt.Statuses[effectName] = math.max(tgt.Statuses[effectName] or 0, duration)
				return " <font color='" .. (colorHex or T0_COLORS[effectName]) .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end

		elseif DOT_MASKS[effectName] then
			local incoming_mask = DOT_MASKS[effectName]
			local active_mask = incoming_mask
			local maxDuration = duration
			local freezeSplit = false
			local freezeDur = 0

			for dot, mask in pairs(DOT_MASKS) do
				if (tgt.Statuses[dot] or 0) > 0 then
					maxDuration = math.max(maxDuration, tgt.Statuses[dot])
					active_mask = bit32.bor(active_mask, mask)
					tgt.Statuses[dot] = 0
				end
			end

			if (tgt.Statuses.Freeze or 0) > 0 then
				freezeDur = tgt.Statuses.Freeze
				maxDuration = math.max(maxDuration, freezeDur)
				active_mask = bit32.bor(active_mask, 8)
				freezeSplit = true
			end

			local newEffectData = MASK_TO_DOT[active_mask]
			local resultEffect = newEffectData[1]
			local resultColor = newEffectData[2]

			if freezeSplit and active_mask > 8 then
				tgt.Statuses.Freeze = 0
				tgt.Statuses.Stun = math.max(tgt.Statuses.Stun or 0, freezeDur)
			end

			tgt.Statuses[resultEffect] = maxDuration

			if bit32.band(active_mask, 1) > 0 then tgt.Statuses.Burn = 0 end
			if bit32.band(active_mask, 2) > 0 then tgt.Statuses.Sick = 0 end
			if bit32.band(active_mask, 4) > 0 then tgt.Statuses.Bleed = 0 end
			if bit32.band(active_mask, 8) > 0 then tgt.Statuses.Chill = 0 end

			local msgEffect = resultEffect
			if resultEffect == effectName and overrideMsg then
				msgEffect = overrideMsg
			end

			local extraMsg = (freezeSplit and active_mask > 8) and " + Stun" or ""
			return " <font color='" .. resultColor .. "'>(" .. msgEffect .. extraMsg .. "!)</font>"
		else
			tgt.Statuses[effectName] = math.max(tgt.Statuses[effectName] or 0, duration)
			return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
		end
	end

	if skill.Effect == "Block" then
		b.BlockTurns = 2; return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! " .. bName .. " reduces incoming damage.", false, "None", b

	elseif skill.Effect == "Counter" then
		b.CounterTurns = 2; return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#55AAFF'>" .. bName .. " readies a counter-stance.</font>", false, "None", b

	elseif skill.Effect == "Rest" or skill.Effect == "CleanseRest" then
		local clearedStatuses = false
		if skill.Effect == "CleanseRest" and b.Statuses then
			local toClear = {
				"Sick", "Poison", "Burn", "Scorch", "Bleed", "Hemorrhage", "Chill", "Frost", 
				"Stun", "Freeze", "Confusion", "Debuff_Strength", "Debuff_Defense", "Debuff_Speed", "Debuff_Willpower", 
				"StaminaExhausted", "EnergyExhausted", "Dizzy", "Acid", "Infection", "Rupture", "Frostburn", "Frostbite", "Decay",
				"Blight", "Miasma", "Necrosis", "Plague", "Calamity"
			}
			for _, st in ipairs(toClear) do
				if (b.Statuses[st] or 0) > 0 then
					b.Statuses[st] = 0
					clearedStatuses = true
				end
			end
		end

		local purifyCount = CombatCore.CountTrait(b, "Purifying")
		if clearedStatuses and purifyCount > 0 then
			local healAmt = (b.MaxHP or 100) * (0.10 * purifyCount)
			b.HP = math.min(b.MaxHP, b.HP + healAmt)
			msgPrefix = msgPrefix .. "<font color='#55FF55'>[Purified +"..math.floor(healAmt).." HP!] </font>"
		end

		local restPct = CombatCore.HasModifier(uniModStr, "Resource Drought") and 0.10 or 0.20
		local stamRestAmount = math.floor((b.MaxStamina or 100) * restPct)
		local nrgRestAmount = math.floor((b.MaxStandEnergy or 100) * restPct)

		if b.MaxStamina then b.Stamina = math.min(b.MaxStamina, (b.Stamina or 0) + stamRestAmount) end
		if b.MaxStandEnergy then b.StandEnergy = math.min(b.MaxStandEnergy, (b.StandEnergy or 0) + nrgRestAmount) end

		local appliedWarded = false
		if b.BlockTurns and b.BlockTurns > 0 then
			if b.Statuses then b.Statuses.Warded = 2 end
			appliedWarded = true
		end

		if clearedStatuses and appliedWarded then
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b> behind their guard! <font color='#55FFFF'>" .. bName .. " restores resources, Cleanses ailments, and gains Warded!</font>", false, "None", b
		elseif clearedStatuses then
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#55FFFF'>" .. bName .. " takes a deep breath, restoring resources and Cleansing all ailments!</font>", false, "None", b
		elseif appliedWarded then
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b> behind their guard! <font color='#55FF55'>" .. bName .. " rests, recovering Stamina and Energy, and gains Warded!</font>", false, "None", b
		else
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#55FF55'>" .. bName .. " rests, recovering Stamina and Energy.</font>", false, "None", b
		end

	elseif skill.Effect == "Heal" then
		local healAmount = (b.MaxHP or 100) * (skill.HealPercent or 0.25)
		b.HP = math.min(b.MaxHP or b.HP, b.HP + healAmount)
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b> and recovered <font color='#55FF55'>" .. math.floor(healAmount) .. " HP</font> for " .. bName .. "!", false, "None", b
	elseif skill.Effect == "TimeRewind" then
		local lostHP = (b.MaxHP or b.HP) - b.HP
		local healAmount = lostHP * 0.5 
		b.HP = math.min(b.MaxHP or b.HP, b.HP + healAmount)
		if b.Statuses then
			b.Statuses.Sick = 0; b.Statuses.Poison = 0; b.Statuses.Burn = 0; b.Statuses.Scorch = 0; b.Statuses.Bleed = 0; b.Statuses.Hemorrhage = 0; b.Statuses.Chill = 0; b.Statuses.Frost = 0; b.Statuses.Freeze = 0; b.Statuses.Confusion = 0
			b.Statuses.Acid = 0; b.Statuses.Infection = 0; b.Statuses.Rupture = 0; b.Statuses.Frostburn = 0; b.Statuses.Frostbite = 0; b.Statuses.Decay = 0
			b.Statuses.Blight = 0; b.Statuses.Miasma = 0; b.Statuses.Necrosis = 0; b.Statuses.Plague = 0; b.Statuses.Calamity = 0; b.Statuses.Warded = 0
		end
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF55FF'>Bites the Dust activates! Rewinding time to restore " .. math.floor(healAmount) .. " HP and clear ailments for " .. bName .. "!</font>", false, "Heavy", b
	elseif skill.Effect == "TimeReset" then
		local lostHP = (b.MaxHP or b.HP) - b.HP
		local healAmount = lostHP * 0.25 
		b.HP = math.min(b.MaxHP or b.HP, b.HP + healAmount)
		if b.Statuses then
			b.Statuses.Sick = 0; b.Statuses.Poison = 0; b.Statuses.Burn = 0; b.Statuses.Scorch = 0; b.Statuses.Bleed = 0; b.Statuses.Hemorrhage = 0; b.Statuses.Chill = 0; b.Statuses.Frost = 0; b.Statuses.Freeze = 0; b.Statuses.Confusion = 0
			b.Statuses.Acid = 0; b.Statuses.Infection = 0; b.Statuses.Rupture = 0; b.Statuses.Frostburn = 0; b.Statuses.Frostbite = 0; b.Statuses.Decay = 0
			b.Statuses.Blight = 0; b.Statuses.Miasma = 0; b.Statuses.Necrosis = 0; b.Statuses.Plague = 0; b.Statuses.Calamity = 0; b.Statuses.Warded = 0
		end
		local ccMsg = ""
		if t and t.Statuses then
			ccMsg = ApplyCC("Confusion", 2, t, "#FF55FF", "Confused")
		end
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF55FF'>Made in Heaven activates! The universe begins to restart... restoring " .. math.floor(healAmount) .. " HP for " .. bName .. " and disorienting " .. tName .. "!</font>" .. ccMsg, false, "Heavy", b
	elseif skill.Effect == "ReturnToZero" then
		b.HP = b.MaxHP or b.HP
		if b.Statuses then
			b.Statuses.Sick = 0; b.Statuses.Poison = 0; b.Statuses.Burn = 0; b.Statuses.Scorch = 0; b.Statuses.Bleed = 0; b.Statuses.Hemorrhage = 0; b.Statuses.Chill = 0; b.Statuses.Frost = 0; b.Statuses.Freeze = 0; b.Statuses.Confusion = 0
			b.Statuses.Acid = 0; b.Statuses.Infection = 0; b.Statuses.Rupture = 0; b.Statuses.Frostburn = 0; b.Statuses.Frostbite = 0; b.Statuses.Decay = 0
			b.Statuses.Blight = 0; b.Statuses.Miasma = 0; b.Statuses.Necrosis = 0; b.Statuses.Plague = 0; b.Statuses.Calamity = 0; b.Statuses.Warded = 0
		end
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FFD700'>Return to Zero! Reality is reset, fully restoring " .. bName .. " and nullifying all negative effects.</font>", false, "Heavy", b
	elseif skill.Effect == "TimeErase" then
		b.Statuses.Buff_Speed = skill.Duration or 2
		local ccMsg = ApplyCC("Stun", skill.Duration or 2, t, "#FF0000")
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF0000'>Time is erased, boosting Speed!</font>" .. ccMsg, false, "Light", b
	elseif skill.Effect == "TimeStop" then
		local ccMsg = ApplyCC("Stun", skill.Duration or 2, t, "#FFFFFF", "Time Stopped")
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#AAAAAA'>Time comes to a halt...</font>" .. ccMsg, false, "Heavy", b
	elseif skill.Effect == "Buff_Random" then
		local stats = {"Strength", "Defense", "Speed", "Willpower"}
		local s = stats[math.random(1, 4)]
		b.Statuses["Buff_"..s] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FFFF55'>" .. bName .. "'s " .. s .. " is boosted!</font>", false, "None", b
	elseif skill.Effect and string.sub(skill.Effect, 1, 5) == "Buff_" then
		local statName = string.sub(skill.Effect, 6); b.Statuses[skill.Effect] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FFFF55'>" .. bName .. "'s " .. statName .. " is boosted!</font>", false, "None", b
	elseif skill.Effect == "Debuff_Random" then
		if (t.Statuses.Warded or 0) > 0 then
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#AAAAAA'>But " .. tName .. " is Warded!</font>", false, "None", t
		end
		local stats = {"Strength", "Defense", "Speed", "Willpower"}
		local s = stats[math.random(1, 4)]
		t.Statuses["Debuff_"..s] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF5555'>" .. tName .. "'s " .. s .. " is reduced!</font>", false, "None", t
	elseif skill.Effect and string.sub(skill.Effect, 1, 7) == "Debuff_" then
		if (t.Statuses.Warded or 0) > 0 then
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#AAAAAA'>But " .. tName .. " is Warded!</font>", false, "None", t
		end
		local statName = string.sub(skill.Effect, 8); t.Statuses[skill.Effect] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF5555'>" .. tName .. "'s " .. statName .. " is reduced!</font>", false, "None", t
	end

	local hitsToDo = skill.Hits or 1
	local isUnavoidable = (skillName == "Time Stop" or skillName == "ZA WARUDO!")
	local msg = msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>" .. (hitsToDo == 1 and "" or "!")
	local hitLogs = {}
	local didHitAtAll = false
	local overallShake = "None"
	local effectApplied = false

	for i = 1, hitsToDo do
		if t.HP < 1 and i > 1 then break end 

		local atkSpdBuff = (((attacker.Statuses and attacker.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((attacker.Statuses and attacker.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		local defSpdBuff = (((t.Statuses and t.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((t.Statuses and t.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		local atkSpd = (attacker.TotalSpeed or 1) * atkSpdBuff
		local defSpd = (t.TotalSpeed or 1) * defSpdBuff

		if attacker.IsPlayer then
			if CombatCore.HasModifier(uniModStr, "Speed of Light") then atkSpd *= 1.5 end
			if CombatCore.HasModifier(uniModStr, "Heavy Gravity") then atkSpd *= 0.75 end
			if CombatCore.HasModifier(uniModStr, "Brisk Pace") then atkSpd *= 1.1 end
			if CombatCore.HasModifier(uniModStr, "Sluggish") then atkSpd *= 0.9 end
		end
		if t.IsPlayer then
			if CombatCore.HasModifier(uniModStr, "Speed of Light") then defSpd *= 1.5 end
			if CombatCore.HasModifier(uniModStr, "Heavy Gravity") then defSpd *= 0.75 end
			if CombatCore.HasModifier(uniModStr, "Brisk Pace") then defSpd *= 1.1 end
			if CombatCore.HasModifier(uniModStr, "Sluggish") then defSpd *= 0.9 end
		end

		local dodgeChance = math.clamp(5 + (defSpd - atkSpd) * 0.2, 5, 50)
		dodgeChance = math.max(0, dodgeChance - ((attacker.TotalRange or 0) * 0.1))

		dodgeChance += (10 * CombatCore.CountTrait(t, "Swift"))
		dodgeChance += (20 * CombatCore.CountTrait(t, "Evasive"))
		dodgeChance += (5 * CombatCore.CountTrait(t, "Lucky"))
		dodgeChance += (25 * CombatCore.CountTrait(t, "Blessed"))

		dodgeChance = math.min(dodgeChance, 80)

		local dodged = false
		if not isUnavoidable and (t.Statuses and t.Statuses.Stun or 0) == 0 and (t.Statuses and t.Statuses.Freeze or 0) == 0 and math.random(1, 100) <= dodgeChance then
			dodged = true
		end

		if dodged then
			if hitsToDo == 1 then return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>, but " .. tName .. " dodged!", false, "None"
			else table.insert(hitLogs, "<font color='#AAAAAA'>- Hit " .. i .. " missed!</font>") end
			continue
		end

		didHitAtAll = true
		local atkWillBuff = (((attacker.Statuses and attacker.Statuses.Buff_Willpower or 0) > 0) and 1.5 or 1.0) * (((attacker.Statuses and attacker.Statuses.Debuff_Willpower or 0) > 0) and 0.5 or 1.0)
		local atkWill = (attacker.TotalWillpower or 1) * atkWillBuff
		if attacker.IsPlayer then
			if CombatCore.HasModifier(uniModStr, "Determined") then atkWill *= 1.1 end
			if CombatCore.HasModifier(uniModStr, "Faltering") then atkWill *= 0.9 end
		end

		local critChance = math.clamp(5 + (atkWill * 0.5) + ((attacker.TotalPrecision or 0) * 0.2), 5, 75)
		critChance += (15 * CombatCore.CountTrait(attacker, "Brutal"))
		critChance += (5 * CombatCore.CountTrait(attacker, "Lucky"))
		critChance += (25 * CombatCore.CountTrait(attacker, "Blessed"))

		critChance = math.min(critChance, 100)

		local isCrit = math.random(1, 100) <= critChance
		local critMult = 1.5 + (1.5 * CombatCore.CountTrait(attacker, "Lethal"))

		local treeMult = attacker.TreeDamageMult or 1.0
		local mult = skill.Mult * treeMult * (isCrit and critMult or 1.0)

		local relCount = CombatCore.CountTrait(attacker, "Relentless")
		if relCount > 0 then mult *= (1.15 ^ relCount) end

		local ohCount = CombatCore.CountTrait(attacker, "Overheaven")
		if ohCount > 0 then mult *= (1.30 ^ ohCount) end

		local reqCount = CombatCore.CountTrait(attacker, "Requiem")
		if reqCount > 0 then mult *= (1.50 ^ reqCount) end

		if attacker.FusionDamageBonus and attacker.FusionDamageBonus > 0 then
			mult += (attacker.FusionDamageBonus / hitsToDo)
		end

		local gachaMsg = ""
		local gachaCount = CombatCore.CountTrait(attacker, "Gambling Addict")
		if gachaCount > 0 then
			local roulette = math.random(1, 100)
			if roulette == 1 then
				mult = 99999
				gachaMsg = " <font color='#FFD700'>...JACKPOT!</font>"
			elseif roulette == 100 then
				b.HP = 0
				mult = 0
				gachaMsg = " <font color='#FF0000'>...BANKRUPT! (Instantly died!)</font>"
			end
		end

		local isBlocking = (t.BlockTurns or 0) > 0
		local isCountering = (t.CounterTurns or 0) > 0

		local damage = CombatCore.CalculateDamage(attacker, t, mult, isBlocking, uniModStr, skill)

		if isCountering and damage > 0 then
			t.CounterTurns = 0

			local reflectedDmg = math.max(1, damage)
			local counterSurvival = CombatCore.TakeDamageWithWillpower(attacker, reflectedDmg)

			local cMsg = " <font color='#55AAFF'>(COUNTERED! " .. tName .. " predicted it, evading completely and striking back for " .. math.floor(reflectedDmg) .. " damage!)</font>"
			if counterSurvival then cMsg = cMsg .. " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>" end

			if hitsToDo == 1 then
				msg = msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>... but it was caught! " .. cMsg
			else
				table.insert(hitLogs, "<font color='#AAAAAA'>- Hit " .. i .. " triggered a trap...</font>" .. cMsg)
			end

			didHitAtAll = true
			overallShake = "Heavy"

			break
		end

		local survivalTriggered = CombatCore.TakeDamageWithWillpower(t, damage)

		if isCrit or survivalTriggered then overallShake = "Heavy" elseif isBlocking and overallShake == "None" then overallShake = "Light" elseif overallShake == "None" then overallShake = "Normal" end

		local hitMsg = hitsToDo == 1 and (msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b> and dealt " .. math.floor(damage) .. " damage to " .. tName .. "!") or ("- Hit " .. i .. " dealt " .. math.floor(damage) .. " damage")
		if isBlocking then hitMsg = hitMsg .. " <font color='#AAAAAA'>(Blocked)</font>" end
		if isCrit then hitMsg = hitMsg .. " <font color='#FFAA00'>(CRIT!)</font>" end
		if gachaMsg ~= "" then hitMsg = hitMsg .. gachaMsg end

		if survivalTriggered then 
			local persCount = CombatCore.CountTrait(t, "Perseverance")
			if persCount > 0 then
				hitMsg = hitMsg .. " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED! (+".. (25 * persCount) .."% HP)</font>"
			else
				hitMsg = hitMsg .. " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>"
			end
		end

		local postMsg = ""
		local vampCount = CombatCore.CountTrait(attacker, "Vampiric")
		if vampCount > 0 and damage > 0 then
			local vHeal = damage * (0.20 * vampCount); attacker.HP = math.min(attacker.MaxHP, attacker.HP + vHeal)
			postMsg = postMsg .. " <font color='#AA00AA'>(Healed " .. math.floor(vHeal) .. ")</font>"
		end

		local oppCount = CombatCore.CountTrait(attacker, "Opportunistic")
		if oppCount > 0 and math.random(1, 100) <= (10 * oppCount) then
			attacker.CounterTurns = math.max(attacker.CounterTurns or 0, 2)
			postMsg = postMsg .. " <font color='#55AAFF'>(Opportunistic Counter!)</font>"
		end

		if CombatCore.HasModifier(uniModStr, "Vampiric Night") and not attacker.IsPlayer and not attacker.IsAlly and damage > 0 then
			local nHeal = damage * 0.05; attacker.HP = math.min(attacker.MaxHP, attacker.HP + nHeal)
			postMsg = postMsg .. " <font color='#AA00AA'>(Night Heal: " .. math.floor(nHeal) .. ")</font>"
		end

		if damage > 0 and not isBlocking then
			local pctDamage = math.clamp(damage / (t.MaxHP or 1), 0, 1)

			local shatterCount = CombatCore.CountTrait(attacker, "Shattering")
			local baseExhaust = CombatCore.HasModifier(uniModStr, "Aggressive Attrition") and 1.5 or 0.75
			local exhaustMult = baseExhaust + (0.5 * shatterCount)

			local stoicCount = CombatCore.CountTrait(t, "Stoic")
			local stoicMult = 0.5 ^ stoicCount

			local stamDrain = math.floor((t.MaxStamina or 100) * (pctDamage * exhaustMult) * stoicMult)
			local nrgDrain = math.floor((t.MaxStandEnergy or 100) * (pctDamage * exhaustMult) * stoicMult)

			if t.Stamina then
				t.Stamina = math.max(0, t.Stamina - stamDrain)
				if t.Stamina == 0 and (t.Statuses.StaminaExhausted or 0) == 0 then
					t.Statuses.StaminaExhausted = 3
					postMsg = postMsg .. " <font color='#AAAAAA'>(Stamina Broken!)</font>"
				end
			end
			if t.StandEnergy then
				t.StandEnergy = math.max(0, t.StandEnergy - nrgDrain)
				if t.StandEnergy == 0 and (t.Statuses.EnergyExhausted or 0) == 0 then
					t.Statuses.EnergyExhausted = 3
					postMsg = postMsg .. " <font color='#A020F0'>(Energy Broken!)</font>"
				end
			end

			local siphonCount = CombatCore.CountTrait(attacker, "Siphoning")
			if siphonCount > 0 then
				local siphonedStam = math.floor(stamDrain * 0.10 * siphonCount)
				local siphonedNrg = math.floor(nrgDrain * 0.10 * siphonCount)
				if siphonedStam > 0 or siphonedNrg > 0 then
					if attacker.Stamina then attacker.Stamina = math.min(attacker.MaxStamina, attacker.Stamina + siphonedStam) end
					if attacker.StandEnergy then attacker.StandEnergy = math.min(attacker.MaxStandEnergy, attacker.StandEnergy + siphonedNrg) end
					postMsg = postMsg .. " <font color='#8B008B'>(Siphoned " .. (siphonedStam + siphonedNrg) .. " Resources)</font>"
				end
			end

			local elecCount = CombatCore.CountTrait(attacker, "Electric")
			local frozCount = CombatCore.CountTrait(attacker, "Frozen")
			local flameCount = CombatCore.CountTrait(attacker, "Flaming")
			local toxCount = CombatCore.CountTrait(attacker, "Toxic")
			local serrCount = CombatCore.CountTrait(attacker, "Serrated")
			local disCount = CombatCore.CountTrait(attacker, "Disorienting")
			local gamCount = CombatCore.CountTrait(attacker, "Gambler")
			local glCount = CombatCore.CountTrait(attacker, "Gloomy")
			local chCount = CombatCore.CountTrait(attacker, "Cheerful")

			if elecCount > 0 and math.random(1, 100) <= (10 * elecCount) then postMsg = postMsg .. ApplyCC("Stun", 1, t, "#FFFF55", "Shocked")
			elseif frozCount > 0 and math.random(1, 100) <= (10 * frozCount) then postMsg = postMsg .. ApplyCC("Freeze", 1, t, "#00FFFF", "Frozen")
			elseif flameCount > 0 and math.random(1, 100) <= (10 * flameCount) then postMsg = postMsg .. ApplyCC("Scorch", 3, t, "#FF5500", "Ignited")
			elseif toxCount > 0 and math.random(1, 100) <= (10 * toxCount) then postMsg = postMsg .. ApplyCC("Poison", 3, t, "#AA00AA", "Infected")
			elseif serrCount > 0 and math.random(1, 100) <= (10 * serrCount) then postMsg = postMsg .. ApplyCC("Hemorrhage", 3, t, "#FF0000", "Bled")
			elseif disCount > 0 and math.random(1, 100) <= (10 * disCount) then postMsg = postMsg .. ApplyCC("Confusion", 1, t, "#FF55FF", "Confused")
			elseif gamCount > 0 and math.random(1, 100) <= (10 * gamCount) then
				local pick = ({{ "Hemorrhage", "#FF0000" }, { "Poison", "#AA00AA" }, { "Scorch", "#FF5500" }, { "Confusion", "#FF55FF" }, { "Stun", "#FFFF55" }, { "Freeze", "#00FFFF" }})[math.random(1, 6)]
				postMsg = postMsg .. ApplyCC(pick[1], 2, t, pick[2], "Gambler: " .. pick[1])
			elseif glCount > 0 and math.random(1, 100) <= (10 * glCount) then
				if (t.Statuses.Warded or 0) == 0 then
					local s = {"Strength", "Defense", "Speed", "Willpower"}
					t.Statuses["Debuff_"..s[math.random(1,4)]] = 3
					postMsg = postMsg .. " <font color='#FF5555'>(Gloomy Debuff!)</font>"
				end
			elseif chCount > 0 and math.random(1, 100) <= (10 * chCount) then
				local s = {"Strength", "Defense", "Speed", "Willpower"}
				b.Statuses["Buff_"..s[math.random(1,4)]] = 3
				postMsg = postMsg .. " <font color='#55FF55'>(Cheerful Buff!)</font>"
			end
		end

		if skill.Effect == "Lifesteal" then
			local heal = damage * 0.5; attacker.HP = math.min(attacker.MaxHP, attacker.HP + heal)
			postMsg = postMsg .. " <font color='#55FF55'>(Lifesteal)</font>"
		end

		if not effectApplied then
			local eff = skill.Effect
			local duration = skill.Duration or 2

			if eff and attacker.ActivePassives then
				for _, p in ipairs(attacker.ActivePassives) do
					if p.Effects then
						for _, effData in ipairs(p.Effects) do
							if effData.Type == "StatusUpgrade" and effData.From == eff then
								eff = effData.To
							end
						end
					end
				end
			end

			local statColors = { 
				Stun = "#FFFF55", Freeze = "#00FFFF", Confusion = "#FF55FF",
				Burn = "#FF8844", Sick = "#CC55CC", Bleed = "#FF5555", Chill = "#99DDFF",
				Scorch = "#FF5500", Poison = "#AA00AA", Hemorrhage = "#FF0000", Frost = "#66CCFF",
				Acid = "#80FF00", Infection = "#800000", Rupture = "#FF4400", Frostburn = "#55AAFF", Frostbite = "#0055FF", Decay = "#00AA55",
				Blight = "#4B0082", Miasma = "#2E8B57", Necrosis = "#8B4513", Plague = "#556B2F", Calamity = "#CC00FF"
			}

			if statColors[eff] then
				postMsg = postMsg .. ApplyCC(eff, duration, t, statColors[eff])
				effectApplied = true
			elseif eff == "Status_Random" then
				local effs = { {"Hemorrhage", "#FF0000"}, {"Poison", "#AA00AA"}, {"Scorch", "#FF5500"}, {"Confusion", "#FF55FF"}, {"Stun", "#FFFF55"}, {"Freeze", "#00FFFF"} }
				local pick = effs[math.random(1, #effs)]
				postMsg = postMsg .. ApplyCC(pick[1], duration, t, pick[2])
				effectApplied = true
			end
		end

		if hitsToDo == 1 then msg = hitMsg .. postMsg else table.insert(hitLogs, hitMsg .. postMsg) end

		CombatCore.HandleInfectiousSpread(attacker, t)
		if attacker.HP < 1 or t.HP < 1 then break end
	end

	if hitsToDo > 1 then
		if not didHitAtAll then msg = msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>, but " .. tName .. " dodged completely!"
		else msg = msg .. "\n" .. table.concat(hitLogs, "\n") end
	end

	return msg, didHitAtAll, overallShake, t
end

return CombatCore