-- @ScriptType: ModuleScript
local StoryTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local CombatTemplate = require(script.Parent:WaitForChild("CombatTemplate"))
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))

local combatUI
local activeFighters = {}
local buttonContainer
local randomEncounterBtn, storyEncounterBtn, prestigeBtn
local rootFrame, forceTabFocus
local modifierBubble
local cachedTooltipMgr = nil
local resourceLabel

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

local currentLog = ""
local function AddLog(text, append)
	if append then
		currentLog = currentLog .. "\n" .. text
	else
		currentLog = text
	end
	if combatUI then combatUI:Log(currentLog) end
end

local function SyncFighter(fKey, isAlly, id, name, iconId, hp, maxHp, statuses, immunities, stam, maxStam, nrg, maxNrg)
	if not activeFighters[fKey] then
		activeFighters[fKey] = combatUI:AddFighter(isAlly, id, name, iconId, hp, maxHp)
	else
		local f = activeFighters[fKey]
		f:UpdateIcon(iconId, name)
	end
	local f = activeFighters[fKey]
	f:UpdateHealth(hp, maxHp)

	if stam and maxStam and nrg and maxNrg then
		f:UpdateResources(stam, maxStam, nrg, maxNrg)
	end

	local currentStatuses = {}
	if statuses then
		for eff, duration in pairs(statuses) do
			if duration and duration > 0 then
				currentStatuses[eff] = true
				f:SetStatus(eff, StatusIcons[eff] or "EFF", tostring(duration), StatusDescs[eff] or "Active effect.")
			end
		end
	end
	for eff, _ in pairs(StatusIcons) do
		if not currentStatuses[eff] then
			f:RemoveStatus(eff)
		end
	end

	local hasStunImmunity = (immunities and immunities.Stun and immunities.Stun > 0)
	if hasStunImmunity then
		f:SetCooldown("StunImmunity", "STN", tostring(immunities.Stun), "Immune to Stun effects.")
	else
		f:RemoveCooldown("StunImmunity")
	end

	local hasConfImmunity = (immunities and immunities.Confusion and immunities.Confusion > 0)
	if hasConfImmunity then
		f:SetCooldown("ConfImmunity", "CNF", tostring(immunities.Confusion), "Immune to Confusion effects.")
	else
		f:RemoveCooldown("ConfImmunity")
	end
end

function StoryTab.Init(parentFrame, tooltipMgr, focusFunc, passedModifierBubble)
	rootFrame = parentFrame; cachedTooltipMgr = tooltipMgr; forceTabFocus = focusFunc
	modifierBubble = passedModifierBubble

	if modifierBubble then
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
						tooltipStr = tooltipStr .. "<b><font color='"..(mData.Color or "#FFFFFF").."'>"..m.."</font></b>\n" .. mData.Description .. "\n\n"
					end
				end
			end
			cachedTooltipMgr.Show(tooltipStr)
		end)
		modifierBubble.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)
	end

	combatUI = CombatTemplate.Create(parentFrame, cachedTooltipMgr)
	combatUI.MainFrame.LayoutOrder = 1
	combatUI.AbilitiesArea.Visible = false

	local templates = ReplicatedStorage:WaitForChild("JJBITemplates")
	local storyControls = templates:WaitForChild("StoryControlsTemplate")

	resourceLabel = storyControls:WaitForChild("ResourceLabel"):Clone()
	resourceLabel.Parent = combatUI.ContentContainer
	resourceLabel.Visible = false

	buttonContainer = storyControls:WaitForChild("ButtonContainer"):Clone()
	buttonContainer.Parent = combatUI.ContentContainer

	prestigeBtn = buttonContainer:WaitForChild("PrestigeBtn")
	randomEncounterBtn = buttonContainer:WaitForChild("RandomEncounterBtn")
	storyEncounterBtn = buttonContainer:WaitForChild("StoryEncounterBtn")

	randomEncounterBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.CombatAction:FireServer("EngageRandom") end)
	storyEncounterBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.CombatAction:FireServer("EngageStory") end)
	prestigeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.PrestigeEvent:FireServer() end)

	local camera = workspace.CurrentCamera
	local function UpdateLayoutForScreen()
		if not parentFrame.Parent then return end
		local vp = camera.ViewportSize
		local isHorizontalMobile = (vp.X > vp.Y) and (vp.Y <= 600)

		if isHorizontalMobile then
			buttonContainer.Size = UDim2.new(1, 0, 0.38, 0)
		else
			buttonContainer.Size = UDim2.new(1, 0, 0.31, 0)
		end
	end

	camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
	UpdateLayoutForScreen()

	local function UpdateStoryUI()
		local currentPart = player:GetAttribute("CurrentPart") or 1
		local currentMission = player:GetAttribute("CurrentMission") or 1

		local prestigeObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
		local prestige = prestigeObj and prestigeObj.Value or 0

		if modifierBubble then
			if prestige > 0 and parentFrame.Visible then modifierBubble.Visible = true else modifierBubble.Visible = false end
		end

		if currentPart >= 9 then
			randomEncounterBtn.Visible = false
			storyEncounterBtn.Visible = false
			prestigeBtn.Visible = true
		elseif currentPart >= 7 then
			randomEncounterBtn.Visible = false
			storyEncounterBtn.Visible = true
			prestigeBtn.Visible = true
		else
			randomEncounterBtn.Visible = true
			storyEncounterBtn.Visible = true
			prestigeBtn.Visible = false
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
	combatUI:ClearAbilities()

	local myStand, myStyle = battleData.Player.Stand or "None", battleData.Player.Style or "None"
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

	for _, sk in ipairs(valid) do
		local c = sk.Data.Type == "Stand" and Color3.fromRGB(120, 20, 160) or (sk.Data.Type == "Style" and Color3.fromRGB(180, 80, 20) or Color3.fromRGB(60, 60, 80))

		local currentCooldown = battleData.Player.Cooldowns and battleData.Player.Cooldowns[sk.Name] or 0
		local disabled = battleData.Player.Stamina < (sk.Data.StaminaCost or 0) or battleData.Player.StandEnergy < (sk.Data.EnergyCost or 0) or currentCooldown > 0

		local btnText = (currentCooldown > 0) and (sk.Name .. " (" .. currentCooldown .. ")") or sk.Name

		local cb = function()
			if disabled then return end
			SFXManager.Play("Click")
			cachedTooltipMgr.Hide()
			Network.CombatAction:FireServer("Attack", {SkillName = sk.Name})
		end

		if sk.Name == "Flee" then cb = nil end

		local btn = combatUI:AddAbility(btnText, disabled and Color3.fromRGB(35, 25, 45) or c, cb)

		if disabled then
			btn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
		else
			if sk.Name == "Flee" then
				local isConfirmingFlee = false
				btn.MouseButton1Click:Connect(function()
					if not disabled then
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
							cachedTooltipMgr.Hide()
							Network.CombatAction:FireServer("Attack", {SkillName = sk.Name}) 
						end
					end
				end)
			end
		end

		btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
		btn.MouseLeave:Connect(cachedTooltipMgr.Hide)
	end
end

function StoryTab.UpdateCombat(status, data)
	if status == "Start" then
		if forceTabFocus then forceTabFocus() end 
		combatUI.ChatText.Text = ""
		buttonContainer.Visible = false
		combatUI.AbilitiesArea.Visible = true

		for fKey, f in pairs(activeFighters) do
			if f.Frame then f.Frame:Destroy() end
		end
		activeFighters = {}

		AddLog(data.LogMsg or "", false)
		StoryTab.RenderSkills(data.Battle)

	elseif status == "TurnStrike" then
		combatUI.AbilitiesArea.Visible = false
		AddLog(data.LogMsg, true)

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
				for i = 1, 6 do 
					local offsetX = math.random(-p, p)
					local offsetY = math.random(-p, p)
					combatUI.MainFrame.Position = UDim2.new(0, offsetX, 0, offsetY)
					task.wait(0.04) 
				end
				combatUI.MainFrame.Position = UDim2.new(0, 0, 0, 0)
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

	elseif status == "WaveComplete" then
		buttonContainer.Visible = false
		combatUI.AbilitiesArea.Visible = true
		StoryTab.RenderSkills(data.Battle)

		local xpDrop = data.Drops and data.Drops.XP or data.XP or 0
		local yenDrop = data.Drops and data.Drops.Yen or data.Yen or 0
		local itemsDrop = data.Drops and data.Drops.Items or data.Items

		AddLog("<font color='#55FF55'>WAVE CLEARED! +" .. xpDrop .. " XP, +¥" .. yenDrop .. ".</font>", true)
		if itemsDrop and #itemsDrop > 0 then AddLog("<font color='#FFFF55'>Dropped: " .. table.concat(itemsDrop, ", ") .. "</font>", true) end
		AddLog("\n" .. (data.LogMsg or ""), true)

	elseif status == "Update" then
		combatUI.AbilitiesArea.Visible = true
		StoryTab.RenderSkills(data.Battle)

	elseif status == "Victory" or status == "Defeat" or status == "Fled" then
		combatUI.AbilitiesArea.Visible = false

		for fKey, f in pairs(activeFighters) do
			if f.Frame then f.Frame:Destroy() end
		end
		activeFighters = {}

		if status == "Victory" then SFXManager.Play("CombatVictory") else SFXManager.Play("CombatDefeat") end

		local color = status == "Victory" and "#00FFFF" or (status == "Defeat" and "#FF0055" or "#AAAAAA")
		AddLog("<font color='" .. color .. "'>" .. status:upper() .. "!</font>", true)

		if status == "Victory" then
			local xpDrop = data.Drops and data.Drops.XP or data.XP or 0
			local yenDrop = data.Drops and data.Drops.Yen or data.Yen or 0
			local itemsDrop = data.Drops and data.Drops.Items or data.Items

			AddLog("<font color='#55FF55'>+" .. xpDrop .. " XP, +¥" .. yenDrop .. ".</font>", true)
			if itemsDrop and #itemsDrop > 0 then AddLog("<font color='#FFFF55'>Dropped: " .. table.concat(itemsDrop, ", ") .. "</font>", true) end
			if data.Battle and data.Battle.Context and data.Battle.Context.IsStoryMission then AddLog("<font color='#FFD700'>MISSION COMPLETE!</font>", true) end
		elseif status == "Fled" then
			AddLog("<font color='#AAAAAA'>You safely escaped.</font>", true)
		end
		task.delay(1.5, function() buttonContainer.Visible = true end)
	end

	if data and data.Battle and status ~= "Victory" and status ~= "Defeat" and status ~= "Fled" then
		SyncFighter("Player", true, "Player", data.Battle.Player.Name, player.UserId, data.Battle.Player.HP, data.Battle.Player.MaxHP, data.Battle.Player.Statuses, {Stun=data.Battle.Player.StunImmunity, Confusion=data.Battle.Player.ConfusionImmunity}, data.Battle.Player.Stamina, data.Battle.Player.MaxStamina, data.Battle.Player.StandEnergy, data.Battle.Player.MaxStandEnergy)
		if data.Battle.Player.HP <= 0 and activeFighters["Player"] then
			activeFighters["Player"].Frame:FindFirstChild("InfoArea").NameLabel.Text = data.Battle.Player.Name .. " (KO)"
		end

		SyncFighter("Enemy", false, "Enemy", data.Battle.Enemy.Name, data.Battle.Enemy.Icon, data.Battle.Enemy.HP, data.Battle.Enemy.MaxHP, data.Battle.Enemy.Statuses, {Stun=data.Battle.Enemy.StunImmunity, Confusion=data.Battle.Enemy.ConfusionImmunity}, data.Battle.Enemy.Stamina, data.Battle.Enemy.MaxStamina, data.Battle.Enemy.StandEnergy, data.Battle.Enemy.MaxStandEnergy)

		if data.Battle.Ally then
			SyncFighter("Ally", true, "Ally", data.Battle.Ally.Name, data.Battle.Ally.Icon, data.Battle.Ally.HP, data.Battle.Ally.MaxHP, data.Battle.Ally.Statuses, {Stun=data.Battle.Ally.StunImmunity, Confusion=data.Battle.Ally.ConfusionImmunity}, data.Battle.Ally.Stamina, data.Battle.Ally.MaxStamina, data.Battle.Ally.StandEnergy, data.Battle.Ally.MaxStandEnergy)
			if data.Battle.Ally.HP <= 0 and activeFighters["Ally"] then
				activeFighters["Ally"].Frame:FindFirstChild("InfoArea").NameLabel.Text = data.Battle.Ally.Name .. " (KO)"
			end
		else
			if activeFighters["Ally"] then
				activeFighters["Ally"].Frame:Destroy()
				activeFighters["Ally"] = nil
			end
		end
	end
end

function StoryTab.SystemMessage(msg) AddLog("" .. msg .. "", true) end

return StoryTab