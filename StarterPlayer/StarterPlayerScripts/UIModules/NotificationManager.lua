-- @ScriptType: ModuleScript
local NotificationManager = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local notificationContainer
local notifTemplate

function NotificationManager.Init(parentGui)
	local playerGui = parentGui.Parent
	local notifGui = playerGui:WaitForChild("NotificationGui")

	notificationContainer = notifGui:WaitForChild("NotificationContainer")
	notifTemplate = ReplicatedStorage:WaitForChild("UITemplates"):WaitForChild("NotifTemplate")

	local camera = workspace.CurrentCamera
	local function UpdateNotifLayout()
		local viewport = camera.ViewportSize
		local isPortrait = viewport.Y > viewport.X
		if isPortrait then
			notificationContainer.Position = UDim2.new(0.5, 0, 0.05, 0)
		else
			notificationContainer.Position = UDim2.new(0.61, 0, 0.05, 0)
		end
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateNotifLayout)
	UpdateNotifLayout()
end

function NotificationManager.Show(message)
	if not notificationContainer or not notifTemplate then return end

	local notifFrame = notifTemplate:Clone()
	notifFrame.Parent = notificationContainer

	local textLabel = notifFrame:WaitForChild("TextLabel")
	textLabel.Text = message

	local stroke = notifFrame:WaitForChild("UIStroke")

	local tweenIn = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, 55),
		BackgroundTransparency = 0.05
	})
	local strokeIn = TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0})
	local textIn = TweenService:Create(textLabel, TweenInfo.new(0.3), {TextTransparency = 0})

	tweenIn:Play()
	strokeIn:Play()
	textIn:Play()

	task.delay(4, function()
		if not notifFrame or not notifFrame.Parent then return end

		local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1
		})
		local strokeOut = TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 1})
		local textOut = TweenService:Create(textLabel, TweenInfo.new(0.3), {TextTransparency = 1})

		tweenOut:Play()
		strokeOut:Play()
		textOut:Play()

		tweenOut.Completed:Connect(function()
			notifFrame:Destroy()
		end)
	end)
end

return NotificationManager