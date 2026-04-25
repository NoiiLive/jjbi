-- @ScriptType: ModuleScript
local SkillTreeModal = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))

local modalBg
local mainView
local treeNodeContainer
local treePointsLabel
local cachedTooltipMgr

local Templates = ReplicatedStorage:WaitForChild("JJBITemplates")

local function RefreshSkillTreeList()
	if not treeNodeContainer then return end
	for _, child in pairs(treeNodeContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then child:Destroy() end
	end

	local sName = player:GetAttribute("Stand") or "None"
	local progressStr = player:GetAttribute("SkillTreeProgress") or "{}"
	local success, progressData = pcall(function() return HttpService:JSONDecode(progressStr) end)
	if not success then progressData = {} end
	local myData = progressData[sName] or { DamageUpgrades = 0, Passives = {}, UnlockedSkills = {} }

	local treeDef = SkillData.Trees and SkillData.Trees[sName]
	if not treeDef or not treeDef.Nodes or #treeDef.Nodes == 0 then
		local noNode = Instance.new("TextLabel", treeNodeContainer)
		noNode.Size = UDim2.new(1,0,1,0)
		noNode.BackgroundTransparency = 1
		noNode.Text = "No Skill Tree available for this Stand!"
		noNode.TextColor3 = Color3.fromRGB(150, 150, 150)
		noNode.Font = Enum.Font.GothamMedium
		noNode.ZIndex = 105
		return
	end

	local prestigeObj = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige")
	local currentPrestige = prestigeObj and prestigeObj.Value or 0
	local preP = player:GetAttribute("PrestigePoints") or 0

	if treePointsLabel then
		treePointsLabel.Text = "Available Points: " .. preP
	end

	for i, node in ipairs(treeDef.Nodes) do
		local isDamageNode = (node.Key == "DamageNode")
		local maxRankStr = (StandData.Stands[sName] and StandData.Stands[sName].Stats and StandData.Stands[sName].Stats.Power) or "E"
		local basePowInt = GameData.StandRanks and GameData.StandRanks[maxRankStr] or 5
		local A_RankVal = GameData.StandRanks and GameData.StandRanks["A"] or 25

		local damageMaxCap = math.max(0, math.floor((A_RankVal - basePowInt) / 5))
		if isDamageNode and basePowInt >= A_RankVal then continue end

		local currentDmgInvest = myData.DamageUpgrades or 0

		local nodeCard = Templates:WaitForChild("TreeNodeTemplate"):Clone()
		nodeCard.LayoutOrder = i

		-- Increase the size of the node by ~15% programmatically
		local origSize = nodeCard.Size
		-- We scale the Y-axis and fixed X offsets to avoid breaking horizontal stretching if the scale is 1
		nodeCard.Size = UDim2.new(origSize.X.Scale, math.floor(origSize.X.Offset * 1.15), origSize.Y.Scale * 1.15, math.floor(origSize.Y.Offset * 1.15))

		-- Dynamically boost the ZIndex of everything inside the template
		nodeCard.ZIndex = nodeCard.ZIndex + 105
		for _, desc in ipairs(nodeCard:GetDescendants()) do
			if desc:IsA("GuiObject") then
				desc.ZIndex = desc.ZIndex + 105
			end
		end

		nodeCard.Parent = treeNodeContainer

		local nodeStrk = nodeCard:FindFirstChildOfClass("UIStroke")
		local titleLabel = nodeCard:WaitForChild("TitleLabel")
		local descLabel = nodeCard:WaitForChild("DescLabel")
		local buyBtn = nodeCard:WaitForChild("BuyBtn")

		titleLabel.Text = "<b>" .. node.Name .. "</b>"
		descLabel.Text = node.Desc

		local hasBought = false
		if isDamageNode then
			hasBought = (currentDmgInvest >= damageMaxCap)
			if hasBought then
				buyBtn.Text = "MAX (" .. currentDmgInvest .. "/" .. damageMaxCap .. ")"
				buyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				if nodeStrk then nodeStrk.Color = Color3.fromRGB(255, 215, 0) end
			else
				buyBtn.Text = "UPG (" .. currentDmgInvest .. "/" .. damageMaxCap .. ") - " .. node.Cost .. " Points"
				buyBtn.BackgroundColor3 = Color3.fromRGB(20, 120, 20)
				if nodeStrk then nodeStrk.Color = Color3.fromRGB(120, 60, 180) end
			end
		else
			hasBought = (node.Type == "Passive" and myData.Passives["Passive_" .. node.Key]) 
				or (node.Type == "Skill" and myData.UnlockedSkills["Skill_" .. node.Key])
			if hasBought then
				buyBtn.Text = "OWNED"
				buyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				if nodeStrk then nodeStrk.Color = Color3.fromRGB(80, 200, 80) end
			else
				buyBtn.Text = node.Cost .. " Points"
				buyBtn.BackgroundColor3 = Color3.fromRGB(20, 120, 20)
				if nodeStrk then nodeStrk.Color = Color3.fromRGB(120, 60, 180) end
			end
		end

		buyBtn.MouseButton1Click:Connect(function()
			if not hasBought then
				SFXManager.Play("Click")
				Network.TreeAction:FireServer("BuyUpgrade", sName, node.Key, node.Cost)
			end
		end)

		nodeCard.MouseEnter:Connect(function() 
			if cachedTooltipMgr then cachedTooltipMgr.Show("<b>" .. node.Name .. "</b>\n" .. node.Desc) end
		end)
		nodeCard.MouseLeave:Connect(function() if cachedTooltipMgr then cachedTooltipMgr.Hide() end end)
	end

	local g = treeNodeContainer:FindFirstChildWhichIsA("UIGridLayout") or treeNodeContainer:FindFirstChildWhichIsA("UIListLayout")
	if g then
		-- If it's a grid layout, we need to scale the cells themselves
		if g:IsA("UIGridLayout") and not g:GetAttribute("HasBeenScaled") then
			g.CellSize = UDim2.new(g.CellSize.X.Scale * 1.15, math.floor(g.CellSize.X.Offset * 1.15), g.CellSize.Y.Scale * 1.15, math.floor(g.CellSize.Y.Offset * 1.15))
			g:SetAttribute("HasBeenScaled", true)
		end

		local function updateCanvas()
			treeNodeContainer.CanvasSize = UDim2.new(0, 0, 0, g.AbsoluteContentSize.Y + 20)
		end
		g:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
		updateCanvas()
	end
end

function SkillTreeModal.Init(parentGui, tooltipMgr)
	cachedTooltipMgr = tooltipMgr
	local modals = parentGui:WaitForChild("ModalsContainer")
	modalBg = modals:WaitForChild("SkillTreeModalBg")

	local skillTreeCard = modalBg:WaitForChild("SkillTreeCard")
	local closeBtn = skillTreeCard:WaitForChild("CloseBtn")
	closeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); modalBg.Visible = false end)

	mainView = skillTreeCard:WaitForChild("MainView")
	treeNodeContainer = mainView:WaitForChild("NodeContainer")
	treePointsLabel = mainView:FindFirstChild("PointsLabel")

	local openTreeEvent = ReplicatedStorage:FindFirstChild("OpenSkillTreeModal")
	if not openTreeEvent then
		openTreeEvent = Instance.new("BindableEvent")
		openTreeEvent.Name = "OpenSkillTreeModal"
		openTreeEvent.Parent = ReplicatedStorage
	end

	openTreeEvent.Event:Connect(function()
		RefreshSkillTreeList()
		modalBg.Visible = true
	end)

	player:GetAttributeChangedSignal("SkillTreeProgress"):Connect(function()
		if modalBg.Visible then RefreshSkillTreeList() end
	end)

	player:GetAttributeChangedSignal("PrestigePoints"):Connect(function()
		if modalBg.Visible then RefreshSkillTreeList() end
	end)
end

return SkillTreeModal