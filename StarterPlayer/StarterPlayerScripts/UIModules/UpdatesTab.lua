-- @ScriptType: ModuleScript
-- @ScriptType: ModuleScript
local UpdatesTab = {}

local UpdatesData = {
	[[<b><font color='#FFD700'>v1.9 - UI Rework Update (March 20th)</font></b>

<font color='#55FF55'>[+]</font> <b>UI Rework:</b> Updated all the in-game UI to be cleaner and more visually interesting.
<font color='#55FF55'>[+]</font> <b>World Boss:</b> World Boss now gives a stand arrow even if you die.
<font color='#55FF55'>[+]</font> <b>Inventory Changes:</b> All consumables are now considered 'key items' (no longer take inventory space). Prestige inventory space has been removed.
<font color='#55FF55'>[+]</font> <b>Combat Pace:</b> Turn deadlines in multiplayer combat have been cut down significantly.

Use code <b><font color='#FF55FF'>GUIREWORK</font></b> and <b><font color='#FF55FF'>250KVISITS</font></b> for free rewards!]],

	[[<b><font color='#FFD700'>v1.8 - Gangs & QoL Update (March 16th)</font></b>

<font color='#55FF55'>[+]</font> <b>Gang Overhaul:</b> Added Gang Emblems, Mottos, and collaborative Orders for loot, treasury, and rep rewards.
<font color='#55FF55'>[+]</font> <b>Gang Infrastructure:</b> Buildings (Armory, HQ, etc.) now provide passive bonuses and are unlocked via Gang Level.
<font color='#55FF55'>[+]</font> <b>New Stand:</b> Added King Crimson Requiem as an evolvable stand.
<font color='#55FF55'>[+]</font> <b>QoL & Fixes:</b> SBR scaling by player count, physical gamepass trading, and stat cap enforcements.]],

	[[<b><font color='#FFD700'>v1.7 - Steel Ball Run Update PART 2 (March 13th)</font></b>

<font color='#55FF55'>[+]</font> <b>New Gamemode:</b> The Steel Ball Run hourly gamemode is here! Participate to earn massive free rewards, including mythical items.
<font color='#55FF55'>[+]</font> <b>Roster Expansion:</b> Added The World: High Voltage and 7 more unique Part-7 Stands!
<font color='#55FF55'>[+]</font> <b>Rebalances:</b> The World & Star Platinum have been promoted to Mythical/Boss Stand tier.
<font color='#55FF55'>[+]</font> <b>Style Economy:</b> Added Fighting Style Storage slots (Starts with 1 slot). Styles can now be securely traded, and claiming them from shops/gifts now features a dedicated slot menu.]],

	[[<b><font color='#FFD700'>v1.6 - Steel Ball Run Update PART 1 (March 10th)</font></b>

<font color='#55FF55'>[+]</font> <b>Part 7 Expanded:</b> Added a new PART 7 extension to story mode featuring harder enemies!
<font color='#55FF55'>[+]</font> <b>New Stands:</b> Added 16 NEW stands from Part 7, obtainable exclusively through the Saint's Corpse Part.
<font color='#55FF55'>[+]</font> <b>Heaven & Requiem:</b> Added The World: Over Heaven and Star Platinum: Over Heaven.
<font color='#55FF55'>[+]</font> <b>New Combat Styles:</b> Added Spin, Golden Spin, and the Ultimate Lifeform styles.]],

	[[<b><font color='#FFD700'>v1.5 - Requiem Update (March 7th)</font></b>

<font color='#55FF55'>[+]</font> <b>World Boss System:</b> A massive threat now spawns every hour at XX:00! Engage in a 10-turn damage race to earn rewards scaled by your performance (+1% Drop Chance per 100k Damage).
<font color='#55FF55'>[+]</font> <b>Requiem Arrives:</b> Gold Experience Requiem and Silver Chariot Requiem have been added!
<font color='#55FF55'>[+]</font> <b>15 New Stands:</b> The roster has expanded significantly with 15 new playable Stands, each with unique skill sets!]],

	[[<b><font color='#FFD700'>v1.4 - Combat Overhaul (March 5th)</font></b>

<font color='#55FF55'>[+]</font> <b>Combat Rework:</b> Completely rebuilt the combat engine for smoother, more dynamic battles!
<font color='#55FF55'>[+]</font> <b>Abilities Overhauled:</b> All Stand abilities have been completely overhauled. Barrages are now true multi-hit attacks!
<font color='#55FF55'>[+]</font> <b>New Traits & Statuses:</b> Added multiple new Stand Traits and diverse Status Effects (Debuffs, Freeze, Bleed, etc.) to spice up gameplay.]],

	[[<b><font color='#FFD700'>v1.3 - Multiplayer Update (March 4th)</font></b>

<font color='#55FF55'>[+]</font> <b>Raid Bosses:</b> Party up with up to 4 players to challenge massive bosses! Featuring dynamic scaling, Mythical drops, and a new Raid Wins leaderboard.
<font color='#55FF55'>[+]</font> <b>Gangs System:</b> Form a Gang for 500k Yen! Includes a Reputation system with global bonuses, a shared Treasury, and exclusive Gang leaderboards.
<font color='#55FF55'>[+]</font> <b>New Arena Modes:</b> 2v2 and 4v4 group combat is now live!]],

	[[<b><font color='#FFD700'>v1.2 - Prestige Update (March 3rd)</font></b>

<font color='#55FF55'>[+]</font> <b>Dungeons & Endless Mode:</b> Reaching Prestige 5+ unlocks new Gauntlet Dungeons and Endless mode.
<font color='#55FF55'>[+]</font> <b>Player Trading:</b> Securely trade items, Stands, and Yen.
<font color='#55FF55'>[+]</font> <b>Universe Modifiers:</b> Prestiging applies random buffs/debuffs to your next run.]]
}

local function applyDoubleGoldBorder(parent)
	local outerStroke = Instance.new("UIStroke")
	outerStroke.Thickness = 3
	outerStroke.Color = Color3.fromRGB(255, 210, 60)
	outerStroke.LineJoinMode = Enum.LineJoinMode.Round
	outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local gradOut = Instance.new("UIGradient", outerStroke)
	gradOut.Rotation = -45
	gradOut.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 160, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 160, 30))
	}
	outerStroke.Parent = parent

	local innerFrame = Instance.new("Frame", parent)
	innerFrame.Name = "InnerGoldBorder"
	innerFrame.Size = UDim2.new(1, -6, 1, -6)
	innerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	innerFrame.BackgroundTransparency = 1
	innerFrame.ZIndex = parent.ZIndex

	local parentCorner = parent:FindFirstChildOfClass("UICorner")
	if parentCorner then
		local innerCorner = Instance.new("UICorner")
		innerCorner.CornerRadius = UDim.new(0, math.max(0, parentCorner.CornerRadius.Offset - 3))
		innerCorner.Parent = innerFrame
	end

	local innerStroke = Instance.new("UIStroke", innerFrame)
	innerStroke.Thickness = 1
	innerStroke.Color = Color3.fromRGB(255, 230, 100)
	innerStroke.LineJoinMode = Enum.LineJoinMode.Round
	innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local gradIn = Instance.new("UIGradient", innerStroke)
	gradIn.Rotation = 45
	gradIn.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 25))
	}
end

function UpdatesTab.Init(parentFrame, tooltipMgr)
	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0.85, 0, 0.85, 0)
	mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
	mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	mainPanel.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
	mainPanel.BorderSizePixel = 0
	mainPanel.ZIndex = 15
	mainPanel.ClipsDescendants = true
	mainPanel.Parent = parentFrame

	Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 12)
	applyDoubleGoldBorder(mainPanel)

	local bgPattern = Instance.new("ImageLabel")
	bgPattern.Name = "OverlayPattern"
	bgPattern.Image = "rbxassetid://79623015802180"
	bgPattern.ImageColor3 = Color3.fromRGB(180, 130, 255)
	bgPattern.ImageTransparency = 0.85
	bgPattern.BackgroundTransparency = 1
	bgPattern.ScaleType = Enum.ScaleType.Tile
	bgPattern.TileSize = UDim2.new(0, 500, 0, 250)
	bgPattern.Size = UDim2.new(1, 0, 1, 0)
	bgPattern.ZIndex = 16
	bgPattern.Parent = mainPanel

	local camera = workspace.CurrentCamera
	local function UpdateLayoutForScreen()
		if not parentFrame.Parent then return end
		local vp = camera.ViewportSize
		if vp.X >= 1050 then
			mainPanel.Size = UDim2.new(0.80, 0, 0.88, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.48, 0)
		elseif vp.X >= 600 and vp.X < 1050 then
			mainPanel.Size = UDim2.new(0.92, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
		else
			mainPanel.Size = UDim2.new(0.96, 0, 0.82, 0)
			mainPanel.Position = UDim2.new(0.5, 0, 0.50, 0)
		end
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
	UpdateLayoutForScreen()

	local innerContent = Instance.new("Frame")
	innerContent.Name = "InnerContent"
	innerContent.Size = UDim2.new(1, 0, 1, 0)
	innerContent.BackgroundTransparency = 1
	innerContent.ZIndex = 17
	innerContent.Parent = mainPanel

	local mainPad = Instance.new("UIPadding", innerContent)
	mainPad.PaddingTop = UDim.new(0.04, 0)
	mainPad.PaddingBottom = UDim.new(0.04, 0)
	mainPad.PaddingLeft = UDim.new(0.04, 0)
	mainPad.PaddingRight = UDim.new(0.04, 0)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "UPDATE LOG"
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 50)
	titleLabel.TextSize = 24
	titleLabel.ZIndex = 22
	titleLabel.Parent = innerContent

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, 0, 1, -45)
	scrollFrame.Position = UDim2.new(0, 0, 0, 45)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 50, 120)
	scrollFrame.ZIndex = 20
	scrollFrame.Parent = innerContent

	local listLayout = Instance.new("UIListLayout", scrollFrame)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 15)

	local scrollPad = Instance.new("UIPadding", scrollFrame)
	scrollPad.PaddingRight = UDim.new(0, 10)
	scrollPad.PaddingLeft = UDim.new(0, 2)
	scrollPad.PaddingTop = UDim.new(0, 2)
	scrollPad.PaddingBottom = UDim.new(0, 10)

	for i, updateText in ipairs(UpdatesData) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 0)
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.BackgroundColor3 = Color3.fromRGB(25, 10, 35)
		card.LayoutOrder = i
		card.ZIndex = 21
		card.Parent = scrollFrame

		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
		local stroke = Instance.new("UIStroke", card)
		stroke.Color = Color3.fromRGB(90, 50, 120)
		stroke.Thickness = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		local cardPad = Instance.new("UIPadding", card)
		cardPad.PaddingTop = UDim.new(0, 15)
		cardPad.PaddingBottom = UDim.new(0, 15)
		cardPad.PaddingLeft = UDim.new(0, 15)
		cardPad.PaddingRight = UDim.new(0, 15)

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 0, 0)
		textLabel.AutomaticSize = Enum.AutomaticSize.Y
		textLabel.BackgroundTransparency = 1
		textLabel.Text = updateText
		textLabel.Font = Enum.Font.GothamMedium
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.TextSize = 15
		textLabel.RichText = true
		textLabel.TextWrapped = true
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextYAlignment = Enum.TextYAlignment.Top
		textLabel.ZIndex = 22
		textLabel.Parent = card
	end

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
	end)
end

return UpdatesTab