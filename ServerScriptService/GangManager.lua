-- @ScriptType: Script
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local TextService = game:GetService("TextService")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local GangStore = DataStoreService:GetDataStore("Jojo_Gangs_V3") 

local ODS_GangRep = DataStoreService:GetOrderedDataStore("Jojo_GangLB_Rep_V3")
local ODS_GangTreasury = DataStoreService:GetOrderedDataStore("Jojo_GangLB_Yen_V3")
local ODS_GangPrestige = DataStoreService:GetOrderedDataStore("Jojo_GangLB_Prestige_V3")
local ODS_GangElo = DataStoreService:GetOrderedDataStore("Jojo_GangLB_Elo_V3")
local ODS_GangRaids = DataStoreService:GetOrderedDataStore("Jojo_GangLB_Raids_V3")

local GangAction = Network:WaitForChild("GangAction")
local GangUpdate = Network:WaitForChild("GangUpdate")

local NotificationEvent = Network:FindFirstChild("NotificationEvent") or Instance.new("RemoteEvent", Network)
NotificationEvent.Name = "NotificationEvent"

local ActiveGangs = {}
local PendingGangSaves = {}
local PendingGangUpdates = {} 
local CachedBrowserList = {} 
local RolePower = { ["Grunt"] = 1, ["Caporegime"] = 2, ["Consigliere"] = 3, ["Boss"] = 4 }

local GANG_TOPIC = "JJBI_Gang_Sync_V1"

local AdminWipeEvent = ReplicatedStorage:FindFirstChild("AdminForceWipeGang")
if not AdminWipeEvent then
	AdminWipeEvent = Instance.new("BindableEvent")
	AdminWipeEvent.Name = "AdminForceWipeGang"
	AdminWipeEvent.Parent = ReplicatedStorage
end

local ProgressOrderEvent = Network:FindFirstChild("AddGangOrderProgress")
if not ProgressOrderEvent then
	ProgressOrderEvent = Instance.new("BindableEvent")
	ProgressOrderEvent.Name = "AddGangOrderProgress"
	ProgressOrderEvent.Parent = Network 
end

local GangRepEvent = ReplicatedStorage:FindFirstChild("AwardGangReputation")
if not GangRepEvent then
	GangRepEvent = Instance.new("BindableEvent")
	GangRepEvent.Name = "AwardGangReputation"
	GangRepEvent.Parent = ReplicatedStorage
end

local function CheckTextFilter(text, userId)
	local success, filterResult = pcall(function()
		return TextService:FilterStringAsync(text, userId)
	end)

	if success and filterResult then
		local success2, filteredText = pcall(function()
			return filterResult:GetNonChatStringForBroadcastAsync()
		end)
		if success2 and filteredText then
			if filteredText == text then
				return true, nil
			else
				return false, "Input contains inappropriate language!"
			end
		end
	end
	return false, "Text filter service is down. Try again later."
end

local function GetDictSize(d)
	local c = 0
	if d then for _ in pairs(d) do c += 1 end end
	return c
end

local function GetGangLevel(rep)
	if rep >= 100000 then return 5 end
	if rep >= 50000 then return 4 end
	if rep >= 10000 then return 3 end
	if rep >= 5000 then return 2 end
	if rep >= 1000 then return 1 end
	return 0
end

local function ApplyGangBuffs(player, gangData)
	if not gangData then
		player:SetAttribute("GangYenBoost", 1.0)
		player:SetAttribute("GangXPBoost", 1.0)
		player:SetAttribute("GangLuckBoost", 1.0)
		player:SetAttribute("GangInvBoost", 0)
		player:SetAttribute("GangDmgBoost", 1.0)
		return
	end

	local b = gangData.Buildings or {}
	local yB = 1.0 + ((b.Vault or 0) * 0.05)
	local xB = 1.0 + ((b.Dojo or 0) * 0.05)
	local lB = 1.0 + (b.Shrine or 0)
	local iB = (b.Market or 0) * 5
	local dB = 1.0 + ((b.Armory or 0) * 0.05)

	player:SetAttribute("GangYenBoost", yB)
	player:SetAttribute("GangXPBoost", xB)
	player:SetAttribute("GangLuckBoost", lB)
	player:SetAttribute("GangInvBoost", iB)
	player:SetAttribute("GangDmgBoost", dB)
end

local function RollSingleOrder()
	local pools = {
		{Type = "Kills", Desc = "Defeat 500 Enemies", Target = 500, RewardT = 500000, RewardR = 250},
		{Type = "Dungeons", Desc = "Clear 100 Dungeon Floors", Target = 100, RewardT = 1000000, RewardR = 500},
		{Type = "Raids", Desc = "Defeat 15 Raid Bosses", Target = 15, RewardT = 2000000, RewardR = 1000},
		{Type = "Arena", Desc = "Win 20 Arena Matches", Target = 20, RewardT = 1000000, RewardR = 400},
		{Type = "Yen", Desc = "Spend ¥10,000,000 Total", Target = 10000000, RewardT = 4000000, RewardR = 800}
	}
	local t = pools[math.random(1, #pools)]
	return {Type = t.Type, Desc = t.Desc, Target = t.Target, Progress = 0, RewardT = t.RewardT, RewardR = t.RewardR, Completed = false}
end

local function GenerateRandomOrders()
	local chosen = {}
	for i = 1, 5 do table.insert(chosen, RollSingleOrder()) end
	return chosen
end

local function DistributeOrderLoot(gangData, rarity)
	local pool = {}
	for name, data in pairs(ItemData.Equipment) do if data.Rarity == rarity then table.insert(pool, name) end end
	for name, data in pairs(ItemData.Consumables) do if data.Rarity == rarity then table.insert(pool, name) end end

	if #pool == 0 then return end
	local item = pool[math.random(#pool)]

	for uidStr, _ in pairs(gangData.Members) do
		local p = Players:GetPlayerByUserId(tonumber(uidStr))
		if p then
			local attr = item:gsub("[^%w]", "") .. "Count"
			p:SetAttribute(attr, (p:GetAttribute(attr) or 0) + 1)
			NotificationEvent:FireClient(p, "<font color='#FFD700'><b>Gang Order Completed!</b> You received 1x " .. item .. "!</font>")
		end
	end
end

local function GetClientGangData(player)
	local gangName = player:GetAttribute("Gang")
	if not gangName or gangName == "None" then
		return { HasGang = false }
	end

	local gKey = string.lower(gangName)
	if not ActiveGangs[gKey] then
		return { HasGang = false }
	end

	local gData = ActiveGangs[gKey]
	local myRole = player:GetAttribute("GangRole") or "Grunt"

	local pending = PendingGangUpdates[gKey]

	local visualOrders = {}
	for i, ord in ipairs(gData.Orders or {}) do
		local vOrd = {
			Type = ord.Type, Desc = ord.Desc, Target = ord.Target,
			Progress = ord.Progress, RewardT = ord.RewardT, RewardR = ord.RewardR,
			Completed = ord.Completed
		}
		if pending and pending.Orders and pending.Orders[ord.Type] and not vOrd.Completed then
			vOrd.Progress = math.min(vOrd.Target, vOrd.Progress + pending.Orders[ord.Type])
			if vOrd.Progress >= vOrd.Target then
				vOrd.Completed = true 
			end
		end
		table.insert(visualOrders, vOrd)
	end

	local visualTreasury = gData.Treasury or 0
	local visualRep = gData.Rep or 0
	if pending then
		visualTreasury += (pending.Treasury or 0)
		visualRep += (pending.Rep or 0)
	end

	local membersList = {}
	for uIdStr, m in pairs(gData.Members) do
		local uid = tonumber(uIdStr) or m.UserId
		local p = uid and Players:GetPlayerByUserId(uid) or nil

		table.insert(membersList, {
			Name = m.Name,
			UserId = uid,
			Role = m.Role,
			IsOnline = p ~= nil,
			LastOnline = m.LastOnline,
			Prestige = m.Prestige,
			PlayTime = m.PlayTime,
			Contribution = m.Contribution
		})
	end

	return {
		HasGang = true,
		MyRole = myRole,
		GangData = {
			Name = gData.Name,
			Level = GetGangLevel(visualRep),
			Rep = visualRep,
			MaxRep = GetGangLevel(visualRep) * 1000, 
			Treasury = visualTreasury,
			Motto = gData.Motto,
			Emblem = gData.Emblem,
			PrestigeReq = gData.PrestigeReq,
			JoinMode = gData.JoinMode,
			Buildings = gData.Buildings,
			Orders = visualOrders,
			LastOrderReset = gData.LastOrderReset,
			ActiveUpgrade = gData.ActiveUpgrade,
			RoleNames = gData.CustomRoles,
			Requests = gData.Requests,
			MemberCount = GetDictSize(gData.Members),
			Members = membersList
		}
	}
end

local function SyncPlayer(player)
	if player and player.Parent then
		GangUpdate:FireClient(player, "Sync", GetClientGangData(player))
	end
end

local function SyncGangToMembers(gangName)
	local key = string.lower(gangName)
	local gang = ActiveGangs[key]
	if not gang then return end
	for userIdStr, _ in pairs(gang.Members) do
		local p = Players:GetPlayerByUserId(tonumber(userIdStr))
		if p then SyncPlayer(p) end
	end
end

local function LoadGangData(gangName, forceRefresh)
	if not gangName or gangName == "None" then return nil end
	local key = string.lower(gangName)
	if not forceRefresh and ActiveGangs[key] then return ActiveGangs[key] end

	local success, data = pcall(function() return GangStore:GetAsync(key) end)
	if success and data then
		if data.RenamedTo then return LoadGangData(data.RenamedTo, forceRefresh) end

		if not data.Buildings then data.Buildings = { Vault = 0, Dojo = 0, Armory = 0, Shrine = 0, Market = 0 } end
		if not data.Orders then data.Orders = GenerateRandomOrders() end
		if not data.LastOrderReset then data.LastOrderReset = math.floor(workspace:GetServerTimeNow()) end
		if not data.PrestigeReq then data.PrestigeReq = 0 end
		if not data.ActiveUpgrade then data.ActiveUpgrade = nil end
		if not data.Requests then data.Requests = {} end
		if not data.CustomRoles then data.CustomRoles = { Boss = "Boss", Consigliere = "Consigliere", Caporegime = "Caporegime", Grunt = "Grunt" } end

		for uIdStr, memData in pairs(data.Members) do
			if not memData.UserId then memData.UserId = tonumber(uIdStr) end
		end

		ActiveGangs[key] = data
		return data
	end
	return nil
end

local function MutateGangData(gangName, mutatorFunc, skipBroadcast)
	if not gangName or gangName == "None" then return false end
	local key = string.lower(gangName)
	local finalData = nil

	local success, err = pcall(function()
		GangStore:UpdateAsync(key, function(oldData)
			if oldData and oldData.RenamedTo then return oldData end
			local dataToSave = oldData or ActiveGangs[key]
			if not dataToSave then return nil end

			dataToSave = mutatorFunc(dataToSave)
			if not dataToSave then return nil end 

			dataToSave.MemberCount = GetDictSize(dataToSave.Members)
			finalData = dataToSave
			return dataToSave
		end)
	end)

	if success and finalData and not finalData.RenamedTo then
		ActiveGangs[key] = finalData
		if not skipBroadcast then
			pcall(function()
				MessagingService:PublishAsync(GANG_TOPIC, { Action = "Refresh", GangKey = key })
			end)
		end
		return true, finalData
	end

	if err then warn("[GangManager] Mutate Error for", key, ":", err) end
	return false, err
end

local function UpdateODS(gangData)
	pcall(function()
		ODS_GangRep:SetAsync(gangData.Name, gangData.Rep or 0)
		ODS_GangTreasury:SetAsync(gangData.Name, gangData.Treasury or 0)
		ODS_GangPrestige:SetAsync(gangData.Name, gangData.TotalPrestige or 0)
		ODS_GangElo:SetAsync(gangData.Name, gangData.TotalElo or 0)
		ODS_GangRaids:SetAsync(gangData.Name, gangData.RaidWins or 0)
	end)
end

local function AddPendingUpdate(gangKey, updateType, amount, extraStr)
	if not gangKey or gangKey == "None" then return end
	local key = string.lower(gangKey)
	if not PendingGangUpdates[key] then
		PendingGangUpdates[key] = { Rep = 0, Treasury = 0, Orders = {}, Contributions = {} }
	end

	if updateType == "Rep" then
		PendingGangUpdates[key].Rep += amount
	elseif updateType == "Treasury" then
		PendingGangUpdates[key].Treasury += amount
	elseif updateType == "Order" then
		PendingGangUpdates[key].Orders[extraStr] = (PendingGangUpdates[key].Orders[extraStr] or 0) + amount
	elseif updateType == "Contribution" then
		PendingGangUpdates[key].Contributions[extraStr] = (PendingGangUpdates[key].Contributions[extraStr] or 0) + amount
	end
end

pcall(function()
	MessagingService:SubscribeAsync(GANG_TOPIC, function(message)
		local data = message.Data
		if data.Action == "Refresh" then
			if ActiveGangs[data.GangKey] then
				task.delay(math.random() * 2, function()
					LoadGangData(data.GangKey, true)
					SyncGangToMembers(data.GangKey)
				end)
			end
		elseif data.Action == "Wipe" then
			ActiveGangs[data.GangKey] = nil
			PendingGangSaves[data.GangKey] = nil
			PendingGangUpdates[data.GangKey] = nil
			for _, p in ipairs(Players:GetPlayers()) do
				if p:GetAttribute("Gang") == data.GangKey then
					p:SetAttribute("Gang", "None")
					p:SetAttribute("GangRole", "None")
					ApplyGangBuffs(p, nil)
					NotificationEvent:FireClient(p, "<font color='#FF5555'>Your gang was completely erased.</font>")
					SyncPlayer(p)
				end
			end
		elseif data.Action == "Rename" then
			if ActiveGangs[data.OldKey] then
				local g = ActiveGangs[data.OldKey]
				g.Name = data.NewName
				ActiveGangs[data.NewKey] = g
				ActiveGangs[data.OldKey] = nil
			end
			for _, p in ipairs(Players:GetPlayers()) do
				if p:GetAttribute("Gang") == data.OldKey then
					p:SetAttribute("Gang", data.NewKey)
					SyncPlayer(p)
				end
			end
		end
	end)
end)

AdminWipeEvent.Event:Connect(function(gangKey, rawGangName)
	local displayToWipe = rawGangName or gangKey
	local gangData = ActiveGangs[gangKey]

	if not gangData then
		local s, d = pcall(function() return GangStore:GetAsync(gangKey) end)
		if s and d and d.Name then displayToWipe = d.Name end
	else
		displayToWipe = gangData.Name
	end

	pcall(function()
		GangStore:RemoveAsync(gangKey)
		ODS_GangRep:RemoveAsync(displayToWipe)
		ODS_GangTreasury:RemoveAsync(displayToWipe)
		ODS_GangPrestige:RemoveAsync(displayToWipe)
		ODS_GangElo:RemoveAsync(displayToWipe)
		ODS_GangRaids:RemoveAsync(displayToWipe)
		MessagingService:PublishAsync(GANG_TOPIC, { Action = "Wipe", GangKey = gangKey })
	end)
end)

local function ElectNewBoss(gangData)
	local bestId = nil; local bestPwr = -1; local bestPrest = -1
	for uId, mem in pairs(gangData.Members) do
		local pwr = RolePower[mem.Role] or 1
		local prest = mem.Prestige or 0
		if pwr > bestPwr then bestPwr = pwr; bestPrest = prest; bestId = uId
		elseif pwr == bestPwr and prest > bestPrest then bestPrest = prest; bestId = uId end
	end
	if bestId then
		gangData.Members[bestId].Role = "Boss"
		local newBoss = Players:GetPlayerByUserId(tonumber(bestId))
		if newBoss then
			newBoss:SetAttribute("GangRole", "Boss")
			NotificationEvent:FireClient(newBoss, "<font color='#FFD700'>You have been promoted to Gang Boss!</font>")
		end
		return true
	end
	return false
end

local function RefreshBrowserCache()
	pcall(function()
		local pages = ODS_GangRep:GetSortedAsync(false, 100)
		local data = pages:GetCurrentPage()
		local newList = {}
		for _, entry in ipairs(data) do table.insert(newList, entry.key) end
		CachedBrowserList = newList
	end)
end

task.spawn(function()
	while true do RefreshBrowserCache(); task.wait(60) end
end)

task.spawn(function()
	while task.wait(30) do 
		for gangKey, updates in pairs(PendingGangUpdates) do
			local hasChanges = (updates.Rep > 0 or updates.Treasury > 0 or GetDictSize(updates.Orders) > 0 or (updates.Contributions and GetDictSize(updates.Contributions) > 0))
			if hasChanges then
				local completedAny = false
				local repToAdd = updates.Rep
				local treasToAdd = updates.Treasury
				local ordToProcess = table.clone(updates.Orders)
				local contToProcess = updates.Contributions and table.clone(updates.Contributions) or {}

				PendingGangUpdates[gangKey] = { Rep = 0, Treasury = 0, Orders = {}, Contributions = {} }

				MutateGangData(gangKey, function(gangData)
					gangData.Rep = (gangData.Rep or 0) + repToAdd
					gangData.Treasury = (gangData.Treasury or 0) + treasToAdd

					for uIdStr, cAmt in pairs(contToProcess) do
						if gangData.Members[uIdStr] then
							gangData.Members[uIdStr].Contribution = (gangData.Members[uIdStr].Contribution or 0) + cAmt
						end
					end

					for oType, oAmt in pairs(ordToProcess) do
						for _, ord in ipairs(gangData.Orders) do
							if ord.Type == oType and not ord.Completed then
								ord.Progress = math.min(ord.Target, ord.Progress + oAmt)
								if ord.Progress >= ord.Target then
									ord.Completed = true
									gangData.Treasury = (gangData.Treasury or 0) + ord.RewardT
									gangData.Rep = (gangData.Rep or 0) + ord.RewardR
									completedAny = true
									task.defer(function() DistributeOrderLoot(gangData, "Legendary") end)
								end
							end
						end
					end
					return gangData
				end, true)

				if completedAny then SyncGangToMembers(gangKey) end
			end
			task.wait(1) 
		end
	end
end)

task.spawn(function()
	while task.wait(300) do 
		for gangKey, _ in pairs(ActiveGangs) do
			MutateGangData(gangKey, function(gData)
				local totalPrestige, totalElo, totalRaids = 0, 0, 0

				if not gData.LastOrderReset or math.floor(workspace:GetServerTimeNow()) - gData.LastOrderReset >= 86400 then
					gData.Orders = GenerateRandomOrders()
					gData.LastOrderReset = math.floor(workspace:GetServerTimeNow())
				end

				for uIdStr, memData in pairs(gData.Members) do
					local livePlayer = Players:GetPlayerByUserId(tonumber(uIdStr))
					if livePlayer then
						local pObj = livePlayer:FindFirstChild("leaderstats")
						if pObj then
							memData.Prestige = pObj:FindFirstChild("Prestige") and pObj.Prestige.Value or memData.Prestige or 0
							memData.Elo = pObj:FindFirstChild("Elo") and pObj.Elo.Value or memData.Elo or 1000
						end
						memData.RaidWins = livePlayer:GetAttribute("RaidWins") or memData.RaidWins or 0
						memData.PlayTime = livePlayer:GetAttribute("PlayTime") or memData.PlayTime or 0
						memData.LastOnline = math.floor(workspace:GetServerTimeNow()) 
					end

					memData.Contribution = memData.Contribution or 0
					memData.PlayTime = memData.PlayTime or 0

					totalPrestige += (memData.Prestige or 0)
					totalElo += (memData.Elo or 1000)
					totalRaids += (memData.RaidWins or 0)
				end

				gData.TotalPrestige = totalPrestige
				gData.TotalElo = totalElo
				gData.RaidWins = totalRaids

				return gData
			end, true)

			if ActiveGangs[gangKey] then UpdateODS(ActiveGangs[gangKey]) end
			PendingGangSaves[gangKey] = nil
			task.wait(1) 
		end
	end
end)

game:BindToClose(function()
	for gangKey, updates in pairs(PendingGangUpdates) do
		local hasChanges = (updates.Rep > 0 or updates.Treasury > 0 or GetDictSize(updates.Orders) > 0 or (updates.Contributions and GetDictSize(updates.Contributions) > 0))
		if hasChanges then
			MutateGangData(gangKey, function(gangData)
				gangData.Rep = (gangData.Rep or 0) + updates.Rep
				gangData.Treasury = (gangData.Treasury or 0) + updates.Treasury

				if updates.Contributions then
					for uIdStr, cAmt in pairs(updates.Contributions) do
						if gangData.Members[uIdStr] then
							gangData.Members[uIdStr].Contribution = (gangData.Members[uIdStr].Contribution or 0) + cAmt
						end
					end
				end

				for oType, oAmt in pairs(updates.Orders) do
					for _, ord in ipairs(gangData.Orders) do
						if ord.Type == oType and not ord.Completed then
							ord.Progress = math.min(ord.Target, ord.Progress + oAmt)
							if ord.Progress >= ord.Target then
								ord.Completed = true
								gangData.Treasury = (gangData.Treasury or 0) + ord.RewardT
								gangData.Rep = (gangData.Rep or 0) + ord.RewardR
							end
						end
					end
				end
				return gangData
			end, true)
		end
	end

	for key, _ in pairs(PendingGangSaves) do
		MutateGangData(key, function(gData)
			for uIdStr, memData in pairs(gData.Members) do
				local liveP = Players:GetPlayerByUserId(tonumber(uIdStr))
				if liveP then
					memData.LastOnline = math.floor(workspace:GetServerTimeNow())
					memData.PlayTime = liveP:GetAttribute("PlayTime") or memData.PlayTime or 0
				end
			end
			return gData
		end, true)
	end
end)

ProgressOrderEvent.Event:Connect(function(gangKey, orderType, amount)
	AddPendingUpdate(gangKey, "Order", amount, orderType)
	SyncGangToMembers(gangKey)
end)

GangRepEvent.Event:Connect(function(userId, amount)
	local player = Players:GetPlayerByUserId(userId)
	if not player then return end

	local pGangName = player:GetAttribute("Gang")
	if not pGangName or pGangName == "None" then return end

	AddPendingUpdate(pGangName, "Rep", amount)
	SyncGangToMembers(pGangName)
end)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("GangDmgBoost", 1.0)
	task.delay(3, function()
		local gName = player:GetAttribute("Gang")
		if gName and gName ~= "None" then
			local data = LoadGangData(gName)
			if data then
				local actualKey = string.lower(data.Name)
				if actualKey ~= string.lower(gName) then
					player:SetAttribute("Gang", actualKey)
					return
				end

				if data.Members[tostring(player.UserId)] then
					local serverRole = data.Members[tostring(player.UserId)].Role
					player:SetAttribute("GangRole", serverRole)
					ApplyGangBuffs(player, data)
					SyncPlayer(player)
				else
					player:SetAttribute("Gang", "None")
					player:SetAttribute("GangRole", "None")
					ApplyGangBuffs(player, nil)
					SyncPlayer(player)
				end
			else
				player:SetAttribute("Gang", "None")
				player:SetAttribute("GangRole", "None")
				ApplyGangBuffs(player, nil)
				SyncPlayer(player)
			end
		else
			ApplyGangBuffs(player, nil)
			SyncPlayer(player)
		end
	end)

	player:GetAttributeChangedSignal("Gang"):Connect(function()
		local gName = player:GetAttribute("Gang")
		if gName and gName ~= "None" then
			local data = LoadGangData(gName)
			if data then
				local actualKey = string.lower(data.Name)
				if actualKey ~= string.lower(gName) then
					player:SetAttribute("Gang", actualKey)
					return
				end

				if data.Members[tostring(player.UserId)] then
					local serverRole = data.Members[tostring(player.UserId)].Role
					player:SetAttribute("GangRole", serverRole)
					ApplyGangBuffs(player, data)
					SyncPlayer(player)
				else
					player:SetAttribute("Gang", "None")
					player:SetAttribute("GangRole", "None")
					ApplyGangBuffs(player, nil)
					SyncPlayer(player)
					NotificationEvent:FireClient(player, "<font color='#FF5555'>You are no longer in a gang.</font>")
				end
			end
		else
			ApplyGangBuffs(player, nil)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	local pGangName = player:GetAttribute("Gang")
	if pGangName and pGangName ~= "None" then
		local key = string.lower(pGangName)
		local gang = ActiveGangs[key]
		if gang and gang.Members[tostring(player.UserId)] then
			gang.Members[tostring(player.UserId)].LastOnline = math.floor(workspace:GetServerTimeNow())
			gang.Members[tostring(player.UserId)].PlayTime = player:GetAttribute("PlayTime") or gang.Members[tostring(player.UserId)].PlayTime or 0
			PendingGangSaves[key] = true
		end
	end
end)

GangAction.OnServerEvent:Connect(function(player, action, value, extraValue)
	local pIdStr = tostring(player.UserId)
	local pGangName = player:GetAttribute("Gang")
	local pRole = player:GetAttribute("GangRole")

	if action == "Create" then
		if pGangName ~= "None" then return end
		local yen = player.leaderstats.Yen
		if yen.Value < 500000 then 
			NotificationEvent:FireClient(player, "<font color='#FF5555'>You need ¥500,000 to create a gang!</font>")
			return 
		end

		local displayGangName = tostring(value)
		local gangKey = string.lower(displayGangName)

		if string.len(displayGangName) < 3 or string.len(displayGangName) > 15 then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Name must be 3 to 15 characters long!</font>")
			return
		end

		if not string.match(displayGangName, "^[a-zA-Z ]+$") then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Alphabetic characters and spaces only!</font>")
			return
		end

		local isClean, errMsg = CheckTextFilter(displayGangName, player.UserId)
		if not isClean then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>" .. errMsg .. "</font>")
			return
		end

		if LoadGangData(gangKey) then 
			NotificationEvent:FireClient(player, "<font color='#FF5555'>That gang name is taken!</font>")
			return 
		end

		yen.Value -= 500000

		local newGang = {
			Name = displayGangName, 
			Motto = "We are " .. displayGangName .. "!",
			Emblem = "",
			JoinMode = "Open",
			PrestigeReq = 0,
			OwnerId = player.UserId, OwnerName = player.Name,
			Members = { [pIdStr] = {Name = player.Name, Role = "Boss", Prestige = player.leaderstats.Prestige.Value, LastOnline = math.floor(workspace:GetServerTimeNow()), Contribution = 0, PlayTime = player:GetAttribute("PlayTime") or 0, UserId = player.UserId} },
			Requests = {}, MemberCount = 1,
			CustomRoles = { Boss = "Boss", Consigliere = "Consigliere", Caporegime = "Caporegime", Grunt = "Grunt" },
			Rep = 0, Treasury = 0, TotalPrestige = player.leaderstats.Prestige.Value, TotalElo = player.leaderstats.Elo.Value, RaidWins = 0,
			Buildings = { Vault = 0, Dojo = 0, Armory = 0, Shrine = 0, Market = 0 },
			Orders = GenerateRandomOrders(), LastOrderReset = math.floor(workspace:GetServerTimeNow()),
			ActiveUpgrade = nil
		}

		local success, err = pcall(function()
			GangStore:SetAsync(gangKey, newGang)
		end)

		if success then
			ActiveGangs[gangKey] = newGang
			player:SetAttribute("Gang", gangKey)
			player:SetAttribute("GangRole", "Boss")
			SyncGangToMembers(gangKey)
			pcall(function() MessagingService:PublishAsync(GANG_TOPIC, { Action = "Refresh", GangKey = gangKey }) end)
		else
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Failed to create gang. Try again later.</font>")
			yen.Value += 500000 
		end

	elseif action == "Rename" then
		if pRole ~= "Boss" then return end

		local oldData = ActiveGangs[pGangName]
		if not oldData or (oldData.Treasury or 0) < 10000000 then 
			NotificationEvent:FireClient(player, "<font color='#FF5555'>You need ¥10,000,000 in the Treasury to rename your gang!</font>")
			return 
		end

		local displayGangName = tostring(value)
		local newKey = string.lower(displayGangName)
		local oldKey = pGangName

		if string.len(displayGangName) < 3 or string.len(displayGangName) > 15 or not string.match(displayGangName, "^[a-zA-Z ]+$") then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Invalid name! 3-15 alphabetic characters only.</font>")
			return
		end

		local isClean, errMsg = CheckTextFilter(displayGangName, player.UserId)
		if not isClean then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>" .. errMsg .. "</font>")
			return
		end

		if LoadGangData(newKey) then 
			NotificationEvent:FireClient(player, "<font color='#FF5555'>That gang name is already taken!</font>")
			return 
		end

		local oldDisplayName = oldData.Name
		oldData.Name = displayGangName
		oldData.Treasury = (oldData.Treasury or 0) - 10000000

		local success, err = pcall(function()
			GangStore:SetAsync(newKey, oldData)
			GangStore:SetAsync(oldKey, { RenamedTo = newKey }) 

			ODS_GangRep:RemoveAsync(oldDisplayName)
			ODS_GangTreasury:RemoveAsync(oldDisplayName)
			ODS_GangPrestige:RemoveAsync(oldDisplayName)
			ODS_GangElo:RemoveAsync(oldDisplayName)
			ODS_GangRaids:RemoveAsync(oldDisplayName)
		end)

		if success then
			ActiveGangs[newKey] = oldData
			ActiveGangs[oldKey] = nil
			PendingGangSaves[oldKey] = nil

			for uIdStr, _ in pairs(oldData.Members) do
				local mem = Players:GetPlayerByUserId(tonumber(uIdStr))
				if mem then mem:SetAttribute("Gang", newKey) end
			end

			NotificationEvent:FireClient(player, "<font color='#55FF55'>Successfully renamed Gang to " .. displayGangName .. "!</font>")
			SyncGangToMembers(newKey)
			pcall(function() MessagingService:PublishAsync(GANG_TOPIC, { Action = "Rename", OldKey = oldKey, NewKey = newKey, NewName = displayGangName }) end)
		else
			oldData.Name = oldDisplayName
			oldData.Treasury = (oldData.Treasury or 0) + 10000000
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Database Error while renaming.</font>")
		end

	elseif action == "UpdateMotto" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local newMotto = tostring(value)
		if string.len(newMotto) > 60 then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Motto must be 60 characters or less.</font>")
			return
		end

		local isClean, errMsg = CheckTextFilter(newMotto, player.UserId)
		if not isClean then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>" .. errMsg .. "</font>")
			return
		end

		MutateGangData(pGangName, function(gangData)
			gangData.Motto = newMotto
			return gangData
		end)
		SyncGangToMembers(pGangName)
		NotificationEvent:FireClient(player, "<font color='#55FF55'>Gang Motto successfully updated!</font>")

	elseif action == "UpdateEmblem" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local rawId = tostring(value)
		local digits = string.match(rawId, "%d+")

		if not digits then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Invalid ID! Please provide a valid Roblox Asset ID.</font>")
			return
		end

		local newEmblem = "rbxthumb://type=Asset&id=" .. digits .. "&w=150&h=150"
		MutateGangData(pGangName, function(gangData)
			gangData.Emblem = newEmblem
			return gangData
		end)
		SyncGangToMembers(pGangName)
		NotificationEvent:FireClient(player, "<font color='#55FF55'>Gang Emblem successfully updated!</font>")

	elseif action == "UpdatePrestigeReq" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local newReq = tonumber(value)
		if not newReq or newReq < 0 then return end

		MutateGangData(pGangName, function(gangData)
			gangData.PrestigeReq = newReq
			return gangData
		end)
		SyncGangToMembers(pGangName)
		NotificationEvent:FireClient(player, "<font color='#55FF55'>Prestige requirement updated to " .. newReq .. ".</font>")

	elseif action == "UpgradeBuilding" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local bId = tostring(value)
		local bConfigs = {
			Vault = {Max = 10, ReqLevel = 1},
			Dojo = {Max = 10, ReqLevel = 2},
			Market = {Max = 7, ReqLevel = 3},
			Shrine = {Max = 3, ReqLevel = 4},
			Armory = {Max = 5, ReqLevel = 5}
		}
		local cfg = bConfigs[bId]
		if not cfg then return end

		local started = false
		local errReason = ""

		MutateGangData(pGangName, function(gangData)
			if gangData.ActiveUpgrade then
				if math.floor(workspace:GetServerTimeNow()) < gangData.ActiveUpgrade.FinishTime then
					errReason = "An upgrade is already in progress!"
					return gangData
				else
					local oldId = gangData.ActiveUpgrade.Id
					gangData.Buildings[oldId] = (gangData.Buildings[oldId] or 0) + 1
					gangData.ActiveUpgrade = nil
				end
			end

			if GetGangLevel(gangData.Rep or 0) < cfg.ReqLevel then return gangData end

			local curLvl = gangData.Buildings[bId] or 0
			if curLvl >= cfg.Max then return gangData end

			local cost = 100000000 
			if (gangData.Treasury or 0) >= cost then
				gangData.Treasury -= cost
				gangData.ActiveUpgrade = { Id = bId, FinishTime = math.floor(workspace:GetServerTimeNow()) + 1800 }
				started = true
			else
				errReason = "Not enough Treasury funds (Requires ¥100M)!"
			end
			return gangData
		end)

		if started then
			SyncGangToMembers(pGangName)
			NotificationEvent:FireClient(player, "<font color='#55FF55'>Started upgrading the " .. bId .. "!</font>")
		else
			if errReason ~= "" then
				NotificationEvent:FireClient(player, "<font color='#FF5555'>" .. errReason .. "</font>")
			end
		end

	elseif action == "RerollOrder" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local orderIndex = tonumber(value)
		if not orderIndex then return end

		local rerolled = false
		MutateGangData(pGangName, function(gangData)
			if not gangData.Orders or not gangData.Orders[orderIndex] then return gangData end
			if gangData.Orders[orderIndex].Completed then return gangData end

			if (gangData.Treasury or 0) >= 1000000 then
				gangData.Treasury -= 1000000
				gangData.Orders[orderIndex] = RollSingleOrder()
				rerolled = true
			end
			return gangData
		end)

		if rerolled then
			SyncGangToMembers(pGangName)
			NotificationEvent:FireClient(player, "<font color='#55FF55'>Order successfully rerolled!</font>")
		else
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Cannot reroll this order. (Requires ¥1M or already completed)</font>")
		end

	elseif action == "RenameRole" then
		if pRole ~= "Boss" then return end
		local newRoleName = tostring(value)
		local targetRole = tostring(extraValue)

		if not RolePower[targetRole] then return end
		if string.len(newRoleName) < 3 or string.len(newRoleName) > 15 or not string.match(newRoleName, "^[a-zA-Z ]+$") then 
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Role names must be 3-15 letters only!</font>")
			return 
		end

		local isClean, errMsg = CheckTextFilter(newRoleName, player.UserId)
		if not isClean then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>" .. errMsg .. "</font>")
			return
		end

		MutateGangData(pGangName, function(gangData)
			if not gangData.CustomRoles then gangData.CustomRoles = {} end
			gangData.CustomRoles[targetRole] = newRoleName
			return gangData
		end)
		SyncGangToMembers(pGangName)
		NotificationEvent:FireClient(player, "<font color='#55FF55'>Successfully renamed " .. targetRole .. " to " .. newRoleName .. "!</font>")

	elseif action == "BrowseGangs" then
		if #CachedBrowserList == 0 then RefreshBrowserCache() end
		local shuffled = table.clone(CachedBrowserList)
		for i = #shuffled, 2, -1 do
			local j = math.random(i)
			shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
		end
		local resultList = {}
		local count = 0
		for _, gName in ipairs(shuffled) do
			if count >= 30 then break end
			local gData = LoadGangData(gName)
			if gData then
				table.insert(resultList, {
					Name = gData.Name, 
					Level = GetGangLevel(gData.Rep or 0), 
					Members = gData.MemberCount, 
					Mode = gData.JoinMode, 
					Req = gData.PrestigeReq or 0,
					Motto = gData.Motto,
					Emblem = gData.Emblem
				})
				count += 1
			end
		end
		GangUpdate:FireClient(player, "BrowserSync", resultList)

	elseif action == "SearchGang" then
		local searchName = tostring(value)
		if string.len(searchName) < 3 then return end

		local gData = LoadGangData(searchName)
		if gData then
			GangUpdate:FireClient(player, "BrowserSync", {{
				Name = gData.Name, 
				Level = GetGangLevel(gData.Rep or 0), 
				Members = gData.MemberCount, 
				Mode = gData.JoinMode, 
				Req = gData.PrestigeReq or 0,
				Motto = gData.Motto,
				Emblem = gData.Emblem
			}})
		else
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Gang not found!</font>")
		end

	elseif action == "ToggleJoinMode" then
		if pRole ~= "Boss" then return end
		MutateGangData(pGangName, function(gangData)
			gangData.JoinMode = (gangData.JoinMode == "Open") and "Request" or "Open"
			return gangData
		end)
		SyncGangToMembers(pGangName)

	elseif action == "RequestJoin" then
		if pGangName ~= "None" then return end
		local targetGangKey = string.lower(tostring(value))
		local gangCache = LoadGangData(targetGangKey)
		if not gangCache then return end

		if gangCache.Members[pIdStr] then return end
		if GetDictSize(gangCache.Members) >= 30 then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Gang is full (30/30)!</font>")
			return
		end

		local pPres = player.leaderstats.Prestige.Value
		local req = gangCache.PrestigeReq or 0
		if pPres < req then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>You do not meet the Prestige requirement for this gang ("..req..").</font>")
			return
		end

		if gangCache.JoinMode == "Open" then
			local actuallyJoined = false

			MutateGangData(targetGangKey, function(gangData)
				actuallyJoined = false
				if GetDictSize(gangData.Members) < 30 and not gangData.Members[pIdStr] then
					gangData.Members[pIdStr] = {Name = player.Name, Role = "Grunt", Prestige = player.leaderstats.Prestige.Value, LastOnline = math.floor(workspace:GetServerTimeNow()), Contribution = 0, PlayTime = player:GetAttribute("PlayTime") or 0, UserId = player.UserId}
					actuallyJoined = true
				end
				return gangData
			end)

			if actuallyJoined then
				player:SetAttribute("Gang", targetGangKey)
				player:SetAttribute("GangRole", "Grunt")
				ApplyGangBuffs(player, ActiveGangs[targetGangKey])
				SyncGangToMembers(targetGangKey)
				NotificationEvent:FireClient(player, "<font color='#55FF55'>Joined " .. gangCache.Name .. "!</font>")
			else
				NotificationEvent:FireClient(player, "<font color='#FF5555'>Gang is full (30/30)!</font>")
			end
		else
			MutateGangData(targetGangKey, function(gangData)
				if not gangData.Requests then gangData.Requests = {} end
				gangData.Requests[pIdStr] = player.Name
				return gangData
			end)
			SyncGangToMembers(targetGangKey)
			NotificationEvent:FireClient(player, "<font color='#FFFF55'>Request sent to " .. gangCache.Name .. "!</font>")
		end

	elseif action == "AcceptRequest" or action == "DenyRequest" then
		if RolePower[pRole] < RolePower["Caporegime"] then return end
		local targetIdStr = tostring(value)
		local targetPlayer = Players:GetPlayerByUserId(tonumber(targetIdStr))
		local accepted = false

		MutateGangData(pGangName, function(gangData)
			accepted = false
			if gangData.Requests and gangData.Requests[targetIdStr] then
				if action == "AcceptRequest" then
					if GetDictSize(gangData.Members) < 30 then
						if targetPlayer and targetPlayer:GetAttribute("Gang") == "None" then
							gangData.Members[targetIdStr] = {Name = targetPlayer.Name, Role = "Grunt", Prestige = targetPlayer.leaderstats.Prestige.Value, LastOnline = math.floor(workspace:GetServerTimeNow()), Contribution = 0, PlayTime = targetPlayer:GetAttribute("PlayTime") or 0, UserId = targetPlayer.UserId}
							accepted = true
						end
					end
				end
				gangData.Requests[targetIdStr] = nil
			end
			return gangData
		end)

		if accepted and targetPlayer then
			targetPlayer:SetAttribute("Gang", pGangName)
			targetPlayer:SetAttribute("GangRole", "Grunt")
			ApplyGangBuffs(targetPlayer, ActiveGangs[pGangName])
			NotificationEvent:FireClient(targetPlayer, "<font color='#55FF55'>Your request to join " .. ActiveGangs[pGangName].Name .. " was accepted!</font>")
		elseif action == "AcceptRequest" and not accepted then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Could not accept. Gang is full (30/30) or player is offline.</font>")
		end
		SyncGangToMembers(pGangName)

	elseif action == "Kick" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local targetIdStr = tostring(value)

		MutateGangData(pGangName, function(gangData)
			local targetMember = gangData.Members[targetIdStr]
			if targetMember and targetIdStr ~= pIdStr and RolePower[pRole] > (RolePower[targetMember.Role] or 1) then
				gangData.Members[targetIdStr] = nil

				local tPlayer = Players:GetPlayerByUserId(tonumber(targetIdStr))
				if tPlayer then
					tPlayer:SetAttribute("Gang", "None")
					tPlayer:SetAttribute("GangRole", "None")
					ApplyGangBuffs(tPlayer, nil)
					NotificationEvent:FireClient(tPlayer, "<font color='#FF5555'>You were kicked from the gang.</font>")
					SyncPlayer(tPlayer)
				end
			end
			return gangData
		end)
		SyncGangToMembers(pGangName)

	elseif action == "Promote" or action == "Demote" then
		if RolePower[pRole] < RolePower["Consigliere"] then return end
		local targetIdStr = tostring(value)

		MutateGangData(pGangName, function(gangData)
			local targetMember = gangData.Members[targetIdStr]
			if targetMember and targetIdStr ~= pIdStr and RolePower[pRole] > (RolePower[targetMember.Role] or 1) then
				local curRole = targetMember.Role
				local newRole = curRole

				if action == "Promote" then
					if curRole == "Grunt" then newRole = "Caporegime"
					elseif curRole == "Caporegime" and pRole == "Boss" then newRole = "Consigliere"
					elseif curRole == "Consigliere" and pRole == "Boss" then
						targetMember.Role = "Boss"
						gangData.Members[pIdStr].Role = "Consigliere"

						player:SetAttribute("GangRole", "Consigliere")
						NotificationEvent:FireClient(player, "<font color='#FFFF55'>You have passed the Boss title to " .. targetMember.Name .. "!</font>")

						local tPlayer = Players:GetPlayerByUserId(tonumber(targetIdStr))
						if tPlayer then
							tPlayer:SetAttribute("GangRole", "Boss")
							NotificationEvent:FireClient(tPlayer, "<font color='#FFD700'>You have been promoted to Gang Boss!</font>")
						end
						return gangData
					end
				elseif action == "Demote" then
					if curRole == "Consigliere" then newRole = "Caporegime"
					elseif curRole == "Caporegime" then newRole = "Grunt" end
				end

				if newRole == "Caporegime" and action == "Promote" then
					local capoCount = 0
					for _, m in pairs(gangData.Members) do if m.Role == "Caporegime" then capoCount += 1 end end
					if capoCount >= 5 then return gangData end
				elseif newRole == "Consigliere" and action == "Promote" then
					local conCount = 0
					for _, m in pairs(gangData.Members) do if m.Role == "Consigliere" then conCount += 1 end end
					if conCount >= 1 then return gangData end
				end

				targetMember.Role = newRole
				local tPlayer = Players:GetPlayerByUserId(tonumber(targetIdStr))
				if tPlayer then
					tPlayer:SetAttribute("GangRole", newRole)
					NotificationEvent:FireClient(tPlayer, "<font color='#FFFF55'>Your gang role was updated to: " .. newRole .. "</font>")
				end
			end
			return gangData
		end)
		SyncGangToMembers(pGangName)

	elseif action == "Donate" then
		local amount = tonumber(value)
		if not amount or amount < 1000 or pGangName == "None" then return end

		local yen = player.leaderstats.Yen
		if yen.Value >= amount then
			yen.Value -= amount
			AddPendingUpdate(pGangName, "Treasury", amount)
			AddPendingUpdate(pGangName, "Contribution", amount, pIdStr) 

			local repGained = math.floor(amount / 1000)
			if repGained > 0 then
				AddPendingUpdate(pGangName, "Rep", repGained)
			end

			ProgressOrderEvent:Fire(pGangName, "Yen", amount)

			local lowerKey = string.lower(pGangName)
			if ActiveGangs[lowerKey] and ActiveGangs[lowerKey].Members[pIdStr] then
				ActiveGangs[lowerKey].Members[pIdStr].Contribution = (ActiveGangs[lowerKey].Members[pIdStr].Contribution or 0) + amount
			end

			ApplyGangBuffs(player, ActiveGangs[lowerKey])

			if repGained > 0 then
				NotificationEvent:FireClient(player, "<font color='#55FF55'>Donated ¥" .. amount .. " to the Gang! (+" .. repGained .. " Rep)</font>")
			else
				NotificationEvent:FireClient(player, "<font color='#55FF55'>Donated ¥" .. amount .. " to the Gang!</font>")
			end

			SyncGangToMembers(pGangName)
		end

	elseif action == "Leave" then
		if pGangName == "None" or pRole == "Boss" then return end

		MutateGangData(pGangName, function(gangData)
			if gangData.Members[pIdStr] then
				gangData.Members[pIdStr] = nil
			end
			return gangData
		end)

		player:SetAttribute("Gang", "None")
		player:SetAttribute("GangRole", "None")
		ApplyGangBuffs(player, nil)
		NotificationEvent:FireClient(player, "<font color='#AAAAAA'>You left the gang.</font>")
		SyncPlayer(player)
		SyncGangToMembers(pGangName)

	elseif action == "Disband" then
		if pGangName == "None" or pRole ~= "Boss" then return end
		local gang = ActiveGangs[string.lower(pGangName)]
		if not gang then return end

		local displayToWipe = gang.Name

		pcall(function()
			GangStore:RemoveAsync(pGangName)
			ODS_GangRep:RemoveAsync(displayToWipe)
			ODS_GangTreasury:RemoveAsync(displayToWipe)
			ODS_GangPrestige:RemoveAsync(displayToWipe)
			ODS_GangElo:RemoveAsync(displayToWipe)
			ODS_GangRaids:RemoveAsync(displayToWipe)
			MessagingService:PublishAsync(GANG_TOPIC, { Action = "Wipe", GangKey = pGangName })
		end)

	elseif action == "RequestSync" then
		if pGangName ~= "None" then
			local gData = LoadGangData(pGangName)
			if gData then
				if gData.ActiveUpgrade and math.floor(workspace:GetServerTimeNow()) >= gData.ActiveUpgrade.FinishTime then
					MutateGangData(pGangName, function(mutateData)
						if mutateData.ActiveUpgrade and math.floor(workspace:GetServerTimeNow()) >= mutateData.ActiveUpgrade.FinishTime then
							local bId = mutateData.ActiveUpgrade.Id
							mutateData.Buildings[bId] = (mutateData.Buildings[bId] or 0) + 1
							mutateData.ActiveUpgrade = nil
						end
						return mutateData
					end)
				else
					for uidString, mem in pairs(gData.Members) do
						local pOnline = Players:GetPlayerByUserId(tonumber(uidString))
						if pOnline then
							mem.LastOnline = math.floor(workspace:GetServerTimeNow())
							mem.PlayTime = pOnline:GetAttribute("PlayTime") or mem.PlayTime or 0
						end
					end
					local hasBoss = false
					for _, m in pairs(gData.Members) do if m.Role == "Boss" then hasBoss = true break end end
					if not hasBoss then
						MutateGangData(pGangName, function(mutateData)
							ElectNewBoss(mutateData)
							return mutateData
						end)
					end
				end
				SyncPlayer(player) 
			else
				player:SetAttribute("Gang", "None")
				player:SetAttribute("GangRole", "None")
				SyncPlayer(player)
			end
		else
			SyncPlayer(player) 
		end
	end
end)