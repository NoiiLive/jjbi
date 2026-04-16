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

local TotalValidFusions = nil
local ValidStandsForFusion = nil

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

	local sPow = hasStand and (player:GetAttribute("Stand_Power_Val") or 0) or 0
	local sDur = hasStand and (player:GetAttribute("Stand_Durability_Val") or 0) or 0
	local sSpd = hasStand and (player:GetAttribute("Stand_Speed_Val") or 0) or 0
	local sPot = hasStand and (player:GetAttribute("Stand_Potential_Val") or 0) or 0
	local sRan = hasStand and (player:GetAttribute("Stand_Range_Val") or 0) or 0
	local sPre = hasStand and (player:GetAttribute("Stand_Precision_Val") or 0) or 0

	local pHP, pStyleStr, pStandStr, pDef, pSpd, pWill, pStamina, pStandEnergy

	if isRawStats then
		pHP = (player:GetAttribute("Health") or 1) + CombatCore.GetEquipBonus(player, "Health")
		pStyleStr = (player:GetAttribute("Strength") or 1) + CombatCore.GetEquipBonus(player, "Strength")
		pStandStr = sPow + CombatCore.GetEquipBonus(player, "Stand_Power")
		pDef = (player:GetAttribute("Defense") or 1) + sDur + CombatCore.GetEquipBonus(player, "Defense") + CombatCore.GetEquipBonus(player, "Stand_Durability")
		pSpd = (player:GetAttribute("Speed") or 1) + sSpd + CombatCore.GetEquipBonus(player, "Speed") + CombatCore.GetEquipBonus(player, "Stand_Speed")
		pWill = (player:GetAttribute("Willpower") or 1) + CombatCore.GetEquipBonus(player, "Willpower")
		pStamina = (player:GetAttribute("Stamina") or 1) + CombatCore.GetEquipBonus(player, "Stamina")
		pStandEnergy = 10 + sPot + CombatCore.GetEquipBonus(player, "Stand_Potential")
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

	local sName = player:GetAttribute("Stand") or "None"
	local fStyle = player:GetAttribute("FightingStyle") or "None"

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

		local completedStands = 0
		for s1, data in pairs(fusionCounts) do
			if data.Count >= TotalValidFusions then
				completedStands += 1
			end
		end
		fusionBonusMult = completedStands * 0.01
	end

	if sName == "Fused Stand" then
		local fs1 = player:GetAttribute("Active_FusedStand1") or "None"
		local fs2 = player:GetAttribute("Active_FusedStand2") or "None"
		local fusedSkills = FusionUtility.CalculateFusedAbilities(fs1, fs2, SkillData)
		for _, sk in ipairs(fusedSkills) do table.insert(validSkills, sk.Name) end
	end

	for n, s in pairs(SkillData.Skills) do
		local isStandReq = (s.Requirement == sName and sName ~= "Fused Stand")
		if s.Requirement == "None" or isStandReq or s.Requirement == fStyle or (s.Requirement == "AnyStand" and sName ~= "None") then
			table.insert(validSkills, n)
		end
	end

	return {
		Player = player, UserId = player.UserId, Name = player.Name, IsPlayer = true, PlayerObj = player,
		Trait = playerTrait, Traits = activeTraits, GlobalDmgBoost = activeBoosts.Damage, Boosts = activeBoosts,
		Stand = sName, Style = fStyle, FusionDamageBonus = fusionBonusMult,
		HP = pHP * 20, MaxHP = pHP * 20, Stamina = pStamina, MaxStamina = pStamina, StandEnergy = pStandEnergy, MaxStandEnergy = pStandEnergy,

		StyleStrength = pStyleStr, StandStrength = pStandStr, 
		TotalStrength = pStyleStr + pStandStr,

		TotalDefense = pDef, TotalSpeed = pSpd,
		TotalWillpower = pWill,
		TotalRange = sRan + CombatCore.GetEquipBonus(player, "Stand_Range"), TotalPrecision = sPre + CombatCore.GetEquipBonus(player, "Stand_Precision"),
		BlockTurns = 0, CounterTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { 
			Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, 
			Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, 
			Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0, 
			StaminaExhausted = 0, EnergyExhausted = 0, Dizzy = 0, Chilly = 0, 
			Acid = 0, Infection = 0, Rupture = 0, Frostburn = 0, Frostbite = 0, Decay = 0, 
			Blight = 0, Miasma = 0, Necrosis = 0, Plague = 0, Calamity = 0, Warded = 0 
		}, 
		Cooldowns = {}, SelectedSkill = nil, Skills = validSkills
	}
end

function CombatCore.CalculateDamage(attacker, defender, skillMult, isDefenderBlocking, uniModStr, skillType)
	local junkieCount = CombatCore.CountTrait(attacker, "Junkie")
	if junkieCount > 0 and attacker.Statuses then
		local debuffCount = 0
		local negStats = {"Poison", "Burn", "Bleed", "Freeze", "Confusion", "Stun", "Dizzy", "Chilly", "Acid", "Infection", "Rupture", "Frostburn", "Frostbite", "Decay", "Blight", "Miasma", "Necrosis", "Plague", "Calamity", "Debuff_Strength", "Debuff_Defense", "Debuff_Speed", "Debuff_Willpower", "StaminaExhausted", "EnergyExhausted"}
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

	local offensiveStat = attacker.TotalStrength or 1
	if skillType == "Stand" and attacker.StandStrength then
		offensiveStat = attacker.StandStrength * 2
	elseif skillType == "Style" and attacker.StyleStrength then
		offensiveStat = attacker.StyleStrength * 2
	end

	local baseDmg = offensiveStat * atkBuff * atkDebuff * skillMult

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
	local defBypass = math.min(1, overCount * 0.30)
	local effectiveArmor = ((defender.TotalDefense or 0) * defBuff * defDebuff) * (1 - defBypass)

	if defender.IsPlayer then
		if CombatCore.HasModifier(uniModStr, "Glass Cannon") then effectiveArmor *= 0.75 end
		if CombatCore.HasModifier(uniModStr, "Hardened Armor") then effectiveArmor *= 1.10 end
		if CombatCore.HasModifier(uniModStr, "Brittle Armor") then effectiveArmor *= 0.90 end
	end

	local armorPen = (attacker.TotalRange or 0) * 0.5
	local effectiveDefense = math.max(0, effectiveArmor - armorPen)

	local defenseMultiplier = 100 / (100 + effectiveDefense)

	local exhaustVuln = 0
	if (defender.Statuses.StaminaExhausted or 0) > 0 then exhaustVuln += 0.15 end
	if (defender.Statuses.EnergyExhausted or 0) > 0 then exhaustVuln += 0.15 end

	local finalDmg = baseDmg * defenseMultiplier * (1 + exhaustVuln)

	local armCount = CombatCore.CountTrait(defender, "Armored")
	if armCount > 0 then finalDmg *= (0.85 ^ armCount) end

	local indomCount = CombatCore.CountTrait(defender, "Indomitable")
	if indomCount > 0 and (defender.HP / defender.MaxHP) <= 0.3 then finalDmg *= (0.75 ^ indomCount) end

	if CombatCore.HasModifier(uniModStr, "Fragile Mortality") then finalDmg *= 1.50 end
	if CombatCore.HasModifier(uniModStr, "Iron Skin") then finalDmg *= 0.75 end

	if isDefenderBlocking then finalDmg *= 0.5 end
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
				elseif string.match(sData.Effect or "", "Debuff_") or sData.Effect == "Stun" or sData.Effect == "Freeze" or sData.Effect == "Confusion" or sData.Effect == "Burn" or sData.Effect == "Poison" or sData.Effect == "Bleed" or sData.Effect == "Status_Random" then
					table.insert(categorized.Debuff, sName)
				else
					table.insert(categorized.Attack, sName)
				end
			end
		end
	end

	if #validSkills == 0 then return "Basic Attack" end

	if needsRest and #categorized.Rest > 0 then
		return categorized.Rest[math.random(1, #categorized.Rest)]
	end

	if isLowHp then
		local lowHpPool = {}
		for _, s in ipairs(categorized.Block) do table.insert(lowHpPool, s) end
		for _, s in ipairs(categorized.Buff) do table.insert(lowHpPool, s) end
		if #lowHpPool > 0 and math.random() < 0.7 then
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
			local dots = {"Poison", "Burn", "Bleed", "Freeze", "Acid", "Infection", "Rupture", "Frostburn", "Frostbite", "Decay", "Blight", "Miasma", "Necrosis", "Plague", "Calamity"}
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
	local armorIgnore = math.min(1, domCount * 0.50)

	local defBuff = (combatant.Statuses and (combatant.Statuses.Buff_Defense or 0) > 0) and 1.5 or 1.0
	local defDebuff = (combatant.Statuses and (combatant.Statuses.Debuff_Defense or 0) > 0) and 0.5 or 1.0
	local effectiveArmor = ((combatant.TotalDefense or 0) * defBuff * defDebuff) * (1 - armorIgnore)

	local defMult = 100 / (100 + math.max(0, effectiveArmor))
	local persCount = CombatCore.CountTrait(combatant, "Perseverance")
	local unstableMult = CombatCore.HasModifier(uniModStr, "Unstable") and 2.0 or 1.0

	local function CheckDeath()
		if combatant.HP < 1 then
			if opponent then CombatCore.HandleInfectiousSpread(opponent, combatant) end
			return true
		end
		return false
	end

	local function ProcessDoT(statusName, hexColor, mult)
		if (combatant.Statuses[statusName] or 0) > 0 then
			local dmg = math.max(1, (combatant.MaxHP * statusDmgMod * mult) * defMult) * unstableMult
			local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
			combatant.Statuses[statusName] -= 1
			local svMsg = survived and (persCount > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
			CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='"..hexColor.."'>"..combatant.Name.." took "..math.floor(dmg).." "..statusName.." damage!"..svMsg.."</font>", DidHit = true, ShakeType = "Light"})
			task.wait(waitMultiplier)
		end
	end

	-- Tier 3 Synergy (1.75x)
	ProcessDoT("Calamity", "#CC00FF", 1.75)
	if CheckDeath() then return end

	-- Tier 2 Synergies (1.5x)
	ProcessDoT("Blight", "#4B0082", 1.5)
	if CheckDeath() then return end
	ProcessDoT("Miasma", "#2E8B57", 1.5)
	if CheckDeath() then return end
	ProcessDoT("Necrosis", "#8B4513", 1.5)
	if CheckDeath() then return end
	ProcessDoT("Plague", "#556B2F", 1.5)
	if CheckDeath() then return end

	-- Tier 1 Synergies (1.25x)
	ProcessDoT("Acid", "#80FF00", 1.25)
	if CheckDeath() then return end
	ProcessDoT("Infection", "#800000", 1.25)
	if CheckDeath() then return end
	ProcessDoT("Rupture", "#FF4400", 1.25)
	if CheckDeath() then return end
	ProcessDoT("Frostburn", "#55AAFF", 1.25)
	if CheckDeath() then return end
	ProcessDoT("Frostbite", "#0055FF", 1.25)
	if CheckDeath() then return end
	ProcessDoT("Decay", "#00AA55", 1.25)
	if CheckDeath() then return end

	-- Base DoTs (1.0x)
	ProcessDoT("Bleed", "#FF0000", 1.0)
	if CheckDeath() then return end
	ProcessDoT("Poison", "#AA00AA", 1.0)
	if CheckDeath() then return end
	ProcessDoT("Burn", "#FF5500", 1.0)
	if CheckDeath() then return end

	if (combatant.Statuses.Chilly or 0) > 0 then
		local dmg = math.max(1, (combatant.MaxHP * statusDmgMod) * defMult)
		local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
		combatant.Statuses.Chilly -= 1
		local svMsg = survived and (persCount > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#66CCFF'>"..combatant.Name.." shivers, taking "..math.floor(dmg).." Chilly damage!</font>"..svMsg, DidHit = true, ShakeType = "Light"})
		task.wait(waitMultiplier)
	end
	if CheckDeath() then return end

	if combatant.Statuses.Freeze > 0 then
		local dmg = math.max(1, (combatant.MaxHP * statusDmgMod) * defMult)
		local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
		combatant.Statuses.Freeze -= 1
		local svMsg = survived and (persCount > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#00FFFF'>"..combatant.Name.." took "..math.floor(dmg).." Freeze damage and is frozen solid!"..svMsg.."</font>", DidHit = true, ShakeType = "Light"})
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
		t = attacker; tName = fLogName; b = defender; bName = fDefName
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

	local function ApplyCC(effectName, duration, tgt, colorHex, overrideMsg)
		if (tgt.Statuses.Warded or 0) > 0 then
			return " <font color='#AAAAAA'>(Warded! Status Blocked!)</font>"
		end

		if CombatCore.HasModifier(uniModStr, "Unstable") and (effectName == "Bleed" or effectName == "Poison" or effectName == "Burn") then
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
				return ApplyCC("Chilly", duration, tgt, "#66CCFF", "Chilly")
			else
				tgt.Statuses.Freeze = duration; tgt.StunImmunity = duration + (tgt.IsBoss and 4 or 2)
				return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end

		elseif effectName == "Confusion" then
			if (tgt.ConfusionImmunity and tgt.ConfusionImmunity > 0) or (tgt.Statuses.Confusion and tgt.Statuses.Confusion > 0) then
				tgt.Statuses.Dizzy = math.max(tgt.Statuses.Dizzy or 0, duration)
				return " <font color='#AAAAAA'>(Confusion Resisted! Applied <font color='#E6E600'>Dizzy</font> instead!)</font>"
			else
				tgt.Statuses.Confusion = duration; tgt.ConfusionImmunity = duration + (tgt.IsBoss and 6 or 3)
				return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end

		elseif effectName == "Burn" then
			if (tgt.Statuses.Plague or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Plague)
				tgt.Statuses.Calamity = mergedDur; tgt.Statuses.Plague = 0; tgt.Statuses.Burn = 0
				return " <font color='#CC00FF'>(Calamity!)</font>"
			elseif (tgt.Statuses.Infection or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Infection)
				tgt.Statuses.Blight = mergedDur; tgt.Statuses.Infection = 0; tgt.Statuses.Burn = 0
				return " <font color='#4B0082'>(Blight!)</font>"
			elseif (tgt.Statuses.Frostbite or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Frostbite)
				tgt.Statuses.Necrosis = mergedDur; tgt.Statuses.Frostbite = 0; tgt.Statuses.Burn = 0
				return " <font color='#8B4513'>(Necrosis!)</font>"
			elseif (tgt.Statuses.Decay or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Decay)
				tgt.Statuses.Miasma = mergedDur; tgt.Statuses.Decay = 0; tgt.Statuses.Burn = 0
				return " <font color='#2E8B57'>(Miasma!)</font>"
			elseif (tgt.Statuses.Calamity or 0) > 0 then
				tgt.Statuses.Calamity = math.max(tgt.Statuses.Calamity, duration); tgt.Statuses.Burn = 0
				return " <font color='#CC00FF'>(Calamity!)</font>"
			elseif (tgt.Statuses.Blight or 0) > 0 then
				tgt.Statuses.Blight = math.max(tgt.Statuses.Blight, duration); tgt.Statuses.Burn = 0
				return " <font color='#4B0082'>(Blight!)</font>"
			elseif (tgt.Statuses.Necrosis or 0) > 0 then
				tgt.Statuses.Necrosis = math.max(tgt.Statuses.Necrosis, duration); tgt.Statuses.Burn = 0
				return " <font color='#8B4513'>(Necrosis!)</font>"
			elseif (tgt.Statuses.Miasma or 0) > 0 then
				tgt.Statuses.Miasma = math.max(tgt.Statuses.Miasma, duration); tgt.Statuses.Burn = 0
				return " <font color='#2E8B57'>(Miasma!)</font>"
			elseif (tgt.Statuses.Poison or 0) > 0 or (tgt.Statuses.Acid or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Poison or 0, tgt.Statuses.Acid or 0)
				tgt.Statuses.Acid = mergedDur; tgt.Statuses.Poison = 0; tgt.Statuses.Burn = 0
				return " <font color='#80FF00'>(Acid!)</font>"
			elseif (tgt.Statuses.Bleed or 0) > 0 or (tgt.Statuses.Rupture or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Bleed or 0, tgt.Statuses.Rupture or 0)
				tgt.Statuses.Rupture = mergedDur; tgt.Statuses.Bleed = 0; tgt.Statuses.Burn = 0
				return " <font color='#FF4400'>(Rupture!)</font>"
			elseif (tgt.Statuses.Chilly or 0) > 0 or (tgt.Statuses.Frostburn or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Chilly or 0, tgt.Statuses.Frostburn or 0)
				tgt.Statuses.Frostburn = mergedDur; tgt.Statuses.Chilly = 0; tgt.Statuses.Burn = 0
				return " <font color='#55AAFF'>(Frostburn!)</font>"
			else
				tgt.Statuses.Burn = math.max(tgt.Statuses.Burn or 0, duration)
				return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end

		elseif effectName == "Poison" then
			if (tgt.Statuses.Necrosis or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Necrosis)
				tgt.Statuses.Calamity = mergedDur; tgt.Statuses.Necrosis = 0; tgt.Statuses.Poison = 0
				return " <font color='#CC00FF'>(Calamity!)</font>"
			elseif (tgt.Statuses.Rupture or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Rupture)
				tgt.Statuses.Blight = mergedDur; tgt.Statuses.Rupture = 0; tgt.Statuses.Poison = 0
				return " <font color='#4B0082'>(Blight!)</font>"
			elseif (tgt.Statuses.Frostburn or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Frostburn)
				tgt.Statuses.Miasma = mergedDur; tgt.Statuses.Frostburn = 0; tgt.Statuses.Poison = 0
				return " <font color='#2E8B57'>(Miasma!)</font>"
			elseif (tgt.Statuses.Frostbite or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Frostbite)
				tgt.Statuses.Plague = mergedDur; tgt.Statuses.Frostbite = 0; tgt.Statuses.Poison = 0
				return " <font color='#556B2F'>(Plague!)</font>"
			elseif (tgt.Statuses.Calamity or 0) > 0 then
				tgt.Statuses.Calamity = math.max(tgt.Statuses.Calamity, duration); tgt.Statuses.Poison = 0
				return " <font color='#CC00FF'>(Calamity!)</font>"
			elseif (tgt.Statuses.Blight or 0) > 0 then
				tgt.Statuses.Blight = math.max(tgt.Statuses.Blight, duration); tgt.Statuses.Poison = 0
				return " <font color='#4B0082'>(Blight!)</font>"
			elseif (tgt.Statuses.Miasma or 0) > 0 then
				tgt.Statuses.Miasma = math.max(tgt.Statuses.Miasma, duration); tgt.Statuses.Poison = 0
				return " <font color='#2E8B57'>(Miasma!)</font>"
			elseif (tgt.Statuses.Plague or 0) > 0 then
				tgt.Statuses.Plague = math.max(tgt.Statuses.Plague, duration); tgt.Statuses.Poison = 0
				return " <font color='#556B2F'>(Plague!)</font>"
			elseif (tgt.Statuses.Burn or 0) > 0 or (tgt.Statuses.Acid or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Burn or 0, tgt.Statuses.Acid or 0)
				tgt.Statuses.Acid = mergedDur; tgt.Statuses.Burn = 0; tgt.Statuses.Poison = 0
				return " <font color='#80FF00'>(Acid!)</font>"
			elseif (tgt.Statuses.Bleed or 0) > 0 or (tgt.Statuses.Infection or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Bleed or 0, tgt.Statuses.Infection or 0)
				tgt.Statuses.Infection = mergedDur; tgt.Statuses.Bleed = 0; tgt.Statuses.Poison = 0
				return " <font color='#800000'>(Infection!)</font>"
			elseif (tgt.Statuses.Chilly or 0) > 0 or (tgt.Statuses.Decay or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Chilly or 0, tgt.Statuses.Decay or 0)
				tgt.Statuses.Decay = mergedDur; tgt.Statuses.Chilly = 0; tgt.Statuses.Poison = 0
				return " <font color='#00AA55'>(Decay!)</font>"
			else
				tgt.Statuses.Poison = math.max(tgt.Statuses.Poison or 0, duration)
				return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end

		elseif effectName == "Bleed" then
			if (tgt.Statuses.Miasma or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Miasma)
				tgt.Statuses.Calamity = mergedDur; tgt.Statuses.Miasma = 0; tgt.Statuses.Bleed = 0
				return " <font color='#CC00FF'>(Calamity!)</font>"
			elseif (tgt.Statuses.Acid or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Acid)
				tgt.Statuses.Blight = mergedDur; tgt.Statuses.Acid = 0; tgt.Statuses.Bleed = 0
				return " <font color='#4B0082'>(Blight!)</font>"
			elseif (tgt.Statuses.Frostburn or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Frostburn)
				tgt.Statuses.Necrosis = mergedDur; tgt.Statuses.Frostburn = 0; tgt.Statuses.Bleed = 0
				return " <font color='#8B4513'>(Necrosis!)</font>"
			elseif (tgt.Statuses.Decay or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Decay)
				tgt.Statuses.Plague = mergedDur; tgt.Statuses.Decay = 0; tgt.Statuses.Bleed = 0
				return " <font color='#556B2F'>(Plague!)</font>"
			elseif (tgt.Statuses.Calamity or 0) > 0 then
				tgt.Statuses.Calamity = math.max(tgt.Statuses.Calamity, duration); tgt.Statuses.Bleed = 0
				return " <font color='#CC00FF'>(Calamity!)</font>"
			elseif (tgt.Statuses.Blight or 0) > 0 then
				tgt.Statuses.Blight = math.max(tgt.Statuses.Blight, duration); tgt.Statuses.Bleed = 0
				return " <font color='#4B0082'>(Blight!)</font>"
			elseif (tgt.Statuses.Necrosis or 0) > 0 then
				tgt.Statuses.Necrosis = math.max(tgt.Statuses.Necrosis, duration); tgt.Statuses.Bleed = 0
				return " <font color='#8B4513'>(Necrosis!)</font>"
			elseif (tgt.Statuses.Plague or 0) > 0 then
				tgt.Statuses.Plague = math.max(tgt.Statuses.Plague, duration); tgt.Statuses.Bleed = 0
				return " <font color='#556B2F'>(Plague!)</font>"
			elseif (tgt.Statuses.Burn or 0) > 0 or (tgt.Statuses.Rupture or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Burn or 0, tgt.Statuses.Rupture or 0)
				tgt.Statuses.Rupture = mergedDur; tgt.Statuses.Burn = 0; tgt.Statuses.Bleed = 0
				return " <font color='#FF4400'>(Rupture!)</font>"
			elseif (tgt.Statuses.Poison or 0) > 0 or (tgt.Statuses.Infection or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Poison or 0, tgt.Statuses.Infection or 0)
				tgt.Statuses.Infection = mergedDur; tgt.Statuses.Poison = 0; tgt.Statuses.Bleed = 0
				return " <font color='#800000'>(Infection!)</font>"
			elseif (tgt.Statuses.Chilly or 0) > 0 or (tgt.Statuses.Frostbite or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Chilly or 0, tgt.Statuses.Frostbite or 0)
				tgt.Statuses.Frostbite = mergedDur; tgt.Statuses.Chilly = 0; tgt.Statuses.Bleed = 0
				return " <font color='#0055FF'>(Frostbite!)</font>"
			else
				tgt.Statuses.Bleed = math.max(tgt.Statuses.Bleed or 0, duration)
				return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end

		elseif effectName == "Chilly" then
			if (tgt.Statuses.Blight or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Blight)
				tgt.Statuses.Calamity = mergedDur; tgt.Statuses.Blight = 0; tgt.Statuses.Chilly = 0
				return " <font color='#CC00FF'>(Calamity!)</font>"
			elseif (tgt.Statuses.Acid or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Acid)
				tgt.Statuses.Miasma = mergedDur; tgt.Statuses.Acid = 0; tgt.Statuses.Chilly = 0
				return " <font color='#2E8B57'>(Miasma!)</font>"
			elseif (tgt.Statuses.Rupture or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Rupture)
				tgt.Statuses.Necrosis = mergedDur; tgt.Statuses.Rupture = 0; tgt.Statuses.Chilly = 0
				return " <font color='#8B4513'>(Necrosis!)</font>"
			elseif (tgt.Statuses.Infection or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Infection)
				tgt.Statuses.Plague = mergedDur; tgt.Statuses.Infection = 0; tgt.Statuses.Chilly = 0
				return " <font color='#556B2F'>(Plague!)</font>"
			elseif (tgt.Statuses.Calamity or 0) > 0 then
				tgt.Statuses.Calamity = math.max(tgt.Statuses.Calamity, duration); tgt.Statuses.Chilly = 0
				return " <font color='#CC00FF'>(Calamity!)</font>"
			elseif (tgt.Statuses.Miasma or 0) > 0 then
				tgt.Statuses.Miasma = math.max(tgt.Statuses.Miasma, duration); tgt.Statuses.Chilly = 0
				return " <font color='#2E8B57'>(Miasma!)</font>"
			elseif (tgt.Statuses.Necrosis or 0) > 0 then
				tgt.Statuses.Necrosis = math.max(tgt.Statuses.Necrosis, duration); tgt.Statuses.Chilly = 0
				return " <font color='#8B4513'>(Necrosis!)</font>"
			elseif (tgt.Statuses.Plague or 0) > 0 then
				tgt.Statuses.Plague = math.max(tgt.Statuses.Plague, duration); tgt.Statuses.Chilly = 0
				return " <font color='#556B2F'>(Plague!)</font>"
			elseif (tgt.Statuses.Burn or 0) > 0 or (tgt.Statuses.Frostburn or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Burn or 0, tgt.Statuses.Frostburn or 0)
				tgt.Statuses.Frostburn = mergedDur; tgt.Statuses.Burn = 0; tgt.Statuses.Chilly = 0
				return " <font color='#55AAFF'>(Frostburn!)</font>"
			elseif (tgt.Statuses.Bleed or 0) > 0 or (tgt.Statuses.Frostbite or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Bleed or 0, tgt.Statuses.Frostbite or 0)
				tgt.Statuses.Frostbite = mergedDur; tgt.Statuses.Bleed = 0; tgt.Statuses.Chilly = 0
				return " <font color='#0055FF'>(Frostbite!)</font>"
			elseif (tgt.Statuses.Poison or 0) > 0 or (tgt.Statuses.Decay or 0) > 0 then
				local mergedDur = math.max(duration, tgt.Statuses.Poison or 0, tgt.Statuses.Decay or 0)
				tgt.Statuses.Decay = mergedDur; tgt.Statuses.Poison = 0; tgt.Statuses.Chilly = 0
				return " <font color='#00AA55'>(Decay!)</font>"
			else
				tgt.Statuses.Chilly = math.max(tgt.Statuses.Chilly or 0, duration)
				return " <font color='" .. (colorHex or "#66CCFF") .. "'>(" .. (overrideMsg or "Chilly") .. "!)</font>"
			end
		else
			tgt.Statuses[effectName] = duration
			return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
		end
	end

	if skill.Effect == "Block" then
		b.BlockTurns = 2; return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! " .. bName .. " reduces incoming damage.", false, "None"

	elseif skill.Effect == "Counter" then
		b.CounterTurns = 2; return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#55AAFF'>" .. bName .. " readies a counter-stance.</font>", false, "None"

	elseif skill.Effect == "Rest" or skill.Effect == "CleanseRest" then
		local clearedStatuses = false
		if skill.Effect == "CleanseRest" and b.Statuses then
			local toClear = {
				"Poison", "Burn", "Bleed", "Stun", "Freeze", "Confusion", "Debuff_Strength", "Debuff_Defense", "Debuff_Speed", "Debuff_Willpower", 
				"StaminaExhausted", "EnergyExhausted", "Dizzy", "Chilly", "Acid", "Infection", "Rupture", "Frostburn", "Frostbite", "Decay",
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

		local restAmount = CombatCore.HasModifier(uniModStr, "Resource Drought") and 25 or 50
		if b.MaxStamina then b.Stamina = math.min(b.MaxStamina, (b.Stamina or 0) + restAmount) end
		if b.MaxStandEnergy then b.StandEnergy = math.min(b.MaxStandEnergy, (b.StandEnergy or 0) + restAmount) end

		local appliedWarded = false
		if b.BlockTurns and b.BlockTurns > 0 then
			if b.Statuses then b.Statuses.Warded = 2 end
			appliedWarded = true
		end

		if clearedStatuses and appliedWarded then
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b> behind their guard! <font color='#55FFFF'>" .. bName .. " restores resources, Cleanses ailments, and gains Warded!</font>", false, "None"
		elseif clearedStatuses then
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#55FFFF'>" .. bName .. " takes a deep breath, restoring resources and Cleansing all ailments!</font>", false, "None"
		elseif appliedWarded then
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b> behind their guard! <font color='#55FF55'>" .. bName .. " rests, recovering Stamina and Energy, and gains Warded!</font>", false, "None"
		else
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#55FF55'>" .. bName .. " rests, recovering Stamina and Energy.</font>", false, "None"
		end

	elseif skill.Effect == "Heal" then
		local healAmount = (b.MaxHP or 100) * (skill.HealPercent or 0.25)
		b.HP = math.min(b.MaxHP or b.HP, b.HP + healAmount)
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b> and recovered <font color='#55FF55'>" .. math.floor(healAmount) .. " HP</font> for " .. bName .. "!", false, "None"
	elseif skill.Effect == "TimeRewind" then
		local lostHP = (b.MaxHP or b.HP) - b.HP
		local healAmount = lostHP * 0.5 
		b.HP = math.min(b.MaxHP or b.HP, b.HP + healAmount)
		if b.Statuses then
			b.Statuses.Poison = 0; b.Statuses.Burn = 0; b.Statuses.Bleed = 0; b.Statuses.Freeze = 0; b.Statuses.Confusion = 0
			b.Statuses.Acid = 0; b.Statuses.Infection = 0; b.Statuses.Rupture = 0; b.Statuses.Frostburn = 0; b.Statuses.Frostbite = 0; b.Statuses.Decay = 0
			b.Statuses.Blight = 0; b.Statuses.Miasma = 0; b.Statuses.Necrosis = 0; b.Statuses.Plague = 0; b.Statuses.Calamity = 0; b.Statuses.Warded = 0
		end
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF55FF'>Bites the Dust activates! Rewinding time to restore " .. math.floor(healAmount) .. " HP and clear ailments for " .. bName .. "!</font>", false, "Heavy"
	elseif skill.Effect == "TimeReset" then
		local lostHP = (b.MaxHP or b.HP) - b.HP
		local healAmount = lostHP * 0.25 
		b.HP = math.min(b.MaxHP or b.HP, b.HP + healAmount)
		if b.Statuses then
			b.Statuses.Poison = 0; b.Statuses.Burn = 0; b.Statuses.Bleed = 0; b.Statuses.Freeze = 0; b.Statuses.Confusion = 0
			b.Statuses.Acid = 0; b.Statuses.Infection = 0; b.Statuses.Rupture = 0; b.Statuses.Frostburn = 0; b.Statuses.Frostbite = 0; b.Statuses.Decay = 0
			b.Statuses.Blight = 0; b.Statuses.Miasma = 0; b.Statuses.Necrosis = 0; b.Statuses.Plague = 0; b.Statuses.Calamity = 0; b.Statuses.Warded = 0
		end
		local ccMsg = ""
		if t and t.Statuses then
			ccMsg = ApplyCC("Confusion", 2, t, "#FF55FF", "Confused")
		end
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF55FF'>Made in Heaven activates! The universe begins to restart... restoring " .. math.floor(healAmount) .. " HP for " .. bName .. " and disorienting " .. tName .. "!</font>" .. ccMsg, false, "Heavy"
	elseif skill.Effect == "ReturnToZero" then
		b.HP = b.MaxHP or b.HP
		if b.Statuses then
			b.Statuses.Poison = 0; b.Statuses.Burn = 0; b.Statuses.Bleed = 0; b.Statuses.Freeze = 0; b.Statuses.Confusion = 0
			b.Statuses.Acid = 0; b.Statuses.Infection = 0; b.Statuses.Rupture = 0; b.Statuses.Frostburn = 0; b.Statuses.Frostbite = 0; b.Statuses.Decay = 0
			b.Statuses.Blight = 0; b.Statuses.Miasma = 0; b.Statuses.Necrosis = 0; b.Statuses.Plague = 0; b.Statuses.Calamity = 0; b.Statuses.Warded = 0
		end
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FFD700'>Return to Zero! Reality is reset, fully restoring " .. bName .. " and nullifying all negative effects.</font>", false, "Heavy"
	elseif skill.Effect == "TimeErase" then
		b.Statuses.Buff_Speed = skill.Duration or 2
		local ccMsg = ApplyCC("Stun", skill.Duration or 2, t, "#FF0000")
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF0000'>Time is erased, boosting Speed!</font>" .. ccMsg, false, "Light"
	elseif skill.Effect == "TimeStop" then
		local ccMsg = ApplyCC("Stun", skill.Duration or 2, t, "#FFFFFF", "Time Stopped")
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#AAAAAA'>Time comes to a halt...</font>" .. ccMsg, false, "Heavy"
	elseif skill.Effect == "Buff_Random" then
		local stats = {"Strength", "Defense", "Speed", "Willpower"}
		local s = stats[math.random(1, 4)]
		b.Statuses["Buff_"..s] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FFFF55'>" .. bName .. "'s " .. s .. " is boosted!</font>", false, "None"
	elseif skill.Effect and string.sub(skill.Effect, 1, 5) == "Buff_" then
		local statName = string.sub(skill.Effect, 6); b.Statuses[skill.Effect] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FFFF55'>" .. bName .. "'s " .. statName .. " is boosted!</font>", false, "None"
	elseif skill.Effect == "Debuff_Random" then
		if (t.Statuses.Warded or 0) > 0 then
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#AAAAAA'>But " .. tName .. " is Warded!</font>", false, "None"
		end
		local stats = {"Strength", "Defense", "Speed", "Willpower"}
		local s = stats[math.random(1, 4)]
		t.Statuses["Debuff_"..s] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF5555'>" .. tName .. "'s " .. s .. " is reduced!</font>", false, "None"
	elseif skill.Effect and string.sub(skill.Effect, 1, 7) == "Debuff_" then
		if (t.Statuses.Warded or 0) > 0 then
			return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#AAAAAA'>But " .. tName .. " is Warded!</font>", false, "None"
		end
		local statName = string.sub(skill.Effect, 8); t.Statuses[skill.Effect] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF5555'>" .. tName .. "'s " .. statName .. " is reduced!</font>", false, "None"
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

		local mult = skill.Mult * (isCrit and critMult or 1.0)
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

		local damage = CombatCore.CalculateDamage(attacker, t, mult, isBlocking, uniModStr, skill.Type)

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
			local baseExhaust = CombatCore.HasModifier(uniModStr, "Aggressive Attrition") and 3.5 or 1.5
			local exhaustMult = baseExhaust + (1.5 * shatterCount)

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
			elseif flameCount > 0 and math.random(1, 100) <= (10 * flameCount) then postMsg = postMsg .. ApplyCC("Burn", 3, t, "#FF5500", "Ignited")
			elseif toxCount > 0 and math.random(1, 100) <= (10 * toxCount) then postMsg = postMsg .. ApplyCC("Poison", 3, t, "#AA00AA", "Infected")
			elseif serrCount > 0 and math.random(1, 100) <= (10 * serrCount) then postMsg = postMsg .. ApplyCC("Bleed", 3, t, "#FF0000", "Bled")
			elseif disCount > 0 and math.random(1, 100) <= (10 * disCount) then postMsg = postMsg .. ApplyCC("Confusion", 1, t, "#FF55FF", "Confused")
			elseif gamCount > 0 and math.random(1, 100) <= (10 * gamCount) then
				local pick = ({{ "Bleed", "#FF0000" }, { "Poison", "#AA00AA" }, { "Burn", "#FF5500" }, { "Confusion", "#FF55FF" }, { "Stun", "#FFFF55" }, { "Freeze", "#00FFFF" }})[math.random(1, 6)]
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
			local statColors = { 
				Stun = "#FFFF55", Freeze = "#00FFFF", Poison = "#AA00AA", Burn = "#FF5500", Bleed = "#FF0000", Confusion = "#FF55FF",
				Acid = "#80FF00", Infection = "#800000", Rupture = "#FF4400", Frostburn = "#55AAFF", Frostbite = "#0055FF", Decay = "#00AA55",
				Blight = "#4B0082", Miasma = "#2E8B57", Necrosis = "#8B4513", Plague = "#556B2F", Calamity = "#CC00FF"
			}

			if statColors[eff] then
				postMsg = postMsg .. ApplyCC(eff, skill.Duration or 2, t, statColors[eff])
				effectApplied = true
			elseif eff == "Status_Random" then
				local effs = { {"Bleed", "#FF0000"}, {"Poison", "#AA00AA"}, {"Burn", "#FF5500"}, {"Confusion", "#FF55FF"}, {"Stun", "#FFFF55"}, {"Freeze", "#00FFFF"} }
				local pick = effs[math.random(1, #effs)]
				postMsg = postMsg .. ApplyCC(pick[1], skill.Duration or 2, t, pick[2])
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

	return msg, didHitAtAll, overallShake
end

return CombatCore