-- @ScriptType: ModuleScript
local TutorialManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Network = ReplicatedStorage:WaitForChild("Network")
local player = game.Players.LocalPlayer

local SFXManager = require(script.Parent:WaitForChild("SFXManager")) 

local guiRoot
local switchTabFuncRef
local tutorialContainer
local topMask, bottomMask, leftMask, rightMask
local dialogueFrame
local dialogueText
local nextButton
local highlightFrame
local highlightConn

local isSkipped = false
local skipEvent = Instance.new("BindableEvent")

local function BuildTutorialUI()
	if player.PlayerGui:FindFirstChild("TutorialGui") then
		player.PlayerGui.TutorialGui:Destroy()
	end

	tutorialContainer = Instance.new("ScreenGui")
	tutorialContainer.Name = "TutorialGui"
	tutorialContainer.DisplayOrder = 100
	tutorialContainer.IgnoreGuiInset = true
	tutorialContainer.Parent = player:WaitForChild("PlayerGui")

	local function MakeMask(name)
		local m = Instance.new("Frame")
		m.Name = name
		m.BackgroundColor3 = Color3.new(0,0,0)
		m.BackgroundTransparency = 0.5
		m.BorderSizePixel = 0
		m.Active = true 
		m.ZIndex = 1
		m.Parent = tutorialContainer
		return m
	end

	topMask = MakeMask("TopMask")
	topMask.Size = UDim2.new(1, 0, 1, 0)

	bottomMask = MakeMask("BottomMask")
	leftMask = MakeMask("LeftMask")
	rightMask = MakeMask("RightMask")

	highlightFrame = Instance.new("Frame")
	highlightFrame.Name = "HighlightFrame"
	highlightFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
	highlightFrame.BackgroundTransparency = 0.8
	highlightFrame.BorderSizePixel = 0
	highlightFrame.ZIndex = 2
	highlightFrame.Parent = tutorialContainer

	local hStroke = Instance.new("UIStroke", highlightFrame)
	hStroke.Color = Color3.fromRGB(255, 255, 0)
	hStroke.Thickness = 3
	hStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local skipBtn = Instance.new("TextButton")
	skipBtn.Name = "SkipBtn"
	skipBtn.Size = UDim2.new(0, 140, 0, 45)
	skipBtn.Position = UDim2.new(1, -160, 0, 20)
	skipBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	skipBtn.Text = "Skip Tutorial"
	skipBtn.Font = Enum.Font.GothamBold
	skipBtn.TextColor3 = Color3.new(1, 1, 1)
	skipBtn.TextScaled = true
	skipBtn.ZIndex = 10
	skipBtn.Parent = tutorialContainer

	Instance.new("UICorner", skipBtn).CornerRadius = UDim.new(0, 6)
	local sp = Instance.new("UIPadding", skipBtn)
	sp.PaddingTop = UDim.new(0, 8); sp.PaddingBottom = UDim.new(0, 8)
	sp.PaddingLeft = UDim.new(0, 8); sp.PaddingRight = UDim.new(0, 8)

	local sStroke = Instance.new("UIStroke", skipBtn)
	sStroke.Color = Color3.fromRGB(255, 150, 150)
	sStroke.Thickness = 2
	sStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	dialogueFrame = Instance.new("Frame")
	dialogueFrame.Name = "DialogueFrame"
	dialogueFrame.Size = UDim2.new(0.6, 0, 0.18, 0)
	dialogueFrame.Position = UDim2.new(0.2, 0, 0.78, 0)
	dialogueFrame.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	dialogueFrame.ZIndex = 10
	dialogueFrame.Parent = tutorialContainer

	Instance.new("UICorner", dialogueFrame).CornerRadius = UDim.new(0, 8)
	local dStroke = Instance.new("UIStroke", dialogueFrame)
	dStroke.Color = Color3.fromRGB(255, 215, 50)
	dStroke.Thickness = 2
	dStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	dialogueText = Instance.new("TextLabel")
	dialogueText.Name = "DialogueText"
	dialogueText.Size = UDim2.new(1, -40, 1, -70) 
	dialogueText.Position = UDim2.new(0, 20, 0, 20)
	dialogueText.BackgroundTransparency = 1
	dialogueText.Text = ""
	dialogueText.Font = Enum.Font.GothamBold
	dialogueText.TextColor3 = Color3.new(1, 1, 1)
	dialogueText.TextScaled = true
	dialogueText.TextWrapped = true
	dialogueText.TextXAlignment = Enum.TextXAlignment.Left
	dialogueText.TextYAlignment = Enum.TextYAlignment.Top
	dialogueText.ZIndex = 11
	dialogueText.Parent = dialogueFrame

	local dtConstraint = Instance.new("UITextSizeConstraint", dialogueText)
	dtConstraint.MaxTextSize = 24
	dtConstraint.MinTextSize = 12

	nextButton = Instance.new("TextButton")
	nextButton.Name = "NextBtn"
	nextButton.Size = UDim2.new(0, 120, 0, 40)
	nextButton.Position = UDim2.new(1, -140, 1, -55) 
	nextButton.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
	nextButton.Text = "Next >"
	nextButton.Font = Enum.Font.GothamBold
	nextButton.TextColor3 = Color3.fromRGB(255, 215, 50)
	nextButton.TextScaled = true
	nextButton.Visible = false
	nextButton.ZIndex = 11
	nextButton.Parent = dialogueFrame

	Instance.new("UICorner", nextButton).CornerRadius = UDim.new(0, 6)
	local nStroke = Instance.new("UIStroke", nextButton)
	nStroke.Color = Color3.fromRGB(255, 215, 50)
	nStroke.Thickness = 2
	nStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local np = Instance.new("UIPadding", nextButton)
	np.PaddingTop = UDim.new(0, 5); np.PaddingBottom = UDim.new(0, 5)

	skipBtn.MouseButton1Click:Connect(function()
		if isSkipped then return end
		isSkipped = true
		pcall(function() SFXManager.Play("Click") end)
		Network:WaitForChild("TutorialAction"):FireServer("Complete")
		skipEvent:Fire()
		if tutorialContainer then tutorialContainer:Destroy() end
	end)

	task.spawn(function()
		while highlightFrame and highlightFrame.Parent do
			local tw = TweenService:Create(highlightFrame, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.2})
			tw:Play()
			task.wait(1.5)
		end
	end)
end

local function GetTabButton(tabName)
	return guiRoot:FindFirstChild(tabName .. "Button", true)
end

local function FindRandomEncounterButton()
	return guiRoot:FindFirstChild("RandomEncounterBtn", true)
end

local function FindStoryEncounterButton()
	return guiRoot:FindFirstChild("StoryEncounterBtn", true)
end

local function FindToggleTrainButton()
	return guiRoot:FindFirstChild("ToggleTrainBtn", true)
end

local function FindStrengthAddButton()
	local pStatsContainer = guiRoot:FindFirstChild("PlayerStatsCard", true)
	if not pStatsContainer then return nil end
	local strRow = pStatsContainer:FindFirstChild("Strength", true)
	if not strRow then return nil end

	local btnContainer = strRow:FindFirstChild("BtnContainer")
	return btnContainer and btnContainer:FindFirstChild("BtnAdd")
end

local function FindItemUseButton(itemName)
	local searchTxt = string.upper(itemName)
	for _, child in ipairs(guiRoot:GetDescendants()) do
		if child:IsA("TextLabel") and child.Name == "NameLabel" and string.find(string.upper(child.Text), searchTxt, 1, true) then
			local itemFrame = child.Parent
			local wrapper = itemFrame and itemFrame:FindFirstChild("BtnWrapper")
			if wrapper then
				local uBtn = wrapper:FindFirstChild("UseBtn")
				if uBtn then return uBtn end
			end
		end
	end
	return nil
end

local function AutoScrollTo(targetBtn)
	if not targetBtn then return end

	local sf = targetBtn:FindFirstAncestorOfClass("ScrollingFrame")
	if sf then
		RunService.PreRender:Wait()

		local targetY = targetBtn.AbsolutePosition.Y - sf.AbsolutePosition.Y + sf.CanvasPosition.Y
		local newPos = targetY - (sf.AbsoluteSize.Y / 2) + (targetBtn.AbsoluteSize.Y / 2)
		sf.CanvasPosition = Vector2.new(0, math.max(0, newPos))
	end
end

local function ClearHighlight()
	if highlightConn then
		highlightConn:Disconnect()
		highlightConn = nil
	end
	if highlightFrame then highlightFrame.Visible = false end

	if topMask and topMask.Parent then
		topMask.Size = UDim2.new(1, 0, 1, 0)
		topMask.Position = UDim2.new(0, 0, 0, 0)
		topMask.Visible = true
		topMask.Active = true 
		bottomMask.Visible = false
		leftMask.Visible = false
		rightMask.Visible = false
	end
end

local function HighlightDynamicTarget(targetBtn, allowScrolling)
	ClearHighlight()
	if isSkipped or not targetBtn then return end

	topMask.Visible = true; bottomMask.Visible = true
	leftMask.Visible = true; rightMask.Visible = true

	local activeState = not allowScrolling
	topMask.Active = activeState; bottomMask.Active = activeState
	leftMask.Active = activeState; rightMask.Active = activeState

	highlightConn = RunService.RenderStepped:Connect(function()
		if targetBtn and targetBtn.Parent then
			local isClipped = false
			local current = targetBtn.Parent
			while current and current:IsA("GuiObject") do
				if current:IsA("ScrollingFrame") then
					local sfTop = current.AbsolutePosition.Y
					local sfBottom = sfTop + current.AbsoluteSize.Y
					local btnTop = targetBtn.AbsolutePosition.Y
					local btnBottom = btnTop + targetBtn.AbsoluteSize.Y

					if btnBottom <= sfTop or btnTop >= sfBottom then
						isClipped = true
						break
					end
				end
				current = current.Parent
			end

			if isClipped then
				highlightFrame.Visible = false
				if not allowScrolling then
					topMask.Size = UDim2.new(1, 0, 1, 0); topMask.Position = UDim2.new(0, 0, 0, 0)
					topMask.Visible = true; bottomMask.Visible = false; leftMask.Visible = false; rightMask.Visible = false
				else
					topMask.Visible = false; bottomMask.Visible = false; leftMask.Visible = false; rightMask.Visible = false
				end
			else
				highlightFrame.Visible = true
				if not allowScrolling then
					topMask.Visible = true; bottomMask.Visible = true
					leftMask.Visible = true; rightMask.Visible = true
				else
					topMask.Visible = false; bottomMask.Visible = false
					leftMask.Visible = false; rightMask.Visible = false
				end

				local inset = GuiService:GetGuiInset()
				local tX = targetBtn.AbsolutePosition.X - 5
				local tY = targetBtn.AbsolutePosition.Y + inset.Y - 5
				local tW = targetBtn.AbsoluteSize.X + 10
				local tH = targetBtn.AbsoluteSize.Y + 10

				highlightFrame.Size = UDim2.new(0, tW, 0, tH)
				highlightFrame.Position = UDim2.new(0, tX, 0, tY)

				if not allowScrolling then
					topMask.Size = UDim2.new(1, 0, 0, tY); topMask.Position = UDim2.new(0, 0, 0, 0)
					bottomMask.Size = UDim2.new(1, 0, 1, -(tY + tH)); bottomMask.Position = UDim2.new(0, 0, 0, tY + tH)
					leftMask.Size = UDim2.new(0, tX, 0, tH); leftMask.Position = UDim2.new(0, 0, 0, tY)
					rightMask.Size = UDim2.new(1, -(tX + tW), 0, tH); rightMask.Position = UDim2.new(0, tX + tW, 0, tY)
				end
			end
		else
			highlightFrame.Visible = false
			ClearHighlight()
		end
	end)
end

local function SetUIHidden(isHidden)
	if not dialogueFrame or not topMask then return end
	dialogueFrame.Visible = not isHidden
	topMask.Size = UDim2.new(1, 0, 1, 0)
	topMask.Position = UDim2.new(0, 0, 0, 0)
	topMask.Visible = not isHidden
	topMask.Active = not isHidden

	bottomMask.Visible = false
	leftMask.Visible = false
	rightMask.Visible = false
	if highlightFrame then highlightFrame.Visible = false end
end

local function ShowDialogue(text, showNext)
	if isSkipped then return end
	ClearHighlight()
	SetUIHidden(false)

	dialogueText.Text = ""
	nextButton.Visible = false

	for i = 1, #text do
		if isSkipped then return end
		dialogueText.Text = string.sub(text, 1, i)
		task.wait(0.015)
	end

	if showNext and not isSkipped then
		nextButton.Visible = true
	end
end

local function WaitNext()
	if isSkipped then return end
	local bindable = Instance.new("BindableEvent")
	local conn, skipConn

	conn = nextButton.MouseButton1Click:Connect(function()
		pcall(function() SFXManager.Play("Click") end)
		if conn then conn:Disconnect() end; if skipConn then skipConn:Disconnect() end
		bindable:Fire()
	end)

	skipConn = skipEvent.Event:Connect(function()
		if conn then conn:Disconnect() end; if skipConn then skipConn:Disconnect() end
		bindable:Fire()
	end)

	bindable.Event:Wait()
end

local function ExecuteStep(dialogueTextStr, expectedTab, targetFindFunc, allowScroll, validationFunc)
	while not isSkipped do
		ClearHighlight()

		if expectedTab and switchTabFuncRef then
			pcall(switchTabFuncRef, expectedTab)
			task.wait(0.1)
		end

		ShowDialogue(dialogueTextStr, true)
		WaitNext(); if isSkipped then return end

		local targetBtn
		local lookAttempts = 0
		while not targetBtn and lookAttempts < 25 and not isSkipped do
			targetBtn = targetFindFunc()
			if not targetBtn then
				lookAttempts += 1
				task.wait(0.2)
			end
		end

		if targetBtn then
			if allowScroll then AutoScrollTo(targetBtn) end

			local clicked = false 

			local clickConn = targetBtn.MouseButton1Click:Connect(function() clicked = true end)
			local breakConn = skipEvent.Event:Connect(function() clicked = true end)

			dialogueFrame.Visible = false 
			HighlightDynamicTarget(targetBtn, allowScroll)

			local clickWaitTries = 0 
			repeat 
				task.wait(0.1)
				clickWaitTries += 0.1
			until clicked or isSkipped or clickWaitTries > 30

			if clickConn then clickConn:Disconnect() end
			if breakConn then breakConn:Disconnect() end 

			ClearHighlight()

			if clicked or isSkipped then 
				if validationFunc and not validationFunc() and not isSkipped then
					warn("Tutorial step verification failed. Step retrying.")
					continue
				end
				return
			end
		end

		if not isSkipped then
			ShowDialogue("Hmm, we got lost... let's try that again!", false)
			task.wait(1.5)
		end
	end
end


local function WaitForRealClick(findFunc)
	if isSkipped then return end

	local targetBtn = nil
	local waitTime = 0

	while not targetBtn and waitTime < 10 and not isSkipped do
		targetBtn = findFunc()
		task.wait(0.2)
		waitTime += 0.2
	end

	if not targetBtn or isSkipped then return end

	local clicked = false
	local conn = targetBtn.MouseButton1Click:Connect(function()
		clicked = true
	end)

	local skipConn = skipEvent.Event:Connect(function()
		clicked = true
	end)

	repeat task.wait(0.2) until clicked or isSkipped

	if conn then conn:Disconnect() end
	if skipConn then skipConn:Disconnect() end
	ClearHighlight()
end

local function PromptInteraction(dialogueTextStr, findTargetFunc, allowScroll)
	ShowDialogue(dialogueTextStr, true)
	WaitNext()
	if isSkipped then return end

	dialogueFrame.Visible = false 
	HighlightDynamicTarget(findTargetFunc, allowScroll)
	WaitForRealClick(findTargetFunc)
end

local function RunTutorial()
	task.wait(2)
	if isSkipped then return end

	ShowDialogue("Welcome to Bizarre Incremental! Let's get you ready for your bizarre adventure.", true)
	WaitNext(); if isSkipped then return end

	ExecuteStep(
		"Your journey begins in the SINGLEPLAYER tab. Click it to open the combat menu!",
		nil,
		function() return GetTabButton("Singleplayer") end,
		false
	)

	ExecuteStep(
		"Click the 'Random Encounter' button to start your first fight!",
		"Singleplayer", 
		FindRandomEncounterButton,
		true
	)

	if isSkipped then return end
	SetUIHidden(true) 
	ShowDialogue("Defeat the enemy by clicking your skills! I'll step back while you fight.", false)
	task.wait(3.5); if isSkipped then return end
	SetUIHidden(true)

	local combatEndStatus = nil
	local conn = Network.CombatUpdate.OnClientEvent:Connect(function(status)
		if status == "Defeat" or status == "Victory" or status == "End" then combatEndStatus = status end
	end)

	local cTimer = 0
	while not combatEndStatus and not isSkipped and cTimer < 60 do 
		task.wait(1); cTimer += 1
	end
	if conn then conn:Disconnect() end

	if isSkipped then return end

	ExecuteStep(
		"Ouch, that was tough! You need more stats to win. Click the TRAINING tab.",
		nil,
		function() return GetTabButton("Training") end,
		false
	)

	ExecuteStep(
		"Click the 'Start Training' button to begin passively gaining XP!",
		"Training",
		FindToggleTrainButton,
		true
	)

	if isSkipped then return end
	ShowDialogue("While you train, let's use some free XP I'm giving you to upgrade immediately!", true)
	Network:WaitForChild("TutorialAction"):FireServer("GiveXP")
	WaitNext(); if isSkipped then return end

	ExecuteStep("Click the INVENTORY tab to view your stats.", nil, function() return GetTabButton("Inventory") end, false)
	ExecuteStep("Click the 'PLAYER' sub-tab to see your character's combat stats.", "Inventory", function() return guiRoot:FindFirstChild("PLAYERButton", true) end, false)

	if isSkipped then return end
	ShowDialogue("Click the '+' button next to STRENGTH 5 times to spend your XP! I'll wait.", true)
	WaitNext(); if isSkipped then return end

	dialogueFrame.Visible = false

	local targetBtn = FindStrengthAddButton()
	HighlightDynamicTarget(targetBtn, false)

	local strGoal = (player:GetAttribute("Strength") or 1) + 5
	local strReached = false 

	local function ValidateStr()
		if (player:GetAttribute("Strength") or 1) >= strGoal then strReached = true end
	end 
	local strBind = player:GetAttributeChangedSignal("Strength"):Connect(ValidateStr)
	ValidateStr()

	local strTimer = 0
	while not strReached and not isSkipped and strTimer < 180 do
		task.wait(1); strTimer += 1 
	end

	if strBind then strBind:Disconnect() end 
	ClearHighlight()

	if isSkipped then return end

	ExecuteStep("Awesome! You're getting stronger. Let's return to the battle. Click SINGLEPLAYER.", nil, function() return GetTabButton("Singleplayer") end, false)

	local wonSecondBattle = false
	while not wonSecondBattle and not isSkipped do
		ExecuteStep("Click 'Random Encounter' and defeat this enemy! If you lose, try again.", "Singleplayer", FindRandomEncounterButton, true)
		if isSkipped then return end
		SetUIHidden(true)

		local c2Result = nil
		local c2 = Network.CombatUpdate.OnClientEvent:Connect(function(status)
			if status == "Defeat" or status == "Victory" or status == "End" then c2Result = status end
		end)

		while not c2Result and not isSkipped do task.wait(1) end
		if c2 then c2:Disconnect() end

		if c2Result == "Victory" then wonSecondBattle = true else
			SetUIHidden(false)
			ShowDialogue("You lost! That's okay, let's try that again.", true)
			WaitNext(); if isSkipped then return end
		end
	end

	if isSkipped then return end

	ShowDialogue("Great job! As a reward, you got a Stand Arrow from the enemy.", true)
	WaitNext(); if isSkipped then return end

	ExecuteStep("Click the INVENTORY tab to use it.", nil, function() return GetTabButton("Inventory") end, false)
	ExecuteStep("Click the 'STAND' sub-tab to view your special items.", "Inventory", function() return guiRoot:FindFirstChild("STANDButton", true) end, false)

	if isSkipped then return end 

	ExecuteStep("Scroll down to find your 'Stand Arrow' and click Use! Click Confirm if prompted.", "Inventory", function() 
		return FindItemUseButton("STAND ARROW") or FindItemUseButton("ARROW")
	end, true)

	if isSkipped then return end
	
	SetUIHidden(true)

	local standGained = false 
	local function checkStand() if player:GetAttribute("Stand") and player:GetAttribute("Stand") ~= "None" then standGained = true end end 

	local standBind = player:GetAttributeChangedSignal("Stand"):Connect(checkStand)
	checkStand()

	local sTimer = 0 
	while not standGained and sTimer < 60 and not isSkipped do task.wait(1); sTimer+=1 end 
	if standBind then standBind:Disconnect() end 

	SetUIHidden(false)

	if isSkipped then return end
	ShowDialogue("Whoa... you feel a new power awakening!", true)
	WaitNext(); if isSkipped then return end

	ExecuteStep("Let's head back to the SINGLEPLAYER tab one last time.", nil, function() return GetTabButton("Singleplayer") end, false)

	if isSkipped then return end
	ShowDialogue("Now that you have a Stand, you are ready for Story Missions!", true)
	WaitNext(); if isSkipped then return end

	ExecuteStep("Attempt the 'Story Encounter' when you feel ready. Good luck on your Bizarre Adventure!", "Singleplayer", FindStoryEncounterButton, false)

	if isSkipped then return end

	ClearHighlight()
	Network:WaitForChild("TutorialAction"):FireServer("Complete")

	if tutorialContainer then tutorialContainer:Destroy() end
end

function TutorialManager.Init(parentGui, switchTabFunc)
	local ls = player:WaitForChild("leaderstats", 15)
	if not ls then return end 
	task.wait(1) 

	if (player:GetAttribute("TutorialStep") or 0) > 0 then 
		return 
	end

	guiRoot = parentGui
	switchTabFuncRef = switchTabFunc
	isSkipped = false 

	BuildTutorialUI()

	tutorialContainer.Enabled = true
	task.spawn(RunTutorial)
end

return TutorialManager