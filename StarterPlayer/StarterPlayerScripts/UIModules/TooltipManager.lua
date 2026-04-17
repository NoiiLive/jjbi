-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local TooltipManager = {}

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))

local tooltip, tooltipText, sizeConstraint

function TooltipManager.Init(screenGui)
	tooltip = screenGui:WaitForChild("TooltipFrame")
	tooltipText = tooltip:WaitForChild("TooltipText")
	sizeConstraint = tooltip:WaitForChild("UISizeConstraint")

	game:GetService("RunService").RenderStepped:Connect(function()
		if tooltip.Visible then
			local viewport = workspace.CurrentCamera.ViewportSize

			local maxW = math.min(300, viewport.X * 0.85)
			sizeConstraint.MaxSize = Vector2.new(maxW, viewport.Y * 0.9)

			local tWidth = tooltip.AbsoluteSize.X
			local tHeight = tooltip.AbsoluteSize.Y

			local targetX = mouse.X + 15
			local targetY = mouse.Y + 15

			if targetX + tWidth > viewport.X then
				targetX = mouse.X - tWidth - 15
			end
			if targetY + tHeight > viewport.Y then
				targetY = mouse.Y - tHeight - 15
			end

			local maxX = math.max(5, viewport.X - tWidth - 5)
			local maxY = math.max(5, viewport.Y - tHeight - 5)

			targetX = math.clamp(targetX, 5, maxX)
			targetY = math.clamp(targetY, 5, maxY)

			tooltip.Position = UDim2.new(0, targetX, 0, targetY)
		end
	end)
end

function TooltipManager.Show(textStr)
	tooltipText.Text = textStr or ""
	tooltip.Visible = true
end

function TooltipManager.Hide()
	tooltip.Visible = false
end

function TooltipManager.GetItemTooltip(itemName)
	if ItemData.Equipment[itemName] then
		local eq = ItemData.Equipment[itemName]
		local text = "<b><font color='#FFD700'>" .. itemName .. "</font></b>\n<i>" .. eq.Slot .. "</i> | <font color='#AAAAAA'>" .. (eq.Rarity or "Common") .. "</font>\n"
		text ..= "____________________\n\n"
		for stat, val in pairs(eq.Bonus) do
			text ..= "<font color='#55FF55'>+" .. val .. " " .. stat:gsub("_", " ") .. "</font>\n"
		end
		return text
	elseif ItemData.Consumables[itemName] then
		local cons = ItemData.Consumables[itemName]
		local desc = type(cons) == "table" and cons.Description or tostring(cons)
		local rarity = type(cons) == "table" and cons.Rarity or "Common"
		return "<b><font color='#FFD700'>" .. itemName .. "</font></b>\n<i>Consumable</i> | <font color='#AAAAAA'>" .. rarity .. "</font>\n____________________\n\n" .. desc
	end
	return "Unknown item."
end

function TooltipManager.GetSkillTooltip(skillName)
	local skill = SkillData.Skills[skillName]
	if skill then
		local text = "<b><font color='#FFD700'>" .. skillName .. "</font></b> (" .. skill.Type .. ")\n"
		text = text .. "" .. (skill.Description or "No description.") .. "\n\n"
		if skill.Mult > 0 then text = text .. "Multiplier: " .. skill.Mult .. "x\n" end

		text = text .. "Cost: "
		if skill.StaminaCost == 0 and skill.EnergyCost == 0 then
			text = text .. "<font color='#55FF55'>Free</font>"
		else
			if skill.StaminaCost > 0 then text = text .. "<font color='#FFD700'>" .. skill.StaminaCost .. " Stamina </font>" end
			if skill.EnergyCost > 0 then text = text .. "<font color='#55FFFF'>" .. skill.EnergyCost .. " Energy</font>" end
		end

		if skill.Cooldown and skill.Cooldown > 0 then
			text = text .. "\nCooldown: <font color='#FF5555'>" .. skill.Cooldown .. " turns</font>"
		end

		return text
	end
	return "Unknown skill."
end

function TooltipManager.GetIndexTooltip(abilityName, abilityType, rarity)
	local rarityDisplay = (rarity and rarity ~= "None") and rarity or abilityType
	local text = "<b><font color='#FFD700'>" .. abilityName .. "</font></b>\n<i>" .. abilityType .. "</i> | <font color='#AAAAAA'>" .. rarityDisplay .. "</font>\n____________________\n\n"

	local skills = {}
	for sName, sData in pairs(SkillData.Skills) do
		if sData.Requirement == abilityName then
			table.insert(skills, {Name = sName, Data = sData})
		end
	end

	table.sort(skills, function(a, b) return (a.Data.Order or 999) < (b.Data.Order or 999) end)

	if #skills == 0 then
		text = text .. "<font color='#AAAAAA'>No known abilities.</font>"
	else
		for i, skillInfo in ipairs(skills) do
			local sData = skillInfo.Data

			text = text .. "<b><font color='#55FF55'>[" .. skillInfo.Name .. "]</font></b>\n"

			local details = {}
			if sData.Mult and sData.Mult > 0 then 
				table.insert(details, "DMG: <font color='#FFFFFF'>" .. sData.Mult .. "x</font>") 
			end
			if sData.Cooldown and sData.Cooldown > 0 then 
				table.insert(details, "CD: <font color='#FFFFFF'>" .. sData.Cooldown .. " turns</font>") 
			end

			if #details > 0 then
				text = text .. "<font color='#AAAAAA'>  • " .. table.concat(details, " | ") .. "</font>\n"
			end

			if sData.Effect then
				local cleanEffectName = sData.Effect:gsub("_", " ")
				local effectText = cleanEffectName

				if sData.Duration and sData.Duration > 0 then
					effectText = effectText .. " (" .. sData.Duration .. " turns)"
				end
				text = text .. "<font color='#FFAA55'>  • Effect: " .. effectText .. "</font>\n"
			end

			if i < #skills then
				text = text .. "\n"
			end
		end
	end

	if abilityType == "Stand" then
		local totalValidFusions = 0
		local validStands = {}

		for sName, sData in pairs(StandData.Stands) do
			if sData.Part and sData.Part ~= "" and sData.Part ~= "None" then
				validStands[sName] = true
				totalValidFusions = totalValidFusions + 1
			end
		end

		local collectedFusions = 0
		local unlockedFusionsStr = player:GetAttribute("UnlockedFusions") or ""
		local seenFusions = {}

		if unlockedFusionsStr ~= "" then
			for _, fStr in ipairs(string.split(unlockedFusionsStr, ",")) do
				local parts = string.split(fStr, "|")
				if parts[1] == abilityName and validStands[parts[2]] then
					if not seenFusions[parts[2]] then
						seenFusions[parts[2]] = true
						collectedFusions = collectedFusions + 1
					end
				end
			end
		end

		if totalValidFusions > 0 then
			local completionRatio = math.clamp(collectedFusions / totalValidFusions, 0, 1)
			local currentDamageBonus = completionRatio * 0.01
			local formattedBonus = string.format("+%.3fx", currentDamageBonus)

			if collectedFusions >= totalValidFusions then
				text = text .. "\n\n<font color='#55FF55'>Fusions Collected: " .. collectedFusions .. " / " .. totalValidFusions .. " (" .. formattedBonus .. " Global DMG)</font>"
			else
				text = text .. "\n\n<font color='#AAAAAA'>Fusions Collected: " .. collectedFusions .. " / " .. totalValidFusions .. " (" .. formattedBonus .. " Global DMG)</font>"
			end
		end
	end

	return text
end

return TooltipManager