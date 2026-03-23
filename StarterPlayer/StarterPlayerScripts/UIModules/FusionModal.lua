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

local modalBg
local mainView, slotSelectView
local drop1Btn, drop2Btn, list1, list2
local previewLabel, abilitiesLabel, fuseBtn
local selectedSlot1, selectedSlot2
local selectedName1, selectedName2
local selectedTrait1, selectedTrait2
local dropdownBtnTpl

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
		local b = dropdownBtnTpl:Clone()
		b.BackgroundTransparency = (i%2==0) and 0.5 or 1

		local tCol = StandData.Traits[opt.Trait] and StandData.Traits[opt.Trait].Color or "#FFFFFF"
		local tStr = opt.Trait ~= "None" and " <font color='"..tCol.."'>["..opt.Trait.."]</font>" or ""
		b.Text = opt.Slot .. ": " .. opt.Name .. tStr
		b.Parent = listFrame

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
	local modals = parentGui:WaitForChild("ModalsContainer")
	modalBg = modals:WaitForChild("FusionModalBg")
	dropdownBtnTpl = ReplicatedStorage:WaitForChild("JJBITemplates"):WaitForChild("FusionDropdownBtnTemplate")

	local fusionCard = modalBg:WaitForChild("FusionCard")
	local closeBtn = fusionCard:WaitForChild("CloseBtn")
	closeBtn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); modalBg.Visible = false end)

	mainView = fusionCard:WaitForChild("MainView")
	drop1Btn = mainView:WaitForChild("Drop1Btn")
	list1 = drop1Btn:WaitForChild("ListScroll")
	drop2Btn = mainView:WaitForChild("Drop2Btn")
	list2 = drop2Btn:WaitForChild("ListScroll")

	drop1Btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); list1.Visible = not list1.Visible end)
	drop2Btn.MouseButton1Click:Connect(function() SFXManager.Play("Click"); list2.Visible = not list2.Visible end)

	previewLabel = mainView:WaitForChild("PreviewLabel")

	local abilitiesScroll = mainView:WaitForChild("AbilitiesScroll")
	abilitiesLabel = abilitiesScroll:WaitForChild("AbilitiesLabel")
	abilitiesLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		abilitiesScroll.CanvasSize = UDim2.new(0, 0, 0, abilitiesLabel.AbsoluteSize.Y + 10)
	end)

	fuseBtn = mainView:WaitForChild("FuseBtn")

	slotSelectView = fusionCard:WaitForChild("SlotSelectView")
	local slotGrid = slotSelectView:WaitForChild("SlotGrid")

	local btnActive = slotGrid:WaitForChild("BtnActive")
	local btnS1 = slotGrid:WaitForChild("BtnS1")
	local btnS2 = slotGrid:WaitForChild("BtnS2")
	local btnS3 = slotGrid:WaitForChild("BtnS3")
	local btnS4 = slotGrid:WaitForChild("BtnS4")
	local btnS5 = slotGrid:WaitForChild("BtnS5")

	local function setupSlotBtn(btn, slotId)
		btn.MouseButton1Click:Connect(function()
			SFXManager.Play("Click")
			local ExecuteFusion = Network:FindFirstChild("ExecuteFusion")
			if ExecuteFusion then
				ExecuteFusion:FireServer(selectedSlot1, selectedSlot2, slotId)
				modalBg.Visible = false
			end
		end)
	end
	setupSlotBtn(btnActive, "Active")
	setupSlotBtn(btnS1, "Slot1")
	setupSlotBtn(btnS2, "Slot2")
	setupSlotBtn(btnS3, "Slot3")
	setupSlotBtn(btnS4, "Slot4")
	setupSlotBtn(btnS5, "Slot5")

	local cancelSlotBtn = slotSelectView:WaitForChild("CancelSlotBtn")
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