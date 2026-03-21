-- @ScriptType: ModuleScript
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

local function GetCleanText(txt)
	return string.upper(string.gsub(txt, "<[^>]+>", ""))
end

local function GetTabButton(tabName)
	return guiRoot:FindFirstChild(tabName .. "Button", true) or guiRoot:FindFirstChild(tabName .. "TabBtn", true)
end

local function FindContentButton(partialText)
	local targetText = string.upper(partialText)
	local results = {}
	local function search(node)
		for _, child in ipairs(node:GetChildren()) do
			if child:IsA("TextButton") and child.Visible then
				local isNav = false
				local p = child
				while p and p ~= guiRoot do
					if p.Name == "NavBar" or p.Name == "TabContainer" or p.Name == "NavContainer" then
						isNav = true
						break
					end
					p = p.Parent
				end

				if not isNav then
					if string.find(GetCleanText(child.Text), targetText, 1, true) then
						table.insert(results, child)
					end
				end
			end
			search(child)
		end
	end
	search(guiRoot)
	return results
end

local function FindStrengthPlus5Button()
	local result = nil
	local function search(node)
		for _, child in ipairs(node:GetChildren()) do
			if child:IsA("TextLabel") and string.find(string.upper(child.Text), "STRENGTH") then
				local parentRow = child.Parent
				if parentRow then
					for _, sibling in ipairs(parentRow:GetChildren()) do
						if sibling:IsA("Frame") then
							for _, btn in ipairs(sibling:GetChildren()) do
								if btn:IsA("TextButton") and btn.Text == "+5" then
									result = btn
									return
								end
							end
						end
					end
				end
			end
			search(child)
			if result then return end
		end
	end
	search(guiRoot)
	return result
end

local function FindItemUseButton(itemName)
	local searchTxt = string.upper(itemName)
	local result = nil
	local function searchTree(node)
		for _, child in ipairs(node:GetChildren()) do
			if child:IsA("TextLabel") and child.Text and string.find(string.upper(child.Text), searchTxt, 1, true) then
				local parentRow = child.Parent
				if parentRow and parentRow.Name ~= "DialogueFrame" then
					for _, sibling in ipairs(parentRow:GetChildren()) do
						if sibling:IsA("Frame") then
							for _, btn in ipairs(sibling:GetChildren()) do
								if btn:IsA("TextButton") and (string.find(string.upper(btn.Text), "USE") or string.find(string.upper(btn.Text), "CONFIRM")) then
									result = btn
									return
								end
							end
						end
					end
				end
			end
			searchTree(child)
			if result then return end
		end
	end
	searchTree(guiRoot)
	return result
end

local function AutoScrollTo(targetBtn)
	if not targetBtn then return end

	local sfList = {}
	local curr = targetBtn
	while curr do
		local sf = curr:FindFirstAncestorOfClass("ScrollingFrame")
		if sf then
			table.insert(sfList, sf)
			curr = sf
		else
			break
		end
	end

	for _, sf in ipairs(sfList) do
		RunService.Heartbeat:Wait()
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

local function HighlightDynamicTarget(findFunc, allowScrolling)
	ClearHighlight()
	if isSkipped then return end

	topMask.Visible = true
	bottomMask.Visible = true
	leftMask.Visible = true
	rightMask.Visible = true

	local activeState = not allowScrolling
	topMask.Active = activeState
	bottomMask.Active = activeState
	leftMask.Active = activeState
	rightMask.Active = activeState

	highlightConn = RunService.RenderStepped:Connect(function()
		local targetBtn = findFunc()
		if targetBtn and targetBtn.Parent then

			local isClipped = false
			local current = targetBtn.Parent
			while current and current:IsA("GuiObject") do
				if current:IsA("ScrollingFrame") then
					local sfTop = current.AbsolutePosition.Y
					local sfBottom = sfTop + current.AbsoluteSize.Y
					local btnTop = targetBtn.AbsolutePosition.Y
					local btnBottom = btnTop + targetBtn.AbsoluteSize.Y
					if btnBottom < sfTop or btnTop > sfBottom then
						isClipped = true
						break
					end
				end
				current = current.Parent
			end

			if isClipped then
				highlightFrame.Visible = false
				if not allowScrolling then
					topMask.Size = UDim2.new(1, 0, 1, 0)
					topMask.Position = UDim2.new(0, 0, 0, 0)
					topMask.Visible = true
					bottomMask.Visible = false
					leftMask.Visible = false
					rightMask.Visible = false
				else
					topMask.Visible = false
					bottomMask.Visible = false
					leftMask.Visible = false
					rightMask.Visible = false
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
					topMask.Size = UDim2.new(1, 0, 0, tY)
					topMask.Position = UDim2.new(0, 0, 0, 0)

					bottomMask.Size = UDim2.new(1, 0, 1, -(tY + tH))
					bottomMask.Position = UDim2.new(0, 0, 0, tY + tH)

					leftMask.Size = UDim2.new(0, tX, 0, tH)
					leftMask.Position = UDim2.new(0, 0, 0, tY)

					rightMask.Size = UDim2.new(1, -(tX + tW), 0, tH)
					rightMask.Position = UDim2.new(0, tX + tW, 0, tY)
				end
			end
		else
			highlightFrame.Visible = false
			if not allowScrolling then
				topMask.Size = UDim2.new(1, 0, 1, 0)
				topMask.Position = UDim2.new(0, 0, 0, 0)
				topMask.Visible = true
				bottomMask.Visible = false
				leftMask.Visible = false
				rightMask.Visible = false
			else
				topMask.Visible = false; bottomMask.Visible = false
				leftMask.Visible = false; rightMask.Visible = false
			end
		end
	end)
end

local function SetUIHidden(isHidden)
	if not dialogueFrame or not topMask then return end
	dialogueFrame.Visible = not isHidden
	topMask.Visible = not isHidden

	if not isHidden then
		topMask.Size = UDim2.new(1, 0, 1, 0)
		topMask.Position = UDim2.new(0, 0, 0, 0)
	end

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
		if conn then conn:Disconnect() end
		if skipConn then skipConn:Disconnect() end
		bindable:Fire()
	end)

	skipConn = skipEvent.Event:Connect(function()
		if conn then conn:Disconnect() end
		if skipConn then skipConn:Disconnect() end
		bindable:Fire()
	end)

	bindable.Event:Wait()
end

local function WaitForRealClick(findFunc)
	if isSkipped then return end
	local targetBtn = findFunc()
	if not targetBtn then 
		task.wait(2)
		return 
	end

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

	PromptInteraction("Your journey begins in the SINGLEPLAYER tab. Click it to open the combat menu!", function() return GetTabButton("Singleplayer") end, false)
	if isSkipped then return end

	PromptInteraction("Click an ENCOUNTER button to start your first fight!", function() return FindContentButton("ENCOUNTER")[1] end, true)
	if isSkipped then return end

	SetUIHidden(true) 

	ShowDialogue("Defeat the enemy by clicking your skills! I'll step back while you fight.", false)
	task.wait(3.5); if isSkipped then return end
	SetUIHidden(true)

	local combatDone = false
	local c = Network.CombatUpdate.OnClientEvent:Connect(function(status)
		if status == "Defeat" or status == "Victory" or status == "End" then
			combatDone = true
		end
	end)

	local timer = 0
	while not combatDone and timer < 45 and not isSkipped do
		task.wait(1)
		timer += 1
	end
	c:Disconnect()
	if isSkipped then return end

	PromptInteraction("Ouch, that was tough! You need more stats to win. Click the TRAINING tab.", function() return GetTabButton("Training") end, false)
	if isSkipped then return end

	PromptInteraction("Click the 'TRAIN' button to start passively gaining XP!", function() return FindContentButton("START TRAINING")[1] or FindContentButton("TRAIN")[1] end, true)
	if isSkipped then return end

	ShowDialogue("While you train, let's use some free XP I'm giving you to upgrade immediately!", true)
	Network:WaitForChild("TutorialAction"):FireServer("GiveXP")
	WaitNext(); if isSkipped then return end

	PromptInteraction("Click the INVENTORY tab to view your stats.", function() return GetTabButton("Inventory") end, false)
	if isSkipped then return end

	ShowDialogue("Click the '+5' button next to STRENGTH to spend your XP! I'll wait.", true)
	WaitNext(); if isSkipped then return end

	dialogueFrame.Visible = false
	HighlightDynamicTarget(FindStrengthPlus5Button, false)

	local startStrength = player:GetAttribute("Strength") or 1
	while (player:GetAttribute("Strength") or 1) < startStrength + 5 and not isSkipped do
		task.wait(0.2)
	end
	ClearHighlight()
	if isSkipped then return end

	PromptInteraction("Awesome! You're getting stronger. Let's return to the battle. Click SINGLEPLAYER.", function() return GetTabButton("Singleplayer") end, false)
	if isSkipped then return end

	local wonSecondBattle = false
	while not wonSecondBattle and not isSkipped do
		PromptInteraction("Click ENCOUNTER and defeat this enemy! If you lose, try again.", function() return FindContentButton("ENCOUNTER")[1] end, true)
		if isSkipped then return end

		SetUIHidden(true)

		local c2Done = false
		local c2Result = "End"
		local c2 = Network.CombatUpdate.OnClientEvent:Connect(function(status)
			if status == "Defeat" or status == "Victory" or status == "End" then
				c2Done = true
				c2Result = status
			end
		end)

		while not c2Done and not isSkipped do
			task.wait(0.5)
		end
		c2:Disconnect()
		if isSkipped then return end

		if c2Result == "Victory" then
			wonSecondBattle = true
		else
			ShowDialogue("You lost! That's okay, let's try that again.", true)
			WaitNext(); if isSkipped then return end
		end
	end

	if isSkipped then return end

	ShowDialogue("Great job! As a reward, you got a Stand Arrow from the enemy.", true)
	WaitNext(); if isSkipped then return end

	PromptInteraction("Click the INVENTORY tab to use it.", function() return GetTabButton("Inventory") end, false)
	if isSkipped then return end

	PromptInteraction("Click the 'STAND & STYLE' sub-tab to view your special items.", function() return FindContentButton("STAND & STYLE")[1] end, false)
	if isSkipped then return end

	ShowDialogue("Scroll down to find your 'Stand Arrow' and click Use! Click Confirm if prompted.", true)
	WaitNext(); if isSkipped then return end

	dialogueFrame.Visible = false

	local arrowBtn = nil
	local findArrowTimeout = 0
	repeat
		arrowBtn = FindItemUseButton("STAND ARROW") or FindItemUseButton("ARROW")
		task.wait(0.5)
		findArrowTimeout += 0.5
	until arrowBtn or isSkipped or findArrowTimeout >= 5

	if isSkipped then return end

	if arrowBtn then
		AutoScrollTo(arrowBtn)
		HighlightDynamicTarget(function()
			return FindItemUseButton("STAND ARROW") or FindItemUseButton("ARROW")
		end, true)
	end

	local standWaitTimer = 0
	while player:GetAttribute("Stand") == "None" and standWaitTimer < 20 and not isSkipped do
		task.wait(1)
		standWaitTimer += 1
	end

	ClearHighlight()
	SetUIHidden(false)

	if isSkipped then return end

	ShowDialogue("Whoa... you feel a new power awakening!", true)
	WaitNext(); if isSkipped then return end

	PromptInteraction("Let's head back to the SINGLEPLAYER tab one last time.", function() return GetTabButton("Singleplayer") end, false)
	if isSkipped then return end

	ShowDialogue("Now that you have a Stand, you are ready for Story Missions!", true)
	WaitNext(); if isSkipped then return end

	PromptInteraction("Attempt the 'Story Encounter' when you feel ready. Good luck on your Bizarre Adventure!", function() return FindContentButton("STORY")[1] end, false)
	if isSkipped then return end

	ClearHighlight()
	Network:WaitForChild("TutorialAction"):FireServer("Complete")

	if tutorialContainer then
		tutorialContainer:Destroy()
	end
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