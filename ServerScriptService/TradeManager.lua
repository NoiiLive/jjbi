-- @ScriptType: Script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PolicyService = game:GetService("PolicyService")
local Network = ReplicatedStorage:WaitForChild("Network")
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))

local AdminLogger = Network:FindFirstChild("AdminLogger")
if not AdminLogger then
	AdminLogger = Instance.new("BindableEvent")
	AdminLogger.Name = "AdminLogger"
	AdminLogger.Parent = Network
end

local TradeAction = Network:WaitForChild("TradeAction")
local TradeUpdate = Network:WaitForChild("TradeUpdate")

local NotificationEvent = Network:FindFirstChild("NotificationEvent") or Instance.new("RemoteEvent", Network)
NotificationEvent.Name = "NotificationEvent"

local OpenLobbies = {} 
local IncomingRequests = {} 
local ActiveTrades = {} 
local PlayerSettings = {} 

local function checkPlayerPolicy(player)
	local success, result = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if success and result then
		player:SetAttribute("PaidItemTradingAllowed", result.IsPaidItemTradingAllowed)
	else
		player:SetAttribute("PaidItemTradingAllowed", false) 
	end
end

Players.PlayerAdded:Connect(checkPlayerPolicy)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(checkPlayerPolicy, p)
end

local function IsKeyItem(name)
	local itemInfo = ItemData.Equipment[name] or ItemData.Consumables[name]
	if not itemInfo then return false end

	if itemInfo.Rarity == "Unique" or itemInfo.Rarity == "Special" then
		return true
	end

	if ItemData.Consumables[name] and itemInfo.Category == "Stand" then
		return true
	end

	return false
end

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
		["Auto-Stat Invest"] = true,
		["Custom Horse Name"] = true,
		["VIP"] = true
	}
	return passes[name] == true
end

local function CanTrade(plr)
	if not plr then return false end
	local ls = plr:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Prestige") then
		return ls.Prestige.Value >= 1
	end
	return false
end

local function GetBrowserDataForPlayer(player)
	local lobbiesList = {}
	for host, data in pairs(OpenLobbies) do
		table.insert(lobbiesList, { HostId = host.UserId, HostName = host.Name, LF = data.LF, Offering = data.Offering })
	end

	local requestsList = {}
	if IncomingRequests[player] then
		for sender, _ in pairs(IncomingRequests[player]) do
			table.insert(requestsList, { SenderId = sender.UserId, SenderName = sender.Name })
		end
	end
	return { Lobbies = lobbiesList, Requests = requestsList }
end

local function UpdateAllBrowsers()
	for _, plr in ipairs(Players:GetPlayers()) do
		if CanTrade(plr) then
			TradeUpdate:FireClient(plr, "BrowserUpdate", GetBrowserDataForPlayer(plr))
		end
	end
end

local function FindPlayerByName(partialName)
	local lowerTarget = string.lower(partialName)
	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name) == lowerTarget or string.lower(p.DisplayName) == lowerTarget then return p end
	end
	return nil
end

local function GetTradeStateForClient(session, requestingPlayer)
	local myOffer = (session.P1 == requestingPlayer) and session.P1Offer or session.P2Offer
	local oppOffer = (session.P1 == requestingPlayer) and session.P2Offer or session.P1Offer
	local oppName = (session.P1 == requestingPlayer) and session.P2.Name or session.P1.Name

	return {
		OpponentName = oppName,
		Me = { Items = myOffer.Items, Stand = myOffer.Stand, Style = myOffer.Style, Yen = myOffer.Yen, Locked = myOffer.Locked, Confirmed = myOffer.Confirmed },
		Opp = { Items = oppOffer.Items, Stand = oppOffer.Stand, Style = oppOffer.Style, Yen = oppOffer.Yen, Locked = oppOffer.Locked, Confirmed = oppOffer.Confirmed }
	}
end

local function SyncTrade(session)
	if session.P1.Parent then TradeUpdate:FireClient(session.P1, "TradeUpdateState", GetTradeStateForClient(session, session.P1)) end
	if session.P2.Parent then TradeUpdate:FireClient(session.P2, "TradeUpdateState", GetTradeStateForClient(session, session.P2)) end
end

local function EndTrade(session, reasonMsg)
	ActiveTrades[session.P1] = nil
	ActiveTrades[session.P2] = nil

	if session.P1.Parent then TradeUpdate:FireClient(session.P1, "TradeEnd") end
	if session.P2.Parent then TradeUpdate:FireClient(session.P2, "TradeEnd") end

	if reasonMsg then
		if session.P1.Parent then NotificationEvent:FireClient(session.P1, reasonMsg) end
		if session.P2.Parent then NotificationEvent:FireClient(session.P2, reasonMsg) end
	end
end

local function ExecuteTrade(session)
	if session.IsExecuting then return end
	session.IsExecuting = true

	local p1, p2 = session.P1, session.P2
	local o1, o2 = session.P1Offer, session.P2Offer

	if not p1 or not p2 or not p1.Parent or not p2.Parent then
		EndTrade(session, "<font color='#FF5555'>Trade failed: A player disconnected.</font>")
		return
	end

	if p1.leaderstats.Yen.Value < o1.Yen or p2.leaderstats.Yen.Value < o2.Yen then
		EndTrade(session, "<font color='#FF5555'>Trade failed: Someone didn't have enough Yen!</font>")
		return
	end

	local function VerifyItems(plr, offer)
		for item, amt in pairs(offer.Items) do
			local actual = plr:GetAttribute(item:gsub("[^%w]", "") .. "Count") or 0
			if actual < amt then return false end
		end
		return true
	end

	local function VerifyStand(plr, offer)
		if not offer.Stand then return true end
		local slot = offer.Stand.Slot
		local expectedName = offer.Stand.Name

		local actual, actualTrait = "None", "None"
		local actualFS1, actualFS2, actualFT1, actualFT2 = "None", "None", "None", "None"

		if slot == "Active" then 
			actual = plr:GetAttribute("Stand") or "None"
			actualTrait = plr:GetAttribute("StandTrait") or "None"
			if actual == "Fused Stand" then
				actualFS1 = plr:GetAttribute("Active_FusedStand1") or "None"
				actualFS2 = plr:GetAttribute("Active_FusedStand2") or "None"
				actualFT1 = plr:GetAttribute("Active_FusedTrait1") or "None"
				actualFT2 = plr:GetAttribute("Active_FusedTrait2") or "None"
			end
		elseif slot == "SlotVIP" then
			actual = plr:GetAttribute("StoredStandVIP") or "None"
			actualTrait = plr:GetAttribute("StoredStandVIP_Trait") or "None"
			if actual == "Fused Stand" then
				actualFS1 = plr:GetAttribute("StoredStandVIP_FusedStand1") or "None"
				actualFS2 = plr:GetAttribute("StoredStandVIP_FusedStand2") or "None"
				actualFT1 = plr:GetAttribute("StoredStandVIP_FusedTrait1") or "None"
				actualFT2 = plr:GetAttribute("StoredStandVIP_FusedTrait2") or "None"
			end
		else
			local num = string.sub(slot, 5)
			actual = plr:GetAttribute("StoredStand"..num) or "None"
			actualTrait = plr:GetAttribute("StoredStand"..num.."_Trait") or "None"
			if actual == "Fused Stand" then
				actualFS1 = plr:GetAttribute("StoredStand"..num.."_FusedStand1") or "None"
				actualFS2 = plr:GetAttribute("StoredStand"..num.."_FusedStand2") or "None"
				actualFT1 = plr:GetAttribute("StoredStand"..num.."_FusedTrait1") or "None"
				actualFT2 = plr:GetAttribute("StoredStand"..num.."_FusedTrait2") or "None"
			end
		end

		if actual ~= expectedName then return false end
		if actualTrait ~= offer.Stand.Trait then return false end

		if expectedName == "Fused Stand" then
			if actualFS1 ~= offer.Stand.FusedS1 or actualFS2 ~= offer.Stand.FusedS2 or actualFT1 ~= offer.Stand.FusedT1 or actualFT2 ~= offer.Stand.FusedT2 then
				return false
			end
		end

		return true
	end

	local function VerifyStyle(plr, offer)
		if not offer.Style then return true end
		local slot = offer.Style.Slot
		local expectedName = offer.Style.Name
		local actual = "None"

		if slot == "Active" then actual = plr:GetAttribute("FightingStyle") or "None"
		elseif slot == "Slot1" then actual = plr:GetAttribute("StoredStyle1") or "None"
		elseif slot == "Slot2" then actual = plr:GetAttribute("StoredStyle2") or "None"
		elseif slot == "Slot3" then actual = plr:GetAttribute("StoredStyle3") or "None"
		elseif slot == "SlotVIP" then actual = plr:GetAttribute("StoredStyleVIP") or "None" end

		return actual == expectedName
	end

	if not VerifyItems(p1, o1) or not VerifyItems(p2, o2) or not VerifyStand(p1, o1) or not VerifyStand(p2, o2) or not VerifyStyle(p1, o1) or not VerifyStyle(p2, o2) then
		EndTrade(session, "<font color='#FF5555'>Trade failed: Inventory mismatched offer.</font>")
		return
	end

	local function GetOfferSpaceNeeded(offer)
		local space = 0
		for item, amt in pairs(offer.Items) do
			if not IsKeyItem(item) then
				space += amt
			end
		end
		return space
	end

	local p1Given = GetOfferSpaceNeeded(o1)
	local p1Received = GetOfferSpaceNeeded(o2)
	local p2Given = GetOfferSpaceNeeded(o2)
	local p2Received = GetOfferSpaceNeeded(o1)

	if GameData.GetInventoryCount(p1) - p1Given + p1Received > GameData.GetMaxInventory(p1) then
		EndTrade(session, "<font color='#FF5555'>Trade failed: " .. p1.Name .. " does not have enough inventory space!</font>")
		return
	end

	if GameData.GetInventoryCount(p2) - p2Given + p2Received > GameData.GetMaxInventory(p2) then
		EndTrade(session, "<font color='#FF5555'>Trade failed: " .. p2.Name .. " does not have enough inventory space!</font>")
		return
	end

	p1.leaderstats.Yen.Value = p1.leaderstats.Yen.Value - o1.Yen + o2.Yen
	p2.leaderstats.Yen.Value = p2.leaderstats.Yen.Value - o2.Yen + o1.Yen

	local function ProcessItems(giver, receiver, offer)
		for itemName, amt in pairs(offer.Items) do
			local cleanName = itemName:gsub("[^%w]", "") .. "Count"
			local currentCount = giver:GetAttribute(cleanName) or 0

			if currentCount - amt == 0 then
				local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
				if itemData and itemData.Slot then
					if giver:GetAttribute("Equipped" .. itemData.Slot) == itemName then
						giver:SetAttribute("Equipped" .. itemData.Slot, "None")
					end
				end
			end

			giver:SetAttribute(cleanName, currentCount - amt)
			receiver:SetAttribute(cleanName, (receiver:GetAttribute(cleanName) or 0) + amt)
		end
	end

	ProcessItems(p1, p2, o1)
	ProcessItems(p2, p1, o2)

	local function WipeStand(plr, slot)
		local prefix = slot == "Active" and "Stand" or "StoredStand" .. slot:gsub("Slot", "")
		local traitSuffix = slot == "Active" and "StandTrait" or "StoredStand" .. slot:gsub("Slot", "") .. "_Trait"

		plr:SetAttribute(prefix, "None")
		plr:SetAttribute(traitSuffix, "None")

		if slot == "Active" then
			plr:SetAttribute("Active_FusedStand1", "None"); plr:SetAttribute("Active_FusedStand2", "None")
			plr:SetAttribute("Active_FusedTrait1", "None"); plr:SetAttribute("Active_FusedTrait2", "None")
		else
			local num = slot:gsub("Slot", "")
			plr:SetAttribute("StoredStand"..num.."_FusedStand1", "None"); plr:SetAttribute("StoredStand"..num.."_FusedStand2", "None")
			plr:SetAttribute("StoredStand"..num.."_FusedTrait1", "None"); plr:SetAttribute("StoredStand"..num.."_FusedTrait2", "None")
		end
	end

	local function WipeStyle(plr, slot)
		if slot == "Active" then
			plr:SetAttribute("FightingStyle", "None")
		elseif slot == "Slot1" then
			plr:SetAttribute("StoredStyle1", "None")
		elseif slot == "Slot2" then
			plr:SetAttribute("StoredStyle2", "None")
		elseif slot == "Slot3" then
			plr:SetAttribute("StoredStyle3", "None")
		elseif slot == "SlotVIP" then
			plr:SetAttribute("StoredStyleVIP", "None")
		end
	end

	if o1.Stand then WipeStand(p1, o1.Stand.Slot) end
	if o2.Stand then WipeStand(p2, o2.Stand.Slot) end
	if o1.Style then WipeStand(p1, o1.Style.Slot) end
	if o2.Style then WipeStyle(p2, o2.Style.Slot) end

	local function DispatchStandClaim(recipient, senderOffer)
		recipient:SetAttribute("PendingStand_Name", senderOffer.Stand.Name)
		recipient:SetAttribute("PendingStand_Trait", senderOffer.Stand.Trait)

		if senderOffer.Stand.Name == "Fused Stand" then
			recipient:SetAttribute("PendingStand_FusedS1", senderOffer.Stand.FusedS1)
			recipient:SetAttribute("PendingStand_FusedS2", senderOffer.Stand.FusedS2)
			recipient:SetAttribute("PendingStand_FusedT1", senderOffer.Stand.FusedT1)
			recipient:SetAttribute("PendingStand_FusedT2", senderOffer.Stand.FusedT2)
		end

		TradeUpdate:FireClient(recipient, "ShowClaimPrompt", {
			Name = senderOffer.Stand.Name,
			Active = recipient:GetAttribute("Stand") or "None",
			Slot1 = recipient:GetAttribute("StoredStand1") or "None",
			Slot2 = recipient:GetAttribute("StoredStand2") or "None",
			Slot3 = recipient:GetAttribute("StoredStand3") or "None",
			Slot4 = recipient:GetAttribute("StoredStand4") or "None",
			Slot5 = recipient:GetAttribute("StoredStand5") or "None",
			SlotVIP = recipient:GetAttribute("StoredStandVIP") or "None"
		})
	end

	if o1.Stand then DispatchStandClaim(p2, o1) end
	if o2.Stand then DispatchStandClaim(p1, o2) end

	if o1.Style then
		p2:SetAttribute("PendingStyle_Name", o1.Style.Name)
		TradeUpdate:FireClient(p2, "ShowStyleClaimPrompt", {
			Name = o1.Style.Name,
			Active = p2:GetAttribute("FightingStyle") or "None",
			Slot1 = p2:GetAttribute("StoredStyle1") or "None",
			Slot2 = p2:GetAttribute("StoredStyle2") or "None",
			Slot3 = p2:GetAttribute("StoredStyle3") or "None",
			SlotVIP = p2:GetAttribute("StoredStyleVIP") or "None"
		})
	end
	if o2.Style then
		p1:SetAttribute("PendingStyle_Name", o2.Style.Name)
		TradeUpdate:FireClient(p1, "ShowStyleClaimPrompt", {
			Name = o2.Style.Name,
			Active = p1:GetAttribute("FightingStyle") or "None",
			Slot1 = p1:GetAttribute("StoredStyle1") or "None",
			Slot2 = p1:GetAttribute("StoredStyle2") or "None",
			Slot3 = p1:GetAttribute("StoredStyle3") or "None",
			SlotVIP = p1:GetAttribute("StoredStyleVIP") or "None"
		})
	end

	local saveEvent = ReplicatedStorage:FindFirstChild("ForcePlayerSave")
	if saveEvent then
		saveEvent:Fire(p1)
		saveEvent:Fire(p2)
	end

	local function GetOfferDetails(offer)
		local details = ""
		for k, v in pairs(offer.Items) do details = details .. v .. "x " .. k .. ", " end
		if offer.Stand then
			if offer.Stand.Name == "Fused Stand" then
				local t1 = (offer.Stand.FusedT1 and offer.Stand.FusedT1 ~= "None") and (" ["..offer.Stand.FusedT1.."]") or ""
				local t2 = (offer.Stand.FusedT2 and offer.Stand.FusedT2 ~= "None") and (" ["..offer.Stand.FusedT2.."]") or ""
				details = details .. "Stand: Fused Stand (" .. tostring(offer.Stand.FusedS1) .. t1 .. " + " .. tostring(offer.Stand.FusedS2) .. t2 .. "), "
			else
				local tr = (offer.Stand.Trait and offer.Stand.Trait ~= "None") and (" ["..offer.Stand.Trait.."]") or ""
				details = details .. "Stand: " .. offer.Stand.Name .. tr .. ", "
			end
		end
		if offer.Style then details = details .. "Style: " .. offer.Style.Name .. ", " end
		if offer.Yen > 0 then details = details .. offer.Yen .. " Yen" end
		return details == "" and "Nothing" or details
	end

	AdminLogger:Fire("Trade", {
		Player1 = p1.Name,
		Player2 = p2.Name,
		Offer1 = GetOfferDetails(o1),
		Offer2 = GetOfferDetails(o2)
	})

	EndTrade(session, "<font color='#55FF55'>Trade successfully completed!</font>")
end

local function StartTrade(p1, p2)
	if OpenLobbies[p1] then 
		OpenLobbies[p1] = nil 
		TradeUpdate:FireClient(p1, "LobbyStatus", {IsHosting = false})
	end
	if OpenLobbies[p2] then 
		OpenLobbies[p2] = nil 
		TradeUpdate:FireClient(p2, "LobbyStatus", {IsHosting = false})
	end

	if IncomingRequests[p1] then IncomingRequests[p1][p2] = nil end
	if IncomingRequests[p2] then IncomingRequests[p2][p1] = nil end

	local tradeMatch = { 
		P1 = p1, P2 = p2,
		IsExecuting = false,
		P1Offer = { Items = {}, Stand = nil, Style = nil, Yen = 0, Locked = false, Confirmed = false },
		P2Offer = { Items = {}, Stand = nil, Style = nil, Yen = 0, Locked = false, Confirmed = false }
	}
	ActiveTrades[p1] = tradeMatch
	ActiveTrades[p2] = tradeMatch

	TradeUpdate:FireClient(p1, "TradeStart", { OpponentName = p2.Name })
	TradeUpdate:FireClient(p2, "TradeStart", { OpponentName = p1.Name })

	SyncTrade(tradeMatch)
	UpdateAllBrowsers()
end

TradeAction.OnServerEvent:Connect(function(player, action, data)
	local session = ActiveTrades[player]

	if not session then
		if action == "RequestData" then
			if CanTrade(player) then
				TradeUpdate:FireClient(player, "BrowserUpdate", GetBrowserDataForPlayer(player))
			end

		elseif action == "ClaimStand" then
			local pName = player:GetAttribute("PendingStand_Name")
			local pTrait = player:GetAttribute("PendingStand_Trait")
			if not pName or pName == "" or pName == "None" then return end

			player:SetAttribute("PendingStand_Name", "None")
			player:SetAttribute("PendingStand_Trait", "None")

			local slot = data

			local oldStand = "None"
			if slot == "Active" then 
				oldStand = player:GetAttribute("Stand") or "None"
				if oldStand == "Fused Stand" then
					local f1 = player:GetAttribute("Active_FusedStand1") or "None"
					local f2 = player:GetAttribute("Active_FusedStand2") or "None"
					local t1 = player:GetAttribute("Active_FusedTrait1") or "None"
					local t2 = player:GetAttribute("Active_FusedTrait2") or "None"
					local t1Str = (t1 ~= "None") and (" ["..t1.."]") or ""
					local t2Str = (t2 ~= "None") and (" ["..t2.."]") or ""
					oldStand = "Fused Stand (" .. tostring(f1) .. t1Str .. " + " .. tostring(f2) .. t2Str .. ")"
				elseif oldStand ~= "None" then
					local tr = player:GetAttribute("StandTrait") or "None"
					oldStand = oldStand .. ((tr ~= "None") and (" ["..tr.."]") or "")
				end
			else
				local num = slot:gsub("Slot", "")
				oldStand = player:GetAttribute("StoredStand"..num) or "None"
				if oldStand == "Fused Stand" then
					local f1 = player:GetAttribute("StoredStand"..num.."_FusedStand1") or "None"
					local f2 = player:GetAttribute("StoredStand"..num.."_FusedStand2") or "None"
					local t1 = player:GetAttribute("StoredStand"..num.."_FusedTrait1") or "None"
					local t2 = player:GetAttribute("StoredStand"..num.."_FusedTrait2") or "None"
					local t1Str = (t1 ~= "None") and (" ["..t1.."]") or ""
					local t2Str = (t2 ~= "None") and (" ["..t2.."]") or ""
					oldStand = "Fused Stand (" .. tostring(f1) .. t1Str .. " + " .. tostring(f2) .. t2Str .. ")"
				elseif oldStand ~= "None" then
					local tr = player:GetAttribute("StoredStand"..num.."_Trait") or "None"
					oldStand = oldStand .. ((tr ~= "None") and (" ["..tr.."]") or "")
				end
			end

			local pNameFormatted = pName
			if pName == "Fused Stand" then
				local f1 = player:GetAttribute("PendingStand_FusedS1") or "None"
				local f2 = player:GetAttribute("PendingStand_FusedS2") or "None"
				local t1 = player:GetAttribute("PendingStand_FusedT1") or "None"
				local t2 = player:GetAttribute("PendingStand_FusedT2") or "None"
				local t1Str = (t1 ~= "None") and (" ["..t1.."]") or ""
				local t2Str = (t2 ~= "None") and (" ["..t2.."]") or ""
				pNameFormatted = "Fused Stand (" .. tostring(f1) .. t1Str .. " + " .. tostring(f2) .. t2Str .. ")"
			elseif pName ~= "None" then
				local tStr = (pTrait ~= "None") and (" ["..pTrait.."]") or ""
				pNameFormatted = pNameFormatted .. tStr
			end

			AdminLogger:Fire("Replacement", {
				Player = player.Name, Context = "Trade", OldItem = oldStand, NewItem = pNameFormatted, Slot = slot
			})

			local function applyStandToSlot(prefix, traitSuffix, numSuffix)
				player:SetAttribute(prefix, pName)
				player:SetAttribute(traitSuffix, pTrait)

				if pName == "Fused Stand" then
					local fs1 = player:GetAttribute("PendingStand_FusedS1") or "None"
					local fs2 = player:GetAttribute("PendingStand_FusedS2") or "None"
					local ft1 = player:GetAttribute("PendingStand_FusedT1") or "None"
					local ft2 = player:GetAttribute("PendingStand_FusedT2") or "None"

					if numSuffix == "Active" then
						player:SetAttribute("Active_FusedStand1", fs1); player:SetAttribute("Active_FusedStand2", fs2)
						player:SetAttribute("Active_FusedTrait1", ft1); player:SetAttribute("Active_FusedTrait2", ft2)
					else
						player:SetAttribute("StoredStand"..numSuffix.."_FusedStand1", fs1); player:SetAttribute("StoredStand"..numSuffix.."_FusedStand2", fs2)
						player:SetAttribute("StoredStand"..numSuffix.."_FusedTrait1", ft1); player:SetAttribute("StoredStand"..numSuffix.."_FusedTrait2", ft2)
					end
				else
					if numSuffix == "Active" then
						player:SetAttribute("Active_FusedStand1", "None"); player:SetAttribute("Active_FusedStand2", "None")
						player:SetAttribute("Active_FusedTrait1", "None"); player:SetAttribute("Active_FusedTrait2", "None")
					else
						player:SetAttribute("StoredStand"..numSuffix.."_FusedStand1", "None"); player:SetAttribute("StoredStand"..numSuffix.."_FusedStand2", "None")
						player:SetAttribute("StoredStand"..numSuffix.."_FusedTrait1", "None"); player:SetAttribute("StoredStand"..numSuffix.."_FusedTrait2", "None")
					end
				end
			end

			if slot == "Active" then
				applyStandToSlot("Stand", "StandTrait", "Active")
				if pName == "Fused Stand" then
					local fs1 = player:GetAttribute("PendingStand_FusedS1") or "None"
					local fs2 = player:GetAttribute("PendingStand_FusedS2") or "None"
					local statsList = {"Power", "Speed", "Range", "Durability", "Precision", "Potential"}
					local rankToNum = {["None"]=0, ["E"]=1, ["D"]=2, ["C"]=3, ["B"]=4, ["A"]=5, ["S"]=6}
					local numToRank = { [0]="None", [1]="E", [2]="D", [3]="C", [4]="B", [5]="A", [6]="S" }

					local s1Data = StandData.Stands[fs1]
					local s2Data = StandData.Stands[fs2]

					if s1Data and s2Data then
						for _, stat in ipairs(statsList) do
							local v1 = rankToNum[s1Data.Stats[stat]] or 0
							local v2 = rankToNum[s2Data.Stats[stat]] or 0
							local avg = math.ceil((val1 + val2) / 2)
							player:SetAttribute("Stand_" .. stat, numToRank[avg] or "C")
						end
					else
						for _, stat in ipairs(statsList) do player:SetAttribute("Stand_"..stat, "E") end
					end
				else
					local stats = StandData.Stands[pName] and StandData.Stands[pName].Stats or {Power="E", Speed="E", Range="E", Durability="E", Precision="E", Potential="E"}
					for statName, rank in pairs(stats) do player:SetAttribute("Stand_"..statName, rank) end
				end
			elseif slot == "Slot1" then applyStandToSlot("StoredStand1", "StoredStand1_Trait", "1")
			elseif slot == "Slot2" then applyStandToSlot("StoredStand2", "StoredStand2_Trait", "2")
			elseif slot == "Slot3" then applyStandToSlot("StoredStand3", "StoredStand3_Trait", "3")
			elseif slot == "Slot4" then applyStandToSlot("StoredStand4", "StoredStand4_Trait", "4")
			elseif slot == "Slot5" then applyStandToSlot("StoredStand5", "StoredStand5_Trait", "5") 
			elseif slot == "SlotVIP" then applyStandToSlot("StoredStandVIP", "StoredStandVIP_Trait", "VIP") end

			player:SetAttribute("PendingStand_FusedS1", "None"); player:SetAttribute("PendingStand_FusedS2", "None")
			player:SetAttribute("PendingStand_FusedT1", "None"); player:SetAttribute("PendingStand_FusedT2", "None")

			TradeUpdate:FireClient(player, "HideClaimPrompt")
			NotificationEvent:FireClient(player, "<font color='#A020F0'>Stand safely stored!</font>")

			local saveEvent = ReplicatedStorage:FindFirstChild("ForcePlayerSave")
			if saveEvent then saveEvent:Fire(player) end

		elseif action == "ClaimStyle" then
			local pName = player:GetAttribute("PendingStyle_Name")
			if not pName or pName == "" or pName == "None" then return end

			player:SetAttribute("PendingStyle_Name", "None")

			local slot = data

			local oldStyle = "None"
			if slot == "Active" then oldStyle = player:GetAttribute("FightingStyle") or "None"
			elseif slot == "Slot1" then oldStyle = player:GetAttribute("StoredStyle1") or "None"
			elseif slot == "Slot2" then oldStyle = player:GetAttribute("StoredStyle2") or "None"
			elseif slot == "Slot3" then oldStyle = player:GetAttribute("StoredStyle3") or "None"
			elseif slot == "SlotVIP" then oldStyle = player:GetAttribute("StoredStyleVIP") or "None" end

			AdminLogger:Fire("Replacement", {
				Player = player.Name, Context = "Trade", OldItem = oldStyle, NewItem = pName, Slot = slot
			})

			if slot == "Active" then
				player:SetAttribute("FightingStyle", pName)
			elseif slot == "Slot1" then
				player:SetAttribute("StoredStyle1", pName)
			elseif slot == "Slot2" then
				player:SetAttribute("StoredStyle2", pName)
			elseif slot == "Slot3" then
				player:SetAttribute("StoredStyle3", pName)
			elseif slot == "SlotVIP" then
				player:SetAttribute("StoredStyleVIP", pName)
			end

			TradeUpdate:FireClient(player, "HideStyleClaimPrompt")
			NotificationEvent:FireClient(player, "<font color='#FF8C00'>Style safely stored!</font>")

			local saveEvent = ReplicatedStorage:FindFirstChild("ForcePlayerSave")
			if saveEvent then saveEvent:Fire(player) end

		elseif action == "ToggleRequests" then
			if not CanTrade(player) then return end
			if not PlayerSettings[player] then PlayerSettings[player] = {} end
			PlayerSettings[player].RequestsEnabled = data

		elseif action == "CreateLobby" then
			if not CanTrade(player) then return end
			local lfStr = data.LF or "Any / Offers"
			local offStr = data.Offering or "Any / Open"
			if string.len(lfStr) > 60 then lfStr = string.sub(lfStr, 1, 60) .. "..." end
			if string.len(offStr) > 60 then offStr = string.sub(offStr, 1, 60) .. "..." end

			OpenLobbies[player] = { LF = lfStr, Offering = offStr }
			TradeUpdate:FireClient(player, "LobbyStatus", {IsHosting = true})
			UpdateAllBrowsers()

		elseif action == "CancelLobby" then
			if OpenLobbies[player] then
				OpenLobbies[player] = nil
				TradeUpdate:FireClient(player, "LobbyStatus", {IsHosting = false})
				UpdateAllBrowsers()
			end

		elseif action == "JoinLobby" then
			if not CanTrade(player) then return end
			local targetHost = nil
			for host, _ in pairs(OpenLobbies) do if host.UserId == data then targetHost = host; break end end
			if targetHost and targetHost ~= player then
				StartTrade(targetHost, player)
			end

		elseif action == "SendRequest" then
			if not CanTrade(player) then return end
			local targetPlayer = FindPlayerByName(data)
			if not targetPlayer or targetPlayer == player then return end

			if not CanTrade(targetPlayer) then
				NotificationEvent:FireClient(player, "<font color='#FF5555'>" .. targetPlayer.Name .. " must reach Prestige 1 to unlock trading!</font>")
				return
			end

			if PlayerSettings[targetPlayer] and PlayerSettings[targetPlayer].RequestsEnabled == false then
				NotificationEvent:FireClient(player, "<font color='#FF5555'>That player is not accepting trade requests right now.</font>")
				return
			end

			if not IncomingRequests[targetPlayer] then IncomingRequests[targetPlayer] = {} end
			IncomingRequests[targetPlayer][player] = true

			NotificationEvent:FireClient(player, "<font color='#55FF55'>Trade request sent to " .. targetPlayer.Name .. "!</font>")
			TradeUpdate:FireClient(targetPlayer, "TradeAlert", player.Name)
			TradeUpdate:FireClient(targetPlayer, "BrowserUpdate", GetBrowserDataForPlayer(targetPlayer))

		elseif action == "AcceptRequest" then
			if not CanTrade(player) then return end
			local targetSender = nil
			for sender, _ in pairs(IncomingRequests[player] or {}) do if sender.UserId == data then targetSender = sender; break end end
			if targetSender then StartTrade(player, targetSender) end

		elseif action == "DeclineRequest" then
			if IncomingRequests[player] then
				local targetSender = nil
				for sender, _ in pairs(IncomingRequests[player]) do if sender.UserId == data then targetSender = sender; break end end
				if targetSender then
					IncomingRequests[player][targetSender] = nil
					TradeUpdate:FireClient(player, "BrowserUpdate", GetBrowserDataForPlayer(player))
				end
			end
		end

	else
		if session.IsExecuting then return end

		local myOffer = (session.P1 == player) and session.P1Offer or session.P2Offer
		local oppOffer = (session.P1 == player) and session.P2Offer or session.P1Offer

		local function UnlockTrade()
			session.P1Offer.Locked = false; session.P1Offer.Confirmed = false
			session.P2Offer.Locked = false; session.P2Offer.Confirmed = false
		end

		if action == "CancelTrade" then
			EndTrade(session, "<font color='#FF5555'>"..player.Name.." cancelled the trade.</font>")

		elseif action == "AddStand" then
			if myOffer.Locked or myOffer.Confirmed then return end
			if myOffer.Stand then return end 

			local slot = data
			local sName, sTrait = "None", "None"

			local fS1, fS2, fT1, fT2 = "None", "None", "None", "None"

			if slot == "Active" then
				sName = player:GetAttribute("Stand") or "None"
				sTrait = player:GetAttribute("StandTrait") or "None"
				if sName == "Fused Stand" then
					fS1 = player:GetAttribute("Active_FusedStand1") or "None"; fS2 = player:GetAttribute("Active_FusedStand2") or "None"
					fT1 = player:GetAttribute("Active_FusedTrait1") or "None"; fT2 = player:GetAttribute("Active_FusedTrait2") or "None"
				end
			elseif slot == "Slot1" then
				sName = player:GetAttribute("StoredStand1") or "None"
				sTrait = player:GetAttribute("StoredStand1_Trait") or "None"
				if sName == "Fused Stand" then
					fS1 = player:GetAttribute("StoredStand1_FusedStand1") or "None"; fS2 = player:GetAttribute("StoredStand1_FusedStand2") or "None"
					fT1 = player:GetAttribute("StoredStand1_FusedTrait1") or "None"; fT2 = player:GetAttribute("StoredStand1_FusedTrait2") or "None"
				end
			elseif slot == "Slot2" then
				sName = player:GetAttribute("StoredStand2") or "None"
				sTrait = player:GetAttribute("StoredStand2_Trait") or "None"
				if sName == "Fused Stand" then
					fS1 = player:GetAttribute("StoredStand2_FusedStand1") or "None"; fS2 = player:GetAttribute("StoredStand2_FusedStand2") or "None"
					fT1 = player:GetAttribute("StoredStand2_FusedTrait1") or "None"; fT2 = player:GetAttribute("StoredStand2_FusedTrait2") or "None"
				end
			elseif slot == "Slot3" then
				sName = player:GetAttribute("StoredStand3") or "None"
				sTrait = player:GetAttribute("StoredStand3_Trait") or "None"
				if sName == "Fused Stand" then
					fS1 = player:GetAttribute("StoredStand3_FusedStand1") or "None"; fS2 = player:GetAttribute("StoredStand3_FusedStand2") or "None"
					fT1 = player:GetAttribute("StoredStand3_FusedTrait1") or "None"; fT2 = player:GetAttribute("StoredStand3_FusedTrait2") or "None"
				end
			elseif slot == "Slot4" then
				sName = player:GetAttribute("StoredStand4") or "None"
				sTrait = player:GetAttribute("StoredStand4_Trait") or "None"
				if sName == "Fused Stand" then
					fS1 = player:GetAttribute("StoredStand4_FusedStand1") or "None"; fS2 = player:GetAttribute("StoredStand4_FusedStand2") or "None"
					fT1 = player:GetAttribute("StoredStand4_FusedTrait1") or "None"; fT2 = player:GetAttribute("StoredStand4_FusedTrait2") or "None"
				end
			elseif slot == "Slot5" then
				sName = player:GetAttribute("StoredStand5") or "None"
				sTrait = player:GetAttribute("StoredStand5_Trait") or "None"
				if sName == "Fused Stand" then
					fS1 = player:GetAttribute("StoredStand5_FusedStand1") or "None"; fS2 = player:GetAttribute("StoredStand5_FusedStand2") or "None"
					fT1 = player:GetAttribute("StoredStand5_FusedTrait1") or "None"; fT2 = player:GetAttribute("StoredStand5_FusedTrait2") or "None"
				end
			elseif slot == "SlotVIP" then
				sName = player:GetAttribute("StoredStandVIP") or "None"
				sTrait = player:GetAttribute("StoredStandVIP_Trait") or "None"
				if sName == "Fused Stand" then
					fS1 = player:GetAttribute("StoredStandVIP_FusedStand1") or "None"; fS2 = player:GetAttribute("StoredStandVIP_FusedStand2") or "None"
					fT1 = player:GetAttribute("StoredStandVIP_FusedTrait1") or "None"; fT2 = player:GetAttribute("StoredStandVIP_FusedTrait2") or "None"
				end
			end

			if sName ~= "None" then
				myOffer.Stand = { Slot = slot, Name = sName, Trait = sTrait, FusedS1 = fS1, FusedS2 = fS2, FusedT1 = fT1, FusedT2 = fT2 }
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "RemoveStand" then
			if myOffer.Locked or myOffer.Confirmed then return end
			if myOffer.Stand then
				myOffer.Stand = nil
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "AddStyle" then
			if myOffer.Locked or myOffer.Confirmed then return end
			if myOffer.Style then return end 

			local slot = data
			local sName = "None"

			if slot == "Active" then sName = player:GetAttribute("FightingStyle") or "None"
			elseif slot == "Slot1" then sName = player:GetAttribute("StoredStyle1") or "None"
			elseif slot == "Slot2" then sName = player:GetAttribute("StoredStyle2") or "None"
			elseif slot == "Slot3" then sName = player:GetAttribute("StoredStyle3") or "None" 
			elseif slot == "SlotVIP" then sName = player:GetAttribute("StoredStyleVIP") or "None" end

			if sName ~= "None" then
				myOffer.Style = { Slot = slot, Name = sName }
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "RemoveStyle" then
			if myOffer.Locked or myOffer.Confirmed then return end
			if myOffer.Style then
				myOffer.Style = nil
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "AddItem" then
			if myOffer.Locked or myOffer.Confirmed then return end
			local itemName = tostring(data)

			local opp = (session.P1 == player) and session.P2 or session.P1
			if IsRestrictedPass(itemName) then
				if player:GetAttribute("PaidItemTradingAllowed") == false or opp:GetAttribute("PaidItemTradingAllowed") == false then
					NotificationEvent:FireClient(player, "<font color='#FF5555'>Premium passes cannot be traded due to region compliance!</font>")
					return
				end
			end

			local countInInv = player:GetAttribute(itemName:gsub("[^%w]", "") .. "Count") or 0
			local countInOffer = myOffer.Items[itemName] or 0

			local isEquipped = false
			local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]
			if itemData and itemData.Slot then
				if player:GetAttribute("Equipped" .. itemData.Slot) == itemName then
					isEquipped = true
				end
			end

			local availableToTrade = isEquipped and (countInInv - 1) or countInInv

			if availableToTrade > countInOffer then
				myOffer.Items[itemName] = countInOffer + 1
				UnlockTrade()
				SyncTrade(session)
			else
				NotificationEvent:FireClient(player, "<font color='#FF5555'>You cannot trade equipped items. Unequip it first!</font>")
			end

		elseif action == "RemoveItem" then
			if myOffer.Locked or myOffer.Confirmed then return end
			local itemName = tostring(data)
			if myOffer.Items[itemName] then
				myOffer.Items[itemName] -= 1
				if myOffer.Items[itemName] <= 0 then myOffer.Items[itemName] = nil end
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "SetYen" then
			if myOffer.Locked or myOffer.Confirmed then return end
			local amt = tonumber(data)
			if amt and amt >= 0 then
				local maxYen = player.leaderstats.Yen.Value
				myOffer.Yen = math.clamp(math.floor(amt), 0, maxYen)
				UnlockTrade()
				SyncTrade(session)
			end

		elseif action == "ToggleLock" then
			if myOffer.Confirmed then return end 

			if not myOffer.Locked then
				myOffer.Locked = true
			elseif myOffer.Locked and oppOffer.Locked then
				myOffer.Confirmed = true
			else
				myOffer.Locked = false
			end

			SyncTrade(session)

			if session.P1Offer.Confirmed and session.P2Offer.Confirmed then
				ExecuteTrade(session)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if OpenLobbies[player] then OpenLobbies[player] = nil end

	IncomingRequests[player] = nil
	for target, reqs in pairs(IncomingRequests) do
		if reqs[player] then reqs[player] = nil end
	end

	PlayerSettings[player] = nil

	local match = ActiveTrades[player]
	if match and not match.IsExecuting then
		EndTrade(match, "<font color='#FF5555'>Trade cancelled: Partner disconnected.</font>")
	end

	UpdateAllBrowsers()
end)