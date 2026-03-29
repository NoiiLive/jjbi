-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local Players = game:GetService("Players")
local Network = ReplicatedStorage:WaitForChild("Network")

local StandStorageAction = Network:FindFirstChild("StandStorageAction")
if not StandStorageAction then
	StandStorageAction = Instance.new("RemoteEvent")
	StandStorageAction.Name = "StandStorageAction"
	StandStorageAction.Parent = Network
end

local NotificationEvent = Network:FindFirstChild("NotificationEvent")
if not NotificationEvent then
	NotificationEvent = Instance.new("RemoteEvent")
	NotificationEvent.Name = "NotificationEvent"
	NotificationEvent.Parent = Network
end

StandStorageAction.OnServerEvent:Connect(function(player, action, slotNum)
	if action == "Swap" then
		if slotNum == 2 and not player:GetAttribute("HasStandSlot2") then return end
		if slotNum == 3 and not player:GetAttribute("HasStandSlot3") then return end

		if slotNum == 4 then
			local pObj = player:FindFirstChild("leaderstats")
			local prestige = pObj and pObj:FindFirstChild("Prestige") and pObj.Prestige.Value or 0
			if prestige < 15 then return end
		end
		if slotNum == 5 then
			local pObj = player:FindFirstChild("leaderstats")
			local prestige = pObj and pObj:FindFirstChild("Prestige") and pObj.Prestige.Value or 0
			if prestige < 30 then return end
		end
		if slotNum == "VIP" and not player:GetAttribute("IsVIP") then return end

		local currentStand = player:GetAttribute("Stand") or "None"
		local currentTrait = player:GetAttribute("StandTrait") or "None"

		local storedStand = player:GetAttribute("StoredStand"..tostring(slotNum)) or "None"
		local storedTrait = player:GetAttribute("StoredStand"..tostring(slotNum).."_Trait") or "None"

		if currentStand == "None" and storedStand == "None" then return end

		player:SetAttribute("Stand", storedStand)
		player:SetAttribute("StandTrait", storedTrait)

		local function SwapFusedData(slot)
			local sKey = tostring(slot)
			local aS1 = player:GetAttribute("Active_FusedStand1") or "None"
			local aS2 = player:GetAttribute("Active_FusedStand2") or "None"
			local aT1 = player:GetAttribute("Active_FusedTrait1") or "None"
			local aT2 = player:GetAttribute("Active_FusedTrait2") or "None"

			local sS1 = player:GetAttribute("StoredStand"..sKey.."_FusedStand1") or "None"
			local sS2 = player:GetAttribute("StoredStand"..sKey.."_FusedStand2") or "None"
			local sT1 = player:GetAttribute("StoredStand"..sKey.."_FusedTrait1") or "None"
			local sT2 = player:GetAttribute("StoredStand"..sKey.."_FusedTrait2") or "None"

			player:SetAttribute("Active_FusedStand1", sS1)
			player:SetAttribute("Active_FusedStand2", sS2)
			player:SetAttribute("Active_FusedTrait1", sT1)
			player:SetAttribute("Active_FusedTrait2", sT2)

			player:SetAttribute("StoredStand"..sKey.."_FusedStand1", aS1)
			player:SetAttribute("StoredStand"..sKey.."_FusedStand2", aS2)
			player:SetAttribute("StoredStand"..sKey.."_FusedTrait1", aT1)
			player:SetAttribute("StoredStand"..sKey.."_FusedTrait2", aT2)
		end

		SwapFusedData(slotNum)

		if storedStand == "Fused Stand" then
			local sS1 = player:GetAttribute("Active_FusedStand1") or "None"
			local sS2 = player:GetAttribute("Active_FusedStand2") or "None"

			local statsList = {"Power", "Speed", "Range", "Durability", "Precision", "Potential"}
			local rankToNum = {["None"]=0, ["E"]=1, ["D"]=2, ["C"]=3, ["B"]=4, ["A"]=5, ["S"]=6}
			local numToRank = { [0]="None", [1]="E", [2]="D", [3]="C", [4]="B",[5]="A", [6]="S" }

			local baseData1 = StandData.Stands[sS1] and StandData.Stands[sS1].Stats or {Power="E", Speed="E", Range="E", Durability="E", Precision="E", Potential="E"}
			local baseData2 = StandData.Stands[sS2] and StandData.Stands[sS2].Stats or {Power="E", Speed="E", Range="E", Durability="E", Precision="E", Potential="E"}

			for _, stat in ipairs(statsList) do
				local val1 = rankToNum[baseData1[stat]] or 0
				local val2 = rankToNum[baseData2[stat]] or 0
				local avg = math.ceil((val1 + val2) / 2)
				player:SetAttribute("Stand_" .. stat, numToRank[avg] or "C")
			end
		elseif storedStand ~= "None" and StandData.Stands[storedStand] then
			local stats = StandData.Stands[storedStand].Stats
			for statName, rank in pairs(stats) do
				player:SetAttribute("Stand_"..statName, rank)
			end
		else
			local emptyStats = {"Power", "Speed", "Range", "Durability", "Precision", "Potential"}
			for _, stat in ipairs(emptyStats) do
				player:SetAttribute("Stand_"..stat, "None")
			end
		end

		player:SetAttribute("StoredStand"..tostring(slotNum), currentStand)
		player:SetAttribute("StoredStand"..tostring(slotNum).."_Trait", currentTrait)

		NotificationEvent:FireClient(player, "<font color='#FFD700'>Swapped Stand with Storage Slot "..tostring(slotNum).."!</font>")

	elseif action == "SwapStyle" then
		if slotNum == 2 and not player:GetAttribute("HasStyleSlot2") then return end
		if slotNum == 3 and not player:GetAttribute("HasStyleSlot3") then return end
		if slotNum == "VIP" and not player:GetAttribute("IsVIP") then return end

		local currentStyle = player:GetAttribute("FightingStyle") or "None"
		local storedStyle = player:GetAttribute("StoredStyle"..tostring(slotNum)) or "None"

		if currentStyle == "None" and storedStyle == "None" then return end

		player:SetAttribute("FightingStyle", storedStyle)
		player:SetAttribute("StoredStyle"..tostring(slotNum), currentStyle)

		NotificationEvent:FireClient(player, "<font color='#FF8C00'>Swapped Style with Storage Slot "..tostring(slotNum).."!</font>")
	end
end)