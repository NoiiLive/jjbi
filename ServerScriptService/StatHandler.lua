-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local Network = ReplicatedStorage:WaitForChild("Network")

local UpgradeRemote = Network:FindFirstChild("UpgradeStat")
if not UpgradeRemote then
	UpgradeRemote = Instance.new("RemoteEvent")
	UpgradeRemote.Name = "UpgradeStat"
	UpgradeRemote.Parent = Network
end

UpgradeRemote.OnServerEvent:Connect(function(player, statToUpgrade, amount)
	local isBaseStat = GameData.BaseStats[statToUpgrade] ~= nil
	local isStandStat = table.find(GameData.StandStats, statToUpgrade) ~= nil

	if not isBaseStat and not isStandStat then return end

	local prestige = player.leaderstats.Prestige.Value
	local statCap = GameData.GetStatCap(prestige)
	local currentStat = player:GetAttribute(statToUpgrade) or 0

	if currentStat >= statCap then return end

	local currentXP = player:GetAttribute("XP") or 0
	local baseVal = 0

	if prestige == 0 then
		if isBaseStat then
			baseVal = GameData.BaseStats[statToUpgrade]
		else
			baseVal = 0 
		end
	else
		baseVal = prestige * 5
	end

	local upgradesToAttempt = 1
	if type(amount) == "number" then
		upgradesToAttempt = amount
	elseif amount == "MAX" then
		upgradesToAttempt = 9999
	end

	local upgradesDone = 0

	while upgradesDone < upgradesToAttempt and currentStat < statCap do
		local cost = GameData.CalculateStatCost(currentStat, baseVal, prestige)

		if currentXP >= cost then
			currentXP -= cost
			currentStat += 1
			upgradesDone += 1
		else
			break
		end
	end

	if upgradesDone > 0 then
		player:SetAttribute("XP", currentXP)
		player:SetAttribute(statToUpgrade, currentStat)
	end
end)

local UpgradeAllEvent = Network:FindFirstChild("UpgradeAllStats")
if not UpgradeAllEvent then
	UpgradeAllEvent = Instance.new("RemoteEvent")
	UpgradeAllEvent.Name = "UpgradeAllStats"
	UpgradeAllEvent.Parent = Network
end

UpgradeAllEvent.OnServerEvent:Connect(function(player, amount)
	if type(amount) ~= "number" or amount <= 0 then return end

	local prestigeObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
	local prestige = prestigeObj and prestigeObj.Value or 0
	local statCap = GameData.GetStatCap(prestige)

	local statsList = {
		"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower", 
		"Stand_Power_Val", "Stand_Speed_Val", "Stand_Range_Val", 
		"Stand_Durability_Val", "Stand_Precision_Val", "Stand_Potential_Val"
	}

	local totalUpgrades = 0

	for i = 1, amount do
		local didUpgradeThisRound = false

		for _, statName in ipairs(statsList) do
			local currentStat = player:GetAttribute(statName) or 1
			if currentStat >= statCap then continue end

			local cleanName = statName:gsub("_Val", "")
			local base = (prestige == 0) and (GameData.BaseStats[cleanName] or 0) or (prestige * 5)
			local cost = GameData.CalculateStatCost(currentStat, base, prestige)

			local currentXP = player:GetAttribute("XP") or 0
			if currentXP >= cost then
				player:SetAttribute("XP", currentXP - cost)
				player:SetAttribute(statName, currentStat + 1)
				didUpgradeThisRound = true
				totalUpgrades += 1
			end
		end
		if not didUpgradeThisRound then break end
	end

	local NotificationEvent = Network:FindFirstChild("NotificationEvent")
	if NotificationEvent then
		if totalUpgrades > 0 then
			NotificationEvent:FireClient(player, "<font color='#55FF55'>Equally leveled stats " .. totalUpgrades .. " total times!</font>") 
		else
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Not enough XP or stats are already maxed!</font>") 
		end
	end
end)