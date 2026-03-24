-- @ScriptType: ModuleScript
local TradingTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))

local templates
local topCard, bottomCard, activeTradeCard
local reqView, hostView, browserLobbyView, browserInboxView
local requestsEnabled = true
local isHosting = false

local forceTabFocus

local myOfferGrid, oppOfferGrid, myInvList, myStandList, myStyleList
local myYenLbl, oppYenLbl, tradeStatusLbl
local addYenInput, lockBtn, confirmBtn
local claimModal, claimContainer, claimTitle
local btnActive, btnSlot1, btnSlot2, btnSlot3, btnSlot4, btnSlot5

local styleClaimModal, styleClaimContainer, styleClaimTitle
local btnStyleActive, btnStyleSlot1, btnStyleSlot2, btnStyleSlot3

local rarityColors = {
	Common = Color3.fromRGB(150, 150, 150),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(50, 100, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythical = Color3.fromRGB(255, 50, 50),
	Unique = Color3.fromRGB(215, 69, 255)
}

local rarityOrder = { Common = 1, Uncommon = 2, Rare = 3, Legendary = 4, Mythical = 5, Unique = 6 }

local function IsRestrictedPass(name)
	local passes = {
		["2x Battle Speed Pass"] = true,
		["2x Inventory Pass"] = true,
		["2x Drop Chance Pass"] = true,
		["Auto Training Pass"] = true,
		["Stand Storage Slot 2"] = true,
		["Stand Storage Slot 3"] = true,
		["Style Storage Slot 2"] = true,
		["Style Storage Slot 3"] = true,
		["Auto-Roll Pass"] = true,
		["Custom Horse Name"] = true,
		["Custom Horse Name Pass"] = true
	}
	return passes[name] == true
end

local KnownItems = {"Any / Offers"}

for itemName, _ in pairs(ItemData.Consumables) do table.insert(KnownItems, itemName) end
for eqName, _ in pairs(ItemData.Equipment) do table.insert(KnownItems, eqName) end

table.sort(KnownItems, function(a, b)
	if a == "Any / Offers" then return true end
	if b == "Any / Offers" then return false end

	local dataA = ItemData.Consumables[a] or ItemData.Equipment[a]
	local dataB = ItemData.Consumables[b] or ItemData.Equipment[b]
	local rA = dataA and dataA.Rarity or "Common"
	local rB = dataB and dataB.Rarity or "Common"
	local orderA = rarityOrder[rA] or 1
	local orderB = rarityOrder[rB] or 1

	if orderA == orderB then return a < b else return orderA < orderB end
end)

local function CreateTradeItemBtn(text, color, strokeColor, zIndex)
	local btn = templates:WaitForChild("TradeItemBtnTemplate"):Clone()
	btn.BackgroundColor3 = color or Color3.fromRGB(30, 20, 40)
	btn.Text = text
	btn.ZIndex = zIndex or 22
	if strokeColor then
		local str = btn:FindFirstChildOfClass("UIStroke")
		if str then str.Color = strokeColor end
	end
	return btn
end

local function InitDropdown(frame, getOptionsFunc)
	local mainBtn = frame:WaitForChild("MainBtn")
	local listFrame = frame:WaitForChild("ListFrame")
	local selectedValue = ""

	mainBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		listFrame.Visible = not listFrame.Visible
		if listFrame.Visible then
			for _, c in pairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
			local options = getOptionsFunc()

			if #options == 0 then
				local empty = Instance.new("TextLabel", listFrame)
				empty.Size = UDim2.new(1, 0, 0, 30)
				empty.BackgroundTransparency = 1
				empty.Text = "No players found"
				empty.Font = Enum.Font.GothamMedium
				empty.TextColor3 = Color3.fromRGB(150, 150, 150)
				empty.TextSize = 14
				empty.ZIndex = 51
				listFrame.CanvasSize = UDim2.new(0, 0, 0, 30)
				return
			end

			for i, opt in ipairs(options) do
				local btn = templates:WaitForChild("TradeDropdownItemTemplate"):Clone()
				btn.BackgroundTransparency = (i%2==0) and 0.5 or 1
				btn.Text = opt
				btn.LayoutOrder = i
				btn.Parent = listFrame

				btn.MouseButton1Click:Connect(function()
					SFXManager.Play("Click")
					selectedValue = opt
					mainBtn.Text = opt
					listFrame.Visible = false
				end)
			end
			listFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
		end
	end)

	return function() return selectedValue end, function(txt) mainBtn.Text = txt; selectedValue = "" end
end

local function InitMultiSelectGrid(frame, defaultText, itemsList)
	local mainBtn = frame:WaitForChild("MainBtn")
	local listFrame = frame:WaitForChild("ListFrame")

	local selectedItems = {}

	local function UpdateMainText()
		if #selectedItems == 0 then mainBtn.Text = defaultText else mainBtn.Text = table.concat(selectedItems, ", ") end
	end

	mainBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); listFrame.Visible = not listFrame.Visible end)

	for i, itemName in ipairs(itemsList) do
		if IsRestrictedPass(itemName) and player:GetAttribute("PaidItemTradingAllowed") == false then
			continue
		end

		local iData = ItemData.Consumables[itemName] or ItemData.Equipment[itemName]
		local rarity = iData and iData.Rarity or "Common"
		local sCol = itemName == "Any / Offers" and Color3.new(1,1,1) or rarityColors[rarity]

		local btn = CreateTradeItemBtn(itemName, Color3.fromRGB(30, 20, 40), sCol, 51)
		btn.LayoutOrder = i
		btn.Parent = listFrame

		btn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			if itemName == "Any / Offers" then
				selectedItems = {}
				for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(30, 20, 40) end end
				listFrame.Visible = false
			else
				local idx = table.find(selectedItems, itemName)
				if idx then
					table.remove(selectedItems, idx)
					btn.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
				elseif #selectedItems < 3 then
					table.insert(selectedItems, itemName)
					btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
				end
			end
			UpdateMainText()
		end)
	end

	task.delay(0.05, function()
		listFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#listFrame:GetChildren() / 2) * 35 + 10)
	end)

	return function() 
		if #selectedItems == 0 then return defaultText end return table.concat(selectedItems, ", ") 
	end, function()
		selectedItems = {}
		for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = Color3.fromRGB(30, 20, 40) end end
		UpdateMainText()
	end
end

local function DrawTradeItems(container, itemsTable, standData, styleData, isMyOffer)
	for _, c in pairs(container:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end

	local order = 1
	for itemName, count in pairs(itemsTable) do
		local iData = ItemData.Consumables[itemName] or ItemData.Equipment[itemName]
		local rarity = iData and iData.Rarity or "Common"

		local btn = CreateTradeItemBtn(itemName .. (count > 1 and " (x"..count..")" or ""), Color3.fromRGB(30, 20, 40), rarityColors[rarity])
		btn.LayoutOrder = order
		btn.Parent = container

		if isMyOffer then
			btn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				Network.TradeAction:FireServer("RemoveItem", itemName)
			end)
		end
		order += 1
	end

	if standData then
		local displayName = standData.Name
		local tColor = StandData.Traits[standData.Trait] and StandData.Traits[standData.Trait].Color or "#FFFFFF"
		local tStr = standData.Trait ~= "None" and " <font color='"..tColor.."'>["..standData.Trait.."]</font>" or ""

		if standData.Name == "Fused Stand" then
			displayName = FusionUtility.CalculateFusedName(standData.FusedS1, standData.FusedS2)

			local c1 = StandData.Traits[standData.FusedT1] and StandData.Traits[standData.FusedT1].Color or "#FFFFFF"
			local c2 = StandData.Traits[standData.FusedT2] and StandData.Traits[standData.FusedT2].Color or "#FFFFFF"

			if standData.FusedT1 ~= "None" and standData.FusedT2 ~= "None" then
				tStr = " <font color='"..c1.."'>["..standData.FusedT1.."]</font> & <font color='"..c2.."'>["..standData.FusedT2.."]</font>"
			elseif standData.FusedT1 ~= "None" then
				tStr = " <font color='"..c1.."'>["..standData.FusedT1.."]</font>"
			elseif standData.FusedT2 ~= "None" then
				tStr = " <font color='"..c2.."'>["..standData.FusedT2.."]</font>"
			else
				tStr = ""
			end
		end

		local btn = CreateTradeItemBtn("<b>[STAND]</b>\n" .. displayName .. tStr, Color3.fromRGB(50, 15, 60), Color3.fromRGB(200, 50, 255))
		btn.LayoutOrder = order
		btn.Parent = container

		if isMyOffer then
			btn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				Network.TradeAction:FireServer("RemoveStand")
			end)
		end
		order += 1
	end

	if styleData then
		local btn = CreateTradeItemBtn("<b>[STYLE]</b>\n" .. styleData.Name, Color3.fromRGB(80, 40, 15), Color3.fromRGB(255, 140, 0))
		btn.LayoutOrder = order
		btn.Parent = container

		if isMyOffer then
			btn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				Network.TradeAction:FireServer("RemoveStyle")
			end)
		end
	end

	local layout = container:FindFirstChildWhichIsA("UIGridLayout")
	if layout then
		local rows = math.ceil(#container:GetChildren() / 3) 
		container.CanvasSize = UDim2.new(0, 0, 0, rows * 60 + 10)
	end
end

function TradingTab.Init(parentFrame, tooltipMgr, focusFunc)
	forceTabFocus = focusFunc
	templates = ReplicatedStorage:WaitForChild("JJBITemplates")

	local lobbyContainer = parentFrame:WaitForChild("LobbyContainer")
	topCard = lobbyContainer:WaitForChild("TopCard")
	bottomCard = lobbyContainer:WaitForChild("BottomCard")
	activeTradeCard = parentFrame:WaitForChild("ActiveTradeCard")

	claimModal = parentFrame:WaitForChild("ClaimModal")
	claimContainer = claimModal:WaitForChild("ClaimContainer")
	claimTitle = claimContainer:WaitForChild("ClaimTitle")

	local claimBtnGrid = claimContainer:WaitForChild("ClaimBtnGrid")
	btnActive = claimBtnGrid:WaitForChild("BtnActive")
	btnSlot1 = claimBtnGrid:WaitForChild("BtnSlot1")
	btnSlot2 = claimBtnGrid:WaitForChild("BtnSlot2")
	btnSlot3 = claimBtnGrid:WaitForChild("BtnSlot3")
	btnSlot4 = claimBtnGrid:WaitForChild("BtnSlot4")
	btnSlot5 = claimBtnGrid:WaitForChild("BtnSlot5")

	styleClaimModal = parentFrame:WaitForChild("StyleClaimModal")
	styleClaimContainer = styleClaimModal:WaitForChild("StyleClaimContainer")
	styleClaimTitle = styleClaimContainer:WaitForChild("StyleClaimTitle")

	local styleClaimBtnGrid = styleClaimContainer:WaitForChild("StyleClaimBtnGrid")
	btnStyleActive = styleClaimBtnGrid:WaitForChild("BtnStyleActive")
	btnStyleSlot1 = styleClaimBtnGrid:WaitForChild("BtnStyleSlot1")
	btnStyleSlot2 = styleClaimBtnGrid:WaitForChild("BtnStyleSlot2")
	btnStyleSlot3 = styleClaimBtnGrid:WaitForChild("BtnStyleSlot3")

	local toggleReqsBtn = topCard:WaitForChild("ToggleReqsBtn")
	local actNav = topCard:WaitForChild("ActNav")
	local tabReqBtn = actNav:WaitForChild("TabReqBtn")
	local tabHostBtn = actNav:WaitForChild("TabHostBtn")

	reqView = topCard:WaitForChild("ReqView")
	hostView = topCard:WaitForChild("HostView")

	local reqDropdownObj = reqView:WaitForChild("ReqDropdownObj")
	local getReqVal, resetReqVal = InitDropdown(reqDropdownObj, function()
		local list = {}
		for _, p in ipairs(game.Players:GetPlayers()) do if p ~= player then table.insert(list, p.Name) end end
		return list
	end)

	local sendReqBtn = reqView:WaitForChild("SendReqBtn")

	local lfDropdownObj = hostView:WaitForChild("LfDropdownObj")
	local getLfVal, resetLfVal = InitMultiSelectGrid(lfDropdownObj, "Any / Offers", KnownItems)

	local offDropdownObj = hostView:WaitForChild("OffDropdownObj")
	local getOffVal, resetOffVal = InitMultiSelectGrid(offDropdownObj, "Any / Open", KnownItems)

	local hostBtn = hostView:WaitForChild("HostBtn")

	local browsNav = bottomCard:WaitForChild("BrowsNav")
	local tabLobbyBtn = browsNav:WaitForChild("TabLobbyBtn")
	local tabInboxBtn = browsNav:WaitForChild("TabInboxBtn")

	browserLobbyView = bottomCard:WaitForChild("BrowserLobbyView")
	browserInboxView = bottomCard:WaitForChild("BrowserInboxView")

	local topBar = activeTradeCard:WaitForChild("TopBar")
	tradeStatusLbl = topBar:WaitForChild("TradeStatusLbl")
	local cancelTradeBtn = topBar:WaitForChild("CancelTradeBtn")

	local offersFrame = activeTradeCard:WaitForChild("OffersFrame")
	local mySide = offersFrame:WaitForChild("MySide")
	local oppSide = offersFrame:WaitForChild("OppSide")

	myYenLbl = mySide:WaitForChild("MyYenLbl")
	oppYenLbl = oppSide:WaitForChild("OppYenLbl")
	myOfferGrid = mySide:WaitForChild("MyOfferGrid")
	oppOfferGrid = oppSide:WaitForChild("OppOfferGrid")

	local bottomArea = activeTradeCard:WaitForChild("BottomArea")
	local invCard = bottomArea:WaitForChild("InvCard")
	local invNav = invCard:WaitForChild("InvNav")

	local tItemsBtn = invNav:WaitForChild("TItemsBtn")
	local tStandsBtn = invNav:WaitForChild("TStandsBtn")
	local tStylesBtn = invNav:WaitForChild("TStylesBtn")

	myInvList = invCard:WaitForChild("MyInvList")
	myStandList = invCard:WaitForChild("MyStandList")
	myStyleList = invCard:WaitForChild("MyStyleList")

	local ctrlFrame = bottomArea:WaitForChild("CtrlFrame")
	addYenInput = ctrlFrame:WaitForChild("AddYenInput")
	local setYenBtn = ctrlFrame:WaitForChild("SetYenBtn")
	lockBtn = ctrlFrame:WaitForChild("LockBtn")

	tItemsBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); myInvList.Visible = true; myStandList.Visible = false; myStyleList.Visible = false; tItemsBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 100); tStandsBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50); tStylesBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50) end)
	tStandsBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); myInvList.Visible = false; myStandList.Visible = true; myStyleList.Visible = false; tItemsBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50); tStandsBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 100); tStylesBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50) end)
	tStylesBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); myInvList.Visible = false; myStandList.Visible = false; myStyleList.Visible = true; tItemsBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50); tStandsBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50); tStylesBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 100) end)

	toggleReqsBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		requestsEnabled = not requestsEnabled
		toggleReqsBtn.Text = requestsEnabled and "Requests: ON" or "Requests: OFF"
		toggleReqsBtn.BackgroundColor3 = requestsEnabled and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(140, 40, 40)
		local stroke = toggleReqsBtn:FindFirstChildOfClass("UIStroke")
		if stroke then stroke.Color = requestsEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100) end
		Network.TradeAction:FireServer("ToggleRequests", requestsEnabled)
	end)

	tabReqBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		reqView.Visible = true
		hostView.Visible = false
		tabReqBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
		tabReqBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
		tabHostBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		tabHostBtn.TextColor3 = Color3.new(1, 1, 1)
		local s1 = tabReqBtn:FindFirstChildOfClass("UIStroke"); if s1 then s1.Color = Color3.fromRGB(255, 215, 0); s1.Thickness = 2 end
		local s2 = tabHostBtn:FindFirstChildOfClass("UIStroke"); if s2 then s2.Color = Color3.fromRGB(120, 60, 180); s2.Thickness = 1 end
	end)

	tabHostBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		reqView.Visible = false
		hostView.Visible = true
		tabHostBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
		tabHostBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
		tabReqBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		tabReqBtn.TextColor3 = Color3.new(1, 1, 1)
		local s1 = tabHostBtn:FindFirstChildOfClass("UIStroke"); if s1 then s1.Color = Color3.fromRGB(255, 215, 0); s1.Thickness = 2 end
		local s2 = tabReqBtn:FindFirstChildOfClass("UIStroke"); if s2 then s2.Color = Color3.fromRGB(120, 60, 180); s2.Thickness = 1 end
	end)

	tabLobbyBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		browserLobbyView.Visible = true
		browserInboxView.Visible = false
		tabLobbyBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
		tabLobbyBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
		tabInboxBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		tabInboxBtn.TextColor3 = Color3.new(1, 1, 1)
		local s1 = tabLobbyBtn:FindFirstChildOfClass("UIStroke"); if s1 then s1.Color = Color3.fromRGB(255, 215, 0); s1.Thickness = 2 end
		local s2 = tabInboxBtn:FindFirstChildOfClass("UIStroke"); if s2 then s2.Color = Color3.fromRGB(120, 60, 180); s2.Thickness = 1 end
	end)

	tabInboxBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		browserLobbyView.Visible = false
		browserInboxView.Visible = true
		tabInboxBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
		tabInboxBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
		tabLobbyBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		tabLobbyBtn.TextColor3 = Color3.new(1, 1, 1)
		local s1 = tabInboxBtn:FindFirstChildOfClass("UIStroke"); if s1 then s1.Color = Color3.fromRGB(255, 215, 0); s1.Thickness = 2 end
		local s2 = tabLobbyBtn:FindFirstChildOfClass("UIStroke"); if s2 then s2.Color = Color3.fromRGB(120, 60, 180); s2.Thickness = 1 end
	end)

	sendReqBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local target = getReqVal()
		if target and target ~= "" and target ~= "Select a Player..." then
			Network.TradeAction:FireServer("SendRequest", target)
			resetReqVal("Select a Player...")
		else
			NotificationManager.Show("<font color='#FF5555'>Please select a player first!</font>")
		end
	end)

	hostBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		if isHosting then
			Network.TradeAction:FireServer("CancelLobby")
		else
			local lf = getLfVal()
			local off = getOffVal()
			Network.TradeAction:FireServer("CreateLobby", {LF = lf, Offering = off})
		end
	end)

	cancelTradeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("CancelTrade") end)

	setYenBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local amt = tonumber(addYenInput.Text)
		if amt and amt >= 0 then Network.TradeAction:FireServer("SetYen", math.floor(amt)) end
		addYenInput.Text = ""
	end)

	lockBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ToggleLock") end)

	btnActive.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Active") end)
	btnSlot1.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot1") end)
	btnSlot2.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot2") end)
	btnSlot3.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot3") end)
	btnSlot4.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot4") end)
	btnSlot5.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot5") end)

	btnStyleActive.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Active") end)
	btnStyleSlot1.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Slot1") end)
	btnStyleSlot2.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Slot2") end)
	btnStyleSlot3.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Slot3") end)

	local function RefreshPickers()
		for _, c in pairs(myInvList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local order = 1
		for _, itemName in ipairs(KnownItems) do
			if itemName == "Any / Offers" or itemName == "Stands" then continue end
			if IsRestrictedPass(itemName) and player:GetAttribute("PaidItemTradingAllowed") == false then
				continue
			end

			local count = player:GetAttribute(itemName:gsub("[^%w]", "") .. "Count") or 0

			local iData = ItemData.Equipment[itemName]
			local isEquipped = iData and player:GetAttribute("Equipped" .. iData.Slot) == itemName
			local visualCount = isEquipped and (count - 1) or count

			if visualCount > 0 then
				local cData = ItemData.Consumables[itemName] or ItemData.Equipment[itemName]
				local rarity = cData and cData.Rarity or "Common"
				local btn = CreateTradeItemBtn(itemName .. " (x"..visualCount..")", Color3.fromRGB(30, 20, 40), rarityColors[rarity])
				btn.LayoutOrder = order
				btn.Parent = myInvList

				btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AddItem", itemName) end)
				order += 1
			end
		end

		local layout = myInvList:FindFirstChildWhichIsA("UIGridLayout")
		if layout then
			local rows = math.ceil(#myInvList:GetChildren() / 3) 
			myInvList.CanvasSize = UDim2.new(0, 0, 0, rows * 60 + 10)
		end

		for _, c in pairs(myStandList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		order = 1
		local function AddStandBtn(slotId, attrName)
			local sName = player:GetAttribute(attrName) or "None"
			if sName ~= "None" then
				local displayName = sName
				if sName == "Fused Stand" then
					local fs1 = player:GetAttribute(slotId == "Active" and "Active_FusedStand1" or attrName.."_FusedStand1")
					local fs2 = player:GetAttribute(slotId == "Active" and "Active_FusedStand2" or attrName.."_FusedStand2")
					displayName = FusionUtility.CalculateFusedName(fs1, fs2)
				end

				local btn = CreateTradeItemBtn(displayName, Color3.fromRGB(50, 15, 60), Color3.fromRGB(200, 50, 255))
				btn.LayoutOrder = order
				btn.Parent = myStandList
				btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AddStand", slotId) end)
				order += 1
			end
		end

		AddStandBtn("Active", "Stand")
		AddStandBtn("Slot1", "StoredStand1")

		if player:GetAttribute("HasStandSlot2") then AddStandBtn("Slot2", "StoredStand2") end
		if player:GetAttribute("HasStandSlot3") then AddStandBtn("Slot3", "StoredStand3") end

		local ls = player:FindFirstChild("leaderstats")
		local prestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0
		if prestige >= 15 then AddStandBtn("Slot4", "StoredStand4") end
		if prestige >= 30 then AddStandBtn("Slot5", "StoredStand5") end

		local l2 = myStandList:FindFirstChildWhichIsA("UIGridLayout")
		if l2 then myStandList.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#myStandList:GetChildren() / 3) * 60 + 10) end

		for _, c in pairs(myStyleList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		order = 1
		local function AddStyleBtn(slotId, attrName)
			local sName = player:GetAttribute(attrName) or "None"
			if sName ~= "None" then
				local btn = CreateTradeItemBtn(sName, Color3.fromRGB(80, 40, 15), Color3.fromRGB(255, 140, 0))
				btn.LayoutOrder = order
				btn.Parent = myStyleList
				btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AddStyle", slotId) end)
				order += 1
			end
		end

		AddStyleBtn("Active", "FightingStyle")
		AddStyleBtn("Slot1", "StoredStyle1")
		if player:GetAttribute("HasStyleSlot2") then AddStyleBtn("Slot2", "StoredStyle2") end
		if player:GetAttribute("HasStyleSlot3") then AddStyleBtn("Slot3", "StoredStyle3") end

		local l3 = myStyleList:FindFirstChildWhichIsA("UIGridLayout")
		if l3 then myStyleList.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#myStyleList:GetChildren() / 3) * 60 + 10) end
	end

	Network.TradeAction:FireServer("RequestData")

	Network:WaitForChild("TradeUpdate").OnClientEvent:Connect(function(action, data)
		if action == "TradeAlert" then
			NotificationManager.Show("<font color='#55FF55'>New Trade Request from " .. data .. "!</font>")

		elseif action == "ShowClaimPrompt" then
			task.spawn(function()
				while styleClaimModal.Visible do task.wait(0.2) end

				if forceTabFocus then forceTabFocus() end 

				local displayClaimName = data.Name
				if data.Name == "Fused Stand" then
					displayClaimName = FusionUtility.CalculateFusedName(player:GetAttribute("PendingStand_FusedS1"), player:GetAttribute("PendingStand_FusedS2"))
				end

				claimTitle.Text = "You received " .. displayClaimName .. "!"

				local function FormatSlotText(title, standName)
					local safeName = standName or "None"
					if safeName == "None" or safeName == "" then return title .. "\n[Empty]" end
					return title .. "\n[" .. safeName .. "]"
				end

				btnActive.Text = FormatSlotText("Active Stand", data.Active)
				btnSlot1.Text = FormatSlotText("Storage 1", data.Slot1)
				btnSlot2.Text = FormatSlotText("Storage 2", data.Slot2)
				btnSlot3.Text = FormatSlotText("Storage 3", data.Slot3)
				btnSlot4.Text = FormatSlotText("Storage 4", data.Slot4)
				btnSlot5.Text = FormatSlotText("Storage 5", data.Slot5)

				local ls = player:FindFirstChild("leaderstats")
				local prestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0

				btnSlot2.Visible = player:GetAttribute("HasStandSlot2") == true
				btnSlot3.Visible = player:GetAttribute("HasStandSlot3") == true
				btnSlot4.Visible = prestige >= 15
				btnSlot5.Visible = prestige >= 30

				claimModal.Visible = true
			end)

		elseif action == "HideClaimPrompt" then
			claimModal.Visible = false

		elseif action == "ShowStyleClaimPrompt" then
			task.spawn(function()
				while claimModal.Visible do task.wait(0.2) end

				if forceTabFocus then forceTabFocus() end 
				styleClaimTitle.Text = "You received " .. (data.Name or "Unknown") .. "!"

				local function FormatSlotText(title, styleName)
					local safeName = styleName or "None"
					if safeName == "None" or safeName == "" then return title .. "\n[Empty]" end
					return title .. "\n[" .. safeName .. "]"
				end

				btnStyleActive.Text = FormatSlotText("Active Style", data.Active)
				btnStyleSlot1.Text = FormatSlotText("Storage 1", data.Slot1)
				btnStyleSlot2.Text = FormatSlotText("Storage 2", data.Slot2)
				btnStyleSlot3.Text = FormatSlotText("Storage 3", data.Slot3)

				btnStyleSlot2.Visible = player:GetAttribute("HasStyleSlot2") == true
				btnStyleSlot3.Visible = player:GetAttribute("HasStyleSlot3") == true

				styleClaimModal.Visible = true
			end)

		elseif action == "HideStyleClaimPrompt" then
			styleClaimModal.Visible = false

		elseif action == "LobbyStatus" then
			isHosting = data.IsHosting
			if isHosting then
				hostBtn.Text = "Cancel"; hostBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			else
				hostBtn.Text = "Host"; hostBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
			end

		elseif action == "BrowserUpdate" then
			for _, c in pairs(browserLobbyView:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			for i, lobby in ipairs(data.Lobbies) do
				local row = templates:WaitForChild("TradeLobbyRowTemplate"):Clone()
				row.Name = "Row_"..i
				row.LayoutOrder = i
				row.Parent = browserLobbyView

				local txt = row:WaitForChild("InfoLabel")
				local safeLF = lobby.LF ~= "" and lobby.LF or "Any"
				local safeOff = lobby.Offering ~= "" and lobby.Offering or "Any"
				txt.Text = "<b>" .. lobby.HostName .. "</b>\n<font color='#AAAAAA'>LF: " .. safeLF .. "\nOFF: " .. safeOff .. "</font>"

				local joinBtn = row:WaitForChild("ActionBtn")

				if lobby.HostId == player.UserId then
					joinBtn.Text = "Hosting"
					joinBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				else
					joinBtn.Text = "Join"
					joinBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
					local str = joinBtn:FindFirstChildOfClass("UIStroke")
					if str then str.Color = Color3.fromRGB(180, 80, 200) end
					joinBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("JoinLobby", lobby.HostId) end)
				end
			end

			local blLayout = browserLobbyView:FindFirstChildWhichIsA("UIListLayout")
			if blLayout then browserLobbyView.CanvasSize = UDim2.new(0, 0, 0, blLayout.AbsoluteContentSize.Y + 10) end

			for _, c in pairs(browserInboxView:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			for i, req in ipairs(data.Requests) do
				local row = templates:WaitForChild("TradeInboxRowTemplate"):Clone()
				row.Name = "ReqRow_"..i
				row.LayoutOrder = i
				row.Parent = browserInboxView

				row:WaitForChild("InfoLabel").Text = "From: <b>" .. req.SenderName .. "</b>"

				local accBtn = row:WaitForChild("AcceptBtn")
				accBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AcceptRequest", req.SenderId) end)

				local decBtn = row:WaitForChild("DeclineBtn")
				decBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("DeclineRequest", req.SenderId) end)
			end

			local biLayout = browserInboxView:FindFirstChildWhichIsA("UIListLayout")
			if biLayout then browserInboxView.CanvasSize = UDim2.new(0, 0, 0, biLayout.AbsoluteContentSize.Y + 10) end

		elseif action == "TradeStart" then
			if forceTabFocus then forceTabFocus() end 
			topCard.Visible = false; bottomCard.Visible = false; activeTradeCard.Visible = true
			tradeStatusLbl.Text = "Trading with <b>" .. data.OpponentName .. "</b>"
			RefreshPickers()

		elseif action == "TradeUpdateState" then
			myYenLbl.Text = "Yen: ¥" .. data.Me.Yen
			oppYenLbl.Text = "Yen: ¥" .. data.Opp.Yen

			DrawTradeItems(myOfferGrid, data.Me.Items, data.Me.Stand, data.Me.Style, true)
			DrawTradeItems(oppOfferGrid, data.Opp.Items, data.Opp.Stand, data.Opp.Style, false)

			if data.Me.Confirmed and data.Opp.Confirmed then
				tradeStatusLbl.Text = "<font color='#55FF55'><b>Trade Processing...</b></font>"
				lockBtn.Text = "Processing..."; lockBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			elseif data.Me.Locked and data.Opp.Locked then
				tradeStatusLbl.Text = "<font color='#FFFF55'><b>Both Locked! Ready to Confirm.</b></font>"
				lockBtn.Text = "Confirm Trade"; lockBtn.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
			elseif data.Me.Locked then
				tradeStatusLbl.Text = "<font color='#AAAAAA'>Waiting for Opponent to lock...</font>"
				lockBtn.Text = "Unlock"; lockBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
			elseif data.Opp.Locked then
				tradeStatusLbl.Text = "<font color='#FFFF55'>Opponent Locked! Lock to proceed.</font>"
				lockBtn.Text = "Lock In Trade"; lockBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
			else
				tradeStatusLbl.Text = "Trading with <b>" .. data.OpponentName .. "</b>"
				lockBtn.Text = "Lock In Trade"; lockBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
			end

		elseif action == "TradeEnd" then
			topCard.Visible = true; bottomCard.Visible = true; activeTradeCard.Visible = false
			Network.TradeAction:FireServer("RequestData")
		end
	end)

	parentFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if parentFrame.Visible and topCard.Visible then
			Network.TradeAction:FireServer("RequestData")
		end
	end)
end

return TradingTab