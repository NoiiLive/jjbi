-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local Players = game:GetService("Players")
local Network = ReplicatedStorage:WaitForChild("Network")

local StandStorageAction = Network:WaitForChild("StandStorageAction")

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

		local currentStand = player:GetAttribute("Stand") or "None"
		local currentTrait = player:GetAttribute("StandTrait") or "None"
		local storedStand = player:GetAttribute("StoredStand"..slotNum) or "None"
		local storedTrait = player:GetAttribute("StoredStand"..slotNum.."_Trait") or "None"

		if currentStand == "None" and storedStand == "None" then return end

		player:SetAttribute("Stand", storedStand)
		player:SetAttribute("StandTrait", storedTrait)

		if storedStand ~= "None" and StandData.Stands[storedStand] then
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

		player:SetAttribute("StoredStand"..slotNum, currentStand)
		player:SetAttribute("StoredStand"..slotNum.."_Trait", currentTrait)

		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FFD700'>Swapped Stand in Slot "..slotNum.."!</font>")

	elseif action == "SwapStyle" then
		if slotNum == 2 and not player:GetAttribute("HasStyleSlot2") then return end
		if slotNum == 3 and not player:GetAttribute("HasStyleSlot3") then return end

		local currentStyle = player:GetAttribute("FightingStyle") or "None"
		local storedStyle = player:GetAttribute("StoredStyle"..slotNum) or "None"

		if currentStyle == "None" and storedStyle == "None" then return end

		player:SetAttribute("FightingStyle", storedStyle)
		player:SetAttribute("StoredStyle"..slotNum, currentStyle)

		Network.CombatUpdate:FireClient(player, "SystemMessage", "<font color='#FF8C00'>Swapped Style in Slot "..slotNum.."!</font>")
	end
end)