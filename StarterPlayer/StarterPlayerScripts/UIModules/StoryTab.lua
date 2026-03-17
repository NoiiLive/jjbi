-- @ScriptType: ModuleScript
local StoryTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))

local uiTemplates = ReplicatedStorage:WaitForChild("UITemplates")

local combatView
local pHPFill, pHPTxt, pName, pBg, pImmunity, pCImmunity, pStatus
local aHPFill, aHPTxt, aName, aBg, aImmunity, aCImmunity, aStatus
local eHPFill, eHPTxt, eName, eBg, eImmunity, eCImmunity, eStatus
local resourceLabel, logScroll, skillsContainer, buttonContainer
local randomEncounterBtn, storyEncounterBtn, prestigeBtn, encounterRow
local rootFrame, forceTabFocus
local modifierBubble
local cachedTooltipMgr = nil

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

function StoryTab.Init(parentFrame, tooltipMgr, focusFunc, mainTitleNode)
	rootFrame = parentFrame; cachedTooltipMgr = tooltipMgr; forceTabFocus = focusFunc
	modifierBubble = mainTitleNode:WaitForChild("ModifierBubble")

	modifierBubble.MouseEnter:Connect(function()
		local modStr = player:GetAttribute("UniverseModifier") or "None"
		local tooltipStr = "<b><font color='#FFFFFF'>Active Modifiers</font></b>\n____________________\n\n"

		if modStr == "None" or modStr == "" then
			tooltipStr = tooltipStr .. "<b><font color='#FFFFFF'>None</font></b>\nThe universe is normal.\n"
		else
			local mods = string.split(modStr, ",")
			for _, m in ipairs(mods) do
				local mData = GameData.UniverseModifiers[m]
				if mData then
					tooltipStr = tooltipStr .. "<b><font color='"..mData.Color.."'>"..m.."</font></b>\n" .. mData.Description .. "\n\n"
				end
			end
		end
		cachedTooltipMgr.Show(tooltipStr)
	end)
	modifierBubble.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

	local mainScroll = parentFrame:WaitForChild("MainScroll")

	combatView = uiTemplates:WaitForChild("CombatViewTemplate"):Clone()
	combatView.LayoutOrder = 1
	combatView.Parent = mainScroll

	local topArea = combatView:WaitForChild("TopArea")

	local pWrap = topArea:WaitForChild("PlayerHPWrapper")
	pName = pWrap:WaitForChild("NameLabel")
	pBg = pWrap:WaitForChild("Bg")
	pHPFill = pBg:WaitForChild("Fill")
	pHPTxt = pBg:WaitForChild("HpText")
	pStatus = pWrap:WaitForChild("StatusLbl")
	pImmunity = pWrap:WaitForChild("Immunity")
	pCImmunity = pWrap:WaitForChild("CImmunity")

	local aWrap = topArea:WaitForChild("AllyHPWrapper")
	aName = aWrap:WaitForChild("NameLabel")
	aBg = aWrap:WaitForChild("Bg")
	aHPFill = aBg:WaitForChild("Fill")
	aHPTxt = aBg:WaitForChild("HpText")
	aStatus = aWrap:WaitForChild("StatusLbl")
	aImmunity = aWrap:WaitForChild("Immunity")
	aCImmunity = aWrap:WaitForChild("CImmunity")

	local eWrap = topArea:WaitForChild("EnemyHPWrapper")
	eName = eWrap:WaitForChild("NameLabel")
	eBg = eWrap:WaitForChild("Bg")
	eHPFill = eBg:WaitForChild("Fill")
	eHPTxt = eBg:WaitForChild("HpText")
	eStatus = eWrap:WaitForChild("StatusLbl")
	eImmunity = eWrap:WaitForChild("Immunity")
	eCImmunity = eWrap:WaitForChild("CImmunity")

	resourceLabel = topArea:WaitForChild("ResourceLabel")
	logScroll = combatView:WaitForChild("LogScroll")
	skillsContainer = combatView:WaitForChild("SkillsContainer")

	buttonContainer = mainScroll:WaitForChild("ButtonContainer")
	buttonContainer.LayoutOrder = 2 
	encounterRow = buttonContainer:WaitForChild("EncounterRow")
	randomEncounterBtn = encounterRow:WaitForChild("RandomEncounterBtn")
	storyEncounterBtn = encounterRow:WaitForChild("StoryEncounterBtn")
	prestigeBtn = encounterRow:WaitForChild("PrestigeBtn")

	randomEncounterBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.CombatAction:FireServer("EngageRandom") end)
	storyEncounterBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.CombatAction:FireServer("EngageStory") end)
	prestigeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.PrestigeEvent:FireServer() end)

	local function UpdateStoryUI()
		local currentPart = player:GetAttribute("CurrentPart") or 1
		local currentMission = player:GetAttribute("CurrentMission") or 1

		local prestigeObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
		local prestige = prestigeObj and prestigeObj.Value or 0

		if prestige > 0 and parentFrame.Visible then modifierBubble.Visible = true else modifierBubble.Visible = false end
		encounterRow.Visible = true

		if currentPart >= 8 then
			randomEncounterBtn.Visible = false
			storyEncounterBtn.Visible = false
			prestigeBtn.Visible = true
			prestigeBtn.Size = UDim2.new(1, 0, 1, 0)
			prestigeBtn.Position = UDim2.new(0, 0, 0, 0)
		elseif currentPart == 7 then
			randomEncounterBtn.Visible = false
			storyEncounterBtn.Visible = true
			prestigeBtn.Visible = true
			prestigeBtn.Size = UDim2.new(0.48, 0, 1, 0)
			prestigeBtn.Position = UDim2.new(0, 0, 0, 0)
			storyEncounterBtn.Size = UDim2.new(0.48, 0, 1, 0)
			storyEncounterBtn.Position = UDim2.new(0.52, 0, 0, 0)
		else
			randomEncounterBtn.Visible = true
			storyEncounterBtn.Visible = true
			prestigeBtn.Visible = false
			randomEncounterBtn.Size = UDim2.new(0.48, 0, 1, 0)
			randomEncounterBtn.Position = UDim2.new(0, 0, 0, 0)
			storyEncounterBtn.Size = UDim2.new(0.48, 0, 1, 0)
			storyEncounterBtn.Position = UDim2.new(0.52, 0, 0, 0)
		end

		local partData = EnemyData.Parts[currentPart]
		if partData then
			local missionTable = (prestige > 0 and partData.PrestigeMissions) and partData.PrestigeMissions or partData.Missions
			if currentMission > #missionTable then
				storyEncounterBtn.Text = "Story Encounter"
			elseif missionTable and missionTable[currentMission] then 
				storyEncounterBtn.Text = "Story: " .. missionTable[currentMission].Name 
			else 
				storyEncounterBtn.Text = "Story Encounter" 
			end
		end
	end

	parentFrame:GetPropertyChangedSignal("Visible"):Connect(UpdateStoryUI)
	player:GetAttributeChangedSignal("CurrentPart"):Connect(UpdateStoryUI)
	player:GetAttributeChangedSignal("CurrentMission"):Connect(UpdateStoryUI)
	player:GetAttributeChangedSignal("UniverseModifier"):Connect(UpdateStoryUI)

	task.spawn(function()
		local pObj = player:WaitForChild("leaderstats", 5)
		if pObj then pObj:WaitForChild("Prestige", 5).Changed:Connect(UpdateStoryUI) end
	end)

	UpdateStoryUI()
end

function StoryTab.RenderSkills(battleData)
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
						Network.CombatAction:FireServer("Attack", {SkillName = sk.Name}) 
					end
				end)
			else
				btn.MouseButton1Click:Connect(function() 
					SFXManager.Play("Click")
					cachedTooltipMgr.Hide()
					Network.CombatAction:FireServer("Attack", {SkillName = sk.Name}) 
				end)
			end
		end
	end
end

function StoryTab.UpdateCombat(status, data)
	if status == "Start" then
		if forceTabFocus then forceTabFocus() end 
		for _, c in pairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
		buttonContainer.Visible = false; skillsContainer.Visible = true; resourceLabel.Visible = true
		AddLog(data.LogMsg or "")
		StoryTab.RenderSkills(data.Battle)

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

	elseif status == "WaveComplete" then
		buttonContainer.Visible = false; skillsContainer.Visible = true; StoryTab.RenderSkills(data.Battle)
		AddLog("<font color='#55FF55'>WAVE CLEARED! +" .. (data.XP or 0) .. " XP, +¥" .. (data.Yen or 0) .. ".</font>")
		if data.Items and #data.Items > 0 then AddLog("<font color='#FFFF55'>Dropped: " .. table.concat(data.Items, ", ") .. "</font>") end
		AddLog("\n" .. (data.LogMsg or ""))

	elseif status == "Update" then
		skillsContainer.Visible = true; StoryTab.RenderSkills(data.Battle)

	elseif status == "Victory" or status == "Defeat" or status == "Fled" then
		skillsContainer.Visible = false; resourceLabel.Visible = false
		pImmunity.Visible = false; eImmunity.Visible = false; aImmunity.Visible = false
		pCImmunity.Visible = false; eCImmunity.Visible = false; aCImmunity.Visible = false
		pStatus.Visible = false; eStatus.Visible = false; aStatus.Visible = false

		if status == "Victory" then SFXManager.Play("CombatVictory") else SFXManager.Play("CombatDefeat") end

		local color = status == "Victory" and "#00FFFF" or (status == "Defeat" and "#FF0055" or "#AAAAAA")
		AddLog("<font color='" .. color .. "'>" .. status:upper() .. "!</font>")

		if status == "Victory" then
			AddLog("<font color='#55FF55'>+" .. (data.XP or 0) .. " XP, +¥" .. (data.Yen or 0) .. ".</font>")
			if data.Items and #data.Items > 0 then AddLog("<font color='#FFFF55'>Dropped: " .. table.concat(data.Items, ", ") .. "</font>") end
			if data.Battle and data.Battle.Context and data.Battle.Context.IsStoryMission then AddLog("<font color='#FFD700'>MISSION COMPLETE!</font>") end
		elseif status == "Fled" then
			AddLog("<font color='#AAAAAA'>You safely escaped.</font>")
		end
		task.delay(1.5, function() buttonContainer.Visible = true end)
	end

	if data and data.Battle then
		pHPFill.Size = UDim2.new(math.clamp(data.Battle.Player.HP / data.Battle.Player.MaxHP, 0, 1), 0, 1, 0)
		pHPTxt.Text = math.floor(data.Battle.Player.HP) .. "/" .. math.floor(data.Battle.Player.MaxHP)
		pName.Text = data.Battle.Player.Name
		pStatus.Text = BuildStatusString(data.Battle.Player.Statuses)
		pStatus.Visible = true

		eName.Text = data.Battle.Enemy.Name
		eHPFill.Size = UDim2.new(math.clamp(data.Battle.Enemy.HP / data.Battle.Enemy.MaxHP, 0, 1), 0, 1, 0)
		eHPTxt.Text = math.floor(data.Battle.Enemy.HP) .. "/" .. math.floor(data.Battle.Enemy.MaxHP)
		eStatus.Text = BuildStatusString(data.Battle.Enemy.Statuses)
		eStatus.Visible = true

		resourceLabel.Text = "STAMINA: " .. math.floor(data.Battle.Player.Stamina) .. " | ENERGY: " .. math.floor(data.Battle.Player.StandEnergy) .. ""

		pImmunity.Visible = (data.Battle.Player.StunImmunity or 0) > 0
		pImmunity.Text = "Stun Immune: " .. (data.Battle.Player.StunImmunity or 0) .. " Turns"
		pCImmunity.Visible = (data.Battle.Player.ConfusionImmunity or 0) > 0
		pCImmunity.Text = "Confuse Immune: " .. (data.Battle.Player.ConfusionImmunity or 0) .. " Turns"

		eImmunity.Visible = (data.Battle.Enemy.StunImmunity or 0) > 0
		eImmunity.Text = "Stun Immune: " .. (data.Battle.Enemy.StunImmunity or 0) .. " Turns"
		eCImmunity.Visible = (data.Battle.Enemy.ConfusionImmunity or 0) > 0
		eCImmunity.Text = "Confuse Immune: " .. (data.Battle.Enemy.ConfusionImmunity or 0) .. " Turns"

		if data.Battle.Ally then
			pBg.Parent.Size = UDim2.new(0.42, 0, 0, 85)
			aBg.Parent.Visible = true
			aBg.Parent.Size = UDim2.new(0.42, 0, 0, 85)
			aBg.Parent.Position = UDim2.new(0.53, 0, 0, 20)

			aHPFill.Size = UDim2.new(math.clamp(data.Battle.Ally.HP / data.Battle.Ally.MaxHP, 0, 1), 0, 1, 0)
			aHPTxt.Text = math.floor(math.max(0, data.Battle.Ally.HP)) .. "/" .. math.floor(data.Battle.Ally.MaxHP)
			aName.Text = data.Battle.Ally.HP > 0 and data.Battle.Ally.Name or data.Battle.Ally.Name .. " (KO)"
			aStatus.Text = BuildStatusString(data.Battle.Ally.Statuses)
			aStatus.Visible = true
			aImmunity.Visible = (data.Battle.Ally.StunImmunity or 0) > 0
			aImmunity.Text = "Stun Immune: " .. (data.Battle.Ally.StunImmunity or 0) .. " Turns"
			aCImmunity.Visible = (data.Battle.Ally.ConfusionImmunity or 0) > 0
			aCImmunity.Text = "Confuse Immune: " .. (data.Battle.Ally.ConfusionImmunity or 0) .. " Turns"
		else
			pBg.Parent.Size = UDim2.new(0.9, 0, 0, 85)
			aBg.Parent.Visible = false
			aImmunity.Visible = false
			aCImmunity.Visible = false
			aStatus.Visible = false
		end
	end
end

function StoryTab.SystemMessage(msg) AddLog("" .. msg .. "") end

return StoryTab