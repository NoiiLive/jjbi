-- @ScriptType: Script
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Network = ReplicatedStorage:WaitForChild("Network")

local NotificationEvent = Network:FindFirstChild("NotificationEvent")
if not NotificationEvent then
	NotificationEvent = Instance.new("RemoteEvent")
	NotificationEvent.Name = "NotificationEvent"
	NotificationEvent.Parent = Network
end

local AdminLogger = Network:FindFirstChild("AdminLogger")
if not AdminLogger then
	AdminLogger = Instance.new("BindableEvent")
	AdminLogger.Name = "AdminLogger"
	AdminLogger.Parent = Network
end

local AdminEditUI = Network:FindFirstChild("AdminEditUI")
if not AdminEditUI then
	AdminEditUI = Instance.new("RemoteEvent")
	AdminEditUI.Name = "AdminEditUI"
	AdminEditUI.Parent = Network
end

local AdminEditAction = Network:FindFirstChild("AdminEditAction")
if not AdminEditAction then
	AdminEditAction = Instance.new("RemoteEvent")
	AdminEditAction.Name = "AdminEditAction"
	AdminEditAction.Parent = Network
end

local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local EnemyData = require(ReplicatedStorage:WaitForChild("EnemyData"))

local GangStore = DataStoreService:GetDataStore("Jojo_Gangs_V3")

local GROUP_ID = 11280027
local GLOBAL_TOPIC = "AdminGlobalCommands"
local GANG_TOPIC = "JJBI_Gang_Sync_V1"

local ADMIN_RANKS = {
	[255] = true,
	[11] = true,
	[10] = true,
	[8] = true
}

local MOD_RANKS = {
	[9] = true,
	[7] = true,
	[5] = true
}

local ANNOUNCER_RANKS = {
	[6] = true
}

local function GetDictSize(d)
	local c = 0
	if d then for _ in pairs(d) do c += 1 end end
	return c
end

local function FindPlayer(nameStr)
	if not nameStr then return nil end
	local search = string.lower(nameStr)
	for _, p in ipairs(Players:GetPlayers()) do
		if string.sub(string.lower(p.Name), 1, #search) == search then
			return p
		end
	end
	return nil
end

local function CleanStr(str)
	if not str then return "" end
	local s = string.lower(str)
	s = string.gsub(s, "&amp;", "and")
	s = string.gsub(s, "&", "and")
	s = string.gsub(s, "[%p%s]", "")
	return s
end

local function GetProperItemName(inputStr)
	local search = CleanStr(inputStr)

	for key, _ in pairs(ItemData.Equipment) do if CleanStr(key) == search then return key end end
	for key, _ in pairs(ItemData.Consumables) do if CleanStr(key) == search then return key end end

	for key, _ in pairs(ItemData.Equipment) do if string.find(CleanStr(key), search, 1, true) then return key end end
	for key, _ in pairs(ItemData.Consumables) do if string.find(CleanStr(key), search, 1, true) then return key end end
	return nil
end

local function GetProperStandName(inputStr)
	local search = CleanStr(inputStr)

	for key, _ in pairs(StandData.Stands) do if CleanStr(key) == search then return key end end
	for key, _ in pairs(StandData.Stands) do if string.find(CleanStr(key), search, 1, true) then return key end end
	return nil
end

local function GetProperStyleName(inputStr)
	local search = CleanStr(inputStr)
	if search == "none" then return "None" end

	for key, _ in pairs(GameData.StyleBonuses) do if CleanStr(key) == search then return key end end
	for key, _ in pairs(GameData.StyleBonuses) do if string.find(CleanStr(key), search, 1, true) then return key end end
	return nil
end

local function GetProperTraitName(inputStr)
	local search = CleanStr(inputStr)
	if search == "none" then return "None" end

	for key, _ in pairs(StandData.Traits) do if CleanStr(key) == search then return key end end
	for key, _ in pairs(StandData.Traits) do if string.find(CleanStr(key), search, 1, true) then return key end end
	return nil
end

local function GetProperStatName(inputStr)
	local search = CleanStr(inputStr)
	local validStats = {
		yen = "Yen", prestige = "Prestige", elo = "Elo", xp = "XP",
		health = "Health", strength = "Strength", defense = "Defense", speed = "Speed", stamina = "Stamina", willpower = "Willpower",
		standpower = "Stand_Power_Val", standspeed = "Stand_Speed_Val", standrange = "Stand_Range_Val",
		standdurability = "Stand_Durability_Val", standprecision = "Stand_Precision_Val", standpotential = "Stand_Potential_Val"
	}

	return validStats[search]
end

local function GetProperWorldBossName(inputStr)
	local search = CleanStr(inputStr)
	for key, _ in pairs(EnemyData.WorldBosses) do if CleanStr(key) == search then return key end end
	for key, _ in pairs(EnemyData.WorldBosses) do if string.find(CleanStr(key), search, 1, true) then return key end end
	return nil
end

local function GetProperPassAttr(inputStr)
	local search = CleanStr(inputStr)
	local passMap = {
		["2xspeed"] = "Has2xBattleSpeed", ["2xbattlespeed"] = "Has2xBattleSpeed", ["2xbattlespeedpass"] = "Has2xBattleSpeed",
		["2xinventory"] = "Has2xInventory", ["2xinventorypass"] = "Has2xInventory",
		["2xdrops"] = "Has2xDropChance", ["2xdropchance"] = "Has2xDropChance", ["2xdropchancepass"] = "Has2xDropChance",
		["autotrain"] = "HasAutoTraining", ["autotraining"] = "HasAutoTraining", ["autotrainingpass"] = "HasAutoTraining",
		["styleslot2"] = "HasStyleSlot2", ["standslot2"] = "HasStandSlot2",
		["styleslot3"] = "HasStyleSlot3", ["standslot3"] = "HasStandSlot3",
		["standstorageslot2"] = "HasStandSlot2", ["standstorageslot3"] = "HasStandSlot3",
		["stylestorageslot2"] = "HasStyleSlot2", ["stylestorageslot3"] = "HasStyleSlot3",
		["autoroll"] = "HasAutoRoll", ["autorollpass"] = "HasAutoRoll",
		["horsename"] = "HasHorseNamePass", ["customhorsename"] = "HasHorseNamePass", ["customhorsenamepass"] = "HasHorseNamePass",
		["vip"] = "IsVIP", ["autostat"] = "HasAutoStatPass"
	}
	return passMap[search]
end

local function GrantStand(playerObj, standName)
	if not StandData.Stands[standName] then return false end

	playerObj:SetAttribute("Stand", standName)

	local prestigeObj = playerObj:WaitForChild("leaderstats") and playerObj.leaderstats:WaitForChild("Prestige")
	local prestige = prestigeObj and prestigeObj.Value or 0
	local stats = StandData.Stands[standName].Stats

	for sName, sRank in pairs(stats) do
		local baseVal = (prestige == 0) and (GameData.StandRanks[sRank] or 0) or (prestige * 5)
		playerObj:SetAttribute("Stand_" .. sName, sRank)
		playerObj:SetAttribute("Stand_" .. sName .. "_Val", baseVal)
	end

	return true
end

local function SendAdminNotice(targetPlayer, message)
	if not targetPlayer then return end
	Network.CombatUpdate:FireClient(targetPlayer, "SystemMessage", message)
	NotificationEvent:FireClient(targetPlayer, message)
end

local function GetStandSlotData(target, slotKey, locked)
	local sName = target:GetAttribute("StoredStand" .. slotKey) or "None"
	local f1 = target:GetAttribute("StoredStand" .. slotKey .. "_FusedStand1")
	local f2 = target:GetAttribute("StoredStand" .. slotKey .. "_FusedStand2")
	local t1 = target:GetAttribute("StoredStand" .. slotKey .. "_FusedTrait1")
	local t2 = target:GetAttribute("StoredStand" .. slotKey .. "_FusedTrait2")
	local st = target:GetAttribute("StoredStand" .. slotKey .. "_Trait") or "None"

	return {
		Name = (sName == "Fused Stand") and f1 or sName,
		FusedWith = (sName == "Fused Stand") and f2 or nil,
		Trait1 = (sName == "Fused Stand") and t1 or st,
		Trait2 = (sName == "Fused Stand") and t2 or nil,
		Locked = locked
	}
end

local function FetchPlayerData(target)
	local data = { Inventory = {}, Stands = {}, Styles = {} }

	for key, _ in pairs(ItemData.Equipment) do
		local attrName = key:gsub("[^%w]", "") .. "Count"
		local c = target:GetAttribute(attrName) or 0
		if c > 0 then data.Inventory[key] = c end
	end
	for key, _ in pairs(ItemData.Consumables) do
		local attrName = key:gsub("[^%w]", "") .. "Count"
		local c = target:GetAttribute(attrName) or 0
		if c > 0 then data.Inventory[key] = c end
	end

	local sName = target:GetAttribute("Stand") or "None"
	local f1 = target:GetAttribute("Active_FusedStand1")
	local f2 = target:GetAttribute("Active_FusedStand2")
	local t1 = target:GetAttribute("Active_FusedTrait1")
	local t2 = target:GetAttribute("Active_FusedTrait2")
	local st = target:GetAttribute("StandTrait") or "None"

	data.Stands["1_Active"] = {
		Name = (sName == "Fused Stand") and f1 or sName,
		FusedWith = (sName == "Fused Stand") and f2 or nil,
		Trait1 = (sName == "Fused Stand") and t1 or st,
		Trait2 = (sName == "Fused Stand") and t2 or nil,
		Locked = false
	}

	local pObj = target:FindFirstChild("leaderstats")
	local prestige = pObj and pObj:FindFirstChild("Prestige") and pObj.Prestige.Value or 0

	data.Stands["2_Slot 1"] = GetStandSlotData(target, "1", false)
	data.Stands["3_Slot 2"] = GetStandSlotData(target, "2", not target:GetAttribute("HasStandSlot2"))
	data.Stands["4_Slot 3"] = GetStandSlotData(target, "3", not target:GetAttribute("HasStandSlot3"))
	data.Stands["5_Slot 4"] = GetStandSlotData(target, "4", prestige < 15)
	data.Stands["6_Slot 5"] = GetStandSlotData(target, "5", prestige < 30)
	data.Stands["7_VIP Slot"] = GetStandSlotData(target, "VIP", not target:GetAttribute("IsVIP"))

	data.Styles["1_Active"] = { Name = target:GetAttribute("FightingStyle") or "None", Locked = false }
	data.Styles["2_Slot 1"] = { Name = target:GetAttribute("StoredStyle1") or "None", Locked = false }
	data.Styles["3_Slot 2"] = { Locked = not target:GetAttribute("HasStyleSlot2"), Name = target:GetAttribute("StoredStyle2") or "None" }
	data.Styles["4_Slot 3"] = { Locked = (not target:GetAttribute("HasStyleSlot3")) and (prestige < 15), Name = target:GetAttribute("StoredStyle3") or "None" }
	data.Styles["5_VIP Slot"] = { Locked = not target:GetAttribute("IsVIP"), Name = target:GetAttribute("StoredStyleVIP") or "None" }

	return data
end

AdminEditAction.OnServerEvent:Connect(function(player, action, targetName, arg1, arg2)
	local isStudio = RunService:IsStudio()
	local rank = player:GetRankInGroupAsync(GROUP_ID)
	local isModOrAdmin = ADMIN_RANKS[rank] or MOD_RANKS[rank] or isStudio
	if not isModOrAdmin then return end

	local target = FindPlayer(targetName)
	if not target then return end

	if action == "AddItem" then
		local properName = GetProperItemName(arg1)
		if properName then
			local attrName = properName:gsub("[^%w]", "") .. "Count"
			target:SetAttribute(attrName, (target:GetAttribute(attrName) or 0) + 1)
			AdminEditUI:FireClient(player, target.Name, FetchPlayerData(target))
		end
	elseif action == "RemoveItem" then
		local properName = GetProperItemName(arg1)
		if properName then
			local attrName = properName:gsub("[^%w]", "") .. "Count"
			local current = target:GetAttribute(attrName) or 0
			if current > 0 then
				target:SetAttribute(attrName, current - 1)
				AdminEditUI:FireClient(player, target.Name, FetchPlayerData(target))
			end
		end
	elseif action == "UpdateStand" then
		local slot = arg1
		local updateData = arg2
		if string.find(slot, "Active") then
			if updateData.FusedWith and updateData.FusedWith ~= "" then
				local s1Proper = GetProperStandName(updateData.Name)
				local s2Proper = GetProperStandName(updateData.FusedWith)
				if s1Proper and s2Proper then
					target:SetAttribute("Active_FusedStand1", s1Proper)
					target:SetAttribute("Active_FusedStand2", s2Proper)
					target:SetAttribute("Active_FusedTrait1", GetProperTraitName(updateData.Trait1) or "None")
					target:SetAttribute("Active_FusedTrait2", GetProperTraitName(updateData.Trait2) or "None")
					target:SetAttribute("Stand", "Fused Stand")
					target:SetAttribute("StandTrait", "Fused")

					local statsList = {"Power", "Speed", "Range", "Durability", "Precision", "Potential"}
					local rankToNum = {["None"]=0, ["E"]=1, ["D"]=2, ["C"]=3, ["B"]=4, ["A"]=5, ["S"]=6}
					local numToRank = { [0]="None", [1]="E", [2]="D", [3]="C", [4]="B", [5]="A", [6]="S" }
					local baseData1 = StandData.Stands[s1Proper].Stats
					local baseData2 = StandData.Stands[s2Proper].Stats
					for _, stat in ipairs(statsList) do
						local v1 = rankToNum[baseData1[stat]] or 0
						local v2 = rankToNum[baseData2[stat]] or 0
						local avg = math.ceil((v1 + v2) / 2)
						target:SetAttribute("Stand_" .. stat, numToRank[avg] or "C")
					end
				end
			else
				local properName = GetProperStandName(updateData.Name)
				if properName then
					GrantStand(target, properName)
					local pTrait = GetProperTraitName(updateData.Trait1)
					if pTrait then target:SetAttribute("StandTrait", pTrait) end
				end
			end
		else
			local slotNum = string.match(slot, "Slot (%d+)")
			if string.find(slot, "VIP") then slotNum = "VIP" end
			if slotNum then
				if updateData.FusedWith and updateData.FusedWith ~= "" then
					local s1Proper = GetProperStandName(updateData.Name)
					local s2Proper = GetProperStandName(updateData.FusedWith)
					if s1Proper and s2Proper then
						target:SetAttribute("StoredStand"..slotNum.."_FusedStand1", s1Proper)
						target:SetAttribute("StoredStand"..slotNum.."_FusedStand2", s2Proper)
						target:SetAttribute("StoredStand"..slotNum.."_FusedTrait1", GetProperTraitName(updateData.Trait1) or "None")
						target:SetAttribute("StoredStand"..slotNum.."_FusedTrait2", GetProperTraitName(updateData.Trait2) or "None")
						target:SetAttribute("StoredStand"..slotNum, "Fused Stand")
						target:SetAttribute("StoredStand"..slotNum.."_Trait", "Fused")
					end
				else
					local properName = GetProperStandName(updateData.Name) or "None"
					target:SetAttribute("StoredStand"..slotNum, properName)
					target:SetAttribute("StoredStand"..slotNum.."_Trait", GetProperTraitName(updateData.Trait1) or "None")
				end
			end
		end
		AdminEditUI:FireClient(player, target.Name, FetchPlayerData(target))
	elseif action == "ClearStand" then
		local slot = arg1
		if string.find(slot, "Active") then
			GrantStand(target, "None")
			target:SetAttribute("Stand", "None")
			target:SetAttribute("StandTrait", "None")
			target:SetAttribute("Active_FusedStand1", "None")
			target:SetAttribute("Active_FusedStand2", "None")
			target:SetAttribute("Active_FusedTrait1", "None")
			target:SetAttribute("Active_FusedTrait2", "None")
		else
			local slotNum = string.match(slot, "Slot (%d+)")
			if string.find(slot, "VIP") then slotNum = "VIP" end
			if slotNum then
				target:SetAttribute("StoredStand"..slotNum, "None")
				target:SetAttribute("StoredStand"..slotNum.."_Trait", "None")
				target:SetAttribute("StoredStand"..slotNum.."_FusedStand1", "None")
				target:SetAttribute("StoredStand"..slotNum.."_FusedStand2", "None")
				target:SetAttribute("StoredStand"..slotNum.."_FusedTrait1", "None")
				target:SetAttribute("StoredStand"..slotNum.."_FusedTrait2", "None")
			end
		end
		AdminEditUI:FireClient(player, target.Name, FetchPlayerData(target))
	elseif action == "UpdateStyle" then
		local slot = arg1
		local styleName = GetProperStyleName(arg2)
		if styleName then
			if string.find(slot, "Active") then
				target:SetAttribute("FightingStyle", styleName)
			else
				local slotNum = string.match(slot, "Slot (%d+)")
				if string.find(slot, "VIP") then slotNum = "VIP" end
				if slotNum then
					target:SetAttribute("StoredStyle"..slotNum, styleName)
				end
			end
		end
		AdminEditUI:FireClient(player, target.Name, FetchPlayerData(target))
	elseif action == "ClearStyle" then
		local slot = arg1
		if string.find(slot, "Active") then
			target:SetAttribute("FightingStyle", "None")
		else
			local slotNum = string.match(slot, "Slot (%d+)")
			if string.find(slot, "VIP") then slotNum = "VIP" end
			if slotNum then
				target:SetAttribute("StoredStyle"..slotNum, "None")
			end
		end
		AdminEditUI:FireClient(player, target.Name, FetchPlayerData(target))
	end
end)

local function ExecuteCommandLocally(cmd, parts, adminPlayer, isFromCrossServer, senderName)
	local targetStr = string.lower(parts[2] or "")
	local targets = {}
	local displayTarget = ""
	local actualSenderName = senderName or (adminPlayer and adminPlayer.Name) or "System"

	if cmd ~= "!deletegang" and cmd ~= "!announcement" and cmd ~= "!addrep" and cmd ~= "!spawnwb" then
		if targetStr == "@all" then
			targets = Players:GetPlayers()
			displayTarget = "everyone in the game"
		elseif targetStr == "@server" then
			targets = Players:GetPlayers()
			displayTarget = "everyone in the server"
		elseif targetStr == "@self" or targetStr == "@me" then
			if adminPlayer then
				table.insert(targets, adminPlayer)
				displayTarget = "yourself"
			end
		else
			if isFromCrossServer then return end 
			local p = FindPlayer(parts[2])
			if p then
				table.insert(targets, p)
				displayTarget = p.Name
			end
		end

		if #targets == 0 then
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Player not found.</font>") end
			return
		end
	end

	local isMassEvent = (targetStr == "@all" or targetStr == "@server" or isFromCrossServer)
	local eventTag = (isFromCrossServer or targetStr == "@all") and "GLOBAL EVENT" or "SERVER EVENT"

	if cmd == "!edit" then
		if adminPlayer then
			if #targets == 1 then
				AdminEditUI:FireClient(adminPlayer, targets[1].Name, FetchPlayerData(targets[1]))
				SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Opened Edit Menu for " .. targets[1].Name .. ".</font>")
			else
				SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: !edit requires exactly one player target.</font>")
			end
		end
		return
	end

	if cmd == "!announcement" then
		local announcementText = table.concat(parts, " ", 2)
		for _, p in ipairs(Players:GetPlayers()) do
			SendAdminNotice(p, "\n<font color='#FF55FF' size='16'><b>[GLOBAL ANNOUNCEMENT - " .. actualSenderName .. "]</b></font>\n<font color='#FFFFFF'>" .. announcementText .. "</font>\n")
		end
		if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Global announcement broadcasted!</font>") end

	elseif cmd == "!spawnwb" then
		local forceEvent = Network:FindFirstChild("AdminForceSpawnWB")
		if forceEvent then
			local rawBossName = parts[2] and table.concat(parts, " ", 2) or nil
			local properBossName = GetProperWorldBossName(rawBossName)

			forceEvent:Fire(properBossName)

			if adminPlayer then 
				if properBossName then
					SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Force-spawned specific World Boss ("..properBossName..") globally!</font>") 
				else
					SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Force-spawned a random World Boss globally!</font>") 
				end
			end
		end

	elseif cmd == "!additem" then
		local amount = tonumber(parts[3])
		local itemStartIndex = 3
		if amount then itemStartIndex = 4 else amount = 1 end
		local rawName = table.concat(parts, " ", itemStartIndex)
		local properName = GetProperItemName(rawName)

		if properName then
			for _, target in ipairs(targets) do
				local attrName = properName:gsub("[^%w]", "") .. "Count"
				target:SetAttribute(attrName, (target:GetAttribute(attrName) or 0) + amount)
				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> You received " .. amount .. "x " .. properName .. "!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Gave " .. amount .. "x " .. properName .. " to " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Item '" .. rawName .. "' does not exist.</font>") end
		end

	elseif cmd == "!addindex" then
		local rawName = table.concat(parts, " ", 3)
		local isAll = (string.lower(rawName) == "@all")
		local properName = not isAll and GetProperStandName(rawName) or nil

		if isAll or properName then
			for _, target in ipairs(targets) do
				local current = target:GetAttribute("UnlockedIndex") or ""
				local tbl = string.split(current, ",")
				local tblMap = {}
				for _, v in ipairs(tbl) do if v ~= "" then tblMap[v] = true end end
				local addedCount = 0

				if isAll then
					for sName, _ in pairs(StandData.Stands) do
						if sName ~= "Fused Stand" and sName ~= "None" and sName ~= "Unknown" and not tblMap[sName] then
							tblMap[sName] = true
							addedCount += 1
						end
					end
				else
					if not tblMap[properName] then
						tblMap[properName] = true
						addedCount += 1
					end
				end

				if addedCount > 0 then
					local newTbl = {}
					for k, _ in pairs(tblMap) do table.insert(newTbl, k) end
					target:SetAttribute("UnlockedIndex", table.concat(newTbl, ","))
				end
				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> Your Stand Index was updated!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Updated Stand Index for " .. displayTarget .. ".</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Stand '" .. rawName .. "' does not exist.</font>") end
		end

	elseif cmd == "!addfusionindex" then
		local rawContent = table.concat(parts, " ", 3)
		local isAllTotal = (string.lower(string.gsub(rawContent, "^%s*(.-)%s*$", "%1")) == "@all")

		local standParts = string.split(rawContent, "/")
		local s1Raw, s2Raw

		if isAllTotal then
			s1Raw, s2Raw = "@all", "@all"
		else
			s1Raw = standParts[1] and string.gsub(standParts[1], "^%s*(.-)%s*$", "%1")
			s2Raw = standParts[2] and string.gsub(standParts[2], "^%s*(.-)%s*$", "%1")

			if not s2Raw and s1Raw and string.match(string.lower(s1Raw), " @all$") then
				s1Raw = string.gsub(s1Raw, "%s*@all$", "")
				s2Raw = "@all"
			end
		end

		local isAllS1 = (string.lower(s1Raw or "") == "@all")
		local isAllS2 = (string.lower(s2Raw or "") == "@all")

		local s1Proper = not isAllS1 and GetProperStandName(s1Raw) or nil
		local s2Proper = not isAllS2 and GetProperStandName(s2Raw) or nil

		if (isAllS1 or s1Proper) and (isAllS2 or s2Proper) then
			for _, target in ipairs(targets) do
				local current = target:GetAttribute("UnlockedFusions") or ""
				local tbl = string.split(current, ",")
				local tblMap = {}
				for _, v in ipairs(tbl) do if v ~= "" then tblMap[v] = true end end
				local addedCount = 0

				local list1 = isAllS1 and StandData.Stands or { [s1Proper] = true }
				local list2 = isAllS2 and StandData.Stands or { [s2Proper] = true }

				for st1, _ in pairs(list1) do
					if st1 == "Fused Stand" or st1 == "None" or st1 == "Unknown" then continue end
					for st2, _ in pairs(list2) do
						if st2 == "Fused Stand" or st2 == "None" or st2 == "Unknown" then continue end
						local fusionStr = st1 .. "|" .. st2
						if not tblMap[fusionStr] then
							tblMap[fusionStr] = true
							addedCount += 1
						end
					end
				end

				if addedCount > 0 then
					local newTbl = {}
					for k, _ in pairs(tblMap) do table.insert(newTbl, k) end
					target:SetAttribute("UnlockedFusions", table.concat(newTbl, ","))
				end
				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> Your Fusion Index was updated!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Updated Fusion Index for " .. displayTarget .. ".</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Usage: !addfusionindex [target] Stand1 / Stand2 (or '@all' or 'Stand1 @all')</font>") end
		end

	elseif cmd == "!addpass" then
		local rawName = table.concat(parts, " ", 3)
		local properAttr = GetProperPassAttr(rawName)

		if properAttr then
			for _, target in ipairs(targets) do
				target:SetAttribute(properAttr, true)
				SendAdminNotice(target, "<font color='#55FF55'>🎁 An Admin/Mod has granted you the " .. properAttr .. " GamePass!</font>")
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Gave GamePass '" .. properAttr .. "' to " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Invalid Pass. Try: speed, inventory, drops, autotrain, slot2, slot3.</font>") end
		end

	elseif cmd == "!setstand" then
		local rawName = table.concat(parts, " ", 3)
		local properName = GetProperStandName(rawName)

		if properName then
			for _, target in ipairs(targets) do
				GrantStand(target, properName)
				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> Your Stand was set to: " .. properName .. "!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Set Stand " .. properName .. " for " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Stand '" .. rawName .. "' does not exist.</font>") end
		end

	elseif cmd == "!setfusedstand" then
		local rawContent = table.concat(parts, " ", 3)
		local standParts = string.split(rawContent, "/")
		local s1Raw = standParts[1] and string.gsub(standParts[1], "^%s*(.-)%s*$", "%1")
		local s2Raw = standParts[2] and string.gsub(standParts[2], "^%s*(.-)%s*$", "%1")

		local s1Proper = GetProperStandName(s1Raw)
		local s2Proper = GetProperStandName(s2Raw)

		if s1Proper and s2Proper then
			for _, target in ipairs(targets) do
				target:SetAttribute("Active_FusedStand1", s1Proper)
				target:SetAttribute("Active_FusedStand2", s2Proper)
				target:SetAttribute("Active_FusedTrait1", target:GetAttribute("Active_FusedTrait1") or "None")
				target:SetAttribute("Active_FusedTrait2", target:GetAttribute("Active_FusedTrait2") or "None")
				target:SetAttribute("Stand", "Fused Stand")
				target:SetAttribute("StandTrait", "Fused")

				local statsList = {"Power", "Speed", "Range", "Durability", "Precision", "Potential"}
				local rankToNum = {["None"]=0, ["E"]=1, ["D"]=2, ["C"]=3, ["B"]=4, ["A"]=5, ["S"]=6}
				local numToRank = { [0]="None", [1]="E", [2]="D", [3]="C", [4]="B", [5]="A", [6]="S" }
				local baseData1 = StandData.Stands[s1Proper].Stats
				local baseData2 = StandData.Stands[s2Proper].Stats
				for _, stat in ipairs(statsList) do
					local v1 = rankToNum[baseData1[stat]] or 0
					local v2 = rankToNum[baseData2[stat]] or 0
					local avg = math.ceil((v1 + v2) / 2)
					target:SetAttribute("Stand_" .. stat, numToRank[avg] or "C")
				end
				SendAdminNotice(target, "<font color='#A020F0'>System set your Fused Stand: " .. s1Proper .. " / " .. s2Proper .. "!</font>")
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Set Fused Stand for " .. displayTarget .. ".</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Usage: !setfusedstand [target] Stand1 / Stand2</font>") end
		end

	elseif cmd == "!setfusedtrait" then
		local rawContent = table.concat(parts, " ", 3)
		local traitParts = string.split(rawContent, "/")
		local t1Raw = traitParts[1] and string.gsub(traitParts[1], "^%s*(.-)%s*$", "%1")
		local t2Raw = traitParts[2] and string.gsub(traitParts[2], "^%s*(.-)%s*$", "%1")

		local t1Proper = GetProperTraitName(t1Raw)
		local t2Proper = GetProperTraitName(t2Raw)

		if t1Proper and t2Proper then
			for _, target in ipairs(targets) do
				if target:GetAttribute("Stand") == "Fused Stand" then
					target:SetAttribute("Active_FusedTrait1", t1Proper)
					target:SetAttribute("Active_FusedTrait2", t2Proper)
					SendAdminNotice(target, "<font color='#A020F0'>System set your Fused Traits: " .. t1Proper .. " & " .. t2Proper .. "!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Set Fused Traits for " .. displayTarget .. ".</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Usage: !setfusedtrait [target] Trait1 / Trait2</font>") end
		end

	elseif cmd == "!setstyle" then
		local rawName = table.concat(parts, " ", 3)
		local properName = GetProperStyleName(rawName)

		if properName then
			for _, target in ipairs(targets) do
				target:SetAttribute("FightingStyle", properName)
				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> Your Fighting Style was set to: " .. properName .. "!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Set Fighting Style " .. properName .. " for " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Fighting Style '" .. rawName .. "' does not exist.</font>") end
		end

	elseif cmd == "!settrait" then
		local rawName = parts[3] or ""
		local properName = GetProperTraitName(rawName)

		if properName then
			for _, target in ipairs(targets) do
				target:SetAttribute("StandTrait", properName)
				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> Your Stand Trait was set to: " .. properName .. "!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Set Stand Trait " .. properName .. " for " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Trait '" .. rawName .. "' does not exist.</font>") end
		end

	elseif cmd == "!addstat" then
		local rawStat = parts[3]
		local properStat = GetProperStatName(rawStat)
		local amount = tonumber(parts[4]) or 1

		if properStat then
			for _, target in ipairs(targets) do
				if properStat == "Yen" or properStat == "Prestige" or properStat == "Elo" then
					local leaderstats = target:FindFirstChild("leaderstats")
					if leaderstats and leaderstats:FindFirstChild(properStat) then
						leaderstats[properStat].Value += amount
					end
				else
					local current = target:GetAttribute(properStat) or 0
					target:SetAttribute(properStat, current + amount)
				end

				if isMassEvent and target ~= adminPlayer then
					SendAdminNotice(target, "<font color='#FFD700'><b>" .. eventTag .. ":</b> You received " .. amount .. " " .. properStat .. "!</font>")
				end
			end
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Added " .. amount .. " " .. properStat .. " to " .. displayTarget .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Stat '" .. rawStat .. "' does not exist.</font>") end
		end

	elseif cmd == "!joingang" then
		local rawGangName = table.concat(parts, " ", 3)
		local gangKey = string.lower(rawGangName)
		local success, gangData = pcall(function() return GangStore:GetAsync(gangKey) end)

		if success and gangData then
			for _, target in ipairs(targets) do
				local uidStr = tostring(target.UserId)
				local prestigeVal = target:WaitForChild("leaderstats") and target.leaderstats:WaitForChild("Prestige").Value or 0

				local oldGangKey = target:GetAttribute("Gang")
				if oldGangKey and oldGangKey ~= "None" then
					GangStore:UpdateAsync(oldGangKey, function(oldData)
						if oldData then
							oldData.Members[uidStr] = nil
							oldData.MemberCount = GetDictSize(oldData.Members)
						end
						return oldData
					end)
					pcall(function() MessagingService:PublishAsync(GANG_TOPIC, { Action = "Refresh", GangKey = oldGangKey }) end)
				end

				GangStore:UpdateAsync(gangKey, function(newData)
					if newData then
						newData.Members[uidStr] = { Name = target.Name, Role = "Grunt", Prestige = prestigeVal, LastOnline = math.floor(workspace:GetServerTimeNow()), Contribution = 0, PlayTime = target:GetAttribute("PlayTime") or 0, UserId = target.UserId }
						newData.MemberCount = GetDictSize(newData.Members)
					end
					return newData
				end)

				target:SetAttribute("Gang", gangKey)
				target:SetAttribute("GangRole", "Grunt")
				SendAdminNotice(target, "<font color='#FFD700'>System force-joined you to " .. gangData.Name .. "!</font>")
			end

			pcall(function() MessagingService:PublishAsync(GANG_TOPIC, { Action = "Refresh", GangKey = gangKey }) end)

			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Force-joined " .. displayTarget .. " to " .. gangData.Name .. ".</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Gang '" .. rawGangName .. "' not found in DataStore.</font>") end
		end

	elseif cmd == "!addrep" then
		local amount = tonumber(parts[2])
		local rawGangName = table.concat(parts, " ", 3)
		local gangKey = string.lower(rawGangName)

		if not amount or not gangKey then
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>Usage: !addrep [Amount] [GangName]</font>") end
			return
		end

		local s, d = pcall(function() return GangStore:GetAsync(gangKey) end)
		if s and d then
			pcall(function()
				GangStore:UpdateAsync(gangKey, function(oldData)
					if oldData then oldData.Rep = (oldData.Rep or 0) + amount end
					return oldData
				end)
				MessagingService:PublishAsync(GANG_TOPIC, { Action = "Refresh", GangKey = gangKey })
			end)
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Added " .. amount .. " Rep to " .. d.Name .. "!</font>") end
		else
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Gang '" .. rawGangName .. "' not found.</font>") end
		end

	elseif cmd == "!promote" then
		local rankNum = tonumber(parts[3])
		local roles = { [1] = "Grunt", [2] = "Caporegime", [3] = "Consigliere", [4] = "Boss" }
		local newRole = roles[rankNum]

		if not newRole then
			if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#FF5555'>System Error: Rank must be 1-4.</font>") end
			return
		end

		for _, target in ipairs(targets) do
			local gangKey = target:GetAttribute("Gang")
			if gangKey and gangKey ~= "None" then
				local success, gangData = pcall(function() return GangStore:GetAsync(gangKey) end)
				if success and gangData then
					local uidStr = tostring(target.UserId)
					if gangData.Members[uidStr] then
						if newRole == "Boss" or newRole == "Consigliere" then
							for u, m in pairs(gangData.Members) do
								if m.Role == newRole and u ~= uidStr then
									m.Role = "Grunt"
									local oldMember = Players:GetPlayerByUserId(tonumber(u))
									if oldMember then 
										oldMember:SetAttribute("GangRole", "Grunt")
										SendAdminNotice(oldMember, "<font color='#FF5555'>System demoted your Gang Rank.</font>")
									end
								end
							end
						end
						gangData.Members[uidStr].Role = newRole
						pcall(function() 
							GangStore:UpdateAsync(gangKey, function(oldData) 
								if oldData then oldData.Members = gangData.Members end
								return oldData 
							end) 
							MessagingService:PublishAsync(GANG_TOPIC, { Action = "Refresh", GangKey = gangKey })
						end)

						target:SetAttribute("GangRole", newRole)
						SendAdminNotice(target, "<font color='#FFD700'>System set your Gang Rank to " .. newRole .. "!</font>")
					end
				end
			end
		end
		if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Promoted " .. displayTarget .. " to " .. newRole .. ".</font>") end

	elseif cmd == "!kickgang" then
		for _, target in ipairs(targets) do
			local gangKey = target:GetAttribute("Gang")
			if gangKey and gangKey ~= "None" then
				pcall(function() 
					GangStore:UpdateAsync(gangKey, function(oldData)
						if oldData and oldData.Members[tostring(target.UserId)] then
							oldData.Members[tostring(target.UserId)] = nil
							oldData.MemberCount = GetDictSize(oldData.Members)
						end
						return oldData
					end) 
					MessagingService:PublishAsync(GANG_TOPIC, { Action = "Refresh", GangKey = gangKey })
				end)
				target:SetAttribute("Gang", "None")
				target:SetAttribute("GangRole", "None")
				SendAdminNotice(target, "<font color='#FF5555'>System forcefully kicked you from your gang.</font>")
			end
		end
		if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Kicked " .. displayTarget .. " from their gang.</font>") end

	elseif cmd == "!deletegang" then
		local rawGangName = table.concat(parts, " ", 2)
		local gangKey = string.lower(rawGangName)

		local wipeEvent = ReplicatedStorage:FindFirstChild("AdminForceWipeGang")
		if wipeEvent then
			wipeEvent:Fire(gangKey, rawGangName)
		end

		if adminPlayer then SendAdminNotice(adminPlayer, "<font color='#55FF55'>System: Obliterated gang '" .. rawGangName .. "' from all servers and leaderboards.</font>") end
	end
end

pcall(function()
	MessagingService:SubscribeAsync(GLOBAL_TOPIC, function(message)
		local data = message.Data

		if data.Cmd == "!bring_req" then
			local t = FindPlayer(data.TargetName)
			if t then
				SendAdminNotice(t, "<font color='#FF5555'>System " .. tostring(data.SenderName) .. " is forcing you to their server...</font>")
				pcall(function()
					TeleportService:TeleportToPlaceInstance(game.PlaceId, data.ServerId, t)
				end)

				pcall(function()
					MessagingService:PublishAsync(GLOBAL_TOPIC, {
						Cmd = "!bring_res",
						TargetName = t.Name,
						AdminId = data.AdminId
					})
				end)
			end
			return
		elseif data.Cmd == "!bring_res" then
			local admin = Players:GetPlayerByUserId(data.AdminId)
			if admin then
				SendAdminNotice(admin, "<font color='#55FF55'>System: Target " .. data.TargetName .. " found! Teleporting them to your server...</font>")
			end
			return
		elseif data.Cmd == "!goto_req" then
			local t = FindPlayer(data.TargetName)
			if t then
				pcall(function()
					MessagingService:PublishAsync(GLOBAL_TOPIC, {
						Cmd = "!goto_res",
						TargetServer = game.JobId,
						AdminId = data.AdminId
					})
				end)
			end
			return
		elseif data.Cmd == "!goto_res" then
			local admin = Players:GetPlayerByUserId(data.AdminId)
			if admin then
				SendAdminNotice(admin, "<font color='#55FF55'>System: Target found! Teleporting to their server...</font>")
				pcall(function()
					TeleportService:TeleportToPlaceInstance(game.PlaceId, data.TargetServer, admin)
				end)
			end
			return
		end

		if data.ServerId == game.JobId then return end 

		ExecuteCommandLocally(data.Cmd, data.Parts, nil, true, data.SenderName)
	end)
end)

local validCmds = {
	["!additem"] = true, ["!setstand"] = true, ["!setstyle"] = true, ["!addstat"] = true,
	["!joingang"] = true, ["!promote"] = true, ["!deletegang"] = true, ["!spawnwb"] = true,
	["!kickgang"] = true, ["!settrait"] = true, ["!announcement"] = true,
	["!addpass"] = true, ["!addrep"] = true, ["!setfusedstand"] = true, ["!setfusedtrait"] = true,
	["!goto"] = true, ["!bring"] = true, ["!teleport"] = true, ["!edit"] = true,
	["!addindex"] = true, ["!addfusionindex"] = true
}

local modAllowedCmds = {
	["!additem"] = true, ["!setstand"] = true, ["!setstyle"] = true, ["!settrait"] = true,
	["!setfusedstand"] = true, ["!setfusedtrait"] = true, ["!goto"] = true, ["!bring"] = true,
	["!teleport"] = true, ["!addstat"] = true, ["!addpass"] = true, 
	["!deletegang"] = true, ["!promote"] = true, ["!announcement"] = true, ["!edit"] = true,
	["!addindex"] = true, ["!addfusionindex"] = true
}

local function OnPlayerAdded(player)
	player.Chatted:Connect(function(message)
		local isStudio = RunService:IsStudio()
		local rank = player:GetRankInGroup(GROUP_ID)

		local isFullAdmin = ADMIN_RANKS[rank] or isStudio
		local isMod = MOD_RANKS[rank] or isStudio
		local isAnnouncer = ANNOUNCER_RANKS[rank] or isStudio

		if not isFullAdmin and not isMod and not isAnnouncer then return end

		local parts = string.split(message, " ")
		local cmd = string.lower(parts[1])

		if not validCmds[cmd] then return end

		AdminLogger:Fire("Command", {
			Player = player.Name,
			Command = cmd,
			FullText = message
		})

		if isAnnouncer and not isFullAdmin and not isMod and cmd ~= "!announcement" then return end

		if isMod and not isFullAdmin and not modAllowedCmds[cmd] then
			SendAdminNotice(player, "<font color='#FF5555'>Mod Error: You lack permission for command " .. cmd .. "</font>")
			return
		end

		if #parts < 2 and cmd ~= "!spawnwb" and cmd ~= "!edit" then return end

		local targetStr = parts[2] and string.lower(parts[2]) or ""

		if isMod and not isFullAdmin and (targetStr == "@all" or targetStr == "@server") then
			SendAdminNotice(player, "<font color='#FF5555'>Mod Error: You cannot use mass targeting selectors (@all, @server).</font>")
			return
		end

		if cmd == "!goto" or cmd == "!teleport" or cmd == "!bring" then
			local targetName = parts[2]
			if not targetName then return end

			local targetPlayer = FindPlayer(targetName)
			if targetPlayer then
				SendAdminNotice(player, "<font color='#FFD700'>System: " .. targetPlayer.Name .. " is already in your current server.</font>")
			else
				pcall(function()
					MessagingService:PublishAsync(GLOBAL_TOPIC, {
						Cmd = (cmd == "!bring") and "!bring_req" or "!goto_req",
						TargetName = targetName,
						AdminId = player.UserId,
						ServerId = game.JobId,
						SenderName = player.Name
					})
				end)
				SendAdminNotice(player, "<font color='#FFD700'>System: Searching cross-servers for " .. targetName .. "...</font>")
			end
			return
		end

		local isGlobal = (targetStr == "@all") or (cmd == "!announcement") or (cmd == "!spawnwb") or (cmd == "!deletegang")

		if isGlobal then
			pcall(function()
				MessagingService:PublishAsync(GLOBAL_TOPIC, {
					Cmd = cmd,
					Parts = parts,
					ServerId = game.JobId,
					SenderName = player.Name
				})
			end)
		end

		ExecuteCommandLocally(cmd, parts, player, false, player.Name)
	end)
end

Players.PlayerAdded:Connect(OnPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	OnPlayerAdded(player)
end