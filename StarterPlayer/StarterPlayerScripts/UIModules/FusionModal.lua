-- @ScriptType: ModuleScript
local FusionModal = {}

local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")
local FusionUtility = require(ReplicatedStorage:WaitForChild("FusionUtility"))
local SkillData = require(ReplicatedStorage:WaitForChild("SkillData"))
local StandData = require(ReplicatedStorage:WaitForChild("StandData"))
local UIModules = script.Parent
local SFXManager = require(UIModules:WaitForChild("SFXManager"))
local NotificationManager = require(UIModules:WaitForChild("NotificationManager"))

local modalBg, fusionCard
local mainView, slotSelectView
local drop1Btn, drop2Btn, list1, list2
local previewLabel, abilitiesLabel, fuseBtn
local selectedSlot1, selectedSlot2
local selectedName1, selectedName2
local selectedTrait1, selectedTrait2

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
	local function check(slot, standAttr, traitAttr)
		local sName = player:GetAttribute(standAttr) or "None"
		local sTrait = player:GetAttribute(traitAttr) or "None"
		if sName ~= "None" and sName ~= "Fused Stand" then
			table.insert(opts, {Slot = slot, Name = sName, Trait = sTrait})
		end
	end

	check("Active", "Stand", "StandTrait")
	check("Slot1", "StoredStand1", "StoredStand1_Trait")
	if player:GetAttribute("HasStandSlot2") then check("Slot2", "StoredStand2", "StoredStand2_Trait") end
	if player:GetAttribute("HasStandSlot3") then check("Slot3", "StoredStand3", "StoredStand3_Trait") end

	local prestige = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Prestige") and player.leaderstats.Prestige.Value or 0
	if prestige >= 15 then check("Slot4", "StoredStand4", "StoredStand4_Trait") end
	if prestige >= 30 then check("Slot5", "StoredStand5", "StoredStand5_Trait") end

	return opts
end

local function UpdatePreview()
	if selectedName1 and selectedName2 then
		local combinedName = FusionUtility.CalculateFusedName(selectedName1, selectedName2)

		local traitDisplay = ""
		local tCol1 = StandData.Traits[selectedTrait1] and StandData.Traits[selectedTrait1].Color or "#FFFFFF"
		local tCol2 = StandData.Traits[selectedTrait2] and StandData.Traits[selectedTrait2].Color or "#FFFFFF"

		if selectedTrait1 == "None" and selectedTrait2 == "None" then
			traitDisplay = ""
		elseif selectedTrait1 == "None" then
			traitDisplay = " <font color='" .. tCol2 .. "'>[" .. selectedTrait2:upper() .. "]</font>"
		elseif selectedTrait2 == "None" then
			traitDisplay = " <font color='" .. tCol1 .. "'>[" .. selectedTrait1:upper() .. "]</font>"
		else
			traitDisplay = " <font color='" .. tCol1 .. "'>[" .. selectedTrait1:upper() .. "]</font> & <font color='" .. tCol2 .. "'>[" .. selectedTrait2:upper() .. "]</font>"
		end

		previewLabel.Text = "Result: <font color='#A020F0'>" .. combinedName .. "</font>" .. traitDisplay

		local finalSkills = FusionUtility.CalculateFusedAbilities(selectedName1, selectedName2, SkillData)
		local skillStr = "<b>Inherited Abilities:</b>\n"
		for _, skill in ipairs(finalSkills) do
			skillStr = skillStr .. "• <font color='#FFD700'>" .. skill.Name .. "</font>\n"
		end
		abilitiesLabel.Text = skillStr

		fuseBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40)
		fuseBtn.AutoButtonColor = true
	else
		previewLabel.Text = "Select two stands to preview fusion."
		abilitiesLabel.Text = ""
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
		b.RichText = true
		b.ZIndex = 105

		local tCol = StandData.Traits[opt.Trait] and StandData.Traits[opt.Trait].Color or "#FFFFFF"
		local tStr = opt.Trait ~= "None" and " <font color='"..tCol.."'>["..opt.Trait.."]</font>" or ""
		b.Text = opt.Slot .. ": " .. opt.Name .. tStr

		b.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			targetBtn.Text = opt.Slot .. ": " .. opt.Name .. tStr
			if isSlot1 then
				selectedSlot1 = opt.Slot
				selectedName1 = opt.Name
				selectedTrait1 = opt.Trait
			else
				selectedSlot2 = opt.Slot
				selectedName2 = opt.Name
				selectedTrait2 = opt.Trait
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
	fusionCard.Size = UDim2.new(0.45, 0, 0.65, 0)
	fusionCard.Position = UDim2.new(0.275, 0, 0.175, 0)
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
	title.Size = UDim2.new(1, 0, 0.12, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = Color3.fromRGB(255, 50, 255)
	title.TextScaled = true
	title.Text = "EQUIVALENT EXCHANGE"
	title.ZIndex = 102
	Instance.new("UITextSizeConstraint", title).MaxTextSize = 24

	mainView = Instance.new("Frame", fusionCard)
	mainView.Size = UDim2.new(1, 0, 0.88, 0)
	mainView.Position = UDim2.new(0, 0, 0.12, 0)
	mainView.BackgroundTransparency = 1

	local sub = Instance.new("TextLabel", mainView)
	sub.Size = UDim2.new(1, 0, 0.08, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamMedium
	sub.TextColor3 = Color3.fromRGB(200, 200, 200)
	sub.TextScaled = true
	sub.Text = "Select two Stands to fuse together."
	sub.ZIndex = 102
	Instance.new("UITextSizeConstraint", sub).MaxTextSize = 14

	local function CreateDropdown(yPos)
		local btn = Instance.new("TextButton", mainView)
		btn.Size = UDim2.new(0.8, 0, 0.1, 0)
		btn.Position = UDim2.new(0.1, 0, yPos, 0)
		btn.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
		btn.Font = Enum.Font.GothamBold
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextScaled = true
		btn.RichText = true
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

	drop1Btn, list1 = CreateDropdown(0.12)
	drop2Btn, list2 = CreateDropdown(0.25)

	previewLabel = Instance.new("TextLabel", mainView)
	previewLabel.Size = UDim2.new(0.9, 0, 0.1, 0)
	previewLabel.Position = UDim2.new(0.05, 0, 0.38, 0)
	previewLabel.BackgroundTransparency = 1
	previewLabel.Font = Enum.Font.GothamBlack
	previewLabel.TextColor3 = Color3.new(1, 1, 1)
	previewLabel.TextScaled = true
	previewLabel.RichText = true
	previewLabel.Text = "Select two stands to preview fusion."
	previewLabel.ZIndex = 102
	Instance.new("UITextSizeConstraint", previewLabel).MaxTextSize = 20

	local abilitiesScroll = Instance.new("ScrollingFrame", mainView)
	abilitiesScroll.Size = UDim2.new(0.8, 0, 0.3, 0)
	abilitiesScroll.Position = UDim2.new(0.1, 0, 0.5, 0)
	abilitiesScroll.BackgroundColor3 = Color3.fromRGB(15, 5, 25)
	abilitiesScroll.ScrollBarThickness = 4
	abilitiesScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	abilitiesScroll.ZIndex = 102
	Instance.new("UICorner", abilitiesScroll).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(abilitiesScroll, 90, 50, 120, 1)

	abilitiesLabel = Instance.new("TextLabel", abilitiesScroll)
	abilitiesLabel.Size = UDim2.new(1, -10, 0, 0)
	abilitiesLabel.Position = UDim2.new(0, 5, 0, 5)
	abilitiesLabel.BackgroundTransparency = 1
	abilitiesLabel.Font = Enum.Font.GothamMedium
	abilitiesLabel.TextColor3 = Color3.new(1, 1, 1)
	abilitiesLabel.TextSize = 14
	abilitiesLabel.RichText = true
	abilitiesLabel.TextWrapped = true
	abilitiesLabel.TextXAlignment = Enum.TextXAlignment.Left
	abilitiesLabel.TextYAlignment = Enum.TextYAlignment.Top
	abilitiesLabel.AutomaticSize = Enum.AutomaticSize.Y
	abilitiesLabel.Text = ""
	abilitiesLabel.ZIndex = 103

	abilitiesLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		abilitiesScroll.CanvasSize = UDim2.new(0, 0, 0, abilitiesLabel.AbsoluteSize.Y + 10)
	end)

	fuseBtn = Instance.new("TextButton", mainView)
	fuseBtn.Size = UDim2.new(0.5, 0, 0.12, 0)
	fuseBtn.Position = UDim2.new(0.25, 0, 0.85, 0)
	fuseBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	fuseBtn.Font = Enum.Font.GothamBold
	fuseBtn.TextColor3 = Color3.new(1, 1, 1)
	fuseBtn.TextScaled = true
	fuseBtn.Text = "FUSE"
	fuseBtn.ZIndex = 102
	Instance.new("UICorner", fuseBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(fuseBtn, 255, 255, 255, 1)
	Instance.new("UITextSizeConstraint", fuseBtn).MaxTextSize = 20

	slotSelectView = Instance.new("Frame", fusionCard)
	slotSelectView.Size = UDim2.new(1, 0, 0.88, 0)
	slotSelectView.Position = UDim2.new(0, 0, 0.12, 0)
	slotSelectView.BackgroundTransparency = 1
	slotSelectView.Visible = false

	local ssSub = Instance.new("TextLabel", slotSelectView)
	ssSub.Size = UDim2.new(1, 0, 0.08, 0)
	ssSub.BackgroundTransparency = 1
	ssSub.Font = Enum.Font.GothamMedium
	ssSub.TextColor3 = Color3.new(1, 1, 1)
	ssSub.TextScaled = true
	ssSub.Text = "Where do you want to store the new Fused Stand?"
	ssSub.ZIndex = 102
	Instance.new("UITextSizeConstraint", ssSub).MaxTextSize = 16

	local slotGrid = Instance.new("Frame", slotSelectView)
	slotGrid.Size = UDim2.new(0.9, 0, 0.6, 0)
	slotGrid.Position = UDim2.new(0.05, 0, 0.15, 0)
	slotGrid.BackgroundTransparency = 1

	local sgLayout = Instance.new("UIGridLayout", slotGrid)
	sgLayout.CellSize = UDim2.new(0.48, 0, 0, 50)
	sgLayout.CellPadding = UDim2.new(0.04, 0, 0, 10)
	sgLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local function CreateSlotBtn(slotId, slotName, order)
		local b = Instance.new("TextButton", slotGrid)
		b.BackgroundColor3 = Color3.fromRGB(50, 15, 60)
		b.Font = Enum.Font.GothamBold
		b.TextColor3 = Color3.new(1, 1, 1)
		b.TextScaled = true
		b.Text = slotName
		b.ZIndex = 103
		b.LayoutOrder = order
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		AddBtnStroke(b, 200, 50, 255, 2)
		Instance.new("UITextSizeConstraint", b).MaxTextSize = 14

		b.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			local ExecuteFusion = Network:FindFirstChild("ExecuteFusion")
			if ExecuteFusion then
				ExecuteFusion:FireServer(selectedSlot1, selectedSlot2, slotId)
				modalBg.Visible = false
			end
		end)

		return b
	end

	local btnActive = CreateSlotBtn("Active", "Active Stand", 1)
	local btnS1 = CreateSlotBtn("Slot1", "Storage 1", 2)
	local btnS2 = CreateSlotBtn("Slot2", "Storage 2", 3)
	local btnS3 = CreateSlotBtn("Slot3", "Storage 3", 4)
	local btnS4 = CreateSlotBtn("Slot4", "Storage 4", 5)
	local btnS5 = CreateSlotBtn("Slot5", "Storage 5", 6)

	local cancelSlotBtn = Instance.new("TextButton", slotSelectView)
	cancelSlotBtn.Size = UDim2.new(0.4, 0, 0.12, 0)
	cancelSlotBtn.Position = UDim2.new(0.3, 0, 0.85, 0)
	cancelSlotBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
	cancelSlotBtn.Font = Enum.Font.GothamBold
	cancelSlotBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelSlotBtn.TextScaled = true
	cancelSlotBtn.Text = "Back"
	cancelSlotBtn.ZIndex = 102
	Instance.new("UICorner", cancelSlotBtn).CornerRadius = UDim.new(0, 6)
	AddBtnStroke(cancelSlotBtn, 200, 80, 80, 1)
	Instance.new("UITextSizeConstraint", cancelSlotBtn).MaxTextSize = 16

	cancelSlotBtn.MouseButton1Click:Connect(function()
		SFXManager.Play("Click")
		slotSelectView.Visible = false
		mainView.Visible = true
	end)

	fuseBtn.MouseButton1Click:Connect(function()
		if selectedSlot1 and selectedSlot2 then
			if selectedSlot1 == selectedSlot2 then
				NotificationManager.Show("<font color='#FF5555'>You must select two different stands!</font>")
				return
			end
			SFXManager.Play("Click")

			local ls = player:FindFirstChild("leaderstats")
			local prestige = ls and ls:FindFirstChild("Prestige") and ls.Prestige.Value or 0

			btnS2.Visible = player:GetAttribute("HasStandSlot2") == true
			btnS3.Visible = player:GetAttribute("HasStandSlot3") == true
			btnS4.Visible = prestige >= 15
			btnS5.Visible = prestige >= 30

			mainView.Visible = false
			slotSelectView.Visible = true
		else
			SFXManager.Play("CombatBlock")
		end
	end)

	local OpenFusionUI = Network:FindFirstChild("OpenFusionUI") or Instance.new("RemoteEvent", Network)
	OpenFusionUI.Name = "OpenFusionUI"

	OpenFusionUI.OnClientEvent:Connect(function()
		selectedSlot1 = nil; selectedSlot2 = nil
		selectedName1 = nil; selectedName2 = nil
		selectedTrait1 = nil; selectedTrait2 = nil

		drop1Btn.Text = "Select Stand 1..."
		drop2Btn.Text = "Select Stand 2..."
		UpdatePreview()

		PopulateDropdown(list1, drop1Btn, true)
		PopulateDropdown(list2, drop2Btn, false)

		mainView.Visible = true
		slotSelectView.Visible = false
		modalBg.Visible = true
	end)
end

return FusionModal