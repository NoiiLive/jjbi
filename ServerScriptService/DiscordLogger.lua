-- @ScriptType: Script
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Network = ReplicatedStorage:WaitForChild("Network")

local AdminLogger = Network:FindFirstChild("AdminLogger")
if not AdminLogger then
	AdminLogger = Instance.new("BindableEvent")
	AdminLogger.Name = "AdminLogger"
	AdminLogger.Parent = Network
end

local WorldBossLogEvent = Network:FindFirstChild("WorldBossLogger")
if not WorldBossLogEvent then
	WorldBossLogEvent = Instance.new("BindableEvent")
	WorldBossLogEvent.Name = "WorldBossLogger"
	WorldBossLogEvent.Parent = Network
end

local ADMIN_WEBHOOK_URL = "https://discord.com/api/webhooks/1488980762165379213/yLjM6XIzDo0sSGiMOpFJQ8gYGs5hiDS-8bJoFzyrrh5Jw5e7EuNI2QdlzQimIZRnrpFW"
local BOSS_WEBHOOK_URL = "https://discord.com/api/webhooks/1488994023652724736/szzJf00-CBHsvW0AIWqzy4N1P3QZaDr0SULPXcduiCLEwJ67Pju1DF7bcsxwhUhwvQwW"

local logQueue = {}
local isProcessingQueue = false

local function ProcessQueue()
	if isProcessingQueue then return end
	isProcessingQueue = true

	while #logQueue > 0 do
		local currentLog = logQueue[1]
		local webhookUrl = currentLog.Url
		local payload = currentLog.Payload

		local jsonData = HttpService:JSONEncode(payload)

		local success, err = pcall(function()
			HttpService:PostAsync(webhookUrl, jsonData, Enum.HttpContentType.ApplicationJson)
		end)

		if success then
			table.remove(logQueue, 1)
			task.wait(1)
		else
			warn("Failed to send log to Discord: " .. tostring(err) .. ". Retrying in 5 seconds...")
			task.wait(5)
		end
	end

	isProcessingQueue = false
end

local function SendToDiscord(webhookUrl, embedData, contentText)
	if RunService:IsStudio() then
		print("[Studio Intercept] Discord log prevented from sending: " .. tostring(embedData and embedData.title or "Unknown Log"))
		return
	end

	if webhookUrl == "" then
		warn("Discord Webhook URL not set correctly in DiscordLogger! Logs are not saving permanently.")
		return
	end

	local payload = {
		["embeds"] = {embedData}
	}

	if contentText then
		payload["content"] = contentText
	end

	table.insert(logQueue, {Url = webhookUrl, Payload = payload})
	task.spawn(ProcessQueue)
end

AdminLogger.Event:Connect(function(logType, logData)
	local embed = {
		["title"] = "📋 " .. tostring(logType) .. " Log",
		["timestamp"] = DateTime.now():ToIsoDate(),
		["color"] = 0xFFFFFF,
		["fields"] = {}
	}

	if logType == "Command" then
		embed.color = 0x3498DB
		table.insert(embed.fields, {name = "Admin", value = tostring(logData.Player), inline = true})
		table.insert(embed.fields, {name = "Command", value = tostring(logData.Command), inline = true})
		table.insert(embed.fields, {name = "Full Text", value = tostring(logData.FullText), inline = false})

	elseif logType == "Trade" then
		embed.color = 0x2ECC71
		table.insert(embed.fields, {name = "Player 1", value = tostring(logData.Player1), inline = true})
		table.insert(embed.fields, {name = "Player 2", value = tostring(logData.Player2), inline = true})
		table.insert(embed.fields, {name = tostring(logData.Player1) .. "'s Offer", value = tostring(logData.Offer1), inline = false})
		table.insert(embed.fields, {name = tostring(logData.Player2) .. "'s Offer", value = tostring(logData.Offer2), inline = false})

	elseif logType == "Purchase" then
		embed.color = 0xF1C40F
		table.insert(embed.fields, {name = "Purchaser", value = tostring(logData.Player), inline = true})
		table.insert(embed.fields, {name = "Target (Gifted To)", value = tostring(logData.Target), inline = true})
		table.insert(embed.fields, {name = "Item Purchased", value = tostring(logData.Item), inline = false})

	elseif logType == "Replacement" then
		embed.color = 0xE67E22
		table.insert(embed.fields, {name = "Player", value = tostring(logData.Player), inline = true})
		table.insert(embed.fields, {name = "Context", value = tostring(logData.Context), inline = true})
		table.insert(embed.fields, {name = "Action", value = "Replaced **" .. tostring(logData.OldItem) .. "** with **" .. tostring(logData.NewItem) .. "** in slot: `" .. tostring(logData.Slot) .. "`", inline = false})
	end

	SendToDiscord(ADMIN_WEBHOOK_URL, embed)
end)

WorldBossLogEvent.Event:Connect(function(bossName)
	local embed = {
		["title"] = "🚨 World Boss Spawned!",
		["description"] = "**" .. tostring(bossName) .. "** has just appeared in a server!\nJump in-game now to battle them!",
		["timestamp"] = DateTime.now():ToIsoDate(),
		["color"] = 0xFF0000,
	}

	SendToDiscord(BOSS_WEBHOOK_URL, embed, "<@&1488983964592111857>")
end)