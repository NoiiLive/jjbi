-- @ScriptType: ModuleScript
local NotificationManager = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local notificationContainer
local notificationTemplate

function NotificationManager.Init(parentGui)
	notificationContainer = parentGui:WaitForChild("NotificationContainer")
	notificationTemplate = ReplicatedStorage:WaitForChild("JJBITemplates"):WaitForChild("NotificationTemplate")
end

function NotificationManager.Show(message)
	if not notificationContainer or not notificationTemplate then return end

	local notifFrame = notificationTemplate:Clone()
	local stroke = notifFrame:WaitForChild("UIStroke")
	local textLabel = notifFrame:WaitForChild("TextLabel")

	textLabel.Text = message
	notifFrame.Parent = notificationContainer

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