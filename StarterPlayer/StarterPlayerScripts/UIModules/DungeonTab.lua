-- @ScriptType: ModuleScript
local DungeonTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local CombatTemplate = require(script.Parent:WaitForChild("CombatTemplate"))
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))

local menuContainer, menuFrame
local combatUI
local activeFighters = {}
local rootFrame, forceTabFocus, cachedTooltipMgr
local resourceLabel, waveLabel

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

local dungeonList = {
	{ Id = 1, Name = "Phantom Blood Dungeon", Req = 5 },
	{ Id = 2, Name = "Battle Tendency Dungeon", Req = 6 },
	{ Id = 3, Name = "Stardust Crusaders Dungeon", Req = 7 },
	{ Id = 4, Name = "Diamond is Unbreakable Dungeon", Req = 8 },
	{ Id = 5, Name = "Golden Wind Dungeon", Req = 9 },
	{ Id = 6, Name = "Stone Ocean Dungeon", Req = 10 },
	{ Id = "Endless", Name = "Endless Dungeon", Req = 15 }
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

local function SyncFighter(fKey, isAlly, id, name, iconId, hp, maxHp, statuses, immunities)
	if not activeFighters[fKey] then
		activeFighters[fKey] = combatUI:AddFighter(isAlly, id, name, iconId, hp, maxHp)
	else
		local f = activeFighters[fKey]
		if f.InfoArea and f.InfoArea:FindFirstChild("NameLabel") then
			f.InfoArea.NameLabel.Text = name
		end
	end
	local f = activeFighters[fKey]
	f:UpdateHealth(hp, maxHp)

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

function DungeonTab.Init(parentFrame, tooltipMgr, focusFunc)
	rootFrame = parentFrame
	cachedTooltipMgr = tooltipMgr
	forceTabFocus = focusFunc

	menuContainer = parentFrame:WaitForChild("MenuContainer")
	menuFrame = menuContainer:WaitForChild("MenuFrame")

	for _, child in pairs(menuFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local templates = ReplicatedStorage:WaitForChild("JJBITemplates")
	local dungeonRowTpl = templates:WaitForChild("DungeonRowTemplate")

	local dungeonUIElements = {}

	for _, dInfo in ipairs(dungeonList) do
		local row = dungeonRowTpl:Clone()
		row.Name = dInfo.Name
		row.Parent = menuFrame

		local infoContainer = row:WaitForChild("InfoContainer")
		local title = infoContainer:WaitForChild("TitleLabel")
		local status = infoContainer:WaitForChild("StatusLabel")
		local reward = infoContainer:WaitForChild("RewardLabel")
		local playBtn = row:WaitForChild("PlayBtn")

		title.Text = dInfo.Name

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
				local pVal = prestige and prestige.Value or 0
				for id, data in pairs(dungeonUIElements) do
					data.Title.Text = data.Info.Name

					if data.Info.Id == "Endless" then
						local hs = player:GetAttribute("EndlessHighScore") or 0
						data.Status.Text = "<font color='#AAAAAA'>High Score:</font> <font color='#55FF55'>Floor " .. hs .. "</font>"
						data.Reward.Text = "<font color='#AAAAAA'>Milestone Reward:</font> <font color='#FF55FF'>Rokakaka</font> every 10 floors."
					else
						local cleared = player:GetAttribute("DungeonClear_Part" .. data.Info.Id)
						if cleared then
							data.Status.Text = "<font color='#AAAAAA'>Status:</font> <font color='#55FF55'>Cleared</font>"
							data.Reward.Text = "<font color='#AAAAAA'>Rewards:</font> Massive Item Pool & XP/Yen"
						else
							data.Status.Text = "<font color='#AAAAAA'>Status:</font> <font color='#FF5555'>Uncleared</font>"
							data.Reward.Text = "<font color='#AAAAAA'>First Time Clear:</font> <font color='#FF55FF'>Rokakaka</font>"
						end
					end

					if pVal >= data.Info.Req then
						data.Btn.BackgroundColor3 = Color3.fromRGB(70, 20, 100)
						data.Btn.Text = "PLAY"
						data.Btn.TextColor3 = Color3.new(1,1,1)
						data.Btn.Active = true
						data.Btn.AutoButtonColor = true
					else
						data.Btn.BackgroundColor3 = Color3.fromRGB(35, 25, 40)
						data.Btn.Text = "??"
						data.Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
						data.Btn.Active = false
						data.Btn.AutoButtonColor = false
						data.Status.Text = "<font color='#AAAAAA'>Status:</font> <font color='#FF5555'>Requires Prestige " .. data.Info.Req .. "</font>"
					end
				end
			end

			if prestige then
				prestige.Changed:Connect(updateLocks)
			end
			player:GetAttributeChangedSignal("EndlessHighScore"):Connect(updateLocks)
			for i = 1, 6 do player:GetAttributeChangedSignal("DungeonClear_Part" .. i):Connect(updateLocks) end
			updateLocks()
		end
	end)

	combatUI = CombatTemplate.Create(parentFrame, cachedTooltipMgr)
	combatUI.MainFrame.Visible = false
	combatUI.MainFrame.ZIndex = 40

	local dControls = templates:WaitForChild("DungeonControlsTemplate")

	waveLabel = dControls:WaitForChild("WaveLabel"):Clone()
	waveLabel.Parent = combatUI.MainFrame

	resourceLabel = dControls:WaitForChild("ResourceLabel"):Clone()
	resourceLabel.Parent = combatUI.ContentContainer
end

function DungeonTab.RenderSkills(battleData)
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
			Network:WaitForChild("DungeonAction"):FireServer("Attack", sk.Name)
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
							Network:WaitForChild("DungeonAction"):FireServer("Attack", sk.Name) 
						end
					end
				end)
			end
		end

		btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
		btn.MouseLeave:Connect(cachedTooltipMgr.Hide)
	end
end

function DungeonTab.UpdateDungeon(status, data)
	if status == "Start" then
		if forceTabFocus then forceTabFocus() end 
		combatUI.ChatText.Text = ""
		menuContainer.Visible = false
		combatUI.MainFrame.Visible = true
		combatUI.AbilitiesArea.Visible = true

		AddLog(data.LogMsg or "", false)
		waveLabel.Text = data.WaveStr or "Floor 1"
		DungeonTab.RenderSkills(data.Battle)

	elseif status == "TurnStrike" then
		combatUI.AbilitiesArea.Visible = false
		AddLog(data.LogMsg, true)

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
				for i = 1, 6 do 
					local offsetX = math.random(-p, p)
					local offsetY = math.random(-p, p)
					combatUI.MainFrame.Position = UDim2.new(0, offsetX, 0, offsetY)
					task.wait(0.04) 
				end
				combatUI.MainFrame.Position = UDim2.new(0, 0, 0, 0)
			end)
		end

	elseif status == "WaveComplete" then
		combatUI.AbilitiesArea.Visible = true
		waveLabel.Text = data.WaveStr or "Floor ?"
		AddLog("<font color='#55FF55'>Enemy Defeated!</font>\n" .. (data.LogMsg or ""), true)
		DungeonTab.RenderSkills(data.Battle)

	elseif status == "Update" then
		combatUI.AbilitiesArea.Visible = true
		DungeonTab.RenderSkills(data.Battle)

	elseif status == "Victory" or status == "Defeat" or status == "Fled" then
		combatUI.AbilitiesArea.Visible = false

		for fKey, f in pairs(activeFighters) do
			f.Frame:Destroy()
		end
		activeFighters = {}

		if status == "Victory" then SFXManager.Play("CombatVictory") else SFXManager.Play("CombatDefeat") end

		local color = status == "Victory" and "#00FFFF" or (status == "Defeat" and "#FF0055" or "#AAAAAA")
		AddLog("<font color='" .. color .. "'>DUNGEON " .. status:upper() .. "!</font>", true)

		if status == "Victory" and data.Drops then
			AddLog("<font color='#55FF55'>+" .. (data.Drops.XP or 0) .. " XP, +¥" .. (data.Drops.Yen or 0) .. ".</font>", true)
			if data.Drops.Items and #data.Drops.Items > 0 then 
				AddLog("<font color='#FFFF55'>Loot Secured: " .. table.concat(data.Drops.Items, ", ") .. "</font>", true) 
			end
		elseif status == "Fled" then
			AddLog("<font color='#AAAAAA'>You fled the dungeon, forfeiting all progress.</font>", true)
		end

		task.delay(4, function() 
			combatUI.MainFrame.Visible = false
			menuContainer.Visible = true
		end)
	end

	if data and data.Battle then
		resourceLabel.Text = "STAMINA: " .. math.floor(data.Battle.Player.Stamina) .. " | ENERGY: " .. math.floor(data.Battle.Player.StandEnergy)

		SyncFighter("Player", true, "Player", data.Battle.Player.Name, player.UserId, data.Battle.Player.HP, data.Battle.Player.MaxHP, data.Battle.Player.Statuses, {Stun=data.Battle.Player.StunImmunity, Confusion=data.Battle.Player.ConfusionImmunity})
		if data.Battle.Player.HP <= 0 and activeFighters["Player"] then
			activeFighters["Player"].Frame:FindFirstChild("InfoArea").NameLabel.Text = data.Battle.Player.Name .. " (KO)"
		end

		if data.Battle.Enemy then
			SyncFighter("Enemy", false, "Enemy", data.Battle.Enemy.Name, "", data.Battle.Enemy.HP, data.Battle.Enemy.MaxHP, data.Battle.Enemy.Statuses, {Stun=data.Battle.Enemy.StunImmunity, Confusion=data.Battle.Enemy.ConfusionImmunity})
			if data.Battle.Enemy.HP <= 0 and activeFighters["Enemy"] then
				activeFighters["Enemy"].Frame:FindFirstChild("InfoArea").NameLabel.Text = data.Battle.Enemy.Name .. " (KO)"
			end
		else
			if activeFighters["Enemy"] then
				activeFighters["Enemy"].Frame:Destroy()
				activeFighters["Enemy"] = nil
			end
		end

		if data.Battle.Ally then
			SyncFighter("Ally", true, "Ally", data.Battle.Ally.Name, "", data.Battle.Ally.HP, data.Battle.Ally.MaxHP, data.Battle.Ally.Statuses, {Stun=data.Battle.Ally.StunImmunity, Confusion=data.Battle.Ally.ConfusionImmunity})
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

function DungeonTab.SystemMessage(msg) AddLog("" .. msg .. "", true) end

return DungeonTab