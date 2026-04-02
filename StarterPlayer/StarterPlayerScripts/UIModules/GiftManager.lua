-- @ScriptType: ModuleScript
local GiftManager = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local SFXManager = require(script.Parent:WaitForChild("SFXManager"))

local standClaimModal, styleClaimModal

-- [ADDED VIP BUTTON VARIABLES HERE]
local btnScActive, btnScSlot1, btnScSlot2, btnScSlot3, btnScSlot4, btnScSlot5, btnScSlotVIP, btnScDeny
local btnStyleActive, btnStyleSlot1, btnStyleSlot2, btnStyleSlot3, btnStyleSlotVIP, btnStyleDeny

local scTitle, styleTitle
local standScroll, styleScroll, standLL, styleLL

local giftModal, giftContainer, giftTitle, giftList

local promptQueue = {}
local isPromptShowing = false
local processQueue
local playerBtnTpl

local function FormatSlotLabel(title, occupantName)
	local safeName = (occupantName == "None" or not occupantName or occupantName == "") and "Empty" or occupantName
	return title .. "\n[" .. safeName .. "]"
end

function GiftManager.Init(parentGui)
	local modals = parentGui:WaitForChild("ModalsContainer")
	playerBtnTpl = ReplicatedStorage:WaitForChild("JJBITemplates"):WaitForChild("GiftPlayerBtnTemplate")

	standClaimModal = modals:WaitForChild("StandClaimModal")
	local scContainer = standClaimModal:WaitForChild("Container")
	scTitle = scContainer:WaitForChild("TitleLabel")
	standScroll = scContainer:WaitForChild("ScrollArea")
	standLL = standScroll:WaitForChild("UIListLayout")

	btnScActive = standScroll:WaitForChild("BtnScActive")
	btnScSlot1 = standScroll:WaitForChild("BtnScSlot1")
	btnScSlot2 = standScroll:WaitForChild("BtnScSlot2")
	btnScSlot3 = standScroll:WaitForChild("BtnScSlot3")
	btnScSlot4 = standScroll:WaitForChild("BtnScSlot4")
	btnScSlot5 = standScroll:WaitForChild("BtnScSlot5")
	btnScSlotVIP = standScroll:WaitForChild("BtnScSlotVIP")
	btnScDeny = standScroll:WaitForChild("BtnScDeny")

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
	btnScSlotVIP.MouseButton1Click:Connect(function() SendClaimStand("SlotVIP") end)
	btnScDeny.MouseButton1Click:Connect(function() SendClaimStand("Deny") end)

	styleClaimModal = modals:WaitForChild("StyleClaimModal")
	local stcContainer = styleClaimModal:WaitForChild("Container")
	styleTitle = stcContainer:WaitForChild("TitleLabel")
	styleScroll = stcContainer:WaitForChild("ScrollArea")
	styleLL = styleScroll:WaitForChild("UIListLayout")

	btnStyleActive = styleScroll:WaitForChild("BtnStyleActive")
	btnStyleSlot1 = styleScroll:WaitForChild("BtnStyleSlot1")
	btnStyleSlot2 = styleScroll:WaitForChild("BtnStyleSlot2")
	btnStyleSlot3 = styleScroll:WaitForChild("BtnStyleSlot3")
	btnStyleSlotVIP = styleScroll:WaitForChild("BtnStyleSlotVIP")
	btnStyleDeny = styleScroll:WaitForChild("BtnStyleDeny")

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
	btnStyleSlotVIP.MouseButton1Click:Connect(function() SendClaimStyle("SlotVIP") end)
	btnStyleDeny.MouseButton1Click:Connect(function() SendClaimStyle("Deny") end)

	giftModal = modals:WaitForChild("GiftSelectionModal")
	giftContainer = giftModal:WaitForChild("Container")
	giftTitle = giftContainer:WaitForChild("TitleLabel")
	giftList = giftContainer:WaitForChild("ScrollArea")

	local closeBtn = giftContainer:WaitForChild("CloseBtn")
	closeBtn.MouseButton1Click:Connect(function() 
		SFXManager.Play("Click") 
		giftModal.Visible = false 
	end)

	local function CatchPrompt(action, data)
		if action == "ShowStandClaim" or action == "GiftPrompt" or action == "ClaimPrompt" or action == "Prompt" or action == "Receive" then
			GiftManager.ShowClaimPrompt(data)
		end
	end
	Network:WaitForChild("ShopUpdate").OnClientEvent:Connect(CatchPrompt)
	Network:WaitForChild("ShopAction").OnClientEvent:Connect(CatchPrompt)
end

local function FormatFusedStand(baseStr, name, fs1, fs2)
	if name == "Fused Stand" then
		return baseStr .. "\n(" .. tostring(fs1) .. " + " .. tostring(fs2) .. ")"
	end
	return baseStr .. "\n[" .. tostring(name) .. "]"
end

processQueue = function()
	if isPromptShowing or #promptQueue == 0 then return end
	local nextData = table.remove(promptQueue, 1)
	isPromptShowing = true
	local ls = player:FindFirstChild("leaderstats")
	local prestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0

	if nextData.StandName then
		local sNameFormatted = nextData.StandName
		if nextData.StandName == "Fused Stand" then
			local tS1 = player:GetAttribute("PendingStand_FusedS1") or "None"
			local tS2 = player:GetAttribute("PendingStand_FusedS2") or "None"
			sNameFormatted = "Fused Stand\n(" .. tS1 .. " + " .. tS2 .. ")"
		end
		scTitle.Text = "GIFT: " .. sNameFormatted

		btnScActive.Text = FormatFusedStand("Active", nextData.Active, player:GetAttribute("Active_FusedStand1"), player:GetAttribute("Active_FusedStand2"))
		btnScSlot1.Text = FormatFusedStand("Slot 1", nextData.Slot1, player:GetAttribute("StoredStand1_FusedStand1"), player:GetAttribute("StoredStand1_FusedStand2"))
		btnScSlot2.Text = FormatFusedStand("Slot 2", nextData.Slot2, player:GetAttribute("StoredStand2_FusedStand1"), player:GetAttribute("StoredStand2_FusedStand2"))
		btnScSlot3.Text = FormatFusedStand("Slot 3", nextData.Slot3, player:GetAttribute("StoredStand3_FusedStand1"), player:GetAttribute("StoredStand3_FusedStand2"))
		btnScSlot4.Text = FormatFusedStand("Slot 4 (Pres. 15)", nextData.Slot4, player:GetAttribute("StoredStand4_FusedStand1"), player:GetAttribute("StoredStand4_FusedStand2"))
		btnScSlot5.Text = FormatFusedStand("Slot 5 (Pres. 30)", nextData.Slot5, player:GetAttribute("StoredStand5_FusedStand1"), player:GetAttribute("StoredStand5_FusedStand2"))
		btnScSlotVIP.Text = FormatFusedStand("VIP Slot", nextData.SlotVIP, player:GetAttribute("StoredStandVIP_FusedStand1"), player:GetAttribute("StoredStandVIP_FusedStand2"))

		btnScSlot2.Visible = player:GetAttribute("HasStandSlot2") == true
		btnScSlot3.Visible = player:GetAttribute("HasStandSlot3") == true
		btnScSlot4.Visible = prestige >= 15
		btnScSlot5.Visible = prestige >= 30

		btnScSlotVIP.Visible = player:GetAttribute("IsVIP") == true 

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

		-- [ADDED VIP STYLE TEXT]
		btnStyleSlotVIP.Text = FormatSlotLabel("VIP Slot", nextData.SlotVIP) 

		btnStyleSlot2.Visible = player:GetAttribute("HasStyleSlot2") == true
		btnStyleSlot3.Visible = player:GetAttribute("HasStyleSlot3") == true

		-- [ADDED VIP STYLE VISIBILITY LOGIC]
		btnStyleSlotVIP.Visible = player:GetAttribute("IsVIP") == true 

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
		local b = playerBtnTpl:Clone()
		b.BackgroundColor3 = color
		b.Text = text
		b.Parent = giftList

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