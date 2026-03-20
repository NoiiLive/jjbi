-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local RaidsTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local CombatTemplate = require(UIModules:WaitForChild("CombatTemplate"))

local RaidAction = Network:WaitForChild("RaidAction")
local RaidUpdate = Network:WaitForChild("RaidUpdate")

local menuFrame, matchmakingFrame, combatCard
local raidTitleLabel
local hostCard, lobbyCard
local viewDefault, viewSetup, viewHosting
local hostingLbl, cancelLobbyBtn, startRaidBtn
local lobbyContainer

local combatUI
local activeFighters = {}
local turnTimerLabel, resourceLabel, waitingLabel

local selectedRaidId = nil
local isFriendsOnly = false
local currentDeadline = 0
local cachedTooltipMgr, forceTabFocus

local raidBosses = {
	{ Id = "Raid_Part1", Name = "Vampire King", Req = 1, Desc = "A deadly raid against the progenitor of the stone mask." },
	{ Id = "Raid_Part2", Name = "Ultimate Lifeform", Req = 2, Desc = "Face the pinnacle of evolution. Bring Hamon!" },
	{ Id = "Raid_Part3", Name = "Time Stop Vampire", Req = 3, Desc = "He has conquered time itself. Good luck." },
	{ Id = "Raid_Part4", Name = "Serial Killer", Req = 4, Desc = "An elusive murderer with explosive tendencies." },
	{ Id = "Raid_Part5", Name = "Mafia Boss", Req = 5, Desc = "The boss of Passione. Time will erase." },
	{ Id = "Raid_Part6", Name = "Gravity Priest", Req = 6, Desc = "Gravity is shifting. The universe accelerates." },
	{ Id = "Raid_Part7", Name = "23rd President", Req = 7, Desc = "He has taken the first napkin. Beware his dimensional shifts." }
}

local StatusIcons = {
	Stun = "STN", Poison = "PSN", Burn = "BRN", Bleed = "BLD", Freeze = "FRZ", Confusion = "CNF",
	Buff_Strength = "STR+", Buff_Defense = "DEF+", Buff_Speed = "SPD+", Buff_Willpower = "WIL+",
	Debuff_Strength = "STR-", Debuff_Defense = "DEF-", Debuff_Speed = "SPD-", Debuff_Willpower = "WIL-"
}

local StatusDescs = {
	Stun = "Cannot move or act.",
	Poison = "Takes damage every turn.",
	Burn = "Takes damage every turn.",
	Bleed = "Takes damage every turn.",
	Freeze = "Frozen solid. Cannot move, takes damage.",
	Confusion = "May attack allies or self.",
	Buff_Strength = "Increased damage dealt.",
	Buff_Defense = "Reduced damage taken.",
	Buff_Speed = "Increased evasion and turn priority.",
	Buff_Willpower = "Increased crit and survival chance.",
	Debuff_Strength = "Reduced damage dealt.",
	Debuff_Defense = "Increased damage taken.",
	Debuff_Speed = "Reduced evasion and turn priority.",
	Debuff_Willpower = "Reduced crit and survival chance."
}

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

local function AddBtnStroke(btn, r, g, b)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(r, g, b)
	s.Thickness = 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = btn
	return s
end

function RaidsTab.Init(parentFrame, tooltipMgr, focusFunc)
	cachedTooltipMgr = tooltipMgr
	forceTabFocus = focusFunc

	-- ==========================================================
	-- MENU FRAME (Raid Selection)
	-- ==========================================================
	menuFrame = Instance.new("ScrollingFrame")
	menuFrame.Name = "MenuFrame"
	menuFrame.Size = UDim2.new(1, 0, 1, 0) 
	menuFrame.Position = UDim2.new(0, 0, 0, 0)
	menuFrame.BackgroundTransparency = 1
	menuFrame.ScrollBarThickness = 6
	menuFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	menuFrame.Visible = true
	menuFrame.Parent = parentFrame

	local mfLayout = Instance.new("UIListLayout")
	mfLayout.FillDirection = Enum.FillDirection.Vertical
	mfLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mfLayout.Padding = UDim.new(0, 10)
	mfLayout.Parent = menuFrame

	local mfPad = Instance.new("UIPadding")
	mfPad.PaddingTop = UDim.new(0.02, 0)
	mfPad.PaddingBottom = UDim.new(0.02, 0)
	mfPad.PaddingLeft = UDim.new(0.02, 0) 
	mfPad.PaddingRight = UDim.new(0.02, 0)
	mfPad.Parent = menuFrame

	local uiElements = {}
	for i, rInfo in ipairs(raidBosses) do
		local row = CreateCard("RaidRow_" .. rInfo.Id, menuFrame, UDim2.new(1, 0, 0, 80), nil)
		row.LayoutOrder = i

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(0.6, 0, 0, 25)
		title.Position = UDim2.new(0, 10, 0, 10)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextColor3 = Color3.fromRGB(255, 215, 50)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = "RAID: " .. rInfo.Name
		title.ZIndex = 22
		title.Parent = row
		Instance.new("UITextSizeConstraint", title).MaxTextSize = 20

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(0.6, 0, 0, 30)
		desc.Position = UDim2.new(0, 10, 0, 40)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.GothamMedium
		desc.TextColor3 = Color3.fromRGB(200, 200, 200)
		desc.TextScaled = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.Text = rInfo.Desc
		desc.ZIndex = 22 
		desc.Parent = row
		Instance.new("UITextSizeConstraint", desc).MaxTextSize = 14

		local status = Instance.new("TextLabel")
		status.Size = UDim2.new(0.35, 0, 0, 20)
		status.Position = UDim2.new(1, -10, 0, 10)
		status.AnchorPoint = Vector2.new(1, 0)
		status.BackgroundTransparency = 1
		status.Font = Enum.Font.GothamBold
		status.TextColor3 = Color3.new(1, 1, 1)
		status.TextScaled = true
		status.RichText = true
		status.TextXAlignment = Enum.TextXAlignment.Right
		status.ZIndex = 22
		status.Parent = row
		Instance.new("UITextSizeConstraint", status).MaxTextSize = 14

		local playBtn = Instance.new("TextButton")
		playBtn.Size = UDim2.new(0.2, 0, 0, 30)
		playBtn.Position = UDim2.new(1, -10, 0, 40)
		playBtn.AnchorPoint = Vector2.new(1, 0)
		playBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
		playBtn.Font = Enum.Font.GothamBold
		playBtn.TextColor3 = Color3.new(1, 1, 1)
		playBtn.TextScaled = true
		playBtn.Text = "SELECT"
		playBtn.ZIndex = 22
		playBtn.Parent = row
		Instance.new("UITextSizeConstraint", playBtn).MaxTextSize = 16
		Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 6)

		local pStroke = AddBtnStroke(playBtn, 200, 80, 80)

		playBtn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			local pObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
			if pObj and pObj.Value >= rInfo.Req then
				selectedRaidId = rInfo.Id
				raidTitleLabel.Text = "MATCHMAKING: " .. string.upper(rInfo.Name)
				menuFrame.Visible = false
				matchmakingFrame.Visible = true
				RaidAction:FireServer("RequestLobbies", selectedRaidId)
			end
		end)

		uiElements[rInfo.Id] = {Row = row, Status = status, Btn = playBtn, Stroke = pStroke, Info = rInfo}
	end

	task.delay(0.1, function()
		menuFrame.CanvasSize = UDim2.new(0, 0, 0, mfLayout.AbsoluteContentSize.Y + 20)
	end)

	task.spawn(function()
		local pObj = player:WaitForChild("leaderstats", 10)
		if pObj then
			local prestige = pObj:WaitForChild("Prestige", 10)
			local function updateLocks()
				local pVal = prestige.Value
				for id, data in pairs(uiElements) do
					if pVal >= data.Info.Req then
						data.Btn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
						data.Btn.Text = "SELECT"
						data.Btn.TextColor3 = Color3.new(1, 1, 1)
						data.Status.Text = "<font color='#55FF55'>Unlocked</font>"
						data.Stroke.Color = Color3.fromRGB(200, 80, 80)
					else
						data.Btn.BackgroundColor3 = Color3.fromRGB(35, 25, 40)
						data.Btn.Text = "🔒"
						data.Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
						data.Status.Text = "<font color='#FF5555'>Requires Prestige " .. data.Info.Req .. "</font>"
						data.Stroke.Color = Color3.fromRGB(80, 60, 90)
					end
				end
			end
			prestige.Changed:Connect(updateLocks)
			updateLocks()
		end
	end)

	-- ==========================================================
	-- MATCHMAKING FRAME
	-- ==========================================================
	matchmakingFrame = Instance.new("Frame")
	matchmakingFrame.Name = "MatchmakingFrame"
	matchmakingFrame.Size = UDim2.new(1, 0, 1, 0)
	matchmakingFrame.Position = UDim2.new(0, 0, 0, 0)
	matchmakingFrame.BackgroundTransparency = 1
	matchmakingFrame.Visible = false
	matchmakingFrame.Parent = parentFrame

	local mmPad = Instance.new("UIPadding")
	mmPad.PaddingTop = UDim.new(0.02, 0)
	mmPad.PaddingBottom = UDim.new(0.02, 0)
	mmPad.PaddingLeft = UDim.new(0.02, 0)
	mmPad.PaddingRight = UDim.new(0.02, 0)
	mmPad.Parent = matchmakingFrame

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 35)
	topBar.BackgroundTransparency = 1
	topBar.Parent = matchmakingFrame

	local backBtn = Instance.new("TextButton")
	backBtn.Name = "BackBtn"
	backBtn.Size = UDim2.new(0, 80, 1, 0)
	backBtn.Position = UDim2.new(0, 5, 0, 0)
	backBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	backBtn.Font = Enum.Font.GothamBold
	backBtn.TextColor3 = Color3.new(1, 1, 1)
	backBtn.TextScaled = true
	backBtn.Text = "BACK"
	backBtn.ZIndex = 22
	backBtn.Parent = topBar
	Instance.new("UITextSizeConstraint", backBtn).MaxTextSize = 14
	Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(backBtn, 220, 80, 80)

	backBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		matchmakingFrame.Visible = false
		menuFrame.Visible = true
		selectedRaidId = nil
		RaidAction:FireServer("CancelLobby")
	end)

	raidTitleLabel = Instance.new("TextLabel")
	raidTitleLabel.Name = "RaidTitleLabel"
	raidTitleLabel.Size = UDim2.new(1, -100, 1, 0)
	raidTitleLabel.Position = UDim2.new(0, 100, 0, 0)
	raidTitleLabel.BackgroundTransparency = 1
	raidTitleLabel.Font = Enum.Font.GothamBlack
	raidTitleLabel.TextColor3 = Color3.fromRGB(255, 215, 50)
	raidTitleLabel.TextScaled = true
	raidTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	raidTitleLabel.ZIndex = 22
	raidTitleLabel.Parent = topBar

	hostCard = CreateCard("HostCard", matchmakingFrame, UDim2.new(0.48, 0, 1, -45), UDim2.new(0, 0, 0, 45))

	local hostTitle = Instance.new("TextLabel")
	hostTitle.Size = UDim2.new(1, 0, 0, 30)
	hostTitle.Position = UDim2.new(0, 0, 0, 5)
	hostTitle.BackgroundTransparency = 1
	hostTitle.Font = Enum.Font.GothamBlack
	hostTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	hostTitle.TextScaled = true
	hostTitle.Text = "HOST PARTY"
	hostTitle.ZIndex = 22
	hostTitle.Parent = hostCard

	-- DYNAMIC CENTERED CONTAINERS
	viewDefault = Instance.new("Frame")
	viewDefault.Name = "ViewDefault"
	viewDefault.Size = UDim2.new(1, 0, 1, -40)
	viewDefault.Position = UDim2.new(0, 0, 0, 40)
	viewDefault.BackgroundTransparency = 1
	viewDefault.Visible = true
	viewDefault.ZIndex = 21
	viewDefault.Parent = hostCard

	local vdLayout = Instance.new("UIListLayout")
	vdLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	vdLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	vdLayout.Parent = viewDefault

	local openSetupBtn = Instance.new("TextButton")
	openSetupBtn.Name = "OpenSetupBtn"
	openSetupBtn.Size = UDim2.new(0.6, 0, 0, 45)
	openSetupBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 140)
	openSetupBtn.Font = Enum.Font.GothamBold
	openSetupBtn.TextColor3 = Color3.new(1, 1, 1)
	openSetupBtn.TextScaled = true
	openSetupBtn.Text = "Create New Party"
	openSetupBtn.ZIndex = 22
	openSetupBtn.Parent = viewDefault
	Instance.new("UITextSizeConstraint", openSetupBtn).MaxTextSize = 14
	Instance.new("UICorner", openSetupBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(openSetupBtn, 180, 80, 180)

	viewSetup = Instance.new("Frame")
	viewSetup.Name = "ViewSetup"
	viewSetup.Size = UDim2.new(1, 0, 1, -40)
	viewSetup.Position = UDim2.new(0, 0, 0, 40)
	viewSetup.BackgroundTransparency = 1
	viewSetup.Visible = false
	viewSetup.ZIndex = 21
	viewSetup.Parent = hostCard

	local vsLayout = Instance.new("UIListLayout")
	vsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	vsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	vsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	vsLayout.Padding = UDim.new(0, 12)
	vsLayout.Parent = viewSetup

	local friendsToggleBtn = Instance.new("TextButton")
	friendsToggleBtn.Name = "FriendsToggleBtn"
	friendsToggleBtn.LayoutOrder = 1
	friendsToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
	friendsToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
	friendsToggleBtn.Font = Enum.Font.GothamBold
	friendsToggleBtn.TextColor3 = Color3.new(1, 1, 1)
	friendsToggleBtn.TextScaled = true
	friendsToggleBtn.Text = "[ ] Friends Only"
	friendsToggleBtn.ZIndex = 22
	friendsToggleBtn.Parent = viewSetup
	Instance.new("UITextSizeConstraint", friendsToggleBtn).MaxTextSize = 14
	Instance.new("UICorner", friendsToggleBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(friendsToggleBtn, 90, 70, 110)

	local confirmSetupBtn = Instance.new("TextButton")
	confirmSetupBtn.Name = "ConfirmSetupBtn"
	confirmSetupBtn.LayoutOrder = 2
	confirmSetupBtn.Size = UDim2.new(0.8, 0, 0, 45)
	confirmSetupBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	confirmSetupBtn.Font = Enum.Font.GothamBold
	confirmSetupBtn.TextColor3 = Color3.new(1, 1, 1)
	confirmSetupBtn.TextScaled = true
	confirmSetupBtn.Text = "Confirm Setup"
	confirmSetupBtn.ZIndex = 22
	confirmSetupBtn.Parent = viewSetup
	Instance.new("UITextSizeConstraint", confirmSetupBtn).MaxTextSize = 14
	Instance.new("UICorner", confirmSetupBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(confirmSetupBtn, 80, 180, 80)

	local cancelSetupBtn = Instance.new("TextButton")
	cancelSetupBtn.Name = "CancelSetupBtn"
	cancelSetupBtn.LayoutOrder = 3
	cancelSetupBtn.Size = UDim2.new(0.8, 0, 0, 40)
	cancelSetupBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
	cancelSetupBtn.Font = Enum.Font.GothamBold
	cancelSetupBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelSetupBtn.TextScaled = true
	cancelSetupBtn.Text = "Cancel"
	cancelSetupBtn.ZIndex = 22
	cancelSetupBtn.Parent = viewSetup
	Instance.new("UITextSizeConstraint", cancelSetupBtn).MaxTextSize = 14
	Instance.new("UICorner", cancelSetupBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(cancelSetupBtn, 200, 80, 80)

	viewHosting = Instance.new("Frame")
	viewHosting.Name = "ViewHosting"
	viewHosting.Size = UDim2.new(1, 0, 1, -40)
	viewHosting.Position = UDim2.new(0, 0, 0, 40)
	viewHosting.BackgroundTransparency = 1
	viewHosting.Visible = false
	viewHosting.ZIndex = 21
	viewHosting.Parent = hostCard

	local vhLayout = Instance.new("UIListLayout")
	vhLayout.SortOrder = Enum.SortOrder.LayoutOrder
	vhLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	vhLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	vhLayout.Padding = UDim.new(0, 15)
	vhLayout.Parent = viewHosting

	hostingLbl = Instance.new("TextLabel")
	hostingLbl.Name = "HostingLbl"
	hostingLbl.LayoutOrder = 1
	hostingLbl.Size = UDim2.new(1, 0, 0, 30)
	hostingLbl.BackgroundTransparency = 1
	hostingLbl.Font = Enum.Font.GothamBold
	hostingLbl.TextColor3 = Color3.new(1, 1, 1)
	hostingLbl.TextScaled = true
	hostingLbl.Text = "Party: 1/4 Players"
	hostingLbl.ZIndex = 22
	hostingLbl.Parent = viewHosting

	local hostingBtnsContainer = Instance.new("Frame")
	hostingBtnsContainer.Size = UDim2.new(1, 0, 0, 45)
	hostingBtnsContainer.BackgroundTransparency = 1
	hostingBtnsContainer.LayoutOrder = 2
	hostingBtnsContainer.Parent = viewHosting

	local hbLayout = Instance.new("UIListLayout")
	hbLayout.FillDirection = Enum.FillDirection.Horizontal
	hbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hbLayout.Padding = UDim.new(0, 10)
	hbLayout.Parent = hostingBtnsContainer

	startRaidBtn = Instance.new("TextButton")
	startRaidBtn.Name = "StartRaidBtn"
	startRaidBtn.Size = UDim2.new(0.42, 0, 1, 0)
	startRaidBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	startRaidBtn.Font = Enum.Font.GothamBold
	startRaidBtn.TextColor3 = Color3.new(1, 1, 1)
	startRaidBtn.TextScaled = true
	startRaidBtn.Text = "Start Solo"
	startRaidBtn.ZIndex = 22
	startRaidBtn.Parent = hostingBtnsContainer
	Instance.new("UITextSizeConstraint", startRaidBtn).MaxTextSize = 14
	Instance.new("UICorner", startRaidBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(startRaidBtn, 80, 180, 80)

	cancelLobbyBtn = Instance.new("TextButton")
	cancelLobbyBtn.Name = "CancelLobbyBtn"
	cancelLobbyBtn.Size = UDim2.new(0.42, 0, 1, 0)
	cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	cancelLobbyBtn.Font = Enum.Font.GothamBold
	cancelLobbyBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelLobbyBtn.TextScaled = true
	cancelLobbyBtn.Text = "Disband"
	cancelLobbyBtn.ZIndex = 22
	cancelLobbyBtn.Parent = hostingBtnsContainer
	Instance.new("UITextSizeConstraint", cancelLobbyBtn).MaxTextSize = 14
	Instance.new("UICorner", cancelLobbyBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(cancelLobbyBtn, 150, 150, 150)

	openSetupBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); viewDefault.Visible = false; viewSetup.Visible = true end)
	cancelSetupBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); viewSetup.Visible = false; viewDefault.Visible = true end)
	friendsToggleBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); isFriendsOnly = not isFriendsOnly
		friendsToggleBtn.Text = isFriendsOnly and "[X] Friends Only" or "[ ] Friends Only"
		friendsToggleBtn.TextColor3 = isFriendsOnly and Color3.fromRGB(50, 255, 50) or Color3.new(1, 1, 1)
	end)
	confirmSetupBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		RaidAction:FireServer("CreateLobby", {RaidId = selectedRaidId, FriendsOnly = isFriendsOnly})
	end)
	cancelLobbyBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); RaidAction:FireServer("CancelLobby") end)
	startRaidBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); RaidAction:FireServer("ForceStartRaid") end)

	lobbyCard = CreateCard("LobbyCard", matchmakingFrame, UDim2.new(0.48, 0, 1, -45), UDim2.new(0.52, 0, 0, 45))

	local lobbyTitle = Instance.new("TextLabel")
	lobbyTitle.Size = UDim2.new(1, 0, 0, 30)
	lobbyTitle.Position = UDim2.new(0, 0, 0, 5)
	lobbyTitle.BackgroundTransparency = 1
	lobbyTitle.Font = Enum.Font.GothamBlack
	lobbyTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	lobbyTitle.TextScaled = true
	lobbyTitle.Text = "OPEN PARTIES"
	lobbyTitle.ZIndex = 22
	lobbyTitle.Parent = lobbyCard

	lobbyContainer = Instance.new("ScrollingFrame")
	lobbyContainer.Name = "LobbyContainer"
	lobbyContainer.Size = UDim2.new(1, 0, 1, -45)
	lobbyContainer.Position = UDim2.new(0, 0, 0, 45)
	lobbyContainer.BackgroundTransparency = 1
	lobbyContainer.ScrollBarThickness = 6
	lobbyContainer.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	lobbyContainer.ZIndex = 21
	lobbyContainer.Parent = lobbyCard

	local lcPad = Instance.new("UIPadding")
	lcPad.PaddingTop = UDim.new(0, 5)
	lcPad.PaddingRight = UDim.new(0, 8)
	lcPad.PaddingLeft = UDim.new(0, 4) 
	lcPad.Parent = lobbyContainer

	local lcLayout = Instance.new("UIListLayout")
	lcLayout.FillDirection = Enum.FillDirection.Vertical
	lcLayout.SortOrder = Enum.SortOrder.LayoutOrder
	lcLayout.Padding = UDim.new(0, 10)
	lcLayout.Parent = lobbyContainer

	-- ==========================================================
	-- COMBAT CARD (Injected from CombatTemplate)
	-- ==========================================================
	combatCard = Instance.new("Frame")
	combatCard.Name = "CombatCard"
	combatCard.Size = UDim2.new(1, 0, 1, 0)
	combatCard.BackgroundTransparency = 1
	combatCard.Visible = false
	combatCard.Parent = parentFrame

	combatUI = CombatTemplate.Create(combatCard, tooltipMgr)

	-- Add specific Raid components (Turn Timer & Resources) into the ContentContainer cleanly
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

	resourceLabel = Instance.new("TextLabel")
	resourceLabel.Size = UDim2.new(1, 0, 0.05, 0)
	resourceLabel.BackgroundTransparency = 1
	resourceLabel.Font = Enum.Font.GothamBold
	resourceLabel.TextColor3 = Color3.fromRGB(255, 235, 130)
	resourceLabel.TextScaled = true
	resourceLabel.ZIndex = 22
	resourceLabel.Text = "STAMINA: 100 | ENERGY: 10"
	resourceLabel.LayoutOrder = 2 
	resourceLabel.Parent = combatUI.ContentContainer

	local resUic = Instance.new("UITextSizeConstraint")
	resUic.MaxTextSize = 18
	resUic.MinTextSize = 10
	resUic.Parent = resourceLabel

	waitingLabel = Instance.new("TextLabel")
	waitingLabel.Name = "WaitingLabel"
	waitingLabel.Size = UDim2.new(1, 0, 0.25, 0)
	waitingLabel.BackgroundTransparency = 1
	waitingLabel.Font = Enum.Font.GothamMedium
	waitingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	waitingLabel.TextScaled = true
	waitingLabel.Text = "Waiting for other players..."
	waitingLabel.Visible = false
	waitingLabel.ZIndex = 22
	waitingLabel.LayoutOrder = 4
	waitingLabel.Parent = combatUI.ContentContainer

	local wUic = Instance.new("UITextSizeConstraint")
	wUic.MaxTextSize = 24
	wUic.MinTextSize = 10
	wUic.Parent = waitingLabel

	-- ==========================================================
	-- LOGIC LOOPS & NETWORKING
	-- ==========================================================
	task.spawn(function()
		while task.wait(0.2) do
			if combatCard.Visible and currentDeadline > 0 then
				local remain = math.max(0, currentDeadline - os.time())
				turnTimerLabel.Text = "Time Remaining: " .. remain .. "s"
				if remain <= 5 then turnTimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				else turnTimerLabel.TextColor3 = Color3.fromRGB(255, 215, 0) end
			end
		end
	end)

	RaidUpdate.OnClientEvent:Connect(function(action, data)
		RaidsTab.HandleUpdate(action, data)
	end)
end

function RaidsTab.UpdateCombatState(state)
	local processed = {}

	-- Render Party (Allies)
	for _, pData in ipairs(state.Party) do
		local id = tostring(pData.UserId)
		processed[id] = true
		local fObj = activeFighters[id]

		if not fObj then
			-- CombatTemplate expects: isAlly, id, name, iconId, initialHp, maxHp
			fObj = combatUI:AddFighter(true, id, pData.Name, id, pData.HP, pData.MaxHP)
			activeFighters[id] = fObj
		else
			fObj:UpdateHealth(pData.HP, pData.MaxHP)
		end

		-- Sync Statuses
		local currentStatuses = {}
		if pData.Statuses then
			for eff, duration in pairs(pData.Statuses) do
				if duration and duration > 0 then
					currentStatuses[eff] = true
					fObj:SetStatus(eff, StatusIcons[eff] or "EFF", tostring(duration), StatusDescs[eff] or "Active effect.")
				end
			end
		end

		for eff, _ in pairs(StatusIcons) do
			if not currentStatuses[eff] then
				fObj:RemoveStatus(eff)
			end
		end

		-- Sync Immunities
		local hasStunImmunity = (pData.StunImmunity and pData.StunImmunity > 0)
		if hasStunImmunity then
			fObj:SetCooldown("StunImmunity", "STN", tostring(pData.StunImmunity), "Immune to Stun effects.")
		else
			fObj:RemoveCooldown("StunImmunity")
		end

		local hasConfImmunity = (pData.ConfusionImmunity and pData.ConfusionImmunity > 0)
		if hasConfImmunity then
			fObj:SetCooldown("ConfImmunity", "CNF", tostring(pData.ConfusionImmunity), "Immune to Confusion effects.")
		else
			fObj:RemoveCooldown("ConfImmunity")
		end

		if pData.UserId == state.MyId then
			resourceLabel.Text = "STAMINA: " .. math.floor(pData.Stamina) .. " | ENERGY: " .. math.floor(pData.StandEnergy)
		end
	end

	-- Render Boss (Enemy)
	local bId = "Boss_" .. (state.Boss.Name or "Unknown")
	processed[bId] = true
	local bObj = activeFighters[bId]

	if not bObj then
		bObj = combatUI:AddFighter(false, bId, state.Boss.Name, "", state.Boss.HP, state.Boss.MaxHP)
		activeFighters[bId] = bObj
	else
		bObj:UpdateHealth(state.Boss.HP, state.Boss.MaxHP)
	end

	-- Sync Boss Statuses
	local bossStatuses = {}
	if state.Boss.Statuses then
		for eff, duration in pairs(state.Boss.Statuses) do
			if duration and duration > 0 then
				bossStatuses[eff] = true
				bObj:SetStatus(eff, StatusIcons[eff] or "EFF", tostring(duration), StatusDescs[eff] or "Active effect.")
			end
		end
	end

	for eff, _ in pairs(StatusIcons) do
		if not bossStatuses[eff] then
			bObj:RemoveStatus(eff)
		end
	end

	-- Sync Boss Immunities
	local hasBossStunImmunity = (state.Boss.StunImmunity and state.Boss.StunImmunity > 0)
	if hasBossStunImmunity then
		bObj:SetCooldown("StunImmunity", "STN", tostring(state.Boss.StunImmunity), "Immune to Stun effects.")
	else
		bObj:RemoveCooldown("StunImmunity")
	end

	local hasBossConfImmunity = (state.Boss.ConfusionImmunity and state.Boss.ConfusionImmunity > 0)
	if hasBossConfImmunity then
		bObj:SetCooldown("ConfImmunity", "CNF", tostring(state.Boss.ConfusionImmunity), "Immune to Confusion effects.")
	else
		bObj:RemoveCooldown("ConfImmunity")
	end

	-- Cleanup dead/missing fighters
	for id, fObj in pairs(activeFighters) do
		if not processed[id] then
			if fObj.Frame then fObj.Frame:Destroy() end
			activeFighters[id] = nil
		end
	end
end

function RaidsTab.RenderSkills(state)
	combatUI:ClearAbilities()
	combatUI.AbilitiesArea.Visible = true
	waitingLabel.Visible = false

	local myState = nil
	for _, p in ipairs(state.Party) do 
		if p.UserId == state.MyId then 
			myState = p 
			break 
		end 
	end
	if not myState then return end

	local myStand, myStyle = myState.Stand or "None", myState.Style or "None"
	local valid = {}
	for n, s in pairs(SkillData.Skills) do
		if s.Requirement == "None" or s.Requirement == myStand or s.Requirement == myStyle or (s.Requirement == "AnyStand" and myStand ~= "None") then 
			table.insert(valid, {Name = n, Data = s}) 
		end
	end
	table.sort(valid, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)

	local function submitAttack(skName)
		SFXManager.Play("Click")
		cachedTooltipMgr.Hide()
		combatUI.AbilitiesArea.Visible = false
		waitingLabel.Text = "Waiting for other players..."
		waitingLabel.Visible = true
		RaidAction:FireServer("Attack", skName) 
	end

	for _, sk in ipairs(valid) do
		local c = sk.Data.Type == "Stand" and Color3.fromRGB(120, 20, 160) or (sk.Data.Type == "Style" and Color3.fromRGB(180, 80, 20) or Color3.fromRGB(60, 60, 80))
		local btn = combatUI:AddAbility(sk.Name, c, nil)

		local currentCooldown = myState.Cooldowns and myState.Cooldowns[sk.Name] or 0

		if myState.Stamina < (sk.Data.StaminaCost or 0) or myState.StandEnergy < (sk.Data.EnergyCost or 0) or currentCooldown > 0 then
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

function RaidsTab.HandleUpdate(action, data)
	if action == "LobbyStatus" then
		if data.IsHosting then
			viewDefault.Visible = false
			viewSetup.Visible = false
			viewHosting.Visible = true

			local count = data.PlayerCount or 1
			hostingLbl.Text = "Party: " .. count .. "/4 Players"

			if data.IsLobbyOwner then
				startRaidBtn.Visible = true
				startRaidBtn.Text = count > 1 and "Start Raid" or "Start Solo"

				cancelLobbyBtn.Size = UDim2.new(0.42, 0, 1, 0)
				cancelLobbyBtn.Text = "Disband Party"
				cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				startRaidBtn.Visible = false

				cancelLobbyBtn.Size = UDim2.new(0.6, 0, 1, 0)
				cancelLobbyBtn.Text = "Leave Party"
				cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(140, 80, 40)
			end
		else
			viewDefault.Visible = true
			viewSetup.Visible = false
			viewHosting.Visible = false
		end

	elseif action == "LobbiesUpdate" then
		if data.RaidId ~= selectedRaidId then return end
		local lobbies = data.Lobbies

		for _, child in pairs(lobbyContainer:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
		end

		if #lobbies == 0 then
			local empty = Instance.new("TextLabel", lobbyContainer)
			empty.Size = UDim2.new(1, 0, 0, 40)
			empty.BackgroundTransparency = 1
			empty.Text = "No open parties found for this Raid."
			empty.TextColor3 = Color3.fromRGB(150, 150, 150)
			empty.Font = Enum.Font.GothamMedium
			empty.TextScaled = true
			empty.TextWrapped = true
			empty.ZIndex = 22

			local eUic = Instance.new("UITextSizeConstraint", empty)
			eUic.MaxTextSize = 16
			eUic.MinTextSize = 10
			return
		end

		for i, lobby in ipairs(lobbies) do
			local row = CreateCard("LobbyRow_" .. i, lobbyContainer, UDim2.new(1, 0, 0, 60), nil)
			row.LayoutOrder = i

			local infoText = "<b>" .. lobby.HostName .. "'s Party</b>"
			if lobby.FriendsOnly then infoText = infoText .. " <font color='#55FF55'>[Friends]</font>" end
			infoText = infoText .. "\n<font color='#AAAAAA' size='12'>Members: " .. table.concat(lobby.Members, ", ") .. "</font>"

			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(0.65, 0, 1, 0)
			lbl.Position = UDim2.new(0, 10, 0, 0)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.GothamMedium
			lbl.TextColor3 = Color3.new(1, 1, 1)
			lbl.TextScaled = true
			lbl.RichText = true
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.Text = infoText
			lbl.ZIndex = 22
			lbl.Parent = row

			local lUic = Instance.new("UITextSizeConstraint")
			lUic.MaxTextSize = 14
			lUic.Parent = lbl

			local countLbl = Instance.new("TextLabel")
			countLbl.Size = UDim2.new(0.15, 0, 1, 0)
			countLbl.Position = UDim2.new(0.65, 0, 0, 0)
			countLbl.BackgroundTransparency = 1
			countLbl.Font = Enum.Font.GothamBold
			countLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
			countLbl.TextScaled = true
			countLbl.Text = (lobby.PlayerCount or 1) .. "/4"
			countLbl.ZIndex = 22
			countLbl.Parent = row

			local cUic = Instance.new("UITextSizeConstraint")
			cUic.MaxTextSize = 16
			cUic.Parent = countLbl

			local joinBtn = Instance.new("TextButton")
			joinBtn.Size = UDim2.new(0.15, 0, 0.6, 0)
			joinBtn.Position = UDim2.new(1, -10, 0.5, 0)
			joinBtn.AnchorPoint = Vector2.new(1, 0.5)
			joinBtn.Font = Enum.Font.GothamBold
			joinBtn.TextColor3 = Color3.new(1, 1, 1)
			joinBtn.TextScaled = true
			joinBtn.ZIndex = 22
			joinBtn.Parent = row
			Instance.new("UITextSizeConstraint", joinBtn).MaxTextSize = 14
			Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)

			if lobby.HostId == player.UserId then
				joinBtn.Text = "Hosting"
				joinBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				joinBtn.Text = "Join"
				joinBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
				AddBtnStroke(joinBtn, 180, 80, 200)
				joinBtn.MouseButton1Click:Connect(function()
					SFXManager.Play("Click")
					RaidAction:FireServer("JoinLobby", {HostId = lobby.HostId})
				end)
			end
		end

	elseif action == "MatchStart" then
		if forceTabFocus then forceTabFocus() end 
		menuFrame.Visible = false
		matchmakingFrame.Visible = false
		combatCard.Visible = true

		currentDeadline = data.Deadline or 0

		combatUI.ChatText.Text = ""
		combatUI:Log("<font color='#FFD700'>" .. data.LogMsg .. "</font>")

		RaidsTab.UpdateCombatState(data.State)
		RaidsTab.RenderSkills(data.State)

	elseif action == "Waiting" then
		combatUI.AbilitiesArea.Visible = false
		waitingLabel.Text = "Waiting for other players..."
		waitingLabel.Visible = true

	elseif action == "TurnResult" then
		currentDeadline = data.Deadline or 0

		if data.LogMsg and data.LogMsg ~= "" then
			combatUI.AbilitiesArea.Visible = false
			waitingLabel.Text = ""
			waitingLabel.Visible = true

			local lines = string.split(data.LogMsg, "\n")
			for _, line in ipairs(lines) do 
				if line ~= "" then 
					combatUI:Log(line) 
				end 
			end

			if string.find(data.LogMsg, "dodged!") then SFXManager.Play("CombatDodge")
			elseif string.find(data.LogMsg, "Blocked") then SFXManager.Play("CombatBlock")
			elseif data.DidHit then SFXManager.Play("CombatHit")
			elseif string.find(data.LogMsg, "used <b>") then SFXManager.Play("CombatUtility") end

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
					for i = 1, 6 do 
						if combatCard then
							combatCard.Position = orig + UDim2.new(0, math.random(-p, p), 0, math.random(-p, p))
						end
						task.wait(0.04) 
					end
					if combatCard then
						combatCard.Position = orig
					end
				end)
			end
		end

		RaidsTab.UpdateCombatState(data.State)

		if data.LogMsg == "" then
			RaidsTab.RenderSkills(data.State)
		end

	elseif action == "MatchOver" then
		currentDeadline = 0
		turnTimerLabel.Text = "Raid Over!"
		combatUI:ClearAbilities()
		combatUI.AbilitiesArea.Visible = false
		waitingLabel.Visible = false
		combatUI:Log(data.LogMsg)

		if data.Result == "Win" then SFXManager.Play("CombatVictory") else SFXManager.Play("CombatDefeat") end

		task.delay(5, function()
			viewDefault.Visible = true
			viewSetup.Visible = false
			viewHosting.Visible = false

			hostCard.Visible = true
			lobbyCard.Visible = true
			combatCard.Visible = false
			menuFrame.Visible = true

			RaidAction:FireServer("RequestLobbies", selectedRaidId)
		end)
	end
end

return RaidsTab