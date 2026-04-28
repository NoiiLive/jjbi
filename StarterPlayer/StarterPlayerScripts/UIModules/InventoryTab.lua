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
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))

local pStatsContainer, sStatsContainer, equipContainer, playerConsContainer, standConsContainer
local standStorageContainer, styleStorageContainer, autoSellContainer
local titlesTabContent, indexTabContent
local capacityLabel, playerConsCapacityLabel
local statLabels = {}

local standLabel, styleLabel, weaponLabel, accLabel, xpLabelP, xpLabelS, yenLabel
local standBox, styleBox, weaponBox, accBox
local standLockBtn, styleLockBtn, openTreeBtn

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
	Unique = Color3.fromRGB(215, 69, 255),
	Special = Color3.fromRGB(239, 255, 62),
	Evolution = Color3.fromRGB(239, 255, 62),
}

local raritySortTiers = { Special = 500, Unique = 1000, Mythical = 2000, Legendary = 3000, Rare = 4000, Uncommon = 5000, Common = 6000 }
local indexRaritySortTiers = { Common = 1, Uncommon = 2, Rare = 3, Legendary = 4, Mythical = 5, Evolution = 6, Unique = 7, Special = 8, None = 9 }

local PartSortOrder = {
	["Part 1"] = 1, ["Part 2"] = 2, ["Part 3"] = 3, ["Part 4"] = 4, 
	["Part 5"] = 5, ["Part 6"] = 6, ["Part 7"] = 7, ["Part 8"] = 8, 
	["Non-Canon"] = 9, ["Event"] = 10
}

local PartColors = {
	["Part 1"] = { StrokeStart = Color3.fromRGB(80, 87, 158), StrokeEnd = Color3.fromRGB(46, 51, 116), BGStart = Color3.fromRGB(80, 87, 158), BGEnd = Color3.fromRGB(46, 51, 116) },
	["Part 2"] = { StrokeStart = Color3.fromRGB(255, 215, 101), StrokeEnd = Color3.fromRGB(91, 154, 84), BGStart = Color3.fromRGB(255, 215, 101), BGEnd = Color3.fromRGB(91, 154, 84) },
	["Part 3"] = { StrokeStart = Color3.fromRGB(167, 160, 215), StrokeEnd = Color3.fromRGB(67, 60, 104), BGStart = Color3.fromRGB(167, 160, 215), BGEnd = Color3.fromRGB(67, 60, 104) },
	["Part 4"] = { StrokeStart = Color3.fromRGB(199, 235, 241), StrokeEnd = Color3.fromRGB(148, 90, 99), BGStart = Color3.fromRGB(199, 235, 241), BGEnd = Color3.fromRGB(148, 90, 99) },
	["Part 5"] = { StrokeStart = Color3.fromRGB(255, 220, 113), StrokeEnd = Color3.fromRGB(151, 100, 236), BGStart = Color3.fromRGB(255, 220, 113), BGEnd = Color3.fromRGB(151, 100, 236) },
	["Part 6"] = { StrokeStart = Color3.fromRGB(150, 223, 231), StrokeEnd = Color3.fromRGB(58, 125, 61), BGStart = Color3.fromRGB(150, 223, 231), BGEnd = Color3.fromRGB(58, 125, 61) },
	["Part 7"] = { StrokeStart = Color3.fromRGB(218, 255, 79), StrokeEnd = Color3.fromRGB(55, 132, 14), BGStart = Color3.fromRGB(218, 255, 79), BGEnd = Color3.fromRGB(55, 132, 14) },
	["Part 8"] = { StrokeStart = Color3.fromRGB(221, 247, 252), StrokeEnd = Color3.fromRGB(164, 158, 239), BGStart = Color3.fromRGB(221, 247, 252), BGEnd = Color3.fromRGB(164, 158, 239) },
	["Non-Canon"] = { StrokeStart = Color3.fromRGB(232, 240, 83), StrokeEnd = Color3.fromRGB(200, 130, 84), BGStart = Color3.fromRGB(232, 240, 83), BGEnd = Color3.fromRGB(200, 130, 84) },
	["Event"] = { StrokeStart = Color3.fromRGB(218, 61, 63), StrokeEnd = Color3.fromRGB(126, 25, 49), BGStart = Color3.fromRGB(218, 61, 63), BGEnd = Color3.fromRGB(126, 25, 49) }
}

local playerStatsList = {"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower"}
local standStatsList = {"Stand_Power_Val", "Stand_Speed_Val", "Stand_Range_Val", "Stand_Durability_Val", "Stand_Precision_Val", "Stand_Potential_Val"}
local allStatsToUpgrade = {"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower", "Stand_Power_Val", "Stand_Speed_Val", "Stand_Range_Val", "Stand_Durability_Val", "Stand_Precision_Val", "Stand_Potential_Val"}

local KnownItems = {}
for itemName, _ in pairs(ItemData.Consumables) do table.insert(KnownItems, itemName) end
for eqName, _ in pairs(ItemData.Equipment) do table.insert(KnownItems, eqName) end

local Templates = ReplicatedStorage:WaitForChild("JJBITemplates")

local activeInvThread = nil
local activeIndexThread = nil

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

local function InstantiateStatRow(statName, parent, isStand)
	local row = Templates:WaitForChild("StatRowTemplate"):Clone()
	row.Name = statName
	row.Parent = parent

	local statLabel = row:WaitForChild("Label")
	statLabel.TextColor3 = isStand and Color3.fromRGB(200, 150, 255) or Color3.fromRGB(220, 220, 220)

	local btnContainer = row:WaitForChild("BtnContainer")
	local bAdd = btnContainer:WaitForChild("BtnAdd")
	local bMax = btnContainer:WaitForChild("BtnMax")

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
	for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

	local options = {"Any"}
	for name, data in pairs(dataTable) do
		if isStand then
			if data.Rarity ~= "Evolution" and data.Rarity ~= "Unique" and data.Rarity ~= "Mythical" then table.insert(options, name) end
		else
			if data.Rarity ~= "Unique" then table.insert(options, name) end
		end
	end
	table.sort(options)

	for _, opt in ipairs(options) do
		local b = Templates:WaitForChild("DropdownOptionTemplate"):Clone()
		b.Text = opt
		b.Parent = listFrame
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
		{ Backend = 5, IsUnlocked = (prestige >= 30), Type = "Prestige", Req = 30 },
		{ Backend = "VIP", IsUnlocked = player:GetAttribute("IsVIP"), Type = "VIP", Prefix = "VIP" }
	}

	local styleSlots = {
		{ Backend = 1, IsUnlocked = true, Type = "Base" },
		{ Backend = 2, IsUnlocked = player:GetAttribute("HasStyleSlot2"), Type = "Robux", PassId = 1746853452 },
		{ Backend = 3, IsUnlocked = player:GetAttribute("HasStyleSlot3"), Type = "Robux", PassId = 1745969849 },
		{ Backend = "VIP", IsUnlocked = player:GetAttribute("IsVIP"), Type = "VIP", Prefix = "VIP" }
	}

	local function RenderSlots(slotsTable, container, isStand)
		for visualNum, slotData in ipairs(slotsTable) do
			local row = Templates:WaitForChild("StorageSlotTemplate"):Clone()
			row.Parent = container

			local prefix = slotData.Prefix or ("S"..visualNum)

			local nameLabel = row:WaitForChild("NameLabel")
			local btn = row:WaitForChild("ActionBtn")

			if slotData.IsUnlocked then
				if isStand then
					local storedName = player:GetAttribute("StoredStand"..tostring(slotData.Backend)) or "None"
					local storedTrait = player:GetAttribute("StoredStand"..tostring(slotData.Backend).."_Trait") or "None"
					local traitDisplay = ""

					if storedName == "Fused Stand" then
						local fs1 = player:GetAttribute("StoredStand"..tostring(slotData.Backend).."_FusedStand1") or "Unknown"
						local fs2 = player:GetAttribute("StoredStand"..tostring(slotData.Backend).."_FusedStand2") or "Unknown"
						local ft1 = player:GetAttribute("StoredStand"..tostring(slotData.Backend).."_FusedTrait1") or "None"
						local ft2 = player:GetAttribute("StoredStand"..tostring(slotData.Backend).."_FusedTrait2") or "None"

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

					nameLabel.Text = prefix..": <font color='#A020F0'>" .. storedName .. "</font>" .. traitDisplay
					local realStoredName = player:GetAttribute("StoredStand"..tostring(slotData.Backend)) or "None"
					if realStoredName == "None" and (player:GetAttribute("Stand") or "None") == "None" then
						btn.Text = "Empty"; btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					else
						btn.Text = realStoredName == "None" and "Store" or "Swap"; btn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
						btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network:WaitForChild("StandStorageAction"):FireServer("Swap", slotData.Backend) end)
					end
				else
					local storedName = player:GetAttribute("StoredStyle"..tostring(slotData.Backend)) or "None"
					nameLabel.Text = prefix..": <font color='#FF8C00'>" .. storedName .. "</font>"
					if storedName == "None" and (player:GetAttribute("FightingStyle") or "None") == "None" then
						btn.Text = "Empty"; btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
					else
						btn.Text = storedName == "None" and "Store" or "Swap"; btn.BackgroundColor3 = Color3.fromRGB(180, 80, 20)
						btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network:WaitForChild("StandStorageAction"):FireServer("SwapStyle", slotData.Backend) end)
					end
				end
			else
				if slotData.Type == "Prestige" then
					nameLabel.Text = prefix..": <font color='#FF5555'>Locked (P."..slotData.Req..")</font>"
					btn.Text = "Lock"; btn.BackgroundColor3 = Color3.fromRGB(100, 50, 50); btn.AutoButtonColor = false
				elseif slotData.Type == "VIP" then
					nameLabel.Text = prefix..": <font color='#FFD700'>Locked (VIP)</font>"
					btn.Text = "Buy"; btn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
					btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); MarketplaceService:PromptGamePassPurchase(player, 1772743731) end)
				else
					nameLabel.Text = prefix..": <font color='#FF5555'>Locked (R$)</font>"
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
	if activeInvThread then
		task.cancel(activeInvThread)
		activeInvThread = nil
	end

	activeInvThread = task.spawn(function()
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
					if ItemData.Equipment[itemName].Rarity ~= "Unique" and ItemData.Equipment[itemName].Rarity ~= "Special" then
						currentInvCount += count
					end
				elseif ItemData.Consumables[itemName] then
					if ItemData.Consumables[itemName].Category == "Stand" then 
						table.insert(standConsItems, {Name = itemName, Count = count})
					else 
						table.insert(playerConsItems, {Name = itemName, Count = count}) 
						if ItemData.Consumables[itemName].Rarity ~= "Unique" and ItemData.Consumables[itemName].Rarity ~= "Special" then
							currentInvCount += count
						end
					end
				end
			end
		end

		table.sort(equipItems, sortItemsFunc)
		table.sort(playerConsItems, sortItemsFunc)
		table.sort(standConsItems, sortItemsFunc)

		equipContainer.CanvasSize = UDim2.new(0, 0, 0, (#equipItems * 34) + 10)
		playerConsContainer.CanvasSize = UDim2.new(0, 0, 0, (#playerConsItems * 34) + 10)
		standConsContainer.CanvasSize = UDim2.new(0, 0, 0, (#standConsItems * 34) + 10)

		if capacityLabel then
			local maxInv = GameData.GetMaxInventory(player)
			capacityLabel.Text = "Capacity: " .. currentInvCount .. "/" .. maxInv
		end

		if playerConsCapacityLabel then
			local maxInv = GameData.GetMaxInventory(player)
			playerConsCapacityLabel.Text = "Capacity: " .. currentInvCount .. "/" .. maxInv
		end

		local function RenderItem(itemName, count, container, orderIdx)
			local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
			local rarity = itemData and itemData.Rarity or "Common"

			local itemFrame = Templates:WaitForChild("InventoryItemTemplate"):Clone()
			itemFrame.LayoutOrder = orderIdx
			itemFrame.Parent = container

			local str = itemFrame:WaitForChild("UIStroke")
			str.Color = rarityColors[rarity] or rarityColors.Common

			local nameLabel = itemFrame:WaitForChild("NameLabel")
			nameLabel.TextColor3 = rarityColors[rarity] or rarityColors.Common
			nameLabel.Text = itemName .. " (x" .. count .. ")"

			local btnWrapper = itemFrame:WaitForChild("BtnWrapper")
			local useBtn = btnWrapper:WaitForChild("UseBtn")
			local sellBtn = btnWrapper:WaitForChild("SellBtn")
			local sellAllBtn = btnWrapper:WaitForChild("SellAllBtn")
			local lockBtn = btnWrapper:WaitForChild("LockBtn")

			useBtn.Text = ItemData.Equipment[itemName] and "Equip" or "Use"

			local lockedItems = player:GetAttribute("LockedItems") or ""
			local isLocked = table.find(string.split(lockedItems, ","), itemName) ~= nil

			if isLocked then
				lockBtn.Text = "🔒"; lockBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
			else
				lockBtn.Text = "🔓"; lockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			end

			if isLocked or rarity == "Special" then
				sellBtn.Visible = false
				sellAllBtn.Visible = false
			else
				sellBtn.Visible = true
				sellBtn.Text = "Sell 1"
				sellBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)

				if count > 1 then
					sellAllBtn.Visible = true
					sellAllBtn.Text = "Sell All"
					sellAllBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
				else
					sellAllBtn.Visible = false
				end
			end

			lockBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network:WaitForChild("ToggleLock"):FireServer("Item", itemName) end)

			local isEquipped = ItemData.Equipment[itemName] and player:GetAttribute("Equipped" .. ItemData.Equipment[itemName].Slot) == itemName
			local isEquipment = ItemData.Equipment[itemName] ~= nil
			local isConfirmingUse, isConfirmingSell, isConfirmingSellAll = false, false, false

			if isEquipped then
				useBtn.Visible = true
				useBtn.Text = "Unequip"; useBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
				useBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network:WaitForChild("UnequipItem"):FireServer(ItemData.Equipment[itemName].Slot) end)
			else
				if isLocked and not isEquipment then
					useBtn.Visible = false
				else
					useBtn.Visible = true
					useBtn.MouseButton1Click:Connect(function()
						if isLocked and not isEquipment then return end
						if useBtn.Text == "Equip" then
							SFXManager.Play("Click"); Network:WaitForChild("UseItem"):FireServer(itemName, targetAutoStand, targetAutoTrait)
						else
							if ItemData.Consumables[itemName] and not isConfirmingUse then
								isConfirmingUse = true; useBtn.Text = "Confirm?"; useBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
								task.delay(3, function() if isConfirmingUse and useBtn.Parent then isConfirmingUse = false; useBtn.Text = "Use"; useBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0) end end)
								return
							end
							isConfirmingUse = false; SFXManager.Play("Click"); Network:WaitForChild("UseItem"):FireServer(itemName, targetAutoStand, targetAutoTrait)
						end
					end)
				end
			end

			sellBtn.MouseButton1Click:Connect(function()
				if isLocked or rarity == "Special" then return end
				if not isConfirmingSell then
					isConfirmingSell = true; sellBtn.Text = "Sure?"; sellBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
					task.delay(3, function() if isConfirmingSell and sellBtn.Parent then isConfirmingSell = false; sellBtn.Text = "Sell 1"; sellBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40) end end)
					return
				end
				isConfirmingSell = false; SFXManager.Play("Click"); cachedTooltipMgr.Hide()

				Network:WaitForChild("ShopAction"):FireServer("Sell", itemName)
				local iData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
				local sellVal = iData and (iData.SellPrice or math.floor((iData.Cost or 50) / 2)) or 25
				NotificationManager.Show("<font color='#55FF55'>Sold " .. itemName .. " for ¥" .. sellVal .. "!</font>")
			end)

			sellAllBtn.MouseButton1Click:Connect(function()
				if isLocked or rarity == "Special" or count <= 1 then return end
				if not isConfirmingSellAll then
					isConfirmingSellAll = true; sellAllBtn.Text = "Sure?"; sellAllBtn.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
					task.delay(3, function() if isConfirmingSellAll and sellAllBtn.Parent then isConfirmingSellAll = false; sellAllBtn.Text = "Sell All"; sellAllBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40) end end)
					return
				end
				isConfirmingSellAll = false; SFXManager.Play("Click"); cachedTooltipMgr.Hide()

				Network:WaitForChild("ShopAction"):FireServer("SellAll", itemName)
			end)

			itemFrame.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetItemTooltip(itemName)) end)
			itemFrame.MouseLeave:Connect(cachedTooltipMgr.Hide)
		end

		local renderCount = 0
		local function checkYield()
			renderCount += 1
			if renderCount % 15 == 0 then task.wait() end
		end

		for i, item in ipairs(equipItems) do RenderItem(item.Name, item.Count, equipContainer, i); checkYield() end
		for i, item in ipairs(playerConsItems) do RenderItem(item.Name, item.Count, playerConsContainer, i); checkYield() end
		for i, item in ipairs(standConsItems) do RenderItem(item.Name, item.Count, standConsContainer, i); checkYield() end

		activeInvThread = nil
	end)
end

local function RefreshTitlesList()
	if not titlesTabContent then return end
	for _, child in pairs(titlesTabContent:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local unlockedTitles = string.split(player:GetAttribute("UnlockedTitles") or "", ",")
	local equippedTitle = player:GetAttribute("EquippedTitle") or "None"

	local layout = titlesTabContent:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout", titlesTabContent)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	end
	layout.Padding = UDim.new(0, 10)

	local padding = titlesTabContent:FindFirstChildOfClass("UIPadding")
	if not padding then
		padding = Instance.new("UIPadding", titlesTabContent)
	end
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 4)

	local titlesArray = {}
	for titleName, data in pairs(GameData.Titles) do
		table.insert(titlesArray, {Name = titleName, Data = data})
	end

	table.sort(titlesArray, function(a, b)
		return (a.Data.Order or 999) < (b.Data.Order or 999)
	end)

	for _, titleInfo in ipairs(titlesArray) do
		local titleName = titleInfo.Name
		local data = titleInfo.Data

		local isUnlocked = table.find(unlockedTitles, titleName) ~= nil

		if data.Secret and not isUnlocked then continue end

		local isEquipped = (equippedTitle == titleName)

		local row = Templates:WaitForChild("TitleRowTemplate"):Clone()
		row.LayoutOrder = isUnlocked and data.Order or (data.Order + 100)
		row.Parent = titlesTabContent

		local txtCont = row:WaitForChild("TextContainer")
		local nameLbl = txtCont:WaitForChild("NameLabel")
		local descLbl = txtCont:WaitForChild("DescLabel")
		local reqLbl = txtCont:WaitForChild("ReqLabel")

		local tColor = data.Color or "#FFFFFF"
		nameLbl.RichText = true
		nameLbl.Text = "<font color='"..tColor.."'>"..titleName.."</font>"
		descLbl.Text = data.Desc
		reqLbl.Text = isUnlocked and "<font color='#55FF55'>Unlocked!</font>" or ("Requires: " .. data.Requirement)

		local btn = row.ActionBtn
		local btnStroke = btn:FindFirstChild("UIStroke")

		if isUnlocked then
			btn.AutoButtonColor = true
			if isEquipped then
				btn.Text = "Unequip"
				btn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
				if btnStroke then btnStroke.Color = Color3.fromRGB(255, 120, 120) end
			else
				btn.Text = "Equip"
				btn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
				if btnStroke then btnStroke.Color = Color3.fromRGB(120, 255, 120) end
			end
			btn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				Network:WaitForChild("CollectionAction"):FireServer("ToggleTitle", titleName)
			end)
		else
			btn.Visible = true
			btn.Text = "Locked"
			btn.BackgroundColor3 = Color3.fromRGB(30, 25, 35)
			btn.TextColor3 = Color3.fromRGB(100, 100, 100)
			btn.AutoButtonColor = false
			if btnStroke then btnStroke.Color = Color3.fromRGB(50, 40, 60) end

			btn.MouseButton1Click:Connect(function() end)
			row.BackgroundColor3 = Color3.fromRGB(20, 15, 25)
		end
	end

	titlesTabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
	titlesTabContent.CanvasSize = UDim2.new(0, 0, 0, 0)

	local spacer = Instance.new("Frame")
	spacer.Name = "MobileSpacer"
	spacer.BackgroundTransparency = 1
	spacer.Size = UDim2.new(1, 0, 0, 150)
	spacer.LayoutOrder = 99999
	spacer.Parent = titlesTabContent
end

local ShowFusionsList 

local function UpdateIndexLayout()
	if not indexTabContent then return end
	local screenWidth = indexTabContent.AbsoluteSize.X
	if screenWidth <= 0 then screenWidth = 900 end 

	local safeWidth = screenWidth - 40 
	local minCellSize = 75  
	local maxCellSize = 110 
	local cellPad = 10

	local cols = math.floor((safeWidth + cellPad) / (maxCellSize + cellPad))
	if safeWidth < 500 then
		cols = math.max(3, cols) 
	end

	local calculatedSize = math.floor((safeWidth - (cellPad * (cols - 1))) / cols)
	calculatedSize = math.clamp(calculatedSize, minCellSize, maxCellSize)

	local finalCols = math.floor((safeWidth + cellPad) / (calculatedSize + cellPad))
	if finalCols < 1 then finalCols = 1 end

	local yOffset = 0

	for _, category in ipairs(indexTabContent:GetChildren()) do
		if category:IsA("Frame") then
			local container = category:FindFirstChild("ItemsContainer")
			if container then
				local grid = container:FindFirstChildOfClass("UIGridLayout")
				if grid then
					grid.CellSize = UDim2.new(0, calculatedSize, 0, calculatedSize)

					local itemCount = tonumber(category:GetAttribute("TotalItems"))
					if not itemCount then
						itemCount = 0
						for _, item in ipairs(container:GetChildren()) do
							if item:IsA("Frame") then itemCount += 1 end
						end
					end

					local rows = math.ceil(itemCount / finalCols)
					local catHeight = 75 + (rows * (calculatedSize + cellPad))
					category.Size = UDim2.new(1, -24, 0, catHeight)
					yOffset += catHeight + 10
				end
			end
		end
	end

	indexTabContent.CanvasSize = UDim2.new(0, 0, 0, yOffset + 150)
end

local function RefreshIndexList()
	if not indexTabContent then return end

	if activeIndexThread then
		task.cancel(activeIndexThread)
		activeIndexThread = nil
	end

	activeIndexThread = task.spawn(function()
		for _, child in pairs(indexTabContent:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local layout = indexTabContent:FindFirstChildOfClass("UIListLayout")
		if not layout then
			layout = Instance.new("UIListLayout", indexTabContent)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
		end
		layout.Padding = UDim.new(0, 10)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local padding = indexTabContent:FindFirstChildOfClass("UIPadding")
		if not padding then
			padding = Instance.new("UIPadding", indexTabContent)
		end
		padding.PaddingTop = UDim.new(0, 4)
		padding.PaddingBottom = UDim.new(0, 4)
		padding.PaddingLeft = UDim.new(0, 4)
		padding.PaddingRight = UDim.new(0, 4)

		local unlockedIndex = string.split(player:GetAttribute("UnlockedIndex") or "", ",")
		local claimedBonuses = string.split(player:GetAttribute("ClaimedIndexBonuses") or "", ",")
		local unlockedFusionsStr = player:GetAttribute("UnlockedFusions") or ""
		local unlockedFusionsList = string.split(unlockedFusionsStr, ",")

		local totalValidFusions = 0
		local validStands = {}
		local requiredStands = {}
		for sName, sData in pairs(StandData.Stands) do
			if sData.Part and sData.Part ~= "" and sData.Part ~= "None" then
				validStands[sName] = true
				if sData.Rarity ~= "Unique" then
					requiredStands[sName] = true
					totalValidFusions += 1
				end
			end
		end

		local parts = {"Part 1", "Part 2", "Part 3", "Part 4", "Part 5", "Part 6", "Part 7", "Part 8", "Non-Canon", "Event"}

		local PartNames = {
			["Part 1"] = "Phantom Blood",
			["Part 2"] = "Battle Tendency",
			["Part 3"] = "Stardust Crusaders",
			["Part 4"] = "Diamond is Unbreakable",
			["Part 5"] = "Golden Wind",
			["Part 6"] = "Stone Ocean",
			["Part 7"] = "Steel Ball Run",
			["Part 8"] = "JoJolion",
			["Non-Canon"] = "Non-Canon",
			["Event"] = "Event"
		}

		local renderCount = 0

		for i, partName in ipairs(parts) do
			local abilities = {}
			for sName, sData in pairs(StandData.Stands) do
				if sData.Part == partName then table.insert(abilities, {Name = sName, Type = "Stand", Rarity = sData.Rarity, Icon = sData.Icon}) end
			end
			for stName, stPart in pairs(GameData.StyleParts) do
				if stPart == partName then 
					local sIcon = GameData.StyleIcons and GameData.StyleIcons[stName] or ""
					table.insert(abilities, {Name = stName, Type = "Style", Rarity = "None", Icon = sIcon}) 
				end
			end

			table.sort(abilities, function(a, b)
				local tierA = indexRaritySortTiers[a.Rarity] or 99
				local tierB = indexRaritySortTiers[b.Rarity] or 99

				if a.Type == "Style" then tierA = 100 end
				if b.Type == "Style" then tierB = 100 end

				if tierA == tierB then return a.Name < b.Name end
				return tierA < tierB
			end)

			if #abilities > 0 then
				local unlockedCount = 0
				for _, ab in ipairs(abilities) do
					if table.find(unlockedIndex, ab.Name) then unlockedCount += 1 end
				end

				local category = Templates:WaitForChild("IndexCategoryTemplate"):Clone()
				category.LayoutOrder = i * 100
				category.Parent = indexTabContent

				local displayTitle = PartNames[partName] or partName
				category.Header.TitleLabel.Text = displayTitle .. " Collection (" .. unlockedCount .. "/" .. #abilities .. ")"


				local isClaimed = table.find(claimedBonuses, partName) ~= nil

				local bonusData = GameData.IndexCompletionBonuses[partName]
				local claimBtn = category.Header.ClaimBtn

				if bonusData then
					category.Header.BonusLabel.Text = partName .. " Bonus: " .. bonusData.Description
					local isClaimed = table.find(claimedBonuses, partName) ~= nil

					if unlockedCount >= #abilities then
						if isClaimed then
							claimBtn.Text = "Claimed"
							claimBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
							claimBtn.Active = false
						else
							claimBtn.Text = "Claim Bonus"
							claimBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
							claimBtn.MouseButton1Click:Connect(function()
								SFXManager.Play("Click")
								Network:WaitForChild("CollectionAction"):FireServer("ClaimIndex", partName)
							end)
						end
					else
						claimBtn.Visible = false
					end
				else
					category.Header.BonusLabel.Text = "Limited-Time Event Abilities"
					category.Header.BonusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
					claimBtn.Visible = false
				end

				local container = category.ItemsContainer
				local grid = Instance.new("UIGridLayout", container)
				grid.CellPadding = UDim2.new(0, 10, 0, 10)
				grid.HorizontalAlignment = Enum.HorizontalAlignment.Center

				category:SetAttribute("TotalItems", #abilities)
				UpdateIndexLayout()

				for _, ab in ipairs(abilities) do
					local isUnlocked = table.find(unlockedIndex, ab.Name) ~= nil
					local item = Templates:WaitForChild("IndexItemTemplate"):Clone()
					item.Parent = container

					local btnOverlay = item:FindFirstChild("ButtonOverlay")
					if btnOverlay then
						btnOverlay.Visible = false
					end

					if ab.Type == "Stand" then
						if btnOverlay then
							local standTreeBtn = btnOverlay:FindFirstChild("StandTreeBtn")
							local fusionsBtn = btnOverlay:FindFirstChild("FusionsBtn")
							local closeBtn = btnOverlay:FindFirstChild("CloseBtn")

							item.InputBegan:Connect(function(input)
								if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
									if not btnOverlay.Visible then
										SFXManager.Play("Click")
										btnOverlay.Visible = true
									end
								end
							end)

							if closeBtn then
								closeBtn.MouseButton1Click:Connect(function()
									SFXManager.Play("Click")
									btnOverlay.Visible = false
								end)
							end

							if fusionsBtn then
								fusionsBtn.MouseButton1Click:Connect(function()
									SFXManager.Play("Click")
									cachedTooltipMgr.Hide()
									ShowFusionsList(ab.Name)
								end)
							end

							if standTreeBtn then
								standTreeBtn.MouseButton1Click:Connect(function()
									SFXManager.Play("Click")
									local ev = ReplicatedStorage:FindFirstChild("OpenSkillTreeModal")
									if not ev then
										ev = Instance.new("BindableEvent")
										ev.Name = "OpenSkillTreeModal"
										ev.Parent = ReplicatedStorage
									end
									ev:Fire(ab.Name)
								end)
							end
						end
					end

					local iconLabel = item:FindFirstChild("Icon")
					if not iconLabel then
						iconLabel = Instance.new("ImageLabel", item)
						iconLabel.Name = "Icon"
						iconLabel.Size = UDim2.new(1, -10, 1, -35)
						iconLabel.Position = UDim2.new(0, 5, 0, 5)
						iconLabel.BackgroundTransparency = 1
						iconLabel.ZIndex = 40
						iconLabel.ScaleType = Enum.ScaleType.Fit
					end

					local qMark = iconLabel:FindFirstChild("QuestionMark")
					if not qMark then
						qMark = Instance.new("TextLabel", iconLabel)
						qMark.Name = "QuestionMark"
						qMark.Size = UDim2.new(1, 0, 1, 0)
						qMark.BackgroundTransparency = 1
						qMark.Text = "?"
						qMark.Font = Enum.Font.GothamBold
						qMark.TextScaled = true
						qMark.ZIndex = 41
					end

					local bgGradient = item:FindFirstChildOfClass("UIGradient")
					local strk = item:FindFirstChildOfClass("UIStroke")
					local strkGradient = strk and strk:FindFirstChildOfClass("UIGradient")

					if isUnlocked then
						local displayName = ab.Name
						local isCompleted = false

						if ab.Type == "Stand" and totalValidFusions > 0 then
							local collectedFusions = 0
							local seenFusions = {}
							for _, fStr in ipairs(unlockedFusionsList) do
								if fStr ~= "" then
									local parts = string.split(fStr, "|")
									if parts[1] == ab.Name and requiredStands[parts[2]] then
										if not seenFusions[parts[2]] then
											seenFusions[parts[2]] = true
											collectedFusions += 1
										end
									end
								end
							end
							if collectedFusions >= totalValidFusions then
								displayName = displayName .. " ⭐"
								isCompleted = true
							end
						end

						item.NameLabel.Text = displayName
						item.NameLabel.TextColor3 = (ab.Type == "Stand") and (rarityColors[ab.Rarity] or Color3.new(1,1,1)) or Color3.fromRGB(255, 140, 0)

						local pColors = PartColors[partName] or { StrokeStart = Color3.fromRGB(100, 100, 100), StrokeEnd = Color3.fromRGB(40, 40, 40), BGStart = Color3.fromRGB(45, 40, 50), BGEnd = Color3.fromRGB(40, 40, 40) }

						item.BackgroundColor3 = Color3.new(0.275, 0.275, 0.275)
						if bgGradient then
							bgGradient.Color = ColorSequence.new(pColors.BGStart, pColors.BGEnd)
						else
							item.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
						end

						if strk then strk.Color = Color3.new(1, 1, 1) end
						if strkGradient then
							if isCompleted then
								strkGradient.Color = ColorSequence.new(Color3.fromRGB(255, 235, 100), Color3.fromRGB(180, 140, 20))
							else
								strkGradient.Color = ColorSequence.new(pColors.StrokeStart, pColors.StrokeEnd)
							end
						elseif strk and isCompleted then
							strk.Color = Color3.fromRGB(255, 215, 0)
						end

						if ab.Icon and ab.Icon ~= "" then
							iconLabel.Image = ab.Icon
							qMark.Visible = false
						else
							iconLabel.Image = ""
							qMark.Visible = true 
							qMark.TextColor3 = Color3.fromRGB(150, 150, 150)
						end

						item.MouseEnter:Connect(function()
							if not (btnOverlay and btnOverlay.Visible) then
								cachedTooltipMgr.Show(cachedTooltipMgr.GetIndexTooltip(ab.Name, ab.Type, ab.Rarity))
							end
						end)
						item.MouseLeave:Connect(function()
							cachedTooltipMgr.Hide()
						end)
					else
						item.NameLabel.Text = "???"
						item.NameLabel.TextColor3 = Color3.fromRGB(100, 100, 100)

						item.BackgroundColor3 = Color3.new(0.275, 0.275, 0.275)
						if bgGradient then
							bgGradient.Color = ColorSequence.new(Color3.fromRGB(25, 20, 30), Color3.fromRGB(15, 10, 20))
						else
							item.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
						end

						if strk then strk.Color = Color3.new(1, 1, 1) end
						if strkGradient then
							strkGradient.Color = ColorSequence.new(Color3.fromRGB(50, 50, 50), Color3.fromRGB(25, 25, 25))
						end

						iconLabel.Image = ""
						qMark.Visible = true 
						qMark.TextColor3 = Color3.fromRGB(60, 60, 60) 
					end

					renderCount += 1
					if renderCount % 15 == 0 then task.wait() end
				end
				task.wait() 
			end
		end

		UpdateIndexLayout()
		activeIndexThread = nil
	end)
end

ShowFusionsList = function(standName)
	if not indexTabContent then return end

	if activeIndexThread then
		task.cancel(activeIndexThread)
		activeIndexThread = nil
	end

	activeIndexThread = task.spawn(function()
		for _, child in pairs(indexTabContent:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local layout = indexTabContent:FindFirstChildOfClass("UIListLayout")
		if not layout then
			layout = Instance.new("UIListLayout", indexTabContent)
			layout.SortOrder = Enum.SortOrder.LayoutOrder
		end
		layout.Padding = UDim.new(0, 10)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local padding = indexTabContent:FindFirstChildOfClass("UIPadding")
		if not padding then
			padding = Instance.new("UIPadding", indexTabContent)
		end
		padding.PaddingTop = UDim.new(0, 4)
		padding.PaddingBottom = UDim.new(0, 4)
		padding.PaddingLeft = UDim.new(0, 4)
		padding.PaddingRight = UDim.new(0, 4)

		local unlockedFusionsStr = player:GetAttribute("UnlockedFusions") or ""
		local unlockedFusionsList = string.split(unlockedFusionsStr, ",")

		local category = Templates:WaitForChild("IndexCategoryTemplate"):Clone()
		category.LayoutOrder = 1
		category.Parent = indexTabContent

		category.Header.TitleLabel.Text = standName .. " Fusions"
		category.Header.BonusLabel.Text = "Possible combinations using " .. standName
		category.Header.BonusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)

		local backBtn = category.Header.ClaimBtn
		backBtn.Visible = true
		backBtn.Text = "Back"
		backBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		backBtn.Active = true
		backBtn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			cachedTooltipMgr.Hide()
			RefreshIndexList()
		end)

		local container = category.ItemsContainer
		local grid = Instance.new("UIGridLayout", container)
		grid.CellPadding = UDim2.new(0, 10, 0, 10)
		grid.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local validStands = {}
		for sName, sData in pairs(StandData.Stands) do
			if sData.Part and sData.Part ~= "" and sData.Part ~= "None" then
				if sData.Rarity ~= "Unique" then
					table.insert(validStands, {Name = sName, Part = sData.Part})
				else
					local fusionString = standName .. "|" .. sName
					if table.find(unlockedFusionsList, fusionString) then
						table.insert(validStands, {Name = sName, Part = sData.Part})
					end
				end
			end
		end

		table.sort(validStands, function(a, b)
			local orderA = PartSortOrder[a.Part] or 99
			local orderB = PartSortOrder[b.Part] or 99
			if orderA == orderB then
				return a.Name < b.Name
			end
			return orderA < orderB
		end)

		category:SetAttribute("TotalItems", #validStands)
		UpdateIndexLayout()

		local renderCount = 0

		for _, sData in ipairs(validStands) do
			local s2Name = sData.Name
			local s2Part = sData.Part
			local fusionString = standName .. "|" .. s2Name
			local isUnlocked = table.find(unlockedFusionsList, fusionString) ~= nil

			local item = Templates:WaitForChild("IndexItemTemplate"):Clone()
			item.Parent = container

			local iconLabel = item:FindFirstChild("Icon")
			if not iconLabel then
				iconLabel = Instance.new("ImageLabel", item)
				iconLabel.Name = "Icon"
				iconLabel.Size = UDim2.new(1, -10, 1, -35)
				iconLabel.Position = UDim2.new(0, 5, 0, 5)
				iconLabel.BackgroundTransparency = 1
				iconLabel.ZIndex = 40
				iconLabel.ScaleType = Enum.ScaleType.Fit
			end

			local qMark = iconLabel:FindFirstChild("QuestionMark")
			if not qMark then
				qMark = Instance.new("TextLabel", iconLabel)
				qMark.Name = "QuestionMark"
				qMark.Size = UDim2.new(1, 0, 1, 0)
				qMark.BackgroundTransparency = 1
				qMark.Text = "?"
				qMark.Font = Enum.Font.GothamBold
				qMark.TextScaled = true
				qMark.ZIndex = 41
			end

			local bgGradient = item:FindFirstChildOfClass("UIGradient")
			local strk = item:FindFirstChildOfClass("UIStroke")
			local strkGradient = strk and strk:FindFirstChildOfClass("UIGradient")

			if isUnlocked then
				local fusedName = FusionUtility.CalculateFusedName(standName, s2Name)
				item.NameLabel.Text = fusedName
				item.NameLabel.TextColor3 = Color3.fromRGB(215, 69, 255)

				local pColors = PartColors[s2Part] or { StrokeStart = Color3.fromRGB(100, 100, 100), StrokeEnd = Color3.fromRGB(40, 40, 40), BGStart = Color3.fromRGB(45, 40, 50), BGEnd = Color3.fromRGB(40, 40, 40) }

				item.BackgroundColor3 = Color3.new(0.275, 0.275, 0.275)
				if bgGradient then
					bgGradient.Color = ColorSequence.new(pColors.BGStart, pColors.BGEnd)
				else
					item.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
				end

				if strk then strk.Color = Color3.new(1, 1, 1) end
				if strkGradient then
					strkGradient.Color = ColorSequence.new(pColors.StrokeStart, pColors.StrokeEnd)
				end

				iconLabel.Image = ""
				qMark.Visible = true 
				qMark.TextColor3 = Color3.fromRGB(150, 150, 150)
				qMark.Text = "F"

				item.MouseEnter:Connect(function()
					local skills = FusionUtility.CalculateFusedAbilities(standName, s2Name, SkillData)
					local tooltip = "<b><font color='#D745FF'>" .. fusedName .. "</font></b>\n<font color='#AAAAAA'>Fusion: " .. standName .. " + " .. s2Name .. "</font>\n____________________\n\n"

					if #skills == 0 then
						tooltip = tooltip .. "<font color='#AAAAAA'>No known abilities.</font>"
					else
						for i, sk in ipairs(skills) do
							local skData = sk.Data
							tooltip = tooltip .. "<b><font color='#55FF55'>[" .. sk.Name .. "]</font></b>\n"

							local details = {}
							if skData.Mult and skData.Mult > 0 then 
								table.insert(details, "DMG: <font color='#FFFFFF'>" .. skData.Mult .. "x</font>") 
							end
							if skData.Cooldown and skData.Cooldown > 0 then 
								table.insert(details, "CD: <font color='#FFFFFF'>" .. skData.Cooldown .. " turns</font>") 
							end

							if #details > 0 then
								tooltip = tooltip .. "<font color='#AAAAAA'>  • " .. table.concat(details, " | ") .. "</font>\n"
							end

							if skData.Effect then
								local cleanEffectName = skData.Effect:gsub("_", " ")
								local effectText = cleanEffectName

								if skData.Duration and skData.Duration > 0 then
									effectText = effectText .. " (" .. skData.Duration .. " turns)"
								end
								tooltip = tooltip .. "<font color='#FFAA55'>  • Effect: " .. effectText .. "</font>\n"
							end

							if i < #skills then
								tooltip = tooltip .. "\n"
							end
						end
					end

					cachedTooltipMgr.Show(tooltip)
				end)
				item.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)
			else
				item.NameLabel.Text = "???"
				item.NameLabel.TextColor3 = Color3.fromRGB(100, 100, 100)

				item.BackgroundColor3 = Color3.new(0.275, 0.275, 0.275)
				if bgGradient then
					bgGradient.Color = ColorSequence.new(Color3.fromRGB(25, 20, 30), Color3.fromRGB(15, 10, 20))
				else
					item.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
				end

				if strk then strk.Color = Color3.new(1, 1, 1) end
				if strkGradient then
					strkGradient.Color = ColorSequence.new(Color3.fromRGB(50, 50, 50), Color3.fromRGB(25, 25, 25))
				end

				iconLabel.Image = ""
				qMark.Visible = true 
				qMark.TextColor3 = Color3.fromRGB(60, 60, 60)
				qMark.Text = "?"

				item.MouseEnter:Connect(function()
					cachedTooltipMgr.Show("<b><font color='#888888'>Unknown Fusion</font></b>\n<font color='#AAAAAA'>Requires: " .. standName .. " + ???</font>")
				end)
				item.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)
			end

			renderCount += 1
			if renderCount % 15 == 0 then task.wait() end
		end

		UpdateIndexLayout()
		activeIndexThread = nil
	end)
end

local function UpdateTopDisplays()
	local realStandName = player:GetAttribute("Stand") or "None"
	local sName = realStandName
	local sTrait = player:GetAttribute("StandTrait") or "None"
	local style = player:GetAttribute("FightingStyle") or "None"
	local wpn = player:GetAttribute("EquippedWeapon") or "None"
	local acc = player:GetAttribute("EquippedAccessory") or "None"

	if openTreeBtn then
		openTreeBtn.Visible = (realStandName ~= "Fused Stand" and realStandName ~= "None")
	end

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

	local xpVal = player:GetAttribute("XP") or 0
	local preP = player:GetAttribute("PrestigePoints") or 0

	if xpLabelP then xpLabelP.Text = "<b>XP:</b> <font color='#55FFFF'>" .. xpVal .. "</font>   |   <font color='#FF55FF'>Tree Pts: " .. preP .. "</font>" end
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

function InventoryTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr
	local currentActiveTab = "INV"

	local mainPanel = parentFrame:WaitForChild("MainPanel")
	local innerContent = mainPanel:WaitForChild("InnerContent")

	local subNavFrame = innerContent:WaitForChild("SubNavFrame")
	local invTabBtn = subNavFrame:WaitForChild("INVButton")
	local playerTabBtn = subNavFrame:WaitForChild("PLAYERButton")
	local standTabBtn = subNavFrame:WaitForChild("STANDButton")
	local titlesTabBtn = subNavFrame:WaitForChild("TITLEButton")
	local indexTabBtn = subNavFrame:WaitForChild("INDEXButton")

	local tabContainer = innerContent:WaitForChild("TabContainer")
	local invTabContent = tabContainer:WaitForChild("InventoryTabContent")
	local playerTabContent = tabContainer:WaitForChild("PlayerTabContent")
	local standTabContent = tabContainer:WaitForChild("StandTabContent")
	titlesTabContent = tabContainer:WaitForChild("TitlesTabContent")
	indexTabContent = tabContainer:WaitForChild("IndexTabContent")

	local invInfoCard = invTabContent:WaitForChild("InvInfoCard")
	weaponBox = invInfoCard:WaitForChild("WepRow")
	weaponLabel = weaponBox:WaitForChild("Label")
	accBox = invInfoCard:WaitForChild("AccRow")
	accLabel = accBox:WaitForChild("Label")
	local yenBox = invInfoCard:WaitForChild("YenRow")
	yenLabel = yenBox:WaitForChild("Label")

	local equipCard = invTabContent:WaitForChild("EquipCard")
	capacityLabel = equipCard:WaitForChild("TopFrame"):WaitForChild("CapacityLabel")
	equipContainer = equipCard:WaitForChild("EquipContainer")

	local autoSellCard = invTabContent:WaitForChild("AutoSellCard")
	autoSellContainer = autoSellCard:WaitForChild("AutoSellContainer")

	local playerInfoCard = playerTabContent:WaitForChild("PlayerInfoCard")
	styleBox = playerInfoCard:WaitForChild("StyleRow")
	styleLabel = styleBox:WaitForChild("Label")
	styleLockBtn = playerInfoCard:WaitForChild("StyleRow"):WaitForChild("ActionBtn")
	local xpBoxP = playerInfoCard:WaitForChild("XPRow")
	xpLabelP = xpBoxP:WaitForChild("Label")

	local playerMidRow = playerTabContent:WaitForChild("PlayerMidRow")
	local pStatsCard = playerMidRow:WaitForChild("PlayerStatsCard")
	local pStatsTopControls = pStatsCard:WaitForChild("StatsTopControls")
	local pAmtBox = pStatsTopControls:WaitForChild("AmtBox")
	local pAllBtn = pStatsTopControls:WaitForChild("AllBtn")
	local pAutoBtn = pStatsTopControls:WaitForChild("AutoBtn")
	pStatsContainer = pStatsCard:WaitForChild("StatsContainer")

	local styleStorageCard = playerMidRow:WaitForChild("StyleStorageCard")
	styleStorageContainer = styleStorageCard:WaitForChild("StorageContainer")

	local playerConsCard = playerTabContent:WaitForChild("PlayerConsCard")
	playerConsCapacityLabel = playerConsCard:WaitForChild("TopFrame"):WaitForChild("CapacityLabel")
	playerConsContainer = playerConsCard:WaitForChild("ConsContainer")

	local standInfoCard = standTabContent:WaitForChild("StandInfoCard")
	standBox = standInfoCard:WaitForChild("StandRow")
	standLabel = standBox:WaitForChild("Label")
	standLockBtn = standBox:WaitForChild("ActionBtn")
	local xpBoxS = standInfoCard:WaitForChild("XPRow")
	xpLabelS = xpBoxS:WaitForChild("Label")

	local standMidRow = standTabContent:WaitForChild("StandMidRow")
	local sStatsCard = standMidRow:WaitForChild("StandStatsCard")
	local sStatsTopControls = sStatsCard:WaitForChild("StatsTopControls")
	local sAmtBox = sStatsTopControls:WaitForChild("AmtBox")
	local sAllBtn = sStatsTopControls:WaitForChild("AllBtn")
	local sAutoBtn = sStatsTopControls:WaitForChild("AutoBtn")
	sStatsContainer = sStatsCard:WaitForChild("StatsContainer")
	local standStorageCard = standMidRow:WaitForChild("StandStorageCard")
	standStorageContainer = standStorageCard:WaitForChild("StorageContainer")
	openTreeBtn = standBox:WaitForChild("OpenTreeBtn")

	local standBotRow = standTabContent:WaitForChild("StandBotRow")
	local standConsCard = standBotRow:WaitForChild("StandConsCard")
	standConsContainer = standConsCard:WaitForChild("ConsContainer")

	local autoRollCard = standBotRow:WaitForChild("AutoRollCard")
	local arContent = autoRollCard:WaitForChild("ARContent")
	local sDrop = arContent:WaitForChild("StandDropdown")
	local tDrop = arContent:WaitForChild("TraitDropdown")
	local btnRollStand = arContent:WaitForChild("RollStandBtn")
	local btnRollTrait = arContent:WaitForChild("RollTraitBtn")

	local function bindAmountBox(box)
		box.FocusLost:Connect(function()
			local val = tonumber(box.Text)
			if val and val > 0 then currentUpgradeAmount = math.floor(val) else currentUpgradeAmount = 1 end
			box.Text = tostring(currentUpgradeAmount)

			if box == pAmtBox then sAmtBox.Text = box.Text else pAmtBox.Text = box.Text end
			RefreshStatTexts()

			if player:GetAttribute("AutoStatPlayer") or player:GetAttribute("AutoStatStand") then
				local r = Network:FindFirstChild("ToggleAutoStat")
				if r then r:FireServer("UpdateAmount", currentUpgradeAmount) end
			end
		end)
	end
	bindAmountBox(pAmtBox)
	bindAmountBox(sAmtBox)

	local function bindAllBtn(btn, statType)
		btn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			local UpgradeAllEvent = Network:FindFirstChild("UpgradeAllStats")
			if UpgradeAllEvent then UpgradeAllEvent:FireServer(currentUpgradeAmount, statType) end
		end)
	end
	bindAllBtn(pAllBtn, "Player")
	bindAllBtn(sAllBtn, "Stand")

	pAutoBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local r = Network:FindFirstChild("ToggleAutoStat")
		if r then r:FireServer("Player", currentUpgradeAmount) end
	end)

	sAutoBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local r = Network:FindFirstChild("ToggleAutoStat")
		if r then r:FireServer("Stand", currentUpgradeAmount) end
	end)

	local function updateAutoBtns()
		if player:GetAttribute("AutoStatPlayer") then
			pAutoBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		else
			pAutoBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
		end

		if player:GetAttribute("AutoStatStand") then
			sAutoBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		else
			sAutoBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
		end
	end

	player:GetAttributeChangedSignal("AutoStatPlayer"):Connect(updateAutoBtns)
	player:GetAttributeChangedSignal("AutoStatStand"):Connect(updateAutoBtns)
	updateAutoBtns()

	for _, stat in ipairs(playerStatsList) do statLabels[stat] = InstantiateStatRow(stat, pStatsContainer, false) end
	for _, stat in ipairs(standStatsList) do statLabels[stat] = InstantiateStatRow(stat, sStatsContainer, true) end

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
			if currentActiveTab == "TITLE" or currentActiveTab == "INDEX" then
				innerContent.CanvasSize = UDim2.new(0, 0, 1, 0)
				innerContent.ScrollBarImageTransparency = 1
				innerContent.ScrollingEnabled = false
			else
				innerContent.CanvasSize = UDim2.new(0, 0, 0, minHeight)
				innerContent.ScrollBarImageTransparency = 0.5
				innerContent.ScrollingEnabled = true
			end
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
		currentActiveTab = target

		invTabContent.Visible = (target == "INV")
		playerTabContent.Visible = (target == "PLAYER")
		standTabContent.Visible = (target == "STAND")
		titlesTabContent.Visible = (target == "TITLE")
		indexTabContent.Visible = (target == "INDEX")

		local function ToggleNav(btn, str, isActive)
			btn.BackgroundColor3 = isActive and Color3.fromRGB(70, 30, 100) or Color3.fromRGB(30, 20, 50)
			btn.TextColor3 = isActive and Color3.fromRGB(255, 235, 130) or Color3.fromRGB(200, 200, 220)
			str.Color = isActive and Color3.fromRGB(255, 215, 50) or Color3.fromRGB(90, 50, 120)
			str.Thickness = isActive and 2 or 1
		end

		ToggleNav(invTabBtn, invTabBtn.UIStroke, target == "INV")
		ToggleNav(playerTabBtn, playerTabBtn.UIStroke, target == "PLAYER")
		ToggleNav(standTabBtn, standTabBtn.UIStroke, target == "STAND")
		ToggleNav(titlesTabBtn, titlesTabBtn.UIStroke, target == "TITLE")
		ToggleNav(indexTabBtn, indexTabBtn.UIStroke, target == "INDEX")

		UpdateLayoutForScreen()

		if target == "TITLE" then RefreshTitlesList()
		elseif target == "INDEX" then RefreshIndexList()
		elseif target == "INV" then RefreshInventoryList() end
	end

	invTabBtn.MouseButton1Click:Connect(function() SetActiveTab("INV") end)
	playerTabBtn.MouseButton1Click:Connect(function() SetActiveTab("PLAYER") end)
	standTabBtn.MouseButton1Click:Connect(function() SetActiveTab("STAND") end)
	titlesTabBtn.MouseButton1Click:Connect(function() SetActiveTab("TITLE") end)
	indexTabBtn.MouseButton1Click:Connect(function() SetActiveTab("INDEX") end)

	openTreeBtn.MouseButton1Click:Connect(function() 
		SFXManager.Play("Click")
		local ev = ReplicatedStorage:FindFirstChild("OpenSkillTreeModal")
		if not ev then
			ev = Instance.new("BindableEvent")
			ev.Name = "OpenSkillTreeModal"
			ev.Parent = ReplicatedStorage
		end
		ev:Fire()
	end)

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

	local raritiesToSell = {"Common", "Uncommon", "Rare", "Legendary", "Mythical"}
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
			local tData = StandData.Traits[ft1]
			local tData2 = StandData.Traits[ft2]
			local desc1 = tData and tData.Desc or ""
			local desc2 = tData2 and tData2.Desc or ""
			local color1 = tData and tData.Color or "#FFFFFF"
			local color2 = tData2 and tData2.Color or "#FFFFFF"

			local combinedDesc = "<font color='#AAAAAA'>" .. fs1 .. " + " .. fs2 .. "</font>\n\n"
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
	player:GetAttributeChangedSignal("UnlockedTitles"):Connect(RefreshTitlesList)
	player:GetAttributeChangedSignal("EquippedTitle"):Connect(RefreshTitlesList)

	player:GetAttributeChangedSignal("UnlockedIndex"):Connect(function()
		if currentActiveTab == "INDEX" then RefreshIndexList() end
	end)
	player:GetAttributeChangedSignal("UnlockedFusions"):Connect(function()
		if currentActiveTab == "INDEX" then RefreshIndexList() end
	end)
	player:GetAttributeChangedSignal("ClaimedIndexBonuses"):Connect(function() 
		RefreshStatTexts()
		if currentActiveTab == "INDEX" then RefreshIndexList() end
		if currentActiveTab == "INV" then RefreshInventoryList() end
	end)

	player:GetAttributeChangedSignal("Active_FusedStand1"):Connect(function() UpdateTopDisplays(); RefreshStatTexts(); RefreshStorageList() end)
	player:GetAttributeChangedSignal("Active_FusedStand2"):Connect(function() UpdateTopDisplays(); RefreshStatTexts(); RefreshStorageList() end)
	player:GetAttributeChangedSignal("Active_FusedTrait1"):Connect(function() UpdateTopDisplays(); RefreshStorageList() end)
	player:GetAttributeChangedSignal("Active_FusedTrait2"):Connect(function() UpdateTopDisplays(); RefreshStorageList() end)

	for i = 1, 5 do 
		player:GetAttributeChangedSignal("StoredStand"..i):Connect(RefreshStorageList) 
		player:GetAttributeChangedSignal("StoredStand"..i.."_FusedStand1"):Connect(RefreshStorageList) 
		player:GetAttributeChangedSignal("StoredStand"..i.."_FusedStand2"):Connect(RefreshStorageList) 
	end

	player:GetAttributeChangedSignal("StoredStandVIP"):Connect(RefreshStorageList)
	player:GetAttributeChangedSignal("StoredStandVIP_FusedStand1"):Connect(RefreshStorageList)
	player:GetAttributeChangedSignal("StoredStandVIP_FusedStand2"):Connect(RefreshStorageList)

	for i = 1, 3 do player:GetAttributeChangedSignal("StoredStyle"..i):Connect(RefreshStorageList) end
	player:GetAttributeChangedSignal("StoredStyleVIP"):Connect(RefreshStorageList)

	player:GetAttributeChangedSignal("IsVIP"):Connect(RefreshStorageList)

	player:GetAttributeChangedSignal("HasStandSlot2"):Connect(RefreshStorageList)
	player:GetAttributeChangedSignal("HasStandSlot3"):Connect(RefreshStorageList)
	player:GetAttributeChangedSignal("HasStyleSlot2"):Connect(RefreshStorageList)
	player:GetAttributeChangedSignal("HasStyleSlot3"):Connect(RefreshStorageList)
	player:GetAttributeChangedSignal("StandLocked"):Connect(UpdateTopDisplays)
	player:GetAttributeChangedSignal("StyleLocked"):Connect(UpdateTopDisplays)
	player:GetAttributeChangedSignal("LockedItems"):Connect(RefreshInventoryList)

	for _, stat in ipairs(allStatsToUpgrade) do player:GetAttributeChangedSignal(stat):Connect(RefreshStatTexts) end
	for _, item in ipairs(KnownItems) do 
		player:GetAttributeChangedSignal(item:gsub("[^%w]", "").."Count"):Connect(function()
			if currentActiveTab == "INV" or currentActiveTab == "PLAYER" or currentActiveTab == "STAND" then
				RefreshInventoryList()
			end
		end) 
	end

	indexTabContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateIndexLayout)

	task.spawn(function()
		local pObj = player:WaitForChild("leaderstats", 5)
		if pObj then 
			pObj:WaitForChild("Prestige", 5).Changed:Connect(function() 
				RefreshStatTexts(); RefreshStorageList()
				if currentActiveTab == "INV" then RefreshInventoryList() end 
			end)
			pObj:WaitForChild("Yen", 5).Changed:Connect(UpdateTopDisplays) 
		end
		UpdateTopDisplays(); RefreshStatTexts(); RefreshInventoryList(); RefreshStorageList()
	end)

	parentFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if parentFrame.Visible then
			UpdateTopDisplays()
			RefreshStatTexts()
			RefreshStorageList()

			if currentActiveTab == "INV" or currentActiveTab == "PLAYER" or currentActiveTab == "STAND" then
				RefreshInventoryList()
			elseif currentActiveTab == "TITLE" then
				RefreshTitlesList()
			elseif currentActiveTab == "INDEX" then
				RefreshIndexList()
			end
		end
	end)
end

return InventoryTab