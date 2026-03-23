-- @ScriptType: ModuleScript
local LeaderboardTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))

local playerCategories = {
	{Id = "Prestige", Name = "Prestiges"},
	{Id = "Endless", Name = "Endless Dungeon"},
	{Id = "PlayTime", Name = "Time Played"},
	{Id = "Elo", Name = "Arena Elo"},
	{Id = "Power", Name = "Power"},
	{Id = "RaidWins", Name = "Raid Bosses"} 
}

local gangCategories = {
	{Id = "GangRep", Name = "Reputation"},
	{Id = "GangTreasury", Name = "Treasury"},
	{Id = "GangPrestige", Name = "Total Prestige"},
	{Id = "GangElo", Name = "Total Elo"},
	{Id = "GangRaids", Name = "Raid Bosses"}
}

local currentMode = "Players"
local currentCategory = "Prestige"

local splitFrame, leftPanel, rightPanel
local modeBtn, catScroll, lbTitle, listContainer
local cachedTooltipMgr
local hoveredLbEntry = nil

local catBtnTpl, rowTpl

local function FormatNumber(n)
	local formatted = tostring(n)
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

local function FormatValue(cat, val)
	if cat == "PlayTime" then
		local hours = math.floor(val / 3600)
		local minutes = math.floor((val % 3600) / 60)
		return hours .. "h " .. minutes .. "m"
	elseif cat == "Endless" then
		return "Floor " .. val
	elseif cat == "GangTreasury" then
		return "¥" .. FormatNumber(val)
	end
	return FormatNumber(val)
end

local function RequestLeaderboard(catId)
	currentCategory = catId
	hoveredLbEntry = nil
	if cachedTooltipMgr and cachedTooltipMgr.Hide then cachedTooltipMgr.Hide() end

	for _, child in pairs(listContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
	end

	local loadingLbl = Instance.new("TextLabel")
	loadingLbl.Size = UDim2.new(1, 0, 0, 40)
	loadingLbl.BackgroundTransparency = 1
	loadingLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	loadingLbl.Font = Enum.Font.GothamMedium
	loadingLbl.TextSize = 16
	loadingLbl.Text = "Fetching data..."
	loadingLbl.Parent = listContainer

	Network.LeaderboardAction:FireServer(catId)
end

local function RenderCategoryButtons()
	for _, child in pairs(catScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local catsToRender = (currentMode == "Players") and playerCategories or gangCategories

	for i, cat in ipairs(catsToRender) do
		local btn = catBtnTpl:Clone()
		btn.Name = "CatBtn_" .. cat.Id
		btn.LayoutOrder = i
		btn.Text = cat.Name
		btn.Parent = catScroll

		local bStr = btn:FindFirstChildOfClass("UIStroke")

		btn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			for _, child in pairs(catScroll:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
					child.TextColor3 = Color3.new(1, 1, 1)
					local cStr = child:FindFirstChildOfClass("UIStroke")
					if cStr then cStr.Color = Color3.fromRGB(120, 60, 180) end
				end
			end
			btn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
			btn.TextColor3 = Color3.fromRGB(255, 215, 0)
			if bStr then bStr.Color = Color3.fromRGB(255, 215, 0) end
			RequestLeaderboard(cat.Id)
		end)

		if cat.Id == currentCategory then
			btn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
			btn.TextColor3 = Color3.fromRGB(255, 215, 0)
			if bStr then bStr.Color = Color3.fromRGB(255, 215, 0) end
		else
			btn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
			btn.TextColor3 = Color3.new(1, 1, 1)
			if bStr then bStr.Color = Color3.fromRGB(120, 60, 180) end
		end
	end

	task.delay(0.05, function()
		local csLayout = catScroll:FindFirstChildOfClass("UIListLayout")
		if csLayout then catScroll.CanvasSize = UDim2.new(0, 0, 0, csLayout.AbsoluteContentSize.Y + 15) end
	end)
end

function LeaderboardTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr

	splitFrame = parentFrame:WaitForChild("SplitFrame")
	leftPanel = splitFrame:WaitForChild("LeftPanel")
	rightPanel = splitFrame:WaitForChild("RightPanel")

	modeBtn = leftPanel:WaitForChild("ModeBtn")
	catScroll = leftPanel:WaitForChild("CatScroll")

	lbTitle = rightPanel:WaitForChild("TitleLabel")
	listContainer = rightPanel:WaitForChild("ListContainer")

	local templates = ReplicatedStorage:WaitForChild("JJBITemplates")
	catBtnTpl = templates:WaitForChild("LeaderboardCatBtnTemplate")
	rowTpl = templates:WaitForChild("LeaderboardRowTemplate")

	modeBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if currentMode == "Players" then
			currentMode = "Gangs"
			modeBtn.Text = "SWITCH TO PLAYERS"
			currentCategory = "GangRep"
			lbTitle.Text = "TOP 100 GANGS"
		else
			currentMode = "Players"
			modeBtn.Text = "SWITCH TO GANGS"
			currentCategory = "Prestige"
			lbTitle.Text = "TOP 100 PLAYERS"
		end
		RenderCategoryButtons()
		RequestLeaderboard(currentCategory)
	end)

	Network:WaitForChild("LeaderboardUpdate").OnClientEvent:Connect(function(catId, data)
		if catId ~= currentCategory then return end

		for _, child in pairs(listContainer:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
		end

		local myRankStr = "Unranked"
		local targetName = (currentMode == "Players") and player.Name or (player:GetAttribute("Gang") or "None")

		for _, entry in ipairs(data) do
			if string.lower(entry.Name) == string.lower(targetName) and targetName ~= "None" then
				myRankStr = "#" .. entry.Rank
				break
			end
		end

		local titlePrefix = (currentMode == "Players") and "TOP 100 PLAYERS" or "TOP 100 GANGS"
		lbTitle.Text = titlePrefix .. " <font color='#AAAAAA' size='14'>(Your Rank: " .. myRankStr .. ")</font>"

		if #data == 0 then
			local emptyLbl = Instance.new("TextLabel")
			emptyLbl.Size = UDim2.new(1, 0, 0, 40)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
			emptyLbl.Font = Enum.Font.GothamMedium
			emptyLbl.TextSize = 16
			emptyLbl.Text = "No data yet."
			emptyLbl.Parent = listContainer
			return
		end

		for i, entry in ipairs(data) do
			local row = rowTpl:Clone()
			row.Name = "Row_" .. entry.Rank
			row.LayoutOrder = entry.Rank
			row.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(35, 25, 45) or Color3.fromRGB(25, 15, 35)
			row.Parent = listContainer

			local rankLbl = row:WaitForChild("RankLbl")
			local avatarImg = row:WaitForChild("AvatarImg")
			local nameLbl = row:WaitForChild("NameLbl")
			local valLbl = row:WaitForChild("ValueLbl")

			local rankColor = Color3.new(0.9, 0.9, 0.9)
			if entry.Rank == 1 then rankColor = Color3.fromRGB(255, 215, 0)
			elseif entry.Rank == 2 then rankColor = Color3.fromRGB(192, 192, 192)
			elseif entry.Rank == 3 then rankColor = Color3.fromRGB(205, 127, 50) end

			rankLbl.TextColor3 = rankColor
			rankLbl.Text = "#" .. entry.Rank

			local hasIcon = false
			if currentMode == "Players" then
				avatarImg.Image = entry.Profile and entry.Profile.Icon or ""
				hasIcon = true
			else
				if entry.Profile and entry.Profile.Emblem and entry.Profile.Emblem ~= "" then
					local emblemStr = entry.Profile.Emblem
					if tonumber(emblemStr) then
						emblemStr = "rbxassetid://" .. emblemStr
					end
					avatarImg.Image = emblemStr
					hasIcon = true
				else
					avatarImg.Visible = false
				end
			end

			valLbl.Text = FormatValue(catId, entry.Value)
			nameLbl.TextColor3 = rankColor
			nameLbl.Text = entry.Name

			if hasIcon then
				nameLbl.Size = UDim2.new(0.70, -95, 1, 0)
				nameLbl.Position = UDim2.new(0, 85, 0, 0)
			else
				nameLbl.Size = UDim2.new(0.70, -60, 1, 0)
				nameLbl.Position = UDim2.new(0, 50, 0, 0)
			end

			row.MouseEnter:Connect(function()
				if not entry.Profile then return end
				hoveredLbEntry = entry.Name

				local desc = ""
				if currentMode == "Players" then
					desc = string.format("<b><font color='#A020F0'>%s</font></b>\n____________________\n\n", entry.Name)
					desc ..= "<font color='#FFD700'>Prestige:</font> " .. FormatNumber(entry.Profile.Prestige) .. "\n"
					desc ..= "<font color='#55FF55'>Power Level:</font> " .. FormatNumber(entry.Profile.Power) .. "\n"
					desc ..= "<font color='#FF5555'>Arena Elo:</font> " .. FormatNumber(entry.Profile.Elo) .. "\n"
					desc ..= "<font color='#55FFFF'>Endless Floor:</font> " .. FormatNumber(entry.Profile.Endless) .. "\n"
					desc ..= "<font color='#FF8C00'>Raid Bosses:</font> " .. FormatNumber(entry.Profile.RaidWins) .. "\n"
					desc ..= "<font color='#AAAAAA'>Playtime:</font> " .. FormatValue("PlayTime", entry.Profile.PlayTime)
				else
					local cleanMotto = entry.Profile.Motto or "No motto set."
					desc = string.format("<b><font color='#A020F0'>%s</font></b>\n<i>%s</i>\n____________________\n\n", entry.Name, cleanMotto)
					desc ..= "<font color='#A020F0'>Reputation:</font> " .. FormatNumber(entry.Profile.Rep) .. "\n"
					desc ..= "<font color='#55FF55'>Treasury:</font> ¥" .. FormatNumber(entry.Profile.Treasury) .. "\n"
					desc ..= "<font color='#FFD700'>Total Prestige:</font> " .. FormatNumber(entry.Profile.Prestige) .. "\n"
					desc ..= "<font color='#FF5555'>Total Elo:</font> " .. FormatNumber(entry.Profile.Elo) .. "\n"
					desc ..= "<font color='#FF8C00'>Raid Bosses:</font> " .. FormatNumber(entry.Profile.RaidWins)
				end

				cachedTooltipMgr.Show(desc)
			end)

			row.MouseLeave:Connect(function()
				if hoveredLbEntry == entry.Name then
					hoveredLbEntry = nil
					if cachedTooltipMgr and cachedTooltipMgr.Hide then
						cachedTooltipMgr.Hide()
					end
				end
			end)
		end

		task.delay(0.05, function()
			local lcLayout = listContainer:FindFirstChildOfClass("UIListLayout")
			if lcLayout then
				listContainer.CanvasSize = UDim2.new(0, 0, 0, lcLayout.AbsoluteContentSize.Y + 10)
			end
		end)
	end)

	RenderCategoryButtons()
	task.delay(1, function() RequestLeaderboard(currentCategory) end)
end

return LeaderboardTab