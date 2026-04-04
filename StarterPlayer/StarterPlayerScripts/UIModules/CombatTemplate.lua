-- @ScriptType: ModuleScript
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CombatTemplate = {}

function CombatTemplate.Create(parentGui, tooltipMgr)
	local combatUI = {}
	local Templates = ReplicatedStorage:WaitForChild("JJBITemplates")

	local mainFrame = Templates:WaitForChild("CombatMainTemplate"):Clone()
	mainFrame.Name = "CombatMainFrame"
	mainFrame.Parent = parentGui

	local contentContainer = mainFrame:WaitForChild("ContentContainer")
	local healthbarArea = contentContainer:WaitForChild("HealthbarArea")
	local hbLayout = healthbarArea:WaitForChild("UIListLayout")

	local alliesContainer = healthbarArea:WaitForChild("AlliesContainer")
	local enemiesContainer = healthbarArea:WaitForChild("EnemiesContainer")
	local alliesLayout = alliesContainer:WaitForChild("UIGridLayout")
	local enemiesLayout = enemiesContainer:WaitForChild("UIGridLayout")

	local chatboxArea = contentContainer:WaitForChild("ChatboxArea")
	local chatScroll = chatboxArea:WaitForChild("ChatScroll")
	local chatText = chatScroll:WaitForChild("LogText")

	local abilitiesArea = contentContainer:WaitForChild("AbilitiesArea")
	local abLayout = abilitiesArea:WaitForChild("UIGridLayout")

	local function updateAbilitiesGrid()
		local vp = workspace.CurrentCamera.ViewportSize
		local isPortrait = vp.Y > vp.X
		local isMedium = not isPortrait and vp.X < 1050

		local columns = isPortrait and 5 or (isMedium and 6 or 7)
		local rows = isPortrait and 3 or 2

		local totalPaddingX = 6 * (columns - 1)
		local totalPaddingY = 6 * (rows - 1)

		local cellW = math.floor((abilitiesArea.AbsoluteSize.X - totalPaddingX - 12) / columns)
		local maxCellH = math.floor((abilitiesArea.AbsoluteSize.Y - totalPaddingY - 16) / rows)

		cellW = math.max(10, math.min(cellW, 180))
		local cellH = math.max(10, math.min(maxCellH, 50))

		abLayout.CellSize = UDim2.new(0, cellW, 0, cellH)
	end

	local function formatGrid(layout, container, count)
		if count <= 0 then count = 1 end
		local cols = math.min(count, 2)
		local rows = math.ceil(count / cols)

		local padX = 6 * (cols - 1)
		local padY = 6 * (rows - 1)

		local w = math.floor((container.AbsoluteSize.X - padX) / cols)
		local h = math.floor((container.AbsoluteSize.Y - padY) / rows)

		layout.CellSize = UDim2.new(0, math.max(10, w), 0, math.max(10, h))
	end

	local function updateAllGrids()
		local aCount, eCount = 0, 0
		for _, c in pairs(alliesContainer:GetChildren()) do if c:IsA("Frame") and c.Name:match("Fighter") then aCount += 1 end end
		for _, c in pairs(enemiesContainer:GetChildren()) do if c:IsA("Frame") and c.Name:match("Fighter") then eCount += 1 end end

		formatGrid(alliesLayout, alliesContainer, aCount)
		formatGrid(enemiesLayout, enemiesContainer, eCount)
		updateAbilitiesGrid()
	end

	abilitiesArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateAllGrids)
	abilitiesArea.ChildAdded:Connect(updateAllGrids)
	abilitiesArea.ChildRemoved:Connect(updateAllGrids)

	local camera = workspace.CurrentCamera
	local resizeConn

	local function updateLayout()
		local vp = camera.ViewportSize
		local isPortrait = vp.Y > vp.X

		if isPortrait then
			healthbarArea.Size = UDim2.new(1, 0, 0.48, 0)
			chatboxArea.Size = UDim2.new(1, 0, 0.15, 0)
			abilitiesArea.Size = UDim2.new(1, 0, 0.28, 0)

			hbLayout.FillDirection = Enum.FillDirection.Vertical
			hbLayout.Padding = UDim.new(0, 8) 

			alliesContainer.LayoutOrder = 1
			enemiesContainer.LayoutOrder = 2
			alliesContainer.Size = UDim2.new(1, 0, 0.45, 0)
			enemiesContainer.Size = UDim2.new(1, 0, 0.45, 0)
		else
			healthbarArea.Size = UDim2.new(1, 0, 0.42, 0)
			chatboxArea.Size = UDim2.new(1, 0, 0.18, 0)
			abilitiesArea.Size = UDim2.new(1, 0, 0.30, 0)

			hbLayout.FillDirection = Enum.FillDirection.Horizontal
			hbLayout.Padding = UDim.new(0, 10)

			alliesContainer.LayoutOrder = 1
			enemiesContainer.LayoutOrder = 2
			alliesContainer.Size = UDim2.new(0.48, 0, 1, 0)
			enemiesContainer.Size = UDim2.new(0.48, 0, 1, 0)
		end

		updateAllGrids()
	end

	resizeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if not mainFrame.Parent then
			resizeConn:Disconnect()
			return
		end
		updateLayout()
	end)

	alliesContainer.ChildAdded:Connect(updateLayout)
	enemiesContainer.ChildAdded:Connect(updateLayout)
	alliesContainer.ChildRemoved:Connect(updateLayout)
	enemiesContainer.ChildRemoved:Connect(updateLayout)

	updateLayout()

	combatUI.MainFrame = mainFrame
	combatUI.ContentContainer = contentContainer
	combatUI.AlliesContainer = alliesContainer
	combatUI.EnemiesContainer = enemiesContainer
	combatUI.ChatText = chatText
	combatUI.ChatScroll = chatScroll
	combatUI.AbilitiesArea = abilitiesArea

	function combatUI:Log(message)
		self.ChatText.Text = message
		task.defer(function()
			self.ChatScroll.CanvasPosition = Vector2.new(0, self.ChatText.AbsoluteSize.Y + 200)
		end)
	end

	function combatUI:ClearAbilities()
		for _, child in pairs(self.AbilitiesArea:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end

	function combatUI:AddAbility(name, color, callback)
		local btn = Templates:WaitForChild("CombatAbilityTemplate"):Clone()
		btn.Name = name
		btn.BackgroundColor3 = color or Color3.fromRGB(30, 20, 50)
		btn.Text = name
		btn.Parent = self.AbilitiesArea

		btn.MouseButton1Click:Connect(function()
			if callback then callback() end
		end)

		updateAllGrids()
		return btn
	end

	function combatUI:AddFighter(isAlly, id, name, iconId, initialHp, maxHp)
		local container = isAlly and self.AlliesContainer or self.EnemiesContainer

		local fFrame = Templates:WaitForChild("CombatFighterTemplate"):Clone()
		fFrame.Name = "Fighter_" .. id
		fFrame.Parent = container

		local iconBox = fFrame:WaitForChild("IconBox")
		local iconImg = iconBox:WaitForChild("IconImage")
		local iconTxt = iconBox:WaitForChild("IconText")

		iconImg.ResampleMode = Enum.ResamplerMode.Pixelated

		if iconId and iconId ~= "" then
			if string.match(tostring(iconId), "^rbx") then
				iconImg.Image = iconId
			else
				iconImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. iconId .. "&w=420&h=420"
			end
			iconImg.Visible = true
			iconTxt.Visible = false
		else
			iconImg.Visible = false
			iconTxt.Visible = true
		end

		local infoArea = fFrame:WaitForChild("InfoArea")
		local nameLbl = infoArea:WaitForChild("NameLabel")
		nameLbl.Text = name

		local hpContainer = infoArea:WaitForChild("HpContainer")
		local hpFill = hpContainer:WaitForChild("HpFill")
		local hpText = hpContainer:WaitForChild("HpText")
		local statusContainer = infoArea:WaitForChild("StatusContainer")

		local pct = math.clamp(initialHp / maxHp, 0, 1)
		hpFill.Size = UDim2.new(pct, 0, 1, 0)
		hpText.Text = math.floor(initialHp) .. " / " .. math.floor(maxHp)

		local fighterObj = {
			Frame = fFrame,
			InfoArea = infoArea,
			HpFill = hpFill,
			HpText = hpText,
			StatusContainer = statusContainer,
			MaxHp = maxHp,
			IconImage = iconImg,
			IconText = iconTxt
		}

		function fighterObj:UpdateHealth(newHp, newMax)
			if newMax then self.MaxHp = newMax end
			local newPct = math.clamp(newHp / self.MaxHp, 0, 1)
			self.HpText.Text = math.floor(newHp) .. " / " .. math.floor(self.MaxHp)
			TweenService:Create(self.HpFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(newPct, 0, 1, 0)
			}):Play()
		end

		function fighterObj:UpdateIcon(newIconId, newName)
			if self.InfoArea and self.InfoArea:FindFirstChild("NameLabel") then
				self.InfoArea.NameLabel.Text = newName or "Unknown"
			end
			if newIconId and newIconId ~= "" then
				if string.match(tostring(newIconId), "^rbx") then
					self.IconImage.Image = newIconId
				else
					self.IconImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. newIconId .. "&w=420&h=420"
				end
				self.IconImage.Visible = true
				self.IconText.Visible = false
			else
				self.IconImage.Visible = false
				self.IconText.Visible = true
			end
		end

		function fighterObj:SetStatus(statusId, iconString, durationText, descText, isImmunity)
			local existing = self.StatusContainer:FindFirstChild(statusId)
			if not existing then
				existing = Templates:WaitForChild("CombatStatusTemplate"):Clone()
				existing.Name = statusId
				existing.BackgroundColor3 = isImmunity and Color3.fromRGB(20, 10, 30) or Color3.fromRGB(30, 20, 50)
				existing.BackgroundTransparency = isImmunity and 0.5 or 0
				existing.LayoutOrder = isImmunity and 1 or 2

				local sStroke = existing:WaitForChild("UIStroke")
				local strokeColor = Color3.fromRGB(255, 215, 50)
				if isImmunity then
					strokeColor = Color3.fromRGB(150, 150, 150)
				elseif string.sub(statusId, 1, 5) == "Buff_" then
					strokeColor = Color3.fromRGB(50, 255, 50)
				elseif string.sub(statusId, 1, 7) == "Debuff_" then
					strokeColor = Color3.fromRGB(255, 50, 50)
				end
				sStroke.Color = strokeColor

				local sIcon = existing:WaitForChild("Icon")
				sIcon.Text = iconString
				sIcon.TextColor3 = isImmunity and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 255, 255)

				local durLbl = existing:WaitForChild("Duration")
				durLbl.TextColor3 = isImmunity and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(255, 50, 50)

				local hoverBtn = existing:WaitForChild("TooltipHover")
				hoverBtn.MouseEnter:Connect(function()
					if tooltipMgr then
						local t = existing:GetAttribute("TooltipTitle")
						local d = existing:GetAttribute("TooltipDesc")
						local dur = existing:GetAttribute("TooltipDur")
						tooltipMgr.Show("<b><font color='#FFD700'>"..t.."</font></b>\n<font color='#AAAAAA'>"..d.."</font>\nDuration: <font color='#FF5555'>"..dur.."</font>")
					end
				end)
				hoverBtn.MouseLeave:Connect(function() if tooltipMgr then tooltipMgr.Hide() end end)

				existing.Parent = self.StatusContainer
			end

			existing:SetAttribute("TooltipTitle", statusId)
			existing:SetAttribute("TooltipDesc", descText or "Active effect.")
			existing:SetAttribute("TooltipDur", durationText)

			local durLbl = existing:FindFirstChild("Duration")
			if durLbl then durLbl.Text = durationText or "" end
		end

		function fighterObj:RemoveStatus(statusId)
			local existing = self.StatusContainer:FindFirstChild(statusId)
			if existing then
				existing:Destroy()
			end
		end

		function fighterObj:SetCooldown(cdId, iconString, durationText, descText)
			self:SetStatus(cdId, iconString, durationText, descText, true)
		end

		function fighterObj:RemoveCooldown(cdId)
			self:RemoveStatus(cdId)
		end

		updateAllGrids()
		return fighterObj
	end

	function combatUI:Destroy()
		if resizeConn then resizeConn:Disconnect() end
		self.MainFrame:Destroy()
	end

	return combatUI
end

return CombatTemplate