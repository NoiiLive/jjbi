-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Network = ReplicatedStorage:WaitForChild("Network")
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local TerritoryStore = DataStoreService:GetDataStore("GangTerritories_V1")

local TILE_MAX_HP = 5e6
local SAVE_INTERVAL = 60
local MAX_TURNS = 15

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

local TerritoryAction = GetOrCreateEvent("TerritoryAction", false)
local TerritoryUpdate = GetOrCreateEvent("TerritoryUpdate", false)
local NotificationEvent = GetOrCreateEvent("NotificationEvent", false)
local GangLeaderboardUpdate = GetOrCreateEvent("GangLeaderboardUpdate", true)

local ActiveBattles = {}
local DirtyDamage = {}
local MapCache = {}

local AddGangTreasury = GetOrCreateEvent("AddGangTreasury", true)
local INCOME_INTERVAL = 300 
local TREASURY_PER_TILE = 25000
local REP_PER_TILE = 10
local BASE_YEN_PER_TILE = 15000
local BASE_XP_PER_TILE = 7500

task.spawn(function()
	while true do
		task.wait(INCOME_INTERVAL)

		for gangName, mapData in pairs(MapCache) do
			local capturedCount = 0

			for tileId, status in pairs(mapData) do
				if status == 1 then
					capturedCount += 1
				end
			end

			if capturedCount > 0 then
				local totalTreasury = capturedCount * TREASURY_PER_TILE
				local totalRep = capturedCount * REP_PER_TILE

				AddGangTreasury:Fire(gangName, totalTreasury, totalRep)

				for _, plr in ipairs(game.Players:GetPlayers()) do
					if plr:GetAttribute("Gang") == gangName then
						local prestige = 0
						if plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Prestige") then
							prestige = plr.leaderstats.Prestige.Value
						end

						local prestigeMult = 1 + (prestige * 0.1)
						local pYen = math.floor(capturedCount * BASE_YEN_PER_TILE * prestigeMult)
						local pXP = math.floor(capturedCount * BASE_XP_PER_TILE * prestigeMult)

						pcall(function()
							if plr.leaderstats:FindFirstChild("Yen") then plr.leaderstats.Yen.Value += pYen end
							if plr.leaderstats:FindFirstChild("XP") then plr.leaderstats.XP.Value += pXP end
						end)

						NotificationEvent:FireClient(plr, "<font color='#55FF55'>[Territories] Your gang recieved ¥" .. totalTreasury .. " for controlling " .. capturedCount .. " sectors! You personally received ¥" .. pYen .. " and " .. pXP .. " XP!</font>")
					end
				end
			end
		end
	end
end)

local function SyncTerritoryMaps()
	for gangName, damageData in pairs(DirtyDamage) do
		local hasDamage = false
		for _, dmg in pairs(damageData) do
			if dmg > 0 then hasDamage = true; break end
		end

		if hasDamage then
			local damageToPush = table.clone(damageData)
			DirtyDamage[gangName] = {}

			local success, updatedMap = pcall(function()
				return TerritoryStore:UpdateAsync("Map_" .. gangName, function(oldData)
					oldData = oldData or {}
					for tileId, status in pairs(damageToPush) do
						if status == 1 then
							oldData[tostring(tileId)] = 1
						end
					end
					return oldData
				end)
			end)

			if success then
				MapCache[gangName] = updatedMap
				for _, plr in ipairs(game.Players:GetPlayers()) do
					if plr:GetAttribute("Gang") == gangName then
						TerritoryUpdate:FireClient(plr, "MapData", updatedMap)
					end
				end
			else
				for tileId, dmg in pairs(damageToPush) do
					DirtyDamage[gangName][tileId] = (DirtyDamage[gangName][tileId] or 0) + dmg
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(SAVE_INTERVAL)
		SyncTerritoryMaps()
	end
end)

game:BindToClose(function()
	SyncTerritoryMaps()
end)

local function StartTerritoryBattle(player, tileId)
	if player:GetAttribute("InCombat") then return end

	local gangName = player:GetAttribute("Gang")
	if not gangName or gangName == "None" then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>You must be in a Gang to fight for territory!</font>")
		return
	end

	tileId = tonumber(tileId)
	if not tileId or tileId < 1 or tileId > 99 then return end

	local currentMap = MapCache[gangName] or {}
	local currentDmg = currentMap[tostring(tileId)] or 0
	if currentMap[tostring(tileId)] == 1 then
		NotificationEvent:FireClient(player, "<font color='#55FF55'>This territory is already conquered!</font>")
		return
	end

	local prestige = player:FindFirstChild("leaderstats") and player.leaderstats.Prestige.Value or 0
	local pData = CombatCore.BuildPlayerStruct(player, true)

	local bHp = 5000 + (prestige * 6000) + (tileId * 3500)
	local bStat = 500 + (prestige * 30)

	local enemyEntity = {
		IsPlayer = false, IsAlly = false, Name = "Sector " .. tileId .. " Guard", Icon = "rbxassetid://595029582", Trait = "None", IsBoss = true,
		HP = bHp, MaxHP = bHp,
		TotalStrength = bStat, TotalDefense = math.floor(bStat * 0.3), TotalSpeed = bStat, TotalWillpower = math.floor(bStat * 0.3),
		Stamina = 9999, MaxStamina = 9999, StandEnergy = 9999, MaxStandEnergy = 9999,
		TotalRange = 500, TotalPrecision = 500,
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
		Cooldowns = {}, Stand = "None", Style = "None",
		Skills = {"Basic Attack", "Heavy Strike"}
	}

	ActiveBattles[player.UserId] = {
		IsProcessing = false, TurnCounter = 1, Boosts = pData.Boosts, 
		Player = pData, Enemy = enemyEntity, TileId = tileId
	}

	CombatCore.ApplyPreCombatPassives(player, pData, enemyEntity)

	player:SetAttribute("InCombat", true)
	TerritoryUpdate:FireClient(player, "Start", { Battle = ActiveBattles[player.UserId], LogMsg = "<font color='#FFAA00'>Defeat the guard to claim Sector " .. tileId .. "!</font>" })
end

TerritoryAction.OnServerEvent:Connect(function(player, actionType, actionData)
	local gangName = player:GetAttribute("Gang")
	if not gangName or gangName == "None" then return end

	if actionType == "GetMap" then
		if not MapCache[gangName] then
			local success, mapData = pcall(function() return TerritoryStore:GetAsync("Map_"..gangName) end)
			if success then MapCache[gangName] = mapData or {} end
		end
		TerritoryUpdate:FireClient(player, "MapData", MapCache[gangName] or {})
		return
	end

	if actionType == "Engage" then 
		StartTerritoryBattle(player, actionData.TileId)
		return 
	end

	local battle = ActiveBattles[player.UserId]
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
			TerritoryUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = msg, DidHit = didHit, ShakeType = shakeType, SkillName = strikeSkill, Defender = defenderKey})
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

		if combatant.BlockTurns and combatant.BlockTurns > 0 then combatant.BlockTurns -= 1 end
		if combatant.CounterTurns and combatant.CounterTurns > 0 then combatant.CounterTurns -= 1 end
		if combatant.StunImmunity and combatant.StunImmunity > 0 then combatant.StunImmunity -= 1 end
		if combatant.ConfusionImmunity and combatant.ConfusionImmunity > 0 then combatant.ConfusionImmunity -= 1 end

		if combatant.Cooldowns then for sName, cd in pairs(combatant.Cooldowns) do if cd > 0 then combatant.Cooldowns[sName] = cd - 1 end end end
		for sName, sVal in pairs(combatant.Statuses) do 
			if (string.sub(sName, 1, 5) == "Buff_" or string.sub(sName, 1, 7) == "Debuff_" or string.find(sName, "Exhausted") or sName == "Dizzy" or sName == "Warded") and sVal > 0 then combatant.Statuses[sName] = sVal - 1 end 
		end

		local freezeResult = CombatCore.ApplyStatusDamage(combatant, "None", TerritoryUpdate, player, battle, waitMultiplier)
		if freezeResult == "Frozen" then continue end
		if combatant.HP < 1 then continue end

		if combatant.Statuses.Stun > 0 then
			combatant.Statuses.Stun -= 1
			TerritoryUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AAAAAA'>"..combatant.Name.." is Stunned!</font>", DidHit = false, ShakeType = "None"})
			task.wait(waitMultiplier); continue
		end

		if combatant.IsPlayer then
			if skill.Effect == "Flee" then
				TerritoryUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AAAAAA'>You fled the territory skirmish!</font>", DidHit = false, ShakeType = "None"})
				task.wait(waitMultiplier)

				local finalPack = { XP = 0, Yen = 0, Items = {} }
				TerritoryUpdate:FireClient(player, "Defeat", {Battle = battle, Drops = finalPack, CustomLog = "<font color='#AAAAAA'>You retreated. The sector remains hostile.</font>"})

				ActiveBattles[player.UserId] = nil
				player:SetAttribute("InCombat", false)
				return
			end
			DispatchStrike(battle.Player, battle.Enemy, skillName)
		else
			local eSkill = CombatCore.ChooseAISkill(combatant)
			DispatchStrike(battle.Enemy, battle.Player, eSkill)
		end
		if combatant.Statuses.Confusion > 0 then combatant.Statuses.Confusion -= 1 end
	end

	battle.TurnCounter += 1

	if battle.Player.HP < 1 or battle.Enemy.HP < 1 or battle.TurnCounter > MAX_TURNS then
		local tileId = tostring(battle.TileId)

		local isCaptured = (battle.Enemy.HP < 1) 

		if isCaptured then
			DirtyDamage[gangName] = DirtyDamage[gangName] or {}
			DirtyDamage[gangName][tileId] = 1

			MapCache[gangName] = MapCache[gangName] or {}
			MapCache[gangName][tileId] = 1
		end

		local pYen = isCaptured and math.floor((battle.Enemy.MaxHP * 0.05) * battle.Boosts.Yen) or 0
		local gangTokens = isCaptured and math.floor(battle.Enemy.MaxHP / 500) or 0

		if isCaptured then
			pcall(function()
				player.leaderstats.Yen.Value += pYen
				if gangTokens > 0 then
					local currentTokens = player:GetAttribute("GangTokens") or 0
					player:SetAttribute("GangTokens", currentTokens + gangTokens)
					GangLeaderboardUpdate:Fire(gangName, gangTokens)
				end
			end)
		end

		local resultLog = "<font color='#FFAA00'><b>Skirmish Finished!</b></font>\n"

		if isCaptured then
			resultLog = resultLog .. "<font color='#55FF55'><b>SECTOR CONQUERED!</b></font>\n"
			resultLog = resultLog .. "<font color='#55FF55'>Tokens Earned: " .. gangTokens .. "</font>"
		else
			resultLog = resultLog .. "<font color='#FF5555'><b>YOU FAILED TO DEFEAT THE GUARD!</b></font>\n"
			resultLog = resultLog .. "<font color='#AAAAAA'>The sector remains hostile.</font>"
		end

		local finalPack = { XP = 0, Yen = pYen, Items = {} }

		TerritoryUpdate:FireClient(player, "Defeat", {Battle = battle, Drops = finalPack, CustomLog = resultLog})

		ActiveBattles[player.UserId] = nil
		player:SetAttribute("InCombat", false)

		if isCaptured then
			for _, plr in ipairs(game.Players:GetPlayers()) do
				if plr:GetAttribute("Gang") == gangName then
					TerritoryUpdate:FireClient(plr, "MapData", MapCache[gangName])
				end
			end
		end
	else
		battle.IsProcessing = false
		TerritoryUpdate:FireClient(player, "Update", {Battle = battle})
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	ActiveBattles[player.UserId] = nil
	player:SetAttribute("InCombat", false)
end)