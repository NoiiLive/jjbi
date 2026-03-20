-- @ScriptType: Script
-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local RedeemCode = Network:WaitForChild("RedeemCode")

local NotificationEvent = Network:FindFirstChild("NotificationEvent") or Instance.new("RemoteEvent", Network)
NotificationEvent.Name = "NotificationEvent"

local ActiveCodes = {
	["BIZARRE"] = {Yen = 1000, XP = 2500, Items = {["Stand Arrow"] = 1}},
	["300KVISITS"] = {Items = {["Stand Arrow"] = 300, ["Rokakaka"] = 300, ["Saint's Corpse Part"] = 125}},
	["GUIREWORK"] = {Items = {["Mythical Giftbox"] = 3}},
	["STEELPIPE"] = {Items = {["Steel Pipe (x400)"] = 1}},
}

RedeemCode.OnServerEvent:Connect(function(player, codeStr)
	if type(codeStr) ~= "string" then return end

	codeStr = string.upper(string.match(codeStr, "^%s*(.-)%s*$"))

	local redeemedStr = player:GetAttribute("RedeemedCodes") or ""
	local redeemedList = string.split(redeemedStr, ",")

	if table.find(redeemedList, codeStr) then
		local msg = "<font color='#FF5555'>Code '" .. codeStr .. "' has already been redeemed!</font>"
		Network.CombatUpdate:FireClient(player, "SystemMessage", msg)
		NotificationEvent:FireClient(player, msg)
		return
	end

	local reward = ActiveCodes[codeStr]
	if reward then
		local xpReward = reward.XP or 0
		local yenReward = reward.Yen or 0

		if yenReward > 0 then
			player.leaderstats.Yen.Value += yenReward
		end
		if xpReward > 0 then
			player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + xpReward)
		end

		local rewardStrings = {}
		if xpReward > 0 then table.insert(rewardStrings, "+" .. xpReward .. " XP") end
		if yenReward > 0 then table.insert(rewardStrings, "+" .. yenReward .. " Yen") end

		if reward.Items then
			for itemName, amount in pairs(reward.Items) do
				local attrName = itemName:gsub("[^%w]", "") .. "Count"
				player:SetAttribute(attrName, (player:GetAttribute(attrName) or 0) + amount)
				table.insert(rewardStrings, "+" .. amount .. " " .. itemName)
			end
		end

		table.insert(redeemedList, codeStr)
		player:SetAttribute("RedeemedCodes", table.concat(redeemedList, ","))

		local currentInv = GameData.GetInventoryCount(player)
		local maxInv = player:GetAttribute("Has2xInventory") and 30 or 15
		local capNotice = (reward.Items and currentInv > maxInv) and " <font color='#AAAAAA'>(Bypassed Inventory Cap)</font>" or ""

		local finalMsg = "<font color='#55FF55'>Code '" .. codeStr .. "' redeemed!</font>"
		if #rewardStrings > 0 then
			finalMsg = finalMsg .. " <font color='#FFFF55'>(" .. table.concat(rewardStrings, ", ") .. ")</font>"
		end

		Network.CombatUpdate:FireClient(player, "SystemMessage", finalMsg .. capNotice)
		NotificationEvent:FireClient(player, finalMsg .. capNotice)
	else
		local msg = "<font color='#FF5555'>Invalid or expired code!</font>"
		Network.CombatUpdate:FireClient(player, "SystemMessage", msg)
		NotificationEvent:FireClient(player, msg)
	end
end)