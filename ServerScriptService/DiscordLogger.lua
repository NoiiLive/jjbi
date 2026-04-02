-- @ScriptType: Script
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local AdminLogger = Network:WaitForChild("AdminLogger")

local WorldBossLogEvent = Network:FindFirstChild("WorldBossLogger")
if not WorldBossLogEvent then
	WorldBossLogEvent = Instance.new("BindableEvent")
	WorldBossLogEvent.Name = "WorldBossLogger"
	WorldBossLogEvent.Parent = Network
end

local ADMIN_WEBHOOK_URL = "https://discord.com/api/webhooks/1488980762165379213/yLjM6XIzDo0sSGiMOpFJQ8gYGs5hiDS-8bJoFzyrrh5Jw5e7EuNI2QdlzQimIZRnrpFW"
local BOSS_WEBHOOK_URL = "https://discord.com/api/webhooks/1488994023652724736/szzJf00-CBHsvW0AIWqzy4N1P3QZaDr0SULPXcduiCLEwJ67Pju1DF7bcsxwhUhwvQwW"

local function SendToDiscord(webhookUrl, embedData, contentText)
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

	local jsonData = HttpService:JSONEncode(payload)

	task.spawn(function()
		local success, err = pcall(function()
			HttpService:PostAsync(webhookUrl, jsonData, Enum.HttpContentType.ApplicationJson)
		end)
		if not success then
			warn("Failed to send log to Discord: " .. tostring(err))
		end
	end)
end

AdminLogger.Event:Connect(function(logType, logData)
	local embed = {
		["title"] = "📋 " .. logType .. " Log",
		["timestamp"] = DateTime.now():ToIsoDate(),
		["color"] = 0xFFFFFF,
		["fields"] = {}
	}

	if logType == "Command" then
		embed.color = 0x3498DB
		table.insert(embed.fields, {name = "Admin", value = logData.Player, inline = true})
		table.insert(embed.fields, {name = "Command", value = logData.Command, inline = true})
		table.insert(embed.fields, {name = "Full Text", value = logData.FullText, inline = false})

	elseif logType == "Trade" then
		embed.color = 0x2ECC71
		table.insert(embed.fields, {name = "Player 1", value = logData.Player1, inline = true})
		table.insert(embed.fields, {name = "Player 2", value = logData.Player2, inline = true})
		table.insert(embed.fields, {name = logData.Player1 .. "'s Offer", value = logData.Offer1, inline = false})
		table.insert(embed.fields, {name = logData.Player2 .. "'s Offer", value = logData.Offer2, inline = false})

	elseif logType == "Purchase" then
		embed.color = 0xF1C40F
		table.insert(embed.fields, {name = "Purchaser", value = logData.Player, inline = true})
		table.insert(embed.fields, {name = "Target (Gifted To)", value = logData.Target, inline = true})
		table.insert(embed.fields, {name = "Item Purchased", value = logData.Item, inline = false})

	elseif logType == "Replacement" then
		embed.color = 0xE67E22
		table.insert(embed.fields, {name = "Player", value = logData.Player, inline = true})
		table.insert(embed.fields, {name = "Context", value = logData.Context, inline = true})
		table.insert(embed.fields, {name = "Action", value = "Replaced **" .. logData.OldItem .. "** with **" .. logData.NewItem .. "** in slot: `" .. logData.Slot .. "`", inline = false})
	end

	SendToDiscord(ADMIN_WEBHOOK_URL, embed)
end)

WorldBossLogEvent.Event:Connect(function(bossName)
	local embed = {
		["title"] = "🚨 World Boss Spawned!",
		["description"] = "**" .. bossName .. "** has just appeared in a server!\nJump in-game now to battle them!",
		["timestamp"] = DateTime.now():ToIsoDate(),
		["color"] = 0xFF0000,
	}

	SendToDiscord(BOSS_WEBHOOK_URL, embed, "<@&1488983964592111857>")
end)