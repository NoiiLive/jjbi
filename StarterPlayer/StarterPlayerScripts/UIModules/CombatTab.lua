-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local CombatTab = {}

local UIModules = script.Parent
local StoryTab = require(UIModules:WaitForChild("StoryTab"))
local SFXManager = require(UIModules:WaitForChild("SFXManager"))

function CombatTab.Init(parentFrame, tooltipMgr, switchTabFunc)
	for _, child in pairs(parentFrame:GetChildren()) do
		if child:IsA("TextLabel") and string.find(child.Text, "View") then
			child:Destroy()
		end
	end

	local tabTitle = Instance.new("Frame")
	tabTitle.Name = "TabTitle"
	tabTitle.BackgroundTransparency = 1
	tabTitle.Size = UDim2.new(1, 0, 0, 0)
	tabTitle.Parent = parentFrame

	local modifierBubble = Instance.new("TextButton")
	modifierBubble.Name = "ModifierBubble"
	modifierBubble.Size = UDim2.new(0, 40, 0, 40)
	modifierBubble.Position = UDim2.new(0, 10, 0, 10)
	modifierBubble.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
	modifierBubble.Text = "🌌"
	modifierBubble.TextScaled = true
	modifierBubble.ZIndex = 30
	modifierBubble.Parent = tabTitle

	local modCorner = Instance.new("UICorner")
	modCorner.CornerRadius = UDim.new(1, 0)
	modCorner.Parent = modifierBubble

	local modStroke = Instance.new("UIStroke")
	modStroke.Color = Color3.fromRGB(255, 215, 50)
	modStroke.Thickness = 1
	modStroke.Parent = modifierBubble

	local subNav = Instance.new("Frame")
	subNav.Name = "SubNav"
	subNav.Size = UDim2.new(0.6, 0, 0.08, 0)
	subNav.Position = UDim2.new(0.5, 0, 0.02, 0)
	subNav.AnchorPoint = Vector2.new(0.5, 0)
	subNav.BackgroundTransparency = 1
	subNav.ZIndex = 20
	subNav.Parent = parentFrame

	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.SortOrder = Enum.SortOrder.LayoutOrder
	navLayout.Padding = UDim.new(0, 10)
	navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	navLayout.Parent = subNav

	local function makeNavBtn(name, text, order)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0.3, 0, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
		btn.Text = text
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextScaled = true
		btn.LayoutOrder = order
		btn.ZIndex = 21
		btn.Parent = subNav

		local uic = Instance.new("UICorner")
		uic.CornerRadius = UDim.new(0, 8)
		uic.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(120, 60, 180)
		stroke.Thickness = 2
		stroke.Parent = btn

		local uip = Instance.new("UIPadding")
		uip.PaddingTop = UDim.new(0, 5)
		uip.PaddingBottom = UDim.new(0, 5)
		uip.Parent = btn

		local ts = Instance.new("UITextSizeConstraint")
		ts.MaxTextSize = 20
		ts.MinTextSize = 10
		ts.Parent = btn

		return btn
	end

	local storyBtn = makeNavBtn("StoryBtn", "Story", 1)
	local dungeonBtn = makeNavBtn("DungeonBtn", "Dungeons", 2)
	local worldBossBtn = makeNavBtn("WorldBossBtn", "World Boss", 3)

	local contentArea = Instance.new("Frame")
	contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, 0, 0.85, 0)
	contentArea.Position = UDim2.new(0.5, 0, 0.12, 0)
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

		storyBtn.BackgroundColor3 = (target == "Story") and Color3.fromRGB(90, 40, 140) or Color3.fromRGB(35, 25, 45)
		storyBtn.TextColor3 = (target == "Story") and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
		storyBtn:FindFirstChild("UIStroke").Color = (target == "Story") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 60, 180)

		dungeonBtn.BackgroundColor3 = (target == "Dungeon") and Color3.fromRGB(90, 40, 140) or Color3.fromRGB(35, 25, 45)
		dungeonBtn.TextColor3 = (target == "Dungeon") and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
		dungeonBtn:FindFirstChild("UIStroke").Color = (target == "Dungeon") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 60, 180)

		worldBossBtn.BackgroundColor3 = (target == "WorldBoss") and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(45, 25, 25)
		worldBossBtn.TextColor3 = (target == "WorldBoss") and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
		worldBossBtn:FindFirstChild("UIStroke").Color = (target == "WorldBoss") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 60, 60)
	end

	storyBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Story") end)
	dungeonBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Dungeon") end)
	worldBossBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("WorldBoss") end)

	StoryTab.Init(storyFrame, tooltipMgr, function() ForceSubTabFocus("Story") end, tabTitle)

	local successD, DungeonTab = pcall(require, UIModules:WaitForChild("DungeonTab", 2))
	if successD and type(DungeonTab) == "table" and DungeonTab.Init then
		DungeonTab.Init(dungeonFrame, tooltipMgr, function() ForceSubTabFocus("Dungeon") end)
		CombatTab.UpdateDungeon = DungeonTab.UpdateDungeon
	end

	local successW, WorldBossTab = pcall(require, UIModules:WaitForChild("WorldBossTab", 2))
	if successW and type(WorldBossTab) == "table" and WorldBossTab.Init then
		WorldBossTab.Init(worldBossFrame, tooltipMgr, function() ForceSubTabFocus("WorldBoss") end)
		CombatTab.UpdateWorldBoss = WorldBossTab.UpdateWorldBoss
	end

	CombatTab.UpdateCombat = StoryTab.UpdateCombat
	CombatTab.SystemMessage = StoryTab.SystemMessage

	ForceSubTabFocus("Story")
end

return CombatTab