-- @ScriptType: ModuleScript
local InventoryTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))

local currencyDisplay, pStatsContainer, sStatsContainer, keyItemsContainer, regItemsContainer
local storageContainer, autoSellContainer, autoRollCard
local capacityLabel
local statLabels = {}

local standLabel, styleLabel, weaponLabel, accLabel
local standLockBtn, styleLockBtn

local currentlyHoveredStat = nil
local cachedTooltipMgr = nil
local currentStorageMode = "Stand"

local targetAutoStand = "Any"
local targetAutoTrait = "Any"

local rarityColors = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(50, 100, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythical = Color3.fromRGB(255, 50, 50),
	Unique = Color3.fromRGB(215, 69, 255)
}

local raritySortTiers = {
	Unique = 1000, Mythical = 2000, Legendary = 3000, Rare = 4000, Uncommon = 5000, Common = 6000
}

local playerStatsList = {"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower"}
local standStatsList = {"Stand_Power_Val", "Stand_Speed_Val", "Stand_Range_Val", "Stand_Durability_Val", "Stand_Precision_Val", "Stand_Potential_Val"}
local allStatsToUpgrade = {"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower", "Stand_Power_Val", "Stand_Speed_Val", "Stand_Range_Val", "Stand_Durability_Val", "Stand_Precision_Val", "Stand_Potential_Val"}

local KnownItems = {}
for itemName, _ in pairs(ItemData.Consumables) do table.insert(KnownItems, itemName) end
for eqName, _ in pairs(ItemData.Equipment) do table.insert(KnownItems, eqName) end

local function IsKeyItem(name)
	if name == "Stand Arrow" or name == "Rokakaka" or name == "Heavenly Stand Disc" or name == "Saint's Corpse Part" then return true end
	local itemInfo = ItemData.Equipment[name] or ItemData.Consumables[name]
	if itemInfo and itemInfo.Rarity == "Unique" then return true end
	return false
end

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

local function GetUpgradeCosts(currentStat, baseVal, prestige, maxCap)
	local cost1 = GameData.CalculateStatCost(currentStat, baseVal, prestige)
	local cost5, cost10 = 0, 0
	for i = 0, 4 do if currentStat + i >= maxCap then break end cost5 += GameData.CalculateStatCost(currentStat + i, baseVal, prestige) end
	for i = 0, 9 do if currentStat + i >= maxCap then break end cost10 += GameData.CalculateStatCost(currentStat + i, baseVal, prestige) end
	return cost1, cost5, cost10
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

local function applyDoubleGoldBorder(parent)
	local outerStroke = Instance.new("UIStroke")
	outerStroke.Thickness = 3
	outerStroke.Color = Color3.fromRGB(255, 210, 60)
	outerStroke.LineJoinMode = Enum.LineJoinMode.Round
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradOut = Instance.new("UIGradient")
	gradOut.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 160, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 160, 30))
	}
	gradOut.Rotation = -45
	gradOut.Parent = outerStroke
	outerStroke.Parent = parent

	local innerFrame = Instance.new("Frame")
	innerFrame.Name = "InnerGoldBorder"
	innerFrame.Size = UDim2.new(1, -6, 1, -6)
	innerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	innerFrame.BackgroundTransparency = 1
	innerFrame.ZIndex = parent.ZIndex

	local parentCorner = parent:FindFirstChildOfClass("UICorner")
	if parentCorner then
		local innerCorner = Instance.new("UICorner")
		innerCorner.CornerRadius = UDim.new(0, math.max(0, parentCorner.CornerRadius.Offset - 3))
		innerCorner.Parent = innerFrame
	end
	innerFrame.Parent = parent

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Thickness = 1
	innerStroke.Color = Color3.fromRGB(255, 230, 100)
	innerStroke.LineJoinMode = Enum.LineJoinMode.Round
	innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradIn = Instance.new("UIGradient")
	gradIn.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 25))
	}
	gradIn.Rotation = 45
	gradIn.Parent = innerStroke
	innerStroke.Parent = innerFrame
end

local function CreateCard(name, parent, size, layoutOrder)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	frame.LayoutOrder = layoutOrder
	frame.ZIndex = 20
	frame.Parent = parent

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Color3.fromRGB(90, 50, 120)
	stroke.Thickness = 1

	local uip = Instance.new("UIPadding", frame)
	uip.PaddingTop = UDim.new(0, 8); uip.PaddingBottom = UDim.new(0, 8)
	uip.PaddingLeft = UDim.new(0, 8); uip.PaddingRight = UDim.new(0, 8)

	return frame
end

local function CreateTitle(parent, text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextColor3 = Color3.fromRGB(255, 215, 50)
	lbl.TextScaled = false
	lbl.TextSize = 14
	lbl.LayoutOrder = 1
	lbl.ZIndex = 22
	lbl.Parent = parent
	return lbl
end

local function CreateStatRow(statName, parent)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1, 0, 0.16, 0)
	row.BackgroundTransparency = 1

	local statLabel = Instance.new("TextLabel", row)
	statLabel.Size = UDim2.new(0.5, 0, 1, 0)
	statLabel.BackgroundTransparency = 1
	statLabel.Font = Enum.Font.GothamBold
	statLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	statLabel.TextXAlignment = Enum.TextXAlignment.Left
	statLabel.TextScaled = false
	statLabel.TextSize = 12
	statLabel.RichText = true
	statLabel.ZIndex = 22

	local btnContainer = Instance.new("Frame", row)
	btnContainer.Size = UDim2.new(0.5, 0, 1, 0)
	btnContainer.Position = UDim2.new(1, 0, 0, 0)
	btnContainer.AnchorPoint = Vector2.new(1, 0)
	btnContainer.BackgroundTransparency = 1
	btnContainer.ZIndex = 22

	local blL = Instance.new("UIListLayout", btnContainer)
	blL.FillDirection = Enum.FillDirection.Horizontal
	blL.HorizontalAlignment = Enum.HorizontalAlignment.Right
	blL.VerticalAlignment = Enum.VerticalAlignment.Center
	blL.Padding = UDim.new(0, 4)
	blL.SortOrder = Enum.SortOrder.LayoutOrder

	local function makeBtn(text, order)
		local b = Instance.new("TextButton", btnContainer)
		b.LayoutOrder = order
		b.Size = UDim2.new(0.23, 0, 0.85, 0)
		b.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.new(1,1,1)
		b.TextScaled = false
		b.TextSize = 10
		b.ZIndex = 23
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
		local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(120, 60, 180)
		return b
	end

	local b1 = makeBtn("+1", 1)
	local b5 = makeBtn("+5", 2)
	local b10 = makeBtn("+10", 3)
	local bMax = makeBtn("MAX", 4)

	row.MouseEnter:Connect(function() currentlyHoveredStat = statName; UpdateStatTooltip() end)
	row.MouseLeave:Connect(function() if currentlyHoveredStat == statName then currentlyHoveredStat = nil; cachedTooltipMgr.Hide() end end)

	b1.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.UpgradeStat:FireServer(statName, 1) end)
	b5.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.UpgradeStat:FireServer(statName, 5) end)
	b10.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.UpgradeStat:FireServer(statName, 10) end)
	bMax.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.UpgradeStat:FireServer(statName, "MAX") end)

	return { Label = statLabel, Btn1 = b1, Btn5 = b5, Btn10 = b10, BtnMax = bMax }
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

	local listL = Instance.new("UIListLayout", listFrame)
	listL.SortOrder = Enum.SortOrder.LayoutOrder

	for _, opt in ipairs(options) do
		local b = Instance.new("TextButton", listFrame)
		b.Size = UDim2.new(1, -8, 0, 25)
		b.BackgroundTransparency = 1
		b.TextColor3 = Color3.new(1,1,1)
		b.Text = opt; b.Font = Enum.Font.GothamMedium; b.TextSize = 12; b.ZIndex = 51
		b.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			if isStand then targetAutoStand = opt; parentBtn.Text = "Target Stand: " .. opt
			else targetAutoTrait = opt; parentBtn.Text = "Target Trait: " .. opt end
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
		local cost1, cost5, cost10 = GetUpgradeCosts(val, base, prestige, statCap)
		local bonusAmount = GetCombinedBonus(cleanName)
		local bonusText = bonusAmount > 0 and " <font color='#55FF55'>(+" .. bonusAmount .. ")</font>" or ""

		if val >= statCap then
			data.Label.Text = cleanName:gsub("Stand_", "") .. ": " .. val .. bonusText .. " <font color='#FF5555'>[MAX]</font>"
			data.Btn1.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			data.Btn5.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			data.Btn10.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			data.BtnMax.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		else
			data.Label.Text = cleanName:gsub("Stand_", "") .. ": " .. val .. bonusText .. " <font color='#AAAAAA'>[" .. cost1 .. " XP]</font>"
			data.Btn1.BackgroundColor3 = (currentXP >= cost1) and Color3.fromRGB(120, 20, 160) or Color3.fromRGB(100, 100, 100)
			data.Btn5.BackgroundColor3 = (currentXP >= cost5) and Color3.fromRGB(120, 20, 160) or Color3.fromRGB(100, 100, 100)
			data.Btn10.BackgroundColor3 = (currentXP >= cost10) and Color3.fromRGB(120, 20, 160) or Color3.fromRGB(100, 100, 100)
			data.BtnMax.BackgroundColor3 = (currentXP >= cost1) and Color3.fromRGB(120, 20, 160) or Color3.fromRGB(100, 100, 100)
		end
	end
	UpdateStatTooltip()
end

local function RefreshStorageList()
	for _, child in pairs(storageContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

	local sortedSlots = {}
	if currentStorageMode == "Stand" then
		local pObj = player:FindFirstChild("leaderstats")
		local prestige = pObj and pObj:FindFirstChild("Prestige") and pObj.Prestige.Value or 0
		local hasR1, hasR2 = player:GetAttribute("HasStandSlot2"), player:GetAttribute("HasStandSlot3")

		table.insert(sortedSlots, { Backend = 1, IsUnlocked = true, Type = "Base" })
		if hasR1 then table.insert(sortedSlots, { Backend = 2, IsUnlocked = true, Type = "Robux", PassId = 1733160695 }) end
		if hasR2 then table.insert(sortedSlots, { Backend = 3, IsUnlocked = true, Type = "Robux", PassId = 1732844091 }) end
		table.insert(sortedSlots, { Backend = 4, IsUnlocked = (prestige >= 15), Type = "Prestige", Req = 15 })
		table.insert(sortedSlots, { Backend = 5, IsUnlocked = (prestige >= 30), Type = "Prestige", Req = 30 })

		if not hasR1 then table.insert(sortedSlots, { Backend = 2, IsUnlocked = false, Type = "Robux", PassId = 1733160695 }) end
		if not hasR2 then table.insert(sortedSlots, { Backend = 3, IsUnlocked = false, Type = "Robux", PassId = 1732844091 }) end
	elseif currentStorageMode == "Style" then
		local hasS1, hasS2 = player:GetAttribute("HasStyleSlot2"), player:GetAttribute("HasStyleSlot3")

		table.insert(sortedSlots, { Backend = 1, IsUnlocked = true, Type = "Base" })
		if hasS1 then table.insert(sortedSlots, { Backend = 2, IsUnlocked = true, Type = "Robux", PassId = 1746853452 }) end
		if hasS2 then table.insert(sortedSlots, { Backend = 3, IsUnlocked = true, Type = "Robux", PassId = 1745969849 }) end

		if not hasS1 then table.insert(sortedSlots, { Backend = 2, IsUnlocked = false, Type = "Robux", PassId = 1746853452 }) end
		if not hasS2 then table.insert(sortedSlots, { Backend = 3, IsUnlocked = false, Type = "Robux", PassId = 1745969849 }) end
	end

	for visualNum, slotData in ipairs(sortedSlots) do
		local row = Instance.new("Frame", storageContainer)
		row.Size = UDim2.new(1, 0, 0.18, 0)
		row.BackgroundColor3 = Color3.fromRGB(45, 25, 65)
		row.ZIndex = 23
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
		local str = Instance.new("UIStroke", row)
		str.Color = currentStorageMode == "Stand" and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 140, 0)

		local nameLabel = Instance.new("TextLabel", row)
		nameLabel.Size = UDim2.new(0.6, 0, 1, 0); nameLabel.Position = UDim2.new(0, 10, 0, 0)
		nameLabel.BackgroundTransparency = 1; nameLabel.Font = Enum.Font.GothamMedium; nameLabel.TextColor3 = Color3.new(1,1,1)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.TextScaled = false; nameLabel.TextSize = 12; nameLabel.RichText = true; nameLabel.ZIndex = 24

		local btn = Instance.new("TextButton", row)
		btn.Size = UDim2.new(0, 50, 0, 20); btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, -10, 0.5, 0)
		btn.Font = Enum.Font.GothamBold; btn.TextColor3 = Color3.new(1,1,1); btn.TextScaled = false; btn.TextSize = 11; btn.ZIndex = 24
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

		if slotData.IsUnlocked then
			if currentStorageMode == "Stand" then
				local storedName = player:GetAttribute("StoredStand"..slotData.Backend) or "None"
				local storedTrait = player:GetAttribute("StoredStand"..slotData.Backend.."_Trait") or "None"
				local traitDisplay = ""
				if storedTrait ~= "None" then
					local tCol = StandData.Traits[storedTrait] and StandData.Traits[storedTrait].Color or "#FFFFFF"
					traitDisplay = " <font color='" .. tCol .. "'>[" .. storedTrait:upper() .. "]</font>"
				end
				nameLabel.Text = "S"..visualNum..": <font color='#A020F0'>" .. storedName .. "</font>" .. traitDisplay
				if storedName == "None" and (player:GetAttribute("Stand") or "None") == "None" then
					btn.Text = "Empty"; btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				else
					btn.Text = storedName == "None" and "Store" or "Swap"; btn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
					btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.StandStorageAction:FireServer("Swap", slotData.Backend) end)
				end
			else
				local storedName = player:GetAttribute("StoredStyle"..slotData.Backend) or "None"
				nameLabel.Text = "S"..visualNum..": <font color='#FF8C00'>" .. storedName .. "</font>"
				if storedName == "None" and (player:GetAttribute("FightingStyle") or "None") == "None" then
					btn.Text = "Empty"; btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				else
					btn.Text = storedName == "None" and "Store" or "Swap"; btn.BackgroundColor3 = Color3.fromRGB(180, 80, 20)
					btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.StandStorageAction:FireServer("SwapStyle", slotData.Backend) end)
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

local function RefreshInventoryList()
	for _, child in pairs(keyItemsContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	for _, child in pairs(regItemsContainer:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

	local specialItems, normalItems = {}, {}
	local currentInvCount = 0

	for _, itemName in ipairs(KnownItems) do
		local count = player:GetAttribute(itemName:gsub("[^%w]", "") .. "Count") or 0
		if count > 0 then
			if IsKeyItem(itemName) then table.insert(specialItems, {Name = itemName, Count = count})
			else table.insert(normalItems, {Name = itemName, Count = count}); currentInvCount += count end
		end
	end

	if capacityLabel then
		local maxInv = GameData.GetMaxInventory(player)
		capacityLabel.Text = "Capacity: " .. currentInvCount .. "/" .. maxInv
	end

	local function RenderItem(itemName, count, isSpecial)
		local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
		local rarity = itemData and itemData.Rarity or "Common"
		local container = isSpecial and keyItemsContainer or regItemsContainer

		local itemFrame = Instance.new("Frame", container)
		itemFrame.Size = UDim2.new(1, 0, 0, 32)
		itemFrame.BackgroundColor3 = Color3.fromRGB(30, 15, 45)
		itemFrame.LayoutOrder = raritySortTiers[rarity] or raritySortTiers.Common
		itemFrame.ZIndex = 23
		Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 6)
		local str = Instance.new("UIStroke", itemFrame); str.Color = rarityColors[rarity] or rarityColors.Common

		local nameLabel = Instance.new("TextLabel", itemFrame)
		nameLabel.Size = UDim2.new(0.45, 0, 1, 0); nameLabel.AnchorPoint = Vector2.new(0, 0.5); nameLabel.Position = UDim2.new(0, 8, 0.5, 0)
		nameLabel.BackgroundTransparency = 1; nameLabel.Font = Enum.Font.GothamMedium; nameLabel.TextColor3 = rarityColors[rarity] or rarityColors.Common
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left; nameLabel.TextScaled = false; nameLabel.TextSize = 12; nameLabel.Text = itemName .. " (x" .. count .. ")"; nameLabel.ZIndex = 24

		local btnWrapper = Instance.new("Frame", itemFrame)
		btnWrapper.Size = UDim2.new(0.55, 0, 1, 0); btnWrapper.Position = UDim2.new(1, -6, 0.5, 0); btnWrapper.AnchorPoint = Vector2.new(1, 0.5); btnWrapper.BackgroundTransparency = 1
		local bL = Instance.new("UIListLayout", btnWrapper); bL.FillDirection = Enum.FillDirection.Horizontal; bL.HorizontalAlignment = Enum.HorizontalAlignment.Right; bL.VerticalAlignment = Enum.VerticalAlignment.Center; bL.Padding = UDim.new(0, 4); bL.SortOrder = Enum.SortOrder.LayoutOrder

		local function makeBtn(text, sizeX, color, order)
			local b = Instance.new("TextButton", btnWrapper)
			b.Size = UDim2.new(0, sizeX, 0, 24); b.LayoutOrder = order
			b.BackgroundColor3 = color; b.Text = text; b.Font = Enum.Font.GothamBold; b.TextColor3 = Color3.new(1,1,1)
			b.TextScaled = false; b.TextSize = 11; b.ZIndex = 24
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
			return b
		end

		local useBtn = makeBtn(ItemData.Equipment[itemName] and "Equip" or "Use", 50, Color3.fromRGB(200, 120, 0), 1)
		local sellBtn = makeBtn("Sell", 40, Color3.fromRGB(140, 40, 40), 2)
		local lockBtn = makeBtn("🔓", 24, Color3.fromRGB(40, 40, 40), 3)

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
			useBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.UnequipItem:FireServer(ItemData.Equipment[itemName].Slot) end)
		else
			useBtn.MouseButton1Click:Connect(function()
				if useBtn.Text == "Equip" then
					SFXManager.Play("Click"); Network.UseItem:FireServer(itemName)
				else
					if itemName == "Stand Arrow" or itemName == "Saint's Corpse Part" or itemName == "Rokakaka" then
						local currentStand = player:GetAttribute("Stand") or "None"
						local currentTrait = player:GetAttribute("StandTrait") or "None"
						if itemName ~= "Rokakaka" and targetAutoStand ~= "Any" and currentStand == targetAutoStand then NotificationManager.Show("<font color='#FF5555'>Blocked! You already have your target Stand.</font>"); return end
						if targetAutoTrait ~= "Any" and currentTrait == targetAutoTrait then NotificationManager.Show("<font color='#FF5555'>Blocked! You already have your target Trait.</font>"); return end
					end
					if ItemData.Consumables[itemName] and not isConfirmingUse then
						isConfirmingUse = true; useBtn.Text = "Confirm?"; useBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
						task.delay(3, function() if isConfirmingUse and useBtn.Parent then isConfirmingUse = false; useBtn.Text = "Use"; useBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0) end end)
						return
					end
					isConfirmingUse = false; SFXManager.Play("Click"); Network.UseItem:FireServer(itemName)
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
			isConfirmingSell = false; SFXManager.Play("Click"); cachedTooltipMgr.Hide(); Network.ShopAction:FireServer("Sell", itemName)
		end)

		itemFrame.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetItemTooltip(itemName)) end)
		itemFrame.MouseLeave:Connect(cachedTooltipMgr.Hide)
	end

	for _, item in ipairs(specialItems) do RenderItem(item.Name, item.Count, true) end
	for _, item in ipairs(normalItems) do RenderItem(item.Name, item.Count, false) end

	keyItemsContainer.CanvasSize = UDim2.new(0, 0, 0, (#specialItems * 36) + 10)
	regItemsContainer.CanvasSize = UDim2.new(0, 0, 0, (#normalItems * 36) + 10)
end

local function UpdateTopDisplays()
	local sName = player:GetAttribute("Stand") or "None"
	local sTrait = player:GetAttribute("StandTrait") or "None"
	local style = player:GetAttribute("FightingStyle") or "None"
	local wpn = player:GetAttribute("EquippedWeapon") or "None"
	local acc = player:GetAttribute("EquippedAccessory") or "None"

	local traitDisplay = ""
	if sTrait ~= "None" then
		local color = StandData.Traits[sTrait] and StandData.Traits[sTrait].Color or "#FFFFFF"
		traitDisplay = " <font color='" .. color .. "'>[" .. sTrait:upper() .. "]</font>"
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

	local yenVal = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Yen") and player.leaderstats.Yen.Value or 0
	currencyDisplay.Text = "<b>XP:</b> <font color='#55FFFF'>" .. (player:GetAttribute("XP") or 0) .. "</font> | <b>YEN:</b> <font color='#55FF55'>¥" .. yenVal .. "</font>"
	RefreshStatTexts()
end

function InventoryTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr

	-- ========================================================
	-- MAIN FRAME SETUP (Matches CombatTab Perfectly)
	-- ========================================================
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

	local camera = workspace.CurrentCamera
	local function UpdateLayoutForScreen()
		if not parentFrame.Parent then return end
		local vp = camera.ViewportSize
		if vp.X >= 1050 then mainPanel.Size = UDim2.new(0.80, 0, 0.88, 0); mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
		elseif vp.X >= 600 and vp.X < 1050 then mainPanel.Size = UDim2.new(0.92, 0, 0.82, 0); mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
		else mainPanel.Size = UDim2.new(0.96, 0, 0.82, 0); mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0) end
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
	UpdateLayoutForScreen()

	local innerContent = Instance.new("Frame")
	innerContent.Name = "InnerContent"
	innerContent.Size = UDim2.new(1, 0, 1, 0)
	innerContent.BackgroundTransparency = 1
	innerContent.ZIndex = 17
	innerContent.Parent = mainPanel

	local mainPad = Instance.new("UIPadding", innerContent)
	mainPad.PaddingTop = UDim.new(0.02, 0); mainPad.PaddingBottom = UDim.new(0.02, 0)
	mainPad.PaddingLeft = UDim.new(0.02, 0); mainPad.PaddingRight = UDim.new(0.02, 0)

	local mainLayout = Instance.new("UIListLayout", innerContent)
	mainLayout.FillDirection = Enum.FillDirection.Horizontal
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainLayout.Padding = UDim.new(0.02, 0)

	local leftContainer = Instance.new("Frame", innerContent)
	leftContainer.Name = "LeftContainer"
	leftContainer.Size = UDim2.new(0.38, 0, 1, 0)
	leftContainer.BackgroundTransparency = 1
	leftContainer.LayoutOrder = 1

	local rightContainer = Instance.new("Frame", innerContent)
	rightContainer.Name = "RightContainer"
	rightContainer.Size = UDim2.new(0.60, 0, 1, 0)
	rightContainer.BackgroundTransparency = 1
	rightContainer.LayoutOrder = 2

	-- ==========================================
	-- LEFT CONTAINER (38%)
	-- ==========================================
	local lLayout = Instance.new("UIListLayout", leftContainer)
	lLayout.FillDirection = Enum.FillDirection.Vertical
	lLayout.SortOrder = Enum.SortOrder.LayoutOrder
	lLayout.Padding = UDim.new(0.02, 0)

	local loadoutCard = CreateCard("LoadoutCard", leftContainer, UDim2.new(1, 0, 0.35, 0), 1)
	local storageCard = CreateCard("StorageCard", leftContainer, UDim2.new(1, 0, 0.41, 0), 2)
	local autoSellCard = CreateCard("AutoSellCard", leftContainer, UDim2.new(1, 0, 0.20, 0), 3)

	-- Loadout
	local loL = Instance.new("UIListLayout", loadoutCard); loL.Padding = UDim.new(0, 4); loL.SortOrder = Enum.SortOrder.LayoutOrder
	CreateTitle(loadoutCard, "LOADOUT")
	local lContent = Instance.new("Frame", loadoutCard); lContent.Size = UDim2.new(1, 0, 1, -24); lContent.BackgroundTransparency = 1; lContent.LayoutOrder = 2
	Instance.new("UIListLayout", lContent).Padding = UDim.new(0, 4)

	local function createLoadRow(name)
		local r = Instance.new("Frame", lContent); r.Size = UDim2.new(1, 0, 0.16, 0); r.BackgroundTransparency = 1
		local lbl = Instance.new("TextLabel", r)
		lbl.Size = UDim2.new(1, -35, 1, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamMedium; lbl.TextColor3 = Color3.new(1,1,1)
		lbl.TextScaled = false; lbl.TextSize = 12; lbl.RichText = true; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 22

		local btn = nil
		if name == "Stand" or name == "Style" then
			btn = Instance.new("TextButton", r)
			btn.Size = UDim2.new(0, 24, 0, 20); btn.AnchorPoint = Vector2.new(1, 0.5); btn.Position = UDim2.new(1, 0, 0.5, 0)
			btn.Font = Enum.Font.GothamBold; btn.TextScaled = false; btn.TextSize = 12; btn.ZIndex = 23
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		end
		return r, lbl, btn
	end

	standBox, standLabel, standLockBtn = createLoadRow("Stand")
	styleBox, styleLabel, styleLockBtn = createLoadRow("Style")
	weaponBox, weaponLabel, _ = createLoadRow("Wep")
	accBox, accLabel, _ = createLoadRow("Acc")

	local currRow = Instance.new("Frame", lContent); currRow.Size = UDim2.new(1, 0, 0.22, 0); currRow.BackgroundTransparency = 1
	currencyDisplay = Instance.new("TextLabel", currRow)
	currencyDisplay.Size = UDim2.new(1, 0, 1, 0); currencyDisplay.BackgroundTransparency = 1
	currencyDisplay.Font = Enum.Font.GothamBold; currencyDisplay.TextColor3 = Color3.new(1,1,1); currencyDisplay.TextScaled = false; currencyDisplay.TextSize = 12; currencyDisplay.TextWrapped = true; currencyDisplay.RichText = true; currencyDisplay.ZIndex = 22; currencyDisplay.TextXAlignment = Enum.TextXAlignment.Left

	-- Storage
	local sL = Instance.new("UIListLayout", storageCard); sL.Padding = UDim.new(0, 4); sL.SortOrder = Enum.SortOrder.LayoutOrder
	local stTop = Instance.new("Frame", storageCard); stTop.Size = UDim2.new(1, 0, 0, 20); stTop.BackgroundTransparency = 1; stTop.LayoutOrder = 1; stTop.ZIndex = 21
	local stTitle = CreateTitle(stTop, "STAND STORAGE"); stTitle.Size = UDim2.new(0.5, 0, 1, 0); stTitle.TextXAlignment = Enum.TextXAlignment.Left
	local toggleStorageBtn = Instance.new("TextButton", stTop)
	toggleStorageBtn.Size = UDim2.new(0.45, 0, 1, 0); toggleStorageBtn.AnchorPoint = Vector2.new(1, 0); toggleStorageBtn.Position = UDim2.new(1, 0, 0, 0)
	toggleStorageBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 20); toggleStorageBtn.Text = "Styles"; toggleStorageBtn.Font = Enum.Font.GothamBold; toggleStorageBtn.TextColor3 = Color3.new(1,1,1); toggleStorageBtn.TextScaled = false; toggleStorageBtn.TextSize = 12; toggleStorageBtn.ZIndex = 23
	Instance.new("UICorner", toggleStorageBtn).CornerRadius = UDim.new(0, 4)

	storageContainer = Instance.new("Frame", storageCard); storageContainer.Size = UDim2.new(1, 0, 1, -24); storageContainer.BackgroundTransparency = 1; storageContainer.LayoutOrder = 2
	Instance.new("UIListLayout", storageContainer).Padding = UDim.new(0, 4)

	-- Auto Sell
	local asL = Instance.new("UIListLayout", autoSellCard); asL.Padding = UDim.new(0, 4); asL.SortOrder = Enum.SortOrder.LayoutOrder
	CreateTitle(autoSellCard, "AUTO SELL")
	autoSellContainer = Instance.new("Frame", autoSellCard)
	autoSellContainer.Size = UDim2.new(1, 0, 1, -24); autoSellContainer.BackgroundTransparency = 1; autoSellContainer.LayoutOrder = 2; autoSellContainer.ZIndex = 21
	local asG = Instance.new("UIGridLayout", autoSellContainer)
	asG.CellSize = UDim2.new(0.31, 0, 0.40, 0); asG.CellPadding = UDim2.new(0.03, 0, 0.1, 0); asG.HorizontalAlignment = Enum.HorizontalAlignment.Center; asG.VerticalAlignment = Enum.VerticalAlignment.Center

	local raritiesToSell = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"}
	for _, r in ipairs(raritiesToSell) do
		local b = Instance.new("TextButton", autoSellContainer)
		b.Name = "AutoSell_" .. r; b.BackgroundColor3 = Color3.fromRGB(40, 30, 50); b.Text = r; b.Font = Enum.Font.GothamBold; b.TextColor3 = Color3.new(1,1,1); b.TextScaled = false; b.TextSize = 11; b.ZIndex = 22
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
		local s = Instance.new("UIStroke", b); s.Color = Color3.fromRGB(100, 100, 100)
	end


	-- ==========================================
	-- RIGHT CONTAINER (60%)
	-- ==========================================
	local rLayout = Instance.new("UIListLayout", rightContainer)
	rLayout.FillDirection = Enum.FillDirection.Vertical
	rLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rLayout.Padding = UDim.new(0.02, 0)

	local statsAreaCard = CreateCard("StatsAreaCard", rightContainer, UDim2.new(1, 0, 0.35, 0), 1)
	local itemsAreaCard = CreateCard("ItemsAreaCard", rightContainer, UDim2.new(1, 0, 0.45, 0), 2)
	autoRollCard = CreateCard("AutoRollCard", rightContainer, UDim2.new(1, 0, 0.16, 0), 3)

	-- Stats
	local sacL = Instance.new("UIListLayout", statsAreaCard)
	sacL.FillDirection = Enum.FillDirection.Horizontal; sacL.Padding = UDim.new(0, 10)

	local pStats = Instance.new("Frame", statsAreaCard)
	pStats.Size = UDim2.new(0.5, -6, 1, 0); pStats.BackgroundTransparency = 1; pStats.LayoutOrder = 1
	Instance.new("UIListLayout", pStats).Padding = UDim.new(0, 4)
	CreateTitle(pStats, "PLAYER STATS")
	pStatsContainer = Instance.new("Frame", pStats)
	pStatsContainer.Size = UDim2.new(1, 0, 1, -24); pStatsContainer.BackgroundTransparency = 1; pStatsContainer.ZIndex = 21; pStatsContainer.LayoutOrder = 2
	Instance.new("UIListLayout", pStatsContainer).Padding = UDim.new(0, 4)

	local sSep1 = Instance.new("Frame", statsAreaCard)
	sSep1.Size = UDim2.new(0, 2, 1, 0); sSep1.BackgroundColor3 = Color3.fromRGB(90, 50, 120); sSep1.BorderSizePixel = 0; sSep1.LayoutOrder = 2; sSep1.ZIndex = 22

	local sStats = Instance.new("Frame", statsAreaCard)
	sStats.Size = UDim2.new(0.5, -6, 1, 0); sStats.BackgroundTransparency = 1; sStats.LayoutOrder = 3
	Instance.new("UIListLayout", sStats).Padding = UDim.new(0, 4)
	CreateTitle(sStats, "STAND STATS")
	sStatsContainer = Instance.new("Frame", sStats)
	sStatsContainer.Size = UDim2.new(1, 0, 1, -24); sStatsContainer.BackgroundTransparency = 1; sStatsContainer.ZIndex = 21; sStatsContainer.LayoutOrder = 2
	Instance.new("UIListLayout", sStatsContainer).Padding = UDim.new(0, 4)

	for _, stat in ipairs(playerStatsList) do statLabels[stat] = CreateStatRow(stat, pStatsContainer) end
	for _, stat in ipairs(standStatsList) do statLabels[stat] = CreateStatRow(stat, sStatsContainer) end

	-- Inventory
	local iacL = Instance.new("UIListLayout", itemsAreaCard)
	iacL.FillDirection = Enum.FillDirection.Horizontal; iacL.Padding = UDim.new(0, 10)

	local keyItems = Instance.new("Frame", itemsAreaCard)
	keyItems.Size = UDim2.new(0.5, -6, 1, 0); keyItems.BackgroundTransparency = 1; keyItems.LayoutOrder = 1
	Instance.new("UIListLayout", keyItems).Padding = UDim.new(0, 4)
	CreateTitle(keyItems, "KEY ITEMS")
	keyItemsContainer = Instance.new("ScrollingFrame", keyItems)
	keyItemsContainer.Size = UDim2.new(1, 0, 1, -24); keyItemsContainer.BackgroundTransparency = 1; keyItemsContainer.ScrollBarThickness = 4; keyItemsContainer.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120); keyItemsContainer.ZIndex = 21; keyItemsContainer.LayoutOrder = 2
	Instance.new("UIPadding", keyItemsContainer).PaddingRight = UDim.new(0, 6)
	Instance.new("UIListLayout", keyItemsContainer).Padding = UDim.new(0, 4)

	local sSep2 = Instance.new("Frame", itemsAreaCard)
	sSep2.Size = UDim2.new(0, 2, 1, 0); sSep2.BackgroundColor3 = Color3.fromRGB(90, 50, 120); sSep2.BorderSizePixel = 0; sSep2.LayoutOrder = 2; sSep2.ZIndex = 22

	local regItems = Instance.new("Frame", itemsAreaCard)
	regItems.Size = UDim2.new(0.5, -6, 1, 0); regItems.BackgroundTransparency = 1; regItems.LayoutOrder = 3
	Instance.new("UIListLayout", regItems).Padding = UDim.new(0, 4)

	local riTop = Instance.new("Frame", regItems)
	riTop.Size = UDim2.new(1, 0, 0, 20); riTop.BackgroundTransparency = 1; riTop.LayoutOrder = 1; riTop.ZIndex = 21
	local riTitle = CreateTitle(riTop, "INVENTORY"); riTitle.Size = UDim2.new(0.5, 0, 1, 0); riTitle.TextXAlignment = Enum.TextXAlignment.Left
	capacityLabel = Instance.new("TextLabel", riTop)
	capacityLabel.Size = UDim2.new(0.5, 0, 1, 0); capacityLabel.Position = UDim2.new(1, -5, 0, 0); capacityLabel.AnchorPoint = Vector2.new(1, 0)
	capacityLabel.BackgroundTransparency = 1; capacityLabel.Font = Enum.Font.GothamMedium; capacityLabel.TextColor3 = Color3.fromRGB(200, 200, 200); capacityLabel.TextXAlignment = Enum.TextXAlignment.Right; capacityLabel.TextScaled = false; capacityLabel.TextSize = 12; capacityLabel.ZIndex = 22

	regItemsContainer = Instance.new("ScrollingFrame", regItems)
	regItemsContainer.Size = UDim2.new(1, 0, 1, -24); regItemsContainer.BackgroundTransparency = 1; regItemsContainer.ScrollBarThickness = 4; regItemsContainer.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120); regItemsContainer.LayoutOrder = 2; regItemsContainer.ZIndex = 21
	Instance.new("UIPadding", regItemsContainer).PaddingRight = UDim.new(0, 6)
	Instance.new("UIListLayout", regItemsContainer).Padding = UDim.new(0, 4)

	-- Auto Roll
	local arL = Instance.new("UIListLayout", autoRollCard)
	arL.FillDirection = Enum.FillDirection.Vertical; arL.SortOrder = Enum.SortOrder.LayoutOrder; arL.Padding = UDim.new(0, 4)
	CreateTitle(autoRollCard, "AUTO ROLL")

	local dropRow = Instance.new("Frame", autoRollCard)
	dropRow.Size = UDim2.new(1, 0, 0.40, 0); dropRow.BackgroundTransparency = 1; dropRow.LayoutOrder = 2
	local drL = Instance.new("UIListLayout", dropRow)
	drL.FillDirection = Enum.FillDirection.Horizontal; drL.Padding = UDim.new(0.02, 0)

	local function createDrop(name, text, color)
		local btn = Instance.new("TextButton", dropRow)
		btn.Name = name; btn.Size = UDim2.new(0.49, 0, 1, 0); btn.BackgroundColor3 = Color3.fromRGB(40, 20, 60); btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.GothamBold; btn.TextScaled = false; btn.TextSize = 12; btn.Text = text; btn.ZIndex = 25
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		local s = Instance.new("UIStroke", btn); s.Color = color; s.Thickness = 1

		local list = Instance.new("ScrollingFrame", btn)
		list.Name = "List"; list.Size = UDim2.new(1, 0, 0, 120); list.AnchorPoint = Vector2.new(0, 1); list.Position = UDim2.new(0, 0, 0, -2); list.BackgroundColor3 = Color3.fromRGB(30, 15, 50); list.ZIndex = 50; list.Visible = false; list.ScrollBarThickness = 4
		Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
		local ls = Instance.new("UIStroke", list); ls.Color = color; ls.Thickness = 1
		return btn
	end

	local sDrop = createDrop("StandDropdown", "Target Stand: Any", Color3.fromRGB(120, 60, 180))
	local tDrop = createDrop("TraitDropdown", "Target Trait: Any", Color3.fromRGB(120, 60, 180))

	local btnRow = Instance.new("Frame", autoRollCard)
	btnRow.Size = UDim2.new(1, 0, 0.40, 0); btnRow.BackgroundTransparency = 1; btnRow.LayoutOrder = 3
	local brL = Instance.new("UIListLayout", btnRow)
	brL.FillDirection = Enum.FillDirection.Horizontal; brL.Padding = UDim.new(0.02, 0)

	local function createRollBtn(name, text, color)
		local btn = Instance.new("TextButton", btnRow)
		btn.Name = name; btn.Size = UDim2.new(0.32, 0, 1, 0); btn.BackgroundColor3 = color; btn.TextColor3 = Color3.new(1,1,1); btn.Font = Enum.Font.GothamBold; btn.TextScaled = false; btn.TextSize = 11; btn.Text = text; btn.ZIndex = 25
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		local s = Instance.new("UIStroke", btn); s.Color = Color3.new(1,1,1); s.Thickness = 1
		return btn
	end

	local btnRArrow = createRollBtn("RollArrowBtn", "Arrow", Color3.fromRGB(200, 150, 0))
	local btnRCorpse = createRollBtn("RollCorpseBtn", "Corpse", Color3.fromRGB(200, 50, 150))
	local btnRRoka = createRollBtn("RollRokaBtn", "Roka", Color3.fromRGB(200, 50, 50))


	-- ==========================================
	-- HOOK UP EVENTS & LOGIC
	-- ==========================================
	BuildDropdownList(sDrop, sDrop:WaitForChild("List"), StandData.Stands, true)
	BuildDropdownList(tDrop, tDrop:WaitForChild("List"), StandData.Traits, false)

	local function HandleAutoRollRequest(rollType)
		SFXManager.Play("Click")
		if not player:GetAttribute("HasAutoRoll") then MarketplaceService:PromptGamePassPurchase(player, 1749484465); return end
		local r = Network:FindFirstChild("AutoRoll")
		if r then r:FireServer(rollType, targetAutoStand, targetAutoTrait) end
	end

	btnRArrow.MouseButton1Click:Connect(function() HandleAutoRollRequest("Arrow") end)
	btnRCorpse.MouseButton1Click:Connect(function() HandleAutoRollRequest("Corpse") end)
	btnRRoka.MouseButton1Click:Connect(function() HandleAutoRollRequest("Roka") end)

	standLockBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); local remote = Network:FindFirstChild("ToggleLock"); if remote then remote:FireServer("Stand") end end)
	styleLockBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); local remote = Network:FindFirstChild("ToggleLock"); if remote then remote:FireServer("Style") end end)

	toggleStorageBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if currentStorageMode == "Stand" then
			currentStorageMode = "Style"
			stTitle.Text = "STYLE STORAGE"
			toggleStorageBtn.Text = "Stands"
			toggleStorageBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
		else
			currentStorageMode = "Stand"
			stTitle.Text = "STAND STORAGE"
			toggleStorageBtn.Text = "Styles"
			toggleStorageBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 20)
		end
		RefreshStorageList()
	end)

	for _, r in ipairs(raritiesToSell) do
		local btn = autoSellContainer:WaitForChild("AutoSell_" .. r)
		local baseCol = rarityColors[r] or Color3.new(1,1,1)

		local function updateBtn()
			if player:GetAttribute("AutoSell_" .. r) then
				btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
				local stroke = btn:FindFirstChild("UIStroke")
				if stroke then stroke.Color = baseCol end
			else
				btn.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
				local stroke = btn:FindFirstChild("UIStroke")
				if stroke then stroke.Color = Color3.fromRGB(100, 100, 100) end
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
end

return InventoryTab