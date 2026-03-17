-- @ScriptType: ModuleScript
local WorldBossTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))

local uiTemplates = ReplicatedStorage:WaitForChild("UITemplates")

local combatView
local pHPFill, pHPTxt, pName, pBg, pImmunity, pCImmunity, pStatus
local eHPFill, eHPTxt, eName, eBg, eImmunity, eCImmunity, eStatus
local resourceLabel, turnLabel, logScroll, skillsContainer, topArea
local infoCard, timerLabel, engageBtn
local rootFrame, forceTabFocus
local cachedTooltipMgr = nil

local inBattle = false
local BOSS_ACTIVE_MINUTES = 30

local function FormatTime(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
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
	local logTemplate = uiTemplates:WaitForChild("LogLineTemplate")
	local line = logTemplate:Clone()
	line.Text = text
	line.Parent = logScroll
	task.defer(function() logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y) end)
end

function WorldBossTab.Init(parentFrame, tooltipMgr, focusFunc)
	rootFrame = parentFrame; cachedTooltipMgr = tooltipMgr; forceTabFocus = focusFunc

	if not WorldBossTab.Listener then
		local wbUpdate = Network:WaitForChild("WorldBossUpdate")
		WorldBossTab.Listener = wbUpdate.OnClientEvent:Connect(function(action, data)
			WorldBossTab.UpdateWorldBoss(action, data)
		end)
	end

	local mainScroll = parentFrame:WaitForChild("MainScroll")

	infoCard = mainScroll:WaitForChild("InfoCard")
	timerLabel = infoCard:WaitForChild("TimerLabel")
	engageBtn = infoCard:WaitForChild("EngageBtn")

	combatView = uiTemplates:WaitForChild("CombatViewTemplate"):Clone()
	combatView.LayoutOrder = 2
	combatView.Parent = mainScroll

	topArea = combatView:WaitForChild("TopArea")
	topArea.Visible = false

	local pWrap = topArea:WaitForChild("PlayerHPWrapper")
	pName = pWrap:WaitForChild("NameLabel")
	pBg = pWrap:WaitForChild("Bg")
	pHPFill = pBg:WaitForChild("Fill")
	pHPTxt = pBg:WaitForChild("HpText")
	pStatus = pWrap:WaitForChild("StatusLbl")
	pImmunity = pWrap:WaitForChild("Immunity")
	pCImmunity = pWrap:WaitForChild("CImmunity")

	local eWrap = topArea:WaitForChild("EnemyHPWrapper")
	eName = eWrap:WaitForChild("NameLabel")
	eBg = eWrap:WaitForChild("Bg")
	eHPFill = eBg:WaitForChild("Fill")
	eHPTxt = eBg:WaitForChild("HpText")
	eStatus = eWrap:WaitForChild("StatusLbl")
	eImmunity = eWrap:WaitForChild("Immunity")
	eCImmunity = eWrap:WaitForChild("CImmunity")

	resourceLabel = topArea:WaitForChild("ResourceLabel")
	turnLabel = topArea:WaitForChild("TurnLabel")
	turnLabel.Visible = true 

	logScroll = combatView:WaitForChild("LogScroll")
	logScroll.Visible = false 

	skillsContainer = combatView:WaitForChild("SkillsContainer")

	engageBtn.MouseButton1Click:Connect(function()
		if engageBtn.Text == "ENGAGE BOSS" then
			SFXManager.Play("Click")
			Network.WorldBossAction:FireServer("Engage")
		end
	end)

	task.delay(0.5, function()
		Network.WorldBossAction:FireServer("RequestSync")
	end)

	task.spawn(function()
		local RunService = game:GetService("RunService")
		while task.wait(1) do
			if inBattle then continue end

			local utc = os.date("!*t")
			local mins = utc.min
			local secs = utc.sec
			local currentHour = utc.hour
			local lastFought = player:GetAttribute("LastWorldBossHour")
			local isStudio = RunService:IsStudio()

			local endTime = ReplicatedStorage:GetAttribute("WorldBossEndTime") or 0
			local timeRemaining = endTime - os.time()

			if lastFought == currentHour and not isStudio then
				local secondsLeft = (60 * 60) - ((mins * 60) + secs)
				timerLabel.Text = "NEXT IN: " .. FormatTime(secondsLeft)
				timerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				engageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				engageBtn.Text = "ALREADY FOUGHT"
			elseif timeRemaining > 0 then
				timerLabel.Text = "DESPAWNS IN: " .. FormatTime(math.floor(timeRemaining))
				timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
				engageBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
				engageBtn.Text = "ENGAGE BOSS"
			else
				local secondsLeft = (60 * 60) - ((mins * 60) + secs)
				timerLabel.Text = "SPAWNS IN: " .. FormatTime(secondsLeft)
				timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				engageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
				engageBtn.Text = "WAITING..."
			end
		end
	end)
end

function WorldBossTab.RenderSkills(battleData)
	if not battleData then return end
	for _, child in pairs(skillsContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

	local myStand, myStyle = battleData.Player.Stand or "None", battleData.Player.Style or "None"
	local valid = {}
	for n, s in pairs(SkillData.Skills) do
		if s.Requirement == "None" or s.Requirement == myStand or s.Requirement == myStyle or (s.Requirement == "AnyStand" and myStand ~= "None") then table.insert(valid, {Name = n, Data = s}) end
	end
	table.sort(valid, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)

	local skillTemplate = uiTemplates:WaitForChild("SkillButtonTemplate")

	for _, sk in ipairs(valid) do
		local btn = skillTemplate:Clone()
		btn.Text = sk.Name
		btn.Parent = skillsContainer

		local c = sk.Data.Type == "Stand" and Color3.fromRGB(120, 20, 160) or (sk.Data.Type == "Style" and Color3.fromRGB(180, 80, 20) or Color3.fromRGB(60, 60, 80))
		btn.BackgroundColor3 = c

		btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
		btn.MouseLeave:Connect(cachedTooltipMgr.Hide)

		local currentCooldown = battleData.Player.Cooldowns and battleData.Player.Cooldowns[sk.Name] or 0

		if battleData.Player.Stamina < (sk.Data.StaminaCost or 0) or battleData.Player.StandEnergy < (sk.Data.EnergyCost or 0) or currentCooldown > 0 then
			btn.BackgroundColor3 = Color3.fromRGB(35, 25, 45); btn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
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
						Network.WorldBossAction:FireServer("Attack", {SkillName = sk.Name}) 
					end
				end)
			else
				btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					cachedTooltipMgr.Hide()
					Network.WorldBossAction:FireServer("Attack", {SkillName = sk.Name}) 
				end)
			end
		end
	end
end

function WorldBossTab.UpdateWorldBoss(status, data)
	if status == "SyncBoss" then
		eName.Text = data and string.upper(data) or "UNKNOWN THREAT"
		return
	end

	if status == "Start" then
		inBattle = true
		if forceTabFocus then forceTabFocus() end 
		for _, c in pairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end

		infoCard.Visible = false
		topArea.Visible = true
		logScroll.Visible = true
		skillsContainer.Visible = true
		resourceLabel.Visible = true

		AddLog(data.LogMsg or "")
		WorldBossTab.RenderSkills(data.Battle)

	elseif status == "TurnStrike" then
		skillsContainer.Visible = false; AddLog(data.LogMsg)

		if string.find(data.LogMsg, "dodged!") then 
			SFXManager.Play("CombatDodge")
		elseif string.find(data.LogMsg, "Blocked") then 
			SFXManager.Play("CombatBlock")
		elseif data.DidHit then 
			SFXManager.Play("CombatHit")
		else 
			SFXManager.Play("CombatUtility") 
		end

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
				for i = 1, 6 do rootFrame:FindFirstChildOfClass("ScrollingFrame").Position = orig + UDim2.new(0, math.random(-p, p), 0, math.random(-p, p)); task.wait(0.04) end
				rootFrame:FindFirstChildOfClass("ScrollingFrame").Position = orig
			end)
		end

	elseif status == "Update" then
		skillsContainer.Visible = true
		WorldBossTab.RenderSkills(data.Battle)

	elseif status == "Victory" or status == "Defeat" or status == "Fled" then
		skillsContainer.Visible = false; resourceLabel.Visible = false
		pImmunity.Text = ""; eImmunity.Text = ""
		pCImmunity.Text = ""; eCImmunity.Text = ""
		pStatus.Text = ""; eStatus.Text = ""

		if status == "Victory" then SFXManager.Play("CombatVictory") else SFXManager.Play("CombatDefeat") end
		AddLog("<font color='#00FFFF'>COMBAT FINISHED!</font>")
		if data.CustomLog then AddLog(data.CustomLog) end
		if data.Drops and data.Drops.Items and #data.Drops.Items > 0 then AddLog("<font color='#FFFF55'>Rewards: " .. table.concat(data.Drops.Items, ", ") .. "</font>") end

		task.delay(4, function()
			inBattle = false
			topArea.Visible = false
			logScroll.Visible = false
			infoCard.Visible = true
		end)
	end

	if data and data.Battle then
		local battle = data.Battle

		pHPFill.Size = UDim2.new(math.clamp(battle.Player.HP / battle.Player.MaxHP, 0, 1), 0, 1, 0)
		pHPTxt.Text = math.floor(battle.Player.HP) .. "/" .. math.floor(battle.Player.MaxHP)
		pStatus.Text = BuildStatusString(battle.Player.Statuses)

		eName.Text = battle.Enemy.Name
		eHPFill.Size = UDim2.new(math.clamp(battle.Enemy.HP / battle.Enemy.MaxHP, 0, 1), 0, 1, 0)
		eHPTxt.Text = math.floor(battle.Enemy.HP) .. "/" .. math.floor(battle.Enemy.MaxHP)
		eStatus.Text = BuildStatusString(battle.Enemy.Statuses)

		resourceLabel.Text = "STAMINA: " .. math.floor(battle.Player.Stamina) .. " | ENERGY: " .. math.floor(battle.Player.StandEnergy)

		local turnsLeft = 11 - (battle.TurnCounter or 1)
		turnLabel.Text = "Turns Remaining: " .. math.max(0, turnsLeft) .. "/10"

		if (battle.Player.StunImmunity or 0) > 0 then
			pImmunity.Text = "Stun Immune: " .. battle.Player.StunImmunity .. " Turns"
		else pImmunity.Text = "" end

		if (battle.Player.ConfusionImmunity or 0) > 0 then
			pCImmunity.Text = "Confuse Immune: " .. battle.Player.ConfusionImmunity .. " Turns"
		else pCImmunity.Text = "" end

		if (battle.Enemy.StunImmunity or 0) > 0 then
			eImmunity.Text = "Stun Immune: " .. battle.Enemy.StunImmunity .. " Turns"
		else eImmunity.Text = "" end

		if (battle.Enemy.ConfusionImmunity or 0) > 0 then
			eCImmunity.Text = "Confuse Immune: " .. battle.Enemy.ConfusionImmunity .. " Turns"
		else eCImmunity.Text = "" end
	end
end

return WorldBossTab