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

local currentDuration = 5

local function PlayTrainingTween()
	if currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then return end
	trainBarFill.Size = UDim2.new(0, 0, 1, 0)
	local tweenInfo = TweenInfo.new(currentDuration, Enum.EasingStyle.Linear)
	currentTween = TweenService:Create(trainBarFill, tweenInfo, {Size = UDim2.new(1, 0, 1, 0)})
	currentTween:Play()
end

function TrainingTab.Init(parentFrame, tooltipMgr)
	local mainPanel = parentFrame:WaitForChild("MainPanel")
	local innerContent = mainPanel:WaitForChild("InnerContent")
	local centerContainer = innerContent:WaitForChild("CenterContainer")
	
	local starWrapper = centerContainer:WaitForChild("StarWrapper")
	spinningStar = starWrapper:WaitForChild("SpinningStar")
	
	trainLog = centerContainer:WaitForChild("TrainLog")
	
	local trainBarBg = centerContainer:WaitForChild("TrainBarBg")
	trainBarFill = trainBarBg:WaitForChild("TrainBarFill")
	
	toggleTrainBtn = centerContainer:WaitForChild("ToggleTrainBtn")

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
		while true do
			task.wait(currentDuration)
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
	if data.Duration then
		currentDuration = data.Duration
	end
	
	if isTraining and trainLog then
		trainLog.Text = "<font color='#55FFFF'>Gained +" .. data.XP .. " XP</font> and <font color='#55FF55'>+" .. data.Yen .. " Yen</font>. (Part " .. data.Part .. " Multiplier!)"
	end
end

return TrainingTab