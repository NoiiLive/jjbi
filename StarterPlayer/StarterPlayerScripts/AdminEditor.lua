-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = ReplicatedStorage:WaitForChild("Network")

local AdminEditUI = Network:WaitForChild("AdminEditUI")
local AdminEditAction = Network:WaitForChild("AdminEditAction")

local currentEditData = nil
local currentEditTarget = ""
local currentEditTab = "Inventory"
local editGui = nil
local editScrollFrame = nil
local editTopBarContainer = nil

local function ClearContainer(container)
	if not container then return end
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function RenderInventory()
	local addBox = Instance.new("TextBox")
	addBox.Size = UDim2.new(1, -60, 1, 0)
	addBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	addBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	addBox.PlaceholderText = "Type item name to add..."
	addBox.Text = ""
	addBox.Font = Enum.Font.SourceSans
	addBox.TextSize = 16
	addBox.BorderSizePixel = 0
	addBox.Parent = editTopBarContainer

	local addBtn = Instance.new("TextButton")
	addBtn.Size = UDim2.new(0, 50, 1, 0)
	addBtn.Position = UDim2.new(1, -50, 0, 0)
	addBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
	addBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	addBtn.Text = "+"
	addBtn.Font = Enum.Font.GothamBold
	addBtn.TextSize = 18
	addBtn.BorderSizePixel = 0
	addBtn.Parent = editTopBarContainer

	addBtn.MouseButton1Click:Connect(function()
		if addBox.Text ~= "" then
			AdminEditAction:FireServer("AddItem", currentEditTarget, addBox.Text)
			addBox.Text = ""
		end
	end)

	for item, count in pairs(currentEditData.Inventory or {}) do
		local itemFrame = Instance.new("Frame")
		itemFrame.Size = UDim2.new(1, 0, 0, 35)
		itemFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		itemFrame.BorderSizePixel = 0
		itemFrame.Parent = editScrollFrame

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -80, 1, 0)
		nameLabel.Position = UDim2.new(0, 10, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
		nameLabel.Text = item .. " (x" .. tostring(count) .. ")"
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Font = Enum.Font.SourceSans
		nameLabel.TextSize = 16
		nameLabel.Parent = itemFrame

		local minusBtn = Instance.new("TextButton")
		minusBtn.Size = UDim2.new(0, 30, 0, 25)
		minusBtn.Position = UDim2.new(1, -70, 0, 5)
		minusBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
		minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		minusBtn.Text = "-"
		minusBtn.Font = Enum.Font.GothamBold
		minusBtn.TextSize = 16
		minusBtn.BorderSizePixel = 0
		minusBtn.Parent = itemFrame

		local plusBtn = Instance.new("TextButton")
		plusBtn.Size = UDim2.new(0, 30, 0, 25)
		plusBtn.Position = UDim2.new(1, -35, 0, 5)
		plusBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		plusBtn.Text = "+"
		plusBtn.Font = Enum.Font.GothamBold
		plusBtn.TextSize = 16
		plusBtn.BorderSizePixel = 0
		plusBtn.Parent = itemFrame

		minusBtn.MouseButton1Click:Connect(function()
			AdminEditAction:FireServer("RemoveItem", currentEditTarget, item)
		end)

		plusBtn.MouseButton1Click:Connect(function()
			AdminEditAction:FireServer("AddItem", currentEditTarget, item)
		end)
	end
end

local function RenderStands()
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Text = "Player Stand Storage"
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.Parent = editTopBarContainer

	local sortedSlots = {}
	for k in pairs(currentEditData.Stands or {}) do table.insert(sortedSlots, k) end
	table.sort(sortedSlots)

	for _, slotName in ipairs(sortedSlots) do
		local standInfo = currentEditData.Stands[slotName]
		local standFrame = Instance.new("Frame")
		standFrame.Size = UDim2.new(1, 0, 0, 120)
		standFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		standFrame.BorderSizePixel = 0
		standFrame.Parent = editScrollFrame

		local slotLabel = Instance.new("TextLabel")
		slotLabel.Size = UDim2.new(1, -10, 0, 25)
		slotLabel.Position = UDim2.new(0, 10, 0, 5)
		slotLabel.BackgroundTransparency = 1
		slotLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		slotLabel.Text = string.gsub(slotName, "^%d+_", "")
		slotLabel.TextXAlignment = Enum.TextXAlignment.Left
		slotLabel.Font = Enum.Font.GothamBold
		slotLabel.TextSize = 14
		slotLabel.Parent = standFrame

		if standInfo.Locked then
			local lockedLabel = Instance.new("TextLabel")
			lockedLabel.Size = UDim2.new(1, -20, 0, 30)
			lockedLabel.Position = UDim2.new(0, 10, 0, 35)
			lockedLabel.BackgroundTransparency = 1
			lockedLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			lockedLabel.Text = "Slot Locked"
			lockedLabel.TextXAlignment = Enum.TextXAlignment.Left
			lockedLabel.Font = Enum.Font.SourceSansItalic
			lockedLabel.TextSize = 16
			lockedLabel.Parent = standFrame
			standFrame.Size = UDim2.new(1, 0, 0, 70)
		else
			local isFused = standInfo.FusedWith and standInfo.FusedWith ~= ""

			local stand1Box = Instance.new("TextBox")
			stand1Box.Size = isFused and UDim2.new(0.5, -45, 0, 30) or UDim2.new(1, -80, 0, 30)
			stand1Box.Position = UDim2.new(0, 10, 0, 35)
			stand1Box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			stand1Box.TextColor3 = Color3.fromRGB(255, 255, 255)
			stand1Box.PlaceholderText = "Stand Name"
			stand1Box.Text = standInfo.Name or ""
			stand1Box.Font = Enum.Font.SourceSans
			stand1Box.TextSize = 16
			stand1Box.BorderSizePixel = 0
			stand1Box.Parent = standFrame

			local stand2Box = Instance.new("TextBox")
			stand2Box.Size = UDim2.new(0.5, -45, 0, 30)
			stand2Box.Position = UDim2.new(0.5, -25, 0, 35)
			stand2Box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			stand2Box.TextColor3 = Color3.fromRGB(255, 255, 255)
			stand2Box.PlaceholderText = "Fused Stand Name"
			stand2Box.Text = standInfo.FusedWith or ""
			stand2Box.Font = Enum.Font.SourceSans
			stand2Box.TextSize = 16
			stand2Box.BorderSizePixel = 0
			stand2Box.Visible = isFused
			stand2Box.Parent = standFrame

			local fuseToggleBtn = Instance.new("TextButton")
			fuseToggleBtn.Size = UDim2.new(0, 60, 0, 30)
			fuseToggleBtn.Position = UDim2.new(1, -70, 0, 35)
			fuseToggleBtn.BackgroundColor3 = isFused and Color3.fromRGB(150, 100, 50) or Color3.fromRGB(50, 100, 150)
			fuseToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			fuseToggleBtn.Text = isFused and "Fused" or "Normal"
			fuseToggleBtn.Font = Enum.Font.GothamBold
			fuseToggleBtn.TextSize = 12
			fuseToggleBtn.BorderSizePixel = 0
			fuseToggleBtn.Parent = standFrame

			fuseToggleBtn.MouseButton1Click:Connect(function()
				isFused = not isFused
				fuseToggleBtn.Text = isFused and "Fused" or "Normal"
				fuseToggleBtn.BackgroundColor3 = isFused and Color3.fromRGB(150, 100, 50) or Color3.fromRGB(50, 100, 150)
				stand2Box.Visible = isFused
				stand1Box.Size = isFused and UDim2.new(0.5, -45, 0, 30) or UDim2.new(1, -80, 0, 30)
			end)

			local trait1Box = Instance.new("TextBox")
			trait1Box.Size = UDim2.new(0.5, -45, 0, 30)
			trait1Box.Position = UDim2.new(0, 10, 0, 75)
			trait1Box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			trait1Box.TextColor3 = Color3.fromRGB(255, 255, 255)
			trait1Box.PlaceholderText = "Trait 1"
			trait1Box.Text = standInfo.Trait1 or ""
			trait1Box.Font = Enum.Font.SourceSans
			trait1Box.TextSize = 16
			trait1Box.BorderSizePixel = 0
			trait1Box.Parent = standFrame

			local trait2Box = Instance.new("TextBox")
			trait2Box.Size = UDim2.new(0.5, -45, 0, 30)
			trait2Box.Position = UDim2.new(0.5, -25, 0, 75)
			trait2Box.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			trait2Box.TextColor3 = Color3.fromRGB(255, 255, 255)
			trait2Box.PlaceholderText = "Trait 2"
			trait2Box.Text = standInfo.Trait2 or ""
			trait2Box.Font = Enum.Font.SourceSans
			trait2Box.TextSize = 16
			trait2Box.BorderSizePixel = 0
			trait2Box.Parent = standFrame

			local applyBtn = Instance.new("TextButton")
			applyBtn.Size = UDim2.new(0, 45, 0, 30)
			applyBtn.Position = UDim2.new(1, -125, 0, 75)
			applyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
			applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			applyBtn.Text = "Set"
			applyBtn.Font = Enum.Font.GothamBold
			applyBtn.TextSize = 12
			applyBtn.BorderSizePixel = 0
			applyBtn.Parent = standFrame

			local clearBtn = Instance.new("TextButton")
			clearBtn.Size = UDim2.new(0, 45, 0, 30)
			clearBtn.Position = UDim2.new(1, -70, 0, 75)
			clearBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
			clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			clearBtn.Text = "-"
			clearBtn.Font = Enum.Font.GothamBold
			clearBtn.TextSize = 16
			clearBtn.BorderSizePixel = 0
			clearBtn.Parent = standFrame

			applyBtn.MouseButton1Click:Connect(function()
				local updateData = {
					Name = stand1Box.Text,
					FusedWith = isFused and stand2Box.Text or nil,
					Trait1 = trait1Box.Text,
					Trait2 = trait2Box.Text
				}
				AdminEditAction:FireServer("UpdateStand", currentEditTarget, slotName, updateData)
			end)

			clearBtn.MouseButton1Click:Connect(function()
				AdminEditAction:FireServer("ClearStand", currentEditTarget, slotName)
			end)
		end
	end
end

local function RenderStyles()
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.Text = "Player Style Storage"
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.Parent = editTopBarContainer

	local sortedSlots = {}
	for k in pairs(currentEditData.Styles or {}) do table.insert(sortedSlots, k) end
	table.sort(sortedSlots)

	for _, slotName in ipairs(sortedSlots) do
		local styleInfo = currentEditData.Styles[slotName]
		local styleFrame = Instance.new("Frame")
		styleFrame.Size = UDim2.new(1, 0, 0, 80)
		styleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		styleFrame.BorderSizePixel = 0
		styleFrame.Parent = editScrollFrame

		local slotLabel = Instance.new("TextLabel")
		slotLabel.Size = UDim2.new(1, -10, 0, 25)
		slotLabel.Position = UDim2.new(0, 10, 0, 5)
		slotLabel.BackgroundTransparency = 1
		slotLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		slotLabel.Text = string.gsub(slotName, "^%d+_", "")
		slotLabel.TextXAlignment = Enum.TextXAlignment.Left
		slotLabel.Font = Enum.Font.GothamBold
		slotLabel.TextSize = 14
		slotLabel.Parent = styleFrame

		if styleInfo.Locked then
			local lockedLabel = Instance.new("TextLabel")
			lockedLabel.Size = UDim2.new(1, -20, 0, 30)
			lockedLabel.Position = UDim2.new(0, 10, 0, 35)
			lockedLabel.BackgroundTransparency = 1
			lockedLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			lockedLabel.Text = "Slot Locked"
			lockedLabel.TextXAlignment = Enum.TextXAlignment.Left
			lockedLabel.Font = Enum.Font.SourceSansItalic
			lockedLabel.TextSize = 16
			lockedLabel.Parent = styleFrame
			styleFrame.Size = UDim2.new(1, 0, 0, 70)
		else
			local styleBox = Instance.new("TextBox")
			styleBox.Size = UDim2.new(1, -140, 0, 30)
			styleBox.Position = UDim2.new(0, 10, 0, 35)
			styleBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			styleBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			styleBox.PlaceholderText = "Style Name"
			styleBox.Text = styleInfo.Name or ""
			styleBox.Font = Enum.Font.SourceSans
			styleBox.TextSize = 16
			styleBox.BorderSizePixel = 0
			styleBox.Parent = styleFrame

			local applyBtn = Instance.new("TextButton")
			applyBtn.Size = UDim2.new(0, 50, 0, 30)
			applyBtn.Position = UDim2.new(1, -120, 0, 35)
			applyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
			applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			applyBtn.Text = "Set"
			applyBtn.Font = Enum.Font.GothamBold
			applyBtn.TextSize = 14
			applyBtn.BorderSizePixel = 0
			applyBtn.Parent = styleFrame

			local clearBtn = Instance.new("TextButton")
			clearBtn.Size = UDim2.new(0, 50, 0, 30)
			clearBtn.Position = UDim2.new(1, -60, 0, 35)
			clearBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
			clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			clearBtn.Text = "-"
			clearBtn.Font = Enum.Font.GothamBold
			clearBtn.TextSize = 18
			clearBtn.BorderSizePixel = 0
			clearBtn.Parent = styleFrame

			applyBtn.MouseButton1Click:Connect(function()
				AdminEditAction:FireServer("UpdateStyle", currentEditTarget, slotName, styleBox.Text)
			end)

			clearBtn.MouseButton1Click:Connect(function()
				AdminEditAction:FireServer("ClearStyle", currentEditTarget, slotName)
			end)
		end
	end
end

local function RenderCurrentTab()
	ClearContainer(editTopBarContainer)
	ClearContainer(editScrollFrame)

	if currentEditTab == "Inventory" then
		RenderInventory()
	elseif currentEditTab == "Stands" then
		RenderStands()
	elseif currentEditTab == "Styles" then
		RenderStyles()
	end
end

AdminEditUI.OnClientEvent:Connect(function(targetName, data)
	currentEditTarget = targetName
	currentEditData = data

	if editGui then editGui:Destroy() end

	editGui = Instance.new("ScreenGui")
	editGui.Name = "AdminEditGui"
	editGui.ResetOnSpawn = false
	editGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local mainFrame = Instance.new("Frame")
	mainFrame.Size = UDim2.new(0, 600, 0, 450)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = editGui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = " Editing Player: " .. targetName
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.BorderSizePixel = 0
	title.Parent = mainFrame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -30, 0, 0)
	closeBtn.BackgroundTransparency = 1
	closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeBtn.Text = "X"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.Parent = mainFrame

	closeBtn.MouseButton1Click:Connect(function()
		editGui:Destroy()
		editGui = nil
	end)

	local tabContainer = Instance.new("Frame")
	tabContainer.Size = UDim2.new(1, -20, 0, 30)
	tabContainer.Position = UDim2.new(0, 10, 0, 40)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = mainFrame

	local tabs = {"Inventory", "Stands", "Styles"}
	local tabWidth = 1 / #tabs
	local tabButtons = {}

	for i, tabName in ipairs(tabs) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(tabWidth, -5, 1, 0)
		btn.Position = UDim2.new((i-1)*tabWidth, 0, 0, 0)
		btn.BackgroundColor3 = tabName == currentEditTab and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(30, 30, 30)
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Text = tabName
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 14
		btn.BorderSizePixel = 0
		btn.Parent = tabContainer

		btn.MouseButton1Click:Connect(function()
			currentEditTab = tabName
			for _, b in ipairs(tabButtons) do b.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			RenderCurrentTab()
		end)
		table.insert(tabButtons, btn)
	end

	editTopBarContainer = Instance.new("Frame")
	editTopBarContainer.Size = UDim2.new(1, -20, 0, 30)
	editTopBarContainer.Position = UDim2.new(0, 10, 0, 80)
	editTopBarContainer.BackgroundTransparency = 1
	editTopBarContainer.Parent = mainFrame

	editScrollFrame = Instance.new("ScrollingFrame")
	editScrollFrame.Size = UDim2.new(1, -20, 1, -130)
	editScrollFrame.Position = UDim2.new(0, 10, 0, 120)
	editScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	editScrollFrame.BorderSizePixel = 0
	editScrollFrame.ScrollBarThickness = 4
	editScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	editScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	editScrollFrame.Parent = mainFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = editScrollFrame

	RenderCurrentTab()
end)