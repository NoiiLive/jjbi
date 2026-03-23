-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local SBREventTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local isStudio = RunService:IsStudio()
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local NotificationManager = require(script.Parent:WaitForChild("NotificationManager"))
local CombatTemplate = require(script.Parent:WaitForChild("CombatTemplate"))
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))

local REROLL_ROBUX_PRODUCT_ID = 3554941196

local mainContainer
local lobbyContainer, raceContainer
local timerLbl, queueBtn, queueCountLbl, forceStartBtn
local horseNameLbl, speedValLbl, endValLbl, traitLbl
local upgSpeedBtn, upgEndBtn, upgTimerLbl
local rerollYenBtn, rerollRobuxBtn

local combatUI
local activeFighters = {}
local sbrTopArea, sbrPathArea, rRegionLbl, rDistLbl
local turnTimerLabel, combatResourceLabel, waitingLabel
local stamFill, stamTxt
local safeBtn, restBtn, riskyBtn
local pathBtns, travelStatusLbl

local cachedTooltipMgr = nil
local forceTabFocus = nil
local currentDeadline = 0

local targetName1 = "Select"
local targetName2 = "Select"
local lastPathTime = 0

local Names1 = {
	"Silver","Black","Golden","Midnight","Red","White","Blue","Crimson","Azure","Onyx","Ivory","Ruby","Sapphire","Emerald","Bronze","Copper","Scarlet","Violet",
	"Fast","Swift","Rapid","Lightning","Thunder","Storm","Wild","Blazing","Flying","Charging","Raging","Dashing","Soaring",
	"Brave","Noble","Savage","Fierce","Proud","Grand","Royal","Legendary","Mighty","Valiant","Heroic","Fearless",
	"Fire","Ice","Frost","Solar","Lunar","Iron","Steel","Ghost","Mystic","Holy","Dark","Light","Radiant","Cursed","Blessed","Cosmic","Astral","Arcane","Ancient",
	"Dire","Great","Alpha","Prime","Stormborn","Sunset","Dawn","Dusk","Mountain","Desert","Prairie",
	"Big","Tiny","Massive","Heavy","Thicc","Mini","Giga","Maximum","Ultra","Mega",
	"Slow","Fat","Angry","Derpy","Lazy","Confused","Suspicious","Goofy","Unhinged","Greasy","Wobbly","Crusty","Spicy","Bald","Dank","Certified", "Stupid"
}

local Names2 = {
	"Stallion","Mustang","Bronco","Hoof","Trotter","Galloper","Racer","Trailblazer", "Dancer",
	"Bullet","Runner","Dasher","Sprinter","Chaser","Hunter","Striker","Blade","Arrow","Spear","Crusher","Breaker",
	"Eagle","Falcon","Hawk","Wolf","Tiger","Lion","Bear","Dragon","Cobra","Panther",
	"Comet","Meteor","Nova","Eclipse","Hurricane","Cyclone","Blizzard","Tornado","Storm","Tempest",
	"Knight","Rider","Champ","Hero","Legend","Master","King","Outlaw","Bandit","Marshal",
	"Valkyrie","Phantom","Specter","Wanderer","Drifter","Seeker","Spirit","Fury","Flash",
	"Boi","Unit","Potato","Nugget","Goblin","Meatball","Gremlin","Grandpa","Chungus","Mogger","Goober","Creature","Thing","Lad","Beast", "Idiot", "Chud", "Chad"
}

local StatusIcons = {
	Stun = "STN", Poison = "PSN", Burn = "BRN", Bleed = "BLD", Freeze = "FRZ", Confusion = "CNF",
	Buff_Strength = "STR+", Buff_Defense = "DEF+", Buff_Speed = "SPD+", Buff_Willpower = "WIL+",
	Debuff_Strength = "STR-", Debuff_Defense = "DEF-", Debuff_Speed = "SPD-", Debuff_Willpower = "WIL-"
}

local StatusDescs = {
	Stun = "Cannot move or act.", Poison = "Takes damage every turn.", Burn = "Takes damage every turn.",
	Bleed = "Takes damage every turn.", Freeze = "Frozen solid. Cannot move, takes damage.",
	Confusion = "May attack allies or self.", Buff_Strength = "Increased damage dealt.",
	Buff_Defense = "Reduced damage taken.", Buff_Speed = "Increased evasion and turn priority.",
	Buff_Willpower = "Increased crit and survival chance.", Debuff_Strength = "Reduced damage dealt.",
	Debuff_Defense = "Increased damage taken.", Debuff_Speed = "Reduced evasion and turn priority.",
	Debuff_Willpower = "Reduced crit and survival chance."
}

local function FormatTime(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
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
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(90, 50, 120)
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	return frame
end

local function AddBtnStroke(btn, r, g, b)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(r, g, b)
	s.Thickness = 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = btn
	return s
end

local function CreateDropdown(parentObj, defaultText, itemList, onSelect)
	parentObj.Text = defaultText

	local listFrame = Instance.new("ScrollingFrame")
	listFrame.Size = UDim2.new(1, 0, 0, 120)
	listFrame.Position = UDim2.new(0, 0, 0, -125) 
	listFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	listFrame.ScrollBarThickness = 6
	listFrame.ScrollBarImageColor3 = Color3.fromRGB(120, 60, 180)
	listFrame.ZIndex = 100
	listFrame.Visible = false
	listFrame.Parent = parentObj
	Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)

	local lStr = Instance.new("UIStroke")
	lStr.Color = Color3.fromRGB(255, 215, 50)
	lStr.Thickness = 2
	lStr.Parent = listFrame

	local layout = Instance.new("UIListLayout", listFrame)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	table.sort(itemList)
	for i, opt in ipairs(itemList) do
		local b = Instance.new("TextButton", listFrame)
		b.Size = UDim2.new(1, -6, 0, 30)
		b.BackgroundTransparency = 1
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = opt
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 12
		b.ZIndex = 101

		b.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			parentObj.Text = opt
			listFrame.Visible = false
			onSelect(opt)
		end)
	end
	listFrame.CanvasSize = UDim2.new(0, 0, 0, #itemList * 30)

	parentObj.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		listFrame.Visible = not listFrame.Visible
	end)
end

function SBREventTab.Init(parentFrame, tooltipMgr, focusFunc)
	mainContainer = parentFrame
	cachedTooltipMgr = tooltipMgr
	forceTabFocus = focusFunc

	lobbyContainer = Instance.new("Frame")
	lobbyContainer.Name = "LobbyContainer"
	lobbyContainer.Size = UDim2.new(1, 0, 1, 0)
	lobbyContainer.BackgroundTransparency = 1
	lobbyContainer.Visible = true
	lobbyContainer.Parent = mainContainer

	local lcPad = Instance.new("UIPadding")
	lcPad.PaddingTop = UDim.new(0.02, 0); lcPad.PaddingBottom = UDim.new(0.02, 0)
	lcPad.PaddingLeft = UDim.new(0.02, 0); lcPad.PaddingRight = UDim.new(0.02, 0)
	lcPad.Parent = lobbyContainer

	local stableCard = CreateCard("StableCard", lobbyContainer, UDim2.new(0.48, 0, 1, 0), UDim2.new(0, 0, 0, 0))

	local scPad = Instance.new("UIPadding")
	scPad.PaddingTop = UDim.new(0, 15); scPad.PaddingBottom = UDim.new(0, 15)
	scPad.PaddingLeft = UDim.new(0, 15); scPad.PaddingRight = UDim.new(0, 15)
	scPad.Parent = stableCard

	local scLayout = Instance.new("UIListLayout", stableCard)
	scLayout.SortOrder = Enum.SortOrder.LayoutOrder; scLayout.Padding = UDim.new(0.025, 0)

	local sTitle = Instance.new("TextLabel", stableCard)
	sTitle.Size = UDim2.new(1, 0, 0.08, 0); sTitle.BackgroundTransparency = 1
	sTitle.Font = Enum.Font.GothamBlack; sTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	sTitle.TextScaled = true; sTitle.Text = "MY STABLE"; sTitle.LayoutOrder = 1
	sTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", sTitle).MaxTextSize = 24

	horseNameLbl = Instance.new("TextLabel", stableCard)
	horseNameLbl.Size = UDim2.new(1, 0, 0.1, 0); horseNameLbl.BackgroundTransparency = 1
	horseNameLbl.Font = Enum.Font.GothamBold; horseNameLbl.TextColor3 = Color3.new(1, 1, 1)
	horseNameLbl.TextScaled = true; horseNameLbl.Text = "Unknown Steed"; horseNameLbl.LayoutOrder = 2
	horseNameLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", horseNameLbl).MaxTextSize = 22

	traitLbl = Instance.new("TextLabel", stableCard)
	traitLbl.Size = UDim2.new(1, 0, 0.06, 0); traitLbl.BackgroundTransparency = 1
	traitLbl.Font = Enum.Font.GothamMedium; traitLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	traitLbl.TextScaled = true; traitLbl.Text = "Trait: None"; traitLbl.LayoutOrder = 3
	traitLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", traitLbl).MaxTextSize = 16

	traitLbl.MouseEnter:Connect(function()
		local t = player:GetAttribute("HorseTrait") or "None"
		local desc = GameData.HorseTraits[t] or "No description available."
		local color = (t == "None") and "#AAAAAA" or "#FFD700"
		cachedTooltipMgr.Show("<b><font color='"..color.."'>" .. t .. "</font></b>\n____________________\n\n" .. desc)
	end)
	traitLbl.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

	local statRow = Instance.new("Frame", stableCard)
	statRow.Size = UDim2.new(1, 0, 0.11, 0); statRow.BackgroundTransparency = 1; statRow.LayoutOrder = 4
	statRow.ZIndex = 21

	speedValLbl = Instance.new("TextLabel", statRow)
	speedValLbl.Size = UDim2.new(0.45, 0, 1, 0); speedValLbl.BackgroundTransparency = 1
	speedValLbl.Font = Enum.Font.GothamBold; speedValLbl.TextColor3 = Color3.fromRGB(50, 255, 50)
	speedValLbl.TextScaled = true; speedValLbl.TextXAlignment = Enum.TextXAlignment.Left
	speedValLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", speedValLbl).MaxTextSize = 18

	upgSpeedBtn = Instance.new("TextButton", statRow)
	upgSpeedBtn.Size = UDim2.new(0.5, 0, 1, 0); upgSpeedBtn.Position = UDim2.new(0.5, 0, 0, 0)
	upgSpeedBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40); upgSpeedBtn.Font = Enum.Font.GothamBold
	upgSpeedBtn.TextColor3 = Color3.new(1, 1, 1); upgSpeedBtn.TextScaled = true; upgSpeedBtn.Text = "Upgrade Speed (100k)"
	upgSpeedBtn.ZIndex = 22
	Instance.new("UICorner", upgSpeedBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(upgSpeedBtn, 80, 180, 80)
	Instance.new("UITextSizeConstraint", upgSpeedBtn).MaxTextSize = 14

	local statRow2 = Instance.new("Frame", stableCard)
	statRow2.Size = UDim2.new(1, 0, 0.11, 0); statRow2.BackgroundTransparency = 1; statRow2.LayoutOrder = 5
	statRow2.ZIndex = 21

	endValLbl = Instance.new("TextLabel", statRow2)
	endValLbl.Size = UDim2.new(0.45, 0, 1, 0); endValLbl.BackgroundTransparency = 1
	endValLbl.Font = Enum.Font.GothamBold; endValLbl.TextColor3 = Color3.fromRGB(50, 255, 255)
	endValLbl.TextScaled = true; endValLbl.TextXAlignment = Enum.TextXAlignment.Left
	endValLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", endValLbl).MaxTextSize = 18

	upgEndBtn = Instance.new("TextButton", statRow2)
	upgEndBtn.Size = UDim2.new(0.5, 0, 1, 0); upgEndBtn.Position = UDim2.new(0.5, 0, 0, 0)
	upgEndBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 140); upgEndBtn.Font = Enum.Font.GothamBold
	upgEndBtn.TextColor3 = Color3.new(1, 1, 1); upgEndBtn.TextScaled = true; upgEndBtn.Text = "Upgrade Endurance (100k)"
	upgEndBtn.ZIndex = 22
	Instance.new("UICorner", upgEndBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(upgEndBtn, 80, 180, 180)
	Instance.new("UITextSizeConstraint", upgEndBtn).MaxTextSize = 14

	upgTimerLbl = Instance.new("TextLabel", stableCard)
	upgTimerLbl.Size = UDim2.new(1, 0, 0.06, 0); upgTimerLbl.BackgroundTransparency = 1
	upgTimerLbl.Font = Enum.Font.GothamMedium; upgTimerLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
	upgTimerLbl.TextScaled = true; upgTimerLbl.Text = ""; upgTimerLbl.LayoutOrder = 6
	upgTimerLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", upgTimerLbl).MaxTextSize = 14

	local rerollRow = Instance.new("Frame", stableCard)
	rerollRow.Size = UDim2.new(1, 0, 0.11, 0); rerollRow.BackgroundTransparency = 1; rerollRow.LayoutOrder = 7
	rerollRow.ZIndex = 21

	rerollYenBtn = Instance.new("TextButton", rerollRow)
	rerollYenBtn.Size = UDim2.new(0.48, 0, 1, 0); rerollYenBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 20)
	rerollYenBtn.Font = Enum.Font.GothamBold; rerollYenBtn.TextColor3 = Color3.new(1,1,1)
	rerollYenBtn.TextScaled = true; rerollYenBtn.Text = "Reroll Trait (1M ¥)"
	rerollYenBtn.ZIndex = 22
	Instance.new("UICorner", rerollYenBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(rerollYenBtn, 220, 180, 80); Instance.new("UITextSizeConstraint", rerollYenBtn).MaxTextSize = 14

	rerollRobuxBtn = Instance.new("TextButton", rerollRow)
	rerollRobuxBtn.Size = UDim2.new(0.48, 0, 1, 0); rerollRobuxBtn.Position = UDim2.new(0.52, 0, 0, 0)
	rerollRobuxBtn.BackgroundColor3 = Color3.fromRGB(20, 140, 60)
	rerollRobuxBtn.Font = Enum.Font.GothamBold; rerollRobuxBtn.TextColor3 = Color3.new(1,1,1)
	rerollRobuxBtn.TextScaled = true; rerollRobuxBtn.Text = "Reroll Name (2 R$)"
	rerollRobuxBtn.ZIndex = 22
	Instance.new("UICorner", rerollRobuxBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(rerollRobuxBtn, 80, 220, 120); Instance.new("UITextSizeConstraint", rerollRobuxBtn).MaxTextSize = 14

	local nameTitle = Instance.new("TextLabel", stableCard)
	nameTitle.Size = UDim2.new(1, 0, 0.06, 0); nameTitle.BackgroundTransparency = 1
	nameTitle.Font = Enum.Font.GothamBlack; nameTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	nameTitle.TextScaled = true; nameTitle.Text = "CUSTOM HORSE NAME"; nameTitle.LayoutOrder = 8
	nameTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", nameTitle).MaxTextSize = 14

	local nameRow = Instance.new("Frame", stableCard)
	nameRow.Size = UDim2.new(1, 0, 0.11, 0); nameRow.BackgroundTransparency = 1; nameRow.LayoutOrder = 9
	nameRow.ZIndex = 21

	local n1Drop = Instance.new("TextButton", nameRow)
	n1Drop.Size = UDim2.new(0.35, 0, 1, 0); n1Drop.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
	n1Drop.Font = Enum.Font.GothamBold; n1Drop.TextColor3 = Color3.new(1,1,1); n1Drop.TextScaled = true
	n1Drop.ZIndex = 22
	Instance.new("UICorner", n1Drop).CornerRadius = UDim.new(0, 6); AddBtnStroke(n1Drop, 100, 70, 120)

	local n2Drop = Instance.new("TextButton", nameRow)
	n2Drop.Size = UDim2.new(0.35, 0, 1, 0); n2Drop.Position = UDim2.new(0.38, 0, 0, 0)
	n2Drop.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
	n2Drop.Font = Enum.Font.GothamBold; n2Drop.TextColor3 = Color3.new(1,1,1); n2Drop.TextScaled = true
	n2Drop.ZIndex = 22
	Instance.new("UICorner", n2Drop).CornerRadius = UDim.new(0, 6); AddBtnStroke(n2Drop, 100, 70, 120)

	local setNameBtn = Instance.new("TextButton", nameRow)
	setNameBtn.Size = UDim2.new(0.24, 0, 1, 0); setNameBtn.Position = UDim2.new(0.76, 0, 0, 0)
	setNameBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	setNameBtn.Font = Enum.Font.GothamBold; setNameBtn.TextColor3 = Color3.new(1,1,1); setNameBtn.TextScaled = true
	setNameBtn.ZIndex = 22
	Instance.new("UICorner", setNameBtn).CornerRadius = UDim.new(0, 6); AddBtnStroke(setNameBtn, 80, 200, 80)
	Instance.new("UITextSizeConstraint", setNameBtn).MaxTextSize = 14

	CreateDropdown(n1Drop, "Select", Names1, function(val) targetName1 = val end)
	CreateDropdown(n2Drop, "Select", Names2, function(val) targetName2 = val end)

	local queueCard = CreateCard("QueueCard", lobbyContainer, UDim2.new(0.48, 0, 1, 0), UDim2.new(0.52, 0, 0, 0))
	local qcPad = Instance.new("UIPadding")
	qcPad.PaddingTop = UDim.new(0, 15); qcPad.PaddingBottom = UDim.new(0, 15)
	qcPad.PaddingLeft = UDim.new(0, 15); qcPad.PaddingRight = UDim.new(0, 15)
	qcPad.Parent = queueCard

	local qcLayout = Instance.new("UIListLayout", queueCard)
	qcLayout.SortOrder = Enum.SortOrder.LayoutOrder; qcLayout.Padding = UDim.new(0.05, 0)
	qcLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local qTitle = Instance.new("TextLabel", queueCard)
	qTitle.Size = UDim2.new(1, 0, 0.1, 0); qTitle.BackgroundTransparency = 1
	qTitle.Font = Enum.Font.GothamBlack; qTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	qTitle.TextScaled = true; qTitle.Text = "SBR EVENT"; qTitle.LayoutOrder = 1
	qTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", qTitle).MaxTextSize = 28

	timerLbl = Instance.new("TextLabel", queueCard)
	timerLbl.Size = UDim2.new(1, 0, 0.25, 0); timerLbl.BackgroundTransparency = 1
	timerLbl.Font = Enum.Font.GothamBlack; timerLbl.TextColor3 = Color3.new(1, 1, 1)
	timerLbl.TextScaled = true; timerLbl.RichText = true; timerLbl.Text = "NEXT RACE IN\n--:--"; timerLbl.LayoutOrder = 2
	timerLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", timerLbl).MaxTextSize = 40

	queueCountLbl = Instance.new("TextLabel", queueCard)
	queueCountLbl.Size = UDim2.new(1, 0, 0.1, 0); queueCountLbl.BackgroundTransparency = 1
	queueCountLbl.Font = Enum.Font.GothamMedium; queueCountLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	queueCountLbl.TextScaled = true; queueCountLbl.Text = "Players in Queue: 0"; queueCountLbl.LayoutOrder = 3
	queueCountLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", queueCountLbl).MaxTextSize = 20

	queueBtn = Instance.new("TextButton", queueCard)
	queueBtn.Size = UDim2.new(0.8, 0, 0.2, 0); queueBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	queueBtn.Font = Enum.Font.GothamBold; queueBtn.TextColor3 = Color3.new(1,1,1)
	queueBtn.TextScaled = true; queueBtn.Text = "Join Event Queue"; queueBtn.LayoutOrder = 4
	queueBtn.ZIndex = 22
	Instance.new("UICorner", queueBtn).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(queueBtn, 80, 200, 80)
	Instance.new("UITextSizeConstraint", queueBtn).MaxTextSize = 24

	forceStartBtn = Instance.new("TextButton", queueCard)
	forceStartBtn.Size = UDim2.new(0.8, 0, 0.15, 0)
	forceStartBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 20)
	forceStartBtn.Font = Enum.Font.GothamBold
	forceStartBtn.TextColor3 = Color3.new(1,1,1)
	forceStartBtn.TextScaled = true
	forceStartBtn.Text = "Force Start (Studio)"
	forceStartBtn.LayoutOrder = 5
	forceStartBtn.ZIndex = 22
	Instance.new("UICorner", forceStartBtn).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(forceStartBtn, 220, 140, 80)
	forceStartBtn.Visible = false
	Instance.new("UITextSizeConstraint", forceStartBtn).MaxTextSize = 18

	forceStartBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		Network.SBRAction:FireServer("ForceStartEvent")
	end)

	local function UpdatePassUI()
		if player:GetAttribute("HasHorseNamePass") then
			setNameBtn.Text = "Set Name"
			setNameBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		else
			setNameBtn.Text = "Buy Pass\n(40 R$)"
			setNameBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
		end
	end
	player:GetAttributeChangedSignal("HasHorseNamePass"):Connect(UpdatePassUI)
	UpdatePassUI()

	setNameBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if not player:GetAttribute("HasHorseNamePass") then
			MarketplaceService:PromptGamePassPurchase(player, 1749586333)
			return
		end
		if targetName1 == "Select" or targetName2 == "Select" then
			NotificationManager.Show("<font color='#FF5555'>Please select both name parts first!</font>")
			return
		end
		Network.SBRAction:FireServer("SetHorseName", {Name1 = targetName1, Name2 = targetName2})
	end)

	local inQueue = false
	queueBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); 
		if queueBtn.Text == "Force Join (Studio)" then
			Network.SBRAction:FireServer("ToggleQueue")
			return
		end
		inQueue = not inQueue; 
		queueBtn.Text = inQueue and "Leave Queue" or "Join Event Queue"
		queueBtn.BackgroundColor3 = inQueue and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(50, 150, 50)
		Network.SBRAction:FireServer("ToggleQueue")
	end)

	upgSpeedBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.SBRAction:FireServer("UpgradeHorse", "Speed") end)
	upgEndBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.SBRAction:FireServer("UpgradeHorse", "Endurance") end)
	rerollYenBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.SBRAction:FireServer("RerollHorseYen") end)
	rerollRobuxBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); MarketplaceService:PromptProductPurchase(player, REROLL_ROBUX_PRODUCT_ID) end)

	local function UpdateStableUI()
		horseNameLbl.Text = player:GetAttribute("HorseName") or "Unknown"
		traitLbl.Text = "Trait: " .. (player:GetAttribute("HorseTrait") or "None")

		local spd = player:GetAttribute("HorseSpeed") or 1
		local endur = player:GetAttribute("HorseEndurance") or 1
		speedValLbl.Text = "Speed: " .. spd .. "/100"
		endValLbl.Text = "Endurance: " .. endur .. "/100"

		local upgEnd = player:GetAttribute("HorseUpgradeEnd") or 0
		local isUpgrading = upgEnd > os.time()

		if spd >= 100 or isUpgrading then upgSpeedBtn.Visible = false else upgSpeedBtn.Visible = true end
		if endur >= 100 or isUpgrading then upgEndBtn.Visible = false else upgEndBtn.Visible = true end
	end

	player:GetAttributeChangedSignal("HorseName"):Connect(UpdateStableUI)
	player:GetAttributeChangedSignal("HorseSpeed"):Connect(UpdateStableUI)
	player:GetAttributeChangedSignal("HorseEndurance"):Connect(UpdateStableUI)
	player:GetAttributeChangedSignal("HorseTrait"):Connect(UpdateStableUI)
	UpdateStableUI()

	raceContainer = Instance.new("Frame")
	raceContainer.Name = "RaceContainer"
	raceContainer.Size = UDim2.new(1, 0, 1, 0)
	raceContainer.BackgroundTransparency = 1
	raceContainer.Visible = false
	raceContainer.Parent = mainContainer

	combatUI = CombatTemplate.Create(raceContainer, tooltipMgr)

	local function AppendLog(text)
		if not text or text == "" then return end
		if not combatUI or not combatUI.ChatText then return end

		if combatUI.ChatText.Text == "" then
			combatUI.ChatText.Text = text
		else
			combatUI.ChatText.Text = combatUI.ChatText.Text .. "\n" .. text
		end

		task.defer(function()
			if combatUI.ChatScroll then
				combatUI.ChatScroll.CanvasPosition = Vector2.new(0, 999999)
			end
		end)
	end

	sbrTopArea = Instance.new("Frame")
	sbrTopArea.Size = UDim2.new(1, 0, 0, 30)
	sbrTopArea.BackgroundTransparency = 1
	sbrTopArea.LayoutOrder = 0
	sbrTopArea.ZIndex = 30
	sbrTopArea.Parent = combatUI.ContentContainer

	rRegionLbl = Instance.new("TextLabel", sbrTopArea)
	rRegionLbl.Size = UDim2.new(0.5, 0, 1, 0); rRegionLbl.BackgroundTransparency = 1
	rRegionLbl.Font = Enum.Font.GothamBlack; rRegionLbl.TextColor3 = Color3.fromRGB(255, 215, 50)
	rRegionLbl.TextScaled = true; rRegionLbl.TextXAlignment = Enum.TextXAlignment.Left
	rRegionLbl.Text = "Region: San Diego Beach"
	rRegionLbl.ZIndex = 31

	rDistLbl = Instance.new("TextLabel", sbrTopArea)
	rDistLbl.Size = UDim2.new(0.5, 0, 1, 0); rDistLbl.Position = UDim2.new(0.5, 0, 0, 0)
	rDistLbl.BackgroundTransparency = 1; rDistLbl.Font = Enum.Font.GothamBlack
	rDistLbl.TextColor3 = Color3.fromRGB(50, 255, 255); rDistLbl.TextScaled = true
	rDistLbl.TextXAlignment = Enum.TextXAlignment.Right; rDistLbl.Text = "Distance: 0 / 10000m"
	rDistLbl.ZIndex = 31

	turnTimerLabel = Instance.new("TextLabel")
	turnTimerLabel.Size = UDim2.new(1, 0, 0, 25)
	turnTimerLabel.Position = UDim2.new(0, 0, 0, -5)
	turnTimerLabel.BackgroundTransparency = 1
	turnTimerLabel.Font = Enum.Font.GothamBlack
	turnTimerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	turnTimerLabel.TextScaled = true
	turnTimerLabel.ZIndex = 30
	turnTimerLabel.Text = "Time Remaining: --s"
	turnTimerLabel.Visible = false
	turnTimerLabel.Parent = combatUI.MainFrame

	combatResourceLabel = Instance.new("TextLabel")
	combatResourceLabel.Size = UDim2.new(1, 0, 0.05, 0)
	combatResourceLabel.BackgroundTransparency = 1
	combatResourceLabel.Font = Enum.Font.GothamBold
	combatResourceLabel.TextColor3 = Color3.fromRGB(255, 235, 130)
	combatResourceLabel.TextScaled = true
	combatResourceLabel.ZIndex = 32
	combatResourceLabel.Text = "STAMINA: 100 | ENERGY: 10"
	combatResourceLabel.LayoutOrder = 2 
	combatResourceLabel.Visible = false
	combatResourceLabel.Parent = combatUI.ContentContainer
	Instance.new("UITextSizeConstraint", combatResourceLabel).MaxTextSize = 18

	sbrPathArea = Instance.new("Frame")
	sbrPathArea.Size = UDim2.new(1, 0, 0.35, 0)
	sbrPathArea.BackgroundTransparency = 1
	sbrPathArea.LayoutOrder = 5
	sbrPathArea.ZIndex = 30
	sbrPathArea.Parent = combatUI.ContentContainer

	local sBg = Instance.new("Frame", sbrPathArea)
	sBg.Size = UDim2.new(1, 0, 0, 25); sBg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	sBg.ZIndex = 31
	Instance.new("UICorner", sBg).CornerRadius = UDim.new(0, 6)

	stamFill = Instance.new("Frame", sBg)
	stamFill.Size = UDim2.new(1, 0, 1, 0); stamFill.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
	stamFill.ZIndex = 32
	Instance.new("UICorner", stamFill).CornerRadius = UDim.new(0, 6)

	stamTxt = Instance.new("TextLabel", sBg)
	stamTxt.Size = UDim2.new(1, 0, 1, 0); stamTxt.BackgroundTransparency = 1
	stamTxt.Font = Enum.Font.GothamBold; stamTxt.TextColor3 = Color3.new(1, 1, 1)
	stamTxt.TextScaled = true; stamTxt.Text = "Horse Stamina: 100/100"
	stamTxt.ZIndex = 33

	pathBtns = Instance.new("Frame", sbrPathArea)
	pathBtns.Size = UDim2.new(1, 0, 1, -35); pathBtns.Position = UDim2.new(0, 0, 0, 35)
	pathBtns.BackgroundTransparency = 1
	pathBtns.ZIndex = 31
	local pbLayout = Instance.new("UIListLayout", pathBtns)
	pbLayout.FillDirection = Enum.FillDirection.Horizontal; pbLayout.Padding = UDim.new(0, 10)
	pbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; pbLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	safeBtn = Instance.new("TextButton", pathBtns)
	safeBtn.Size = UDim2.new(0.3, 0, 0.8, 0); safeBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
	safeBtn.Font = Enum.Font.GothamBold; safeBtn.TextColor3 = Color3.new(1,1,1); safeBtn.TextScaled = true
	safeBtn.Text = "Safe Path"
	safeBtn.ZIndex = 32
	Instance.new("UICorner", safeBtn).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(safeBtn, 100, 200, 255); Instance.new("UITextSizeConstraint", safeBtn).MaxTextSize = 22

	restBtn = Instance.new("TextButton", pathBtns)
	restBtn.Size = UDim2.new(0.3, 0, 0.8, 0); restBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	restBtn.Font = Enum.Font.GothamBold; restBtn.TextColor3 = Color3.new(1,1,1); restBtn.TextScaled = true
	restBtn.Text = "Rest"
	restBtn.ZIndex = 32
	Instance.new("UICorner", restBtn).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(restBtn, 100, 255, 100); Instance.new("UITextSizeConstraint", restBtn).MaxTextSize = 22

	riskyBtn = Instance.new("TextButton", pathBtns)
	riskyBtn.Size = UDim2.new(0.3, 0, 0.8, 0); riskyBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	riskyBtn.Font = Enum.Font.GothamBold; riskyBtn.TextColor3 = Color3.new(1,1,1); riskyBtn.TextScaled = true
	riskyBtn.Text = "Risky Path"
	riskyBtn.ZIndex = 32
	Instance.new("UICorner", riskyBtn).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(riskyBtn, 255, 100, 100); Instance.new("UITextSizeConstraint", riskyBtn).MaxTextSize = 22

	travelStatusLbl = Instance.new("TextLabel", sbrPathArea)
	travelStatusLbl.Size = UDim2.new(1, 0, 1, -35)
	travelStatusLbl.Position = UDim2.new(0, 0, 0, 35)
	travelStatusLbl.BackgroundTransparency = 1
	travelStatusLbl.Font = Enum.Font.GothamMedium
	travelStatusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	travelStatusLbl.TextScaled = true
	travelStatusLbl.Text = "Horse is traveling..."
	travelStatusLbl.Visible = false
	travelStatusLbl.ZIndex = 32
	Instance.new("UITextSizeConstraint", travelStatusLbl).MaxTextSize = 24

	waitingLabel = Instance.new("TextLabel")
	waitingLabel.Name = "WaitingLabel"
	waitingLabel.Size = UDim2.new(1, 0, 0.25, 0)
	waitingLabel.BackgroundTransparency = 1
	waitingLabel.Font = Enum.Font.GothamMedium
	waitingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	waitingLabel.TextScaled = true
	waitingLabel.Text = "Waiting for other players..."
	waitingLabel.Visible = false
	waitingLabel.ZIndex = 30
	waitingLabel.LayoutOrder = 6
	waitingLabel.Parent = combatUI.ContentContainer
	Instance.new("UITextSizeConstraint", waitingLabel).MaxTextSize = 24

	local function SetCombatMode(inCombat)
		combatUI.AlliesContainer.Parent.Visible = inCombat
		combatUI.AbilitiesArea.Visible = inCombat
		combatResourceLabel.Visible = inCombat
		turnTimerLabel.Visible = inCombat
		sbrTopArea.Visible = not inCombat
		sbrPathArea.Visible = not inCombat
		waitingLabel.Visible = false

		if combatUI.ChatScroll and combatUI.ChatScroll.Parent then
			if inCombat then
				combatUI.ChatScroll.Parent.Size = UDim2.new(1, 0, 0.18, 0)
			else
				combatUI.ChatScroll.Parent.Size = UDim2.new(1, 0, 0.40, 0)
			end
		end
	end

	local function RequestPath(typeStr)
		if os.time() - lastPathTime < 1 then return end
		lastPathTime = os.time()

		SFXManager.Play("Click")
		Network.SBRAction:FireServer("TakePath", typeStr)

		pathBtns.Visible = false
		travelStatusLbl.Text = typeStr == "Rest" and "Horse is resting..." or "Horse is traveling..."
		travelStatusLbl.Visible = true

		task.delay(1, function()
			if travelStatusLbl.Parent then
				pathBtns.Visible = true
				travelStatusLbl.Visible = false
			end
		end)
	end

	safeBtn.MouseButton1Click:Connect(function() RequestPath("Safe") end)
	restBtn.MouseButton1Click:Connect(function() RequestPath("Rest") end)
	riskyBtn.MouseButton1Click:Connect(function() RequestPath("Risky") end)

	local currentCycleTime = 1800
	task.spawn(function()
		while task.wait(1) do
			currentCycleTime = (currentCycleTime + 1) % 3600

			local upgEnd = player:GetAttribute("HorseUpgradeEnd") or 0
			if upgEnd > 0 then
				local left = upgEnd - os.time()
				if left > 0 then
					upgTimerLbl.Text = "Upgrading... " .. FormatTime(left)
					upgTimerLbl.Visible = true
					upgSpeedBtn.Visible = false
					upgEndBtn.Visible = false
				else
					upgTimerLbl.Text = ""
					upgTimerLbl.Visible = false
					UpdateStableUI()
				end
			else
				upgTimerLbl.Text = ""
				upgTimerLbl.Visible = false
			end

			if currentCycleTime < 1800 then
				timerLbl.Text = "RACE IN PROGRESS\n<font color='#FF5555'>" .. FormatTime(1800 - currentCycleTime) .. "</font> Left!"
				queueCountLbl.Text = "Event is currently active."

				if isStudio then
					queueBtn.Visible = true
					queueBtn.Text = "Force Join (Studio)"
					queueBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 20)
					forceStartBtn.Visible = false
				else
					queueBtn.Visible = false
					forceStartBtn.Visible = false
				end
			else
				timerLbl.Text = "NEXT RACE IN\n<font color='#55FF55'>" .. FormatTime(3600 - currentCycleTime) .. "</font>"
				queueBtn.Visible = true
				queueBtn.Text = inQueue and "Leave Queue" or "Join Event Queue"
				queueBtn.BackgroundColor3 = inQueue and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(50, 150, 50)
				forceStartBtn.Visible = isStudio
			end
		end
	end)

	task.spawn(function()
		while task.wait(0.2) do
			if currentDeadline > 0 and turnTimerLabel.Visible then
				local remain = math.max(0, currentDeadline - os.time())
				turnTimerLabel.Text = "Time Remaining: " .. remain .. "s"
				if remain <= 5 then turnTimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				else turnTimerLabel.TextColor3 = Color3.fromRGB(255, 215, 0) end
			end
		end
	end)

	local function UpdateCombatState(state)
		local processed = {}

		local id = tostring(state.P1.UserId)
		processed[id] = true
		local fObj = activeFighters[id]

		if not fObj then
			fObj = combatUI:AddFighter(true, id, state.P1.Name, id, state.P1.HP, state.P1.MaxHP)
			activeFighters[id] = fObj
		else
			fObj:UpdateHealth(state.P1.HP, state.P1.MaxHP)
		end

		local currentStatuses = {}
		if state.P1.Statuses then
			for eff, duration in pairs(state.P1.Statuses) do
				if duration and duration > 0 then
					currentStatuses[eff] = true
					fObj:SetStatus(eff, StatusIcons[eff] or "EFF", tostring(duration), StatusDescs[eff] or "Active effect.")
				end
			end
		end
		for eff, _ in pairs(StatusIcons) do
			if not currentStatuses[eff] then fObj:RemoveStatus(eff) end
		end

		if (state.P1.StunImmunity or 0) > 0 then fObj:SetCooldown("StunImm", "STN", tostring(state.P1.StunImmunity), "Stun Immune", true) else fObj:RemoveCooldown("StunImm") end
		if (state.P1.ConfusionImmunity or 0) > 0 then fObj:SetCooldown("ConfImm", "CNF", tostring(state.P1.ConfusionImmunity), "Confusion Immune", true) else fObj:RemoveCooldown("ConfImm") end

		combatResourceLabel.Text = "STAMINA: " .. math.floor(state.P1.Stamina) .. " | ENERGY: " .. math.floor(state.P1.StandEnergy)

		local bId = tostring(state.P2.UserId or ("Enemy_" .. state.P2.Name))
		processed[bId] = true
		local bObj = activeFighters[bId]

		if not bObj then
			local bIcon = state.P2.IsPlayer and bId or ""
			bObj = combatUI:AddFighter(false, bId, state.P2.Name, bIcon, state.P2.HP, state.P2.MaxHP)
			activeFighters[bId] = bObj
		else
			bObj:UpdateHealth(state.P2.HP, state.P2.MaxHP)
		end

		local bStatuses = {}
		if state.P2.Statuses then
			for eff, duration in pairs(state.P2.Statuses) do
				if duration and duration > 0 then
					bStatuses[eff] = true
					bObj:SetStatus(eff, StatusIcons[eff] or "EFF", tostring(duration), StatusDescs[eff] or "Active effect.")
				end
			end
		end
		for eff, _ in pairs(StatusIcons) do
			if not bStatuses[eff] then bObj:RemoveStatus(eff) end
		end

		if (state.P2.StunImmunity or 0) > 0 then bObj:SetCooldown("StunImm", "STN", tostring(state.P2.StunImmunity), "Stun Immune", true) else bObj:RemoveCooldown("StunImm") end
		if (state.P2.ConfusionImmunity or 0) > 0 then bObj:SetCooldown("ConfImm", "CNF", tostring(state.P2.ConfusionImmunity), "Confusion Immune", true) else bObj:RemoveCooldown("ConfImm") end

		for fid, obj in pairs(activeFighters) do
			if not processed[fid] then
				if obj.Frame then obj.Frame:Destroy() end
				activeFighters[fid] = nil
			end
		end
	end

	local function RenderSkills(pData)
		combatUI:ClearAbilities()
		combatUI.AbilitiesArea.Visible = true
		waitingLabel.Visible = false

		local myStand, myStyle = pData.Stand or "None", pData.Style or "None"
		local valid = {}

		if myStand == "Fused Stand" then
			local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))
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

		local function submitAttack(skName)
			SFXManager.Play("Click")
			cachedTooltipMgr.Hide()
			combatUI.AbilitiesArea.Visible = false
			waitingLabel.Text = "Waiting for opponent..."
			waitingLabel.Visible = true
			Network.SBRAction:FireServer("CombatAttack", skName) 
		end

		for _, sk in ipairs(valid) do
			local c = sk.Data.Type == "Stand" and Color3.fromRGB(120, 20, 160) or (sk.Data.Type == "Style" and Color3.fromRGB(180, 80, 20) or Color3.fromRGB(60, 60, 80))
			local btn = combatUI:AddAbility(sk.Name, c, nil)

			local currentCooldown = pData.Cooldowns and pData.Cooldowns[sk.Name] or 0

			if pData.Stamina < (sk.Data.StaminaCost or 0) or pData.StandEnergy < (sk.Data.EnergyCost or 0) or currentCooldown > 0 then
				btn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
				btn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
				if currentCooldown > 0 then 
					btn.Text = sk.Name .. " (" .. currentCooldown .. ")" 
				end
			else
				if sk.Name == "Flee" then
					local isConfirmingFlee = false
					btn.MouseButton1Click:Connect(function() 
						SFXManager.Play("Click")
						if not isConfirmingFlee then
							isConfirmingFlee = true
							btn.Text = "Confirm Flee?"
							btn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
							task.delay(3, function()
								if isConfirmingFlee then
									isConfirmingFlee = false
									if btn and btn.Parent then
										btn.Text = sk.Name
										btn.BackgroundColor3 = c
									end
								end
							end)
						else
							submitAttack(sk.Name)
						end
					end)
				else
					btn.MouseButton1Click:Connect(function() 
						submitAttack(sk.Name)
					end)
				end
			end

			btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
			btn.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)
		end
	end

	Network.SBRUpdate.OnClientEvent:Connect(function(action, data)
		if action == "SyncTimer" then
			currentCycleTime = data
		elseif action == "SyncQueue" then
			queueCountLbl.Text = "Players in Queue: " .. data
		elseif action == "RaceStarted" then
			if forceTabFocus then forceTabFocus() end
			lobbyContainer.Visible = false; raceContainer.Visible = true
			currentDeadline = 0
			combatUI.ChatText.Text = ""
			AppendLog("<font color='#FFD700'><b>THE RACE HAS BEGUN!</b></font>")
			rDistLbl.Text = "Distance: 0 / 10000m"
			rRegionLbl.Text = "Region: San Diego Beach"

			local maxS = data.MaxStamina
			stamTxt.Text = "Horse Stamina: " .. maxS .. "/" .. maxS
			stamFill.Size = UDim2.new(1, 0, 1, 0)

			SetCombatMode(false)

		elseif action == "PathResult" then
			AppendLog(data.Log)
			rDistLbl.Text = "Distance: " .. data.Dist .. " / 10000m"
			rRegionLbl.Text = "Region: " .. data.Region
			local maxS = stamTxt.Text:split("/")[2]
			stamTxt.Text = "Horse Stamina: " .. math.floor(data.Stam) .. "/" .. maxS
			stamFill.Size = UDim2.new(math.clamp(data.Stam / tonumber(maxS), 0, 1), 0, 1, 0)

			waitingLabel.Visible = false
			sbrPathArea.Visible = true

		elseif action == "CombatStart" then
			AppendLog(data.LogMsg)
			currentDeadline = data.Deadline or 0
			SetCombatMode(true)
			UpdateCombatState(data)
			RenderSkills(data.P1)

		elseif action == "CombatTurn" then
			combatUI.AbilitiesArea.Visible = false
			currentDeadline = data.Deadline or 0

			if data.LogMsg and data.LogMsg ~= "" then
				waitingLabel.Text = "Combat is playing out..."
				waitingLabel.Visible = true

				AppendLog(data.LogMsg)

				if string.find(data.LogMsg, "dodged!") then SFXManager.Play("CombatDodge")
				elseif string.find(data.LogMsg, "Blocked") then SFXManager.Play("CombatBlock")
				elseif data.DidHit then SFXManager.Play("CombatHit")
				else SFXManager.Play("CombatUtility") end

				task.spawn(function()
					task.wait(0.05) 
					if string.find(data.LogMsg, "(CRIT!)", 1, true) then SFXManager.Play("CombatCrit") end
					if string.find(data.LogMsg, "(Stunned!)", 1, true) or string.find(data.LogMsg, "stunning") or string.find(data.LogMsg, "halt") then SFXManager.Play("CombatStun") end
					if string.find(string.lower(data.LogMsg), "survived on willpower") then SFXManager.Play("CombatWillpower") end
				end)

				if data.DidHit then
					task.spawn(function()
						local p = data.ShakeType == "Heavy" and 18 or (data.ShakeType == "Light" and 3 or 8)
						local orig = UDim2.new(0, 0, 0, 0)
						for i = 1, 6 do raceContainer.Position = orig + UDim2.new(0, math.random(-p, p), 0, math.random(-p, p)); task.wait(0.04) end
						raceContainer.Position = orig
					end)
				end
			end

			UpdateCombatState(data)

			if data.LogMsg == "" then
				RenderSkills(data.P1)
			end

		elseif action == "CombatUpdateState" then
			currentDeadline = data.Deadline or 0
			UpdateCombatState(data)
			RenderSkills(data.P1)

		elseif action == "CombatEnd" then
			SFXManager.Play("CombatVictory")
			currentDeadline = 0
			AppendLog("<font color='#55FF55'><b>" .. data .. "</b></font>")
			SetCombatMode(false)

		elseif action == "Eliminated" then
			SFXManager.Play("CombatDefeat")
			currentDeadline = 0
			AppendLog("<font color='#FF5555'><b>" .. data .. " YOU HAVE BEEN ELIMINATED!</b></font>")
			SetCombatMode(false)
			sbrPathArea.Visible = false
			inQueue = false
			task.delay(4, function() lobbyContainer.Visible = true; raceContainer.Visible = false end)

		elseif action == "Finished" then
			SFXManager.Play("CombatVictory")
			currentDeadline = 0
			AppendLog("<font color='#55FFFF'><b>YOU CROSSED THE FINISH LINE IN " .. data .. " PLACE!</b></font>")
			SetCombatMode(false)
			sbrPathArea.Visible = false
			inQueue = false
			task.delay(5, function() lobbyContainer.Visible = true; raceContainer.Visible = false end)

		elseif action == "RaceEnded" then
			currentDeadline = 0
			AppendLog("<font color='#FFD700'><b>THE RACE IS OVER!</b></font>")
			SetCombatMode(false)
			sbrPathArea.Visible = false
			inQueue = false
			task.delay(6, function() lobbyContainer.Visible = true; raceContainer.Visible = false end)
		end
	end)

	mainContainer:GetPropertyChangedSignal("Visible"):Connect(function()
		if mainContainer.Visible then Network.SBRAction:FireServer("RequestSync") end
	end)
end

return SBREventTab