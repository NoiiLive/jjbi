-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local SBREventTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local isStudio = RunService:IsStudio()
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))
local CombatTemplate = require(UIModules:WaitForChild("CombatTemplate"))
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

local function FormatTime(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

local function SetupDropdown(dropBtn, listFrame, itemList, onSelect)
	dropBtn.Text = "Select"

	for _, child in pairs(listFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	table.sort(itemList)
	for _, opt in ipairs(itemList) do
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
			dropBtn.Text = opt
			listFrame.Visible = false
			onSelect(opt)
		end)
	end

	listFrame.CanvasSize = UDim2.new(0, 0, 0, #itemList * 30)

	dropBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		listFrame.Visible = not listFrame.Visible
	end)
end

function SBREventTab.Init(parentFrame, tooltipMgr, focusFunc)
	mainContainer = parentFrame
	cachedTooltipMgr = tooltipMgr
	forceTabFocus = focusFunc

	local templates = ReplicatedStorage:WaitForChild("JJBITemplates")

	lobbyContainer = mainContainer:WaitForChild("LobbyContainer")
	local stableCard = lobbyContainer:WaitForChild("StableCard")
	local queueCard = lobbyContainer:WaitForChild("QueueCard")

	horseNameLbl = stableCard:WaitForChild("HorseNameLbl")
	traitLbl = stableCard:WaitForChild("TraitLbl")

	local statRow = stableCard:WaitForChild("StatRow")
	speedValLbl = statRow:WaitForChild("SpeedValLbl")
	upgSpeedBtn = statRow:WaitForChild("UpgSpeedBtn")

	local statRow2 = stableCard:WaitForChild("StatRow2")
	endValLbl = statRow2:WaitForChild("EndValLbl")
	upgEndBtn = statRow2:WaitForChild("UpgEndBtn")

	upgTimerLbl = stableCard:WaitForChild("UpgTimerLbl")

	local rerollRow = stableCard:WaitForChild("RerollRow")
	rerollYenBtn = rerollRow:WaitForChild("RerollYenBtn")
	rerollRobuxBtn = rerollRow:WaitForChild("RerollRobuxBtn")

	local nameRow = stableCard:WaitForChild("NameRow")
	local n1Drop = nameRow:WaitForChild("N1Drop")
	local n2Drop = nameRow:WaitForChild("N2Drop")
	local setNameBtn = nameRow:WaitForChild("SetNameBtn")

	SetupDropdown(n1Drop, n1Drop:WaitForChild("ListScroll"), Names1, function(val) targetName1 = val end)
	SetupDropdown(n2Drop, n2Drop:WaitForChild("ListScroll"), Names2, function(val) targetName2 = val end)

	timerLbl = queueCard:WaitForChild("TimerLbl")
	queueCountLbl = queueCard:WaitForChild("QueueCountLbl")
	queueBtn = queueCard:WaitForChild("QueueBtn")
	forceStartBtn = queueCard:WaitForChild("ForceStartBtn")

	forceStartBtn.Visible = isStudio

	traitLbl.MouseEnter:Connect(function()
		local t = player:GetAttribute("HorseTrait") or "None"
		local desc = GameData.HorseTraits[t] or "No description available."
		local color = (t == "None") and "#AAAAAA" or "#FFD700"
		cachedTooltipMgr.Show("<b><font color='"..color.."'>" .. t .. "</font></b>\n____________________\n\n" .. desc)
	end)
	traitLbl.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

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
	local isTogglingQueue = false

	queueBtn.MouseButton1Click:Connect(function()
		if isTogglingQueue then return end
		isTogglingQueue = true 

		SFXManager.Play("Click")
		if queueBtn.Text == "Force Join (Studio)" then
			Network.SBRAction:FireServer("ToggleQueue")
			task.delay(1.5, function() isTogglingQueue = false end)
			return
		end

		inQueue = not inQueue
		queueBtn.Text = inQueue and "Leave Queue" or "Join Event Queue"
		queueBtn.BackgroundColor3 = inQueue and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(50, 150, 50)
		Network.SBRAction:FireServer("ToggleQueue")

		task.delay(1.5, function() isTogglingQueue = false end) 
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
		local isUpgrading = upgEnd > math.floor(workspace:GetServerTimeNow())

		if spd >= 100 or isUpgrading then upgSpeedBtn.Visible = false else upgSpeedBtn.Visible = true end
		if endur >= 100 or isUpgrading then upgEndBtn.Visible = false else upgEndBtn.Visible = true end
	end

	player:GetAttributeChangedSignal("HorseName"):Connect(UpdateStableUI)
	player:GetAttributeChangedSignal("HorseSpeed"):Connect(UpdateStableUI)
	player:GetAttributeChangedSignal("HorseEndurance"):Connect(UpdateStableUI)
	player:GetAttributeChangedSignal("HorseTrait"):Connect(UpdateStableUI)
	UpdateStableUI()

	raceContainer = mainContainer:WaitForChild("RaceContainer")
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

	sbrTopArea = templates:WaitForChild("SBRTopAreaTemplate"):Clone()
	sbrTopArea.Parent = combatUI.ContentContainer

	rRegionLbl = sbrTopArea:WaitForChild("RegionLbl")
	rDistLbl = sbrTopArea:WaitForChild("DistLbl")

	turnTimerLabel = templates:WaitForChild("SBRTurnTimerTemplate"):Clone()
	turnTimerLabel.Parent = combatUI.MainFrame

	combatResourceLabel = templates:WaitForChild("SBRResourceLabelTemplate"):Clone()
	combatResourceLabel.Parent = combatUI.ContentContainer

	sbrPathArea = templates:WaitForChild("SBRPathAreaTemplate"):Clone()
	sbrPathArea.Parent = combatUI.ContentContainer

	local sBg = sbrPathArea:WaitForChild("StamBg")
	stamFill = sBg:WaitForChild("StamFill")
	stamTxt = sBg:WaitForChild("StamTxt")

	pathBtns = sbrPathArea:WaitForChild("PathBtns")
	safeBtn = pathBtns:WaitForChild("SafeBtn")
	restBtn = pathBtns:WaitForChild("RestBtn")
	riskyBtn = pathBtns:WaitForChild("RiskyBtn")

	travelStatusLbl = sbrPathArea:WaitForChild("TravelStatusLbl")

	waitingLabel = templates:WaitForChild("SBRWaitingLabelTemplate"):Clone()
	waitingLabel.Parent = combatUI.ContentContainer

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
		if math.floor(workspace:GetServerTimeNow()) - lastPathTime < 1 then return end
		lastPathTime = math.floor(workspace:GetServerTimeNow())

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
				local left = upgEnd - math.floor(workspace:GetServerTimeNow())
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
				local remain = math.max(0, currentDeadline - math.floor(workspace:GetServerTimeNow()))
				turnTimerLabel.Text = "Time Remaining: " .. remain .. "s"
				if remain <= 5 then turnTimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				else turnTimerLabel.TextColor3 = Color3.fromRGB(255, 215, 0) end
			end
		end
	end)

	local function UpdateCombatState(state)
		local processed = {}

		local id = tostring(state.P1.UserId or state.P1.Name)
		processed[id] = true
		local fObj = activeFighters[id]

		if not fObj then
			fObj = combatUI:AddFighter(true, id, state.P1.Name, id, state.P1.HP, state.P1.MaxHP)
			activeFighters[id] = fObj
		else
			fObj:UpdateHealth(state.P1.HP, state.P1.MaxHP)
		end

		if state.P1.Stamina and state.P1.MaxStamina and state.P1.StandEnergy and state.P1.MaxStandEnergy then
			fObj:UpdateResources(state.P1.Stamina, state.P1.MaxStamina, state.P1.StandEnergy, state.P1.MaxStandEnergy)
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

		if state.P2.Stamina and state.P2.MaxStamina and state.P2.StandEnergy and state.P2.MaxStandEnergy then
			bObj:UpdateResources(state.P2.Stamina, state.P2.MaxStamina, state.P2.StandEnergy, state.P2.MaxStandEnergy)
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
			inQueue = false
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

				local skillInfo = SkillData.Skills[data.SkillName]
				local eff = skillInfo and skillInfo.Effect or ""
				local isUtility = (eff == "Block" or eff == "Counter" or eff == "Heal" or eff == "Rest" or eff == "CleanseRest" or string.match(eff, "Buff_") or string.match(eff, "Debuff_") or eff == "TimeRewind" or eff == "TimeReset" or eff == "ReturnToZero")

				if (data.DidHit or isUtility) and data.Defender and data.SkillName then
					task.spawn(function()
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