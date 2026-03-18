-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local CombatTab = {}

local UIModules = script.Parent
local StoryTab = require(UIModules:WaitForChild("StoryTab"))
local SFXManager = require(UIModules:WaitForChild("SFXManager"))

local function applyDoubleGoldBorder(parent)
	local parentCorner = parent:FindFirstChildOfClass("UICorner")

	local outerStroke = Instance.new("UIStroke")
	outerStroke.Thickness = 3
	outerStroke.Color = Color3.fromRGB(255, 210, 60)
	outerStroke.LineJoinMode = Enum.LineJoinMode.Round
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradOut = Instance.new("UIGradient")
	gradOut.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 160, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 160, 30))
	}
	gradOut.Rotation = -45
	gradOut.Parent = outerStroke
	outerStroke.Parent = parent

	local innerFrame = Instance.new("Frame")
	innerFrame.Name = "InnerGoldBorder"
	innerFrame.Size = UDim2.new(1, -6, 1, -6)
	innerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	innerFrame.BackgroundTransparency = 1
	innerFrame.ZIndex = parent.ZIndex

	if parentCorner then
		local innerCorner = Instance.new("UICorner")
		if parentCorner.CornerRadius.Scale > 0 then
			innerCorner.CornerRadius = parentCorner.CornerRadius
		else
			local offset = math.max(0, parentCorner.CornerRadius.Offset - 3)
			innerCorner.CornerRadius = UDim.new(0, offset)
		end
		innerCorner.Parent = innerFrame
	end
	innerFrame.Parent = parent

	local innerStroke = Instance.new("UIStroke")
	innerStroke.Thickness = 1
	innerStroke.Color = Color3.fromRGB(255, 230, 100)
	innerStroke.LineJoinMode = Enum.LineJoinMode.Round
	innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local gradIn = Instance.new("UIGradient")
	gradIn.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 25))
	}
	gradIn.Rotation = 45
	gradIn.Parent = innerStroke
	innerStroke.Parent = innerFrame
end

function CombatTab.Init(parentFrame, tooltipMgr, switchTabFunc)
	for _, child in pairs(parentFrame:GetChildren()) do
		if child:IsA("TextLabel") and string.find(child.Text, "View") then
			child:Destroy()
		end
	end

	CombatTab.UpdateCombat = StoryTab.UpdateCombat
	CombatTab.SystemMessage = StoryTab.SystemMessage

	local subNav = Instance.new("Frame")
	subNav.Name = "SubNav"
	subNav.Size = UDim2.new(0.40, 0, 0, 60)
	subNav.Position = UDim2.new(0.5, 0, 0.02, 0)
	subNav.AnchorPoint = Vector2.new(0.5, 0)
	subNav.BackgroundColor3 = Color3.fromRGB(25, 15, 45)
	subNav.ZIndex = 20
	subNav.Parent = parentFrame

	local subNavCorner = Instance.new("UICorner")
	subNavCorner.CornerRadius = UDim.new(0, 12)
	subNavCorner.Parent = subNav

	applyDoubleGoldBorder(subNav)

	local subNavContainer = Instance.new("Frame")
	subNavContainer.Name = "SubNavContainer"
	subNavContainer.Size = UDim2.new(1, -12, 1, -12)
	subNavContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	subNavContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	subNavContainer.BackgroundTransparency = 1
	subNavContainer.ZIndex = 21
	subNavContainer.Parent = subNav

	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.Padding = UDim.new(0, 10)
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	navLayout.Parent = subNavContainer

	local function makeNavBtn(name, text, order)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0.22, 0, 0.75, 0)
		btn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		btn.Text = text
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextScaled = true
		btn.LayoutOrder = order
		btn.ZIndex = 22
		btn.Parent = subNavContainer

		local uic = Instance.new("UICorner")
		uic.CornerRadius = UDim.new(0, 6)
		uic.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(120, 60, 180)
		stroke.Thickness = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = btn

		local uip = Instance.new("UIPadding")
		uip.PaddingTop = UDim.new(0, 5)
		uip.PaddingBottom = UDim.new(0, 5)
		uip.Parent = btn

		local ts = Instance.new("UITextSizeConstraint")
		ts.MaxTextSize = 16
		ts.MinTextSize = 10
		ts.Parent = btn

		return btn
	end

	local storyBtn = makeNavBtn("StoryBtn", "Story", 1)
	local dungeonBtn = makeNavBtn("DungeonBtn", "Dungeons", 2)
	local worldBossBtn = makeNavBtn("WorldBossBtn", "World Boss", 3)

	local modifierBubble = makeNavBtn("ModifierBubble", "MODS", 4)
	modifierBubble.Size = UDim2.new(0.15, 0, 0.75, 0)
	modifierBubble.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
	modifierBubble.TextColor3 = Color3.fromRGB(255, 215, 50)
	modifierBubble:FindFirstChild("UIStroke").Color = Color3.fromRGB(255, 215, 50)

	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, 0, 0.86, 0)
	contentArea.Position = UDim2.new(0.5, 0, 0.14, 0)
	contentArea.AnchorPoint = Vector2.new(0.5, 0)
	contentArea.BackgroundTransparency = 1
	contentArea.ZIndex = 15
	contentArea.Parent = parentFrame

	local storyFrame = Instance.new("Frame")
	storyFrame.Name = "StoryFrame"
	storyFrame.Size = UDim2.new(1, 0, 1, 0)
	storyFrame.BackgroundTransparency = 1
	storyFrame.Parent = contentArea

	local dungeonFrame = Instance.new("Frame")
	dungeonFrame.Name = "DungeonFrame"
	dungeonFrame.Size = UDim2.new(1, 0, 1, 0)
	dungeonFrame.BackgroundTransparency = 1
	dungeonFrame.Visible = false
	dungeonFrame.Parent = contentArea

	local worldBossFrame = Instance.new("Frame")
	worldBossFrame.Name = "WorldBossFrame"
	worldBossFrame.Size = UDim2.new(1, 0, 1, 0)
	worldBossFrame.BackgroundTransparency = 1
	worldBossFrame.Visible = false
	worldBossFrame.Parent = contentArea

	local function ForceSubTabFocus(target)
		if switchTabFunc then switchTabFunc("Singleplayer") end
		storyFrame.Visible = (target == "Story")
		dungeonFrame.Visible = (target == "Dungeon")
		worldBossFrame.Visible = (target == "WorldBoss")

		storyBtn.BackgroundColor3 = (target == "Story") and Color3.fromRGB(70, 30, 100) or Color3.fromRGB(35, 25, 45)
		storyBtn.TextColor3 = (target == "Story") and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
		storyBtn:FindFirstChild("UIStroke").Color = (target == "Story") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 60, 180)

		dungeonBtn.BackgroundColor3 = (target == "Dungeon") and Color3.fromRGB(70, 30, 100) or Color3.fromRGB(35, 25, 45)
		dungeonBtn.TextColor3 = (target == "Dungeon") and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
		dungeonBtn:FindFirstChild("UIStroke").Color = (target == "Dungeon") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 60, 180)

		worldBossBtn.BackgroundColor3 = (target == "WorldBoss") and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(45, 25, 25)
		worldBossBtn.TextColor3 = (target == "WorldBoss") and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
		worldBossBtn:FindFirstChild("UIStroke").Color = (target == "WorldBoss") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 60, 60)
	end

	storyBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Story") end)
	dungeonBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Dungeon") end)
	worldBossBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("WorldBoss") end)

	StoryTab.Init(storyFrame, tooltipMgr, function() ForceSubTabFocus("Story") end, modifierBubble)

	task.spawn(function()
		local dMod = UIModules:FindFirstChild("DungeonTab")
		if dMod then
			local successD, DungeonTab = pcall(require, dMod)
			if successD and type(DungeonTab) == "table" and DungeonTab.Init then
				DungeonTab.Init(dungeonFrame, tooltipMgr, function() ForceSubTabFocus("Dungeon") end)
				CombatTab.UpdateDungeon = DungeonTab.UpdateDungeon
			end
		end
	end)

	task.spawn(function()
		local wMod = UIModules:FindFirstChild("WorldBossTab")
		if wMod then
			local successW, WorldBossTab = pcall(require, wMod)
			if successW and type(WorldBossTab) == "table" and WorldBossTab.Init then
				WorldBossTab.Init(worldBossFrame, tooltipMgr, function() ForceSubTabFocus("WorldBoss") end)
				CombatTab.UpdateWorldBoss = WorldBossTab.UpdateWorldBoss
			end
		end
	end)

	ForceSubTabFocus("Story")

	local camera = workspace.CurrentCamera
	local resizeConn
	resizeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if not parentFrame.Parent then
			resizeConn:Disconnect()
			return
		end
		local vp = camera.ViewportSize
		if vp.X >= 1050 then
			subNav.Size = UDim2.new(0.40, 0, 0, 60)
			contentArea.Size = UDim2.new(1, 0, 0.86, 0)
			contentArea.Position = UDim2.new(0.5, 0, 0.14, 0)
		elseif vp.X >= 600 and vp.X < 1050 then
			subNav.Size = UDim2.new(0.60, 0, 0, 55)
			contentArea.Size = UDim2.new(1, 0, 0.88, 0)
			contentArea.Position = UDim2.new(0.5, 0, 0.12, 0)
		else
			subNav.Size = UDim2.new(0.95, 0, 0, 55)
			contentArea.Size = UDim2.new(1, 0, 0.88, 0)
			contentArea.Position = UDim2.new(0.5, 0, 0.12, 0)
		end
	end)

	local vpInit = camera.ViewportSize
	if vpInit.X >= 1050 then
		subNav.Size = UDim2.new(0.40, 0, 0, 60)
		contentArea.Size = UDim2.new(1, 0, 0.86, 0)
		contentArea.Position = UDim2.new(0.5, 0, 0.14, 0)
	elseif vpInit.X >= 600 and vpInit.X < 1050 then
		subNav.Size = UDim2.new(0.60, 0, 0, 55)
		contentArea.Size = UDim2.new(1, 0, 0.88, 0)
		contentArea.Position = UDim2.new(0.5, 0, 0.12, 0)
	else
		subNav.Size = UDim2.new(0.95, 0, 0, 55)
		contentArea.Size = UDim2.new(1, 0, 0.88, 0)
		contentArea.Position = UDim2.new(0.5, 0, 0.12, 0)
	end
end

return CombatTab