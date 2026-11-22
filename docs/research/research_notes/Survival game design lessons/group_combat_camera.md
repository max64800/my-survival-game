# Group combat, enemy packs, third-person camera for a short character, and sprint feel

Scope: attack limits for enemy groups, off-screen attack warnings, pack design, third-person camera rules, sprint acceleration. Already covered in `docs/research/research_notes/Godot and game design lessons/combat_and_movement_feel.md` and not repeated: telegraph length (Dark Souls 3 340 ms floor), dodge i-frames, boss co-op scaling, Celeste and Titanfall 2 movement, hit-stop. About 15 tool calls used. Several sources are developer blogs or search snippets. Two fetches were blocked by the tool's domain check and were re-read through another fetch tool. One source (StraySpark, 2026) is a vendor blog that sells an AI toolkit, so its numbers are examples, not standards.

## 1. Attack tokens: how many enemies may attack at once

### Takeaway
The best-documented shipped example is DOOM (2016): each attack type has a limited pool of tokens, and a demon must hold a token before it attacks and gives it back when the attack ends. No source found gives DOOM's actual token counts. The useful rule from every source is: cap attackers per target per attack type, let the rest keep pressure, and give each player their own pool in co-op.

### Cited Findings
- DOOM (2016) token system, as described by a secondary article: "every attack type has a limited number of tokens available at any moment. A demon that wants to attack must request a token first, then release it when the attack ends." Naughty Dog is said to use the same idea for melee in The Last of Us Part II. — [StraySpark, UE5 attack-token article (2026, vendor blog)](https://www.strayspark.studio/blog/attack-token-system-ue5-group-combat-that-feels-fair) (fetched)
- Token counts change with difficulty in DOOM, per a 2026 secondary article that cites the GDC talks. No count is given. — [Only Trusted Finds, "Why Game Enemies Attack One at a Time"](https://onlytrustedfinds.com/articles/why-do-game-enemies-attack-one-at-a-time) (search snippet; secondary; "studios rarely publish their exact engagement parameters")
- Example defaults from a UE5 write-up (labelled by its author as a starting point, not a shipped game): melee 1, ranged 2, heavy 1 per target, plus one global aggression multiplier. — [StraySpark](https://www.strayspark.studio/blog/attack-token-system-ue5-group-combat-that-feels-fair) (fetched; example values, not sourced to a game)
- Per-target keying: "In co-op, two players are two independent pools — enemies attacking player A never starve the enemies attacking player B." — [StraySpark](https://www.strayspark.studio/blog/attack-token-system-ue5-group-combat-that-feels-fair) (fetched)
- Claim before commit: a state should claim its token on entry, not halfway through the wind-up, or the attack must be cancelled after the animation has played. — [StraySpark](https://www.strayspark.studio/blog/attack-token-system-ue5-group-combat-that-feels-fair) (fetched)
- Tokens must be released on attack end, death and unpossess, with a periodic audit; a leaked pool means enemies that never attack again. — [StraySpark](https://www.strayspark.studio/blog/attack-token-system-ue5-group-combat-that-feels-fair) (fetched)
- Tokens fix timing, not space. Eight enemies with one melee token still stack on the same point unless there are separate slots around the target. — [StraySpark](https://www.strayspark.studio/blog/attack-token-system-ue5-group-combat-that-feels-fair) (fetched)
- The Last of Us Part II (Naughty Dog, GDC 2021, Ming-Lun Chou): "strafe slots" are spokes around the player. Each spoke is a valid attack position, and one NPC can stand on each. Slot validity is rechecked as the player moves. In the Chinese write-up, the level uses 16 lines radiating from the player. — [GameLook.com.cn write-up of the GDC talk, 2021](http://www.gamelook.com.cn/2021/08/449210/) (search snippet, Chinese; the 16-line figure is from this source only)
- TLOU2 melee: each NPC is in one "melee behaviour" at a time, which holds its allowed attacks and a destination (run up, or keep a set distance). Attacks have start conditions (in range, facing, clear line of motion) and events on the timeline (hit frames, tracking, invincible frames). — [Game Developer, Naughty Dog melee write-up, 2021](https://www.gamedeveloper.com/design/how-naughty-dog-defined-melee-attacks-and-behaviors-in-i-the-last-of-us-part-ii-i-) (search snippet with full quote)
- TLOU2: when the player dodges, the enemy's target tracking turns off, so the enemy that missed "appears more dumbfounded by the dodge." — [AI and Games #70 video analysis, 2023](https://www.youtube.com/watch?v=BghECmeLda0) (search snippet; the video's own transcript)
- TLOU2 wall probes: 8 rays, in two sets of 4 (high and low), to see whether a wall behind the player is low or high. — [AI and Games #70](https://www.youtube.com/watch?v=BghECmeLda0) (search snippet)
- Attack concurrency is decided before each attack, in the "Assignment of Attacker Role" step. StraySpark claims a player "can track roughly one incoming melee attack and a couple of ranged shots at a time," but cites no study. — [Signals and Light, part 5](https://signalsandlight.substack.com/p/how-do-simultaneous-enemy-attacks) (fetched); [StraySpark](https://www.strayspark.studio/blog/attack-token-system-ue5-group-combat-that-feels-fair) (fetched; unsourced claim)
- Signals and Light (2024): games either gate attacks with tickets (by attack type or strength, such as a heavy attack costing more tickets), or use no system and rely on "encounter and level design." Ranged and melee can use separate slot pools. Ticket systems are "often used in games with encounters that have between six or more active enemies." Souls games let a dozen enemies attack with few complaints, because the attack rules are clear. — [Signals and Light, part 5 (2024)](https://signalsandlight.substack.com/p/how-do-simultaneous-enemy-attacks) (fetched)
- Batman Arkham: thugs approach in large groups but attack one at a time, and a blue indicator above an attacker's head signals the incoming hit. Arkham City added simultaneous counters for two or three attackers. — [Only Trusted Finds](https://onlytrustedfinds.com/articles/why-do-game-enemies-attack-one-at-a-time) (search snippet; secondary; the blue-indicator claim is cited there to a source not read); [Siliconera, Rocksteady Q&A, 2011](https://www.siliconera.com/the-improvements-to-batman-arkham-citys-combat-system/) (search snippet; quote from Rocksteady)
- Freeflow: "you're generally attacking one enemy at a time, but you can rapidly move between enemies across the entire encounter." — [Reddit r/truegaming, 2026](https://www.reddit.com/r/truegaming/comments/1wh1qgl/there_is_more_to_the_freeflow_combat_system/) (search snippet; community)
- Batman's combo drops after about 1 second with no input (Freeflow Fandom wiki). — [Arkham Wiki, Freeflow Combat](https://arkhamcity.fandom.com/wiki/Freeflow_Combat) (search snippet; wiki)

### Inferences (for our game)
- Give each attack category its own pool per player, not one shared pool: skeleton melee (about 1 to 2 per player), beetle or bat swarm contact (a separate pool, so they can pile on a bit more), and boss heavy attacks (1 at a time). Our existing research notes already say that boss chaining is the main problem, which fits a heavy-attack pool of 1.
- Each player needs their own pool. With 4 players and a tokens-per-player rule, enemies attack the one closest to them and do not all spend on the same dwarf.
- Enemies without a token should keep moving: strafe, reposition, or wait at a slot. They must not stand still.
- Release tokens on death, on stun, on the player's dodge, and on a timer, so a stuck pool cannot lock out attacks. Add a debug counter that shows tokens held per player.
- Slots: place 6 to 8 slots around each dwarf (an estimate based on the spoke idea, not a sourced number) so packs spread out. Check that pack members don't stack into each other, which the StraySpark article flags as the main failure.
- Co-op: keep the number of tokens the same per player. Do not scale the number of attackers with player count. Count one pool per dwarf.

### Gaps
- No actual DOOM token numbers were found. No primary GDC talk text or slides were read. The GDC Vault talk "Embracing Push Forward Combat in DOOM" (2018) is listed but not read.
- No source found for Assassin's Creed or God of War attacker limits, or for Hades or Sifu. No cooldown values found.
- Wait behaviour (how enemies circle while waiting) is described only as "strafe, advance, reposition, take cover" in one blog. No source with frame or second values.
- Off-screen warning rules (see section 2) and audio cue timing: not researched beyond the notes below.

## 2. Off-screen and behind-the-player attack warnings, and pack composition

### Takeaway
The sources agree on a few tools: arrow or indicator UI for attacks from off-screen (God of War uses colour coding), a visible indicator over the attacker (Batman Arkham), and a rule that only a few enemies attack at once so the player can see each attack. No source gave timing numbers for audio cues.

### Cited Findings
- God of War (2018): arrow indicators show the direction and type of incoming attack: white for an attack from behind, red for melee, purple for ranged. — [Digital Trends guide](https://www.digitaltrends.com/gaming/god-of-war-combat-guide/) and [PlayStation Blog](https://blog.playstation.com/?p=370399) (search snippets from the previous research notes; not re-read this session)
- Batman Arkham Asylum: the blue indicator above an attacker signals its hit. — [Only Trusted Finds](https://onlytrustedfinds.com/articles/why-do-game-enemies-attack-one-at-a-time) (search snippet; secondary)
- Arkham games: the prompt for a counter disappears once the input is registered, so the player knows they no longer need to respond. — [Cluttered Mind, "Game Anatomy: FreeFlow Combat" (2017)](https://clutteredmind.wordpress.com/2017/11/19/game-anatomy-freeflow-combat/) (search snippet)
- TLOU2: enemy attack tells were lengthened versus Uncharted 4, and the player can now dodge. — [Game Developer, Naughty Dog melee write-up](https://www.gamedeveloper.com/design/how-naughty-dog-defined-melee-attacks-and-behaviors-in-i-the-last-of-us-part-ii-i-) (search snippet with full quote)
- Pack mix: "Sometimes ranged attackers and melee attackers don't use tickets in the same reservation slots, allowing a fixed number of both to harry the player simultaneously." — [Signals and Light, part 5](https://signalsandlight.substack.com/p/how-do-simultaneous-enemy-attacks) (fetched)
- Doom Eternal (weapon side of "push forward"): each weapon has a specific role, for example the arbalist for flying enemies. This is about the player's tools, not enemy packs. — [Game Developer, Josh Bycer, "Pushing Push Forward Combat"](https://www.gamedeveloper.com/game-platforms/pushing-push-forward-combat-with-gameplay) (fetched; blogger, not a developer)
- Left 4 Dead 2 AI Director manages attack concurrency and timing based on player "stress," per an essay's reading of Valve's explanations (not read directly). — [Signals and Light, part 5](https://signalsandlight.substack.com/p/how-do-simultaneous-enemy-attacks) (fetched; secondary)

### Inferences (for our game)
- Off-screen attacks: a small arrow at the screen edge, coloured by attack type (melee red, ranged purple, behind white, as God of War does), and a short pulse of the dwarf's own sound. These are cheap and proven.
- A visible indicator above each attacker that is about to hit (Batman's blue mark) suits the beetle and skeleton packs, which are small and hard to see.
- Pack mix that matches the token rule: one or two melee skeletons per dwarf, plus one ranged (for example, a bat or skeleton archer) with its own pool, and a tank or heavy that holds the heavy-attack token. Keep swarms (beetles, bats) as crowd pressure that does not spend melee tokens, but they still need a visible tell.
- Rule: nothing spawns directly behind the camera on a fresh engage. Spawn packs in front of the dwarf and let them wrap around over time.
- The owner's "can't see attacks from behind or below" complaint is answered by the indicator and by the camera fix (section 3), not only by audio.

### Gaps
- No source for audio cue timing or volume rules for off-screen attacks. Not researched.
- No source for enemy spacing numbers (metres between pack members).
- God of War and Batman indicator claims come from snippets and were not re-checked against the games.

## 3. Third-person camera: height and distance for a short character

### Takeaway
No source found for a third-person camera tuned for a dwarf-sized character, and no Return to Moria review judged its camera height. The general rules that do have sources: a camera that pulls in close when looking up and out when looking down, a spring arm that pulls the camera toward the player when rock blocks the view, and a designer's warning that "dynamic third-person cameras are the hardest to design" (Nesky). For our fix, the height and distance numbers must be tuned in the game.

### Cited Findings
- John Nesky (Journey camera designer), GDC 2014 "50 Camera Mistakes": "Dynamic third-person cameras are the hardest to design," and the camera should turn the way the player wants. — [Vice, "Lights, camera, distraction"](https://www.vice.com/en/article/lights-camera-distraction-the-problem-with-virtual-camera-systems) (search snippet, quoting Nesky); talk page: [GDC Vault, "50 Camera"](https://gdcvault.com/play/1020460/50-Camera) (listed, not read)
- Framing model (Max Kaufmann, Little Polygon, 2023): a camera has five parameters: tracking position, 2D screen framing of the player, distance, pitch, yaw. Framing places the player in the screen (for example, bottom third when looking across). Platformer rule: "come in close when looking up and pull far out when looking down." Over-the-shoulder shifts framing sideways. — [Little Polygon, Third Person Cameras](https://blog.littlepolygon.com/posts/cameras/) (fetched)
- Little Polygon also says tracking should not follow every bump; a low-pass or spring smooth is the normal fix, and on Solar Ash the team projected the player onto the ground for tracking so jumps don't move the camera. — [Little Polygon](https://blog.littlepolygon.com/posts/cameras/) (fetched)
- Little Polygon: a counter-framing trick (player on the opposite side from the aim) gives more screen to see targets; in Tiny Starpilot. — [Little Polygon](https://blog.littlepolygon.com/posts/cameras/) (fetched)
- Unreal Engine (Nick Pruehs, 2018): the spring arm "will automatically pull the camera closer to the character in order to keep line of sight" when an obstacle blocks it. The team also says "ensure that line of sight between camera and player character is never occluded by level obstacles," and that the player can always override the dynamic camera. — [Unreal Engine tech blog, "Six Ingredients for a Dynamic Third Person Camera"](https://www.unrealengine.com/tech-blog/six-ingredients-for-a-dynamic-third-person-camera) (search snippet)
- Unreal's team also changed camera distance and field of view by pitch angle, using a curve asset. — [same](https://www.unrealengine.com/tech-blog/six-ingredients-for-a-dynamic-third-person-camera) (search snippet)
- Camera lag ("rubber band") in Unreal: a short delay before the camera follows after the player starts moving, and a delay before it stops. Speeds are set in the spring arm. — [same](https://www.unrealengine.com/tech-blog/six-ingredients-for-a-dynamic-third-person-camera) (search snippet)
- Ratchet & Clank style: over-the-shoulder, following the player, with "raycasting to have the camera detect and avoid obstacles." — [Unity Discussions, Ratchet & Clank camera](https://discussions.unity.com/t/ratchet-and-clank-3rd-person-camera-tutorial/602529) (search snippet; forum)
- Return to Moria: the official FAQ and Common Sense Media say the game is third person. Combat is in third person, and players "dodge out the way of enemy attacks" (Epic store news). No review found that judges camera height against dwarf size. — [Epic Games Store news](https://store.epicgames.com/news/the-lord-of-the-rings-return-to-moria-is-a-story-heavy-take-on-drunken-dwarven-exploration-and-crafting) and [Common Sense Media](https://www.commonsensemedia.org/game-reviews/the-lord-of-the-rings-return-to-moria) (search snippets)

### Inferences (for our game)
- Lower the camera's aim point to the dwarf's head or chest height, and bring the camera closer (distance is a parameter to tune; test a pull-in from the current value in steps). This is the core of the "camera too high" complaint. Use the framing model: put the dwarf in the lower third, so more of the cave ahead is visible.
- Pitch by movement: look down a bit more when moving toward small enemies on the floor, so beetles and attacks near the feet are on screen. The Little Polygon rule says pull out when looking down, so use a separate, small pitch-based distance curve (Unreal's approach) rather than a single distance.
- Caves: use a spring arm (or a raycast from the pivot to the camera) that pulls the camera toward the dwarf when rock blocks the view. Unreal's rule that line of sight must never be blocked is the target. Add a fade or dither on rock that sits between the camera and the dwarf, rather than a hard cut. The fade style itself is not sourced here.
- Enemy visibility: when a fight starts, widen the framing so the pack and its indicators stay on screen, then return to the normal framing afterwards.
- Lock-on: no source found for lock-on design in this session.
- Keep camera lag low (short delay) for the dwarf. Long lag hides attacks coming from behind.

### Gaps
- No source for dwarf-scale camera height, distance, or FOV in cm or degrees. No source for an actual short-character camera in Valheim, Ratchet & Clank, or Return to Moria. The Return to Moria review snippets did not discuss the camera.
- No source for transparency or dithering of rock in tight spaces (only the Unreal "line of sight" rule).
- No source for over-the-shoulder offset values.
- No source for lock-on design rules.
- Nesky's 50-mistakes list was not read (the GDC Vault and YouTube pages were listed only).

## 4. Sprint, acceleration, turning, FOV, and stamina

### Takeaway
Sources agree that acceleration is a feel setting, not a single right number. Responsive acceleration can feel good for twitch play but too fast for casual players (Darcey). One game (Echo Point Nova) used a slow build to top speed on purpose. Sprint can add a small FOV widening, and sprint stamina varies a lot (Apex has none, Dark Souls III uses a constant drain). No source gave tested ramp times for a heavy character.

### Cited Findings
- Acceleration tuning: "Having drag on your character can be really engaging; forcing players to analyze the environment more closely and plan their next move." And "there is such a thing as 'too responsive'... a super high acceleration value might make them feel out of control." Halo 1 had low acceleration, Halo 2 high, Halo 5 moved toward Halo 2's value. — [Gamasutra/Game Developer, Ryan Darcey, "Analyzing Core Character Movement in 3D" (2016)](https://gamedeveloper.com/design/analyzing-core-character-movement-in-3d) (fetched)
- Darcey's advice: keep a history of acceleration values and graph them over time when tuning, and read them in screen space rather than world space. — [same](https://gamedeveloper.com/design/analyzing-core-character-movement-in-3d) (fetched)
- Echo Point Nova (Matt Larrabee, 2024): "typically, a player hits their max walk speed quickly, but a hoverboard takes a few seconds of holding forward to hit top speed." Walking physics are used with friction and deceleration disabled. — [Game Developer deep dive, 2024](https://gamedeveloper.com/design/deep-dive-the-movement-of-echo-point-nova) (fetched)
- Echo Point Nova (search snippet, not in the fetched part): the faster the player moves, the wider the FOV. A thesis on maneuverability lists speed lines and wide FOV as ways to sell speed. A forum thread says most games slightly increase FOV while sprinting. — [Game Developer deep dive](https://gamedeveloper.com/design/deep-dive-the-movement-of-echo-point-nova) (search snippet); [Game Developer, maneuverability essay](https://gamedeveloper.com/design/maneuverability-in-games-the-importance-of-speed-and-control) (search snippet, not read)
- Acceleration tuning in a developer thesis: an instantly maxing "stiff" curve does not make movement more precise than a gradual one. Super Meat Boy keeps a somewhat long curve and still turns easily thanks to light weight and high acceleration. — [Fiction Horizon, "20 Games With Perfectly Tuned Sprinting"](https://fictionhorizon.com/games-with-perfectly-tuned-sprinting/) (search snippet; aggregator, secondary)
- Stamina designs: Apex has no sprint stamina bar; Dark Souls III uses a stamina drain at a constant rate that matches rolls and attacks; Mass Effect 3 removed the sprint bar. Critics say open-world sprint meters are tied to stamina used for other things too. — [Fiction Horizon](https://fictionhorizon.com/games-with-perfectly-tuned-sprinting/) (search snippet; aggregator)
- A sample design spec (author and game not identified in the snippet): a 2-second ramp to max speed, 5 stamina to start sprinting, and no stamina regeneration during sprint. — [Fiction Horizon](https://fictionhorizon.com/games-with-perfectly-tuned-sprinting/) (search snippet; source is not a named developer, so treat as an example only)
- Developer tip: define sprint as a multiplier on the default speed, not a separate fixed acceleration value. Tween the speed value rather than setting it in one frame. — [Unity Discussions](https://discussions.unity.com/t/whats-a-good-way-to-slow-turning-speed-in-an-fps-when-running/840047) and [DevForum](https://devforum.roblox.com/t/how-can-i-make-sprint-more-realistic/2030661) (search snippets; forums)
- Titanfall 2 (already in the earlier note): sprint plus crouch starts a slide with a small speed boost; the slide cannot turn as easily. The designers said a speed boost gives players a reason to use a move. — [Game Developer, Titanfall 2 interview](https://www.gamedeveloper.com/design/designer-interview-getting-i-titanfall-i-s-controls-just-right) (fetched earlier; in the other note)

### Inferences (for our game)
- Walk-to-run ramp for a heavy dwarf: use a short tween to top speed, not an instant jump. Echo Point Nova's "a few seconds" is a clear upper example for a hoverboard; for a dwarf the number should sit between an instant start and a few seconds. A starting test range is 0.3 to 0.6 s to full sprint speed (a guess, not sourced), tuned in the game.
- Turning: slow the turn rate while sprinting, the way Titanfall 2 slides cannot turn as easily. This is a feel rule supported by the Titanfall note and the Darcey "drag" point.
- Deceleration on stop: a short slide-down, not an instant stop, fits a heavy body. Check that the slide does not break the melee timing (already flagged in the other note).
- FOV: a small widening while sprinting (a few degrees, to be tested) is cheap and common. Keep it small, because the camera-height fix already changes the view.
- Stamina: one shared pool for sprint, roll and attack (the Dark Souls III model) keeps the owner's "dodge is always there" rule simple. Sprint should not drain the roll pool, or co-op players will run out at bad times.
- Graph acceleration values in the debug overlay (Darcey) when tuning, so the feel can be compared between builds.

### Gaps
- No source with a tested acceleration curve, turn-rate number, or sprint ramp time for any game.
- No source for FOV kick values in degrees.
- No source for stamina numbers (drain per second, regen delay) from a named developer.
- No source for co-op sprint or stamina sharing.
- Maneuverability essay and Echo Point Nova FOV claim were not read in full.

## Source-quality warning
- StraySpark (2026) is a vendor blog that sells an AI toolkit. Its token pattern matches other sources, but its numbers are examples.
- Fiction Horizon and Only Trusted Finds are aggregators. Treat their claims as leads.
- Several search-snippet sources (Vice, Digital Trends, Unreal blog, GameLook) were not fetched in full. Quotes are as shown in search results.
- The fetch tool blocked the strayspark.studio, gamedeveloper.com and substack domains through the normal fetch tool. The same URLs were read through another fetch tool.
- No DOOM token numbers, no Nesky mistake list, and no dwarf-scale camera values were confirmed. These are the most important gaps for the owner's camera complaint.

## Overall gaps (next research round)
- Read the GDC Vault talk "Embracing Push Forward Combat in DOOM" (2018) or a transcript for token counts.
- Read the Naughty Dog GDC 2021 talk (Ming-Lun Chou) for slot and behaviour numbers, if a slide deck or transcript is found.
- Read the GDC 2014 "50 Camera Mistakes" slides for specific camera rules.
- Search for a Dark Souls or Elden Ring lock-on camera write-up, and for a short-character third-person game (for example, Ratchet & Clank or a hobbit game) camera write-up with numbers.
- Test our own camera and sprint values in the game, using the debug graph, since no source gives dwarf-scale numbers.
