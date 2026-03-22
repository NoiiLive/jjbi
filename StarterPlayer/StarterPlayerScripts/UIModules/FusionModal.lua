-- @ScriptType: ModuleScript
local FusionModal = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))

local modalBg, fusionCard
local drop1Btn, drop2Btn, list1, list2
local previewLabel, fuseBtn
local selectedSlot1, selectedSlot2
local selectedName1, selectedName2

local function AddBtnStroke(btn, r, g, b, t)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(r, g, b)
	s.Thickness = t or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = btn
	return s
end

local function GetAvailableStands()
	local opts = {}
	local function check(slot, attrName)
		local sName = player:GetAttribute(attrName) or "None"
		if sName ~= "None" and sName ~= "Fused Stand" then
			table.insert(opts, {Slot = slot, Name = sName})
		end
	end

	check("Active", "Stand")
	check("Slot1", "StoredStand1")
	if player:GetAttribute("HasStandSlot2") then check("Slot2", "StoredStand2") end
	if player:GetAttribute("HasStandSlot3") then check("Slot3", "StoredStand3") end

	local prestige = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige") and player.leaderstats.Prestige.Value or 0
	if prestige >= 15 then check("Slot4", "StoredStand4") end
	if prestige >= 30 then check("Slot5", "StoredStand5") end

	return opts
end

local function UpdatePreview()
	if selectedName1 and selectedName2 then
		local combined = FusionUtility.CalculateFusedName(selectedName1, selectedName2)
		previewLabel.Text = "Result: <font color='#55FF55'>" .. combined .. "</font>"
		fuseBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
		fuseBtn.AutoButtonColor = true
	else
		previewLabel.Text = "Select two stands to preview fusion."
		fuseBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		fuseBtn.AutoButtonColor = false
	end
end

local function PopulateDropdown(listFrame, targetBtn, isSlot1)
	for _, c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	local opts = GetAvailableStands()

	if #opts == 0 then
		listFrame.CanvasSize = UDim2.new(0, 0, 0, 30)
		return
	end

	for i, opt in ipairs(opts) do
		local b = Instance.new("TextButton", listFrame)
		b.Size = UDim2.new(1, -8, 0, 30)
		b.BackgroundTransparency = (i%2==0) and 0.5 or 1
		b.BackgroundColor3 = Color3.fromRGB(30, 20, 40)
		b.Font = Enum.Font.GothamMedium
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextSize = 14
		b.Text = opt.Slot .. ": " .. opt.Name
		b.ZIndex = 105

		b.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			targetBtn.Text = opt.Slot .. ": " .. opt.Name
			if isSlot1 then
				selectedSlot1 = opt.Slot
				selectedName1 = opt.Name
			else
				selectedSlot2 = opt.Slot
				selectedName2 = opt.Name
			end
			listFrame.Visible = false
			UpdatePreview()
		end)
	end
	listFrame.CanvasSize = UDim2.new(0, 0, 0, #opts * 30)
end

function FusionModal.Init(parentGui)
	modalBg = Instance.new("Frame")
	modalBg.Name = "FusionModalBg"
	modalBg.Size = UDim2.new(1, 0, 1, 0)
	modalBg.BackgroundColor3 = Color3.new(0, 0, 0)
	modalBg.BackgroundTransparency = 0.5
	modalBg.Visible = false
	modalBg.ZIndex = 100
	modalBg.Parent = parentGui

	fusionCard = Instance.new("Frame")
	fusionCard.Name = "FusionCard"
	fusionCard.Size = UDim2.new(0.4, 0, 0.5, 0)
	fusionCard.Position = UDim2.new(0.3, 0, 0.25, 0)
	fusionCard.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
	fusionCard.ZIndex = 101
	fusionCard.Parent = modalBg

	Instance.new("UICorner", fusionCard).CornerRadius = UDim.new(0, 8)
	AddBtnStroke(fusionCard, 90, 50, 120, 2)

	local closeBtn = Instance.new("TextButton", fusionCard)
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.Text = "X"
	closeBtn.ZIndex = 102
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
	closeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); modalBg.Visible = false end)

	local title = Instance.new("TextLabel", fusionCard)
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = Color3.fromRGB(255, 50, 255)
	title.TextScaled = true
	title.Text = "EQUIVALENT EXCHANGE"
	title.ZIndex = 102
	Instance.new("UITextSizeConstraint", title).MaxTextSize = 24

	local sub = Instance.new("TextLabel", fusionCard)
	sub.Size = UDim2.new(1, 0, 0.1, 0)
	sub.Position = UDim2.new(0, 0, 0.15, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamMedium
	sub.TextColor3 = Color3.fromRGB(200, 200, 200)
	sub.TextScaled = true
	sub.Text = "Select two Stands to fuse together."
	sub.ZIndex = 102
	Instance.new("UITextSizeConstraint", sub).MaxTextSize = 14

	local function CreateDropdown(yPos)
		local btn = Instance.new("TextButton", fusionCard)
		btn.Size = UDim2.new(0.8, 0, 0.12, 0)
		btn.Position = UDim2.new(0.1, 0, yPos, 0)
		btn.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextScaled = true
		btn.Text = "Select Stand..."
		btn.ZIndex = 102
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		AddBtnStroke(btn, 90, 50, 120, 1)
		Instance.new("UITextSizeConstraint", btn).MaxTextSize = 16

		local list = Instance.new("ScrollingFrame", btn)
		list.Size = UDim2.new(1, 0, 0, 150)
		list.Position = UDim2.new(0, 0, 1, 5)
		list.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
		list.ScrollBarThickness = 6
		list.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
		list.Visible = false
		list.ZIndex = 104
		Instance.new("UICorner", list).CornerRadius = UDim.new(0, 6)
		AddBtnStroke(list, 255, 215, 50, 2)
		local lLayout = Instance.new("UIListLayout", list)
		lLayout.SortOrder = Enum.SortOrder.LayoutOrder

		btn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			list.Visible = not list.Visible
		end)

		return btn, list
	end

	drop1Btn, list1 = CreateDropdown(0.3)
	drop2Btn, list2 = CreateDropdown(0.45)

	previewLabel = Instance.new("TextLabel", fusionCard)
	previewLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
	previewLabel.Position = UDim2.new(0.05, 0, 0.62, 0)
	previewLabel.BackgroundTransparency = 1
	previewLabel.Font = Enum.Font.GothamBlack
	previewLabel.TextColor3 = Color3.new(1, 1, 1)
	previewLabel.TextScaled = true
	previewLabel.RichText = true
	previewLabel.Text = "Select two stands to preview fusion."
	previewLabel.ZIndex = 102
	Instance.new("UITextSizeConstraint", previewLabel).MaxTextSize = 20

	fuseBtn = Instance.new("TextButton", fusionCard)
	fuseBtn.Size = UDim2.new(0.5, 0, 0.12, 0)
	fuseBtn.Position = UDim2.new(0.25, 0, 0.82, 0)
	fuseBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	fuseBtn.Font = Enum.Font.GothamBold
	fuseBtn.TextColor3 = Color3.new(1, 1, 1)
	fuseBtn.TextScaled = true
	fuseBtn.Text = "FUSE"
	fuseBtn.ZIndex = 102
	Instance.new("UICorner", fuseBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(fuseBtn, 255, 255, 255, 1)
	Instance.new("UITextSizeConstraint", fuseBtn).MaxTextSize = 20

	fuseBtn.MouseButton1Click:Connect(function()
		if selectedSlot1 and selectedSlot2 then
			if selectedSlot1 == selectedSlot2 then
				NotificationManager.Show("<font color='#FF5555'>You must select two different stands!</font>")
				return
			end
			SFXManager.Play("Click")
			local ExecuteFusion = Network:FindFirstChild("ExecuteFusion")
			if ExecuteFusion then
				ExecuteFusion:FireServer(selectedSlot1, selectedSlot2)
				modalBg.Visible = false
			end
		else
			SFXManager.Play("CombatBlock")
		end
	end)

	local OpenFusionUI = Network:FindFirstChild("OpenFusionUI") or Instance.new("RemoteEvent", Network)
	OpenFusionUI.Name = "OpenFusionUI"

	OpenFusionUI.OnClientEvent:Connect(function()
		selectedSlot1 = nil; selectedSlot2 = nil
		selectedName1 = nil; selectedName2 = nil
		drop1Btn.Text = "Select Stand 1..."
		drop2Btn.Text = "Select Stand 2..."
		UpdatePreview()

		PopulateDropdown(list1, drop1Btn, true)
		PopulateDropdown(list2, drop2Btn, false)

		modalBg.Visible = true
	end)
end

return FusionModal