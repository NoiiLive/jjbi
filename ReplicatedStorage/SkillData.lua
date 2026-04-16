-- @ScriptType: ModuleScript
local SkillData = {}

SkillData.Skills = {
	["Basic Attack"] = { Requirement = "None", Type = "Basic", Mult = 1.0, StaminaCost = 0, EnergyCost = 0, Order = 1, Description = "A standard strike. Regenerates 5 Stamina and 5 Energy." },
	["Heavy Strike"] = { Requirement = "None", Type = "Basic", Mult = 1.4, StaminaCost = 5, EnergyCost = 0, Order = 2, Description = "A powerful, stamina-consuming physical attack." },
	["Block"] = { Requirement = "None", Type = "Basic", Mult = 0, StaminaCost = 5, EnergyCost = 0, Effect = "Block", Cooldown = 3, Order = 3, Description = "Reduces incoming damage by 50% for the next 2 turns." },
	["Rest"] = { Requirement = "None", Type = "Basic", Mult = 0, StaminaCost = 0, EnergyCost = 0, Effect = "CleanseRest", Cooldown = 3, Order = 4, Description = "Catch your breath to wipe away all negative status conditionsand recover 50 Stamina & Energy." },
	["Flee"] = { Requirement = "None", Type = "Basic", Mult = 0, StaminaCost = 0, EnergyCost = 0, Effect = "Flee", Order = 5, Description = "Escape from the current battle." },

	-- Style Skills
	["Haymaker"] = { Requirement = "Boxing", Type = "Style", Mult = 1.6, StaminaCost = 6, EnergyCost = 0, Order = 6, Description = "A devastating boxing punch." },
	["Liver Blow"] = { Requirement = "Boxing", Type = "Style", Mult = 1.3, StaminaCost = 8, EnergyCost = 0, Effect = "Stun", Duration = 2, Cooldown = 4, Order = 7, Description = "A precise hook that stuns the enemy for 2 turns." },
	["Footwork"] = { Requirement = "Boxing", Type = "Style", Mult = 0, StaminaCost = 5, EnergyCost = 0, Effect = "Buff_Speed", Duration = 3, Cooldown = 5, Order = 8, Description = "Increases evasion and Speed for 3 turns." },

	["Zoom Punch"] = { Requirement = "Hamon", Type = "Style", Mult = 1.5, StaminaCost = 5, EnergyCost = 0, Order = 6, Description = "Dislocates the arm to strike from a distance." },
	["Sunlight Yellow Overdrive"] = { Requirement = "Hamon", Type = "Style", Mult = 0.7, Hits = 3, StaminaCost = 10, EnergyCost = 0, Effect = "Burn", Duration = 2, Cooldown = 3, Order = 7, Description = "A massive burst of Hamon energy that burns the enemy." },
	["Deep Breathing"] = { Requirement = "Hamon", Type = "Style", Mult = 0, StaminaCost = 0, EnergyCost = 0, Effect = "Heal", HealPercent = 0.20, Cooldown = 5, Order = 8, Description = "Uses Hamon to rapidly regenerate 25% of Max HP." },

	["Blood Drain"] = { Requirement = "Vampirism", Type = "Style", Mult = 1.4, StaminaCost = 6, EnergyCost = 0, Effect = "Lifesteal", Order = 6, Description = "Drains the enemy's blood, healing for 50% of damage dealt." },
	["Space Ripper Stingy Eyes"] = { Requirement = "Vampirism", Type = "Style", Mult = 2.0, StaminaCost = 8, EnergyCost = 0, Effect = "Bleed", Duration = 2, Cooldown = 4, Order = 7, Description = "Fires high-pressure fluid, causing bleeding." },
	["Vaporization Freezing"] = { Requirement = "Vampirism", Type = "Style", Mult = 1.2, StaminaCost = 8, EnergyCost = 0, Effect = "Freeze", Duration = 1, Cooldown = 5, Order = 8, Description = "Freezes the moisture in the enemy's body on contact." },

	["Chest Machine Gun"] = { Requirement = "Cyborg", Type = "Style", Mult = 0.5, Hits = 3, StaminaCost = 6, EnergyCost = 0, Order = 6, Description = "Unleashes German engineering upon the enemy." },
	["UV Laser Eye"] = { Requirement = "Cyborg", Type = "Style", Mult = 2.1, StaminaCost = 8, EnergyCost = 0, Effect = "Burn", Duration = 3, Cooldown = 4, Order = 7, Description = "Scorches the enemy, inflicting Burn damage for 3 turns." },
	["German Engineering"] = { Requirement = "Cyborg", Type = "Style", Mult = 0, StaminaCost = 6, EnergyCost = 0, Effect = "Buff_Defense", Duration = 3, Cooldown = 5, Order = 8, Description = "Activates internal shielding to greatly increase Defense." },

	["Flesh Assimilation"] = { Requirement = "Pillarman", Type = "Style", Mult = 1.6, StaminaCost = 8, EnergyCost = 0, Effect = "Lifesteal", Order = 6, Description = "Absorbs the enemy's flesh, healing for 50% of damage dealt." },
	["Horn Drill"] = { Requirement = "Pillarman", Type = "Style", Mult = 2.2, StaminaCost = 8, EnergyCost = 0, Effect = "Bleed", Duration = 3, Cooldown = 4, Order = 7 , Description = "Grows and spins a horn to pierce the enemy, causing Bleed." },
	["Body Contortion"] = { Requirement = "Pillarman", Type = "Style", Mult = 0, StaminaCost = 5, EnergyCost = 0, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 8, Description = "Dislocates and hardens bones, vastly increasing Defense." },

	["Trusty Steel Pipe"] = { Requirement = "Man of Steel", Type = "Style", Mult = 2.0, StaminaCost = 8, EnergyCost = 0, Effect = "Lifesteal", Order = 6, Description = "Your trusty steel pipe, it turns pain into power." },
	["Iron Will"] = { Requirement = "Man of Steel", Type = "Style", Mult = 0.5, StaminaCost = 8, EnergyCost = 0, Effect = "Buff_Willpower", Duration = 3, Cooldown = 4, Order = 7, Description = "Enforce your will, prove you are the strongest." },
	["Unbreakable"] = { Requirement = "Man of Steel", Type = "Style", Mult = 0.5, StaminaCost = 5, EnergyCost = 0, Effect = "Heal", HealPercent = 0.5, Cooldown = 5, Order = 8, Description = "You are unbreakable, nothing can stop you." },

	["Light Slip Blades"] = { Requirement = "Ultimate Lifeform", Type = "Style", Mult = 2.2, StaminaCost = 8, EnergyCost = 0, Order = 6, Description = "Slashes the enemy with brilliant, light-reflecting bone blades." },
	["Melting Overdrive"] = { Requirement = "Ultimate Lifeform", Type = "Style", Mult = 2.9, StaminaCost = 12, EnergyCost = 0, Effect = "Burn", Duration = 4, Cooldown = 7, Order = 7, Description = "Unleashes Hamon hundreds of times stronger than a human's, instantly melting the target." },
	["Apex Adaptation"] = { Requirement = "Ultimate Lifeform", Type = "Style", Mult = 0, StaminaCost = 10, EnergyCost = 0, Effect = "Buff_Random", Duration = 4, Cooldown = 6, Order = 8, Description = "Rearranges your cellular structure to adapt." },
	["Instant Reformation"] = { Requirement = "Ultimate Lifeform", Type = "Style", Mult = 0, StaminaCost = 10, EnergyCost = 0, Effect = "Heal", HealPercent = 0.35, Cooldown = 6, Order = 9, Description = "Instantly reforms any damaged body parts, healing 35% of Max HP" },

	["Steel Ball Throw"] = { Requirement = "Spin", Type = "Style", Mult = 1.6, StaminaCost = 6, EnergyCost = 0, Order = 6, Description = "Throws a steel ball infused with rotational energy." },
	["Wrecking Ball"] = { Requirement = "Spin", Type = "Style", Mult = 1.3, StaminaCost = 8, EnergyCost = 0, Effect = "Confusion", Duration = 2, Cooldown = 6, Order = 7, Description = "Strikes the enemy's nerves with a spinning steel ball, confusing them for 2 turns." },
	["Ratio Visualization"] = { Requirement = "Spin", Type = "Style", Mult = 0, StaminaCost = 6, EnergyCost = 0, Effect = "Buff_Strength", Duration = 3, Cooldown = 7, Order = 8, Description = "Visualize the spin, increasing your energy output." },

	["Golden Ratio"] = { Requirement = "Golden Spin", Type = "Style", Mult = 2.2, StaminaCost = 8, EnergyCost = 0, Order = 6, Description = "Throws a steel ball imbued with the infinite golden rotation." },
	["Ball Breaker"] = { Requirement = "Golden Spin", Type = "Style", Mult = 2.8, StaminaCost = 12, EnergyCost = 0, Effect = "Debuff_Defense", Duration = 4, Cooldown = 5, Order = 7, Description = "Manifests Ball Breaker to rapidly age the target, completely shredding their Defense." },
	["Horseback Spin"] = { Requirement = "Golden Spin", Type = "Style", Mult = 0, StaminaCost = 10, EnergyCost = 0, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 8, Description = "Uses the horse's power to perfectly align with the golden ratio, massively boosting Speed." },
	["Hemispatial Neglect"] = { Requirement = "Golden Spin", Type = "Style", Mult = 2.3, StaminaCost = 8, EnergyCost = 0, Effect = "Confusion", Duration = 2, Cooldown = 7, Order = 9, Description = "Strikes the enemy's nerves with a spinning steel ball, confusing them for 2 turns." },

	["Silicon Strike"] = { Requirement = "Rock Human", Type = "Style", Mult = 2.3, StaminaCost = 8, EnergyCost = 0, Cooldown = 0, Order = 6, Description = "A dense, heavy strike using your silicon-based biology." },
	["Rock Armor"] = { Requirement = "Rock Human", Type = "Style", Mult = 0, StaminaCost = 12, EnergyCost = 0, Effect = "Buff_Defense", Duration = 4, Cooldown = 6, Order = 7, Description = "Hardens your skin into impenetrable rock, massively boosting Defense." },
	["Parasitic Shedding"] = { Requirement = "Rock Human", Type = "Style", Mult = 2.6, StaminaCost = 15, EnergyCost = 0, Effect = "Poison", Duration = 3, Cooldown = 5, Order = 8, Description = "Sheds toxic, rock-like scales that burrow into the enemy, causing Poison." },
	["Hibernation"] = { Requirement = "Rock Human", Type = "Style", Mult = 0, StaminaCost = 10, EnergyCost = 0, Effect = "Heal", HealPercent = 0.35, Cooldown = 8, Order = 9, Description = "Enters a brief state of rock hibernation, instantly restoring 35% of Max HP." },

	-- April Fools
	["Lapse: Blue"] = { Requirement = "Limitless", Type = "Style", Mult = 2.5, StaminaCost = 10, EnergyCost = 0, Order = 6, Description = "Creates a magnetic center of gravity, pulling the target and slowing them." },
	["Reversal: Red"] = { Requirement = "Limitless", Type = "Style", Mult = 3.5, StaminaCost = 15, EnergyCost = 0, Cooldown = 3, Order = 7, Description = "Unleashes a powerful repelling force that shatters the enemy's guard." },
	["Hollow Purple"] = { Requirement = "Limitless", Type = "Style", Mult = 4.0, StaminaCost = 35, EnergyCost = 0, Effect = "Bleed", Duration = 5, Cooldown = 7, Order = 8, Description = "Collides Blue and Red to create an imaginary mass that erases everything in its path." },
	["Unlimited Void"] = { Requirement = "Limitless", Type = "Style", Mult = 0, StaminaCost = 20, EnergyCost = 0, Effect = "Stun", Duration = 3, Cooldown = 10, Order = 9, Description = "Floods the mind of your enemy with infinite, endless knowledge, stunning them." },

	["Dismantle"] = { Requirement = "Shrine", Type = "Style", Mult = 2.5, StaminaCost = 10, EnergyCost = 0, Order = 6, Description = "A default slashing attack that easily slices mundane objects." },
	["Cleave"] = { Requirement = "Shrine", Type = "Style", Mult = 2.5, StaminaCost = 15, EnergyCost = 0, Effect = "Bleed", Duration = 2, Cooldown = 4, Order = 7, Description = "A slash that adjusts itself to the target's toughness to cut them down, causing Bleed" },
	["Divine Flame"] = { Requirement = "Shrine", Type = "Style", Mult = 3.0, StaminaCost = 25, EnergyCost = 0, Effect = "Burn", Duration = 3, Cooldown = 5, Order = 8, Description = "Opens the black box to unleash a devastating arrow of pure fire." },
	["Malevolent Shrine"] = { Requirement = "Shrine", Type = "Style", Mult = 0.6, Hits = 5, StaminaCost = 30, EnergyCost = 0, Effect = "Bleed", Duration = 5, Cooldown = 10, Order = 9, Description = "Expands your domain, relentlessly painting the area with endless slashes." },

	-- Easter
	["Reskiniharden Saber"] = { Requirement = "Baoh Armed Phenomenon", Type = "Style", Mult = 2.8, StaminaCost = 10, EnergyCost = 0, Effect = "Bleed", Duration = 2, Cooldown = 6, Order = 6, Description = "Hardens skin into wrist blades, violently slashing and causing Bleed." },
	["Meltedin Palm"] = { Requirement = "Baoh Armed Phenomenon", Type = "Style", Mult = 2.4, StaminaCost = 8, EnergyCost = 0, Effect = "Poison", Duration = 2, Cooldown = 6, Order = 7, Description = "Secretes corrosive enzymes from your palms, poisoning the enemy." },
	["Shooting-Bees Stinger"] = { Requirement = "Baoh Armed Phenomenon", Type = "Style", Mult = 2.5, StaminaCost = 15, EnergyCost = 0, Effect = "Burn", Duration = 2, Cooldown = 6, Order = 8, Description = "Shoots out hardened hair, instantly combusting upon contact, burning the enemy." },
	["Break Dark Thunder"] = { Requirement = "Baoh Armed Phenomenon", Type = "Style", Mult = 2.7, StaminaCost = 12, EnergyCost = 0, Effect = "Stun", Duration = 2, Cooldown = 6, Order = 9, Description = "Discharges high-voltage bio-electricity, stunning the enemy." },

	-- Stand Skills
	["Stand Barrage"] = { Requirement = "AnyStand", Type = "Stand", Mult = 0.4, Hits = 3, StaminaCost = 0, EnergyCost = 10, Cooldown = 3, Order = 10, Description = "A rapid flurry of 3 Stand punches." },

	["Spirit Photo"] = { Requirement = "Hermit Purple", Type = "Stand", Mult = 1.4, StaminaCost = 0, EnergyCost = 3, Order = 11, Description = "Uses the environment to strike with spirit vines." },
	["Vine Bind"] = { Requirement = "Hermit Purple", Type = "Stand", Mult = 1.3, StaminaCost = 0, EnergyCost = 6, Effect = "Stun", Duration = 2, Cooldown = 4, Order = 12, Description = "Whips and wraps the enemy, stunning them for 2 turns." },

	["Hook Strike"] = { Requirement = "Beach Boy", Type = "Stand", Mult = 1.5, StaminaCost = 0, EnergyCost = 3, Order = 11, Description = "Casts the hook straight into the enemy's flesh." },
	["Line Reel"] = { Requirement = "Beach Boy", Type = "Stand", Mult = 2.0, StaminaCost = 0, EnergyCost = 6, Effect = "Bleed", Duration = 3, Cooldown = 4, Order = 12, Description = "Rips the hook out forcefully, causing Bleed for 3 turns." },

	["Vola Vola Vola!"] = { Requirement = "Aerosmith", Type = "Stand", Mult = 0.5, Hits = 3, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "A barrage of high-speed machine gun fire." },
	["Bomb Drop"] = { Requirement = "Aerosmith", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 8, Effect = "Burn", Duration = 3, Cooldown = 4, Order = 12, Description = "Drops a volatile explosive, burning the enemy." },

	["Tower Needle"] = { Requirement = "Tower of Gray", Type = "Stand", Mult = 1.5, StaminaCost = 0, EnergyCost = 4, Order = 11, Description = "A piercing, high-speed strike." },
	["Massacre"] = { Requirement = "Tower of Gray", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 12, Description = "Zips around the room, drastically increasing Speed." },

	["Homing Bullet"] = { Requirement = "Emperor", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Fires a bullet that redirects toward the enemy." },
	["Quick Draw"] = { Requirement = "Emperor", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 6, Effect = "Buff_Speed", Duration = 3, Cooldown = 4, Order = 12, Description = "Increases your reaction time and Speed." },

	["Coin Toss"] = { Requirement = "Harvest", Type = "Stand", Mult = 1.4, StaminaCost = 0, EnergyCost = 3, Order = 11, Description = "Flings a collected coin at high speed." },
	["Swarm Attack"] = { Requirement = "Harvest", Type = "Stand", Mult = 0.5, Hits = 3, StaminaCost = 0, EnergyCost = 6, Effect = "Poison", Duration = 3, Cooldown = 4, Order = 12, Description = "Sends a swarm to sting the enemy, causing Poison damage." },

	["Rapier Thrust"] = { Requirement = "Soft Machine", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 4, Order = 11, Description = "A sharp stab with a rapier." },
	["Deflate"] = { Requirement = "Soft Machine", Type = "Stand", Mult = 1.8, StaminaCost = 0, EnergyCost = 8, Effect = "Debuff_Strength", Duration = 4, Cooldown = 5, Order = 12, Description = "Deflates the enemy, heavily reducing their Strength." },

	["Shrink Slash"] = { Requirement = "Little Feet", Type = "Stand", Mult = 1.5, StaminaCost = 0, EnergyCost = 4, Order = 11, Description = "A cutting strike that shrinks the impact zone." },
	["Size Alteration"] = { Requirement = "Little Feet", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 7, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 12, Description = "Shrinks yourself to avoid damage, increasing Defense." },

	["Rat Corpse"] = { Requirement = "Goo Goo Dolls", Type = "Stand", Mult = 1.5, StaminaCost = 0, EnergyCost = 4, Order = 11, Description = "Throws a diseased rat corpse." },
	["Shrink Command"] = { Requirement = "Goo Goo Dolls", Type = "Stand", Mult = 1.8, StaminaCost = 0, EnergyCost = 8, Effect = "Debuff_Defense", Duration = 4, Cooldown = 5, Order = 12, Description = "Forces the enemy into a smaller space, weakening their Defense." },

	["Ricochet Shot"] = { Requirement = "Manhattan Transfer", Type = "Stand", Mult = 1.7, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Bounces a sniper round perfectly into the target." },
	["Wind Reading"] = { Requirement = "Manhattan Transfer", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 12, Description = "Reads the air currents to massively boost Speed." },

	["Neural Shock"] = { Requirement = "Survivor", Type = "Stand", Mult = 1.5, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Sends a tiny electric current that hurts the nerves." },
	["Spark Fight"] = { Requirement = "Survivor", Type = "Stand", Mult = 1.8, StaminaCost = 0, EnergyCost = 8, Effect = "Confusion", Duration = 1, Cooldown = 5, Order = 12, Description = "Induces blind rage, Confusing the target so they attack themselves." },

	["Emerald Splash"] = { Requirement = "Hierophant Green", Type = "Stand", Mult = 0.5, Hits = 3, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Fires a spread of concentrated energy emeralds." },
	["Tentacle Trap"] = { Requirement = "Hierophant Green", Type = "Stand", Mult = 2.0, StaminaCost = 0, EnergyCost = 8, Effect = "Stun", Duration = 2, Cooldown = 5, Order = 12, Description = "Lays a web that damages and stuns the enemy for 2 turns." },

	["Crossfire Hurricane"] = { Requirement = "Magician's Red", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Fires an ankh-shaped flame." },
	["Red Bind"] = { Requirement = "Magician's Red", Type = "Stand", Mult = 2.1, StaminaCost = 0, EnergyCost = 8, Effect = "Burn", Duration = 3, Cooldown = 4, Order = 12, Description = "Binds the enemy in ropes of fire, Burning them." },

	["Sound Generation"] = { Requirement = "Echoes Act 1", Type = "Stand", Mult = 1.4, StaminaCost = 0, EnergyCost = 4, Order = 11, Description = "Writes a heavy sound into the target." },
	["Echoes Scout"] = { Requirement = "Echoes Act 1", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 6, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 12, Description = "Flies ahead to scout, boosting your dodge chance." },

	["Voodoo Doll"] = { Requirement = "Ebony Devil", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Strikes from under the bed with a razor blade." },
	["Malice"] = { Requirement = "Ebony Devil", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Strength", Duration = 4, Cooldown = 5, Order = 12, Description = "Converts damage taken into pure hatred, boosting Strength." },

	["Flesh Bud"] = { Requirement = "Lovers", Type = "Stand", Mult = 1.5, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "A micro-strike directed at the brain stem." },
	["Brain Spores"] = { Requirement = "Lovers", Type = "Stand", Mult = 2.0, StaminaCost = 0, EnergyCost = 8, Effect = "Confusion", Duration = 1, Cooldown = 5, Order = 12, Description = "Releases spores that confuse the target's neural pathways." },

	["Internal Tear"] = { Requirement = "Aqua Necklace", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Enters the enemy's body and strikes from within." },
	["Steam Sneak"] = { Requirement = "Aqua Necklace", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 6, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 12, Description = "Evaporates into steam, vastly increasing Defense." },

	["Paper Gun"] = { Requirement = "Enigma", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Unfolds a loaded gun and fires it." },
	["Paper Trap"] = { Requirement = "Enigma", Type = "Stand", Mult = 1.9, StaminaCost = 0, EnergyCost = 7, Effect = "Stun", Duration = 1, Cooldown = 4, Order = 12, Description = "Folds the enemy into paper, stunning them briefly." },

	["Mirror Shards"] = { Requirement = "Man in the Mirror", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Throws a barrage of shattered mirror glass." },
	["Mirror Pull"] = { Requirement = "Man in the Mirror", Type = "Stand", Mult = 2.1, StaminaCost = 0, EnergyCost = 8, Effect = "Stun", Duration = 2, Cooldown = 5, Order = 12, Description = "Pulls half the enemy's body into the mirror, stunning them." },

	["Centrifuge Strike"] = { Requirement = "Jumping Jack Flash", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Spins at high speeds and launches debris." },
	["Zero Gravity"] = { Requirement = "Jumping Jack Flash", Type = "Stand", Mult = 2.0, StaminaCost = 0, EnergyCost = 8, Effect = "Confusion", Duration = 1, Cooldown = 5, Order = 12, Description = "Removes gravity, Confusing the enemy's spatial awareness." },

	["Invisible Bite"] = { Requirement = "Limp Bizkit", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "An invisible jaw bites the target." },
	["Zombie Swarm"] = { Requirement = "Limp Bizkit", Type = "Stand", Mult = 0.6, Hits = 3, StaminaCost = 0, EnergyCost = 8, Effect = "Bleed", Duration = 3, Cooldown = 4, Order = 12, Description = "A horde of invisible animals causes ongoing Bleed damage." },

	["Fated Calamity"] = { Requirement = "Tohth", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Causes a predicted, unavoidable accident to strike the enemy." },
	["Premonition"] = { Requirement = "Tohth", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 12, Description = "Reads the future to dodge incoming attacks, massively boosting Speed." },

	["Sand Strike"] = { Requirement = "The Fool", Type = "Stand", Mult = 1.7, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Slams into the target." },
	["Sand Dome"] = { Requirement = "The Fool", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 12, Description = "Surrounds the user in a hardened shell of sand, boosting Defense." },

	["Scorching Rays"] = { Requirement = "The Sun", Type = "Stand", Mult = 1.8, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Fires a concentrated beam of intense heat." },
	["Heatstroke"] = { Requirement = "The Sun", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Burn", Duration = 4, Cooldown = 5, Order = 12, Description = "Raises the ambient temperature, crippling the enemy." },

	["Dual Wield Strike"] = { Requirement = "Anubis", Type = "Stand", Mult = 1.2, Hits = 2, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A rapid, cross-slashing attack." },
	["Mind Control"] = { Requirement = "Anubis", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Strength", Duration = 4, Cooldown = 5, Order = 12, Description = "Allows the sword to completely take over, boosting Strength." },

	["Infantry Fire"] = { Requirement = "Bad Company", Type = "Stand", Mult = 0.2, Hits = 5, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Commands a miniature platoon to fire on the target." },
	["Tactical Formation"] = { Requirement = "Bad Company", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 12, Description = "Orders the troops to form a defensive perimeter, boosting Defense." },

	["Ricochet"] = { Requirement = "Six Pistols", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Kicks a bullet perfectly to hit a vital spot." },
	["Pass the Ammo"] = { Requirement = "Six Pistols", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 12, Description = "The Pistols coordinate flawlessly, vastly increasing Speed." },

	["Replay Strike"] = { Requirement = "Moody Blues", Type = "Stand", Mult = 1.8, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Replays a recorded punch with perfect accuracy." },
	["Fast Forward"] = { Requirement = "Moody Blues", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 12, Description = "Accelerates the replay speed, making you harder to hit." },

	["WANNABE!"] = { Requirement = "Spice Girl", Type = "Stand", Mult = 0.6, Hits = 3, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A fierce flurry of punches." },
	["Soften"] = { Requirement = "Spice Girl", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 9, Effect = "Debuff_Defense", Duration = 4, Cooldown = 5, Order = 12, Description = "Softens the target's armor, ruining their Defense." },

	["The Hook"] = { Requirement = "Marilyn Manson", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "Throws a hook to violently collect a debt." },
	["Debt Collection"] = { Requirement = "Marilyn Manson", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 9, Effect = "Debuff_Strength", Duration = 4, Cooldown = 5, Order = 12, Description = "Steals the enemy's internal organs, crippling their Strength." },

	["Internal Strike"] = { Requirement = "Diver Down", Type = "Stand", Mult = 1.8, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Phases into the enemy to strike them from the inside." },
	["Store Attack"] = { Requirement = "Diver Down", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Strength", Duration = 4, Cooldown = 5, Order = 12, Description = "Stores kinetic energy into an object, buffing your next strikes." },

	["Smack Sticker"] = { Requirement = "Kiss", Type = "Stand", Mult = 1.8, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A heavy, sticker-empowered punch." },
	["Remove Sticker"] = { Requirement = "Kiss", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Stun", Duration = 2, Cooldown = 5, Order = 12, Description = "Rips off a sticker causing violently merging clones, Stunning the target." },

	["Silver Rapier"] = { Requirement = "Silver Chariot", Type = "Stand", Mult = 1.7, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "A blindingly fast sword thrust." },
	["Armor Off"] = { Requirement = "Silver Chariot", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 12, Description = "Sheds armor to vastly increase Speed for 4 turns." },

	["ARI ARI ARI!"] = { Requirement = "Sticky Fingers", Type = "Stand", Mult = 1.7, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A rapid barrage of zipper-laced punches." },
	["Zipper Dash"] = { Requirement = "Sticky Fingers", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 12, Description = "Unzips the ground to glide at extreme Speed." },

	["Feral Strike"] = { Requirement = "Purple Haze", Type = "Stand", Mult = 1.8, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A frenzied, incredibly violent punch." },
	["Capsule Break"] = { Requirement = "Purple Haze", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 12, Effect = "Poison", Duration = 3, Cooldown = 5, Order = 12, Description = "Crushes a virus capsule, inflicting severe Poison." },

	["String Beatdown"] = { Requirement = "Stone Free", Type = "Stand", Mult = 1.7, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Unravels its body to unleash a flurry of blows." },
	["Mobius Strip"] = { Requirement = "Stone Free", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 12, Description = "Turns your body into an inverted plane, greatly increasing Defense." },

	["Void Strike"] = { Requirement = "Cream", Type = "Stand", Mult = 1.8, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "A sweeping strike empowered by a dimension of nothingness." },
	["Dimension Hide"] = { Requirement = "Cream", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 12, Description = "Hides inside its own void dimension, massively boosting Defense." },

	["Dream Scythe"] = { Requirement = "Death 13", Type = "Stand", Mult = 1.7, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A massive sweep with a grim reaper's scythe." },
	["Lali-Ho!"] = { Requirement = "Death 13", Type = "Stand", Mult = 2.3, StaminaCost = 0, EnergyCost = 9, Effect = "Stun", Duration = 2, Cooldown = 5, Order = 12, Description = "Puts the enemy to sleep in the dream world, stunning them." },

	["Water Slash"] = { Requirement = "Geb", Type = "Stand", Mult = 1.7, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A high-pressure slash made of desert water." },
	["Sand Sonar"] = { Requirement = "Geb", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 7, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 12, Description = "Senses vibrations through the ground, increasing Defense." },

	["Ice Spikes"] = { Requirement = "Horus", Type = "Stand", Mult = 1.7, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Fires massive stalactites of pure ice." },
	["Flash Freeze"] = { Requirement = "Horus", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 10, Effect = "Freeze", Duration = 2, Cooldown = 5, Order = 12, Description = "Freezes the air around the enemy, locking them in ice." },

	["Zap"] = { Requirement = "Red Hot Chili Pepper", Type = "Stand", Mult = 1.7, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Shocks the enemy with a fast burst of electricity." },
	["Electric Charge"] = { Requirement = "Red Hot Chili Pepper", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Buff_Speed", Duration = 4, Cooldown = 6, Order = 12, Description = "Absorbs electricity to vastly increase Speed." },

	["Aging Grasp"] = { Requirement = "The Grateful Dead", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A withering physical grab." },
	["Rapid Aging"] = { Requirement = "The Grateful Dead", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 9, Effect = "Debuff_Strength", Duration = 4, Cooldown = 5, Order = 12, Description = "Accelerates the enemy's aging, crippling their Strength." },

	["Cryokinesis"] = { Requirement = "White Album", Type = "Stand", Mult = 1.8, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "Freezes the absolute moisture in the air into a deadly strike." },
	["Gently Weeps"] = { Requirement = "White Album", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 12, Description = "Freezes the air into solid armor, heavily boosting Defense." },

	["Downward Dismemberment"] = { Requirement = "Green Day", Type = "Stand", Mult = 1.7, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A brutal physical attack targeting the lower body." },
	["Mold Spread"] = { Requirement = "Green Day", Type = "Stand", Mult = 2.3, StaminaCost = 0, EnergyCost = 9, Effect = "Poison", Duration = 3, Cooldown = 5, Order = 12, Description = "Infects the target with flesh-eating mold." },

	["Meteor Strike"] = { Requirement = "Planet Waves", Type = "Stand", Mult = 1.7, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A single flaming meteor strike." },
	["Meteor Barrage"] = { Requirement = "Planet Waves", Type = "Stand", Mult = 0.7, Hits = 3, StaminaCost = 0, EnergyCost = 10, Effect = "Burn", Duration = 3, Cooldown = 4, Order = 12, Description = "Pulls 3 meteors from orbit down onto the enemy." },

	["Iron Bar Strike"] = { Requirement = "Jail House Lock", Type = "Stand", Mult = 1.6, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "A physical attack using the prison surroundings." },
	["Three Memories"] = { Requirement = "Jail House Lock", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Confusion", Duration = 2, Cooldown = 7, Order = 12, Description = "Forces the enemy to forget their goal, stunning them for 3 turns." },

	["ORA!"] = { Requirement = "Star Platinum", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "An overwhelming strike of incredible power." },
	["Star Finger"] = { Requirement = "Star Platinum", Type = "Stand", Mult = 2.6, StaminaCost = 0, EnergyCost = 10, Effect = "Bleed", Duration = 2, Cooldown = 4, Order = 12, Description = "A piercing strike that causes intense bleeding." },
	["Deep Breath"] = { Requirement = "Star Platinum", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Buff_Random", Duration = 4, Cooldown = 5, Order = 13, Description = "Inhales deeply, gaining a random Stat Buff." },

	["ORA ORA ORA!"] = { Requirement = "Star Platinum: The World", Type = "Stand", Mult = 0.8, Hits = 3, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "The ultimate barrage of strength." },
	["Bearing Shot"] = { Requirement = "Star Platinum: The World", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 12, Effect = "Bleed", Duration = 3, Cooldown = 4, Order = 12, Description = "A high speed projectile that causes extreme bleeding." },
	["Time Stop"] = { Requirement = "Star Platinum: The World", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 15, Effect = "TimeStop", Duration = 2, Cooldown = 6, Order = 13, Description = "Stops time, completely freezing the enemy in place." },

	["MUDA MUDA MUDA!"] = { Requirement = "The World", Type = "Stand", Mult = 0.8, Hits = 3, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "A merciless barrage of golden punches." },
	["Road Roller"] = { Requirement = "The World", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 12, Effect = "Bleed", Duration = 2, Cooldown = 4, Order = 12, Description = "Drops a massive steamroller, causing crushing Bleed damage." },
	["ZA WARUDO!"] = { Requirement = "The World", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 15, Effect = "TimeStop", Duration = 2, Cooldown = 6, Order = 13, Description = "Stops time, completely freezing the enemy in place." },

	["Primary Bomb"] = { Requirement = "Killer Queen", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "Turns the enemy into a bomb and detonates them." },
	["Sheer Heart Attack"] = { Requirement = "Killer Queen", Type = "Stand", Mult = 2.7, StaminaCost = 0, EnergyCost = 10, Effect = "Burn", Duration = 3, Cooldown = 4, Order = 12, Description = "Deploys an autonomous tracking bomb that severely burns the target." },
	["Bomb Plant"] = { Requirement = "Killer Queen", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Debuff_Defense", Duration = 4, Cooldown = 5, Order = 13, Description = "Plants a secondary charge to shatter enemy Defense." },

	["Donut Punch"] = { Requirement = "King Crimson", Type = "Stand", Mult = 2.9, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "A devastating punch straight through the enemy's torso." },

	["Time Erasure"] = { Requirement = "King Crimson", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 15, Effect = "TimeErase", Duration = 2, Cooldown = 6, Order = 12, Description = "Erases time, stunning the enemy and boosting Speed." },
	["Epitaph"] = { Requirement = "King Crimson", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Counter", Cooldown = 6, Order = 13, Description = "Predicts the absolute future of an incoming attack, rendering it useless, and counter-attacking instantly." },

	["DORA DORA DORA!"] = { Requirement = "Crazy Diamond", Type = "Stand", Mult = 0.7, Hits = 3, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "A rapid barrage of high-strength punches." },
	["Blood Bullet"] = { Requirement = "Crazy Diamond", Type = "Stand", Mult = 2.7, StaminaCost = 0, EnergyCost = 10, Effect = "Bleed", Duration = 3, Cooldown = 4, Order = 12, Description = "Fires a hardened shard of glass tracking your dried blood." },
	["Restoration"] = { Requirement = "Crazy Diamond", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 12, Effect = "Heal", HealPercent = 0.3, Cooldown = 6, Order = 13, Description = "Fixes injuries, instantly recovering 30% of Max HP." },

	["MUDA!"] = { Requirement = "Gold Experience", Type = "Stand", Mult = 2.3, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "A fast and precise punch." },
	["Sensory Overload"] = { Requirement = "Gold Experience", Type = "Stand", Mult = 2.6, StaminaCost = 0, EnergyCost = 11, Effect = "Confusion", Duration = 2, Cooldown = 5, Order = 12, Description = "Overloads the target's consciousness, Confusing them." },
	["Life Giver"] = { Requirement = "Gold Experience", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 12, Effect = "Heal", HealPercent = 0.3, Cooldown = 5, Order = 13, Description = "Transforms objects into body parts, healing 30% Max HP." },

	["Melt Your Heart"] = { Requirement = "Whitesnake", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Strikes with a highly corrosive acid." },
	["Gun Illusion"] = { Requirement = "Whitesnake", Type = "Stand", Mult = 2.7, StaminaCost = 0, EnergyCost = 10, Effect = "Confusion", Duration = 2, Cooldown = 5, Order = 12, Description = "Traps the enemy in an illusion, Confusing them." },
	["Disc Extraction"] = { Requirement = "Whitesnake", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 12, Effect = "Debuff_Random", Duration = 4, Cooldown = 6, Order = 13, Description = "Steals the enemy's spirit disc, applying a random Debuff." },

	["Surface Inversion"] = { Requirement = "C-Moon", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "Inverts the target's physical body from the inside out." },
	["Gravity Shift"] = { Requirement = "C-Moon", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 12, Effect = "Confusion", Duration = 1, Cooldown = 5, Order = 12, Description = "Shifts the center of gravity, Confusing the target's attacks." },
	["Gravity Repulsion"] = { Requirement = "C-Moon", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 13, Description = "Repels all incoming attacks, massively increasing Defense." },

	["Tail Strike"] = { Requirement = "Echoes Act 2", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A fast physical strike with its tail." },
	["SIZZLE!"] = { Requirement = "Echoes Act 2", Type = "Stand", Mult = 2.5, StaminaCost = 0, EnergyCost = 9, Effect = "Burn", Duration = 3, Cooldown = 4, Order = 12, Description = "Places a burning sound effect on the target." },
	["WHOOSH!"] = { Requirement = "Echoes Act 2", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 13, Description = "Applies a wind sound effect to vastly boost Speed." },

	["C-R-A-P"] = { Requirement = "Echoes Act 3", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "A heavy, concentrated strike." },
	["3 FREEZE"] = { Requirement = "Echoes Act 3", Type = "Stand", Mult = 1.5, StaminaCost = 0, EnergyCost = 12, Effect = "Stun", Duration = 3, Cooldown = 6, Order = 12, Description = "Increases gravity on the target, pinning and Stunning them for 3 turns." },
	["Heavy Gravity"] = { Requirement = "Echoes Act 3", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Debuff_Speed", Duration = 4, Cooldown = 5, Order = 13, Description = "Locks down the enemy's legs, heavily reducing their Speed." },

	["Weather Control"] = { Requirement = "Weather Report", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "Summons a crushing storm of heavy rain." },
	["Torrential Downpour"] = { Requirement = "Weather Report", Type = "Stand", Mult = 2.7, StaminaCost = 0, EnergyCost = 12, Effect = "Poison", Duration = 3, Cooldown = 6, Order = 12, Description = "Rains poisonous dart frogs over the battlefield." },
	["Heavy Weather"] = { Requirement = "Weather Report", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 15, Effect = "Confusion", Duration = 2, Cooldown = 5, Order = 13, Description = "Projects rainbows that convince the target they are a snail, forgetting their purpose." },

	["Page Peel"] = { Requirement = "Heaven's Door", Type = "Stand", Mult = 2.7, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "Slashes with a pen, peeling open the enemy's skin like a book." },
	["Written Calamity"] = { Requirement = "Heaven's Door", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 10, Effect = "Status_Random", Duration = 1, Cooldown = 5, Order = 12, Description = "Writes a disastrous, unpredictable fate into the target's pages." },
	["Character Flaw"] = { Requirement = "Heaven's Door", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 12, Effect = "Debuff_Random", Duration = 2, Cooldown = 6, Order = 13, Description = "Rewrites the enemy's fundamental traits, randomly crippling one of their stats." },

	["Camouflaged Strike"] = { Requirement = "Metallica", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Bends light around iron particles to become invisible and striking secretely." },
	["Iron Manipulation"] = { Requirement = "Metallica", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 8, Effect = "Bleed", Duration = 5, Cooldown = 7, Order = 12, Description = "Forces iron inside the enemy's blood to form sharp objects." },
	["Hemoglobin Exhaustion"] = { Requirement = "Metallica", Type = "Stand", Mult = 0.5, StaminaCost = 0, EnergyCost = 12, Effect = "Debuff_Defense", Duration = 4, Cooldown = 6, Order = 13, Description = "Depletes the iron from the enemy's blood, causing them to become weakened" },

	["Erasure Barrage"] = { Requirement = "The Hand", Type = "Stand", Mult = 0.9, Hits = 3, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Quickly erases the space in front of you wildy." },
	["Space Erasure"] = { Requirement = "The Hand", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 10, Effect = "Bleed", Duration = 3, Cooldown = 5, Order = 12, Description = "Swipes the air, completely erasing anything in its path." },
	["Erasure Pull"] = { Requirement = "The Hand", Type = "Stand", Mult = 1.0, StaminaCost = 0, EnergyCost = 15, Effect = "Stun", Duration = 2, Cooldown = 7, Order = 13, Description = "A terrifying vertical swipe that erases the ground and space beneath the enemy, leaving them disoriented." },

	["Shattering Fist"] = { Requirement = "Steel Platinum", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "Devastate those foes who doubted your power." },
	["Defense Breaker"] = { Requirement = "Steel Platinum", Type = "Stand", Mult = 1.0,  Hits = 3, StaminaCost = 0, EnergyCost = 12, Effect = "Debuff_Defense", Duration = 3, Cooldown = 4, Order = 12, Description = "Destroy the defense of those who oppose you." },
	["Iron Jail"] = { Requirement = "Steel Platinum", Type = "Stand", Mult = 1.0, StaminaCost = 0, EnergyCost = 15, Effect = "Stun", Duration = 3, Cooldown = 6, Order = 13, Description = "Lock the weak-willed behind bars of steel." },

	["MUDA MUDA MUDA! (High Voltage)"] = { Requirement = "The World: High Voltage", Type = "Stand", Mult = 0.8, Hits = 3, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "A ruthless barrage of punches from the alternate universe." },
	["Checkmate"] = { Requirement = "The World: High Voltage", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 12, Effect = "Bleed", Duration = 2, Cooldown = 6, Order = 12, Description = "Throws a flurry of knives in stopped time, causing severe Bleeding." },
	["Gasoline Ignition"] = { Requirement = "The World: High Voltage", Type = "Stand", Mult = 2.5, StaminaCost = 0, EnergyCost = 10, Effect = "Burn", Duration = 2, Cooldown = 6, Order = 13, Description = "Douses the enemy in gasoline and throws a match, inflicting heavy Burn damage." },
	["ZA WARUDO! (High Voltage)"] = { Requirement = "The World: High Voltage", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 15, Effect = "TimeStop", Duration = 2, Cooldown = 6, Order = 14, Description = "Stops time completely, freezing the enemy in place to set up a lethal trap." },

	["Primary Bomb (BTD)"] = { Requirement = "Killer Queen BTD", Type = "Stand", Mult = 2.5, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "Turns the enemy into a bomb and detonates them." },
	["Sheer Heart Attack (BTD)"] = { Requirement = "Killer Queen BTD", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 12, Effect = "Burn", Duration = 3, Cooldown = 5, Order = 12, Description = "Deploys an explosive tank that causes severe Burns." },
	["Air Bomb"] = { Requirement = "Killer Queen BTD", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 14, Effect = "Debuff_Defense", Duration = 4, Cooldown = 5, Order = 13, Description = "Fires an invisible explosive air bubble that shatters the enemy's Defense." },
	["Bites the Dust"] = { Requirement = "Killer Queen BTD", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 20, Effect = "TimeRewind", Cooldown = 10, Order = 14, Description = "Rewinds time, restoring 50% of lost health and clearing ailments." },

	["Speed Slice"] = { Requirement = "Made in Heaven", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "A high-speed strike that is nearly impossible to track." },
	["Accelerated Knives"] = { Requirement = "Made in Heaven", Type = "Stand", Mult = 0.9, Hits = 3, StaminaCost = 0, EnergyCost = 12, Effect = "Bleed", Duration = 3, Cooldown = 4, Order = 12, Description = "Throws a spread of knives at terminal velocity, causing Bleed." },
	["Time Acceleration"] = { Requirement = "Made in Heaven", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 15, Effect = "Buff_Speed", Duration = 5, Cooldown = 8, Order = 13, Description = "Accelerates time, vastly increasing Speed for 5 turns." },
	["Universe Reset"] = { Requirement = "Made in Heaven", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 12, Effect = "TimeReset", Cooldown = 10, Order = 14, Description = "Resets the universe, restores 25% of lost HP, and confuses the enemy for 2 turns." },

	["Apex Vitality"] = { Requirement = "Gold Experience Requiem", Type = "Stand", Mult = 1.2, Hits = 3, StaminaCost = 0, EnergyCost = 10, Effect = "Status_Random", Duration = 3, Cooldown = 5, Order = 11, Description = "Fires a life-infused stone that transforms into random animals upon impact." },
	["Truth Unveiled"] = { Requirement = "Gold Experience Requiem", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 15, Effect = "Buff_Strength", Duration = 5, Cooldown = 6, Order = 12, Description = "Basks in the ultimate truth, massively increasing your Strength." },
	["Return to Zero"] = { Requirement = "Gold Experience Requiem", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "ReturnToZero", Duration = 3, Cooldown = 20, Order = 13, Description = "Resets the enemy's actions to zero, where they cannot reach the truth." },
	["Infinite Retribution"] = { Requirement = "Gold Experience Requiem", Type = "Stand", Mult = 3.2, StaminaCost = 0, EnergyCost = 25, Effect = "Confusion", Duration = 3, Cooldown = 7, Order = 14, Description = "The ultimate Requiem strike. Traps the enemy in an inescapable cycle of death and confusion that scales infinitely." },

	["Soul Transposition"] = { Requirement = "Chariot Requiem", Type = "Stand", Mult = 3.2, StaminaCost = 0, EnergyCost = 10, Effect = "Stun", Duration = 3, Cooldown = 5, Order = 11, Description = "Swaps the spiritual frequencies of those nearby, causing them to fall asleep temporarily." },
	["Stand Refraction"] = { Requirement = "Chariot Requiem", Type = "Stand", Mult = 1.5, StaminaCost = 0, EnergyCost = 15, Effect = "Confusion", Duration = 3, Cooldown = 6, Order = 12, Description = "Forces the enemy's own Stand power to reflect back upon them." },
	["Requiem Walk"] = { Requirement = "Chariot Requiem", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 16, Effect = "Buff_Defense", Duration = 5, Cooldown = 7, Order = 13, Description = "Walks inexorably forward, shrouded in a soul-thickening aura that vastly boosts Defense." },
	["Life Alteration"] = { Requirement = "Chariot Requiem", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 20, Effect = "Debuff_Random", Duration = 5, Cooldown = 8, Order = 14, Description = "The inevitable march of the Requiem, altering all life into something else entirely." },

	["Raging Demon"] = { Requirement = "King Crimson Requiem", Type = "Stand", Mult = 0.6, Hits = 5, StaminaCost = 0, EnergyCost = 12, Order = 11, Description = "Unleash a flurry of rage and anger, obliterating the enemies that stand before you." },
	["Dimensional Slash"] = { Requirement = "King Crimson Requiem", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 16, Effect = "Bleed", Duration = 4, Cooldown = 6, Order = 12, Description = "Cleave reality with your strike, causing severe, inescapable Bleeding." },
	["True Epitaph"] = { Requirement = "King Crimson Requiem", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 22, Effect = "Debuff_Defense", Duration = 3, Cooldown = 6, Order = 13, Description = "See the fated outcome of your victory, and reposition at your enemies weakest point." },
	["Reality Marble"] = { Requirement = "King Crimson Requiem", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 30, Effect = "TimeErase", Duration = 3, Cooldown = 10, Order = 14, Description = "Completely obliterates the concept of time for all except yourself, freezing the enemy and wiping their actions." },

	["Overwrite Reality"] = { Requirement = "The World: Over Heaven", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 15, Order = 11, Description = "Punches the target, completely overwriting their physical reality to deal immense damage." },
	["Heavenly Smite"] = { Requirement = "The World: Over Heaven", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 20, Effect = "Bleed", Duration = 3, Cooldown = 8, Order = 12, Description = "Calls down a devastating strike of holy lightning, completely Stunning the target." },
	["Rewrite Existence"] = { Requirement = "The World: Over Heaven", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Heal", HealPercent = 0.40, Cooldown = 10, Order = 13, Description = "Overwrites your own injuries, instantly restoring 40% of your Max HP." },
	["ZA WARUDO! (Over Heaven)"] = { Requirement = "The World: Over Heaven", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 30, Effect = "TimeStop", Duration = 3, Cooldown = 10, Order = 14, Description = "Stops time on a universal scale, completely freezing the enemy." },

	["Reality Barrage"] = { Requirement = "Star Platinum: Over Heaven", Type = "Stand", Mult = 1.0, Hits = 3, StaminaCost = 0, EnergyCost = 15, Order = 11, Description = "An overwhelming punch that defies the laws of the universe." },
	["Reality Piercing Strike"] = { Requirement = "Star Platinum: Over Heaven", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 20, Effect = "Bleed", Duration = 4, Cooldown = 8, Order = 12, Description = "Shatters the enemy's body, causing them to bleed out." },
	["Rewrite Truth"] = { Requirement = "Star Platinum: Over Heaven", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Debuff_Defense", Duration = 5, Cooldown = 7, Order = 13, Description = "Rewrites the truth to enforce your absolute victory, shattering their defense." },
	["Time Stop (Over Heaven)"] = { Requirement = "Star Platinum: Over Heaven", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 30, Effect = "TimeStop", Duration = 3, Cooldown = 10, Order = 14, Description = "Stops time on a universal scale, completely freezing the enemy." },

	["Assassination Shot"] = { Requirement = "TATOO YOU!", Type = "Stand", Mult = 1.9, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "A calculated shot from a hidden angle." },
	["Eleven Men Swarm"] = { Requirement = "TATOO YOU!", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 8, Effect = "Bleed", Duration = 3, Cooldown = 5, Order = 12, Description = "Assassins emerge from your back to ambush the target, causing Bleed." },
	["Hide in the Canvas"] = { Requirement = "TATOO YOU!", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 7, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 13, Description = "Retreats into the tattoo dimension, drastically increasing Speed." },

	["Nail Strike"] = { Requirement = "Tubular Bells", Type = "Stand", Mult = 1.9, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "A harsh physical strike using metal tools." },
	["Balloon Animal"] = { Requirement = "Tubular Bells", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 8, Effect = "Bleed", Duration = 3, Cooldown = 5, Order = 12, Description = "Inflates a metal balloon that explodes upon contact." },
	["Metal Phasing"] = { Requirement = "Tubular Bells", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 7, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 13, Description = "Slips through narrow gaps to take cover, boosting Defense." },

	["Accidental Trip"] = { Requirement = "Hey Ya!", Type = "Stand", Mult = 1.9, StaminaCost = 0, EnergyCost = 5, Order = 11, Description = "You trip over a rock, somehow dealing damage to the enemy." },
	["Perfect Advice"] = { Requirement = "Hey Ya!", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 7, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 12, Description = "Hey Ya! whispers exactly where to step, vastly increasing Speed." },
	["Flawless Luck"] = { Requirement = "Hey Ya!", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Random", Duration = 4, Cooldown = 6, Order = 13, Description = "Everything falls perfectly into place." },

	["Flesh Spray"] = { Requirement = "Cream Starter", Type = "Stand", Mult = 2.0, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Sprays a high-pressure beam of pressurized flesh." },
	["Melting Foam"] = { Requirement = "Cream Starter", Type = "Stand", Mult = 2.5, StaminaCost = 0, EnergyCost = 9, Effect = "Burn", Duration = 3, Cooldown = 4, Order = 12, Description = "Sprays an acidic flesh-foam that burns the target." },
	["Flesh Healing"] = { Requirement = "Cream Starter", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Heal", HealPercent = 0.30, Cooldown = 6, Order = 13, Description = "Patches wounds with flesh spray, restoring 30% Max HP." },

	["Sound Construct"] = { Requirement = "In a Silent Way", Type = "Stand", Mult = 2.0, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Materializes a solid word to strike the enemy." },
	["Destructive Slash"] = { Requirement = "In a Silent Way", Type = "Stand", Mult = 2.6, StaminaCost = 0, EnergyCost = 9, Effect = "Bleed", Duration = 3, Cooldown = 6, Order = 12, Description = "Sends a razor-sharp slicing sound effect that causes Bleeding." },
	["Sound Camouflage"] = { Requirement = "In a Silent Way", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 8, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 13, Description = "Hides within a silent space to avoid attacks, increasing Speed." },

	["Grounded Strike"] = { Requirement = "20th Century Boy", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "A heavy strike utilizing the momentum of the ground." },
	["Energy Redirection"] = { Requirement = "20th Century Boy", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 10, Effect = "Stun", Duration = 2, Cooldown = 5, Order = 12, Description = "Redirects impact energy into the earth, stunning the opponent." },
	["Absolute Defense"] = { Requirement = "20th Century Boy", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 12, Effect = "Buff_Defense", Duration = 4, Cooldown = 6, Order = 13, Description = "Kneels to the ground, becoming nearly indestructible and vastly raising Defense." },

	["Raindrop Blade"] = { Requirement = "Catch the Rainbow", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "Solidifies raindrops into sharp projectiles." },
	["Storm Slicer"] = { Requirement = "Catch the Rainbow", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 10, Effect = "Bleed", Duration = 3, Cooldown = 5, Order = 12, Description = "Locks raindrops mid-air to slice the target to ribbons." },
	["Walking on Water"] = { Requirement = "Catch the Rainbow", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 9, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 13, Description = "Steps effortlessly on the falling rain, greatly boosting Speed." },

	["Guilt Manifestation"] = { Requirement = "Civil War", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "Attacks using the discarded remnants of the past." },
	["Burden of Sins"] = { Requirement = "Civil War", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 10, Effect = "Confusion", Duration = 2, Cooldown = 6, Order = 12, Description = "Overwhelms the enemy with their past sins, causing severe Confusion." },
	["Materialized Memories"] = { Requirement = "Civil War", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 9, Effect = "Debuff_Strength", Duration = 4, Cooldown = 6, Order = 13, Description = "Crushes the opponent under the weight of their own guilt, lowering Strength." },

	["Tear Blade"] = { Requirement = "Ticket to Ride", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 6, Effect = "Bleed", Duration = 3, Cooldown = 4, Order = 11, Description = "Hardens tears into a sharp blade to slash the opponent, causing Bleed." },
	["Divine Protection"] = { Requirement = "Ticket to Ride", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Buff_Defense", Duration = 4, Cooldown = 6, Order = 12, Description = "The Saint's Corpse naturally repels misfortune, vastly increasing your Defense." },
	["Misfortune Deflection"] = { Requirement = "Ticket to Ride", Type = "Stand", Mult = 2.0, StaminaCost = 0, EnergyCost = 12, Effect = "Confusion", Duration = 2, Cooldown = 5, Order = 13, Description = "Redirects a fatal blow into a chain of unfortunate events for the target, Confusing them." },

	["Magnetic Pull"] = { Requirement = "Tomb of the Boom", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 8, Effect = "Debuff_Speed", Duration = 3, Cooldown = 4, Order = 11, Description = "Magnetizes the enemy, heavily reducing their Speed by pulling them to the ground." },
	["Iron Sand Rip"] = { Requirement = "Tomb of the Boom", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 12, Effect = "Bleed", Duration = 4, Cooldown = 5, Order = 12, Description = "Forces iron particles to violently rip through the enemy's skin from the inside out." },
	["Magnetic Repulsion"] = { Requirement = "Tomb of the Boom", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Buff_Defense", Duration = 4, Cooldown = 6, Order = 13, Description = "Uses magnetic forces to repel metallic attacks, heavily boosting your Defense." },

	["Dimensional Hook"] = { Requirement = "Wired", Type = "Stand", Mult = 2.6, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "Drops a massive, heavy hook from the sky through a puddle." },
	["Reel In"] = { Requirement = "Wired", Type = "Stand", Mult = 2.0, StaminaCost = 0, EnergyCost = 12, Effect = "Stun", Duration = 2, Cooldown = 5, Order = 12, Description = "Snags the enemy and brutally reels them into the air, Stunning them." },
	["Stealth Drop"] = { Requirement = "Wired", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 9, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 13, Description = "Hides your presence using the water reflection, increasing Speed and evasion." },

	["Pin Detonation"] = { Requirement = "Boku no Rhythm wo Kiitekure", Type = "Stand", Mult = 2.5, StaminaCost = 0, EnergyCost = 8, Effect = "Burn", Duration = 2, Cooldown = 4, Order = 11, Description = "Throws objects rigged with explosive pins, causing Burn damage." },
	["Clockwork Trap"] = { Requirement = "Boku no Rhythm wo Kiitekure", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 12, Effect = "Debuff_Defense", Duration = 3, Cooldown = 5, Order = 12, Description = "Plants a delayed bomb that shatters the enemy's armor on detonation." },
	["Listen to My Rhythm"] = { Requirement = "Boku no Rhythm wo Kiitekure", Type = "Stand", Mult = 1.5, StaminaCost = 0, EnergyCost = 14, Effect = "Stun", Duration = 2, Cooldown = 6, Order = 13, Description = "Covers the area in bombs, stunning the target with a deafening blast." },

	["Coordinate Drop"] = { Requirement = "Chocolate Disco", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "Teleports a dangerous projectile directly to the target's grid coordinate." },
	["Grid Trap"] = { Requirement = "Chocolate Disco", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 10, Effect = "Confusion", Duration = 2, Cooldown = 5, Order = 12, Description = "Disorients the enemy by constantly teleporting objects around them." },
	["Absolute Positioning"] = { Requirement = "Chocolate Disco", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 13, Description = "Manipulates the grid to instantly reposition yourself, drastically boosting Speed." },

	["Golden Exchange"] = { Requirement = "Sugar Mountain", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 8, Effect = "Lifesteal", Order = 11, Description = "Forces an unfair trade, stealing health from the enemy to heal yourself." },
	["Burden of Wealth"] = { Requirement = "Sugar Mountain", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 12, Effect = "Debuff_Speed", Duration = 4, Cooldown = 5, Order = 12, Description = "Overwhelms the enemy with material possessions, crippling their Speed." },
	["Wood Transformation"] = { Requirement = "Sugar Mountain", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 15, Effect = "Stun", Duration = 2, Cooldown = 6, Order = 13, Description = "The curse of the spring begins to turn the enemy into a tree, Stunning them." },

	["Rope Lasso"] = { Requirement = "Oh! Lonesome Me", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 6, Order = 11, Description = "Whips the target with a hardened rope." },
	["Body Separation"] = { Requirement = "Oh! Lonesome Me", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Buff_Defense", Duration = 4, Cooldown = 5, Order = 12, Description = "Splits your body along a rope to completely avoid fatal damage, boosting Defense." },
	["Constricting Tie"] = { Requirement = "Oh! Lonesome Me", Type = "Stand", Mult = 1.8, StaminaCost = 0, EnergyCost = 12, Effect = "Stun", Duration = 2, Cooldown = 5, Order = 13, Description = "Binds the enemy tightly in a lasso, preventing movement for 2 turns." },

	["Pistol Quickdraw"] = { Requirement = "Mandom", Type = "Stand", Mult = 2.6, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "A perfectly executed shot in a duel." },
	["True Man's World"] = { Requirement = "Mandom", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 12, Effect = "Stun", Duration = 2, Cooldown = 5, Order = 12, Description = "Enforces the rules of a fair duel, stunning those who try to cheat." },
	["Six Seconds Rewind"] = { Requirement = "Mandom", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 15, Effect = "Heal", HealPercent = 0.40, Cooldown = 8, Order = 13, Description = "Turns the watch back 6 seconds, restoring 40% of Max HP." },
	["Disorienting Time"] = { Requirement = "Mandom", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Debuff_Defense", Duration = 4, Cooldown = 6, Order = 14, Description = "Rewinds time slightly to expose the target's weak points, shredding their Defense." },

	["Dimensional Strike"] = { Requirement = "Dirty Deeds Done Dirt Cheap", Type = "Stand", Mult = 2.7, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "A crushing chop backed by dimensional force." },
	["Sponge Paradox"] = { Requirement = "Dirty Deeds Done Dirt Cheap", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 13, Effect = "Bleed", Duration = 4, Cooldown = 6, Order = 12, Description = "Merges the enemy with a parallel version of themselves, causing violent Bleeding." },
	["Parallel Replacement"] = { Requirement = "Dirty Deeds Done Dirt Cheap", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 16, Effect = "Heal", HealPercent = 0.4, Cooldown = 10, Order = 13, Description = "Swaps places with a healthy alternate universe self, healing 40% Max HP." },
	["Between Dimensions"] = { Requirement = "Dirty Deeds Done Dirt Cheap", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 12, Effect = "Buff_Defense", Duration = 4, Cooldown = 6, Order = 14, Description = "Hides between two objects, vastly increasing Defense against attacks." },

	["Raptor Claw"] = { Requirement = "Scary Monsters", Type = "Stand", Mult = 2.6, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "A vicious slash from dinosaur claws." },
	["Dinosaur Virus"] = { Requirement = "Scary Monsters", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 12, Effect = "Poison", Duration = 4, Cooldown = 6, Order = 12, Description = "Bites the target to infect them with the dinosaur virus, causing heavy Poison." },
	["Fossilization"] = { Requirement = "Scary Monsters", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Buff_Defense", Duration = 4, Cooldown = 6, Order = 13, Description = "Hardens your dinosaur scales into a fossilized armor, boosting Defense." },
	["Predator's Agility"] = { Requirement = "Scary Monsters", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 14, Description = "Taps into primal instincts to drastically increase Speed." },

	["Nail Bullet"] = { Requirement = "Tusk Act 1", Type = "Stand", Mult = 2.5, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "Fires a rapidly spinning fingernail." },
	["Spinning Nail"] = { Requirement = "Tusk Act 1", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 11, Effect = "Bleed", Duration = 3, Cooldown = 5, Order = 12, Description = "Fires a sharp nail that burrows into the target, causing Bleed." },
	["Golden Rectangle"] = { Requirement = "Tusk Act 1", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 10, Effect = "Buff_Strength", Duration = 4, Cooldown = 6, Order = 13, Description = "Visualizes the golden ratio, greatly enhancing your Strength." },

	["Golden Nail"] = { Requirement = "Tusk Act 2", Type = "Stand", Mult = 2.7, StaminaCost = 0, EnergyCost = 10, Order = 11, Description = "Fires a heavily empowered fingernail bullet." },
	["Tracking Hole"] = { Requirement = "Tusk Act 2", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 14, Effect = "Stun", Duration = 2, Cooldown = 5, Order = 12, Description = "The bullet hole chases the target and strikes vital points, Stunning them." },
	["Aureal Rotation"] = { Requirement = "Tusk Act 2", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 12, Effect = "Buff_Strength", Duration = 4, Cooldown = 5, Order = 13, Description = "Masters the spin, massively increasing Strength." },
	["Moving Bullet"] = { Requirement = "Tusk Act 2", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 12, Effect = "Debuff_Defense", Duration = 4, Cooldown = 6, Order = 14, Description = "The nail burrows through armor, lowering the enemy's Defense." },

	["Spatial Nail"] = { Requirement = "Tusk Act 3", Type = "Stand", Mult = 2.9, StaminaCost = 0, EnergyCost = 12, Order = 11, Description = "A masterfully spun bullet that ignores distance." },
	["Infinite Spin"] = { Requirement = "Tusk Act 3", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 16, Effect = "Bleed", Duration = 4, Cooldown = 7, Order = 12, Description = "Fires a bullet carrying infinite rotational energy, causing massive Bleeding." },
	["Wormhole Evasion"] = { Requirement = "Tusk Act 3", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 14, Effect = "Buff_Speed", Duration = 4, Cooldown = 5, Order = 13, Description = "Shoots yourself into the bullet hole to hide, heavily boosting Speed." },
	["Spatial Shot"] = { Requirement = "Tusk Act 3", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 15, Effect = "Confusion", Duration = 2, Cooldown = 8, Order = 14, Description = "Fires from a completely impossible angle, Confusing the target." },

	["Infinite Rotation"] = { Requirement = "Tusk Act 4", Type = "Stand", Mult = 1.0, Hits = 3, StaminaCost = 0, EnergyCost = 14, Order = 11, Description = "A punch carrying the perfect golden spin." },
	["Golden Spin"] = { Requirement = "Tusk Act 4", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 18, Effect = "Stun", Duration = 2, Cooldown = 7, Order = 12, Description = "Injects infinite rotation into the enemy, stunning them entirely." },
	["Absolute Energy"] = { Requirement = "Tusk Act 4", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 15, Effect = "Buff_Strength", Duration = 5, Cooldown = 6, Order = 13, Description = "Harnesses the complete power of the horse's energy, maximizing Strength." },
	["Cellular Destruction"] = { Requirement = "Tusk Act 4", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 16, Effect = "Poison", Duration = 4, Cooldown = 8, Order = 14, Description = "The spin forces the enemy's cells to rotate and tear apart, causing severe Poison." },

	["Light Strike"] = { Requirement = "D4C Love Train", Type = "Stand", Mult = 2.9, StaminaCost = 0, EnergyCost = 14, Order = 11, Description = "A devastating chop imbued with the holy light." },
	["Misfortune Redirection"] = { Requirement = "D4C Love Train", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 18, Effect = "Burn", Duration = 4, Cooldown = 8, Order = 12, Description = "Pushes bad luck into the target, causing them to spontaneously ignite." },
	["Wall of Light"] = { Requirement = "D4C Love Train", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 16, Effect = "Buff_Defense", Duration = 5, Cooldown = 6, Order = 13, Description = "Hides behind the gap in space, becoming almost entirely immune to damage." },
	["Dimensional Clone"] = { Requirement = "D4C Love Train", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 20, Effect = "Heal", HealPercent = 0.50, Cooldown = 10, Order = 14, Description = "Transfers consciousness to a fresh clone, instantly healing 50% Max HP." },

	["Peel"] = { Requirement = "Canine Style", Type = "Stand", Mult = 1.1, Hits = 2, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "Peels off your skin like an apple to strike the enemy." },
	["Wire Trap"] = { Requirement = "Canine Style", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Stun", Duration = 1, Cooldown = 4, Order = 12, Description = "Sets a wire trap made of your own skin, stunning the target." },
	["Sling"] = { Requirement = "Canine Style", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 20, Cooldown = 3, Order = 13, Description = "Slingshots yourself using your peeled limbs for a heavy strike." },

	["Above You"] = { Requirement = "Fun Fun Fun", Type = "Stand", Mult = 2.1, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A calculated strike from directly above the target." },
	["Mark"] = { Requirement = "Fun Fun Fun", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 20, Effect = "Debuff_Defense", Duration = 3, Cooldown = 5, Order = 12, Description = "Marks the enemy's limbs, breaking down their defensive stance." },
	["Puppeteer"] = { Requirement = "Fun Fun Fun", Type = "Stand", Mult = 2.0, StaminaCost = 0, EnergyCost = 30, Effect = "Confusion", Duration = 2, Cooldown = 5, Order = 13, Description = "Takes control of the marked limbs, forcing the enemy to attack themselves." },

	["Sneak Attack"] = { Requirement = "California King Bed", Type = "Stand", Mult = 1.9, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A sly, underhanded physical attack." },
	["Memory Theft"] = { Requirement = "California King Bed", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 20, Effect = "Debuff_Strength", Duration = 3, Cooldown = 5, Order = 12, Description = "Steals a crucial memory of how to fight, lowering their Strength." },
	["Rule Enforcement"] = { Requirement = "California King Bed", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 30, Effect = "Stun", Duration = 1, Cooldown = 4, Order = 13, Description = "Punishes the enemy for breaking a rule, stunning them." },

	["Origami Strike"] = { Requirement = "Paper Moon King", Type = "Stand", Mult = 2.0, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "Slashes the enemy with an impossibly sharp folded paper." },
	["Sensory Illusion"] = { Requirement = "Paper Moon King", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Confusion", Duration = 2, Cooldown = 5, Order = 12, Description = "Alters the target's facial recognition, deeply confusing them." },
	["Swarm"] = { Requirement = "Paper Moon King", Type = "Stand", Mult = 0.8, Hits = 3, StaminaCost = 0, EnergyCost = 20, Cooldown = 4, Order = 13, Description = "Sends a swarm of origami frogs to bite the target." },

	["Card Conceal"] = { Requirement = "Space Trucking", Type = "Stand", Mult = 2.1, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "Slices the enemy with a rigid playing card." },
	["Store Away"] = { Requirement = "Space Trucking", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Buff_Defense", Duration = 3, Cooldown = 5, Order = 12, Description = "Hides yourself between playing cards, increasing Defense." },
	["Eject Object"] = { Requirement = "Space Trucking", Type = "Stand", Mult = 2.6, StaminaCost = 0, EnergyCost = 20, Cooldown = 4, Order = 13, Description = "Violently ejects a stored heavy object into the target." },

	["Cash Bash"] = { Requirement = "Milagro Man", Type = "Stand", Mult = 2.3, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A heavy strike fueled by a cursed wad of cash." },
	["Overwhelming Wealth"] = { Requirement = "Milagro Man", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Debuff_Speed", Duration = 3, Cooldown = 5, Order = 12, Description = "Burdens the enemy with infinitely multiplying money, lowering their Speed." },
	["Crushing Debt"] = { Requirement = "Milagro Man", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 30, Cooldown = 5, Order = 13, Description = "Crushes the opponent under the physical weight of the curse." },

	["Jigsaw Strike"] = { Requirement = "King Nothing", Type = "Stand", Mult = 2.1, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A fast strike from a puzzle-piece fist." },
	["Scent Tracking"] = { Requirement = "King Nothing", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 20, Effect = "Buff_Speed", Duration = 3, Cooldown = 5, Order = 12, Description = "Tracks the enemy's scent perfectly, increasing your Speed and evasion." },
	["Dismantling"] = { Requirement = "King Nothing", Type = "Stand", Mult = 1.3, Hits = 2, StaminaCost = 0, EnergyCost = 25, Cooldown = 4, Order = 13, Description = "Breaks into puzzle pieces to surround and strike the target twice." },

	["Heel Spike"] = { Requirement = "Walking Heart", Type = "Stand", Mult = 2.3, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A brutal kick using hardened heel spikes." },
	["Wall Walk"] = { Requirement = "Walking Heart", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 20, Effect = "Buff_Speed", Duration = 3, Cooldown = 5, Order = 12, Description = "Uses the spikes to traverse walls, greatly boosting Speed." },
	["Impale"] = { Requirement = "Walking Heart", Type = "Stand", Mult = 2.7, StaminaCost = 0, EnergyCost = 30, Effect = "Bleed", Duration = 3, Cooldown = 5, Order = 13, Description = "Deeply impales the target's foot, causing severe Bleeding." },

	["Hair Whip"] = { Requirement = "Love Love Deluxe", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "Whips the enemy with extended strands of hair." },
	["Tangle"] = { Requirement = "Love Love Deluxe", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Stun", Duration = 1, Cooldown = 4, Order = 12, Description = "Grows hair over the enemy's body, stunning them in place." },
	["Strangle"] = { Requirement = "Love Love Deluxe", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 25, Cooldown = 4, Order = 13, Description = "Constricts the overgrown hair for heavy damage." },

	["Tornado Strike"] = { Requirement = "Doobie Wah!", Type = "Stand", Mult = 1.2, Hits = 2, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A rapid double-strike using miniature tornadoes." },
	["Breath Tracking"] = { Requirement = "Doobie Wah!", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Debuff_Defense", Duration = 3, Cooldown = 5, Order = 12, Description = "The tornado hunts their breath, tearing away their defensive armor." },
	["Suffocate"] = { Requirement = "Doobie Wah!", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 30, Effect = "Burn", Duration = 3, Cooldown = 5, Order = 13, Description = "Forces the tornado into their lungs, causing massive internal Burn damage." },

	["Toxin Touch"] = { Requirement = "Brain Storm", Type = "Stand", Mult = 2.1, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A light touch that begins the breakdown process." },
	["Cellular Breakdown"] = { Requirement = "Brain Storm", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Poison", Duration = 3, Cooldown = 5, Order = 12, Description = "Infects the enemy, causing their cells to pop like bubbles (Poison)." },
	["Melt"] = { Requirement = "Brain Storm", Type = "Stand", Mult = 1.3, Hits = 2, StaminaCost = 0, EnergyCost = 25, Cooldown = 4, Order = 13, Description = "Spreads the infection rapidly, dealing two waves of heavy damage." },

	["Zombie Strike"] = { Requirement = "Blue Hawaii", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A relentless, unfeeling physical attack from an infected host." },
	["Mind Controlling"] = { Requirement = "Blue Hawaii", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 30, Effect = "Confusion", Duration = 2, Cooldown = 5, Order = 12, Description = "Infects the target's blood, Confusing them into attacking themselves." },
	["Relentless Pursuit"] = { Requirement = "Blue Hawaii", Type = "Stand", Mult = 2.9, StaminaCost = 0, EnergyCost = 30, Cooldown = 5, Order = 13, Description = "Commands all infected hosts to pile onto the target at once." },

	["Direct Route"] = { Requirement = "Paisley Park", Type = "Stand", Mult = 2.3, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "Finds the exact path of least resistance to strike." },
	["Navigation"] = { Requirement = "Paisley Park", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 20, Effect = "Buff_Speed", Duration = 3, Cooldown = 5, Order = 12, Description = "Hacks the environment to map out enemy attacks, boosting Speed." },
	["Electronic Hack"] = { Requirement = "Paisley Park", Type = "Stand", Mult = 2.0, StaminaCost = 0, EnergyCost = 25, Effect = "Stun", Duration = 1, Cooldown = 4, Order = 13, Description = "Takes over a nearby electronic device to shock and Stun the target." },

	["Nut & Bolt Punch"] = { Requirement = "Nut King Call", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A solid punch that implants a nut and bolt into the enemy." },
	["Dismantle Limbs"] = { Requirement = "Nut King Call", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Debuff_Strength", Duration = 3, Cooldown = 5, Order = 12, Description = "Unscrews the bolts holding the enemy's arms together, crippling Strength." },
	["Screw Off"] = { Requirement = "Nut King Call", Type = "Stand", Mult = 2.9, StaminaCost = 0, EnergyCost = 30, Effect = "Bleed", Duration = 3, Cooldown = 5, Order = 13, Description = "Violently removes the nuts and bolts, causing severe Bleeding." },

	["Heat Strike"] = { Requirement = "Speed King", Type = "Stand", Mult = 2.5, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A fast strike that slightly raises the target's temperature." },
	["Boiling Point"] = { Requirement = "Speed King", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Burn", Duration = 3, Cooldown = 5, Order = 12, Description = "Accumulates extreme heat inside the target's blood, causing Burn." },
	["Combustion"] = { Requirement = "Speed King", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 30, Cooldown = 5, Order = 13, Description = "Instantly detonates all stored heat for massive damage." },

	["Gravity Pull"] = { Requirement = "I Am a Rock", Type = "Stand", Mult = 2.4, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A heavy strike utilizing the target's own gravity." },
	["Attract Objects"] = { Requirement = "I Am a Rock", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Debuff_Defense", Duration = 3, Cooldown = 5, Order = 12, Description = "Forces heavy debris to stick to the enemy, lowering their Defense." },
	["Spike Rain"] = { Requirement = "I Am a Rock", Type = "Stand", Mult = 0.9, Hits = 3, StaminaCost = 0, EnergyCost = 30, Cooldown = 4, Order = 13, Description = "Pulls a swarm of sharp rocks directly into the target's center of gravity." },

	["Soft Strike"] = { Requirement = "Vitamin C", Type = "Stand", Mult = 2.2, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A seemingly harmless punch that leaves a handprint." },
	["Liquefy"] = { Requirement = "Vitamin C", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Debuff_Defense", Duration = 3, Cooldown = 5, Order = 12, Description = "Softens the target's body into a liquid state, destroying their Defense." },
	["Melt Down"] = { Requirement = "Vitamin C", Type = "Stand", Mult = 2.8, StaminaCost = 0, EnergyCost = 30, Effect = "Poison", Duration = 3, Cooldown = 5, Order = 13, Description = "The target's liquefied form begins to break down, taking Poison damage." },

	["Pressure Push"] = { Requirement = "Ozon Baby", Type = "Stand", Mult = 2.5, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A blast of highly pressurized air." },
	["Depressurize"] = { Requirement = "Ozon Baby", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Debuff_Speed", Duration = 3, Cooldown = 5, Order = 12, Description = "Lowers the atmospheric pressure, making the target sluggish and slow." },
	["Crush"] = { Requirement = "Ozon Baby", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 30, Cooldown = 5, Order = 13, Description = "Instantly restores pressure to normal, crushing the target's internal organs." },

	["Bubble Strike"] = { Requirement = "Soft & Wet", Type = "Stand", Mult = 2.6, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A fast punch accompanied by a floating soap bubble." },
	["Plunder Vision"] = { Requirement = "Soft & Wet", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Stun", Duration = 1, Cooldown = 4, Order = 12, Description = "A bubble pops on the target's face, stealing their sight and Stunning them." },
	["Plunder Friction"] = { Requirement = "Soft & Wet", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Debuff_Speed", Duration = 3, Cooldown = 5, Order = 13, Description = "Steals the friction from the floor, causing the target to slip and lose Speed." },
	["Soap Bubble Barrage"] = { Requirement = "Soft & Wet", Type = "Stand", Mult = 0.9, Hits = 3, StaminaCost = 0, EnergyCost = 30, Cooldown = 4, Order = 14, Description = "A relentless barrage of physical punches and explosive bubbles." },

	["Hook Punch"] = { Requirement = "Killer Queen (Part 8)", Type = "Stand", Mult = 2.5, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A precise, methodical punch." },
	["Sheer Heart Attack (Part 8)"] = { Requirement = "Killer Queen (Part 8)", Type = "Stand", Mult = 1.0, Hits = 3, StaminaCost = 0, EnergyCost = 30, Effect = "Burn", Duration = 3, Cooldown = 5, Order = 12, Description = "Deploys multiple miniature explosive tanks that track the target, causing Burns." },
	["Bubble Bomb Trap"] = { Requirement = "Killer Queen (Part 8)", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Buff_Defense", Duration = 3, Cooldown = 6, Order = 13, Description = "Surrounds yourself in a defensive perimeter of explosive bubbles." },
	["Detonate"] = { Requirement = "Killer Queen (Part 8)", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 35, Effect = "Burn", Duration = 3, Cooldown = 6, Order = 14, Description = "Instantly detonates all active bubble bombs for massive burst damage." },

	["Frost Strike"] = { Requirement = "Born This Way", Type = "Stand", Mult = 2.7, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A heavy, freezing strike." },
	["Freezing Wind"] = { Requirement = "Born This Way", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 30, Effect = "Freeze", Duration = 1, Cooldown = 4, Order = 12, Description = "Unleashes a sub-zero wind that completely Freezes the target." },
	["Motorcycle Charge"] = { Requirement = "Born This Way", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 30, Cooldown = 5, Order = 13, Description = "Rams the target at full speed with a frozen motorcycle." },
	["Cold Front"] = { Requirement = "Born This Way", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Debuff_Speed", Duration = 3, Cooldown = 6, Order = 14, Description = "Drops the temperature drastically, slowing the target's Speed." },

	["Vector Punch"] = { Requirement = "Awaking III Leaves", Type = "Stand", Mult = 2.6, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A punch guided by perfectly aligned vectors." },
	["Vector Arrow"] = { Requirement = "Awaking III Leaves", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 25, Cooldown = 4, Order = 12, Description = "Places an arrow in space, redirecting massive force into the target." },
	["Repel"] = { Requirement = "Awaking III Leaves", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Buff_Defense", Duration = 3, Cooldown = 6, Order = 13, Description = "Creates a barrier of outward-facing vectors, increasing Defense." },
	["Vector Tornado"] = { Requirement = "Awaking III Leaves", Type = "Stand", Mult = 1.0, Hits = 3, StaminaCost = 0, EnergyCost = 35, Cooldown = 5, Order = 14, Description = "Combines multiple vectors into a destructive, multi-hit whirlwind." },

	["Spinning Bubble"] = { Requirement = "Soft & Wet: Go Beyond", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "Fires a bubble imbued with explosive rotational energy." },
	["Go Beyond Barrage"] = { Requirement = "Soft & Wet: Go Beyond", Type = "Stand", Mult = 1.0, Hits = 3, StaminaCost = 0, EnergyCost = 30, Cooldown = 5, Order = 12, Description = "A devastating barrage of logic-defying explosive bubbles." },
	["Explosive Spin"] = { Requirement = "Soft & Wet: Go Beyond", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 30, Effect = "Burn", Duration = 3, Cooldown = 6, Order = 13, Description = "Harness the power of your fused stand to create devastating explosions." },
	["Invisible Bubble"] = { Requirement = "Soft & Wet: Go Beyond", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 35, Effect = "Bleed", Duration = 3, Cooldown = 6, Order = 14, Description = "Fires an infinitely thin, spinning bubble that ignores logic, causing massive Bleed." },

	["Cane Strike"] = { Requirement = "Wonder of U", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 15, Cooldown = 0, Order = 11, Description = "A simple, yet impossibly painful strike with a cane." },
	["Flow of Calamity"] = { Requirement = "Wonder of U", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Debuff_Defense", Duration = 5, Cooldown = 6, Order = 12, Description = "Manipulates the logic of the world to make the target succeptible to attacks." },
	["Illusory Presence"] = { Requirement = "Wonder of U", Type = "Stand", Mult = 3.0, StaminaCost = 0, EnergyCost = 35, Effect = "Confusion", Duration = 3, Cooldown = 6, Order = 13, Description = "Appears in the corner of their eye, Confusing them completely." },
	["Rain of Debris"] = { Requirement = "Wonder of U", Type = "Stand", Mult = 0.6, Hits = 5, StaminaCost = 0, EnergyCost = 35, Effect = "Calamity", Duration = 3, Cooldown = 6, Order = 14, Description = "A calamity forces surrounding objects to violently crash into the target." },

	-- Boss Alternatives
	["Revert to Zero"] = { Requirement = "Boss", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 25, Effect = "Heal", HealPercent = 0.40, Duration = 3, Cooldown = 20, Order = 13, Description = "Resets the enemy's actions to zero, where they cannot reach the truth." },

	-- April Fools
	["Waaah!"] = { Requirement = "Chiikawa", Type = "Stand", Mult = 2.5, StaminaCost = 0, EnergyCost = 8, Order = 11, Description = "Tears up and wildly flails around." },
	["Usagi's Help"] = { Requirement = "Chiikawa", Type = "Stand", Mult = 3, StaminaCost = 0, EnergyCost = 20, Effect = "Status_Random", Duration = 3, Cooldown = 6, Order = 12, Description = "Usagi rushes in screaming, causing a completely random, chaotic effect." },	
	["Pajama Party"] = { Requirement = "Chiikawa", Type = "Stand", Mult = 0, StaminaCost = 0, EnergyCost = 15, Effect = "Heal", HealPercent = 0.5, Cooldown = 5, Order = 13, Description = "Puts on cute pajamas and dances, restoring 50% of your Max HP." },
	["Weed Whacker"] = { Requirement = "Chiikawa", Type = "Stand", Mult = 0.7, Hits = 5, StaminaCost = 0, EnergyCost = 15, Effect = "Bleed", Duration = 2, Cooldown = 4, Order = 14, Description = "Wildly swings a weed whacker, dealing multi-hit damage." },

	-- Easter
	["Urya Urya Rush"] = { Requirement = "Charmy Green", Type = "Stand", Mult = 0.7, Hits = 4, StaminaCost = 0, EnergyCost = 7, Order = 11, Description = "A ruthless, high-speed barrage of punches." },
	["Emerald Star Finger"] = { Requirement = "Charmy Green", Type = "Stand", Mult = 2.9, StaminaCost = 0, EnergyCost = 10, Effect = "Bleed", Duration = 2, Cooldown = 4, Order = 12, Description = "A concentrated piercing strike combining Star Platinum and Hierophant Green." },
	["Green Trap"] = { Requirement = "Charmy Green", Type = "Stand", Mult = 2.5, StaminaCost = 0, EnergyCost = 8, Effect = "Stun", Duration = 2, Cooldown = 5, Order = 12, Description = "Triggers a sudden emerald bind that strikes and immobilizes the enemy for 2 turns." },
}

return SkillData