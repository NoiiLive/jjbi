-- @ScriptType: ModuleScript
local WorldBossTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))
local CombatTemplate = require(script.Parent:WaitForChild("CombatTemplate"))
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))

local menuContainer, infoCard
local bossNameLabel, timerLabel, engageBtn, rerollBtn
local combatUI
local activeFighters = {}
local rootFrame, forceTabFocus, cachedTooltipMgr
local resourceLabel, turnLabel

local inBattle = false
local BOSS_ACTIVE_MINUTES = 30

local StatusIcons = {
	Stun = "STN", Poison = "PSN", Burn = "BRN", Bleed = "BLD", Freeze = "FRZ", Confusion = "CNF", Dizzy = "DZY", Chilly = "CLD",
	Acid = "ACD", Infection = "INF", Rupture = "RPT", Frostburn = "FBN", Frostbite = "FBT", Decay = "DCY",
	Blight = "BLT", Miasma = "MSM", Necrosis = "NCR", Plague = "PLG", Calamity = "CLM",
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
	Buff_Strength = "Increased damage dealt.",
	Buff_Defense = "Reduced damage taken.",
	Buff_Speed = "Increased evasion and turn priority.",
	Buff_Willpower = "Increased crit and survival chance.",
	Debuff_Strength = "Reduced damage dealt.",
	Debuff_Defense = "Increased damage taken.",
	Debuff_Speed = "Reduced evasion and turn priority.",
	Debuff_Willpower = "Reduced crit and survival chance.",
	EnergyExhausted = "Cannot use stand skills.",
	StaminaExhausted = "Cannot use style skills."
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

local function FormatTime(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

local function SyncFighter(fKey, isAlly, id, name, iconId, hp, maxHp, statuses, immunities)
	if not activeFighters[fKey] then
		activeFighters[fKey] = combatUI:AddFighter(isAlly, id, name, iconId, hp, maxHp)
	else
		local f = activeFighters[fKey]
		f:UpdateIcon(iconId, name)
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

function WorldBossTab.Init(parentFrame, tooltipMgr, focusFunc)
	rootFrame = parentFrame
	cachedTooltipMgr = tooltipMgr
	forceTabFocus = focusFunc

	if not WorldBossTab.Listener then
		local wbUpdate = Network:WaitForChild("WorldBossUpdate")
		WorldBossTab.Listener = wbUpdate.OnClientEvent:Connect(function(action, data)
			WorldBossTab.UpdateWorldBoss(action, data)
		end)
	end

	menuContainer = parentFrame:WaitForChild("MenuContainer")
	infoCard = menuContainer:WaitForChild("InfoCard")
	bossNameLabel = infoCard:WaitForChild("BossNameLabel")
	timerLabel = infoCard:WaitForChild("TimerLabel")
	engageBtn = infoCard:WaitForChild("EngageBtn")
	rerollBtn = infoCard:WaitForChild("RerollBtn")

	rerollBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)

	combatUI = CombatTemplate.Create(parentFrame, cachedTooltipMgr)
	combatUI.MainFrame.Visible = false
	combatUI.MainFrame.ZIndex = 40

	local templates = ReplicatedStorage:WaitForChild("JJBITemplates")
	local wbControls = templates:WaitForChild("WorldBossControlsTemplate")

	turnLabel = wbControls:WaitForChild("TurnLabel"):Clone()
	turnLabel.Parent = combatUI.MainFrame

	resourceLabel = wbControls:WaitForChild("ResourceLabel"):Clone()
	resourceLabel.Parent = combatUI.ContentContainer

	engageBtn.MouseButton1Click:Connect(function()
		if engageBtn.Text == "ENGAGE BOSS" or engageBtn.Text == "ENGAGE PRIVATE BOSS" then
			SFXManager.Play("Click")
			Network.WorldBossAction:FireServer("Engage")
		end
	end)

	rerollBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		MarketplaceService:PromptProductPurchase(player, 3567043458)
	end)

	task.delay(0.5, function()
		Network.WorldBossAction:FireServer("RequestSync")
	end)

	task.spawn(function()
		local RunService = game:GetService("RunService")
		while task.wait(1) do
			if inBattle then continue end

			local now = math.floor(workspace:GetServerTimeNow())
			local utc = os.date("!*t", now)
			local mins = utc.min
			local secs = utc.sec

			local instancedBoss = player:GetAttribute("InstancedWorldBoss")
			local instancedEndTime = player:GetAttribute("InstancedWorldBossEndTime") or 0
			local hasInstanced = instancedBoss and instancedEndTime > now

			if hasInstanced then
				local timeRemaining = instancedEndTime - now
				timerLabel.Text = "PRIVATE BOSS DESPAWNS IN: " .. FormatTime(math.floor(timeRemaining))
				timerLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				engageBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				engageBtn.Text = "ENGAGE PRIVATE BOSS"
				engageBtn.AutoButtonColor = true
				if bossNameLabel.Text ~= string.upper(instancedBoss) .. " (PRIVATE)" then
					bossNameLabel.Text = string.upper(instancedBoss) .. " (PRIVATE)"
				end
			else
				local isStudio = RunService:IsStudio()
				local currentSession = ReplicatedStorage:GetAttribute("CurrentBossSession") or ""
				local lastFought = player:GetAttribute("LastBossSessionFought") or ""

				local endTime = ReplicatedStorage:GetAttribute("WorldBossEndTime") or 0
				local timeRemaining = endTime - now

				if timeRemaining > 0 then
					if lastFought == currentSession and currentSession ~= "" and not isStudio then
						local secondsLeft = (60 * 60) - ((mins * 60) + secs)
						timerLabel.Text = "NEXT IN: " .. FormatTime(secondsLeft)
						timerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
						engageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
						engageBtn.Text = "ALREADY FOUGHT"
						engageBtn.AutoButtonColor = false
					else
						timerLabel.Text = "DESPAWNS IN: " .. FormatTime(math.floor(timeRemaining))
						timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
						engageBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
						engageBtn.Text = "ENGAGE BOSS"
						engageBtn.AutoButtonColor = true
					end
				else
					local secondsLeft = (60 * 60) - ((mins * 60) + secs)
					timerLabel.Text = "SPAWNS IN: " .. FormatTime(secondsLeft)
					timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
					engageBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
					engageBtn.Text = "WAITING..."
					engageBtn.AutoButtonColor = false
				end
			end
		end
	end)
end

function WorldBossTab.RenderSkills(battleData)
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
			Network.WorldBossAction:FireServer("Attack", {SkillName = sk.Name})
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
							Network.WorldBossAction:FireServer("Attack", {SkillName = sk.Name}) 
						end
					end
				end)
			end
		end

		btn.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetSkillTooltip(sk.Name)) end)
		btn.MouseLeave:Connect(cachedTooltipMgr.Hide)
	end
end

function WorldBossTab.UpdateWorldBoss(status, data)
	if status == "SyncBoss" then
		local now = math.floor(workspace:GetServerTimeNow())
		local instancedBoss = player:GetAttribute("InstancedWorldBoss")
		local instancedEndTime = player:GetAttribute("InstancedWorldBossEndTime") or 0
		if instancedBoss and instancedEndTime > now then
			if bossNameLabel then bossNameLabel.Text = string.upper(instancedBoss) .. " (PRIVATE)" end
		else
			if bossNameLabel then bossNameLabel.Text = data and string.upper(data) or "UNKNOWN THREAT" end
		end
		return
	end

	if status == "Start" then
		inBattle = true
		if forceTabFocus then forceTabFocus() end 
		combatUI.ChatText.Text = ""
		menuContainer.Visible = false
		combatUI.MainFrame.Visible = true
		combatUI.AbilitiesArea.Visible = true

		for fKey, f in pairs(activeFighters) do
			if f.Frame then f.Frame:Destroy() end
		end
		activeFighters = {}

		AddLog(data.LogMsg or "", false)
		WorldBossTab.RenderSkills(data.Battle)

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

	elseif status == "Update" then
		combatUI.AbilitiesArea.Visible = true
		WorldBossTab.RenderSkills(data.Battle)

	elseif status == "Victory" or status == "Defeat" or status == "Fled" then
		combatUI.AbilitiesArea.Visible = false

		for fKey, f in pairs(activeFighters) do
			if f.Frame then f.Frame:Destroy() end
		end
		activeFighters = {}

		if status == "Victory" then SFXManager.Play("CombatVictory") else SFXManager.Play("CombatDefeat") end

		local color = status == "Victory" and "#00FFFF" or (status == "Defeat" and "#FF0055" or "#AAAAAA")
		AddLog("<font color='" .. color .. "'>WORLD BOSS " .. status:upper() .. "!</font>", true)

		if data.CustomLog then AddLog(data.CustomLog, true) end

		if status == "Victory" and data.Drops then
			AddLog("<font color='#55FF55'>+" .. (data.Drops.XP or 0) .. " XP, +¥" .. (data.Drops.Yen or 0) .. ".</font>", true)
			if data.Drops.Items and #data.Drops.Items > 0 then 
				AddLog("<font color='#FFFF55'>Loot Secured: " .. table.concat(data.Drops.Items, ", ") .. "</font>", true) 
			end
		elseif status == "Fled" then
			AddLog("<font color='#AAAAAA'>You fled the battle.</font>", true)
		end

		task.delay(4, function() 
			inBattle = false
			combatUI.MainFrame.Visible = false
			menuContainer.Visible = true
		end)
	end

	if data and data.Battle then
		local battle = data.Battle
		resourceLabel.Text = "STAMINA: " .. math.floor(battle.Player.Stamina) .. " | ENERGY: " .. math.floor(battle.Player.StandEnergy)

		local turnsLeft = 11 - (battle.TurnCounter or 1)
		turnLabel.Text = "Turns Remaining: " .. math.max(0, turnsLeft) .. "/10"

		SyncFighter("Player", true, "Player", battle.Player.Name, player.UserId, battle.Player.HP, battle.Player.MaxHP, battle.Player.Statuses, {Stun=battle.Player.StunImmunity, Confusion=battle.Player.ConfusionImmunity})
		if battle.Player.HP <= 0 and activeFighters["Player"] then
			activeFighters["Player"].Frame:FindFirstChild("InfoArea").NameLabel.Text = battle.Player.Name .. " (KO)"
		end

		if battle.Enemy then
			SyncFighter("Enemy", false, "Enemy", battle.Enemy.Name, battle.Enemy.Icon, battle.Enemy.HP, battle.Enemy.MaxHP, battle.Enemy.Statuses, {Stun=battle.Enemy.StunImmunity, Confusion=battle.Enemy.ConfusionImmunity})
			if battle.Enemy.HP <= 0 and activeFighters["Enemy"] then
				activeFighters["Enemy"].Frame:FindFirstChild("InfoArea").NameLabel.Text = battle.Enemy.Name .. " (KO)"
			end
		else
			if activeFighters["Enemy"] then
				activeFighters["Enemy"].Frame:Destroy()
				activeFighters["Enemy"] = nil
			end
		end

		if battle.Ally then
			SyncFighter("Ally", true, "Ally", battle.Ally.Name, battle.Ally.Icon, battle.Ally.HP, battle.Ally.MaxHP, battle.Ally.Statuses, {Stun=battle.Ally.StunImmunity, Confusion=battle.Ally.ConfusionImmunity})
			if battle.Ally.HP <= 0 and activeFighters["Ally"] then
				activeFighters["Ally"].Frame:FindFirstChild("InfoArea").NameLabel.Text = battle.Ally.Name .. " (KO)"
			end
		else
			if activeFighters["Ally"] then
				activeFighters["Ally"].Frame:Destroy()
				activeFighters["Ally"] = nil
			end
		end
	end
end

function WorldBossTab.SystemMessage(msg)
	AddLog(msg, true)
end

return WorldBossTab