# Combat and movement feel for a third-person melee dwarf survival game

Scope: telegraphing, fair bosses, movement feel, dodge invincibility. Hit feedback (hit-stop, shake, stagger meters) is already covered in `docs/research/Melee hit feedback design.md` and is not repeated here, except where a point adds to it. Research budget used: about 15 tool calls. Several sources are search snippets or community wikis; each is marked.

## Combat telegraphing: how long an enemy's warning must be

### Takeaway
The best-sourced number is a floor: in Dark Souls 3, an enemy's visible "attack signal" plus its attack must last at least 340 ms, and the player's own reaction chain (perceive, decide, press) takes roughly 240 ms. Enemy attacks in our game need a wind-up that is clearly longer than that, and the owner's "no wind-up" complaint says we are far below it today.

### Cited Findings
- Dark Souls 3 attack phases: "Attack Signal and Attack together need to have a guaranteed duration of at least 340ms." Some enemy moves fall below this (the first Hollow at the High Wall of Lothric is the example given). "End Pose as bait: the duration must be at least 240ms." "End Pose before Return: the duration must be at least 170ms for the player to confirm the end of this attack." — [Anatomy of an Enemy Attack in Dark Souls 3, Game Developer](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3) (fetched; article analysis, not a developer post)
- The same article says the hitbox is "only active in 2-4 frames," and that hitboxes are often several times the size of the weapon model. The author calls this a clarity cost kept for the feeling of power. — [same article](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3) (fetched)
- Attack phases in that article are: opening pose, attack signal, attack (hitbox), end pose, return. The "Return" is the Window of Opportunity and is "generally the longest among the 5 phases." — [same article](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3) (fetched)
- Response-time model used in that article: perception about 100 ms (50 to 200 ms), cognition about 70 ms (30 to 100 ms), motor about 70 ms (25 to 170 ms), citing the Model Human Processor. Game-system delay: 50 to 100 ms "feels tight," above 100 ms is noticeable, around 200 ms feels sluggish (citing Mick West, via that article). — [same article](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3) (fetched)
- Design principles stated in that article: the opening pose's silhouette should suggest the coming attack and its weight; motion should carry the cue; each attack should leave time to react. Difficulty levers it lists: fewer Return phases, longer bait durations, shorter Return phases. — [same article](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3) (fetched)
- A Game Developer piece on enemy telegraphing uses the long sword-swing wind-up as its standard example, with animation and visual effects working together. — [enemy attacks and telegraphing, Game Developer](https://gamedeveloper.com/design/enemy-attacks-and-telegraphing) (search snippet only; not fetched)
- Some bosses use exaggerated wind-ups as fakeouts to punish early dodges; a follow-up attack then punishes the player. — [the art of the fakeout combat design, wayline.io](https://www.wayline.io/blog/the-art-of-the-fakeout-combat-design) (search snippet only; a blog, low authority)
- Monster Hunter Rise: GameSpot says many of the most damaging attacks, mostly tail moves, have a lengthy wind-up that makes them easy to dodge or block. — [GameSpot, Rise monster list](https://gamespot.com/articles/monster-hunter-rise-monster-list-and-how-to-kill-each-one/1100-6489304/) (search snippet only)
- Monster Hunter Wilds offset attacks: timing depends on your own attack's wind-up and the time the monster takes to slam or grab. A guide cites Quematrice's fire-breath sweep as having a clear telegraph and Congalala's belly slam a visible wind-up. — [Inverse](https://www.inverse.com/gaming/counter-monsters-with-offset-attacks-in-monster-hunter-wilds) and [Bossdown guide](https://bossdown.com/guides/monster-hunter-wilds-offset-attacks-guide/) (search snippets only)
- God of War (2018): player guides describe weak attacks being signalled through animation (for example, the enemy raising an arm before a sword swing). Arrow indicators show direction and type: white for an attack from behind, red for melee, purple for ranged. A PlayStation developer post says the camera position shaped how giant attacks were signalled. — [PlayStation Blog, GoW combat](https://blog.playstation.com/?p=370399) and [Digital Trends guide](https://www.digitaltrends.com/gaming/god-of-war-combat-guide/) (search snippets only; no frame numbers found)
- Souls-style telegraph definition (community): a wind-up timed so the player should dodge now; an attack that starts signalling long before the dodge is sensible is "excessively delayed." — [Steam discussion](https://steamcommunity.com/app/2407270/discussions/0/601900765808702898) (search snippet; community, not authoritative)

### Inferences
- Our enemy attacks should have a visible signal of at least about 340 ms (about 20 frames at 60 fps) before the damage window opens, following the Dark Souls 3 floor. Heavy attacks should be longer. This is a floor from one analysis, not a tested rule.
- The hit window itself can be very short (2 to 4 frames, about 33 to 67 ms at 60 fps). A short hit window with a long signal reads as fair; a long hit window with a short signal reads as unfair. Our rule should be the signal length, not the hit length.
- Silhouette and motion carry the cue. Audio cues are not covered in the sources found here.

### Gaps
- No frame-data source for Hades, Valheim, Sekiro or Elden Ring enemy wind-ups was fetched. The owner's named games were not checked for telegraph lengths.
- No source found for attack tokens (limits on how many enemies attack at once). Not researched this session.
- No source found for audio cue timing. Not researched this session.
- Monster Hunter's developers' own telegraph rules were not found; only player guides.

## Fair boss design and co-op scaling (1 to 4 players)

### Takeaway
No official FromSoftware or Funcom co-op boss scaling numbers were found. Community reports suggest that adding health per ally is common, with numbers like +50% per extra player (one Dark Souls forum post), and that bosses can feel too easy with 3 to 4 players. For our game, a per-monster immunity window that all players share is more useful than a player-count health multiplier, since the bosses' problem is chaining, not raw health.

### Cited Findings
- Dark Souls co-op (fan-reported in a forum post): one ally adds 50% boss health, two allies 100%, three allies 150%. — [Dark Souls forum via search](https://steamcommunity.com/app/211420/discussions/0/357288572113450185) (search snippet; the exact post is not confirmed; treat as community claim)
- Dark Souls Remastered: an extra summon-slot count "could push boss health" by up to 250% extra health, per a PC Gamer article flagging the risk. — [PC Gamer](https://www.pcgamer.com/dark-souls-remastereds-summon-count-could-create-op-bosses) (search snippet)
- Don't Starve Together community suggestion: three boss versions, one for 1 to 2 players, one for 3 to 4, one for 5 or more. Another suggestion: an explosion-type damage resistance that triggers on too much damage in a short time, avoiding player counts. — [Klei forum](https://forums.kleientertainment.com/forums/topic/169689-boss-multiplayer-difficulty-scaling/) and [Klei forum](https://kleiforums.com/forums/topic/142077-suggestion-enemies-health-or-boss-scaling-according-to-number-players/) (search snippets; community, not developer)
- Complaints go both ways: bosses "melt" with 4 players, and some reviewers found co-op easier than solo. — [Steam and forum threads via search](https://steamcommunity.com/app/1245620/discussions/0/3866958929506972135) (search snippets; community)
- Souls critics judge the genre by "tough, but fair." — [the design lessons designers fail to learn from dark souls, Game Developer](https://www.gamedeveloper.com/design/the-design-lessons-designers-fail-to-learn-from-dark-souls) (title only; article not fetched)
- Black Myth: Wukong's early boss is cited as a fair-fight design example in a UX article; not fetched. — [uxdesign.cc](https://uxdesign.cc/how-to-design-an-early-boss-fight-wandering-wight-boss-in-black-myth-wukong-6ec8408d06e0) (search snippet only)

### Inferences
- Scaling by player count is a known source of "too easy" and "too hard" complaints. A safer plan for our game is to scale boss health modestly (for example, not more than linearly per player, to be tested) and to scale the immunity and chain limits per monster, not per player.
- The owner's "boss too brutal" complaint is more likely about damage per hit and stun-chains than health. The sources support tuning the damage per hit and the number of hits between safe windows first.
- Fair-death principles in the sources: each attack shows its signal (see above), the player gets a Return/recovery window, and difficulty rises by shortening that window or lengthening bait, not by adding invisible damage.

### Gaps
- No official numbers for co-op boss scaling were found from any developer.
- No source for Elden Ring's multiplayer correction numbers was fetched (a wiki page exists: eldenring.wiki.gg/wiki/Multiplayer_Correction; not read).
- No phase-count or pattern-learning guidance was sourced for bosses (not researched this session).

## Movement feel: sprint, slide, wall run, jump forgiveness

### Takeaway
Only one movement source gave useful numbers this session: Celeste's developer gave pixel and frame details, and Titanfall 2's designers gave speed numbers but no frame counts. Most movement numbers (coyote time, jump buffer, slide length) come from community sources and need testing in our game.

### Cited Findings
- Celeste, Maddy Thorson's article: coyote time is "a short time" with no number given; jump buffering is "a short time before landing" with no number given. — [Celeste & Forgiveness](https://maddymakesgames.com/articles/celeste_and_forgiveness/) (fetched)
- Celeste: "the top of your jump has half gravity applied," a 50% gravity cut at the jump peak. — [same article](https://maddymakesgames.com/articles/celeste_and_forgiveness/) (fetched)
- Celeste: a wall jump works "2 pixels from a wall," and the super wall jump is about "5 pixels" (on a 320x180 game where a quarter tile is the unit). — [same article](https://maddymakesgames.com/articles/celeste_and_forgiveness/) (fetched)
- Celeste: momentum from a moving platform is stored, and "still get a boosted jump for a few frames after the platform has stopped moving" (no frame count). — [same article](https://maddymakesgames.com/articles/celeste_and_forgiveness/) (fetched)
- Community wiki and review (unverified): coyote-style air jump after leaving a ledge lasts 5 frames. — [GameRant](https://gamerant.com/celeste-coyote-time-mechanic-platforming-impact-hidden-mechanics/) (search snippet; secondary)
- Titanfall 2 designers: wall-run starts by jumping into a wall, gives a speed boost, and the view tilts away from the wall; tilting toward the wall before the run helps the player anticipate it. — [Game Developer, Titanfall 2 controls interview](https://www.gamedeveloper.com/design/designer-interview-getting-i-titanfall-i-s-controls-just-right) (fetched)
- Titanfall 2 slide: triggered by crouch while sprinting; a small speed boost at start; otherwise like ground movement but you cannot stop or turn as easily. Allows slide-hopping. In first person the gun cants down about 45 degrees during a slide. — [same](https://www.gamedeveloper.com/design/designer-interview-getting-i-titanfall-i-s-controls-just-right) (fetched)
- Titanfall 2: players did not trust the wall-run and jumped off too early; training sections and enforced early wall runs fixed this. The speed boost gave a reason to use it. — [same](https://www.gamedeveloper.com/design/designer-interview-getting-i-titanfall-i-s-controls-just-right) (fetched)
- Titanfall 2 motion comfort: head bob without a fixed crosshair caused nausea for some players. After a long fall the view springs back, with spring depth scaling with fall height. A small view bob on shooting was added. — [same](https://www.gamedeveloper.com/design/designer-interview-getting-i-titanfall-i-s-controls-just-right) (fetched)
- Titanfall 2 top speed with acrobatics: about 30 mph, "well over double a pilot's sprint speed." No frame or percentage values given. — [same](https://www.gamedeveloper.com/design/designer-interview-getting-i-titanfall-i-s-controls-just-right) (fetched)
- Mirror's Edge: a GDC talk, "Creating First Person Movement for Mirror's Edge" (Tobias Dahl, Mikael Lagre, DICE), is listed on GDC Vault, but its content was not read. — [GDC Vault](https://gdcvault.com/play/1012171/contactUs) (search listing only; no content)

### Inferences
- Jump forgiveness is cheap and clearly valuable: Celeste's designer chose forgiveness over a strict rule. Start with a short coyote window and jump buffer in the few-frame range, then test. The sources give no exact frames for our case.
- Titanfall 2's rule that a speed boost rewards using a move is a good model for our sprint ramp-up, dash and slide: each new move should give a small, visible speed or reward so players choose it.
- Slide that cannot change direction, plus a short start boost, fits a dwarf's heavy body. Check that a slide does not defeat the melee attack timing.
- A view tilt toward a wall before a wall run, and a spring after a long fall, are both cheap feel tools that the Titanfall 2 designers used.

### Gaps
- No source for acceleration curves, sprint ramp-up times, or dash distance.
- No source for FOV kick values or camera height for short characters.
- No source for root motion vs code motion trade-offs (not researched this session).
- No source for climbing or crouch numbers.
- Mirror's Edge GDC talk content not read.

## Invincibility frames on dodge

### Takeaway
Souls-series dodge invincibility runs about 9 to 15 frames depending on roll type, counted at 30 frames per second in the wiki convention. One Dark Souls 3 analysis gives 433 ms for a medium roll, which is about 13 frames at 30 fps. Use the start-of-animation rule and make it a tuning number, since sources disagree.

### Cited Findings
- Fextralife: invincibility frames are measured in 1/30 second. Dark Souls 1 i-frames: 9 (slow roll), 11 (medium), 13 (fast), 15 (with Dark Wood Grain Ring). — [Fextralife via search](https://darksouls2.wiki.fextralife.com/Agility) and wiki snippets (secondary; unverified against the game)
- Dark Souls Fandom wiki: 11 i-frames for the 100% fat roll, then 9 recovery frames. Its Dark Souls 2 page lists the Dark Wood Grain Ring roll at 13 i-frames, while Fextralife says 15 (conflict noted, not resolved). — [Dark Souls Wiki, Rolling](https://darksouls.fandom.com/wiki/Rolling) (search snippet; the two wikis disagree)
- Fandom notes "Instability Frames" are the roll's vulnerable frames, where a hit does 1.4x damage. A player post adds that enemy attacks cannot touch you until you hit the ground. — [Dark Souls Wiki, Rolling](https://darksouls.fandom.com/wiki/Rolling) (search snippet; community)
- Dark Souls 3 analysis: roll invincibility is active from the first frame and lasts 433 ms (medium roll). — [Anatomy of an Enemy Attack in Dark Souls 3](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3) (fetched)
- Dark Souls 3 forum claim (unverified): 13 i-frames for a normal roll, 12 for a fat roll. — [Steam discussion](https://steamcommunity.com/app/211420/discussions/0/1471966894871183628) (search snippet; community; not checked)

### Inferences
- A starting value of about 10 to 13 frames at 60 fps is inside the range of the sources. Note that the wiki frames were counted at 30 fps, so the same frame count lasts half as long at 60 fps (for example, 13 frames is about 433 ms at 30 fps but about 217 ms at 60 fps). Convert to milliseconds before copying a number; 433 ms is the one reference that is stated directly in a source.
- Give the dodge its i-frames from the first animation frame, as the Dark Souls 3 analysis describes, so a dodge read at the signal always works.
- Instability frames at the end of a roll (taking extra damage) are a second, cheap difficulty lever for bosses.

### Gaps
- No Dark Souls 3 official frame data was confirmed.
- No source for dash or slide i-frames.
- No source for co-op interaction with dodge timing.

## Hit-stop and feedback addenda (not in the earlier note)
- Monster Hunter Wilds: the director said hitstop was adjusted after beta feedback that players missed the hitstop of past games, and that it was partly reduced to match Monster Hunter: World players, who called it sluggish. Frame values were not found. — [PC Gamer](https://pcgamer.com/games/rpg/monster-hunter-wilds-game-director-says-the-betas-missing-hitstop-has-already-been-tweaked-thanks-to-very-positive-feedback-from-hitstop-hungry-veteran-hunters) (search snippet). Note: the PC Gamer article "Capcom, if you're listening: Monster Hunter Wilds needs its hitstop back" could not be read (fetch returned only navigation).
- Inference: this is a direct example of a game dropping hit-stop after hitting a feel problem with players, then returning it. It supports keeping hit-stop as a per-attack setting rather than one global value.

## Source-quality warning
Several links above point to a search results page or a wiki index, not to the exact post that made the claim (the Dark Souls co-op percentages, the Dark Souls 3 roll-frame forum claim, and the Dark Souls 1 i-frame list are the main cases). Treat those numbers as leads to verify in the game, not as settings to copy.

## Overall gaps
- No Hades, Valheim, God of War frame data; only qualitative sources.
- No source for attack tokens, audio cue timing, FOV kick, camera height, acceleration curves, sprint ramp times, climbing, root motion, or crouch.
- Sources were mostly secondary (articles about developers, wikis and forums). Only the Dark Souls 3 analysis, Celeste article and Titanfall 2 interview were fetched in full. Everything else is a search snippet.
