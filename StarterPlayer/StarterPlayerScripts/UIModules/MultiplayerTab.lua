-- @ScriptType: ModuleScript
local MultiplayerTab = {}

local UIModules = script.Parent
local LeaderboardTab = require(UIModules:WaitForChild("LeaderboardTab"))
local GangsTab = require(UIModules:WaitForChild("GangsTab"))
local ArenaTab = require(UIModules:WaitForChild("ArenaTab"))
local TradingTab = require(UIModules:WaitForChild("TradingTab"))
local RaidsTab = require(UIModules:WaitForChild("RaidsTab"))
local SBREventTab = require(UIModules:WaitForChild("SBREventTab"))
local SFXManager = require(UIModules:WaitForChild("SFXManager"))

local activeSubTab = "Gangs"

function MultiplayerTab.Init(parentFrame, tooltipMgr, switchTabFunc)
	local mainPanel = parentFrame:WaitForChild("MainPanel")
	local innerContent = mainPanel:WaitForChild("InnerContent")

	local subNavFrame = innerContent:WaitForChild("SubNavFrame")
	local tabContainer = innerContent:WaitForChild("TabContainer")

	local tabs = {
		{Name = "Gangs", Btn = subNavFrame:WaitForChild("GangsBtn"), Frame = tabContainer:WaitForChild("GangsTabContent")},
		{Name = "SBR", Btn = subNavFrame:WaitForChild("SBRBtn"), Frame = tabContainer:WaitForChild("SBRTabContent")},
		{Name = "Raids", Btn = subNavFrame:WaitForChild("RaidsBtn"), Frame = tabContainer:WaitForChild("RaidsTabContent")},
		{Name = "Arena", Btn = subNavFrame:WaitForChild("ArenaBtn"), Frame = tabContainer:WaitForChild("ArenaTabContent")},
		{Name = "Trades", Btn = subNavFrame:WaitForChild("TradesBtn"), Frame = tabContainer:WaitForChild("TradesTabContent")},
		{Name = "Leaderboards", Btn = subNavFrame:WaitForChild("LeaderboardsBtn"), Frame = tabContainer:WaitForChild("LeaderboardsTabContent")}
	}

	local function SwitchSubTab(targetName)
		SFXManager.Play("Click")
		activeSubTab = targetName

		for _, tab in ipairs(tabs) do
			local isActive = (tab.Name == targetName)
			tab.Frame.Visible = isActive

			tab.Btn.BackgroundColor3 = isActive and Color3.fromRGB(70, 30, 100) or Color3.fromRGB(30, 20, 50)
			tab.Btn.TextColor3 = isActive and Color3.fromRGB(255, 235, 130) or Color3.fromRGB(200, 200, 220)

			local stroke = tab.Btn:FindFirstChild("UIStroke")
			if stroke then
				stroke.Color = isActive and Color3.fromRGB(255, 215, 50) or Color3.fromRGB(90, 50, 120)
				stroke.Thickness = isActive and 2 or 1
			end
		end
	end

	for _, tab in ipairs(tabs) do
		tab.Btn.MouseButton1Click:Connect(function() SwitchSubTab(tab.Name) end)

		if tab.Name == "Leaderboards" then LeaderboardTab.Init(tab.Frame, tooltipMgr)
		elseif tab.Name == "Gangs" then GangsTab.Init(tab.Frame, tooltipMgr)
		elseif tab.Name == "Arena" then ArenaTab.Init(tab.Frame, tooltipMgr)
		elseif tab.Name == "Trades" then TradingTab.Init(tab.Frame, tooltipMgr)
		elseif tab.Name == "Raids" then RaidsTab.Init(tab.Frame, tooltipMgr)
		elseif tab.Name == "SBR" then SBREventTab.Init(tab.Frame, tooltipMgr)
		end
	end

	SwitchSubTab("Gangs")

	local camera = workspace.CurrentCamera
	local resizeConn

	local function UpdateLayoutForScreen()
		if not parentFrame.Parent then
			if resizeConn then resizeConn:Disconnect() end
			return
		end

		local vp = camera.ViewportSize
		if vp.X >= 1050 then
			mainPanel.Size = UDim2.new(0.85, 0, 0.88, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
		elseif vp.X >= 600 and vp.X < 1050 then
			mainPanel.Size = UDim2.new(0.92, 0, 0.85, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
		else
			mainPanel.Size = UDim2.new(0.96, 0, 0.85, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
		end
	end

	resizeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
	UpdateLayoutForScreen()
end

function MultiplayerTab.HandleGangUpdate(action, data)
	if GangsTab.HandleUpdate then GangsTab.HandleUpdate(action, data) end
end

function MultiplayerTab.HandleArenaUpdate(action, data)
	if ArenaTab.HandleUpdate then ArenaTab.HandleUpdate(action, data) end
end

function MultiplayerTab.HandleTradeUpdate(action, data)
	if TradingTab.HandleUpdate then TradingTab.HandleUpdate(action, data) end
end

return MultiplayerTab