-- @ScriptType: LocalScript
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")

	if message.TextSource then
		local player = Players:GetPlayerByUserId(message.TextSource.UserId)
		if player then
			local equippedTitle = player:GetAttribute("EquippedTitle") or "None"

			if equippedTitle ~= "None" then
				local titleData = GameData.Titles[equippedTitle]
				local color = titleData and titleData.Color or "#FFFFFF"

				props.PrefixText = "<font color='" .. color .. "'>[" .. equippedTitle .. "]</font> " .. message.PrefixText
			end
		end
	end

	return props
end