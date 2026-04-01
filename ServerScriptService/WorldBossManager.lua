-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local function GetOrCreateEvent(name, isBindable)
	local className = isBindable and "BindableEvent" or "RemoteEvent"
	local remote = Network:FindFirstChild(name)

	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = Network
	elseif remote.ClassName ~= className then
		remote:Destroy()
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = Network
	end

	return remote
end

local WorldBossAction = GetOrCreateEvent("WorldBossAction", false)
local WorldBossUpdate = GetOrCreateEvent("WorldBossUpdate", false)
local AdminForceSpawnWB = GetOrCreateEvent("AdminForceSpawnWB", true)
local RerollWorldBoss = GetOrCreateEvent("RerollWorldBoss", true)
local NotificationEvent = GetOrCreateEvent("NotificationEvent", false)
local WorldBossLogger = GetOrCreateEvent("WorldBossLogger", true)

local ActiveBossBattles = {}
local CurrentActiveBoss = nil
local LastSpawnHour = -1
local AdminForcedEndTime = 0

local BOSS_ACTIVE_MINUTES = 30

local APRIL_FOOLS_BOSSES = {
	"Chiikawa",
	"Satoru Gojo",
	"Ryomen Sukuna"
}

local function IsBossActive()
	if os.time() < AdminForcedEndTime then return true end
	local utc = os.date("!*t")
	return utc.min < BOSS_ACTIVE_MINUTES
end

local function GetAvailableBosses()
	local utc = os.date("!*t")
	local isAprilFools = (utc.month == 4 and utc.day == 1)
	local list = {}

	for bossName, _ in pairs(EnemyData.WorldBosses or {}) do
		if table.find(APRIL_FOOLS_BOSSES, bossName) then
			if isAprilFools then 
				table.insert(list, bossName) 
			end
		else
			table.insert(list, bossName)
		end
	end

	return list
end

pcall(function()
	AdminForceSpawnWB.Event:Connect(function(specificBossName)
		for _, p in ipairs(Players:GetPlayers()) do
			p:SetAttribute("LastWorldBossHour", -1)
		end

		local bossList = GetAvailableBosses()

		if #bossList > 0 then
			if specificBossName and EnemyData.WorldBosses[specificBossName] then
				CurrentActiveBoss = specificBossName
			else
				CurrentActiveBoss = bossList[math.random(1, #bossList)]
			end

			AdminForcedEndTime = os.time() + (BOSS_ACTIVE_MINUTES * 60)
			ReplicatedStorage:SetAttribute("WorldBossEndTime", AdminForcedEndTime)

			local spawnMsg = "<font color='#FF55FF'><b>[ADMIN EVENT] " .. CurrentActiveBoss .. " has been summoned! Cooldowns have been reset!</b></font>"
			Network.CombatUpdate:FireAllClients("SystemMessage", spawnMsg)
			NotificationEvent:FireAllClients("<font color='#FF55FF'><b>[ADMIN EVENT] " .. CurrentActiveBoss .. " has been summoned!</b></font>")
			WorldBossUpdate:FireAllClients("SyncBoss", CurrentActiveBoss)

			WorldBossLogger:Fire(CurrentActiveBoss)
		end
	end)
end)

RerollWorldBoss.Event:Connect(function(player)
	local bossList = GetAvailableBosses()

	if #bossList > 0 then
		local instancedBoss = bossList[math.random(1, #bossList)]
		local endTime = os.time() + (BOSS_ACTIVE_MINUTES * 60)

		player:SetAttribute("InstancedWorldBoss", instancedBoss)
		player:SetAttribute("InstancedWorldBossEndTime", endTime)
		player:SetAttribute("LastWorldBossHour", -1)

		local spawnMsg = "<font color='#55FF55'><b>[SYSTEM] You spawned a private " .. instancedBoss .. "! You have " .. BOSS_ACTIVE_MINUTES .. " minutes to engage!</b></font>"
		Network.CombatUpdate:FireClient(player, "SystemMessage", spawnMsg)
		NotificationEvent:FireClient(player, "<font color='#55FF55'><b>Private " .. instancedBoss .. " spawned!</b></font>")

		WorldBossUpdate:FireClient(player, "SyncBoss", CurrentActiveBoss)
	end
end)

task.spawn(function()
	while task.wait(1) do
		local utc = os.date("!*t")

		if IsBossActive() then
			if os.time() > AdminForcedEndTime and LastSpawnHour ~= utc.hour then
				LastSpawnHour = utc.hour

				local bossList = GetAvailableBosses()

				if #bossList > 0 then
					local timeSeed = (utc.year * 10000) + (utc.yday * 100) + utc.hour
					local globalRNG = Random.new(timeSeed)

					CurrentActiveBoss = bossList[globalRNG:NextInteger(1, #bossList)]

					local normalEndTime = os.time() + ((BOSS_ACTIVE_MINUTES - utc.min) * 60) - utc.sec
					ReplicatedStorage:SetAttribute("WorldBossEndTime", normalEndTime)

					local spawnMsg = "<font color='#FF5555'><b>[WORLD BOSS] " .. CurrentActiveBoss .. " has spawned! You have " .. BOSS_ACTIVE_MINUTES .. " minutes to engage!</b></font>"
					Network.CombatUpdate:FireAllClients("SystemMessage", spawnMsg)
					NotificationEvent:FireAllClients("<font color='#FF5555'><b>[WORLD BOSS] " .. CurrentActiveBoss .. " has spawned!</b></font>")
					WorldBossUpdate:FireAllClients("SyncBoss", CurrentActiveBoss)

					WorldBossLogger:Fire(CurrentActiveBoss)
				end
			end
		else
			if CurrentActiveBoss ~= nil then
				CurrentActiveBoss = nil
				ReplicatedStorage:SetAttribute("WorldBossEndTime", 0)
				WorldBossUpdate:FireAllClients("SyncBoss", "UNKNOWN THREAT")
			end
		end
	end
end)

local function StartBossBattle(player)
	local utc = os.date("!*t")

	local instancedBossName = player:GetAttribute("InstancedWorldBoss")
	local instancedEndTime = player:GetAttribute("InstancedWorldBossEndTime") or 0
	local hasInstanced = instancedBossName and (instancedEndTime > os.time())

	local activeBossName

	if hasInstanced then
		activeBossName = instancedBossName
	else
		activeBossName = CurrentActiveBoss
		if not activeBossName or not IsBossActive() then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>The World Boss is not currently active!</font>")
			return
		end

		local isStudio = game:GetService("RunService"):IsStudio()
		if player:GetAttribute("LastWorldBossHour") == utc.hour and not isStudio then
			Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>You have already challenged the World Boss this hour!</font>")
			return
		end
	end

	local bossTemplate = EnemyData.WorldBosses[activeBossName]
	if not bossTemplate then 
		return 
	end

	local pData = CombatCore.BuildPlayerStruct(player, true)

	local bossEntity = {
		IsPlayer = false, IsAlly = false, Name = bossTemplate.Name, Trait = "None", IsBoss = true,
		HP = bossTemplate.Health, MaxHP = bossTemplate.Health,
		TotalStrength = bossTemplate.Strength + (GameData.StandRanks[bossTemplate.StandStats.Power] or 0),
		TotalDefense = bossTemplate.Defense + (GameData.StandRanks[bossTemplate.StandStats.Durability] or 0),
		TotalSpeed = bossTemplate.Speed + (GameData.StandRanks[bossTemplate.StandStats.Speed] or 0),
		TotalWillpower = bossTemplate.Willpower,
		TotalRange = (GameData.StandRanks[bossTemplate.StandStats.Range] or 0),
		TotalPrecision = (GameData.StandRanks[bossTemplate.StandStats.Precision] or 0),
		BlockTurns = 0, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0,
		Statuses = { Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0 },
		Cooldowns = {}, Skills = bossTemplate.Skills
	}

	ActiveBossBattles[player.UserId] = {
		IsProcessing = false, TurnCounter = 1, Boosts = pData.Boosts, Drops = bossTemplate.Drops,
		Player = pData,
		Enemy = bossEntity,
		IsInstanced = hasInstanced
	}

	WorldBossUpdate:FireClient(player, "Start", { Battle = ActiveBossBattles[player.UserId], LogMsg = "<font color='#FF5555'>The sky darkens... " .. activeBossName .. " has arrived!</font>" })
	if not hasInstanced then
		player:SetAttribute("LastWorldBossHour", utc.hour)
	end
end

WorldBossAction.OnServerEvent:Connect(function(player, actionType, actionData)
	if actionType == "RequestSync" then
		WorldBossUpdate:FireClient(player, "SyncBoss", CurrentActiveBoss or "UNKNOWN THREAT")
		return
	elseif actionType == "Engage" then 
		StartBossBattle(player)
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
		local success, msg, didHit, shakeType = pcall(function()
			local lColor = attacker.IsPlayer and "#FFFFFF" or "#FF5555"
			local dColor = defender.IsPlayer and "#FFFFFF" or "#FF5555"
			local lName = attacker.IsPlayer and "You" or attacker.Name
			local dName = defender.IsPlayer and "you" or defender.Name
			return CombatCore.ExecuteStrike(attacker, defender, strikeSkill, "None", lName, dName, lColor, dColor)
		end)

		if success then
			WorldBossUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = msg, DidHit = didHit, ShakeType = shakeType})
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
			if (string.sub(sName, 1, 5) == "Buff_" or string.sub(sName, 1, 7) == "Debuff_") and sVal > 0 then combatant.Statuses[sName] = sVal - 1 end 
		end
		if combatant.StunImmunity and combatant.StunImmunity > 0 then combatant.StunImmunity -= 1 end
		if combatant.ConfusionImmunity and combatant.ConfusionImmunity > 0 then combatant.ConfusionImmunity -= 1 end
		if combatant.BlockTurns then combatant.BlockTurns = math.max(0, combatant.BlockTurns - 1) end

		local freezeResult = CombatCore.ApplyStatusDamage(combatant, "None", WorldBossUpdate, player, battle, waitMultiplier)
		if freezeResult == "Frozen" then continue end
		if combatant.HP < 1 then continue end

		if combatant.Statuses.Stun > 0 then
			combatant.Statuses.Stun -= 1
			if combatant.IsPlayer then
				combatant.Stamina = math.min(combatant.MaxStamina, combatant.Stamina + 5)
				combatant.StandEnergy = math.min(combatant.MaxStandEnergy, combatant.StandEnergy + 5)
			end
			WorldBossUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AAAAAA'>"..combatant.Name.." is Stunned and cannot move!</font>", DidHit = false, ShakeType = "None"})
			task.wait(waitMultiplier); continue
		end

		if combatant.IsPlayer then
			if skill.Effect == "Flee" then
				if battle.IsInstanced then
					player:SetAttribute("InstancedWorldBoss", nil)
					player:SetAttribute("InstancedWorldBossEndTime", 0)
				end
				WorldBossUpdate:FireClient(player, "TurnStrike", {Battle = battle, LogMsg = "<font color='#AAAAAA'>You fled the boss fight!</font>", DidHit = false, ShakeType = "None"})
				task.wait(waitMultiplier); WorldBossUpdate:FireClient(player, "Fled", {Battle = battle}); ActiveBossBattles[player.UserId] = nil
				if battle.IsInstanced then WorldBossUpdate:FireClient(player, "SyncBoss", CurrentActiveBoss) end
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

	if battle.Player.HP < 1 or battle.Enemy.HP < 1 or battle.TurnCounter > 10 then
		local isDeath = (battle.Player.HP < 1)
		local damageDealt = math.max(0, battle.Enemy.MaxHP - battle.Enemy.HP)
		local dmgBonusDropPercent = math.floor(damageDealt / 100000)

		pcall(function()
			if battle.Enemy.HP < 1 then
				local gangEvent = Network:FindFirstChild("AddGangOrderProgress")
				if gangEvent and gangEvent:IsA("BindableEvent") then gangEvent:Fire(player:GetAttribute("Gang"), "Raids", 1) end
			end
		end)

		local fXP = math.floor((damageDealt * 0.25) * battle.Boosts.XP)
		local fYen = math.floor((damageDealt * 0.1) * battle.Boosts.Yen)

		pcall(function()
			player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + fXP)
			player.leaderstats.Yen.Value += fYen
		end)

		local dropMultiplier = player:GetAttribute("Has2xDropChance") and 2 or 1
		local currentInv = 0
		local maxInv = 50
		pcall(function() currentInv = GameData.GetInventoryCount(player) end)
		pcall(function() maxInv = GameData.GetMaxInventory(player) end)

		local droppedItems = {}

		pcall(function()
			if not isDeath and battle.Drops and battle.Drops.ItemChance then
				for itemName, baseChance in pairs(battle.Drops.ItemChance) do
					local finalChance = (baseChance + dmgBonusDropPercent + battle.Boosts.Luck) * dropMultiplier

					if math.random(1, 100) <= finalChance then
						local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
						local itemRarity = itemData and itemData.Rarity or "Common"
						local isIgnored = itemData and (itemData.Rarity == "Unique" or (ItemData.Consumables[itemName] and itemData.Category == "Stand"))

						if player:GetAttribute("AutoSell_" .. itemRarity) and not isIgnored then
							local sellVal = itemData and (itemData.SellPrice or math.floor((itemData.Cost or 50) / 2)) or 25
							player.leaderstats.Yen.Value += sellVal
							table.insert(droppedItems, itemName .. " <font color='#AAAAAA'>(Auto-Sold: ¥" .. sellVal .. ")</font>")
						else
							if isIgnored then
								local attrName = itemName:gsub("[^%w]", "") .. "Count"
								player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + 1)
								table.insert(droppedItems, itemName)
							elseif currentInv < maxInv then
								local attrName = itemName:gsub("[^%w]", "") .. "Count"
								player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + 1)
								table.insert(droppedItems, itemName)
								currentInv += 1 
							else
								Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF5555'>Inventory Full! " .. itemName .. " was lost.</font>")
							end
						end
					end
				end
			end

			if isDeath then
				player:SetAttribute("StandArrowCount", (player:GetAttribute("StandArrowCount") or 0) + 1)
				table.insert(droppedItems, "<font color='#55FFFF'>1x Stand Arrow (Participation)</font>")
			end
		end)

		local resultLog = isDeath and "<font color='#FF5555'>You were defeated by the World Boss!</font>" or "<font color='#55FF55'>Battle Finished! The boss flees.</font>"
		resultLog = resultLog .. "\n<font color='#FFAA00'>Total Damage Dealt: " .. math.floor(damageDealt) .. "</font>"

		if battle.IsInstanced then
			player:SetAttribute("InstancedWorldBoss", nil)
			player:SetAttribute("InstancedWorldBossEndTime", 0)
		end

		local finalPack = { XP = fXP, Yen = fYen, Items = droppedItems }
		WorldBossUpdate:FireClient(player, isDeath and "Defeat" or "Victory", {Battle = battle, Drops = finalPack, CustomLog = resultLog})
		ActiveBossBattles[player.UserId] = nil

		if battle.IsInstanced then
			WorldBossUpdate:FireClient(player, "SyncBoss", CurrentActiveBoss)
		end
	else
		if stamCost == 0 then battle.Player.Stamina = math.min(battle.Player.MaxStamina, battle.Player.Stamina + 5) end
		if nrgCost == 0 then battle.Player.StandEnergy = math.min(battle.Player.MaxStandEnergy, battle.Player.StandEnergy + 5) end

		local vigCount = CombatCore.CountTrait(battle.Player, "Vigorous")
		if vigCount > 0 then 
			battle.Player.Stamina = math.min(battle.Player.MaxStamina, battle.Player.Stamina + (10 * vigCount))
			battle.Player.StandEnergy = math.min(battle.Player.MaxStandEnergy, battle.Player.StandEnergy + (10 * vigCount)) 
		end

		battle.IsProcessing = false
		WorldBossUpdate:FireClient(player, "Update", {Battle = battle})
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	ActiveBossBattles[player.UserId] = nil
	player:SetAttribute("InstancedWorldBoss", nil)
	player:SetAttribute("InstancedWorldBossEndTime", 0)
end)