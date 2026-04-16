-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))
local Network = ReplicatedStorage:WaitForChild("Network")
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local RaidAction = Network:WaitForChild("RaidAction")
local RaidUpdate = Network:WaitForChild("RaidUpdate")

local OpenLobbies = {} 
local ActiveRaids = {} 
local StartLocks = {}

local function GetLobbyData(raidId)
	local list = {}
	for hostId, data in pairs(OpenLobbies) do
		if data.RaidId == raidId then
			local members = {}
			for _, p in ipairs(data.Queue) do table.insert(members, p.Name) end
			table.insert(list, { 
				HostId = hostId, 
				HostName = data.Host.Name, 
				FriendsOnly = data.FriendsOnly, 
				PlayerCount = #data.Queue,
				Members = members 
			})
		end
	end
	return list
end

local function LeaveAllLobbies(player)
	RaidUpdate:FireClient(player, "LobbyStatus", {IsHosting = false})

	if OpenLobbies[player.UserId] then
		local rId = OpenLobbies[player.UserId].RaidId
		for _, qp in ipairs(OpenLobbies[player.UserId].Queue) do 
			if qp ~= player then 
				RaidUpdate:FireClient(qp, "LobbyStatus", {IsHosting = false}) 
			end
		end
		OpenLobbies[player.UserId] = nil
		RaidUpdate:FireAllClients("LobbiesUpdate", {RaidId = rId, Lobbies = GetLobbyData(rId)})
	end

	for hId, lobby in pairs(OpenLobbies) do
		for i, qp in ipairs(lobby.Queue) do
			if qp == player then
				table.remove(lobby.Queue, i)
				for _, rem in ipairs(lobby.Queue) do 
					RaidUpdate:FireClient(rem, "LobbyStatus", {IsHosting = true, IsLobbyOwner = (rem.UserId == hId), PlayerCount = #lobby.Queue}) 
				end
				RaidUpdate:FireAllClients("LobbiesUpdate", {RaidId = lobby.RaidId, Lobbies = GetLobbyData(lobby.RaidId)})
				break
			end
		end
	end
end

local function GetClientState(match, myId)
	local state = {
		Party = {}, 
		Boss = { 
			Name = match.Boss.Name, Icon = match.Boss.Icon, HP = match.Boss.HP, MaxHP = match.Boss.MaxHP, 
			Stamina = match.Boss.Stamina, MaxStamina = match.Boss.MaxStamina, StandEnergy = match.Boss.StandEnergy, MaxStandEnergy = match.Boss.MaxStandEnergy,
			StunImmunity = match.Boss.StunImmunity, ConfusionImmunity = match.Boss.ConfusionImmunity, Statuses = match.Boss.Statuses 
		}, 
		MyId = myId
	}
	for _, pData in ipairs(match.Party) do
		table.insert(state.Party, { 
			UserId = pData.UserId, Name = pData.Name, HP = pData.HP, MaxHP = pData.MaxHP, 
			Stamina = pData.Stamina, MaxStamina = pData.MaxStamina, StandEnergy = pData.StandEnergy, MaxStandEnergy = pData.MaxStandEnergy, 
			Cooldowns = pData.Cooldowns, Stand = pData.Stand, Style = pData.Style, Statuses = pData.Statuses, 
			StunImmunity = pData.StunImmunity, ConfusionImmunity = pData.ConfusionImmunity 
		})
	end
	return state
end

local function ProcessTurn(match)
	if not match or match.IsProcessing or match.IsDead then return end
	match.IsProcessing = true

	local waitMultiplier = 1.2
	local partyHasFastPass = true
	for _, pData in ipairs(match.Party) do
		if not pData.Player:GetAttribute("Has2xBattleSpeed") then
			partyHasFastPass = false
			break
		end
	end
	if partyHasFastPass then waitMultiplier = 0.6 end

	local allCombatants = {}
	for _, p in ipairs(match.Party) do table.insert(allCombatants, p) end
	table.insert(allCombatants, match.Boss)

	table.sort(allCombatants, function(a, b) 
		local spdA = (a and a.TotalSpeed or 0) * (((a.Statuses and a.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((a.Statuses and a.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		local spdB = (b and b.TotalSpeed or 0) * (((b.Statuses and b.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((b.Statuses and b.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		return spdA > spdB
	end)

	local function IsPartyDead()
		for _, p in ipairs(match.Party) do if p.HP > 0 then return false end end
		return true
	end

	local function GetAliveTarget(isBossAttacking)
		if isBossAttacking then
			local alive = {}
			for _, p in ipairs(match.Party) do if p.HP > 0 then table.insert(alive, p) end end
			if #alive > 0 then return alive[math.random(1, #alive)] end
		else
			if match.Boss.HP > 0 then return match.Boss end
		end
		return nil
	end

	for _, attacker in ipairs(allCombatants) do
		if match.IsDead then return end
		if IsPartyDead() or match.Boss.HP < 1 then break end
		if not attacker or attacker.HP < 1 then continue end

		local uniModStr = "None" 
		if attacker.IsPlayer then uniModStr = attacker.PlayerObj and attacker.PlayerObj:GetAttribute("UniverseModifier") or "None" end

		if attacker.StunImmunity and attacker.StunImmunity > 0 then attacker.StunImmunity -= 1 end
		if attacker.ConfusionImmunity and attacker.ConfusionImmunity > 0 then attacker.ConfusionImmunity -= 1 end

		local statusDmgMod = 0.05 
		if attacker.IsBoss then statusDmgMod = statusDmgMod * 0.85 end
		local unstableMult = CombatCore.HasModifier(uniModStr, "Unstable") and 2.0 or 1.0

		local function ProcessDoT(statusName, hexColor, mult)
			if attacker.Statuses and (attacker.Statuses[statusName] or 0) > 0 then
				local dmg = math.max(1, attacker.MaxHP * statusDmgMod * mult) * unstableMult
				local survived = CombatCore.TakeDamageWithWillpower(attacker, dmg)
				attacker.Statuses[statusName] -= 1
				local svMsg = survived and (CombatCore.CountTrait(attacker, "Perseverance") > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
				local msg = "<font color='"..hexColor.."'>"..attacker.Name.." took "..math.floor(dmg).." "..statusName.." damage!"..svMsg.."</font>"
				for _, p in ipairs(match.Party) do 
					if ActiveRaids[p.Player] == match then
						RaidUpdate:FireClient(p.Player, "TurnResult", {LogMsg = msg, State = GetClientState(match, p.UserId), DidHit = true, ShakeType = "Light", Deadline = match.TurnDeadline}) 
					end
				end
				task.wait(waitMultiplier)
				return true
			end
			return false
		end

		local dotsToProcess = {
			{Name="Calamity", Color="#CC00FF", Mult=1.75},
			{Name="Blight", Color="#4B0082", Mult=1.5},
			{Name="Miasma", Color="#2E8B57", Mult=1.5},
			{Name="Necrosis", Color="#8B4513", Mult=1.5},
			{Name="Plague", Color="#556B2F", Mult=1.5},
			{Name="Acid", Color="#80FF00", Mult=1.25},
			{Name="Infection", Color="#800000", Mult=1.25},
			{Name="Rupture", Color="#FF4400", Mult=1.25},
			{Name="Frostburn", Color="#55AAFF", Mult=1.25},
			{Name="Frostbite", Color="#0055FF", Mult=1.25},
			{Name="Decay", Color="#00AA55", Mult=1.25},
			{Name="Bleed", Color="#FF0000", Mult=1.0},
			{Name="Poison", Color="#AA00AA", Mult=1.0},
			{Name="Burn", Color="#FF5500", Mult=1.0},
			{Name="Chilly", Color="#66CCFF", Mult=1.0}
		}

		for _, dot in ipairs(dotsToProcess) do
			if ProcessDoT(dot.Name, dot.Color, dot.Mult) then 
				if attacker.HP < 1 or match.IsDead then break end
			end
		end

		if match.IsDead then return end
		if attacker.HP < 1 then continue end

		if attacker.Statuses and (attacker.Statuses.Freeze or 0) > 0 then
			local dmg = math.max(1, attacker.MaxHP * statusDmgMod)
			local survived = CombatCore.TakeDamageWithWillpower(attacker, dmg)
			attacker.Statuses.Freeze -= 1
			local svMsg = survived and (CombatCore.CountTrait(attacker, "Perseverance") > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
			local msg = "<font color='#00FFFF'>"..attacker.Name.." took "..math.floor(dmg).." Freeze damage and is frozen solid!"..svMsg.."</font>"
			for _, p in ipairs(match.Party) do 
				if ActiveRaids[p.Player] == match then
					RaidUpdate:FireClient(p.Player, "TurnResult", {LogMsg = msg, State = GetClientState(match, p.UserId), DidHit = true, ShakeType = "Light", Deadline = match.TurnDeadline}) 
				end
			end
			task.wait(waitMultiplier)
			if match.IsDead then return end
			if attacker.HP < 1 then continue end
			if not attacker.IsBoss then
				attacker.Stamina = math.min(attacker.MaxStamina, attacker.Stamina + 5)
				attacker.StandEnergy = math.min(attacker.MaxStandEnergy, attacker.StandEnergy + 5)
				attacker.SelectedSkill = nil 
			end
			continue
		end

		if attacker.Statuses and (attacker.Statuses.Stun or 0) > 0 then
			attacker.Statuses.Stun -= 1
			if not attacker.IsBoss then
				attacker.Stamina = math.min(attacker.MaxStamina, attacker.Stamina + 5)
				attacker.StandEnergy = math.min(attacker.MaxStandEnergy, attacker.StandEnergy + 5)
				attacker.SelectedSkill = nil 
			end
			local msg = "<font color='#AAAAAA'>"..attacker.Name.." is Stunned!</font>"
			for _, p in ipairs(match.Party) do 
				if ActiveRaids[p.Player] == match then
					RaidUpdate:FireClient(p.Player, "TurnResult", {LogMsg = msg, State = GetClientState(match, p.UserId), DidHit = false, ShakeType = "None", Deadline = match.TurnDeadline}) 
				end
			end
			task.wait(waitMultiplier)
			if match.IsDead then return end
			continue
		end

		local skillName = attacker.SelectedSkill
		if attacker.IsBoss then
			skillName = CombatCore.ChooseAISkill(attacker)
			if attacker.Cooldowns then attacker.Cooldowns[skillName] = SkillData.Skills[skillName].Cooldown or 0 end
		end

		local skillDataRef = SkillData.Skills[skillName]
		if not attacker.IsBoss and skillDataRef then
			if skillDataRef.Effect == "Flee" then
				attacker.HP = 0
				local msg = "<font color='#AAAAAA'>"..attacker.Name.." fled the raid!</font>"
				for _, p in ipairs(match.Party) do 
					if ActiveRaids[p.Player] == match then
						RaidUpdate:FireClient(p.Player, "TurnResult", {LogMsg = msg, State = GetClientState(match, p.UserId), DidHit = false, ShakeType = "None", Deadline = match.TurnDeadline}) 
					end
				end
				task.wait(waitMultiplier)
				if match.IsDead then return end
				continue
			end
		end

		local defender = GetAliveTarget(attacker.IsBoss)
		if skillName and defender then
			local lColor = attacker.IsBoss and "#FF5555" or "#55FF55"
			local dColor = defender.IsBoss and "#FF5555" or "#55FF55"

			local msg, hit, shake = CombatCore.ExecuteStrike(attacker, defender, skillName, uniModStr, attacker.Name, defender.Name, lColor, dColor)
			for _, p in ipairs(match.Party) do 
				if ActiveRaids[p.Player] == match then
					RaidUpdate:FireClient(p.Player, "TurnResult", {LogMsg = msg, State = GetClientState(match, p.UserId), DidHit = hit, ShakeType = shake, Deadline = match.TurnDeadline}) 
				end
			end
			task.wait(waitMultiplier)
			if match.IsDead then return end
		end

		if attacker.Statuses and (attacker.Statuses.Confusion or 0) > 0 then attacker.Statuses.Confusion -= 1 end
	end

	for _, combatant in ipairs(allCombatants) do
		if not combatant or combatant.HP < 1 then continue end
		if combatant.Cooldowns then for sName, cd in pairs(combatant.Cooldowns) do if cd > 0 then combatant.Cooldowns[sName] = cd - 1 end end end

		if combatant.Statuses then 
			for sName, sVal in pairs(combatant.Statuses) do 
				if (string.sub(sName, 1, 5) == "Buff_" or string.sub(sName, 1, 7) == "Debuff_" or string.find(sName, "Exhausted") or sName == "Dizzy" or sName == "Warded") and sVal > 0 then combatant.Statuses[sName] = sVal - 1 end 
			end 
		end

		if combatant.BlockTurns then combatant.BlockTurns = math.max(0, combatant.BlockTurns - 1) end
		if combatant.CounterTurns then combatant.CounterTurns = math.max(0, combatant.CounterTurns - 1) end

		if not combatant.IsBoss then 
			local usedSkillData = SkillData.Skills[combatant.SelectedSkill]
			if usedSkillData then
				if usedSkillData.StaminaCost == 0 then combatant.Stamina = math.min(combatant.MaxStamina, combatant.Stamina + 5) end
				if usedSkillData.EnergyCost == 0 then combatant.StandEnergy = math.min(combatant.MaxStandEnergy, combatant.StandEnergy + 5) end
			end

			local vigCount = CombatCore.CountTrait(combatant, "Vigorous")
			if vigCount > 0 then
				combatant.Stamina = math.min(combatant.MaxStamina, combatant.Stamina + (10 * vigCount))
				combatant.StandEnergy = math.min(combatant.MaxStandEnergy, combatant.StandEnergy + (10 * vigCount))
			end
			combatant.SelectedSkill = nil 
		end
	end

	if IsPartyDead() or match.Boss.HP < 1 then
		match.IsDead = true
		local isWin = match.Boss.HP < 1
		local endMsg = isWin and "<font color='#55FF55'>RAID CLEARED!</font>" or "<font color='#FF5555'>PARTY DEFEATED!</font>"

		for _, pData in ipairs(match.Party) do
			if ActiveRaids[pData.Player] ~= match then continue end

			local pDrops = {}
			if isWin then
				local gangEvent = Network:FindFirstChild("AddGangOrderProgress")
				if gangEvent then gangEvent:Fire(pData.Player:GetAttribute("Gang"), "Raids", 1) end

				pData.Player:SetAttribute("RaidWins", (pData.Player:GetAttribute("RaidWins") or 0) + 1)
				local repEvent = ReplicatedStorage:FindFirstChild("AwardGangReputation")
				if repEvent then repEvent:Fire(pData.Player.UserId, 50) end

				local fXP = math.floor(match.ScaledDrops.XP * pData.Boosts.XP)
				local fYen = math.floor(match.ScaledDrops.Yen * pData.Boosts.Yen)
				pData.Player:SetAttribute("XP", (pData.Player:GetAttribute("XP") or 0) + fXP)
				pData.Player.leaderstats.Yen.Value += fYen

				local dropMultiplier = pData.Player:GetAttribute("Has2xDropChance") and 2 or 1
				local currentInv = GameData.GetInventoryCount(pData.Player)
				local maxInv = GameData.GetMaxInventory(pData.Player)

				if pData.Player:GetAttribute("IsInGroup") and not pData.Player:GetAttribute("ClaimedGroupRaidBonus") then
					pData.Player:SetAttribute("StandArrowCount", (pData.Player:GetAttribute("StandArrowCount") or 0) + 5)
					pData.Player:SetAttribute("RokakakaCount", (pData.Player:GetAttribute("RokakakaCount") or 0) + 3)
					pData.Player:SetAttribute("ClaimedGroupRaidBonus", true)
					table.insert(pDrops, "<font color='#FFFF55'>Loot: 5x Stand Arrow, 3x Rokakaka (Group Bonus)</font>")
				end

				local droppedItems = {}
				if match.ScaledDrops.ItemChance then
					for itemName, chanceData in pairs(match.ScaledDrops.ItemChance) do
						local baseChance = type(chanceData) == "table" and chanceData.Chance or chanceData
						local boostedChance = (baseChance + pData.Boosts.Luck) * dropMultiplier

						if math.random(1, 100) <= boostedChance then
							local amount = type(chanceData) == "table" and math.random(chanceData.Min, chanceData.Max) or 1
							local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
							local itemRarity = itemData and itemData.Rarity or "Common"
							local isIgnored = itemData and (itemData.Rarity == "Unique" or (ItemData.Consumables[itemName] and itemData.Category == "Stand") or itemData.Rarity == "Special")

							if pData.Player:GetAttribute("AutoSell_" .. itemRarity) and not isIgnored then
								local sellVal = itemData and (itemData.SellPrice or math.floor((itemData.Cost or 50) / 2)) or 25
								pData.Player.leaderstats.Yen.Value += (sellVal * amount)
								table.insert(droppedItems, amount .. "x " .. itemName .. " <font color='#AAAAAA'>(Auto-Sold: ¥" .. (sellVal * amount) .. ")</font>")
							else
								if isIgnored then
									local attrName = itemName:gsub("[^%w]", "") .. "Count"
									pData.Player:SetAttribute(attrName, (pData.Player:GetAttribute(attrName) or 0) + amount)
									table.insert(droppedItems, amount .. "x " .. itemName)
								elseif currentInv < maxInv then
									local attrName = itemName:gsub("[^%w]", "") .. "Count"
									pData.Player:SetAttribute(attrName, (pData.Player:GetAttribute(attrName) or 0) + amount)
									table.insert(droppedItems, amount .. "x " .. itemName)
									currentInv += amount
								else
									Network.CombatUpdate:FireClient(pData.Player, "SystemMessage", "<font color='#FF5555'>Inventory Full! " .. itemName .. " was lost.</font>")
								end
							end
						end
					end
				end
				table.insert(pDrops, "<font color='#55FF55'>+"..fXP.." XP, +¥"..fYen.."</font>")
				if #droppedItems > 0 then table.insert(pDrops, "<font color='#FFFF55'>Loot: " .. table.concat(droppedItems, ", ") .. "</font>") end
			end
			RaidUpdate:FireClient(pData.Player, "MatchOver", {Result = isWin and "Win" or "Loss", LogMsg = endMsg .. "\n" .. table.concat(pDrops, "\n")})
			ActiveRaids[pData.Player] = nil
			pData.Player:SetAttribute("InCombat", false)
		end
	else
		match.IsProcessing = false; match.TurnDeadline = math.floor(workspace:GetServerTimeNow()) + 15
		for _, pData in ipairs(match.Party) do
			if pData.HP > 0 and ActiveRaids[pData.Player] == match then 
				RaidUpdate:FireClient(pData.Player, "TurnResult", {LogMsg = "", State = GetClientState(match, pData.UserId), DidHit = false, ShakeType = "None", Deadline = match.TurnDeadline}) 
			end
		end
	end
end

local function StartRaidMatch(hostId)
	local lobby = OpenLobbies[hostId]
	if not lobby then return end

	local party = {}
	local totalPrestige = 0
	for _, p in ipairs(lobby.Queue) do
		table.insert(party, CombatCore.BuildPlayerStruct(p, true))
		totalPrestige += (p.leaderstats.Prestige.Value or 0)
	end

	local avgPrestige = totalPrestige / #lobby.Queue
	local prestigeMult = 1 + (avgPrestige * 0.10)
	local minorMult = 1 + (avgPrestige * 0.05)
	local partyMult = #lobby.Queue * 0.2 

	local bossTemplate = EnemyData.RaidBosses[lobby.RaidId]
	local finalHP = math.floor(bossTemplate.Health * prestigeMult * (1 + partyMult))
	local finalStr = math.floor(bossTemplate.Strength * prestigeMult * (1 + partyMult))

	local sStats = bossTemplate.StandStats or {Power="None", Speed="None", Range="None", Durability="None", Precision="None", Potential="None"}

	local calcStamina = bossTemplate.Stamina or (150 + ((bossTemplate.Willpower or 1) * 2) + (finalHP * 0.05))
	local calcEnergy = bossTemplate.StandEnergy or (150 + ((GameData.StandRanks[sStats.Potential] or 0) * 10) + (finalHP * 0.05))

	local raidBoss = {
		IsBoss = true, Name = bossTemplate.Name, Icon = bossTemplate.Icon or "", HP = finalHP, MaxHP = finalHP, TotalStrength = finalStr,
		TotalDefense = math.floor(bossTemplate.Defense * prestigeMult), TotalSpeed = math.floor(bossTemplate.Speed * minorMult), TotalWillpower = math.floor(bossTemplate.Willpower * minorMult),
		Stamina = calcStamina, MaxStamina = calcStamina, StandEnergy = calcEnergy, MaxStandEnergy = calcEnergy,
		Statuses = { 
			Stun = 0, Poison = 0, Burn = 0, Bleed = 0, Freeze = 0, Confusion = 0, 
			Buff_Strength = 0, Buff_Defense = 0, Buff_Speed = 0, Buff_Willpower = 0, 
			Debuff_Strength = 0, Debuff_Defense = 0, Debuff_Speed = 0, Debuff_Willpower = 0,
			StaminaExhausted = 0, EnergyExhausted = 0, Dizzy = 0, Chilly = 0,
			Acid = 0, Infection = 0, Rupture = 0, Frostburn = 0, Frostbite = 0, Decay = 0,
			Blight = 0, Miasma = 0, Necrosis = 0, Plague = 0, Calamity = 0, Warded = 0 
		},
		BlockTurns = 0, CounterTurns = 0, Cooldowns = {}, StunImmunity = 0, ConfusionImmunity = 0, WillpowerSurvivals = 0, Skills = bossTemplate.Skills
	}

	local match = { Id = HttpService:GenerateGUID(false), Party = party, Boss = raidBoss, ScaledDrops = { XP = math.floor(bossTemplate.Drops.XP * prestigeMult), Yen = math.floor(bossTemplate.Drops.Yen * prestigeMult), ItemChance = bossTemplate.Drops.ItemChance }, RaidId = lobby.RaidId, IsProcessing = false, IsDead = false, TurnDeadline = math.floor(workspace:GetServerTimeNow()) + 15 }

	for _, pData in ipairs(party) do 
		pData.Cooldowns = {}

		if ActiveRaids[pData.Player] then
			ActiveRaids[pData.Player].IsDead = true 
		end

		ActiveRaids[pData.Player] = match 
		pData.Player:SetAttribute("InCombat", true)
	end

	for _, pData in ipairs(party) do 
		RaidUpdate:FireClient(pData.Player, "MatchStart", { State = GetClientState(match, pData.UserId), LogMsg = "The Raid Boss approaches...", Deadline = match.TurnDeadline }) 
	end

	OpenLobbies[hostId] = nil
end

task.spawn(function()
	while task.wait(1) do
		local checked = {}
		for _, match in pairs(ActiveRaids) do
			if match and not checked[match] and not match.IsProcessing and not match.IsDead and match.TurnDeadline and math.floor(workspace:GetServerTimeNow()) >= match.TurnDeadline then
				checked[match] = true
				for _, p in ipairs(match.Party) do if p.HP > 0 and not p.SelectedSkill then p.SelectedSkill = "Basic Attack" end end
				task.spawn(function() ProcessTurn(match) end)
			end
		end
	end
end)

RaidAction.OnServerEvent:Connect(function(player, action, data)
	if action == "RequestLobbies" then 
		RaidUpdate:FireClient(player, "LobbiesUpdate", {RaidId = data, Lobbies = GetLobbyData(data)})

	elseif action == "CreateLobby" then
		if ActiveRaids[player] then return end
		LeaveAllLobbies(player)
		OpenLobbies[player.UserId] = { Host = player, RaidId = data.RaidId, Queue = {player}, FriendsOnly = data.FriendsOnly }
		RaidUpdate:FireClient(player, "LobbyStatus", {IsHosting = true, IsLobbyOwner = true, PlayerCount = 1})

		RaidUpdate:FireAllClients("LobbiesUpdate", {RaidId = data.RaidId, Lobbies = GetLobbyData(data.RaidId)})

	elseif action == "CancelLobby" then
		LeaveAllLobbies(player)

	elseif action == "JoinLobby" then
		if ActiveRaids[player] then return end
		LeaveAllLobbies(player)

		local lobby = OpenLobbies[data.HostId]
		if lobby and #lobby.Queue < 4 then
			table.insert(lobby.Queue, player)
			for _, qp in ipairs(lobby.Queue) do RaidUpdate:FireClient(qp, "LobbyStatus", {IsHosting = true, IsLobbyOwner = (qp.UserId == data.HostId), PlayerCount = #lobby.Queue}) end
			RaidUpdate:FireAllClients("LobbiesUpdate", {RaidId = lobby.RaidId, Lobbies = GetLobbyData(lobby.RaidId)})
		end

	elseif action == "ForceStartRaid" then
		if StartLocks[player.UserId] then return end
		StartLocks[player.UserId] = true
		if OpenLobbies[player.UserId] then StartRaidMatch(player.UserId) end
		task.delay(1, function() StartLocks[player.UserId] = nil end)

	elseif action == "Attack" then
		local m = ActiveRaids[player]
		if m and not m.IsProcessing and not m.IsDead then
			for _, p in ipairs(m.Party) do
				if p.Player == player then
					local skill = SkillData.Skills[data]
					if not table.find(p.Skills, data) then break end
					if skill and p.Stamina >= (skill.StaminaCost or 0) and p.StandEnergy >= (skill.EnergyCost or 0) then
						p.SelectedSkill = data
						RaidUpdate:FireClient(player, "Waiting")
					end
					break
				end
			end
			local ready = true
			for _, p in ipairs(m.Party) do if p.HP > 0 and not p.SelectedSkill then ready = false break end end
			if ready then ProcessTurn(m) end
		end
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	LeaveAllLobbies(player)

	local match = ActiveRaids[player]
	if match then
		local combatant
		for i, p in ipairs(match.Party) do
			if p.Player == player then 
				combatant = p 
				table.remove(match.Party, i)
				break 
			end
		end

		if #match.Party == 0 then
			match.IsDead = true
		elseif combatant and not match.IsProcessing then
			local allReady = true
			for _, p in ipairs(match.Party) do if p.HP > 0 and not p.SelectedSkill then allReady = false break end end
			if allReady then ProcessTurn(match) end
		end

		ActiveRaids[player] = nil
	end
	player:SetAttribute("InCombat", false)
end)