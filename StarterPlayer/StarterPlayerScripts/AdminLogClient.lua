-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local AdminLogsUI = Network:WaitForChild("AdminLogsUI")

local currentLogs = nil
local currentTab = "Commands"
local gui = nil
local scrollFrame = nil

local function FormatTime(ts)
	local d = os.date("*t", ts)
	return string.format("%02d:%02d:%02d", d.hour, d.min, d.sec)
end

local function RenderLogs(searchText)
	if not scrollFrame then return end
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local logs = currentLogs[currentTab] or {}
	local yOffset = 0

	for _, logData in ipairs(logs) do
		local searchMatch = false
		local lowerSearch = string.lower(searchText or "")

		if currentTab == "Commands" then
			if lowerSearch == "" or string.find(string.lower(logData.Player), lowerSearch) then searchMatch = true end
		elseif currentTab == "Trades" then
			if lowerSearch == "" or string.find(string.lower(logData.Player1), lowerSearch) or string.find(string.lower(logData.Player2), lowerSearch) then searchMatch = true end
		elseif currentTab == "Purchases" then
			if lowerSearch == "" or string.find(string.lower(logData.Player), lowerSearch) or string.find(string.lower(logData.Target), lowerSearch) then searchMatch = true end
		end

		if searchMatch then
			local logFrame = Instance.new("Frame")
			logFrame.Size = UDim2.new(1, 0, 0, 30)
			logFrame.Position = UDim2.new(0, 0, 0, yOffset)
			logFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			logFrame.BorderSizePixel = 0
			logFrame.Parent = scrollFrame

			local timeLabel = Instance.new("TextLabel")
			timeLabel.Size = UDim2.new(0, 70, 1, 0)
			timeLabel.BackgroundTransparency = 1
			timeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			timeLabel.Text = "[" .. FormatTime(logData.Time) .. "]"
			timeLabel.Font = Enum.Font.Code
			timeLabel.TextSize = 14
			timeLabel.Parent = logFrame

			local descLabel = Instance.new("TextLabel")
			descLabel.Size = UDim2.new(1, -80, 1, 0)
			descLabel.Position = UDim2.new(0, 75, 0, 0)
			descLabel.BackgroundTransparency = 1
			descLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.Font = Enum.Font.SourceSans
			descLabel.TextSize = 16
			descLabel.Parent = logFrame

			if currentTab == "Commands" then
				descLabel.Text = logData.Player .. " used: " .. logData.FullText
			elseif currentTab == "Trades" then
				descLabel.Text = logData.Player1 .. " & " .. logData.Player2 .. " | " .. logData.Player1 .. " gave: [" .. logData.Offer1 .. "] | " .. logData.Player2 .. " gave: [" .. logData.Offer2 .. "]"
			elseif currentTab == "Purchases" then
				local targetStr = logData.Player == logData.Target and "themselves" or logData.Target
				descLabel.Text = logData.Player .. " purchased " .. logData.Item .. " for " .. targetStr
			end

			yOffset = yOffset + 35
		end
	end
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

AdminLogsUI.OnClientEvent:Connect(function(logs)
	currentLogs = logs

	if gui then gui:Destroy() end

	gui = Instance.new("ScreenGui")
	gui.Name = "AdminLogsGui"
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 600, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = " Admin Logs"
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.BorderSizePixel = 0
	title.Parent = mainFrame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -30, 0, 0)
	closeBtn.BackgroundTransparency = 1
	closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.Parent = mainFrame

	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
		gui = nil
	end)

	local searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -20, 0, 30)
	searchBox.Position = UDim2.new(0, 10, 0, 40)
	searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	searchBox.Text = ""
	searchBox.PlaceholderText = "Search player username..."
	searchBox.Font = Enum.Font.SourceSans
	searchBox.TextSize = 16
	searchBox.BorderSizePixel = 0
	searchBox.Parent = mainFrame

	local tabContainer = Instance.new("Frame")
	tabContainer.Size = UDim2.new(1, -20, 0, 30)
	tabContainer.Position = UDim2.new(0, 10, 0, 80)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = mainFrame

	local tabs = {"Commands", "Trades", "Purchases"}
	local tabWidth = 1 / #tabs
	local tabButtons = {}

	for i, tabName in ipairs(tabs) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(tabWidth, -5, 1, 0)
		btn.Position = UDim2.new((i-1)*tabWidth, 0, 0, 0)
		btn.BackgroundColor3 = tabName == currentTab and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(30, 30, 30)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = tabName
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 14
		btn.BorderSizePixel = 0
		btn.Parent = tabContainer

		btn.MouseButton1Click:Connect(function()
			currentTab = tabName
			for _, b in ipairs(tabButtons) do b.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			RenderLogs(searchBox.Text)
		end)
		table.insert(tabButtons, btn)
	end

	scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -20, 1, -130)
	scrollFrame.Position = UDim2.new(0, 10, 0, 120)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.Parent = mainFrame

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		RenderLogs(searchBox.Text)
	end)

	RenderLogs("")
end)