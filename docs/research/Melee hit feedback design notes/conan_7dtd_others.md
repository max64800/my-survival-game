# Enemy Stun, Stagger, Stun-lock and Knockdown: Conan Exiles, 7 Days to Die, Others

Research date: 2026-11-21. Budget: about 15 tool calls. Items marked "(search snippet)" were seen only in search result summaries, not in a fetched page. Items marked "(community)" are player or forum claims, not official.

## 1. Conan Exiles: hyper armor, stagger, stun, concussive

### Takeaway
Conan Exiles treats "hyper armor" (a timed window in an attack animation where the attacker cannot be stunned) as the core anti-stun-lock tool. The June 2023 developer letter said heavy, slow weapons should hold most of it and fast weapons should be able to interrupt slow ones. The May 2026 forum reply shows that hyper armor was later cut back in some places, and that Funcom now wants "a bit more hyperarmor back."

### Cited Findings
- Developer letter (June 15, 2023, "Combat changes during the Age of War"): "Hyper Armor is a window of time during an animation in which a character cannot be stunned." — [Conan Exiles dev letter](https://www.conanexiles.com/?p=16687)
- Same letter: "Many of the attacks in Exiles are inundated with Hyper Armor"; plan was to "decrease the excess of Hyper Armor" in Chapter 2; "Hyper Armor is reserved for moments during an attack where extreme momentum is present." — [Conan Exiles dev letter](https://www.conanexiles.com/?p=16687)
- Same letter: "heavier weapons with slow animations and a lot of moving mass possessing most of the Hyper Armor"; "smaller faster weapons having less of it." — [Conan Exiles dev letter](https://www.conanexiles.com/?p=16687)
- Same letter (interrupts): "This will open the window to using fast weapons to interrupt slow weapons"; if the interrupt is missed, "the heavy weapon in motion will not be stoppable." — [Conan Exiles dev letter](https://www.conanexiles.com/?p=16687)
- Same letter (stun break removed): the "stun break" system was taken away; the old timing was roughly "For every 3 seconds of being stunned, you get 1 second to act with impunity." Enemies are now either stunnable or immune, and "only certain high difficulty enemies will be immune." — [Conan Exiles dev letter](https://www.conanexiles.com/?p=16687)
- Same letter (stamina): attacks cost much more stamina, and stamina regen was raised to offset it; "Without stamina you are vulnerable… it is effectively the enemies' turn." Stamina changes were Chapter 1; hyper armor changes were planned for Chapter 2. — [Conan Exiles dev letter](https://www.conanexiles.com/?p=16687)
- Post-"Conan Enhanced" update (released May 5, 2026): a forum reply dated May 8, 2026 says "Mace's have hyperarmor" and "enemies with maces do not get staggered." It admits "enemy staggering has at times been too easy to sustain" and "Some of this has been over-corrected," and says "Many players would like us to have a bit more hyperarmor back… We'll see how it goes over time." No specific change or patch number is given. The page does not label the poster as staff. — [Funcom forum thread](https://forums.funcom.com/t/combat-feedback-after-conan-enhanced-update-may-5th-enemy-stagger-hit-detection-combat-flow-issues/297723)
- Older hyper armor change (2019 TestLive): two-handed hammers got hyper armor on selected parts of their light-attack combos, meant to let attacks "go through uninterrupted." — [Funcom TestLive 01-03-2019 thread](https://forums.funcom.com/t/testlive-patch-01-03-2019-balancing-passes-exploits-and-bug-fixes/55715) (search snippet)
- Official patch note (undated in the search result): hyperarmor was changed to exist only for specific animations with visible high velocity or heavy motion, e.g. two-handed heavy attacks. — (search snippet) [Funcom forums search results](https://forums.funcom.com/t/heavy-armour-should-have-more-hyper-armour-than-light-armour/200265)
- Player claim: hyper armor depends on the weapon attack and the roll-recovery stat, which light armor raises; being naked gives the most. — (community) [Funcom forum](https://forums.funcom.com/t/heavy-armour-should-have-more-hyper-armour-than-light-armour/200265) (search snippet)

### Concussive damage (Conan's knockout "stun" system, not a stagger)
- Knockouts run on a separate **concussive** meter (blue bar) next to health. Concussive damage can exceed health damage, so an NPC can be knocked out before it dies. — [Funcom forum: Blunted arrows decoded](https://forums.funcom.com/t/blunted-arrows-decoded/71820) (search snippet; the claim is community)
- Player test write-up (community, author "Xevyr," not official): steel truncheon with no fitting = 35 concussive on light attack, 40 on heavy. With advanced blunted fitting = 65 light, 100 heavy. Authority adds about 6% concussive per point. Savory Feast +15% (tested 100→115). Strength does not change concussive. Agility, Dead Shot and the Strength finisher perk showed no effect. Blunted bow: charged shot gets a fixed concussive bonus. — [Funcom forum: Concussive damage explanation](https://forums.funcom.com/t/concussive-damage-explanation-in-3-0-or-knocking-out-thralls-umm-scientifically/209427)
- Blunted fitting numbers (community wiki, search snippet): +10 concussive on light, +20 on heavy; does not affect kill damage. — [Conan wiki: Simple Blunted Weapon Fitting](https://conanexiles.fandom.com/wiki/Simple_Blunted_Weapon_Fitting) (search snippet)
- Server setting: a "ConciousnessDamageMultiplier" in ServerSettings.ini (community, search snippet). — [Funcom forum: Can no longer knock out thralls](https://forums.funcom.com/t/can-no-longer-knock-out-thralls/8363)
- Sunder (search snippet, GamerGuides): each hit applies 10% armor penetration, stacking up to 5 times for 50%. — [GamerGuides: weapon perks and status effects](https://www.gamerguides.com/conan-exiles/guide/weapons/legendary-weapons/all-weapon-perks-and-status-effects-conan-exiles) (search snippet; not fetched, verify in game)

### Inferences
- Conan's design is "hyper armor by momentum": the stun resistance is tied to the animation's weight and timing, not to the enemy. The 2023 letter gives a clear rule: heavy = more armor, fast = interrupts slow.
- The 2026 reply shows the cost: too little hyper armor on enemies made fights a stun-lock; too much made them unstaggerable. Funcom is tuning it by hand, with no fixed number.

### Gaps
- No exact hyper-armor frame counts or stagger thresholds were found in any source.
- No official "daze" or "stun" status definition for Conan was found. The "Daze" hits were from other games. Whether "Stun Damage" (Giant's Fingerbone perk) is a separate status is unconfirmed.
- The exact patch where the post-2023 hyper armor changes landed was not confirmed.
- Grit/Strength stagger perks: only a community note that Grit helps stamina (May 2026 reply). No stagger-perk numbers found.
- Boss poise values: not found.

---

## 2. 7 Days to Die: zombie stun, knockdown, stagger

### Takeaway
Vanilla 7 Days to Die has no single knockdown percentage for zombies on the pages I could read. Stun and knockdown are mostly weapon- or perk-driven chances. The wiki lists the chances for Brawler tiers, but the wiki pages I checked say their values may be from older versions. Zombies get back up after a few seconds, so ragdoll is a delay, not a kill.

### Cited Findings
- Zombie behaviour: leg hits "be stunned for a couple of seconds"; torso hits "may be stunned, causing them to fall to the ground"; downed zombies "will get up a few seconds later and resume their assault." — [7DTD wiki: Zombie](https://7daystodie.wiki.gg/wiki/Zombie)
- Zombie variants: Feral "staggering (also known as ragdolling) can help to slow them down"; Radiated "less susceptible to stagger"; Charged "more resistant, but not immune" to stun baton and electric fence; Infernal "only ragdoll 25% of the time from a Robotic Sledge." — [7DTD wiki: Zombie](https://7daystodie.wiki.gg/wiki/Zombie)
- Stun from attacks: "All attacks have a chance of causing an Infection, Stunned, Fatigue, Sprained Legs and Sprained Arms." No chance percentage is given. — [7DTD wiki: Zombie](https://7daystodie.wiki.gg/wiki/Zombie)
- Fall damage: "will stun the zombie, making it vulnerable to triple-damage while stunned." — [7DTD wiki: Zombie](https://7daystodie.wiki.gg/wiki/Zombie)
- Stunned debuff effect: "Slows movement/attack speed by 80%/50%, falling to 20%/0% over the duration." Durations: Brawler rank 2 + Weighted Head Mod = 4 s; Boomstick rank 1 / Sniper vol 3 = 6 s; Boomstick rank 3 = 8 s. No chances listed. — [7DTD wiki: Enemy Debuffs](https://7daystodie.wiki.gg/wiki/Enemy_Debuffs)
- Stun Baton: "making them stunned for a while"; Shocked from Stun Baton = 6 damage per second for 4–8 s by Electrocutioner rank. — [7DTD wiki: Weapons](https://7daystodie.wiki.gg/wiki/Weapons); [7DTD wiki: Enemy Debuffs](https://7daystodie.wiki.gg/wiki/Enemy_Debuffs)
- Pipe Baton (Electrocutioner perk): "causes zombies to stagger instantly"; power attack is "an instant knockdown against all but the most tough zombies"; can knock more than one zombie down. — [7DTD wiki: Weapons](https://7daystodie.wiki.gg/wiki/Weapons)
- Brawler (page last edited 2 July 2025, no game version stated): Tier 2 Scrapper, 30% chance to stagger with power attacks using knuckle weapons; Tier 3 Slugger, 20% chance to knock down with power attacks; Tier 4 knockdown on power attacks, no % given; Tier 1 and 5 no stun. — [7DTD wiki: The Brawler](https://7daystodie.wiki.gg/wiki/The_Brawler)
- Brawler older values (search snippet, a guide): headshot power attack knockdown chance rising by rank, knockdown 4 s; the guide's per-tier list was -/-/20/30/30%. The wiki's perks page warns it "may contain outdated information… (Version 2.1)." — [BisectHosting perk guide](https://www.bisecthosting.com/blog/7-days-to-die-perks-skills-points-guide) (search snippet); [7DTD wiki: Perks](https://7daystodie.wiki.gg/wiki/Perks) (search snippet)
- Mod (not vanilla): one Nexus mod adds a random stun chance at half the knockdown chance, with a timeout up to 20. — [Nexus mod 1014](https://www.nexusmods.com/7daystodie/mods/1014) (search snippet)

### Inferences
- Zombie stun is a short timed state with a movement and attack-speed slow, not an animation lock. Stun is granted per attack by chance, and by perk, with the chance usually tied to a specific action (power attack, head hit, knuckle weapon).
- Knockdown means ragdoll-then-recover. Its value is spacing, not kill.

### Gaps
- No vanilla percentages for the basic zombie stun chance or the knockdown chance.
- No stagger or knockdown durations for the Pummel Pete perk were found. Pummel Pete is "club and bat specialization" only (search snippet); no numbers.
- Knockdown recovery time: only "a few seconds" (wiki).
- Head-shot dismemberment rules and the "Skull Crusher" perk: not researched.
- Game-file values (items.xml / entity config) would give exact numbers; not fetched.

---

## 3. Dying Light (1 and 2): kicks, knockdowns, stagger

### Takeaway
No technical source on Dying Light's kick knockdown or limb-flinch code was found. Available sources are player and press descriptions: kicks are used to interrupt and to stagger, and ragdoll does not always trigger after a stagger.

### Cited Findings
- DL1 flying two-footed kick "can stagger enemies or knock them off perches" (review). — [PC Gamer Dying Light review](https://pcgamer.com/dying-light-review) (search snippet)
- DL1 dropkick "can occasionally be used to stagger and knock back Goons and Demolishers." — [Dying Light wiki: Drop kick](https://dyinglight.fandom.com/wiki/Drop_kick) (search snippet)
- DL2 has no dedicated kick button for stagger; "to stagger an enemy you have to either block an incoming attack at exactly the right moment or… use the Perfect Dodge or Grapple skills." — [PowerPyx/Gamepur-type guide: DL2 kick](https://www.powerpyx.com/dying-light-2-how-to-kick/) (search snippet, guide; attribution uncertain)
- Attack-kick alternation for stagger-chaining: a guide says "attack once, do a kick to stagger the enemy, attack again, kick again." — [Sportskeeda: how to kick enemies DL2](https://www.sportskeeda.com/esports/how-kick-enemies-dying-light-2) (search snippet)
- Ragdoll not always firing after stagger: a Reddit post (early 2022, anecdotal) said ragdoll "sometimes fails to activate after a zombie's stagger animation"; Techland reportedly acknowledged zombie physics issues. — [r/dyinglight thread](https://red.bismuth.it/r/dyinglight/comments/skjky2/note_techland_has_acknowledged_there_are_issues/hvoksgy/?context=3) (search snippet; unverified)
- Press: DL2 dropkick described as "exactly as overpowered as it should be." — [PC Gamer](https://pcgamer.com/dying-light-2s-dropkick-is-exactly-as-overpowered-as-it-should-be) (search snippet, opinion)

### Inferences
- Dying Light uses a "stagger then ragdoll" chain with a separate kick action, which is a two-input interrupt design. Stagger is driven by the player's timing (block window, dodge, grapple), not by the enemy's armor.

### Gaps
- Limb-specific flinch: no source found.
- Stamina-based knockdown rules: no source found.
- Ground finishers: not researched.

---

## 4. Other games (brief)

### Enshrouded
- Parry and block fill a white stagger bar under the enemy's health bar; attacking a blocking enemy also fills it. A full bar stuns for about five seconds. Stagger value scales with weapon level versus enemy level, so a much higher-level enemy can make parry fail. Merciless Attack (skill tree) deals heavy damage to a stunned enemy. — [Sportskeeda: Enshrouded combat](https://www.sportskeeda.com/esports/enshrouded-combat-mechanics-how-attack-and-defend) and [Enshrouded wiki: Combat Mechanics](https://enshrouded.wiki.gg/wiki/Combat_Mechanics) (search snippets; not fetched)
- Design point: a meter that fills per hit and blocks, instead of per-attack flags.

### V Rising
- No stagger or hyper armor rules found. Only general notes (boss gating, melee viability). Gap.

### Elden Ring (reference only, not a survival game)
- Hyper armor: keeps attacking through hits unless the incoming poise damage is high enough or a status or grab bypasses it. — [Elden Ring wiki: Hyper Armor](https://eldenring.wiki.gg/wiki/Hyperarmor) (search snippet)

### Grounded, Sons of the Forest, Mordhau-style melee, Mordhau-lite survival melee
- Not researched within budget. Gap.

---

## 5. Player opinion on stun-lock (cross-game)

### Cited Findings
- Player on a Funcom forum: "This artificial difficulty using a cheap gimmick is stupid. Make them better not cheaper with knockdown and stunlock spam." — [Funcom forum: Does every NPC need a stunlock/knockdown?](https://forums.funcom.com/t/does-every-npc-need-a-stunlock-knockdown/9918) (search snippet; the quote is from the search summary of a Funcom thread)
- Warframe players asked for a short stun protection after being staggered. Path of Exile players proposed extra stun resistance after the first stun. — [Warframe forum: why stuns are bad](https://forums.warframe.com/topic/27121-why-stuns-are-bad) and [PoE forum: stun suggestions](https://pathofexile.com/forum/view-thread/3677859) (search snippets)
- Dune: Awakening PvP stunlock: Funcom said the stab-stunlock exploit "is being fixed." — [PC Gamer](https://www.pcgamer.com/games/survival-crafting/dune-awakenings-stabby-stunlock-pvp-exploit-is-being-fixed-says-funcom-weve-got-this-covered) (search snippet)
- TV Tropes: stunlock is attacking the moment the target recovers; a bug when accidental. — [TV Tropes: Stunlock](https://tvtropes.org/pmwiki/pmwiki.php/Main/StunLock) (search snippet)
- Common position (search results, community): stun-lock is acceptable only when the player has a way out, such as a stun-protection window, a cooldown between knockdowns, or a cap on how often enemies can stun.

### Inferences
- The fixes players ask for match the mechanisms seen above: hyper-armor windows (Conan), stun-break timing (Conan 2023, removed), per-stun cooldowns (7DTD chance-based), and immunity for high-tier enemies (Conan 2023, "only certain high difficulty enemies").

### Gaps
- No survey data. Forum posts only.

---

## Design takeaways for an original co-op melee survival system (summary of cited facts)
1. Make armor per attack, not per enemy. Conan ties it to animation momentum: heavy and slow = more hyper armor, fast = can interrupt slow (dev letter, 2023).
2. Keep a stun break or a cooldown window. Conan's old rule was 3 s stunned : 1 s free (dev letter, 2023), since removed; players want protection after a stun (Warframe, PoE snippets).
3. Use chances per perk and per action (7DTD Brawler: 30% stagger, 20% knockdown on power attacks; source wiki, possibly outdated).
4. Use a second meter for knockout, separate from health (Conan concussive). Community tests suggest it scales with weapon fitting and Authority, but these numbers are unofficial.
5. Give stunned enemies a slow, then ragdoll-and-recover (7DTD: "get up a few seconds later").
6. Make bosses and high-tier enemies immune or partly immune (Conan 2023; 7DTD Charged zombies "more resistant, but not immune").
7. Avoid stagger-chaining with no outs. Forum sentiment strongly says stun-lock is frustrating unless the player has an answer.
