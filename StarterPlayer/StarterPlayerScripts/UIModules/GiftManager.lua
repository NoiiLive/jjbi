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
	local gradOut = Instance.new("UIGradient", outerStroke)
	gradOut.Rotation = -45
	gradOut.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 160, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 160, 30))
	}
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
		innerCorner.CornerRadius = UDim.new(0, math.max(0, parentCorner.CornerRadius.Offset - 3))
		innerCorner.Parent = innerFrame
	end
	innerFrame.Parent = parent

	local innerStroke = Instance.new("UIStroke", innerFrame)
	innerStroke.Thickness = 1
	innerStroke.Color = Color3.fromRGB(255, 230, 100)
	innerStroke.LineJoinMode = Enum.LineJoinMode.Round
	innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local gradIn = Instance.new("UIGradient", innerStroke)
	gradIn.Rotation = 45
	gradIn.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 25))
	}
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

	local container = Instance.new("Frame", modal)
	container.Size = UDim2.new(0.45, 0, 0.75, 0)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	container.ZIndex = 201
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 12)
	applyDoubleGoldBorder(container)

	local title = Instance.new("TextLabel", container)
	title.Size = UDim2.new(1, -80, 0, 40)
	title.Position = UDim2.new(0.5, 0, 0, 15)
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = Color3.fromRGB(255, 215, 50)
	title.TextScaled = true
	title.ZIndex = 202
	Instance.new("UITextSizeConstraint", title).MaxTextSize = 28

	local scroll = Instance.new("ScrollingFrame", container)
	scroll.Size = UDim2.new(1, -20, 1, -70)
	scroll.Position = UDim2.new(0.5, 0, 0, 60)
	scroll.AnchorPoint = Vector2.new(0.5, 0)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	scroll.ZIndex = 202
	local pad = Instance.new("UIPadding", scroll)
	pad.PaddingRight = UDim.new(0, 6)
	local layout = Instance.new("UIListLayout", scroll)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	return modal, container, title, scroll, layout
end

local function createSlotBtn(name, order, isDeny, parent)
	local btn = Instance.new("TextButton", parent)
	btn.Name = name
	btn.LayoutOrder = order
	btn.Size = UDim2.new(0.9, 0, 0, 50)
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextScaled = true
	btn.ZIndex = 203
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	Instance.new("UITextSizeConstraint", btn).MaxTextSize = 18

	if isDeny then
		btn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = Color3.fromRGB(255, 100, 100)
		stroke.Thickness = 2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	else
		btn.BackgroundColor3 = Color3.fromRGB(45, 20, 65)
		local grad = Instance.new("UIGradient", btn)
		grad.Rotation = 45
		grad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 30, 100)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 10, 50))
		}
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = Color3.fromRGB(255, 215, 50)
		stroke.Thickness = 2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
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

	giftContainer = Instance.new("Frame", giftModal)
	giftContainer.Size = UDim2.new(0.4, 0, 0.7, 0)
	giftContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	giftContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	giftContainer.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	giftContainer.ZIndex = 301
	Instance.new("UICorner", giftContainer).CornerRadius = UDim.new(0, 12)
	applyDoubleGoldBorder(giftContainer)

	giftTitle = Instance.new("TextLabel", giftContainer)
	giftTitle.Size = UDim2.new(1, -100, 0, 40)
	giftTitle.Position = UDim2.new(0.5, 0, 0, 15)
	giftTitle.AnchorPoint = Vector2.new(0.5, 0)
	giftTitle.BackgroundTransparency = 1
	giftTitle.Font = Enum.Font.GothamBlack
	giftTitle.TextColor3 = Color3.fromRGB(255, 215, 50)
	giftTitle.TextScaled = true
	giftTitle.ZIndex = 302
	Instance.new("UITextSizeConstraint", giftTitle).MaxTextSize = 24

	local closeBtn = Instance.new("TextButton", giftContainer)
	closeBtn.Size = UDim2.new(0, 35, 0, 35)
	closeBtn.Position = UDim2.new(1, -10, 0, 10)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextScaled = true
	closeBtn.ZIndex = 303
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
	closeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click") giftModal.Visible = false end)

	giftList = Instance.new("ScrollingFrame", giftContainer)
	giftList.Size = UDim2.new(1, -30, 1, -80)
	giftList.Position = UDim2.new(0.5, 0, 0, 65)
	giftList.AnchorPoint = Vector2.new(0.5, 0)
	giftList.BackgroundTransparency = 1
	giftList.ScrollBarThickness = 6
	giftList.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	giftList.ZIndex = 302
	local gLL = Instance.new("UIListLayout", giftList)
	gLL.FillDirection = Enum.FillDirection.Vertical
	gLL.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gLL.Padding = UDim.new(0, 8)
	gLL.SortOrder = Enum.SortOrder.LayoutOrder

	Network:WaitForChild("ShopUpdate").OnClientEvent:Connect(function(action, data)
		if action == "GiftPrompt" then GiftManager.ShowClaimPrompt(data) end
	end)
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
		task.delay(0.05, function() standScroll.CanvasSize = UDim2.new(0, 0, 0, standLL.AbsoluteContentSize.Y + 10) end)
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
		task.delay(0.05, function() styleScroll.CanvasSize = UDim2.new(0, 0, 0, styleLL.AbsoluteContentSize.Y + 10) end)
	end
end

function GiftManager.OpenGiftModal(pInfo)
	giftTitle.Text = "GIFTING: " .. pInfo.Name:upper()
	for _, c in pairs(giftList:GetChildren()) do if c:IsA("TextButton") then c.Visible = false c:Destroy() end end

	local function makePlayerBtn(text, color, onClick)
		local b = Instance.new("TextButton", giftList)
		b.Size = UDim2.new(0.95, 0, 0, 45)
		b.BackgroundColor3 = color
		b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = text
		b.TextSize = 16
		b.ZIndex = 303
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		local s = Instance.new("UIStroke", b)
		s.Color = Color3.fromRGB(255, 215, 50)
		s.Thickness = 1
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		b.MouseButton1Click:Connect(function() SFXManager.Play("Click") giftModal.Visible = false onClick() end)
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
			if pInfo.Type == "Pass" and pInfo.Attr and p:GetAttribute(pInfo.Attr) == true then continue end
			count += 1
			makePlayerBtn("Gift to: " .. p.Name, Color3.fromRGB(120, 20, 160), function()
				Network.ShopAction:FireServer("SetGiftTarget", p.UserId)
				task.wait(0.1)
				if pInfo.Type == "Pass" then game:GetService("MarketplaceService"):PromptProductPurchase(player, pInfo.GiftId)
				else game:GetService("MarketplaceService"):PromptProductPurchase(player, pInfo.Id) end
			end)
		end
	end

	if count == 0 and pInfo.Type ~= "Pass" then
		local empty = makePlayerBtn("No eligible players found!", Color3.fromRGB(100, 100, 100), function() end)
		empty.AutoButtonColor = false
	end

	task.delay(0.05, function() giftList.CanvasSize = UDim2.new(0, 0, 0, giftList.UIListLayout.AbsoluteContentSize.Y + 10) end)
	giftModal.Visible = true
end

function GiftManager.ShowClaimPrompt(data)
	if data.StandName and data.StyleName then
		local sData, stData = table.clone(data), table.clone(data)
		sData.StyleName = nil
		stData.StandName = nil
		table.insert(promptQueue, sData)
		table.insert(promptQueue, stData)
	else
		table.insert(promptQueue, data)
	end
	processQueue()
end

return GiftManager