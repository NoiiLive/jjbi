-- @ScriptType: Script
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local EventStore = DataStoreService:GetDataStore("UniversalEventCalendar_V1")
local SYNC_TOPIC = "UniversalEventSync_V1"

local Network = ReplicatedStorage:WaitForChild("Network")
local AdminEventRemote = Network:FindFirstChild("AdminEventAction")
if not AdminEventRemote then
	AdminEventRemote = Instance.new("RemoteEvent")
	AdminEventRemote.Name = "AdminEventAction"
	AdminEventRemote.Parent = Network
end

local EventAdmins = {
	[82860902] = true,
	[950762580] = true,
}
local cachedSchedule = {}

local function GenerateID()
	return HttpService:GenerateGUID(false)
end

local function UpdateActiveEvents()
	local now = os.time()
	local activeTypes = {}

	for _, event in ipairs(cachedSchedule) do
		if now >= event.Start and now < event.End then
			activeTypes[event.Type] = { Mult = event.Mult, End = event.End }
		end
	end

	for eType, data in pairs(activeTypes) do
		ReplicatedStorage:SetAttribute("GlobalEvent_" .. eType, data.Mult)
		ReplicatedStorage:SetAttribute("GlobalEventEnd_" .. eType, data.End)
	end

	for name, _ in pairs(ReplicatedStorage:GetAttributes()) do
		if string.sub(name, 1, 12) == "GlobalEvent_" then
			local eType = string.sub(name, 13)
			if not activeTypes[eType] then
				ReplicatedStorage:SetAttribute("GlobalEvent_" .. eType, nil)
				ReplicatedStorage:SetAttribute("GlobalEventEnd_" .. eType, nil)
			end
		end
	end
end

local function CleanOldEvents()
	local cleaned = {}
	local now = os.time()
	for _, event in ipairs(cachedSchedule) do
		if event.End > (now - 60*60*3) then
			table.insert(cleaned, event)
		end
	end
	cachedSchedule = cleaned
end

pcall(function()
	MessagingService:SubscribeAsync(SYNC_TOPIC, function(message)
		local success, newSchedule = pcall(function()
			return HttpService:JSONDecode(message.Data)
		end)

		if success and type(newSchedule) == "table" then
			cachedSchedule = newSchedule
			UpdateActiveEvents()
		end
	end)
end)


local function FetchScheduleInitial()
	local success, data = pcall(function()
		return EventStore:GetAsync("Schedule")
	end)

	if success and data then
		cachedSchedule = HttpService:JSONDecode(data)
		UpdateActiveEvents()
	end
end

task.spawn(FetchScheduleInitial)

task.spawn(function()
	while true do
		task.wait(5)
		UpdateActiveEvents()
	end
end)

task.spawn(function()
	while true do
		task.wait(math.random(600, 900))
		FetchScheduleInitial()
	end
end)

AdminEventRemote.OnServerEvent:Connect(function(player, action, data)
	if not EventAdmins[player.UserId] and not game:GetService("RunService"):IsStudio() then return end

	if action == "CreateEvent" then
		CleanOldEvents()
		
		local mult = math.max(1, tonumber(data.Mult) or 1)
		

		table.insert(cachedSchedule, {
			Id = GenerateID(),
			Type = data.Type,
			Mult = mult, 
			Start = data.Start,
			End = data.End
		})

		local jsonData = HttpService:JSONEncode(cachedSchedule)

		pcall(function() EventStore:SetAsync("Schedule", jsonData) end)

		pcall(function() MessagingService:PublishAsync(SYNC_TOPIC, jsonData) end)
		UpdateActiveEvents()

	elseif action == "DeleteEvent" then
		for i, event in ipairs(cachedSchedule) do
			if event.Id == data.Id then
				table.remove(cachedSchedule, i)
				break
			end
		end

		local jsonData = HttpService:JSONEncode(cachedSchedule)
		pcall(function() EventStore:SetAsync("Schedule", jsonData) end)
		pcall(function() MessagingService:PublishAsync(SYNC_TOPIC, jsonData) end)
		UpdateActiveEvents()

	elseif action == "GetSchedule" then
		AdminEventRemote:FireClient(player, "ScheduleData", cachedSchedule)
	end
end)