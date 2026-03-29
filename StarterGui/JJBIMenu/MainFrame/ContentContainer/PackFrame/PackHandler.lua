-- @ScriptType: LocalScript
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local RemotesFolder = ReplicatedStorage:WaitForChild("Network")
local packActionRemote = RemotesFolder:WaitForChild("PackAction")

local packFrame = script.Parent

local originalPosition = packFrame.Position
local originalAnchorPoint = packFrame.AnchorPoint
local originalSize = UDim2.new(0.12, 0, 0.251, 0)

local starterBtn = packFrame:WaitForChild("StarterOfferButton")
local proBtn = packFrame:WaitForChild("ProOfferButton")

local starterTimerLabel = starterBtn:WaitForChild("TimerLabel")
local proTimerLabel = proBtn:WaitForChild("TimerLabel")

local starterPackId = 3564613970 
local proPackId = 3564614182

local starterVis = 20
local proWait = 0.05
local proVis = 30

local ownsStarter = false
local ownsPro = false
local isStarterTimerRunning = false
local isProTimerRunning = false

local resizeConnection

local function AdjustPositionForOrientation()
	if not packFrame or not packFrame.Parent then
		if resizeConnection then resizeConnection:Disconnect() end
		return
	end

	local screenSize = camera.ViewportSize

	if screenSize.Y > screenSize.X then
		packFrame.AnchorPoint = Vector2.new(0.5, 1)
		packFrame.Position = UDim2.new(0.5, 0, 1, 15) 
		packFrame.Size = UDim2.new(0.4, 0, 0.1, 0)
	else
		packFrame.AnchorPoint = originalAnchorPoint
		packFrame.Position = originalPosition
		packFrame.Size = originalSize
	end
end

AdjustPositionForOrientation()
resizeConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(AdjustPositionForOrientation)

local function FormatTime(totalSeconds)
	local minutes = math.floor(totalSeconds / 60)
	local seconds = totalSeconds % 60
	return string.format("%02d:%02d", minutes, seconds)
end

local function ShowProPack()
	if ownsPro then return end

	if packFrame and packFrame.Parent then
		if starterBtn and starterBtn.Parent then starterBtn.Visible = false end
		proBtn.Visible = true
		packFrame.Visible = true
		isProTimerRunning = true

		task.spawn(function()
			local timeRemaining = proVis * 60

			while timeRemaining > 0 and isProTimerRunning and not ownsPro do
				proTimerLabel.Text = FormatTime(timeRemaining)
				task.wait(1)
				timeRemaining -= 1
			end

			if timeRemaining <= 0 and not ownsPro and packFrame then
				packActionRemote:FireServer("ProExpired")
				packFrame:Destroy()
			end
		end)
	end
end

local function HandleProWait()
	if starterBtn and starterBtn.Parent then
		starterBtn.Visible = false
	end
	proBtn.Visible = false
	if packFrame and packFrame.Parent then 
		packFrame.Visible = false
	end

	task.wait(proWait * 60)

	ShowProPack()
end

local function RunStarterPack()
	starterBtn.Visible = true
	proBtn.Visible = false
	packFrame.Visible = true
	isStarterTimerRunning = true

	task.spawn(function()
		local timeRemaining = starterVis * 60

		while timeRemaining > 0 and isStarterTimerRunning and not ownsStarter do
			starterTimerLabel.Text = FormatTime(timeRemaining)
			task.wait(1)
			timeRemaining -= 1
		end

		if timeRemaining <= 0 and not ownsStarter then
			packActionRemote:FireServer("StarterExpired")
			packFrame.Visible = false
		end
	end)
end

starterBtn.MouseButton1Click:Connect(function()
	MarketplaceService:PromptProductPurchase(player, starterPackId)
end)

proBtn.MouseButton1Click:Connect(function()
	MarketplaceService:PromptProductPurchase(player, proPackId)
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
	if userId == player.UserId and wasPurchased then
		if productId == starterPackId then
			ownsStarter = true
			isStarterTimerRunning = false 

			if starterBtn then
				starterBtn:Destroy() 
			end

			task.spawn(HandleProWait) 

		elseif productId == proPackId then
			ownsPro = true
			isProTimerRunning = false

			if packFrame then
				packFrame:Destroy() 
			end
		end
	end
end)

task.spawn(function()
	task.wait(2)

	if packFrame and packFrame.Parent then 
		packFrame.Visible = false 
	end

	ownsStarter = player:GetAttribute("BoughtStarterPack") or false
	ownsPro = player:GetAttribute("BoughtProPack") or false

	local starterExpired = player:GetAttribute("StarterPackExpired") or false
	local proExpired = player:GetAttribute("ProPackExpired") or false

	if ownsPro or proExpired then
		if packFrame then
			packFrame:Destroy()
		end
		return
	end

	if ownsStarter or starterExpired then
		if starterBtn then starterBtn:Destroy() end
		task.spawn(HandleProWait) 
	else
		RunStarterPack() 
	end
end)