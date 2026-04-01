-- @ScriptType: ModuleScript
local UpdatesTab = {}

local UpdatesData = {
	[[<b><font color='#FFD700'>v2.2 - April Fools Update (April 1st)</font></b>

<font color='#55FF55'>[+]</font> <b>New Bosses:</b> 3 NEW World Bosses with LIMITED TIME Drops!
<font color='#55FF55'>[+]</font> <b>New Stand:</b> Chiikawa
<font color='#55FF55'>[+]</font> <b>New Styles:</b> 2 New Fighting Styles: Shrine & Limitless
<font color='#55FF55'>[+]</font> <b>New Gear:</b> 3 New Weapons & 3 New Accessories
<font color='#55FF55'>[+]</font> <b>New Trait:</b> Gambling Addict

Use code <b><font color='#FF55FF'>APRILFOOLS</font></b> for free rewards!]],

	[[<b><font color='#FFD700'>v2.1 - JoJolion Update PART 2 (March 22nd)</font></b>

<font color='#55FF55'>[+]</font> <b>Stand Fusion:</b> Fuse two Stands from your storage to create a hybrid Stand!
<font color='#55FF55'>[+]</font> <b>New Rokakaka:</b> A new item that opens up the Stand Fusion menu.
<font color='#55FF55'>[+]</font> <b>Hybrid Abilities & Names:</b> Fused Stands take the first half of their name and abilities from Stand 1, and the second half from Stand 2. Order matters!
<font color='#55FFFF'>[*]</font> <b>Bug Fixes:</b> Fixed mobile UI scrolling issues, Gang order tracking, and Gang renaming.

Use code <b><font color='#FF55FF'>FUSION</font></b> for free rewards!]],

	[[<b><font color='#FFD700'>v2.0 - JoJolion Update PART 1 (March 21st)</font></b>

<font color='#55FF55'>[+]</font> <b>New Stands:</b> Added Soft & Wet, Wonder of U, and many other Part 8 Stands!
<font color='#55FF55'>[+]</font> <b>Go Beyond:</b> Soft & Wet can now evolve into Soft & Wet: Go Beyond using the Rokakaka Branch!
<font color='#55FF55'>[+]</font> <b>New Combat Style:</b> Rock Human style has been added!
<font color='#55FF55'>[+]</font> <b>Story Expansion:</b> Part 8 Story Expansion is now playable after completing Part 7.
<font color='#55FF55'>[+]</font> <b>New Raid:</b> Added the Part 8 Raid (The Head Doctor) which drops a new accessory, weapon, and the Rokakaka Branch.
<font color='#55FF55'>[+]</font> <b>New World Boss:</b> Wonder of U is now a World Boss! Defeat him for a chance at his Stand Disc and the New Rokakaka.]],

	[[<b><font color='#FFD700'>v1.9 - UI Rework Update (March 20th)</font></b>

<font color='#55FF55'>[+]</font> <b>UI Rework:</b> Updated all the in-game UI to be cleaner and more visually interesting.
<font color='#55FF55'>[+]</font> <b>World Boss:</b> World Boss now gives a stand arrow even if you die.
<font color='#55FF55'>[+]</font> <b>Inventory Changes:</b> All consumables are now considered 'key items' (no longer take inventory space). Prestige inventory space has been removed.
<font color='#55FF55'>[+]</font> <b>Combat Pace:</b> Turn deadlines in multiplayer combat have been cut down significantly.]],

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

function UpdatesTab.Init(parentFrame, tooltipMgr)
	local mainPanel = parentFrame:WaitForChild("MainPanel")
	local innerContent = mainPanel:WaitForChild("InnerContent")
	local scrollFrame = innerContent:WaitForChild("ScrollFrame")
	local listLayout = scrollFrame:WaitForChild("UIListLayout")

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Templates = ReplicatedStorage:WaitForChild("JJBITemplates")
	local updateCardTpl = Templates:WaitForChild("UpdateCardTemplate")

	for _, child in pairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for i, updateText in ipairs(UpdatesData) do
		local card = updateCardTpl:Clone()
		card.LayoutOrder = i
		card.TextLabel.Text = updateText
		card.Parent = scrollFrame
	end

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
	end)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)

	local camera = workspace.CurrentCamera
	local resizeConn

	local function UpdateLayoutForScreen()
		if not parentFrame.Parent then
			if resizeConn then resizeConn:Disconnect() end
			return
		end

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

	resizeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateLayoutForScreen)
	UpdateLayoutForScreen()
end

return UpdatesTab