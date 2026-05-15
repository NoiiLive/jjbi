-- @ScriptType: Script
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = ReplicatedStorage:WaitForChild("Network")

local LeaderboardAction = Network:WaitForChild("GangLeaderboardAction")
local LeaderboardUpdate = Network:WaitForChild("GangLeaderboardUpdate")

local WeeklyGangTokensStore = DataStoreService:GetOrderedDataStore("GangTokens_Weekly_W2")
local SeasonalGangTokensStore = DataStoreService:GetOrderedDataStore("GangTokens_Season_V1")

local WeeklyMetaStore = DataStoreService:GetDataStore("GangTokens_Weekly_Meta_W2")

local WEEK_DURATION = 7 * 24 * 60 * 60
local SAVE_INTERVAL = 300

local Cache = {
	Weekly = {},
	Season = {}
}

local DirtyWeekly = {}
local DirtySeason = {}

local function GetWeekStart()
	local success, value = pcall(function()
		return WeeklyMetaStore:GetAsync("WeekStart")
	end)

	if success and value then
		return value
	end

	local now = os.time()
	pcall(function()
		WeeklyMetaStore:SetAsync("WeekStart", now)
	end)
	return now
end

local function SetWeekStart(timestamp)
	pcall(function()
		WeeklyMetaStore:SetAsync("WeekStart", timestamp)
	end)
end

local function ClearWeeklyLeaderboard()
	for k in pairs(DirtyWeekly) do
		DirtyWeekly[k] = nil
	end

	local success, pages = pcall(function()
		return WeeklyGangTokensStore:GetSortedAsync(false, 100)
	end)

	if success and pages then
		while true do
			local data = pages:GetCurrentPage()
			for _, entry in ipairs(data) do
				pcall(function()
					WeeklyGangTokensStore:RemoveAsync(entry.key)
				end)
				task.wait(0.05)
			end
			if pages.IsFinished then break end
			local advSuccess = pcall(function() pages:AdvanceToNextPageAsync() end)
			if not advSuccess then break end
		end
	end

	SetWeekStart(os.time())
end

local function CheckWeeklyReset()
	local start = GetWeekStart()
	if os.time() - start >= WEEK_DURATION then
		ClearWeeklyLeaderboard()
	end
end

local function SaveDirty()
	for gangKey, amount in pairs(DirtyWeekly) do
		if amount ~= 0 then
			pcall(function()
				WeeklyGangTokensStore:IncrementAsync(gangKey, amount)
			end)
		end
		DirtyWeekly[gangKey] = nil
		task.wait(0.05)
	end

	for gangKey, amount in pairs(DirtySeason) do
		if amount ~= 0 then
			pcall(function()
				SeasonalGangTokensStore:IncrementAsync(gangKey, amount)
			end)
		end
		DirtySeason[gangKey] = nil
		task.wait(0.05)
	end
end

local function FetchLeaderboard(store, oldCache)
	local success, pages = pcall(function()
		return store:GetSortedAsync(false, 100)
	end)

	if success and pages then
		local result = {}
		local data = pages:GetCurrentPage()
		for i, entry in ipairs(data) do
			table.insert(result, {
				Rank = i,
				GangKey = entry.key,
				Tokens = entry.value
			})
		end
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
	if typeof(gangKey) ~= "string" then return end
	if typeof(amount) ~= "number" then return end

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

game:BindToClose(function()
	SaveDirty()
end)

RefreshAll()

LeaderboardAction.OnServerEvent:Connect(function(player, category)
	local data = Cache[category]
	if data then
		LeaderboardAction:FireClient(player, category, data)
	end
end)

LeaderboardUpdate.Event:Connect(function(gangKey, amount)
	AddTokens(gangKey, amount)
end)