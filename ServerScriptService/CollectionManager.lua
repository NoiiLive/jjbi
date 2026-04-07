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
	if not abilityName or abilityName == "None" or abilityName == "Fused Stand" then return end

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

function CollectionManager.CheckRetroactiveIndex(player)
	CollectionManager.UnlockAbility(player, player:GetAttribute("Stand"))
	CollectionManager.UnlockAbility(player, player:GetAttribute("FightingStyle"))

	for i = 1, 5 do
		CollectionManager.UnlockAbility(player, player:GetAttribute("StoredStand" .. i))
	end
	CollectionManager.UnlockAbility(player, player:GetAttribute("StoredStandVIP"))

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

	if player:GetAttribute("Stand") and player:GetAttribute("Stand") ~= "None" then
		CollectionManager.UnlockTitle(player, "Novice")
	end

	if (player:GetAttribute("RaidWins") or 0) >= 10 then
		CollectionManager.UnlockTitle(player, "Raid Boss")
	end

	if (player:GetAttribute("EndlessMaxMilestone") or 0) >= 25 then
		CollectionManager.UnlockTitle(player, "Survivor")
	end

	if prestige >= 30 and player:GetAttribute("HasStandSlot2") and player:GetAttribute("HasStandSlot3") then
		CollectionManager.UnlockTitle(player, "Hoarder")
	end
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
	player:GetAttributeChangedSignal("FightingStyle"):Connect(function() CollectionManager.CheckRetroactiveIndex(player) end)
	player:GetAttributeChangedSignal("RaidWins"):Connect(function() CollectionManager.CheckAutomaticTitles(player) end)
	player:GetAttributeChangedSignal("EndlessMaxMilestone"):Connect(function() CollectionManager.CheckAutomaticTitles(player) end)

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