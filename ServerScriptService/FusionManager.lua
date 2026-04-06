-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))

local ExecuteFusion = Network:FindFirstChild("ExecuteFusion") or Instance.new("RemoteEvent", Network)
ExecuteFusion.Name = "ExecuteFusion"

local NotificationEvent = Network:WaitForChild("NotificationEvent")

local AdminLogger = Network:FindFirstChild("AdminLogger")
if not AdminLogger then
	AdminLogger = Instance.new("BindableEvent")
	AdminLogger.Name = "AdminLogger"
	AdminLogger.Parent = Network
end

ExecuteFusion.OnServerEvent:Connect(function(player, slot1, slot2, targetSlot)
	local rokaCount = player:GetAttribute("NewRokakakaCount") or 0
	if rokaCount < 1 then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>You do not have a New Rokakaka!</font>")
		return
	end

	if slot1 == slot2 then return end 
	if not targetSlot then return end

	if targetSlot == "Slot2" and not player:GetAttribute("HasStandSlot2") then return end
	if targetSlot == "Slot3" and not player:GetAttribute("HasStandSlot3") then return end
	local prestige = player:FindFirstChild("leaderstats") and player.leaderstats.Prestige.Value or 0
	if targetSlot == "Slot4" and prestige < 15 then return end
	if targetSlot == "Slot5" and prestige < 30 then return end
	if targetSlot == "SlotVIP" and not player:GetAttribute("IsVIP") then return end

	local function GetStandDataFromSlot(slot)
		if slot == "Active" then return player:GetAttribute("Stand") or "None", player:GetAttribute("StandTrait") or "None"
		elseif slot == "Slot1" then return player:GetAttribute("StoredStand1") or "None", player:GetAttribute("StoredStand1_Trait") or "None"
		elseif slot == "Slot2" then return player:GetAttribute("StoredStand2") or "None", player:GetAttribute("StoredStand2_Trait") or "None"
		elseif slot == "Slot3" then return player:GetAttribute("StoredStand3") or "None", player:GetAttribute("StoredStand3_Trait") or "None"
		elseif slot == "Slot4" then return player:GetAttribute("StoredStand4") or "None", player:GetAttribute("StoredStand4_Trait") or "None"
		elseif slot == "Slot5" then return player:GetAttribute("StoredStand5") or "None", player:GetAttribute("StoredStand5_Trait") or "None"
		elseif slot == "SlotVIP" then return player:GetAttribute("StoredStandVIP") or "None", player:GetAttribute("StoredStandVIP_Trait") or "None" end
		return "None", "None"
	end

	local stand1, trait1 = GetStandDataFromSlot(slot1)
	local stand2, trait2 = GetStandDataFromSlot(slot2)

	local oldTargetStandName = GetStandDataFromSlot(targetSlot)
	if oldTargetStandName == "Fused Stand" then
		local fs1, fs2 = "None", "None"
		if targetSlot == "Active" then
			fs1 = player:GetAttribute("Active_FusedStand1") or "None"
			fs2 = player:GetAttribute("Active_FusedStand2") or "None"
		else
			local num = targetSlot:gsub("Slot", "")
			fs1 = player:GetAttribute("StoredStand"..num.."_FusedStand1") or "None"
			fs2 = player:GetAttribute("StoredStand"..num.."_FusedStand2") or "None"
		end
		oldTargetStandName = "Fused Stand (" .. tostring(fs1) .. " + " .. tostring(fs2) .. ")"
	end

	local newStandFormatted = "Fused Stand (" .. tostring(stand1) .. " + " .. tostring(stand2) .. ")"

	if oldTargetStandName ~= "None" then
		AdminLogger:Fire("Replacement", {
			Player = player.Name, Context = "Fusion", OldItem = oldTargetStandName, NewItem = newStandFormatted, Slot = targetSlot
		})
	end

	if stand1 == "None" or stand2 == "None" then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>Both slots must contain a valid Stand!</font>")
		return
	end

	if stand1 == "Fused Stand" or stand2 == "Fused Stand" then
		NotificationEvent:FireClient(player, "<font color='#FF5555'>You cannot fuse a Stand that is already fused!</font>")
		return
	end

	player:SetAttribute("NewRokakakaCount", rokaCount - 1)

	local function ClearSlot(slot)
		if slot == "Active" then 
			player:SetAttribute("Stand", "None"); player:SetAttribute("StandTrait", "None")
			player:SetAttribute("Active_FusedStand1", "None")
			player:SetAttribute("Active_FusedStand2", "None")
			player:SetAttribute("Active_FusedTrait1", "None")
			player:SetAttribute("Active_FusedTrait2", "None")
		else
			local num = slot:gsub("Slot", "")
			player:SetAttribute("StoredStand" .. num, "None"); player:SetAttribute("StoredStand" .. num .. "_Trait", "None")
			player:SetAttribute("StoredStand"..num.."_FusedStand1", "None")
			player:SetAttribute("StoredStand"..num.."_FusedStand2", "None")
			player:SetAttribute("StoredStand"..num.."_FusedTrait1", "None")
			player:SetAttribute("StoredStand"..num.."_FusedTrait2", "None")
		end
	end

	ClearSlot(slot1)
	ClearSlot(slot2)

	local prefix = (targetSlot == "Active") and "Active_" or ("StoredStand" .. targetSlot:gsub("Slot", "") .. "_")

	player:SetAttribute(prefix .. "FusedStand1", stand1)
	player:SetAttribute(prefix .. "FusedStand2", stand2)
	player:SetAttribute(prefix .. "FusedTrait1", trait1)
	player:SetAttribute(prefix .. "FusedTrait2", trait2)

	if targetSlot == "Active" then
		player:SetAttribute("Stand", "Fused Stand")
		player:SetAttribute("StandTrait", "Fused")

		local statsList = {"Power", "Speed", "Range", "Durability", "Precision", "Potential"}
		local rankToNum = {["None"]=0, ["E"]=1, ["D"]=2, ["C"]=3, ["B"]=4, ["A"]=5, ["S"]=6}
		local numToRank = { [0]="None", [1]="E", [2]="D", [3]="C", [4]="B", [5]="A", [6]="S" }

		local baseData1 = StandData.Stands[stand1] and StandData.Stands[stand1].Stats or {Power="E", Speed="E", Range="E", Durability="E", Precision="E", Potential="E"}
		local baseData2 = StandData.Stands[stand2] and StandData.Stands[stand2].Stats or {Power="E", Speed="E", Range="E", Durability="E", Precision="E", Potential="E"}

		for _, stat in ipairs(statsList) do
			local val1 = rankToNum[baseData1[stat]] or 0
			local val2 = rankToNum[baseData2[stat]] or 0
			local avg = math.ceil((val1 + val2) / 2)
			player:SetAttribute("Stand_" .. stat, numToRank[avg] or "C")
		end
	else
		local num = targetSlot:gsub("Slot", "")
		player:SetAttribute("StoredStand" .. num, "Fused Stand")
		player:SetAttribute("StoredStand" .. num .. "_Trait", "Fused")
	end

	local targetName = (targetSlot == "Active") and "Active Stand" or "Storage " .. targetSlot:gsub("Slot", "")
	NotificationEvent:FireClient(player, "<font color='#FF55FF'>Equivalent Exchange complete. Your Stands have fused into " .. targetName .. "!</font>")
end)