-- @ScriptType: ModuleScript
local SkillTreeModal = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Network = ReplicatedStorage:WaitForChild("Network")
local GameData = require(ReplicatedStorage:WaitForChild("GameData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local PassiveSkillData = require(ReplicatedStorage:WaitForChild("PassiveSkillData"))
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))

local modalBg
local mainView
local treeNodeContainer
local treePointsLabel
local cachedTooltipMgr

local Templates = ReplicatedStorage:WaitForChild("JJBITemplates")

local function GetMaxDamageUpgrades(power)
	local powerStarts = { E = 1.0, D = 1.1, C = 1.2, B = 1.3, A = 1.4, S = 1.5 }
	local base = powerStarts[power] or 1.0
	local phase1 = math.floor((2.0 - base) / 0.1 + 0.5)
	return phase1 + 7 
end

local function GetDamageMultiplier(power, upgrades)
	local powerStarts = { E = 1.0, D = 1.1, C = 1.2, B = 1.3, A = 1.4, S = 1.5 }
	local mult = powerStarts[power] or 1.0
	for i = 1, upgrades do
		if mult < 2.0 then mult += 0.1
		elseif mult < 3.0 then mult += 0.25
		elseif mult < 4.0 then mult += 0.5
		elseif mult < 5.0 then mult += 1.0 end
	end
	return math.floor(mult * 100 + 0.5) / 100
end

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

	local treeDef = { Nodes = {} }

	if PassiveSkillData.Trees and PassiveSkillData.Trees[sName] then
		local pNodes = PassiveSkillData.Trees[sName].Nodes or PassiveSkillData.Trees[sName]
		for _, n in ipairs(pNodes) do table.insert(treeDef.Nodes, n) end
	end

	if StandData.Stands[sName] then
		local hasDmgNode = false
		for _, n in ipairs(treeDef.Nodes) do
			if n.Key == "DamageNode" then hasDmgNode = true break end
		end

		if not hasDmgNode then
			table.insert(treeDef.Nodes, 1, {
				Key = "DamageNode",
				Name = "Damage Upgrade",
				Desc = "Increase base damage multiplier.",
				Type = "Stat",
				Cost = 1
			})
		end
	end

	if #treeDef.Nodes == 0 then
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
		local powerRank = (StandData.Stands[sName] and StandData.Stands[sName].Stats and StandData.Stands[sName].Stats.Power) or "E"

		local damageMaxCap = GetMaxDamageUpgrades(powerRank)
		local currentDmgInvest = myData.DamageUpgrades or 0

		local displayName = node.Name or "Unknown"
		local displayDesc = node.Desc or "No description."

		if node.Type == "Passive" then
			local pData = nil
			if PassiveSkillData.Passives[sName] and PassiveSkillData.Passives[sName][node.Key] then
				pData = PassiveSkillData.Passives[sName][node.Key]
			end

			if pData then
				displayName = pData.Name or displayName
				displayDesc = pData.Desc or displayDesc
			end
		elseif node.Type == "Skill" then
			local sData = SkillData.Skills[node.Key]
			if sData then
				displayName = node.Key
				displayDesc = sData.Description or displayDesc
			end
		end

		local nodeCard = Templates:WaitForChild("TreeNodeTemplate"):Clone()
		nodeCard.LayoutOrder = i

		local origSize = nodeCard.Size
		nodeCard.Size = UDim2.new(origSize.X.Scale, math.floor(origSize.X.Offset * 1.15), origSize.Y.Scale * 1.15, math.floor(origSize.Y.Offset * 1.15))

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

		titleLabel.Text = "<b>" .. displayName .. "</b>"

		local hasBought = false
		if isDamageNode then
			local curMult = GetDamageMultiplier(powerRank, currentDmgInvest)
			local nextMult = GetDamageMultiplier(powerRank, currentDmgInvest + 1)

			hasBought = (currentDmgInvest >= damageMaxCap)

			if hasBought then
				descLabel.Text = string.format("Increase base damage multiplier.\nCurrent: %.2fx (MAX)", curMult)
				buyBtn.Text = "MAX (" .. currentDmgInvest .. "/" .. damageMaxCap .. ")"
				buyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				if nodeStrk then nodeStrk.Color = Color3.fromRGB(255, 215, 0) end
			else
				descLabel.Text = string.format("Increase base damage multiplier.\nCurrent: %.2fx ➔ Next: %.2fx", curMult, nextMult)
				buyBtn.Text = "UPG (" .. currentDmgInvest .. "/" .. damageMaxCap .. ") — " .. node.Cost .. " Pts"
				buyBtn.BackgroundColor3 = Color3.fromRGB(20, 120, 20)
				if nodeStrk then nodeStrk.Color = Color3.fromRGB(120, 60, 180) end
			end
		else
			descLabel.Text = displayDesc
			hasBought = (node.Type == "Passive" and myData.Passives["Passive_" .. node.Key]) 
				or (node.Type == "Skill" and myData.UnlockedSkills["Skill_" .. node.Key])

			if hasBought then
				buyBtn.Text = "OWNED"
				buyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				if nodeStrk then nodeStrk.Color = Color3.fromRGB(80, 200, 80) end
			else
				buyBtn.Text = node.Cost .. " Pts"
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
			if cachedTooltipMgr then cachedTooltipMgr.Show("<b>" .. displayName .. "</b>\n" .. displayDesc) end
		end)
		nodeCard.MouseLeave:Connect(function() if cachedTooltipMgr then cachedTooltipMgr.Hide() end end)
	end

	local g = treeNodeContainer:FindFirstChildWhichIsA("UIGridLayout") or treeNodeContainer:FindFirstChildWhichIsA("UIListLayout")
	if g then
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