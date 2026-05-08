-- @ScriptType: ModuleScript
local ShopTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local ItemData = require(ReplicatedStorage:WaitForChild("GangItemData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local MarketplaceService = game:GetService("MarketplaceService")

local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))
local GiftManager = require(UIModules:WaitForChild("GiftManager"))
local TooltipManager = require(UIModules:WaitForChild("TooltipManager"))

local PREMIUM_RESTOCK_PRODUCT_ID = 3588089796

local shopContainer, timerLabel, yenLabel
local cachedTooltipMgr = nil

local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("JJBIMenu", 10)

local rarityColors = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(50, 100, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythical = Color3.fromRGB(255, 50, 50),
	Unique = Color3.fromRGB(215, 69, 255),
	Special = Color3.fromRGB(239, 255, 62)
}


local function FormatTime(seconds)
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

function ShopTab.Init(parentFrame, tooltipMgr)
	cachedTooltipMgr = TooltipManager

	local mainPanel = parentFrame:WaitForChild("MainPanel")
	local innerContent = mainPanel:WaitForChild("InnerContent")

	local subNavFrame = innerContent:WaitForChild("SubNavFrame")

	local tabContainer = innerContent:WaitForChild("TabContainer")
	local marketTabContent = tabContainer:WaitForChild("MarketTabContent")

	local stockCard = marketTabContent:WaitForChild("StockCard")
	local scTop = stockCard:WaitForChild("TopArea")
	timerLabel = scTop:WaitForChild("TimerLabel")
	yenLabel = scTop:WaitForChild("YenLabel")
	local restockArea = scTop:WaitForChild("RestockArea")
	local restockYenBtn = restockArea:WaitForChild("RestockYenBtn")
	local restockRobuxBtn = restockArea:WaitForChild("RestockRobuxBtn")
	shopContainer = stockCard:WaitForChild("ShopContainer")


	local Templates = ReplicatedStorage:WaitForChild("JJBITemplates")
	local shopItemTpl = Templates:WaitForChild("ShopItemTemplate")
	local premiumItemTpl = Templates:WaitForChild("PremiumItemTemplate")

	local premLabels = {}
	local gachaBtns = {}

	restockYenBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		Network.GangShopAction:FireServer("RestockYen")
	end)

	restockRobuxBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		Network.GangShopAction:FireServer("SetRestockType", "Normal")
		MarketplaceService:PromptProductPurchase(player, PREMIUM_RESTOCK_PRODUCT_ID)
	end)

	
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


	local function SwitchTab(target)
		SFXManager.Play("Click")
		marketTabContent.Visible = (target == "MARKET")
		premiumTabContent.Visible = (target == "PREMIUM")

		marketTabBtn.BackgroundColor3 = (target == "MARKET") and Color3.fromRGB(70, 30, 100) or Color3.fromRGB(30, 20, 50)
		marketTabBtn.TextColor3 = (target == "MARKET") and Color3.fromRGB(255, 235, 130) or Color3.fromRGB(200, 200, 220)
		

		premiumTabBtn.BackgroundColor3 = (target == "PREMIUM") and Color3.fromRGB(70, 30, 100) or Color3.fromRGB(30, 20, 50)
		premiumTabBtn.TextColor3 = (target == "PREMIUM") and Color3.fromRGB(255, 235, 130) or Color3.fromRGB(200, 200, 220)
		
	end

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

		if not stockStr or stockStr == "" then return end
		local stockData = {}

		if string.sub(stockStr, 1, 1) == "[" then
			local success, decoded = pcall(function() return game:GetService("HttpService"):JSONDecode(stockStr) end)
			if success and decoded then stockData = decoded end
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
			nameLabel.Text = item.Name .. "\n<font color='#55FF55'>" .. (item.Cost or 0) .. " Gang Tokens</font>"

			local buyBtn = itemFrame:WaitForChild("BuyBtn")
			buyBtn.MouseButton1Click:Connect(function() 
				SFXManager.Play("Click") 
				Network.GangShopAction:FireServer("Buy", item.Name) 
			end)

			itemFrame.MouseEnter:Connect(function() cachedTooltipMgr.Show(cachedTooltipMgr.GetItemTooltip(item.Name)) end)
			itemFrame.MouseLeave:Connect(function() cachedTooltipMgr.Hide() end)
		end
	end

	Network:WaitForChild("GangShopUpdate").OnClientEvent:Connect(function(action, data)
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


	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
		if userId == player.UserId and wasPurchased then 
			SFXManager.Play("BuyPass") 
		end
	end)

	player:GetAttributeChangedSignal("GangShopStock"):Connect(function() 
		RefreshShopItems(player:GetAttribute("GangShopStock")) 
	end)

	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 5)
		if leaderstats then
			local yen = leaderstats:WaitForChild("GangTokens", 5)
			if yen then
				yenLabel.Text = "Gang Tokens: <font color='#55FF55'>" .. yen.Value .. "</font>"
				yen.Changed:Connect(function(val) 
					yenLabel.Text = "Gang Tokens: <font color='#55FF55'>" .. val .. "</font>" 
				end)
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			local rt = player:GetAttribute("GangShopRefreshTime") or 0
			local remain = rt - math.floor(workspace:GetServerTimeNow())
			if remain > 0 then 
				timerLabel.Text = "Restocks in: " .. FormatTime(remain) 
			else 
				timerLabel.Text = "Restocking..." 
			end
		end
	end)

	task.delay(1, function() 
		RefreshShopItems(player:GetAttribute("GangShopStock")) 
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