-- @ScriptType: ModuleScript
local ShopTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local MarketplaceService = game:GetService("MarketplaceService")

local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))
local GiftManager = require(UIModules:WaitForChild("GiftManager"))

local PREMIUM_RESTOCK_PRODUCT_ID = 3548843760

local shopContainer, timerLabel, yenLabel
local cachedTooltipMgr = nil

local rarityColors = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(50, 100, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythical = Color3.fromRGB(255, 50, 50),
	Unique = Color3.fromRGB(215, 69, 255)
}

local premiumItems = {
	{ Type = "Product", Id = 3553771635, Name = "Saint's Corpse Part (x10)", Price = 400, Desc = "<b><font color='#FFD700'>Saint's Corpse Part (x10)</font></b>\nGives you <font color='#55FF55'>x10 Saint's Corpse Parts</font>." },
	{ Type = "Product", Id = 3550862625, Name = "Stand Arrow (x25)", Price = 250, Desc = "<b><font color='#FFD700'>Stand Arrow (x25)</font></b>\nGives you <font color='#55FF55'>x25 Stand Arrows</font>." },
	{ Type = "Product", Id = 3550862858, Name = "Rokakaka (x5)", Price = 100, Desc = "<b><font color='#FFD700'>Rokakaka (x5)</font></b>\nGives you <font color='#55FF55'>x5 Rokakakas</font>." },
	{ Type = "Product", Id = 3560808666, Name = "Mythical Giftbox", Price = 400, Desc = "<b><font color='#FFD700'>Mythical Giftbox</font></b>\nGives you 1 random <font color='#FF55FF'>Mythical Item</font>." },

	{ Type = "Product", Id = 3560802297, Name = "Gappy Pack", Price = 1500, Desc = "<b><font color='#FFD700'>Gappy Bundle</font></b>\n<b>Soft & Wet</b> <font color='#FF55FF'>[Lethal]</font>, & x25 Rokakaka" },
	{ Type = "Product", Id = 3553767064, Name = "Johnny Pack", Price = 1500, Desc = "<b><font color='#FFD700'>Johnny Bundle</font></b>\n<b>Tusk Act 1</b> <font color='#FF55FF'>[Cheerful]</font>, Saint's Left Arm, & Saint's Right Eye." },
	{ Type = "Product", Id = 3547646706, Name = "DIO Pack", Price = 1500, Desc = "<b><font color='#FFD700'>DIO Bundle</font></b>\n<b>The World</b> <font color='#FF55FF'>[Vampiric]</font>, Vampirism Style, Vampire Cape & Dio's Throwing Knives." },
	{ Type = "Product", Id = 3550839948, Name = "Pucci Pack", Price = 1500, Desc = "<b><font color='#FFD700'>Pucci Bundle</font></b>\n<b>Whitesnake</b> <font color='#FF55FF'>[Blessed]</font>, Green Baby, & Dio's Diary." },
	{ Type = "Product", Id = 3547646703, Name = "Jotaro Pack", Price = 1500, Desc = "<b><font color='#FFD700'>Jotaro Bundle</font></b>\n<b>Star Platinum</b> <font color='#FF55FF'>[Overwhelming]</font>, Jotaro's Hat & Dio's Diary." },

	{ Type = "Product", Id = 3553764779, Name = "Spin Pack", Price = 200, Desc = "<b><font color='#FFD700'>Spin Bundle</font></b>\n<font color='#5FE625'>Spin Style</font> & Saint's Right Eye." },
	{ Type = "Product", Id = 3548207626, Name = "Hamon Pack", Price = 200, Desc = "<b><font color='#FFD700'>Hamon Bundle</font></b>\n<font color='#FF8855'>Hamon Style</font>, Hamon Clackers, & Hamon Breathing Mask." },
	{ Type = "Product", Id = 3548207336, Name = "Vampire Pack", Price = 200, Desc = "<b><font color='#FFD700'>Vampire Bundle</font></b>\n<font color='#AA00AA'>Vampire Style</font> & Vampire Cape." },
	{ Type = "Product", Id = 3548207175, Name = "Pillarman Pack", Price = 200, Desc = "<b><font color='#FFD700'>Pillarman Bundle</font></b>\n<font color='#FF5555'>Pillarman Style</font> & Red Stone of Aja." },

	{ Type = "Pass", Id = 1772743731, GiftId = 3564614546, Name = "VIP Pass", Price = 900, Desc = "<b><font color='#FFD700'>VIP Status</font></b>\n<font color='#55FF55'>2x Training Speed</font>\nExclusive VIP Stand Slot\nExclusive VIP Style Slot.", Attr = "IsVIP" },
	{ Type = "Pass", Id = 1731694181, GiftId = 3552102461, Name = "2x Speed", Price = 200, Desc = "<b><font color='#55FFFF'>2x Battle Speed</font></b>\nBattles play out <font color='#55FF55'>twice as fast!</font>", Attr = "Has2xBattleSpeed" },
	{ Type = "Pass", Id = 1732900742, GiftId = 3552102647, Name = "2x Inventory", Price = 100, Desc = "<b><font color='#55FFFF'>2x Inventory</font></b>\nIncreases slots to <font color='#55FF55'>30</font>.", Attr = "Has2xInventory" },
	{ Type = "Pass", Id = 1732842877, GiftId = 3552103016, Name = "2x Drops", Price = 400, Desc = "<b><font color='#55FFFF'>2x Drop Chance</font></b>\n<font color='#55FF55'>Doubles</font> the chance of items dropping.", Attr = "Has2xDropChance" },
	{ Type = "Pass", Id = 1749484465, GiftId = 3557500443, Name = "Auto-Roll", Price = 400, Desc = "<b><font color='#55FFFF'>Auto-Roll</font></b>\nInstantly roll for target Stands/Traits!", Attr = "HasAutoRoll" },
	{ Type = "Pass", Id = 1733160695, GiftId = 3552103567, Name = "Stand Slot 2", Price = 150, Desc = "<b><font color='#55FFFF'>Stand Storage 2</font></b>\nUnlocks the <font color='#FFD700'>second</font> stand slot.", Attr = "HasStandSlot2" },
	{ Type = "Pass", Id = 1732844091, GiftId = 3552103754, Name = "Stand Slot 3", Price = 300, Desc = "<b><font color='#55FFFF'>Stand Storage 3</font></b>\nUnlocks the <font color='#FFD700'>third</font> stand slot.", Attr = "HasStandSlot3" },
	{ Type = "Pass", Id = 1746853452, GiftId = 3554936785, Name = "Style Slot 2", Price = 50, Desc = "<b><font color='#55FFFF'>Style Storage 2</font></b>\nUnlocks the <font color='#55FF55'>second</font> style slot.", Attr = "HasStyleSlot2" },
	{ Type = "Pass", Id = 1745969849, GiftId = 3554936823, Name = "Style Slot 3", Price = 100, Desc = "<b><font color='#55FFFF'>Style Storage 3</font></b>\nUnlocks the <font color='#55FF55'>third</font> style slot.", Attr = "HasStyleSlot3" },
	{ Type = "Pass", Id = 1732129582, GiftId = 3552103397, Name = "Auto Train", Price = 40, Desc = "<b><font color='#55FFFF'>Auto Training</font></b>\nAuto-starts training on join!", Attr = "HasAutoTraining" },
	{ Type = "Pass", Id = 1749586333, GiftId = 3557535781, Name = "Custom Horse", Price = 40, Desc = "<b><font color='#55FFFF'>Horse Name</font></b>\nAbility to <font color='#55FF55'>name your horse</font>!", Attr = "HasHorseNamePass" },
}

local function FormatTime(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

function ShopTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = tooltipMgr

	local mainPanel = parentFrame:WaitForChild("MainPanel")
	local innerContent = mainPanel:WaitForChild("InnerContent")

	local subNavFrame = innerContent:WaitForChild("SubNavFrame")
	local marketTabBtn = subNavFrame:WaitForChild("MarketTabBtn")
	local premiumTabBtn = subNavFrame:WaitForChild("PremiumTabBtn")

	local tabContainer = innerContent:WaitForChild("TabContainer")
	local marketTabContent = tabContainer:WaitForChild("MarketTabContent")
	local premiumTabContent = tabContainer:WaitForChild("PremiumTabContent")

	local stockCard = marketTabContent:WaitForChild("StockCard")
	local scTop = stockCard:WaitForChild("TopArea")
	timerLabel = scTop:WaitForChild("TimerLabel")
	yenLabel = scTop:WaitForChild("YenLabel")
	local restockArea = scTop:WaitForChild("RestockArea")
	local restockYenBtn = restockArea:WaitForChild("RestockYenBtn")
	local restockRobuxBtn = restockArea:WaitForChild("RestockRobuxBtn")
	shopContainer = stockCard:WaitForChild("ShopContainer")

	local ratesCard = marketTabContent:WaitForChild("RatesCard")
	local rcSplit = ratesCard:WaitForChild("SplitArea")
	local standRatesCol = rcSplit:WaitForChild("StandRatesScroll"):WaitForChild("StandRatesCol")
	local traitRatesCol = rcSplit:WaitForChild("TraitRatesScroll"):WaitForChild("TraitRatesCol")

	local codesCard = marketTabContent:WaitForChild("CodesCard")
	local codeArea = codesCard:WaitForChild("CodeArea")
	local codeInput = codeArea:WaitForChild("CodeInput")
	local redeemBtn = codeArea:WaitForChild("RedeemBtn")

	local prodCard = premiumTabContent:WaitForChild("ProductsCard")
	local prodScroll = prodCard:WaitForChild("ProdScroll")

	local passCard = premiumTabContent:WaitForChild("PassesCard")
	local passScroll = passCard:WaitForChild("PassScroll")

	local Templates = ReplicatedStorage:WaitForChild("JJBITemplates")
	local shopItemTpl = Templates:WaitForChild("ShopItemTemplate")
	local premiumItemTpl = Templates:WaitForChild("PremiumItemTemplate")

	local premLabels = {}
	local gachaBtns = {}

	restockYenBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		Network.ShopAction:FireServer("RestockYen")
	end)

	restockRobuxBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		MarketplaceService:PromptProductPurchase(player, PREMIUM_RESTOCK_PRODUCT_ID)
	end)

	for i, pInfo in ipairs(premiumItems) do
		local isPass = (pInfo.Type == "Pass")
		local isGacha = (pInfo.Id == 3553771635 or pInfo.Id == 3550862625 or pInfo.Id == 3550862858 or pInfo.Id == 3560808666)
		local targetScroll = isPass and passScroll or prodScroll

		local itemFrm = premiumItemTpl:Clone()
		itemFrm.LayoutOrder = i
		itemFrm.Parent = targetScroll

		local nLbl = itemFrm:WaitForChild("TitleLabel")
		nLbl.Text = pInfo.Name

		local dLbl = itemFrm:WaitForChild("DescLabel")
		dLbl.Text = pInfo.Desc

		local buyBtn = itemFrm:WaitForChild("BuyBtn")
		buyBtn.Text = tostring(pInfo.Price) .. " R$"

		local giftBtn = itemFrm:WaitForChild("GiftBtn")

		if isGacha then table.insert(gachaBtns, {Btn = buyBtn, Price = pInfo.Price, DescLbl = dLbl, OrigDesc = pInfo.Desc}) end

		if pInfo.Type == "Product" or pInfo.GiftId then
			if isGacha then table.insert(gachaBtns, {Btn = giftBtn, IsGift = true}) end

			giftBtn.MouseButton1Click:Connect(function()
				if isGacha and player:GetAttribute("PaidRandomItemsRestricted") then SFXManager.Play("CombatBlock"); return end
				SFXManager.Play("Click")
				GiftManager.OpenGiftModal(pInfo)
			end)
		else
			giftBtn.Visible = false
			buyBtn.Size = UDim2.new(1, -10, 0, 24)
			buyBtn.Position = UDim2.new(0, 5, 1, -29)
		end

		buyBtn.MouseButton1Click:Connect(function()
			if isGacha and player:GetAttribute("PaidRandomItemsRestricted") then SFXManager.Play("CombatBlock"); return end
			if pInfo.Attr and player:GetAttribute(pInfo.Attr) then return end 
			SFXManager.Play("Click")
			Network.ShopAction:FireServer("SetGiftTarget", 0)
			task.wait(0.1) 
			if isPass then 
				MarketplaceService:PromptGamePassPurchase(player, pInfo.Id)
			else 
				MarketplaceService:PromptProductPurchase(player, pInfo.Id) 
			end
		end)

		if pInfo.Attr then 
			premLabels[pInfo.Attr] = {Btn = buyBtn, Price = pInfo.Price} 
		end
	end

	local function UpdateRestrictedUI()
		local restricted = player:GetAttribute("PaidRandomItemsRestricted")
		for _, gData in ipairs(gachaBtns) do
			if restricted then
				gData.Btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				if gData.IsGift then
					gData.Btn.Text = "BLOCKED"
				else
					gData.Btn.Text = "RESTRICTED"
					if gData.DescLbl then
						gData.DescLbl.Text = gData.OrigDesc .. "\n\n<font color='#FF5555'><b>RESTRICTED IN YOUR REGION</b></font>"
					end
				end
			else
				if gData.IsGift then
					gData.Btn.BackgroundColor3 = Color3.fromRGB(180, 80, 20)
					gData.Btn.Text = "Gift"
				else
					gData.Btn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
					gData.Btn.Text = tostring(gData.Price) .. " R$"
					if gData.DescLbl then
						gData.DescLbl.Text = gData.OrigDesc
					end
				end
			end
		end
	end
	player:GetAttributeChangedSignal("PaidRandomItemsRestricted"):Connect(UpdateRestrictedUI)
	UpdateRestrictedUI()

	task.spawn(function()
		task.wait(0.1)
		local prodGL = prodScroll:WaitForChild("UIGridLayout")
		local passGL = passScroll:WaitForChild("UIGridLayout")
		prodScroll.CanvasSize = UDim2.new(0, 0, 0, prodGL.AbsoluteContentSize.Y + 10)
		passScroll.CanvasSize = UDim2.new(0, 0, 0, passGL.AbsoluteContentSize.Y + 10)
	end)

	local function SwitchTab(target)
		SFXManager.Play("Click")
		marketTabContent.Visible = (target == "MARKET")
		premiumTabContent.Visible = (target == "PREMIUM")

		marketTabBtn.BackgroundColor3 = (target == "MARKET") and Color3.fromRGB(70, 30, 100) or Color3.fromRGB(30, 20, 50)
		marketTabBtn.TextColor3 = (target == "MARKET") and Color3.fromRGB(255, 235, 130) or Color3.fromRGB(200, 200, 220)
		marketTabBtn:FindFirstChild("UIStroke").Color = (target == "MARKET") and Color3.fromRGB(255, 215, 50) or Color3.fromRGB(90, 50, 120)
		marketTabBtn:FindFirstChild("UIStroke").Thickness = (target == "MARKET") and 2 or 1

		premiumTabBtn.BackgroundColor3 = (target == "PREMIUM") and Color3.fromRGB(70, 30, 100) or Color3.fromRGB(30, 20, 50)
		premiumTabBtn.TextColor3 = (target == "PREMIUM") and Color3.fromRGB(255, 235, 130) or Color3.fromRGB(200, 200, 220)
		premiumTabBtn:FindFirstChild("UIStroke").Color = (target == "PREMIUM") and Color3.fromRGB(255, 215, 50) or Color3.fromRGB(90, 50, 120)
		premiumTabBtn:FindFirstChild("UIStroke").Thickness = (target == "PREMIUM") and 2 or 1
	end

	marketTabBtn.MouseButton1Click:Connect(function() SwitchTab("MARKET") end)
	premiumTabBtn.MouseButton1Click:Connect(function() SwitchTab("PREMIUM") end)

	redeemBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if codeInput.Text ~= "" then
			Network.RedeemCode:FireServer(codeInput.Text)
			codeInput.Text = ""
		end
	end)

	local function RefreshDropRatesText()
		local currentStand = player:GetAttribute("Stand") or "None"
		local currentTrait = player:GetAttribute("StandTrait") or "None"

		local function BuildPoolString(dataTable, isTrait, currentEquipped)
			local pools = { Common = {}, Uncommon = {}, Rare = {}, Legendary = {}, Mythical = {}, Evolution = {}, Boss = {} }
			local rates = {}

			if isTrait then 
				rates = { Common = "35%", Rare = "16%", Legendary = "6%", Mythical = "1%" }
			else 
				rates = { Common = "50%", Uncommon = "30%", Rare = "15%", Legendary = "5%", Mythical = "1% WORLD BOSS ONLY" } 
			end

			for name, data in pairs(dataTable) do
				if pools[data.Rarity] then 
					table.insert(pools[data.Rarity], name) 
				end
			end

			local str = ""
			local order = {"Common", "Uncommon", "Rare", "Legendary", "Mythical"}
			local hexes = { Common = "#AAAAAA", Uncommon = "#55FF55", Rare = "#55FFFF", Legendary = "#FFD700", Mythical = "#FF55FF" }

			for _, rarity in ipairs(order) do
				if #pools[rarity] > 0 and rates[rarity] then
					table.sort(pools[rarity])
					str = str .. "<b><font color='"..hexes[rarity].."'>"..rarity.." ("..rates[rarity]..")</font></b>\n"

					local formattedNames = {}
					for _, name in ipairs(pools[rarity]) do
						if name == currentEquipped then 
							table.insert(formattedNames, "<u><b><font color='#FFFFFF'>" .. name .. "</font></b></u>")
						else 
							table.insert(formattedNames, name) 
						end
					end
					str = str .. table.concat(formattedNames, ", ") .. "\n\n"
				end
			end

			if not isTrait and #pools["Evolution"] > 0 then
				table.sort(pools["Evolution"])
				str = str .. "<b><font color='#AA00AA'>Evolution</font></b>\n"
				local formattedEvos = {}
				for _, name in ipairs(pools["Evolution"]) do
					if name == currentEquipped then 
						table.insert(formattedEvos, "<u><b><font color='#FFFFFF'>" .. name .. "</font></b></u>")
					else 
						table.insert(formattedEvos, name) 
					end
				end
				str = str .. table.concat(formattedEvos, ", ") .. "\n\n"
			end
			return str
		end

		standRatesCol.Text = "<b><font size='14'>STAND ARROW RATES</font></b>\n<i><font color='#888888'>Guarantees Rare+ every 25 rolls.</font></i>\n\n" .. BuildPoolString(StandData.Stands, false, currentStand)
		traitRatesCol.Text = "<b><font size='14'>ROKAKAKA RATES</font></b>\n<i><font color='#888888'>Guarantees Legendary+ every 5 rolls.</font></i>\n\n" .. BuildPoolString(StandData.Traits, true, currentTrait)
	end

	player:GetAttributeChangedSignal("Stand"):Connect(RefreshDropRatesText)
	player:GetAttributeChangedSignal("StandTrait"):Connect(RefreshDropRatesText)
	RefreshDropRatesText()

	local function UpdateRobuxUI()
		for attrName, data in pairs(premLabels) do
			if player:GetAttribute(attrName) then
				data.Btn.Text = "OWNED"
				data.Btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				data.Btn.Text = tostring(data.Price) .. " R$"
				data.Btn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
			end
		end
	end

	for attrName, _ in pairs(premLabels) do 
		player:GetAttributeChangedSignal(attrName):Connect(UpdateRobuxUI) 
	end

	UpdateRobuxUI()

	local function RefreshShopItems(stockStr)
		for _, child in pairs(shopContainer:GetChildren()) do 
			if child:IsA("Frame") then 
				child:Destroy() 
			end 
		end

		if not stockStr or stockStr == "" then 
			return 
		end

		local stockData = {}

		if string.sub(stockStr, 1, 1) == "[" then
			local success, decoded = pcall(function() 
				return game:GetService("HttpService"):JSONDecode(stockStr) 
			end)
			if success and decoded then 
				stockData = decoded 
			end
		else
			local items = string.split(stockStr, ",")
			for _, name in ipairs(items) do
				if name ~= "" then
					local data = ItemData.Equipment[name] or ItemData.Consumables[name]
					if data then
						table.insert(stockData, { Name = name, Cost = data.Cost or data.Price or 50, Rarity = data.Rarity or "Common" })
					end
				end
			end
		end

		for _, item in ipairs(stockData) do
			local itemFrame = shopItemTpl:Clone()
			itemFrame.Parent = shopContainer

			local iStr = itemFrame:WaitForChild("UIStroke")
			iStr.Color = rarityColors[item.Rarity or "Common"]

			local nameLabel = itemFrame:WaitForChild("NameLabel")
			nameLabel.TextColor3 = rarityColors[item.Rarity or "Common"]
			nameLabel.Text = item.Name .. "\n<font color='#55FF55'>¥" .. (item.Cost or 0) .. "</font>"

			local buyBtn = itemFrame:WaitForChild("BuyBtn")
			buyBtn.MouseButton1Click:Connect(function() 
				SFXManager.Play("Click") 
				Network.ShopAction:FireServer("Buy", item.Name) 
			end)

			itemFrame.MouseEnter:Connect(function() 
				cachedTooltipMgr.Show(cachedTooltipMgr.GetItemTooltip(item.Name)) 
			end)

			itemFrame.MouseLeave:Connect(function()
				cachedTooltipMgr.Hide()
			end)
		end
	end

	Network:WaitForChild("ShopUpdate").OnClientEvent:Connect(function(action, data)
		if action == "Refresh" then 
			RefreshShopItems(table.concat(data, ",")) 
		elseif type(data) == "string" and (action == "Notify" or action == "Notification" or action == "SystemMessage" or action == "Message" or action == "Error" or action == "Success") then
			NotificationManager.Show(data)
		elseif type(action) == "string" and data == nil then
			if action ~= "Refresh" and not string.match(action, "Prompt") then
				NotificationManager.Show(action)
			end
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(passPlayer, passId, wasPurchased)
		if passPlayer == player and wasPurchased then 
			SFXManager.Play("BuyPass") 
			for _, pItem in ipairs(premiumItems) do 
				if pItem.Id == passId and pItem.Attr then 
					player:SetAttribute(pItem.Attr, true) 
				end 
			end
		end
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
		if userId == player.UserId and wasPurchased then 
			SFXManager.Play("BuyPass") 
		end
	end)

	player:GetAttributeChangedSignal("ShopStock"):Connect(function() 
		RefreshShopItems(player:GetAttribute("ShopStock")) 
	end)

	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 5)
		if leaderstats then
			local yen = leaderstats:WaitForChild("Yen", 5)
			if yen then
				yenLabel.Text = "Yen: <font color='#55FF55'>¥" .. yen.Value .. "</font>"
				yen.Changed:Connect(function(val) 
					yenLabel.Text = "Yen: <font color='#55FF55'>¥" .. val .. "</font>" 
				end)
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			local rt = player:GetAttribute("ShopRefreshTime") or 0
			local remain = rt - os.time()
			if remain > 0 then 
				timerLabel.Text = "Restocks in: " .. FormatTime(remain) 
			else 
				timerLabel.Text = "Restocking..." 
			end
		end
	end)

	task.delay(1, function() 
		RefreshShopItems(player:GetAttribute("ShopStock")) 
	end)

	local camera = workspace.CurrentCamera
	local resizeConn

	local function UpdateLayoutForScreen()
		if not parentFrame.Parent then
			if resizeConn then resizeConn:Disconnect() end
			return
		end

		local vp = camera.ViewportSize
		if vp.X >= 1050 then
			mainPanel.Size = UDim2.new(0.80, 0, 0.88, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
		elseif vp.X >= 600 and vp.X < 1050 then
			mainPanel.Size = UDim2.new(0.92, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
		else
			mainPanel.Size = UDim2.new(0.96, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0) 
		end

		local panelAbsHeight = vp.Y * mainPanel.Size.Y.Scale
		local minHeight = 600

		if panelAbsHeight < minHeight then
			innerContent.CanvasSize = UDim2.new(0, 0, 0, minHeight)
			innerContent.ScrollBarImageTransparency = 0
			innerContent.ScrollBarThickness = 6
			innerContent.ScrollingEnabled = true
		else
			innerContent.CanvasSize = UDim2.new(0, 0, 1, 0)
			innerContent.ScrollBarImageTransparency = 1
			innerContent.ScrollBarThickness = 0
			innerContent.ScrollingEnabled = false
		end
	end

	resizeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
	UpdateLayoutForScreen()
end

return ShopTab