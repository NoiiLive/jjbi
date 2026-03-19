-- @ScriptType: ModuleScript
local GiftManager = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))

local standClaimModal, styleClaimModal
local btnScActive, btnScSlot1, btnScSlot2, btnScSlot3, btnScSlot4, btnScSlot5, btnScDeny
local btnStyleActive, btnStyleSlot1, btnStyleSlot2, btnStyleSlot3, btnStyleDeny
local scTitle, styleTitle
local standScroll, styleScroll, standLL, styleLL

local giftModal, giftContainer, giftTitle, giftList

local promptQueue = {}
local isPromptShowing = false

local function applyDoubleGoldBorder(parent)
	local parentCorner = parent:FindFirstChildOfClass("UICorner")

	local outerStroke = Instance.new("UIStroke")
	outerStroke.Thickness = 3
	outerStroke.Color = Color3.fromRGB(255, 210, 60)
	outerStroke.LineJoinMode = Enum.LineJoinMode.Round
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradOut = Instance.new("UIGradient")
	gradOut.Rotation = -45
	gradOut.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 160, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 160, 30))
	}
	gradOut.Parent = outerStroke
	outerStroke.Parent = parent

	local innerFrame = Instance.new("Frame")
	innerFrame.Name = "InnerGoldBorder"
	innerFrame.Size = UDim2.new(1, -6, 1, -6)
	innerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	innerFrame.BackgroundTransparency = 1
	innerFrame.ZIndex = parent.ZIndex

	if parentCorner then
		local innerCorner = Instance.new("UICorner")
		if parentCorner.CornerRadius.Scale > 0 then
			innerCorner.CornerRadius = parentCorner.CornerRadius
		else
			local offset = math.max(0, parentCorner.CornerRadius.Offset - 3)
			innerCorner.CornerRadius = UDim.new(0, offset)
		end
		innerCorner.Parent = innerFrame
	end
	innerFrame.Parent = parent

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Thickness = 1
	innerStroke.Color = Color3.fromRGB(255, 230, 100)
	innerStroke.LineJoinMode = Enum.LineJoinMode.Round
	innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradIn = Instance.new("UIGradient")
	gradIn.Rotation = 45
	gradIn.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 25))
	}
	gradIn.Parent = innerStroke
	innerStroke.Parent = innerFrame
end

local function createModal(name, parent)
	local modal = Instance.new("Frame")
	modal.Name = name
	modal.Size = UDim2.new(1, 0, 1, 0)
	modal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	modal.BackgroundTransparency = 0.6
	modal.Visible = false
	modal.ZIndex = 200
	modal.Parent = parent

	local container = Instance.new("Frame")
	container.Size = UDim2.new(0.55, 0, 0.80, 0)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	container.ZIndex = 201
	container.Parent = modal

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 12)
	cCorner.Parent = container

	applyDoubleGoldBorder(container)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -80, 0, 40)
	title.Position = UDim2.new(0.5, 0, 0, 15)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = Color3.fromRGB(255, 215, 50)
	title.TextScaled = true
	title.ZIndex = 202
	title.Parent = container

	local tUic = Instance.new("UITextSizeConstraint")
	tUic.MaxTextSize = 28
	tUic.Parent = title

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -20, 1, -75)
	scroll.Position = UDim2.new(0.5, 0, 0, 65)
	scroll.AnchorPoint = Vector2.new(0.5, 0)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	scroll.ZIndex = 202
	scroll.Parent = container

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = scroll

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll

	return modal, container, title, scroll, layout
end

local function createSlotBtn(name, order, isDeny, parent)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.LayoutOrder = order
	btn.Size = UDim2.new(0.95, 0, 0, 55)
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextScaled = true
	btn.ZIndex = 203
	btn.Parent = parent

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 6)
	bCorner.Parent = btn

	local bUic = Instance.new("UITextSizeConstraint")
	bUic.MaxTextSize = 22
	bUic.Parent = btn

	if isDeny then
		btn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 100, 100)
		stroke.Thickness = 2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn
	else
		btn.BackgroundColor3 = Color3.fromRGB(45, 20, 65)
		local grad = Instance.new("UIGradient")
		grad.Rotation = 45
		grad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 30, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 10, 50))
		}
		grad.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 215, 50)
		stroke.Thickness = 2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn
	end
	return btn
end

local function FormatSlotLabel(title, occupantName)
	local safeName = (occupantName == "None" or not occupantName or occupantName == "") and "Empty" or occupantName
	return title .. "\n[" .. safeName .. "]"
end

local processQueue

function GiftManager.Init(parentGui)
	standClaimModal, _, scTitle, standScroll, standLL = createModal("StandClaimModal", parentGui)
	btnScActive = createSlotBtn("BtnScActive", 1, false, standScroll)
	btnScSlot1 = createSlotBtn("BtnScSlot1", 2, false, standScroll)
	btnScSlot2 = createSlotBtn("BtnScSlot2", 3, false, standScroll)
	btnScSlot3 = createSlotBtn("BtnScSlot3", 4, false, standScroll)
	btnScSlot4 = createSlotBtn("BtnScSlot4", 5, false, standScroll)
	btnScSlot5 = createSlotBtn("BtnScSlot5", 6, false, standScroll)
	btnScDeny = createSlotBtn("BtnScDeny", 7, true, standScroll)
	btnScDeny.Text = "Discard / Do Not Claim"

	local function SendClaimStand(slot)
		SFXManager.Play("Click")
		Network.ShopAction:FireServer("ClaimShopStand", slot)
		standClaimModal.Visible = false
		isPromptShowing = false
		processQueue()
	end

	btnScActive.MouseButton1Click:Connect(function() SendClaimStand("Active") end)
	btnScSlot1.MouseButton1Click:Connect(function() SendClaimStand("Slot1") end)
	btnScSlot2.MouseButton1Click:Connect(function() SendClaimStand("Slot2") end)
	btnScSlot3.MouseButton1Click:Connect(function() SendClaimStand("Slot3") end)
	btnScSlot4.MouseButton1Click:Connect(function() SendClaimStand("Slot4") end)
	btnScSlot5.MouseButton1Click:Connect(function() SendClaimStand("Slot5") end)
	btnScDeny.MouseButton1Click:Connect(function() SendClaimStand("Deny") end)

	styleClaimModal, _, styleTitle, styleScroll, styleLL = createModal("StyleClaimModal", parentGui)
	btnStyleActive = createSlotBtn("BtnStyleActive", 1, false, styleScroll)
	btnStyleSlot1 = createSlotBtn("BtnStyleSlot1", 2, false, styleScroll)
	btnStyleSlot2 = createSlotBtn("BtnStyleSlot2", 3, false, styleScroll)
	btnStyleSlot3 = createSlotBtn("BtnStyleSlot3", 4, false, styleScroll)
	btnStyleDeny = createSlotBtn("BtnStyleDeny", 5, true, styleScroll)
	btnStyleDeny.Text = "Discard / Do Not Claim"

	local function SendClaimStyle(slot)
		SFXManager.Play("Click")
		Network.ShopAction:FireServer("ClaimShopStyle", slot)
		styleClaimModal.Visible = false
		isPromptShowing = false
		processQueue()
	end

	btnStyleActive.MouseButton1Click:Connect(function() SendClaimStyle("Active") end)
	btnStyleSlot1.MouseButton1Click:Connect(function() SendClaimStyle("Slot1") end)
	btnStyleSlot2.MouseButton1Click:Connect(function() SendClaimStyle("Slot2") end)
	btnStyleSlot3.MouseButton1Click:Connect(function() SendClaimStyle("Slot3") end)
	btnStyleDeny.MouseButton1Click:Connect(function() SendClaimStyle("Deny") end)

	giftModal = Instance.new("Frame")
	giftModal.Name = "GiftSelectionModal"
	giftModal.Size = UDim2.new(1, 0, 1, 0)
	giftModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	giftModal.BackgroundTransparency = 0.6
	giftModal.Visible = false
	giftModal.ZIndex = 300
	giftModal.Parent = parentGui

	giftContainer = Instance.new("Frame")
	giftContainer.Size = UDim2.new(0.55, 0, 0.80, 0)
	giftContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	giftContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	giftContainer.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	giftContainer.ZIndex = 301
	giftContainer.Parent = giftModal

	local gCorner = Instance.new("UICorner")
	gCorner.CornerRadius = UDim.new(0, 12)
	gCorner.Parent = giftContainer

	applyDoubleGoldBorder(giftContainer)

	giftTitle = Instance.new("TextLabel")
	giftTitle.Size = UDim2.new(1, -100, 0, 40)
	giftTitle.Position = UDim2.new(0.5, 0, 0, 15)
	giftTitle.AnchorPoint = Vector2.new(0.5, 0)
	giftTitle.BackgroundTransparency = 1
	giftTitle.Font = Enum.Font.GothamBlack
	giftTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	giftTitle.TextScaled = true
	giftTitle.ZIndex = 302
	giftTitle.Parent = giftContainer

	local gtUic = Instance.new("UITextSizeConstraint")
	gtUic.MaxTextSize = 28
	gtUic.Parent = giftTitle

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 35, 0, 35)
	closeBtn.Position = UDim2.new(1, -15, 0, 15)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextScaled = true
	closeBtn.ZIndex = 303
	closeBtn.Parent = giftContainer

	local cbCorner = Instance.new("UICorner")
	cbCorner.CornerRadius = UDim.new(0, 6)
	cbCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function() 
		SFXManager.Play("Click") 
		giftModal.Visible = false 
	end)

	giftList = Instance.new("ScrollingFrame")
	giftList.Size = UDim2.new(1, -20, 1, -75)
	giftList.Position = UDim2.new(0.5, 0, 0, 65)
	giftList.AnchorPoint = Vector2.new(0.5, 0)
	giftList.BackgroundTransparency = 1
	giftList.ScrollBarThickness = 6
	giftList.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	giftList.ZIndex = 302
	giftList.Parent = giftContainer

	local gPad = Instance.new("UIPadding")
	gPad.PaddingTop = UDim.new(0, 10)
	gPad.PaddingBottom = UDim.new(0, 10)
	gPad.PaddingRight = UDim.new(0, 6)
	gPad.Parent = giftList

	local gLL = Instance.new("UIListLayout")
	gLL.FillDirection = Enum.FillDirection.Vertical
	gLL.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gLL.Padding = UDim.new(0, 10)
	gLL.SortOrder = Enum.SortOrder.LayoutOrder
	gLL.Parent = giftList

	-- Catch any Server Prompt Events across ShopUpdate or ShopAction
	local function CatchPrompt(action, data)
		if action == "GiftPrompt" or action == "ClaimPrompt" or action == "Prompt" or action == "Receive" then
			GiftManager.ShowClaimPrompt(data)
		end
	end
	Network:WaitForChild("ShopUpdate").OnClientEvent:Connect(CatchPrompt)
	Network:WaitForChild("ShopAction").OnClientEvent:Connect(CatchPrompt)
end

processQueue = function()
	if isPromptShowing or #promptQueue == 0 then return end
	local nextData = table.remove(promptQueue, 1)
	isPromptShowing = true
	local ls = player:FindFirstChild("leaderstats")
	local prestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0

	if nextData.StandName then
		scTitle.Text = "GIFT: " .. nextData.StandName
		btnScActive.Text = FormatSlotLabel("Active", nextData.Active)
		btnScSlot1.Text = FormatSlotLabel("Slot 1", nextData.Slot1)
		btnScSlot2.Text = FormatSlotLabel("Slot 2", nextData.Slot2)
		btnScSlot3.Text = FormatSlotLabel("Slot 3", nextData.Slot3)
		btnScSlot4.Text = FormatSlotLabel("Slot 4 (Pres. 15)", nextData.Slot4)
		btnScSlot5.Text = FormatSlotLabel("Slot 5 (Pres. 30)", nextData.Slot5)

		btnScSlot2.Visible = player:GetAttribute("HasStandSlot2") == true
		btnScSlot3.Visible = player:GetAttribute("HasStandSlot3") == true
		btnScSlot4.Visible = prestige >= 15
		btnScSlot5.Visible = prestige >= 30

		standClaimModal.Visible = true
		SFXManager.Play("BuyPass")

		task.delay(0.05, function() 
			standScroll.CanvasSize = UDim2.new(0, 0, 0, standLL.AbsoluteContentSize.Y + 20) 
		end)
	elseif nextData.StyleName then
		styleTitle.Text = "GIFT: " .. nextData.StyleName
		btnStyleActive.Text = FormatSlotLabel("Active", nextData.Active)
		btnStyleSlot1.Text = FormatSlotLabel("Slot 1", nextData.Slot1)
		btnStyleSlot2.Text = FormatSlotLabel("Slot 2", nextData.Slot2)
		btnStyleSlot3.Text = FormatSlotLabel("Slot 3", nextData.Slot3)

		btnStyleSlot2.Visible = player:GetAttribute("HasStyleSlot2") == true
		btnStyleSlot3.Visible = player:GetAttribute("HasStyleSlot3") == true

		styleClaimModal.Visible = true
		SFXManager.Play("BuyPass")

		task.delay(0.05, function() 
			styleScroll.CanvasSize = UDim2.new(0, 0, 0, styleLL.AbsoluteContentSize.Y + 20) 
		end)
	end
end

function GiftManager.OpenGiftModal(pInfo)
	giftTitle.Text = "GIFTING: " .. string.upper(pInfo.Name)
	for _, c in pairs(giftList:GetChildren()) do 
		if c:IsA("TextButton") then 
			c.Visible = false 
			c:Destroy() 
		end 
	end

	local function makePlayerBtn(text, color, onClick)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.95, 0, 0, 55)
		b.BackgroundColor3 = color
		b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextScaled = true
		b.Text = text
		b.ZIndex = 303
		b.Parent = giftList

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 6)
		bCorner.Parent = b

		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(255, 215, 50)
		s.Thickness = 1
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = b

		local bUic = Instance.new("UITextSizeConstraint")
		bUic.MaxTextSize = 22
		bUic.Parent = b

		b.MouseButton1Click:Connect(function() 
			SFXManager.Play("Click") 
			giftModal.Visible = false 
			onClick() 
		end)
		return b
	end

	if pInfo.Type == "Pass" then
		makePlayerBtn("Buy as Tradable Item (Self)", Color3.fromRGB(200, 150, 0), function()
			Network.ShopAction:FireServer("SetGiftTarget", -1)
			task.wait(0.1)
			game:GetService("MarketplaceService"):PromptProductPurchase(player, pInfo.GiftId)
		end)
	end

	local count = 0
	for _, p in ipairs(game.Players:GetPlayers()) do
		if p ~= player then
			if pInfo.Type == "Pass" and pInfo.Attr and p:GetAttribute(pInfo.Attr) == true then 
				continue 
			end
			count += 1
			makePlayerBtn("Gift to: " .. p.Name, Color3.fromRGB(120, 20, 160), function()
				Network.ShopAction:FireServer("SetGiftTarget", p.UserId)
				task.wait(0.1)
				if pInfo.Type == "Pass" then 
					game:GetService("MarketplaceService"):PromptProductPurchase(player, pInfo.GiftId)
				else 
					game:GetService("MarketplaceService"):PromptProductPurchase(player, pInfo.Id) 
				end
			end)
		end
	end

	if count == 0 and pInfo.Type ~= "Pass" then
		local empty = makePlayerBtn("No eligible players found!", Color3.fromRGB(100, 100, 100), function() end)
		empty.AutoButtonColor = false
	end

	task.delay(0.05, function() 
		giftList.CanvasSize = UDim2.new(0, 0, 0, giftList.UIListLayout.AbsoluteContentSize.Y + 20) 
	end)

	giftModal.Visible = true
end

function GiftManager.ShowClaimPrompt(data)
	if type(data) ~= "table" then return end
	if data.StandName and data.StyleName then
		local sData = table.clone(data)
		sData.StyleName = nil
		local stData = table.clone(data)
		stData.StandName = nil
		table.insert(promptQueue, sData)
		table.insert(promptQueue, stData)
	else
		table.insert(promptQueue, data)
	end
	processQueue()
end

return GiftManager