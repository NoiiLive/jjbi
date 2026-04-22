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
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))

local ArenaAction = Network:WaitForChild("ArenaAction")
local ArenaUpdate = Network:WaitForChild("ArenaUpdate")

local mainContainer
local lobbyContainer, combatContainer
local profileCard, openQueuesCard, activeMatchesCard
local openQueuesScroll, activeMatchesScroll
local eloLbl

local viewDefault, viewSetup, viewHosting
local friendsToggleBtn, casualToggleBtn, noHoldsBarredBtn, capacityBtn, confirmSetupBtn, cancelSetupBtn
local hostingLbl, cancelLobbyBtn, createRoomBtn

local combatUI
local activeFighters = {}
local turnTimerLabel, combatResourceLabel, waitingLabel
local bettingArea, betInput, betT1Btn, betT2Btn, leaveSpecBtn, bettingStatusLbl
local pool1Lbl, pool2Lbl

local templates

local cachedTooltipMgr = nil
local forceTabFocus = nil
local currentDeadline = 0

local isSpectating = false
local currentMatchId = nil
local selectedTargetId = nil

local isFriendsOnly = false
local isCasual = false
local isNoHoldsBarred = false
local currentCapacity = 2

local StatusIcons = {
	Stun = "STN", Poison = "PSN", Burn = "BRN", Bleed = "BLD", Freeze = "FRZ", Confusion = "CNF", Dizzy = "DZY", Chilly = "CLD",
	Acid = "ACD", Infection = "INF", Rupture = "RPT", Frostburn = "FBN", Frostbite = "FBT", Decay = "DCY",
	Blight = "BLT", Miasma = "MSM", Necrosis = "NCR", Plague = "PLG", Calamity = "CLM", Warded = "WRD",
	Buff_Strength = "STR+", Buff_Defense = "DEF+", Buff_Speed = "SPD+", Buff_Willpower = "WIL+",
	Debuff_Strength = "STR-", Debuff_Defense = "DEF-", Debuff_Speed = "SPD-", Debuff_Willpower = "WIL-",
	EnergyExhausted = "ENG-", StaminaExhausted = "STM-"
}

local StatusDescs = {
	Stun = "Cannot move or act.",
	Poison = "Takes damage every turn.",
	Burn = "Takes damage every turn.",
	Bleed = "Takes damage every turn.",
	Freeze = "Frozen solid. Cannot move, takes damage.",
	Confusion = "May attack allies or self.",
	Dizzy = "May miss or attack self",
	Chilly = "Takes damage every turn.",
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

	templates = ReplicatedStorage:WaitForChild("JJBITemplates")

	lobbyContainer = mainContainer:WaitForChild("LobbyContainer")
	profileCard = lobbyContainer:WaitForChild("ProfileCard")
	eloLbl = profileCard:WaitForChild("EloLbl")

	local milestonesBtn = profileCard:WaitForChild("MilestonesBtn")
	milestonesBtn.MouseEnter:Connect(function()
		local pObj = player:FindFirstChild("leaderstats")
		local elo = pObj and pObj:FindFirstChild("Elo") and pObj.Elo.Value or 1000
		cachedTooltipMgr.Show(GetEloBoostText(elo))
	end)
	milestonesBtn.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

	local hostArea = profileCard:WaitForChild("HostArea")
	viewDefault = hostArea:WaitForChild("ViewDefault")
	createRoomBtn = viewDefault:WaitForChild("CreateRoomBtn")

	viewSetup = hostArea:WaitForChild("ViewSetup")
	friendsToggleBtn = viewSetup:WaitForChild("FriendsToggleBtn")
	casualToggleBtn = viewSetup:WaitForChild("CasualToggleBtn")
	noHoldsBarredBtn = viewSetup:WaitForChild("NoHoldsBarredBtn")
	capacityBtn = viewSetup:WaitForChild("CapacityBtn")
	confirmSetupBtn = viewSetup:WaitForChild("ConfirmSetupBtn")
	cancelSetupBtn = viewSetup:WaitForChild("CancelSetupBtn")

	viewHosting = hostArea:WaitForChild("ViewHosting")
	hostingLbl = viewHosting:WaitForChild("HostingLbl")
	cancelLobbyBtn = viewHosting:WaitForChild("CancelLobbyBtn")

	local rightPanel = lobbyContainer:WaitForChild("RightPanel")
	openQueuesCard = rightPanel:WaitForChild("OpenQueuesCard")
	openQueuesScroll = openQueuesCard:WaitForChild("OpenQueuesScroll")

	activeMatchesCard = rightPanel:WaitForChild("ActiveMatchesCard")
	activeMatchesScroll = activeMatchesCard:WaitForChild("ActiveMatchesScroll")

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

	noHoldsBarredBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click"); isNoHoldsBarred = not isNoHoldsBarred
		noHoldsBarredBtn.Text = isNoHoldsBarred and "[X] No Holds Barred" or "[ ] No Holds Barred"
		noHoldsBarredBtn.TextColor3 = isNoHoldsBarred and Color3.fromRGB(50, 255, 50) or Color3.new(1,1,1)
	end)

	noHoldsBarredBtn.MouseEnter:Connect(function() cachedTooltipMgr.Show("Disables equalized stats, both teams fight using their true level and stats.") end)
	noHoldsBarredBtn.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

	capacityBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if currentCapacity == 2 then currentCapacity = 4; capacityBtn.Text = "Mode: 2v2"
		elseif currentCapacity == 4 then currentCapacity = 8; capacityBtn.Text = "Mode: 4v4"
		else currentCapacity = 2; capacityBtn.Text = "Mode: 1v1" end
	end)

	confirmSetupBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		Network.ArenaAction:FireServer("CreateLobby", {FriendsOnly = isFriendsOnly, Casual = isCasual, Capacity = currentCapacity, NoHoldsBarred = isNoHoldsBarred}) 
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

	combatContainer = mainContainer:WaitForChild("CombatContainer")
	combatUI = CombatTemplate.Create(combatContainer, tooltipMgr)

	turnTimerLabel = templates:WaitForChild("ArenaTurnTimerTemplate"):Clone()
	turnTimerLabel.Parent = combatUI.ContentContainer

	combatResourceLabel = templates:WaitForChild("ArenaResourceLabelTemplate"):Clone()
	combatResourceLabel.Parent = combatUI.ContentContainer

	waitingLabel = templates:WaitForChild("ArenaWaitingLabelTemplate"):Clone()
	waitingLabel.Parent = combatUI.ContentContainer

	bettingArea = templates:WaitForChild("ArenaBettingAreaTemplate"):Clone()
	bettingArea.Parent = combatUI.ContentContainer

	leaveSpecBtn = bettingArea:WaitForChild("LeaveSpecBtn")

	local betCol = bettingArea:WaitForChild("BetCol")
	betInput = betCol:WaitForChild("BetInput")
	bettingStatusLbl = betCol:WaitForChild("BettingStatusLbl")

	local t1Col = bettingArea:WaitForChild("T1Col")
	betT1Btn = t1Col:WaitForChild("BetT1Btn")
	pool1Lbl = t1Col:WaitForChild("Pool1Lbl")

	local t2Col = bettingArea:WaitForChild("T2Col")
	betT2Btn = t2Col:WaitForChild("BetT2Btn")
	pool2Lbl = t2Col:WaitForChild("Pool2Lbl")

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

	local function SetCombatMode(inCombat, spec)
		combatUI.AlliesContainer.Parent.Visible = inCombat
		combatUI.AbilitiesArea.Visible = inCombat and not spec
		bettingArea.Visible = inCombat and spec
		combatResourceLabel.Visible = inCombat and not spec
		turnTimerLabel.Visible = inCombat
		waitingLabel.Visible = false

		if combatUI.ChatScroll and combatUI.ChatScroll.Parent then
			if inCombat then
				if spec then
					combatUI.ChatScroll.Parent.Size = UDim2.new(1, 0, 0.28, 0)
				else
					combatUI.ChatScroll.Parent.Size = UDim2.new(1, 0, 0.13, 0)
				end
			else
				combatUI.ChatScroll.Parent.Size = UDim2.new(1, 0, 0.40, 0)
			end
		end
	end

	task.spawn(function()
		while task.wait(0.2) do
			if combatContainer.Visible and currentDeadline > 0 then
				local remain = math.max(0, currentDeadline - math.floor(workspace:GetServerTimeNow()))
				turnTimerLabel.Text = "Time Remaining: " .. remain .. "s"
				if remain <= 5 then turnTimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				else turnTimerLabel.TextColor3 = Color3.fromRGB(255, 215, 0) end
			end
		end
	end)

	mainContainer:GetPropertyChangedSignal("Visible"):Connect(function()
		if mainContainer.Visible and lobbyContainer.Visible then Network.ArenaAction:FireServer("RequestLobbies") end
	end)

	ArenaTab.SetCombatMode = SetCombatMode
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
		for _, child in pairs(openQueuesScroll:GetChildren()) do 
			if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end 
		end

		if #data == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 40); empty.BackgroundTransparency = 1; empty.Text = "No open rooms found."
			empty.TextColor3 = Color3.fromRGB(150, 150, 150); empty.Font = Enum.Font.GothamMedium; empty.TextScaled = true
			empty.Parent = openQueuesScroll; Instance.new("UITextSizeConstraint", empty).MaxTextSize = 16
			return
		end

		for i, lobby in ipairs(data) do
			local row = templates:WaitForChild("ArenaQueueRowTemplate"):Clone()
			row.Name = "QRow_"..i
			row.LayoutOrder = i
			row.Parent = openQueuesScroll

			local modeStr = (lobby.Capacity == 2 and "1v1") or (lobby.Capacity == 4 and "2v2") or "4v4"
			local infoText = "<b>" .. lobby.HostName .. "'s Room</b> | " .. modeStr .. " | Elo: " .. lobby.Elo
			if lobby.FriendsOnly then infoText = infoText .. " <font color='#55FF55'>[Friends]</font>" end
			if lobby.Casual then infoText = infoText .. " <font color='#55FFFF'>[Casual]</font>" end
			if lobby.NoHoldsBarred then infoText = infoText .. " <font color='#FF5555'>[No Holds Barred]</font>" end

			row:WaitForChild("InfoLabel").Text = infoText

			local maxPerTeam = lobby.Capacity / 2

			local hostLbl = row:WaitForChild("HostLbl")
			local joinBtn = row:WaitForChild("JoinBtn")
			local t1Btn = row:WaitForChild("T1Btn")
			local t2Btn = row:WaitForChild("T2Btn")

			if lobby.HostId == player.UserId then
				hostLbl.Visible = true
			elseif lobby.Capacity == 2 then
				joinBtn.Visible = true
				joinBtn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					Network.ArenaAction:FireServer("JoinLobby", {HostId = lobby.HostId, TeamIndex = 2}) 
				end)
			else
				t1Btn.Visible = true
				t1Btn.Text = "T1 (" .. lobby.T1Count .. "/" .. maxPerTeam .. ")"
				t1Btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click"); Network.ArenaAction:FireServer("JoinLobby", {HostId = lobby.HostId, TeamIndex = 1}) 
				end)

				t2Btn.Visible = true
				t2Btn.Text = "T2 (" .. lobby.T2Count .. "/" .. maxPerTeam .. ")"
				t2Btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click"); Network.ArenaAction:FireServer("JoinLobby", {HostId = lobby.HostId, TeamIndex = 2}) 
				end)
			end
		end
		task.delay(0.05, function()
			local layout = openQueuesScroll:FindFirstChildWhichIsA("UIListLayout")
			if layout then openQueuesScroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10) end
		end)

	elseif action == "ActiveMatchesUpdate" then
		for _, child in pairs(activeMatchesScroll:GetChildren()) do 
			if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end 
		end

		if #data == 0 then
			local empty = Instance.new("TextLabel"); empty.Size = UDim2.new(1, 0, 0, 40); empty.BackgroundTransparency = 1; empty.Text = "No active battles."; empty.TextColor3 = Color3.fromRGB(150, 150, 150); empty.Font = Enum.Font.GothamMedium; empty.TextScaled = true; empty.Parent = activeMatchesScroll; Instance.new("UITextSizeConstraint", empty).MaxTextSize = 16
			return
		end

		for i, match in ipairs(data) do
			local row = templates:WaitForChild("ArenaMatchRowTemplate"):Clone()
			row.Name = "MRow_"..i
			row.LayoutOrder = i
			row.Parent = activeMatchesScroll

			local infoText = "<b>" .. match.HostName .. "'s Match</b> | " .. match.Mode .. "\n<font color='#AAAAAA' size='12'>Pool: ¥" .. (match.Pool1 + match.Pool2) .. " | Spectators: " .. match.SpectatorCount .. "</font>"
			row:WaitForChild("InfoLabel").Text = infoText

			local specBtn = row:WaitForChild("SpecBtn")
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

		isSpectating = data.State.IsSpectator
		currentMatchId = data.State.MatchId

		for fid, fObj in pairs(activeFighters) do if fObj.Frame then fObj.Frame:Destroy() end end
		activeFighters = {}

		task.delay(0.05, function()
			if ArenaTab.SetCombatMode then ArenaTab.SetCombatMode(true, false) end

			combatUI.ChatText.Text = ""
			AppendLog("<font color='#FFD700'><b>" .. data.LogMsg .. "</b></font>")
			selectedTargetId = nil
			ArenaTab.UpdateCombatState(data.State)

			if not isSpectating then 
				ArenaTab.RenderSkills(data.State) 
			end
		end)

	elseif action == "SpectateStart" then
		if forceTabFocus then forceTabFocus() end
		lobbyContainer.Visible = false
		combatContainer.Visible = true
		isSpectating = true
		currentMatchId = data.MatchId

		for fid, fObj in pairs(activeFighters) do if fObj.Frame then fObj.Frame:Destroy() end end
		activeFighters = {}

		task.delay(0.05, function()
			if ArenaTab.SetCombatMode then ArenaTab.SetCombatMode(true, true) end

			combatUI.ChatText.Text = ""

			local t1Name = data.State.MyTeam[1] and data.State.MyTeam[1].Name or "Team 1"
			local t2Name = data.State.EnemyTeam[1] and data.State.EnemyTeam[1].Name or "Team 2"
			AppendLog("<font color='#55FFFF'><b>SPECTATING: " .. t1Name .. " VS " .. t2Name .. "</b></font>")

			betInput.Text = ""
			betInput.Visible = true
			betT1Btn.Text = "Bet Team 1"
			betT1Btn.Visible = true
			betT2Btn.Text = "Bet Team 2"
			betT2Btn.Visible = true
			bettingStatusLbl.Visible = false

			pool1Lbl.Text = "Pool 1: ¥" .. (data.State.Pool1 or 0)
			pool2Lbl.Text = "Pool 2: ¥" .. (data.State.Pool2 or 0)

			ArenaTab.UpdateCombatState(data.State)
		end)

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
				if data.Strikes then
					task.spawn(function()
						for _, strike in ipairs(data.Strikes) do
							local skillInfo = SkillData.Skills[strike.SkillName]
							local eff = skillInfo and skillInfo.Effect or ""
							local isUtility = (eff == "Block" or eff == "Counter" or eff == "Heal" or eff == "Rest" or eff == "CleanseRest" or string.match(eff, "Buff_") or string.match(eff, "Debuff_") or eff == "TimeRewind" or eff == "TimeReset" or eff == "ReturnToZero")

							if (strike.DidHit or isUtility) and strike.Defender then
								local targetFighter = activeFighters[strike.Defender]
								if targetFighter and targetFighter.Frame then
									local iconBox = targetFighter.Frame:FindFirstChild("IconBox")
									if iconBox then
										local displayTarget = iconBox:FindFirstChild("IconImage")
										if displayTarget and not displayTarget.Visible then displayTarget = iconBox:FindFirstChild("IconText") end
										if not displayTarget then displayTarget = iconBox end

										local vfxName = (skillInfo and skillInfo.VFX) or "Punch"
										if eff == "Block" or eff == "Counter" then vfxName = "Block"
										elseif eff == "Heal" or eff == "Rest" or eff == "CleanseRest" or eff == "TimeRewind" or eff == "TimeReset" or eff == "ReturnToZero" then vfxName = "Heal"
										elseif string.match(eff, "Buff_") then vfxName = "Buff"
										elseif string.match(eff, "Debuff_") then vfxName = "Debuff"
										end

										local hits = (skillInfo and skillInfo.Hits) or 1
										if vfxName == "Buff" or vfxName == "Debuff" or vfxName == "Heal" then hits = 5 end
										if vfxName == "Block" then hits = 1 end

										local templates = ReplicatedStorage:FindFirstChild("JJBITemplates")
										local effectsFolder = templates and templates:FindFirstChild("CombatEffects")
										local TweenService = game:GetService("TweenService")

										for i = 1, hits do
											task.spawn(function()
												local vfxObj
												if effectsFolder and effectsFolder:FindFirstChild(vfxName) then
													vfxObj = effectsFolder[vfxName]:Clone()
												elseif effectsFolder and effectsFolder:FindFirstChild("Punch") then
													vfxObj = effectsFolder["Punch"]:Clone()
												else
													vfxObj = Instance.new("ImageLabel")
													vfxObj.BackgroundTransparency = 1
													vfxObj.Image = "rbxassetid://10849495111"
													vfxObj.ImageColor3 = Color3.fromRGB(255, 200, 100)
												end

												vfxObj.ZIndex = displayTarget.ZIndex + 1 
												vfxObj.Parent = displayTarget

												if vfxName == "Buff" then
													vfxObj.Position = UDim2.new(math.random(20, 80)/100, 0, 0.9, 0)
													vfxObj.Size = UDim2.new(0.3, 0, 0.3, 0)

													local tIn = TweenService:Create(vfxObj, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
														Position = UDim2.new(vfxObj.Position.X.Scale, 0, 0.1, 0),
														ImageTransparency = 1
													})
													tIn:Play(); tIn.Completed:Wait()

												elseif vfxName == "Debuff" then
													vfxObj.Position = UDim2.new(math.random(20, 80)/100, 0, 0.1, 0)
													vfxObj.Rotation = 180
													vfxObj.Size = UDim2.new(0.3, 0, 0.3, 0)

													local tIn = TweenService:Create(vfxObj, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
														Position = UDim2.new(vfxObj.Position.X.Scale, 0, 0.9, 0),
														ImageTransparency = 1
													})
													tIn:Play(); tIn.Completed:Wait()

												elseif vfxName == "Heal" then
													vfxObj.Position = UDim2.new(math.random(30, 70)/100, 0, math.random(40, 80)/100, 0)
													vfxObj.Size = UDim2.new(0, 0, 0, 0)

													local tIn = TweenService:Create(vfxObj, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
														Size = UDim2.new(0.4, 0, 0.4, 0),
														Position = UDim2.new(vfxObj.Position.X.Scale, 0, vfxObj.Position.Y.Scale - 0.2, 0)
													})
													tIn:Play(); tIn.Completed:Wait()

													local tOut = TweenService:Create(vfxObj, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
														ImageTransparency = 1,
														Position = UDim2.new(vfxObj.Position.X.Scale, 0, vfxObj.Position.Y.Scale - 0.1, 0)
													})
													tOut:Play(); tOut.Completed:Wait()

												elseif vfxName == "Block" then
													vfxObj.Position = UDim2.new(0.5, 0, 0.5, 0)
													vfxObj.Size = UDim2.new(0, 0, 0, 0)

													local tIn = TweenService:Create(vfxObj, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
														Size = UDim2.new(0.8, 0, 0.8, 0)
													})
													tIn:Play(); task.wait(0.5)

													local tOut = TweenService:Create(vfxObj, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
														ImageTransparency = 1,
														Size = UDim2.new(1, 0, 1, 0)
													})
													tOut:Play(); tOut.Completed:Wait()

												else
													vfxObj.Position = UDim2.new(math.random(20, 80)/100, 0, math.random(20, 80)/100, 0)
													vfxObj.Rotation = math.random(0, 360)
													vfxObj.Size = UDim2.new(0, 0, 0, 0)

													local tIn = TweenService:Create(vfxObj, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
														Size = UDim2.new(0.8, 0, 0.8, 0),
														ImageTransparency = 0
													})
													tIn:Play(); tIn.Completed:Wait()

													local tOut = TweenService:Create(vfxObj, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
														Size = UDim2.new(1, 0, 1, 0),
														ImageTransparency = 1
													})
													tOut:Play(); tOut.Completed:Wait()
												end

												vfxObj:Destroy()
											end)

											if vfxName == "Punch" or vfxName == "Slash" then
												task.wait(0.15)
											else
												task.wait(0.05) 
											end
										end
									end
								end
							end
							task.wait(0.3)
						end
					end)
				end

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
					elseif string.find(line, "damage!") or string.find(line, "bled for") or string.find(line, "Freeze damage") then
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

	elseif action == "CombatUpdateState" then
		currentDeadline = data.Deadline or 0
		ArenaTab.UpdateCombatState(data.State)

		if not isSpectating then 
			combatUI.AbilitiesArea.Visible = true
			ArenaTab.RenderSkills(data.State) 
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
			isSpectating = false
			bettingArea.Visible = false
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

		if pData.Stamina and pData.MaxStamina and pData.StandEnergy and pData.MaxStandEnergy then
			fObj:UpdateResources(pData.Stamina, pData.MaxStamina, pData.StandEnergy, pData.MaxStandEnergy)
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

		if pData.Stamina and pData.MaxStamina and pData.StandEnergy and pData.MaxStandEnergy then
			fObj:UpdateResources(pData.Stamina, pData.MaxStamina, pData.StandEnergy, pData.MaxStandEnergy)
		end

		if not isSpectating then
			if fObj.Frame then
				local stroke = fObj.Frame:FindFirstChildOfClass("UIStroke")
				if not stroke then
					stroke = Instance.new("UIStroke")
					stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					stroke.Parent = fObj.Frame
				end

				if stroke then
					if pData.UserId == selectedTargetId then
						stroke.Color = Color3.fromRGB(50, 150, 255) 
						stroke.Thickness = 2
					else
						stroke.Color = Color3.fromRGB(90, 50, 120) 
						stroke.Thickness = 1
					end
				end

				if not fObj.Frame:GetAttribute("TargetHooked") then
					fObj.Frame:SetAttribute("TargetHooked", true)

					local function hookClick(guiObj)
						guiObj.InputBegan:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
								if pData.HP > 0 and selectedTargetId ~= pData.UserId then
									SFXManager.Play("Click")
									selectedTargetId = pData.UserId

									for _, eData in ipairs(state.EnemyTeam) do
										local eObj = activeFighters[tostring(eData.UserId)]
										if eObj and eObj.Frame then
											local eStroke = eObj.Frame:FindFirstChildOfClass("UIStroke")
											if eStroke then
												if eData.UserId == selectedTargetId then
													eStroke.Color = Color3.fromRGB(50, 150, 255)
													eStroke.Thickness = 2
												else
													eStroke.Color = Color3.fromRGB(90, 50, 120)
													eStroke.Thickness = 1
												end
											end
										end
									end
								end
							end
						end)
					end

					hookClick(fObj.Frame)
					for _, c in ipairs(fObj.Frame:GetDescendants()) do
						if c:IsA("GuiObject") then hookClick(c) end
					end

					fObj.Frame.DescendantAdded:Connect(function(c)
						if c:IsA("GuiObject") then hookClick(c) end
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

return ArenaTab