-- @ScriptType: ModuleScript
local SkillTreeHandler = {}

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))

local function GetTreeData(player, standName)
	if not player or not standName then return nil end
	local progressStr = player:GetAttribute("SkillTreeProgress") or "{}"
	local success, treeTable = pcall(function() return HttpService:JSONDecode(progressStr) end)

	if not success or type(treeTable) ~= "table" then return nil end
	return treeTable[standName]
end

function SkillTreeHandler.GetDamageMultiplier(player, standName)
	local powerStarts = { E = 1.0, D = 1.1, C = 1.2, B = 1.3, A = 1.4, S = 1.5 }

	local powerRank = (StandData.Stands[standName] and StandData.Stands[standName].Stats and StandData.Stands[standName].Stats.Power) or "E"
	local base = powerStarts[powerRank] or 1.0

	local treeData = GetTreeData(player, standName)
	local upgrades = treeData and treeData.DamageUpgrades or 0

	local mult = base
	for i = 1, upgrades do
		if mult < 2.0 then mult += 0.1
		elseif mult < 3.0 then mult += 0.25
		elseif mult < 4.0 then mult += 0.5
		elseif mult < 5.0 then mult += 1.0 end
	end

	return math.floor(mult * 100 + 0.5) / 100
end

function SkillTreeHandler.HasPassive(player, standName, passiveKey)
	local treeData = GetTreeData(player, standName)
	if not treeData or type(treeData.Passives) ~= "table" then return false end

	return treeData.Passives["Passive_" .. passiveKey] == true
end

function SkillTreeHandler.HasSkill(player, standName, skillKey)
	local treeData = GetTreeData(player, standName)
	if not treeData or type(treeData.UnlockedSkills) ~= "table" then return false end

	return treeData.UnlockedSkills["Skill_" .. skillKey] == true
end

return SkillTreeHandler