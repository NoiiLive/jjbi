-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local InventoryTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))

local pStatsContainer, sStatsContainer, equipContainer, playerConsContainer, standConsContainer
local standStorageContainer, styleStorageContainer, autoSellContainer
local capacityLabel
local statLabels = {}

local standLabel, styleLabel, weaponLabel, accLabel, xpLabelP, xpLabelS, yenLabel
local standBox, styleBox, weaponBox, accBox
local standLockBtn, styleLockBtn

local currentlyHoveredStat = nil
local currentlyHoveredUpgrade = false
local cachedTooltipMgr = nil

local targetAutoStand = "Any"
local targetAutoTrait = "Any"
local currentUpgradeAmount = 1

local rarityColors = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(50, 100, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythical = Color3.fromRGB(255, 50, 50),
	Unique = Color3.fromRGB(215, 69, 255)
}

local raritySortTiers = { Unique = 1000, Mythical = 2000, Legendary = 3000, Rare = 4000, Uncommon = 5000, Common = 6000 }

local playerStatsList = {"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower"}
local standStatsList = {"Stand_Power_Val", "Stand_Speed_Val", "Stand_Range_Val", "Stand_Durability_Val", "Stand_Precision_Val", "Stand_Potential_Val"}
local allStatsToUpgrade = {"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower", "Stand_Power_Val", "Stand_Speed_Val", "Stand_Range_Val", "Stand_Durability_Val", "Stand_Precision_Val", "Stand_Potential_Val"}

local KnownItems = {}
for itemName, _ in pairs(ItemData.Consumables) do table.insert(KnownItems, itemName) end
for eqName, _ in pairs(ItemData.Equipment) do table.insert(KnownItems, eqName) end

local function GetCombinedBonus(statName)
	local wpn = player:GetAttribute("EquippedWeapon") or "None"
	local acc = player:GetAttribute("EquippedAccessory") or "None"
	local style = player:GetAttribute("FightingStyle") or "None"
	local bonus = 0

	if ItemData.Equipment[wpn] and ItemData.Equipment[wpn].Bonus[statName] then bonus += ItemData.Equipment[wpn].Bonus[statName] end
	if ItemData.Equipment[acc] and ItemData.Equipment[acc].Bonus[statName] then bonus += ItemData.Equipment[acc].Bonus[statName] end
	if GameData.StyleBonuses and GameData.StyleBonuses[style] and GameData.StyleBonuses[style][statName] then bonus += GameData.StyleBonuses[style][statName] end

	return bonus
end

local function GetUpgradeCostForAmount(currentStat, baseVal, prestige, maxCap, amount)
	if amount == "MAX" then return 0 end
	local cost = 0
	local added = 0
	for i = 0, amount - 1 do
		if currentStat + added >= maxCap then break end
		cost += GameData.CalculateStatCost(currentStat + added, baseVal, prestige)
		added += 1
	end
	return cost
end

local function UpdateStatTooltip()
	if not currentlyHoveredStat then return end
	local statName = currentlyHoveredStat
	local base = player:GetAttribute(statName) or 1
	local function getAttr(name) return player:GetAttribute(name) or 0 end

	local total = base
	local cleanName = statName:gsub("_Val", "")
	local desc = GameData.StatDescriptions and GameData.StatDescriptions[cleanName] or ""

	if statName == "Health" then total = base + GetCombinedBonus("Health")
	elseif statName == "Strength" then total = base + getAttr("Stand_Power_Val") + GetCombinedBonus("Strength") + GetCombinedBonus("Stand_Power")
	elseif statName == "Defense" then total = base + getAttr("Stand_Durability_Val") + GetCombinedBonus("Defense") + GetCombinedBonus("Stand_Durability")
	elseif statName == "Speed" then total = base + getAttr("Stand_Speed_Val") + GetCombinedBonus("Speed") + GetCombinedBonus("Stand_Speed")
	elseif statName == "Stamina" then total = base + GetCombinedBonus("Stamina")
	elseif statName == "Willpower" then total = base + GetCombinedBonus("Willpower")
	elseif statName == "Stand_Power_Val" then total = getAttr("Strength") + base + GetCombinedBonus("Strength") + GetCombinedBonus("Stand_Power")
	elseif statName == "Stand_Durability_Val" then total = getAttr("Defense") + base + GetCombinedBonus("Defense") + GetCombinedBonus("Stand_Durability")
	elseif statName == "Stand_Speed_Val" then total = getAttr("Speed") + base + GetCombinedBonus("Speed") + GetCombinedBonus("Stand_Speed")
	elseif statName == "Stand_Range_Val" then total = base + GetCombinedBonus("Stand_Range")
	elseif statName == "Stand_Precision_Val" then total = base + GetCombinedBonus("Stand_Precision")
	elseif statName == "Stand_Potential_Val" then total = base + GetCombinedBonus("Stand_Potential")
	end

	local impactStr = "\n\n<b><font color='#55FF55'>COMBAT EFFECTS (Total Stat: "..total.."):</font></b>\n"
	local trait = player:GetAttribute("StandTrait") or "None"

	if statName == "Health" then
		local mult = 1
		if trait == "Tough" then mult = 1.1 elseif trait == "Perseverance" then mult = 1.5 end
		impactStr = impactStr .. "• Max HP: " .. math.floor((total * 10) * mult)
	elseif statName == "Strength" or statName == "Stand_Power_Val" then
		local mult = trait == "Fierce" and 1.1 or 1.0
		impactStr = impactStr .. "• Base Damage: " .. math.floor(total * mult)
	elseif statName == "Defense" or statName == "Stand_Durability_Val" then
		local dmgTaken = (100 / (100 + total)) * 100
		impactStr = impactStr .. "• Armor Rating: " .. total .. "\n• Damage Taken: " .. string.format("%.1f", dmgTaken) .. "%"
	elseif statName == "Speed" or statName == "Stand_Speed_Val" then
		local mult = trait == "Godspeed" and 1.3 or 1.0
		impactStr = impactStr .. "• Dodge Modifier: " .. string.format("%.1f", (total * mult) * 0.2) .. "%"
	elseif statName == "Willpower" then
		local wMult = trait == "Perseverance" and 1.5 or 1.0
		local wTotal = total * wMult
		impactStr = impactStr .. "• Base Crit Chance: " .. string.format("%.1f", 5 + (wTotal * 0.5)) .. "%\n• Survival Chance (1 HP): " .. string.format("%.1f", math.min(45, wTotal * 0.7)) .. "%"
	elseif statName == "Stamina" then
		local mult = trait == "Focused" and 1.1 or 1.0
		impactStr = impactStr .. "• Max Stamina: " .. math.floor(total * mult)
	elseif statName == "Stand_Potential_Val" then
		local mult = trait == "Focused" and 1.1 or 1.0
		impactStr = impactStr .. "• Max Energy: " .. math.floor((10 + total) * mult)
	elseif statName == "Stand_Range_Val" then
		impactStr = impactStr .. "• Armor Penetration: " .. string.format("%.1f", total * 0.5) .. "\n• Negate Enemy Dodge: " .. string.format("%.1f", total * 0.1) .. "%"
	elseif statName == "Stand_Precision_Val" then
		impactStr = impactStr .. "• Bonus Crit Chance: +" .. string.format("%.1f", total * 0.2) .. "%"
	end

	cachedTooltipMgr.Show(desc .. impactStr)
end

local function showUpgradeTooltip(statName, amt)
	currentlyHoveredUpgrade = true
	local prestigeObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
	local prestige = prestigeObj and prestigeObj.Value or 0
	local statCap = GameData.GetStatCap(prestige)
	local currentStat = player:GetAttribute(statName) or 1
	local currentXP = player:GetAttribute("XP") or 0
	local cleanName = statName:gsub("_Val", "")
	local base = (prestige == 0) and (GameData.BaseStats[cleanName] or 0) or (prestige * 5)

	if currentStat >= statCap then
		cachedTooltipMgr.Show("<font color='#FF5555'>Stat is MAXED!</font>")
		return
	end

	local cost = 0
	local added = 0
	local simulatedXP = currentXP
	local target = (amt == "MAX") and 9999 or amt

	for i = 0, target - 1 do
		if currentStat + added >= statCap then break end
		local stepCost = GameData.CalculateStatCost(currentStat + added, base, prestige)

		if simulatedXP >= stepCost then
			simulatedXP -= stepCost
			cost += stepCost
			added += 1
		else
			break
		end
	end

	if added == 0 then
		local stepCost = GameData.CalculateStatCost(currentStat, base, prestige)
		cachedTooltipMgr.Show("<b>UPGRADE " .. cleanName:upper() .. "</b>\n<font color='#FF5555'>Not enough XP!</font>\n<font color='#AAAAAA'>Next level costs: " .. stepCost .. " XP</font>")
	else
		cachedTooltipMgr.Show("<b>UPGRADE " .. cleanName:upper() .. " (+" .. added .. ")</b>\n<font color='#55FFFF'>Cost: " .. cost .. " XP</font>\n<font color='#55FF55'>New Level: " .. (currentStat + added) .. "</font>")
	end
end

local function applyDoubleGoldBorder(parent)
	local outerStroke = Instance.new("UIStroke")
	outerStroke.Thickness = 3; outerStroke.Color = Color3.fromRGB(255, 210, 60); outerStroke.LineJoinMode = Enum.LineJoinMode.Round; outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local gradOut = Instance.new("UIGradient", outerStroke); gradOut.Rotation = -45
	gradOut.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 160, 30)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 150)), ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 160, 30))}
	outerStroke.Parent = parent

	local innerFrame = Instance.new("Frame", parent)
	innerFrame.Name = "InnerGoldBorder"; innerFrame.Size = UDim2.new(1, -6, 1, -6); innerFrame.Position = UDim2.new(0.5, 0, 0.5, 0); innerFrame.AnchorPoint = Vector2.new(0.5, 0.5); innerFrame.BackgroundTransparency = 1; innerFrame.ZIndex = parent.ZIndex

	local parentCorner = parent:FindFirstChildOfClass("UICorner")
	if parentCorner then
		local innerCorner = Instance.new("UICorner")
		innerCorner.CornerRadius = UDim.new(0, math.max(0, parentCorner.CornerRadius.Offset - 3))
		innerCorner.Parent = innerFrame
	end

	local innerStroke = Instance.new("UIStroke", innerFrame)
	innerStroke.Thickness = 1; innerStroke.Color = Color3.fromRGB(255, 230, 100); innerStroke.LineJoinMode = Enum.LineJoinMode.Round; innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local gradIn = Instance.new("UIGradient", innerStroke); gradIn.Rotation = 45
	gradIn.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 25))}
end

local function CreateCard(name, parent, size, layoutOrder)
	local frame = Instance.new("Frame", parent)
	frame.Name = name; frame.Size = size; frame.BackgroundColor3 = Color3.fromRGB(25, 10, 35); frame.LayoutOrder = layoutOrder; frame.ZIndex = 20
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(90, 50, 120); stroke.Thickness = 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local uip = Instance.new("UIPadding", frame); uip.PaddingTop = UDim.new(0, 8); uip.PaddingBottom = UDim.new(0, 8); uip.PaddingLeft = UDim.new(0, 8); uip.PaddingRight = UDim.new(0, 8)
	return frame
end

local function CreateTitle(parent, text)
	local lbl = Instance.new("TextLabel", parent)
	lbl.Size = UDim2.new(1, 0, 0, 18); lbl.BackgroundTransparency = 1; lbl.Text = text; lbl.Font = Enum.Font.GothamBlack; lbl.TextColor3 = Color3.fromRGB(255, 215, 50); lbl.TextScaled = false; lbl.TextSize = 14; lbl.LayoutOrder = 1; lbl.ZIndex = 22; lbl.TextXAlignment = Enum.TextXAlignment.Center
	return lbl
end

local function setUpgradeBtnState(btn, enabled)
	if enabled then
		btn.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
		btn.TextColor3 = Color3.new(1, 1, 1)
		local stroke = btn:FindFirstChild("UIStroke")
		if stroke then stroke.Color = Color3.fromRGB(120, 60, 180) end
	else
		btn.BackgroundColor3 = Color3.fromRGB(30, 20, 30)
		btn.TextColor3 = Color3.fromRGB(100, 100, 100)
		local stroke = btn:FindFirstChild("UIStroke")
		if stroke then stroke.Color = Color3.fromRGB(60, 40, 80) end
	end
end

local function CreateStatRow(statName, parent, isStand)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1, 0, 1/6, 0)
	row.BackgroundTransparency = 1

	local rowPad = Instance.new("UIPadding", row)
	rowPad.PaddingLeft = UDim.new(0, 5)
	rowPad.PaddingRight = UDim.new(0, 5)

	local statLabel = Instance.new("TextLabel", row)
	statLabel.Size = UDim2.new(0.50, 0, 1, 0)
	statLabel.BackgroundTransparency = 1
	statLabel.Font = Enum.Font.GothamBold
	statLabel.TextColor3 = isStand and Color3.fromRGB(200, 150, 255) or Color3.fromRGB(220, 220, 220)
	statLabel.TextXAlignment = Enum.TextXAlignment.Left
	statLabel.TextScaled = true
	statLabel.TextWrapped = true
	statLabel.RichText = true
	statLabel.ZIndex = 22
	Instance.new("UITextSizeConstraint", statLabel).MaxTextSize = 13

	local btnContainer = Instance.new("Frame", row)
	btnContainer.Size = UDim2.new(0.48, 0, 1, 0)
	btnContainer.Position = UDim2.new(1, 0, 0, 0)
	btnContainer.AnchorPoint = Vector2.new(1, 0)
	btnContainer.BackgroundTransparency = 1
	btnContainer.ZIndex = 22

	local blL = Instance.new("UIListLayout", btnContainer)
	blL.FillDirection = Enum.FillDirection.Horizontal
	blL.HorizontalAlignment = Enum.HorizontalAlignment.Right
	blL.VerticalAlignment = Enum.VerticalAlignment.Center
	blL.Padding = UDim.new(0.04, 0)
	blL.SortOrder = Enum.SortOrder.LayoutOrder

	local function makeBtn(text, order, widthScaleX)
		local b = Instance.new("TextButton", btnContainer)
		b.LayoutOrder = order
		b.Size = UDim2.new(widthScaleX, 0, 0.85, 0) 
		b.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.new(1,1,1)
		b.TextScaled = true
		b.TextWrapped = true
		b.ZIndex = 23
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
		local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(120, 60, 180); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 14
		return b
	end

	local bAdd = makeBtn("+", 1, 0.35) 
	local bMax = makeBtn("MAX", 2, 0.60)

	local function hookUpgradeHover(btn, isMax)
		btn.MouseEnter:Connect(function() 
			if isMax then showUpgradeTooltip(statName, "MAX")
			else showUpgradeTooltip(statName, currentUpgradeAmount) end
		end)
		btn.MouseLeave:Connect(function()
			currentlyHoveredUpgrade = false
			if currentlyHoveredStat == statName then UpdateStatTooltip() else cachedTooltipMgr.Hide() end
		end)
	end

	hookUpgradeHover(bAdd, false)
	hookUpgradeHover(bMax, true)

	row.MouseEnter:Connect(function() 
		currentlyHoveredStat = statName
		if not currentlyHoveredUpgrade then UpdateStatTooltip() end
	end)
	row.MouseLeave:Connect(function() 
		if currentlyHoveredStat == statName then 
			currentlyHoveredStat = nil
			if not currentlyHoveredUpgrade then cachedTooltipMgr.Hide() end
		end 
	end)

	bAdd.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network:WaitForChild("UpgradeStat"):FireServer(statName, currentUpgradeAmount) end)
	bMax.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network:WaitForChild("UpgradeStat"):FireServer(statName, "MAX") end)

	return { Label = statLabel, BtnAdd = bAdd, BtnMax = bMax }
end

local function BuildDropdownList(parentBtn, listFrame, dataTable, isStand)
	for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") or c:IsA("UIListLayout") then c:Destroy() end end

	local options = {"Any"}
	for name, data in pairs(dataTable) do
		if isStand then
			if data.Rarity ~= "Evolution" and data.Rarity ~= "Unique" and data.Rarity ~= "Mythical" then table.insert(options, name) end
		else
			if data.Rarity ~= "Unique" then table.insert(options, name) end
		end
	end
	table.sort(options)

	local listL = Instance.new("UIListLayout", listFrame); listL.SortOrder = Enum.SortOrder.LayoutOrder
	for _, opt in ipairs(options) do
		local b = Instance.new("TextButton", listFrame)
		b.Size = UDim2.new(1, -8, 0, 25)
		b.BackgroundTransparency = 1
		b.TextColor3 = Color3.new(1,1,1)
		b.Text = opt; b.Font = Enum.Font.GothamMedium; b.TextScaled = true; b.ZIndex = 51
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 12
		b.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			if isStand then targetAutoStand = opt; parentBtn.Text = "Stand: " .. opt
			else targetAutoTrait = opt; parentBtn.Text = "Trait: " .. opt end
			listFrame.Visible = false
		end)
	end
	listFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 25)
	parentBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); listFrame.Visible = not listFrame.Visible end)
end

local function RefreshStatTexts()
	local prestigeObj = player:WaitForChild("leaderstats", 5) and player.leaderstats:WaitForChild("Prestige", 5)
	local prestige = prestigeObj and prestigeObj.Value or 0
	local currentXP = player:GetAttribute("XP") or 0
	local statCap = GameData.GetStatCap(prestige)

	for statName, data in pairs(statLabels) do
		local val = player:GetAttribute(statName) or 1
		local cleanName = statName:gsub("_Val", "")
		local base = (prestige == 0) and (GameData.BaseStats[cleanName] or 0) or (prestige * 5)

		local costAmt = GetUpgradeCostForAmount(val, base, prestige, statCap, currentUpgradeAmount)
		local cost1 = GetUpgradeCostForAmount(val, base, prestige, statCap, 1)

		local bonusAmount = GetCombinedBonus(cleanName)
		local bonusText = bonusAmount > 0 and " <font color='#55FF55'>(+" .. bonusAmount .. ")</font>" or ""

		if val >= statCap then
			data.Label.Text = cleanName:gsub("Stand_", "") .. ": " .. val .. bonusText .. " <font color='#FF5555'>[MAX]</font>"
			setUpgradeBtnState(data.BtnAdd, false)
			setUpgradeBtnState(data.BtnMax, false)
		else
			data.Label.Text = cleanName:gsub("Stand_", "") .. ": " .. val .. bonusText
			setUpgradeBtnState(data.BtnAdd, currentXP >= costAmt and costAmt > 0)
			setUpgradeBtnState(data.BtnMax, currentXP >= cost1)
		end
	end
end

local function RefreshStorageList()
	for _, child in pairs(standStorageContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	for _, child in pairs(styleStorageContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

	local pObj = player:FindFirstChild("leaderstats")
	local prestige = pObj and pObj:FindFirstChild("Prestige") and pObj.Prestige.Value or 0

	local standSlots = {
		{ Backend = 1, IsUnlocked = true, Type = "Base" },
		{ Backend = 2, IsUnlocked = player:GetAttribute("HasStandSlot2"), Type = "Robux", PassId = 1733160695 },
		{ Backend = 3, IsUnlocked = player:GetAttribute("HasStandSlot3"), Type = "Robux", PassId = 1732844091 },
		{ Backend = 4, IsUnlocked = (prestige >= 15), Type = "Prestige", Req = 15 },
		{ Backend = 5, IsUnlocked = (prestige >= 30), Type = "Prestige", Req = 30 }
	}

	local styleSlots = {
		{ Backend = 1, IsUnlocked = true, Type = "Base" },
		{ Backend = 2, IsUnlocked = player:GetAttribute("HasStyleSlot2"), Type = "Robux", PassId = 1746853452 },
		{ Backend = 3, IsUnlocked = player:GetAttribute("HasStyleSlot3"), Type = "Robux", PassId = 1745969849 }
	}

	local function RenderSlots(slotsTable, container, isStand)
		for visualNum, slotData in ipairs(slotsTable) do
			local row = Instance.new("Frame", container)
			row.Size = UDim2.new(1, 0, 1/5, 0)
			row.BackgroundTransparency = 1
			row.ZIndex = 23

			local nameLabel = Instance.new("TextLabel", row)
			nameLabel.Size = UDim2.new(0.68, 0, 1, 0); nameLabel.Position = UDim2.new(0, 4, 0, 0)
			nameLabel.BackgroundTransparency = 1; nameLabel.Font = Enum.Font.GothamMedium; nameLabel.TextColor3 = Color3.new(1,1,1)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.TextScaled = true; nameLabel.RichText = true; nameLabel.ZIndex = 24
			Instance.new("UITextSizeConstraint", nameLabel).MaxTextSize = 13

			local btn = Instance.new("TextButton", row)
			btn.Size = UDim2.new(0.28, 0, 0.8, 0)
			btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, -4, 0.5, 0)
			btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.new(1,1,1); btn.TextScaled = true; btn.ZIndex = 24
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
			Instance.new("UITextSizeConstraint", btn).MaxTextSize = 12

			if slotData.IsUnlocked then
				if isStand then
					local storedName = player:GetAttribute("StoredStand"..slotData.Backend) or "None"
					local storedTrait = player:GetAttribute("StoredStand"..slotData.Backend.."_Trait") or "None"
					local traitDisplay = ""

					if storedName == "Fused Stand" then
						local fs1 = player:GetAttribute("StoredStand"..slotData.Backend.."_FusedStand1") or "Unknown"
						local fs2 = player:GetAttribute("StoredStand"..slotData.Backend.."_FusedStand2") or "Unknown"
						local ft1 = player:GetAttribute("StoredStand"..slotData.Backend.."_FusedTrait1") or "None"
						local ft2 = player:GetAttribute("StoredStand"..slotData.Backend.."_FusedTrait2") or "None"

						storedName = FusionUtility.CalculateFusedName(fs1, fs2)

						local tCol1 = StandData.Traits[ft1] and StandData.Traits[ft1].Color or "#FFFFFF"
						local tCol2 = StandData.Traits[ft2] and StandData.Traits[ft2].Color or "#FFFFFF"

						if ft1 == "None" and ft2 == "None" then traitDisplay = ""
						elseif ft1 == "None" then traitDisplay = " <font color='" .. tCol2 .. "'>[" .. ft2:upper() .. "]</font>"
						elseif ft2 == "None" then traitDisplay = " <font color='" .. tCol1 .. "'>[" .. ft1:upper() .. "]</font>"
						else traitDisplay = " <font color='" .. tCol1 .. "'>[" .. ft1:upper() .. "]</font> & <font color='" .. tCol2 .. "'>[" .. ft2:upper() .. "]</font>" end
					else
						if storedTrait ~= "None" then
							local tCol = StandData.Traits[storedTrait] and StandData.Traits[storedTrait].Color or "#FFFFFF"
							traitDisplay = " <font color='" .. tCol .. "'>[" .. storedTrait:upper() .. "]</font>"
						end
					end

					nameLabel.Text = "S"..visualNum..": <font color='#A020F0'>" .. storedName .. "</font>" .. traitDisplay
					local realStoredName = player:GetAttribute("StoredStand"..slotData.Backend) or "None"
					if realStoredName == "None" and (player:GetAttribute("Stand") or "None") == "None" then
						btn.Text = "Empty"; btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					else
						btn.Text = realStoredName == "None" and "Store" or "Swap"; btn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
						btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network:WaitForChild("StandStorageAction"):FireServer("Swap", slotData.Backend) end)
					end
				else
					local storedName = player:GetAttribute("StoredStyle"..slotData.Backend) or "None"
					nameLabel.Text = "S"..visualNum..": <font color='#FF8C00'>" .. storedName .. "</font>"
					if storedName == "None" and (player:GetAttribute("FightingStyle") or "None") == "None" then
						btn.Text = "Empty"; btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					else
						btn.Text = storedName == "None" and "Store" or "Swap"; btn.BackgroundColor3 = Color3.fromRGB(180, 80, 20)
						btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network:WaitForChild("StandStorageAction"):FireServer("SwapStyle", slotData.Backend) end)
					end
				end
			else
				if slotData.Type == "Prestige" then
					nameLabel.Text = "S"..visualNum..": <font color='#FF5555'>Locked (P."..slotData.Req..")</font>"
					btn.Text = "Lock"; btn.BackgroundColor3 = Color3.fromRGB(100, 50, 50); btn.AutoButtonColor = false
				else
					nameLabel.Text = "S"..visualNum..": <font color='#FF5555'>Locked (R$)</font>"
					btn.Text = "Buy"; btn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
					btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); MarketplaceService:PromptGamePassPurchase(player, slotData.PassId) end)
				end
			end
		end
	end

	RenderSlots(standSlots, standStorageContainer, true)
	RenderSlots(styleSlots, styleStorageContainer, false)
end

local function sortItemsFunc(a, b)
	local dataA = ItemData.Equipment[a.Name] or ItemData.Consumables[a.Name]
	local dataB = ItemData.Equipment[b.Name] or ItemData.Consumables[b.Name]
	local rA = dataA and dataA.Rarity or "Common"
	local rB = dataB and dataB.Rarity or "Common"
	local tierA = raritySortTiers[rA] or raritySortTiers.Common
	local tierB = raritySortTiers[rB] or raritySortTiers.Common

	if tierA == tierB then return a.Name < b.Name end
	return tierA < tierB
end

local function RefreshInventoryList()
	for _, child in pairs(equipContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	for _, child in pairs(playerConsContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	for _, child in pairs(standConsContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

	local equipItems, playerConsItems, standConsItems = {}, {}, {}
	local currentInvCount = 0

	for _, itemName in ipairs(KnownItems) do
		local count = player:GetAttribute(itemName:gsub("[^%w]", "") .. "Count") or 0
		if count > 0 then
			if ItemData.Equipment[itemName] then 
				table.insert(equipItems, {Name = itemName, Count = count})
				currentInvCount += count
			elseif ItemData.Consumables[itemName] then
				if ItemData.Consumables[itemName].Category == "Stand" then table.insert(standConsItems, {Name = itemName, Count = count})
				else table.insert(playerConsItems, {Name = itemName, Count = count}) end
			end
		end
	end

	table.sort(equipItems, sortItemsFunc)
	table.sort(playerConsItems, sortItemsFunc)
	table.sort(standConsItems, sortItemsFunc)

	if capacityLabel then
		local maxInv = GameData.GetMaxInventory(player)
		capacityLabel.Text = "Capacity: " .. currentInvCount .. "/" .. maxInv
	end

	local function RenderItem(itemName, count, container, orderIdx)
		local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
		local rarity = itemData and itemData.Rarity or "Common"

		local itemFrame = Instance.new("Frame", container)
		itemFrame.Size = UDim2.new(1, -8, 0, 30)
		itemFrame.BackgroundColor3 = Color3.fromRGB(30, 15, 45)
		itemFrame.LayoutOrder = orderIdx
		itemFrame.ZIndex = 23
		Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 4)
		local str = Instance.new("UIStroke", itemFrame); str.Color = rarityColors[rarity] or rarityColors.Common; str.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local nameLabel = Instance.new("TextLabel", itemFrame)
		nameLabel.Size = UDim2.new(0.48, 0, 1, 0); nameLabel.AnchorPoint = Vector2.new(0, 0.5); nameLabel.Position = UDim2.new(0, 8, 0.5, 0)
		nameLabel.BackgroundTransparency = 1; nameLabel.Font = Enum.Font.GothamMedium; nameLabel.TextColor3 = rarityColors[rarity] or rarityColors.Common
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.TextScaled = true; nameLabel.TextWrapped = true; nameLabel.Text = itemName .. " (x" .. count .. ")"; nameLabel.ZIndex = 24
		Instance.new("UITextSizeConstraint", nameLabel).MaxTextSize = 12

		local btnWrapper = Instance.new("Frame", itemFrame)
		btnWrapper.Size = UDim2.new(0.50, 0, 1, 0); btnWrapper.Position = UDim2.new(1, -4, 0.5, 0); btnWrapper.AnchorPoint = Vector2.new(1, 0.5); btnWrapper.BackgroundTransparency = 1
		local bL = Instance.new("UIListLayout", btnWrapper); bL.FillDirection = Enum.FillDirection.Horizontal; bL.HorizontalAlignment = Enum.HorizontalAlignment.Right; bL.VerticalAlignment = Enum.VerticalAlignment.Center; bL.Padding = UDim.new(0.02, 0); bL.SortOrder = Enum.SortOrder.LayoutOrder

		local function makeBtn(text, scaleW, color, order)
			local b = Instance.new("TextButton", btnWrapper)
			b.Size = UDim2.new(scaleW, 0, 0.8, 0); b.LayoutOrder = order
			b.BackgroundColor3 = color; b.Text = text; b.Font = Enum.Font.GothamBold; b.TextColor3 = Color3.new(1,1,1)
			b.TextScaled = true; b.TextWrapped = true; b.ZIndex = 24
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
			Instance.new("UITextSizeConstraint", b).MaxTextSize = 11
			return b
		end

		local useBtn = makeBtn(ItemData.Equipment[itemName] and "Equip" or "Use", 0.42, Color3.fromRGB(200, 120, 0), 1)
		local sellBtn = makeBtn("Sell", 0.32, Color3.fromRGB(140, 40, 40), 2)
		local lockBtn = makeBtn("🔓", 0.20, Color3.fromRGB(40, 40, 40), 3)

		local lockedItems = player:GetAttribute("LockedItems") or ""
		if table.find(string.split(lockedItems, ","), itemName) ~= nil then
			lockBtn.Text = "🔒"; lockBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
			sellBtn.Text = "Locked"; sellBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		end

		lockBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network:WaitForChild("ToggleLock"):FireServer("Item", itemName) end)

		local isEquipped = ItemData.Equipment[itemName] and player:GetAttribute("Equipped" .. ItemData.Equipment[itemName].Slot) == itemName
		local isConfirmingUse, isConfirmingSell = false, false

		if isEquipped then
			useBtn.Text = "Unequip"; useBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
			useBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network:WaitForChild("UnequipItem"):FireServer(ItemData.Equipment[itemName].Slot) end)
		else
			useBtn.MouseButton1Click:Connect(function()
				if useBtn.Text == "Equip" then
					SFXManager.Play("Click"); Network:WaitForChild("UseItem"):FireServer(itemName)
				else
					if ItemData.Consumables[itemName] and not isConfirmingUse then
						isConfirmingUse = true; useBtn.Text = "Confirm?"; useBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
						task.delay(3, function() if isConfirmingUse and useBtn.Parent then isConfirmingUse = false; useBtn.Text = "Use"; useBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0) end end)
						return
					end
					isConfirmingUse = false; SFXManager.Play("Click"); Network:WaitForChild("UseItem"):FireServer(itemName)
				end
			end)
		end

		sellBtn.MouseButton1Click:Connect(function()
			if table.find(string.split(player:GetAttribute("LockedItems") or "", ","), itemName) then return end
			if not isConfirmingSell then
				isConfirmingSell = true; sellBtn.Text = "Sure?"; sellBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
				task.delay(3, function() if isConfirmingSell and sellBtn.Parent then isConfirmingSell = false; sellBtn.Text = "Sell"; sellBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40) end end)
				return
			end
			isConfirmingSell = false; SFXManager.Play("Click"); cachedTooltipMgr.Hide()

			Network:WaitForChild("ShopAction"):FireServer("Sell", itemName)
			local iData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
			local sellVal = iData and (iData.SellPrice or math.floor((iData.Cost or 50) / 2)) or 25
			NotificationManager.Show("<font color='#55FF55'>Sold " .. itemName .. " for ¥" .. sellVal .. "!</font>")
		end)

		itemFrame.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetItemTooltip(itemName)) end)
		itemFrame.MouseLeave:Connect(cachedTooltipMgr.Hide)
	end

	for i, item in ipairs(equipItems) do RenderItem(item.Name, item.Count, equipContainer, i) end
	for i, item in ipairs(playerConsItems) do RenderItem(item.Name, item.Count, playerConsContainer, i) end
	for i, item in ipairs(standConsItems) do RenderItem(item.Name, item.Count, standConsContainer, i) end

	equipContainer.CanvasSize = UDim2.new(0, 0, 0, (#equipItems * 34) + 10)
	playerConsContainer.CanvasSize = UDim2.new(0, 0, 0, (#playerConsItems * 34) + 10)
	standConsContainer.CanvasSize = UDim2.new(0, 0, 0, (#standConsItems * 34) + 10)
end

local function UpdateTopDisplays()
	local sName = player:GetAttribute("Stand") or "None"
	local sTrait = player:GetAttribute("StandTrait") or "None"
	local style = player:GetAttribute("FightingStyle") or "None"
	local wpn = player:GetAttribute("EquippedWeapon") or "None"
	local acc = player:GetAttribute("EquippedAccessory") or "None"

	local traitDisplay = ""

	if sName == "Fused Stand" then
		local fs1 = player:GetAttribute("Active_FusedStand1") or "Unknown"
		local fs2 = player:GetAttribute("Active_FusedStand2") or "Unknown"
		local ft1 = player:GetAttribute("Active_FusedTrait1") or "None"
		local ft2 = player:GetAttribute("Active_FusedTrait2") or "None"

		sName = FusionUtility.CalculateFusedName(fs1, fs2)

		local tCol1 = StandData.Traits[ft1] and StandData.Traits[ft1].Color or "#FFFFFF"
		local tCol2 = StandData.Traits[ft2] and StandData.Traits[ft2].Color or "#FFFFFF"

		if ft1 == "None" and ft2 == "None" then traitDisplay = ""
		elseif ft1 == "None" then traitDisplay = " <font color='" .. tCol2 .. "'>[" .. ft2:upper() .. "]</font>"
		elseif ft2 == "None" then traitDisplay = " <font color='" .. tCol1 .. "'>[" .. ft1:upper() .. "]</font>"
		else traitDisplay = " <font color='" .. tCol1 .. "'>[" .. ft1:upper() .. "]</font> & <font color='" .. tCol2 .. "'>[" .. ft2:upper() .. "]</font>" end
	else
		if sTrait ~= "None" then
			local color = StandData.Traits[sTrait] and StandData.Traits[sTrait].Color or "#FFFFFF"
			traitDisplay = " <font color='" .. color .. "'>[" .. sTrait:upper() .. "]</font>"
		end
	end

	standLabel.Text = "<b>STAND:</b> <font color='#A020F0'>" .. sName:upper() .. "</font>" .. traitDisplay
	styleLabel.Text = "<b>STYLE:</b> <font color='#FF8C00'>" .. style:upper() .. "</font>"
	weaponLabel.Text = "<b>WEAPON:</b> <font color='#55FF55'>" .. wpn:upper() .. "</font>"
	accLabel.Text = "<b>ACCESSORY:</b> <font color='#55FFFF'>" .. acc:upper() .. "</font>"

	if standLockBtn then
		if player:GetAttribute("StandLocked") then standLockBtn.Text = "🔒"; standLockBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
		else standLockBtn.Text = "🔓"; standLockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end
	end
	if styleLockBtn then
		if player:GetAttribute("StyleLocked") then styleLockBtn.Text = "🔒"; styleLockBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
		else styleLockBtn.Text = "🔓"; styleLockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end
	end

	local xpVal = player:GetAttribute("XP") or 0
	local yenVal = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Yen") and player.leaderstats.Yen.Value or 0
	xpLabelP.Text = "<b>XP:</b> <font color='#55FFFF'>" .. xpVal .. "</font>"
	xpLabelS.Text = "<b>XP:</b> <font color='#55FFFF'>" .. xpVal .. "</font>"
	yenLabel.Text = "<b>YEN:</b> <font color='#55FF55'>¥" .. yenVal .. "</font>"
	RefreshStatTexts()
end

local function AttachStatsControls(parentCard, titleText)
	local tLbl = CreateTitle(parentCard, titleText)
	tLbl.Size = UDim2.new(0.45, 0, 0, 18)
	tLbl.TextXAlignment = Enum.TextXAlignment.Left

	local statsTopControls = Instance.new("Frame", parentCard)
	statsTopControls.Size = UDim2.new(0.55, 0, 0, 18) 
	statsTopControls.Position = UDim2.new(1, 0, 0, 0)
	statsTopControls.AnchorPoint = Vector2.new(1, 0)
	statsTopControls.BackgroundTransparency = 1
	statsTopControls.ZIndex = 25

	local topLayout = Instance.new("UIListLayout", statsTopControls)
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	topLayout.Padding = UDim.new(0, 4)
	topLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local upgradeLbl = Instance.new("TextLabel", statsTopControls)
	upgradeLbl.Size = UDim2.new(0.35, 0, 1, 0)
	upgradeLbl.BackgroundTransparency = 1
	upgradeLbl.Font = Enum.Font.GothamMedium
	upgradeLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	upgradeLbl.Text = "Pts:"
	upgradeLbl.TextScaled = true
	upgradeLbl.LayoutOrder = 1
	upgradeLbl.ZIndex = 26
	Instance.new("UITextSizeConstraint", upgradeLbl).MaxTextSize = 12

	local amtBox = Instance.new("TextBox", statsTopControls)
	amtBox.Size = UDim2.new(0.25, 0, 1, 0)
	amtBox.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
	amtBox.TextColor3 = Color3.new(1,1,1)
	amtBox.Font = Enum.Font.GothamBold
	amtBox.TextScaled = true
	amtBox.Text = tostring(currentUpgradeAmount)
	amtBox.PlaceholderText = "#"
	amtBox.LayoutOrder = 2
	amtBox.ZIndex = 26
	Instance.new("UICorner", amtBox).CornerRadius = UDim.new(0, 3)
	local amtStroke = Instance.new("UIStroke", amtBox)
	amtStroke.Color = Color3.fromRGB(120, 60, 180)
	amtStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Instance.new("UITextSizeConstraint", amtBox).MaxTextSize = 12

	amtBox.FocusLost:Connect(function()
		local val = tonumber(amtBox.Text)
		if val and val > 0 then currentUpgradeAmount = math.floor(val) else currentUpgradeAmount = 1 end
		amtBox.Text = tostring(currentUpgradeAmount)
		RefreshStatTexts()
	end)

	local allBtn = Instance.new("TextButton", statsTopControls)
	allBtn.Size = UDim2.new(0.35, 0, 1, 0)
	allBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 20)
	allBtn.TextColor3 = Color3.new(1,1,1)
	allBtn.Font = Enum.Font.GothamBold
	allBtn.TextScaled = true
	allBtn.Text = "ALL"
	allBtn.LayoutOrder = 3
	allBtn.ZIndex = 26
	Instance.new("UICorner", allBtn).CornerRadius = UDim.new(0, 3)
	local allStroke = Instance.new("UIStroke", allBtn)
	allStroke.Color = Color3.fromRGB(255, 200, 50)
	allStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Instance.new("UITextSizeConstraint", allBtn).MaxTextSize = 12

	allBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local UpgradeAllEvent = Network:FindFirstChild("UpgradeAllStats")
		if UpgradeAllEvent then UpgradeAllEvent:FireServer(currentUpgradeAmount) end
	end)
end

local function createLoadRow(name, parentFrame, heightScale)
	local r = Instance.new("Frame", parentFrame)
	r.Size = UDim2.new(1, 0, heightScale or 0.25, 0)
	r.BackgroundTransparency = 1

	local rL = Instance.new("UIListLayout", r)
	rL.FillDirection = Enum.FillDirection.Horizontal
	rL.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rL.VerticalAlignment = Enum.VerticalAlignment.Center
	rL.SortOrder = Enum.SortOrder.LayoutOrder
	rL.Padding = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel", r)
	lbl.LayoutOrder = 1
	lbl.AutomaticSize = Enum.AutomaticSize.X
	lbl.Size = UDim2.new(0, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextColor3 = Color3.new(1,1,1)
	lbl.TextScaled = false
	lbl.TextSize = 14
	lbl.RichText = true
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.ZIndex = 22

	local btn = nil
	if name == "Stand" or name == "Style" then
		btn = Instance.new("TextButton", r)
		btn.LayoutOrder = 2
		btn.SizeConstraint = Enum.SizeConstraint.RelativeYY
		btn.Size = UDim2.new(0.85, 0, 0.85, 0)
		btn.Font = Enum.Font.GothamBold
		btn.TextScaled = true
		btn.ZIndex = 23
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		local s = Instance.new("UIStroke", btn)
		s.Color = Color3.fromRGB(90, 50, 120)
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end

	return r, lbl, btn
end

function InventoryTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr

	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0.85, 0, 0.85, 0)
	mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
	mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	mainPanel.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	mainPanel.BorderSizePixel = 0
	mainPanel.ZIndex = 15
	mainPanel.ClipsDescendants = true
	mainPanel.Parent = parentFrame

	Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 12)
	applyDoubleGoldBorder(mainPanel)

	local bgPattern = Instance.new("ImageLabel")
	bgPattern.Name = "OverlayPattern"
	bgPattern.Image = "rbxassetid://79623015802180"
	bgPattern.ImageColor3 = Color3.fromRGB(180, 130, 255)
	bgPattern.ImageTransparency = 0.85
	bgPattern.BackgroundTransparency = 1
	bgPattern.ScaleType = Enum.ScaleType.Tile
	bgPattern.TileSize = UDim2.new(0, 500, 0, 250)
	bgPattern.Size = UDim2.new(1, 0, 1, 0)
	bgPattern.ZIndex = 16
	bgPattern.Parent = mainPanel

	local innerContent = Instance.new("ScrollingFrame")
	innerContent.Name = "InnerContent"
	innerContent.Size = UDim2.new(1, 0, 1, 0)
	innerContent.BackgroundTransparency = 1
	innerContent.ZIndex = 17
	innerContent.ScrollBarThickness = 6
	innerContent.ScrollBarImageColor3 = Color3.fromRGB(150, 100, 200)
	innerContent.ScrollingDirection = Enum.ScrollingDirection.Y
	innerContent.BorderSizePixel = 0
	innerContent.Parent = mainPanel

	local mainPad = Instance.new("UIPadding", innerContent)
	mainPad.PaddingTop = UDim.new(0.02, 0); mainPad.PaddingBottom = UDim.new(0.02, 0)
	mainPad.PaddingLeft = UDim.new(0.02, 0); mainPad.PaddingRight = UDim.new(0.02, 0)

	local mainLayout = Instance.new("UIListLayout", innerContent)
	mainLayout.FillDirection = Enum.FillDirection.Vertical
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainLayout.Padding = UDim.new(0.02, 0)

	local subNavFrame = Instance.new("Frame", innerContent)
	subNavFrame.Name = "SubNavFrame"
	subNavFrame.Size = UDim2.new(1, 0, 0.06, 0)
	subNavFrame.BackgroundTransparency = 1
	subNavFrame.LayoutOrder = 1

	local subNavL = Instance.new("UIListLayout", subNavFrame)
	subNavL.FillDirection = Enum.FillDirection.Horizontal
	subNavL.HorizontalAlignment = Enum.HorizontalAlignment.Center
	subNavL.Padding = UDim.new(0.02, 0)

	local function CreateTabBtn(txt)
		local btn = Instance.new("TextButton", subNavFrame)
		btn.Size = UDim2.new(0.32, 0, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
		btn.Text = txt
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(200, 200, 220)
		btn.TextScaled = true
		btn.ZIndex = 20
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		local str = Instance.new("UIStroke", btn); str.Color = Color3.fromRGB(90, 50, 120); str.Thickness = 1; str.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Instance.new("UITextSizeConstraint", btn).MaxTextSize = 16
		return btn, str
	end

	local invTabBtn, invStr = CreateTabBtn("INVENTORY")
	local playerTabBtn, playerStr = CreateTabBtn("PLAYER")
	local standTabBtn, standStr = CreateTabBtn("STAND")

	local tabContainer = Instance.new("Frame", innerContent)
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, 0, 0.90, 0)
	tabContainer.BackgroundTransparency = 1
	tabContainer.LayoutOrder = 2

	local invTabContent = Instance.new("Frame", tabContainer)
	invTabContent.Name = "InventoryTabContent"; invTabContent.Size = UDim2.new(1, 0, 1, 0); invTabContent.BackgroundTransparency = 1; invTabContent.Visible = true
	local invTL = Instance.new("UIListLayout", invTabContent); invTL.FillDirection = Enum.FillDirection.Vertical; invTL.SortOrder = Enum.SortOrder.LayoutOrder; invTL.Padding = UDim.new(0.02, 0)

	local invInfoCard = CreateCard("InvInfoCard", invTabContent, UDim2.new(1, 0, 0.24, 0), 1)
	local invIL = Instance.new("UIListLayout", invInfoCard)
	invIL.FillDirection = Enum.FillDirection.Vertical; invIL.HorizontalAlignment = Enum.HorizontalAlignment.Center; invIL.VerticalAlignment = Enum.VerticalAlignment.Center; invIL.Padding = UDim.new(0, 6)

	weaponBox, weaponLabel, _ = createLoadRow("Wep", invInfoCard, 0.25)
	accBox, accLabel, _ = createLoadRow("Acc", invInfoCard, 0.25)
	local yenBox; yenBox, yenLabel, _ = createLoadRow("Yen", invInfoCard, 0.25)

	local equipCard = CreateCard("EquipCard", invTabContent, UDim2.new(1, 0, 0.44, 0), 2)
	local eqTop = Instance.new("Frame", equipCard); eqTop.Size = UDim2.new(1, 0, 0, 20); eqTop.BackgroundTransparency = 1; eqTop.ZIndex = 21
	local eqTitle = CreateTitle(eqTop, "EQUIPMENT INVENTORY"); eqTitle.Size = UDim2.new(0.5, 0, 1, 0); eqTitle.TextXAlignment = Enum.TextXAlignment.Left
	capacityLabel = Instance.new("TextLabel", eqTop)
	capacityLabel.Size = UDim2.new(0.5, 0, 1, 0); capacityLabel.Position = UDim2.new(1, -15, 0, 0); capacityLabel.AnchorPoint = Vector2.new(1, 0)
	capacityLabel.BackgroundTransparency = 1; capacityLabel.Font = Enum.Font.GothamMedium; capacityLabel.TextColor3 = Color3.fromRGB(200, 200, 200); capacityLabel.TextXAlignment = Enum.TextXAlignment.Right; capacityLabel.TextScaled = true; capacityLabel.ZIndex = 22
	Instance.new("UITextSizeConstraint", capacityLabel).MaxTextSize = 12

	equipContainer = Instance.new("ScrollingFrame", equipCard)
	equipContainer.Size = UDim2.new(1, 0, 1, -24); equipContainer.Position = UDim2.new(0,0,0,24); equipContainer.BackgroundTransparency = 1; equipContainer.ScrollBarThickness = 4; equipContainer.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120); equipContainer.ZIndex = 21
	local eqp = Instance.new("UIPadding", equipContainer); eqp.PaddingRight = UDim.new(0, 6); eqp.PaddingLeft = UDim.new(0, 2); eqp.PaddingTop = UDim.new(0, 2); eqp.PaddingBottom = UDim.new(0, 2)
	Instance.new("UIListLayout", equipContainer).Padding = UDim.new(0, 4)

	local autoSellCard = CreateCard("AutoSellCard", invTabContent, UDim2.new(1, 0, 0.28, 0), 3)
	CreateTitle(autoSellCard, "AUTO SELL PREFERENCES")
	autoSellContainer = Instance.new("Frame", autoSellCard)
	autoSellContainer.Size = UDim2.new(1, 0, 1, -24); autoSellContainer.Position = UDim2.new(0,0,0,24); autoSellContainer.BackgroundTransparency = 1; autoSellContainer.ZIndex = 21
	local asG = Instance.new("UIListLayout", autoSellContainer)
	asG.FillDirection = Enum.FillDirection.Horizontal; asG.HorizontalAlignment = Enum.HorizontalAlignment.Center; asG.VerticalAlignment = Enum.VerticalAlignment.Center; asG.Padding = UDim.new(0.015, 0); asG.SortOrder = Enum.SortOrder.LayoutOrder

	local raritiesToSell = {"Common", "Uncommon", "Rare", "Legendary", "Mythical"}
	for i, r in ipairs(raritiesToSell) do
		local b = Instance.new("TextButton", autoSellContainer)
		b.Name = "AutoSell_" .. r; b.LayoutOrder = i; b.Size = UDim2.new(0.188, 0, 0.53, 0); b.BackgroundColor3 = Color3.fromRGB(40, 30, 50); b.Text = r; b.Font = Enum.Font.GothamBold; b.TextColor3 = Color3.new(1,1,1); b.TextScaled = true; b.ZIndex = 22
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
		local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(100, 100, 100); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 13
	end

	local playerTabContent = Instance.new("Frame", tabContainer)
	playerTabContent.Name = "PlayerTabContent"; playerTabContent.Size = UDim2.new(1, 0, 1, 0); playerTabContent.BackgroundTransparency = 1; playerTabContent.Visible = false
	local pTL = Instance.new("UIListLayout", playerTabContent); pTL.FillDirection = Enum.FillDirection.Vertical; pTL.SortOrder = Enum.SortOrder.LayoutOrder; pTL.Padding = UDim.new(0.02, 0)

	local playerInfoCard = CreateCard("PlayerInfoCard", playerTabContent, UDim2.new(1, 0, 0.24, 0), 1)
	local pIL = Instance.new("UIListLayout", playerInfoCard)
	pIL.FillDirection = Enum.FillDirection.Vertical; pIL.HorizontalAlignment = Enum.HorizontalAlignment.Center; pIL.VerticalAlignment = Enum.VerticalAlignment.Center; pIL.Padding = UDim.new(0, 6)

	styleBox, styleLabel, styleLockBtn = createLoadRow("Style", playerInfoCard, 0.35)
	local xpBoxP; xpBoxP, xpLabelP, _ = createLoadRow("XP", playerInfoCard, 0.35)

	local playerMidRow = Instance.new("Frame", playerTabContent)
	playerMidRow.Size = UDim2.new(1, 0, 0.44, 0); playerMidRow.BackgroundTransparency = 1; playerMidRow.LayoutOrder = 2

	local pStatsCard = CreateCard("PlayerStatsCard", playerMidRow, UDim2.new(0.48, 0, 1, 0), 1)
	pStatsCard.Position = UDim2.new(0, 0, 0, 0)

	AttachStatsControls(pStatsCard, "PLAYER STATS")
	pStatsContainer = Instance.new("Frame", pStatsCard)
	pStatsContainer.Size = UDim2.new(1, 0, 1, -24); pStatsContainer.Position = UDim2.new(0, 0, 0, 24); pStatsContainer.BackgroundTransparency = 1; pStatsContainer.ZIndex = 21
	Instance.new("UIListLayout", pStatsContainer).Padding = UDim.new(0, 0)
	for _, stat in ipairs(playerStatsList) do statLabels[stat] = CreateStatRow(stat, pStatsContainer, false) end

	local styleStorageCard = CreateCard("StyleStorageCard", playerMidRow, UDim2.new(0.48, 0, 1, 0), 2)
	styleStorageCard.AnchorPoint = Vector2.new(1, 0)
	styleStorageCard.Position = UDim2.new(1, 0, 0, 0)

	CreateTitle(styleStorageCard, "STYLE STORAGE")
	styleStorageContainer = Instance.new("Frame", styleStorageCard)
	styleStorageContainer.Size = UDim2.new(1, 0, 1, -24); styleStorageContainer.Position = UDim2.new(0,0,0,24); styleStorageContainer.BackgroundTransparency = 1; styleStorageContainer.ZIndex = 21
	Instance.new("UIListLayout", styleStorageContainer).Padding = UDim.new(0, 0)

	local playerConsCard = CreateCard("PlayerConsCard", playerTabContent, UDim2.new(1, 0, 0.28, 0), 3)
	local pcTop = Instance.new("Frame", playerConsCard); pcTop.Size = UDim2.new(1, 0, 0, 20); pcTop.BackgroundTransparency = 1; pcTop.ZIndex = 21
	local pcTitle = CreateTitle(pcTop, "PLAYER CONSUMABLES"); pcTitle.Size = UDim2.new(1, 0, 1, 0); pcTitle.TextXAlignment = Enum.TextXAlignment.Left

	playerConsContainer = Instance.new("ScrollingFrame", playerConsCard)
	playerConsContainer.Size = UDim2.new(1, 0, 1, -24); playerConsContainer.Position = UDim2.new(0,0,0,24); playerConsContainer.BackgroundTransparency = 1; playerConsContainer.ScrollBarThickness = 4; playerConsContainer.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120); playerConsContainer.ZIndex = 21
	local pcp = Instance.new("UIPadding", playerConsContainer); pcp.PaddingRight = UDim.new(0, 6); pcp.PaddingLeft = UDim.new(0, 2); pcp.PaddingTop = UDim.new(0, 2); pcp.PaddingBottom = UDim.new(0, 2)
	Instance.new("UIListLayout", playerConsContainer).Padding = UDim.new(0, 4)

	local standTabContent = Instance.new("Frame", tabContainer)
	standTabContent.Name = "StandTabContent"; standTabContent.Size = UDim2.new(1, 0, 1, 0); standTabContent.BackgroundTransparency = 1; standTabContent.Visible = false
	local sTL = Instance.new("UIListLayout", standTabContent); sTL.FillDirection = Enum.FillDirection.Vertical; sTL.SortOrder = Enum.SortOrder.LayoutOrder; sTL.Padding = UDim.new(0.02, 0)

	local standInfoCard = CreateCard("StandInfoCard", standTabContent, UDim2.new(1, 0, 0.24, 0), 1)
	local sIL = Instance.new("UIListLayout", standInfoCard)
	sIL.FillDirection = Enum.FillDirection.Vertical; sIL.HorizontalAlignment = Enum.HorizontalAlignment.Center; sIL.VerticalAlignment = Enum.VerticalAlignment.Center; sIL.Padding = UDim.new(0, 6)

	standBox, standLabel, standLockBtn = createLoadRow("Stand", standInfoCard, 0.35)
	local xpBoxS; xpBoxS, xpLabelS, _ = createLoadRow("XP", standInfoCard, 0.35)

	local standMidRow = Instance.new("Frame", standTabContent)
	standMidRow.Size = UDim2.new(1, 0, 0.44, 0); standMidRow.BackgroundTransparency = 1; standMidRow.LayoutOrder = 2

	local sStatsCard = CreateCard("StandStatsCard", standMidRow, UDim2.new(0.48, 0, 1, 0), 1)
	sStatsCard.Position = UDim2.new(0, 0, 0, 0)

	AttachStatsControls(sStatsCard, "STAND STATS")
	sStatsContainer = Instance.new("Frame", sStatsCard)
	sStatsContainer.Size = UDim2.new(1, 0, 1, -24); sStatsContainer.Position = UDim2.new(0, 0, 0, 24); sStatsContainer.BackgroundTransparency = 1; sStatsContainer.ZIndex = 21
	Instance.new("UIListLayout", sStatsContainer).Padding = UDim.new(0, 0)
	for _, stat in ipairs(standStatsList) do statLabels[stat] = CreateStatRow(stat, sStatsContainer, true) end

	local standStorageCard = CreateCard("StandStorageCard", standMidRow, UDim2.new(0.48, 0, 1, 0), 2)
	standStorageCard.AnchorPoint = Vector2.new(1, 0)
	standStorageCard.Position = UDim2.new(1, 0, 0, 0)

	CreateTitle(standStorageCard, "STAND STORAGE")
	standStorageContainer = Instance.new("Frame", standStorageCard)
	standStorageContainer.Size = UDim2.new(1, 0, 1, -24); standStorageContainer.Position = UDim2.new(0,0,0,24); standStorageContainer.BackgroundTransparency = 1; standStorageContainer.ZIndex = 21
	Instance.new("UIListLayout", standStorageContainer).Padding = UDim.new(0, 0)

	local standBotRow = Instance.new("Frame", standTabContent)
	standBotRow.Size = UDim2.new(1, 0, 0.28, 0); standBotRow.BackgroundTransparency = 1; standBotRow.LayoutOrder = 3

	local standConsCard = CreateCard("StandConsCard", standBotRow, UDim2.new(0.63, 0, 1, 0), 1)
	standConsCard.Position = UDim2.new(0, 0, 0, 0)

	local scTop = Instance.new("Frame", standConsCard); scTop.Size = UDim2.new(1, 0, 0, 20); scTop.BackgroundTransparency = 1; scTop.ZIndex = 21
	local scTitle = CreateTitle(scTop, "STAND CONSUMABLES"); scTitle.Size = UDim2.new(1, 0, 1, 0); scTitle.TextXAlignment = Enum.TextXAlignment.Left

	standConsContainer = Instance.new("ScrollingFrame", standConsCard)
	standConsContainer.Size = UDim2.new(1, 0, 1, -24); standConsContainer.Position = UDim2.new(0,0,0,24); standConsContainer.BackgroundTransparency = 1; standConsContainer.ScrollBarThickness = 4; standConsContainer.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120); standConsContainer.ZIndex = 21
	local scp = Instance.new("UIPadding", standConsContainer); scp.PaddingRight = UDim.new(0, 6); scp.PaddingLeft = UDim.new(0, 2); scp.PaddingTop = UDim.new(0, 2); scp.PaddingBottom = UDim.new(0, 2)
	Instance.new("UIListLayout", standConsContainer).Padding = UDim.new(0, 4)

	local autoRollCard = CreateCard("AutoRollCard", standBotRow, UDim2.new(0.35, 0, 1, 0), 2)
	autoRollCard.AnchorPoint = Vector2.new(1, 0)
	autoRollCard.Position = UDim2.new(1, 0, 0, 0)
	autoRollCard.ClipsDescendants = false

	CreateTitle(autoRollCard, "AUTO ROLL")

	local arContent = Instance.new("Frame", autoRollCard)
	arContent.Size = UDim2.new(1, 0, 1, -24); arContent.Position = UDim2.new(0,0,0,24); arContent.BackgroundTransparency = 1; arContent.ZIndex = 21
	local arL = Instance.new("UIGridLayout", arContent)
	arL.CellSize = UDim2.new(0.48, 0, 0.42, 0); arL.CellPadding = UDim2.new(0.04, 0, 0.1, 0); arL.SortOrder = Enum.SortOrder.LayoutOrder

	local function createDrop(name, text, orderIdx)
		local btn = Instance.new("TextButton", arContent)
		btn.Name = name; btn.LayoutOrder = orderIdx; btn.BackgroundColor3 = Color3.fromRGB(40, 20, 60); btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.GothamBold; btn.TextScaled = true; btn.Text = text; btn.ZIndex = 25
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		local s = Instance.new("UIStroke", btn); s.Color = Color3.fromRGB(120, 60, 180); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Instance.new("UITextSizeConstraint", btn).MaxTextSize = 12

		local list = Instance.new("ScrollingFrame", btn)
		list.Name = "List"; list.Size = UDim2.new(1, 0, 0, 120); list.AnchorPoint = Vector2.new(0, 1); list.Position = UDim2.new(0, 0, 0, -2); list.BackgroundColor3 = Color3.fromRGB(30, 15, 50); list.ZIndex = 50; list.Visible = false; list.ScrollBarThickness = 4
		Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
		local ls = Instance.new("UIStroke", list); ls.Color = Color3.fromRGB(120, 60, 180); ls.Thickness = 1; ls.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		return btn
	end

	local sDrop = createDrop("StandDropdown", "Stand: Any", 1)
	local tDrop = createDrop("TraitDropdown", "Trait: Any", 2)

	local function createRollBtn(name, text, color, orderIdx)
		local btn = Instance.new("TextButton", arContent)
		btn.Name = name; btn.LayoutOrder = orderIdx; btn.BackgroundColor3 = color; btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.GothamBold; btn.TextScaled = true; btn.Text = text; btn.ZIndex = 25
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		local s = Instance.new("UIStroke", btn); s.Color = Color3.new(1,1,1); s.Thickness = 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		Instance.new("UITextSizeConstraint", btn).MaxTextSize = 12
		return btn
	end

	local btnRollStand = createRollBtn("RollStandBtn", "Roll Stand", Color3.fromRGB(200, 150, 0), 3)
	local btnRollTrait = createRollBtn("RollTraitBtn", "Roll Trait", Color3.fromRGB(200, 50, 150), 4)

	local camera = workspace.CurrentCamera
	local UpdateLayoutForScreen = function()
		if not parentFrame.Parent then return end
		local vp = camera.ViewportSize
		if vp.X >= 1050 then mainPanel.Size = UDim2.new(0.80, 0, 0.88, 0); mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
		elseif vp.X >= 600 and vp.X < 1050 then mainPanel.Size = UDim2.new(0.92, 0, 0.82, 0); mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
		else mainPanel.Size = UDim2.new(0.96, 0, 0.82, 0); mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0) end

		local panelAbsHeight = vp.Y * mainPanel.Size.Y.Scale
		local minHeight = 600

		if panelAbsHeight < minHeight then
			innerContent.CanvasSize = UDim2.new(0, 0, 0, minHeight)
			innerContent.ScrollBarImageTransparency = 0
			innerContent.ScrollingEnabled = true
		else
			innerContent.CanvasSize = UDim2.new(0, 0, 1, 0)
			innerContent.ScrollBarImageTransparency = 1
			innerContent.ScrollingEnabled = false
		end
	end

	camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
	UpdateLayoutForScreen()

	local function SetActiveTab(target)
		SFXManager.Play("Click")
		invTabContent.Visible = (target == "INV")
		playerTabContent.Visible = (target == "PLAYER")
		standTabContent.Visible = (target == "STAND")

		local function ToggleNav(btn, str, isActive)
			btn.BackgroundColor3 = isActive and Color3.fromRGB(70, 30, 100) or Color3.fromRGB(30, 20, 50)
			btn.TextColor3 = isActive and Color3.fromRGB(255, 235, 130) or Color3.fromRGB(200, 200, 220)
			str.Color = isActive and Color3.fromRGB(255, 215, 50) or Color3.fromRGB(90, 50, 120)
			str.Thickness = isActive and 2 or 1
		end

		ToggleNav(invTabBtn, invStr, target == "INV")
		ToggleNav(playerTabBtn, playerStr, target == "PLAYER")
		ToggleNav(standTabBtn, standStr, target == "STAND")
	end

	invTabBtn.MouseButton1Click:Connect(function() SetActiveTab("INV") end)
	playerTabBtn.MouseButton1Click:Connect(function() SetActiveTab("PLAYER") end)
	standTabBtn.MouseButton1Click:Connect(function() SetActiveTab("STAND") end)
	SetActiveTab("INV")

	BuildDropdownList(sDrop, sDrop:WaitForChild("List"), StandData.Stands, true)
	BuildDropdownList(tDrop, tDrop:WaitForChild("List"), StandData.Traits, false)

	local function HandleAutoRollRequest(rollType)
		SFXManager.Play("Click")
		if not player:GetAttribute("HasAutoRoll") then MarketplaceService:PromptGamePassPurchase(player, 1749484465); return end
		local r = Network:FindFirstChild("AutoRoll")
		if r then r:FireServer(rollType, targetAutoStand, targetAutoTrait) end
	end

	btnRollStand.MouseButton1Click:Connect(function() HandleAutoRollRequest("Stand") end)
	btnRollTrait.MouseButton1Click:Connect(function() HandleAutoRollRequest("Trait") end)

	standLockBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); local remote = Network:FindFirstChild("ToggleLock"); if remote then remote:FireServer("Stand") end end)
	styleLockBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); local remote = Network:FindFirstChild("ToggleLock"); if remote then remote:FireServer("Style") end end)

	for _, r in ipairs(raritiesToSell) do
		local btn = autoSellContainer:WaitForChild("AutoSell_" .. r)

		local function updateBtn()
			if player:GetAttribute("AutoSell_" .. r) then
				btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
			else
				btn.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
			end
		end

		btn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			local AutoSellEvent = Network:FindFirstChild("AutoSellToggle")
			if AutoSellEvent then AutoSellEvent:FireServer(r) end
		end)
		player:GetAttributeChangedSignal("AutoSell_" .. r):Connect(updateBtn)
		updateBtn()
	end

	standBox.MouseEnter:Connect(function()
		local sName = player:GetAttribute("Stand") or "None"
		local sTrait = player:GetAttribute("StandTrait") or "None"
		if sName == "None" then return end
		if sName == "Fused Stand" then
			local fs1 = player:GetAttribute("Active_FusedStand1") or "Unknown"
			local fs2 = player:GetAttribute("Active_FusedStand2") or "Unknown"
			local ft1 = player:GetAttribute("Active_FusedTrait1") or "None"
			local ft2 = player:GetAttribute("Active_FusedTrait2") or "None"

			local display = FusionUtility.CalculateFusedName(fs1, fs2)
			local tData1 = StandData.Traits[ft1]
			local tData2 = StandData.Traits[ft2]
			local desc1 = tData1 and tData1.Desc or ""
			local desc2 = tData2 and tData2.Desc or ""
			local color1 = tData1 and tData1.Color or "#FFFFFF"
			local color2 = tData2 and tData2.Color or "#FFFFFF"

			local combinedDesc = "Fused Stand\n\n"
			if ft1 ~= "None" then combinedDesc = combinedDesc .. "<font color='"..color1.."'>["..ft1.."]</font>: " .. desc1 .. "\n" end
			if ft2 ~= "None" then combinedDesc = combinedDesc .. "<font color='"..color2.."'>["..ft2.."]</font>: " .. desc2 .. "\n" end

			cachedTooltipMgr.Show("<b><font color='#A020F0'>" .. display .. "</font></b>\n____________________\n\n" .. combinedDesc)
			return
		end

		local tData = StandData.Traits[sTrait]
		local desc = tData and tData.Desc or "No special traits."
		local color = tData and tData.Color or "#FFFFFF"
		local rarity = tData and tData.Rarity or "None"
		local rarityText = ""
		if rarity ~= "None" then rarityText = " <font color='#AAAAAA'>[" .. rarity .. "]</font>" end
		cachedTooltipMgr.Show("<b><font color='#A020F0'>" .. sName .. "</font></b>\nTrait: <font color='" .. color .. "'>" .. sTrait .. "</font>" .. rarityText .. "\n____________________\n\n" .. desc)
	end)
	standBox.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

	styleBox.MouseEnter:Connect(function()
		local style = player:GetAttribute("FightingStyle") or "None"
		if style == "None" then return end
		local sData = GameData.StyleBonuses[style]
		local desc = "<b><font color='#FF8C00'>" .. style .. "</font></b>\n____________________\n\n"
		if sData then for stat, val in pairs(sData) do desc = desc .. "<font color='#55FF55'>+" .. val .. " " .. stat .. "</font>\n" end else desc = desc .. "No stat bonuses." end
		cachedTooltipMgr.Show(desc)
	end)
	styleBox.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

	weaponBox.MouseEnter:Connect(function() local wpn = player:GetAttribute("EquippedWeapon") or "None"; if wpn ~= "None" then cachedTooltipMgr.Show(cachedTooltipMgr.GetItemTooltip(wpn)) end end)
	weaponBox.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

	accBox.MouseEnter:Connect(function() local acc = player:GetAttribute("EquippedAccessory") or "None"; if acc ~= "None" then cachedTooltipMgr.Show(cachedTooltipMgr.GetItemTooltip(acc)) end end)
	accBox.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)

	player:GetAttributeChangedSignal("XP"):Connect(UpdateTopDisplays)
	player:GetAttributeChangedSignal("FightingStyle"):Connect(function() UpdateTopDisplays(); RefreshStorageList() end)
	player:GetAttributeChangedSignal("GangInvBoost"):Connect(RefreshInventoryList)
	player:GetAttributeChangedSignal("Has2xInventory"):Connect(RefreshInventoryList)
	player:GetAttributeChangedSignal("EquippedWeapon"):Connect(function() UpdateTopDisplays(); RefreshInventoryList() end)
	player:GetAttributeChangedSignal("EquippedAccessory"):Connect(function() UpdateTopDisplays(); RefreshInventoryList() end)
	player:GetAttributeChangedSignal("Stand"):Connect(function() UpdateTopDisplays(); RefreshStatTexts(); RefreshStorageList() end)
	player:GetAttributeChangedSignal("StandTrait"):Connect(function() UpdateTopDisplays(); RefreshStorageList() end)

	for i = 1, 5 do player:GetAttributeChangedSignal("StoredStand"..i):Connect(RefreshStorageList) end
	for i = 1, 3 do player:GetAttributeChangedSignal("StoredStyle"..i):Connect(RefreshStorageList) end

	player:GetAttributeChangedSignal("HasStandSlot2"):Connect(RefreshStorageList)
	player:GetAttributeChangedSignal("HasStandSlot3"):Connect(RefreshStorageList)
	player:GetAttributeChangedSignal("HasStyleSlot2"):Connect(RefreshStorageList)
	player:GetAttributeChangedSignal("HasStyleSlot3"):Connect(RefreshStorageList)
	player:GetAttributeChangedSignal("StandLocked"):Connect(UpdateTopDisplays)
	player:GetAttributeChangedSignal("StyleLocked"):Connect(UpdateTopDisplays)
	player:GetAttributeChangedSignal("LockedItems"):Connect(RefreshInventoryList)

	for _, stat in ipairs(allStatsToUpgrade) do player:GetAttributeChangedSignal(stat):Connect(RefreshStatTexts) end
	for _, item in ipairs(KnownItems) do player:GetAttributeChangedSignal(item:gsub("[^%w]", "").."Count"):Connect(RefreshInventoryList) end

	task.spawn(function()
		local pObj = player:WaitForChild("leaderstats", 5)
		if pObj then 
			pObj:WaitForChild("Prestige", 5).Changed:Connect(function() RefreshStatTexts(); RefreshInventoryList(); RefreshStorageList() end)
			pObj:WaitForChild("Yen", 5).Changed:Connect(UpdateTopDisplays) 
		end
		UpdateTopDisplays(); RefreshStatTexts(); RefreshInventoryList(); RefreshStorageList()
	end)

	parentFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if parentFrame.Visible then
			UpdateTopDisplays()
			RefreshStatTexts()
			RefreshInventoryList()
			RefreshStorageList()
		end
	end)
end

return InventoryTab