-- @ScriptType: Script
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = ReplicatedStorage:WaitForChild("Network")

local LeaderboardAction = Network:WaitForChild("GangLeaderboardAction")
local LeaderboardUpdate = Network:WaitForChild("GangLeaderboardUpdate")

local WeeklyGangTokensStore = DataStoreService:GetOrderedDataStore("GangTokens_Weekly")
local SeasonalGangTokensStore = DataStoreService:GetOrderedDataStore("GangTokens_Season_V1")

local WeeklyMetaStore = DataStoreService:GetDataStore("GangTokens_Weekly_Meta")

local WEEK_DURATION = 7 * 24 * 60 * 60
local SAVE_INTERVAL = 300

local Cache = {
	Weekly = {},
	Season = {}
}

local RuntimeTokens = {
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
	for k in pairs(RuntimeTokens.Weekly) do
		RuntimeTokens.Weekly[k] = nil
	end

	for k in pairs(DirtyWeekly) do
		DirtyWeekly[k] = nil
	end

	local success, pages = pcall(function()
		return WeeklyGangTokensStore:GetSortedAsync(false, 100)
	end)

	if success and pages then
		local data = pages:GetCurrentPage()
		for _, entry in ipairs(data) do
			pcall(function()
				WeeklyGangTokensStore:RemoveAsync(entry.key)
			end)
			task.wait(0.05)
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

local function LoadStore(store, target)
	local success, pages = pcall(function()
		return store:GetSortedAsync(false, 100)
	end)

	if not success or not pages then
		return
	end

	local data = pages:GetCurrentPage()

	for _, entry in ipairs(data) do
		target[entry.key] = entry.value
	end
end

LoadStore(WeeklyGangTokensStore, RuntimeTokens.Weekly)
LoadStore(SeasonalGangTokensStore, RuntimeTokens.Season)

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

local function BuildCache(runtime)
	local temp = {}

	for gangKey, tokens in pairs(runtime) do
		table.insert(temp, {
			GangKey = gangKey,
			Tokens = tokens
		})
	end

	table.sort(temp, function(a, b)
		return a.Tokens > b.Tokens
	end)

	local result = {}

	for i = 1, math.min(100, #temp) do
		local e = temp[i]
		result[i] = {
			Rank = i,
			GangKey = e.GangKey,
			Tokens = e.Tokens
		}
	end

	return result
end

local function RefreshAll()
	CheckWeeklyReset()

	Cache.Weekly = BuildCache(RuntimeTokens.Weekly)
	Cache.Season = BuildCache(RuntimeTokens.Season)
end

local function AddTokens(gangKey, amount)
	if typeof(gangKey) ~= "string" then return end
	if typeof(amount) ~= "number" then return end

	RuntimeTokens.Weekly[gangKey] = (RuntimeTokens.Weekly[gangKey] or 0) + amount
	RuntimeTokens.Season[gangKey] = (RuntimeTokens.Season[gangKey] or 0) + amount

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