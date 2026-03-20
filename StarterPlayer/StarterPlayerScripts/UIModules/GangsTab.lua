-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local GangsTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))

local GangAction = Network:WaitForChild("GangAction")
local GangUpdate = Network:WaitForChild("GangUpdate")

local mainContainer
local noGangContainer, hasGangContainer
local navBar, infoFrame, upgradesFrame, ordersFrame, settingsFrame

local titleLabel, mottoLabel, emblemImage, repLabel, treasuryLabel, levelLabel, joinModeBtn
local membersList, browserList, requestsList, buildingScroll, ordersScroll
local membersCard, requestsCard, settingsCard
local leaveBtn, boostsBtn, donateInput, donateBtn, ordersTimerLbl
local reqInput, reqBtn

local pendingLeave = false
local currentBoostText = "Loading boosts..."
local cachedTooltipMgr = nil
local lastOrderResetTime = 0

local activeUpgradeFinishTime = 0
local activeUpgradeBtnRef = nil

local RolePower = { ["Grunt"] = 1, ["Caporegime"] = 2, ["Consigliere"] = 3, ["Boss"] = 4 }
local RoleColors = { ["Grunt"] = "#AAAAAA", ["Caporegime"] = "#55FF55", ["Consigliere"] = "#FF55FF", ["Boss"] = "#FFD700" }

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
	local diff = os.time() - timestamp
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

local function AddBtnStroke(btn, r, g, b, t)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(r, g, b)
	s.Thickness = t or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = btn
	return s
end

local function CreateCard(name, parent, size, pos)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	if pos then frame.Position = pos end
	frame.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	frame.ZIndex = 20
	frame.Parent = parent
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(frame, 90, 50, 120, 1)
	return frame
end

local function UpdateTabSizes()
	local visibleTabs = 0
	for _, btn in ipairs(navBar:GetChildren()) do
		if btn:IsA("TextButton") and btn.Visible then
			visibleTabs += 1
		end
	end
	local sizeScale = (1 / visibleTabs) - 0.02
	for _, btn in ipairs(navBar:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.Size = UDim2.new(sizeScale, 0, 1, 0)
		end
	end
end

local function SelectTab(tabName)
	SFXManager.Play("Click")
	infoFrame.Visible = (tabName == "Info")
	upgradesFrame.Visible = (tabName == "Upgrades")
	ordersFrame.Visible = (tabName == "Orders")
	settingsFrame.Visible = (tabName == "Settings")

	for _, btn in ipairs(navBar:GetChildren()) do
		if btn:IsA("TextButton") then
			local isSel = (btn.Name == "Btn" .. tabName)
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

local function BuildNoGangView()
	for _, c in pairs(noGangContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

	local createCard = CreateCard("CreateCard", noGangContainer, UDim2.new(0.3, 0, 0.48, 0), UDim2.new(0, 0, 0, 0))
	local cPad = Instance.new("UIPadding", createCard)
	cPad.PaddingTop = UDim.new(0.05, 0); cPad.PaddingBottom = UDim.new(0.05, 0)
	cPad.PaddingLeft = UDim.new(0.05, 0); cPad.PaddingRight = UDim.new(0.05, 0)

	local cTitle = Instance.new("TextLabel", createCard)
	cTitle.Size = UDim2.new(1, 0, 0.2, 0)
	cTitle.BackgroundTransparency = 1
	cTitle.Font = Enum.Font.GothamBlack
	cTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	cTitle.TextScaled = true
	cTitle.Text = "CREATE A GANG"
	cTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", cTitle).MaxTextSize = 24

	local nameInput = Instance.new("TextBox", createCard)
	nameInput.Size = UDim2.new(0.9, 0, 0.2, 0)
	nameInput.Position = UDim2.new(0.05, 0, 0.3, 0)
	nameInput.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	nameInput.Font = Enum.Font.GothamBold
	nameInput.TextColor3 = Color3.new(1,1,1)
	nameInput.PlaceholderText = "Enter Name (Max 15 Chars)"
	nameInput.Text = ""
	nameInput.TextScaled = true
	nameInput.ZIndex = 22
	Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(nameInput, 150, 100, 200, 1)

	local costLbl = Instance.new("TextLabel", createCard)
	costLbl.Size = UDim2.new(1, 0, 0.1, 0)
	costLbl.Position = UDim2.new(0, 0, 0.55, 0)
	costLbl.BackgroundTransparency = 1
	costLbl.Font = Enum.Font.GothamMedium
	costLbl.TextColor3 = Color3.fromRGB(85, 255, 85)
	costLbl.TextScaled = true
	costLbl.Text = "Cost: ¥500,000"
	costLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", costLbl).MaxTextSize = 16

	local createBtn = Instance.new("TextButton", createCard)
	createBtn.Size = UDim2.new(0.8, 0, 0.2, 0)
	createBtn.Position = UDim2.new(0.1, 0, 0.7, 0)
	createBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	createBtn.Font = Enum.Font.GothamBold
	createBtn.TextColor3 = Color3.new(1,1,1)
	createBtn.TextScaled = true
	createBtn.Text = "Form Gang"
	createBtn.ZIndex = 22
	Instance.new("UICorner", createBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(createBtn, 100, 255, 100, 1)
	Instance.new("UITextSizeConstraint", createBtn).MaxTextSize = 20

	createBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if nameInput.Text and string.len(nameInput.Text) >= 3 then Network.GangAction:FireServer("Create", nameInput.Text) end
	end)

	local invitesCard = CreateCard("InvitesCard", noGangContainer, UDim2.new(0.3, 0, 0.48, 0), UDim2.new(0, 0, 0.52, 0))
	local iPad = Instance.new("UIPadding", invitesCard)
	iPad.PaddingTop = UDim.new(0.05, 0); iPad.PaddingBottom = UDim.new(0.05, 0)
	iPad.PaddingLeft = UDim.new(0.05, 0); iPad.PaddingRight = UDim.new(0.05, 0)

	local iTitle = Instance.new("TextLabel", invitesCard)
	iTitle.Size = UDim2.new(1, 0, 0.2, 0)
	iTitle.BackgroundTransparency = 1
	iTitle.Font = Enum.Font.GothamBlack
	iTitle.TextColor3 = Color3.fromRGB(50, 255, 255)
	iTitle.TextScaled = true
	iTitle.Text = "PENDING INVITES"
	iTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", iTitle).MaxTextSize = 24

	requestsList = Instance.new("ScrollingFrame", invitesCard)
	requestsList.Name = "InvScroll"
	requestsList.Size = UDim2.new(1, 0, 0.8, 0)
	requestsList.Position = UDim2.new(0, 0, 0.2, 0)
	requestsList.BackgroundTransparency = 1
	requestsList.ScrollBarThickness = 6
	requestsList.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	requestsList.ZIndex = 22

	local isLayout = Instance.new("UIListLayout", requestsList)
	isLayout.SortOrder = Enum.SortOrder.LayoutOrder
	isLayout.Padding = UDim.new(0, 10)
	local isPad = Instance.new("UIPadding", requestsList)
	isPad.PaddingTop = UDim.new(0, 5); isPad.PaddingLeft = UDim.new(0, 5); isPad.PaddingRight = UDim.new(0, 10)

	local browseCard = CreateCard("BrowseCard", noGangContainer, UDim2.new(0.68, 0, 1, 0), UDim2.new(0.32, 0, 0, 0))
	local bPad = Instance.new("UIPadding", browseCard)
	bPad.PaddingTop = UDim.new(0.04, 0); bPad.PaddingBottom = UDim.new(0.04, 0)
	bPad.PaddingLeft = UDim.new(0.04, 0); bPad.PaddingRight = UDim.new(0.04, 0)

	local bTitle = Instance.new("TextLabel", browseCard)
	bTitle.Size = UDim2.new(0.4, 0, 0.1, 0)
	bTitle.BackgroundTransparency = 1
	bTitle.Font = Enum.Font.GothamBlack
	bTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	bTitle.TextScaled = true
	bTitle.TextXAlignment = Enum.TextXAlignment.Left
	bTitle.Text = "GANG BROWSER"
	bTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", bTitle).MaxTextSize = 24

	local refreshBtn = Instance.new("TextButton", browseCard)
	refreshBtn.Size = UDim2.new(0.15, 0, 0.08, 0)
	refreshBtn.Position = UDim2.new(0.42, 0, 0.01, 0)
	refreshBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
	refreshBtn.Font = Enum.Font.GothamBold
	refreshBtn.TextColor3 = Color3.new(1,1,1)
	refreshBtn.TextScaled = true
	refreshBtn.Text = "Randomize"
	refreshBtn.ZIndex = 22
	Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(refreshBtn, 150, 100, 200, 1)
	Instance.new("UITextSizeConstraint", refreshBtn).MaxTextSize = 14

	refreshBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("BrowseGangs") end)

	local searchInput = Instance.new("TextBox", browseCard)
	searchInput.Size = UDim2.new(0.3, 0, 0.08, 0)
	searchInput.Position = UDim2.new(0.6, 0, 0.01, 0)
	searchInput.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	searchInput.Font = Enum.Font.GothamBold
	searchInput.TextColor3 = Color3.new(1,1,1)
	searchInput.PlaceholderText = "Search Gang..."
	searchInput.Text = ""
	searchInput.TextScaled = true
	searchInput.ZIndex = 22
	Instance.new("UICorner", searchInput).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(searchInput, 150, 100, 200, 1)
	Instance.new("UITextSizeConstraint", searchInput).MaxTextSize = 14

	local searchBtn = Instance.new("TextButton", browseCard)
	searchBtn.Size = UDim2.new(0.08, 0, 0.08, 0)
	searchBtn.Position = UDim2.new(0.92, 0, 0.01, 0)
	searchBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
	searchBtn.Font = Enum.Font.GothamBold
	searchBtn.TextColor3 = Color3.new(1,1,1)
	searchBtn.TextScaled = true
	searchBtn.Text = "Go"
	searchBtn.ZIndex = 22
	Instance.new("UICorner", searchBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(searchBtn, 100, 150, 255, 1)
	Instance.new("UITextSizeConstraint", searchBtn).MaxTextSize = 14

	searchBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if searchInput.Text and string.len(searchInput.Text) >= 3 then Network.GangAction:FireServer("SearchGang", searchInput.Text) end
	end)

	browserList = Instance.new("ScrollingFrame", browseCard)
	browserList.Size = UDim2.new(1, 0, 0.88, 0)
	browserList.Position = UDim2.new(0, 0, 0.12, 0)
	browserList.BackgroundTransparency = 1
	browserList.ScrollBarThickness = 6
	browserList.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	browserList.ZIndex = 22

	local blLayout = Instance.new("UIListLayout", browserList)
	blLayout.SortOrder = Enum.SortOrder.LayoutOrder
	blLayout.Padding = UDim.new(0, 10)
	local blPad = Instance.new("UIPadding", browserList)
	blPad.PaddingTop = UDim.new(0, 5); blPad.PaddingLeft = UDim.new(0, 5); blPad.PaddingRight = UDim.new(0, 10)
end

local function BuildHasGangViews()
	for _, c in pairs(hasGangContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

	navBar = Instance.new("Frame", hasGangContainer)
	navBar.Size = UDim2.new(1, 0, 0.1, 0)
	navBar.BackgroundTransparency = 1
	navBar.ZIndex = 22

	local nLayout = Instance.new("UIListLayout", navBar)
	nLayout.FillDirection = Enum.FillDirection.Horizontal
	nLayout.SortOrder = Enum.SortOrder.LayoutOrder
	nLayout.Padding = UDim.new(0.02, 0)
	nLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local function CreateNavBtn(name, txt, order)
		local b = Instance.new("TextButton")
		b.Name = name
		b.Size = UDim2.new(0.23, 0, 1, 0)
		b.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.new(1,1,1)
		b.TextScaled = true
		b.Text = txt
		b.ZIndex = 22
		b.LayoutOrder = order
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		AddBtnStroke(b, 90, 50, 120, 1)
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 16
		b.Parent = navBar
		return b
	end

	local btnInfo = CreateNavBtn("BtnInfo", "INFO", 1)
	local btnUpg = CreateNavBtn("BtnUpgrades", "UPGRADES", 2)
	local btnOrd = CreateNavBtn("BtnOrders", "ORDERS", 3)
	local btnSet = CreateNavBtn("BtnSettings", "SETTINGS", 4)

	btnInfo.MouseButton1Click:Connect(function() SelectTab("Info") end)
	btnUpg.MouseButton1Click:Connect(function() SelectTab("Upgrades") end)
	btnOrd.MouseButton1Click:Connect(function() SelectTab("Orders") end)
	btnSet.MouseButton1Click:Connect(function() SelectTab("Settings") end)

	local contentArea = Instance.new("Frame", hasGangContainer)
	contentArea.Size = UDim2.new(1, 0, 0.88, 0)
	contentArea.Position = UDim2.new(0, 0, 0.12, 0)
	contentArea.BackgroundTransparency = 1
	contentArea.ZIndex = 21

	-- INFO FRAME
	infoFrame = Instance.new("Frame", contentArea)
	infoFrame.Size = UDim2.new(1, 0, 1, 0)
	infoFrame.BackgroundTransparency = 1
	infoFrame.Visible = true

	local headerCard = CreateCard("HeaderCard", infoFrame, UDim2.new(1, 0, 0.35, 0), UDim2.new(0, 0, 0, 0))
	local hcPad = Instance.new("UIPadding", headerCard)
	hcPad.PaddingTop = UDim.new(0.05, 0); hcPad.PaddingBottom = UDim.new(0.05, 0)
	hcPad.PaddingLeft = UDim.new(0.05, 0); hcPad.PaddingRight = UDim.new(0.05, 0)

	emblemImage = Instance.new("ImageLabel", headerCard)
	emblemImage.Size = UDim2.new(0.2, 0, 1, 0)
	emblemImage.BackgroundTransparency = 1
	emblemImage.ScaleType = Enum.ScaleType.Fit
	emblemImage.ZIndex = 22

	local infoBox = Instance.new("Frame", headerCard)
	infoBox.Size = UDim2.new(0.75, 0, 1, 0)
	infoBox.Position = UDim2.new(0.25, 0, 0, 0)
	infoBox.BackgroundTransparency = 1

	titleLabel = Instance.new("TextLabel", infoBox)
	titleLabel.Size = UDim2.new(0.6, 0, 0.3, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 50)
	titleLabel.TextScaled = true
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 22
	Instance.new("UITextSizeConstraint", titleLabel).MaxTextSize = 28

	levelLabel = Instance.new("TextLabel", infoBox)
	levelLabel.Size = UDim2.new(0.4, 0, 0.3, 0)
	levelLabel.Position = UDim2.new(0.6, 0, 0, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Font = Enum.Font.GothamBold
	levelLabel.TextColor3 = Color3.new(1, 1, 1)
	levelLabel.TextScaled = true
	levelLabel.TextXAlignment = Enum.TextXAlignment.Right
	levelLabel.ZIndex = 22
	Instance.new("UITextSizeConstraint", levelLabel).MaxTextSize = 20

	mottoLabel = Instance.new("TextLabel", infoBox)
	mottoLabel.Size = UDim2.new(1, 0, 0.25, 0)
	mottoLabel.Position = UDim2.new(0, 0, 0.3, 0)
	mottoLabel.BackgroundTransparency = 1
	mottoLabel.Font = Enum.Font.GothamMedium
	mottoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	mottoLabel.TextScaled = true
	mottoLabel.TextXAlignment = Enum.TextXAlignment.Left
	mottoLabel.ZIndex = 22
	Instance.new("UITextSizeConstraint", mottoLabel).MaxTextSize = 14

	local repBg = Instance.new("Frame", infoBox)
	repBg.Size = UDim2.new(1, 0, 0.15, 0)
	repBg.Position = UDim2.new(0, 0, 0.6, 0)
	repBg.BackgroundColor3 = Color3.fromRGB(20, 10, 20)
	repBg.ZIndex = 22
	Instance.new("UICorner", repBg).CornerRadius = UDim.new(0, 4)

	local repFill = Instance.new("Frame", repBg)
	repFill.Name = "RepFill"
	repFill.Size = UDim2.new(0, 0, 1, 0)
	repFill.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
	repFill.ZIndex = 23
	Instance.new("UICorner", repFill).CornerRadius = UDim.new(0, 4)

	repLabel = Instance.new("TextLabel", repBg)
	repLabel.Size = UDim2.new(1, 0, 1, 0)
	repLabel.BackgroundTransparency = 1
	repLabel.Font = Enum.Font.GothamBold
	repLabel.TextColor3 = Color3.new(1, 1, 1)
	repLabel.TextScaled = true
	repLabel.ZIndex = 24
	Instance.new("UITextSizeConstraint", repLabel).MaxTextSize = 12

	treasuryLabel = Instance.new("TextLabel", infoBox)
	treasuryLabel.Size = UDim2.new(0.5, 0, 0.25, 0)
	treasuryLabel.Position = UDim2.new(0, 0, 0.75, 0)
	treasuryLabel.BackgroundTransparency = 1
	treasuryLabel.Font = Enum.Font.GothamBold
	treasuryLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
	treasuryLabel.TextScaled = true
	treasuryLabel.TextXAlignment = Enum.TextXAlignment.Left
	treasuryLabel.ZIndex = 22
	Instance.new("UITextSizeConstraint", treasuryLabel).MaxTextSize = 16

	leaveBtn = Instance.new("TextButton", infoBox)
	leaveBtn.Size = UDim2.new(0.2, 0, 0.25, 0)
	leaveBtn.Position = UDim2.new(0.8, 0, 0.75, 0)
	leaveBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	leaveBtn.Font = Enum.Font.GothamBold
	leaveBtn.TextColor3 = Color3.new(1,1,1)
	leaveBtn.TextScaled = true
	leaveBtn.Text = "Leave"
	leaveBtn.ZIndex = 22
	Instance.new("UICorner", leaveBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(leaveBtn, 255, 100, 100, 1)
	Instance.new("UITextSizeConstraint", leaveBtn).MaxTextSize = 14

	leaveBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local isBoss = (player:GetAttribute("GangRole") == "Boss")
		local origText = isBoss and "Disband Gang" or "Leave Gang"
		if pendingLeave then
			pendingLeave = false; leaveBtn.Text = origText
			if isBoss then Network.GangAction:FireServer("Disband") else Network.GangAction:FireServer("Leave") end
		else
			pendingLeave = true; leaveBtn.Text = isBoss and "Confirm Disband?" or "Confirm Leave?"
			task.delay(3, function() if pendingLeave then pendingLeave = false; leaveBtn.Text = origText end end)
		end
	end)

	membersCard = CreateCard("MembersCard", infoFrame, UDim2.new(0.68, 0, 0.62, 0), UDim2.new(0, 0, 0.38, 0))
	local mcPad = Instance.new("UIPadding", membersCard)
	mcPad.PaddingTop = UDim.new(0.04, 0); mcPad.PaddingBottom = UDim.new(0.04, 0)
	mcPad.PaddingLeft = UDim.new(0.04, 0); mcPad.PaddingRight = UDim.new(0.04, 0)

	local mcTop = Instance.new("Frame", membersCard)
	mcTop.Size = UDim2.new(1, 0, 0.15, 0)
	mcTop.BackgroundTransparency = 1
	mcTop.ZIndex = 22

	local mTitle = Instance.new("TextLabel", mcTop)
	mTitle.Size = UDim2.new(0.4, 0, 1, 0)
	mTitle.BackgroundTransparency = 1
	mTitle.Font = Enum.Font.GothamBlack
	mTitle.TextColor3 = Color3.fromRGB(50, 255, 255)
	mTitle.TextScaled = true
	mTitle.TextXAlignment = Enum.TextXAlignment.Left
	mTitle.Text = "MEMBERS"
	mTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", mTitle).MaxTextSize = 20

	local invBox = Instance.new("TextBox", mcTop)
	invBox.Size = UDim2.new(0.4, 0, 1, 0)
	invBox.Position = UDim2.new(0.4, 0, 0, 0)
	invBox.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	invBox.Font = Enum.Font.GothamMedium
	invBox.TextColor3 = Color3.new(1,1,1)
	invBox.PlaceholderText = "Player Name..."
	invBox.Text = ""
	invBox.TextScaled = true
	invBox.ZIndex = 22
	Instance.new("UICorner", invBox).CornerRadius = UDim.new(0, 4)
	AddBtnStroke(invBox, 90, 50, 120, 1)

	local invBtn = Instance.new("TextButton", mcTop)
	invBtn.Size = UDim2.new(0.18, 0, 1, 0)
	invBtn.Position = UDim2.new(0.82, 0, 0, 0)
	invBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
	invBtn.Font = Enum.Font.GothamBold
	invBtn.TextColor3 = Color3.new(1,1,1)
	invBtn.TextScaled = true
	invBtn.Text = "Invite"
	invBtn.ZIndex = 22
	Instance.new("UICorner", invBtn).CornerRadius = UDim.new(0, 4)
	AddBtnStroke(invBtn, 100, 150, 255, 1)
	Instance.new("UITextSizeConstraint", invBtn).MaxTextSize = 14

	invBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if invBox.Text ~= "" then
			Network.GangAction:FireServer("InvitePlayer", invBox.Text)
			invBox.Text = ""
		end
	end)

	membersList = Instance.new("ScrollingFrame", membersCard)
	membersList.Size = UDim2.new(1, 0, 0.8, 0)
	membersList.Position = UDim2.new(0, 0, 0.2, 0)
	membersList.BackgroundTransparency = 1
	membersList.ScrollBarThickness = 6
	membersList.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	membersList.ZIndex = 22

	local msLayout = Instance.new("UIListLayout", membersList)
	msLayout.SortOrder = Enum.SortOrder.LayoutOrder
	msLayout.Padding = UDim.new(0, 8)
	local msPad = Instance.new("UIPadding", membersList)
	msPad.PaddingTop = UDim.new(0, 5); msPad.PaddingLeft = UDim.new(0, 5); msPad.PaddingRight = UDim.new(0, 10)

	requestsCard = CreateCard("RequestsCard", infoFrame, UDim2.new(0.3, 0, 0.62, 0), UDim2.new(0.7, 0, 0.38, 0))
	local rcPad = Instance.new("UIPadding", requestsCard)
	rcPad.PaddingTop = UDim.new(0.04, 0); rcPad.PaddingBottom = UDim.new(0.04, 0)
	rcPad.PaddingLeft = UDim.new(0.04, 0); rcPad.PaddingRight = UDim.new(0.04, 0)

	local rTitle = Instance.new("TextLabel", requestsCard)
	rTitle.Size = UDim2.new(1, 0, 0.15, 0)
	rTitle.BackgroundTransparency = 1
	rTitle.Font = Enum.Font.GothamBlack
	rTitle.TextColor3 = Color3.fromRGB(255, 140, 0)
	rTitle.TextScaled = true
	rTitle.TextXAlignment = Enum.TextXAlignment.Left
	rTitle.Text = "REQUESTS"
	rTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", rTitle).MaxTextSize = 20

	-- UPGRADES FRAME
	upgradesFrame = Instance.new("Frame", contentArea)
	upgradesFrame.Size = UDim2.new(1, 0, 1, 0)
	upgradesFrame.BackgroundTransparency = 1
	upgradesFrame.Visible = false

	local donationCard = CreateCard("DonationCard", upgradesFrame, UDim2.new(1, 0, 0.15, 0), UDim2.new(0, 0, 0, 0))
	local dPad = Instance.new("UIPadding", donationCard)
	dPad.PaddingTop = UDim.new(0, 10); dPad.PaddingBottom = UDim.new(0, 10)
	dPad.PaddingLeft = UDim.new(0, 15); dPad.PaddingRight = UDim.new(0, 15)

	local dLayout = Instance.new("UIListLayout", donationCard)
	dLayout.FillDirection = Enum.FillDirection.Horizontal
	dLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dLayout.Padding = UDim.new(0.02, 0)

	donateInput = Instance.new("TextBox", donationCard)
	donateInput.Size = UDim2.new(0.4, 0, 1, 0)
	donateInput.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	donateInput.Font = Enum.Font.GothamBold
	donateInput.TextColor3 = Color3.fromRGB(85, 255, 85)
	donateInput.PlaceholderText = "Amount to Donate (Min 1,000)"
	donateInput.Text = ""
	donateInput.TextScaled = true
	donateInput.ZIndex = 22
	Instance.new("UICorner", donateInput).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(donateInput, 50, 150, 50, 1)

	donateBtn = Instance.new("TextButton", donationCard)
	donateBtn.Size = UDim2.new(0.2, 0, 1, 0)
	donateBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	donateBtn.Font = Enum.Font.GothamBold
	donateBtn.TextColor3 = Color3.new(1,1,1)
	donateBtn.TextScaled = true
	donateBtn.Text = "Deposit Yen"
	donateBtn.ZIndex = 22
	Instance.new("UICorner", donateBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(donateBtn, 100, 255, 100, 1)

	donateBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local amt = tonumber(donateInput.Text)
		if amt and amt >= 1000 then Network.GangAction:FireServer("Donate", amt); donateInput.Text = "" end
	end)

	boostsBtn = Instance.new("TextButton", donationCard)
	boostsBtn.Size = UDim2.new(0.2, 0, 1, 0)
	boostsBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 20)
	boostsBtn.Font = Enum.Font.GothamBold
	boostsBtn.TextColor3 = Color3.new(1,1,1)
	boostsBtn.TextScaled = true
	boostsBtn.Text = "View Boosts"
	boostsBtn.ZIndex = 22
	Instance.new("UICorner", boostsBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(boostsBtn, 255, 215, 50, 1)

	boostsBtn.MouseEnter:Connect(function() if cachedTooltipMgr and cachedTooltipMgr.Show then cachedTooltipMgr.Show(currentBoostText) end end)
	boostsBtn.MouseLeave:Connect(function() if cachedTooltipMgr and cachedTooltipMgr.Hide then cachedTooltipMgr.Hide() end end)

	buildingScroll = Instance.new("ScrollingFrame", upgradesFrame)
	buildingScroll.Size = UDim2.new(1, 0, 0.82, 0)
	buildingScroll.Position = UDim2.new(0, 0, 0.18, 0)
	buildingScroll.BackgroundTransparency = 1
	buildingScroll.ScrollBarThickness = 6
	buildingScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	buildingScroll.ZIndex = 22

	local usLayout = Instance.new("UIGridLayout", buildingScroll)
	usLayout.CellSize = UDim2.new(0.48, 0, 0, 100)
	usLayout.CellPadding = UDim2.new(0.04, 0, 0, 15)
	usLayout.SortOrder = Enum.SortOrder.LayoutOrder
	local usPad = Instance.new("UIPadding", buildingScroll)
	usPad.PaddingTop = UDim.new(0, 5); usPad.PaddingLeft = UDim.new(0, 5); usPad.PaddingRight = UDim.new(0, 10)

	-- ORDERS FRAME
	ordersFrame = Instance.new("Frame", contentArea)
	ordersFrame.Size = UDim2.new(1, 0, 1, 0)
	ordersFrame.BackgroundTransparency = 1
	ordersFrame.Visible = false

	ordersTimerLbl = Instance.new("TextLabel", ordersFrame)
	ordersTimerLbl.Size = UDim2.new(1, 0, 0.1, 0)
	ordersTimerLbl.BackgroundTransparency = 1
	ordersTimerLbl.Font = Enum.Font.GothamBlack
	ordersTimerLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	ordersTimerLbl.TextScaled = true
	ordersTimerLbl.Text = "Next Orders in: --:--:--"
	ordersTimerLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", ordersTimerLbl).MaxTextSize = 24

	ordersScroll = Instance.new("ScrollingFrame", ordersFrame)
	ordersScroll.Size = UDim2.new(1, 0, 0.88, 0)
	ordersScroll.Position = UDim2.new(0, 0, 0.12, 0)
	ordersScroll.BackgroundTransparency = 1
	ordersScroll.ScrollBarThickness = 6
	ordersScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	ordersScroll.ZIndex = 22

	local osLayout = Instance.new("UIListLayout", ordersScroll)
	osLayout.SortOrder = Enum.SortOrder.LayoutOrder
	osLayout.Padding = UDim.new(0, 10)
	local osPad = Instance.new("UIPadding", ordersScroll)
	osPad.PaddingTop = UDim.new(0, 5); osPad.PaddingLeft = UDim.new(0, 5); osPad.PaddingRight = UDim.new(0, 10)

	-- SETTINGS FRAME
	settingsFrame = Instance.new("Frame", contentArea)
	settingsFrame.Size = UDim2.new(1, 0, 1, 0)
	settingsFrame.BackgroundTransparency = 1
	settingsFrame.Visible = false

	settingsCard = Instance.new("ScrollingFrame", settingsFrame)
	settingsCard.Size = UDim2.new(1, 0, 1, 0)
	settingsCard.BackgroundTransparency = 1
	settingsCard.ScrollBarThickness = 6
	settingsCard.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	settingsCard.ZIndex = 22

	local stLayout = Instance.new("UIListLayout", settingsCard)
	stLayout.SortOrder = Enum.SortOrder.LayoutOrder
	stLayout.Padding = UDim.new(0, 10)
	local stPad = Instance.new("UIPadding", settingsCard)
	stPad.PaddingTop = UDim.new(0, 5); stPad.PaddingLeft = UDim.new(0, 5); stPad.PaddingRight = UDim.new(0, 10)

	SelectTab("Info")
end

function GangsTab.Init(parentFrame, tooltipMgr, focusFunc)
	mainContainer = parentFrame
	cachedTooltipMgr = tooltipMgr
	forceTabFocus = focusFunc

	noGangContainer = Instance.new("Frame", mainContainer)
	noGangContainer.Name = "NoGangContainer"
	noGangContainer.Size = UDim2.new(0.96, 0, 0.96, 0)
	noGangContainer.Position = UDim2.new(0.02, 0, 0.02, 0)
	noGangContainer.BackgroundTransparency = 1
	noGangContainer.Visible = false

	hasGangContainer = Instance.new("Frame", mainContainer)
	hasGangContainer.Name = "HasGangContainer"
	hasGangContainer.Size = UDim2.new(0.96, 0, 0.96, 0)
	hasGangContainer.Position = UDim2.new(0.02, 0, 0.02, 0)
	hasGangContainer.BackgroundTransparency = 1
	hasGangContainer.Visible = false

	BuildNoGangView()
	BuildHasGangViews()

	GangUpdate.OnClientEvent:Connect(function(action, data)
		if action == "BrowserSync" then
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

			for i, g in ipairs(data) do
				local row = CreateCard("Brow_"..i, browserList, UDim2.new(1, 0, 0, 60), nil)
				row.LayoutOrder = i
				local rPad = Instance.new("UIPadding", row)
				rPad.PaddingLeft = UDim.new(0, 10); rPad.PaddingRight = UDim.new(0, 10)

				local txt = Instance.new("TextLabel", row)
				txt.Size = UDim2.new(0.65, 0, 1, 0)
				txt.BackgroundTransparency = 1
				txt.Font = Enum.Font.GothamMedium
				txt.TextColor3 = Color3.new(1,1,1)
				txt.TextScaled = true
				txt.RichText = true
				txt.TextXAlignment = Enum.TextXAlignment.Left
				local reqText = (g.Req and g.Req > 0) and " <font color='#FFAA00'>[Pres " .. g.Req .. "+]</font>" or ""
				txt.Text = "<b>" .. g.Name .. "</b>" .. reqText .. "\n<font color='#AAAAAA'>Lv." .. g.Level .. " | " .. g.Members .. "/30</font>"
				txt.ZIndex = 22
				Instance.new("UITextSizeConstraint", txt).MaxTextSize = 16

				local jBtn = Instance.new("TextButton", row)
				jBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
				jBtn.Position = UDim2.new(1, 0, 0.5, 0)
				jBtn.AnchorPoint = Vector2.new(1, 0.5)
				jBtn.Font = Enum.Font.GothamBold
				jBtn.TextColor3 = Color3.new(1,1,1)
				jBtn.TextScaled = true
				jBtn.Text = g.Mode == "Open" and "Join" or "Request"
				jBtn.BackgroundColor3 = g.Mode == "Open" and Color3.fromRGB(40, 140, 40) or Color3.fromRGB(200, 150, 0)
				jBtn.ZIndex = 22
				Instance.new("UICorner", jBtn).CornerRadius = UDim.new(0, 4)
				AddBtnStroke(jBtn, jBtn.BackgroundColor3.R*200, jBtn.BackgroundColor3.G*200, jBtn.BackgroundColor3.B*200, 1)
				Instance.new("UITextSizeConstraint", jBtn).MaxTextSize = 14

				jBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("RequestJoin", g.Name) end)
			end
			task.delay(0.05, function()
				local l = browserList:FindFirstChildWhichIsA("UIListLayout")
				if l then browserList.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
			end)

		elseif action == "Sync" then
			GangsTab.HandleUpdate(action, data)
		end
	end)

	mainContainer:GetPropertyChangedSignal("Visible"):Connect(function()
		if mainContainer.Visible then
			local gName = player:GetAttribute("Gang") or "None"
			if gName == "None" then
				Network.GangAction:FireServer("BrowseGangs")
			else
				Network.GangAction:FireServer("RequestData")
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			if ordPage and ordPage.Visible and lastOrderResetTime > 0 then
				local timeLeft = math.max(0, (lastOrderResetTime + 86400) - os.time())
				if timeLeft <= 0 then
					ordersTimerLbl.Text = "Generating new orders..."
				else
					local h = math.floor(timeLeft / 3600)
					local m = math.floor((timeLeft % 3600) / 60)
					local s = timeLeft % 60
					ordersTimerLbl.Text = string.format("Next Orders in: %02d:%02d:%02d", h, m, s)
				end
			end

			if upgPage and upgPage.Visible and activeUpgradeFinishTime > 0 and activeUpgradeBtnRef then
				local timeLeft = math.max(0, activeUpgradeFinishTime - os.time())
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
end

local function BuildUpgradeCard(parent, order, title, desc, currLvl, maxLvl, cost, uType, myRole)
	local card = CreateCard("Upg_"..uType, parent, UDim2.new(0, 0, 0, 0), nil)
	card.LayoutOrder = order
	local cPad = Instance.new("UIPadding", card)
	cPad.PaddingTop = UDim.new(0, 5); cPad.PaddingBottom = UDim.new(0, 5)
	cPad.PaddingLeft = UDim.new(0, 10); cPad.PaddingRight = UDim.new(0, 10)

	local tLbl = Instance.new("TextLabel", card)
	tLbl.Size = UDim2.new(0.7, 0, 0.3, 0)
	tLbl.BackgroundTransparency = 1
	tLbl.Font = Enum.Font.GothamBlack
	tLbl.TextColor3 = Color3.fromRGB(255, 215, 50)
	tLbl.TextScaled = true
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Text = title .. " [" .. currLvl .. "/" .. maxLvl .. "]"
	tLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", tLbl).MaxTextSize = 16

	local dLbl = Instance.new("TextLabel", card)
	dLbl.Size = UDim2.new(1, 0, 0.4, 0)
	dLbl.Position = UDim2.new(0, 0, 0.3, 0)
	dLbl.BackgroundTransparency = 1
	dLbl.Font = Enum.Font.GothamMedium
	dLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	dLbl.TextScaled = true
	dLbl.TextXAlignment = Enum.TextXAlignment.Left
	dLbl.Text = desc
	dLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", dLbl).MaxTextSize = 12

	if currLvl < maxLvl then
		local costLbl = Instance.new("TextLabel", card)
		costLbl.Size = UDim2.new(0.5, 0, 0.3, 0)
		costLbl.Position = UDim2.new(0, 0, 0.7, 0)
		costLbl.BackgroundTransparency = 1
		costLbl.Font = Enum.Font.GothamBold
		costLbl.TextColor3 = Color3.fromRGB(85, 255, 85)
		costLbl.TextScaled = true
		costLbl.TextXAlignment = Enum.TextXAlignment.Left
		costLbl.Text = "Cost: ¥" .. FormatNumber(cost)
		costLbl.ZIndex = 22
		Instance.new("UITextSizeConstraint", costLbl).MaxTextSize = 14

		if RolePower[myRole] and RolePower[myRole] >= RolePower["Consigliere"] then
			local buyBtn = Instance.new("TextButton", card)
			buyBtn.Size = UDim2.new(0.4, 0, 0.25, 0)
			buyBtn.Position = UDim2.new(0.6, 0, 0.75, 0)
			buyBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextColor3 = Color3.new(1,1,1)
			buyBtn.TextScaled = true
			buyBtn.Text = "Upgrade"
			buyBtn.ZIndex = 22
			Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 4)
			AddBtnStroke(buyBtn, 100, 255, 100, 1)
			Instance.new("UITextSizeConstraint", buyBtn).MaxTextSize = 14

			buyBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("UpgradeBuilding", uType) end)
		end
	else
		local maxLbl = Instance.new("TextLabel", card)
		maxLbl.Size = UDim2.new(1, 0, 0.3, 0)
		maxLbl.Position = UDim2.new(0, 0, 0.7, 0)
		maxLbl.BackgroundTransparency = 1
		maxLbl.Font = Enum.Font.GothamBold
		maxLbl.TextColor3 = Color3.fromRGB(255, 215, 50)
		maxLbl.TextScaled = true
		maxLbl.Text = "MAX LEVEL REACHED"
		maxLbl.ZIndex = 22
		Instance.new("UITextSizeConstraint", maxLbl).MaxTextSize = 14
	end
end

local function BuildOrderCard(parent, order, oData, myRole)
	local card = CreateCard("Ord_"..order, parent, UDim2.new(1, 0, 0, 60), nil)
	card.LayoutOrder = order
	local cPad = Instance.new("UIPadding", card)
	cPad.PaddingTop = UDim.new(0, 5); cPad.PaddingBottom = UDim.new(0, 5)
	cPad.PaddingLeft = UDim.new(0, 10); cPad.PaddingRight = UDim.new(0, 10)

	local tLbl = Instance.new("TextLabel", card)
	tLbl.Size = UDim2.new(0.6, 0, 0.4, 0)
	tLbl.BackgroundTransparency = 1
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextColor3 = Color3.new(1,1,1)
	tLbl.TextScaled = true
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Text = oData.Desc .. " (" .. FormatNumber(oData.Progress) .. "/" .. FormatNumber(oData.Target) .. ")"
	tLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", tLbl).MaxTextSize = 14

	local rLbl = Instance.new("TextLabel", card)
	rLbl.Size = UDim2.new(0.6, 0, 0.3, 0)
	rLbl.Position = UDim2.new(0, 0, 0.4, 0)
	rLbl.BackgroundTransparency = 1
	rLbl.Font = Enum.Font.GothamMedium
	rLbl.TextColor3 = Color3.fromRGB(85, 255, 85)
	rLbl.TextScaled = true
	rLbl.TextXAlignment = Enum.TextXAlignment.Left
	rLbl.Text = "Reward: ¥" .. FormatNumber(oData.RewardT) .. " | +" .. FormatNumber(oData.RewardR) .. " Rep"
	rLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", rLbl).MaxTextSize = 12

	local pBg = Instance.new("Frame", card)
	pBg.Size = UDim2.new(0.6, 0, 0.2, 0)
	pBg.Position = UDim2.new(0, 0, 0.8, 0)
	pBg.BackgroundColor3 = Color3.fromRGB(20, 10, 20)
	pBg.ZIndex = 22
	Instance.new("UICorner", pBg).CornerRadius = UDim.new(0, 4)

	local pct = math.clamp(oData.Progress / oData.Target, 0, 1)
	local pFill = Instance.new("Frame", pBg)
	pFill.Size = UDim2.new(pct, 0, 1, 0)
	pFill.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
	pFill.ZIndex = 23
	Instance.new("UICorner", pFill).CornerRadius = UDim.new(0, 4)

	if oData.Completed and not oData.Claimed then
		if RolePower[myRole] and RolePower[myRole] == RolePower["Boss"] then
			local claimBtn = Instance.new("TextButton", card)
			claimBtn.Size = UDim2.new(0.2, 0, 0.6, 0)
			claimBtn.Position = UDim2.new(1, 0, 0.5, 0)
			claimBtn.AnchorPoint = Vector2.new(1, 0.5)
			claimBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
			claimBtn.Font = Enum.Font.GothamBold
			claimBtn.TextColor3 = Color3.new(1,1,1)
			claimBtn.TextScaled = true
			claimBtn.Text = "Claim"
			claimBtn.ZIndex = 22
			Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 6)
			AddBtnStroke(claimBtn, 255, 215, 50, 1)
			Instance.new("UITextSizeConstraint", claimBtn).MaxTextSize = 14
			claimBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("ClaimOrder", order) end)
		else
			local cLbl = Instance.new("TextLabel", card)
			cLbl.Size = UDim2.new(0.3, 0, 0.6, 0)
			cLbl.Position = UDim2.new(1, 0, 0.5, 0)
			cLbl.AnchorPoint = Vector2.new(1, 0.5)
			cLbl.BackgroundTransparency = 1
			cLbl.Font = Enum.Font.GothamBold
			cLbl.TextColor3 = Color3.fromRGB(200, 150, 0)
			cLbl.TextScaled = true
			cLbl.Text = "Awaiting Boss..."
			cLbl.ZIndex = 22
			Instance.new("UITextSizeConstraint", cLbl).MaxTextSize = 12
		end
	elseif oData.Claimed then
		local dLbl = Instance.new("TextLabel", card)
		dLbl.Size = UDim2.new(0.2, 0, 0.6, 0)
		dLbl.Position = UDim2.new(1, 0, 0.5, 0)
		dLbl.AnchorPoint = Vector2.new(1, 0.5)
		dLbl.BackgroundTransparency = 1
		dLbl.Font = Enum.Font.GothamBold
		dLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
		dLbl.TextScaled = true
		dLbl.Text = "Completed"
		dLbl.ZIndex = 22
		Instance.new("UITextSizeConstraint", dLbl).MaxTextSize = 14
	else
		if RolePower[myRole] and RolePower[myRole] >= RolePower["Consigliere"] then
			local rBtn = Instance.new("TextButton", card)
			rBtn.Size = UDim2.new(0.2, 0, 0.6, 0)
			rBtn.Position = UDim2.new(1, 0, 0.5, 0)
			rBtn.AnchorPoint = Vector2.new(1, 0.5)
			rBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 140)
			rBtn.Font = Enum.Font.GothamBold
			rBtn.TextColor3 = Color3.new(1,1,1)
			rBtn.TextScaled = true
			rBtn.Text = "Reroll (¥1M)"
			rBtn.ZIndex = 22
			Instance.new("UICorner", rBtn).CornerRadius = UDim.new(0, 6)
			AddBtnStroke(rBtn, 180, 80, 180, 1)
			Instance.new("UITextSizeConstraint", rBtn).MaxTextSize = 12
			rBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("RerollOrder", order) end)
		end
	end
end

local function BuildSettingsField(parent, order, title, placeholder, currentVal, isNumeric, actionKey)
	local row = CreateCard("Set_"..order, parent, UDim2.new(1, 0, 0, 50), nil)
	row.LayoutOrder = order
	local rPad = Instance.new("UIPadding", row)
	rPad.PaddingTop = UDim.new(0, 5); rPad.PaddingBottom = UDim.new(0, 5)
	rPad.PaddingLeft = UDim.new(0, 10); rPad.PaddingRight = UDim.new(0, 10)

	local tLbl = Instance.new("TextLabel", row)
	tLbl.Size = UDim2.new(0.3, 0, 1, 0)
	tLbl.BackgroundTransparency = 1
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextColor3 = Color3.new(1,1,1)
	tLbl.TextScaled = true
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Text = title
	tLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", tLbl).MaxTextSize = 14

	local input = Instance.new("TextBox", row)
	input.Size = UDim2.new(0.4, 0, 0.8, 0)
	input.Position = UDim2.new(0.35, 0, 0.1, 0)
	input.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	input.Font = Enum.Font.GothamMedium
	input.TextColor3 = Color3.new(1,1,1)
	input.PlaceholderText = placeholder
	input.Text = tostring(currentVal)
	input.TextScaled = true
	input.ZIndex = 22
	Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)
	AddBtnStroke(input, 90, 50, 120, 1)

	local saveBtn = Instance.new("TextButton", row)
	saveBtn.Size = UDim2.new(0.2, 0, 0.8, 0)
	saveBtn.Position = UDim2.new(1, 0, 0.1, 0)
	saveBtn.AnchorPoint = Vector2.new(1, 0)
	saveBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	saveBtn.Font = Enum.Font.GothamBold
	saveBtn.TextColor3 = Color3.new(1,1,1)
	saveBtn.TextScaled = true
	saveBtn.Text = "Update"
	saveBtn.ZIndex = 22
	Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
	AddBtnStroke(saveBtn, 100, 255, 100, 1)
	Instance.new("UITextSizeConstraint", saveBtn).MaxTextSize = 14

	saveBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local val = input.Text
		if isNumeric then val = tonumber(val) end
		if val then
			Network.GangAction:FireServer(actionKey, val)
		end
	end)
end

function GangsTab.HandleUpdate(action, data)
	if not data then 
		activeContainer.Visible = false
		noGangContainer.Visible = true
		if titleLabel then titleLabel.Text = "LOADING..." end
		if mottoLabel then mottoLabel.Text = "<i>...</i>" end
		if emblemImage then emblemImage.Image = "" end
		lastOrderResetTime = 0
		activeUpgradeFinishTime = 0
		activeUpgradeBtnRef = nil
		for _, c in pairs(membersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		for _, c in pairs(requestsList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		for _, c in pairs(buildingScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		for _, c in pairs(ordersScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		return
	end

	if data.HasGang == false then
		activeContainer.Visible = false
		noGangContainer.Visible = true

		local invScroll = noGangContainer.InvitesCard.InvScroll
		for _, c in pairs(invScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

		if #data.Invites == 0 then
			local empty = Instance.new("TextLabel", invScroll)
			empty.Size = UDim2.new(1, 0, 0, 30)
			empty.BackgroundTransparency = 1
			empty.Text = "No pending invites."
			empty.Font = Enum.Font.GothamMedium
			empty.TextColor3 = Color3.fromRGB(150, 150, 150)
			empty.TextScaled = true
			empty.ZIndex = 22
			Instance.new("UITextSizeConstraint", empty).MaxTextSize = 14
		else
			for i, gang in ipairs(data.Invites) do
				local row = CreateCard("Inv_"..i, invScroll, UDim2.new(1, 0, 0, 50), nil)
				row.LayoutOrder = i
				local rPad = Instance.new("UIPadding", row)
				rPad.PaddingLeft = UDim.new(0, 10); rPad.PaddingRight = UDim.new(0, 10)

				local txt = Instance.new("TextLabel", row)
				txt.Size = UDim2.new(0.5, 0, 1, 0)
				txt.BackgroundTransparency = 1
				txt.Font = Enum.Font.GothamBold
				txt.TextColor3 = Color3.new(1,1,1)
				txt.TextScaled = true
				txt.TextXAlignment = Enum.TextXAlignment.Left
				txt.Text = gang
				txt.ZIndex = 22
				Instance.new("UITextSizeConstraint", txt).MaxTextSize = 16

				local accBtn = Instance.new("TextButton", row)
				accBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
				accBtn.Position = UDim2.new(0.75, -5, 0.5, 0)
				accBtn.AnchorPoint = Vector2.new(1, 0.5)
				accBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
				accBtn.Font = Enum.Font.GothamBold
				accBtn.TextColor3 = Color3.new(1,1,1)
				accBtn.TextScaled = true
				accBtn.Text = "Accept"
				accBtn.ZIndex = 22
				Instance.new("UICorner", accBtn).CornerRadius = UDim.new(0, 4)
				AddBtnStroke(accBtn, 100, 255, 100, 1)
				accBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("AcceptInvite", gang) end)

				local decBtn = Instance.new("TextButton", row)
				decBtn.Size = UDim2.new(0.2, 0, 0.7, 0)
				decBtn.Position = UDim2.new(1, 0, 0.5, 0)
				decBtn.AnchorPoint = Vector2.new(1, 0.5)
				decBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
				decBtn.Font = Enum.Font.GothamBold
				decBtn.TextColor3 = Color3.new(1,1,1)
				decBtn.TextScaled = true
				decBtn.Text = "Decline"
				decBtn.ZIndex = 22
				Instance.new("UICorner", decBtn).CornerRadius = UDim.new(0, 4)
				AddBtnStroke(decBtn, 255, 100, 100, 1)
				decBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("DeclineInvite", gang) end)
			end
		end
		task.delay(0.05, function()
			local l = invScroll:FindFirstChildWhichIsA("UIListLayout")
			if l then invScroll.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
		end)
		return
	end

	noGangContainer.Visible = false
	hasGangContainer.Visible = true

	local gData = data.GangData
	local myRole = data.MyRole
	local myPower = RolePower[myRole] or 1

	local settingsTabBtn = navBar:FindFirstChild("BtnSettings")
	if settingsTabBtn then
		settingsTabBtn.Visible = (myRole == "Boss")
		UpdateTabSizes()
	end

	if settingsPage and settingsPage.Visible and myRole ~= "Boss" then
		SelectTab("Info")
	end

	if titleLabel then titleLabel.Text = gData.Name:upper() end
	if mottoLabel then mottoLabel.Text = "<i>" .. (gData.Motto or "No motto set.") .. "</i>" end
	if repLabel then repLabel.Text = "Reputation: <b><font color='#A020F0'>" .. FormatNumber(gData.Rep or 0) .. "</font></b>" end

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
	if treasuryLabel then treasuryLabel.Text = "Bank: <b>¥" .. FormatNumber(gData.Treasury or 0) .. "</b>" end

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
			requestsCard.Visible = true; membersCard.Size = UDim2.new(0.68, 0, 0.62, 0)
		else 
			requestsCard.Visible = false; membersCard.Size = UDim2.new(1, 0, 0.62, 0) 
		end
	end

	for _, c in pairs(membersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local memArray = {}
	for _, mem in ipairs(gData.Members) do table.insert(memArray, mem) end
	table.sort(memArray, function(a, b) 
		local pa = RolePower[a.Role] or 1; local pb = RolePower[b.Role] or 1
		if pa == pb then return a.Name < b.Name else return pa > pb end
	end)

	local customRoles = gData.RoleNames or {}
	for i, mem in ipairs(memArray) do
		local uIdStr = tostring(mem.UserId)
		local targetPower = RolePower[mem.Role] or 1

		local row = CreateCard("Mem_"..i, membersList, UDim2.new(1, 0, 0, 40), nil)
		row.LayoutOrder = i
		local rPad = Instance.new("UIPadding", row)
		rPad.PaddingLeft = UDim.new(0, 10); rPad.PaddingRight = UDim.new(0, 10)

		local statCol = mem.IsOnline and "#55FF55" or "#AAAAAA"
		local nLbl = Instance.new("TextLabel", row)
		nLbl.Size = UDim2.new(0.4, 0, 1, 0)
		nLbl.BackgroundTransparency = 1
		nLbl.Font = Enum.Font.GothamBold
		nLbl.TextColor3 = Color3.new(1,1,1)
		nLbl.TextScaled = true
		nLbl.RichText = true
		nLbl.TextXAlignment = Enum.TextXAlignment.Left
		nLbl.Text = "<b>" .. mem.Name .. "</b> <font color='"..statCol.."'>●</font>"
		nLbl.ZIndex = 22
		Instance.new("UITextSizeConstraint", nLbl).MaxTextSize = 14

		local displayRoleName = customRoles[mem.Role] or mem.Role
		local rLbl = Instance.new("TextLabel", row)
		rLbl.Size = UDim2.new(0.3, 0, 1, 0)
		rLbl.Position = UDim2.new(0.4, 0, 0, 0)
		rLbl.BackgroundTransparency = 1
		rLbl.Font = Enum.Font.GothamMedium
		rLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		rLbl.TextScaled = true
		rLbl.RichText = true
		rLbl.TextXAlignment = Enum.TextXAlignment.Left
		rLbl.Text = "<b><font color='" .. (RoleColors[mem.Role] or "#FFFFFF") .. "'>(" .. displayRoleName .. ")</font></b>"
		rLbl.ZIndex = 22
		Instance.new("UITextSizeConstraint", rLbl).MaxTextSize = 14

		if uIdStr ~= tostring(player.UserId) then
			local btnCount = 0
			local function AddActionBtn(txt, col, cb)
				local b = Instance.new("TextButton", row)
				b.Size = UDim2.new(0.1, 0, 0.7, 0)
				b.Position = UDim2.new(1 - (btnCount * 0.12), 0, 0.5, 0)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.BackgroundColor3 = col
				b.Font = Enum.Font.GothamBold
				b.TextColor3 = Color3.new(1,1,1)
				b.TextScaled = true
				b.Text = txt
				b.ZIndex = 22
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
				AddBtnStroke(b, col.R*200, col.G*200, col.B*200, 1)
				Instance.new("UITextSizeConstraint", b).MaxTextSize = 12
				b.MouseButton1Click:Connect(cb)
				btnCount += 1
			end

			if myRole == "Boss" then
				AddActionBtn("Kick", Color3.fromRGB(140, 40, 40), function() SFXManager.Play("Click"); Network.GangAction:FireServer("Kick", mem.UserId) end)
				if mem.Role ~= "Consigliere" then AddActionBtn("Up", Color3.fromRGB(40, 140, 40), function() SFXManager.Play("Click"); Network.GangAction:FireServer("Promote", mem.UserId) end) end
				if mem.Role ~= "Grunt" then AddActionBtn("Dn", Color3.fromRGB(180, 100, 40), function() SFXManager.Play("Click"); Network.GangAction:FireServer("Demote", mem.UserId) end) end
			elseif myRole == "Consigliere" and targetPower <= RolePower["Caporegime"] then
				AddActionBtn("Kick", Color3.fromRGB(140, 40, 40), function() SFXManager.Play("Click"); Network.GangAction:FireServer("Kick", mem.UserId) end)
			end
		end
	end
	task.delay(0.05, function()
		local l = membersList:FindFirstChildWhichIsA("UIListLayout")
		if l then membersList.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
	end)

	for _, c in pairs(requestsList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	if shouldShowRequests and gData.Requests then
		local count = 0
		for uIdStr, reqName in pairs(gData.Requests) do
			count += 1
			local row = CreateCard("ReqRow_"..count, requestsList, UDim2.new(1, -8, 0, 40))
			row.LayoutOrder = count
			local rPad = Instance.new("UIPadding", row)
			rPad.PaddingLeft = UDim.new(0, 5); rPad.PaddingRight = UDim.new(0, 5)

			local txt = Instance.new("TextLabel", row)
			txt.Size = UDim2.new(0.5, 0, 1, 0)
			txt.BackgroundTransparency = 1
			txt.Font = Enum.Font.GothamMedium
			txt.TextColor3 = Color3.new(1, 1, 1)
			txt.TextScaled = true
			txt.TextXAlignment = Enum.TextXAlignment.Left
			txt.Text = reqName
			txt.ZIndex = 22
			Instance.new("UITextSizeConstraint", txt).MaxTextSize = 14

			local accBtn = Instance.new("TextButton", row)
			accBtn.Size = UDim2.new(0.22, 0, 0.7, 0)
			accBtn.Position = UDim2.new(0.75, -5, 0.5, 0)
			accBtn.AnchorPoint = Vector2.new(1, 0.5)
			accBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
			accBtn.Font = Enum.Font.GothamBold
			accBtn.TextColor3 = Color3.new(1, 1, 1)
			accBtn.TextScaled = true
			accBtn.Text = "Y"
			accBtn.ZIndex = 22
			Instance.new("UICorner", accBtn).CornerRadius = UDim.new(0, 6)
			AddBtnStroke(accBtn, 80, 180, 80, 1)
			Instance.new("UITextSizeConstraint", accBtn).MaxTextSize = 14
			accBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("AcceptRequest", uIdStr) end)

			local decBtn = Instance.new("TextButton", row)
			decBtn.Size = UDim2.new(0.22, 0, 0.7, 0)
			decBtn.Position = UDim2.new(1, 0, 0.5, 0)
			decBtn.AnchorPoint = Vector2.new(1, 0.5)
			decBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
			decBtn.Font = Enum.Font.GothamBold
			decBtn.TextColor3 = Color3.new(1, 1, 1)
			decBtn.TextScaled = true
			decBtn.Text = "N"
			decBtn.ZIndex = 22
			Instance.new("UICorner", decBtn).CornerRadius = UDim.new(0, 6)
			AddBtnStroke(decBtn, 200, 80, 80, 1)
			Instance.new("UITextSizeConstraint", decBtn).MaxTextSize = 14
			decBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("DenyRequest", uIdStr) end)
		end
		task.delay(0.05, function()
			local l = requestsList:FindFirstChildWhichIsA("UIListLayout")
			if l then requestsList.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
		end)
	end

	for _, c in pairs(buildingScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local bConfigs = {
		{Id = "Vault", Name = "The Vault", Desc = "+5% Yen Gain per level.", Max = 10, ReqLevel = 1},
		{Id = "Dojo", Name = "Training Hall", Desc = "+5% XP Gain per level.", Max = 10, ReqLevel = 2},
		{Id = "Market", Name = "Black Market", Desc = "+5 Inventory Slots per level.", Max = 3, ReqLevel = 3},
		{Id = "Shrine", Name = "Saint's Church", Desc = "+1 Luck per level.", Max = 3, ReqLevel = 4},
		{Id = "Armory", Name = "Armory", Desc = "+5% Damage per level.", Max = 5, ReqLevel = 5}
	}

	activeUpgradeFinishTime = gData.ActiveUpgrade and gData.ActiveUpgrade.FinishTime or 0
	local activeUpgradeId = gData.ActiveUpgrade and gData.ActiveUpgrade.Id or nil
	activeUpgradeBtnRef = nil

	for i, conf in ipairs(bConfigs) do
		local cLvl = (gData.Buildings and gData.Buildings[conf.Id]) or 0
		local cost = 100000000 
		local cId = conf.Id

		local card = CreateCard("Upg_"..cId, buildingScroll, UDim2.new(0, 0, 0, 0), nil)
		card.LayoutOrder = i
		local cPad = Instance.new("UIPadding", card)
		cPad.PaddingTop = UDim.new(0, 5); cPad.PaddingBottom = UDim.new(0, 5)
		cPad.PaddingLeft = UDim.new(0, 10); cPad.PaddingRight = UDim.new(0, 10)

		local tLbl = Instance.new("TextLabel", card)
		tLbl.Size = UDim2.new(0.7, 0, 0.3, 0)
		tLbl.BackgroundTransparency = 1
		tLbl.Font = Enum.Font.GothamBlack
		tLbl.TextColor3 = Color3.fromRGB(255, 215, 50)
		tLbl.TextScaled = true
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.Text = conf.Name .. " [" .. cLvl .. "/" .. conf.Max .. "]"
		tLbl.ZIndex = 22
		Instance.new("UITextSizeConstraint", tLbl).MaxTextSize = 16

		local dLbl = Instance.new("TextLabel", card)
		dLbl.Size = UDim2.new(1, 0, 0.4, 0)
		dLbl.Position = UDim2.new(0, 0, 0.3, 0)
		dLbl.BackgroundTransparency = 1
		dLbl.Font = Enum.Font.GothamMedium
		dLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		dLbl.TextScaled = true
		dLbl.TextXAlignment = Enum.TextXAlignment.Left
		dLbl.Text = conf.Desc
		dLbl.ZIndex = 22
		Instance.new("UITextSizeConstraint", dLbl).MaxTextSize = 12

		if cLvl < conf.Max then
			local costLbl = Instance.new("TextLabel", card)
			costLbl.Size = UDim2.new(0.5, 0, 0.3, 0)
			costLbl.Position = UDim2.new(0, 0, 0.7, 0)
			costLbl.BackgroundTransparency = 1
			costLbl.Font = Enum.Font.GothamBold
			costLbl.TextColor3 = Color3.fromRGB(85, 255, 85)
			costLbl.TextScaled = true
			costLbl.TextXAlignment = Enum.TextXAlignment.Left
			costLbl.Text = "Cost: ¥" .. FormatNumber(cost)
			costLbl.ZIndex = 22
			Instance.new("UITextSizeConstraint", costLbl).MaxTextSize = 14

			if myPower >= RolePower["Consigliere"] then
				local uBtn = Instance.new("TextButton", card)
				uBtn.Size = UDim2.new(0.4, 0, 0.25, 0)
				uBtn.Position = UDim2.new(0.6, 0, 0.75, 0)
				uBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
				uBtn.Font = Enum.Font.GothamBold
				uBtn.TextColor3 = Color3.new(1,1,1)
				uBtn.TextScaled = true
				uBtn.ZIndex = 22
				Instance.new("UICorner", uBtn).CornerRadius = UDim.new(0, 4)
				AddBtnStroke(uBtn, 100, 255, 100, 1)
				Instance.new("UITextSizeConstraint", uBtn).MaxTextSize = 14

				if activeUpgradeId == cId then 
					activeUpgradeBtnRef = uBtn; uBtn.Text = "Starting..."; uBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 20)
				elseif activeUpgradeId ~= nil then 
					uBtn.Text = "Busy"; uBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				elseif level < conf.ReqLevel then 
					uBtn.Text = "Requires Gang Lv." .. conf.ReqLevel; uBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				else 
					uBtn.Text = "Upgrade"; uBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("UpgradeBuilding", cId) end) 
				end
			end
		else
			local maxLbl = Instance.new("TextLabel", card)
			maxLbl.Size = UDim2.new(1, 0, 0.3, 0)
			maxLbl.Position = UDim2.new(0, 0, 0.7, 0)
			maxLbl.BackgroundTransparency = 1
			maxLbl.Font = Enum.Font.GothamBold
			maxLbl.TextColor3 = Color3.fromRGB(255, 215, 50)
			maxLbl.TextScaled = true
			maxLbl.Text = "MAX LEVEL REACHED"
			maxLbl.ZIndex = 22
			Instance.new("UITextSizeConstraint", maxLbl).MaxTextSize = 14
		end
	end
	task.delay(0.05, function()
		local l = buildingScroll:FindFirstChildWhichIsA("UIGridLayout")
		if l then buildingScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#buildingScroll:GetChildren()/2) * 115 + 10) end
	end)

	for _, c in pairs(ordersScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	if gData.Orders then
		for i, ord in ipairs(gData.Orders) do 
			BuildOrderCard(ordersScroll, i, ord, myRole) 
		end
	end
	task.delay(0.05, function()
		local l = ordersScroll:FindFirstChildWhichIsA("UIListLayout")
		if l then ordersScroll.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
	end)

	if myRole == "Boss" and settingsPage then
		local sScroll = settingsPage:FindFirstChild("SetScroll")
		if sScroll then
			for _, c in pairs(sScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
			BuildSettingsField(sScroll, 1, "Gang Motto", "Enter motto...", gData.Motto, false, "UpdateMotto")
			BuildSettingsField(sScroll, 2, "Emblem ID", "Enter image ID...", gData.Emblem, false, "UpdateEmblem")
			BuildSettingsField(sScroll, 3, "Prestige Req.", "Enter prestige (1-100)...", gData.PrestigeReq, true, "UpdatePrestigeReq")

			local function BuildRoleSet(order, rKey, title)
				local row = CreateCard("SetRole_"..order, sScroll, UDim2.new(1, 0, 0, 50), nil)
				row.LayoutOrder = order
				local rPad = Instance.new("UIPadding", row)
				rPad.PaddingTop = UDim.new(0, 5); rPad.PaddingBottom = UDim.new(0, 5)
				rPad.PaddingLeft = UDim.new(0, 10); rPad.PaddingRight = UDim.new(0, 10)

				local tLbl = Instance.new("TextLabel", row)
				tLbl.Size = UDim2.new(0.3, 0, 1, 0)
				tLbl.BackgroundTransparency = 1
				tLbl.Font = Enum.Font.GothamBold
				tLbl.TextColor3 = Color3.new(1,1,1)
				tLbl.TextScaled = true
				tLbl.TextXAlignment = Enum.TextXAlignment.Left
				tLbl.Text = title .. " Name"
				tLbl.ZIndex = 22
				Instance.new("UITextSizeConstraint", tLbl).MaxTextSize = 14

				local input = Instance.new("TextBox", row)
				input.Size = UDim2.new(0.4, 0, 0.8, 0)
				input.Position = UDim2.new(0.35, 0, 0.1, 0)
				input.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
				input.Font = Enum.Font.GothamMedium
				input.TextColor3 = Color3.new(1,1,1)
				input.PlaceholderText = "Enter role name..."
				input.Text = gData.RoleNames and gData.RoleNames[rKey] or rKey
				input.TextScaled = true
				input.ZIndex = 22
				Instance.new("UICorner", input).CornerRadius = UDim.new(0, 4)
				AddBtnStroke(input, 90, 50, 120, 1)

				local saveBtn = Instance.new("TextButton", row)
				saveBtn.Size = UDim2.new(0.2, 0, 0.8, 0)
				saveBtn.Position = UDim2.new(1, 0, 0.1, 0)
				saveBtn.AnchorPoint = Vector2.new(1, 0)
				saveBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
				saveBtn.Font = Enum.Font.GothamBold
				saveBtn.TextColor3 = Color3.new(1,1,1)
				saveBtn.TextScaled = true
				saveBtn.Text = "Update"
				saveBtn.ZIndex = 22
				Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
				AddBtnStroke(saveBtn, 100, 255, 100, 1)
				Instance.new("UITextSizeConstraint", saveBtn).MaxTextSize = 14

				saveBtn.MouseButton1Click:Connect(function()
					SFXManager.Play("Click")
					if input.Text ~= "" then
						Network.GangAction:FireServer("RenameRole", rKey, input.Text)
					end
				end)
			end

			BuildRoleSet(4, "Consigliere", "Consigliere")
			BuildRoleSet(5, "Caporegime", "Caporegime")
			BuildRoleSet(6, "Grunt", "Grunt")

			local disBtn = Instance.new("TextButton", sScroll)
			disBtn.Size = UDim2.new(1, 0, 0, 40)
			disBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
			disBtn.Font = Enum.Font.GothamBold
			disBtn.TextColor3 = Color3.new(1,1,1)
			disBtn.TextScaled = true
			disBtn.Text = "DISBAND GANG"
			disBtn.ZIndex = 22
			disBtn.LayoutOrder = 99
			Instance.new("UICorner", disBtn).CornerRadius = UDim.new(0, 6)
			AddBtnStroke(disBtn, 255, 100, 100, 2)
			Instance.new("UITextSizeConstraint", disBtn).MaxTextSize = 16

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

			task.delay(0.05, function()
				local l = sScroll:FindFirstChildWhichIsA("UIListLayout")
				if l then sScroll.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
			end)
		end
	end
end

return GangsTab