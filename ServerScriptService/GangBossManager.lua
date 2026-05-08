-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local Network = ReplicatedStorage:WaitForChild("Network")
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local GangLeaderboardUpdate = Network:WaitForChild("GangLeaderboardUpdate")

local GangBossCooldowns = MemoryStoreService:GetHashMap("GangBossDaily")

local function GetOrCreateEvent(name, isBindable)
	local className = isBindable and "BindableEvent" or "RemoteEvent"
	local remote = Network:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = Network
	end
	return remote
end

local GangBossAction = GetOrCreateEvent("GangBossAction", false)
local GangBossUpdate = GetOrCreateEvent("GangBossUpdate", false)
local NotificationEvent = GetOrCreateEvent("NotificationEvent", false)
local AddGangTreasury = GetOrCreateEvent("AddGangTreasury", true)

local ActiveBossBattles = {}
local MAX_TURNS = 15

local function ScaleResource(val)
	if val <= 1000 then return val end
	return 1000 + math.floor((val - 1000) ^ 0.65 * 3)
end

local function StartGangBossBattle(player)
	if player:GetAttribute("InCombat") or player:GetAttribute("IsEngagingGangBoss") then return end

	local gangName = player:GetAttribute("Gang")
	if not gangName or gangName == "None" then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>You must be in a Gang to fight the Gang Boss!</font>")
		return
	end

	local lastFought = player:GetAttribute("LastGangBossFight") or ""
	local todayDate = os.date("!%Y_%j")
	if lastFought == todayDate then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>You have already challenged the Gang Boss today!</font>")
		return
	end
	
	local hasFought = false
	pcall(function() hasFought = GangBossCooldowns:GetAsync(tostring(player.UserId)) end)
	if hasFought then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>You have already challenged the Gang Boss today!</font>")
		return
	end

	player:SetAttribute("IsEngagingGangBoss", true)

	local bossName = "Za Warudo Mirage"
	local bossTemplate = EnemyData.GangBosses[bossName]
	if not bossTemplate then 
		player:SetAttribute("IsEngagingGangBoss", false)
		return 
	end

	local pData = CombatCore.BuildPlayerStruct(player, true)
	local sStats = bossTemplate.StandStats or {Power="E", Speed="E", Range="E", Durability="E", Precision="E", Potential="E"}

	local bossEntity = {
		IsPlayer = false, IsAlly = false, Name = bossTemplate.Name, Icon = bossTemplate.Icon or "", Trait = "None", IsBoss = true,
		HP = bossTemplate.Health, MaxHP = bossTemplate.Health,
		TotalStrength = bossTemplate.Strength, TotalDefense = bossTemplate.Defense,
		TotalSpeed = bossTemplate.Speed, TotalWillpower = bossTemplate.Willpower,
		Stamina = 99999, MaxStamina = 99999, StandEnergy = 99999, MaxStandEnergy = 99999,
		TotalRange = (GameData.StandRanks[sStats.Range] or 0),
		TotalPrecision = (GameData.StandRanks[sStats.Precision] or 0),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
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
		Cooldowns = {}, Stand = bossTemplate.Stand or "None", Style = bossTemplate.Style or "None",
		Skills = CombatCore.GetNPCSkills(bossTemplate.Stand, bossTemplate.Style)
	}

	ActiveBossBattles[player.UserId] = {
		IsProcessing = false, TurnCounter = 1, Boosts = pData.Boosts, 
		Player = pData, Enemy = bossEntity
	}
	
	CombatCore.ApplyPreCombatPassives(player, pData, bossEntity)
	
	player:SetAttribute("LastGangBossFight", todayDate)
	player:SetAttribute("InCombat", true)
	player:SetAttribute("IsEngagingGangBoss", false)

	GangBossUpdate:FireClient(player, "Start", { Battle = ActiveBossBattles[player.UserId], LogMsg = "<font color='#FF5555'>DEAL AS MUCH DAMAGE AS POSSIBLE!</font>" })
end

GangBossAction.OnServerEvent:Connect(function(player, actionType, actionData)
	if actionType == "Engage" then 
		StartGangBossBattle(player)
		return 
	end

	local battle = ActiveBossBattles[player.UserId]
	if not battle or battle.IsProcessing or actionType ~= "Attack" then return end

	local skillName = actionData.SkillName
	local skill = SkillData.Skills[skillName]
	if not table.find(battle.Player.Skills, skillName) then return end

	local stamCost, nrgCost = skill.StaminaCost or 0, skill.EnergyCost or 0
	if not skill or battle.Player.Stamina < stamCost or battle.Player.StandEnergy < nrgCost then return end
	if battle.Player.Cooldowns[skillName] and battle.Player.Cooldowns[skillName] > 0 then return end

	battle.IsProcessing = true
	local waitMultiplier = player:GetAttribute("Has2xBattleSpeed") and 0.6 or 1.2

	local function DispatchStrike(attacker, defender, strikeSkill)
		if not attacker or not defender or attacker.HP <= 0 or defender.HP <= 0 then return end
		local success, msg, didHit, shakeType, actualTarget = pcall(function()
			local lColor = attacker.IsPlayer and "#FFFFFF" or "#FF5555"
			local dColor = defender.IsPlayer and "#FFFFFF" or "#FF5555"
			local lName = attacker.IsPlayer and "You" or attacker.Name
			local dName = defender.IsPlayer and "you" or defender.Name
			return CombatCore.ExecuteStrike(attacker, defender, strikeSkill, "None", lName, dName, lColor, dColor)
		end)
		if success then
			local hitTarget = actualTarget or defender
			local defenderKey = hitTarget.IsPlayer and "Player" or "Enemy"
			GangBossUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = msg, DidHit = didHit, ShakeType = shakeType, SkillName = strikeSkill, Defender = defenderKey})
			task.wait(waitMultiplier)
		end
	end

	local combatants = { battle.Player, battle.Enemy }
	table.sort(combatants, function(a, b) 
		local aSpd = a.TotalSpeed * (((a.Statuses and a.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((a.Statuses and a.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		local bSpd = b.TotalSpeed * (((b.Statuses and b.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((b.Statuses and b.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		return aSpd > bSpd 
	end)

	for _, combatant in ipairs(combatants) do
		if battle.Player.HP < 1 or battle.Enemy.HP < 1 then break end
		if combatant.HP < 1 then continue end

		if combatant.Cooldowns then for sName, cd in pairs(combatant.Cooldowns) do if cd > 0 then combatant.Cooldowns[sName] = cd - 1 end end end
		for sName, sVal in pairs(combatant.Statuses) do 
			if (string.sub(sName, 1, 5) == "Buff_" or string.sub(sName, 1, 7) == "Debuff_" or string.find(sName, "Exhausted") or sName == "Dizzy" or sName == "Warded") and sVal > 0 then combatant.Statuses[sName] = sVal - 1 end 
		end

		local freezeResult = CombatCore.ApplyStatusDamage(combatant, "None", GangBossUpdate, player, battle, waitMultiplier)
		if freezeResult == "Frozen" then continue end
		if combatant.HP < 1 then continue end

		if combatant.Statuses.Stun > 0 then
			combatant.Statuses.Stun -= 1
			GangBossUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AAAAAA'>"..combatant.Name.." is Stunned!</font>", DidHit = false, ShakeType = "None"})
			task.wait(waitMultiplier); continue
		end

		if combatant.IsPlayer then
			DispatchStrike(battle.Player, battle.Enemy, skillName)
		else
			local eSkill = CombatCore.ChooseAISkill(combatant)
			DispatchStrike(battle.Enemy, battle.Player, eSkill)
		end
		if combatant.Statuses.Confusion > 0 then combatant.Statuses.Confusion -= 1 end
	end

	battle.TurnCounter += 1

	if battle.Player.HP < 1 or battle.Enemy.HP < 1 or battle.TurnCounter > MAX_TURNS then
		local damageDealt = math.max(0, battle.Enemy.MaxHP - battle.Enemy.HP)

		local pYen = math.floor((damageDealt * 0.1) * battle.Boosts.Yen)
		local gangTreasuryGain = math.floor(damageDealt * 0.01)
		local gangRepGain = math.floor(damageDealt / 50000)
		local gangTokens = math.floor(damageDealt / 100000)
		local gangName = player:GetAttribute("Gang")
		if gangName and gangName ~= "None" then
			AddGangTreasury:Fire(gangName, gangTreasuryGain, gangRepGain)
		end
		if gangName and gangName ~= "None" then
			GangLeaderboardUpdate:Fire(gangName, gangTokens ) 
		end
		if gangTokens > 0 then
			local currentTokens = player:GetAttribute("GangTokens") or 0
			player:SetAttribute("GangTokens", currentTokens + gangTokens)
			
		end
		
		pcall(function()
			player.leaderstats.Yen.Value += pYen
		end)
		
		
		pcall(function()
			GangBossCooldowns:SetAsync(tostring(player.UserId), true, 86400)
		end)

	

		local resultLog = "<font color='#FFAA00'><b>Raid Finished!</b></font>\n"
		resultLog = resultLog .. "<font color='#FF5555'>Total Damage Dealt: " .. math.floor(damageDealt) .. "</font>\n"
		resultLog = resultLog .. "<font color='#55FF55'>Gang Treasury Earned: ¥" .. gangTreasuryGain .. "</font>\n"
		resultLog = resultLog .. "<font color='#55FF55'>Gang Tokens Earned: " .. gangTokens .. "</font>"
		
		local finalPack = { XP = 0, Yen = pYen, Items = {} }

		GangBossUpdate:FireClient(player, "Defeat", {Battle = battle, Drops = finalPack, CustomLog = resultLog})

		ActiveBossBattles[player.UserId] = nil
		player:SetAttribute("InCombat", false)
	else
		battle.IsProcessing = false
		GangBossUpdate:FireClient(player, "Update", {Battle = battle})
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	ActiveBossBattles[player.UserId] = nil
	player:SetAttribute("InCombat", false)
	player:SetAttribute("IsEngagingGangBoss", false)
end)