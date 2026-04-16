-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))

local collectionRemote = Network:FindFirstChild("CollectionAction")
if not collectionRemote then
	collectionRemote = Instance.new("RemoteEvent")
	collectionRemote.Name = "CollectionAction"
	collectionRemote.Parent = Network
end

local CollectionManager = {}

function CollectionManager.UnlockAbility(player, abilityName)
	if not abilityName or abilityName == "None" or abilityName == "Fused Stand" or abilityName == "Unknown" then return end

	local current = player:GetAttribute("UnlockedIndex") or ""
	local tbl = string.split(current, ",")
	if not table.find(tbl, abilityName) then
		if current == "" then
			player:SetAttribute("UnlockedIndex", abilityName)
		else
			player:SetAttribute("UnlockedIndex", current .. "," .. abilityName)
		end
	end
end

function CollectionManager.UnlockFusion(player, stand1, stand2)
	if not stand1 or stand1 == "None" or stand1 == "Fused Stand" or stand1 == "Unknown" then return end
	if not stand2 or stand2 == "None" or stand2 == "Fused Stand" or stand2 == "Unknown" then return end

	local fusionStr = stand1 .. "|" .. stand2
	local current = player:GetAttribute("UnlockedFusions") or ""
	local tbl = string.split(current, ",")

	if not table.find(tbl, fusionStr) then
		if current == "" then
			player:SetAttribute("UnlockedFusions", fusionStr)
		else
			player:SetAttribute("UnlockedFusions", current .. "," .. fusionStr)
		end
	end
end

function CollectionManager.UnlockTitle(player, titleName)
	if not GameData.Titles[titleName] then return end

	local current = player:GetAttribute("UnlockedTitles") or ""
	local tbl = string.split(current, ",")

	if not table.find(tbl, titleName) then
		if current == "" then
			player:SetAttribute("UnlockedTitles", titleName)
		else
			player:SetAttribute("UnlockedTitles", current .. "," .. titleName)
		end

		local notif = Network:FindFirstChild("NotificationEvent")
		if notif then
			local color = GameData.Titles[titleName].Color or "#FFFFFF"
			notif:FireClient(player, "<b>Title Unlocked: <font color='"..color.."'>" .. titleName .. "</font></b>")
		end
	end
end

function CollectionManager.RemoveTitle(player, titleName)
	local current = player:GetAttribute("UnlockedTitles") or ""
	local tbl = string.split(current, ",")
	local index = table.find(tbl, titleName)

	if index then
		table.remove(tbl, index)
		player:SetAttribute("UnlockedTitles", table.concat(tbl, ","))

		if player:GetAttribute("EquippedTitle") == titleName then
			player:SetAttribute("EquippedTitle", "None")
		end
	end
end

function CollectionManager.CheckRetroactiveIndex(player)
	local currentStand = player:GetAttribute("Stand")
	if currentStand == "Fused Stand" then
		local fs1 = player:GetAttribute("Active_FusedStand1")
		local fs2 = player:GetAttribute("Active_FusedStand2")
		CollectionManager.UnlockAbility(player, fs1)
		CollectionManager.UnlockAbility(player, fs2)
		CollectionManager.UnlockFusion(player, fs1, fs2)
	else
		CollectionManager.UnlockAbility(player, currentStand)
	end

	CollectionManager.UnlockAbility(player, player:GetAttribute("FightingStyle"))

	for i = 1, 5 do
		local stored = player:GetAttribute("StoredStand" .. i)
		if stored == "Fused Stand" then
			local fs1 = player:GetAttribute("StoredStand" .. i .. "_FusedStand1")
			local fs2 = player:GetAttribute("StoredStand" .. i .. "_FusedStand2")
			CollectionManager.UnlockAbility(player, fs1)
			CollectionManager.UnlockAbility(player, fs2)
			CollectionManager.UnlockFusion(player, fs1, fs2)
		else
			CollectionManager.UnlockAbility(player, stored)
		end
	end

	local storedVIP = player:GetAttribute("StoredStandVIP")
	if storedVIP == "Fused Stand" then
		local fs1 = player:GetAttribute("StoredStandVIP_FusedStand1")
		local fs2 = player:GetAttribute("StoredStandVIP_FusedStand2")
		CollectionManager.UnlockAbility(player, fs1)
		CollectionManager.UnlockAbility(player, fs2)
		CollectionManager.UnlockFusion(player, fs1, fs2)
	else
		CollectionManager.UnlockAbility(player, storedVIP)
	end

	for i = 1, 3 do
		CollectionManager.UnlockAbility(player, player:GetAttribute("StoredStyle" .. i))
	end
	CollectionManager.UnlockAbility(player, player:GetAttribute("StoredStyleVIP"))
end

function CollectionManager.CheckAutomaticTitles(player)
	if player:GetAttribute("IsVIP") then CollectionManager.UnlockTitle(player, "VIP") end

	local claimedIndices = string.split(player:GetAttribute("ClaimedIndexBonuses") or "", ",")
	if table.find(claimedIndices, "Part 1") then CollectionManager.UnlockTitle(player, "Phantom Blood") end
	if table.find(claimedIndices, "Part 2") then CollectionManager.UnlockTitle(player, "Battle Tendency") end
	if table.find(claimedIndices, "Part 3") then CollectionManager.UnlockTitle(player, "Stardust Crusader") end
	if table.find(claimedIndices, "Part 4") then CollectionManager.UnlockTitle(player, "Diamond is Unbreakable") end
	if table.find(claimedIndices, "Part 5") then CollectionManager.UnlockTitle(player, "Golden Wind") end
	if table.find(claimedIndices, "Part 6") then CollectionManager.UnlockTitle(player, "Stone Ocean") end
	if table.find(claimedIndices, "Part 7") then CollectionManager.UnlockTitle(player, "Steel Ball Run") end
	if table.find(claimedIndices, "Part 8") then CollectionManager.UnlockTitle(player, "JoJolion") end

	local prestige = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige") and player.leaderstats.Prestige.Value or 0
	if prestige >= 1 then CollectionManager.UnlockTitle(player, "Apprentice") end
	if prestige >= 15 then CollectionManager.UnlockTitle(player, "Master") end
	if prestige >= 30 then CollectionManager.UnlockTitle(player, "Grandmaster") end

	if player:GetAttribute("Stand") and player:GetAttribute("Stand") ~= "None" then
		CollectionManager.UnlockTitle(player, "Novice")
	end

	local gang = player:GetAttribute("Gang") or "None"
	if gang ~= "None" then CollectionManager.UnlockTitle(player, "Mobster") end

	local endless = player:GetAttribute("EndlessMaxMilestone") or 0
	if endless >= 10 then CollectionManager.UnlockTitle(player, "Endurance") end
	if endless >= 100 then CollectionManager.UnlockTitle(player, "Unyielding") end
	if endless >= 1000 then CollectionManager.UnlockTitle(player, "Immortal") end

	local raids = player:GetAttribute("RaidWins") or 0
	if raids >= 1 then CollectionManager.UnlockTitle(player, "Raider") end
	if raids >= 25 then CollectionManager.UnlockTitle(player, "Raid Veteran") end
	if raids >= 50 then CollectionManager.UnlockTitle(player, "Raid Expert") end
	if raids >= 100 then CollectionManager.UnlockTitle(player, "Raid God") end

	if (player:GetAttribute("WorldBossParticipations") or 0) >= 1 then CollectionManager.UnlockTitle(player, "Challenger") end
	if (player:GetAttribute("WorldBossKills") or 0) >= 1 then CollectionManager.UnlockTitle(player, "Slayer") end
	if (player:GetAttribute("ArenaWins") or 0) >= 1 then CollectionManager.UnlockTitle(player, "Gladiator") end
	if (player:GetAttribute("SBRWins") or 0) >= 1 then CollectionManager.UnlockTitle(player, "Champion") end

	local s0 = player:GetAttribute("Stand")
	local s1 = player:GetAttribute("StoredStand1")
	local s4 = player:GetAttribute("StoredStand4")
	local s5 = player:GetAttribute("StoredStand5")

	if s0 and s0 ~= "None" and s1 and s1 ~= "None" and s4 and s4 ~= "None" and s5 and s5 ~= "None" then
		CollectionManager.UnlockTitle(player, "Hoarder")
	end

	task.spawn(function()
		local success, rank = pcall(function() return player:GetRankInGroup(11280027) end)
		if success then
			local function CheckStaffRank(reqRanks, title)
				local hasRank = false
				for _, r in ipairs(reqRanks) do
					if rank == r then hasRank = true; break end
				end
				if hasRank then
					CollectionManager.UnlockTitle(player, title)
				else
					CollectionManager.RemoveTitle(player, title)
				end
			end

			CheckStaffRank({255, 11}, "Owner")
			CheckStaffRank({8}, "Admin")
			CheckStaffRank({7}, "Sr. Mod")
			CheckStaffRank({6}, "Moderator")
			CheckStaffRank({2}, "Helper")
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player:GetAttributeChangedSignal("DataLoaded"):Connect(function()
		if player:GetAttribute("DataLoaded") then
			CollectionManager.CheckRetroactiveIndex(player)
			CollectionManager.CheckAutomaticTitles(player)
		end
	end)

	player:GetAttributeChangedSignal("IsVIP"):Connect(function() CollectionManager.CheckAutomaticTitles(player) end)
	player:GetAttributeChangedSignal("ClaimedIndexBonuses"):Connect(function() CollectionManager.CheckAutomaticTitles(player) end)
	player:GetAttributeChangedSignal("Stand"):Connect(function() 
		CollectionManager.CheckRetroactiveIndex(player)
		CollectionManager.CheckAutomaticTitles(player) 
	end)
	player:GetAttributeChangedSignal("Active_FusedStand1"):Connect(function() CollectionManager.CheckRetroactiveIndex(player) end)
	player:GetAttributeChangedSignal("Active_FusedStand2"):Connect(function() CollectionManager.CheckRetroactiveIndex(player) end)
	player:GetAttributeChangedSignal("FightingStyle"):Connect(function() CollectionManager.CheckRetroactiveIndex(player) end)

	player:GetAttributeChangedSignal("Gang"):Connect(function() CollectionManager.CheckAutomaticTitles(player) end)
	player:GetAttributeChangedSignal("RaidWins"):Connect(function() CollectionManager.CheckAutomaticTitles(player) end)
	player:GetAttributeChangedSignal("EndlessMaxMilestone"):Connect(function() CollectionManager.CheckAutomaticTitles(player) end)
	player:GetAttributeChangedSignal("WorldBossParticipations"):Connect(function() CollectionManager.CheckAutomaticTitles(player) end)
	player:GetAttributeChangedSignal("WorldBossKills"):Connect(function() CollectionManager.CheckAutomaticTitles(player) end)
	player:GetAttributeChangedSignal("ArenaWins"):Connect(function() CollectionManager.CheckAutomaticTitles(player) end)
	player:GetAttributeChangedSignal("SBRWins"):Connect(function() CollectionManager.CheckAutomaticTitles(player) end)

	task.spawn(function()
		local ls = player:WaitForChild("leaderstats", 10)
		if ls then
			local p = ls:WaitForChild("Prestige", 5)
			if p then
				p.Changed:Connect(function() CollectionManager.CheckAutomaticTitles(player) end)
			end
		end
	end)
end)

collectionRemote.OnServerEvent:Connect(function(player, action, target)
	if action == "ToggleTitle" then
		local unlocked = string.split(player:GetAttribute("UnlockedTitles") or "", ",")
		if table.find(unlocked, target) then
			if player:GetAttribute("EquippedTitle") == target then
				player:SetAttribute("EquippedTitle", "None")
			else
				player:SetAttribute("EquippedTitle", target)
			end
		end
	elseif action == "ClaimIndex" then
		if target == "Event" then return end

		local unlockedIndex = string.split(player:GetAttribute("UnlockedIndex") or "", ",")
		local claimed = string.split(player:GetAttribute("ClaimedIndexBonuses") or "", ",")

		if table.find(claimed, target) then return end

		local hasAll = true
		for sName, sData in pairs(StandData.Stands) do
			if sData.Part == target and not table.find(unlockedIndex, sName) then hasAll = false; break end
		end
		if hasAll then
			for stName, stPart in pairs(GameData.StyleParts) do
				if stPart == target and not table.find(unlockedIndex, stName) then hasAll = false; break end
			end
		end

		if hasAll then
			if player:GetAttribute("ClaimedIndexBonuses") == "" or not player:GetAttribute("ClaimedIndexBonuses") then
				player:SetAttribute("ClaimedIndexBonuses", target)
			else
				player:SetAttribute("ClaimedIndexBonuses", player:GetAttribute("ClaimedIndexBonuses") .. "," .. target)
			end
			CollectionManager.CheckAutomaticTitles(player)
		end
	end
end)

return CollectionManager