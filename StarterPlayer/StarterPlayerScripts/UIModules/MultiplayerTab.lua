-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local MultiplayerTab = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local UIModules = script.Parent

-- Temporarily disabled
-- local GangsTab = require(UIModules:WaitForChild("GangsTab"))
-- local ArenaTab = require(UIModules:WaitForChild("ArenaTab"))
-- local TradingTab = require(UIModules:WaitForChild("TradingTab"))
-- local SBREventTab = require(UIModules:WaitForChild("SBREventTab"))

local RaidsTab = require(UIModules:WaitForChild("RaidsTab"))
local LeaderboardTab = require(UIModules:WaitForChild("LeaderboardTab"))
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))

local function applyDoubleGoldBorder(parent)
	local outerStroke = Instance.new("UIStroke")
	outerStroke.Thickness = 3
	outerStroke.Color = Color3.fromRGB(255, 210, 60)
	outerStroke.LineJoinMode = Enum.LineJoinMode.Round
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradOut = Instance.new("UIGradient")
	gradOut.Rotation = -45
	gradOut.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 160, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 160, 30))
	}
	gradOut.Parent = outerStroke
	outerStroke.Parent = parent

	local innerFrame = Instance.new("Frame")
	innerFrame.Name = "InnerGoldBorder"
	innerFrame.Size = UDim2.new(1, -6, 1, -6)
	innerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	innerFrame.BackgroundTransparency = 1
	innerFrame.ZIndex = parent.ZIndex
	innerFrame.Parent = parent

	local parentCorner = parent:FindFirstChildOfClass("UICorner")
	if parentCorner then
		local innerCorner = Instance.new("UICorner")
		innerCorner.CornerRadius = UDim.new(0, math.max(0, parentCorner.CornerRadius.Offset - 3))
		innerCorner.Parent = innerFrame
	end

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Thickness = 1
	innerStroke.Color = Color3.fromRGB(255, 230, 100)
	innerStroke.LineJoinMode = Enum.LineJoinMode.Round
	innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradIn = Instance.new("UIGradient")
	gradIn.Rotation = 45
	gradIn.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 25))
	}
	gradIn.Parent = innerStroke
	innerStroke.Parent = innerFrame
end

function MultiplayerTab.Init(parentFrame, tooltipMgr, switchTabFunc)
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

	local mpCorner = Instance.new("UICorner")
	mpCorner.CornerRadius = UDim.new(0, 12)
	mpCorner.Parent = mainPanel

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

	-- ========================================================
	-- COMBAT-TAB MATCHING LAYOUT
	-- ========================================================
	local subNav = Instance.new("Frame")
	subNav.Name = "SubNav"
	subNav.Size = UDim2.new(1, 0, 0, 55)
	subNav.BackgroundTransparency = 1
	subNav.ZIndex = 20
	subNav.Parent = mainPanel

	local subNavCenter = Instance.new("Frame")
	subNavCenter.Name = "CenterContainer"
	subNavCenter.Size = UDim2.new(0.85, 0, 1, -10)
	subNavCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
	subNavCenter.AnchorPoint = Vector2.new(0.5, 0.5)
	subNavCenter.BackgroundTransparency = 1
	subNavCenter.ZIndex = 21
	subNavCenter.Parent = subNav

	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.Padding = UDim.new(0, 8)
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Parent = subNavCenter

	local camera = workspace.CurrentCamera
	local function UpdateLayoutForScreen()
		if not parentFrame.Parent then return end
		local vp = camera.ViewportSize
		if vp.X >= 1050 then 
			mainPanel.Size = UDim2.new(0.80, 0, 0.88, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
			subNavCenter.Size = UDim2.new(0.85, 0, 1, -10)
		elseif vp.X >= 600 and vp.X < 1050 then 
			mainPanel.Size = UDim2.new(0.92, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
			subNavCenter.Size = UDim2.new(0.95, 0, 1, -10)
		else 
			mainPanel.Size = UDim2.new(0.96, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0) 
			subNavCenter.Size = UDim2.new(0.98, 0, 1, -10)
		end
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
	UpdateLayoutForScreen()

	local function CreateSubNavButton(name, text, order)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.LayoutOrder = order
		btn.Size = UDim2.new(0.15, 0, 0.85, 0)
		btn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		btn.Text = text
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextScaled = true
		btn.ZIndex = 20
		btn.Parent = subNavCenter

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 6)
		bCorner.Parent = btn

		local bStr = Instance.new("UIStroke")
		bStr.Color = Color3.fromRGB(120, 60, 180)
		bStr.Thickness = 1
		bStr.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		bStr.Parent = btn

		local bPad = Instance.new("UIPadding")
		bPad.PaddingTop = UDim.new(0, 5)
		bPad.PaddingBottom = UDim.new(0, 5)
		bPad.Parent = btn

		local bUic = Instance.new("UITextSizeConstraint")
		bUic.MaxTextSize = 14
		bUic.Parent = btn

		return btn, bStr
	end

	local gangBtn, gStroke = CreateSubNavButton("GangBtn", "GANGS", 1)
	local sbrBtn, sStroke = CreateSubNavButton("SbrBtn", "EVENT", 2)
	local raidBtn, rStroke = CreateSubNavButton("RaidBtn", "RAIDS", 3)
	local arenaBtn, aStroke = CreateSubNavButton("ArenaBtn", "ARENA", 4)
	local tradeBtn, tStroke = CreateSubNavButton("TradeBtn", "TRADING", 5)
	local lbBtn, lStroke = CreateSubNavButton("LbBtn", "RANKS", 6)

	-- TAB CONTAINER (Absolute 75px offset matches CombatTab exactly)
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, 0, 1, -75)
	tabContainer.Position = UDim2.new(0, 0, 0, 75)
	tabContainer.BackgroundTransparency = 1
	tabContainer.ZIndex = 17
	tabContainer.Parent = mainPanel

	local function CreateSubFrame(name, needsPadding)
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundTransparency = 1
		frame.Visible = false
		frame.Parent = tabContainer

		-- Inject padding only for non-combat menus so they don't hug the absolute edge
		if needsPadding then
			local pad = Instance.new("UIPadding")
			pad.PaddingTop = UDim.new(0.02, 0)
			pad.PaddingBottom = UDim.new(0.02, 0)
			pad.PaddingLeft = UDim.new(0.02, 0)
			pad.PaddingRight = UDim.new(0.02, 0)
			pad.Parent = frame
		end

		return frame
	end

	local gangsFrame = CreateSubFrame("GangsFrame", true)
	local sbrFrame = CreateSubFrame("SbrFrame", true)
	local raidsFrame = CreateSubFrame("RaidsFrame", false) -- Raids receives 0 Padding so it matches StoryTab exactly
	local arenaFrame = CreateSubFrame("ArenaFrame", true)
	local tradeFrame = CreateSubFrame("TradeFrame", true)
	local lbFrame = CreateSubFrame("LbFrame", true)

	gangsFrame.Visible = true
	gangBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 140)
	gangBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
	gStroke.Color = Color3.fromRGB(255, 215, 0)
	gStroke.Thickness = 2

	local function ForceSubTabFocus(target)
		if switchTabFunc then switchTabFunc("Multiplayer") end

		gangsFrame.Visible = (target == "Gangs")
		sbrFrame.Visible = (target == "Event")
		raidsFrame.Visible = (target == "Raids")
		arenaFrame.Visible = (target == "Arena")
		tradeFrame.Visible = (target == "Trading")
		lbFrame.Visible = (target == "Ranks")

		local function toggleBtn(btn, stroke, isActive)
			btn.BackgroundColor3 = isActive and Color3.fromRGB(90, 40, 140) or Color3.fromRGB(35, 25, 45)
			btn.TextColor3 = isActive and Color3.fromRGB(255, 215, 0) or Color3.new(1, 1, 1)
			stroke.Color = isActive and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 60, 180)
			stroke.Thickness = isActive and 2 or 1
		end

		toggleBtn(gangBtn, gStroke, target == "Gangs")
		toggleBtn(sbrBtn, sStroke, target == "Event")
		toggleBtn(raidBtn, rStroke, target == "Raids")
		toggleBtn(arenaBtn, aStroke, target == "Arena")
		toggleBtn(tradeBtn, tStroke, target == "Trading")
		toggleBtn(lbBtn, lStroke, target == "Ranks")

		local pObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
		local pVal = pObj and pObj.Value or 0
		if pVal < 1 then
			if target ~= "Trading" then 
				tradeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
				tStroke.Color = Color3.fromRGB(80, 40, 100) 
			end
			if target ~= "Raids" then 
				raidBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
				rStroke.Color = Color3.fromRGB(80, 40, 100) 
			end
		end
	end

	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 10)
		if leaderstats then
			local prestige = leaderstats:WaitForChild("Prestige", 10)
			if prestige then
				local function updateLocks()
					if prestige.Value < 1 then
						tradeBtn.Text = "🔒 TRADING"
						raidBtn.Text = "🔒 RAIDS"
						if not tradeFrame.Visible then 
							tradeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
							tStroke.Color = Color3.fromRGB(80, 40, 100) 
						end
						if not raidsFrame.Visible then 
							raidBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
							rStroke.Color = Color3.fromRGB(80, 40, 100) 
						end
					else
						tradeBtn.Text = "TRADING"
						raidBtn.Text = "RAIDS"
						if not tradeFrame.Visible then 
							tradeBtn.TextColor3 = Color3.new(1, 1, 1)
							tStroke.Color = Color3.fromRGB(120, 60, 180) 
						end
						if not raidsFrame.Visible then 
							raidBtn.TextColor3 = Color3.new(1, 1, 1)
							rStroke.Color = Color3.fromRGB(120, 60, 180) 
						end
					end
				end
				prestige.Changed:Connect(updateLocks)
				updateLocks()
			end
		end
	end)

	gangBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Gangs") end)
	sbrBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Event") end)
	arenaBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Arena") end)
	lbBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Ranks") end)

	local function TryOpenLockedTab(tabName)
		SFXManager.Play("Click") 
		local pObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
		if not pObj or pObj.Value < 1 then
			NotificationManager.Show("<font color='#FF5555'>You must be Prestige 1 to unlock " .. tabName .. "!</font>")
			return
		end
		ForceSubTabFocus(tabName) 
	end

	raidBtn.MouseButton1Click:Connect(function() TryOpenLockedTab("Raids") end)
	tradeBtn.MouseButton1Click:Connect(function() TryOpenLockedTab("Trading") end)

	-- ==========================================
	-- INIT SUB MODULES
	-- ==========================================
	-- pcall(function() GangsTab.Init(gangsFrame, tooltipMgr) end)
	-- pcall(function() ArenaTab.Init(arenaFrame, tooltipMgr, function() ForceSubTabFocus("Arena") end) end)
	pcall(function() RaidsTab.Init(raidsFrame, tooltipMgr, function() ForceSubTabFocus("Raids") end) end)
	-- pcall(function() TradingTab.Init(tradeFrame, tooltipMgr, function() ForceSubTabFocus("Trading") end) end)
	pcall(function() LeaderboardTab.Init(lbFrame, tooltipMgr) end)
	-- pcall(function() SBREventTab.Init(sbrFrame, tooltipMgr, function() ForceSubTabFocus("Event") end) end)

	MultiplayerTab.HandleGangUpdate = function() end
	MultiplayerTab.HandleArenaUpdate = function() end
	MultiplayerTab.HandleTradeUpdate = function() end
	MultiplayerTab.HandleRaidUpdate = RaidsTab.HandleUpdate or function() end
end

return MultiplayerTab