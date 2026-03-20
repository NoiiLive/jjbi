-- @ScriptType: ModuleScript
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

local function AddBtnStroke(btn, r, g, b, t)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(r, g, b)
	s.Thickness = t or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = btn
	return s
end

local function CreateCard(name, parent, size, pos)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	if pos then frame.Position = pos end
	frame.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	frame.ZIndex = 20
	frame.Parent = parent
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(frame, 90, 50, 120, 1)
	return frame
end

local function CreateTradeItemBtn(text, color, strokeColor, zIndex)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = color or Color3.fromRGB(30, 20, 40)
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextScaled = true
	btn.RichText = true
	btn.Text = text
	btn.ZIndex = zIndex or 22
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	Instance.new("UITextSizeConstraint", btn).MaxTextSize = 14
	if strokeColor then
		AddBtnStroke(btn, strokeColor.R*255, strokeColor.G*255, strokeColor.B*255, 1)
	end
	return btn
end

local function InitDropdown(frame, getOptionsFunc)
	local mainBtn = Instance.new("TextButton", frame)
	mainBtn.Name = "MainBtn"
	mainBtn.Size = UDim2.new(1, 0, 1, 0)
	mainBtn.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	mainBtn.Font = Enum.Font.GothamBold
	mainBtn.TextColor3 = Color3.new(1, 1, 1)
	mainBtn.TextScaled = true
	mainBtn.Text = "Select a Player..."
	mainBtn.ZIndex = 22
	Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(mainBtn, 90, 50, 120, 1)
	Instance.new("UITextSizeConstraint", mainBtn).MaxTextSize = 14

	local listFrame = Instance.new("ScrollingFrame", frame)
	listFrame.Name = "ListFrame"
	listFrame.Size = UDim2.new(1, 0, 0, 120)
	listFrame.Position = UDim2.new(0, 0, 1, 5)
	listFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	listFrame.ScrollBarThickness = 6
	listFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	listFrame.Visible = false
	listFrame.ZIndex = 50
	Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(listFrame, 255, 215, 50, 2)

	local listLayout = Instance.new("UIListLayout", listFrame)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder

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
				local btn = Instance.new("TextButton", listFrame)
				btn.Size = UDim2.new(1, -6, 0, 30)
				btn.BackgroundTransparency = (i%2==0) and 0.5 or 1
				btn.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
				btn.Font = Enum.Font.GothamMedium
				btn.TextColor3 = Color3.new(1, 1, 1)
				btn.TextSize = 14
				btn.Text = opt
				btn.ZIndex = 51

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
	local mainBtn = Instance.new("TextButton", frame)
	mainBtn.Name = "MainBtn"
	mainBtn.Size = UDim2.new(1, 0, 1, 0)
	mainBtn.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	mainBtn.Font = Enum.Font.GothamBold
	mainBtn.TextColor3 = Color3.new(1, 1, 1)
	mainBtn.TextScaled = true
	mainBtn.Text = defaultText
	mainBtn.ZIndex = 22
	Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(mainBtn, 90, 50, 120, 1)
	Instance.new("UITextSizeConstraint", mainBtn).MaxTextSize = 14

	local listFrame = Instance.new("ScrollingFrame", frame)
	listFrame.Name = "ListFrame"
	listFrame.Size = UDim2.new(1, 0, 0, 150)
	listFrame.Position = UDim2.new(0, 0, 1, 5)
	listFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	listFrame.ScrollBarThickness = 6
	listFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	listFrame.Visible = false
	listFrame.ZIndex = 50
	Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(listFrame, 255, 215, 50, 2)

	local listLayout = Instance.new("UIGridLayout", listFrame)
	listLayout.CellSize = UDim2.new(0.48, 0, 0, 30)
	listLayout.CellPadding = UDim2.new(0.02, 0, 0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local pad = Instance.new("UIPadding", listFrame)
	pad.PaddingTop = UDim.new(0, 5)
	pad.PaddingLeft = UDim.new(0, 5)

	local selectedItems = {}

	local function UpdateMainText()
		if #selectedItems == 0 then mainBtn.Text = defaultText else mainBtn.Text = table.concat(selectedItems, ", ") end
	end

	mainBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); listFrame.Visible = not listFrame.Visible end)

	for _, itemName in ipairs(itemsList) do
		local iData = ItemData.Consumables[itemName] or ItemData.Equipment[itemName]
		local rarity = iData and iData.Rarity or "Common"
		local sCol = itemName == "Any / Offers" and Color3.new(1,1,1) or rarityColors[rarity]

		local btn = CreateTradeItemBtn(itemName, Color3.fromRGB(30, 20, 40), sCol, 51)
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

	listFrame.CanvasSize = UDim2.new(0, 0, 0, math.ceil(#itemsList / 2) * 35 + 10)

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

	for itemName, count in pairs(itemsTable) do
		local iData = ItemData.Consumables[itemName] or ItemData.Equipment[itemName]
		local rarity = iData and iData.Rarity or "Common"

		local btn = CreateTradeItemBtn(itemName .. (count > 1 and " (x"..count..")" or ""), Color3.fromRGB(30, 20, 40), rarityColors[rarity])
		btn.Parent = container

		if isMyOffer then
			btn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				Network.TradeAction:FireServer("RemoveItem", itemName)
			end)
		end
	end

	if standData then
		local tColor = StandData.Traits[standData.Trait] and StandData.Traits[standData.Trait].Color or "#FFFFFF"
		local tStr = standData.Trait ~= "None" and " <font color='"..tColor.."'>["..standData.Trait.."]</font>" or ""
		local btn = CreateTradeItemBtn("<b>[STAND]</b>\n" .. standData.Name .. tStr, Color3.fromRGB(50, 15, 60), Color3.fromRGB(200, 50, 255))
		btn.Parent = container

		if isMyOffer then
			btn.MouseButton1Click:Connect(function()
				SFXManager.Play("Click")
				Network.TradeAction:FireServer("RemoveStand")
			end)
		end
	end

	if styleData then
		local btn = CreateTradeItemBtn("<b>[STYLE]</b>\n" .. styleData.Name, Color3.fromRGB(80, 40, 15), Color3.fromRGB(255, 140, 0))
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

	local lobbyContainer = Instance.new("Frame", parentFrame)
	lobbyContainer.Name = "LobbyContainer"
	lobbyContainer.Size = UDim2.new(0.96, 0, 0.96, 0)
	lobbyContainer.Position = UDim2.new(0.02, 0, 0.02, 0)
	lobbyContainer.BackgroundTransparency = 1
	lobbyContainer.Visible = true

	topCard = CreateCard("TopCard", lobbyContainer, UDim2.new(1, 0, 0.42, 0), UDim2.new(0, 0, 0, 0))
	local tcPad = Instance.new("UIPadding", topCard)
	tcPad.PaddingTop = UDim.new(0.04, 0); tcPad.PaddingBottom = UDim.new(0.04, 0)
	tcPad.PaddingLeft = UDim.new(0.04, 0); tcPad.PaddingRight = UDim.new(0.04, 0)

	local topTitle = Instance.new("TextLabel", topCard)
	topTitle.Size = UDim2.new(0.6, 0, 0.15, 0)
	topTitle.BackgroundTransparency = 1
	topTitle.Font = Enum.Font.GothamBlack
	topTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	topTitle.TextScaled = true
	topTitle.TextXAlignment = Enum.TextXAlignment.Left
	topTitle.Text = "TRADE SETTINGS & HOSTING"
	topTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", topTitle).MaxTextSize = 22

	local toggleReqsBtn = Instance.new("TextButton", topCard)
	toggleReqsBtn.Size = UDim2.new(0.3, 0, 0.15, 0)
	toggleReqsBtn.Position = UDim2.new(1, 0, 0, 0)
	toggleReqsBtn.AnchorPoint = Vector2.new(1, 0)
	toggleReqsBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	toggleReqsBtn.Font = Enum.Font.GothamBold
	toggleReqsBtn.TextColor3 = Color3.new(1, 1, 1)
	toggleReqsBtn.TextScaled = true
	toggleReqsBtn.Text = "Requests: ON"
	toggleReqsBtn.ZIndex = 22
	Instance.new("UICorner", toggleReqsBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(toggleReqsBtn, 100, 255, 100, 1)
	Instance.new("UITextSizeConstraint", toggleReqsBtn).MaxTextSize = 14

	local actNav = Instance.new("Frame", topCard)
	actNav.Size = UDim2.new(1, 0, 0.15, 0)
	actNav.Position = UDim2.new(0, 0, 0.25, 0)
	actNav.BackgroundTransparency = 1
	actNav.ZIndex = 22

	local anLayout = Instance.new("UIListLayout", actNav)
	anLayout.FillDirection = Enum.FillDirection.Horizontal
	anLayout.Padding = UDim.new(0.02, 0)

	local tabReqBtn = Instance.new("TextButton", actNav)
	tabReqBtn.Size = UDim2.new(0.49, 0, 1, 0)
	tabReqBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
	tabReqBtn.Font = Enum.Font.GothamBold
	tabReqBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
	tabReqBtn.TextScaled = true
	tabReqBtn.Text = "SEND REQUEST"
	tabReqBtn.ZIndex = 22
	Instance.new("UICorner", tabReqBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(tabReqBtn, 255, 215, 0, 2)
	Instance.new("UITextSizeConstraint", tabReqBtn).MaxTextSize = 14

	local tabHostBtn = Instance.new("TextButton", actNav)
	tabHostBtn.Size = UDim2.new(0.49, 0, 1, 0)
	tabHostBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
	tabHostBtn.Font = Enum.Font.GothamBold
	tabHostBtn.TextColor3 = Color3.new(1, 1, 1)
	tabHostBtn.TextScaled = true
	tabHostBtn.Text = "HOST TRADE"
	tabHostBtn.ZIndex = 22
	Instance.new("UICorner", tabHostBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(tabHostBtn, 120, 60, 180, 1)
	Instance.new("UITextSizeConstraint", tabHostBtn).MaxTextSize = 14

	reqView = Instance.new("Frame", topCard)
	reqView.Size = UDim2.new(1, 0, 0.5, 0)
	reqView.Position = UDim2.new(0, 0, 0.5, 0)
	reqView.BackgroundTransparency = 1
	reqView.Visible = true
	reqView.ZIndex = 21

	local reqDropdownObj = Instance.new("Frame", reqView)
	reqDropdownObj.Size = UDim2.new(0.6, 0, 0.4, 0)
	reqDropdownObj.BackgroundTransparency = 1
	local getReqVal, resetReqVal = InitDropdown(reqDropdownObj, function()
		local list = {}
		for _, p in ipairs(game.Players:GetPlayers()) do if p ~= player then table.insert(list, p.Name) end end
		return list
	end)

	local sendReqBtn = Instance.new("TextButton", reqView)
	sendReqBtn.Size = UDim2.new(0.35, 0, 0.4, 0)
	sendReqBtn.Position = UDim2.new(0.65, 0, 0, 0)
	sendReqBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
	sendReqBtn.Font = Enum.Font.GothamBold
	sendReqBtn.TextColor3 = Color3.new(1, 1, 1)
	sendReqBtn.TextScaled = true
	sendReqBtn.Text = "Send Request"
	sendReqBtn.ZIndex = 22
	Instance.new("UICorner", sendReqBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(sendReqBtn, 100, 150, 255, 1)
	Instance.new("UITextSizeConstraint", sendReqBtn).MaxTextSize = 14

	hostView = Instance.new("Frame", topCard)
	hostView.Size = UDim2.new(1, 0, 0.5, 0)
	hostView.Position = UDim2.new(0, 0, 0.5, 0)
	hostView.BackgroundTransparency = 1
	hostView.Visible = false
	hostView.ZIndex = 21

	local lblLF = Instance.new("TextLabel", hostView)
	lblLF.Size = UDim2.new(0.4, 0, 0.3, 0)
	lblLF.Position = UDim2.new(0, 0, 0, 0)
	lblLF.BackgroundTransparency = 1
	lblLF.Font = Enum.Font.GothamBold
	lblLF.TextColor3 = Color3.new(1,1,1)
	lblLF.TextScaled = true
	lblLF.TextXAlignment = Enum.TextXAlignment.Left
	lblLF.Text = "Looking For:"
	lblLF.ZIndex = 22
	Instance.new("UITextSizeConstraint", lblLF).MaxTextSize = 12

	local lfDropdownObj = Instance.new("Frame", hostView)
	lfDropdownObj.Size = UDim2.new(0.5, 0, 0.4, 0)
	lfDropdownObj.Position = UDim2.new(0, 0, 0.3, 0)
	lfDropdownObj.BackgroundTransparency = 1
	local getLfVal, resetLfVal = InitMultiSelectGrid(lfDropdownObj, "Any / Offers", KnownItems)

	local lblOff = Instance.new("TextLabel", hostView)
	lblOff.Size = UDim2.new(0.4, 0, 0.3, 0)
	lblOff.Position = UDim2.new(0.52, 0, 0, 0)
	lblOff.BackgroundTransparency = 1
	lblOff.Font = Enum.Font.GothamBold
	lblOff.TextColor3 = Color3.new(1,1,1)
	lblOff.TextScaled = true
	lblOff.TextXAlignment = Enum.TextXAlignment.Left
	lblOff.Text = "Offering:"
	lblOff.ZIndex = 22
	Instance.new("UITextSizeConstraint", lblOff).MaxTextSize = 12

	local offDropdownObj = Instance.new("Frame", hostView)
	offDropdownObj.Size = UDim2.new(0.48, 0, 0.4, 0)
	offDropdownObj.Position = UDim2.new(0.52, 0, 0.3, 0)
	offDropdownObj.BackgroundTransparency = 1
	local getOffVal, resetOffVal = InitMultiSelectGrid(offDropdownObj, "Any / Open", KnownItems)

	local hostBtn = Instance.new("TextButton", hostView)
	hostBtn.Size = UDim2.new(0.2, 0, 0.5, 0)
	hostBtn.Position = UDim2.new(1, 0, 0, 0)
	hostBtn.AnchorPoint = Vector2.new(1, 0)
	hostBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
	hostBtn.Font = Enum.Font.GothamBold
	hostBtn.TextColor3 = Color3.new(1, 1, 1)
	hostBtn.TextScaled = true
	hostBtn.Text = "Host"
	hostBtn.ZIndex = 22
	Instance.new("UICorner", hostBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(hostBtn, 255, 100, 100, 1)
	Instance.new("UITextSizeConstraint", hostBtn).MaxTextSize = 14

	bottomCard = CreateCard("BottomCard", lobbyContainer, UDim2.new(1, 0, 0.55, 0), UDim2.new(0, 0, 0.45, 0))
	local bcPad = Instance.new("UIPadding", bottomCard)
	bcPad.PaddingTop = UDim.new(0.04, 0); bcPad.PaddingBottom = UDim.new(0.04, 0)
	bcPad.PaddingLeft = UDim.new(0.04, 0); bcPad.PaddingRight = UDim.new(0.04, 0)

	local botTitle = Instance.new("TextLabel", bottomCard)
	botTitle.Size = UDim2.new(0.6, 0, 0.12, 0)
	botTitle.BackgroundTransparency = 1
	botTitle.Font = Enum.Font.GothamBlack
	botTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	botTitle.TextScaled = true
	botTitle.TextXAlignment = Enum.TextXAlignment.Left
	botTitle.Text = "TRADE BROWSER"
	botTitle.ZIndex = 22
	Instance.new("UITextSizeConstraint", botTitle).MaxTextSize = 22

	local browsNav = Instance.new("Frame", bottomCard)
	browsNav.Size = UDim2.new(1, 0, 0.12, 0)
	browsNav.Position = UDim2.new(0, 0, 0.15, 0)
	browsNav.BackgroundTransparency = 1
	browsNav.ZIndex = 22

	local bnLayout = Instance.new("UIListLayout", browsNav)
	bnLayout.FillDirection = Enum.FillDirection.Horizontal
	bnLayout.Padding = UDim.new(0.02, 0)

	local tabLobbyBtn = Instance.new("TextButton", browsNav)
	tabLobbyBtn.Size = UDim2.new(0.49, 0, 1, 0)
	tabLobbyBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
	tabLobbyBtn.Font = Enum.Font.GothamBold
	tabLobbyBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
	tabLobbyBtn.TextScaled = true
	tabLobbyBtn.Text = "OPEN LOBBIES"
	tabLobbyBtn.ZIndex = 22
	Instance.new("UICorner", tabLobbyBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(tabLobbyBtn, 255, 215, 0, 2)
	Instance.new("UITextSizeConstraint", tabLobbyBtn).MaxTextSize = 14

	local tabInboxBtn = Instance.new("TextButton", browsNav)
	tabInboxBtn.Size = UDim2.new(0.49, 0, 1, 0)
	tabInboxBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
	tabInboxBtn.Font = Enum.Font.GothamBold
	tabInboxBtn.TextColor3 = Color3.new(1, 1, 1)
	tabInboxBtn.TextScaled = true
	tabInboxBtn.Text = "INBOX"
	tabInboxBtn.ZIndex = 22
	Instance.new("UICorner", tabInboxBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(tabInboxBtn, 120, 60, 180, 1)
	Instance.new("UITextSizeConstraint", tabInboxBtn).MaxTextSize = 14

	browserLobbyView = Instance.new("ScrollingFrame", bottomCard)
	browserLobbyView.Size = UDim2.new(1, 0, 0.7, 0)
	browserLobbyView.Position = UDim2.new(0, 0, 0.3, 0)
	browserLobbyView.BackgroundTransparency = 1
	browserLobbyView.ScrollBarThickness = 6
	browserLobbyView.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	browserLobbyView.Visible = true
	browserLobbyView.ZIndex = 21

	local blvLayout = Instance.new("UIListLayout", browserLobbyView)
	blvLayout.SortOrder = Enum.SortOrder.LayoutOrder
	blvLayout.Padding = UDim.new(0, 10)
	local blvPad = Instance.new("UIPadding", browserLobbyView)
	blvPad.PaddingTop = UDim.new(0, 5); blvPad.PaddingLeft = UDim.new(0, 5); blvPad.PaddingRight = UDim.new(0, 10)

	browserInboxView = Instance.new("ScrollingFrame", bottomCard)
	browserInboxView.Size = UDim2.new(1, 0, 0.7, 0)
	browserInboxView.Position = UDim2.new(0, 0, 0.3, 0)
	browserInboxView.BackgroundTransparency = 1
	browserInboxView.ScrollBarThickness = 6
	browserInboxView.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	browserInboxView.Visible = false
	browserInboxView.ZIndex = 21

	local bivLayout = Instance.new("UIListLayout", browserInboxView)
	bivLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bivLayout.Padding = UDim.new(0, 10)
	local bivPad = Instance.new("UIPadding", browserInboxView)
	bivPad.PaddingTop = UDim.new(0, 5); bivPad.PaddingLeft = UDim.new(0, 5); bivPad.PaddingRight = UDim.new(0, 10)

	-- ==========================================================
	-- LOBBY NAVIGATION BUTTON CONNECTIONS
	-- ==========================================================
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


	-- ==========================================================
	-- ACTIVE TRADE CARD
	-- ==========================================================
	activeTradeCard = CreateCard("ActiveTradeCard", parentFrame, UDim2.new(0.96, 0, 0.96, 0), UDim2.new(0.02, 0, 0.02, 0))
	activeTradeCard.Visible = false
	local atcPad = Instance.new("UIPadding", activeTradeCard)
	atcPad.PaddingTop = UDim.new(0.02, 0); atcPad.PaddingBottom = UDim.new(0.02, 0)
	atcPad.PaddingLeft = UDim.new(0.02, 0); atcPad.PaddingRight = UDim.new(0.02, 0)

	local topBar = Instance.new("Frame", activeTradeCard)
	topBar.Size = UDim2.new(1, 0, 0.08, 0)
	topBar.BackgroundTransparency = 1
	topBar.ZIndex = 22

	tradeStatusLbl = Instance.new("TextLabel", topBar)
	tradeStatusLbl.Size = UDim2.new(0.7, 0, 1, 0)
	tradeStatusLbl.BackgroundTransparency = 1
	tradeStatusLbl.Font = Enum.Font.GothamBlack
	tradeStatusLbl.TextColor3 = Color3.fromRGB(255, 215, 50)
	tradeStatusLbl.TextScaled = true
	tradeStatusLbl.RichText = true
	tradeStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
	tradeStatusLbl.Text = "Trading..."
	tradeStatusLbl.ZIndex = 22
	Instance.new("UITextSizeConstraint", tradeStatusLbl).MaxTextSize = 22

	local cancelTradeBtn = Instance.new("TextButton", topBar)
	cancelTradeBtn.Size = UDim2.new(0.2, 0, 0.8, 0)
	cancelTradeBtn.Position = UDim2.new(1, 0, 0.1, 0)
	cancelTradeBtn.AnchorPoint = Vector2.new(1, 0)
	cancelTradeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	cancelTradeBtn.Font = Enum.Font.GothamBold
	cancelTradeBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelTradeBtn.TextScaled = true
	cancelTradeBtn.Text = "Cancel Trade"
	cancelTradeBtn.ZIndex = 22
	Instance.new("UICorner", cancelTradeBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(cancelTradeBtn, 255, 100, 100, 1)
	Instance.new("UITextSizeConstraint", cancelTradeBtn).MaxTextSize = 14

	local offersFrame = Instance.new("Frame", activeTradeCard)
	offersFrame.Size = UDim2.new(1, 0, 0.45, 0)
	offersFrame.Position = UDim2.new(0, 0, 0.1, 0)
	offersFrame.BackgroundTransparency = 1
	offersFrame.ZIndex = 21

	local function BuildOfferSide(name, pos)
		local side = CreateCard(name, offersFrame, UDim2.new(0.49, 0, 1, 0), pos)
		local sPad = Instance.new("UIPadding", side)
		sPad.PaddingTop = UDim.new(0.04, 0); sPad.PaddingBottom = UDim.new(0.04, 0)
		sPad.PaddingLeft = UDim.new(0.04, 0); sPad.PaddingRight = UDim.new(0.04, 0)

		local tLbl = Instance.new("TextLabel", side)
		tLbl.Size = UDim2.new(0.5, 0, 0.15, 0)
		tLbl.BackgroundTransparency = 1
		tLbl.Font = Enum.Font.GothamBlack
		tLbl.TextColor3 = Color3.new(1,1,1)
		tLbl.TextScaled = true
		tLbl.TextXAlignment = Enum.TextXAlignment.Left
		tLbl.Text = name == "MySide" and "My Offer" or "Their Offer"
		tLbl.ZIndex = 22
		Instance.new("UITextSizeConstraint", tLbl).MaxTextSize = 16

		local yLbl = Instance.new("TextLabel", side)
		yLbl.Name = name == "MySide" and "MyYenLbl" or "OppYenLbl"
		yLbl.Size = UDim2.new(0.5, 0, 0.15, 0)
		yLbl.Position = UDim2.new(0.5, 0, 0, 0)
		yLbl.BackgroundTransparency = 1
		yLbl.Font = Enum.Font.GothamBold
		yLbl.TextColor3 = Color3.fromRGB(85, 255, 85)
		yLbl.TextScaled = true
		yLbl.TextXAlignment = Enum.TextXAlignment.Right
		yLbl.Text = "Yen: ¥0"
		yLbl.ZIndex = 22
		Instance.new("UITextSizeConstraint", yLbl).MaxTextSize = 14

		local grid = Instance.new("ScrollingFrame", side)
		grid.Name = name == "MySide" and "MyOfferGrid" or "OppOfferGrid"
		grid.Size = UDim2.new(1, 0, 0.8, 0)
		grid.Position = UDim2.new(0, 0, 0.2, 0)
		grid.BackgroundTransparency = 1
		grid.ScrollBarThickness = 6
		grid.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
		grid.ZIndex = 22

		local gLayout = Instance.new("UIGridLayout", grid)
		gLayout.CellSize = UDim2.new(0.31, 0, 0, 50)
		gLayout.CellPadding = UDim2.new(0.03, 0, 0, 10)
		gLayout.SortOrder = Enum.SortOrder.LayoutOrder

		local gPad = Instance.new("UIPadding", grid)
		gPad.PaddingRight = UDim.new(0, 8)

		return side
	end

	local mySide = BuildOfferSide("MySide", UDim2.new(0, 0, 0, 0))
	local oppSide = BuildOfferSide("OppSide", UDim2.new(0.51, 0, 0, 0))

	myYenLbl = mySide.MyYenLbl
	oppYenLbl = oppSide.OppYenLbl
	myOfferGrid = mySide.MyOfferGrid
	oppOfferGrid = oppSide.OppOfferGrid

	local bottomArea = Instance.new("Frame", activeTradeCard)
	bottomArea.Size = UDim2.new(1, 0, 0.42, 0)
	bottomArea.Position = UDim2.new(0, 0, 0.58, 0)
	bottomArea.BackgroundTransparency = 1
	bottomArea.ZIndex = 21

	local invCard = CreateCard("InvCard", bottomArea, UDim2.new(0.68, 0, 1, 0), UDim2.new(0, 0, 0, 0))
	local iPad = Instance.new("UIPadding", invCard)
	iPad.PaddingTop = UDim.new(0.04, 0); iPad.PaddingBottom = UDim.new(0.04, 0)
	iPad.PaddingLeft = UDim.new(0.04, 0); iPad.PaddingRight = UDim.new(0.04, 0)

	local invNav = Instance.new("Frame", invCard)
	invNav.Size = UDim2.new(1, 0, 0.15, 0)
	invNav.BackgroundTransparency = 1
	invNav.ZIndex = 22

	local inLayout = Instance.new("UIListLayout", invNav)
	inLayout.FillDirection = Enum.FillDirection.Horizontal
	inLayout.Padding = UDim.new(0.02, 0)

	local function CreateInvTabBtn(txt, color)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.32, 0, 1, 0)
		b.BackgroundColor3 = color
		b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextScaled = true
		b.Text = txt
		b.ZIndex = 22
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 14
		return b
	end

	local tItemsBtn = CreateInvTabBtn("ITEMS", Color3.fromRGB(70, 30, 100))
	tItemsBtn.Parent = invNav
	local tStandsBtn = CreateInvTabBtn("STANDS", Color3.fromRGB(30, 20, 50))
	tStandsBtn.Parent = invNav
	local tStylesBtn = CreateInvTabBtn("STYLES", Color3.fromRGB(30, 20, 50))
	tStylesBtn.Parent = invNav

	myInvList = Instance.new("ScrollingFrame", invCard)
	myInvList.Size = UDim2.new(1, 0, 0.8, 0); myInvList.Position = UDim2.new(0, 0, 0.2, 0)
	myInvList.BackgroundTransparency = 1; myInvList.ScrollBarThickness = 6; myInvList.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	myInvList.Visible = true; myInvList.ZIndex = 22
	local milLayout = Instance.new("UIGridLayout", myInvList)
	milLayout.CellSize = UDim2.new(0.31, 0, 0, 50); milLayout.CellPadding = UDim2.new(0.03, 0, 0, 10)
	Instance.new("UIPadding", myInvList).PaddingRight = UDim.new(0, 8)

	myStandList = Instance.new("ScrollingFrame", invCard)
	myStandList.Size = UDim2.new(1, 0, 0.8, 0); myStandList.Position = UDim2.new(0, 0, 0.2, 0)
	myStandList.BackgroundTransparency = 1; myStandList.ScrollBarThickness = 6; myStandList.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	myStandList.Visible = false; myStandList.ZIndex = 22
	local mslLayout = Instance.new("UIGridLayout", myStandList)
	mslLayout.CellSize = UDim2.new(0.31, 0, 0, 50); mslLayout.CellPadding = UDim2.new(0.03, 0, 0, 10)
	Instance.new("UIPadding", myStandList).PaddingRight = UDim.new(0, 8)

	myStyleList = Instance.new("ScrollingFrame", invCard)
	myStyleList.Size = UDim2.new(1, 0, 0.8, 0); myStyleList.Position = UDim2.new(0, 0, 0.2, 0)
	myStyleList.BackgroundTransparency = 1; myStyleList.ScrollBarThickness = 6; myStyleList.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	myStyleList.Visible = false; myStyleList.ZIndex = 22
	local mstLayout = Instance.new("UIGridLayout", myStyleList)
	mstLayout.CellSize = UDim2.new(0.31, 0, 0, 50); mstLayout.CellPadding = UDim2.new(0.03, 0, 0, 10)
	Instance.new("UIPadding", myStyleList).PaddingRight = UDim.new(0, 8)

	tItemsBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); myInvList.Visible = true; myStandList.Visible = false; myStyleList.Visible = false; tItemsBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 100); tStandsBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50); tStylesBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50) end)
	tStandsBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); myInvList.Visible = false; myStandList.Visible = true; myStyleList.Visible = false; tItemsBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50); tStandsBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 100); tStylesBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50) end)
	tStylesBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); myInvList.Visible = false; myStandList.Visible = false; myStyleList.Visible = true; tItemsBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50); tStandsBtn.BackgroundColor3 = Color3.fromRGB(30, 20, 50); tStylesBtn.BackgroundColor3 = Color3.fromRGB(70, 30, 100) end)

	local ctrlFrame = CreateCard("CtrlFrame", bottomArea, UDim2.new(0.3, 0, 1, 0), UDim2.new(0.7, 0, 0, 0))
	local cPad = Instance.new("UIPadding", ctrlFrame)
	cPad.PaddingTop = UDim.new(0.04, 0); cPad.PaddingBottom = UDim.new(0.04, 0)
	cPad.PaddingLeft = UDim.new(0.04, 0); cPad.PaddingRight = UDim.new(0.04, 0)

	local cLayout = Instance.new("UIListLayout", ctrlFrame)
	cLayout.SortOrder = Enum.SortOrder.LayoutOrder; cLayout.Padding = UDim.new(0.05, 0)
	cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; cLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	addYenInput = Instance.new("TextBox", ctrlFrame)
	addYenInput.Size = UDim2.new(0.9, 0, 0.25, 0)
	addYenInput.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	addYenInput.Font = Enum.Font.GothamBold
	addYenInput.TextColor3 = Color3.fromRGB(85, 255, 85)
	addYenInput.TextScaled = true
	addYenInput.PlaceholderText = "Add Yen..."
	addYenInput.Text = ""
	addYenInput.ZIndex = 22; addYenInput.LayoutOrder = 1
	Instance.new("UICorner", addYenInput).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(addYenInput, 50, 150, 50, 1)
	Instance.new("UITextSizeConstraint", addYenInput).MaxTextSize = 16

	local setYenBtn = Instance.new("TextButton", ctrlFrame)
	setYenBtn.Size = UDim2.new(0.9, 0, 0.25, 0)
	setYenBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 180)
	setYenBtn.Font = Enum.Font.GothamBold
	setYenBtn.TextColor3 = Color3.new(1, 1, 1)
	setYenBtn.TextScaled = true
	setYenBtn.Text = "Set Yen"
	setYenBtn.ZIndex = 22; setYenBtn.LayoutOrder = 2
	Instance.new("UICorner", setYenBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(setYenBtn, 100, 150, 255, 1)
	Instance.new("UITextSizeConstraint", setYenBtn).MaxTextSize = 16

	lockBtn = Instance.new("TextButton", ctrlFrame)
	lockBtn.Size = UDim2.new(0.9, 0, 0.35, 0)
	lockBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)
	lockBtn.Font = Enum.Font.GothamBold
	lockBtn.TextColor3 = Color3.new(1, 1, 1)
	lockBtn.TextScaled = true
	lockBtn.Text = "Lock In Trade"
	lockBtn.ZIndex = 22; lockBtn.LayoutOrder = 3
	Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(lockBtn, 255, 180, 50, 1)
	Instance.new("UITextSizeConstraint", lockBtn).MaxTextSize = 16

	cancelTradeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("CancelTrade") end)

	setYenBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local amt = tonumber(addYenInput.Text)
		if amt and amt >= 0 then Network.TradeAction:FireServer("SetYen", math.floor(amt)) end
		addYenInput.Text = ""
	end)

	lockBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ToggleLock") end)

	-- ==========================================================
	-- CLAIM MODALS
	-- ==========================================================
	claimModal = Instance.new("Frame", parentFrame)
	claimModal.Name = "ClaimModal"
	claimModal.Size = UDim2.new(1, 0, 1, 0)
	claimModal.BackgroundColor3 = Color3.new(0, 0, 0)
	claimModal.BackgroundTransparency = 0.5
	claimModal.Visible = false
	claimModal.ZIndex = 100

	claimContainer = CreateCard("ClaimContainer", claimModal, UDim2.new(0.6, 0, 0.6, 0), UDim2.new(0.2, 0, 0.2, 0))
	claimContainer.ZIndex = 101

	claimTitle = Instance.new("TextLabel", claimContainer)
	claimTitle.Size = UDim2.new(1, 0, 0.15, 0)
	claimTitle.BackgroundTransparency = 1
	claimTitle.Font = Enum.Font.GothamBlack
	claimTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	claimTitle.TextScaled = true
	claimTitle.Text = "You received a Stand!"
	claimTitle.ZIndex = 102
	Instance.new("UITextSizeConstraint", claimTitle).MaxTextSize = 24

	local claimSubtitle = Instance.new("TextLabel", claimContainer)
	claimSubtitle.Size = UDim2.new(1, 0, 0.1, 0)
	claimSubtitle.Position = UDim2.new(0, 0, 0.15, 0)
	claimSubtitle.BackgroundTransparency = 1
	claimSubtitle.Font = Enum.Font.GothamMedium
	claimSubtitle.TextColor3 = Color3.new(1,1,1)
	claimSubtitle.TextScaled = true
	claimSubtitle.Text = "Select a slot to store it:"
	claimSubtitle.ZIndex = 102
	Instance.new("UITextSizeConstraint", claimSubtitle).MaxTextSize = 16

	local claimBtnGrid = Instance.new("Frame", claimContainer)
	claimBtnGrid.Size = UDim2.new(1, -20, 0.7, 0)
	claimBtnGrid.Position = UDim2.new(0, 10, 0.28, 0)
	claimBtnGrid.BackgroundTransparency = 1
	claimBtnGrid.ZIndex = 102

	local cgLayout = Instance.new("UIGridLayout", claimBtnGrid)
	cgLayout.CellSize = UDim2.new(0.31, 0, 0, 60)
	cgLayout.CellPadding = UDim2.new(0.03, 0, 0, 10)
	cgLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local function CreateClaimBtn(name, order)
		local b = Instance.new("TextButton")
		b.Name = name
		b.BackgroundColor3 = Color3.fromRGB(50, 15, 60)
		b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextScaled = true
		b.RichText = true
		b.ZIndex = 103
		b.LayoutOrder = order
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		AddBtnStroke(b, 200, 50, 255, 2)
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 14
		return b
	end

	btnActive = CreateClaimBtn("BtnActive", 1); btnActive.Parent = claimBtnGrid
	btnSlot1 = CreateClaimBtn("BtnSlot1", 2); btnSlot1.Parent = claimBtnGrid
	btnSlot2 = CreateClaimBtn("BtnSlot2", 3); btnSlot2.Parent = claimBtnGrid
	btnSlot3 = CreateClaimBtn("BtnSlot3", 4); btnSlot3.Parent = claimBtnGrid
	btnSlot4 = CreateClaimBtn("BtnSlot4", 5); btnSlot4.Parent = claimBtnGrid
	btnSlot5 = CreateClaimBtn("BtnSlot5", 6); btnSlot5.Parent = claimBtnGrid

	btnActive.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Active") end)
	btnSlot1.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot1") end)
	btnSlot2.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot2") end)
	btnSlot3.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot3") end)
	btnSlot4.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot4") end)
	btnSlot5.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStand", "Slot5") end)

	styleClaimModal = Instance.new("Frame", parentFrame)
	styleClaimModal.Name = "StyleClaimModal"
	styleClaimModal.Size = UDim2.new(1, 0, 1, 0)
	styleClaimModal.BackgroundColor3 = Color3.new(0, 0, 0)
	styleClaimModal.BackgroundTransparency = 0.5
	styleClaimModal.Visible = false
	styleClaimModal.ZIndex = 100

	styleClaimContainer = CreateCard("StyleClaimContainer", styleClaimModal, UDim2.new(0.6, 0, 0.6, 0), UDim2.new(0.2, 0, 0.2, 0))
	styleClaimContainer.ZIndex = 101

	styleClaimTitle = Instance.new("TextLabel", styleClaimContainer)
	styleClaimTitle.Size = UDim2.new(1, 0, 0.15, 0)
	styleClaimTitle.BackgroundTransparency = 1
	styleClaimTitle.Font = Enum.Font.GothamBlack
	styleClaimTitle.TextColor3 = Color3.fromRGB(255, 140, 0)
	styleClaimTitle.TextScaled = true
	styleClaimTitle.Text = "You received a Style!"
	styleClaimTitle.ZIndex = 102
	Instance.new("UITextSizeConstraint", styleClaimTitle).MaxTextSize = 24

	local scSubtitle = Instance.new("TextLabel", styleClaimContainer)
	scSubtitle.Size = UDim2.new(1, 0, 0.1, 0)
	scSubtitle.Position = UDim2.new(0, 0, 0.15, 0)
	scSubtitle.BackgroundTransparency = 1
	scSubtitle.Font = Enum.Font.GothamMedium
	scSubtitle.TextColor3 = Color3.new(1,1,1)
	scSubtitle.TextScaled = true
	scSubtitle.Text = "Select a slot to store it:"
	scSubtitle.ZIndex = 102
	Instance.new("UITextSizeConstraint", scSubtitle).MaxTextSize = 16

	local styleClaimBtnGrid = Instance.new("Frame", styleClaimContainer)
	styleClaimBtnGrid.Size = UDim2.new(1, -20, 0.7, 0)
	styleClaimBtnGrid.Position = UDim2.new(0, 10, 0.28, 0)
	styleClaimBtnGrid.BackgroundTransparency = 1
	styleClaimBtnGrid.ZIndex = 102

	local scgLayout = Instance.new("UIGridLayout", styleClaimBtnGrid)
	scgLayout.CellSize = UDim2.new(0.48, 0, 0, 60)
	scgLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
	scgLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local function CreateStyleClaimBtn(name, order)
		local b = Instance.new("TextButton")
		b.Name = name
		b.BackgroundColor3 = Color3.fromRGB(80, 40, 15)
		b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextScaled = true
		b.RichText = true
		b.ZIndex = 103
		b.LayoutOrder = order
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		AddBtnStroke(b, 255, 140, 0, 2)
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 14
		return b
	end

	btnStyleActive = CreateStyleClaimBtn("BtnStyleActive", 1); btnStyleActive.Parent = styleClaimBtnGrid
	btnStyleSlot1 = CreateStyleClaimBtn("BtnStyleSlot1", 2); btnStyleSlot1.Parent = styleClaimBtnGrid
	btnStyleSlot2 = CreateStyleClaimBtn("BtnStyleSlot2", 3); btnStyleSlot2.Parent = styleClaimBtnGrid
	btnStyleSlot3 = CreateStyleClaimBtn("BtnStyleSlot3", 4); btnStyleSlot3.Parent = styleClaimBtnGrid

	btnStyleActive.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Active") end)
	btnStyleSlot1.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Slot1") end)
	btnStyleSlot2.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Slot2") end)
	btnStyleSlot3.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("ClaimStyle", "Slot3") end)

	local function RefreshPickers()
		for _, c in pairs(myInvList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for _, itemName in ipairs(KnownItems) do
			if itemName == "Any / Offers" or itemName == "Stands" then continue end
			local count = player:GetAttribute(itemName:gsub("[^%w]", "") .. "Count") or 0

			local iData = ItemData.Equipment[itemName]
			local isEquipped = iData and player:GetAttribute("Equipped" .. iData.Slot) == itemName
			local visualCount = isEquipped and (count - 1) or count

			if visualCount > 0 then
				local cData = ItemData.Consumables[itemName] or ItemData.Equipment[itemName]
				local rarity = cData and cData.Rarity or "Common"
				local btn = CreateTradeItemBtn(itemName .. " (x"..visualCount..")", Color3.fromRGB(30, 20, 40), rarityColors[rarity])
				btn.Parent = myInvList

				btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AddItem", itemName) end)
			end
		end

		local layout = myInvList:FindFirstChildWhichIsA("UIGridLayout")
		if layout then
			local rows = math.ceil(#myInvList:GetChildren() / 3) 
			myInvList.CanvasSize = UDim2.new(0, 0, 0, rows * 60 + 10)
		end

		for _, c in pairs(myStandList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local function AddStandBtn(slotId, attrName)
			local sName = player:GetAttribute(attrName) or "None"
			if sName ~= "None" then
				local btn = CreateTradeItemBtn(sName, Color3.fromRGB(50, 15, 60), Color3.fromRGB(200, 50, 255))
				btn.Parent = myStandList
				btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AddStand", slotId) end)
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
		local function AddStyleBtn(slotId, attrName)
			local sName = player:GetAttribute(attrName) or "None"
			if sName ~= "None" then
				local btn = CreateTradeItemBtn(sName, Color3.fromRGB(80, 40, 15), Color3.fromRGB(255, 140, 0))
				btn.Parent = myStyleList
				btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AddStyle", slotId) end)
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
			if forceTabFocus then forceTabFocus() end 
			claimTitle.Text = "You received " .. (data.Name or "Unknown") .. "!"

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

		elseif action == "HideClaimPrompt" then
			claimModal.Visible = false

		elseif action == "ShowStyleClaimPrompt" then
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
				local row = CreateCard("Row_"..i, browserLobbyView, UDim2.new(1, -8, 0, 60))
				row.LayoutOrder = i
				local rPad = Instance.new("UIPadding", row)
				rPad.PaddingLeft = UDim.new(0, 10); rPad.PaddingRight = UDim.new(0, 10)

				local txt = Instance.new("TextLabel", row)
				txt.Size = UDim2.new(0.65, 0, 1, 0)
				txt.BackgroundTransparency = 1
				txt.Font = Enum.Font.GothamMedium
				txt.TextColor3 = Color3.new(1, 1, 1)
				txt.TextScaled = true
				txt.RichText = true
				txt.TextXAlignment = Enum.TextXAlignment.Left
				local safeLF = lobby.LF ~= "" and lobby.LF or "Any"
				local safeOff = lobby.Offering ~= "" and lobby.Offering or "Any"
				txt.Text = "<b>" .. lobby.HostName .. "</b>\n<font color='#AAAAAA'>LF: " .. safeLF .. "\nOFF: " .. safeOff .. "</font>"
				txt.ZIndex = 22
				Instance.new("UITextSizeConstraint", txt).MaxTextSize = 14

				local joinBtn = Instance.new("TextButton", row)
				joinBtn.Size = UDim2.new(0.25, 0, 0.7, 0)
				joinBtn.Position = UDim2.new(1, 0, 0.5, 0)
				joinBtn.AnchorPoint = Vector2.new(1, 0.5)
				joinBtn.Font = Enum.Font.GothamBold
				joinBtn.TextColor3 = Color3.new(1, 1, 1)
				joinBtn.TextScaled = true
				joinBtn.ZIndex = 22
				Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)
				Instance.new("UITextSizeConstraint", joinBtn).MaxTextSize = 14

				if lobby.HostId == player.UserId then
					joinBtn.Text = "Hosting"
					joinBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				else
					joinBtn.Text = "Join"
					joinBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
					AddBtnStroke(joinBtn, 180, 80, 200, 1)
					joinBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("JoinLobby", lobby.HostId) end)
				end
			end

			local blLayout = browserLobbyView:FindFirstChildWhichIsA("UIListLayout")
			if blLayout then browserLobbyView.CanvasSize = UDim2.new(0, 0, 0, blLayout.AbsoluteContentSize.Y + 10) end

			for _, c in pairs(browserInboxView:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end

			for i, req in ipairs(data.Requests) do
				local row = CreateCard("ReqRow_"..i, browserInboxView, UDim2.new(1, -8, 0, 60))
				row.LayoutOrder = i
				local rPad = Instance.new("UIPadding", row)
				rPad.PaddingLeft = UDim.new(0, 10); rPad.PaddingRight = UDim.new(0, 10)

				local txt = Instance.new("TextLabel", row)
				txt.Size = UDim2.new(0.5, 0, 1, 0)
				txt.BackgroundTransparency = 1
				txt.Font = Enum.Font.GothamMedium
				txt.TextColor3 = Color3.new(1, 1, 1)
				txt.TextScaled = true
				txt.RichText = true
				txt.TextXAlignment = Enum.TextXAlignment.Left
				txt.Text = "From: <b>" .. req.SenderName .. "</b>"
				txt.ZIndex = 22
				Instance.new("UITextSizeConstraint", txt).MaxTextSize = 16

				local accBtn = Instance.new("TextButton", row)
				accBtn.Size = UDim2.new(0.22, 0, 0.7, 0)
				accBtn.Position = UDim2.new(0.75, -5, 0.5, 0)
				accBtn.AnchorPoint = Vector2.new(1, 0.5)
				accBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
				accBtn.Font = Enum.Font.GothamBold
				accBtn.TextColor3 = Color3.new(1, 1, 1)
				accBtn.TextScaled = true
				accBtn.Text = "Accept"
				accBtn.ZIndex = 22
				Instance.new("UICorner", accBtn).CornerRadius = UDim.new(0, 6)
				AddBtnStroke(accBtn, 80, 180, 80, 1)
				Instance.new("UITextSizeConstraint", accBtn).MaxTextSize = 14
				accBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); Network.TradeAction:FireServer("AcceptRequest", req.SenderId) end)

				local decBtn = Instance.new("TextButton", row)
				decBtn.Size = UDim2.new(0.22, 0, 0.7, 0)
				decBtn.Position = UDim2.new(1, 0, 0.5, 0)
				decBtn.AnchorPoint = Vector2.new(1, 0.5)
				decBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
				decBtn.Font = Enum.Font.GothamBold
				decBtn.TextColor3 = Color3.new(1, 1, 1)
				decBtn.TextScaled = true
				decBtn.Text = "Decline"
				decBtn.ZIndex = 22
				Instance.new("UICorner", decBtn).CornerRadius = UDim.new(0, 6)
				AddBtnStroke(decBtn, 200, 80, 80, 1)
				Instance.new("UITextSizeConstraint", decBtn).MaxTextSize = 14
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