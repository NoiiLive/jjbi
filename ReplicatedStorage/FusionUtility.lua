-- @ScriptType: ModuleScript
local FusionUtility = {}

function FusionUtility.CalculateFusedName(name1, name2)
	if not name1 or not name2 or name1 == "None" or name2 == "None" then return "Unknown Fusion" end

	if name1 == name2 then
		local baseStr, numStr = string.match(name1, "^(.*%D)(%d+)$")
		if baseStr and numStr then
			local combinedNum = tonumber(numStr) * 2
			return baseStr .. combinedNum
		end

		return "Dual " .. name1
	end

	local words1 = string.split(name1, " ")
	local words2 = string.split(name2, " ")

	local take1 = math.floor(#words1 / 2)
	if take1 < 1 then take1 = 1 end

	local take2 = math.ceil(#words2 / 2)
	if take2 < 1 then take2 = 1 end

	local part1 = {}
	for i = 1, take1 do table.insert(part1, words1[i]) end

	local part2 = {}
	local start2 = #words2 - take2 + 1
	for i = start2, #words2 do table.insert(part2, words2[i]) end

	return table.concat(part1, " ") .. " " .. table.concat(part2, " ")
end

function FusionUtility.CalculateFusedAbilities(stand1, stand2, SkillData)
	local function getStandSkills(sName)
		local valid = {}
		for n, s in pairs(SkillData.Skills) do
			if s.Requirement == sName then table.insert(valid, {Name = n, Data = s}) end
		end
		table.sort(valid, function(a, b) return (a.Data.Order or 99) < (b.Data.Order or 99) end)
		return valid
	end

	local skills1 = getStandSkills(stand1)
	local skills2 = getStandSkills(stand2)

	local finalSkills = {}

	local take1 = math.ceil(#skills1 / 2)
	for i = 1, take1 do 
		if skills1[i] then table.insert(finalSkills, skills1[i]) end 
	end

	local take2 = math.ceil(#skills2 / 2)
	local start2 = #skills2 - take2 + 1
	for i = start2, #skills2 do 
		if skills2[i] then table.insert(finalSkills, skills2[i]) end 
	end

	return finalSkills
end

return FusionUtility