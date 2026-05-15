-- @ScriptType: ModuleScript
local UpdatesTab = {}

local UpdatesData = {
	[[<b><font color='#FFD700'>v2.8 - AOT: Incremental Crossover Event (April 28th)</font></b>

<font color='#55FF55'>[+]</font> <b>New World Boss:</b> Added Eren Jaeger World Boss
<font color='#55FF55'>[+]</font> <b>New Equipment:</b> Added ODM Blades Weapon and Scout Uniform Accessory
<font color='#55FF55'>[+]</font> <b>New Abilities:</b> Added ODM Gear Fighting Style and Attack Titan Stand
<font color='#55FF55'>[+]</font> <b>Special Rewards:</b> Defeat the Female Titan Raid in AOT: Incremental to receive the special "Source of All Living Matter" item; Used to evolve the Attack Titan into the limited Founding Titan Stand
<font color='#55FF55'>[+]</font> <b>New Badge:</b> Defeat the Part 1 Raid for Rewards in AOT: Incremental
<font color='#55FFFF'>[*]</font> <b>Fusion Name Additions:</b> Added and adjusted some more fusion names
<font color='#55FFFF'>[*]</font> <b>Fusion Index Changes:</b> You no longer need event stands for the fusion index
<font color='#55FFFF'>[*]</font> <b>Easter Egg Conversion:</b> Easter Eggs will automatically convert into Yen (10,000 per) when joining, Lucky Eggs will now give Yen instead of Easter Eggs (500k-2.5m)
<font color='#55FFFF'>[*]</font> <b>Rarity Changes:</b> Non-JoJo items are now 'Special' rarity (April Fools), to feel truly limited.]],

	[[<b><font color='#FFD700'>v2.7 - Stand Overhaul Update (April 25th)</font></b>
	
<font color='#D745FF'>[+]</font> <b>Stand Types:</b> Stands now have a 'Type' (Power > Automatic > Ranged > Power) that influences battle strengths and weaknesses!
<font color='#D745FF'>[+]</font> <b>Skill Tree & Prestige Points:</b> Earn Prestige Points upon prestiging to fuel your skill tree! Enhance abilities, unlock passives, and boost damage.
<font color='#D745FF'>[+]</font> <b>Persistent Upgrades:</b> Abilities can be upgraded to apply new status effects or function differently in combat. Upgrades save to the specific stand!
<font color='#D745FF'>[+]</font> <b>Stat Scaling:</b> Base damage multipliers have been replaced with stat upgrades in the skill tree. Weaker stands can now become viable through enough upgrading!
<font color='#EFFF3E'>[+]</font> <b>Ability Expansion:</b> Common, Uncommon, and Rare stands now have 3 skills, while Legendary+ stands feature 4 abilities!
<font color='#EFFF3E'>[+]</font> <b>Skill Tree Access:</b> Access the skill tree via the button next to the stand name in your inventory or directly through the Stand Index!

Use codes <b><font color='#FF55FF'>DELAYED</font></b> and <b><font color='#FF55FF'>SKILLTREES</font></b> for free rewards!]],

	[[<b><font color='#FFD700'>v2.6 - Combat Overhaul Update (April 17th)</font></b>

<font color='#D745FF'>[+]</font> <b>Synergized Statuses:</b> DoT effects (Burn, Bleed, Poison, Chilly) now merge into powerful Tier 2 and Tier 3 synergies when combined!
<font color='#D745FF'>[+]</font> <b>Resource Overhaul:</b> Enemies now utilize Stamina and Energy! Taking damage depletes resources. Running out applies 'Exhausted', disabling skills and increasing damage taken by 15% (Stacks up to 30%).
<font color='#D745FF'>[+]</font> <b>New Mechanics:</b> 
    • <b>Cleanse & Warded:</b> Rest now Cleanses all active statuses. Using Rest while Blocking applies 'Warded', granting status immunity for 2 turns!
    • <b>Counters:</b> New Counter skills allow you to predict, negate, and reflect enemy damage!
    • <b>Sub-Effects:</b> Enemies immune to Stun/Confusion now get 'Dizzy' (chance to miss/hit self). Freeze immunity applies 'Chilly' (DoT without stun).
<font color='#D745FF'>[+]</font> <b>DoT Rework:</b> Damage-over-Time effects now deal increased damage but respect the target's Defense.
<font color='#EFFF3E'>[+]</font> <b>Dynamic Fusion Index:</b> The Fusion Index Global Damage buff now scales fractionally! You no longer need 100% completion to see a damage increase; every individual fusion now contributes to your multiplier.
<font color='#EFFF3E'>[+]</font> <b>Training Manuals & Stat Rework:</b> Added 15 new Legendary and Mythical Training Manuals to boost your stats! To balance this, items like Stand Arrows and the Green Baby no longer grant bonus stats upon use.
<font color='#EFFF3E'>[+]</font> <b>AI Improvements:</b> Enemies are now much smarter! They manage resources, rest when heavily debuffed, and adapt their strategy based on their HP.
<font color='#EFFF3E'>[+]</font> <b>8 New Traits:</b> Added Siphoning, Shattering, Dominating, Infectious, Junkie (Mythics), Purifying, Opportunistic, and Stoic (Legendaries).
<font color='#EFFF3E'>[+]</font> <b>3 New Modifiers:</b> Resource Drought, Aggressive Attrition, and Unstable added to the Prestige pool.

Use codes <b><font color='#FF55FF'>12KFAVS</font></b> and <b><font color='#FF55FF'>COMBATREWORK</font></b> for free rewards!]],

	[[<b><font color='#FFD700'>v2.5 - Collection Update (April 10th)</font></b>

<font color='#D745FF'>[+]</font> <b>Ability Index:</b> Located in the Inventory Tab, you can now track every Stand and Style you've ever obtained! Abilities are permanently recorded once obtained, even if traded or lost. Organized by Parts, with a separate section for limited abilities.
<font color='#D745FF'>[+]</font> <b>Part Completion Bonuses:</b> Collecting every ability in a specific Part will permanently unlock global stat boosts (e.g., +Inventory Space, +XP Gain, +Global Damage).
<font color='#D745FF'>[+]</font> <b>Fusion Tracking:</b> The Index now tracks all Fused Stands you've created! Completing all possible fusions for a Stand grants it a permanent +0.5x Damage Multiplier.
<font color='#D745FF'>[+]</font> <b>Titles System:</b> Show off your achievements! Earn titles by completing the Index, surviving Endless Mode, winning raids, or progressing through the game. Titles are displayed next to your name in chat, and can be equipped/changed in the inventory.
<font color='#55FFFF'>[*]</font> <b>Sell All:</b> Added a Sell All option for equipment, consumables, and stands!
<font color='#55FFFF'>[*]</font> <b>Auto Rolling:</b> While auto-rolling for traits/stands, Legendary or higher rolls are now automatically saved to an unused storage slot instead of being overwritten
<font color='#55FFFF'>[*]</font> <b>Raids:</b> Closing/disbanding your party during a raid will no longer break the UI or prevent starting another raid 
<font color='#55FFFF'>[*]</font> <b>Sell All:</b> Event queue issues have been fixed - players will now correctly join/leave queues and rejoin without desync
<font color='#55FFFF'>[*]</font> <b>Gang QoL:</b> Gang members are now sorted by Prestige and Power, Gang leaderboards now display the Boss of each gang when hovered, Gang donations now properly contribute to personal rep/contribution
<font color='#55FF55'>[*]</font> <b>Fixes:</b> Fixed the "Gambling Addict" trait self-killing when confused
<font color='#55FF55'>[*]</font> <b>Fixes:</b> Re-enabled the Equip button for locked items]],

	[[<b><font color='#FFD700'>v2.4 - Endless Overhaul (April 6th)</font></b>

<font color='#D745FF'>[+]</font> <b>Endless Overhaul:</b> Endless Dungeons now feature all fighting styles, an increased name pool, and dangerous fused stands!
<font color='#D745FF'>[+]</font> <b>Scaling Loot:</b> Endless Floor rewards now scale every 100 floors (e.g., 100+ grants +2 Rokakaka/Arrows) and include Corpse Parts.
<font color='#D745FF'>[+]</font> <b>Massive Gains:</b> Dungeon XP and Yen gain has been massively boosted across the board!
<font color='#D745FF'>[+]</font> <b>Daily Milestones:</b> Claim powerful rewards once every 24 hours (Resets Midnight UTC):
    • Floor 50: Legendary Giftbox
    • Floor 100: Mythical Giftbox
    • Floor 1000: Unique Giftbox
<font color='#EFFF3E'>[+]</font> <b>New Rarity [Special]:</b> Gamepasses, Giftboxes, and Easter Eggs now fall under this rarity and cannot be sold.
<font color='#55FF55'>[*]</font> <b>Security & QoL:</b> Locked items hide use buttons to prevent accidents, and items no longer need to be unlocked to trade.
<font color='#55FFFF'>[*]</font> <b>Technical:</b> More robust Gang data storage, synchronized global timers, and fixed offline boss cooldown resets.
<font color='#55FF55'>[+]</font> <b>Balance:</b> Nerfed Global Donation goal to 10k and increased Easter Egg drop rates.]],

	[[<b><font color='#FFD700'>v2.3 - Easter Event Update (April 4th)</font></b>

<font color='#55FF55'>[+]</font> <b>Easter Event:</b> Obtain Easter Eggs by defeating enemies (5% drop from normal mobs, 40% from bosses)!
<font color='#55FF55'>[+]</font> <b>Easter Shop:</b> Spend your collected Eggs in the new rotating event shop.
<font color='#55FF55'>[+]</font> <b>Global Donations:</b> Contribute Eggs to a global pool across all servers. Everyone gets rewarded when the goal is met!
<font color='#55FF55'>[+]</font> <b>New Limited Stand:</b> Charmy Green
<font color='#55FF55'>[+]</font> <b>New Limited Style:</b> Baoh Armed Phenomenon
<font color='#55FF55'>[+]</font> <b>New World Boss:</b> Easter Bunny, that provides players with large amounts of eggs!
<font color='#55FF55'>[+]</font> <b>New Gear:</b> Added 2 New Weapons and 2 New Accessories.
<font color='#55FFFF'>[*]</font> <b>Boss Icons:</b> World Bosses now feature profile icons during combat!]],

	[[<b><font color='#FFD700'>v2.2 - April Fools Update (April 1st)</font></b>

<font color='#55FF55'>[+]</font> <b>New Bosses:</b> 3 NEW World Bosses with LIMITED TIME Drops!
<font color='#55FF55'>[+]</font> <b>New Stand:</b> Chiikawa
<font color='#55FF55'>[+]</font> <b>New Styles:</b> 2 New Fighting Styles: Shrine & Limitless
<font color='#55FF55'>[+]</font> <b>New Gear:</b> 3 New Weapons & 3 New Accessories
<font color='#55FF55'>[+]</font> <b>New Trait:</b> Gambling Addict]],

	[[<b><font color='#FFD700'>v2.1 - JoJolion Update PART 2 (March 22nd)</font></b>

<font color='#55FF55'>[+]</font> <b>Stand Fusion:</b> Fuse two Stands from your storage to create a hybrid Stand!
<font color='#55FF55'>[+]</font> <b>New Rokakaka:</b> A new item that opens up the Stand Fusion menu.
<font color='#55FF55'>[+]</font> <b>Hybrid Abilities & Names:</b> Fused Stands take the first half of their name and abilities from Stand 1, and the second half from Stand 2. Order matters!
<font color='#55FFFF'>[*]</font> <b>Bug Fixes:</b> Fixed mobile UI scrolling issues, Gang order tracking, and Gang renaming.]],

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