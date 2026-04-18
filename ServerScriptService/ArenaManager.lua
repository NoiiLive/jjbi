-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local Network = ReplicatedStorage:WaitForChild("Network")
local CombatCore = require(game:GetService("ServerScriptService"):WaitForChild("CombatCore"))

local ArenaAction = Network:WaitForChild("ArenaAction")
local ArenaUpdate = Network:WaitForChild("ArenaUpdate")

local OpenLobbies = {} 
local ActiveMatches = {} 
local SpectatingMatches = {} 
local MatchRegistry = {} 

local function GetLobbyData()
	local list = {}
	for hostId, data in pairs(OpenLobbies) do
		table.insert(list, {
			HostId = hostId,
			HostName = data.Host.Name,
			Elo = data.Elo,
			FriendsOnly = data.FriendsOnly,
			Casual = data.Casual,
			NoHoldsBarred = data.NoHoldsBarred,
			Capacity = data.Capacity,
			T1Count = #data.Team1Queue,
			T2Count = #data.Team2Queue
		})
	end
	return list
end

local function GetActiveMatchesData()
	local list = {}
	for matchId, match in pairs(MatchRegistry) do
		table.insert(list, {
			MatchId = matchId,
			HostName = match.HostName,
			Mode = (match.Capacity == 2 and "1v1") or (match.Capacity == 4 and "2v2") or "4v4",
			Pool1 = match.Pool1,
			Pool2 = match.Pool2,
			SpectatorCount = #match.Spectators
		})
	end
	return list
end

local function UpdateTeamElo(winningTeam, losingTeam)
	local wTotal, lTotal = 0, 0
	for _, pData in ipairs(winningTeam) do wTotal += pData.Player.leaderstats.Elo.Value end
	for _, pData in ipairs(losingTeam) do lTotal += pData.Player.leaderstats.Elo.Value end

	local wAvg = wTotal / #winningTeam
	local lAvg = lTotal / #losingTeam

	local expW = 1 / (1 + 10^((lAvg - wAvg) / 400))
	local expL = 1 / (1 + 10^((wAvg - lAvg) / 400))

	local wGain = math.floor(32 * (1 - expW))
	local lLoss = math.floor(32 * (0 - expL))

	for _, pData in ipairs(winningTeam) do pData.Player.leaderstats.Elo.Value += wGain end
	for _, pData in ipairs(losingTeam) do pData.Player.leaderstats.Elo.Value = math.max(0, pData.Player.leaderstats.Elo.Value + lLoss) end

	return wGain, lLoss
end

local function GetClientState(match, requestingPlayer, isSpectator)
	local myTeamStruct, enemyTeamStruct = match.Team1, match.Team2

	if not isSpectator then
		local inTeam1 = false
		for _, p in ipairs(match.Team1) do 
			if p.Player == requestingPlayer then 
				inTeam1 = true; break 
			end 
		end

		if not inTeam1 then 
			myTeamStruct = match.Team2
			enemyTeamStruct = match.Team1 
		end
	end

	local state = { MyTeam = {}, EnemyTeam = {}, MyId = requestingPlayer.UserId, IsSpectator = isSpectator, Pool1 = match.Pool1, Pool2 = match.Pool2, MatchId = match.Id }

	for _, p in ipairs(myTeamStruct) do table.insert(state.MyTeam, { UserId = p.UserId, Name = p.Name, HP = p.HP, MaxHP = p.MaxHP, Stamina = p.Stamina, MaxStamina = p.MaxStamina, StandEnergy = p.StandEnergy, MaxStandEnergy = p.MaxStandEnergy, Cooldowns = p.Cooldowns, BlockTurns = p.BlockTurns, StunImmunity = p.StunImmunity, ConfusionImmunity = p.ConfusionImmunity, Stand = p.Stand, Style = p.Style, Statuses = p.Statuses }) end
	for _, p in ipairs(enemyTeamStruct) do table.insert(state.EnemyTeam, { UserId = p.UserId, Name = p.Name, HP = p.HP, MaxHP = p.MaxHP, Stamina = p.Stamina, MaxStamina = p.MaxStamina, StandEnergy = p.StandEnergy, MaxStandEnergy = p.MaxStandEnergy, StunImmunity = p.StunImmunity, ConfusionImmunity = p.ConfusionImmunity, Stand = p.Stand, Style = p.Style, Statuses = p.Statuses }) end

	return state
end

local function IsTeamDead(team)
	for _, p in ipairs(team) do if p.HP > 0 then return false end end
	return true
end

local function GetAliveEnemy(enemyTeam)
	local alive = {}
	for _, p in ipairs(enemyTeam) do if p.HP > 0 then table.insert(alive, p) end end
	if #alive > 0 then return alive[math.random(1, #alive)] end
	return nil
end

local function ProcessTurn(match)
	match.IsProcessing = true
	local logMessages = {}

	local allCombatants = {}
	for _, p in ipairs(match.Team1) do table.insert(allCombatants, p) end
	for _, p in ipairs(match.Team2) do table.insert(allCombatants, p) end

	table.sort(allCombatants, function(a, b) 
		local aSpd = a.TotalSpeed * (((a.Statuses and a.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((a.Statuses and a.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		local bSpd = b.TotalSpeed * (((b.Statuses and b.Statuses.Buff_Speed or 0) > 0) and 1.5 or 1.0) * (((b.Statuses and b.Statuses.Debuff_Speed or 0) > 0) and 0.5 or 1.0)
		return aSpd > bSpd 
	end)

	local didHit, shakeType = false, "None"

	for _, attacker in ipairs(allCombatants) do
		if IsTeamDead(match.Team1) or IsTeamDead(match.Team2) then break end
		if attacker.HP < 1 then continue end

		local uniModStr = "None" 
		if attacker.IsPlayer and attacker.PlayerObj then uniModStr = attacker.PlayerObj:GetAttribute("UniverseModifier") or "None" end

		if attacker.StunImmunity and attacker.StunImmunity > 0 then attacker.StunImmunity -= 1 end
		if attacker.ConfusionImmunity and attacker.ConfusionImmunity > 0 then attacker.ConfusionImmunity -= 1 end

		local enemyTeam = nil
		for _, p in ipairs(match.Team1) do if p == attacker then enemyTeam = match.Team2 break end end
		if not enemyTeam then enemyTeam = match.Team1 end

		local statCap = math.huge
		local domCount = 0

		local highestStat = 0
		for _, p in ipairs(enemyTeam) do
			if p.HP > 0 then
				local pStat = (math.max(p.TotalStrength or 0, p.StyleStrength or 0, p.StandStrength or 0) + 100) * 3.5
				if pStat > highestStat then highestStat = pStat end
				local pDom = CombatCore.CountTrait(p, "Dominating")
				if pDom > domCount then domCount = pDom end
			end
		end
		if highestStat > 0 then statCap = highestStat end

		local armorIgnore = math.min(0.30, domCount * 0.15)
		local defBuff = (attacker.Statuses and (attacker.Statuses.Buff_Defense or 0) > 0) and 1.5 or 1.0
		local defDebuff = (attacker.Statuses and (attacker.Statuses.Debuff_Defense or 0) > 0) and 0.5 or 1.0
		local effectiveArmor = ((attacker.TotalDefense or 0) * defBuff * defDebuff) * (1 - armorIgnore)
		local scaledDef = math.max(0, effectiveArmor)
		if scaledDef > 200 then scaledDef = 200 + ((scaledDef - 200) ^ 0.7) end
		local defMult = 100 / (100 + scaledDef)

		local isBlocking = (attacker.BlockTurns or 0) > 0
		local blockMult = isBlocking and 0.5 or 1.0
		local statusBlockMult = isBlocking and 0.25 or 1.0
		local statusDmgMod = 0.05
		local unstableMult = CombatCore.HasModifier(uniModStr, "Unstable") and 2.0 or 1.0

		local function ProcessDoT(statusName, hexColor, mult)
			if attacker.Statuses and (attacker.Statuses[statusName] or 0) > 0 then
				local rawDmg = attacker.MaxHP * statusDmgMod * mult
				local cappedRawDmg = math.min(rawDmg, statCap)
				local dmg = math.max(1, cappedRawDmg * defMult) * unstableMult * statusBlockMult

				local survived = CombatCore.TakeDamageWithWillpower(attacker, dmg)
				attacker.Statuses[statusName] -= 1
				local svMsg = survived and (CombatCore.CountTrait(attacker, "Perseverance") > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
				local blockMsg = isBlocking and " <font color='#AAAAAA'>(Blocked)</font>" or ""
				table.insert(logMessages, "<font color='"..hexColor.."'>"..attacker.Name.." took "..math.floor(dmg).." "..statusName.." damage!"..svMsg..blockMsg.."</font>")
			end
		end

		local dotsToProcess = {
			{Name="Calamity", Color="#CC00FF", Mult=3.0},
			{Name="Blight", Color="#4B0082", Mult=2.25},
			{Name="Miasma", Color="#2E8B57", Mult=2.25},
			{Name="Necrosis", Color="#8B4513", Mult=2.25},
			{Name="Plague", Color="#556B2F", Mult=2.25},
			{Name="Acid", Color="#80FF00", Mult=1.5},
			{Name="Infection", Color="#800000", Mult=1.5},
			{Name="Rupture", Color="#FF4400", Mult=1.5},
			{Name="Frostburn", Color="#55AAFF", Mult=1.5},
			{Name="Frostbite", Color="#0055FF", Mult=1.5},
			{Name="Decay", Color="#00AA55", Mult=1.5},
			{Name="Bleed", Color="#FF0000", Mult=1.0},
			{Name="Poison", Color="#AA00AA", Mult=1.0},
			{Name="Burn", Color="#FF5500", Mult=1.0}
		}

		for _, dot in ipairs(dotsToProcess) do
			ProcessDoT(dot.Name, dot.Color, dot.Mult)
		end

		if attacker.HP < 1 then continue end

		if attacker.HP > 0 and attacker.Statuses and (attacker.Statuses.Chilly or 0) > 0 then
			local rawDmg = attacker.MaxHP * statusDmgMod
			local cappedRawDmg = math.min(rawDmg, statCap)
			local dmg = math.max(1, cappedRawDmg * defMult * blockMult)
			local survived = CombatCore.TakeDamageWithWillpower(attacker, dmg)
			attacker.Statuses.Chilly -= 1
			local svMsg = survived and (CombatCore.CountTrait(attacker, "Perseverance") > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
			local blockMsg = isBlocking and " <font color='#AAAAAA'>(Blocked)</font>" or ""
			table.insert(logMessages, "<font color='#66CCFF'>"..attacker.Name.." shivers, taking "..math.floor(dmg).." Chilly damage!"..svMsg..blockMsg.."</font>")
		end

		if attacker.HP < 1 then continue end

		if attacker.Statuses and (attacker.Statuses.Freeze or 0) > 0 then
			local rawDmg = attacker.MaxHP * statusDmgMod
			local cappedRawDmg = math.min(rawDmg, statCap)
			local dmg = math.max(1, cappedRawDmg * defMult * blockMult)
			local survived = CombatCore.TakeDamageWithWillpower(attacker, dmg)
			attacker.Statuses.Freeze -= 1
			local svMsg = survived and (CombatCore.CountTrait(attacker, "Perseverance") > 0 and " <font color='#FF55FF'>...PERSEVERANCE ACTIVATED!</font>" or " <font color='#FF55FF'>...SURVIVED ON WILLPOWER!</font>") or ""
			local blockMsg = isBlocking and " <font color='#AAAAAA'>(Blocked)</font>" or ""
			table.insert(logMessages, "<font color='#00FFFF'>"..attacker.Name.." took "..math.floor(dmg).." Freeze damage and is frozen solid!"..svMsg..blockMsg.."</font>")
			if attacker.HP < 1 then continue end
			attacker.Stamina = math.min(attacker.MaxStamina, attacker.Stamina + 5)
			attacker.StandEnergy = math.min(attacker.MaxStandEnergy, attacker.StandEnergy + 5)
			attacker.SelectedSkill = nil 
			continue
		end

		if attacker.Statuses and (attacker.Statuses.Stun or 0) > 0 then
			attacker.Statuses.Stun -= 1
			table.insert(logMessages, "<font color='#AAAAAA'>"..attacker.Name.." is Stunned and skips their turn!</font>")
			attacker.Stamina = math.min(attacker.MaxStamina, attacker.Stamina + 5)
			attacker.StandEnergy = math.min(attacker.MaxStandEnergy, attacker.StandEnergy + 5)
			attacker.SelectedSkill = nil 
			continue
		end

		local skillName = attacker.SelectedSkill
		local skill = SkillData.Skills[skillName]
		if skill then
			if skillName == "Flee" or skill.Effect == "Flee" then 
				attacker.HP = 0; table.insert(logMessages, "<font color='#FF5555'>"..attacker.Name.." fled!</font>"); continue 
			end
		end

		local defender = nil
		for _, p in ipairs(enemyTeam) do if p.UserId == attacker.SelectedTargetId and p.HP > 0 then defender = p break end end
		if not defender then defender = GetAliveEnemy(enemyTeam) end

		if skill and defender then
			local s, msg, hit, shake = pcall(function()
				return CombatCore.ExecuteStrike(attacker, defender, skillName, uniModStr, attacker.Name, defender.Name, "#55FF55", "#FF5555")
			end)
			if s then
				table.insert(logMessages, msg)
				if hit then didHit = true end
				if shake == "Heavy" then shakeType = "Heavy" elseif shake == "Light" and shakeType == "None" then shakeType = "Light" end
			else
				warn("CombatCore Arena Error:", msg)
				table.insert(logMessages, "<font color='#FF5555'>[Combat Error] " .. attacker.Name .. "'s attack failed.</font>")
			end
		end

		if attacker.Statuses and (attacker.Statuses.Confusion or 0) > 0 then attacker.Statuses.Confusion -= 1 end
	end

	for _, combatant in ipairs(allCombatants) do
		if combatant.HP < 1 then continue end
		if combatant.Cooldowns then for sName, cd in pairs(combatant.Cooldowns) do if cd > 0 then combatant.Cooldowns[sName] = cd - 1 end end end

		if combatant.Statuses then 
			for sName, sVal in pairs(combatant.Statuses) do 
				if (string.sub(sName, 1, 5) == "Buff_" or string.sub(sName, 1, 7) == "Debuff_" or string.find(sName, "Exhausted") or sName == "Dizzy" or sName == "Warded") and sVal > 0 then combatant.Statuses[sName] = sVal - 1 end 
			end 
		end

		if combatant.BlockTurns > 0 then combatant.BlockTurns -= 1 end
		if combatant.CounterTurns then combatant.CounterTurns = math.max(0, combatant.CounterTurns - 1) end

		local sk = SkillData.Skills[combatant.SelectedSkill]
		if sk then
			if sk.StaminaCost == 0 then combatant.Stamina = math.min(combatant.MaxStamina, combatant.Stamina + 5) end
			if sk.EnergyCost == 0 then combatant.StandEnergy = math.min(combatant.MaxStandEnergy, combatant.StandEnergy + 5) end
		end

		local vigCount = CombatCore.CountTrait(combatant, "Vigorous")
		if vigCount > 0 then
			combatant.Stamina = math.min(combatant.MaxStamina, combatant.Stamina + (10 * vigCount))
			combatant.StandEnergy = math.min(combatant.MaxStandEnergy, combatant.StandEnergy + (10 * vigCount))
		end

		combatant.SelectedSkill = nil
		combatant.SelectedTargetId = nil
	end

	if #logMessages == 0 then table.insert(logMessages, "<font color='#AAAAAA'>Nothing happened this turn.</font>") end
	local logStr = table.concat(logMessages, "\n")

	if IsTeamDead(match.Team1) or IsTeamDead(match.Team2) then
		local winningTeam = IsTeamDead(match.Team2) and match.Team1 or match.Team2
		local losingTeam = winningTeam == match.Team1 and match.Team2 or match.Team1
		local winningTeamNum = (winningTeam == match.Team1) and 1 or 2

		local wGain, lLoss = 0, 0
		if not match.IsCasual then wGain, lLoss = UpdateTeamElo(winningTeam, losingTeam) end

		local wMsg = match.IsCasual and "YOUR TEAM WON! (Casual)" or "YOUR TEAM WON! (+"..wGain.." Elo)"
		local lMsg = match.IsCasual and "YOUR TEAM LOST! (Casual)" or "YOUR TEAM LOST! (-"..lLoss.." Elo)"

		for _, pData in ipairs(winningTeam) do
			local gangEvent = Network:FindFirstChild("AddGangOrderProgress")
			if gangEvent then gangEvent:Fire(pData.Player:GetAttribute("Gang"), "Arena", 1) end

			pData.Player:SetAttribute("ArenaWins", (pData.Player:GetAttribute("ArenaWins") or 0) + 1)

			ArenaUpdate:FireClient(pData.Player, "MatchOver", {Result = "Win", EloChange = wGain, LogMsg = logStr .. "\n\n<font color='#55FF55'>"..wMsg.."</font>"})
			ActiveMatches[pData.Player] = nil
			pData.Player:SetAttribute("InCombat", false)
			local repEvent = ReplicatedStorage:FindFirstChild("AwardGangReputation")
			if repEvent then repEvent:Fire(pData.Player.UserId, 10) end
		end

		for _, pData in ipairs(losingTeam) do
			ArenaUpdate:FireClient(pData.Player, "MatchOver", {Result = "Loss", EloChange = -lLoss, LogMsg = logStr .. "\n\n<font color='#FF5555'>"..lMsg.."</font>"})
			ActiveMatches[pData.Player] = nil
			pData.Player:SetAttribute("InCombat", false)
		end

		local winPool = (winningTeamNum == 1) and match.Pool1 or match.Pool2
		local losePool = (winningTeamNum == 1) and match.Pool2 or match.Pool1

		for _, specPlayer in ipairs(match.Spectators) do
			if specPlayer and specPlayer.Parent then
				local betData = match.Bets[specPlayer]
				if betData then
					if betData.Team == winningTeamNum then
						local share = betData.Amount / winPool
						local payout = math.floor(betData.Amount + (share * losePool))
						specPlayer.leaderstats.Yen.Value += payout
						ArenaUpdate:FireClient(specPlayer, "MatchOver", {Result = "Spectate", LogMsg = logStr .. "\n\n<font color='#55FF55'>Bet Won! Payout: ¥" .. payout .. "</font>"})
					else
						ArenaUpdate:FireClient(specPlayer, "MatchOver", {Result = "Spectate", LogMsg = logStr .. "\n\n<font color='#FF5555'>Bet Lost! (-¥" .. betData.Amount .. ")</font>"})
					end
				else
					ArenaUpdate:FireClient(specPlayer, "MatchOver", {Result = "Spectate", LogMsg = logStr .. "\n\n<font color='#AAAAAA'>Match Finished.</font>"})
				end
				SpectatingMatches[specPlayer] = nil
			end
		end

		MatchRegistry[match.Id] = nil
		ArenaUpdate:FireAllClients("ActiveMatchesUpdate", GetActiveMatchesData())
	else
		match.IsProcessing = false
		match.TurnDeadline = math.floor(workspace:GetServerTimeNow()) + match.TurnTime

		for _, pData in ipairs(allCombatants) do
			ArenaUpdate:FireClient(pData.Player, "TurnResult", {LogMsg = logStr, State = GetClientState(match, pData.Player, false), DidHit = didHit, ShakeType = shakeType, Deadline = match.TurnDeadline})
			if pData.HP > 0 and (pData.Statuses.Stun or 0) > 0 then pData.SelectedSkill = "Stunned" end
		end

		for _, specPlayer in ipairs(match.Spectators) do
			ArenaUpdate:FireClient(specPlayer, "TurnResult", {LogMsg = logStr, State = GetClientState(match, specPlayer, true), DidHit = didHit, ShakeType = shakeType, Deadline = match.TurnDeadline})
		end

		local allReady = true
		for _, p in ipairs(allCombatants) do if p.HP > 0 and not p.SelectedSkill then allReady = false; break end end
		if allReady then task.defer(function() ProcessTurn(match) end) end
	end
end

task.spawn(function()
	while task.wait(1) do
		local checked = {}
		for _, match in pairs(MatchRegistry) do
			if not checked[match] then
				checked[match] = true
				if not match.IsProcessing and match.TurnDeadline and math.floor(workspace:GetServerTimeNow()) >= match.TurnDeadline then
					local allCombatants = {}
					for _, p in ipairs(match.Team1) do table.insert(allCombatants, p) end
					for _, p in ipairs(match.Team2) do table.insert(allCombatants, p) end
					for _, p in ipairs(allCombatants) do if p.HP > 0 and not p.SelectedSkill then p.SelectedSkill = "Basic Attack" end end
					task.defer(function() ProcessTurn(match) end)
				end
			end
		end
	end
end)

ArenaAction.OnServerEvent:Connect(function(player, action, data)
	if action == "RequestLobbies" then
		ArenaUpdate:FireClient(player, "LobbiesUpdate", GetLobbyData())
		ArenaUpdate:FireClient(player, "ActiveMatchesUpdate", GetActiveMatchesData())
	elseif action == "CreateLobby" then
		if ActiveMatches[player] or SpectatingMatches[player] or OpenLobbies[player.UserId] then return end
		local pElo = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Elo") and player.leaderstats.Elo.Value or 1000
		local cap = data.Capacity or 2 

		OpenLobbies[player.UserId] = { Host = player, Capacity = cap, Team1Queue = {player}, Team2Queue = {}, Elo = pElo, FriendsOnly = data.FriendsOnly, Casual = data.Casual, NoHoldsBarred = data.NoHoldsBarred }
		ArenaUpdate:FireClient(player, "LobbyStatus", {IsHosting = true, IsLobbyOwner = true, T1Count = 1, T2Count = 0, Capacity = cap})
		ArenaUpdate:FireAllClients("LobbiesUpdate", GetLobbyData())
	elseif action == "CancelLobby" then
		if OpenLobbies[player.UserId] then
			for _, queuedPlayer in ipairs(OpenLobbies[player.UserId].Team1Queue) do ArenaUpdate:FireClient(queuedPlayer, "LobbyStatus", {IsHosting = false}) end
			for _, queuedPlayer in ipairs(OpenLobbies[player.UserId].Team2Queue) do ArenaUpdate:FireClient(queuedPlayer, "LobbyStatus", {IsHosting = false}) end
			OpenLobbies[player.UserId] = nil
			ArenaUpdate:FireAllClients("LobbiesUpdate", GetLobbyData())
		else
			for hostId, lobby in pairs(OpenLobbies) do
				local found = false
				for i, qp in ipairs(lobby.Team1Queue) do if qp == player then table.remove(lobby.Team1Queue, i); found = true; break end end
				if not found then
					for i, qp in ipairs(lobby.Team2Queue) do if qp == player then table.remove(lobby.Team2Queue, i); found = true; break end end
				end
				if found then
					ArenaUpdate:FireClient(player, "LobbyStatus", {IsHosting = false})
					for _, remainingPlayer in ipairs(lobby.Team1Queue) do ArenaUpdate:FireClient(remainingPlayer, "LobbyStatus", {IsHosting = true, IsLobbyOwner = (remainingPlayer.UserId == hostId), T1Count = #lobby.Team1Queue, T2Count = #lobby.Team2Queue, Capacity = lobby.Capacity}) end
					for _, remainingPlayer in ipairs(lobby.Team2Queue) do ArenaUpdate:FireClient(remainingPlayer, "LobbyStatus", {IsHosting = true, IsLobbyOwner = (remainingPlayer.UserId == hostId), T1Count = #lobby.Team1Queue, T2Count = #lobby.Team2Queue, Capacity = lobby.Capacity}) end
					ArenaUpdate:FireAllClients("LobbiesUpdate", GetLobbyData()); break
				end
			end
		end
	elseif action == "JoinLobby" then
		if ActiveMatches[player] or SpectatingMatches[player] then return end
		for _, lobby in pairs(OpenLobbies) do
			for _, qp in ipairs(lobby.Team1Queue) do if qp == player then return end end
			for _, qp in ipairs(lobby.Team2Queue) do if qp == player then return end end
		end

		local lobby = OpenLobbies[data.HostId]
		if not lobby then return end
		local targetQueue = data.TeamIndex == 2 and lobby.Team2Queue or lobby.Team1Queue
		local maxPerTeam = lobby.Capacity / 2
		if #targetQueue >= maxPerTeam then return end
		if lobby.FriendsOnly then
			local success, isFriend = pcall(function() return player:IsFriendsWith(data.HostId) end)
			if not success or not isFriend then return end
		end

		table.insert(targetQueue, player)

		if #lobby.Team1Queue == maxPerTeam and #lobby.Team2Queue == maxPerTeam then
			local t1, t2 = {}, {}
			for _, qp in ipairs(lobby.Team1Queue) do table.insert(t1, CombatCore.BuildPlayerStruct(qp, lobby.NoHoldsBarred)) end
			for _, qp in ipairs(lobby.Team2Queue) do table.insert(t2, CombatCore.BuildPlayerStruct(qp, lobby.NoHoldsBarred)) end

			local turnTime = 15
			if lobby.Capacity == 4 then turnTime = 30 elseif lobby.Capacity == 8 then turnTime = 45 end

			local matchId = HttpService:GenerateGUID(false)
			local match = { 
				Id = matchId, HostName = lobby.Host.Name, Capacity = lobby.Capacity, Team1 = t1, Team2 = t2, Spectators = {}, Bets = {}, Pool1 = 0, Pool2 = 0,
				IsProcessing = false, TurnDeadline = math.floor(workspace:GetServerTimeNow()) + turnTime, IsCasual = lobby.Casual, TurnTime = turnTime 
			}
			MatchRegistry[matchId] = match

			for _, pData in ipairs(t1) do ActiveMatches[pData.Player] = match; pData.Player:SetAttribute("InCombat", true) end
			for _, pData in ipairs(t2) do ActiveMatches[pData.Player] = match; pData.Player:SetAttribute("InCombat", true) end

			for _, pData in ipairs(match.Team1) do ArenaUpdate:FireClient(pData.Player, "MatchStart", { State = GetClientState(match, pData.Player, false), LogMsg = "The team battle begins!", Deadline = match.TurnDeadline }) end
			for _, pData in ipairs(match.Team2) do ArenaUpdate:FireClient(pData.Player, "MatchStart", { State = GetClientState(match, pData.Player, false), LogMsg = "The team battle begins!", Deadline = match.TurnDeadline }) end

			OpenLobbies[data.HostId] = nil
			ArenaUpdate:FireAllClients("LobbiesUpdate", GetLobbyData())
			ArenaUpdate:FireAllClients("ActiveMatchesUpdate", GetActiveMatchesData())
		else
			for _, qp in ipairs(lobby.Team1Queue) do ArenaUpdate:FireClient(qp, "LobbyStatus", {IsHosting = true, IsLobbyOwner = (qp.UserId == data.HostId), T1Count = #lobby.Team1Queue, T2Count = #lobby.Team2Queue, Capacity = lobby.Capacity}) end
			for _, qp in ipairs(lobby.Team2Queue) do ArenaUpdate:FireClient(qp, "LobbyStatus", {IsHosting = true, IsLobbyOwner = (qp.UserId == data.HostId), T1Count = #lobby.Team1Queue, T2Count = #lobby.Team2Queue, Capacity = lobby.Capacity}) end
			ArenaUpdate:FireAllClients("LobbiesUpdate", GetLobbyData())
		end
	elseif action == "SpectateMatch" then
		if ActiveMatches[player] or SpectatingMatches[player] then return end
		local match = MatchRegistry[data.MatchId]
		if not match then return end

		table.insert(match.Spectators, player)
		SpectatingMatches[player] = match
		ArenaUpdate:FireClient(player, "SpectateStart", { MatchId = match.Id, State = GetClientState(match, player, true), Deadline = match.TurnDeadline })
		ArenaUpdate:FireAllClients("ActiveMatchesUpdate", GetActiveMatchesData())
	elseif action == "LeaveSpectate" then
		local match = SpectatingMatches[player]
		if match then
			for i, spec in ipairs(match.Spectators) do if spec == player then table.remove(match.Spectators, i); break end end
			SpectatingMatches[player] = nil
			ArenaUpdate:FireClient(player, "MatchOver", {Result = "Spectate", LogMsg = "Left spectating mode."})
			ArenaUpdate:FireAllClients("ActiveMatchesUpdate", GetActiveMatchesData())
		end
	elseif action == "PlaceBet" then
		local match = SpectatingMatches[player]
		if not match or match.Bets[player] then return end 

		local amount = tonumber(data.Amount) or 0
		if amount <= 0 or player.leaderstats.Yen.Value < amount then return end
		player.leaderstats.Yen.Value -= amount
		match.Bets[player] = { Team = data.Team, Amount = amount }

		if data.Team == 1 then match.Pool1 += amount else match.Pool2 += amount end
		for _, specPlayer in ipairs(match.Spectators) do ArenaUpdate:FireClient(specPlayer, "BetUpdate", { Pool1 = match.Pool1, Pool2 = match.Pool2 }) end
		ArenaUpdate:FireAllClients("ActiveMatchesUpdate", GetActiveMatchesData())
	elseif action == "Attack" then
		local match = ActiveMatches[player]
		if not match or match.IsProcessing then return end

		local combatant = nil
		for _, p in ipairs(match.Team1) do if p.Player == player then combatant = p break end end
		if not combatant then for _, p in ipairs(match.Team2) do if p.Player == player then combatant = p break end end end

		local skillName = data.SkillName
		local targetId = data.TargetUserId
		local skill = SkillData.Skills[skillName]

		if not table.find(combatant.Skills, skillName) then return end

		if not skill or combatant.Stamina < (skill.StaminaCost or 0) or combatant.StandEnergy < (skill.EnergyCost or 0) or (combatant.Cooldowns[skillName] and combatant.Cooldowns[skillName] > 0) then return end

		combatant.SelectedSkill = skillName; combatant.SelectedTargetId = targetId

		ArenaUpdate:FireClient(player, "Waiting")

		local allReady = true
		for _, p in ipairs(match.Team1) do if p.HP > 0 and not p.SelectedSkill then allReady = false break end end
		for _, p in ipairs(match.Team2) do if p.HP > 0 and not p.SelectedSkill then allReady = false break end end
		if allReady then ProcessTurn(match) end
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	if OpenLobbies[player.UserId] then
		OpenLobbies[player.UserId] = nil
		ArenaUpdate:FireAllClients("LobbiesUpdate", GetLobbyData())
	else
		for hostId, lobby in pairs(OpenLobbies) do
			local found = false
			for i, qp in ipairs(lobby.Team1Queue) do if qp == player then table.remove(lobby.Team1Queue, i); found = true; break end end
			if not found then for i, qp in ipairs(lobby.Team2Queue) do if qp == player then table.remove(lobby.Team2Queue, i); found = true; break end end end

			if found then
				for _, remainingPlayer in ipairs(lobby.Team1Queue) do ArenaUpdate:FireClient(remainingPlayer, "LobbyStatus", {IsHosting = true, IsLobbyOwner = (remainingPlayer.UserId == hostId), T1Count = #lobby.Team1Queue, T2Count = #lobby.Team2Queue, Capacity = lobby.Capacity}) end
				for _, remainingPlayer in ipairs(lobby.Team2Queue) do ArenaUpdate:FireClient(remainingPlayer, "LobbyStatus", {IsHosting = true, IsLobbyOwner = (remainingPlayer.UserId == hostId), T1Count = #lobby.Team1Queue, T2Count = #lobby.Team2Queue, Capacity = lobby.Capacity}) end
				ArenaUpdate:FireAllClients("LobbiesUpdate", GetLobbyData())
				break
			end
		end
	end

	local sMatch = SpectatingMatches[player]
	if sMatch then
		for i, spec in ipairs(sMatch.Spectators) do if spec == player then table.remove(sMatch.Spectators, i); break end end
		SpectatingMatches[player] = nil
		ArenaUpdate:FireAllClients("ActiveMatchesUpdate", GetActiveMatchesData())
	end

	local match = ActiveMatches[player]
	if match then
		local combatant
		for _, p in ipairs(match.Team1) do if p.Player == player then combatant = p break end end
		if not combatant then for _, p in ipairs(match.Team2) do if p.Player == player then combatant = p break end end end

		if combatant then
			combatant.HP = 0
			combatant.SelectedSkill = "Flee"
			if not match.IsProcessing then
				local allReady = true
				for _, p in ipairs(match.Team1) do if p.HP > 0 and not p.SelectedSkill then allReady = false break end end
				for _, p in ipairs(match.Team2) do if p.HP > 0 and not p.SelectedSkill then allReady = false break end end
				if allReady then ProcessTurn(match) end
			end
		end
	end
	player:SetAttribute("InCombat", false)
end)