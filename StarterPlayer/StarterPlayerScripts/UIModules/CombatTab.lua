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

	CombatTab.UpdateCombat = StoryTab.UpdateCombat
	CombatTab.SystemMessage = StoryTab.SystemMessage

	local mainPanel = parentFrame:WaitForChild("MainPanel")
	local innerContent = mainPanel:WaitForChild("InnerContent")

	local subNav = innerContent:WaitForChild("SubNav")
	local subNavCenter = subNav:WaitForChild("CenterContainer")
	local storyBtn = subNavCenter:WaitForChild("StoryBtn")
	local dungeonBtn = subNavCenter:WaitForChild("DungeonBtn")
	local worldBossBtn = subNavCenter:WaitForChild("WorldBossBtn")

	local modifierBubble = innerContent:WaitForChild("ModifierBubble")
	local contentArea = innerContent:WaitForChild("ContentArea")

	local storyFrame = contentArea:WaitForChild("StoryFrame")
	local dungeonFrame = contentArea:WaitForChild("DungeonFrame")
	local worldBossFrame = contentArea:WaitForChild("WorldBossFrame")

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

	local function UpdateLayoutForScreen()
		if not parentFrame.Parent then
			if resizeConn then resizeConn:Disconnect() end
			return
		end

		local vp = camera.ViewportSize
		if vp.X >= 1050 then
			mainPanel.Size = UDim2.new(0.80, 0, 0.88, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
			subNavCenter.Size = UDim2.new(0.5, 0, 1, -10)
		elseif vp.X >= 600 and vp.X < 1050 then
			mainPanel.Size = UDim2.new(0.92, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
			subNavCenter.Size = UDim2.new(0.65, 0, 1, -10)
		else
			mainPanel.Size = UDim2.new(0.96, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
			subNavCenter.Size = UDim2.new(0.75, 0, 1, -10)
		end

		local panelAbsHeight = vp.Y * mainPanel.Size.Y.Scale
		local minHeight = 600

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

return CombatTab