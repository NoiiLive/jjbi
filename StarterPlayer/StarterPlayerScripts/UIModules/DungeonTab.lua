-- @ScriptType: ModuleScript
local DungeonTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))

local uiTemplates = ReplicatedStorage:WaitForChild("UITemplates")

local menuFrame, combatScroll, combatView
local pHPFill, pHPTxt, pName, pBg, pImmunity, pCImmunity, pStatus
local eHPFill, eHPTxt, eName, eBg, eImmunity, eCImmunity, eStatus
local resourceLabel, waveLabel, logScroll, skillsContainer
local rootFrame, forceTabFocus, cachedTooltipMgr

local dungeonList = {
	{ Id = 1, Name = "Phantom Blood Dungeon", Req = 5 },
	{ Id = 2, Name = "Battle Tendency Dungeon", Req = 6 },
	{ Id = 3, Name = "Stardust Crusaders Dungeon", Req = 7 },
	{ Id = 4, Name = "Diamond is Unbreakable Dungeon", Req = 8 },
	{ Id = 5, Name = "Golden Wind Dungeon", Req = 9 },
	{ Id = 6, Name = "Stone Ocean Dungeon", Req = 10 },
	{ Id = "Endless", Name = "Endless Dungeon", Req = 15 }
}

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

function DungeonTab.Init(parentFrame, tooltipMgr, focusFunc)
	rootFrame = parentFrame; cachedTooltipMgr = tooltipMgr; forceTabFocus = focusFunc

	menuFrame = parentFrame:WaitForChild("MenuFrame")

	local dungeonUIElements = {}
	local rowTemplate = uiTemplates:WaitForChild("DungeonRowTemplate")

	for _, dInfo in ipairs(dungeonList) do
		local row = rowTemplate:Clone()
		row.Parent = menuFrame

		local title = row:WaitForChild("TitleLabel")
		local status = row:WaitForChild("StatusLabel")
		local reward = row:WaitForChild("RewardLabel")
		local playBtn = row:WaitForChild("PlayBtn")

		playBtn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			local pObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
			if pObj and pObj.Value >= dInfo.Req then
				Network:WaitForChild("DungeonAction"):FireServer("StartDungeon", dInfo.Id)
			end
		end)

		dungeonUIElements[dInfo.Id] = {Row = row, Title = title, Status = status, Reward = reward, Btn = playBtn, Info = dInfo}
	end

	task.spawn(function()
		local pObj = player:WaitForChild("leaderstats", 10)
		if pObj then
			local prestige = pObj:WaitForChild("Prestige", 10)
			local function updateLocks()
				local pVal = prestige.Value
				for id, data in pairs(dungeonUIElements) do
					data.Title.Text = data.Info.Name

					if data.Info.Id == "Endless" then
						local hs = player:GetAttribute("EndlessHighScore") or 0
						data.Status.Text = "High Score: <font color='#55FF55'>Floor " .. hs .. "</font>"
						data.Reward.Text = "Milestone Reward: <font color='#FF55FF'>Rokakaka</font> every 10 floors."
					else
						local cleared = player:GetAttribute("DungeonClear_Part" .. data.Info.Id)
						if cleared then
							data.Status.Text = "Status: <font color='#55FF55'>Cleared</font>"
							data.Reward.Text = "Rewards: Massive Item Pool & XP/Yen"
						else
							data.Status.Text = "Status: <font color='#FF5555'>Uncleared</font>"
							data.Reward.Text = "First Time Clear Reward: <font color='#FF55FF'>Rokakaka</font>"
						end
					end

					if pVal >= data.Info.Req then
						data.Btn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
						data.Btn.Text = "PLAY"
						data.Btn.TextColor3 = Color3.new(1,1,1)
					else
						data.Btn.BackgroundColor3 = Color3.fromRGB(35, 25, 40)
						data.Btn.Text = "??"
						data.Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
						data.Status.Text = "Status: <font color='#FF5555'>Requires Prestige " .. data.Info.Req .. "</font>"
					end
				end
			end

			prestige.Changed:Connect(updateLocks)
			player:GetAttributeChangedSignal("EndlessHighScore"):Connect(updateLocks)
			for i = 1, 6 do player:GetAttributeChangedSignal("DungeonClear_Part" .. i):Connect(updateLocks) end
			updateLocks()
		end
	end)

	combatScroll = parentFrame:WaitForChild("CombatScroll")

	combatView = uiTemplates:WaitForChild("CombatViewTemplate"):Clone()
	combatView.LayoutOrder = 1
	combatView.Parent = combatScroll

	local topArea = combatView:WaitForChild("TopArea")

	waveLabel = topArea:WaitForChild("WaveLabel")
	waveLabel.Visible = true 
	resourceLabel = topArea:WaitForChild("ResourceLabel")

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

	logScroll = combatView:WaitForChild("LogScroll")
	skillsContainer = combatView:WaitForChild("SkillsContainer")
end

function DungeonTab.RenderSkills(battleData)
	if not battleData then return end
	for _, child in pairs(skillsContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end

	local myStand, myStyle = battleData.Player.Stand or "None", battleData.Player.Style or "None"
	local valid = {}
	for n, s in pairs(SkillData.Skills) do
		if s.Requirement == "None" or s.Requirement == myStand or s.Requirement == myStyle or (s.Requirement == "AnyStand" and myStand ~= "None") then
			if battleData.IsEndless and s.Effect == "Flee" then continue end
			table.insert(valid, {Name = n, Data = s}) 
		end
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
						Network:WaitForChild("DungeonAction"):FireServer("Attack", sk.Name) 
					end
				end)
			else
				btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					cachedTooltipMgr.Hide()
					Network:WaitForChild("DungeonAction"):FireServer("Attack", sk.Name) 
				end)
			end
		end
	end
end

function DungeonTab.UpdateDungeon(status, data)
	if status == "Start" then
		if forceTabFocus then forceTabFocus() end 
		for _, c in pairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
		menuFrame.Visible = false; combatScroll.Visible = true
		skillsContainer.Visible = true; resourceLabel.Visible = true

		AddLog(data.LogMsg or "")
		waveLabel.Text = data.WaveStr or "Floor 1"
		DungeonTab.RenderSkills(data.Battle)

	elseif status == "TurnStrike" then
		skillsContainer.Visible = false; AddLog(data.LogMsg)

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
				local orig = UDim2.new(0.025, 0, 0, 0) 
				for i = 1, 6 do combatScroll.Position = orig + UDim2.new(0, math.random(-p, p), 0, math.random(-p, p)); task.wait(0.04) end
				combatScroll.Position = orig
			end)
		end

	elseif status == "WaveComplete" then
		skillsContainer.Visible = true
		waveLabel.Text = data.WaveStr or "Floor ?"
		AddLog("<font color='#55FF55'>Enemy Defeated!</font>\n" .. (data.LogMsg or ""))
		DungeonTab.RenderSkills(data.Battle)

	elseif status == "Update" then
		skillsContainer.Visible = true; DungeonTab.RenderSkills(data.Battle)

	elseif status == "Victory" or status == "Defeat" or status == "Fled" then
		skillsContainer.Visible = false; resourceLabel.Visible = false
		pImmunity.Text = ""; eImmunity.Text = ""
		pCImmunity.Text = ""; eCImmunity.Text = ""
		pStatus.Text = ""; eStatus.Text = ""

		if status == "Victory" then SFXManager.Play("CombatVictory") else SFXManager.Play("CombatDefeat") end

		local color = status == "Victory" and "#00FFFF" or (status == "Defeat" and "#FF0055" or "#AAAAAA")
		AddLog("<font color='" .. color .. "'>DUNGEON " .. status:upper() .. "!</font>")

		if status == "Victory" and data.Drops then
			AddLog("<font color='#55FF55'>+" .. (data.Drops.XP or 0) .. " XP, +¥" .. (data.Drops.Yen or 0) .. ".</font>")
			if data.Drops.Items and #data.Drops.Items > 0 then 
				AddLog("<font color='#FFFF55'>Loot Secured: " .. table.concat(data.Drops.Items, ", ") .. "</font>") 
			end
		elseif status == "Fled" then
			AddLog("<font color='#AAAAAA'>You fled the dungeon, forfeiting all progress.</font>")
		end

		task.delay(4, function() 
			combatScroll.Visible = false
			menuFrame.Visible = true
		end)
	end

	if data and data.Battle then
		pHPFill.Size = UDim2.new(math.clamp(data.Battle.Player.HP / data.Battle.Player.MaxHP, 0, 1), 0, 1, 0)
		pHPTxt.Text = math.floor(data.Battle.Player.HP) .. "/" .. math.floor(data.Battle.Player.MaxHP)
		pStatus.Text = BuildStatusString(data.Battle.Player.Statuses)

		eName.Text = data.Battle.Enemy.Name
		eHPFill.Size = UDim2.new(math.clamp(data.Battle.Enemy.HP / data.Battle.Enemy.MaxHP, 0, 1), 0, 1, 0)
		eHPTxt.Text = math.floor(data.Battle.Enemy.HP) .. "/" .. math.floor(data.Battle.Enemy.MaxHP)
		eStatus.Text = BuildStatusString(data.Battle.Enemy.Statuses)

		resourceLabel.Text = "STAMINA: " .. math.floor(data.Battle.Player.Stamina) .. " | ENERGY: " .. math.floor(data.Battle.Player.StandEnergy)

		if (data.Battle.Player.StunImmunity or 0) > 0 then
			pImmunity.Text = "Stun Immune: " .. data.Battle.Player.StunImmunity .. " Turns"
		else pImmunity.Text = "" end

		if (data.Battle.Player.ConfusionImmunity or 0) > 0 then
			pCImmunity.Text = "Confuse Immune: " .. data.Battle.Player.ConfusionImmunity .. " Turns"
		else pCImmunity.Text = "" end

		if (data.Battle.Enemy.StunImmunity or 0) > 0 then
			eImmunity.Text = "Stun Immune: " .. data.Battle.Enemy.StunImmunity .. " Turns"
		else eImmunity.Text = "" end

		if (data.Battle.Enemy.ConfusionImmunity or 0) > 0 then
			eCImmunity.Text = "Confuse Immune: " .. data.Battle.Enemy.ConfusionImmunity .. " Turns"
		else eCImmunity.Text = "" end
	end
end

return DungeonTab