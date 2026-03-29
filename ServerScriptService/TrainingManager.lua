-- @ScriptType: Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local ToggleTraining = Network:FindFirstChild("ToggleTraining")
if not ToggleTraining then
	ToggleTraining = Instance.new("RemoteEvent")
	ToggleTraining.Name = "ToggleTraining"
	ToggleTraining.Parent = Network
end

local ActiveTrainers = {}

local TrainingRates = {
	[1] = {XP = 50, Yen = 1},
	[2] = {XP = 100, Yen = 5},
	[3] = {XP = 250, Yen = 10},
	[4] = {XP = 500, Yen = 15},
	[5] = {XP = 1000, Yen = 25},
	[6] = {XP = 1500, Yen = 50},
	[7] = {XP = 2500, Yen = 75},
	[8] = {XP = 5000, Yen = 100},
	[9] = {XP = 10000, Yen = 500}
}

local function GetPlayerBoosts(player)
	local boosts = { XP = 1.0, Yen = 1.0 }

	local friends = math.min(player:GetAttribute("ServerFriends") or 0, 4)
	boosts.XP += (friends * 0.05)
	boosts.Yen += (friends * 0.05)

	if player.MembershipType == Enum.MembershipType.Premium then
		boosts.XP += 0.05
	end

	if player:GetAttribute("IsSupporter") == true then
		boosts.XP += 0.05
	end

	local elo = 1000
	if player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Elo") then
		elo = player.leaderstats.Elo.Value
	end

	if elo >= 1500 then boosts.Yen += 0.05 end
	if elo >= 2000 then boosts.XP += 0.05 end

	boosts.Yen *= (player:GetAttribute("GangYenBoost") or 1.0)
	boosts.XP *= (player:GetAttribute("GangXPBoost") or 1.0)

	return boosts
end

ToggleTraining.OnServerEvent:Connect(function(player, isTraining)
	if isTraining then
		ActiveTrainers[player] = true
	else
		ActiveTrainers[player] = nil
	end
end)

local tickCounter = 0

task.spawn(function()
	while true do
		task.wait(2.5)
		tickCounter += 1

		for player, _ in pairs(ActiveTrainers) do
			if not player or not player.Parent then
				ActiveTrainers[player] = nil
				continue
			end

			local leaderstats = player:FindFirstChild("leaderstats")
			if not leaderstats then continue end

			local isVIP = player:GetAttribute("IsVIP") == true

			local shouldTrain = isVIP or (tickCounter % 2 == 0)
			if not shouldTrain then
				continue
			end

			local prestige = leaderstats:FindFirstChild("Prestige") and leaderstats.Prestige.Value or 0
			local currentPart = player:GetAttribute("CurrentPart") or 1
			local safePart = math.clamp(currentPart, 1, 9)

			local baseRates = TrainingRates[safePart]
			if not baseRates then continue end

			local xpGain = baseRates.XP * (1 + prestige)
			local yenGain = baseRates.Yen * (1 + prestige)

			local boosts = GetPlayerBoosts(player)
			xpGain = math.floor(xpGain * boosts.XP)
			yenGain = math.floor(yenGain * boosts.Yen)

			player:SetAttribute("XP", (player:GetAttribute("XP") or 0) + xpGain)

			if leaderstats:FindFirstChild("Yen") then
				leaderstats.Yen.Value += yenGain
			end

			Network.CombatUpdate:FireClient(player, "TrainingTick", {
				XP = xpGain,
				Yen = yenGain,
				Part = safePart,
				Duration = isVIP and 2.5 or 5
			})
		end
	end
end)