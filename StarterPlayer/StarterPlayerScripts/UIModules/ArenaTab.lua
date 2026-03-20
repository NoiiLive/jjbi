-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local ArenaTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))
local CombatTemplate = require(UIModules:WaitForChild("CombatTemplate"))

local ArenaAction = Network:WaitForChild("ArenaAction")
local ArenaUpdate = Network:WaitForChild("ArenaUpdate")

local mainContainer
local lobbyContainer, combatContainer
local profileCard, openQueuesCard, activeMatchesCard
local openQueuesScroll, activeMatchesScroll
local eloLbl

local viewDefault, viewSetup, viewHosting
local friendsToggleBtn, casualToggleBtn, capacityBtn, confirmSetupBtn, cancelSetupBtn
local hostingLbl, cancelLobbyBtn, createRoomBtn

local combatUI
local activeFighters = {}
local turnTimerLabel, combatResourceLabel, waitingLabel
local bettingArea, betInput, betT1Btn, betT2Btn, leaveSpecBtn, bettingStatusLbl
local pool1Lbl, pool2Lbl

local cachedTooltipMgr = nil
local forceTabFocus = nil
local currentDeadline = 0

local isSpectating = false
local currentMatchId = nil
local selectedTargetId = nil

local isFriendsOnly = false
local isCasual = false
local currentCapacity = 2

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

local function GetEloBoostText(elo)
	local str = "<b><font color='#FFD700'>ELO MILESTONES</font></b>\n____________________\n\n"
	local boosts = {
		{req = 1500, text = "1.5k: +5% Yen Boost"},
		{req = 2000, text = "2k: +5% XP Boost"},
		{req = 3000, text = "3k: +1% Luck Boost"},
		{req = 4000, text = "4k: +5 Inventory Space"},
		{req = 5000, text = "5k: 5% Increased Global Damage"}
	}

	for i, b in ipairs(boosts) do
		if elo >= b.req then
			str = str .. "<font color='#55FF55'>• " .. b.text .. "</font>"
		else
			str = str .. "<font color='#888888'>• " .. b.text .. "</font>"
		end
		if i < #boosts then str = str .. "\n" end
	end
	return str
end

function ArenaTab.Init(parentFrame, tooltipMgr, focusFunc)
	mainContainer = parentFrame
	cachedTooltipMgr = tooltipMgr
	forceTabFocus = focusFunc

	-- ==========================================================
	-- LOBBY CONTAINER
	-- ==========================================================
	lobbyContainer = Instance.new("Frame")
	lobbyContainer.Name = "LobbyContainer"
	lobbyContainer.Size = UDim2.new(0.96, 0, 0.96, 0)
	lobbyContainer.Position = UDim2.new(0.02, 0, 0.02, 0)
	lobbyContainer.BackgroundTransparency = 1
	lobbyContainer.Visible = true
	lobbyContainer.Parent = mainContainer

	-- LEFT PANEL (Profile & Host Setup)
	profileCard = CreateCard("ProfileCard", lobbyContainer, UDim2.new(0.30, 0, 1, 0), UDim2.new(0, 0, 0, 0))
	local pPad = Instance.new("UIPadding", profileCard)
	pPad.PaddingTop = UDim.new(0.04, 0); pPad.PaddingBottom = UDim.new(0.04, 0)
	pPad.PaddingLeft = UDim.new(0.04, 0); pPad.PaddingRight = UDim.new(0.04, 0)

	local pLayout = Instance.new("UIListLayout", profileCard)
	pLayout.SortOrder = Enum.SortOrder.LayoutOrder; pLayout.Padding = UDim.new(0.03, 0)
	pLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local pTitle = Instance.new("TextLabel", profileCard)
	pTitle.Size = UDim2.new(1, 0, 0.1, 0); pTitle.BackgroundTransparency = 1
	pTitle.Font = Enum.Font.GothamBlack; pTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	pTitle.TextScaled = true; pTitle.Text = "ARENA PROFILE"; pTitle.LayoutOrder = 1
	pTitle.ZIndex = 22; Instance.new("UITextSizeConstraint", pTitle).MaxTextSize = 24

	eloLbl = Instance.new("TextLabel", profileCard)
	eloLbl.Size = UDim2.new(1, 0, 0.15, 0); eloLbl.BackgroundTransparency = 1
	eloLbl.Font = Enum.Font.GothamBlack; eloLbl.TextColor3 = Color3.fromRGB(50, 255, 255)
	eloLbl.TextScaled = true; eloLbl.Text = "1000 ELO"; eloLbl.LayoutOrder = 2
	eloLbl.ZIndex = 22; Instance.new("UITextSizeConstraint", eloLbl).MaxTextSize = 40

	local milestonesBtn = Instance.new("TextButton", profileCard)
	milestonesBtn.Size = UDim2.new(0.6, 0, 0.08, 0); milestonesBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 20)
	milestonesBtn.Font = Enum.Font.GothamBold; milestonesBtn.TextColor3 = Color3.new(1,1,1)
	milestonesBtn.TextScaled = true; milestonesBtn.Text = "View Milestones"; milestonesBtn.LayoutOrder = 3
	milestonesBtn.ZIndex = 22; Instance.new("UICorner", milestonesBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(milestonesBtn, 255, 215, 50); Instance.new("UITextSizeConstraint", milestonesBtn).MaxTextSize = 16

	milestonesBtn.MouseEnter:Connect(function()
		local pObj = player:FindFirstChild("leaderstats")
		local elo = pObj and pObj:FindFirstChild("Elo") and pObj.Elo.Value or 1000
		cachedTooltipMgr.Show(GetEloBoostText(elo))
	end)
	milestonesBtn.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

	local hostArea = Instance.new("Frame", profileCard)
	hostArea.Size = UDim2.new(1, 0, 0.6, 0); hostArea.BackgroundTransparency = 1; hostArea.LayoutOrder = 4

	viewDefault = Instance.new("Frame", hostArea)
	viewDefault.Size = UDim2.new(1, 0, 1, 0); viewDefault.BackgroundTransparency = 1; viewDefault.Visible = true
	local vdLayout = Instance.new("UIListLayout", viewDefault); vdLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; vdLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	createRoomBtn = Instance.new("TextButton", viewDefault)
	createRoomBtn.Size = UDim2.new(0.8, 0, 0.15, 0); createRoomBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	createRoomBtn.Font = Enum.Font.GothamBold; createRoomBtn.TextColor3 = Color3.new(1,1,1)
	createRoomBtn.TextScaled = true; createRoomBtn.Text = "Create New Room"
	createRoomBtn.ZIndex = 22; Instance.new("UICorner", createRoomBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(createRoomBtn, 80, 180, 80); Instance.new("UITextSizeConstraint", createRoomBtn).MaxTextSize = 20

	viewSetup = Instance.new("Frame", hostArea)
	viewSetup.Size = UDim2.new(1, 0, 1, 0); viewSetup.BackgroundTransparency = 1; viewSetup.Visible = false
	local vsLayout = Instance.new("UIListLayout", viewSetup); vsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; vsLayout.VerticalAlignment = Enum.VerticalAlignment.Center; vsLayout.Padding = UDim.new(0.05, 0)

	friendsToggleBtn = Instance.new("TextButton", viewSetup)
	friendsToggleBtn.Size = UDim2.new(0.8, 0, 0.12, 0); friendsToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
	friendsToggleBtn.Font = Enum.Font.GothamBold; friendsToggleBtn.TextColor3 = Color3.new(1,1,1)
	friendsToggleBtn.TextScaled = true; friendsToggleBtn.Text = "[ ] Friends Only"
	friendsToggleBtn.ZIndex = 22; Instance.new("UICorner", friendsToggleBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(friendsToggleBtn, 90, 70, 110); Instance.new("UITextSizeConstraint", friendsToggleBtn).MaxTextSize = 16

	casualToggleBtn = Instance.new("TextButton", viewSetup)
	casualToggleBtn.Size = UDim2.new(0.8, 0, 0.12, 0); casualToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
	casualToggleBtn.Font = Enum.Font.GothamBold; casualToggleBtn.TextColor3 = Color3.new(1,1,1)
	casualToggleBtn.TextScaled = true; casualToggleBtn.Text = "[ ] Casual Match"
	casualToggleBtn.ZIndex = 22; Instance.new("UICorner", casualToggleBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(casualToggleBtn, 90, 70, 110); Instance.new("UITextSizeConstraint", casualToggleBtn).MaxTextSize = 16

	capacityBtn = Instance.new("TextButton", viewSetup)
	capacityBtn.Size = UDim2.new(0.8, 0, 0.12, 0); capacityBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
	capacityBtn.Font = Enum.Font.GothamBold; capacityBtn.TextColor3 = Color3.new(1,1,1)
	capacityBtn.TextScaled = true; capacityBtn.Text = "Mode: 1v1"
	capacityBtn.ZIndex = 22; Instance.new("UICorner", capacityBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(capacityBtn, 180, 80, 200); Instance.new("UITextSizeConstraint", capacityBtn).MaxTextSize = 16

	confirmSetupBtn = Instance.new("TextButton", viewSetup)
	confirmSetupBtn.Size = UDim2.new(0.8, 0, 0.15, 0); confirmSetupBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	confirmSetupBtn.Font = Enum.Font.GothamBold; confirmSetupBtn.TextColor3 = Color3.new(1,1,1)
	confirmSetupBtn.TextScaled = true; confirmSetupBtn.Text = "Host Room"
	confirmSetupBtn.ZIndex = 22; Instance.new("UICorner", confirmSetupBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(confirmSetupBtn, 80, 180, 80); Instance.new("UITextSizeConstraint", confirmSetupBtn).MaxTextSize = 18

	cancelSetupBtn = Instance.new("TextButton", viewSetup)
	cancelSetupBtn.Size = UDim2.new(0.8, 0, 0.12, 0); cancelSetupBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
	cancelSetupBtn.Font = Enum.Font.GothamBold; cancelSetupBtn.TextColor3 = Color3.new(1,1,1)
	cancelSetupBtn.TextScaled = true; cancelSetupBtn.Text = "Cancel"
	cancelSetupBtn.ZIndex = 22; Instance.new("UICorner", cancelSetupBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(cancelSetupBtn, 200, 80, 80); Instance.new("UITextSizeConstraint", cancelSetupBtn).MaxTextSize = 16

	viewHosting = Instance.new("Frame", hostArea)
	viewHosting.Size = UDim2.new(1, 0, 1, 0); viewHosting.BackgroundTransparency = 1; viewHosting.Visible = false
	local vhLayout = Instance.new("UIListLayout", viewHosting); vhLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; vhLayout.VerticalAlignment = Enum.VerticalAlignment.Center; vhLayout.Padding = UDim.new(0.1, 0)

	hostingLbl = Instance.new("TextLabel", viewHosting)
	hostingLbl.Size = UDim2.new(1, 0, 0.2, 0); hostingLbl.BackgroundTransparency = 1
	hostingLbl.Font = Enum.Font.GothamBold; hostingLbl.TextColor3 = Color3.new(1,1,1)
	hostingLbl.TextScaled = true; hostingLbl.Text = "Team 1: 1/1 | Team 2: 0/1"
	hostingLbl.ZIndex = 22; Instance.new("UITextSizeConstraint", hostingLbl).MaxTextSize = 18

	cancelLobbyBtn = Instance.new("TextButton", viewHosting)
	cancelLobbyBtn.Size = UDim2.new(0.8, 0, 0.15, 0); cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
	cancelLobbyBtn.Font = Enum.Font.GothamBold; cancelLobbyBtn.TextColor3 = Color3.new(1,1,1)
	cancelLobbyBtn.TextScaled = true; cancelLobbyBtn.Text = "Disband Room"
	cancelLobbyBtn.ZIndex = 22; Instance.new("UICorner", cancelLobbyBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(cancelLobbyBtn, 200, 80, 80); Instance.new("UITextSizeConstraint", cancelLobbyBtn).MaxTextSize = 18

	-- RIGHT PANEL (Lists)
	local rightPanel = Instance.new("Frame", lobbyContainer)
	rightPanel.Size = UDim2.new(0.68, -10, 1, 0); rightPanel.Position = UDim2.new(0.32, 10, 0, 0)
	rightPanel.BackgroundTransparency = 1

	openQueuesCard = CreateCard("OpenQueuesCard", rightPanel, UDim2.new(1, 0, 0.48, 0), UDim2.new(0, 0, 0, 0))
	local oqPad = Instance.new("UIPadding", openQueuesCard)
	oqPad.PaddingTop = UDim.new(0.04, 0); oqPad.PaddingBottom = UDim.new(0.04, 0)
	oqPad.PaddingLeft = UDim.new(0.04, 0); oqPad.PaddingRight = UDim.new(0.04, 0)

	local oqCardLayout = Instance.new("UIListLayout", openQueuesCard)
	oqCardLayout.SortOrder = Enum.SortOrder.LayoutOrder; oqCardLayout.Padding = UDim.new(0.02, 0)

	local oqTitle = Instance.new("TextLabel", openQueuesCard)
	oqTitle.Size = UDim2.new(1, 0, 0.15, 0); oqTitle.BackgroundTransparency = 1
	oqTitle.Font = Enum.Font.GothamBlack; oqTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	oqTitle.TextScaled = true; oqTitle.Text = "OPEN ROOMS"; oqTitle.TextXAlignment = Enum.TextXAlignment.Left
	oqTitle.ZIndex = 22; oqTitle.LayoutOrder = 1
	Instance.new("UITextSizeConstraint", oqTitle).MaxTextSize = 22

	openQueuesScroll = Instance.new("ScrollingFrame", openQueuesCard)
	openQueuesScroll.Size = UDim2.new(1, 0, 0.83, 0); openQueuesScroll.LayoutOrder = 2
	openQueuesScroll.BackgroundTransparency = 1; openQueuesScroll.ScrollBarThickness = 8
	openQueuesScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120); openQueuesScroll.ZIndex = 21
	local oqLayout = Instance.new("UIListLayout", openQueuesScroll); oqLayout.SortOrder = Enum.SortOrder.LayoutOrder; oqLayout.Padding = UDim.new(0, 10)
	Instance.new("UIPadding", openQueuesScroll).PaddingRight = UDim.new(0, 12)

	activeMatchesCard = CreateCard("ActiveMatchesCard", rightPanel, UDim2.new(1, 0, 0.48, 0), UDim2.new(0, 0, 0.52, 0))
	local amPad = Instance.new("UIPadding", activeMatchesCard)
	amPad.PaddingTop = UDim.new(0.04, 0); amPad.PaddingBottom = UDim.new(0.04, 0)
	amPad.PaddingLeft = UDim.new(0.04, 0); amPad.PaddingRight = UDim.new(0.04, 0)

	local amCardLayout = Instance.new("UIListLayout", activeMatchesCard)
	amCardLayout.SortOrder = Enum.SortOrder.LayoutOrder; amCardLayout.Padding = UDim.new(0.02, 0)

	local amTitle = Instance.new("TextLabel", activeMatchesCard)
	amTitle.Size = UDim2.new(1, 0, 0.15, 0); amTitle.BackgroundTransparency = 1
	amTitle.Font = Enum.Font.GothamBlack; amTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	amTitle.TextScaled = true; amTitle.Text = "SPECTATE MATCHES"; amTitle.TextXAlignment = Enum.TextXAlignment.Left
	amTitle.ZIndex = 22; amTitle.LayoutOrder = 1
	Instance.new("UITextSizeConstraint", amTitle).MaxTextSize = 22

	activeMatchesScroll = Instance.new("ScrollingFrame", activeMatchesCard)
	activeMatchesScroll.Size = UDim2.new(1, 0, 0.83, 0); activeMatchesScroll.LayoutOrder = 2
	activeMatchesScroll.BackgroundTransparency = 1; activeMatchesScroll.ScrollBarThickness = 8
	activeMatchesScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120); activeMatchesScroll.ZIndex = 21
	local amLayout = Instance.new("UIListLayout", activeMatchesScroll); amLayout.SortOrder = Enum.SortOrder.LayoutOrder; amLayout.Padding = UDim.new(0, 10)
	Instance.new("UIPadding", activeMatchesScroll).PaddingRight = UDim.new(0, 12)

	-- ==========================================================
	-- BUTTON LOGIC (Host Setup)
	-- ==========================================================
	createRoomBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); viewDefault.Visible = false; viewSetup.Visible = true end)
	cancelSetupBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); viewSetup.Visible = false; viewDefault.Visible = true end)

	friendsToggleBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); isFriendsOnly = not isFriendsOnly
		friendsToggleBtn.Text = isFriendsOnly and "[X] Friends Only" or "[ ] Friends Only"
		friendsToggleBtn.TextColor3 = isFriendsOnly and Color3.fromRGB(50, 255, 50) or Color3.new(1,1,1)
	end)

	casualToggleBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); isCasual = not isCasual
		casualToggleBtn.Text = isCasual and "[X] Casual Match" or "[ ] Casual Match"
		casualToggleBtn.TextColor3 = isCasual and Color3.fromRGB(50, 255, 50) or Color3.new(1,1,1)
	end)

	capacityBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if currentCapacity == 2 then currentCapacity = 4; capacityBtn.Text = "Mode: 2v2"
		elseif currentCapacity == 4 then currentCapacity = 8; capacityBtn.Text = "Mode: 4v4"
		else currentCapacity = 2; capacityBtn.Text = "Mode: 1v1" end
	end)

	confirmSetupBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		Network.ArenaAction:FireServer("CreateLobby", {FriendsOnly = isFriendsOnly, Casual = isCasual, Capacity = currentCapacity}) 
	end)

	cancelLobbyBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.ArenaAction:FireServer("CancelLobby") end)

	task.spawn(function()
		while task.wait(1) do
			local pObj = player:FindFirstChild("leaderstats")
			if pObj and pObj:FindFirstChild("Elo") then
				eloLbl.Text = pObj.Elo.Value .. " ELO"
			end
		end
	end)

	-- ==========================================================
	-- COMBAT CONTAINER (Injected from CombatTemplate)
	-- ==========================================================
	combatContainer = Instance.new("Frame")
	combatContainer.Name = "CombatContainer"
	combatContainer.Size = UDim2.new(1, 0, 1, 0)
	combatContainer.BackgroundTransparency = 1
	combatContainer.Visible = false
	combatContainer.Parent = mainContainer

	combatUI = CombatTemplate.Create(combatContainer, tooltipMgr)

	turnTimerLabel = Instance.new("TextLabel")
	turnTimerLabel.Size = UDim2.new(1, 0, 0, 25)
	turnTimerLabel.Position = UDim2.new(0, 0, 0, -5)
	turnTimerLabel.BackgroundTransparency = 1
	turnTimerLabel.Font = Enum.Font.GothamBlack
	turnTimerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	turnTimerLabel.TextScaled = true
	turnTimerLabel.ZIndex = 30
	turnTimerLabel.Text = "Time Remaining: --s"
	turnTimerLabel.Parent = combatUI.MainFrame

	combatResourceLabel = Instance.new("TextLabel")
	combatResourceLabel.Size = UDim2.new(1, 0, 0.05, 0)
	combatResourceLabel.BackgroundTransparency = 1
	combatResourceLabel.Font = Enum.Font.GothamBold
	combatResourceLabel.TextColor3 = Color3.fromRGB(255, 235, 130)
	combatResourceLabel.TextScaled = true
	combatResourceLabel.ZIndex = 22
	combatResourceLabel.Text = "STAMINA: 100 | ENERGY: 10"
	combatResourceLabel.LayoutOrder = 2 
	combatResourceLabel.Visible = false
	combatResourceLabel.Parent = combatUI.ContentContainer
	Instance.new("UITextSizeConstraint", combatResourceLabel).MaxTextSize = 18

	waitingLabel = Instance.new("TextLabel")
	waitingLabel.Name = "WaitingLabel"
	waitingLabel.Size = UDim2.new(1, 0, 0.25, 0)
	waitingLabel.BackgroundTransparency = 1
	waitingLabel.Font = Enum.Font.GothamMedium
	waitingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	waitingLabel.TextScaled = true
	waitingLabel.Text = "Waiting for opponent..."
	waitingLabel.Visible = false
	waitingLabel.ZIndex = 22
	waitingLabel.LayoutOrder = 6
	waitingLabel.Parent = combatUI.ContentContainer
	Instance.new("UITextSizeConstraint", waitingLabel).MaxTextSize = 24

	-- ==========================================================
	-- BETTING AREA (Spectator Mode)
	-- ==========================================================
	bettingArea = Instance.new("Frame")
	bettingArea.Name = "BettingArea"
	bettingArea.Size = UDim2.new(1, 0, 0.18, 0)
	bettingArea.BackgroundTransparency = 1
	bettingArea.LayoutOrder = 6
	bettingArea.ZIndex = 30
	bettingArea.Visible = false
	bettingArea.Parent = combatUI.ContentContainer

	local bLayout = Instance.new("UIListLayout", bettingArea)
	bLayout.FillDirection = Enum.FillDirection.Horizontal
	bLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	bLayout.Padding = UDim.new(0, 15)

	leaveSpecBtn = Instance.new("TextButton", bettingArea)
	leaveSpecBtn.Size = UDim2.new(0.15, 0, 0.6, 0)
	leaveSpecBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	leaveSpecBtn.Font = Enum.Font.GothamBold
	leaveSpecBtn.TextColor3 = Color3.new(1,1,1)
	leaveSpecBtn.Text = "Exit Spectate"
	leaveSpecBtn.TextScaled = true
	Instance.new("UICorner", leaveSpecBtn).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(leaveSpecBtn, 255, 100, 100)
	Instance.new("UITextSizeConstraint", leaveSpecBtn).MaxTextSize = 16

	local betCol = Instance.new("Frame", bettingArea)
	betCol.Size = UDim2.new(0.2, 0, 0.8, 0); betCol.BackgroundTransparency = 1
	local bcLayout = Instance.new("UIListLayout", betCol); bcLayout.SortOrder = Enum.SortOrder.LayoutOrder; bcLayout.Padding = UDim.new(0, 5)

	betInput = Instance.new("TextBox", betCol)
	betInput.Size = UDim2.new(1, 0, 0.6, 0)
	betInput.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	betInput.TextColor3 = Color3.fromRGB(255, 215, 0)
	betInput.Font = Enum.Font.GothamBold
	betInput.PlaceholderText = "Bet Amount..."
	betInput.TextScaled = true; betInput.LayoutOrder = 1
	Instance.new("UICorner", betInput).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(betInput, 255, 215, 50)
	Instance.new("UITextSizeConstraint", betInput).MaxTextSize = 20

	bettingStatusLbl = Instance.new("TextLabel", betCol)
	bettingStatusLbl.Size = UDim2.new(1, 0, 0.35, 0)
	bettingStatusLbl.BackgroundTransparency = 1
	bettingStatusLbl.Font = Enum.Font.GothamBold
	bettingStatusLbl.TextColor3 = Color3.fromRGB(50, 255, 50)
	bettingStatusLbl.TextScaled = true; bettingStatusLbl.LayoutOrder = 2
	bettingStatusLbl.Visible = false
	Instance.new("UITextSizeConstraint", bettingStatusLbl).MaxTextSize = 14

	local t1Col = Instance.new("Frame", bettingArea)
	t1Col.Size = UDim2.new(0.25, 0, 0.8, 0); t1Col.BackgroundTransparency = 1
	local t1Layout = Instance.new("UIListLayout", t1Col); t1Layout.SortOrder = Enum.SortOrder.LayoutOrder; t1Layout.Padding = UDim.new(0, 5)

	betT1Btn = Instance.new("TextButton", t1Col)
	betT1Btn.Size = UDim2.new(1, 0, 0.6, 0)
	betT1Btn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
	betT1Btn.Font = Enum.Font.GothamBold; betT1Btn.TextColor3 = Color3.new(1,1,1)
	betT1Btn.TextScaled = true; betT1Btn.LayoutOrder = 1
	Instance.new("UICorner", betT1Btn).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(betT1Btn, 100, 150, 255)
	Instance.new("UITextSizeConstraint", betT1Btn).MaxTextSize = 18

	pool1Lbl = Instance.new("TextLabel", t1Col)
	pool1Lbl.Size = UDim2.new(1, 0, 0.35, 0); pool1Lbl.BackgroundTransparency = 1
	pool1Lbl.Font = Enum.Font.GothamBold; pool1Lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	pool1Lbl.TextScaled = true; pool1Lbl.Text = "Pool 1: ¥0"; pool1Lbl.LayoutOrder = 2
	Instance.new("UITextSizeConstraint", pool1Lbl).MaxTextSize = 14

	local t2Col = Instance.new("Frame", bettingArea)
	t2Col.Size = UDim2.new(0.25, 0, 0.8, 0); t2Col.BackgroundTransparency = 1
	local t2Layout = Instance.new("UIListLayout", t2Col); t2Layout.SortOrder = Enum.SortOrder.LayoutOrder; t2Layout.Padding = UDim.new(0, 5)

	betT2Btn = Instance.new("TextButton", t2Col)
	betT2Btn.Size = UDim2.new(1, 0, 0.6, 0)
	betT2Btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	betT2Btn.Font = Enum.Font.GothamBold; betT2Btn.TextColor3 = Color3.new(1,1,1)
	betT2Btn.TextScaled = true; betT2Btn.LayoutOrder = 1
	Instance.new("UICorner", betT2Btn).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(betT2Btn, 255, 100, 100)
	Instance.new("UITextSizeConstraint", betT2Btn).MaxTextSize = 18

	pool2Lbl = Instance.new("TextLabel", t2Col)
	pool2Lbl.Size = UDim2.new(1, 0, 0.35, 0); pool2Lbl.BackgroundTransparency = 1
	pool2Lbl.Font = Enum.Font.GothamBold; pool2Lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	pool2Lbl.TextScaled = true; pool2Lbl.Text = "Pool 2: ¥0"; pool2Lbl.LayoutOrder = 2
	Instance.new("UITextSizeConstraint", pool2Lbl).MaxTextSize = 14

	leaveSpecBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		Network.ArenaAction:FireServer("LeaveSpectate")
		lobbyContainer.Visible = true
		combatContainer.Visible = false
		isSpectating = false
	end)

	local function TryPlaceBet(teamIndex)
		SFXManager.Play("Click")
		local amt = tonumber(betInput.Text)
		if amt and amt > 0 then
			Network.ArenaAction:FireServer("PlaceBet", {Team = teamIndex, Amount = amt})
		else
			NotificationManager.Show("<font color='#FF5555'>Invalid bet amount!</font>")
		end
	end

	betT1Btn.MouseButton1Click:Connect(function() TryPlaceBet(1) end)
	betT2Btn.MouseButton1Click:Connect(function() TryPlaceBet(2) end)

	mainContainer:GetPropertyChangedSignal("Visible"):Connect(function()
		if mainContainer.Visible and lobbyContainer.Visible then Network.ArenaAction:FireServer("RequestLobbies") end
	end)
end

function ArenaTab.HandleUpdate(action, data)
	if action == "LobbyStatus" then
		if data.IsHosting then
			viewDefault.Visible = false
			viewSetup.Visible = false
			viewHosting.Visible = true

			local cap = data.Capacity or 2
			local maxPerTeam = cap / 2
			local modeStr = (cap == 2 and "1v1") or (cap == 4 and "2v2") or "4v4"
			hostingLbl.Text = "Team 1: " .. (data.T1Count or 1) .. "/" .. maxPerTeam .. " | Team 2: " .. (data.T2Count or 0) .. "/" .. maxPerTeam .. "\n[" .. modeStr .. "]"

			if data.IsLobbyOwner then
				cancelLobbyBtn.Text = "Disband Room"
				cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
			else
				cancelLobbyBtn.Text = "Leave Queue"
				cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(140, 80, 40)
			end
		else
			viewDefault.Visible = true
			viewSetup.Visible = false
			viewHosting.Visible = false
		end

	elseif action == "LobbiesUpdate" then
		for _, child in pairs(openQueuesScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
		if #data == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 40); empty.BackgroundTransparency = 1; empty.Text = "No open rooms found."
			empty.TextColor3 = Color3.fromRGB(150, 150, 150); empty.Font = Enum.Font.GothamMedium; empty.TextSize = 16
			empty.Parent = openQueuesScroll
			return
		end

		for i, lobby in ipairs(data) do
			local row = CreateCard("QRow_"..i, openQueuesScroll, UDim2.new(1, -8, 0, 60))
			row.LayoutOrder = i
			local rowPad = Instance.new("UIPadding", row)
			rowPad.PaddingLeft = UDim.new(0, 10); rowPad.PaddingRight = UDim.new(0, 10)

			local modeStr = (lobby.Capacity == 2 and "1v1") or (lobby.Capacity == 4 and "2v2") or "4v4"
			local infoText = "<b>" .. lobby.HostName .. "'s Room</b> | " .. modeStr .. " | Elo: " .. lobby.Elo
			if lobby.FriendsOnly then infoText = infoText .. " <font color='#55FF55'>[Friends]</font>" end
			if lobby.Casual then infoText = infoText .. " <font color='#55FFFF'>[Casual]</font>" end

			local info = Instance.new("TextLabel", row)
			info.Size = UDim2.new(0.65, 0, 1, 0); info.Position = UDim2.new(0, 0, 0, 0)
			info.BackgroundTransparency = 1; info.Font = Enum.Font.GothamMedium
			info.TextColor3 = Color3.new(1, 1, 1); info.TextScaled = true; info.TextXAlignment = Enum.TextXAlignment.Left
			info.RichText = true; info.Text = infoText
			info.ZIndex = 22; Instance.new("UITextSizeConstraint", info).MaxTextSize = 14

			local maxPerTeam = lobby.Capacity / 2

			if lobby.HostId == player.UserId then
				local hostLbl = Instance.new("TextLabel", row)
				hostLbl.Size = UDim2.new(0.25, 0, 0.6, 0); hostLbl.Position = UDim2.new(1, 0, 0.5, 0); hostLbl.AnchorPoint = Vector2.new(1, 0.5)
				hostLbl.BackgroundTransparency = 1; hostLbl.Font = Enum.Font.GothamBold; hostLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
				hostLbl.TextScaled = true; hostLbl.Text = "Hosting..."; hostLbl.ZIndex = 22
				Instance.new("UITextSizeConstraint", hostLbl).MaxTextSize = 14

			elseif lobby.Capacity == 2 then
				local joinBtn = Instance.new("TextButton", row)
				joinBtn.Size = UDim2.new(0.25, 0, 0.7, 0); joinBtn.Position = UDim2.new(1, 0, 0.5, 0); joinBtn.AnchorPoint = Vector2.new(1, 0.5)
				joinBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40); joinBtn.Font = Enum.Font.GothamBold
				joinBtn.TextColor3 = Color3.new(1, 1, 1); joinBtn.TextScaled = true; joinBtn.Text = "CHALLENGE"
				joinBtn.ZIndex = 22; Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)
				AddBtnStroke(joinBtn, 255, 100, 100); Instance.new("UITextSizeConstraint", joinBtn).MaxTextSize = 14

				joinBtn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					Network.ArenaAction:FireServer("JoinLobby", {HostId = lobby.HostId, TeamIndex = 2}) 
				end)
			else
				local t2Btn = Instance.new("TextButton", row)
				t2Btn.Size = UDim2.new(0.18, 0, 0.7, 0); t2Btn.Position = UDim2.new(1, 0, 0.5, 0); t2Btn.AnchorPoint = Vector2.new(1, 0.5)
				t2Btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40); t2Btn.Font = Enum.Font.GothamBold
				t2Btn.TextColor3 = Color3.new(1, 1, 1); t2Btn.TextScaled = true; t2Btn.Text = "T2 (" .. lobby.T2Count .. "/" .. maxPerTeam .. ")"
				t2Btn.ZIndex = 22; Instance.new("UICorner", t2Btn).CornerRadius = UDim.new(0, 6)
				AddBtnStroke(t2Btn, 255, 100, 100); Instance.new("UITextSizeConstraint", t2Btn).MaxTextSize = 12

				t2Btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click"); Network.ArenaAction:FireServer("JoinLobby", {HostId = lobby.HostId, TeamIndex = 2}) 
				end)

				local t1Btn = Instance.new("TextButton", row)
				t1Btn.Size = UDim2.new(0.18, 0, 0.7, 0); t1Btn.Position = UDim2.new(0.80, -5, 0.5, 0); t1Btn.AnchorPoint = Vector2.new(1, 0.5)
				t1Btn.BackgroundColor3 = Color3.fromRGB(40, 100, 180); t1Btn.Font = Enum.Font.GothamBold
				t1Btn.TextColor3 = Color3.new(1, 1, 1); t1Btn.TextScaled = true; t1Btn.Text = "T1 (" .. lobby.T1Count .. "/" .. maxPerTeam .. ")"
				t1Btn.ZIndex = 22; Instance.new("UICorner", t1Btn).CornerRadius = UDim.new(0, 6)
				AddBtnStroke(t1Btn, 100, 150, 255); Instance.new("UITextSizeConstraint", t1Btn).MaxTextSize = 12

				t1Btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click"); Network.ArenaAction:FireServer("JoinLobby", {HostId = lobby.HostId, TeamIndex = 1}) 
				end)
			end
		end
		task.delay(0.05, function()
			local layout = openQueuesScroll:FindFirstChildWhichIsA("UIListLayout")
			if layout then openQueuesScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10) end
		end)

	elseif action == "ActiveMatchesUpdate" then
		for _, child in pairs(activeMatchesScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
		if #data == 0 then
			local empty = Instance.new("TextLabel"); empty.Size = UDim2.new(1, 0, 0, 40); empty.BackgroundTransparency = 1; empty.Text = "No active battles."; empty.TextColor3 = Color3.fromRGB(150, 150, 150); empty.Font = Enum.Font.GothamMedium; empty.TextSize = 16; empty.Parent = activeMatchesScroll
			return
		end

		for i, match in ipairs(data) do
			local row = CreateCard("MRow_"..i, activeMatchesScroll, UDim2.new(1, -8, 0, 60))
			row.LayoutOrder = i
			local rowPad = Instance.new("UIPadding", row)
			rowPad.PaddingLeft = UDim.new(0, 10); rowPad.PaddingRight = UDim.new(0, 10)

			local infoText = "<b>" .. match.HostName .. "'s Match</b> | " .. match.Mode .. "\n<font color='#AAAAAA' size='12'>Pool: ¥" .. (match.Pool1 + match.Pool2) .. " | Spectators: " .. match.SpectatorCount .. "</font>"
			local info = Instance.new("TextLabel", row)
			info.Size = UDim2.new(0.7, 0, 1, 0); info.Position = UDim2.new(0, 0, 0, 0)
			info.BackgroundTransparency = 1; info.Font = Enum.Font.GothamMedium
			info.TextColor3 = Color3.new(1, 1, 1); info.TextScaled = true; info.TextXAlignment = Enum.TextXAlignment.Left
			info.RichText = true; info.Text = infoText
			info.ZIndex = 22; Instance.new("UITextSizeConstraint", info).MaxTextSize = 14

			local specBtn = Instance.new("TextButton", row)
			specBtn.Size = UDim2.new(0.25, 0, 0.7, 0); specBtn.Position = UDim2.new(1, 0, 0.5, 0); specBtn.AnchorPoint = Vector2.new(1, 0.5)
			specBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160); specBtn.Font = Enum.Font.GothamBold
			specBtn.TextColor3 = Color3.new(1, 1, 1); specBtn.TextScaled = true; specBtn.Text = "SPECTATE"
			specBtn.ZIndex = 22; Instance.new("UICorner", specBtn).CornerRadius = UDim.new(0, 6)
			AddBtnStroke(specBtn, 180, 80, 200); Instance.new("UITextSizeConstraint", specBtn).MaxTextSize = 14

			specBtn.MouseButton1Click:Connect(function() 
				SFXManager.Play("Click")
				Network.ArenaAction:FireServer("SpectateMatch", {MatchId = match.MatchId}) 
			end)
		end
		task.delay(0.05, function()
			local layout = activeMatchesScroll:FindFirstChildWhichIsA("UIListLayout")
			if layout then activeMatchesScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10) end
		end)

	elseif action == "MatchStart" then
		if forceTabFocus then forceTabFocus() end 
		currentDeadline = data.Deadline or 0
		lobbyContainer.Visible = false
		combatContainer.Visible = true
		waitingLabel.Visible = false

		isSpectating = data.State.IsSpectator
		currentMatchId = data.State.MatchId

		combatUI.AlliesContainer.Parent.Visible = true
		combatUI.AbilitiesArea.Visible = not isSpectating
		combatResourceLabel.Visible = not isSpectating
		bettingArea.Visible = isSpectating
		turnTimerLabel.Visible = true

		if isSpectating then
			betInput.Text = ""
			betInput.Visible = true
			betT1Btn.Text = "Bet Team 1"
			betT1Btn.Visible = true
			betT2Btn.Text = "Bet Team 2"
			betT2Btn.Visible = true
			bettingStatusLbl.Visible = false

			pool1Lbl.Text = "Pool 1: ¥" .. (data.State.Pool1 or 0)
			pool2Lbl.Text = "Pool 2: ¥" .. (data.State.Pool2 or 0)

			if combatUI.ChatScroll and combatUI.ChatScroll.Parent then
				combatUI.ChatScroll.Parent.Size = UDim2.new(1, 0, 0.18, 0)
			end
		else
			if combatUI.ChatScroll and combatUI.ChatScroll.Parent then
				combatUI.ChatScroll.Parent.Size = UDim2.new(1, 0, 0.40, 0)
			end
		end

		combatUI.ChatText.Text = ""
		AppendLog("<font color='#FFD700'><b>" .. data.LogMsg .. "</b></font>")
		selectedTargetId = nil
		ArenaTab.UpdateCombatState(data.State)
		if not isSpectating then ArenaTab.RenderSkills(data.State) end

	elseif action == "Waiting" then
		combatUI.AbilitiesArea.Visible = false
		waitingLabel.Visible = true

	elseif action == "BetConfirmed" then
		betInput.Visible = false
		betT1Btn.Visible = false
		betT2Btn.Visible = false
		bettingStatusLbl.Text = "Bet Placed: ¥" .. data.Amount .. " on Team " .. data.Team
		bettingStatusLbl.Visible = true
		SFXManager.Play("Click")

	elseif action == "BetUpdate" then
		pool1Lbl.Text = "Pool 1: ¥" .. data.Pool1
		pool2Lbl.Text = "Pool 2: ¥" .. data.Pool2

	elseif action == "TurnResult" then
		combatUI.AbilitiesArea.Visible = false
		currentDeadline = data.Deadline or 0

		if data.LogMsg and data.LogMsg ~= "" then
			if not isSpectating then
				waitingLabel.Text = "Combat is playing out..."
				waitingLabel.Visible = true
			end

			local lines = string.split(data.LogMsg, "\n")
			for _, line in ipairs(lines) do if line ~= "" then AppendLog(line) end end

			ArenaTab.UpdateCombatState(data.State)

			task.spawn(function()
				for _, line in ipairs(lines) do
					if string.find(line, "used <b>") or string.find(line, "%- Hit ") then
						if string.find(line, "dodged!") or string.find(line, "missed!") then SFXManager.Play("CombatDodge")
						elseif string.find(line, "Blocked") then SFXManager.Play("CombatBlock")
						elseif string.find(line, "damage to") or string.find(line, "dealt") then SFXManager.Play("CombatHit")
						else SFXManager.Play("CombatUtility") end

						task.spawn(function()
							task.wait(0.05)
							if string.find(line, "(CRIT!)", 1, true) then SFXManager.Play("CombatCrit") end
							if string.find(line, "(Stunned!)", 1, true) or string.find(line, "stunning") or string.find(line, "halt") then SFXManager.Play("CombatStun") end
							if string.find(string.lower(line), "survived on willpower") then SFXManager.Play("CombatWillpower") end
						end)

						if string.find(line, "damage to") or string.find(line, "dealt") then
							task.spawn(function()
								local p = string.find(line, "(CRIT!)", 1, true) and 18 or 8
								local orig = UDim2.new(0, 0, 0, 0)
								for i = 1, 6 do combatContainer.Position = orig + UDim2.new(0, math.random(-p, p), 0, math.random(-p, p)); task.wait(0.04) end
								combatContainer.Position = orig
							end)
						end
						task.wait(0.3)
					elseif string.find(line, "Poison damage") or string.find(line, "Burn damage") or string.find(line, "bled for") or string.find(line, "Freeze damage") then
						SFXManager.Play("CombatHit")
						task.wait(0.3)
					end
				end

				if not isSpectating then
					waitingLabel.Visible = false
					combatUI.AbilitiesArea.Visible = true
					ArenaTab.RenderSkills(data.State)
				end
			end)
		else
			ArenaTab.UpdateCombatState(data.State)
			if not isSpectating then
				waitingLabel.Visible = false
				combatUI.AbilitiesArea.Visible = true
				ArenaTab.RenderSkills(data.State)
			end
		end

	elseif action == "MatchOver" then
		currentDeadline = 0
		turnTimerLabel.Text = "Match Over!"
		combatUI.AbilitiesArea.Visible = false
		bettingArea.Visible = false
		waitingLabel.Visible = false
		AppendLog(data.LogMsg)

		if data.Result == "Win" then SFXManager.Play("CombatVictory") elseif data.Result == "Loss" then SFXManager.Play("CombatDefeat") end

		task.delay(4, function()
			viewDefault.Visible = true; viewSetup.Visible = false; viewHosting.Visible = false
			lobbyContainer.Visible = true
			combatContainer.Visible = false
			Network.ArenaAction:FireServer("RequestLobbies")
		end)
	end
end

function ArenaTab.UpdateCombatState(state)
	if state.EnemyTeam and #state.EnemyTeam == 1 and not selectedTargetId then
		selectedTargetId = state.EnemyTeam[1].UserId
	end

	local processed = {}

	for _, pData in ipairs(state.MyTeam) do
		local id = tostring(pData.UserId)
		processed[id] = true
		local fObj = activeFighters[id]

		if not fObj then
			fObj = combatUI:AddFighter(true, id, pData.Name, id, pData.HP, pData.MaxHP)
			activeFighters[id] = fObj
		else
			fObj:UpdateHealth(pData.HP, pData.MaxHP)
		end

		local currentStatuses = {}
		if pData.Statuses then
			for eff, duration in pairs(pData.Statuses) do
				if duration and duration > 0 then
					currentStatuses[eff] = true
					fObj:SetStatus(eff, StatusIcons[eff] or "EFF", tostring(duration), StatusDescs[eff] or "Active effect.")
				end
			end
		end
		for eff, _ in pairs(StatusIcons) do if not currentStatuses[eff] then fObj:RemoveStatus(eff) end end

		if (pData.StunImmunity or 0) > 0 then fObj:SetCooldown("StunImm", "STN", tostring(pData.StunImmunity), "Stun Immune", true) else fObj:RemoveCooldown("StunImm") end
		if (pData.ConfusionImmunity or 0) > 0 then fObj:SetCooldown("ConfImm", "CNF", tostring(pData.ConfusionImmunity), "Confusion Immune", true) else fObj:RemoveCooldown("ConfImm") end

		if pData.UserId == state.MyId and not isSpectating then
			combatResourceLabel.Text = "STAMINA: " .. math.floor(pData.Stamina) .. " | ENERGY: " .. math.floor(pData.StandEnergy)
		end
	end

	for _, pData in ipairs(state.EnemyTeam) do
		local id = tostring(pData.UserId)
		processed[id] = true
		local fObj = activeFighters[id]

		if not fObj then
			fObj = combatUI:AddFighter(false, id, pData.Name, id, pData.HP, pData.MaxHP)
			activeFighters[id] = fObj
		else
			fObj:UpdateHealth(pData.HP, pData.MaxHP)
		end

		if not isSpectating then
			if fObj.Frame then
				local stroke = fObj.Frame:FindFirstChildOfClass("UIStroke")
				if stroke then
					if pData.UserId == selectedTargetId then
						stroke.Color = Color3.fromRGB(255, 215, 0)
						stroke.Thickness = 2
					else
						stroke.Color = Color3.fromRGB(90, 50, 120) 
						stroke.Thickness = 1
					end
				end

				if not fObj.Frame:GetAttribute("TargetHooked") then
					fObj.Frame:SetAttribute("TargetHooked", true)
					local btn = Instance.new("TextButton", fObj.Frame)
					btn.Size = UDim2.new(1, 0, 1, 0)
					btn.BackgroundTransparency = 1
					btn.Text = ""
					btn.ZIndex = 50
					btn.MouseButton1Click:Connect(function()
						if pData.HP > 0 then
							SFXManager.Play("Click")
							selectedTargetId = pData.UserId
							ArenaTab.UpdateCombatState(state) 
						end
					end)
				end
			end
		end

		local currentStatuses = {}
		if pData.Statuses then
			for eff, duration in pairs(pData.Statuses) do
				if duration and duration > 0 then
					currentStatuses[eff] = true
					fObj:SetStatus(eff, StatusIcons[eff] or "EFF", tostring(duration), StatusDescs[eff] or "Active effect.")
				end
			end
		end
		for eff, _ in pairs(StatusIcons) do if not currentStatuses[eff] then fObj:RemoveStatus(eff) end end

		if (pData.StunImmunity or 0) > 0 then fObj:SetCooldown("StunImm", "STN", tostring(pData.StunImmunity), "Stun Immune", true) else fObj:RemoveCooldown("StunImm") end
		if (pData.ConfusionImmunity or 0) > 0 then fObj:SetCooldown("ConfImm", "CNF", tostring(pData.ConfusionImmunity), "Confusion Immune", true) else fObj:RemoveCooldown("ConfImm") end
	end

	for fid, obj in pairs(activeFighters) do
		if not processed[fid] then
			if obj.Frame then obj.Frame:Destroy() end
			activeFighters[fid] = nil
		end
	end
end

function ArenaTab.RenderSkills(state)
	if isSpectating then return end
	combatUI:ClearAbilities()
	combatUI.AbilitiesArea.Visible = true
	waitingLabel.Visible = false

	local myState = nil
	for _, p in ipairs(state.MyTeam) do if p.UserId == state.MyId then myState = p break end end
	if not myState then return end

	if myState.HP <= 0 then
		combatUI.AbilitiesArea.Visible = false
		waitingLabel.Text = "You have been defeated. Spectating..."
		waitingLabel.Visible = true
		return
	end

	local myStand, myStyle = myState.Stand or "None", myState.Style or "None"
	local valid = {}
	for n, s in pairs(SkillData.Skills) do
		if s.Requirement == "None" or s.Requirement == myStand or s.Requirement == myStyle or (s.Requirement == "AnyStand" and myStand ~= "None") then 
			table.insert(valid, {Name = n, Data = s}) 
		end
	end
	table.sort(valid, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)

	local function submitAttack(skName)
		if not selectedTargetId and skName ~= "Flee" and string.sub(SkillData.Skills[skName].Effect or "", 1, 5) ~= "Buff_" and SkillData.Skills[skName].Effect ~= "Heal" and SkillData.Skills[skName].Effect ~= "Block" and SkillData.Skills[skName].Effect ~= "Rest" then
			NotificationManager.Show("<font color='#FF5555'>You must select an enemy target first!</font>")
			return
		end

		SFXManager.Play("Click")
		cachedTooltipMgr.Hide()
		combatUI.AbilitiesArea.Visible = false
		waitingLabel.Text = "Waiting for opponent..."
		waitingLabel.Visible = true
		Network.ArenaAction:FireServer("Attack", {SkillName = skName, TargetUserId = selectedTargetId}) 
	end

	for _, sk in ipairs(valid) do
		local c = sk.Data.Type == "Stand" and Color3.fromRGB(120, 20, 160) or (sk.Data.Type == "Style" and Color3.fromRGB(180, 80, 20) or Color3.fromRGB(60, 60, 80))
		local btn = combatUI:AddAbility(sk.Name, c, nil)

		local currentCooldown = myState.Cooldowns and myState.Cooldowns[sk.Name] or 0

		if myState.Stamina < (sk.Data.StaminaCost or 0) or myState.StandEnergy < (sk.Data.EnergyCost or 0) or currentCooldown > 0 then
			btn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
			btn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
			if currentCooldown > 0 then btn.Text = sk.Name .. " (" .. currentCooldown .. ")" end
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
							if isConfirmingFlee and btn and btn.Parent then
								isConfirmingFlee = false
								btn.Text = sk.Name
								btn.BackgroundColor3 = c
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

return ArenaTab