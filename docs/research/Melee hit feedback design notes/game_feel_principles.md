# Game Feel and Melee Hit Feedback: Principles and Numbers

Scope note: this run used about 19 tool calls. Several primary talks (Eiserloh, Vlambeer, Jonasson/Purho) could not be reached in usable form, so those points are marked as gaps. Figures from community wikis are labelled as such. Fighting-game frame numbers are from SSBWiki and are not a template for a 3D action game; they show how one genre tunes hitstop.

## Hit-stop (hitlag / hit pause): durations and formulas

### Takeaway
Hitstop is a short freeze of attacker and/or victim on contact. In Super Smash Bros. it scales with damage, and it is capped (20 frames in Melee, 30 from Brawl on). Scaling by damage plus a hard cap is a usable pattern for a small team.

### Cited Findings
- Melee hitlag formula as printed: floor(floor(floor(d/3 + 3) x e) x c), where d = damage %, e = electric multiplier, c = crouch-cancel factor. Melee cap: 20 frames. Brawl and Smash 4 formula: floor(floor(d x 0.3846154 + 5) x h x e) x c, cap 30 frames (20 for a victim crouch-canceling). Ultimate formula: floor(floor(floor(d x 0.65 + 6) x h x e x s) x p) x c, where h = move hitlag multiplier, s = spirit factor, p = Ultimate's extra factor (the page does not define p in the excerpt). Source: [SSBWiki Hitlag](https://ssbwiki.com/Hitlag)
- Worked example from the same page: a 15% move gives 8 frames in Melee, 10 in Brawl and Smash 4, and 15 in Ultimate. Source: [SSBWiki Hitlag](https://ssbwiki.com/Hitlag)
- Electric attacks multiply hitlag by 1.5 (rounded down). Crouch-cancel multiplies the victim's hitlag by 0.667. Shielding applies 0.67 (multipliers below 1 are ignored when shielding). Source: [SSBWiki Hitlag](https://ssbwiki.com/Hitlag)
- Attacks with no knockback cause no hitlag to the target. Source: [SSBWiki Hitlag search summary](https://www.ssbwiki.com/Hitlag) (search snippet, page not fetched in full)
- Hitstun is roughly 0.4 frames per knockback unit in Melee and Brawl (100 knockback = about 40 frames). Launch velocity is roughly knockback x 0.03. Source: [Smashboards knockback tool thread](https://smashboards.com/threads/tool-knockback-launch-speed-hitstun-hitlag-shieldstun-calculation-v1-11.324878/post-14662705) (search snippet). Ultimate tumble hitstun formula is unresolved per the SSBWiki user page (search snippet).
- Hitstop is also called "freeze frames" or "impact freeze"; one source says it keeps cancel timing consistent. Source: [SSBWiki Hitlag](https://www.ssbwiki.com/Hitlag) and [SSBWiki Talk: Hitlag](https://www.ssbwiki.com/Talk:Hitlag) (search snippets only).

### Inferences
- A usable 3D formula: hitstop frames = min(cap, floor(base + damage x k) x weight_multiplier), with separate values for light, heavy, and crit hits. Smash's pattern (scaling by damage, capped, reduced for the defending/guarding side) carries over directly.
- Hitstop only on attacks that actually move the target (knockback or stagger > 0) avoids freezes on jabs that feel dead.
- Shorter freezes for the defender when it is blocking or crouching matches Smash's 0.67 rule.

### Gaps
- No source found for Monster Hunter, God of War, Hades, Dark Souls, or Street Fighter hitstop values in ms. Search returned community forum posts only.
- Whether hitstop is local-only or synced online: no source found. Search returned netcode overviews (rollback, GGPO) but none that address hitstop specifically. Practical reading for our game: under rollback, hitstop must be part of the simulated state (a frame counter the host owns), not a local visual-only effect, or clients drift. This is an inference, not a sourced fact.

## Hit reactions, flash, knockback

### Takeaway
Hit reactions are a family: light flinch, heavy stagger, knockback, and knockdown/launch. Monster Hunter uses hidden per-part HP to pick the reaction. The exact numeric knockback and flash values for big-name games could not be sourced in this run.

### Cited Findings
- Monster Hunter (player explanation, not official): each body part has its own HP pool; depleting it produces a flinch, topple, or dunk (flying monsters). Leg damage builds a hidden topple bar. Source: [Steam community, Monster Hunter: World discussions](https://steamcommunity.com/app/582010/discussions/0/595134572710073243) (secondary; numbers not given)
- Monster Hunter stun: blunt head damage builds a stun meter; the threshold rises after each stun. Source: [Steam community, Monster Hunter: World discussions](https://steamcommunity.com/app/582010/discussions/0/2979655949473804881) (secondary)
- Monster Hunter Stories 3: a Wyvernsoul gauge acts as poise; at zero the monster is Dazed and can be Toppled by the next Head-to-Head or Double Attack. Source: [Monster Hunter Rise Fextralife combat page search listing](https://monsterhunterrise.wiki.fextralife.com/Combat) (search result summary; the Stories 3 detail came from [G2A Stories 3 combat guide search result](https://www.g2a.com/news/features/guide/monster-hunter-stories-3-combat-guide/))
- Vlambeer's screenshake is described as "slightly in the opposite direction of the player's gunfire." Source: [Game Developer, Vlambeer co-founder advice](https://www.gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games)
- Nuclear Throne-related summary of Nijman's talk (secondary, no URL in search results): kick the camera back 6 px from the aim direction, add 4 to screenshake, and the effect degrades fast. Source: blog post cited in [DK Liao devlog search results](https://dkliao.itch.io/the-art-of-screenshake-recreation/devlog) (secondary; the exact blog URL was not retrieved)
- Nijman's talk, per a secondary recreation (DK Liao): camera lerp, hit pause, and enemy knockback were among the added steps. Source: [DK Liao, the art of screenshake recreation](https://dkliao.itch.io/the-art-of-screenshake-recreation/devlog/451576/quick-breakdown-of-all-the-effects) (search snippet)

### Inferences
- Use a hidden per-part or per-zone HP/poise pool to choose the reaction type. Makes "weak spot" hits more reactive without a second system.
- Keep "flinch" (small, interrupts only light attacks) and "stagger/knockdown" (large, from poise break) as separate tiers.

### Gaps
- No verified numbers for flash duration (white flash ms), knockback distances in metres, additive hit-react animation blend times, or procedural bone-impulse values. The Eiserloh and Juice-It talks were not reachable. Recommended: test these in-engine with the owner rather than copy numbers.
- "Juice it or lose it" (Jonasson and Purho): a search for the talk and its named techniques (hit pause, squash, stretch) returned only squash-sport pages. No source obtained.

## Camera: screen shake, FOV punch, rumble

### Takeaway
Screen shake should be scaled by a trauma-style value and should decay. The main formula (trauma squared, with noise per axis) is widely taught, but I could not source it from the talk in this run.

### Cited Findings
- Squirrel Eiserloh, "Math for Game Programmers: Juicing Your Cameras With Math," GDC 2016. Covers screen shake, split screen, and camera smoothing math. Source: [GDC Vault session page](https://gdcvault.com/play/1023146/contactUs) (listing); [Game Developer video summary](https://gamedeveloper.com/programming/video-sprucing-up-cameras-with-math)
- Vlambeer's talk "The Art of Screenshake" (Jan Willem Nijman, 2013) is described as a sequence of about 30 small tweaks to a dull shooter. Source: [Game Developer, Vlambeer advice](https://www.gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games); [itch.io post](https://itch.io/post/1671105) (search snippet)
- Nijman's tweaks include a 33% chance that enemies "explode harmlessly on death." Source: [Game Developer, Vlambeer advice](https://www.gamedeveloper.com/design/vlambeer-co-founder-shares-advice-on-building-better-action-games)

### Inferences
- Recommended starting model (from general practice, not sourced here): trauma 0 to 1, shake = trauma squared, add to camera rotation/offset using smooth noise, and decay trauma per second (roughly 1.0 to 2.0 per second for light hits). Scale trauma by hit weight and by how close the player is to the hit. Verify against Eiserloh's slides before committing.
- Use shake sparingly in co-op: a shake per player's own camera only, so a hit on someone else does not shake everyone's screen.

### Gaps
- No verified shake magnitude in pixels or degrees, decay time, or FOV-punch numbers.
- Controller rumble durations and strengths: no source gathered.
- The exact trauma formula from the Eiserloh talk: not confirmed (search returned photography pages).

## Audio and VFX

### Takeaway
No concrete numbers obtained this run. Layered impacts, pitch variation, and a distinct crit sound are standard practice, but there are no sourced figures to quote.

### Cited Findings
- None verified. Searches on audio layering and pitch variation were not run separately in this pass.

### Inferences
- Layered impact sounds: one body-hit layer, one material layer (stone, flesh, metal), and one tail layer, with random pitch per play. Keep crit sound distinct in pitch register and timbre.
- Damage numbers: colour by hit type, bigger text for crits. No sourced palette.

### Gaps
- Audio layer counts, pitch ranges, and volume tables: no source.
- Spark, blood, decal, and damage-number colours and sizes: no source.

## Poise, posture, stagger, stance-break

### Takeaway
Two dominant models: a visible posture bar that refills over time (Sekiro) and a hidden poise pool that resets after a quiet period (Elden Ring). Hidden poise with a long regeneration delay is the easier one to tune for co-op because it rarely needs UI, and hyperarmor is a separate per-action flag.

### Cited Findings
- Elden Ring player poise: poise damage per attack is subtracted; at zero you stagger and poise resets. Poise regenerates only after 30 seconds without being hit. Breakpoints: 51 poise survives one normal attack; 101 survives two. Source: [Fextralife Elden Ring Stance page](https://eldenring.wiki.gg/wiki/Stance) (fetched; note the page is eldenring.wiki.gg; the 30-second figure is also on [Fextralife Poise](https://eldenring.wiki.fextralife.com/poise) per search summary). Player reports conflict: some players staggered with 100 poise (search comment); DualShockers says nearly every melee attack deals over 50 poise damage to the player. Source: [DualShockers search result](https://www.dualshockers.com/what-does-poise-do-in-elden-ring) (search snippet)
- Elden Ring enemy poise: hidden meter 15 to 65 for normal enemies, 80 to 120 for most bosses. Regeneration starts after a delay equal to base poise divided by 13, then restores 13 poise per second (65 poise: 5 s delay; 120 poise: 9.2 s). Source: [Fextralife Elden Ring Stance page](https://eldenring.wiki.gg/wiki/Stance) (fetched). Outliers: Radahn 200 poise, 15.4 s delay; Night's Cavalry takes 20% poise damage. Source: same page.
- Elden Ring hyperarmor: extra poise during part of certain actions; super armor ignores poise for the action. Source: same page.
- Sekiro posture (fetched from Fextralife wiki): no recovery delay on enemy posture; if the player does not Deathblow within "a few seconds" of full posture, the enemy recovers a small portion. Bosses need posture depleted once per health bar (search summary). Source: [Fextralife Sekiro Posture](https://sekiroshadowsdietwice.wiki.fextralife.com/Posture) (fetched); [Samurai Gamers posture system](https://samurai-gamers.com/sekiro-shadows-die-twice/posture-system/) (search)
- Sekiro player posture: recovery begins after about 1 second without posture damage; cannot recover while attacking, sprinting, grappling, or staggered. Recovery rate by Vitality: 100 to 75% = 100%; 75 to 50% = 66%; 50 to 25% = 33%; 25 to 0% = 1%. Source: [Fextralife Sekiro Posture](https://sekiroshadowsdietwice.wiki.fextralife.com/Posture) (fetched)
- Sekiro: while posture is broken, incoming attacks do significantly more damage. Posture gauge rises from deflects; deflects against a regular attack cannot break the player. Source: [Fextralife Sekiro Posture](https://sekiroshadowsdietwice.wiki.fextralife.com/Posture) (fetched)
- Sekiro Prayer Beads: 10 upgrades of +30 posture each, max 420 (page states; base value not given). Source: same page.
- Nioh: Ki (stamina) bar is the stance equivalent; breaking Ki allows a grapple for heavy damage. Break stat varies by weapon type (axe and odachi high; sword and kusarigama lower). Source: [Fextralife Nioh 2 Break page](https://nioh2.wiki.fextralife.com/Break) and [Gamesradar Nioh 2 Ki Pulse](https://gamesradar.com/nioh-2-ki-pulse-guard-dodge-explained) (search snippets; no numbers obtained).

### Inferences
- Hidden poise with a regen delay (Elden Ring model) fits co-op: nothing extra on screen, and each enemy's pool is one number. Tune delay as poise / k (for example poise / 13 seconds) to get "stagger chains end" behaviour.
- A visible bar (Sekiro model) suits bosses or elite enemies where the player should see the break coming; players then plan for the deathblow window.
- Player poise: a Sekiro-style "not hit for about 1 second, then recover at a rate tied to health" rule is a good template for player stagger resistance.

### Gaps
- Monster Hunter's exact topple/flinch thresholds: no numeric source found.
- God of War stun meter values: no source found (search returned no result for it).
- Dark Souls 3 poise numbers beyond Elden Ring: not gathered.

## Criticals, riposte, backstab

### Takeaway
No sourced data this run on crit design. The usual reason for earned crits (a stagger or backstab opening) over random crit rolls is that the player can read and plan for them; this is from general design practice and is not cited.

### Cited Findings
- Elden Ring: most enemies have a weak spot where a light-attack riposte is a critical hit that knocks back and resets poise. Source: [Fextralife Elden Ring Stance page](https://eldenring.wiki.gg/wiki/Stance) (fetched)
- Sekiro: a Shinobi Deathblow is guaranteed once posture is full and the player acts within the window. Source: [Fextralife Sekiro Posture](https://sekiroshadowsdietwice.wiki.fextralife.com/Posture) (fetched)

### Inferences
- Guaranteed crits on stagger, backstab, or riposte are easy to teach: the game shows the opening, the player takes it. Random crit chance on normal hits adds noise without a clear skill signal. Recommended: use a crit only on a visible opening, and keep a small random chance only if the owner wants variety.

### Gaps
- No source found on how crit multipliers are chosen (typical values, for example 1.5x to 2x, are not sourced here).

## Co-op stun-lock prevention

### Takeaway
No direct source found on diminishing returns or per-player scaling in co-op melee. Mechanisms seen in the sourced games: poise regen delay (Elden Ring, 30 s), Sekiro's recovery-only-when-not-hit rule, and Smash's capped hitstop. Their combination is the most sourced way to limit chains.

### Cited Findings
- Elden Ring: poise regen needs 30 s without being hit, so repeated hits keep a target staggered. Source: [Fextralife Elden Ring Stance page](https://eldenring.wiki.gg/wiki/Stance) (fetched)
- Smash: hitstop cap of 20 or 30 frames limits freeze chains. Source: [SSBWiki Hitlag](https://ssbwiki.com/Hitlag)

### Inferences
- Stagger immunity window: after a stagger ends, the target gets a short window (for example 1 to 2 s) where it cannot be re-staggered by a non-crit hit, while still taking damage.
- Scale poise and stagger thresholds with the number of players (more players = more total hits): the number is a design choice, not sourced here.

### Gaps
- No sourced multiplayer scaling numbers. Recommended: test with the owner in a 2 to 4 player session.

## Source quality notes
- Strongest sources: Fextralife/eldenring.wiki.gg poise and posture pages (fetched; community wiki, verify against patch notes; Elden Ring patch 1.1.0 changed poise per the search summary), SSBWiki Hitlag (fetched; community wiki, but detailed formulas).
- Weak sources: Steam forum posts (Monster Hunter), itch.io devlogs (Vlambeer recreation), Smashboards tool threads.
- Could not access: GDC Vault talk contents (Eiserloh, Vlambeer, Jonasson/Purho), Sakurai's hitstop videos, GMTK videos, Game Developer article full text on hitstop. A later pass should fetch the GDC slides or transcripts directly, and find a Sakurai or GMTK transcript.
- Fextralife Sekiro posture page at the fandom mirror returned HTTP 402; the working URL was sekiroshadowsdietwice.wiki.fextralife.com.
