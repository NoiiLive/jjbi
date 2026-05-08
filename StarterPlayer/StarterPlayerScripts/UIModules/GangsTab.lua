-- @ScriptType: ModuleScript
local GangsTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local LeaderBoardAction: RemoteEvent = Network:WaitForChild("GangLeaderboardAction")

local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local CombatTemplate = require(UIModules:WaitForChild("CombatTemplate"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))
local JJBITemplates = ReplicatedStorage:WaitForChild("JJBITemplates")
local LeaderBoardTemplate = JJBITemplates:WaitForChild("GangLeaderboardTemplate")

local ShopModule = require(script.Parent:WaitForChild("GangShopTab"))

local GangUpdate = Network:WaitForChild("GangUpdate")

local mainContainer, noGangContainer, hasGangContainer, pagesContainer, tabContainer
local infoPage, upgPage, ordPage, settingsPage, shopPage, bossPage
local titleLabel, mottoLabel, emblemImage, repLabel, infoTreasuryLabel, upgTreasuryLabel, levelLabel, joinModeBtn
local membersList, browserList, requestsList, buildingList, ordersList
local membersCard, requestsCard, settingsCard
local leaveBtn, boostsBtn, donateInput, donateBtn, ordersTimerLbl
local reqInput, reqBtn
local seasonList
local weeklyList

local engageBossBtn
local combatUI
local activeFighters = {}
local resourceLabel, turnLabel
local inBattle = false

local currentLog = ""
local function AddLog(text, append)
	if append then currentLog = currentLog .. "\n" .. text else currentLog = text end
	if combatUI then combatUI:Log(currentLog) end
end

local pendingLeave = false
local currentBoostText = "Loading boosts..."
local cachedTooltipMgr = nil
local lastOrderResetTime = 0

local activeUpgradeFinishTime = 0
local activeUpgradeBtnRef = nil

local RolePower = { ["Grunt"] = 1, ["Caporegime"] = 2, ["Consigliere"] = 3, ["Boss"] = 4 }
local RoleColors = { ["Grunt"] = "#AAAAAA", ["Caporegime"] = "#55FF55", ["Consigliere"] = "#FF55FF", ["Boss"] = "#FFD700" }

local memTemplate, reqTemplate, buildTpl, ordTpl, brTemplate

local function GetGangLevel(rep)
	if rep >= 100000 then return 5 end
	if rep >= 50000 then return 4 end
	if rep >= 10000 then return 3 end
	if rep >= 5000 then return 2 end
	if rep >= 1000 then return 1 end
	return 0
end

local function GetBoostText(buildings)
	local b = buildings or {}
	local v = b.Vault or 0
	local d = b.Dojo or 0
	local m = b.Market or 0
	local s = b.Shrine or 0
	local a = b.Armory or 0

	return "<b><font color='#FFD700'>GANG BUILDING BOOSTS</font></b>\n____________________\n\n" ..
		"<font color='#55FF55'>Vault (Lv."..v.."): +"..(v*5).."% Yen</font>\n" ..
		"<font color='#55FFFF'>Training Hall (Lv."..d.."): +"..(d*5).."% XP</font>\n" ..
		"<font color='#AA00AA'>Black Market (Lv."..m.."): +"..(m*5).." Inv Slots</font>\n" ..
		"<font color='#FFD700'>Saint's Church (Lv."..s.."): +"..(s).." Luck</font>\n" ..
		"<font color='#FF5555'>Armory (Lv."..a.."): +"..(a*5).."% Damage</font>"
end

local function FormatTimeAgo(timestamp)
	if not timestamp then return "<font color='#AAAAAA'>Offline: Unknown</font>" end
	local diff = math.floor(workspace:GetServerTimeNow()) - timestamp
	if diff < 300 then return "<font color='#55FF55'>Online</font>" end 
	if diff < 3600 then return "<font color='#AAAAAA'>Offline: " .. math.floor(diff / 60) .. "m</font>"
	elseif diff < 86400 then return "<font color='#AAAAAA'>Offline: " .. math.floor(diff / 3600) .. "h</font>"
	else
		local days = math.floor(diff / 86400)
		local color = days >= 3 and "#FF5555" or "#AAAAAA" 
		return "<font color='" .. color .. "'>Offline: " .. days .. "d</font>"
	end
end

local function FormatNumber(n)
	local formatted = tostring(n)
	while true do
		local k
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return formatted
end

local function FormatPlayTime(seconds)
	local s = tonumber(seconds) or 0
	local hours = math.floor(s / 3600)
	local mins = math.floor((s % 3600) / 60)
	return hours .. "h " .. mins .. "m"
end

local function UpdateTabSizes()
	local visibleTabs = 0
	if not tabContainer then return end
	for _, btn in ipairs(tabContainer:GetChildren()) do
		if btn:IsA("TextButton") and btn.Visible then
			visibleTabs += 1
		end
	end
	if visibleTabs <= 0 then visibleTabs = 1 end
	local sizeScale = (1 / visibleTabs) - 0.02
	for _, btn in ipairs(tabContainer:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.Size = UDim2.new(sizeScale, 0, 1, 0)
		end
	end
end

local function SelectTab(tabName)
	SFXManager.Play("Click")
	if infoPage then infoPage.Visible = (tabName == "Info") end
	if upgPage then upgPage.Visible = (tabName == "Upgrades") end
	if ordPage then ordPage.Visible = (tabName == "Orders") end
	if settingsPage then settingsPage.Visible = (tabName == "Settings") end
	if shopPage then shopPage.Visible = (tabName == "GangShop") end
	if bossPage then bossPage.Visible = (tabName == "Boss") end
	if tabContainer then
		for _, btn in ipairs(tabContainer:GetChildren()) do
			if btn:IsA("TextButton") then
				local isSel = (btn.Name == "Btn" .. tabName) or (tabName == "GangShop" and btn.Name == "BtnShop")
				btn.BackgroundColor3 = isSel and Color3.fromRGB(90, 40, 140) or Color3.fromRGB(35, 25, 45)
				btn.TextColor3 = isSel and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
				local str = btn:FindFirstChildOfClass("UIStroke")
				if str then
					str.Color = isSel and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(90, 50, 120)
					str.Thickness = isSel and 2 or 1
				end
			end
		end
	end
end


function GangsTab.Init(parentFrame, tooltipMgr, focusFunc)
	mainContainer = parentFrame
	cachedTooltipMgr = tooltipMgr

	local templates = ReplicatedStorage:WaitForChild("JJBITemplates")
	memTemplate = templates:WaitForChild("GangMemberTemplate")
	reqTemplate = templates:WaitForChild("GangRequestTemplate")
	buildTpl = templates:WaitForChild("GangBuildingTemplate")
	ordTpl = templates:WaitForChild("GangOrderTemplate")
	brTemplate = templates:WaitForChild("GangBrowserTemplate")

	noGangContainer = mainContainer:WaitForChild("NoGangContainer")
	local createCard = noGangContainer:WaitForChild("CreateCard")
	local nameInput = createCard:WaitForChild("NameInput")
	local createBtn = createCard:WaitForChild("CreateBtn")

	createBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if nameInput.Text and string.len(nameInput.Text) >= 3 then Network.GangAction:FireServer("Create", nameInput.Text) end
	end)

	local browseCard = noGangContainer:WaitForChild("BrowseCard")
	local refreshBtn = browseCard:WaitForChild("RefreshBtn")
	local searchInput = browseCard:WaitForChild("SearchInput")
	local searchBtn = browseCard:WaitForChild("SearchBtn")
	browserList = browseCard:WaitForChild("BrowserList")

	refreshBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("BrowseGangs") end)
	searchBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if searchInput.Text and string.len(searchInput.Text) >= 3 then Network.GangAction:FireServer("SearchGang", searchInput.Text) end
	end)

	hasGangContainer = mainContainer:WaitForChild("HasGangContainer")
	tabContainer = hasGangContainer:WaitForChild("TabContainer")

	local btnInfo = tabContainer:WaitForChild("BtnInfo")
	local btnUpg = tabContainer:WaitForChild("BtnUpgrades")
	local btnOrd = tabContainer:WaitForChild("BtnOrders")
	local btnSet = tabContainer:WaitForChild("BtnSettings")
	local btnShop = tabContainer:WaitForChild("BtnShop")
	local btnBoss = tabContainer:WaitForChild("BtnBoss")


	btnInfo.MouseButton1Click:Connect(function() SelectTab("Info") end)
	btnBoss.MouseButton1Click:Connect(function() SelectTab("Boss") end)
	btnUpg.MouseButton1Click:Connect(function() SelectTab("Upgrades") end)
	btnOrd.MouseButton1Click:Connect(function() SelectTab("Orders") end)
	btnSet.MouseButton1Click:Connect(function() SelectTab("Settings") end)
	btnShop.MouseButton1Click:Connect(function() SelectTab("GangShop") end)

	pagesContainer = hasGangContainer:WaitForChild("PagesContainer")
	
	infoPage = pagesContainer:WaitForChild("InfoPage")
	local headerCard = infoPage:WaitForChild("HeaderCard")
	bossPage = pagesContainer:WaitForChild("BossPage")
	local bossHeaderCard = bossPage:WaitForChild("HeaderCard")
	emblemImage = headerCard:WaitForChild("EmblemImage")
	local infoBox = headerCard:WaitForChild("InfoBox")
	titleLabel = infoBox:WaitForChild("TitleLabel")
	levelLabel = infoBox:WaitForChild("LevelLabel")
	mottoLabel = infoBox:WaitForChild("MottoLabel")
	local repBg = infoBox:WaitForChild("RepBg")
	repLabel = repBg:WaitForChild("RepLabel")
	infoTreasuryLabel = infoBox:WaitForChild("TreasuryLabel")
	leaveBtn = infoBox:WaitForChild("LeaveBtn")
	engageBossBtn = bossHeaderCard:WaitForChild("EngageGangBoss") 
	
	local dualBossContainer = bossPage:WaitForChild("DualContainer")

	local seasonCard = dualBossContainer:WaitForChild("SeasonCard")
	local weeklyCard = dualBossContainer:WaitForChild("WeeklyCard")

	seasonList = seasonCard:WaitForChild("MembersList")
	weeklyList = weeklyCard:WaitForChild("MembersList")
	
	combatUI = CombatTemplate.Create(parentFrame, cachedTooltipMgr)
	combatUI.MainFrame.Visible = false
	combatUI.MainFrame.ZIndex = 40

	local playerGui = player:WaitForChild("PlayerGui")
	local jjbMenu = playerGui:WaitForChild("JJBIMenu")
	local mainFrame = jjbMenu:WaitForChild("MainFrame")
	local navBar = mainFrame:WaitForChild("NavBar")
	
	local templates = ReplicatedStorage:WaitForChild("JJBITemplates")
	local wbControls = templates:WaitForChild("WorldBossControlsTemplate")

	turnLabel = wbControls:WaitForChild("TurnLabel"):Clone()
	turnLabel.Parent = combatUI.MainFrame

	resourceLabel = wbControls:WaitForChild("ResourceLabel"):Clone()
	resourceLabel.Parent = combatUI.ContentContainer
	resourceLabel.Visible = false
	
	engageBossBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		Network:WaitForChild("GangBossAction"):FireServer("Engage")
	end)
	
	leaveBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local isBoss = (player:GetAttribute("GangRole") == "Boss" or player:GetAttribute("GangRole") == "Owner")
		local origText = isBoss and "Disband Gang" or "Leave Gang"
		if pendingLeave then
			pendingLeave = false; leaveBtn.Text = origText
			if isBoss then Network.GangAction:FireServer("Disband") else Network.GangAction:FireServer("Leave") end
		else
			pendingLeave = true; leaveBtn.Text = isBoss and "Confirm Disband?" or "Confirm Leave?"
			task.delay(3, function() if pendingLeave then pendingLeave = false; leaveBtn.Text = origText end end)
		end
	end)

	local dualContainer = infoPage:WaitForChild("DualContainer")
	membersCard = dualContainer:WaitForChild("MembersCard")
	membersList = membersCard:WaitForChild("MembersList")
	requestsCard = dualContainer:WaitForChild("RequestsCard")
	requestsList = requestsCard:WaitForChild("RequestsList")

	upgPage = pagesContainer:WaitForChild("UpgradesPage")
	local donationCard = upgPage:WaitForChild("DonationCard")
	upgTreasuryLabel = donationCard:WaitForChild("TreasuryLabel")
	donateInput = donationCard:WaitForChild("DonateInput")
	donateBtn = donationCard:WaitForChild("DonateBtn")
	boostsBtn = donationCard:WaitForChild("BoostsBtn")
	buildingList = upgPage:WaitForChild("BuildingList")

	donateBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local amt = tonumber(donateInput.Text)
		if amt and amt >= 1000 then Network.GangAction:FireServer("Donate", amt); donateInput.Text = "" end
	end)

	boostsBtn.MouseEnter:Connect(function() if cachedTooltipMgr and cachedTooltipMgr.Show then cachedTooltipMgr.Show(currentBoostText) end end)
	boostsBtn.MouseLeave:Connect(function() if cachedTooltipMgr and cachedTooltipMgr.Hide then cachedTooltipMgr.Hide() end end)

	ordPage = pagesContainer:WaitForChild("OrdersPage")
	ordersTimerLbl = ordPage:WaitForChild("OrdersTimerLbl")
	ordersList = ordPage:WaitForChild("OrdersList")

	settingsPage = pagesContainer:WaitForChild("SettingsPage")
	shopPage = pagesContainer:WaitForChild("ShopPage")
	settingsCard = settingsPage:WaitForChild("SetScroll")
	
	
	ShopModule.Init(shopPage)

	bossPage = pagesContainer:WaitForChild("BossPage")
	local function BindSettingsField(order, actionKey, isNumeric)
		local row = settingsCard:WaitForChild("Set_"..order)
		local input = row:WaitForChild("Input")
		local saveBtn = row:WaitForChild("UpdateBtn")

		if actionKey == "ToggleJoinMode" then
			joinModeBtn = saveBtn
			joinModeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("ToggleJoinMode") end)
		else
			saveBtn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				local val = input.Text
				if isNumeric then val = tonumber(val) end
				if val then
					Network.GangAction:FireServer(actionKey, val)
					input.Text = ""
				end
			end)
		end

		if actionKey == "UpdatePrestigeReq" then
			reqInput = input
			reqBtn = saveBtn
		end
	end

	BindSettingsField("Rename", "Rename", false)
	BindSettingsField("JoinMode", "ToggleJoinMode", false)
	BindSettingsField("Motto", "UpdateMotto", false)
	BindSettingsField("Emblem", "UpdateEmblem", false)
	BindSettingsField("PrestigeReq", "UpdatePrestigeReq", true)

	local function BindRoleField(rKey)
		local row = settingsCard:WaitForChild("SetRole_"..rKey)
		local input = row:WaitForChild("Input")
		local saveBtn = row:WaitForChild("UpdateBtn")

		saveBtn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			local val = input.Text
			if val ~= "" then
				Network.GangAction:FireServer("RenameRole", val, rKey)
				input.Text = ""
			end
		end)
	end

	BindRoleField("Boss")
	BindRoleField("Consigliere")
	BindRoleField("Caporegime")
	BindRoleField("Grunt")

	local disBtn = settingsCard:WaitForChild("DisbandBtn")
	local confirming = false
	disBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if not confirming then
			confirming = true
			disBtn.Text = "ARE YOU SURE? (Click Again)"
			disBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
			task.delay(3, function() confirming = false; if disBtn then disBtn.Text = "DISBAND GANG"; disBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40) end end)
		else
			Network.GangAction:FireServer("Disband")
		end
	end)
	
	local gangBossUpdate = Network:FindFirstChild("GangBossUpdate")
	if not gangBossUpdate then
		gangBossUpdate = Instance.new("RemoteEvent")
		gangBossUpdate.Name = "GangBossUpdate"
		gangBossUpdate.Parent = Network
	end

	gangBossUpdate.OnClientEvent:Connect(function(action, data)
		GangsTab.UpdateGangBoss(action, data)
	end)
	
	SelectTab("Info")

	GangUpdate.OnClientEvent:Connect(function(action, data)
		if action == "BrowserSync" then
			if not browserList then return end
			for _, c in pairs(browserList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			if #data == 0 then
				local empty = Instance.new("TextLabel", browserList)
				empty.Size = UDim2.new(1, 0, 0, 30)
				empty.BackgroundTransparency = 1
				empty.Text = "No gangs found."
				empty.Font = Enum.Font.GothamMedium
				empty.TextColor3 = Color3.fromRGB(150, 150, 150)
				empty.TextScaled = true
				empty.ZIndex = 22
				Instance.new("UITextSizeConstraint", empty).MaxTextSize = 14
				return
			end

			for _, g in ipairs(data) do
				local row = brTemplate:Clone()
				row.Visible = true
				row.Parent = browserList

				local emb = row:FindFirstChild("EmblemImage")
				if emb then
					emb.Image = (g.Emblem and g.Emblem ~= "" and g.Emblem ~= "0") and g.Emblem or "rbxassetid://133872443057434"
				end

				local reqText = (g.Req and g.Req > 0) and " <font color='#FFAA00'>[Pres " .. g.Req .. "+]</font>" or ""
				local gNameSafe = g.Name or "Unknown"
				row:FindFirstChild("NameLabel").Text = "<b>" .. gNameSafe .. "</b> <font size='12' color='#AAAAAA'>(" .. (g.Members or 1) .. "/30)</font>" .. reqText .. "\n<font size='12' color='#CCCCCC'><i>" .. (g.Motto or "No motto set.") .. "</i></font>"

				row:FindFirstChild("JoinBtn").Text = g.Mode == "Open" and "Join" or "Request"
				row:FindFirstChild("JoinBtn").BackgroundColor3 = g.Mode == "Open" and Color3.fromRGB(40, 140, 40) or Color3.fromRGB(200, 150, 0)
				row:FindFirstChild("JoinBtn").MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("RequestJoin", g.Name) end)
			end
			task.delay(0.05, function()
				if browserList then
					local l = browserList:FindFirstChildWhichIsA("UIListLayout")
					if l then browserList.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
				end
			end)

		elseif action == "Sync" then
			GangsTab.HandleUpdate(action, data)
		end
	end)
	
	LeaderBoardAction.OnClientEvent:Connect(function(category, data)

		local targetList

		if category == "Season" then
			targetList = seasonList
		elseif category == "Weekly" then
			targetList = weeklyList
		else
			return
		end

		if not targetList then
			return
		end


		for _, child in ipairs(targetList:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end


		for _, entry in ipairs(data) do
			local row = LeaderBoardTemplate:Clone()

			row.Visible = true
			row.Parent = targetList

			local nameLbl = row:WaitForChild("NameLbl")
			local valueLbl = row:WaitForChild("ValueLbl")

			nameLbl.Text = "#" .. tostring(entry.Rank) .. "  " .. tostring(entry.GangKey)
			valueLbl.Text = tostring(entry.Tokens)
		end


		task.defer(function()
			local layout = targetList:FindFirstChildWhichIsA("UIListLayout")

			if layout then
				targetList.CanvasSize = UDim2.new(
					0,
					0,
					0,
					layout.AbsoluteContentSize.Y + 10
				)
			end
		end)
	end)

	mainContainer:GetPropertyChangedSignal("Visible"):Connect(function()
		if mainContainer.Visible and not inBattle then 
			local gName = player:GetAttribute("Gang") or "None"
			if gName == "None" then
				if noGangContainer then noGangContainer.Visible = true end
				if hasGangContainer then hasGangContainer.Visible = false end
				Network.GangAction:FireServer("BrowseGangs")
			else
				if noGangContainer then noGangContainer.Visible = false end
				if hasGangContainer then hasGangContainer.Visible = true end
				Network.GangAction:FireServer("RequestSync")
			end
		end
	end)

	task.spawn(function()
		if mainContainer.Visible then
			local gName = player:GetAttribute("Gang") or "None"
			if gName == "None" then
				if noGangContainer then noGangContainer.Visible = true end
				if hasGangContainer then hasGangContainer.Visible = false end
				Network.GangAction:FireServer("BrowseGangs")
			else
				if noGangContainer then noGangContainer.Visible = false end
				if hasGangContainer then hasGangContainer.Visible = true end
				Network.GangAction:FireServer("RequestSync")
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			if ordPage and ordPage.Visible and lastOrderResetTime > 0 then
				local timeLeft = math.max(0, (lastOrderResetTime + 86400) - math.floor(workspace:GetServerTimeNow()))
				if timeLeft <= 0 then
					if ordersTimerLbl then ordersTimerLbl.Text = "Generating new orders..." end
				else
					local h = math.floor(timeLeft / 3600)
					local m = math.floor((timeLeft % 3600) / 60)
					local s = timeLeft % 60
					if ordersTimerLbl then ordersTimerLbl.Text = string.format("Next Orders in: %02d:%02d:%02d", h, m, s) end
				end
			end

			if upgPage and upgPage.Visible and activeUpgradeFinishTime > 0 and activeUpgradeBtnRef then
				local timeLeft = math.max(0, activeUpgradeFinishTime - math.floor(workspace:GetServerTimeNow()))
				if timeLeft <= 0 then
					activeUpgradeBtnRef.Text = "Finishing..."
				else
					local m = math.floor(timeLeft / 60)
					local s = timeLeft % 60
					activeUpgradeBtnRef.Text = string.format("Upgrading (%02d:%02d)", m, s)
				end
			end
		end
	end)

	LeaderBoardAction:FireServer("Weekly")
	LeaderBoardAction:FireServer("Season")
end

function GangsTab.HandleUpdate(action, data)
	if type(data) ~= "table" then return end

	if data.HasGang == false then
		if hasGangContainer then hasGangContainer.Visible = false end
		if noGangContainer then noGangContainer.Visible = true end
		if titleLabel then titleLabel.Text = "LOADING..." end
		if mottoLabel then mottoLabel.Text = "<i>...</i>" end
		if emblemImage then emblemImage.Image = "" end
		lastOrderResetTime = 0
		activeUpgradeFinishTime = 0
		activeUpgradeBtnRef = nil
		if membersList then for _, c in pairs(membersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end end
		if requestsList then for _, c in pairs(requestsList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end end
		if buildingList then for _, c in pairs(buildingList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end end
		if ordersList then for _, c in pairs(ordersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end end
		return
	end

	local gData = data.GangData
	if type(gData) ~= "table" then gData = data end
	if type(gData) ~= "table" or not gData.Name then return end

	if not inBattle then
		if noGangContainer then noGangContainer.Visible = false end
		if hasGangContainer then hasGangContainer.Visible = true end
	end

	local myRole = data.MyRole or gData.MyRole or "Grunt"
	local myPower = RolePower[myRole] or 1

	if tabContainer then
		local settingsTabBtn = tabContainer:FindFirstChild("BtnSettings")
		if settingsTabBtn then
			settingsTabBtn.Visible = (myRole == "Boss")
			UpdateTabSizes()
		end
	end

	if settingsPage and settingsPage.Visible and myRole ~= "Boss" then
		if tabContainer then
			for _, btn in ipairs(tabContainer:GetChildren()) do
				if btn:IsA("TextButton") then
					local isSel = (btn.Name == "BtnInfo")
					btn.BackgroundColor3 = isSel and Color3.fromRGB(90, 40, 140) or Color3.fromRGB(35, 25, 45)
					btn.TextColor3 = isSel and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
					local str = btn:FindFirstChildOfClass("UIStroke")
					if str then
						str.Color = isSel and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(90, 50, 120)
						str.Thickness = isSel and 2 or 1
					end
				end
			end
		end
		if infoPage then infoPage.Visible = true end
		if upgPage then upgPage.Visible = false end
		if ordPage then ordPage.Visible = false end
		if settingsPage then settingsPage.Visible = false end
	end

	if titleLabel then titleLabel.Text = tostring(gData.Name):upper() .. " <font size='16' color='#AAAAAA'>(" .. (gData.MemberCount or 1) .. "/30)</font>" end
	if mottoLabel then mottoLabel.Text = "<i>" .. (gData.Motto or "No motto set.") .. "</i>" end
	if repLabel then repLabel.Text = "Reputation: <b><font color='#A020F0'>" .. FormatNumber(gData.Rep or 0) .. "</font></b>" end

	if reqInput then reqInput.PlaceholderText = "Current Req: " .. tostring(gData.PrestigeReq or 0) end
	lastOrderResetTime = gData.LastOrderReset or 0

	if emblemImage then
		if gData.Emblem and gData.Emblem ~= "" then
			emblemImage.Image = gData.Emblem
			emblemImage.Visible = true
		else
			emblemImage.Visible = false
		end
	end

	local level = GetGangLevel(gData.Rep or 0)
	currentBoostText = GetBoostText(gData.Buildings)
	if levelLabel then levelLabel.Text = "<b>Lv. " .. level .. "</b>" end

	if infoTreasuryLabel then infoTreasuryLabel.Text = "Treasury: <b>¥" .. FormatNumber(gData.Treasury or 0) .. "</b>" end
	if upgTreasuryLabel then upgTreasuryLabel.Text = "Treasury: <b>¥" .. FormatNumber(gData.Treasury or 0) .. "</b>" end

	if joinModeBtn then
		if gData.JoinMode == "Open" then 
			joinModeBtn.Text = "Join: Open"; joinModeBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		else 
			joinModeBtn.Text = "Join: Request"; joinModeBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0) 
		end
	end

	local shouldShowRequests = (myPower >= RolePower["Caporegime"]) and (gData.JoinMode == "Request")
	if requestsCard then
		if shouldShowRequests then 
			requestsCard.Visible = true; 
			if membersCard then membersCard.Size = UDim2.new(0.68, 0, 1, 0) end
		else 
			requestsCard.Visible = false; 
			if membersCard then membersCard.Size = UDim2.new(1, 0, 1, 0) end
		end
	end

	if membersList then
		for _, c in pairs(membersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		local memArray = {}
		if type(gData.Members) == "table" then
			for _, mem in ipairs(gData.Members) do table.insert(memArray, mem) end
		end

		table.sort(memArray, function(a, b) 
			local pa = RolePower[a and a.Role or "Grunt"] or 1
			local pb = RolePower[b and b.Role or "Grunt"] or 1
			if pa == pb then 
				local prestA = (a and a.Prestige) or 0
				local prestB = (b and b.Prestige) or 0
				if prestA == prestB then
					local nA = (a and a.Name) and tostring(a.Name) or ""
					local nB = (b and b.Name) and tostring(b.Name) or ""
					return nA < nB 
				else
					return prestA > prestB
				end
			else 
				return pa > pb 
			end
		end)

		local customRoles = type(gData.RoleNames) == "table" and gData.RoleNames or {}
		for _, mem in ipairs(memArray) do
			if type(mem) ~= "table" then continue end
			local uIdStr = tostring(mem.UserId)
			local targetPower = RolePower[mem.Role] or 1

			local row = memTemplate:Clone()
			row.Visible = true
			row.Parent = membersList

			local statCol = mem.IsOnline and "#55FF55" or "#AAAAAA"
			local displayRoleName = customRoles[mem.Role] or mem.Role
			local safeName = mem.Name or "Unknown"

			local nLbl = row:FindFirstChild("NameLabel")
			if nLbl then
				nLbl.Text = "<b>" .. safeName .. "</b> <font color='"..statCol.."'>●</font> <b><font color='" .. (RoleColors[mem.Role] or "#FFFFFF") .. "'>(" .. displayRoleName .. ")</font></b>"
			end

			local tLbl = row:FindFirstChild("TimeLabel")
			if tLbl then tLbl.Text = FormatTimeAgo(mem.LastOnline) end

			row.MouseEnter:Connect(function()
				if cachedTooltipMgr and cachedTooltipMgr.Show then
					cachedTooltipMgr.Show(string.format("<b>%s</b>, %s\n<font color='#55FFFF'>Prestige %d</font>, <font color='#AAAAAA'>%s</font>\n<font color='#55FF55'>Treasury Contribution: ¥%s</font>", safeName, FormatTimeAgo(mem.LastOnline), mem.Prestige or 0, FormatPlayTime(mem.PlayTime or 0), FormatNumber(mem.Contribution or 0)))
				end
			end)
			row.MouseLeave:Connect(function() if cachedTooltipMgr and cachedTooltipMgr.Hide then cachedTooltipMgr.Hide() end end)

			local acts = row:FindFirstChild("Actions")
			if acts then
				local kBtn = acts:FindFirstChild("KickBtn"); local pBtn = acts:FindFirstChild("PromoteBtn"); local dBtn = acts:FindFirstChild("DemoteBtn")

				if uIdStr ~= tostring(player.UserId) then
					if myRole == "Boss" then
						if kBtn then kBtn.Visible = true end
						if pBtn then pBtn.Visible = (mem.Role ~= "Consigliere") end
						if dBtn then dBtn.Visible = (mem.Role ~= "Grunt") end
					elseif myRole == "Consigliere" and targetPower <= RolePower["Caporegime"] then
						if kBtn then kBtn.Visible = true end
					end

					if kBtn then
						local pk = false
						kBtn.MouseButton1Click:Connect(function()
							SFXManager.Play("Click")
							if pk then Network.GangAction:FireServer("Kick", mem.UserId)
							else pk = true; kBtn.Text = "Sure?"; task.delay(3, function() if pk then pk = false; kBtn.Text = "Kick" end end) end
						end)
					end
					if pBtn then pBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("Promote", mem.UserId) end) end
					if dBtn then dBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("Demote", mem.UserId) end) end
				end
			end
		end
		task.delay(0.05, function()
			if membersList then
				local l = membersList:FindFirstChildWhichIsA("UIListLayout")
				if l then membersList.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
			end
		end)
	end

	if requestsList then
		for _, c in pairs(requestsList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		if shouldShowRequests and type(gData.Requests) == "table" then
			for uId, reqName in pairs(gData.Requests) do
				local row = reqTemplate:Clone()
				row.Visible = true
				row.Parent = requestsList
				local nLbl = row:FindFirstChild("NameLabel")
				if nLbl then nLbl.Text = tostring(reqName) end

				local yBtn = row:FindFirstChild("YesBtn")
				local nBtn = row:FindFirstChild("NoBtn")
				if yBtn then yBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("AcceptRequest", uId) end) end
				if nBtn then nBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("DenyRequest", uId) end) end
			end
			task.delay(0.05, function()
				if requestsList then
					local l = requestsList:FindFirstChildWhichIsA("UIListLayout")
					if l then requestsList.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
				end
			end)
		end
	end

	if buildingList then
		for _, c in pairs(buildingList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		local bConfigs = {
			{Id = "Vault", Name = "The Vault", Desc = "+5% Yen Gain per level.", Max = 10, ReqLevel = 1},
			{Id = "Dojo", Name = "Training Hall", Desc = "+5% XP Gain per level.", Max = 10, ReqLevel = 2},
			{Id = "Market", Name = "Black Market", Desc = "+5 Inventory Slots per level.", Max = 7, ReqLevel = 3},
			{Id = "Shrine", Name = "Saint's Church", Desc = "+1 Luck per level.", Max = 3, ReqLevel = 4},
			{Id = "Armory", Name = "Armory", Desc = "+5% Damage per level.", Max = 5, ReqLevel = 5}
		}

		activeUpgradeFinishTime = (type(gData.ActiveUpgrade) == "table" and gData.ActiveUpgrade.FinishTime) or 0
		local activeUpgradeId = (type(gData.ActiveUpgrade) == "table" and gData.ActiveUpgrade.Id) or nil
		activeUpgradeBtnRef = nil

		for _, conf in ipairs(bConfigs) do
			local row = buildTpl:Clone(); row.Visible = true; row.Parent = buildingList
			local cLvl = (type(gData.Buildings) == "table" and gData.Buildings[conf.Id]) or 0

			local nLbl = row:FindFirstChild("NameLabel")
			local dLbl = row:FindFirstChild("DescLbl")
			if nLbl then nLbl.Text = conf.Name .. " <font color='#FFFFFF'>(Lv."..cLvl.."/"..conf.Max..")</font>" end
			if dLbl then dLbl.Text = conf.Desc end

			local uBtn = row:FindFirstChild("UpgradeBtn")
			local costLbl = row:FindFirstChild("CostLbl")

			if cLvl < conf.Max then
				if costLbl then costLbl.Text = "Cost: ¥100,000,000" end
				if uBtn then
					if activeUpgradeId == conf.Id then activeUpgradeBtnRef = uBtn; uBtn.Text = "Starting..."; uBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 20)
					elseif activeUpgradeId ~= nil then uBtn.Text = "Busy"; uBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					elseif level < conf.ReqLevel then uBtn.Text = "Requires Gang Lv." .. conf.ReqLevel; uBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					else uBtn.Text = "Upgrade"; uBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("UpgradeBuilding", conf.Id) end) end
					if myPower < RolePower["Consigliere"] then uBtn.Visible = false end
				end
			else
				if costLbl then costLbl.Text = "<font color='#FFD700'>MAX LEVEL REACHED</font>" end
				if uBtn then uBtn.Visible = false end
			end
		end
	end

	if ordersList then
		for _, c in pairs(ordersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		if type(gData.Orders) == "table" then
			for i, ord in ipairs(gData.Orders) do
				local row = ordTpl:Clone()
				row.Visible = true 
				row.Parent = ordersList

				local pBg = row:FindFirstChild("ProgBg")
				if pBg then
					local f = pBg:FindFirstChild("Fill")
					local pt = pBg:FindFirstChild("ProgTxt")
					if f then f.Size = UDim2.new(math.clamp(ord.Progress / ord.Target, 0, 1), 0, 1, 0) end
					if pt then pt.Text = FormatNumber(ord.Progress) .. " / " .. FormatNumber(ord.Target) end
				end

				local taskLbl = row:FindFirstChild("TaskLbl")
				local rBtn = row:FindFirstChild("ActionBtn")

				if ord.Completed then
					if taskLbl then taskLbl.Text = "<b>" .. ord.Desc .. "</b>\n<font size='12' color='#55FF55'>[COMPLETED!]</font>" end
					if rBtn then rBtn.Visible = false end
				else
					if taskLbl then taskLbl.Text = "<b>" .. ord.Desc .. "</b>\n<font size='11' color='#AAAAAA'>Rewards:</font> <font size='11' color='#55FF55'>¥" .. FormatNumber(ord.RewardT) .. "</font> <font size='11' color='#AAAAAA'>|</font> <font size='11' color='#A020F0'>+" .. ord.RewardR .. " Rep</font>" end

					if rBtn then
						if myPower >= RolePower["Consigliere"] then
							rBtn.Visible = true
							rBtn.MouseButton1Click:Connect(function()
								SFXManager.Play("Click")
								Network.GangAction:FireServer("RerollOrder", i)
							end)
						else
							rBtn.Visible = false
						end
					end
				end
			end
		end
	end

	if myRole == "Boss" and settingsCard and type(gData.RoleNames) == "table" then
		for k, v in pairs(gData.RoleNames) do
			local rSet = settingsCard:FindFirstChild("SetRole_" .. k)
			if rSet then 
				local inp = rSet:FindFirstChild("Input")
				if inp then inp.Text = v end
			end
		end
	end
end

function GangsTab.RenderSkills(battleData)
	if not battleData then return end
	combatUI:ClearAbilities()

	local myStand, myStyle = battleData.Player.Stand or "None", battleData.Player.Style or "None"
	local valid = {}

	if myStand == "Fused Stand" then
		local fs1 = player:GetAttribute("Active_FusedStand1") or "None"
		local fs2 = player:GetAttribute("Active_FusedStand2") or "None"
		local fusedSkills = FusionUtility.CalculateFusedAbilities(fs1, fs2, SkillData)
		for _, sk in ipairs(fusedSkills) do table.insert(valid, sk) end
	end

	for n, s in pairs(SkillData.Skills) do
		local isStandReq = (s.Requirement == myStand and myStand ~= "Fused Stand")
		if s.Requirement == "None" or isStandReq or s.Requirement == myStyle or (s.Requirement == "AnyStand" and myStand ~= "None") then 
			table.insert(valid, {Name = n, Data = s}) 
		end
	end
	table.sort(valid, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)

	for _, sk in ipairs(valid) do
		local c = sk.Data.Type == "Stand" and Color3.fromRGB(120, 20, 160) or (sk.Data.Type == "Style" and Color3.fromRGB(180, 80, 20) or Color3.fromRGB(60, 60, 80))
		local currentCooldown = battleData.Player.Cooldowns and battleData.Player.Cooldowns[sk.Name] or 0
		local disabled = battleData.Player.Stamina < (sk.Data.StaminaCost or 0) or battleData.Player.StandEnergy < (sk.Data.EnergyCost or 0) or currentCooldown > 0

		local btnText = (currentCooldown > 0) and (sk.Name .. " (" .. currentCooldown .. ")") or sk.Name

		local cb = function()
			if disabled then return end
			SFXManager.Play("Click")
			if cachedTooltipMgr then cachedTooltipMgr.Hide() end
			Network:WaitForChild("GangBossAction"):FireServer("Attack", {SkillName = sk.Name})
		end

		if sk.Name == "Flee" then cb = nil end

		local btn = combatUI:AddAbility(btnText, disabled and Color3.fromRGB(35, 25, 45) or c, cb)
		if disabled then
			btn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
		else
			if sk.Name == "Flee" then
				local isConfirmingFlee = false
				btn.MouseButton1Click:Connect(function() 
					if not disabled then
						SFXManager.Play("Click")
						if not isConfirmingFlee then
							isConfirmingFlee = true
							btn.Text = "Sure?"
							btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
							task.delay(3, function()
								if isConfirmingFlee and btn and btn.Parent then
									isConfirmingFlee = false; btn.Text = sk.Name; btn.BackgroundColor3 = c
								end
							end)
						else
							if cachedTooltipMgr then cachedTooltipMgr.Hide() end
							Network:WaitForChild("GangBossAction"):FireServer("Attack", {SkillName = sk.Name}) 
						end
					end
				end)
			end
		end

		if cachedTooltipMgr then
			btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
			btn.MouseLeave:Connect(cachedTooltipMgr.Hide)
		end
	end
end

local StatusIcons = {
	Stun = "STN", Freeze = "FRZ", Confusion = "CNF", Dizzy = "DZY", Warded = "WRD",
	Burn = "BRN", Sick = "SCK", Bleed = "BLD", Chill = "CHL",
	Scorch = "SCH", Poison = "PSN", Hemorrhage = "HEM", Frost = "FST",
	Acid = "ACD", Infection = "INF", Rupture = "RPT", Frostburn = "FBN", Frostbite = "FBT", Decay = "DCY",
	Blight = "BLT", Miasma = "MSM", Necrosis = "NCR", Plague = "PLG", Calamity = "CLM",
	Buff_Strength = "STR+", Buff_Defense = "DEF+", Buff_Speed = "SPD+", Buff_Willpower = "WIL+",
	Debuff_Strength = "STR-", Debuff_Defense = "DEF-", Debuff_Speed = "SPD-", Debuff_Willpower = "WIL-",
	EnergyExhausted = "ENG-", StaminaExhausted = "STM-"
}

local StatusDescs = {
	Stun = "Cannot move or act.",
	Freeze = "Frozen solid. Cannot move, takes damage.",
	Confusion = "May attack allies or self.",
	Dizzy = "May miss or attack self.",
	Burn = "Takes minor damage every turn.",
	Sick = "Takes minor damage every turn.",
	Bleed = "Takes minor damage every turn.",
	Chill = "Takes minor damage every turn.",
	Scorch = "Takes damage every turn.",
	Poison = "Takes damage every turn.",
	Hemorrhage = "Takes damage every turn.",
	Frost = "Takes damage every turn.",
	Acid = "Takes synergized damage every turn.",
	Infection = "Takes synergized damage every turn.",
	Rupture = "Takes synergized damage every turn.",
	Frostburn = "Takes synergized damage every turn.",
	Frostbite = "Takes synergized damage every turn.",
	Decay = "Takes synergized damage every turn.",
	Blight = "Takes heavy synergized damage every turn.",
	Miasma = "Takes heavy synergized damage every turn.",
	Necrosis = "Takes heavy synergized damage every turn.",
	Plague = "Takes heavy synergized damage every turn.",
	Calamity = "Takes apocalyptic synergized damage every turn.",
	Warded = "Immune to incoming debuffs and ailments.",
	Buff_Strength = "Increased damage dealt.",
	Buff_Defense = "Reduced damage taken.",
	Buff_Speed = "Increased evasion and turn priority.",
	Buff_Willpower = "Increased crit and survival chance.",
	Debuff_Strength = "Reduced damage dealt.",
	Debuff_Defense = "Increased damage taken.",
	Debuff_Speed = "Reduced evasion and turn priority.",
	Debuff_Willpower = "Reduced crit and survival chance.",
	EnergyExhausted = "Cannot use stand skills. Take +15% damage.",
	StaminaExhausted = "Cannot use style skills. Take +15% damage."
}

local function SyncFighter(fKey, isAlly, id, name, iconId, hp, maxHp, statuses, immunities, stam, maxStam, nrg, maxNrg)
	if not activeFighters[fKey] then
		activeFighters[fKey] = combatUI:AddFighter(isAlly, id, name, iconId, hp, maxHp)
	else
		local f = activeFighters[fKey]
		f:UpdateIcon(iconId, name)
	end
	local f = activeFighters[fKey]
	f:UpdateHealth(hp, maxHp)

	if stam and maxStam and nrg and maxNrg then
		f:UpdateResources(stam, maxStam, nrg, maxNrg)
	end

	local currentStatuses = {}
	if statuses then
		for eff, duration in pairs(statuses) do
			if duration and duration > 0 then
				currentStatuses[eff] = true
				f:SetStatus(eff, StatusIcons[eff] or "EFF", tostring(duration), StatusDescs[eff] or "Active effect.")
			end
		end
	end
	for eff, _ in pairs(StatusIcons) do
		if not currentStatuses[eff] then
			f:RemoveStatus(eff)
		end
	end

	local hasStunImmunity = (immunities and immunities.Stun and immunities.Stun > 0)
	if hasStunImmunity then
		f:SetCooldown("StunImmunity", "STN", tostring(immunities.Stun), "Immune to Stun effects.")
	else
		f:RemoveCooldown("StunImmunity")
	end

	local hasConfImmunity = (immunities and immunities.Confusion and immunities.Confusion > 0)
	if hasConfImmunity then
		f:SetCooldown("ConfImmunity", "CNF", tostring(immunities.Confusion), "Immune to Confusion effects.")
	else
		f:RemoveCooldown("ConfImmunity")
	end
end

function GangsTab.UpdateGangBoss(status, data)
	local playerGui = player:WaitForChild("PlayerGui")
	local jjbMenu = playerGui:WaitForChild("JJBIMenu")
	local mainFrame = jjbMenu:WaitForChild("MainFrame")
	local navBar = mainFrame:WaitForChild("NavBar")
	
	if status == "Start" then
		inBattle = true
		combatUI.ChatText.Text = ""

		hasGangContainer.Visible = false
		if navBar then navBar.Visible = false end

		combatUI.MainFrame.Visible = true
		combatUI.AbilitiesArea.Visible = true
		resourceLabel.Visible = true

		for fKey, f in pairs(activeFighters) do
			if f.Frame then f.Frame:Destroy() end
		end
		activeFighters = {}

		AddLog(data.LogMsg or "", false)
		GangsTab.RenderSkills(data.Battle)

	elseif status == "TurnStrike" then
		combatUI.AbilitiesArea.Visible = false
		AddLog(data.LogMsg, true)

		if string.find(data.LogMsg, "dodged!") then SFXManager.Play("CombatDodge")
		elseif string.find(data.LogMsg, "Blocked") then SFXManager.Play("CombatBlock")
		elseif data.DidHit then SFXManager.Play("CombatHit")
		else SFXManager.Play("CombatUtility") end

		if data.DidHit then
			task.spawn(function()
				local p = data.ShakeType == "Heavy" and 18 or (data.ShakeType == "Light" and 3 or 8)
				for i = 1, 6 do 
					local offsetX = math.random(-p, p)
					local offsetY = math.random(-p, p)
					combatUI.MainFrame.Position = UDim2.new(0, offsetX, 0, offsetY)
					task.wait(0.04) 
				end
				combatUI.MainFrame.Position = UDim2.new(0, 0, 0, 0)
			end)
		end
	elseif status == "Update" then
		combatUI.AbilitiesArea.Visible = true
		GangsTab.RenderSkills(data.Battle)

	elseif status == "Defeat" or status == "Fled" then

		resourceLabel.Visible = false
		combatUI.AbilitiesArea.Visible = false

		for fKey, f in pairs(activeFighters) do
			if f.Frame then f.Frame:Destroy() end
		end
		activeFighters = {}
		SFXManager.Play("CombatDefeat")

		local color = (status == "Defeat" and "#FF0055" or "#AAAAAA")
		AddLog("<font color='" .. color .. "'>GANG RAID ENDED!</font>", true)
		if data.CustomLog then AddLog(data.CustomLog, true) end

		task.delay(4, function() 
			inBattle = false
			combatUI.MainFrame.Visible = false

			hasGangContainer.Visible = true
			if navBar then navBar.Visible = true end
		end)
	end

	if data and data.Battle then
		local battle = data.Battle
		resourceLabel.Text = "STAMINA: " .. math.floor(battle.Player.Stamina) .. " | ENERGY: " .. math.floor(battle.Player.StandEnergy)

		local turnsLeft = 16 - (battle.TurnCounter or 1)
		turnLabel.Text = "Turns Remaining: " .. math.max(0, turnsLeft) .. "/15"
		SyncFighter("Player", true, "Player", battle.Player.Name, player.UserId, battle.Player.HP, battle.Player.MaxHP, battle.Player.Statuses, {Stun=battle.Player.StunImmunity, Confusion=battle.Player.ConfusionImmunity}, battle.Player.Stamina, battle.Player.MaxStamina, battle.Player.StandEnergy, battle.Player.MaxStandEnergy)
		if battle.Enemy then
			SyncFighter("Enemy", false, "Enemy", battle.Enemy.Name, battle.Enemy.Icon, battle.Enemy.HP, battle.Enemy.MaxHP, battle.Enemy.Statuses, {Stun=battle.Enemy.StunImmunity, Confusion=battle.Enemy.ConfusionImmunity}, battle.Enemy.Stamina, battle.Enemy.MaxStamina, battle.Enemy.StandEnergy, battle.Enemy.MaxStandEnergy)
		end
	end
end

return GangsTab