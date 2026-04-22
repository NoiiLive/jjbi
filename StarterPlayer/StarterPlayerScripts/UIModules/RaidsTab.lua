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
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))

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

local currentLog = ""
local templates
local eventConnected = false

local raidBosses = {
	{ Id = "Raid_Part1", Name = "Vampire King", Req = 1, Desc = "A deadly raid against the progenitor of the stone mask." },
	{ Id = "Raid_Part2", Name = "Ultimate Lifeform", Req = 2, Desc = "Face the pinnacle of evolution. Bring Hamon!" },
	{ Id = "Raid_Part3", Name = "Time Stop Vampire", Req = 3, Desc = "He has conquered time itself. Good luck." },
	{ Id = "Raid_Part4", Name = "Serial Killer", Req = 4, Desc = "An elusive murderer with explosive tendencies." },
	{ Id = "Raid_Part5", Name = "Mafia Boss", Req = 5, Desc = "The boss of Passione. Time will erase." },
	{ Id = "Raid_Part6", Name = "Gravity Priest", Req = 6, Desc = "Gravity is shifting. The universe accelerates." },
	{ Id = "Raid_Part7", Name = "23rd President", Req = 7, Desc = "He has taken the first napkin. Beware his dimensional shifts." },
	{ Id = "Raid_Part8", Name = "The Head Doctor", Req = 8, Desc = "Something is off, calamity follows the doctor as you start to pursue." }
}

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

local function AppendLog(text, overwrite)
	if overwrite then
		currentLog = text
	else
		currentLog = currentLog .. "\n" .. text
	end
	if combatUI then combatUI:Log(currentLog) end
end

function RaidsTab.Init(parentFrame, tooltipMgr, focusFunc)
	cachedTooltipMgr = tooltipMgr
	forceTabFocus = focusFunc
	templates = ReplicatedStorage:WaitForChild("JJBITemplates")

	menuFrame = parentFrame:WaitForChild("MenuFrame")
	matchmakingFrame = parentFrame:WaitForChild("MatchmakingFrame")
	combatCard = parentFrame:WaitForChild("CombatCard")

	local uiElements = {}
	for i, rInfo in ipairs(raidBosses) do
		local row = templates:WaitForChild("RaidRowTemplate"):Clone()
		row.Name = "RaidRow_" .. rInfo.Id
		row.LayoutOrder = i
		row.Parent = menuFrame

		row:WaitForChild("TitleLabel").Text = "RAID: " .. rInfo.Name
		row:WaitForChild("DescLabel").Text = rInfo.Desc

		local status = row:WaitForChild("StatusLabel")
		local playBtn = row:WaitForChild("PlayBtn")
		local pStroke = playBtn:WaitForChild("UIStroke")

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

	-- Dynamically adjust the menuFrame CanvasSize so it scrolls correctly on all screen sizes
	task.delay(0.1, function()
		if menuFrame:IsA("ScrollingFrame") then
			local layout = menuFrame:FindFirstChildOfClass("UIListLayout") or menuFrame:FindFirstChildOfClass("UIGridLayout")
			if layout then
				menuFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 25)
				layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					menuFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 25)
				end)
			end
		end
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

	local topBar = matchmakingFrame:WaitForChild("TopBar")
	raidTitleLabel = topBar:WaitForChild("RaidTitleLabel")

	local backBtn = topBar:WaitForChild("BackBtn")
	backBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		matchmakingFrame.Visible = false
		menuFrame.Visible = true
		selectedRaidId = nil
		RaidAction:FireServer("CancelLobby")
	end)

	hostCard = matchmakingFrame:WaitForChild("HostCard")
	viewDefault = hostCard:WaitForChild("ViewDefault")
	viewSetup = hostCard:WaitForChild("ViewSetup")
	viewHosting = hostCard:WaitForChild("ViewHosting")

	local openSetupBtn = viewDefault:WaitForChild("OpenSetupBtn")
	local confirmSetupBtn = viewSetup:WaitForChild("ConfirmSetupBtn")
	local cancelSetupBtn = viewSetup:WaitForChild("CancelSetupBtn")
	local friendsToggleBtn = viewSetup:WaitForChild("FriendsToggleBtn")

	hostingLbl = viewHosting:WaitForChild("HostingLbl")
	local hostingBtns = viewHosting:WaitForChild("BtnsContainer")
	startRaidBtn = hostingBtns:WaitForChild("StartRaidBtn")
	cancelLobbyBtn = hostingBtns:WaitForChild("CancelLobbyBtn")

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

	lobbyCard = matchmakingFrame:WaitForChild("LobbyCard")
	lobbyContainer = lobbyCard:WaitForChild("LobbyContainer")

	combatUI = CombatTemplate.Create(combatCard, tooltipMgr)

	turnTimerLabel = templates:WaitForChild("RaidTurnTimerTemplate"):Clone()
	turnTimerLabel.Parent = combatUI.MainFrame

	resourceLabel = templates:WaitForChild("RaidResourceLabelTemplate"):Clone()
	resourceLabel.Parent = combatUI.ContentContainer

	waitingLabel = templates:WaitForChild("RaidWaitingLabelTemplate"):Clone()
	waitingLabel.Parent = combatUI.ContentContainer

	task.spawn(function()
		while task.wait(0.2) do
			if combatCard.Visible and currentDeadline > 0 then
				local remain = math.max(0, currentDeadline - math.floor(workspace:GetServerTimeNow()))
				turnTimerLabel.Text = "Time Remaining: " .. remain .. "s"
				if remain <= 5 then turnTimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				else turnTimerLabel.TextColor3 = Color3.fromRGB(255, 215, 0) end
			end
		end
	end)

	if not eventConnected then
		eventConnected = true
		RaidUpdate.OnClientEvent:Connect(function(action, data)
			RaidsTab.HandleUpdate(action, data)
		end)
	end
end

function RaidsTab.UpdateCombatState(state)
	local processed = {}

	for _, pData in ipairs(state.Party) do
		local id = tostring(pData.UserId)
		processed[id] = true
		local fObj = activeFighters[id]

		if not fObj then
			fObj = combatUI:AddFighter(true, id, pData.Name, id, pData.HP, pData.MaxHP)
			activeFighters[id] = fObj
		else
			fObj:UpdateHealth(pData.HP, pData.MaxHP)
			fObj:UpdateIcon(id, pData.Name)
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

		for eff, _ in pairs(StatusIcons) do
			if not currentStatuses[eff] then
				fObj:RemoveStatus(eff)
			end
		end

		local hasStunImmunity = (pData.StunImmunity and pData.StunImmunity > 0)
		if hasStunImmunity then
			fObj:SetCooldown("StunImmunity", "STN", tostring(pData.StunImmunity), "Immune to Stun effects.", true)
		else
			fObj:RemoveCooldown("StunImmunity")
		end

		local hasConfImmunity = (pData.ConfusionImmunity and pData.ConfusionImmunity > 0)
		if hasConfImmunity then
			fObj:SetCooldown("ConfImmunity", "CNF", tostring(pData.ConfusionImmunity), "Immune to Confusion effects.", true)
		else
			fObj:RemoveCooldown("ConfImmunity")
		end

		if pData.UserId == state.MyId then
			resourceLabel.Text = "STAMINA: " .. math.floor(pData.Stamina) .. " | ENERGY: " .. math.floor(pData.StandEnergy)
		end
	end

	local bId = "Boss_" .. (state.Boss.Name or "Unknown")
	processed[bId] = true
	local bObj = activeFighters[bId]

	if not bObj then
		bObj = combatUI:AddFighter(false, bId, state.Boss.Name, state.Boss.Icon, state.Boss.HP, state.Boss.MaxHP)
		activeFighters[bId] = bObj
	else
		bObj:UpdateHealth(state.Boss.HP, state.Boss.MaxHP)
		bObj:UpdateIcon(state.Boss.Icon, state.Boss.Name)
	end

	if state.Boss.Stamina and state.Boss.MaxStamina and state.Boss.StandEnergy and state.Boss.MaxStandEnergy then
		bObj:UpdateResources(state.Boss.Stamina, state.Boss.MaxStamina, state.Boss.StandEnergy, state.Boss.MaxStandEnergy)
	end

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

	local hasBossStunImmunity = (state.Boss.StunImmunity and state.Boss.StunImmunity > 0)
	if hasBossStunImmunity then
		bObj:SetCooldown("StunImmunity", "STN", tostring(state.Boss.StunImmunity), "Immune to Stun effects.", true)
	else
		bObj:RemoveCooldown("StunImmunity")
	end

	local hasBossConfImmunity = (state.Boss.ConfusionImmunity and state.Boss.ConfusionImmunity > 0)
	if hasBossConfImmunity then
		bObj:SetCooldown("ConfImmunity", "CNF", tostring(state.Boss.ConfusionImmunity), "Immune to Confusion effects.", true)
	else
		bObj:RemoveCooldown("ConfImmunity")
	end

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
				cancelLobbyBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
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
			empty.ZIndex = 22
			Instance.new("UITextSizeConstraint", empty).MaxTextSize = 16

			lobbyContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
			return
		end

		for i, lobby in ipairs(lobbies) do
			local row = templates:WaitForChild("RaidLobbyRowTemplate"):Clone()
			row.Name = "LobbyRow_" .. i
			row.LayoutOrder = i
			row.Parent = lobbyContainer

			local infoText = "<b>" .. lobby.HostName .. "'s Party</b>"
			if lobby.FriendsOnly then infoText = infoText .. " <font color='#55FF55'>[Friends]</font>" end
			infoText = infoText .. "\n<font color='#AAAAAA' size='12'>Members: " .. table.concat(lobby.Members, ", ") .. "</font>"

			row:WaitForChild("InfoLabel").Text = infoText
			row:WaitForChild("CountLabel").Text = (lobby.PlayerCount or 1) .. "/4"

			local joinBtn = row:WaitForChild("JoinBtn")
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

		task.delay(0.05, function()
			local l = lobbyContainer:FindFirstChildOfClass("UIListLayout")
			if l then lobbyContainer.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 10) end
		end)

	elseif action == "MatchStart" then
		if forceTabFocus then forceTabFocus() end 
		menuFrame.Visible = false
		matchmakingFrame.Visible = false
		combatCard.Visible = true

		currentDeadline = data.Deadline or 0
		currentLog = "" 

		for fKey, f in pairs(activeFighters) do
			if f.Frame then f.Frame:Destroy() end
		end
		activeFighters = {}

		if combatUI.ChatScroll and combatUI.ChatScroll.Parent then
			combatUI.ChatScroll.Parent.Size = UDim2.new(1, 0, 0.13, 0)
		end

		combatUI.ChatText.Text = ""
		AppendLog("<font color='#FFD700'>" .. data.LogMsg .. "</font>", true)

		RaidsTab.UpdateCombatState(data.State)
		RaidsTab.RenderSkills(data.State)

	elseif action == "TurnResult" then
		currentDeadline = data.Deadline or 0

		-- HIDE THE ABILITY BAR IMMEDIATELY UPON RECEIVING A COMBAT TURN
		combatUI.AbilitiesArea.Visible = false
		if data.LogMsg ~= "" then
			waitingLabel.Text = "Combat is playing out..."
			waitingLabel.Visible = true
		end

		if data.LogMsg and data.LogMsg ~= "" then
			local lines = string.split(data.LogMsg, "\n")
			for _, line in ipairs(lines) do 
				if line ~= "" then 
					AppendLog(line, false)
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

			task.spawn(function()
				local skillInfo = SkillData.Skills[data.SkillName]
				local eff = skillInfo and skillInfo.Effect or ""
				local isUtility = (eff == "Block" or eff == "Counter" or eff == "Heal" or eff == "Rest" or eff == "CleanseRest" or string.match(eff, "Buff_") or string.match(eff, "Debuff_") or eff == "TimeRewind" or eff == "TimeReset" or eff == "ReturnToZero")

				if (data.DidHit or isUtility) and data.Defender and data.SkillName then
					local targetFighter = activeFighters[data.Defender]
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
			end)
		end

		RaidsTab.UpdateCombatState(data.State)

		if data.LogMsg == "" then
			waitingLabel.Visible = false
			RaidsTab.RenderSkills(data.State)
		end

	elseif action == "MatchOver" then
		currentDeadline = 0
		turnTimerLabel.Text = "Raid Over!"
		combatUI:ClearAbilities()
		AppendLog(data.LogMsg, false)

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