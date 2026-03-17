-- @ScriptType: ModuleScript
local CombatTab = {}

local UIModules = script.Parent
local StoryTab = require(UIModules:WaitForChild("StoryTab"))
local DungeonTab = require(UIModules:WaitForChild("DungeonTab"))
local WorldBossTab = require(UIModules:WaitForChild("WorldBossTab"))
local SFXManager = require(UIModules:WaitForChild("SFXManager"))

function CombatTab.Init(parentFrame, tooltipMgr, switchTabFunc)
	local tabTitle = parentFrame:WaitForChild("TabTitle")
	local subNav = parentFrame:WaitForChild("SubNav")

	local storyFrame = parentFrame:WaitForChild("StoryFrame")
	local dungeonFrame = parentFrame:WaitForChild("DungeonFrame")
	local worldBossFrame = parentFrame:WaitForChild("WorldBossFrame")

	local storyBtn = subNav:WaitForChild("StoryBtn")
	local sStroke = storyBtn:WaitForChild("UIStroke")

	local dungeonBtn = subNav:WaitForChild("DungeonBtn")
	local dStroke = dungeonBtn:WaitForChild("UIStroke")

	local worldBossBtn = subNav:WaitForChild("WorldBossBtn")
	local wStroke = worldBossBtn:WaitForChild("UIStroke")

	local function ForceSubTabFocus(target)
		if switchTabFunc then switchTabFunc("Combat") end
		storyFrame.Visible = (target == "Story")
		dungeonFrame.Visible = (target == "Dungeon")
		worldBossFrame.Visible = (target == "WorldBoss")

		storyBtn.BackgroundColor3 = (target == "Story") and Color3.fromRGB(90, 40, 140) or Color3.fromRGB(35, 25, 45)
		storyBtn.TextColor3 = (target == "Story") and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
		sStroke.Color = (target == "Story") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 60, 180)

		dungeonBtn.BackgroundColor3 = (target == "Dungeon") and Color3.fromRGB(90, 40, 140) or Color3.fromRGB(35, 25, 45)
		dungeonBtn.TextColor3 = (target == "Dungeon") and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
		dStroke.Color = (target == "Dungeon") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(120, 60, 180)

		worldBossBtn.BackgroundColor3 = (target == "WorldBoss") and Color3.fromRGB(140, 40, 40) or Color3.fromRGB(45, 25, 25)
		worldBossBtn.TextColor3 = (target == "WorldBoss") and Color3.fromRGB(255, 215, 0) or Color3.new(1,1,1)
		wStroke.Color = (target == "WorldBoss") and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(180, 60, 60)
	end

	storyBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Story") end)
	dungeonBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("Dungeon") end)
	worldBossBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); ForceSubTabFocus("WorldBoss") end)

	StoryTab.Init(storyFrame, tooltipMgr, function() ForceSubTabFocus("Story") end, tabTitle)
	DungeonTab.Init(dungeonFrame, tooltipMgr, function() ForceSubTabFocus("Dungeon") end)
	WorldBossTab.Init(worldBossFrame, tooltipMgr, function() ForceSubTabFocus("WorldBoss") end)

	CombatTab.UpdateCombat = StoryTab.UpdateCombat
	CombatTab.SystemMessage = StoryTab.SystemMessage
	CombatTab.UpdateDungeon = DungeonTab.UpdateDungeon
	CombatTab.UpdateWorldBoss = WorldBossTab.UpdateWorldBoss
end

return CombatTab