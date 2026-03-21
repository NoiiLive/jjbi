-- @ScriptType: ModuleScript
local TrainingTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))

local trainLog, trainBarFill, currentTween, toggleTrainBtn, spinningStar, spinConnection
local isTraining = false
local trainTweenInfo = TweenInfo.new(4.8, Enum.EasingStyle.Linear)

local function PlayTrainingTween()
	if currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then return end
	trainBarFill.Size = UDim2.new(0, 0, 1, 0)
	currentTween = TweenService:Create(trainBarFill, trainTweenInfo, {Size = UDim2.new(1, 0, 1, 0)})
	currentTween:Play()
end

local function applyDoubleGoldBorder(parent)
	local outerStroke = Instance.new("UIStroke")
	outerStroke.Thickness = 3
	outerStroke.Color = Color3.fromRGB(255, 210, 60)
	outerStroke.LineJoinMode = Enum.LineJoinMode.Round
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local gradOut = Instance.new("UIGradient", outerStroke)
	gradOut.Rotation = -45
	gradOut.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 160, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 160, 30))
	}
	outerStroke.Parent = parent

	local innerFrame = Instance.new("Frame", parent)
	innerFrame.Name = "InnerGoldBorder"
	innerFrame.Size = UDim2.new(1, -6, 1, -6)
	innerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	innerFrame.BackgroundTransparency = 1
	innerFrame.ZIndex = parent.ZIndex

	local parentCorner = parent:FindFirstChildOfClass("UICorner")
	if parentCorner then
		local innerCorner = Instance.new("UICorner")
		innerCorner.CornerRadius = UDim.new(0, math.max(0, parentCorner.CornerRadius.Offset - 3))
		innerCorner.Parent = innerFrame
	end

	local innerStroke = Instance.new("UIStroke", innerFrame)
	innerStroke.Thickness = 1
	innerStroke.Color = Color3.fromRGB(255, 230, 100)
	innerStroke.LineJoinMode = Enum.LineJoinMode.Round
	innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local gradIn = Instance.new("UIGradient", innerStroke)
	gradIn.Rotation = 45
	gradIn.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 25))
	}
end

function TrainingTab.Init(parentFrame, tooltipMgr)
	-- ========================================================
	-- MAIN FRAME SETUP
	-- ========================================================
	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0.85, 0, 0.85, 0)
	mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
	mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	mainPanel.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	mainPanel.BorderSizePixel = 0
	mainPanel.ZIndex = 15
	mainPanel.ClipsDescendants = true
	mainPanel.Parent = parentFrame

	Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 12)
	applyDoubleGoldBorder(mainPanel)

	local bgPattern = Instance.new("ImageLabel")
	bgPattern.Name = "OverlayPattern"
	bgPattern.Image = "rbxassetid://79623015802180"
	bgPattern.ImageColor3 = Color3.fromRGB(180, 130, 255)
	bgPattern.ImageTransparency = 0.85
	bgPattern.BackgroundTransparency = 1
	bgPattern.ScaleType = Enum.ScaleType.Tile
	bgPattern.TileSize = UDim2.new(0, 500, 0, 250)
	bgPattern.Size = UDim2.new(1, 0, 1, 0)
	bgPattern.ZIndex = 16
	bgPattern.Parent = mainPanel

	-- Converted to ScrollingFrame
	local innerContent = Instance.new("ScrollingFrame")
	innerContent.Name = "InnerContent"
	innerContent.Size = UDim2.new(1, 0, 1, 0)
	innerContent.BackgroundTransparency = 1
	innerContent.ZIndex = 17
	innerContent.ScrollBarImageColor3 = Color3.fromRGB(150, 100, 200)
	innerContent.ScrollingDirection = Enum.ScrollingDirection.Y
	innerContent.BorderSizePixel = 0
	innerContent.Parent = mainPanel

	local mainPad = Instance.new("UIPadding", innerContent)
	mainPad.PaddingTop = UDim.new(0.04, 0)
	mainPad.PaddingBottom = UDim.new(0.04, 0)
	mainPad.PaddingLeft = UDim.new(0.04, 0)
	mainPad.PaddingRight = UDim.new(0.04, 0)

	local mainLayout = Instance.new("UIListLayout", innerContent)
	mainLayout.FillDirection = Enum.FillDirection.Vertical
	mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
	mainLayout.Padding = UDim.new(0.05, 0)
	mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 35)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "TRAINING"
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 50)
	titleLabel.TextScaled = true
	titleLabel.LayoutOrder = 1
	titleLabel.ZIndex = 22
	titleLabel.Parent = innerContent
	Instance.new("UITextSizeConstraint", titleLabel).MaxTextSize = 30

	-- ========================================================
	-- CENTER CONTAINER
	-- ========================================================
	local centerContainer = Instance.new("Frame")
	centerContainer.Name = "CenterContainer"
	centerContainer.Size = UDim2.new(0.8, 0, 0.8, 0)
	centerContainer.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	centerContainer.LayoutOrder = 2
	centerContainer.ZIndex = 20
	centerContainer.Parent = innerContent

	Instance.new("UICorner", centerContainer).CornerRadius = UDim.new(0, 12)
	local ccStroke = Instance.new("UIStroke", centerContainer)
	ccStroke.Color = Color3.fromRGB(90, 50, 120)
	ccStroke.Thickness = 2
	ccStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local ccPad = Instance.new("UIPadding", centerContainer)
	ccPad.PaddingTop = UDim.new(0.08, 0)
	ccPad.PaddingBottom = UDim.new(0.08, 0)
	ccPad.PaddingLeft = UDim.new(0.05, 0)
	ccPad.PaddingRight = UDim.new(0.05, 0)

	local ccLayout = Instance.new("UIListLayout", centerContainer)
	ccLayout.FillDirection = Enum.FillDirection.Vertical
	ccLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ccLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	ccLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ccLayout.Padding = UDim.new(0.06, 0)

	-- Spinning Star Icon Wrapper (Fixes UIListLayout rotation clipping)
	local starWrapper = Instance.new("Frame")
	starWrapper.Name = "StarWrapper"
	starWrapper.Size = UDim2.new(0, 120, 0, 120)
	starWrapper.BackgroundTransparency = 1
	starWrapper.LayoutOrder = 1
	starWrapper.ZIndex = 21
	starWrapper.Parent = centerContainer

	local starAspect = Instance.new("UIAspectRatioConstraint", starWrapper)
	starAspect.AspectRatio = 1
	starAspect.DominantAxis = Enum.DominantAxis.Width

	spinningStar = Instance.new("ImageLabel")
	spinningStar.Name = "SpinningStar"
	spinningStar.Size = UDim2.new(1, 0, 1, 0)
	spinningStar.Position = UDim2.new(0.5, 0, 0.5, 0)
	spinningStar.AnchorPoint = Vector2.new(0.5, 0.5)
	spinningStar.BackgroundTransparency = 1
	spinningStar.Image = "rbxassetid://5639840603" 
	spinningStar.ImageColor3 = Color3.fromRGB(255, 215, 50)
	spinningStar.ZIndex = 21
	spinningStar.Parent = starWrapper

	-- Training Log Text
	trainLog = Instance.new("TextLabel")
	trainLog.Name = "TrainLog"
	trainLog.Size = UDim2.new(1, 0, 0.15, 0)
	trainLog.BackgroundTransparency = 1
	trainLog.Font = Enum.Font.GothamBold
	trainLog.TextColor3 = Color3.fromRGB(220, 220, 220)
	trainLog.TextScaled = true
	trainLog.RichText = true
	trainLog.Text = "Resting. Start training to gain passive XP/Yen."
	trainLog.LayoutOrder = 2
	trainLog.ZIndex = 21
	trainLog.Parent = centerContainer
	Instance.new("UITextSizeConstraint", trainLog).MaxTextSize = 20

	-- Training Progress Bar
	local trainBarBg = Instance.new("Frame")
	trainBarBg.Name = "TrainBarBg"
	trainBarBg.Size = UDim2.new(0.8, 0, 0, 25)
	trainBarBg.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	trainBarBg.ClipsDescendants = true
	trainBarBg.LayoutOrder = 3
	trainBarBg.ZIndex = 21
	trainBarBg.Parent = centerContainer

	Instance.new("UICorner", trainBarBg).CornerRadius = UDim.new(0, 6)
	local barStroke = Instance.new("UIStroke", trainBarBg)
	barStroke.Color = Color3.fromRGB(90, 50, 120)
	barStroke.Thickness = 1
	barStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	trainBarFill = Instance.new("Frame")
	trainBarFill.Name = "TrainBarFill"
	trainBarFill.Size = UDim2.new(0, 0, 1, 0)
	trainBarFill.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
	trainBarFill.BorderSizePixel = 0
	trainBarFill.ZIndex = 22
	trainBarFill.Parent = trainBarBg

	Instance.new("UICorner", trainBarFill).CornerRadius = UDim.new(0, 6)

	-- Toggle Button
	toggleTrainBtn = Instance.new("TextButton")
	toggleTrainBtn.Name = "ToggleTrainBtn"
	toggleTrainBtn.Size = UDim2.new(0.5, 0, 0, 50)
	toggleTrainBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
	toggleTrainBtn.Font = Enum.Font.GothamBlack
	toggleTrainBtn.TextColor3 = Color3.new(1, 1, 1)
	toggleTrainBtn.TextScaled = true
	toggleTrainBtn.Text = "Start Training"
	toggleTrainBtn.LayoutOrder = 4
	toggleTrainBtn.ZIndex = 23
	toggleTrainBtn.Parent = centerContainer

	Instance.new("UICorner", toggleTrainBtn).CornerRadius = UDim.new(0, 8)
	local btnStroke = Instance.new("UIStroke", toggleTrainBtn)
	btnStroke.Color = Color3.fromRGB(200, 150, 255)
	btnStroke.Thickness = 2
	btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Instance.new("UITextSizeConstraint", toggleTrainBtn).MaxTextSize = 22

	-- ========================================================
	-- LOGIC & EVENTS
	-- ========================================================
	toggleTrainBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		isTraining = not isTraining
		player:SetAttribute("IsTraining", isTraining)

		if isTraining then
			toggleTrainBtn.Text = "Stop Training"
			toggleTrainBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
			trainLog.Text = "<font color='#55FF55'>Training started... Pushing limits!</font>"
			PlayTrainingTween()
			spinConnection = RunService.RenderStepped:Connect(function() spinningStar.Rotation = spinningStar.Rotation + 0.5 end)
		else
			toggleTrainBtn.Text = "Start Training"
			toggleTrainBtn.BackgroundColor3 = Color3.fromRGB(120, 20, 160)
			trainLog.Text = "Resting. Start training to gain passive XP/Yen."
			trainBarFill.Size = UDim2.new(0, 0, 1, 0)
			if currentTween then currentTween:Cancel() end
			if spinConnection then spinConnection:Disconnect() end
		end
		Network:WaitForChild("ToggleTraining"):FireServer(isTraining)
	end)

	task.spawn(function()
		while task.wait(5) do
			if isTraining then PlayTrainingTween() end
		end
	end)

	task.spawn(function()
		task.wait(2)
		if player:GetAttribute("HasAutoTraining") and not isTraining then
			isTraining = true
			player:SetAttribute("IsTraining", isTraining)
			toggleTrainBtn.Text = "Stop Training"
			toggleTrainBtn.BackgroundColor3 = Color3.fromRGB(180, 20, 60)
			trainLog.Text = "<font color='#55FF55'>Training started... Pushing limits!</font>"
			PlayTrainingTween()
			spinConnection = RunService.RenderStepped:Connect(function() spinningStar.Rotation = spinningStar.Rotation + 0.5 end)
			Network:WaitForChild("ToggleTraining"):FireServer(isTraining)
		end
	end)

	-- ========================================================
	-- RESPONSIVE LAYOUT LOGIC
	-- ========================================================
	local camera = workspace.CurrentCamera
	local resizeConn

	local function UpdateLayoutForScreen()
		if not parentFrame.Parent then
			if resizeConn then resizeConn:Disconnect() end
			return
		end

		local vp = camera.ViewportSize
		if vp.X >= 1050 then 
			mainPanel.Size = UDim2.new(0.80, 0, 0.88, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
		elseif vp.X >= 600 and vp.X < 1050 then 
			mainPanel.Size = UDim2.new(0.92, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
		else 
			mainPanel.Size = UDim2.new(0.96, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0) 
		end

		local panelAbsHeight = vp.Y * mainPanel.Size.Y.Scale
		local minHeight = 500

		if panelAbsHeight < minHeight then
			innerContent.CanvasSize = UDim2.new(0, 0, 0, minHeight)
			innerContent.ScrollBarImageTransparency = 0
			innerContent.ScrollBarThickness = 6
			innerContent.ScrollingEnabled = true
		else
			innerContent.CanvasSize = UDim2.new(0, 0, 1, 0)
			innerContent.ScrollBarImageTransparency = 1
			innerContent.ScrollBarThickness = 0
			innerContent.ScrollingEnabled = false
		end
	end

	resizeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
	UpdateLayoutForScreen()
end

function TrainingTab.OnTick(data)
	if isTraining and trainLog then
		trainLog.Text = "<font color='#55FFFF'>Gained +" .. data.XP .. " XP</font> and <font color='#55FF55'>+" .. data.Yen .. " Yen</font>. (Part " .. data.Part .. " Multiplier!)"
	end
end

return TrainingTab