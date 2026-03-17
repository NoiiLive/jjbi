-- @ScriptType: ModuleScript
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local CombatTemplate = {}

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

function CombatTemplate.Create(parentGui)
	local combatUI = {}

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "CombatMainFrame"
	mainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	mainFrame.BorderSizePixel = 0
	mainFrame.ZIndex = 10
	mainFrame.Parent = parentGui

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = mainFrame

	applyDoubleGoldBorder(mainFrame)

	local bgPattern = Instance.new("ImageLabel")
	bgPattern.Name = "OverlayPattern"
	bgPattern.Image = "rbxassetid://79623015802180"
	bgPattern.ImageColor3 = Color3.fromRGB(180, 130, 255)
	bgPattern.ImageTransparency = 0.85
	bgPattern.BackgroundTransparency = 1
	bgPattern.ScaleType = Enum.ScaleType.Tile
	bgPattern.TileSize = UDim2.new(0, 256, 0, 256)
	bgPattern.Size = UDim2.new(1, 0, 1, 0)
	bgPattern.ZIndex = 11
	bgPattern.Parent = mainFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 12)
	contentCorner.Parent = bgPattern

	local uiLayout = Instance.new("UIListLayout")
	uiLayout.FillDirection = Enum.FillDirection.Vertical
	uiLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiLayout.Padding = UDim.new(0, 10)
	uiLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	uiLayout.Parent = mainFrame

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingTop = UDim.new(0, 15)
	uiPadding.PaddingBottom = UDim.new(0, 15)
	uiPadding.PaddingLeft = UDim.new(0, 15)
	uiPadding.PaddingRight = UDim.new(0, 15)
	uiPadding.Parent = mainFrame

	local healthbarArea = Instance.new("Frame")
	healthbarArea.Name = "HealthbarArea"
	healthbarArea.Size = UDim2.new(1, 0, 0.55, 0)
	healthbarArea.BackgroundTransparency = 1
	healthbarArea.LayoutOrder = 1
	healthbarArea.ZIndex = 12
	healthbarArea.Parent = mainFrame

	local hbLayout = Instance.new("UIListLayout")
	hbLayout.FillDirection = Enum.FillDirection.Horizontal
	hbLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hbLayout.Padding = UDim.new(0, 20)
	hbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hbLayout.Parent = healthbarArea

	local alliesContainer = Instance.new("Frame")
	alliesContainer.Name = "AlliesContainer"
	alliesContainer.Size = UDim2.new(0.48, 0, 1, 0)
	alliesContainer.BackgroundTransparency = 1
	alliesContainer.LayoutOrder = 1
	alliesContainer.ZIndex = 12
	alliesContainer.Parent = healthbarArea

	local alliesLayout = Instance.new("UIListLayout")
	alliesLayout.FillDirection = Enum.FillDirection.Vertical
	alliesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	alliesLayout.Padding = UDim.new(0, 10)
	alliesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	alliesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	alliesLayout.Parent = alliesContainer

	local enemiesContainer = Instance.new("Frame")
	enemiesContainer.Name = "EnemiesContainer"
	enemiesContainer.Size = UDim2.new(0.48, 0, 1, 0)
	enemiesContainer.BackgroundTransparency = 1
	enemiesContainer.LayoutOrder = 2
	enemiesContainer.ZIndex = 12
	enemiesContainer.Parent = healthbarArea

	local enemiesLayout = Instance.new("UIListLayout")
	enemiesLayout.FillDirection = Enum.FillDirection.Vertical
	enemiesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	enemiesLayout.Padding = UDim.new(0, 10)
	enemiesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	enemiesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	enemiesLayout.Parent = enemiesContainer

	local chatboxArea = Instance.new("Frame")
	chatboxArea.Name = "ChatboxArea"
	chatboxArea.Size = UDim2.new(1, 0, 0.15, 0)
	chatboxArea.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	chatboxArea.BackgroundTransparency = 0.2
	chatboxArea.LayoutOrder = 2
	chatboxArea.ZIndex = 12
	chatboxArea.Parent = mainFrame

	local cbCorner = Instance.new("UICorner")
	cbCorner.CornerRadius = UDim.new(0, 8)
	cbCorner.Parent = chatboxArea

	local cbStroke = Instance.new("UIStroke")
	cbStroke.Color = Color3.fromRGB(90, 50, 120)
	cbStroke.Thickness = 1
	cbStroke.Parent = chatboxArea

	local chatPadding = Instance.new("UIPadding")
	chatPadding.PaddingTop = UDim.new(0, 8)
	chatPadding.PaddingBottom = UDim.new(0, 8)
	chatPadding.PaddingLeft = UDim.new(0, 12)
	chatPadding.PaddingRight = UDim.new(0, 12)
	chatPadding.Parent = chatboxArea

	local chatText = Instance.new("TextLabel")
	chatText.Name = "LogText"
	chatText.Size = UDim2.new(1, 0, 1, 0)
	chatText.BackgroundTransparency = 1
	chatText.Font = Enum.Font.GothamMedium
	chatText.TextColor3 = Color3.fromRGB(220, 220, 220)
	chatText.TextScaled = true
	chatText.RichText = true
	chatText.TextXAlignment = Enum.TextXAlignment.Left
	chatText.TextYAlignment = Enum.TextYAlignment.Top
	chatText.ZIndex = 13
	chatText.Parent = chatboxArea

	local cbConstraint = Instance.new("UITextSizeConstraint")
	cbConstraint.MaxTextSize = 24
	cbConstraint.MinTextSize = 10
	cbConstraint.Parent = chatText

	local abilitiesArea = Instance.new("Frame")
	abilitiesArea.Name = "AbilitiesArea"
	abilitiesArea.Size = UDim2.new(1, 0, 0.25, 0)
	abilitiesArea.BackgroundTransparency = 1
	abilitiesArea.LayoutOrder = 3
	abilitiesArea.ZIndex = 12
	abilitiesArea.Parent = mainFrame

	local abLayout = Instance.new("UIGridLayout")
	abLayout.SortOrder = Enum.SortOrder.LayoutOrder
	abLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	abLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	abLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	abLayout.Parent = abilitiesArea

	local function updateAbilitiesGrid()
		local count = #abilitiesArea:GetChildren() - 1
		if count <= 0 then count = 1 end

		local totalPaddingX = 10 * (math.min(count, 5) - 1)
		local totalPaddingY = 10 * (math.ceil(count / 5) - 1)

		local columns = math.min(count, 5)
		local rows = math.ceil(count / 5)

		local cellW = (abilitiesArea.AbsoluteSize.X - totalPaddingX) / columns
		local cellH = (abilitiesArea.AbsoluteSize.Y - totalPaddingY) / rows

		abLayout.CellSize = UDim2.new(0, cellW, 0, cellH)
	end
	abilitiesArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateAbilitiesGrid)
	abilitiesArea.ChildAdded:Connect(updateAbilitiesGrid)
	abilitiesArea.ChildRemoved:Connect(updateAbilitiesGrid)

	local camera = workspace.CurrentCamera
	local resizeConn
	resizeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if not mainFrame.Parent then
			resizeConn:Disconnect()
			return
		end
		local vp = camera.ViewportSize
		if vp.Y > vp.X then
			hbLayout.FillDirection = Enum.FillDirection.Vertical
			alliesContainer.Size = UDim2.new(1, 0, 0.48, 0)
			enemiesContainer.Size = UDim2.new(1, 0, 0.48, 0)
			alliesLayout.FillDirection = Enum.FillDirection.Horizontal
			enemiesLayout.FillDirection = Enum.FillDirection.Horizontal
		else
			hbLayout.FillDirection = Enum.FillDirection.Horizontal
			alliesContainer.Size = UDim2.new(0.48, 0, 1, 0)
			enemiesContainer.Size = UDim2.new(0.48, 0, 1, 0)
			alliesLayout.FillDirection = Enum.FillDirection.Vertical
			enemiesLayout.FillDirection = Enum.FillDirection.Vertical
		end
	end)

	combatUI.MainFrame = mainFrame
	combatUI.AlliesContainer = alliesContainer
	combatUI.EnemiesContainer = enemiesContainer
	combatUI.ChatText = chatText
	combatUI.AbilitiesArea = abilitiesArea

	function combatUI:Log(message)
		self.ChatText.Text = message
	end

	function combatUI:ClearAbilities()
		for _, child in pairs(self.AbilitiesArea:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end

	function combatUI:AddAbility(name, color, callback)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.BackgroundColor3 = color or Color3.fromRGB(30, 20, 50)
		btn.Text = name
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextScaled = true
		btn.ZIndex = 14
		btn.Parent = self.AbilitiesArea

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(90, 50, 120)
		btnStroke.Thickness = 2
		btnStroke.Parent = btn

		local btnPad = Instance.new("UIPadding")
		btnPad.PaddingTop = UDim.new(0, 5)
		btnPad.PaddingBottom = UDim.new(0, 5)
		btnPad.Parent = btn

		local uic = Instance.new("UITextSizeConstraint")
		uic.MaxTextSize = 24
		uic.MinTextSize = 8
		uic.Parent = btn

		btn.MouseButton1Click:Connect(function()
			if callback then callback() end
		end)

		return btn
	end

	function combatUI:AddFighter(isAlly, id, name, iconId, initialHp, maxHp)
		local container = isAlly and self.AlliesContainer or self.EnemiesContainer

		local fFrame = Instance.new("Frame")
		fFrame.Name = "Fighter_" .. id
		fFrame.Size = UDim2.new(1, 0, 0, 0)
		fFrame.AutomaticSize = Enum.AutomaticSize.Y
		fFrame.BackgroundTransparency = 1
		fFrame.ZIndex = 13
		fFrame.Parent = container

		local fLayout = Instance.new("UIListLayout")
		fLayout.FillDirection = Enum.FillDirection.Vertical
		fLayout.SortOrder = Enum.SortOrder.LayoutOrder
		fLayout.Padding = UDim.new(0, 4)
		fLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		fLayout.Parent = fFrame

		local iconBox = Instance.new("Frame")
		iconBox.Name = "IconBox"
		iconBox.Size = UDim2.new(0, 60, 0, 60)
		iconBox.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
		iconBox.LayoutOrder = 1
		iconBox.ZIndex = 14
		iconBox.Parent = fFrame

		local icCorner = Instance.new("UICorner")
		icCorner.CornerRadius = UDim.new(0, 8)
		icCorner.Parent = iconBox

		local icStroke = Instance.new("UIStroke")
		icStroke.Color = Color3.fromRGB(255, 215, 50)
		icStroke.Thickness = 2
		icStroke.Parent = iconBox

		if iconId and iconId ~= "" then
			local img = Instance.new("ImageLabel")
			img.Size = UDim2.new(1, 0, 1, 0)
			img.BackgroundTransparency = 1
			img.Image = iconId
			img.ScaleType = Enum.ScaleType.Crop
			img.ZIndex = 15
			img.Parent = iconBox

			local imgCorner = Instance.new("UICorner")
			imgCorner.CornerRadius = UDim.new(0, 8)
			imgCorner.Parent = img
		else
			local txt = Instance.new("TextLabel")
			txt.Size = UDim2.new(1, 0, 1, 0)
			txt.BackgroundTransparency = 1
			txt.Text = "?"
			txt.Font = Enum.Font.GothamBold
			txt.TextColor3 = Color3.fromRGB(255, 215, 50)
			txt.TextScaled = true
			txt.ZIndex = 15
			txt.Parent = iconBox
		end

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "NameLabel"
		nameLbl.Size = UDim2.new(1, 0, 0, 20)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = name
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLbl.TextScaled = true
		nameLbl.LayoutOrder = 2
		nameLbl.ZIndex = 14
		nameLbl.Parent = fFrame

		local nameUic = Instance.new("UITextSizeConstraint")
		nameUic.MaxTextSize = 18
		nameUic.MinTextSize = 10
		nameUic.Parent = nameLbl

		local hpContainer = Instance.new("Frame")
		hpContainer.Name = "HpContainer"
		hpContainer.Size = UDim2.new(0.8, 0, 0, 14)
		hpContainer.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
		hpContainer.LayoutOrder = 3
		hpContainer.ZIndex = 14
		hpContainer.Parent = fFrame

		local hpCorner = Instance.new("UICorner")
		hpCorner.CornerRadius = UDim.new(1, 0)
		hpCorner.Parent = hpContainer

		local hpStroke = Instance.new("UIStroke")
		hpStroke.Color = Color3.fromRGB(20, 5, 5)
		hpStroke.Thickness = 1
		hpStroke.Parent = hpContainer

		local hpFill = Instance.new("Frame")
		hpFill.Name = "HpFill"
		local pct = math.clamp(initialHp / maxHp, 0, 1)
		hpFill.Size = UDim2.new(pct, 0, 1, 0)
		hpFill.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		hpFill.ZIndex = 15
		hpFill.Parent = hpContainer

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(1, 0)
		fillCorner.Parent = hpFill

		local statusContainer = Instance.new("Frame")
		statusContainer.Name = "StatusContainer"
		statusContainer.Size = UDim2.new(1, 0, 0, 24)
		statusContainer.BackgroundTransparency = 1
		statusContainer.LayoutOrder = 4
		statusContainer.ZIndex = 14
		statusContainer.Parent = fFrame

		local statusLayout = Instance.new("UIListLayout")
		statusLayout.FillDirection = Enum.FillDirection.Horizontal
		statusLayout.SortOrder = Enum.SortOrder.LayoutOrder
		statusLayout.Padding = UDim.new(0, 4)
		statusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		statusLayout.Parent = statusContainer

		local fighterObj = {
			Frame = fFrame,
			HpFill = hpFill,
			StatusContainer = statusContainer,
			MaxHp = maxHp
		}

		function fighterObj:UpdateHealth(newHp, newMax)
			if newMax then self.MaxHp = newMax end
			local newPct = math.clamp(newHp / self.MaxHp, 0, 1)
			TweenService:Create(self.HpFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(newPct, 0, 1, 0)
			}):Play()
		end

		function fighterObj:SetStatus(statusId, iconString, durationText)
			local existing = self.StatusContainer:FindFirstChild(statusId)
			if not existing then
				existing = Instance.new("Frame")
				existing.Name = statusId
				existing.Size = UDim2.new(0, 24, 0, 24)
				existing.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
				existing.ZIndex = 15
				existing.Parent = self.StatusContainer

				local sCorner = Instance.new("UICorner")
				sCorner.CornerRadius = UDim.new(0, 4)
				sCorner.Parent = existing

				local sStroke = Instance.new("UIStroke")
				sStroke.Color = Color3.fromRGB(255, 215, 50)
				sStroke.Thickness = 1
				sStroke.Parent = existing

				local sIcon = Instance.new("TextLabel")
				sIcon.Name = "Icon"
				sIcon.Size = UDim2.new(1, 0, 1, 0)
				sIcon.BackgroundTransparency = 1
				sIcon.Text = iconString
				sIcon.Font = Enum.Font.GothamBold
				sIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
				sIcon.TextScaled = true
				sIcon.ZIndex = 16
				sIcon.Parent = existing

				local durLbl = Instance.new("TextLabel")
				durLbl.Name = "Duration"
				durLbl.Size = UDim2.new(1, 0, 0.4, 0)
				durLbl.Position = UDim2.new(0, 0, 0.8, 0)
				durLbl.BackgroundTransparency = 1
				durLbl.Text = durationText or ""
				durLbl.Font = Enum.Font.GothamBold
				durLbl.TextColor3 = Color3.fromRGB(255, 50, 50)
				durLbl.TextScaled = true
				durLbl.ZIndex = 17
				durLbl.Parent = existing

				local strokeTxt = Instance.new("UIStroke")
				strokeTxt.Color = Color3.fromRGB(0, 0, 0)
				strokeTxt.Thickness = 1
				strokeTxt.Parent = durLbl
			else
				local durLbl = existing:FindFirstChild("Duration")
				if durLbl then durLbl.Text = durationText or "" end
			end
		end

		function fighterObj:RemoveStatus(statusId)
			local existing = self.StatusContainer:FindFirstChild(statusId)
			if existing then
				existing:Destroy()
			end
		end

		return fighterObj
	end

	function combatUI:Destroy()
		if resizeConn then resizeConn:Disconnect() end
		self.MainFrame:Destroy()
	end

	local vpInit = camera.ViewportSize
	if vpInit.Y > vpInit.X then
		hbLayout.FillDirection = Enum.FillDirection.Vertical
		alliesContainer.Size = UDim2.new(1, 0, 0.48, 0)
		enemiesContainer.Size = UDim2.new(1, 0, 0.48, 0)
		alliesLayout.FillDirection = Enum.FillDirection.Horizontal
		enemiesLayout.FillDirection = Enum.FillDirection.Horizontal
	end

	return combatUI
end

return CombatTemplate