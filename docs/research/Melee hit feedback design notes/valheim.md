# Valheim: melee hit feedback, stagger, parry, knockback (research notes)

Research date: 2026-11-21. Method: web search plus fetches. The official wiki (valheim.fandom.com, valheim.wiki.gg) returned HTTP 401/402 to our fetch tool, and the breezewiki mirror was blocked by a bot check. So most wiki-level numbers below come from third-party guides (gamever.io, which says its figures come from community wikis) and from search-result snippets. No decompiled code was verified: `Character.AddStaggerDamage` and `m_staggerDamageFactor` returned no results, so those field names are NOT confirmed. Valheim numbers change with patches; none of the sources here state the game version, so treat every number as "community-reported, unknown patch" unless noted.

## 1. Stagger meter (hidden bar that makes an enemy or the player stumble)

### Takeaway
Each creature has a hidden stagger bar. Physical or lightning damage fills it. When it fills, the target is stunned and takes 2x damage for a short time. Players have the same bar, set to 40% of max health (community-reported), and a block fails once the leftover damage fills it.

### Cited Findings
- Stagger is caused by physical (blunt, slash, pierce) and lightning damage, or by a successful parry. Fire, frost, poison and spirit do not stagger, per one wiki-based guide. Staggering "doubles damage taken and stops the enemy from acting." Duration varies per enemy. Players can be staggered but do not take the extra damage. — [gamever damage guide](https://gamever.io/knowledge-base/how-valheim-actually-calculates-damage-and-why-your-numbers-swing-so-much)
- Stagger damage equals the amount of damage dealt, per a wiki mirror. The same mirror says the stagger bar gradually expires at 20% of the stagger limit per second, and it is flagged as possibly outdated. Source: search snippet of [Valheim wiki Stagger (BreezeWiki mirror)](https://breezewiki.discard.no/valheim/wiki/Stagger). We could not open the page, so this is unconfirmed.
- Stagger threshold: "Your stagger bar is 40% of maximum health. A block fails when leftover damage fills it." — [gamever parry guide](https://gamever.io/knowledge-base/blocking-parrying-in-valheim-shield-types-the-parry-window-and-stagger). A 2023 forum thread also quotes "Your Stagger Bar maximum is based on 40% of your max HP," citing the wiki. — [Steam thread, 25 Aug 2023](https://steamcommunity.com/app/892970/discussions/0/3827550531058812597). Both are secondary.
- The wiki says food that raises max health also raises the stagger limit and so makes stagger wear off faster (snippet of the wiki Stagger page; not verified).
- Stagger duration per creature: a wiki table, as quoted in a search summary, lists the player at about 1.18 s and the boar at about 1.24 s. Not verified against the page.
- Enemies have a higher stagger limit the stronger they are, so bosses and big creatures are harder to stagger (wiki snippet).
- A stagger cannot be re-applied while the target is already staggered (wiki snippet).
- Mod evidence: Goo's Combat Overhaul separates "stagger decay speed" from "outgoing stagger power" and "incoming resistance," and has settings for a "non-staggering hit stagger decay cooldown" and stagger duration per weapon and attack. Its settings are documented as PvP-focused; PvE behaviour may differ. — [Goo's Combat Overhaul on Thunderstore](https://thunderstore.io/c/valheim/p/gnls/GoosCombatOverhaul/) (search snippet). Kyresel's CombatOverhaul changes the enemy stagger-damage reset timer from 3 s to 4 s in v1.7.6. — [Thunderstore](https://thunderstore.io/c/valheim/p/Kyresel/CombatOverhaul/v/1.7.6/) (search snippet).

### Inferences
- The stagger rule ("stagger = damage dealt, so fast small hits and big hits both fill the bar") is what gives a 2x payoff for hitting hard enough. It is a clear, readable target.
- Two different rules for the player's own bar (block is checked before armour; hit is checked after) are a common complaint (see section 2), so if we copy the idea we should make the order explicit and consistent.

### Gaps
- Exact decay per second and stagger duration per creature: only the snippet, not the page. Need the wiki (blocked) or a mod's config file.
- Exact field names and default values in code: not found.
- Whether the 40% figure and the 20%/s decay still hold in the current (Hearth & Home or later) build: not confirmed.

## 2. Blocking and parrying

### Takeaway
A parry is a timed block in the last 0.25 s before a hit. It negates the hit and staggers the attacker, and it costs no stamina. Blocking that takes too much damage staggers the defender. Parry and block numbers are community-measured and disputed; the block-order rule comes from a single forum thread.

### Cited Findings
- Parry window: "under 0.25 seconds before the hit lands." — [gamever](https://gamever.io/knowledge-base/blocking-parrying-in-valheim-shield-types-the-parry-window-and-stagger)
- Parry effect: the attacker is staggered, cannot move, and takes 2x damage. Parry multiplier by weapon: Flesh Rippers 6x, knives 4x, bucklers 2.5x, round shields 1.5x, most other weapons 1.5x to 2x. Tower shields cannot parry. Parrying costs no stamina. — [gamever](https://gamever.io/knowledge-base/blocking-parrying-in-valheim-shield-types-the-parry-window-and-stagger). Forum poster gives the same 1.5x (normal shields) and 2.5x (bucklers). — [Steam 2023](https://steamcommunity.com/app/892970/discussions/0/3827550531058812597)
- Parry works on ranged attacks too: the shooter is staggered (wiki snippet, search summary).
- Bosses cannot be parried; nearly all small and medium enemies can (one guide, via search summary).
- Block damage formula (gamever, from community wikis): if block armour is at least half the incoming damage, damage taken = damage² / (4 × block armour); if block armour is under half, damage taken = damage − block armour. Blocking skill adds +0.5% block armour per level (+50% at level 100). — [gamever](https://gamever.io/knowledge-base/blocking-parrying-in-valheim-shield-types-the-parry-window-and-stagger)
- Failure: a block fails when leftover damage fills the 40% stagger bar. The article says a big hit "staggers you." Blocks also fail when you run out of stamina; the stamina cost is up to 10, scaled by the leftover damage ratio. — [gamever](https://gamever.io/knowledge-base/blocking-parrying-in-valheim-shield-types-the-parry-window-and-stagger)
- Block-order rule (forum claim citing the wiki): "when you block, Stagger is getting calculated BEFORE armor reduction is applied"; "when you get hit, Stagger is getting calculated AFTER armor reduction." A player on the hardest difficulty said blocking staggered too easily and called it "blocking = death." A user's worked example: a 140-damage wolf hit against 116 block power (0 Blocking skill) leaves about 42.2 damage through, and avoiding stagger needs at least 108 max HP. The thread says this has been the case "since the Hearth and Home update." — [Steam thread, 25 Aug 2023](https://steamcommunity.com/app/892970/discussions/0/3827550531058812597). Community claim, no developer reply in the thread.
- Hearth & Home preview: developers said block effectiveness would tie to max health rather than stamina, with a new stagger meter. We could only see headlines and snippets. — [PC Gamer](https://www.pcgamer.com/new-valheim-video-outlines-upcoming-changes-to-blocking-and-staggering) (headline only), [GamesRadar](https://gamesradar.com/valheim-hearth-and-home-trailer-highlights-changes-to-blocking-and-a-new-stagger-meter) (snippet only). Late-2023 community posts describe the stagger bar as already live, so the preview may be out of date.

### Inferences
- A parry is the best feedback loop in the game: a tight, skill-based window, a large reward (stagger plus a multiplier), and the cost is free. Copy the shape (window + big reward + no cost), not the numbers.
- The "block fails and you stagger" rule makes shields feel risky. The 2023 thread shows players read it as unfair on hard mode, so the stagger rule needs a clear, visible threshold.

### Gaps
- The exact parry window in frames or milliseconds, and whether it changed in later patches: only "under 0.25 s" from one guide.
- Stagger the blocker takes on failure (duration, animation): not found.
- Current block formula after the Hearth & Home change: not verified.

## 3. Knockback (push-back force)

### Takeaway
Each melee weapon has a knockback number. Clubs and maces push hardest. Swords hold enemies in place with low knockback. Knockback can move an enemy out of its attack range. We found no source on how knockback scales with enemy size or mass.

### Cited Findings
- Club 30, Torch 30, Bronze mace 80, Iron mace 90, Frostner 100, Porcupine 100, Flametal mace 100. Sledgehammers: Stagbreaker 150 (area damage only), Iron sledge 200 (2x stagger plus area damage), Demolisher 210 (2x stagger plus area damage). — [gamever clubs](https://gamever.io/knowledge-base/every-club-and-sledgehammer-in-valheim-knockback-from-30-to-210). The article gives no patch version and notes figures come from community wikis.
- The gamever article says knockback is "sufficient to displace some enemies out of their effective attack range," and that clubs push enemies away one at a time while swords have low knockback and hold a crowd in place. — same source.
- Game8 lists Iron, Bronze, Silver and Blackmetal swords at knockback 40, and basic Club at 25 (conflicts with gamever's 30). — [Game8 search snippet](https://game8.co/games/Valheim/archives/321859). Numbers differ by source and probably by patch.
- Two-handed club: listed at 200 knockback, will stagger and slow enemies (search summary of a guide; source not confirmed).

### Inferences
- Knockback value and stagger are separate numbers. Maces get high knockback and sword stagger comes from damage; this gives each weapon class its own feel.

### Gaps
- How knockback relates to enemy size or mass: not found in any source.
- Exact pushback distance or force units: not found (only Frostner's "120 unit knockback distance" from one search summary, no source page).
- Whether knockback is applied to the enemy only, or also to the player when blocked: not found.

## 4. Combo structure, secondary attacks and damage multipliers

### Takeaway
Most swords and two-handed weapons use a 3-hit chain. The third hit deals double damage, per the gamever damage guide and the Nidhögg wiki snippet. Secondary attacks use a separate multiplier. Stamina cost and the exact per-hit values need checking in the game.

### Cited Findings
- Damage formula (gamever): damage = listed damage × skill factor × multipliers. Skill factor at skill 0 is 25% to 55%, at 50 about 55% to 78%, at 100 85% to 100%. Multipliers: backstab 2x to 6x (shown on tooltip), stagger 2x, attack chain 2x on the third hit, secondary attacks 0.5x to 3x depending on weapon, multitarget 4 / (3 × targets) (66.7% for 2 targets, 44.4% for 3, 33.3% for 4, 26.7% for 5; trees, rocks and ground count as targets), damage type 0% to 200%. Armour is subtracted afterwards. — [gamever damage guide](https://gamever.io/knowledge-base/how-valheim-actually-calculates-damage-and-why-your-numbers-swing-so-much)
- Nidhögg wiki snippet: "The Nidhögg is the sixth one-handed sword. Like other swords it has a primary attack that is a 3-hit combo with double damage on the last hit." Its secondary attack deals 3x damage. — [Valheim wiki, Nidhögg](https://valheim.fandom.com/wiki/Nidh%C3%B6gg) (search snippet, page not opened)
- Nord Greatsword (patch 1.0.21 guide): three-hit chain, double damage on third hit. — [theclick.gg](https://www.theclick.gg/?p=57908) (search snippet)
- Conflicting: a Thunderstore mod lists sword chain multipliers of 1.2, 1.4, 2.0 per hit. This is a mod, not vanilla. — [SpecialAttack mod](https://thunderstore.io/c/valheim/p/MM94/SpecialAttack/v/1.2.4/) (search snippet)
- Secondary attacks multiply with the stagger x2 on a staggered target (one guide, search summary; example given is a mace secondary).

### Inferences
- The third hit as a clear "payoff" beat (double damage, bigger animation) is a simple rhythm to copy in an original game.

### Gaps
- Stamina cost per swing and per combo step: not found in the sources we could read.
- Exact animation or hit-pause length on the third hit: not found.

## 5. Sneak attacks and backstab

### Takeaway
Backstab (sneak) damage is 2x to 6x, shown on the weapon tooltip. A backstabbed enemy is immune to backstab for five minutes. Players cannot be backstabbed. We did not find a separate "3x / 4x knife sneak" value; the 4x figure we found belongs to the knife parry.

### Cited Findings
- Backstab 2x to 6x; enemy immune for 5 min after one backstab; players cannot be backstabbed. — [gamever damage guide](https://gamever.io/knowledge-base/how-valheim-actually-calculates-damage-and-why-your-numbers-swing-so-much)
- Knife parry multiplier 4x. — [gamever parry guide](https://gamever.io/knowledge-base/blocking-parrying-in-valheim-shield-types-the-parry-window-and-stagger)

### Gaps
- Per-weapon backstab values (which knife gives 3x or 4x): not found.
- Backstab detection angle and window: not found.

## 6. Hit reactions, hit-stop, camera shake, VFX, sound

### Takeaway
We could not find a source that documents Valheim's hit-stop frames, camera shake amounts, hit-spark or blood VFX, or sound layering. The only Valheim-specific statement is from a mod author who says hit-stop is already in vanilla and can make some weapons feel sticky. Most "why it feels good" evidence is general game-feel writing, not Valheim data.

### Cited Findings
- Goo's Combat Overhaul author: a brief freeze or slowdown of the animation when a hit connects gives attacks more impact; "this is a feature that vanilla Valheim already has"; heavy attacks can get stronger hit-stop while light attacks stay snappy; too much hit-stop makes weapons feel sticky. — Goo's Combat Overhaul description, [Thunderstore](https://thunderstore.io/c/valheim/p/gnls/GoosCombatOverhaul/) (search summary; not verified in game).
- The mod's author also says the melee loop depends on stagger thresholds, with blocking, parrying and weapon stagger creating safe punish windows. — same source.
- Damage number colours (search summary of guides; not all confirmed): yellow means the enemy is weak to that damage type; white means normal; grey means resistant. Damage over time always shows white, even against weak or resistant enemies (per wiki, via search summary). A Steam commenter said yellow means strong; others corrected that. — [GamePressure Combat Guide](https://www.gamepressure.com/valheim/combat/zee2f1) and [Steam thread](https://steamcommunity.com/app/892970/discussions/0/4416424085342094157) (search snippets).
- General game-feel guidance (not Valheim-specific): hit-stop should freeze both attacker and target, or the enemy looks like it hiccupped; a light shake can be 1–2 px decaying over about 100 ms (2D example); most indie games shake on every hit, which dilutes it. — [uhiyama-lab Unity game-feel primer](https://uhiyama-lab.com/en/notes/unity/unity-game-feel-hit-feedback/) and a [freegamesprites article](https://freegamesprites.com/ar/news/game-feel-2d-combat-juice-tricks) (search snippets).

### Inferences
- Hit feedback is probably a stack: short freeze plus animation, a stagger state the player can read, damage numbers with a colour code, and layered impact sound. The stagger state gives the most visible "it worked" signal.
- The yellow/white/grey colour code matches a clear three-state rule (weak / normal / resistant), which is easy to copy.

### Gaps
- Hit-stop length in milliseconds or frames: not found.
- Camera shake values: not found.
- Sound design details (layers, pitch variation): not found. Iron Gate has not published these in any source we could reach.
- Hit spark and blood VFX details: not found.

## 7. Damage types and weakness feedback

### Takeaway
Each creature has a multiplier per damage type. The scale runs from 0% (immune) to 200% (very weak). Armour is applied after the type multiplier. Physical damage (blunt, slash, pierce) and lightning stagger; fire, frost, poison and spirit do not stagger (wiki-based claim, one source).

### Cited Findings
- Resistance scale: very weak 200%, weak 150%, neutral 100%, resistant 50%, very resistant 25%, immune 0%. — [gamever damage guide](https://gamever.io/knowledge-base/how-valheim-actually-calculates-damage-and-why-your-numbers-swing-so-much)
- Type multiplier applied per type first, then armour on the total. Example from the source: 100 fire and 100 blunt, fire resistance and 75 armour, gives 25 fire and 50 blunt damage. — same source.
- Maximum armour synergy when armour is at least half the raw damage: very weak 200% to 400%, weak 150% to 225%, resistant 25% to 50%, very resistant 6.25% to 25%. — same source.
- Damage-type stagger rule: one guide says only slash, pierce, blunt and lightning stagger. A different game guide says stagger comes from physical damage in general. Conflict noted; we lean to the first, but it is one source. — [gamever damage guide](https://gamever.io/knowledge-base/how-valheim-actually-calculates-damage-and-why-your-numbers-swing-so-much) and search summary of [theclick.gg Stagger guide](https://www.theclick.gg/?p=58600) (page returned HTTP 403 when we tried to open it).

### Gaps
- The exact list of "weak to blunt" creatures (skeletons, etc.) per creature: not checked against the wiki.

## 8. Community and reviewer commentary on why combat feels good

### Takeaway
We found little direct player or reviewer writing on why Valheim's hits feel good. The commentary we found is about frustration, not praise: the blocking and stagger rules are read as unclear or unfair on hard mode, and modders tune hit-stop, stagger decay and knockback to change the feel.

### Cited Findings
- Hard-mode blocking complaint (Aug 2023): "On hardest setting, blocking = death." The poster says blocking staggers too easily, while dodging and taking hits works. Other posters argued parries are too narrow on very hard and rely on memorised numbers. — [Steam thread](https://steamcommunity.com/app/892970/discussions/0/3827550531058812597)
- Goo's Combat Overhaul's stated goal is making weapon classes "more distinct, responsive, and satisfying" while keeping vanilla structure. — [Thunderstore](https://thunderstore.io/c/valheim/p/gnls/GoosCombatOverhaul/) (search snippet)
- Kyresel's CombatOverhaul aims to balance combat "without straying too far from developers' original intent." — [Thunderstore](https://thunderstore.io/c/valheim/p/Kyresel/CombatOverhaul/) (search snippet)
- An Obsidian combat designer says that without a "sense of connection" a fighting game "just feels bad." — [PC Gamer](https://www.pcgamer.com/games/rpg/if-youve-been-worried-about-avowed-not-looking-punchy-enough-obsidians-combat-designer-has-a-hitstop-animation-superpower-that-might-reassure-you) (search snippet, not Valheim)

### Inferences
- Players' praise (if it exists) is probably about the stagger payoff and the parry, while complaints centre on blocking. Community sentiment was not sampled in this pass, so this is an inference.

### Gaps
- No Reddit or Steam review text was read in full. The "feels good" claim itself is not sourced to any player or reviewer in this pass.
- No developer interview about combat design was found.

## Sources not reached
- valheim.fandom.com and valheim.wiki.gg: HTTP 401/402 (the Stagger, Clubs pages).
- breezewiki.discard.no Stagger page: blocked by a bot check.
- theclick.gg: HTTP 403 on fetch.
- PC Gamer Hearth & Home article: only the headline loaded.
- NME Hearth & Home article: not opened.

## Next steps for the team
1. Get the wiki pages through another route (a wiki dump, or a mod's README) to confirm stagger decay (20%/s?), duration per creature, and the parry window.
2. Read a stagger-related mod's config file (Goo's Combat Overhaul) for real default values and field names, instead of guessing from decompiled code.
3. Decide the original design from the shape, not the numbers: a readable stagger bar, a short parry window with a big payoff, a third-hit beat, a 3-state damage colour code.
