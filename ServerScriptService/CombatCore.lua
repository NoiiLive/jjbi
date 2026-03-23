-- @ScriptType: ModuleScript
local CombatCore = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))

function CombatCore.HasModifier(modStr, modName)
	if not modStr or modStr == "None" or modStr == "" then return false end
	for _, m in ipairs(string.split(modStr, ",")) do
		if m == modName then return true end
	end
	return false
end

function CombatCore.CountTrait(combatant, traitName)
	local count = 0
	if combatant.Trait == traitName then count += 1 end

	if type(combatant.Traits) == "table" then
		for _, t in ipairs(combatant.Traits) do
			if t == traitName then count += 1 end
		end
	end

	if combatant.IsPlayer and combatant.PlayerObj then
		local sTrait = combatant.PlayerObj:GetAttribute("StandTrait")
		if sTrait == "Fused" then
			local t1 = combatant.PlayerObj:GetAttribute("Active_FusedTrait1")
			local t2 = combatant.PlayerObj:GetAttribute("Active_FusedTrait2")
			if t1 == traitName then count += 1 end
			if t2 == traitName then count += 1 end
		elseif sTrait == traitName then
			count += 1
		end
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

	return boosts
end

function CombatCore.BuildPlayerStruct(player)
	local playerTrait = player:GetAttribute("StandTrait") or "None"
	local hasStand = (player:GetAttribute("Stand") or "None") ~= "None"

	local sPow = hasStand and (player:GetAttribute("Stand_Power_Val") or 0) or 0
	local sDur = hasStand and (player:GetAttribute("Stand_Durability_Val") or 0) or 0
	local sSpd = hasStand and (player:GetAttribute("Stand_Speed_Val") or 0) or 0
	local sPot = hasStand and (player:GetAttribute("Stand_Potential_Val") or 0) or 0
	local sRan = hasStand and (player:GetAttribute("Stand_Range_Val") or 0) or 0
	local sPre = hasStand and (player:GetAttribute("Stand_Precision_Val") or 0) or 0

	local pHP = (player:GetAttribute("Health") or 1) + CombatCore.GetEquipBonus(player, "Health")
	local pStr = (player:GetAttribute("Strength") or 1) + sPow + CombatCore.GetEquipBonus(player, "Strength") + CombatCore.GetEquipBonus(player, "Stand_Power")
	local pDef = (player:GetAttribute("Defense") or 1) + sDur + CombatCore.GetEquipBonus(player, "Defense") + CombatCore.GetEquipBonus(player, "Stand_Durability")
	local pSpd = (player:GetAttribute("Speed") or 1) + sSpd + CombatCore.GetEquipBonus(player, "Speed") + CombatCore.GetEquipBonus(player, "Stand_Speed")
	local pWill = (player:GetAttribute("Willpower") or 1) + CombatCore.GetEquipBonus(player, "Willpower")

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
	if fierceCount > 0 then pStr *= (1.1 ^ fierceCount) end
	if persCount > 0 then pHP *= (1.5 ^ persCount); pWill *= (1.5 ^ persCount) end

	local pStamina = (player:GetAttribute("Stamina") or 1) + CombatCore.GetEquipBonus(player, "Stamina")
	local pStandEnergy = 10 + sPot + CombatCore.GetEquipBonus(player, "Stand_Potential")

	local focCount = cT("Focused")
	if focCount > 0 then pStamina *= (1.1 ^ focCount); pStandEnergy *= (1.1 ^ focCount) end

	local activeBoosts = CombatCore.GetPlayerBoosts(player)
	local validSkills = {}

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
		Stand = sName, Style = fStyle,
		HP = pHP * 10, MaxHP = pHP * 10, Stamina = pStamina, MaxStamina = pStamina, StandEnergy = pStandEnergy, MaxStandEnergy = pStandEnergy,
		TotalStrength = pStr, TotalDefense = pDef, TotalSpeed = pSpd,
		TotalWillpower = pWill,
		TotalRange = sRan + CombatCore.GetEquipBonus(player, "Stand_Range"), TotalPrecision = sPre + CombatCore.GetEquipBonus(player, "Stand_Precision"),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0 }, 
		Cooldowns = {}, SelectedSkill = nil, Skills = validSkills
	}
end

function CombatCore.CalculateDamage(attacker, defender, skillMult, isDefenderBlocking, uniModStr)
	local atkBuff = (attacker.Statuses and (attacker.Statuses.Buff_Strength or 0) > 0) and 1.5 or 1.0
	local atkDebuff = (attacker.Statuses and (attacker.Statuses.Debuff_Strength or 0) > 0) and 0.5 or 1.0

	local defBuff = (defender.Statuses and (defender.Statuses.Buff_Defense or 0) > 0) and 1.5 or 1.0
	local defDebuff = (defender.Statuses and (defender.Statuses.Debuff_Defense or 0) > 0) and 0.5 or 1.0

	local baseDmg = (attacker.TotalStrength or 1) * atkBuff * atkDebuff * skillMult

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
	local finalDmg = baseDmg * defenseMultiplier

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
	if combatant.Skills then
		for _, sName in ipairs(combatant.Skills) do
			local cd = combatant.Cooldowns and combatant.Cooldowns[sName] or 0
			if cd > 0 then continue end
			local sData = SkillData.Skills[sName]
			if sData and sData.Effect == "Block" and combatant.BlockTurns > 0 then continue end
			table.insert(validSkills, sName)
		end
	end
	if #validSkills > 0 then return validSkills[math.random(1, #validSkills)] else return "Basic Attack" end
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
	local statusDmgMod = CombatCore.HasModifier(uniModStr, "Cursed Wounds") and 0.07 or 0.05 

	if combatant.IsBoss then
		statusDmgMod = statusDmgMod * 0.85
	end

	local persCount = CombatCore.CountTrait(combatant, "Perseverance")

	if combatant.Statuses.Bleed > 0 then
		local dmg = math.max(1, combatant.MaxHP * statusDmgMod)
		local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
		combatant.Statuses.Bleed -= 1
		local svMsg = survived and (persCount > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#FF0000'>"..combatant.Name.." bled for "..math.floor(dmg).." damage!"..svMsg.."</font>", DidHit = true, ShakeType = "Light"})
		task.wait(waitMultiplier)
	end
	if combatant.HP < 1 then return end

	if combatant.Statuses.Poison > 0 then
		local dmg = math.max(1, combatant.MaxHP * statusDmgMod)
		local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
		combatant.Statuses.Poison -= 1
		local svMsg = survived and (persCount > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AA00AA'>"..combatant.Name.." took "..math.floor(dmg).." Poison damage!"..svMsg.."</font>", DidHit = true, ShakeType = "Light"})
		task.wait(waitMultiplier)
	end
	if combatant.HP < 1 then return end

	if combatant.Statuses.Burn > 0 then
		local dmg = math.max(1, combatant.MaxHP * statusDmgMod)
		local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
		combatant.Statuses.Burn -= 1
		local svMsg = survived and (persCount > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#FF5500'>"..combatant.Name.." took "..math.floor(dmg).." Burn damage!"..svMsg.."</font>", DidHit = true, ShakeType = "Light"})
		task.wait(waitMultiplier)
	end
	if combatant.HP < 1 then return end

	if combatant.Statuses.Freeze > 0 then
		local dmg = math.max(1, combatant.MaxHP * statusDmgMod)
		local survived = CombatCore.TakeDamageWithWillpower(combatant, dmg)
		combatant.Statuses.Freeze -= 1
		local svMsg = survived and (persCount > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
		CombatUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#00FFFF'>"..combatant.Name.." took "..math.floor(dmg).." Freeze damage and is frozen solid!"..svMsg.."</font>", DidHit = true, ShakeType = "Light"})
		task.wait(waitMultiplier)
		if combatant.HP < 1 then return end
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

	if attacker.Statuses and (attacker.Statuses.Confusion or 0) > 0 then
		msgPrefix = "<font color='#FF55FF'>[CONFUSED] </font>"
		t = attacker
		tName = fLogName
		b = defender
		bName = fDefName
	end

	if skill.Effect ~= "Flee" then
		local stamCost = skill.StaminaCost or 0
		local nrgCost = skill.EnergyCost or 0
		if attacker.IsPlayer then
			if CombatCore.HasModifier(uniModStr, "Speed of Light") then stamCost *= 1.5; nrgCost *= 1.5 end
			if CombatCore.HasModifier(uniModStr, "Endless Stamina") then stamCost *= 0.5; nrgCost *= 0.5 end
		end
		if attacker.Stamina then attacker.Stamina = math.max(0, attacker.Stamina - stamCost) end
		if attacker.StandEnergy then attacker.StandEnergy = math.max(0, attacker.StandEnergy - nrgCost) end
		if attacker.Cooldowns then attacker.Cooldowns[skillName] = skill.Cooldown or 0 end
	end

	local function ApplyCC(effectName, duration, tgt, colorHex, overrideMsg)
		if effectName == "Stun" or effectName == "Freeze" then
			if tgt.StunImmunity and tgt.StunImmunity > 0 then
				return " <font color='#AAAAAA'>(" .. (overrideMsg or effectName) .. " Resisted!)</font>"
			else
				tgt.Statuses[effectName] = duration
				tgt.StunImmunity = duration + (tgt.IsBoss and 4 or 2)
				return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end
		elseif effectName == "Confusion" then
			if tgt.ConfusionImmunity and tgt.ConfusionImmunity > 0 then
				return " <font color='#AAAAAA'>(Confusion Resisted!)</font>"
			else
				tgt.Statuses[effectName] = duration
				tgt.ConfusionImmunity = duration + (tgt.IsBoss and 6 or 3)
				return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
			end
		else
			tgt.Statuses[effectName] = duration
			return " <font color='" .. colorHex .. "'>(" .. (overrideMsg or effectName) .. "!)</font>"
		end
	end

	if skill.Effect == "Block" then
		b.BlockTurns = 2; return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! " .. bName .. " reduces incoming damage.", false, "None"
	elseif skill.Effect == "Rest" then
		if b.MaxStamina then b.Stamina = math.min(b.MaxStamina, (b.Stamina or 0) + 20) end
		if b.MaxStandEnergy then b.StandEnergy = math.min(b.MaxStandEnergy, (b.StandEnergy or 0) + 20) end
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#55FF55'>" .. bName .. " rests, recovering Stamina and Energy.</font>", false, "None"
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
		end
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF55FF'>Bites the Dust activates! Rewinding time to restore " .. math.floor(healAmount) .. " HP and clear ailments for " .. bName .. "!</font>", false, "Heavy"
	elseif skill.Effect == "TimeReset" then
		local lostHP = (b.MaxHP or b.HP) - b.HP
		local healAmount = lostHP * 0.25 
		b.HP = math.min(b.MaxHP or b.HP, b.HP + healAmount)
		if b.Statuses then
			b.Statuses.Poison = 0; b.Statuses.Burn = 0; b.Statuses.Bleed = 0; b.Statuses.Freeze = 0; b.Statuses.Confusion = 0
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
		local stats = {"Strength", "Defense", "Speed", "Willpower"}
		local s = stats[math.random(1, 4)]
		t.Statuses["Debuff_"..s] = skill.Duration or 3
		return msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>! <font color='#FF5555'>" .. tName .. "'s " .. s .. " is reduced!</font>", false, "None"
	elseif skill.Effect and string.sub(skill.Effect, 1, 7) == "Debuff_" then
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

		local isCrit = math.random(1, 100) <= critChance
		local critMult = 1.5 + (1.5 * CombatCore.CountTrait(attacker, "Lethal"))

		local mult = skill.Mult * (isCrit and critMult or 1.0)
		local relCount = CombatCore.CountTrait(attacker, "Relentless")
		if relCount > 0 then mult *= (1.15 ^ relCount) end

		local ohCount = CombatCore.CountTrait(attacker, "Overheaven")
		if ohCount > 0 then mult *= (1.30 ^ ohCount) end

		local reqCount = CombatCore.CountTrait(attacker, "Requiem")
		if reqCount > 0 then mult *= (1.50 ^ reqCount) end

		local isBlocking = (t.BlockTurns or 0) > 0
		local damage = CombatCore.CalculateDamage(attacker, t, mult, isBlocking, uniModStr)
		local survivalTriggered = CombatCore.TakeDamageWithWillpower(t, damage)

		if isCrit or survivalTriggered then overallShake = "Heavy" elseif isBlocking and overallShake == "None" then overallShake = "Light" elseif overallShake == "None" then overallShake = "Normal" end

		local hitMsg = hitsToDo == 1 and (msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b> and dealt " .. math.floor(damage) .. " damage to " .. tName .. "!") or ("- Hit " .. i .. " dealt " .. math.floor(damage) .. " damage")
		if isBlocking then hitMsg = hitMsg .. " <font color='#AAAAAA'>(Blocked)</font>" end
		if isCrit then hitMsg = hitMsg .. " <font color='#FFAA00'>(CRIT!)</font>" end

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

		if CombatCore.HasModifier(uniModStr, "Vampiric Night") and not attacker.IsPlayer and not attacker.IsAlly and damage > 0 then
			local nHeal = damage * 0.05; attacker.HP = math.min(attacker.MaxHP, attacker.HP + nHeal)
			postMsg = postMsg .. " <font color='#AA00AA'>(Night Heal: " .. math.floor(nHeal) .. ")</font>"
		end

		if damage > 0 and not isBlocking then
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
				local s = {"Strength", "Defense", "Speed", "Willpower"}
				t.Statuses["Debuff_"..s[math.random(1,4)]] = 3
				postMsg = postMsg .. " <font color='#FF5555'>(Gloomy Debuff!)</font>"
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
			local statColors = { Stun = "#FFFF55", Freeze = "#00FFFF", Poison = "#AA00AA", Burn = "#FF5500", Bleed = "#FF0000", Confusion = "#FF55FF" }

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
	end

	if hitsToDo > 1 then
		if not didHitAtAll then msg = msgPrefix .. fLogName .. " used <b>" .. skillName .. "</b>, but " .. tName .. " dodged completely!"
		else msg = msg .. "\n" .. table.concat(hitLogs, "\n") end
	end

	return msg, didHitAtAll, overallShake
end

return CombatCore