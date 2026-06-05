-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local eventsUI = playerGui:WaitForChild("CommunityEventsUI")
local eventText = eventsUI:WaitForChild("EventText")
local adminBtn = eventsUI:WaitForChild("AdminStartNowButton")

local durationInput = eventsUI:WaitForChild("DurationInput")

local Network = ReplicatedStorage:WaitForChild("Network")
local AdminEventRemote = Network:WaitForChild("AdminEventAction")

local EVENT_NAMES = {
	["DropRate"] = "Items drop chance",
	["Yen"] = "Yen earnings boost",
	["XP"] = "Experience boost",
	["Luck"] = "Universal Luck boost"
}

local EventAdmins = {
	[82860902] = true,
	[950762580] = true,
	[342662401] = true
}

local isAdmin = false

local function CheckActiveEvents()
	local activeType = nil
	local activeMult = 1
	local activeEnd = 0

	for name, value in pairs(ReplicatedStorage:GetAttributes()) do
		if string.sub(name, 1, 12) == "GlobalEvent_" and not string.find(name, "End") then
			activeType = string.sub(name, 13)
			activeMult = value
			activeEnd = ReplicatedStorage:GetAttribute("GlobalEventEnd_" .. activeType) or 0
			break
		end
	end

	if activeType then
		local displayName = EVENT_NAMES[activeType] or (activeType .. " boost")
		local dateString = os.date("%d/%m/%Y", activeEnd)

		eventText.Text = string.format("Weekend event!\n\n%sx %s\n\n\n ends %s", tostring(activeMult), displayName, dateString)

		eventText.Visible = true
		adminBtn.Visible = false
		durationInput.Visible = false
	else
		eventText.Visible = false

		if isAdmin then
			adminBtn.Visible = true
			durationInput.Visible = true
		else
			adminBtn.Visible = false
			durationInput.Visible = false
		end
	end
end

if EventAdmins[player.UserId] then
	isAdmin = true
end

adminBtn.Visible = false
durationInput.Visible = false
CheckActiveEvents()

adminBtn.MouseButton1Click:Connect(function()
	adminBtn.Text = "STARTING..."
	adminBtn.Active = false

	local inputHours = tonumber(durationInput.Text)

	if not inputHours or inputHours <= 0 then
		inputHours = 4
	end

	local now = os.time()
	local durationSeconds = math.floor(inputHours * 3600)

	AdminEventRemote:FireServer("CreateEvent", {
		Type = "DropRate",
		Mult = 2,
		Start = now,
		End = now + durationSeconds
	})

	task.delay(2, function()
		adminBtn.Text = "START EVENT NOW"
		adminBtn.Active = true
		durationInput.Text = ""
	end)
end)

ReplicatedStorage.AttributeChanged:Connect(function(attrName)
	if string.sub(attrName, 1, 12) == "GlobalEvent_" then
		CheckActiveEvents()
	end
end)