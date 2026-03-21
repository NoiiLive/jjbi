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

local mainContainer, noGangContainer, hasGangContainer, pagesContainer, tabContainer
local infoPage, upgPage, ordPage, settingsPage
local titleLabel, mottoLabel, emblemImage, repLabel, treasuryLabel, levelLabel, joinModeBtn
local membersList, browserList, requestsList, buildingList, ordersList
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

local function BuildCodeTemplates()
	memTemplate = Instance.new("Frame")
	memTemplate.Size = UDim2.new(1, 0, 0, 40)
	memTemplate.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	memTemplate.ZIndex = 22
	Instance.new("UICorner", memTemplate).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(memTemplate, 90, 50, 120, 1)

	local mName = Instance.new("TextLabel", memTemplate)
	mName.Name = "NameLabel"
	mName.Size = UDim2.new(0.4, 0, 1, 0)
	mName.Position = UDim2.new(0, 10, 0, 0)
	mName.BackgroundTransparency = 1
	mName.Font = Enum.Font.GothamBold
	mName.TextColor3 = Color3.new(1,1,1)
	mName.TextScaled = true; mName.RichText = true
	mName.TextXAlignment = Enum.TextXAlignment.Left
	mName.ZIndex = 23
	Instance.new("UITextSizeConstraint", mName).MaxTextSize = 14

	local mTime = Instance.new("TextLabel", memTemplate)
	mTime.Name = "TimeLabel"
	mTime.Size = UDim2.new(0.25, 0, 1, 0)
	mTime.Position = UDim2.new(0.4, 0, 0, 0)
	mTime.BackgroundTransparency = 1
	mTime.Font = Enum.Font.GothamMedium
	mTime.TextColor3 = Color3.fromRGB(200, 200, 200)
	mTime.TextScaled = true; mTime.RichText = true
	mTime.TextXAlignment = Enum.TextXAlignment.Left
	mTime.ZIndex = 23
	Instance.new("UITextSizeConstraint", mTime).MaxTextSize = 14

	local actContainer = Instance.new("Frame", memTemplate)
	actContainer.Name = "Actions"
	actContainer.Size = UDim2.new(0.35, 0, 1, 0)
	actContainer.Position = UDim2.new(1, -10, 0, 0)
	actContainer.AnchorPoint = Vector2.new(1, 0)
	actContainer.BackgroundTransparency = 1

	local actLayout = Instance.new("UIListLayout", actContainer)
	actLayout.FillDirection = Enum.FillDirection.Horizontal
	actLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	actLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	actLayout.Padding = UDim.new(0, 5)
	actLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local function makeMemBtn(n, sizeX, c, txt, order)
		local b = Instance.new("TextButton", actContainer)
		b.Name = n; b.Size = UDim2.new(sizeX, 0, 0.7, 0)
		b.BackgroundColor3 = c; b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.new(1,1,1); b.TextScaled = true; b.Visible = false
		b.Text = txt; b.ZIndex = 23; b.LayoutOrder = order
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
		AddBtnStroke(b, c.R*200, c.G*200, c.B*200, 1)
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 14
	end
	makeMemBtn("DemoteBtn", 0.15, Color3.fromRGB(180, 100, 40), "▼", 1)
	makeMemBtn("PromoteBtn", 0.15, Color3.fromRGB(40, 140, 40), "▲", 2)
	makeMemBtn("KickBtn", 0.4, Color3.fromRGB(140, 40, 40), "Kick", 3)

	reqTemplate = Instance.new("Frame")
	reqTemplate.Size = UDim2.new(1, -8, 0, 40)
	reqTemplate.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	reqTemplate.ZIndex = 22
	Instance.new("UICorner", reqTemplate).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(reqTemplate, 90, 50, 120, 1)

	local rName = Instance.new("TextLabel", reqTemplate)
	rName.Name = "NameLabel"
	rName.Size = UDim2.new(0.5, 0, 1, 0)
	rName.Position = UDim2.new(0, 10, 0, 0)
	rName.BackgroundTransparency = 1
	rName.Font = Enum.Font.GothamMedium
	rName.TextColor3 = Color3.new(1, 1, 1)
	rName.TextScaled = true; rName.RichText = true
	rName.TextXAlignment = Enum.TextXAlignment.Left
	rName.ZIndex = 23
	Instance.new("UITextSizeConstraint", rName).MaxTextSize = 14

	local function makeReqBtn(n, p, txt, c)
		local b = Instance.new("TextButton", reqTemplate)
		b.Name = n; b.Size = UDim2.new(0.22, 0, 0.7, 0)
		b.Position = UDim2.new(p, -5, 0.5, 0)
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.BackgroundColor3 = c; b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.new(1, 1, 1); b.TextScaled = true
		b.RichText = true; b.Text = txt
		b.ZIndex = 23
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		AddBtnStroke(b, c.R*200, c.G*200, c.B*200, 1)
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 14
	end
	makeReqBtn("YesBtn", 0.75, "Y", Color3.fromRGB(40, 140, 40))
	makeReqBtn("NoBtn", 1, "N", Color3.fromRGB(140, 40, 40))

	-- Upgrades List Template (Proper Scale Height)
	buildTpl = Instance.new("Frame")
	buildTpl.Size = UDim2.new(1, 0, 0.17, 0) 
	buildTpl.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	buildTpl.ZIndex = 22
	Instance.new("UICorner", buildTpl).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(buildTpl, 90, 50, 120, 1)
	local bPad = Instance.new("UIPadding", buildTpl)
	bPad.PaddingTop = UDim.new(0, 5); bPad.PaddingBottom = UDim.new(0, 5)
	bPad.PaddingLeft = UDim.new(0, 10); bPad.PaddingRight = UDim.new(0, 10)

	local bName = Instance.new("TextLabel", buildTpl)
	bName.Name = "NameLabel"
	bName.Size = UDim2.new(0.7, 0, 0.35, 0)
	bName.BackgroundTransparency = 1
	bName.Font = Enum.Font.GothamBlack; bName.TextColor3 = Color3.fromRGB(255, 215, 50)
	bName.TextScaled = true; bName.RichText = true; bName.TextXAlignment = Enum.TextXAlignment.Left
	bName.ZIndex = 23
	Instance.new("UITextSizeConstraint", bName).MaxTextSize = 16

	local bDesc = Instance.new("TextLabel", buildTpl)
	bDesc.Name = "DescLbl"
	bDesc.Size = UDim2.new(0.7, 0, 0.35, 0)
	bDesc.Position = UDim2.new(0, 0, 0.35, 0)
	bDesc.BackgroundTransparency = 1
	bDesc.Font = Enum.Font.GothamMedium; bDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
	bDesc.TextScaled = true; bDesc.RichText = true; bDesc.TextXAlignment = Enum.TextXAlignment.Left
	bDesc.ZIndex = 23
	Instance.new("UITextSizeConstraint", bDesc).MaxTextSize = 12

	local bCost = Instance.new("TextLabel", buildTpl)
	bCost.Name = "CostLbl"
	bCost.Size = UDim2.new(0.7, 0, 0.3, 0)
	bCost.Position = UDim2.new(0, 0, 0.7, 0)
	bCost.BackgroundTransparency = 1
	bCost.Font = Enum.Font.GothamBold; bCost.TextColor3 = Color3.fromRGB(85, 255, 85)
	bCost.TextScaled = true; bCost.RichText = true; bCost.TextXAlignment = Enum.TextXAlignment.Left
	bCost.ZIndex = 23
	Instance.new("UITextSizeConstraint", bCost).MaxTextSize = 14

	local bUpBtn = Instance.new("TextButton", buildTpl)
	bUpBtn.Name = "UpgradeBtn"
	bUpBtn.Size = UDim2.new(0.25, 0, 1, 0)
	bUpBtn.Position = UDim2.new(1, 0, 0.5, 0)
	bUpBtn.AnchorPoint = Vector2.new(1, 0.5)
	bUpBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	bUpBtn.Font = Enum.Font.GothamBold; bUpBtn.TextColor3 = Color3.new(1,1,1)
	bUpBtn.TextScaled = true; bUpBtn.RichText = true
	bUpBtn.ZIndex = 23
	Instance.new("UICorner", bUpBtn).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(bUpBtn, 100, 255, 100, 1)
	Instance.new("UITextSizeConstraint", bUpBtn).MaxTextSize = 16

	-- Orders List Template (Proper Scale Height)
	ordTpl = Instance.new("Frame")
	ordTpl.Size = UDim2.new(1, 0, 0.18, 0)
	ordTpl.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	ordTpl.ZIndex = 22
	Instance.new("UICorner", ordTpl).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(ordTpl, 90, 50, 120, 1)
	local oPad = Instance.new("UIPadding", ordTpl)
	oPad.PaddingTop = UDim.new(0, 5); oPad.PaddingBottom = UDim.new(0, 5)
	oPad.PaddingLeft = UDim.new(0, 10); oPad.PaddingRight = UDim.new(0, 10)

	local oTask = Instance.new("TextLabel", ordTpl)
	oTask.Name = "TaskLbl"
	oTask.Size = UDim2.new(0.7, 0, 0.6, 0)
	oTask.BackgroundTransparency = 1
	oTask.Font = Enum.Font.GothamBold; oTask.TextColor3 = Color3.new(1,1,1)
	oTask.TextScaled = true; oTask.RichText = true; oTask.TextXAlignment = Enum.TextXAlignment.Left
	oTask.ZIndex = 23
	Instance.new("UITextSizeConstraint", oTask).MaxTextSize = 14

	local oBg = Instance.new("Frame", ordTpl)
	oBg.Name = "ProgBg"
	oBg.Size = UDim2.new(0.7, 0, 0.35, 0)
	oBg.Position = UDim2.new(0, 0, 0.65, 0)
	oBg.BackgroundColor3 = Color3.fromRGB(20, 10, 20)
	oBg.ZIndex = 23
	Instance.new("UICorner", oBg).CornerRadius = UDim.new(0, 4)
	local oFill = Instance.new("Frame", oBg)
	oFill.Name = "Fill"
	oFill.Size = UDim2.new(0, 0, 1, 0)
	oFill.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
	oFill.ZIndex = 24
	Instance.new("UICorner", oFill).CornerRadius = UDim.new(0, 4)

	local oTxt = Instance.new("TextLabel", oBg)
	oTxt.Name = "ProgTxt"
	oTxt.Size = UDim2.new(1, 0, 1, 0)
	oTxt.BackgroundTransparency = 1
	oTxt.Font = Enum.Font.GothamBold; oTxt.TextColor3 = Color3.new(1,1,1)
	oTxt.TextScaled = true; oTxt.RichText = true
	oTxt.ZIndex = 25
	Instance.new("UITextSizeConstraint", oTxt).MaxTextSize = 12

	local oReroll = Instance.new("TextButton", ordTpl)
	oReroll.Name = "ActionBtn"
	oReroll.Size = UDim2.new(0.25, 0, 1, 0)
	oReroll.Position = UDim2.new(1, 0, 0.5, 0)
	oReroll.AnchorPoint = Vector2.new(1, 0.5)
	oReroll.BackgroundColor3 = Color3.fromRGB(140, 40, 140)
	oReroll.Font = Enum.Font.GothamBold; oReroll.TextColor3 = Color3.new(1,1,1)
	oReroll.TextScaled = true; oReroll.RichText = true
	oReroll.ZIndex = 23
	Instance.new("UICorner", oReroll).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(oReroll, 180, 80, 180, 1)
	Instance.new("UITextSizeConstraint", oReroll).MaxTextSize = 16

	brTemplate = Instance.new("Frame")
	brTemplate.Size = UDim2.new(1, 0, 0, 60)
	brTemplate.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	brTemplate.ZIndex = 22
	Instance.new("UICorner", brTemplate).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(brTemplate, 90, 50, 120, 1)
	local brPad = Instance.new("UIPadding", brTemplate)
	brPad.PaddingLeft = UDim.new(0, 10); brPad.PaddingRight = UDim.new(0, 10)

	local brEmblem = Instance.new("ImageLabel", brTemplate)
	brEmblem.Name = "EmblemImage"
	brEmblem.Size = UDim2.new(0, 40, 0, 40)
	brEmblem.Position = UDim2.new(0, 0, 0.5, 0)
	brEmblem.AnchorPoint = Vector2.new(0, 0.5)
	brEmblem.BackgroundTransparency = 1
	brEmblem.ScaleType = Enum.ScaleType.Fit
	brEmblem.ZIndex = 23
	Instance.new("UICorner", brEmblem).CornerRadius = UDim.new(0, 6)

	local brName = Instance.new("TextLabel", brTemplate)
	brName.Name = "NameLabel"
	brName.Size = UDim2.new(0.65, -50, 1, 0)
	brName.Position = UDim2.new(0, 50, 0, 0)
	brName.BackgroundTransparency = 1
	brName.Font = Enum.Font.GothamMedium; brName.TextColor3 = Color3.new(1,1,1)
	brName.TextScaled = true; brName.RichText = true; brName.TextXAlignment = Enum.TextXAlignment.Left
	brName.ZIndex = 23
	Instance.new("UITextSizeConstraint", brName).MaxTextSize = 16

	local brJoin = Instance.new("TextButton", brTemplate)
	brJoin.Name = "JoinBtn"
	brJoin.Size = UDim2.new(0.2, 0, 0.7, 0)
	brJoin.Position = UDim2.new(1, 0, 0.5, 0)
	brJoin.AnchorPoint = Vector2.new(1, 0.5)
	brJoin.Font = Enum.Font.GothamBold; brJoin.TextColor3 = Color3.new(1,1,1)
	brJoin.TextScaled = true; brJoin.RichText = true
	brJoin.ZIndex = 23
	Instance.new("UICorner", brJoin).CornerRadius = UDim.new(0, 4)
	Instance.new("UITextSizeConstraint", brJoin).MaxTextSize = 14
end

local function UpdateTabSizes()
	local visibleTabs = 0
	for _, btn in ipairs(tabContainer:GetChildren()) do
		if btn:IsA("TextButton") and btn.Visible then
			visibleTabs += 1
		end
	end
	local sizeScale = (1 / visibleTabs) - 0.02
	for _, btn in ipairs(tabContainer:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.Size = UDim2.new(sizeScale, 0, 1, 0)
		end
	end
end

local function SelectTab(tabName)
	SFXManager.Play("Click")
	infoPage.Visible = (tabName == "Info")
	upgPage.Visible = (tabName == "Upgrades")
	ordPage.Visible = (tabName == "Orders")
	settingsPage.Visible = (tabName == "Settings")

	for _, btn in ipairs(tabContainer:GetChildren()) do
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
	noGangContainer = Instance.new("Frame", mainContainer)
	noGangContainer.Name = "NoGangContainer"
	noGangContainer.Size = UDim2.new(0.96, 0, 0.96, 0)
	noGangContainer.Position = UDim2.new(0.02, 0, 0.02, 0)
	noGangContainer.BackgroundTransparency = 1
	noGangContainer.Visible = false

	local createCard = CreateCard("CreateCard", noGangContainer, UDim2.new(0.3, 0, 1, 0), UDim2.new(0, 0, 0, 0))
	local cPad = Instance.new("UIPadding", createCard)
	cPad.PaddingTop = UDim.new(0.05, 0); cPad.PaddingBottom = UDim.new(0.05, 0)
	cPad.PaddingLeft = UDim.new(0.05, 0); cPad.PaddingRight = UDim.new(0.05, 0)

	local cLayout = Instance.new("UIListLayout", createCard)
	cLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cLayout.Padding = UDim.new(0, 20)
	cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	local cTitle = Instance.new("TextLabel", createCard)
	cTitle.Size = UDim2.new(1, 0, 0, 35)
	cTitle.BackgroundTransparency = 1
	cTitle.Font = Enum.Font.GothamBlack
	cTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	cTitle.TextScaled = true
	cTitle.RichText = true
	cTitle.Text = "CREATE A GANG"
	cTitle.ZIndex = 22
	cTitle.LayoutOrder = 1
	Instance.new("UITextSizeConstraint", cTitle).MaxTextSize = 24

	local nameInput = Instance.new("TextBox", createCard)
	nameInput.Name = "NameInput"
	nameInput.Size = UDim2.new(1, 0, 0, 45)
	nameInput.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	nameInput.Font = Enum.Font.GothamBold
	nameInput.TextColor3 = Color3.new(1,1,1)
	nameInput.PlaceholderText = "Enter Name (Max 15 Chars)"
	nameInput.Text = ""
	nameInput.TextScaled = true
	nameInput.ZIndex = 22
	nameInput.LayoutOrder = 2
	Instance.new("UICorner", nameInput).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(nameInput, 150, 100, 200, 1)

	local costLbl = Instance.new("TextLabel", createCard)
	costLbl.Size = UDim2.new(1, 0, 0, 25)
	costLbl.BackgroundTransparency = 1
	costLbl.Font = Enum.Font.GothamMedium
	costLbl.TextColor3 = Color3.fromRGB(85, 255, 85)
	costLbl.TextScaled = true
	costLbl.RichText = true
	costLbl.Text = "Cost: ¥500,000"
	costLbl.ZIndex = 22
	costLbl.LayoutOrder = 3
	Instance.new("UITextSizeConstraint", costLbl).MaxTextSize = 16

	local createBtn = Instance.new("TextButton", createCard)
	createBtn.Name = "CreateBtn"
	createBtn.Size = UDim2.new(1, 0, 0, 45)
	createBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	createBtn.Font = Enum.Font.GothamBold
	createBtn.TextColor3 = Color3.new(1,1,1)
	createBtn.TextScaled = true
	createBtn.RichText = true
	createBtn.Text = "Form Gang"
	createBtn.ZIndex = 22
	createBtn.LayoutOrder = 4
	Instance.new("UICorner", createBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(createBtn, 100, 255, 100, 1)
	Instance.new("UITextSizeConstraint", createBtn).MaxTextSize = 20

	createBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if nameInput.Text and string.len(nameInput.Text) >= 3 then Network.GangAction:FireServer("Create", nameInput.Text) end
	end)

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
	bTitle.RichText = true
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
	hasGangContainer = Instance.new("Frame", mainContainer)
	hasGangContainer.Name = "HasGangContainer"
	hasGangContainer.Size = UDim2.new(0.96, 0, 0.96, 0)
	hasGangContainer.Position = UDim2.new(0.02, 0, 0.02, 0)
	hasGangContainer.BackgroundTransparency = 1
	hasGangContainer.Visible = false

	tabContainer = Instance.new("Frame", hasGangContainer)
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, 0, 0.1, 0)
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = 22

	local nLayout = Instance.new("UIListLayout", tabContainer)
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
		b.RichText = true
		b.Text = txt
		b.ZIndex = 22
		b.LayoutOrder = order
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		AddBtnStroke(b, 90, 50, 120, 1)
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 16
		b.Parent = tabContainer
		return b
	end

	local btnInfo = CreateNavBtn("BtnInfo", "INFO", 1)
	local btnUpg = CreateNavBtn("BtnUpgrades", "UPGRADES", 2)
	local btnOrd = CreateNavBtn("BtnOrders", "ORDERS", 3)
	local btnSet = CreateNavBtn("BtnSettings", "SETTINGS", 4)
	btnSet.Visible = false

	btnInfo.MouseButton1Click:Connect(function() SelectTab("Info") end)
	btnUpg.MouseButton1Click:Connect(function() SelectTab("Upgrades") end)
	btnOrd.MouseButton1Click:Connect(function() SelectTab("Orders") end)
	btnSet.MouseButton1Click:Connect(function() SelectTab("Settings") end)

	pagesContainer = Instance.new("Frame", hasGangContainer)
	pagesContainer.Name = "PagesContainer"
	pagesContainer.Size = UDim2.new(1, 0, 0.88, 0)
	pagesContainer.Position = UDim2.new(0, 0, 0.12, 0)
	pagesContainer.BackgroundTransparency = 1
	pagesContainer.ZIndex = 21

	-- INFO FRAME
	infoPage = Instance.new("Frame", pagesContainer)
	infoPage.Name = "InfoPage"
	infoPage.Size = UDim2.new(1, 0, 1, 0)
	infoPage.BackgroundTransparency = 1
	infoPage.Visible = true

	local headerCard = CreateCard("HeaderCard", infoPage, UDim2.new(1, 0, 0.35, 0), UDim2.new(0, 0, 0, 0))
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
	titleLabel.RichText = true
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
	levelLabel.RichText = true
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
	mottoLabel.RichText = true
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
	repLabel.Size = UDim2.new(1, -10, 1, 0)
	repLabel.Position = UDim2.new(0, 5, 0, 0)
	repLabel.BackgroundTransparency = 1
	repLabel.Font = Enum.Font.GothamBold
	repLabel.TextColor3 = Color3.new(1, 1, 1)
	repLabel.TextScaled = true
	repLabel.RichText = true
	repLabel.TextXAlignment = Enum.TextXAlignment.Left
	repLabel.ZIndex = 24
	Instance.new("UITextSizeConstraint", repLabel).MaxTextSize = 12

	treasuryLabel = Instance.new("TextLabel", infoBox)
	treasuryLabel.Size = UDim2.new(0.5, 0, 0.25, 0)
	treasuryLabel.Position = UDim2.new(0, 0, 0.75, 0)
	treasuryLabel.BackgroundTransparency = 1
	treasuryLabel.Font = Enum.Font.GothamBold
	treasuryLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
	treasuryLabel.TextScaled = true
	treasuryLabel.RichText = true
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

	local dualContainer = Instance.new("Frame", infoPage)
	dualContainer.Name = "DualContainer"
	dualContainer.Size = UDim2.new(1, 0, 0.65, 0)
	dualContainer.Position = UDim2.new(0, 0, 0.35, 0)
	dualContainer.BackgroundTransparency = 1

	membersCard = CreateCard("MembersCard", dualContainer, UDim2.new(0.68, 0, 1, 0), UDim2.new(0, 0, 0, 0))
	local mcPad = Instance.new("UIPadding", membersCard)
	mcPad.PaddingTop = UDim.new(0.04, 0); mcPad.PaddingBottom = UDim.new(0.04, 0)
	mcPad.PaddingLeft = UDim.new(0.04, 0); mcPad.PaddingRight = UDim.new(0.04, 0)

	local mcTop = Instance.new("Frame", membersCard)
	mcTop.Size = UDim2.new(1, 0, 0, 30)
	mcTop.BackgroundTransparency = 1
	mcTop.ZIndex = 22

	local mTitle = Instance.new("TextLabel", mcTop)
	mTitle.Size = UDim2.new(1, 0, 1, 0)
	mTitle.BackgroundTransparency = 1
	mTitle.Font = Enum.Font.GothamBlack
	mTitle.TextColor3 = Color3.fromRGB(50, 255, 255)
	mTitle.TextScaled = true
	mTitle.RichText = true
	mTitle.TextXAlignment = Enum.TextXAlignment.Left
	mTitle.Text = "MEMBERS"
	mTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", mTitle).MaxTextSize = 20

	membersList = Instance.new("ScrollingFrame", membersCard)
	membersList.Size = UDim2.new(1, 0, 1, -30)
	membersList.Position = UDim2.new(0, 0, 0, 30)
	membersList.BackgroundTransparency = 1
	membersList.ScrollBarThickness = 6
	membersList.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	membersList.ZIndex = 22

	local msLayout = Instance.new("UIListLayout", membersList)
	msLayout.SortOrder = Enum.SortOrder.LayoutOrder
	msLayout.Padding = UDim.new(0, 8)
	local msPad = Instance.new("UIPadding", membersList)
	msPad.PaddingTop = UDim.new(0, 5); msPad.PaddingLeft = UDim.new(0, 5); msPad.PaddingRight = UDim.new(0, 10)

	requestsCard = CreateCard("RequestsCard", dualContainer, UDim2.new(0.3, 0, 1, 0), UDim2.new(0.7, 0, 0, 0))
	local rcPad = Instance.new("UIPadding", requestsCard)
	rcPad.PaddingTop = UDim.new(0.04, 0); rcPad.PaddingBottom = UDim.new(0.04, 0)
	rcPad.PaddingLeft = UDim.new(0.04, 0); rcPad.PaddingRight = UDim.new(0.04, 0)

	local rTitle = Instance.new("TextLabel", requestsCard)
	rTitle.Size = UDim2.new(1, 0, 0, 30)
	rTitle.BackgroundTransparency = 1
	rTitle.Font = Enum.Font.GothamBlack
	rTitle.TextColor3 = Color3.fromRGB(255, 140, 0)
	rTitle.TextScaled = true
	rTitle.RichText = true
	rTitle.TextXAlignment = Enum.TextXAlignment.Left
	rTitle.Text = "REQUESTS"
	rTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", rTitle).MaxTextSize = 20

	requestsList = Instance.new("ScrollingFrame", requestsCard)
	requestsList.Size = UDim2.new(1, 0, 1, -30)
	requestsList.Position = UDim2.new(0, 0, 0, 30)
	requestsList.BackgroundTransparency = 1
	requestsList.ScrollBarThickness = 6
	requestsList.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	requestsList.ZIndex = 22

	local rlLayout = Instance.new("UIListLayout", requestsList)
	rlLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rlLayout.Padding = UDim.new(0, 8)
	local rlPad = Instance.new("UIPadding", requestsList)
	rlPad.PaddingTop = UDim.new(0, 5); rlPad.PaddingLeft = UDim.new(0, 5); rlPad.PaddingRight = UDim.new(0, 10)

	-- UPGRADES PAGE
	upgPage = Instance.new("Frame", pagesContainer)
	upgPage.Name = "UpgradesPage"
	upgPage.Size = UDim2.new(1, 0, 1, 0)
	upgPage.BackgroundTransparency = 1
	upgPage.Visible = false

	local donationCard = CreateCard("DonationCard", upgPage, UDim2.new(1, 0, 0.15, 0), UDim2.new(0, 0, 0, 0))
	local dPad = Instance.new("UIPadding", donationCard)
	dPad.PaddingTop = UDim.new(0, 10); dPad.PaddingBottom = UDim.new(0, 10)
	dPad.PaddingLeft = UDim.new(0, 15); dPad.PaddingRight = UDim.new(0, 15)

	local dLayout = Instance.new("UIListLayout", donationCard)
	dLayout.FillDirection = Enum.FillDirection.Horizontal
	dLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dLayout.Padding = UDim.new(0.02, 0)

	treasuryLabel = Instance.new("TextLabel", donationCard)
	treasuryLabel.Size = UDim2.new(0.2, 0, 1, 0)
	treasuryLabel.BackgroundTransparency = 1
	treasuryLabel.Font = Enum.Font.GothamBold
	treasuryLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
	treasuryLabel.TextScaled = true
	treasuryLabel.RichText = true
	treasuryLabel.TextXAlignment = Enum.TextXAlignment.Left
	treasuryLabel.ZIndex = 22
	treasuryLabel.LayoutOrder = 1
	Instance.new("UITextSizeConstraint", treasuryLabel).MaxTextSize = 16

	donateInput = Instance.new("TextBox", donationCard)
	donateInput.Size = UDim2.new(0.35, 0, 1, 0)
	donateInput.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	donateInput.Font = Enum.Font.GothamBold
	donateInput.TextColor3 = Color3.fromRGB(85, 255, 85)
	donateInput.PlaceholderText = "Amount to Donate (Min 1k)"
	donateInput.Text = ""
	donateInput.TextScaled = true
	donateInput.ZIndex = 22
	donateInput.LayoutOrder = 2
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
	donateBtn.LayoutOrder = 3
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
	boostsBtn.LayoutOrder = 4
	Instance.new("UICorner", boostsBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(boostsBtn, 255, 215, 50, 1)

	boostsBtn.MouseEnter:Connect(function() if cachedTooltipMgr and cachedTooltipMgr.Show then cachedTooltipMgr.Show(currentBoostText) end end)
	boostsBtn.MouseLeave:Connect(function() if cachedTooltipMgr and cachedTooltipMgr.Hide then cachedTooltipMgr.Hide() end end)

	buildingList = Instance.new("Frame", upgPage)
	buildingList.Size = UDim2.new(1, 0, 0.82, 0)
	buildingList.Position = UDim2.new(0, 0, 0.18, 0)
	buildingList.BackgroundTransparency = 1
	buildingList.ZIndex = 22

	local usLayout = Instance.new("UIListLayout", buildingList)
	usLayout.SortOrder = Enum.SortOrder.LayoutOrder
	usLayout.Padding = UDim.new(0.015, 0)

	-- ORDERS PAGE
	ordPage = Instance.new("Frame", pagesContainer)
	ordPage.Name = "OrdersPage"
	ordPage.Size = UDim2.new(1, 0, 1, 0)
	ordPage.BackgroundTransparency = 1
	ordPage.Visible = false

	ordersTimerLbl = Instance.new("TextLabel", ordPage)
	ordersTimerLbl.Size = UDim2.new(1, 0, 0.1, 0)
	ordersTimerLbl.BackgroundTransparency = 1
	ordersTimerLbl.Font = Enum.Font.GothamBlack
	ordersTimerLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	ordersTimerLbl.TextScaled = true
	ordersTimerLbl.RichText = true
	ordersTimerLbl.Text = "Next Orders in: --:--:--"
	ordersTimerLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", ordersTimerLbl).MaxTextSize = 24

	ordersList = Instance.new("Frame", ordPage)
	ordersList.Size = UDim2.new(1, 0, 0.88, 0)
	ordersList.Position = UDim2.new(0, 0, 0.12, 0)
	ordersList.BackgroundTransparency = 1
	ordersList.ZIndex = 22

	local osLayout = Instance.new("UIListLayout", ordersList)
	osLayout.SortOrder = Enum.SortOrder.LayoutOrder
	osLayout.Padding = UDim.new(0.015, 0)

	-- SETTINGS PAGE
	settingsPage = Instance.new("Frame", pagesContainer)
	settingsPage.Name = "SettingsPage"
	settingsPage.Size = UDim2.new(1, 0, 1, 0)
	settingsPage.BackgroundTransparency = 1
	settingsPage.Visible = false

	settingsCard = Instance.new("ScrollingFrame", settingsPage)
	settingsCard.Name = "SetScroll"
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

	local function BuildSettingsField(order, title, placeholder, isNumeric, actionKey)
		local row = CreateCard("Set_"..order, settingsCard, UDim2.new(1, 0, 0, 50), nil)
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
		tLbl.RichText = true
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.Text = title
		tLbl.ZIndex = 22
		Instance.new("UITextSizeConstraint", tLbl).MaxTextSize = 14

		local input = Instance.new("TextBox", row)
		input.Name = "Input"
		input.Size = UDim2.new(0.4, 0, 0.8, 0)
		input.Position = UDim2.new(0.35, 0, 0.1, 0)
		input.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
		input.Font = Enum.Font.GothamMedium
		input.TextColor3 = Color3.new(1,1,1)
		input.PlaceholderText = placeholder
		input.Text = ""
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
		saveBtn.RichText = true
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
				input.Text = ""
			end
		end)

		if actionKey == "ToggleJoinMode" then
			input.Visible = false
			saveBtn.Size = UDim2.new(0.4, 0, 0.8, 0)
			saveBtn.Position = UDim2.new(0.35, 0, 0.1, 0)
			saveBtn.AnchorPoint = Vector2.new(0, 0)
			joinModeBtn = saveBtn
			joinModeBtn.Text = "Join Mode"
			joinModeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("ToggleJoinMode") end)
		end

		if actionKey == "UpdatePrestigeReq" then reqInput = input; reqBtn = saveBtn end
	end

	BuildSettingsField(0, "Join Mode", "", false, "ToggleJoinMode")
	BuildSettingsField(1, "Gang Motto", "Enter motto...", false, "UpdateMotto")
	BuildSettingsField(2, "Emblem ID", "Enter image ID...", false, "UpdateEmblem")
	BuildSettingsField(3, "Prestige Req.", "Current: 0", true, "UpdatePrestigeReq")

	local function BuildRoleSet(order, rKey, title)
		local row = CreateCard("SetRole_"..order, settingsCard, UDim2.new(1, 0, 0, 50), nil)
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
		tLbl.RichText = true
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.Text = title .. " Name"
		tLbl.ZIndex = 22
		Instance.new("UITextSizeConstraint", tLbl).MaxTextSize = 14

		local input = Instance.new("TextBox", row)
		input.Name = "Input"
		input.Size = UDim2.new(0.4, 0, 0.8, 0)
		input.Position = UDim2.new(0.35, 0, 0.1, 0)
		input.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
		input.Font = Enum.Font.GothamMedium
		input.TextColor3 = Color3.new(1,1,1)
		input.PlaceholderText = "Enter role name..."
		input.Text = ""
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
		saveBtn.RichText = true
		saveBtn.Text = "Update"
		saveBtn.ZIndex = 22
		Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
		AddBtnStroke(saveBtn, 100, 255, 100, 1)
		Instance.new("UITextSizeConstraint", saveBtn).MaxTextSize = 14

		saveBtn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			local val = input.Text
			if val ~= "" then
				Network.GangAction:FireServer("RenameRole", val, rKey)
				input.Text = ""
			end
		end)
	end

	BuildRoleSet(4, "Boss", "Boss")
	BuildRoleSet(5, "Consigliere", "Consigliere")
	BuildRoleSet(6, "Caporegime", "Caporegime")
	BuildRoleSet(7, "Grunt", "Grunt")

	local disBtn = Instance.new("TextButton", settingsCard)
	disBtn.Size = UDim2.new(1, 0, 0, 40)
	disBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	disBtn.Font = Enum.Font.GothamBold
	disBtn.TextColor3 = Color3.new(1,1,1)
	disBtn.TextScaled = true
	disBtn.RichText = true
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

	SelectTab("Info")
end

function GangsTab.Init(parentFrame, tooltipMgr, focusFunc)
	mainContainer = parentFrame
	cachedTooltipMgr = tooltipMgr
	forceTabFocus = focusFunc

	BuildCodeTemplates()
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
				local row = brTemplate:Clone()
				row.Visible = true
				row.Parent = browserList

				local emb = row:FindFirstChild("EmblemImage")
				if emb then
					emb.Image = (g.Emblem and g.Emblem ~= "" and g.Emblem ~= "0") and g.Emblem or "rbxassetid://133872443057434"
				end

				local reqText = (g.Req and g.Req > 0) and " <font color='#FFAA00'>[Pres " .. g.Req .. "+]</font>" or ""
				row:FindFirstChild("NameLabel").Text = "<b>" .. g.Name .. "</b> <font size='12' color='#AAAAAA'>(" .. g.Members .. "/30)</font>" .. reqText .. "\n<font size='12' color='#CCCCCC'><i>" .. (g.Motto or "No motto set.") .. "</i></font>"

				row:FindFirstChild("JoinBtn").Text = g.Mode == "Open" and "Join" or "Request"
				row:FindFirstChild("JoinBtn").BackgroundColor3 = g.Mode == "Open" and Color3.fromRGB(40, 140, 40) or Color3.fromRGB(200, 150, 0)
				row:FindFirstChild("JoinBtn").MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("RequestJoin", g.Name) end)
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

function GangsTab.HandleUpdate(action, data)
	if not data or data.HasGang == false then
		if hasGangContainer then hasGangContainer.Visible = false end
		if noGangContainer then noGangContainer.Visible = true end
		if titleLabel then titleLabel.Text = "LOADING..." end
		if mottoLabel then mottoLabel.Text = "<i>...</i>" end
		if emblemImage then emblemImage.Image = "" end
		lastOrderResetTime = 0
		activeUpgradeFinishTime = 0
		activeUpgradeBtnRef = nil
		for _, c in pairs(membersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		for _, c in pairs(requestsList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		for _, c in pairs(buildingList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		for _, c in pairs(ordersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		return
	end

	if noGangContainer then noGangContainer.Visible = false end
	if hasGangContainer then hasGangContainer.Visible = true end

	local gData = data.GangData
	local myRole = data.MyRole
	local myPower = RolePower[myRole] or 1

	local settingsTabBtn = tabContainer:FindFirstChild("BtnSettings")
	if settingsTabBtn then
		settingsTabBtn.Visible = (myRole == "Boss")
		UpdateTabSizes()
	end

	if settingsPage and settingsPage.Visible and myRole ~= "Boss" then
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
		infoPage.Visible = true
		upgPage.Visible = false
		ordPage.Visible = false
		settingsPage.Visible = false
	end

	if titleLabel then titleLabel.Text = gData.Name:upper() .. " <font size='16' color='#AAAAAA'>(" .. (gData.MemberCount or 1) .. "/30)</font>" end
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
	if treasuryLabel then treasuryLabel.Text = "Treasury: <b>¥" .. FormatNumber(gData.Treasury or 0) .. "</b>" end

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
			requestsCard.Visible = true; membersCard.Size = UDim2.new(0.68, 0, 1, 0)
		else 
			requestsCard.Visible = false; membersCard.Size = UDim2.new(1, 0, 1, 0) 
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
	for _, mem in ipairs(memArray) do
		local uIdStr = tostring(mem.UserId)
		local targetPower = RolePower[mem.Role] or 1

		local row = memTemplate:Clone()
		row.Visible = true
		row.Parent = membersList

		local statCol = mem.IsOnline and "#55FF55" or "#AAAAAA"
		local displayRoleName = customRoles[mem.Role] or mem.Role

		row:FindFirstChild("NameLabel").Text = "<b>" .. mem.Name .. "</b> <font color='"..statCol.."'>●</font> <b><font color='" .. (RoleColors[mem.Role] or "#FFFFFF") .. "'>(" .. displayRoleName .. ")</font></b>"
		row:FindFirstChild("TimeLabel").Text = FormatTimeAgo(mem.LastOnline)

		row.MouseEnter:Connect(function()
			if cachedTooltipMgr and cachedTooltipMgr.Show then
				cachedTooltipMgr.Show(string.format("<b>%s</b>, %s\n<font color='#55FFFF'>Prestige %d</font>, <font color='#AAAAAA'>%s</font>\n<font color='#55FF55'>Treasury Contribution: ¥%s</font>", mem.Name, FormatTimeAgo(mem.LastOnline), mem.Prestige or 0, FormatPlayTime(mem.PlayTime or 0), FormatNumber(mem.Contribution or 0)))
			end
		end)
		row.MouseLeave:Connect(function() if cachedTooltipMgr and cachedTooltipMgr.Hide then cachedTooltipMgr.Hide() end end)

		local acts = row:FindFirstChild("Actions")
		if acts then
			local kBtn = acts:FindFirstChild("KickBtn"); local pBtn = acts:FindFirstChild("PromoteBtn"); local dBtn = acts:FindFirstChild("DemoteBtn")

			if uIdStr ~= tostring(player.UserId) then
				if myRole == "Boss" then
					kBtn.Visible = true; pBtn.Visible = (mem.Role ~= "Consigliere"); dBtn.Visible = (mem.Role ~= "Grunt")
				elseif myRole == "Consigliere" and targetPower <= RolePower["Caporegime"] then
					kBtn.Visible = true
				end

				local pk = false
				kBtn.MouseButton1Click:Connect(function()
					SFXManager.Play("Click")
					if pk then Network.GangAction:FireServer("Kick", mem.UserId)
					else pk = true; kBtn.Text = "Sure?"; task.delay(3, function() if pk then pk = false; kBtn.Text = "Kick" end end) end
				end)
				pBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("Promote", mem.UserId) end)
				dBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("Demote", mem.UserId) end)
			end
		end
	end
	task.delay(0.05, function()
		local l = membersList:FindFirstChildWhichIsA("UIListLayout")
		if l then membersList.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
	end)

	for _, c in pairs(requestsList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	if shouldShowRequests and gData.Requests then
		for uId, reqName in pairs(gData.Requests) do
			local row = reqTemplate:Clone()
			row.Visible = true
			row.Parent = requestsList
			row:FindFirstChild("NameLabel").Text = reqName
			row:FindFirstChild("YesBtn").MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("AcceptRequest", uId) end)
			row:FindFirstChild("NoBtn").MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("DenyRequest", uId) end)
		end
		task.delay(0.05, function()
			local l = requestsList:FindFirstChildWhichIsA("UIListLayout")
			if l then requestsList.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
		end)
	end

	for _, c in pairs(buildingList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
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

	for _, conf in ipairs(bConfigs) do
		local row = buildTpl:Clone(); row.Visible = true; row.Parent = buildingList
		local cLvl = (gData.Buildings and gData.Buildings[conf.Id]) or 0
		row:FindFirstChild("NameLabel").Text = conf.Name .. " <font color='#FFFFFF'>(Lv."..cLvl.."/"..conf.Max..")</font>"
		row:FindFirstChild("DescLbl").Text = conf.Desc

		local uBtn = row:FindFirstChild("UpgradeBtn")
		local costLbl = row:FindFirstChild("CostLbl")

		if cLvl < conf.Max then
			costLbl.Text = "Cost: ¥100,000,000"
			if activeUpgradeId == conf.Id then activeUpgradeBtnRef = uBtn; uBtn.Text = "Starting..."; uBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 20)
			elseif activeUpgradeId ~= nil then uBtn.Text = "Busy"; uBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			elseif level < conf.ReqLevel then uBtn.Text = "Requires Gang Lv." .. conf.ReqLevel; uBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else uBtn.Text = "Upgrade"; uBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.GangAction:FireServer("UpgradeBuilding", conf.Id) end) end
			if myPower < RolePower["Consigliere"] then uBtn.Visible = false end
		else
			costLbl.Text = "<font color='#FFD700'>MAX LEVEL REACHED</font>"
			uBtn.Visible = false
		end
	end

	for _, c in pairs(ordersList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	if gData.Orders then
		for i, ord in ipairs(gData.Orders) do
			local row = ordTpl:Clone()
			row.Visible = true 
			row.Parent = ordersList
			row:FindFirstChild("ProgBg"):FindFirstChild("Fill").Size = UDim2.new(math.clamp(ord.Progress / ord.Target, 0, 1), 0, 1, 0)
			row:FindFirstChild("ProgBg"):FindFirstChild("ProgTxt").Text = FormatNumber(ord.Progress) .. " / " .. FormatNumber(ord.Target)

			local taskLbl = row:FindFirstChild("TaskLbl")
			local rBtn = row:FindFirstChild("ActionBtn")

			if ord.Completed then
				taskLbl.Text = "<b>" .. ord.Desc .. "</b>\n<font size='12' color='#55FF55'>[COMPLETED!]</font>"
				if rBtn then rBtn.Visible = false end
			else
				taskLbl.Text = "<b>" .. ord.Desc .. "</b>\n<font size='11' color='#AAAAAA'>Rewards:</font> <font size='11' color='#55FF55'>¥" .. FormatNumber(ord.RewardT) .. "</font> <font size='11' color='#AAAAAA'>|</font> <font size='11' color='#A020F0'>+" .. ord.RewardR .. " Rep</font>"

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

	if myRole == "Boss" and settingsCard then
		for k, v in pairs(gData.RoleNames) do
			local rSet = settingsCard:FindFirstChild("SetRole_" .. k)
			if rSet then rSet:FindFirstChild("Input").Text = v end
		end
	end
end

return GangsTab