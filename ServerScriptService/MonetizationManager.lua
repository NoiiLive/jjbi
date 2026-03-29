-- @ScriptType: Script
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PolicyService = game:GetService("PolicyService")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local Network = ReplicatedStorage:WaitForChild("Network")

local NotificationEvent = Network:FindFirstChild("NotificationEvent") or Instance.new("RemoteEvent", Network)
NotificationEvent.Name = "NotificationEvent"

local function checkPlayerPolicy(player)
	local success, result = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if success and result then
		player:SetAttribute("PaidRandomItemsRestricted", result.ArePaidRandomItemsRestricted)
	else
		player:SetAttribute("PaidRandomItemsRestricted", false)
	end
end

game.Players.PlayerAdded:Connect(checkPlayerPolicy)
for _, p in ipairs(game.Players:GetPlayers()) do
	task.spawn(checkPlayerPolicy, p)
end

local function GrantItem(player, itemName, amount)
	local grantAmount = amount or 1
	local attrName = itemName:gsub("[^%w]", "") .. "Count"
	player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + grantAmount)
end

local function PromptStandClaim(receiver, standName, traitName)
	receiver:SetAttribute("PendingShopStand", standName)
	receiver:SetAttribute("PendingShopTrait", traitName)

	local currentActive = receiver:GetAttribute("Stand") or "None"
	local currentS1 = receiver:GetAttribute("StoredStand1") or "None"
	local currentS2 = receiver:GetAttribute("StoredStand2") or "None"
	local currentS3 = receiver:GetAttribute("StoredStand3") or "None"
	local currentS4 = receiver:GetAttribute("StoredStand4") or "None"
	local currentS5 = receiver:GetAttribute("StoredStand5") or "None"

	if Network:FindFirstChild("ShopUpdate") then
		Network.ShopUpdate:FireClient(receiver, "ShowStandClaim", {
			StandName = standName,
			Active = currentActive,
			Slot1 = currentS1,
			Slot2 = currentS2,
			Slot3 = currentS3,
			Slot4 = currentS4,
			Slot5 = currentS5
		})
	end
end

local function PromptStyleClaim(receiver, styleName)
	receiver:SetAttribute("PendingShopStyle", styleName)

	local currentActive = receiver:GetAttribute("FightingStyle") or "None"
	local currentS1 = receiver:GetAttribute("StoredStyle1") or "None"
	local currentS2 = receiver:GetAttribute("StoredStyle2") or "None"
	local currentS3 = receiver:GetAttribute("StoredStyle3") or "None"

	if Network:FindFirstChild("ShopUpdate") then
		Network.ShopUpdate:FireClient(receiver, "ShowStandClaim", {
			StyleName = styleName,
			Active = currentActive,
			Slot1 = currentS1,
			Slot2 = currentS2,
			Slot3 = currentS3
		})
	end
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local purchaser = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not purchaser then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local targetUserId = purchaser:GetAttribute("GiftTarget")
	local buyAsItem = (targetUserId == -1)

	local receiver = nil
	if buyAsItem then
		receiver = purchaser
	else
		receiver = (targetUserId and targetUserId ~= 0) and game.Players:GetPlayerByUserId(targetUserId) or purchaser
	end

	if not receiver then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local function SendPurchaseMsg(itemName)
		if purchaser ~= receiver then
			if Network:FindFirstChild("CombatUpdate") then
				local pMsg = "<font color='#55FF55'>Successfully gifted " .. itemName .. " to " .. receiver.Name .. "!</font>"
				local rMsg = "<font color='#FF55FF'>🎁 You received a gift! (" .. itemName .. ") from " .. purchaser.Name .. "!</font>"
				Network.CombatUpdate:FireClient(purchaser, "SystemMessage", pMsg)
				NotificationEvent:FireClient(purchaser, pMsg)
				Network.CombatUpdate:FireClient(receiver, "SystemMessage", rMsg)
				NotificationEvent:FireClient(receiver, rMsg)
			end
		else
			if Network:FindFirstChild("CombatUpdate") then
				local msg = "<font color='#55FF55'>Successfully purchased " .. itemName .. "!</font>"
				Network.CombatUpdate:FireClient(purchaser, "SystemMessage", msg)
				NotificationEvent:FireClient(purchaser, msg)
			end
		end
	end

	local productId = receiptInfo.ProductId

	if productId == 3552102461 then
		if buyAsItem then 
			GrantItem(receiver, "2x Battle Speed Pass"); SendPurchaseMsg("2x Battle Speed Pass (Item)")
		else 
			receiver:SetAttribute("Has2xBattleSpeed", true); SendPurchaseMsg("2x Battle Speed Pass") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3552102647 then
		if buyAsItem then 
			GrantItem(receiver, "2x Inventory Pass"); SendPurchaseMsg("2x Inventory Pass (Item)")
		else 
			receiver:SetAttribute("Has2xInventory", true); SendPurchaseMsg("2x Inventory Pass") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3552103016 then
		if buyAsItem then 
			GrantItem(receiver, "2x Drop Chance Pass"); SendPurchaseMsg("2x Drop Chance Pass (Item)")
		else 
			receiver:SetAttribute("Has2xDropChance", true); SendPurchaseMsg("2x Drop Chance Pass") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3552103397 then
		if buyAsItem then 
			GrantItem(receiver, "Auto Training Pass"); SendPurchaseMsg("Auto Training Pass (Item)")
		else 
			receiver:SetAttribute("HasAutoTraining", true); SendPurchaseMsg("Auto Training Pass") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3552103567 then
		if buyAsItem then 
			GrantItem(receiver, "Stand Storage Slot 2"); SendPurchaseMsg("Stand Storage Slot 2 (Item)")
		else 
			receiver:SetAttribute("HasStandSlot2", true); SendPurchaseMsg("Stand Storage Slot 2") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3552103754 then
		if buyAsItem then 
			GrantItem(receiver, "Stand Storage Slot 3"); SendPurchaseMsg("Stand Storage Slot 3 (Item)")
		else 
			receiver:SetAttribute("HasStandSlot3", true); SendPurchaseMsg("Stand Storage Slot 3") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3554941196 then
		local wipeEvent = ReplicatedStorage:FindFirstChild("SBRRobuxReroll")
		if wipeEvent then wipeEvent:Fire(receiver) end
		SendPurchaseMsg("Horse Reroll")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3554936785 then
		if buyAsItem then 
			GrantItem(receiver, "Style Storage Slot 2"); SendPurchaseMsg("Style Storage Slot 2 (Item)")
		else 
			receiver:SetAttribute("HasStyleSlot2", true); SendPurchaseMsg("Style Storage Slot 2") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3554936823 then
		if buyAsItem then 
			GrantItem(receiver, "Style Storage Slot 3"); SendPurchaseMsg("Style Storage Slot 3 (Item)")
		else 
			receiver:SetAttribute("HasStyleSlot3", true); SendPurchaseMsg("Style Storage Slot 3") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3557500443 then
		if buyAsItem then 
			GrantItem(receiver, "Auto-Roll Pass"); SendPurchaseMsg("Auto-Roll Pass (Item)")
		else 
			receiver:SetAttribute("HasAutoRoll", true); SendPurchaseMsg("Auto-Roll Pass") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3557535781 then
		if buyAsItem then 
			GrantItem(receiver, "Custom Horse Name"); SendPurchaseMsg("Custom Horse Name (Item)")
		else 
			receiver:SetAttribute("HasHorseNamePass", true); SendPurchaseMsg("Custom Horse Name Pass") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if productId == 3548843760 then
		receiver:SetAttribute("ShopPity", 10); receiver:SetAttribute("ShopRefreshTime", 0) 
		SendPurchaseMsg("Premium Shop Restock")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if productId == 3548207626 then
		PromptStyleClaim(receiver, "Hamon"); GrantItem(receiver, "Hamon Clackers"); GrantItem(receiver, "Breathing Mask") 
		SendPurchaseMsg("Hamon Pack")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3548207336 then
		PromptStyleClaim(receiver, "Vampirism"); GrantItem(receiver, "Vampire Cape")
		SendPurchaseMsg("Vampire Pack")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3548207175 then
		PromptStyleClaim(receiver, "Pillarman"); GrantItem(receiver, "Red Stone of Aja")
		SendPurchaseMsg("Pillarman Pack")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3553764779 then
		PromptStyleClaim(receiver, "Spin"); GrantItem(receiver, "Saint's Right Eye")
		SendPurchaseMsg("Spin Pack")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if productId == 3547646703 then
		GrantItem(receiver, "Jotaro's Hat"); GrantItem(receiver, "Dio's Diary")
		PromptStandClaim(receiver, "Star Platinum", "Overwhelming")
		SendPurchaseMsg("Jotaro Pack")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3547646706 then
		PromptStyleClaim(receiver, "Vampirism"); GrantItem(receiver, "Vampire Cape"); GrantItem(receiver, "Dio's Throwing Knives")
		PromptStandClaim(receiver, "The World", "Vampiric")
		SendPurchaseMsg("DIO Pack")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3550839948 then
		GrantItem(receiver, "Green Baby"); GrantItem(receiver, "Dio's Diary")
		PromptStandClaim(receiver, "Whitesnake", "Blessed")
		SendPurchaseMsg("Pucci Pack")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3553767064 then
		GrantItem(receiver, "Saint's Left Arm"); GrantItem(receiver, "Saint's Right Eye")
		PromptStandClaim(receiver, "Tusk Act 1", "Cheerful")
		SendPurchaseMsg("Johnny Pack")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3560802297 then
		if receiver:GetAttribute("PaidRandomItemsRestricted") then
			local ls = receiver:FindFirstChild("leaderstats")
			if ls and ls:FindFirstChild("Yen") then ls.Yen.Value += 10000000 end
			SendPurchaseMsg("10M Yen (Region Compliance Compensation)")
		else
			GrantItem(receiver, "Rokakaka", 25)
		end
		PromptStandClaim(receiver, "Soft & Wet", "Lethal")
		SendPurchaseMsg("Gappy Pack")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if productId == 3560808666 then
		if receiver:GetAttribute("PaidRandomItemsRestricted") then
			local ls = receiver:FindFirstChild("leaderstats")
			if ls and ls:FindFirstChild("Yen") then ls.Yen.Value += 10000000 end
			SendPurchaseMsg("10M Yen (Region Compliance Compensation)")
		else
			GrantItem(receiver, "Mythical Giftbox", 1)
			SendPurchaseMsg("Mythical Giftbox")
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3550862625 then
		if receiver:GetAttribute("PaidRandomItemsRestricted") then
			local ls = receiver:FindFirstChild("leaderstats")
			if ls and ls:FindFirstChild("Yen") then ls.Yen.Value += 10000000 end
			SendPurchaseMsg("10M Yen (Region Compliance Compensation)")
		else
			GrantItem(receiver, "Stand Arrow", 25)
			SendPurchaseMsg("25x Stand Arrows")
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3550862858 then
		if receiver:GetAttribute("PaidRandomItemsRestricted") then
			local ls = receiver:FindFirstChild("leaderstats")
			if ls and ls:FindFirstChild("Yen") then ls.Yen.Value += 10000000 end
			SendPurchaseMsg("10M Yen (Region Compliance Compensation)")
		else
			GrantItem(receiver, "Rokakaka", 5)
			SendPurchaseMsg("5x Rokakakas")
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3553771635 then
		if receiver:GetAttribute("PaidRandomItemsRestricted") then
			local ls = receiver:FindFirstChild("leaderstats")
			if ls and ls:FindFirstChild("Yen") then ls.Yen.Value += 10000000 end
			SendPurchaseMsg("10M Yen (Region Compliance Compensation)")
		else
			GrantItem(receiver, "Saint's Corpse Part", 10)
			SendPurchaseMsg("10x Saint's Corpse Parts")
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	if productId == 3564613970 then -- STARTER PACK
		if receiver:GetAttribute("PaidRandomItemsRestricted") then
			local ls = receiver:FindFirstChild("leaderstats")
			if ls and ls:FindFirstChild("Yen") then ls.Yen.Value += 2500000 end
			SendPurchaseMsg("2.5M Yen (Region Compliance Compensation)")
		else
			GrantItem(receiver, "Stand Arrow", 15)
		end

		receiver:SetAttribute("BoughtStarterPack", true)

		PromptStandClaim(receiver, "Silver Chariot", "None")
		SendPurchaseMsg("Starter Pack")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if productId == 3564614182 then -- PRO PACK
		if receiver:GetAttribute("PaidRandomItemsRestricted") then
			local ls = receiver:FindFirstChild("leaderstats")
			if ls and ls:FindFirstChild("Yen") then ls.Yen.Value += 12500000 end
			SendPurchaseMsg("12.5M Yen (Region Compliance Compensation)")
		else
			GrantItem(receiver, "Stand Arrow", 25)
			GrantItem(receiver, "Rokakaka", 10)
		end

		receiver:SetAttribute("BoughtProPack", true)

		PromptStandClaim(receiver, "Whitesnake", "None")
		SendPurchaseMsg("Pro Pack")
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	if productId == 3564614326 then
		if buyAsItem then 
			GrantItem(receiver, "VIP"); SendPurchaseMsg("VIP (Item)")
		else 
			receiver:SetAttribute("IsVIP", true); SendPurchaseMsg("VIP") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if productId == 3564614546 then
		if buyAsItem then 
			GrantItem(receiver, "VIP"); SendPurchaseMsg("VIP Gift (Item)")
		else 
			receiver:SetAttribute("IsVIP", true); SendPurchaseMsg("VIP") 
		end
		purchaser:SetAttribute("GiftTarget", nil); return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, wasPurchased)
	if not wasPurchased then return end

	local passName = "GamePass"
	if passId == 1731694181 then player:SetAttribute("Has2xBattleSpeed", true); passName = "2x Battle Speed"
	elseif passId == 1732129582 then player:SetAttribute("HasAutoTraining", true); passName = "Auto Training"
	elseif passId == 1732900742 then player:SetAttribute("Has2xInventory", true); passName = "2x Inventory Space"
	elseif passId == 1732842877 then player:SetAttribute("Has2xDropChance", true); passName = "2x Drop Chance"
	elseif passId == 1733160695 then player:SetAttribute("HasStandSlot2", true); passName = "Stand Storage Slot 2"
	elseif passId == 1732844091 then player:SetAttribute("HasStandSlot3", true); passName = "Stand Storage Slot 3"
	elseif passId == 1746853452 then player:SetAttribute("HasStyleSlot2", true); passName = "Style Storage Slot 2"
	elseif passId == 1745969849 then player:SetAttribute("HasStyleSlot3", true); passName = "Style Storage Slot 3"
	elseif passId == 1749484465 then player:SetAttribute("HasAutoRoll", true); passName = "Auto-Roll Pass"
	elseif passId == 1749586333 then player:SetAttribute("HasHorseNamePass", true); passName = "Custom Horse Name Pass"
	elseif passId == 1772743731 then player:SetAttribute("IsVIP", true); passName = "VIP Status" end

	if Network:FindFirstChild("CombatUpdate") then
		local msg = "<font color='#55FF55'>Successfully unlocked " .. passName .. "!</font>"
		Network.CombatUpdate:FireClient(player, "SystemMessage", msg)
		NotificationEvent:FireClient(player, msg)
	end
end)