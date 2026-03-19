-- @ScriptType: ModuleScript
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
local listContainer, catScroll, lbTitle
local cachedTooltipMgr
local hoveredLbEntry = nil

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

local function CreateCard(name, parent, size, pos)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	if pos then frame.Position = pos end
	frame.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	frame.ZIndex = 20
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(90, 50, 120)
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	return frame
end

function LeaderboardTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr

	-- Top level layout
	local splitFrame = Instance.new("Frame")
	splitFrame.Name = "SplitFrame"
	splitFrame.Size = UDim2.new(1, 0, 1, 0)
	splitFrame.BackgroundTransparency = 1
	splitFrame.Parent = parentFrame

	-- LEFT PANEL (Categories)
	local leftPanel = CreateCard("LeftPanel", splitFrame, UDim2.new(0.28, 0, 1, 0), UDim2.new(0, 0, 0, 0))
	local lpPad = Instance.new("UIPadding")
	lpPad.PaddingTop = UDim.new(0, 10); lpPad.PaddingBottom = UDim.new(0, 10)
	lpPad.PaddingLeft = UDim.new(0, 10); lpPad.PaddingRight = UDim.new(0, 10)
	lpPad.Parent = leftPanel

	local lpLayout = Instance.new("UIListLayout")
	lpLayout.FillDirection = Enum.FillDirection.Vertical
	lpLayout.SortOrder = Enum.SortOrder.LayoutOrder
	lpLayout.Padding = UDim.new(0, 10)
	lpLayout.Parent = leftPanel

	local modeBtn = Instance.new("TextButton")
	modeBtn.Name = "ModeBtn"
	modeBtn.LayoutOrder = 1
	modeBtn.Size = UDim2.new(1, 0, 0, 45)
	modeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	modeBtn.Font = Enum.Font.GothamBlack
	modeBtn.TextColor3 = Color3.new(1, 1, 1)
	modeBtn.TextScaled = true
	modeBtn.Text = "SWITCH TO GANGS"
	modeBtn.ZIndex = 21
	modeBtn.Parent = leftPanel

	local mbCorner = Instance.new("UICorner")
	mbCorner.CornerRadius = UDim.new(0, 6)
	mbCorner.Parent = modeBtn

	local mbStroke = Instance.new("UIStroke")
	mbStroke.Color = Color3.fromRGB(255, 100, 100)
	mbStroke.Thickness = 2
	mbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	mbStroke.Parent = modeBtn

	local mbUic = Instance.new("UITextSizeConstraint")
	mbUic.MaxTextSize = 16
	mbUic.Parent = modeBtn

	catScroll = Instance.new("ScrollingFrame")
	catScroll.Name = "CatScroll"
	catScroll.LayoutOrder = 2
	catScroll.Size = UDim2.new(1, 0, 1, -55)
	catScroll.BackgroundTransparency = 1
	catScroll.ScrollBarThickness = 4
	catScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	catScroll.ZIndex = 21
	catScroll.Parent = leftPanel

	local csPad = Instance.new("UIPadding")
	csPad.PaddingTop = UDim.new(0, 3)
	csPad.PaddingBottom = UDim.new(0, 3)
	csPad.PaddingLeft = UDim.new(0, 3)
	csPad.PaddingRight = UDim.new(0, 8)
	csPad.Parent = catScroll

	local csLayout = Instance.new("UIListLayout")
	csLayout.FillDirection = Enum.FillDirection.Vertical
	csLayout.SortOrder = Enum.SortOrder.LayoutOrder
	csLayout.Padding = UDim.new(0, 8)
	csLayout.Parent = catScroll

	-- RIGHT PANEL (List)
	local rightPanel = CreateCard("RightPanel", splitFrame, UDim2.new(0.70, 0, 1, 0), UDim2.new(0.30, 0, 0, 0))
	local rpPad = Instance.new("UIPadding")
	rpPad.PaddingTop = UDim.new(0, 10); rpPad.PaddingBottom = UDim.new(0, 10)
	rpPad.PaddingLeft = UDim.new(0, 10); rpPad.PaddingRight = UDim.new(0, 10)
	rpPad.Parent = rightPanel

	lbTitle = Instance.new("TextLabel")
	lbTitle.Name = "TitleLabel"
	lbTitle.Size = UDim2.new(1, 0, 0, 30)
	lbTitle.Position = UDim2.new(0, 0, 0, 0)
	lbTitle.BackgroundTransparency = 1
	lbTitle.Font = Enum.Font.GothamBlack
	lbTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	lbTitle.TextScaled = true
	lbTitle.RichText = true
	lbTitle.Text = "TOP 100 PLAYERS"
	lbTitle.TextXAlignment = Enum.TextXAlignment.Left
	lbTitle.ZIndex = 22
	lbTitle.Parent = rightPanel

	local ltUic = Instance.new("UITextSizeConstraint")
	ltUic.MaxTextSize = 24
	ltUic.Parent = lbTitle

	listContainer = Instance.new("ScrollingFrame")
	listContainer.Name = "ListContainer"
	listContainer.Size = UDim2.new(1, 0, 1, -40)
	listContainer.Position = UDim2.new(0, 0, 0, 40)
	listContainer.BackgroundTransparency = 1
	listContainer.ScrollBarThickness = 6
	listContainer.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	listContainer.ZIndex = 21
	listContainer.Parent = rightPanel

	local lcPad = Instance.new("UIPadding")
	lcPad.PaddingRight = UDim.new(0, 8)
	lcPad.Parent = listContainer

	local lcLayout = Instance.new("UIListLayout")
	lcLayout.FillDirection = Enum.FillDirection.Vertical
	lcLayout.SortOrder = Enum.SortOrder.LayoutOrder
	lcLayout.Padding = UDim.new(0, 5)
	lcLayout.Parent = listContainer

	local function RequestLeaderboard(catId)
		currentCategory = catId
		hoveredLbEntry = nil
		if cachedTooltipMgr and cachedTooltipMgr.Hide then cachedTooltipMgr.Hide() end

		for _, child in pairs(listContainer:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
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
			local btn = Instance.new("TextButton")
			btn.Name = "CatBtn_" .. cat.Id
			btn.LayoutOrder = i
			btn.Size = UDim2.new(1, 0, 0, 40)
			btn.Font = Enum.Font.GothamBold
			btn.TextScaled = true
			btn.Text = cat.Name
			btn.ZIndex = 22
			btn.Parent = catScroll

			local bCorner = Instance.new("UICorner")
			bCorner.CornerRadius = UDim.new(0, 6)
			bCorner.Parent = btn

			local bStr = Instance.new("UIStroke")
			bStr.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			bStr.Parent = btn

			local bUic = Instance.new("UITextSizeConstraint")
			bUic.MaxTextSize = 14
			bUic.Parent = btn

			btn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				for _, child in pairs(catScroll:GetChildren()) do
					if child:IsA("TextButton") then
						child.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
						child.TextColor3 = Color3.new(1, 1, 1)
						child:FindFirstChild("UIStroke").Color = Color3.fromRGB(120, 60, 180)
					end
				end
				btn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
				btn.TextColor3 = Color3.fromRGB(255, 215, 0)
				bStr.Color = Color3.fromRGB(255, 215, 0)
				RequestLeaderboard(cat.Id)
			end)

			if cat.Id == currentCategory then
				btn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
				btn.TextColor3 = Color3.fromRGB(255, 215, 0)
				bStr.Color = Color3.fromRGB(255, 215, 0)
			else
				btn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
				btn.TextColor3 = Color3.new(1, 1, 1)
				bStr.Color = Color3.fromRGB(120, 60, 180)
			end
		end
		task.delay(0.05, function()
			catScroll.CanvasSize = UDim2.new(0, 0, 0, csLayout.AbsoluteContentSize.Y + 15)
		end)
	end

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
			local row = Instance.new("Frame")
			row.Name = "Row_" .. entry.Rank
			row.LayoutOrder = entry.Rank
			row.Size = UDim2.new(1, 0, 0, 40)
			row.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(35, 25, 45) or Color3.fromRGB(25, 15, 35)
			row.BorderSizePixel = 0
			row.ZIndex = 22
			row.Parent = listContainer

			local rCorner = Instance.new("UICorner")
			rCorner.CornerRadius = UDim.new(0, 6)
			rCorner.Parent = row

			local rankColor = Color3.new(0.9, 0.9, 0.9)
			if entry.Rank == 1 then rankColor = Color3.fromRGB(255, 215, 0)
			elseif entry.Rank == 2 then rankColor = Color3.fromRGB(192, 192, 192)
			elseif entry.Rank == 3 then rankColor = Color3.fromRGB(205, 127, 50) end

			-- Rank Label: Fixed width to completely avoid crushing the icon
			local rankLbl = Instance.new("TextLabel")
			rankLbl.Size = UDim2.new(0, 40, 1, 0)
			rankLbl.Position = UDim2.new(0, 10, 0, 0)
			rankLbl.BackgroundTransparency = 1
			rankLbl.Font = Enum.Font.GothamBlack
			rankLbl.TextColor3 = rankColor
			rankLbl.TextScaled = true
			rankLbl.Text = "#" .. entry.Rank
			rankLbl.TextXAlignment = Enum.TextXAlignment.Left
			rankLbl.ZIndex = 23
			rankLbl.Parent = row
			Instance.new("UITextSizeConstraint", rankLbl).MaxTextSize = 18

			local hasIcon = false
			local iconImg = Instance.new("ImageLabel")
			iconImg.Size = UDim2.new(0, 28, 0, 28)
			iconImg.Position = UDim2.new(0, 50, 0.5, 0)
			iconImg.AnchorPoint = Vector2.new(0, 0.5)
			iconImg.BackgroundTransparency = 1
			iconImg.ScaleType = Enum.ScaleType.Fit
			iconImg.ZIndex = 23
			iconImg.Parent = row
			Instance.new("UICorner", iconImg).CornerRadius = UDim.new(1, 0)

			if currentMode == "Players" then
				iconImg.Image = entry.Profile and entry.Profile.Icon or ""
				hasIcon = true
			else
				if entry.Profile and entry.Profile.Emblem and entry.Profile.Emblem ~= "" then
					local emblemStr = entry.Profile.Emblem
					-- If players input raw ID instead of rbxassetid://
					if tonumber(emblemStr) then
						emblemStr = "rbxassetid://" .. emblemStr
					end
					iconImg.Image = emblemStr
					hasIcon = true
				else
					iconImg.Visible = false
				end
			end

			-- Value Label: Anchored tightly to the right side (takes exactly 30% space)
			local valLbl = Instance.new("TextLabel")
			valLbl.Size = UDim2.new(0.30, 0, 1, 0)
			valLbl.Position = UDim2.new(1, -10, 0, 0)
			valLbl.AnchorPoint = Vector2.new(1, 0)
			valLbl.BackgroundTransparency = 1
			valLbl.Font = Enum.Font.GothamMedium
			valLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
			valLbl.TextScaled = true
			valLbl.Text = FormatValue(catId, entry.Value)
			valLbl.TextXAlignment = Enum.TextXAlignment.Right
			valLbl.ZIndex = 23
			valLbl.Parent = row
			Instance.new("UITextSizeConstraint", valLbl).MaxTextSize = 16

			-- Name Label: Dynamically stretches exactly from the end of the icon up to the start of the Value
			local nameLbl = Instance.new("TextLabel")
			nameLbl.Size = hasIcon and UDim2.new(0.70, -95, 1, 0) or UDim2.new(0.70, -60, 1, 0)
			nameLbl.Position = hasIcon and UDim2.new(0, 85, 0, 0) or UDim2.new(0, 50, 0, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextColor3 = rankColor
			nameLbl.TextScaled = true
			nameLbl.Text = entry.Name
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.ZIndex = 23
			nameLbl.Parent = row
			Instance.new("UITextSizeConstraint", nameLbl).MaxTextSize = 16

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
			listContainer.CanvasSize = UDim2.new(0, 0, 0, lcLayout.AbsoluteContentSize.Y + 10)
		end)
	end)

	RenderCategoryButtons()
	task.delay(1, function() RequestLeaderboard(currentCategory) end)
end

return LeaderboardTab