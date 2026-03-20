-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local RaidsTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))

local RaidAction = Network:WaitForChild("RaidAction")
local RaidUpdate = Network:WaitForChild("RaidUpdate")

local menuFrame, matchmakingFrame, combatCard
local raidTitleLabel
local hostCard, lobbyCard
local viewDefault, viewSetup, viewHosting
local hostingLbl, cancelLobbyBtn, startRaidBtn
local lobbyContainer

local partyContainer, bossContainer
local activeHPBars = {}
local bossHPBar = nil
local resourceLabel, turnTimerLabel, logScroll, skillsContainer, waitingLabel

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

local function CreateHPBarProgrammatic(parent, isMe, isBoss)
	local wrapper = Instance.new("Frame")
	wrapper.Size = isBoss and UDim2.new(1, 0, 1, 0) or UDim2.new(1, 0, 0, 50)
	wrapper.BackgroundTransparency = 1
	wrapper.Parent = parent

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0, 20)
	nameLbl.Position = UDim2.new(0, 0, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextColor3 = isBoss and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 215, 50)
	nameLbl.TextScaled = true
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.ZIndex = 22
	nameLbl.Parent = wrapper

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 0, 20)
	bg.Position = UDim2.new(0, 0, 0, 22)
	bg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	bg.ZIndex = 21
	bg.Parent = wrapper

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 4)
	bgCorner.Parent = bg

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = isMe and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(255, 50, 50)
	fill.ZIndex = 22
	fill.Parent = bg

	local fCorner = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(0, 4)
	fCorner.Parent = fill

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.GothamBold
	txt.TextColor3 = Color3.new(1, 1, 1)
	txt.TextScaled = true
	txt.ZIndex = 23
	txt.Parent = bg

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Size = UDim2.new(1, 0, 0, 15)
	statusLbl.Position = UDim2.new(0, 0, 0, 45)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Font = Enum.Font.GothamMedium
	statusLbl.TextColor3 = Color3.new(1, 1, 1)
	statusLbl.TextScaled = true
	statusLbl.RichText = true
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.ZIndex = 22
	statusLbl.Parent = wrapper

	local immLbl = Instance.new("TextLabel")
	immLbl.Size = UDim2.new(0.5, 0, 0, 15)
	immLbl.Position = UDim2.new(0.5, 0, 0, 0)
	immLbl.BackgroundTransparency = 1
	immLbl.Font = Enum.Font.GothamMedium
	immLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	immLbl.TextScaled = true
	immLbl.TextXAlignment = Enum.TextXAlignment.Right
	immLbl.ZIndex = 22
	immLbl.Parent = wrapper

	local cImmLbl = Instance.new("TextLabel")
	cImmLbl.Size = UDim2.new(0.5, 0, 0, 15)
	cImmLbl.Position = UDim2.new(0.5, 0, 0, 15)
	cImmLbl.BackgroundTransparency = 1
	cImmLbl.Font = Enum.Font.GothamMedium
	cImmLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	cImmLbl.TextScaled = true
	cImmLbl.TextXAlignment = Enum.TextXAlignment.Right
	cImmLbl.ZIndex = 22
	cImmLbl.Parent = wrapper

	return {
		Wrapper = wrapper,
		Fill = fill,
		Txt = txt,
		Label = nameLbl,
		Status = statusLbl,
		Immunity = immLbl,
		CImmunity = cImmLbl
	}
end

local function BuildStatusString(statuses)
	if not statuses then return "" end
	local active = {}
	local colors = {
		Stun = "#FFFF55", Poison = "#AA00AA", Burn = "#FF5500", Bleed = "#FF0000", Freeze = "#00FFFF", Confusion = "#FF55FF",
		Buff_Strength = "#55FF55", Buff_Defense = "#55FF55", Buff_Speed = "#55FF55", Buff_Willpower = "#55FF55",
		Debuff_Strength = "#FF5555", Debuff_Defense = "#FF5555", Debuff_Speed = "#FF5555", Debuff_Willpower = "#FF5555"
	}
	local names = {
		Buff_Strength = "Str+", Buff_Defense = "Def+", Buff_Speed = "Spd+", Buff_Willpower = "Will+",
		Debuff_Strength = "Str-", Debuff_Defense = "Def-", Debuff_Speed = "Spd-", Debuff_Willpower = "Will-"
	}
	local order = {"Stun", "Freeze", "Confusion", "Bleed", "Poison", "Burn", "Buff_Strength", "Buff_Defense", "Buff_Speed", "Buff_Willpower", "Debuff_Strength", "Debuff_Defense", "Debuff_Speed", "Debuff_Willpower"}

	for _, eff in ipairs(order) do
		local duration = statuses[eff]
		if duration and duration > 0 then
			local color = colors[eff] or "#FFFFFF"
			local name = names[eff] or eff
			table.insert(active, "<font color='" .. color .. "'>" .. name .. " (" .. duration .. ")</font>")
		end
	end
	return table.concat(active, " | ")
end

local function AddLog(text)
	local line = Instance.new("TextLabel")
	line.Size = UDim2.new(1, 0, 0, 20)
	line.BackgroundTransparency = 1
	line.Font = Enum.Font.GothamMedium
	line.TextColor3 = Color3.fromRGB(220, 220, 220)
	line.TextSize = 14
	line.TextWrapped = true
	line.RichText = true
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.TextYAlignment = Enum.TextYAlignment.Top
	line.ZIndex = 23
	line.Text = text
	line.Parent = logScroll

	task.defer(function() 
		logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y) 
	end)
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
	mfPad.PaddingTop = UDim.new(0, 10)
	mfPad.PaddingBottom = UDim.new(0, 10)
	mfPad.PaddingLeft = UDim.new(0, 5) -- Fixed Left Outline Cutoff
	mfPad.PaddingRight = UDim.new(0, 10)
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
		title.ZIndex = 22 -- Fixed Visibility
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
		desc.ZIndex = 22 -- Fixed Visibility
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
		status.ZIndex = 22 -- Fixed Visibility
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
		playBtn.ZIndex = 22 -- Fixed Visibility
		playBtn.Parent = row
		Instance.new("UITextSizeConstraint", playBtn).MaxTextSize = 16

		local pbCorner = Instance.new("UICorner")
		pbCorner.CornerRadius = UDim.new(0, 6)
		pbCorner.Parent = playBtn

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

		uiElements[rInfo.Id] = {Row = row, Status = status, Btn = playBtn, Info = rInfo}
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
					else
						data.Btn.BackgroundColor3 = Color3.fromRGB(35, 25, 40)
						data.Btn.Text = "🔒"
						data.Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
						data.Status.Text = "<font color='#FF5555'>Requires Prestige " .. data.Info.Req .. "</font>"
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
	matchmakingFrame.BackgroundTransparency = 1
	matchmakingFrame.Visible = false
	matchmakingFrame.Parent = parentFrame

	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 50)
	topBar.BackgroundTransparency = 1
	topBar.Parent = matchmakingFrame

	local backBtn = Instance.new("TextButton")
	backBtn.Name = "BackBtn"
	backBtn.Size = UDim2.new(0, 100, 1, 0)
	backBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	backBtn.Font = Enum.Font.GothamBold
	backBtn.TextColor3 = Color3.new(1, 1, 1)
	backBtn.TextScaled = true
	backBtn.Text = "BACK"
	backBtn.ZIndex = 22
	backBtn.Parent = topBar

	local bbCorner = Instance.new("UICorner")
	bbCorner.CornerRadius = UDim.new(0, 6)
	bbCorner.Parent = backBtn

	backBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		matchmakingFrame.Visible = false
		menuFrame.Visible = true
		selectedRaidId = nil
		RaidAction:FireServer("CancelLobby")
	end)

	raidTitleLabel = Instance.new("TextLabel")
	raidTitleLabel.Name = "RaidTitleLabel"
	raidTitleLabel.Size = UDim2.new(1, -120, 1, 0)
	raidTitleLabel.Position = UDim2.new(0, 120, 0, 0)
	raidTitleLabel.BackgroundTransparency = 1
	raidTitleLabel.Font = Enum.Font.GothamBlack
	raidTitleLabel.TextColor3 = Color3.fromRGB(255, 215, 50)
	raidTitleLabel.TextScaled = true
	raidTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	raidTitleLabel.ZIndex = 22
	raidTitleLabel.Parent = topBar

	hostCard = CreateCard("HostCard", matchmakingFrame, UDim2.new(0.48, 0, 1, -60), UDim2.new(0, 0, 0, 60))

	local hostTitle = Instance.new("TextLabel")
	hostTitle.Size = UDim2.new(1, 0, 0, 30)
	hostTitle.BackgroundTransparency = 1
	hostTitle.Font = Enum.Font.GothamBlack
	hostTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	hostTitle.TextScaled = true
	hostTitle.Text = "HOST PARTY"
	hostTitle.ZIndex = 22
	hostTitle.Parent = hostCard

	viewDefault = Instance.new("Frame")
	viewDefault.Name = "ViewDefault"
	viewDefault.Size = UDim2.new(1, 0, 1, -40)
	viewDefault.Position = UDim2.new(0, 0, 0, 40)
	viewDefault.BackgroundTransparency = 1
	viewDefault.Visible = true
	viewDefault.ZIndex = 21
	viewDefault.Parent = hostCard

	local openSetupBtn = Instance.new("TextButton")
	openSetupBtn.Name = "OpenSetupBtn"
	openSetupBtn.Size = UDim2.new(0.6, 0, 0, 50)
	openSetupBtn.Position = UDim2.new(0.2, 0, 0.4, 0)
	openSetupBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 140)
	openSetupBtn.Font = Enum.Font.GothamBold
	openSetupBtn.TextColor3 = Color3.new(1, 1, 1)
	openSetupBtn.TextScaled = true
	openSetupBtn.Text = "Create New Party"
	openSetupBtn.ZIndex = 22
	openSetupBtn.Parent = viewDefault

	local osCorner = Instance.new("UICorner")
	osCorner.CornerRadius = UDim.new(0, 6)
	osCorner.Parent = openSetupBtn

	viewSetup = Instance.new("Frame")
	viewSetup.Name = "ViewSetup"
	viewSetup.Size = UDim2.new(1, 0, 1, -40)
	viewSetup.Position = UDim2.new(0, 0, 0, 40)
	viewSetup.BackgroundTransparency = 1
	viewSetup.Visible = false
	viewSetup.ZIndex = 21
	viewSetup.Parent = hostCard

	local friendsToggleBtn = Instance.new("TextButton")
	friendsToggleBtn.Name = "FriendsToggleBtn"
	friendsToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
	friendsToggleBtn.Position = UDim2.new(0.1, 0, 0.1, 0)
	friendsToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
	friendsToggleBtn.Font = Enum.Font.GothamBold
	friendsToggleBtn.TextColor3 = Color3.new(1, 1, 1)
	friendsToggleBtn.TextScaled = true
	friendsToggleBtn.Text = "[ ] Friends Only"
	friendsToggleBtn.ZIndex = 22
	friendsToggleBtn.Parent = viewSetup

	local ftCorner = Instance.new("UICorner")
	ftCorner.CornerRadius = UDim.new(0, 6)
	ftCorner.Parent = friendsToggleBtn

	local confirmSetupBtn = Instance.new("TextButton")
	confirmSetupBtn.Name = "ConfirmSetupBtn"
	confirmSetupBtn.Size = UDim2.new(0.8, 0, 0, 50)
	confirmSetupBtn.Position = UDim2.new(0.1, 0, 0.5, 0)
	confirmSetupBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	confirmSetupBtn.Font = Enum.Font.GothamBold
	confirmSetupBtn.TextColor3 = Color3.new(1, 1, 1)
	confirmSetupBtn.TextScaled = true
	confirmSetupBtn.Text = "Confirm Setup"
	confirmSetupBtn.ZIndex = 22
	confirmSetupBtn.Parent = viewSetup

	local csCorner = Instance.new("UICorner")
	csCorner.CornerRadius = UDim.new(0, 6)
	csCorner.Parent = confirmSetupBtn

	local cancelSetupBtn = Instance.new("TextButton")
	cancelSetupBtn.Name = "CancelSetupBtn"
	cancelSetupBtn.Size = UDim2.new(0.8, 0, 0, 40)
	cancelSetupBtn.Position = UDim2.new(0.1, 0, 0.8, 0)
	cancelSetupBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
	cancelSetupBtn.Font = Enum.Font.GothamBold
	cancelSetupBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelSetupBtn.TextScaled = true
	cancelSetupBtn.Text = "Cancel"
	cancelSetupBtn.ZIndex = 22
	cancelSetupBtn.Parent = viewSetup

	local cstCorner = Instance.new("UICorner")
	cstCorner.CornerRadius = UDim.new(0, 6)
	cstCorner.Parent = cancelSetupBtn

	viewHosting = Instance.new("Frame")
	viewHosting.Name = "ViewHosting"
	viewHosting.Size = UDim2.new(1, 0, 1, -40)
	viewHosting.Position = UDim2.new(0, 0, 0, 40)
	viewHosting.BackgroundTransparency = 1
	viewHosting.Visible = false
	viewHosting.ZIndex = 21
	viewHosting.Parent = hostCard

	hostingLbl = Instance.new("TextLabel")
	hostingLbl.Name = "HostingLbl"
	hostingLbl.Size = UDim2.new(1, 0, 0, 40)
	hostingLbl.Position = UDim2.new(0, 0, 0.1, 0)
	hostingLbl.BackgroundTransparency = 1
	hostingLbl.Font = Enum.Font.GothamBold
	hostingLbl.TextColor3 = Color3.new(1, 1, 1)
	hostingLbl.TextScaled = true
	hostingLbl.Text = "Party: 1/4 Players"
	hostingLbl.ZIndex = 22
	hostingLbl.Parent = viewHosting

	startRaidBtn = Instance.new("TextButton")
	startRaidBtn.Name = "StartRaidBtn"
	startRaidBtn.Size = UDim2.new(0.42, 0, 0, 50)
	startRaidBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
	startRaidBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
	startRaidBtn.Font = Enum.Font.GothamBold
	startRaidBtn.TextColor3 = Color3.new(1, 1, 1)
	startRaidBtn.TextScaled = true
	startRaidBtn.Text = "Start Solo"
	startRaidBtn.ZIndex = 22
	startRaidBtn.Parent = viewHosting

	local srCorner = Instance.new("UICorner")
	srCorner.CornerRadius = UDim.new(0, 6)
	srCorner.Parent = startRaidBtn

	cancelLobbyBtn = Instance.new("TextButton")
	cancelLobbyBtn.Name = "CancelLobbyBtn"
	cancelLobbyBtn.Size = UDim2.new(0.42, 0, 0, 50)
	cancelLobbyBtn.Position = UDim2.new(0.53, 0, 0.5, 0)
	cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	cancelLobbyBtn.Font = Enum.Font.GothamBold
	cancelLobbyBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelLobbyBtn.TextScaled = true
	cancelLobbyBtn.Text = "Disband"
	cancelLobbyBtn.ZIndex = 22
	cancelLobbyBtn.Parent = viewHosting

	local clCorner = Instance.new("UICorner")
	clCorner.CornerRadius = UDim.new(0, 6)
	clCorner.Parent = cancelLobbyBtn

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

	lobbyCard = CreateCard("LobbyCard", matchmakingFrame, UDim2.new(0.48, 0, 1, -60), UDim2.new(0.52, 0, 0, 60))

	local lobbyTitle = Instance.new("TextLabel")
	lobbyTitle.Size = UDim2.new(1, 0, 0, 30)
	lobbyTitle.BackgroundTransparency = 1
	lobbyTitle.Font = Enum.Font.GothamBlack
	lobbyTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	lobbyTitle.TextScaled = true
	lobbyTitle.Text = "OPEN PARTIES"
	lobbyTitle.ZIndex = 22
	lobbyTitle.Parent = lobbyCard

	lobbyContainer = Instance.new("ScrollingFrame")
	lobbyContainer.Name = "LobbyContainer"
	lobbyContainer.Size = UDim2.new(1, 0, 1, -40)
	lobbyContainer.Position = UDim2.new(0, 0, 0, 40)
	lobbyContainer.BackgroundTransparency = 1
	lobbyContainer.ScrollBarThickness = 6
	lobbyContainer.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	lobbyContainer.ZIndex = 21
	lobbyContainer.Parent = lobbyCard

	local lcPad = Instance.new("UIPadding")
	lcPad.PaddingRight = UDim.new(0, 8)
	lcPad.PaddingLeft = UDim.new(0, 4) -- Fixed Left Cutoff
	lcPad.Parent = lobbyContainer

	local lcLayout = Instance.new("UIListLayout")
	lcLayout.FillDirection = Enum.FillDirection.Vertical
	lcLayout.SortOrder = Enum.SortOrder.LayoutOrder
	lcLayout.Padding = UDim.new(0, 10)
	lcLayout.Parent = lobbyContainer

	-- ==========================================================
	-- COMBAT CARD
	-- ==========================================================
	combatCard = Instance.new("Frame")
	combatCard.Name = "CombatCard"
	combatCard.Size = UDim2.new(1, 0, 1, 0)
	combatCard.BackgroundTransparency = 1
	combatCard.Visible = false
	combatCard.Parent = parentFrame

	local topArea = CreateCard("TopArea", combatCard, UDim2.new(1, 0, 0.45, 0), UDim2.new(0, 0, 0, 0))

	partyContainer = Instance.new("ScrollingFrame")
	partyContainer.Name = "PartyContainer"
	partyContainer.Size = UDim2.new(0.45, 0, 1, -30)
	partyContainer.Position = UDim2.new(0, 0, 0, 30)
	partyContainer.BackgroundTransparency = 1
	partyContainer.ScrollBarThickness = 0
	partyContainer.ZIndex = 21
	partyContainer.Parent = topArea

	local pcLayout = Instance.new("UIListLayout")
	pcLayout.FillDirection = Enum.FillDirection.Vertical
	pcLayout.SortOrder = Enum.SortOrder.LayoutOrder
	pcLayout.Padding = UDim.new(0, 5)
	pcLayout.Parent = partyContainer

	bossContainer = Instance.new("Frame")
	bossContainer.Name = "BossContainer"
	bossContainer.Size = UDim2.new(0.45, 0, 1, -30)
	bossContainer.Position = UDim2.new(0.55, 0, 0, 30)
	bossContainer.BackgroundTransparency = 1
	bossContainer.ZIndex = 21
	bossContainer.Parent = topArea

	turnTimerLabel = Instance.new("TextLabel")
	turnTimerLabel.Name = "TurnTimerLabel"
	turnTimerLabel.Size = UDim2.new(1, 0, 0, 30)
	turnTimerLabel.Position = UDim2.new(0, 0, 0, 0)
	turnTimerLabel.BackgroundTransparency = 1
	turnTimerLabel.Font = Enum.Font.GothamBlack
	turnTimerLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	turnTimerLabel.TextScaled = true
	turnTimerLabel.Text = "Time Remaining: --s"
	turnTimerLabel.ZIndex = 22
	turnTimerLabel.Parent = topArea

	resourceLabel = Instance.new("TextLabel")
	resourceLabel.Name = "ResourceLabel"
	resourceLabel.Size = UDim2.new(1, 0, 0, 30)
	resourceLabel.Position = UDim2.new(0, 0, 1, -30)
	resourceLabel.BackgroundTransparency = 1
	resourceLabel.Font = Enum.Font.GothamBold
	resourceLabel.TextColor3 = Color3.fromRGB(50, 255, 255)
	resourceLabel.TextScaled = true
	resourceLabel.Text = "STAMINA: 100 | ENERGY: 10"
	resourceLabel.ZIndex = 22
	resourceLabel.Parent = topArea

	local realLogScroll = Instance.new("ScrollingFrame")
	realLogScroll.Name = "LogScroll"
	realLogScroll.Size = UDim2.new(1, 0, 0.30, 0)
	realLogScroll.Position = UDim2.new(0, 0, 0.47, 0)
	realLogScroll.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	realLogScroll.ScrollBarThickness = 6
	realLogScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	realLogScroll.ZIndex = 20
	realLogScroll.Parent = combatCard
	logScroll = realLogScroll

	local lsCorner = Instance.new("UICorner")
	lsCorner.CornerRadius = UDim.new(0, 8)
	lsCorner.Parent = logScroll

	local lsStroke = Instance.new("UIStroke")
	lsStroke.Color = Color3.fromRGB(90, 50, 120)
	lsStroke.Thickness = 1
	lsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	lsStroke.Parent = logScroll

	local lsPad = Instance.new("UIPadding")
	lsPad.PaddingTop = UDim.new(0, 8); lsPad.PaddingBottom = UDim.new(0, 8)
	lsPad.PaddingLeft = UDim.new(0, 8); lsPad.PaddingRight = UDim.new(0, 15)
	lsPad.Parent = logScroll

	local lsLayout = Instance.new("UIListLayout")
	lsLayout.FillDirection = Enum.FillDirection.Vertical
	lsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	lsLayout.Padding = UDim.new(0, 2)
	lsLayout.Parent = logScroll

	skillsContainer = Instance.new("Frame")
	skillsContainer.Name = "SkillsContainer"
	skillsContainer.Size = UDim2.new(1, 0, 0.20, 0)
	skillsContainer.Position = UDim2.new(0, 0, 0.80, 0)
	skillsContainer.BackgroundTransparency = 1
	skillsContainer.ZIndex = 21
	skillsContainer.Parent = combatCard

	local skLayout = Instance.new("UIGridLayout")
	skLayout.CellSize = UDim2.new(0.23, 0, 0.45, 0)
	skLayout.CellPadding = UDim2.new(0.02, 0, 0.1, 0)
	skLayout.SortOrder = Enum.SortOrder.LayoutOrder
	skLayout.Parent = skillsContainer

	waitingLabel = Instance.new("TextLabel")
	waitingLabel.Name = "WaitingLabel"
	waitingLabel.Size = UDim2.new(1, 0, 0.20, 0)
	waitingLabel.Position = UDim2.new(0, 0, 0.80, 0)
	waitingLabel.BackgroundTransparency = 1
	waitingLabel.Font = Enum.Font.GothamMedium
	waitingLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	waitingLabel.TextScaled = true
	waitingLabel.Text = "Waiting for other players..."
	waitingLabel.Visible = false
	waitingLabel.ZIndex = 22
	waitingLabel.Parent = combatCard

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
			if logScroll then
				logScroll.CanvasSize = UDim2.new(0, 0, 0, lsLayout.AbsoluteContentSize.Y + 10)
			end
		end
	end)

	RaidUpdate.OnClientEvent:Connect(function(action, data)
		RaidsTab.HandleUpdate(action, data)
	end)
end

function RaidsTab.UpdateCombatState(state)
	for _, c in pairs(partyContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, c in pairs(bossContainer:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

	for _, pData in ipairs(state.Party) do
		local barInfo = CreateHPBarProgrammatic(partyContainer, pData.UserId == state.MyId, false)
		barInfo.Label.Text = pData.Name .. (pData.HP <= 0 and " (DEAD)" or "")
		barInfo.Fill.Size = UDim2.new(math.clamp(pData.HP / pData.MaxHP, 0, 1), 0, 1, 0)
		barInfo.Txt.Text = math.floor(pData.HP) .. "/" .. math.floor(pData.MaxHP)
		barInfo.Status.Text = BuildStatusString(pData.Statuses)

		if pData.StunImmunity and pData.StunImmunity > 0 then
			barInfo.Immunity.Text = "Stun Immune: " .. pData.StunImmunity .. " Turns"
		else
			barInfo.Immunity.Text = ""
		end

		if pData.ConfusionImmunity and pData.ConfusionImmunity > 0 then
			barInfo.CImmunity.Text = "Confuse Immune: " .. pData.ConfusionImmunity .. " Turns"
		else
			barInfo.CImmunity.Text = ""
		end

		if pData.UserId == state.MyId then
			resourceLabel.Text = "STAMINA: " .. math.floor(pData.Stamina) .. " | ENERGY: " .. math.floor(pData.StandEnergy)
		end
	end

	bossHPBar = CreateHPBarProgrammatic(bossContainer, false, true)
	bossHPBar.Label.Text = state.Boss.Name
	bossHPBar.Fill.Size = UDim2.new(math.clamp(state.Boss.HP / state.Boss.MaxHP, 0, 1), 0, 1, 0)
	bossHPBar.Txt.Text = math.floor(state.Boss.HP) .. " / " .. math.floor(state.Boss.MaxHP)
	bossHPBar.Status.Text = BuildStatusString(state.Boss.Statuses)

	if state.Boss.StunImmunity and state.Boss.StunImmunity > 0 then
		bossHPBar.Immunity.Text = "Stun Immune: " .. state.Boss.StunImmunity .. " Turns"
	else
		bossHPBar.Immunity.Text = ""
	end

	if state.Boss.ConfusionImmunity and state.Boss.ConfusionImmunity > 0 then
		bossHPBar.CImmunity.Text = "Confuse Immune: " .. state.Boss.ConfusionImmunity .. " Turns"
	else
		bossHPBar.CImmunity.Text = ""
	end
end

function RaidsTab.RenderSkills(state)
	for _, child in pairs(skillsContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

	local myState = nil
	for _, p in ipairs(state.Party) do if p.UserId == state.MyId then myState = p break end end
	if not myState then return end

	local myStand, myStyle = myState.Stand or "None", myState.Style or "None"
	local valid = {}
	for n, s in pairs(SkillData.Skills) do
		if s.Requirement == "None" or s.Requirement == myStand or s.Requirement == myStyle or (s.Requirement == "AnyStand" and myStand ~= "None") then 
			table.insert(valid, {Name = n, Data = s}) 
		end
	end
	table.sort(valid, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)

	for _, sk in ipairs(valid) do
		local btn = Instance.new("TextButton")
		btn.Name = "SkillBtn_" .. sk.Name
		btn.Text = sk.Name
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextScaled = true
		btn.ZIndex = 22
		btn.Parent = skillsContainer

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 6)
		bCorner.Parent = btn

		local bUic = Instance.new("UITextSizeConstraint")
		bUic.MaxTextSize = 16
		bUic.Parent = btn

		local c = sk.Data.Type == "Stand" and Color3.fromRGB(120, 20, 160) or (sk.Data.Type == "Style" and Color3.fromRGB(180, 80, 20) or Color3.fromRGB(60, 60, 80))
		btn.BackgroundColor3 = c

		btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
		btn.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

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
							if isConfirmingFlee then
								isConfirmingFlee = false
								if btn and btn.Parent then
									btn.Text = sk.Name
									btn.BackgroundColor3 = c
								end
							end
						end)
					else
						cachedTooltipMgr.Hide()
						RaidAction:FireServer("Attack", sk.Name) 
					end
				end)
			else
				btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					cachedTooltipMgr.Hide()
					RaidAction:FireServer("Attack", sk.Name) 
				end)
			end
		end
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
				cancelLobbyBtn.Size = UDim2.new(0.42, 0, 0.4, 0)
				cancelLobbyBtn.Position = UDim2.new(0.53, 0, 0.5, 0)
				cancelLobbyBtn.Text = "Disband Party"
				cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				startRaidBtn.Visible = false
				cancelLobbyBtn.Size = UDim2.new(0.6, 0, 0.4, 0)
				cancelLobbyBtn.Position = UDim2.new(0.2, 0, 0.5, 0)
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
			empty.TextSize = 14
			empty.ZIndex = 22
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

			local jCorner = Instance.new("UICorner")
			jCorner.CornerRadius = UDim.new(0, 6)
			jCorner.Parent = joinBtn

			local jUic = Instance.new("UITextSizeConstraint")
			jUic.MaxTextSize = 14
			jUic.Parent = joinBtn

			if lobby.HostId == player.UserId then
				joinBtn.Text = "Hosting"
				joinBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				joinBtn.Text = "Join"
				joinBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
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
		for _, c in pairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
		AddLog("<font color='#FFD700'>" .. data.LogMsg .. "</font>")
		skillsContainer.Visible = true
		waitingLabel.Visible = false

		RaidsTab.UpdateCombatState(data.State)
		RaidsTab.RenderSkills(data.State)

	elseif action == "Waiting" then
		skillsContainer.Visible = false
		waitingLabel.Text = "Waiting for other players..."
		waitingLabel.Visible = true

	elseif action == "TurnResult" then
		currentDeadline = data.Deadline or 0

		if data.LogMsg and data.LogMsg ~= "" then
			skillsContainer.Visible = false
			waitingLabel.Text = "Combat is playing out..."
			waitingLabel.Visible = true

			local lines = string.split(data.LogMsg, "\n")
			for _, line in ipairs(lines) do if line ~= "" then AddLog(line) end end

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
					local orig = UDim2.new(0.025, 0, 0, 0)
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
		else
			waitingLabel.Visible = false
			skillsContainer.Visible = true
		end

		RaidsTab.UpdateCombatState(data.State)

		if data.LogMsg == "" then
			RaidsTab.RenderSkills(data.State)
		end

	elseif action == "MatchOver" then
		currentDeadline = 0
		turnTimerLabel.Text = "Raid Over!"
		skillsContainer.Visible = false
		waitingLabel.Visible = false
		AddLog(data.LogMsg)

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