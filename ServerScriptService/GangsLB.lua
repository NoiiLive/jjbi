-- @ScriptType: Script
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Network = ReplicatedStorage:WaitForChild("Network")
local LeaderboardAction = Network:WaitForChild("GangLeaderboardAction")
local LeaderboardUpdate = Network:WaitForChild("GangLeaderboardUpdate")

local SeasonRewardAction = Network:FindFirstChild("SeasonRewardAction")
if not SeasonRewardAction then
	SeasonRewardAction = Instance.new("RemoteEvent")
	SeasonRewardAction.Name = "SeasonRewardAction"
	SeasonRewardAction.Parent = Network
end

local CURRENT_SEASON = 1 
ReplicatedStorage:SetAttribute("CurrentSeason", CURRENT_SEASON)

local BASE_WEEK_TIMESTAMP = 1779353457 
local STARTING_WEEK_NUMBER = 2
local WEEK_DURATION = 7 * 24 * 60 * 60

local function GetCurrentWeek()
	local elapsed = math.max(0, os.time() - BASE_WEEK_TIMESTAMP)
	return STARTING_WEEK_NUMBER + math.floor(elapsed / WEEK_DURATION)
end

local CURRENT_WEEK = GetCurrentWeek()
local WeeklyGangTokensStore = DataStoreService:GetOrderedDataStore("GangTokens_Weekly_W" .. CURRENT_WEEK)
local SeasonalGangTokensStore = DataStoreService:GetOrderedDataStore("GangTokens_Season_V" .. CURRENT_SEASON)

local SAVE_INTERVAL = 300

local REWARD_TIERS = {
	[1] = { Items = { ["Mythical Giftbox"] = 2, ["Legendary Giftbox"] = 3 }, Yen = 5000000 },
	[2] = { Items = { ["Mythical Giftbox"] = 1, ["Legendary Giftbox"] = 2 }, Yen = 2500000 },
	[3] = { Items = { ["Legendary Giftbox"] = 3, ["Unique Giftbox"] = 2 }, Yen = 1000000 },
	[4] = { Items = { ["Legendary Giftbox"] = 1, ["Unique Giftbox"] = 2 }, Yen = 500000 },
	[5] = { Items = { ["Unique Giftbox"] = 1 }, Yen = 100000 }
}

local function GetRewardTier(rank)
	if rank == 1 then return 1 end
	if rank == 2 then return 2 end
	if rank == 3 then return 3 end
	if rank >= 4 and rank <= 10 then return 4 end
	if rank >= 11 and rank <= 50 then return 5 end
	return nil
end

local Cache = { Weekly = {}, Season = {} }
local PreviousSeasonCache = {}
local PastSeasonsTop3Cache = {}
local DirtyWeekly = {}
local DirtySeason = {}

local function FetchPreviousSeason()
	if CURRENT_SEASON <= 1 then return end
	local prevStore = DataStoreService:GetOrderedDataStore("GangTokens_Season_V" .. (CURRENT_SEASON - 1))
	local success, pages = pcall(function() return prevStore:GetSortedAsync(false, 50) end)
	if success and pages then
		local data = pages:GetCurrentPage()
		for i, entry in ipairs(data) do
			PreviousSeasonCache[entry.key] = {Rank = i, Tokens = entry.value}
		end
	end
end
task.spawn(FetchPreviousSeason)

local function FetchAllPastTop3()
	if CURRENT_SEASON <= 1 then return end
	for s = CURRENT_SEASON - 1, 1, -1 do
		local store = DataStoreService:GetOrderedDataStore("GangTokens_Season_V" .. s)
		local success, pages = pcall(function() return store:GetSortedAsync(false, 3) end)
		local top3 = {}
		if success and pages then
			local data = pages:GetCurrentPage()
			for i, entry in ipairs(data) do
				top3[i] = entry.key
			end
		end
		PastSeasonsTop3Cache[tostring(s)] = top3
	end
end
task.spawn(FetchAllPastTop3)

local function CheckWeeklyReset()
	local calculatedWeek = GetCurrentWeek()

	if CURRENT_WEEK ~= calculatedWeek then
		CURRENT_WEEK = calculatedWeek
		WeeklyGangTokensStore = DataStoreService:GetOrderedDataStore("GangTokens_Weekly_W" .. CURRENT_WEEK)

		for k in pairs(DirtyWeekly) do DirtyWeekly[k] = nil end
		Cache.Weekly = {}

		print("[GangsLB] Weekly Leaderboard mathematically switched to W" .. CURRENT_WEEK)
	end
end

local function SaveDirty()
	for gangKey, amount in pairs(DirtyWeekly) do
		if amount ~= 0 then pcall(function() WeeklyGangTokensStore:IncrementAsync(gangKey, amount) end) end
		DirtyWeekly[gangKey] = nil
		task.wait(0.05)
	end
	for gangKey, amount in pairs(DirtySeason) do
		if amount ~= 0 then pcall(function() SeasonalGangTokensStore:IncrementAsync(gangKey, amount) end) end
		DirtySeason[gangKey] = nil
		task.wait(0.05)
	end
end

local function FetchLeaderboard(store, oldCache)
	local success, pages = pcall(function() return store:GetSortedAsync(false, 100) end)
	if success and pages then
		local result = {}
		local data = pages:GetCurrentPage()
		for i, entry in ipairs(data) do table.insert(result, { Rank = i, GangKey = entry.key, Tokens = entry.value }) end
		return result
	end
	return oldCache
end

local function RefreshAll()
	CheckWeeklyReset()
	Cache.Weekly = FetchLeaderboard(WeeklyGangTokensStore, Cache.Weekly)
	Cache.Season = FetchLeaderboard(SeasonalGangTokensStore, Cache.Season)
end

local function AddTokens(gangKey, amount)
	if typeof(gangKey) ~= "string" or typeof(amount) ~= "number" then return end
	DirtyWeekly[gangKey] = (DirtyWeekly[gangKey] or 0) + amount
	DirtySeason[gangKey] = (DirtySeason[gangKey] or 0) + amount
end

task.spawn(function()
	while true do
		task.wait(SAVE_INTERVAL)
		SaveDirty()
		RefreshAll()
		LeaderboardAction:FireAllClients("Weekly", Cache.Weekly)
		LeaderboardAction:FireAllClients("Season", Cache.Season)
	end
end)

game:BindToClose(function() SaveDirty() end)
RefreshAll()

LeaderboardAction.OnServerEvent:Connect(function(player, category)
	local data = Cache[category]
	if data then LeaderboardAction:FireClient(player, category, data) end
end)

LeaderboardUpdate.Event:Connect(function(gangKey, amount) AddTokens(gangKey, amount) end)

SeasonRewardAction.OnServerEvent:Connect(function(player, action, dataPayload)
	if action == "GetSeasonsOverview" then
		SeasonRewardAction:FireClient(player, "SeasonsOverviewData", PastSeasonsTop3Cache)

	elseif action == "GetSeasonData" then
		local targetSeason = tonumber(dataPayload)
		if not targetSeason then return end

		if targetSeason == CURRENT_SEASON - 1 then
			local orderedData = {}
			for gang, cacheData in pairs(PreviousSeasonCache) do 
				table.insert(orderedData, {GangKey = gang, Rank = cacheData.Rank, Tokens = cacheData.Tokens}) 
			end
			table.sort(orderedData, function(a, b) return a.Rank < b.Rank end)
			SeasonRewardAction:FireClient(player, "SeasonData", {Season = targetSeason, Data = orderedData})
		else
			local oldStore = DataStoreService:GetOrderedDataStore("GangTokens_Season_V" .. targetSeason)
			local success, pages = pcall(function() return oldStore:GetSortedAsync(false, 50) end)
			local orderedData = {}
			if success and pages then
				local pageData = pages:GetCurrentPage()
				for i, entry in ipairs(pageData) do
					table.insert(orderedData, {GangKey = entry.key, Rank = i, Tokens = entry.value})
				end
			end
			SeasonRewardAction:FireClient(player, "SeasonData", {Season = targetSeason, Data = orderedData})
		end

	elseif action == "ClaimReward" then
		local targetSeason = tonumber(dataPayload)
		if not targetSeason or targetSeason >= CURRENT_SEASON then return end

		local targetSeasonStr = tostring(targetSeason)
		local claimedJson = player:GetAttribute("SeasonRewardsClaimed") or "{}"
		local success, claimedTable = pcall(function() return HttpService:JSONDecode(claimedJson) end)
		if not success or type(claimedTable) ~= "table" then claimedTable = {} end

		local NotificationEvent = Network:FindFirstChild("NotificationEvent")

		if claimedTable[targetSeasonStr] then
			if NotificationEvent then NotificationEvent:FireClient(player, "<font color='#FF5555'>You already claimed your reward for Season " .. targetSeasonStr .. "!</font>") end
			return
		end

		local partsJson = player:GetAttribute("SeasonParticipation") or "{}"
		local s2, partsTable = pcall(function() return HttpService:JSONDecode(partsJson) end)
		if not s2 or type(partsTable) ~= "table" then partsTable = {} end

		local pastGangs = partsTable[targetSeasonStr] or ""
		if pastGangs == "" then
			if NotificationEvent then NotificationEvent:FireClient(player, "<font color='#FF5555'>You did not participate in any gang during Season " .. targetSeasonStr .. "!</font>") end
			return
		end

		local bestRank = 9999

		if targetSeason == CURRENT_SEASON - 1 then
			for gangName in string.gmatch(pastGangs, "([^,]+)") do
				local cacheData = PreviousSeasonCache[gangName]
				if cacheData and cacheData.Rank < bestRank then bestRank = cacheData.Rank end
			end
		else
			local oldStore = DataStoreService:GetOrderedDataStore("GangTokens_Season_V" .. targetSeasonStr)
			local s3, pages = pcall(function() return oldStore:GetSortedAsync(false, 50) end)
			if s3 and pages then
				local pageData = pages:GetCurrentPage()
				for i, entry in ipairs(pageData) do
					for gangName in string.gmatch(pastGangs, "([^,]+)") do
						if entry.key == gangName and i < bestRank then
							bestRank = i
						end
					end
				end
			end
		end

		if bestRank > 50 then
			if NotificationEvent then NotificationEvent:FireClient(player, "<font color='#FF5555'>Your gang(s) did not reach Top 50 in Season " .. targetSeasonStr .. ".</font>") end
			return
		end

		local tier = GetRewardTier(bestRank)
		local reward = REWARD_TIERS[tier]

		if reward then
			claimedTable[targetSeasonStr] = true
			player:SetAttribute("SeasonRewardsClaimed", HttpService:JSONEncode(claimedTable))

			pcall(function() player.leaderstats.Yen.Value += reward.Yen end)
			for itemName, amount in pairs(reward.Items) do
				local cleanName = itemName:gsub("[^%w]", "") .. "Count"
				player:SetAttribute(cleanName, (player:GetAttribute(cleanName) or 0) + amount)
			end

			local saveEvent = ReplicatedStorage:FindFirstChild("ForcePlayerSave")
			if saveEvent then saveEvent:Fire(player) end

			local invAction = Network:FindFirstChild("InventoryAction")
			if invAction then
				invAction:FireClient(player, "Refresh")
			end

			if NotificationEvent then NotificationEvent:FireClient(player, "<font color='#55FF55'>Successfully claimed Season " .. targetSeasonStr .. " reward (Rank " .. bestRank .. ")!</font>") end
		end
	end
end)