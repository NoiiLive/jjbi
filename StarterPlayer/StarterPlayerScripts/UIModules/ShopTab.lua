-- @ScriptType: ModuleScript
local ShopTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local MarketplaceService = game:GetService("MarketplaceService")

local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))
local GiftManager = require(UIModules:WaitForChild("GiftManager"))

local PREMIUM_RESTOCK_PRODUCT_ID = 3548843760

local shopContainer, timerLabel, yenLabel
local cachedTooltipMgr = nil

local rarityColors = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(50, 100, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythical = Color3.fromRGB(255, 50, 50),
	Unique = Color3.fromRGB(215, 69, 255)
}

local premiumItems = {
	{ Type = "Product", Id = 3553771635, Name = "Saint's Corpse Part (x10)", Price = 400, Desc = "<b><font color='#FFD700'>Saint's Corpse Part (x10)</font></b>\nGives you <font color='#55FF55'>x10 Saint's Corpse Parts</font>." },
	{ Type = "Product", Id = 3550862625, Name = "Stand Arrow (x25)", Price = 250, Desc = "<b><font color='#FFD700'>Stand Arrow (x25)</font></b>\nGives you <font color='#55FF55'>x25 Stand Arrows</font>." },
	{ Type = "Product", Id = 3550862858, Name = "Rokakaka (x5)", Price = 100, Desc = "<b><font color='#FFD700'>Rokakaka (x5)</font></b>\nGives you <font color='#55FF55'>x5 Rokakakas</font>." },

	{ Type = "Product", Id = 3553767064, Name = "Johnny Pack", Price = 1500, Desc = "<b><font color='#FFD700'>Johnny Bundle</font></b>\n<b>Tusk Act 1</b> <font color='#FF55FF'>[Cheerful]</font>, L. Arm, & R. Eye." },
	{ Type = "Product", Id = 3547646706, Name = "DIO Pack", Price = 1500, Desc = "<b><font color='#FFD700'>DIO Bundle</font></b>\n<b>The World</b> <font color='#FF55FF'>[Vampiric]</font>, Vamp Style, Cape & Knives." },
	{ Type = "Product", Id = 3550839948, Name = "Pucci Pack", Price = 1500, Desc = "<b><font color='#FFD700'>Pucci Bundle</font></b>\n<b>Whitesnake</b> <font color='#FF55FF'>[Blessed]</font>, Green Baby, & Diary." },
	{ Type = "Product", Id = 3547646703, Name = "Jotaro Pack", Price = 1500, Desc = "<b><font color='#FFD700'>Jotaro Bundle</font></b>\n<b>Star Platinum</b> <font color='#FF55FF'>[Overwhelming]</font>, Hat & Diary." },

	{ Type = "Product", Id = 3553764779, Name = "Spin Pack", Price = 200, Desc = "<b><font color='#FFD700'>Spin Bundle</font></b>\n<font color='#5FE625'>Spin Style</font> & Saint's Right Eye." },
	{ Type = "Product", Id = 3548207626, Name = "Hamon Pack", Price = 200, Desc = "<b><font color='#FFD700'>Hamon Bundle</font></b>\n<font color='#FF8855'>Hamon Style</font>, Clackers, & Mask." },
	{ Type = "Product", Id = 3548207336, Name = "Vampire Pack", Price = 200, Desc = "<b><font color='#FFD700'>Vampire Bundle</font></b>\n<font color='#AA00AA'>Vampire Style</font> & Vampire Cape." },
	{ Type = "Product", Id = 3548207175, Name = "Pillarman Pack", Price = 200, Desc = "<b><font color='#FFD700'>Pillarman Bundle</font></b>\n<font color='#FF5555'>Pillarman Style</font> & Aja Stone." },

	{ Type = "Pass", Id = 1731694181, GiftId = 3552102461, Name = "2x Speed", Price = 200, Desc = "<b><font color='#55FFFF'>2x Battle Speed</font></b>\nBattles play out <font color='#55FF55'>twice as fast!</font>", Attr = "Has2xBattleSpeed" },
	{ Type = "Pass", Id = 1732900742, GiftId = 3552102647, Name = "2x Inventory", Price = 100, Desc = "<b><font color='#55FFFF'>2x Inventory</font></b>\nIncreases slots to <font color='#55FF55'>30</font>.", Attr = "Has2xInventory" },
	{ Type = "Pass", Id = 1732842877, GiftId = 3552103016, Name = "2x Drops", Price = 400, Desc = "<b><font color='#55FFFF'>2x Drop Chance</font></b>\n<font color='#55FF55'>Doubles</font> the chance of items dropping.", Attr = "Has2xDropChance" },
	{ Type = "Pass", Id = 1749484465, GiftId = 3557500443, Name = "Auto-Roll", Price = 400, Desc = "<b><font color='#55FFFF'>Auto-Roll</font></b>\nInstantly roll for target Stands/Traits!", Attr = "HasAutoRoll" },
	{ Type = "Pass", Id = 1733160695, GiftId = 3552103567, Name = "Stand Slot 2", Price = 150, Desc = "<b><font color='#55FFFF'>Stand Storage 2</font></b>\nUnlocks the <font color='#FFD700'>second</font> stand slot.", Attr = "HasStandSlot2" },
	{ Type = "Pass", Id = 1732844091, GiftId = 3552103754, Name = "Stand Slot 3", Price = 300, Desc = "<b><font color='#55FFFF'>Stand Storage 3</font></b>\nUnlocks the <font color='#FFD700'>third</font> stand slot.", Attr = "HasStandSlot3" },
	{ Type = "Pass", Id = 1746853452, GiftId = 3554936785, Name = "Style Slot 2", Price = 50, Desc = "<b><font color='#FF8C00'>Style Storage 2</font></b>\nUnlocks the <font color='#55FF55'>second</font> style slot.", Attr = "HasStyleSlot2" },
	{ Type = "Pass", Id = 1745969849, GiftId = 3554936823, Name = "Style Slot 3", Price = 100, Desc = "<b><font color='#FF8C00'>Style Storage 3</font></b>\nUnlocks the <font color='#55FF55'>third</font> style slot.", Attr = "HasStyleSlot3" },
	{ Type = "Pass", Id = 1732129582, GiftId = 3552103397, Name = "Auto Train", Price = 40, Desc = "<b><font color='#55FFFF'>Auto Training</font></b>\nAuto-starts training on join!", Attr = "HasAutoTraining" },
	{ Type = "Pass", Id = 1749586333, GiftId = 3557535781, Name = "Custom Horse", Price = 40, Desc = "<b><font color='#55FFFF'>Horse Name</font></b>\nAbility to <font color='#55FF55'>name your horse</font>!", Attr = "HasHorseNamePass" },
}

local function FormatTime(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

local function applyDoubleGoldBorder(parent)
	local outerStroke = Instance.new("UIStroke")
	outerStroke.Thickness = 3
	outerStroke.Color = Color3.fromRGB(255, 210, 60)
	outerStroke.LineJoinMode = Enum.LineJoinMode.Round
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradOut = Instance.new("UIGradient")
	gradOut.Rotation = -45
	gradOut.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 160, 30)), 
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 150)), 
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 160, 30))
	}
	gradOut.Parent = outerStroke
	outerStroke.Parent = parent

	local innerFrame = Instance.new("Frame")
	innerFrame.Name = "InnerGoldBorder"
	innerFrame.Size = UDim2.new(1, -6, 1, -6)
	innerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	innerFrame.BackgroundTransparency = 1
	innerFrame.ZIndex = parent.ZIndex
	innerFrame.Parent = parent

	local parentCorner = parent:FindFirstChildOfClass("UICorner")
	if parentCorner then
		local innerCorner = Instance.new("UICorner")
		innerCorner.CornerRadius = UDim.new(0, math.max(0, parentCorner.CornerRadius.Offset - 3))
		innerCorner.Parent = innerFrame
	end

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Thickness = 1
	innerStroke.Color = Color3.fromRGB(255, 230, 100)
	innerStroke.LineJoinMode = Enum.LineJoinMode.Round
	innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradIn = Instance.new("UIGradient")
	gradIn.Rotation = 45
	gradIn.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)), 
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 25))
	}
	gradIn.Parent = innerStroke
	innerStroke.Parent = innerFrame
end

local function CreateCard(name, parent, size, layoutOrder)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	frame.LayoutOrder = layoutOrder
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

	local uip = Instance.new("UIPadding")
	uip.PaddingTop = UDim.new(0, 8)
	uip.PaddingBottom = UDim.new(0, 8)
	uip.PaddingLeft = UDim.new(0, 8)
	uip.PaddingRight = UDim.new(0, 8)
	uip.Parent = frame

	return frame
end

local function CreateTitle(parent, text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextColor3 = Color3.fromRGB(255, 215, 50)
	lbl.TextScaled = false
	lbl.TextSize = 14
	lbl.LayoutOrder = 1
	lbl.ZIndex = 22
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.Parent = parent

	return lbl
end

function ShopTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr

	-- ========================================================
	-- MAIN FRAME SETUP
	-- ========================================================
	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0.85, 0, 0.85, 0)
	mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
	mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	mainPanel.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	mainPanel.BorderSizePixel = 0
	mainPanel.ZIndex = 15
	mainPanel.ClipsDescendants = true
	mainPanel.Parent = parentFrame

	local mpCorner = Instance.new("UICorner")
	mpCorner.CornerRadius = UDim.new(0, 12)
	mpCorner.Parent = mainPanel

	applyDoubleGoldBorder(mainPanel)

	local bgPattern = Instance.new("ImageLabel")
	bgPattern.Name = "OverlayPattern"
	bgPattern.Image = "rbxassetid://79623015802180"
	bgPattern.ImageColor3 = Color3.fromRGB(180, 130, 255)
	bgPattern.ImageTransparency = 0.85
	bgPattern.BackgroundTransparency = 1
	bgPattern.ScaleType = Enum.ScaleType.Tile
	bgPattern.TileSize = UDim2.new(0, 500, 0, 250)
	bgPattern.Size = UDim2.new(1, 0, 1, 0)
	bgPattern.ZIndex = 16
	bgPattern.Parent = mainPanel

	local camera = workspace.CurrentCamera
	local function UpdateLayoutForScreen()
		if not parentFrame.Parent then return end
		local vp = camera.ViewportSize
		if vp.X >= 1050 then 
			mainPanel.Size = UDim2.new(0.80, 0, 0.88, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
		elseif vp.X >= 600 and vp.X < 1050 then 
			mainPanel.Size = UDim2.new(0.92, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
		else 
			mainPanel.Size = UDim2.new(0.96, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0) 
		end
	end

	camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
	UpdateLayoutForScreen()

	local innerContent = Instance.new("Frame")
	innerContent.Name = "InnerContent"
	innerContent.Size = UDim2.new(1, 0, 1, 0)
	innerContent.BackgroundTransparency = 1
	innerContent.ZIndex = 17
	innerContent.Parent = mainPanel

	local mainPad = Instance.new("UIPadding")
	mainPad.PaddingTop = UDim.new(0.02, 0)
	mainPad.PaddingBottom = UDim.new(0.02, 0)
	mainPad.PaddingLeft = UDim.new(0.02, 0)
	mainPad.PaddingRight = UDim.new(0.02, 0)
	mainPad.Parent = innerContent

	local mainLayout = Instance.new("UIListLayout")
	mainLayout.FillDirection = Enum.FillDirection.Vertical
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainLayout.Padding = UDim.new(0.02, 0)
	mainLayout.Parent = innerContent

	-- ==========================================
	-- SUB NAVIGATION
	-- ==========================================
	local subNavFrame = Instance.new("Frame")
	subNavFrame.Name = "SubNavFrame"
	subNavFrame.Size = UDim2.new(1, 0, 0.06, 0)
	subNavFrame.BackgroundTransparency = 1
	subNavFrame.LayoutOrder = 1
	subNavFrame.Parent = innerContent

	local subNavL = Instance.new("UIListLayout")
	subNavL.FillDirection = Enum.FillDirection.Horizontal
	subNavL.HorizontalAlignment = Enum.HorizontalAlignment.Center
	subNavL.Padding = UDim.new(0.02, 0)
	subNavL.Parent = subNavFrame

	local marketTabBtn = Instance.new("TextButton")
	marketTabBtn.Size = UDim2.new(0.49, 0, 1, 0)
	marketTabBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 100)
	marketTabBtn.Text = "MARKET"
	marketTabBtn.Font = Enum.Font.GothamBold
	marketTabBtn.TextColor3 = Color3.fromRGB(255, 235, 130)
	marketTabBtn.TextScaled = true
	marketTabBtn.ZIndex = 20
	marketTabBtn.Parent = subNavFrame

	local mCorner = Instance.new("UICorner")
	mCorner.CornerRadius = UDim.new(0, 6)
	mCorner.Parent = marketTabBtn

	local mStr = Instance.new("UIStroke")
	mStr.Color = Color3.fromRGB(255, 215, 50)
	mStr.Thickness = 2
	mStr.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	mStr.Parent = marketTabBtn

	local mUic = Instance.new("UITextSizeConstraint")
	mUic.MaxTextSize = 16
	mUic.Parent = marketTabBtn

	local premiumTabBtn = Instance.new("TextButton")
	premiumTabBtn.Size = UDim2.new(0.49, 0, 1, 0)
	premiumTabBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
	premiumTabBtn.Text = "PREMIUM"
	premiumTabBtn.Font = Enum.Font.GothamBold
	premiumTabBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
	premiumTabBtn.TextScaled = true
	premiumTabBtn.ZIndex = 20
	premiumTabBtn.Parent = subNavFrame

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 6)
	pCorner.Parent = premiumTabBtn

	local pStr = Instance.new("UIStroke")
	pStr.Color = Color3.fromRGB(90, 50, 120)
	pStr.Thickness = 1
	pStr.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pStr.Parent = premiumTabBtn

	local pUic = Instance.new("UITextSizeConstraint")
	pUic.MaxTextSize = 16
	pUic.Parent = premiumTabBtn

	-- ==========================================
	-- TAB CONTAINER
	-- ==========================================
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, 0, 0.90, 0)
	tabContainer.BackgroundTransparency = 1
	tabContainer.LayoutOrder = 2
	tabContainer.Parent = innerContent

	-- ==========================================
	-- MARKET TAB
	-- ==========================================
	local marketTabContent = Instance.new("Frame")
	marketTabContent.Name = "MarketTabContent"
	marketTabContent.Size = UDim2.new(1, 0, 1, 0)
	marketTabContent.BackgroundTransparency = 1
	marketTabContent.Visible = true
	marketTabContent.Parent = tabContainer

	local mTL = Instance.new("UIListLayout")
	mTL.FillDirection = Enum.FillDirection.Vertical
	mTL.SortOrder = Enum.SortOrder.LayoutOrder
	mTL.Padding = UDim.new(0.02, 0)
	mTL.Parent = marketTabContent

	-- Top: Stock Card (50% layout for huge chunk buttons)
	local stockCard = CreateCard("StockCard", marketTabContent, UDim2.new(1, 0, 0.50, 0), 1)

	local scTop = Instance.new("Frame")
	scTop.Size = UDim2.new(1, 0, 0, 20)
	scTop.BackgroundTransparency = 1
	scTop.ZIndex = 21
	scTop.Parent = stockCard

	local shopTitle = CreateTitle(scTop, "ITEM SHOP")
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left

	timerLabel = Instance.new("TextLabel")
	timerLabel.Size = UDim2.new(0.3, 0, 1, 0)
	timerLabel.Position = UDim2.new(0.5, 0, 0, 0)
	timerLabel.AnchorPoint = Vector2.new(0.5, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Font = Enum.Font.GothamMedium
	timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	timerLabel.TextScaled = true
	timerLabel.Text = "Restocks in: --:--:--"
	timerLabel.ZIndex = 22
	timerLabel.Parent = scTop

	local tUic = Instance.new("UITextSizeConstraint")
	tUic.MaxTextSize = 13
	tUic.Parent = timerLabel

	yenLabel = Instance.new("TextLabel")
	yenLabel.Size = UDim2.new(0.3, 0, 1, 0)
	yenLabel.Position = UDim2.new(1, 0, 0, 0)
	yenLabel.AnchorPoint = Vector2.new(1, 0)
	yenLabel.BackgroundTransparency = 1
	yenLabel.Font = Enum.Font.GothamBold
	yenLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
	yenLabel.TextScaled = true
	yenLabel.RichText = true
	yenLabel.Text = "Yen: ¥0"
	yenLabel.TextXAlignment = Enum.TextXAlignment.Right
	yenLabel.ZIndex = 22
	yenLabel.Parent = scTop

	local yUic = Instance.new("UITextSizeConstraint")
	yUic.MaxTextSize = 13
	yUic.Parent = yenLabel

	shopContainer = Instance.new("Frame")
	shopContainer.Size = UDim2.new(1, 0, 1, -25)
	shopContainer.Position = UDim2.new(0, 0, 0, 25)
	shopContainer.BackgroundTransparency = 1
	shopContainer.ZIndex = 21
	shopContainer.Parent = stockCard

	local sGL = Instance.new("UIGridLayout")
	sGL.CellSize = UDim2.new(0.315, 0, 0.45, 0)
	sGL.CellPadding = UDim2.new(0.02, 0, 0.05, 0)
	sGL.SortOrder = Enum.SortOrder.LayoutOrder
	sGL.Parent = shopContainer

	-- Middle: Rates Card (30% vertical height)
	local ratesCard = CreateCard("RatesCard", marketTabContent, UDim2.new(1, 0, 0.30, 0), 2)
	CreateTitle(ratesCard, "DROP RATES")

	local rcSplit = Instance.new("Frame")
	rcSplit.Size = UDim2.new(1, 0, 1, -22)
	rcSplit.Position = UDim2.new(0, 0, 0, 22)
	rcSplit.BackgroundTransparency = 1
	rcSplit.ZIndex = 21
	rcSplit.Parent = ratesCard

	local rcL = Instance.new("UIListLayout")
	rcL.FillDirection = Enum.FillDirection.Horizontal
	rcL.Padding = UDim.new(0.02, 0)
	rcL.Parent = rcSplit

	local standRatesScroll = Instance.new("ScrollingFrame")
	standRatesScroll.Size = UDim2.new(0.49, 0, 1, 0)
	standRatesScroll.BackgroundTransparency = 1
	standRatesScroll.ScrollBarThickness = 4
	standRatesScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	standRatesScroll.ZIndex = 22
	standRatesScroll.Parent = rcSplit

	local standRatesCol = Instance.new("TextLabel")
	standRatesCol.Size = UDim2.new(1, -10, 0, 0)
	standRatesCol.AutomaticSize = Enum.AutomaticSize.Y
	standRatesCol.BackgroundTransparency = 1
	standRatesCol.Font = Enum.Font.GothamMedium
	standRatesCol.TextColor3 = Color3.new(1, 1, 1)
	standRatesCol.TextSize = 12
	standRatesCol.RichText = true
	standRatesCol.TextWrapped = true
	standRatesCol.TextXAlignment = Enum.TextXAlignment.Left
	standRatesCol.TextYAlignment = Enum.TextYAlignment.Top
	standRatesCol.ZIndex = 23
	standRatesCol.Parent = standRatesScroll

	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(0, 2, 1, 0)
	sep.BackgroundColor3 = Color3.fromRGB(90, 50, 120)
	sep.BorderSizePixel = 0
	sep.ZIndex = 22
	sep.Parent = rcSplit

	local traitRatesScroll = Instance.new("ScrollingFrame")
	traitRatesScroll.Size = UDim2.new(0.49, 0, 1, 0)
	traitRatesScroll.BackgroundTransparency = 1
	traitRatesScroll.ScrollBarThickness = 4
	traitRatesScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	traitRatesScroll.ZIndex = 22
	traitRatesScroll.Parent = rcSplit

	local traitRatesCol = Instance.new("TextLabel")
	traitRatesCol.Size = UDim2.new(1, -10, 0, 0)
	traitRatesCol.AutomaticSize = Enum.AutomaticSize.Y
	traitRatesCol.BackgroundTransparency = 1
	traitRatesCol.Font = Enum.Font.GothamMedium
	traitRatesCol.TextColor3 = Color3.new(1, 1, 1)
	traitRatesCol.TextSize = 12
	traitRatesCol.RichText = true
	traitRatesCol.TextWrapped = true
	traitRatesCol.TextXAlignment = Enum.TextXAlignment.Left
	traitRatesCol.TextYAlignment = Enum.TextYAlignment.Top
	traitRatesCol.ZIndex = 23
	traitRatesCol.Parent = traitRatesScroll

	-- Bottom: Codes Card (16% to perfectly anchor to bottom)
	local codesCard = CreateCard("CodesCard", marketTabContent, UDim2.new(1, 0, 0.16, 0), 3)
	CreateTitle(codesCard, "CODES")

	local codeArea = Instance.new("Frame")
	codeArea.Size = UDim2.new(1, 0, 1, -22)
	codeArea.Position = UDim2.new(0, 0, 0, 22)
	codeArea.BackgroundTransparency = 1
	codeArea.ZIndex = 21
	codeArea.Parent = codesCard

	local cL = Instance.new("UIListLayout")
	cL.FillDirection = Enum.FillDirection.Horizontal
	cL.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cL.VerticalAlignment = Enum.VerticalAlignment.Center
	cL.Padding = UDim.new(0.02, 0)
	cL.Parent = codeArea

	local codeInput = Instance.new("TextBox")
	codeInput.Text = "" 
	codeInput.Size = UDim2.new(0.7, 0, 0.8, 0)
	codeInput.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	codeInput.TextColor3 = Color3.new(1, 1, 1)
	codeInput.Font = Enum.Font.GothamBold
	codeInput.TextScaled = true
	codeInput.PlaceholderText = "Enter Code Here..."
	codeInput.ZIndex = 22
	codeInput.Parent = codeArea

	local ciCorner = Instance.new("UICorner")
	ciCorner.CornerRadius = UDim.new(0, 6)
	ciCorner.Parent = codeInput

	local ciStr = Instance.new("UIStroke")
	ciStr.Color = Color3.fromRGB(90, 50, 120)
	ciStr.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	ciStr.Parent = codeInput

	local ciUic = Instance.new("UITextSizeConstraint")
	ciUic.MaxTextSize = 16
	ciUic.Parent = codeInput

	local redeemBtn = Instance.new("TextButton")
	redeemBtn.Size = UDim2.new(0.25, 0, 0.8, 0)
	redeemBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
	redeemBtn.TextColor3 = Color3.new(1, 1, 1)
	redeemBtn.Font = Enum.Font.GothamBold
	redeemBtn.TextScaled = true
	redeemBtn.Text = "Redeem"
	redeemBtn.ZIndex = 22
	redeemBtn.Parent = codeArea

	local rbCorner = Instance.new("UICorner")
	rbCorner.CornerRadius = UDim.new(0, 6)
	rbCorner.Parent = redeemBtn

	local rbStr = Instance.new("UIStroke")
	rbStr.Color = Color3.fromRGB(200, 150, 255)
	rbStr.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rbStr.Parent = redeemBtn

	local rbUic = Instance.new("UITextSizeConstraint")
	rbUic.MaxTextSize = 16
	rbUic.Parent = redeemBtn

	-- ==========================================
	-- PREMIUM TAB
	-- ==========================================
	local premiumTabContent = Instance.new("Frame")
	premiumTabContent.Name = "PremiumTabContent"
	premiumTabContent.Size = UDim2.new(1, 0, 1, 0)
	premiumTabContent.BackgroundTransparency = 1
	premiumTabContent.Visible = false
	premiumTabContent.Parent = tabContainer

	local pTL = Instance.new("UIListLayout")
	pTL.FillDirection = Enum.FillDirection.Vertical
	pTL.SortOrder = Enum.SortOrder.LayoutOrder
	pTL.Padding = UDim.new(0.02, 0)
	pTL.Parent = premiumTabContent

	local prodCard = CreateCard("ProductsCard", premiumTabContent, UDim2.new(1, 0, 0.48, 0), 1)
	CreateTitle(prodCard, "ROBUX BUNDLES & ITEMS")

	local prodScroll = Instance.new("ScrollingFrame")
	prodScroll.Size = UDim2.new(1, 0, 1, -22)
	prodScroll.Position = UDim2.new(0, 0, 0, 22)
	prodScroll.BackgroundTransparency = 1
	prodScroll.ScrollBarThickness = 6
	prodScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	prodScroll.ZIndex = 21
	prodScroll.Parent = prodCard

	local prodPad = Instance.new("UIPadding")
	prodPad.PaddingTop = UDim.new(0, 2)
	prodPad.PaddingLeft = UDim.new(0, 2)
	prodPad.PaddingRight = UDim.new(0, 8)
	prodPad.PaddingBottom = UDim.new(0, 2)
	prodPad.Parent = prodScroll

	local prodGL = Instance.new("UIGridLayout")
	prodGL.CellSize = UDim2.new(0.315, 0, 0, 110)
	prodGL.CellPadding = UDim2.new(0.02, 0, 0, 10)
	prodGL.SortOrder = Enum.SortOrder.LayoutOrder
	prodGL.Parent = prodScroll

	local passCard = CreateCard("PassesCard", premiumTabContent, UDim2.new(1, 0, 0.48, 0), 2)
	CreateTitle(passCard, "GAMEPASSES")

	local passScroll = Instance.new("ScrollingFrame")
	passScroll.Size = UDim2.new(1, 0, 1, -22)
	passScroll.Position = UDim2.new(0, 0, 0, 22)
	passScroll.BackgroundTransparency = 1
	passScroll.ScrollBarThickness = 6
	passScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	passScroll.ZIndex = 21
	passScroll.Parent = passCard

	local passPad = Instance.new("UIPadding")
	passPad.PaddingTop = UDim.new(0, 2)
	passPad.PaddingLeft = UDim.new(0, 2)
	passPad.PaddingRight = UDim.new(0, 8)
	passPad.PaddingBottom = UDim.new(0, 2)
	passPad.Parent = passScroll

	local passGL = Instance.new("UIGridLayout")
	passGL.CellSize = UDim2.new(0.315, 0, 0, 110)
	passGL.CellPadding = UDim2.new(0.02, 0, 0, 10)
	passGL.SortOrder = Enum.SortOrder.LayoutOrder
	passGL.Parent = passScroll

	-- Build Premium Items
	local premLabels = {}
	for i, pInfo in ipairs(premiumItems) do
		local isPass = (pInfo.Type == "Pass")
		local targetScroll = isPass and passScroll or prodScroll

		local itemFrm = Instance.new("Frame")
		itemFrm.BackgroundColor3 = Color3.fromRGB(45, 20, 65)
		itemFrm.LayoutOrder = i
		itemFrm.ZIndex = 22
		itemFrm.Parent = targetScroll

		local frmCorner = Instance.new("UICorner")
		frmCorner.CornerRadius = UDim.new(0, 6)
		frmCorner.Parent = itemFrm

		local iGrad = Instance.new("UIGradient")
		iGrad.Rotation = 45
		iGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 30, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 10, 50))
		}
		iGrad.Parent = itemFrm

		local ifStr = Instance.new("UIStroke")
		ifStr.Color = Color3.fromRGB(255, 215, 50)
		ifStr.Thickness = 2
		ifStr.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ifStr.Parent = itemFrm

		local nLbl = Instance.new("TextLabel")
		nLbl.Size = UDim2.new(1, -10, 0, 20)
		nLbl.Position = UDim2.new(0, 5, 0, 5)
		nLbl.BackgroundTransparency = 1
		nLbl.Font = Enum.Font.GothamBold
		nLbl.TextColor3 = Color3.fromRGB(255, 235, 130)
		nLbl.TextScaled = true
		nLbl.Text = pInfo.Name
		nLbl.TextXAlignment = Enum.TextXAlignment.Left
		nLbl.ZIndex = 23
		nLbl.Parent = itemFrm

		local nlUic = Instance.new("UITextSizeConstraint")
		nlUic.MaxTextSize = 15
		nlUic.Parent = nLbl

		local dLbl = Instance.new("TextLabel")
		dLbl.Size = UDim2.new(1, -10, 1, -60)
		dLbl.Position = UDim2.new(0, 5, 0, 28)
		dLbl.BackgroundTransparency = 1
		dLbl.Font = Enum.Font.GothamMedium
		dLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
		dLbl.TextSize = 12
		dLbl.RichText = true
		dLbl.TextWrapped = true
		dLbl.TextXAlignment = Enum.TextXAlignment.Left
		dLbl.TextYAlignment = Enum.TextYAlignment.Top
		dLbl.Text = pInfo.Desc
		dLbl.ZIndex = 23
		dLbl.Parent = itemFrm

		local buyBtn = Instance.new("TextButton")
		buyBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextColor3 = Color3.new(1, 1, 1)
		buyBtn.TextScaled = true
		buyBtn.Text = tostring(pInfo.Price) .. " R$"
		buyBtn.ZIndex = 24
		buyBtn.Parent = itemFrm

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 4)
		bCorner.Parent = buyBtn

		local bUic = Instance.new("UITextSizeConstraint")
		bUic.MaxTextSize = 13
		bUic.Parent = buyBtn

		if pInfo.Type == "Product" or pInfo.GiftId then
			local giftBtn = Instance.new("TextButton")
			giftBtn.Size = UDim2.new(0.42, 0, 0, 24)
			giftBtn.Position = UDim2.new(0, 5, 1, -29)
			giftBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 20)
			giftBtn.Font = Enum.Font.GothamBold
			giftBtn.TextColor3 = Color3.new(1, 1, 1)
			giftBtn.TextScaled = true
			giftBtn.Text = "Gift"
			giftBtn.ZIndex = 24
			giftBtn.Parent = itemFrm

			local gCorner = Instance.new("UICorner")
			gCorner.CornerRadius = UDim.new(0, 4)
			gCorner.Parent = giftBtn

			local gUic = Instance.new("UITextSizeConstraint")
			gUic.MaxTextSize = 13
			gUic.Parent = giftBtn

			buyBtn.Size = UDim2.new(0.5, 0, 0, 24)
			buyBtn.Position = UDim2.new(1, -5, 1, -29)
			buyBtn.AnchorPoint = Vector2.new(1, 0)

			giftBtn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				GiftManager.OpenGiftModal(pInfo)
			end)
		else
			buyBtn.Size = UDim2.new(1, -10, 0, 24)
			buyBtn.Position = UDim2.new(0, 5, 1, -29)
		end

		buyBtn.MouseButton1Click:Connect(function()
			if pInfo.Attr and player:GetAttribute(pInfo.Attr) then
				return 
			end 
			SFXManager.Play("Click")
			Network.ShopAction:FireServer("SetGiftTarget", 0)
			task.wait(0.1) 
			if isPass then 
				MarketplaceService:PromptGamePassPurchase(player, pInfo.Id)
			else 
				MarketplaceService:PromptProductPurchase(player, pInfo.Id) 
			end
		end)

		if pInfo.Attr then 
			premLabels[pInfo.Attr] = {Btn = buyBtn, Price = pInfo.Price} 
		end
	end

	task.spawn(function()
		task.wait(0.1)
		prodScroll.CanvasSize = UDim2.new(0, 0, 0, prodGL.AbsoluteContentSize.Y + 10)
		passScroll.CanvasSize = UDim2.new(0, 0, 0, passGL.AbsoluteContentSize.Y + 10)
	end)

	-- ==========================================
	-- HOOK UP EVENTS & LOGIC
	-- ==========================================

	marketTabBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		marketTabContent.Visible = true
		premiumTabContent.Visible = false
		marketTabBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 100)
		premiumTabBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
		mStr.Color = Color3.fromRGB(255, 215, 50)
		mStr.Thickness = 2
		pStr.Color = Color3.fromRGB(90, 50, 120)
		pStr.Thickness = 1
		marketTabBtn.TextColor3 = Color3.fromRGB(255, 235, 130)
		premiumTabBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
	end)

	premiumTabBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		marketTabContent.Visible = false
		premiumTabContent.Visible = true
		premiumTabBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 100)
		marketTabBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
		pStr.Color = Color3.fromRGB(255, 215, 50)
		pStr.Thickness = 2
		mStr.Color = Color3.fromRGB(90, 50, 120)
		mStr.Thickness = 1
		premiumTabBtn.TextColor3 = Color3.fromRGB(255, 235, 130)
		marketTabBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
	end)

	redeemBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if codeInput.Text ~= "" then
			Network.RedeemCode:FireServer(codeInput.Text)
			codeInput.Text = ""
		end
	end)

	local function RefreshDropRatesText()
		local currentStand = player:GetAttribute("Stand") or "None"
		local currentTrait = player:GetAttribute("StandTrait") or "None"

		local function BuildPoolString(dataTable, isTrait, currentEquipped)
			local pools = { Common = {}, Uncommon = {}, Rare = {}, Legendary = {}, Mythical = {}, Evolution = {}, Boss = {} }
			local rates = {}

			if isTrait then 
				rates = { Common = "35%", Rare = "16%", Legendary = "6%", Mythical = "1%" }
			else 
				rates = { Common = "50%", Uncommon = "30%", Rare = "15%", Legendary = "5%", Mythical = "1% WORLD BOSS ONLY" } 
			end

			for name, data in pairs(dataTable) do
				if pools[data.Rarity] then 
					table.insert(pools[data.Rarity], name) 
				end
			end

			local str = ""
			local order = {"Common", "Uncommon", "Rare", "Legendary", "Mythical"}
			local hexes = { Common = "#AAAAAA", Uncommon = "#55FF55", Rare = "#55FFFF", Legendary = "#FFD700", Mythical = "#FF55FF" }

			for _, rarity in ipairs(order) do
				if #pools[rarity] > 0 and rates[rarity] then
					table.sort(pools[rarity])
					str = str .. "<b><font color='"..hexes[rarity].."'>"..rarity.." ("..rates[rarity]..")</font></b>\n"

					local formattedNames = {}
					for _, name in ipairs(pools[rarity]) do
						if name == currentEquipped then 
							table.insert(formattedNames, "<u><b><font color='#FFFFFF'>" .. name .. "</font></b></u>")
						else 
							table.insert(formattedNames, name) 
						end
					end
					str = str .. table.concat(formattedNames, ", ") .. "\n\n"
				end
			end

			if not isTrait and #pools["Evolution"] > 0 then
				table.sort(pools["Evolution"])
				str = str .. "<b><font color='#AA00AA'>Evolution</font></b>\n"
				local formattedEvos = {}
				for _, name in ipairs(pools["Evolution"]) do
					if name == currentEquipped then 
						table.insert(formattedEvos, "<u><b><font color='#FFFFFF'>" .. name .. "</font></b></u>")
					else 
						table.insert(formattedEvos, name) 
					end
				end
				str = str .. table.concat(formattedEvos, ", ") .. "\n\n"
			end
			return str
		end

		standRatesCol.Text = "<b><font size='14'>STAND ARROW RATES</font></b>\n<i><font color='#888888'>Guarantees Rare+ every 25 rolls.</font></i>\n\n" .. BuildPoolString(StandData.Stands, false, currentStand)
		traitRatesCol.Text = "<b><font size='14'>ROKAKAKA RATES</font></b>\n<i><font color='#888888'>Guarantees Legendary+ every 5 rolls.</font></i>\n\n" .. BuildPoolString(StandData.Traits, true, currentTrait)

		task.delay(0.1, function()
			standRatesScroll.CanvasSize = UDim2.new(0, 0, 0, standRatesCol.AbsoluteSize.Y + 20)
			traitRatesScroll.CanvasSize = UDim2.new(0, 0, 0, traitRatesCol.AbsoluteSize.Y + 20)
		end)
	end

	player:GetAttributeChangedSignal("Stand"):Connect(RefreshDropRatesText)
	player:GetAttributeChangedSignal("StandTrait"):Connect(RefreshDropRatesText)
	RefreshDropRatesText()

	local function UpdateRobuxUI()
		for attrName, data in pairs(premLabels) do
			if player:GetAttribute(attrName) then
				data.Btn.Text = "OWNED"
				data.Btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				data.Btn.Text = tostring(data.Price) .. " R$"
				data.Btn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
			end
		end
	end

	for attrName, _ in pairs(premLabels) do 
		player:GetAttributeChangedSignal(attrName):Connect(UpdateRobuxUI) 
	end

	UpdateRobuxUI()

	local function RefreshShopItems(stockStr)
		for _, child in pairs(shopContainer:GetChildren()) do 
			if child:IsA("Frame") then 
				child:Destroy() 
			end 
		end

		if not stockStr or stockStr == "" then 
			return 
		end

		local stockData = {}

		if string.sub(stockStr, 1, 1) == "[" then
			local success, decoded = pcall(function() 
				return game:GetService("HttpService"):JSONDecode(stockStr) 
			end)
			if success and decoded then 
				stockData = decoded 
			end
		else
			local items = string.split(stockStr, ",")
			for _, name in ipairs(items) do
				if name ~= "" then
					local data = ItemData.Equipment[name] or ItemData.Consumables[name]
					if data then
						table.insert(stockData, { Name = name, Cost = data.Cost or data.Price or 50, Rarity = data.Rarity or "Common" })
					end
				end
			end
		end

		for _, item in ipairs(stockData) do
			local itemFrame = Instance.new("Frame")
			itemFrame.BackgroundColor3 = Color3.fromRGB(30, 15, 45)
			itemFrame.ZIndex = 22
			itemFrame.Parent = shopContainer

			local iCorner = Instance.new("UICorner")
			iCorner.CornerRadius = UDim.new(0, 6)
			iCorner.Parent = itemFrame

			local iStr = Instance.new("UIStroke")
			iStr.Color = rarityColors[item.Rarity or "Common"]
			iStr.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			iStr.Parent = itemFrame

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, -10, 0.6, 0)
			nameLabel.Position = UDim2.new(0, 5, 0, 5)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Font = Enum.Font.GothamMedium
			nameLabel.TextColor3 = rarityColors[item.Rarity or "Common"]
			nameLabel.TextScaled = true
			nameLabel.TextWrapped = true
			nameLabel.RichText = true
			nameLabel.Text = item.Name .. "\n<font color='#55FF55'>¥" .. (item.Cost or 0) .. "</font>"
			nameLabel.ZIndex = 23
			nameLabel.Parent = itemFrame

			local nlUic = Instance.new("UITextSizeConstraint")
			nlUic.MaxTextSize = 14
			nlUic.Parent = nameLabel

			local buyBtn = Instance.new("TextButton")
			buyBtn.Size = UDim2.new(1, -10, 0.4, -10)
			buyBtn.Position = UDim2.new(0, 5, 1, -5)
			buyBtn.AnchorPoint = Vector2.new(0, 1)
			buyBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextColor3 = Color3.new(1, 1, 1)
			buyBtn.TextScaled = true
			buyBtn.Text = "Buy"
			buyBtn.ZIndex = 24
			buyBtn.Parent = itemFrame

			local bbCorner = Instance.new("UICorner")
			bbCorner.CornerRadius = UDim.new(0, 4)
			bbCorner.Parent = buyBtn

			local bbUic = Instance.new("UITextSizeConstraint")
			bbUic.MaxTextSize = 13
			bbUic.Parent = buyBtn

			buyBtn.MouseButton1Click:Connect(function() 
				SFXManager.Play("Click") 
				Network.ShopAction:FireServer("Buy", item.Name) 
			end)

			itemFrame.MouseEnter:Connect(function() 
				cachedTooltipMgr.Show(cachedTooltipMgr.GetItemTooltip(item.Name)) 
			end)

			itemFrame.MouseLeave:Connect(function()
				cachedTooltipMgr.Hide()
			end)
		end
	end

	-- Catch-all for Shop Notification Routing
	Network:WaitForChild("ShopUpdate").OnClientEvent:Connect(function(action, data)
		if action == "Refresh" then 
			RefreshShopItems(table.concat(data, ",")) 
		elseif type(data) == "string" and (action == "Notify" or action == "Notification" or action == "SystemMessage" or action == "Message" or action == "Error" or action == "Success") then
			NotificationManager.Show(data)
		elseif type(action) == "string" and data == nil then
			-- In case the server passes the message as the action directly
			if action ~= "Refresh" and not string.match(action, "Prompt") then
				NotificationManager.Show(action)
			end
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(passPlayer, passId, wasPurchased)
		if passPlayer == player and wasPurchased then 
			SFXManager.Play("BuyPass") 
			for _, pItem in ipairs(premiumItems) do 
				if pItem.Id == passId and pItem.Attr then 
					player:SetAttribute(pItem.Attr, true) 
				end 
			end
		end
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
		if userId == player.UserId and wasPurchased then 
			SFXManager.Play("BuyPass") 
		end
	end)

	player:GetAttributeChangedSignal("ShopStock"):Connect(function() 
		RefreshShopItems(player:GetAttribute("ShopStock")) 
	end)

	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 5)
		if leaderstats then
			local yen = leaderstats:WaitForChild("Yen", 5)
			if yen then
				yenLabel.Text = "Yen: <font color='#55FF55'>¥" .. yen.Value .. "</font>"
				yen.Changed:Connect(function(val) 
					yenLabel.Text = "Yen: <font color='#55FF55'>¥" .. val .. "</font>" 
				end)
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			local rt = player:GetAttribute("ShopRefreshTime") or 0
			local remain = rt - os.time()
			if remain > 0 then 
				timerLabel.Text = "Restocks in: " .. FormatTime(remain) 
			else 
				timerLabel.Text = "Restocking..." 
			end
		end
	end)

	task.delay(1, function() 
		RefreshShopItems(player:GetAttribute("ShopStock")) 
	end)
end

return ShopTab