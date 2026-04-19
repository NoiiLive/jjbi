-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local ItemData = require(ReplicatedStorage:WaitForChild("ItemData"))
local Network = ReplicatedStorage:WaitForChild("Network")
local MarketplaceService = game:GetService("MarketplaceService")

local AdminLogger = Network:FindFirstChild("AdminLogger")
if not AdminLogger then
	AdminLogger = Instance.new("BindableEvent")
	AdminLogger.Name = "AdminLogger"
	AdminLogger.Parent = Network
end

local UseItemRemote = Network:FindFirstChild("UseItem") or Instance.new("RemoteEvent", Network)
UseItemRemote.Name = "UseItem"

local UnequipItemRemote = Network:FindFirstChild("UnequipItem") or Instance.new("RemoteEvent", Network)
UnequipItemRemote.Name = "UnequipItem"

local ToggleLockRemote = Network:FindFirstChild("ToggleLock") or Instance.new("RemoteEvent", Network)
ToggleLockRemote.Name = "ToggleLock"

local NotificationEvent = Network:FindFirstChild("NotificationEvent") or Instance.new("RemoteEvent", Network)
NotificationEvent.Name = "NotificationEvent"

local OpenFusionUIRemote = Network:FindFirstChild("OpenFusionUI") or Instance.new("RemoteEvent", Network)
OpenFusionUIRemote.Name = "OpenFusionUI"

local InventoryAction = Network:FindFirstChild("InventoryAction") or Instance.new("RemoteEvent", Network)
InventoryAction.Name = "InventoryAction"

local ToggleAutoStatRemote = Network:FindFirstChild("ToggleAutoStat") or Instance.new("RemoteEvent", Network)
ToggleAutoStatRemote.Name = "ToggleAutoStat"

ToggleAutoStatRemote.OnServerEvent:Connect(function(player, target, amount)
	if not player:GetAttribute("HasAutoStatPass") then
		MarketplaceService:PromptGamePassPurchase(player, 1785974455)
		return
	end

	if type(amount) == "number" and amount > 0 then
		player:SetAttribute("AutoStatAmount", math.floor(amount))
	end

	if target == "Player" then
		player:SetAttribute("AutoStatPlayer", not player:GetAttribute("AutoStatPlayer"))
	elseif target == "Stand" then
		player:SetAttribute("AutoStatStand", not player:GetAttribute("AutoStatStand"))
	end
end)

UnequipItemRemote.OnServerEvent:Connect(function(player, slot)
	if slot == "Weapon" or slot == "Accessory" or slot == "Head" or slot == "Torso" or slot == "Legs" then
		local currentEq = player:GetAttribute("Equipped" .. slot)
		if currentEq and currentEq ~= "None" then
			player:SetAttribute("Equipped" .. slot, "None")
			local notif = Network:FindFirstChild("NotificationEvent")
			if notif then notif:FireClient(player, "<font color='#FF5555'>Unequipped " .. currentEq .. "!</font>") end
		end
	end
end)

ToggleLockRemote.OnServerEvent:Connect(function(player, lockType, extraData)
	if lockType == "Stand" then
		player:SetAttribute("StandLocked", not player:GetAttribute("StandLocked"))
	elseif lockType == "Style" then
		player:SetAttribute("StyleLocked", not player:GetAttribute("StyleLocked"))
	elseif lockType == "Item" and extraData then
		local itemName = tostring(extraData)
		local lockedItems = player:GetAttribute("LockedItems") or ""
		local itemsList = string.split(lockedItems, ",")

		local foundIndex = table.find(itemsList, itemName)
		if foundIndex then
			table.remove(itemsList, foundIndex)
		else
			table.insert(itemsList, itemName)
		end

		local cleanList = {}
		for _, v in ipairs(itemsList) do if v ~= "" then table.insert(cleanList, v) end end
		player:SetAttribute("LockedItems", table.concat(cleanList, ","))
	end
end)

InventoryAction.OnServerEvent:Connect(function(player, action, data)
	if action == "ClaimUnfuse" then
		local pName = player:GetAttribute("PendingUnfuse_Stand1")
		local pTrait = player:GetAttribute("PendingUnfuse_Trait1")

		if not pName or pName == "None" then return end

		player:SetAttribute("PendingUnfuse_Stand1", "None")
		player:SetAttribute("PendingUnfuse_Trait1", "None")

		local slot = data
		local pendingFormatted = pName .. ((pTrait ~= "None") and (" ["..pTrait.."]") or "")

		if slot == "Deny" or slot == "Trash" then
			AdminLogger:Fire("Replacement", {
				Player = player.Name, Context = "Discard Unfuse", OldItem = pendingFormatted, NewItem = "None", Slot = "Trash"
			})
			NotificationEvent:FireClient(player, "<font color='#FF5555'>You discarded " .. pName .. ".</font>")
		else
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

			AdminLogger:Fire("Replacement", {
				Player = player.Name, Context = "Unfuse Stand", OldItem = oldStand, NewItem = pendingFormatted, Slot = slot
			})

			local prestige = player:FindFirstChild("leaderstats") and player.leaderstats.Prestige.Value or 0
			local stats = StandData.Stands[pName] and StandData.Stands[pName].Stats

			if slot == "Active" then
				player:SetAttribute("Stand", pName)
				player:SetAttribute("StandTrait", pTrait)
				player:SetAttribute("Active_FusedStand1", "None")
				player:SetAttribute("Active_FusedStand2", "None")
				player:SetAttribute("Active_FusedTrait1", "None")
				player:SetAttribute("Active_FusedTrait2", "None")
				if stats then
					for sName, sRank in pairs(stats) do
						local rankVal = GameData.StandRanks[sRank] or 0
						player:SetAttribute("Stand_" .. sName .. "_Val", rankVal + (prestige * 5))
					end
				end
			else
				local num = slot:gsub("Slot", "")
				player:SetAttribute("StoredStand"..num, pName)
				player:SetAttribute("StoredStand"..num.."_Trait", pTrait)
				player:SetAttribute("StoredStand"..num.."_FusedStand1", "None")
				player:SetAttribute("StoredStand"..num.."_FusedStand2", "None")
				player:SetAttribute("StoredStand"..num.."_FusedTrait1", "None")
				player:SetAttribute("StoredStand"..num.."_FusedTrait2", "None")
			end
		end

		local pName2 = player:GetAttribute("PendingUnfuse_Stand2")
		local pTrait2 = player:GetAttribute("PendingUnfuse_Trait2")

		if pName2 and pName2 ~= "None" then
			player:SetAttribute("PendingUnfuse_Stand2", "None")
			player:SetAttribute("PendingUnfuse_Trait2", "None")

			player:SetAttribute("PendingUnfuse_Stand1", pName2)
			player:SetAttribute("PendingUnfuse_Trait1", pTrait2)

			task.delay(0.5, function()
				local ShopUpdate = Network:FindFirstChild("ShopUpdate")
				if ShopUpdate then
					ShopUpdate:FireClient(player, "ShowStandClaim", {
						RemoteName = "InventoryAction",
						StandAction = "ClaimUnfuse",
						DenyText = "Trash Stand\n[Discard Permanently]",
						StandName = pName2,
						Active = player:GetAttribute("Stand") or "None",
						Slot1 = player:GetAttribute("StoredStand1") or "None",
						Slot2 = player:GetAttribute("StoredStand2") or "None",
						Slot3 = player:GetAttribute("StoredStand3") or "None",
						Slot4 = player:GetAttribute("StoredStand4") or "None",
						Slot5 = player:GetAttribute("StoredStand5") or "None",
						SlotVIP = player:GetAttribute("StoredStandVIP") or "None"
					})
					NotificationEvent:FireClient(player, "<font color='#A020F0'>Now choose a slot for your second Stand!</font>")
				end
			end)
		else
			if slot ~= "Deny" and slot ~= "Trash" then
				NotificationEvent:FireClient(player, "<font color='#A020F0'>Stand safely stored!</font>")
			end
		end
	end
end)

local function GetPlayerBoosts(player)
	local boosts = { Luck = 0 }

	if player:GetAttribute("IsSupporter") then boosts.Luck += 1 end

	local elo = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Elo") and player.leaderstats.Elo.Value or 1000
	if elo >= 3000 then boosts.Luck += 1 end

	local gLuck = player:GetAttribute("GangLuckBoost") or 1.0
	if gLuck > 1.0 then boosts.Luck += 1 end 

	local indexBoosts = GameData.GetIndexBoosts(player)
	boosts.Luck += indexBoosts.Luck

	return boosts
end

local AutoRollRemote = Network:FindFirstChild("AutoRoll") or Instance.new("RemoteEvent", Network)
AutoRollRemote.Name = "AutoRoll"

AutoRollRemote.OnServerEvent:Connect(function(player, rollType, targetStand, targetTrait)
	if player:GetAttribute("IsAutoRolling") then return end
	player:SetAttribute("IsAutoRolling", true)

	if rollType == "Arrow" or rollType == "Corpse" then rollType = "Stand" end
	if rollType == "Roka" then rollType = "Trait" end

	local itemReq = ""
	local poolType = "Arrow"

	if rollType == "Stand" then
		if targetStand == "Any" then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Please select a specific Stand to roll for!</font>")
			player:SetAttribute("IsAutoRolling", false)
			return
		end

		local sData = StandData.Stands[targetStand]
		if not sData then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Invalid Stand selected!</font>")
			player:SetAttribute("IsAutoRolling", false)
			return
		end

		if sData.Rarity == "Evolution" or sData.Rarity == "Unique" or sData.Rarity == "Mythical" then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>" .. targetStand .. " cannot be rolled from items!</font>")
			player:SetAttribute("IsAutoRolling", false)
			return
		end

		if sData.Pool == "Corpse" then
			itemReq = "Saint's Corpse Part"
			poolType = "Corpse"
		else
			itemReq = "Stand Arrow"
			poolType = "Arrow"
		end

	elseif rollType == "Trait" then
		if targetTrait == "Any" then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Please select a specific Trait to roll for!</font>")
			player:SetAttribute("IsAutoRolling", false)
			return
		end
		itemReq = "Rokakaka"
	else
		player:SetAttribute("IsAutoRolling", false)
		return
	end

	local attr = itemReq:gsub("[^%w]", "") .. "Count"
	local count = player:GetAttribute(attr) or 0

	if count <= 0 then 
		NotificationEvent:FireClient(player, "<font color='#FF5555'>You do not have any " .. itemReq .. "s!</font>")
		player:SetAttribute("IsAutoRolling", false)
		return 
	end

	local newStand = player:GetAttribute("Stand") or "None"
	local newTrait = player:GetAttribute("StandTrait") or "None"

	if player:GetAttribute("StandLocked") then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>Your Stand is locked! Unlock it before Auto-Rolling.</font>")
		player:SetAttribute("IsAutoRolling", false)
		return
	end

	if rollType == "Trait" then
		if newStand == "None" then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>You don't have a Stand to reroll!</font>")
			player:SetAttribute("IsAutoRolling", false)
			return
		elseif newStand == "Fused Stand" then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>You cannot Auto-Roll traits on a Fused Stand!</font>")
			player:SetAttribute("IsAutoRolling", false)
			return
		end
	end

	local pBoosts = GetPlayerBoosts(player)
	local sPity = player:GetAttribute("StandPity") or 0
	local tPity = player:GetAttribute("TraitPity") or 0
	local rollsDone = 0
	local hit = false

	while count > 0 do
		count -= 1
		rollsDone += 1

		if rollType == "Stand" then
			newStand = StandData.RollStand(pBoosts.Luck, sPity, poolType)
			newTrait = StandData.RollTrait(pBoosts.Luck, tPity)
		elseif rollType == "Trait" then
			newTrait = StandData.RollTrait(pBoosts.Luck, tPity)
		end

		if StandData.Stands[newStand] and StandData.Stands[newStand].Rarity == "Legendary" then sPity = 0 else sPity += 1 end
		if StandData.Traits[newTrait] and (StandData.Traits[newTrait].Rarity == "Mythical" or StandData.Traits[newTrait].Rarity == "Legendary") then tPity = 0 else tPity += 1 end

		local isTarget = (rollType == "Stand" and newStand == targetStand) or (rollType == "Trait" and newTrait == targetTrait)

		if isTarget then 
			hit = true; break 
		else
			local stashStand = false

			if rollType == "Stand" then
				local sR = StandData.Stands[newStand] and StandData.Stands[newStand].Rarity or "Common"
				if sR == "Legendary" or sR == "Mythical" or sR == "Evolution" or sR == "Unique" then stashStand = true end
			end

			if stashStand then
				local pLeaderstats = player:FindFirstChild("leaderstats")
				local prestige = pLeaderstats and pLeaderstats:FindFirstChild("Prestige") and pLeaderstats.Prestige.Value or 0

				local emptySlot = nil
				local slotsToCheck = {"1", "2", "3", "4", "5", "VIP"}

				for _, slotID in ipairs(slotsToCheck) do
					local canUse = true
					if slotID == "2" and not player:GetAttribute("HasStandSlot2") then canUse = false end
					if slotID == "3" and not player:GetAttribute("HasStandSlot3") then canUse = false end
					if slotID == "4" and prestige < 15 then canUse = false end
					if slotID == "5" and prestige < 30 then canUse = false end
					if slotID == "VIP" and not player:GetAttribute("IsVIP") then canUse = false end

					if canUse then
						local currentInSlot = player:GetAttribute("StoredStand"..slotID) or "None"
						if currentInSlot == "None" then
							emptySlot = "StoredStand"..slotID
							break
						end
					end
				end

				if emptySlot then
					player:SetAttribute(emptySlot, newStand)
					player:SetAttribute(emptySlot .. "_Trait", newTrait)

					player:SetAttribute(emptySlot .. "_FusedStand1", "None")
					player:SetAttribute(emptySlot .. "_FusedStand2", "None")
					player:SetAttribute(emptySlot .. "_FusedTrait1", "None")
					player:SetAttribute(emptySlot .. "_FusedTrait2", "None")

					local sRarity = StandData.Stands[newStand] and StandData.Stands[newStand].Rarity or "Common"
					if sRarity == "Mythical" or sRarity == "Evolution" or sRarity == "Unique" then
						local trStr = (newTrait and newTrait ~= "None") and (" ["..newTrait.."]") or ""
						AdminLogger:Fire("Replacement", {
							Player = player.Name,
							Context = "Auto-Roll Stash",
							OldItem = "None",
							NewItem = newStand .. trStr,
							Slot = emptySlot
						})
					end

					local rarityLevel = "Legendary"
					if sRarity == "Mythical" or sRarity == "Unique" or sRarity == "Evolution" then rarityLevel = sRarity end

					NotificationEvent:FireClient(player, "<b><font color='#FFD700'>Auto-Roll caught a " .. rarityLevel .. " Stand ["..newStand.."]! Automatically Stashed to an empty Stand Storage slot!</font></b>")
				end
			end
		end

		if rollsDone % 100 == 0 then task.wait() end
	end

	player:SetAttribute(attr, count)
	player:SetAttribute("Stand", newStand)
	player:SetAttribute("StandTrait", newTrait)
	player:SetAttribute("StandPity", sPity)
	player:SetAttribute("TraitPity", tPity)

	if newStand ~= "None" and StandData.Stands[newStand] then
		for statName, rank in pairs(StandData.Stands[newStand].Stats) do player:SetAttribute("Stand_"..statName, rank) end
	end

	local traitTag = newTrait ~= "None" and " ("..newTrait..")" or ""
	if hit then
		NotificationEvent:FireClient(player, "<font color='#55FF55'>Auto-Roll successful! Used " .. rollsDone .. "x " .. itemReq .. ".\nGot: " .. newStand .. traitTag .. "</font>")
	else
		NotificationEvent:FireClient(player, "<font color='#FF5555'>Ran out of " .. itemReq .. "s! Used " .. rollsDone .. ".\nEnded with: " .. newStand .. traitTag .. "</font>")
	end

	player:SetAttribute("IsAutoRolling", false)
end)

local function RollModifiers(count)
	if count <= 0 then return "None" end
	local available = {}
	for modName, _ in pairs(GameData.UniverseModifiers) do
		if modName ~= "None" then table.insert(available, modName) end
	end
	local rolled = {}
	for i = 1, count do
		if #available == 0 then break end
		local idx = math.random(1, #available)
		table.insert(rolled, available[idx])
		table.remove(available, idx)
	end
	return table.concat(rolled, ",")
end

local function HandleGiftboxDrop(player, targetRarity)
	local pool = {}
	for name, data in pairs(ItemData.Equipment) do 
		if data.Rarity == targetRarity then 
			table.insert(pool, name) 
		end 
	end
	for name, data in pairs(ItemData.Consumables) do 
		if data.Rarity == targetRarity then 
			table.insert(pool, name) 
		end 
	end

	if #pool > 0 then
		local itemName = pool[math.random(#pool)]
		local itemData = ItemData.Equipment[itemName] or ItemData.Consumables[itemName]

		if player:GetAttribute("AutoSell_" .. targetRarity) then
			local sellVal = itemData and (itemData.SellPrice or math.floor((itemData.Cost or 50) / 2)) or 25
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats and leaderstats:FindFirstChild("Yen") then
				leaderstats.Yen.Value += sellVal
			end
			return "You opened the box and found a " .. itemName .. ", but it was Auto-Sold for ¥" .. sellVal .. "!"
		else
			local currentInv = GameData.GetInventoryCount(player)
			local maxInv = GameData.GetMaxInventory(player)
			local attr = itemName:gsub("[^%w]", "") .. "Count"
			player:SetAttribute(attr, (player:GetAttribute(attr) or 0) + 1)
			return "You opened the box and received a " .. itemName .. "!"
		end
	end
	return "The box was empty..."
end

local function HandleRollResult(player, newStand, newTrait, rollType, itemReq, oldStandFormatted, oldStandRarity)
	local sRarity = StandData.Stands[newStand] and StandData.Stands[newStand].Rarity or "Common"

	local stashStand = false

	if rollType == "Stand" then
		if sRarity == "Legendary" or sRarity == "Mythical" or sRarity == "Evolution" or sRarity == "Unique" then stashStand = true end
	end

	local stashedSlot = nil
	if stashStand then
		local pLeaderstats = player:FindFirstChild("leaderstats")
		local prestige = pLeaderstats and pLeaderstats:FindFirstChild("Prestige") and pLeaderstats.Prestige.Value or 0

		local slotsToCheck = {"1", "2", "3", "4", "5", "VIP"}
		for _, slotID in ipairs(slotsToCheck) do
			local canUse = true
			if slotID == "2" and not player:GetAttribute("HasStandSlot2") then canUse = false end
			if slotID == "3" and not player:GetAttribute("HasStandSlot3") then canUse = false end
			if slotID == "4" and prestige < 15 then canUse = false end
			if slotID == "5" and prestige < 30 then canUse = false end
			if slotID == "VIP" and not player:GetAttribute("IsVIP") then canUse = false end

			if canUse then
				local currentInSlot = player:GetAttribute("StoredStand"..slotID) or "None"
				if currentInSlot == "None" then
					stashedSlot = "StoredStand"..slotID
					break
				end
			end
		end
	end

	if stashedSlot then
		player:SetAttribute(stashedSlot, newStand)
		player:SetAttribute(stashedSlot .. "_Trait", newTrait)

		player:SetAttribute(stashedSlot .. "_FusedStand1", "None")
		player:SetAttribute(stashedSlot .. "_FusedStand2", "None")
		player:SetAttribute(stashedSlot .. "_FusedTrait1", "None")
		player:SetAttribute(stashedSlot .. "_FusedTrait2", "None")

		if rollType == "Stand" and (sRarity == "Mythical" or sRarity == "Evolution" or sRarity == "Unique") then
			local trStr = (newTrait and newTrait ~= "None") and (" ["..newTrait.."]") or ""
			AdminLogger:Fire("Replacement", {
				Player = player.Name,
				Context = "Manual Roll Stash",
				OldItem = "None",
				NewItem = newStand .. trStr,
				Slot = stashedSlot
			})
		end

		local rarityLevel = "Legendary"
		if sRarity == "Mythical" or sRarity == "Unique" or sRarity == "Evolution" then rarityLevel = sRarity end

		return true, "<b><font color='#FFD700'>You manually rolled a " .. rarityLevel .. " Stand [" .. newStand .. "]! Automatically Stashed to an empty Stand Storage slot!</font></b>"
	else
		local logReplacement = false
		if rollType == "Stand" then
			if (sRarity == "Mythical" or sRarity == "Evolution" or sRarity == "Unique") then logReplacement = true end
			if (oldStandRarity == "Mythical" or oldStandRarity == "Evolution" or oldStandRarity == "Unique") then logReplacement = true end
		end

		if logReplacement then
			local traitStr = (newTrait and newTrait ~= "None") and (" [" .. newTrait .. "]") or ""
			local logContext = (itemReq == "Saint's Corpse Part") and "Corpse Part Roll" or "Stand Arrow Roll"
			AdminLogger:Fire("Replacement", {
				Player = player.Name,
				Context = logContext,
				OldItem = oldStandFormatted,
				NewItem = newStand .. traitStr,
				Slot = "Active"
			})
		end

		player:SetAttribute("StandTrait", newTrait)
		if rollType == "Stand" then
			player:SetAttribute("Stand", newStand)
			local stats = StandData.Stands[newStand] and StandData.Stands[newStand].Stats
			if stats then
				for statName, rank in pairs(stats) do player:SetAttribute("Stand_"..statName, rank) end
			end
		end

		local traitTag = newTrait ~= "None" and (" ("..newTrait..")") or ""
		local msg = ""
		if rollType == "Stand" then
			if itemReq == "Saint's Corpse Part" then
				msg = "The corpse part fuses with you! Awakened Stand: " .. newStand .. traitTag .. "!"
			else
				msg = "You were pierced by the arrow! Awakened Stand: " .. newStand .. traitTag .. "!"
			end
		else
			local traitColor = StandData.Traits[newTrait] and StandData.Traits[newTrait].Color or "#FFFFFF"
			local traitDisplay = newTrait ~= "None" and "<font color='"..traitColor.."'>["..newTrait.."]</font>" or "None"
			msg = "You consumed the Rokakaka! Your Stand's trait is now: " .. traitDisplay .. "!"
		end
		return false, msg
	end
end

UseItemRemote.OnServerEvent:Connect(function(player, itemName, targetStand, targetTrait)
	local attrName = itemName:gsub("[^%w]", "") .. "Count"
	local itemCount = player:GetAttribute(attrName) or 0

	if itemCount > 0 then
		local lockedItems = player:GetAttribute("LockedItems") or ""
		local itemsList = string.split(lockedItems, ",")
		if table.find(itemsList, itemName) then
			if not ItemData.Equipment[itemName] then
				NotificationEvent:FireClient(player, "<font color='#FF5555'>Cannot use a locked item!</font>")
				return
			end
		end

		local message = ""
		local prestige = player.leaderstats.Prestige.Value
		local statCap = GameData.GetStatCap(prestige)
		local myStand = player:GetAttribute("Stand") or "None"
		local myTrait = player:GetAttribute("StandTrait") or "None"
		local itemConsumed = true

		if ItemData.Equipment[itemName] then
			local equipSlot = ItemData.Equipment[itemName].Slot
			player:SetAttribute("Equipped" .. equipSlot, itemName)
			message = "Equipped " .. itemName .. " as " .. equipSlot .. "!"
			NotificationEvent:FireClient(player, "<font color='#55FF55'>" .. message .. "</font>")
			return
		end

		local isStandItem = 
			(itemName == "Stand Arrow" or itemName == "Saint's Corpse Part" or itemName == "Stand Disc" or itemName == "Requiem Arrow" 
				or itemName == "Dio's Diary" or itemName == "Saint's Left Arm" or itemName == "Saint's Right Eye" or itemName == "Saint's Pelvis" 
				or itemName == "Saint's Heart" or itemName == "Saint's Spine" or itemName == "Strange Arrow" or itemName == "Green Baby" 
				or itemName == "Rokakaka" or itemName == "Rokakaka Branch" or itemName == "Chiikawa Mascot" or itemName == "Kakyoin's Egg"
				or itemName == "Scratch-Off Ticket" or itemName == "Inversion Medicine"
				or (string.find(itemName, "Disc") and itemName ~= "Memory Disc" and itemName ~= "Heavenly Stand Disc")
			)

		local isStyleItem = 
			(itemName == "Memory Disc" or itemName == "Boxing Manual" or itemName == "Vampire Mask" or itemName == "Hamon Manual" 
				or itemName == "Cyborg Blueprints" or itemName == "Ancient Mask" or itemName == "Steel Ball" or itemName == "Perfect Aja Mask" 
				or itemName == "Golden Spin Scroll" or itemName == "Rokakaka Fruit" or itemName == "Limitless Manual" or itemName == "Cursed Finger"
				or itemName == "Parasitic Egg"
			)

		if isStandItem and player:GetAttribute("StandLocked") then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Your Stand is locked! Unlock it to use this item.</font>")
			return
		end

		if isStyleItem and player:GetAttribute("StyleLocked") then
			NotificationEvent:FireClient(player, "<font color='#FF5555'>Your Fighting Style is locked! Unlock it to use this item.</font>")
			return
		end

		if targetStand and targetStand ~= "Any" and targetStand ~= "" and myStand == targetStand then
			if itemName == "Stand Arrow" or itemName == "Saint's Corpse Part" then
				NotificationEvent:FireClient(player, "<font color='#FF5555'>You already have your target Stand! (" .. targetStand .. ")</font>")
				return
			end
		end

		if targetTrait and targetTrait ~= "Any" and targetTrait ~= "" and myTrait == targetTrait then
			if itemName == "Stand Arrow" or itemName == "Saint's Corpse Part" or itemName == "Rokakaka" then
				NotificationEvent:FireClient(player, "<font color='#FF5555'>You already have your target Trait! (" .. targetTrait .. ")</font>")
				return
			end
		end

		local oldStandFormatted = myStand
		local oldStandRarity = "None"

		if oldStandFormatted == "Fused Stand" then
			local f1 = player:GetAttribute("Active_FusedStand1") or "None"
			local f2 = player:GetAttribute("Active_FusedStand2") or "None"
			local t1 = player:GetAttribute("Active_FusedTrait1") or "None"
			local t2 = player:GetAttribute("Active_FusedTrait2") or "None"
			local t1Str = (t1 ~= "None") and (" ["..t1.."]") or ""
			local t2Str = (t2 ~= "None") and (" ["..t2.."]") or ""
			oldStandFormatted = "Fused Stand (" .. tostring(f1) .. t1Str .. " + " .. tostring(f2) .. t2Str .. ")"
			oldStandRarity = "Unique"
		elseif oldStandFormatted ~= "None" then
			oldStandFormatted = oldStandFormatted .. ((myTrait ~= "None") and (" ["..myTrait.."]") or "")
			oldStandRarity = StandData.Stands[myStand] and StandData.Stands[myStand].Rarity or "Common"
		end

		local function EvolveStand(newStand)
			player:SetAttribute("Stand", newStand)
			local stats = StandData.Stands[newStand].Stats
			for statName, rank in pairs(stats) do
				player:SetAttribute("Stand_"..statName, rank)
			end
		end

		if itemName == "Legendary Giftbox" then
			message = HandleGiftboxDrop(player, "Legendary")

		elseif itemName == "Mythical Giftbox" then
			message = HandleGiftboxDrop(player, "Mythical")

		elseif itemName == "Unique Giftbox" then
			message = HandleGiftboxDrop(player, "Unique")

		elseif itemName == "2x Battle Speed Pass" then
			if player:GetAttribute("Has2xBattleSpeed") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("Has2xBattleSpeed", true); message = "Unlocked 2x Battle Speed!" end
		elseif itemName == "2x Inventory Pass" then
			if player:GetAttribute("Has2xInventory") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("Has2xInventory", true); message = "Unlocked 2x Inventory Space!" end
		elseif itemName == "2x Drop Chance Pass" then
			if player:GetAttribute("Has2xDropChance") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("Has2xDropChance", true); message = "Unlocked 2x Drop Chance!" end
		elseif itemName == "Auto Training Pass" then
			if player:GetAttribute("HasAutoTraining") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasAutoTraining", true); message = "Unlocked Auto Training!" end
		elseif itemName == "Stand Storage Slot 2" then
			if player:GetAttribute("HasStandSlot2") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasStandSlot2", true); message = "Unlocked Stand Storage Slot 2!" end
		elseif itemName == "Stand Storage Slot 3" then
			if player:GetAttribute("HasStandSlot3") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasStandSlot3", true); message = "Unlocked Stand Storage Slot 3!" end
		elseif itemName == "Style Storage Slot 2" then
			if player:GetAttribute("HasStyleSlot2") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasStyleSlot2", true); message = "Unlocked Style Storage Slot 2!" end
		elseif itemName == "Style Storage Slot 3" then
			if player:GetAttribute("HasStyleSlot3") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasStyleSlot3", true); message = "Unlocked Style Storage Slot 3!" end
		elseif itemName == "Auto-Roll Pass" then
			if player:GetAttribute("HasAutoRoll") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasAutoRoll", true); message = "Unlocked Auto-Roll!" end
		elseif itemName == "Custom Horse Name" then
			if player:GetAttribute("HasHorseNamePass") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasHorseNamePass", true); message = "Unlocked Custom Horse Names!" end
		elseif itemName == "VIP" then
			if player:GetAttribute("IsVIP") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("IsVIP", true); message = "Unlocked VIP!" end
		elseif itemName == "Auto-Stat Invest" then
			if player:GetAttribute("HasAutoStatPass") then message = "You already own this pass!"; itemConsumed = false
			else player:SetAttribute("HasAutoStatPass", true); message = "Unlocked Auto-Stat Invest!" end

		elseif itemName == "Stand Arrow" or itemName == "Saint's Corpse Part" then
			local pBoosts = GetPlayerBoosts(player)
			local currentStandPity = player:GetAttribute("StandPity") or 0
			local currentTraitPity = player:GetAttribute("TraitPity") or 0
			local poolType = (itemName == "Saint's Corpse Part") and "Corpse" or "Arrow"

			local newStand = StandData.RollStand(pBoosts.Luck, currentStandPity, poolType)
			local newTrait = StandData.RollTrait(pBoosts.Luck, currentTraitPity)

			local standInfo = StandData.Stands[newStand]
			if standInfo then
				if standInfo.Rarity == "Legendary" then player:SetAttribute("StandPity", 0)
				else player:SetAttribute("StandPity", currentStandPity + 1) end
			end

			local traitData = StandData.Traits[newTrait]
			if traitData and (traitData.Rarity == "Mythical" or traitData.Rarity == "Legendary") then player:SetAttribute("TraitPity", 0)
			else player:SetAttribute("TraitPity", currentTraitPity + 1) end

			local stashed, msg = HandleRollResult(player, newStand, newTrait, "Stand", itemName, oldStandFormatted, oldStandRarity)
			message = msg

		elseif itemName == "Rokakaka" then
			if myStand == "None" then
				message = "You don't have a Stand to reroll!"; itemConsumed = false
			elseif myStand == "Fused Stand" then
				message = "You cannot use a Rokakaka on a Fused Stand!"; itemConsumed = false
			else
				local pBoosts = GetPlayerBoosts(player)
				local currentTraitPity = player:GetAttribute("TraitPity") or 0
				local newTrait = StandData.RollTrait(pBoosts.Luck, currentTraitPity)

				local traitData = StandData.Traits[newTrait]
				if traitData and (traitData.Rarity == "Mythical" or traitData.Rarity == "Legendary") then player:SetAttribute("TraitPity", 0) else player:SetAttribute("TraitPity", currentTraitPity + 1) end

				local stashed, msg = HandleRollResult(player, myStand, newTrait, "Trait", itemName, oldStandFormatted, oldStandRarity)
				message = msg
			end

		elseif itemName == "Inversion Medicine" then
			if myStand ~= "Fused Stand" then
				message = "You can only use this on a Fused Stand!"
				itemConsumed = false
			else
				local fs1 = player:GetAttribute("Active_FusedStand1")
				local fs2 = player:GetAttribute("Active_FusedStand2")
				local ft1 = player:GetAttribute("Active_FusedTrait1")
				local ft2 = player:GetAttribute("Active_FusedTrait2")

				if not fs1 or fs1 == "None" or not fs2 or fs2 == "None" then
					message = "Failed to identify fusion components!"
					itemConsumed = false
				else
					player:SetAttribute("Stand", "None")
					player:SetAttribute("StandTrait", "None")
					player:SetAttribute("Active_FusedStand1", "None")
					player:SetAttribute("Active_FusedStand2", "None")
					player:SetAttribute("Active_FusedTrait1", "None")
					player:SetAttribute("Active_FusedTrait2", "None")
					for _, s in ipairs({"Power", "Speed", "Range", "Durability", "Precision", "Potential"}) do
						player:SetAttribute("Stand_" .. s, "None")
					end

					player:SetAttribute("PendingUnfuse_Stand1", fs1)
					player:SetAttribute("PendingUnfuse_Trait1", ft1)
					player:SetAttribute("PendingUnfuse_Stand2", fs2)
					player:SetAttribute("PendingUnfuse_Trait2", ft2)

					local ShopUpdate = Network:FindFirstChild("ShopUpdate")
					if ShopUpdate then
						ShopUpdate:FireClient(player, "ShowStandClaim", {
							RemoteName = "InventoryAction",
							StandAction = "ClaimUnfuse",
							DenyText = "Trash Stand\n[Discard Permanently]",
							StandName = fs1,
							Active = "None",
							Slot1 = player:GetAttribute("StoredStand1") or "None",
							Slot2 = player:GetAttribute("StoredStand2") or "None",
							Slot3 = player:GetAttribute("StoredStand3") or "None",
							Slot4 = player:GetAttribute("StoredStand4") or "None",
							Slot5 = player:GetAttribute("StoredStand5") or "None",
							SlotVIP = player:GetAttribute("StoredStandVIP") or "None"
						})
					end

					message = "The medicine violently forces your Stand to split apart! Choose a slot for your first Stand."
				end
			end

		elseif itemName == "Memory Disc" then
			if player:GetAttribute("FightingStyle") == "None" then
				message = "You don't have a Fighting Style to forget!"
				itemConsumed = false
			else
				player:SetAttribute("FightingStyle", "None")
				message = "Your memory fades. Fighting Style removed."
			end

		elseif itemName == "Stand Disc" then
			if myStand == "None" then
				message = "You don't have a Stand to extract!"
				itemConsumed = false
			else
				player:SetAttribute("Stand", "None")
				player:SetAttribute("StandTrait", "None")
				local standStatsList = {"Power", "Speed", "Range", "Durability", "Precision", "Potential"}
				for _, s in ipairs(standStatsList) do player:SetAttribute("Stand_" .. s, "None") end
				message = "Your Stand and Trait have been extracted!"
			end

		elseif itemName == "Heavenly Stand Disc" then
			if prestige >= 5 then
				local rollCount = math.floor(prestige/5)
				local newMods = RollModifiers(rollCount)
				player:SetAttribute("UniverseModifier", newMods)
				message = "A heavenly glow surrounds you. Your Universe Modifiers have been rerolled!"
			else
				message = "You must be at least Prestige 5 to have Universe Modifiers!"
				itemConsumed = false
			end

		elseif itemName == "Health Training Manual" then
			local amount = math.max(15, math.floor(15 * (prestige / 5)))
			player:SetAttribute("Health", math.min(statCap, (player:GetAttribute("Health") or 1) + amount))
			message = "You studied the manual and gained +"..amount.." Health!"
		elseif itemName == "Strength Training Manual" then
			local amount = math.max(15, math.floor(15 * (prestige / 5)))
			player:SetAttribute("Strength", math.min(statCap, (player:GetAttribute("Strength") or 1) + amount))
			message = "You studied the manual and gained +"..amount.." Strength!"
		elseif itemName == "Defense Training Manual" then
			local amount = math.max(15, math.floor(15 * (prestige / 5)))
			player:SetAttribute("Defense", math.min(statCap, (player:GetAttribute("Defense") or 1) + amount))
			message = "You studied the manual and gained +"..amount.." Defense!"
		elseif itemName == "Speed Training Manual" then
			local amount = math.max(15, math.floor(15 * (prestige / 5)))
			player:SetAttribute("Speed", math.min(statCap, (player:GetAttribute("Speed") or 1) + amount))
			message = "You studied the manual and gained +"..amount.." Speed!"
		elseif itemName == "Stamina Training Manual" then
			local amount = math.max(15, math.floor(15 * (prestige / 5)))
			player:SetAttribute("Stamina", math.min(statCap, (player:GetAttribute("Stamina") or 1) + amount))
			message = "You studied the manual and gained +"..amount.." Stamina!"
		elseif itemName == "Willpower Training Manual" then
			local amount = math.max(15, math.floor(15 * (prestige / 5)))
			player:SetAttribute("Willpower", math.min(statCap, (player:GetAttribute("Willpower") or 1) + amount))
			message = "You studied the manual and gained +"..amount.." Willpower!"

		elseif itemName == "Stand Power Training Manual" then
			if myStand == "None" then message = "You don't have a Stand to train!"; itemConsumed = false else
				local amount = math.max(15, math.floor(15 * (prestige / 5)))
				player:SetAttribute("Stand_Power_Val", math.min(statCap, (player:GetAttribute("Stand_Power_Val") or 0) + amount)); message = "Your Stand gained +"..amount.." Power!"
			end
		elseif itemName == "Stand Speed Training Manual" then
			if myStand == "None" then message = "You don't have a Stand to train!"; itemConsumed = false else
				local amount = math.max(15, math.floor(15 * (prestige / 5)))
				player:SetAttribute("Stand_Speed_Val", math.min(statCap, (player:GetAttribute("Stand_Speed_Val") or 0) + amount)); message = "Your Stand gained +"..amount.." Speed!"
			end
		elseif itemName == "Stand Range Training Manual" then
			if myStand == "None" then message = "You don't have a Stand to train!"; itemConsumed = false else
				local amount = math.max(15, math.floor(15 * (prestige / 5)))
				player:SetAttribute("Stand_Range_Val", math.min(statCap, (player:GetAttribute("Stand_Range_Val") or 0) + amount)); message = "Your Stand gained +"..amount.." Range!"
			end
		elseif itemName == "Stand Durability Training Manual" then
			if myStand == "None" then message = "You don't have a Stand to train!"; itemConsumed = false else
				local amount = math.max(15, math.floor(15 * (prestige / 5)))
				player:SetAttribute("Stand_Durability_Val", math.min(statCap, (player:GetAttribute("Stand_Durability_Val") or 0) + amount)); message = "Your Stand gained +"..amount.." Durability!"
			end
		elseif itemName == "Stand Precision Training Manual" then
			if myStand == "None" then message = "You don't have a Stand to train!"; itemConsumed = false else
				local amount = math.max(15, math.floor(15 * (prestige / 5)))
				player:SetAttribute("Stand_Precision_Val", math.min(statCap, (player:GetAttribute("Stand_Precision_Val") or 0) + amount)); message = "Your Stand gained +"..amount.." Precision!"
			end
		elseif itemName == "Stand Potential Training Manual" then
			if myStand == "None" then message = "You don't have a Stand to train!"; itemConsumed = false else
				local amount = math.max(15, math.floor(15 * (prestige / 5)))
				player:SetAttribute("Stand_Potential_Val", math.min(statCap, (player:GetAttribute("Stand_Potential_Val") or 0) + amount)); message = "Your Stand gained +"..amount.." Potential!"
			end

		elseif itemName == "Advanced Style Training Manual" then
			local amount = math.max(10, math.floor(10 * (prestige / 4)))
			for _, s in ipairs({"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower"}) do
				player:SetAttribute(s, math.min(statCap, (player:GetAttribute(s) or 1) + amount))
			end
			message = "You mastered the Advanced Style Training Manual! All Player Stats +"..amount.."!"
		elseif itemName == "Advanced Stand Training Manual" then
			if myStand == "None" then message = "You don't have a Stand to train!"; itemConsumed = false else
				local amount = math.max(10, math.floor(10 * (prestige / 4)))
				for _, s in ipairs({"Power", "Speed", "Range", "Durability", "Precision", "Potential"}) do
					player:SetAttribute("Stand_"..s.."_Val", math.min(statCap, (player:GetAttribute("Stand_"..s.."_Val") or 0) + amount))
				end
				message = "You mastered the Advanced Stand Training Manual! All Stand Stats +"..amount.."!"
			end
		elseif itemName == "Master Training Manual" then
			if myStand == "None" then message = "You don't have a Stand to train!"; itemConsumed = false else
				local amount = math.max(5, math.floor(5 * (prestige / 4)))
				for _, s in ipairs({"Health", "Strength", "Defense", "Speed", "Stamina", "Willpower"}) do
					player:SetAttribute(s, math.min(statCap, (player:GetAttribute(s) or 1) + amount))
				end
				for _, s in ipairs({"Power", "Speed", "Range", "Durability", "Precision", "Potential"}) do
					player:SetAttribute("Stand_"..s.."_Val", math.min(statCap, (player:GetAttribute("Stand_"..s.."_Val") or 0) + amount))
				end
				message = "You absorbed the Master Training Manual! All Stats +"..amount.."!"
			end

		elseif itemName == "Boxing Manual" then
			player:SetAttribute("FightingStyle", "Boxing"); message = "You read the manual. Gained Boxing Style."
		elseif itemName == "Vampire Mask" then
			player:SetAttribute("FightingStyle", "Vampirism"); message = "I REJECT MY HUMANITY! Gained Vampirism Style."
		elseif itemName == "Hamon Manual" then
			player:SetAttribute("FightingStyle", "Hamon"); message = "Your breathing stabilized. Gained Hamon Style."
		elseif itemName == "Cyborg Blueprints" then
			player:SetAttribute("FightingStyle", "Cyborg"); message = "German science is the best! Gained Cyborg Style."
		elseif itemName == "Ancient Mask" then
			player:SetAttribute("FightingStyle", "Pillarman"); message = "Awakened ancient biology! Gained Pillarman Style."
		elseif itemName == "Steel Ball" then
			player:SetAttribute("FightingStyle", "Spin"); message = "You grasped the rotation! Gained Spin Style."
		elseif itemName == "Rokakaka Fruit" then
			player:SetAttribute("FightingStyle", "Rock Human"); message = "You consumed the Rokakaka Fruit. Your body hardens as you become a Rock Human!"
		elseif itemName == "Perfect Aja Mask" then
			if player:GetAttribute("FightingStyle") == "Pillarman" then
				player:SetAttribute("FightingStyle", "Ultimate Lifeform")
				message = "The mask pierces your brain! You have evolved into the Ultimate Lifeform!"
			else
				message = "You must be a Pillarman to survive using this mask!"
				itemConsumed = false
			end
		elseif itemName == "Golden Spin Scroll" then
			if player:GetAttribute("FightingStyle") == "Spin" then
				player:SetAttribute("FightingStyle", "Golden Spin")
				message = "You comprehend the golden ratio! Your Spin has evolved into the Golden Spin!"
			else
				message = "You must master the base Spin style to understand this scroll!"
				itemConsumed = false
			end

		elseif itemName == "Weather Report Disc" then
			player:SetAttribute("Stand", "Weather Report"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken Weather Report!"
		elseif itemName == "Heaven's Door Disc" then
			player:SetAttribute("Stand", "Heaven's Door"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken Heaven's Door!"
		elseif itemName == "The Hand Disc" then
			player:SetAttribute("Stand", "The Hand"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken The Hand!"
		elseif itemName == "Metallica Disc" then
			player:SetAttribute("Stand", "Metallica"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken Metallica!"
		elseif itemName == "The World Disc" then
			player:SetAttribute("Stand", "The World"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken The World!"
		elseif itemName == "Star Platinum Disc" then
			player:SetAttribute("Stand", "Star Platinum"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken Star Platinum!"
		elseif itemName == "Wonder of U Disc" then
			player:SetAttribute("Stand", "Wonder of U"); player:SetAttribute("StandTrait", "None"); message = "You insert the disc into your head and awaken Wonder of U!"

		elseif itemName == "Requiem Arrow" then
			if prestige >= 5 then
				if myStand == "Gold Experience" then EvolveStand("Gold Experience Requiem"); message = "Your stand evolved into Gold Experience Requiem!"
				elseif myStand == "Silver Chariot" then EvolveStand("Chariot Requiem"); message = "Your stand evolved into Chariot Requiem!"
				elseif myStand == "King Crimson" then EvolveStand("King Crimson Requiem"); message = "Your stand evolved into King Crimson Requiem!"
				elseif (myStand ~= "Chariot Requiem" and myStand ~= "Gold Experience Requiem" and myStand ~= "King Crimson Requiem" and myStand ~= "None") then
					player:SetAttribute("StandTrait", "Requiem"); message = "The arrow accepts you, greedily worming it's way into your stand's body..."
				else	
					message = "The arrow falls through your graps, rejecting you."; itemConsumed = false
				end
			else
				message = "You must be at least Prestige 5 to use this!"; itemConsumed = false
			end

		elseif itemName == "Dio's Diary" then
			if myStand == "Star Platinum" then 
				EvolveStand("Star Platinum: The World"); 
				message = "Your Stand evolved into Star Platinum: The World!"
			elseif myStand == "C-Moon" then 
				EvolveStand("Made in Heaven"); 
				message = "Your Stand evolved into Made in Heaven!"
			else
				if (myStand ~= "Star Platinum: The World" and myStand ~= "Star Platinum: Over Heaven" and myStand ~= "The World" and myStand ~= "The World: Over Heaven" and myStand ~= "None") then
					if (math.random(1,100) <= 5) then
						player:SetAttribute("StandTrait", "Overheaven")
						message = "You begin to understand the writing, you unlock forbidden knowledge... Your stand has evolved into Over Heaven!"
					else	
						message = "You fail to understand the writings..."
					end
				else	
					message = "You've already gained the knowledge from these writings."
				end
			end

		elseif itemName == "Saint's Left Arm" then
			if myStand == "Tusk Act 1" then EvolveStand("Tusk Act 2"); message = "You fuse with the Left Arm! Your Stand evolved into Tusk Act 2!"
			else message = "The Corpse Part has no reaction to this stand."; itemConsumed = false end

		elseif itemName == "Saint's Right Eye" then
			if myStand == "Tusk Act 2" then EvolveStand("Tusk Act 3"); message = "You fuse with the Right Eye! Your Stand evolved into Tusk Act 3!"
			elseif myStand == "The World" then EvolveStand("The World: High Voltage"); message = "You fuse with the Right Eye! Your Stand evolved into The World: High Voltage!"
			else message = "The Corpse Part has no reaction to this stand."; itemConsumed = false end

		elseif itemName == "Saint's Pelvis" then
			if myStand == "Tusk Act 3" then EvolveStand("Tusk Act 4"); message = "You fuse with the Pelvis and master the infinite rotation! Your Stand evolved into Tusk Act 4!"
			else message = "The Corpse Part has no reaction to this stand."; itemConsumed = false end

		elseif itemName == "Saint's Heart" then
			if myStand == "Dirty Deeds Done Dirt Cheap" then EvolveStand("D4C Love Train"); message = "The holy light of the Heart protects you! Your Stand evolved into D4C Love Train!"
			else message = "The Corpse Part has no reaction to this stand."; itemConsumed = false end

		elseif itemName == "Saint's Spine" then
			if myStand == "The World" then EvolveStand("The World: Over Heaven"); message = "Your stand has evolved into The World: Over Heaven!"
			elseif myStand == "Star Platinum: The World" then EvolveStand("Star Platinum: Over Heaven"); message = "Your stand has evolved into Star Platinum: Over Heaven!"
			else message = "The Corpse Part has no reaction to this stand."; itemConsumed = false end

		elseif itemName == "Rokakaka Branch" then
			if myStand == "Soft & Wet" then EvolveStand("Soft & Wet: Go Beyond"); message = "The miraculous branch fuses with your Stand. Your bubbles now push beyond logic!"
			else message = "The branch has no reaction to this stand."; itemConsumed = false end

		elseif itemName == "Strange Arrow" then
			if myStand == "Killer Queen" then EvolveStand("Killer Queen BTD"); message = "Your Stand evolved into Killer Queen BTD!"
			elseif myStand == "Echoes Act 1" then EvolveStand("Echoes Act 2"); message = "Your Stand evolved into Echoes Act 2!"
			elseif myStand == "Echoes Act 2" then EvolveStand("Echoes Act 3"); message = "Your Stand evolved into Echoes Act 3!"
			else
				message = "The arrow has no reaction to this stand."; itemConsumed = false
			end

		elseif itemName == "Green Baby" then
			if myStand == "Whitesnake" then EvolveStand("C-Moon"); message = "Your Stand evolved into C-Moon!"
			else
				message = "The Green Baby has no reaction to you."; itemConsumed = false
			end

		elseif itemName == "New Rokakaka" then
			if prestige >= 15 then
				local fusionEvent = Network:FindFirstChild("OpenFusionUI")
				if fusionEvent then
					fusionEvent:FireClient(player)
					itemConsumed = false
				else
					message = "The fusion system is currently unavailable."
					itemConsumed = false
				end
			else
				message = "You must be at least Prestige 15 to use the New Rokakaka!"
				itemConsumed = false
			end

			-- April Fools
		elseif itemName == "Scratch-Off Ticket" then
			if myStand == "None" then
				message = "You need a Stand to gamble your life away!"
				itemConsumed = false
			elseif myStand == "Fused Stand" then
				message = "You cannot use a Scratch-Off Ticket on a Fused Stand!"
				itemConsumed = false
			else
				player:SetAttribute("StandTrait", "Gambling Addict")
				message = "You vigorously scratch the ticket... You gained the Gambling Addict trait!"
			end
		elseif itemName == "Chiikawa Mascot" then
			player:SetAttribute("Stand", "Chiikawa")
			player:SetAttribute("StandTrait", "None")
			local stats = StandData.Stands["Chiikawa"].Stats
			for statName, rank in pairs(stats) do
				player:SetAttribute("Stand_"..statName, rank)
			end
			message = "A strange little creature has chosen you! Awakened Stand: Chiikawa!"

		elseif itemName == "Limitless Manual" then
			player:SetAttribute("FightingStyle", "Limitless")
			message = "You have understood the concept of infinity! Gained Limitless Style."

		elseif itemName == "Cursed Finger" then
			player:SetAttribute("FightingStyle", "Shrine")
			message = "The finger's curse flows through you! Gained Shrine Style."	

			-- Easter
		elseif itemName == "Parasitic Egg" then
			player:SetAttribute("FightingStyle", "Baoh Armed Phenomenon")
			message = "A mysterious parasite burrows into your host body! Gained Baoh Style."

		elseif itemName == "Kakyoin's Egg" then
			player:SetAttribute("Stand", "Charmy Green")
			player:SetAttribute("StandTrait", "None")
			local stats = StandData.Stands["Charmy Green"].Stats
			if stats then
				for statName, rank in pairs(stats) do
					player:SetAttribute("Stand_"..statName, rank)
				end
			end
			message = "A mysterious egg hatched! Awakened Stand: Charmy Green!"

		elseif itemName == "Easter Egg" then
			message = "Spend this in the Easter Shop!"
			itemConsumed = false

		elseif itemName == "Lucky Egg" then
			local roll = math.random(1, 100)
			if roll <= 5 then
				local easterPool = {"Kakyoin's Paintbrush", "Baoh Arm Blade", "Shoshinsha Mark", "Ikuro's Jacket", "Kakyoin's Egg", "Parasitic Egg"}
				local reward = easterPool[math.random(1, #easterPool)]
				local attr = reward:gsub("[^%w]", "") .. "Count"
				player:SetAttribute(attr, (player:GetAttribute(attr) or 0) + 1)
				message = "You cracked open the Lucky Egg and found a rare " .. reward .. "!"
			else
				local amount = math.random(50, 250)
				player:SetAttribute("EasterEggCount", (player:GetAttribute("EasterEggCount") or 0) + amount)
				message = "You cracked open the Lucky Egg and got " .. amount .. " Easter Eggs!"
			end
		end

		if itemConsumed then
			player:SetAttribute(attrName, itemCount - 1)
			if message ~= "" then
				NotificationEvent:FireClient(player, "<font color='#FF55FF'>" .. message .. "</font>")
			end
		else
			if message ~= "" then
				NotificationEvent:FireClient(player, "<font color='#FF5555'>" .. message .. "</font>")
			end
		end
	end
end)