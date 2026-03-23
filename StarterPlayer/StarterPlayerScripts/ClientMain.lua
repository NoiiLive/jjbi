-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("JJBIMenu", 10)

local UIModules = script.Parent:WaitForChild("UIModules", 10)
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local TooltipManager = require(UIModules:WaitForChild("TooltipManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))
local CombatTab = require(UIModules:WaitForChild("CombatTab"))
local InventoryTab = require(UIModules:WaitForChild("InventoryTab"))
local UpdatesTab = require(UIModules:WaitForChild("UpdatesTab"))
local TrainingTab = require(UIModules:WaitForChild("TrainingTab"))
local ShopTab = require(UIModules:WaitForChild("ShopTab"))
local GiftManager = require(UIModules:WaitForChild("GiftManager"))
local MultiplayerTab = require(UIModules:WaitForChild("MultiplayerTab"))
local TutorialManager = require(UIModules:WaitForChild("TutorialManager"))
local FusionModal = require(UIModules:WaitForChild("FusionModal"))

SFXManager.Init()
TooltipManager.Init(screenGui)
NotificationManager.Init(screenGui)
GiftManager.Init(screenGui)
FusionModal.Init(screenGui)

local Network = ReplicatedStorage:WaitForChild("Network", 10)
local NotificationEvent = Network:WaitForChild("NotificationEvent", 10)
local CombatUpdate = Network:WaitForChild("CombatUpdate", 10)
local DungeonUpdate = Network:WaitForChild("DungeonUpdate", 10)

if NotificationEvent then
	NotificationEvent.OnClientEvent:Connect(function(msg)
		NotificationManager.Show(msg)
	end)
end

local redeemCodeEvent = Network:FindFirstChild("RedeemCode")
if redeemCodeEvent then
	redeemCodeEvent.OnClientEvent:Connect(function(msg)
		if type(msg) == "string" then
			NotificationManager.Show(msg)
		end
	end)
end

local shopActionEvent = Network:FindFirstChild("ShopAction")
if shopActionEvent then
	shopActionEvent.OnClientEvent:Connect(function(action, data)
		if type(action) == "string" and data == nil then
			if action ~= "Refresh" and not string.match(action, "Prompt") then
				NotificationManager.Show(action)
			end
		elseif type(data) == "string" and (action == "Notify" or action == "Notification" or action == "Message" or action == "Error" or action == "Success") then
			NotificationManager.Show(data)
		end
	end)
end

if CombatUpdate then
	CombatUpdate.OnClientEvent:Connect(function(action, data)
		if action == "SystemMessage" then
			CombatTab.SystemMessage(data)
		elseif action == "TrainingTick" then
			TrainingTab.OnTick(data)
		else
			CombatTab.UpdateCombat(action, data)
		end
	end)
end

if DungeonUpdate then
	DungeonUpdate.OnClientEvent:Connect(function(action, data)
		if CombatTab.UpdateDungeon then
			CombatTab.UpdateDungeon(action, data)
		end
	end)
end

local function safeCall(func, action, data)
	if func then func(action, data) end
end

local gangUpdate = Network:FindFirstChild("GangUpdate")
if gangUpdate then gangUpdate.OnClientEvent:Connect(function(action, data) safeCall(MultiplayerTab.HandleGangUpdate, action, data) end) end

local arenaUpdate = Network:FindFirstChild("ArenaUpdate")
if arenaUpdate then arenaUpdate.OnClientEvent:Connect(function(action, data) safeCall(MultiplayerTab.HandleArenaUpdate, action, data) end) end

local tradeUpdate = Network:FindFirstChild("TradeUpdate")
if tradeUpdate then tradeUpdate.OnClientEvent:Connect(function(action, data) safeCall(MultiplayerTab.HandleTradeUpdate, action, data) end) end

local mainFrame = screenGui:WaitForChild("MainFrame", 10)
local bgDecor = mainFrame:WaitForChild("BgDecor", 10)
local bgPattern = bgDecor:WaitForChild("JoJoPattern", 10)
local contentContainer = mainFrame:WaitForChild("ContentContainer", 10)

local navBar = mainFrame:WaitForChild("NavBar", 10)
local navContainer = navBar:WaitForChild("NavContainer", 10)
local uiListLayout = navContainer:WaitForChild("UIListLayout", 10)

local topRightFrame = mainFrame:WaitForChild("TopRightFrame", 10)
local topRightContainer = topRightFrame:WaitForChild("TopRightContainer", 10)

local boostBtn = topRightContainer:WaitForChild("BoostBtn", 10)
local muteBtn = topRightContainer:WaitForChild("MuteBtn", 10)
local navToggleBtn = topRightContainer:WaitForChild("NavToggleBtn", 10)

local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

RunService.RenderStepped:Connect(function()
	local vp = camera.ViewportSize
	if vp.X > 0 and vp.Y > 0 and bgPattern then
		local offsetX = (mouse.X / vp.X) - 0.5
		local offsetY = (mouse.Y / vp.Y) - 0.5
		local targetPos = UDim2.new(-0.1 - (offsetX * 0.05), 0, -0.1 - (offsetY * 0.05), 0)
		bgPattern.Position = bgPattern.Position:Lerp(targetPos, 0.064)
	end
end)

local templateFolder = ReplicatedStorage:WaitForChild("JJBITemplates", 10)
local symbolTemplate = templateFolder and templateFolder:WaitForChild("SymbolTemplate", 10)

if symbolTemplate then
	task.spawn(function()
		while true do
			local symbol = symbolTemplate:Clone()

			local absSize = math.random(80, 160)
			symbol.Size = UDim2.new(0, absSize, 0, absSize)
			symbol.Position = UDim2.new(math.random(5, 95)/100, 0, 1.1, 0)
			symbol.Rotation = math.random(-30, 30)
			symbol.Parent = bgDecor

			local tInfo = TweenInfo.new(math.random(7, 14), Enum.EasingStyle.Linear)
			local tween = TweenService:Create(symbol, tInfo, {
				Position = UDim2.new(symbol.Position.X.Scale + (math.random(-15, 15)/100), 0, -0.2, 0),
				ImageTransparency = 1
			})
			tween:Play()
			tween.Completed:Connect(function() symbol:Destroy() end)
			task.wait(math.random(5, 15)/10)
		end
	end)
end

local function applyMuteState()
	local isCurrentlyMuted = player:GetAttribute("IsMuted") or false
	if muteBtn then muteBtn.Text = isCurrentlyMuted and "🔈" or "🔊" end
	local bgm = SoundService:FindFirstChild("BizarreBGM")
	if bgm then
		bgm.Volume = isCurrentlyMuted and 0 or 0.4
	end
end

player:GetAttributeChangedSignal("IsMuted"):Connect(applyMuteState)

task.spawn(function()
	SoundService:WaitForChild("BizarreBGM", 5)
	applyMuteState()
end)

if muteBtn then
	muteBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		local currentState = player:GetAttribute("IsMuted") or false
		local newState = not currentState
		player:SetAttribute("IsMuted", newState)
		Network:WaitForChild("ToggleMute"):FireServer(newState)
	end)
end

local function GetActiveBoostsText()
	local text = "<b><font color='#FFD700'>GLOBAL BOOSTS</font></b>\n____________________\n\n"

	local friends = math.min(player:GetAttribute("ServerFriends") or 0, 4)
	if friends > 0 then
		text ..= "<font color='#55FFFF'>• Connection Boost ("..friends.."/4): +"..(friends*5).."% XP & Yen</font>\n"
	else
		text ..= "<font color='#888888'>• Connection Boost (0/4): +0% XP & Yen</font>\n"
	end

	if player.MembershipType == Enum.MembershipType.Premium then
		text ..= "<font color='#55FFFF'>• Premium Boost: +5% XP</font>\n"
	else
		text ..= "<font color='#888888'>• Premium Boost: +5% XP</font>\n"
	end

	if player:GetAttribute("IsSupporter") then
		text ..= "<font color='#55FFFF'>• Group Boost: +1% Luck & 5% XP</font>\n"
	else
		text ..= "<font color='#888888'>• Group Boost: +1% Luck & 5% XP</font>\n"
	end

	return text
end

if boostBtn then
	boostBtn.MouseEnter:Connect(function() TooltipManager.Show(GetActiveBoostsText()) end)
	boostBtn.MouseLeave:Connect(function() TooltipManager.Hide() end)
	boostBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		Network:WaitForChild("BoostAction"):FireServer("CheckSupporter")
	end)
end

local TabFrames = {}
local tabs = {"Singleplayer", "Inventory", "Shop", "Multiplayer", "Training", "Updates"}

for _, tabName in ipairs(tabs) do
	local frame = contentContainer:WaitForChild(tabName .. "Frame", 5)
	if frame then TabFrames[tabName] = frame end
end

local activeTab = "Updates"
local currentLayoutState = "Large"

local function refreshButtons()
	local vp = camera.ViewportSize
	if vp.X == 0 then return end -- Failsafe to prevent 0x0 scale errors

	local btnCount = #tabs
	local navWidthLarge = vp.X * 0.85
	local btnWidthLarge = (navWidthLarge / btnCount) - 15
	local textSpaceLarge = btnWidthLarge - 60
	local uniformTextSize = math.clamp(math.floor(textSpaceLarge / 7.5), 10, 45)

	local navWidthMed = vp.X * 0.95
	local activeBtnWidthMed = navWidthMed * 0.40
	local textSpaceMed = activeBtnWidthMed - 60
	local mediumTextSize = math.clamp(math.floor(textSpaceMed / 7.5), 10, 35)

	for _, btn in pairs(navContainer:GetChildren()) do
		if btn:IsA("TextButton") then
			local tabName = string.gsub(btn.Name, "Button", "")
			local isActive = (tabName == activeTab)

			local titleLbl = btn:FindFirstChild("Title")
			local iconCont = btn:FindFirstChild("IconContainer")
			local btnStroke = btn:FindFirstChildOfClass("UIStroke")
			local icnStroke = iconCont and iconCont:FindFirstChildOfClass("UIStroke")

			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = isActive and Color3.fromRGB(70, 30, 100) or Color3.fromRGB(30, 20, 50)}):Play()
			if titleLbl then titleLbl.TextColor3 = isActive and Color3.fromRGB(255, 235, 130) or Color3.fromRGB(200, 200, 220) end
			if iconCont then iconCont.BackgroundColor3 = isActive and Color3.fromRGB(45, 15, 65) or Color3.fromRGB(15, 5, 25) end
			if btnStroke then 
				btnStroke.Color = isActive and Color3.fromRGB(255, 215, 50) or Color3.fromRGB(90, 50, 120)
				btnStroke.Thickness = isActive and 2 or 1
			end
			if icnStroke then icnStroke.Color = isActive and Color3.fromRGB(255, 215, 50) or Color3.fromRGB(90, 50, 120) end

			if currentLayoutState == "Large" then
				TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new((1/#tabs) - 0.015, 0, 0.8, 0)}):Play()
				if titleLbl then 
					titleLbl.Visible = true 
					titleLbl.TextSize = uniformTextSize
				end
				if iconCont then 
					TweenService:Create(iconCont, TweenInfo.new(0.2), {Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 10, 0.5, 0)}):Play()
					iconCont.AnchorPoint = Vector2.new(0, 0.5)
				end
				btn.BackgroundTransparency = 0
				if btnStroke then btnStroke.Enabled = true end

			elseif currentLayoutState == "Medium" then
				local targetWidth = isActive and 0.40 or ((0.60 / (#tabs - 1)) - 0.015)
				TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new(targetWidth, 0, 0.8, 0)}):Play()

				if titleLbl then 
					titleLbl.Visible = isActive 
					titleLbl.TextSize = mediumTextSize
				end
				if iconCont then 
					if isActive then
						TweenService:Create(iconCont, TweenInfo.new(0.2), {Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 10, 0.5, 0)}):Play()
						iconCont.AnchorPoint = Vector2.new(0, 0.5)
					else
						TweenService:Create(iconCont, TweenInfo.new(0.2), {Size = UDim2.new(0.8, 0, 0.8, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
						iconCont.AnchorPoint = Vector2.new(0.5, 0.5)
					end
				end
				btn.BackgroundTransparency = 0
				if btnStroke then btnStroke.Enabled = true end

			elseif currentLayoutState == "Small" then
				TweenService:Create(btn, TweenInfo.new(0.2), {Size = UDim2.new((1/#tabs) - 0.015, 0, 0.8, 0)}):Play()
				if titleLbl then titleLbl.Visible = false end
				if iconCont then 
					TweenService:Create(iconCont, TweenInfo.new(0.2), {Size = UDim2.new(0.85, 0, 0.85, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
					iconCont.AnchorPoint = Vector2.new(0.5, 0.5)
				end
				btn.BackgroundTransparency = 1
				if btnStroke then btnStroke.Enabled = false end
			end
		end
	end
end

local function SwitchTab(targetTabName)
	activeTab = targetTabName
	for tName, f in pairs(TabFrames) do
		f.Visible = (tName == targetTabName)
	end
	refreshButtons()
end

for _, tabName in ipairs(tabs) do
	local btn = navContainer:WaitForChild(tabName .. "Button", 5)
	if btn then
		btn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			SwitchTab(tabName)
		end)
	end
end

local isNavOpen = true

local function ToggleNav()
	isNavOpen = not isNavOpen
	if navToggleBtn then navToggleBtn.Text = isNavOpen and "⬇" or "⬆" end

	local targetY = isNavOpen and UDim2.new(0.5, 0, 1, -25) or UDim2.new(0.5, 0, 1, 100)
	TweenService:Create(navBar, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = targetY
	}):Play()

	local currentWidth = 0.8
	if currentLayoutState == "Medium" then
		currentWidth = 0.85
	elseif currentLayoutState == "Small" then
		currentWidth = 0.95
	end

	local targetSize = isNavOpen and UDim2.new(currentWidth, 0, 0.75, 0) or UDim2.new(currentWidth, 0, 0.9, 0)
	local targetPos = isNavOpen and UDim2.new(0.5, 0, 0.45, 0) or UDim2.new(0.5, 0, 0.5, 0)

	TweenService:Create(contentContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = targetSize,
		Position = targetPos
	}):Play()
end

if navToggleBtn then
	navToggleBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		ToggleNav()
	end)
end

local keyMap = { 
	[Enum.KeyCode.One] = 1, [Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.Two] = 2, [Enum.KeyCode.KeypadTwo] = 2,
	[Enum.KeyCode.Three] = 3, [Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.Four] = 4, [Enum.KeyCode.KeypadFour] = 4,
	[Enum.KeyCode.Five] = 5, [Enum.KeyCode.KeypadFive] = 5,
	[Enum.KeyCode.Six] = 6, [Enum.KeyCode.KeypadSix] = 6 
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode == Enum.KeyCode.Backquote then
		SFXManager.Play("Click")
		ToggleNav()
	end
	local tabIndex = keyMap[input.KeyCode]
	if tabIndex and tabs[tabIndex] then
		SFXManager.Play("Click")
		SwitchTab(tabs[tabIndex])
	end
end)

local function UpdateLayoutForScreen()
	local vp = camera.ViewportSize
	if vp.X == 0 then return end -- Failsafe check 

	if vp.X >= 1050 then
		currentLayoutState = "Large"
		navBar.Size = UDim2.new(0.85, 0, 0, 75)
		topRightFrame.Size = UDim2.new(0, 180, 0, 65)
		topRightFrame.Position = UDim2.new(1, -20, 0, 20)
		contentContainer.Size = isNavOpen and UDim2.new(0.8, 0, 0.75, 0) or UDim2.new(0.8, 0, 0.9, 0)
		if uiListLayout then uiListLayout.Padding = UDim.new(0, 10) end
		if boostBtn then boostBtn.Size = UDim2.new(0, 45, 0, 45) end
		if muteBtn then muteBtn.Size = UDim2.new(0, 45, 0, 45) end
		if navToggleBtn then navToggleBtn.Size = UDim2.new(0, 45, 0, 45) end
	elseif vp.X >= 600 and vp.X < 1050 then
		currentLayoutState = "Medium"
		navBar.Size = UDim2.new(0.95, 0, 0, 70)
		topRightFrame.Size = UDim2.new(0, 170, 0, 60)
		topRightFrame.Position = UDim2.new(1, -15, 0, 15)
		contentContainer.Size = isNavOpen and UDim2.new(0.85, 0, 0.75, 0) or UDim2.new(0.85, 0, 0.9, 0)
		if uiListLayout then uiListLayout.Padding = UDim.new(0, 8) end
		if boostBtn then boostBtn.Size = UDim2.new(0, 40, 0, 40) end
		if muteBtn then muteBtn.Size = UDim2.new(0, 40, 0, 40) end
		if navToggleBtn then navToggleBtn.Size = UDim2.new(0, 40, 0, 40) end
	else
		currentLayoutState = "Small"
		navBar.Size = UDim2.new(0.95, 0, 0, 65)
		topRightFrame.Size = UDim2.new(0, 160, 0, 55)
		topRightFrame.Position = UDim2.new(1, -10, 0, 10)
		contentContainer.Size = isNavOpen and UDim2.new(0.95, 0, 0.75, 0) or UDim2.new(0.95, 0, 0.9, 0)
		if uiListLayout then uiListLayout.Padding = UDim.new(0, 5) end
		if boostBtn then boostBtn.Size = UDim2.new(0, 35, 0, 35) end
		if muteBtn then muteBtn.Size = UDim2.new(0, 35, 0, 35) end
		if navToggleBtn then navToggleBtn.Size = UDim2.new(0, 35, 0, 35) end
	end

	navBar.Position = isNavOpen and UDim2.new(0.5, 0, 1, -25) or UDim2.new(0.5, 0, 1, 100)
	refreshButtons()
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
UpdateLayoutForScreen()

-- Initialize Tabs 
if TabFrames["Singleplayer"] then CombatTab.Init(TabFrames["Singleplayer"], TooltipManager, SwitchTab) end
if TabFrames["Inventory"] then InventoryTab.Init(TabFrames["Inventory"], TooltipManager, SwitchTab) end
if TabFrames["Updates"] then UpdatesTab.Init(TabFrames["Updates"], TooltipManager, SwitchTab) end
if TabFrames["Training"] then TrainingTab.Init(TabFrames["Training"], TooltipManager, SwitchTab) end
if TabFrames["Shop"] then ShopTab.Init(TabFrames["Shop"], TooltipManager) end
if TabFrames["Multiplayer"] then MultiplayerTab.Init(TabFrames["Multiplayer"], TooltipManager, SwitchTab) end

TutorialManager.Init(mainFrame, SwitchTab)
SwitchTab("Updates")