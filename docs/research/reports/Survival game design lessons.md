# Reliable joins and readable fights win players

## In plain words

**Players**
- Friends are the big reason people love these games. In the reviews we checked, "play with friends" was the top praise in most of them.
- Bad connections are the top complaint. A friend who cannot join, or gets kicked out, leaves a bad review.
- Long early access with slow updates makes players angry. Fast, honest updates calm them down.
- Shared progress feels unfair. Each dwarf should have its own rewards, even in a shared cave.
- A solo player needs a fair path. Deep Rock Galactic's helper character Bosco is praised for this.
- Games go stale when the only change is bigger numbers. Each new area should bring a new trick.

**Fights and enemies**
- Too many enemies hitting at once is confusing. Give each dwarf a small number of "attack tickets" (a limit on how many enemies may attack at once).
- Every dwarf gets its own tickets. A swarm on one dwarf should not use up another dwarf's tickets.
- An enemy without a ticket should walk around and wait, not stand still.
- A small arrow at the screen edge shows where an off-screen hit comes from. Colour can show the kind of attack.
- A small mark above an enemy about to strike shows you what is coming.

**Camera**
- FOV (field of view) is how wide the camera sees. Players want a slider for it.
- A camera that sits too high hides the ground. Lower it a little and move it closer to the dwarf.
- A spring arm is a stick that pulls the camera in when a rock wall is in the way.
- Head bob (the bounce while walking) and camera shake can make people feel sick. Give each one an off switch.

**Sprint and movement**
- Do not jump to full sprint in one frame. A tween (a smooth slide from one speed to another) feels better.
- A heavy dwarf should turn slower while sprinting and slide to a stop, not stop on a dime.
- Keep one energy bar for sprint, dodge and attack, so the dodge is always there when you need it.

**Building**
- The 45-degree turn step is the likely cause of "I can't line things up." Offer finer steps and a hold-key for free placement.
- Show a green, yellow or red ghost (the see-through preview) before a piece is placed. Red means it would fall.
- Every build should have a visible reason, such as a comfort bonus.

**Dark caves**
- Caves should be dark by default. Light comes from what you carry or place.
- The lantern is your main light. Flares are short, bright bursts.
- Keep a faint "night eye" light, so no one is ever totally blind if the lights fail.
- Warm light means safe. Danger gets a different colour and a shape or icon, never colour alone.

**Settings**
- Let players change every key. This is the cheapest big win.
- Subtitles should be on by default for voice lines, with a size option.
- Give separate sliders for music, effects, voice and master volume.
- Put FOV, head bob, camera shake and motion blur in one "Comfort" group.
- Each player's own settings stay their own. The host does not change them.

## How to read the labels in this report

Labels appear in brackets. **[Sourced]** means a named page says it. **[Secondary]** means a blog, aggregator, or search snippet we did not open in full. **[Anecdotal]** means one or a few forum or Steam posts. **[Guess]** means a number or rule we chose that must be tested in play. Review counts come from VaporLens, a site that sorts Steam reviews with a small summarising model. Treat them as **rough rank order**, not exact totals. We could not read Steam's "Most Helpful" reviews directly, so the negative-review picture is partial.

The short version (BLUF): the two cheapest wins with the most player impact are **reliable co-op joining** and **full key remapping with comfort sliders**. The biggest design risk is the **fight and camera feel** for a short dwarf, because our notes contain no measured numbers for a dwarf-sized camera. Test every number in play. Lead with co-op reliability and settings, then tune the camera and fights with a short test loop.

## Friends sell the game, and broken joins sink it

The genre's praise is almost always about other people. In Grounded, **co-op was praised about 83 times** and survival mechanics about 99 times, while multiplayer connectivity drew about **39 complaints** ([VaporLens Grounded](https://vaporlens.app/app/962130/grounded), rough count). Deep Rock Galactic shows the same pattern, with **63 co-op mentions** against **36 network complaints** (unstable connections, ping spikes, disconnects, host-migration problems) ([VaporLens Deep Rock Galactic](https://vaporlens.app/app/548430/deep_rock_galactic)). Valheim's praise "great with friends" appears 27 times ([VaporLens Valheim](https://vaporlens.app/app/892970/valheim)). The pattern is clear, but the counts are **[Secondary]** and approximate.

The second complaint family is onboarding and staleness. Core Keeper's "No Tutorial Or Guidance" is **23.7% of issues** and the top churn risk ([VaporLens Core Keeper](https://vaporlens.app/app/1621690/core_keeper/stats/analysis)). Core Keeper's refund-risk model puts **56.9% of revenue at risk to design** and **37.2% to technical problems**, but the page says its precision was about 88.8% and churn scores are not churn rates (same source). Deep Rock's "becomes boring after many hours" appears about 23 times (VaporLens Deep Rock Galactic, above). For shared progress, Deep Rock: Rogue Core drew complaints about **shared progression and shared upgrades** that cause friction ([GamesRadar](https://www.gamesradar.com/games/fps/deep-rock-galactic-roguelike-spin-off-launches-to-mostly-positive-steam-reviews-that-cant-decide-if-they-love-or-hate-its-timer-and-shared-progression-tool/)). Enshrouded players were irritated that one player's quest finish counted for everyone ([VaporLens Enshrouded](https://vaporlens.app/app/1203620/enshrouded), search summary).

Early access also matters. Valheim's "extended early access criticized" theme appears about **25 times** ([VaporLens Valheim](https://vaporlens.app/app/892970/valheim)). By contrast, Deep Rock's Rogue Core developers reportedly **changed the game in under 24 hours** and published a fix plan and roadmap ([DLCompare](https://www.dlcompare.com/gaming-news/deep-rock-galactic-rogue-core-responds-swiftly-to-community-feedback-77265)). That is **[Secondary]**, but the contrast is consistent with the Valheim complaints.

**Action for us:** make a join-leave-rejoin-host-change test part of every build, because connection is the most common co-op complaint. Show a simple connection-quality icon next to each friend. Give each dwarf its own rewards and unlocks inside the shared cave. Give solo players a helper or scale the early fights so one dwarf can win. Add a new mechanic in each zone, not only bigger numbers. Publish a short update note in the same week of each change.

## Fights and camera: give each dwarf its own attack tickets

The best-documented idea for groups of enemies is the **attack token** (or ticket). An enemy must hold a ticket before it attacks and gives it back when the attack ends. DOOM (2016) is said to use this for each attack type, but **no source we read gave DOOM's actual token counts** ([StraySpark, a vendor blog](https://www.strayspark.studio/blog/attack-token-system-ue5-group-combat-that-feels-fair) [Secondary]). Signals and Light, a design writer, says ticket systems are "often used in games with encounters that have between six or more active enemies," while Souls games let a dozen enemies attack with few complaints because their rules are clear ([Signals and Light, part 5](https://signalsandlight.substack.com/p/how-do-simultaneous-enemy-attacks) [Secondary]).

Two points carry most of the value for us. First, **keep pools per player**. StraySpark's example says two co-op players are two independent pools, so enemies on one player never starve the enemies on another ([StraySpark](https://www.strayspark.studio/blog/attack-token-system-ue5-group-combat-that-feels-fair)). Second, **tokens fix timing, not space**. Eight enemies with one melee token still crowd the same point unless they have separate slots ([StraySpark](https://www.strayspark.studio/blog/attack-token-system-ue5-group-combat-that-feels-fair)). The Last of Us Part II uses "strafe slots," spokes around the player, and one write-up of the GDC talk says the level uses 16 lines radiating from the player ([GameLook, GDC 2021 write-up](http://www.gamelook.com.cn/2021/08/449210/) [Secondary]). The starting numbers we would use (**one or two melee tickets per dwarf, one heavy, two ranged**, from the StraySpark example) are **[Guess]**, to test in play.

The owner's "can't see attacks from behind or below" complaint needs visual help as well as sound. God of War colours its arrows by attack type: white for behind, red for melee, purple for ranged ([Digital Trends guide](https://www.digitaltrends.com/gaming/god-of-war-combat-guide/) [Secondary]). Batman's Arkham games put a blue indicator above an attacker that is about to hit ([Only Trusted Finds](https://onlytrustedfinds.com/articles/why-do-game-enemies-attack-one-at-a-time) [Secondary]). The Last of Us Part II turns off an enemy's target tracking when the player dodges, so the enemy looks "dumbfounded" ([AI and Games #70](https://www.youtube.com/watch?v=BghECmeLda0) [Secondary]). That is a cheap way to make a dodge feel rewarding.

The camera is the largest unknown. Max Kaufmann's camera guide gives a rule that fits our problem: **come in close when looking up, and pull out when looking down**, and place the player in the lower part of the frame when looking across ([Little Polygon](https://blog.littlepolygon.com/posts/cameras/) [Secondary, fetched]). He also advises smoothing the tracking so every bump does not move the camera. Unreal's camera team says the spring arm should pull the camera toward the character when a wall blocks the view, and that line of sight should **never be occluded by level obstacles** ([Unreal Engine tech blog](https://www.unrealengine.com/tech-blog/six-ingredients-for-a-dynamic-third-person-camera) [Secondary, snippet]). The Journey camera designer John Nesky said that "dynamic third-person cameras are the hardest to design" ([Vice](https://www.vice.com/en/article/lights-camera-distraction-the-problem-with-virtual-camera-systems) [Secondary, quote]). **We found no source with a dwarf-sized camera height, distance or FOV in centimetres or degrees.** Every number for our camera is **[Guess]**.

**Action for us:** lower the camera's aim point to about chest height and move the camera closer in small steps, testing each step in a narrow tunnel and an open hall. Use a separate small curve for pitch (looking down pulls out a little, looking up comes in), following Little Polygon's rule. Add a spring arm that slides the camera in when rock blocks the view, and fade the rock between the camera and the dwarf rather than cutting. Widen framing for a few seconds when a pack appears, then return. Give every attack category its own ticket pool per dwarf, with starting values of one or two melee, one heavy and two ranged **[Guess]**. Add an edge arrow coloured by attack type and a small mark above attackers. Do not spawn packs directly behind the camera.

## Sprint and movement should feel heavy, not floaty

Sources agree that acceleration is a feel setting, not a single right number. Ryan Darcey's analysis of Halo's movement says **"there is such a thing as 'too responsive,'"** and that a very high acceleration can make a character "feel out of control." He also advises that you **graph acceleration values over time** when tuning ([Game Developer, Darcey, 2016](https://gamedeveloper.com/design/analyzing-core-character-movement-in-3d) [Secondary, fetched]). Echo Point Nova's designers let a player take a few seconds to reach top speed on a hoverboard, on purpose ([Game Developer deep dive, 2024](https://gamedeveloper.com/design/deep-dive-the-movement-of-echo-point-nova) [Secondary, fetched]). Titanfall 2's designers let a slide after sprint give a small speed boost, but the slide cannot turn as easily ([Game Developer interview](https://www.gamedeveloper.com/design/designer-interview-getting-i-titanfall-i-s-controls-just-right) [Secondary]). A stamina example from Dark Souls III uses a constant drain that matches rolls and attacks ([Fiction Horizon](https://fictionhorizon.com/games-with-perfectly-tuned-sprinting/) [Secondary, aggregator]).

For a heavy dwarf, a ramp of about **0.3 to 0.6 seconds** to full sprint is our starting guess **[Guess]**, not a sourced value. The "slower turn while sprinting" and "slide to a stop" ideas come from the Titanfall and Darcey points and fit a short, heavy body. A small widening of FOV during sprint (a few degrees) is common practice in forum posts **[Anecdotal]**, and it should stay small because the camera fix already changes the view.

**Action for us:** tween speed from walk to sprint over the ramp above. Slow the turn rate while sprinting, and give stopping a short slide. Put one shared stamina pool for sprint, dodge and attack, so sprint does not drain the dodge reserve. Add a debug graph of acceleration values, so builds can be compared. Keep the sprint FOV bump to a few degrees, and test it in tunnels.

## Building: finer turns, a visible preview, and a fixed support rule

The owner's "45 degrees per press" complaint has strong matches in other games. Valheim added manual snapping, where the pivot moves to a piece's corners or ends and holding Shift places a piece freely ([PCGamesN](https://www.pcgamesn.com/valheim/building-snapping-update) [Secondary]). Conan Exiles players asked for a hold-to-place-freely button, because "snap points and piece orientation often refuse to change" ([Funcom forum](https://forums.funcom.com/t/frustrating-build-system/79451) [Anecdotal]). Conan's rotation is limited to **90 and 60 degree combinations**, so players build scaffolding to reach other angles ([Funcom forum](https://forums.funcom.com/t/fence-foundation-rework-suggestion/174548) [Anecdotal]). Conan players also report fence pieces flipping orientation, and the build hammer cycling the ghost through many snap points ([Funcom bug list](https://forums.funcom.com/t/current-bugs-issues-pt-2/269980) [Anecdotal]). These are forum complaints, not measured counts.

The support preview is well liked when it is clear. A Valheim guide describes colours by support: blue for well grounded, green for supported, yellow for losing support, red for the weakest ([Mobalytics](https://mobalytics.gg/gamebase/guides/valheim-general-building-guide) [Secondary, guide; colours not checked in game]). 7 Days to Die players called building "impossible" when blocks dropped with no warning ([7DTD forum](https://steamcommunity.com/app/251570/discussions/0/619568793945872474) [Anecdotal]), and one bug report says integrity was calculated before neighbouring chunks loaded, which gave wrong results ([TFP community](https://community.thefunpimps.com/threads/possibly-a-bug-wrong-structural-integrity-calculation-on-incremental-chunk-loading.25299/latest) [Sourced bug report]). The lesson: the rule must be fixed and visible before placing, and it must not depend on loading order.

Reasons to build matter too. Valheim's comfort buff (the "Rested" bonus) counts each furniture category once, and furniture must be within about 10 metres ([Exitlag](https://www.exitlag.com/blog/valheim-comfort/) [Secondary]). Guides disagree on the maximum comfort and the regen numbers, so **we copy none of them**. Enshrouded's PC Gamer coverage says building "rarely sees a reward for the extra effort" ([PC Gamer](https://pcgamer.com/mountain-keeps-hobbit-holes-and-sick-castles-enshrouded-players-are-hard-at-work-with-that-excellent-building-system) [Secondary, snippet]), and one reviewer spent about an hour on a basic house ([GameSkinny](https://www.gameskinny.com/reviews/enshrouded-early-access-review-brave-the-fog/) [Secondary, snippet]). A streamer dug a basement by pickaxe for **three hours** before finding the faster construction tool ([GamesRadar](https://www.gamesradar.com/3-hours-into-manually-mining-out-their-basement-enshrouded-player-learns-the-survival-rpg-has-a-tool-that-would-have-done-it-in-an-instant) [Anecdotal]).

**Action for us:** add a finer rotation step (15 degrees or 5 degrees **[Guess]**) and a hold-key for free placement. Highlight the active snap point on the ghost. Make the ghost green, yellow or red for support, and refuse red placements. Keep the support rule fixed, and test that it does not change with chunk loading. Give stone and wood half walls the same snap points, and keep orientation when the material changes. Make the build hammer keep focus on the piece under the crosshair, so the wheel changes the piece type and not the snap point. Give each build one visible bonus per furniture category, with a ring on the ground that shows the range. Put a dig-and-make-room tool in the first hour, so no player spends three hours with a pickaxe.

## Dark caves: caves are dark by default, and light is something you carry

The closest technical match to our dig-anywhere caves is Foundry, a voxel survival game. Its developers say caves are **dark by default**, because light is traced down from the sky, and that old global ambient light leaked into caves. The fix computes light **per position**, and player lights are stored per block and do not change with day or night ([Foundry dev blog 17](https://www.paradoxinteractive.com/games/foundry/news/dev-blog-17-new-lighting-system-and-art-backlog) [Sourced, developer]). That is the model for "a dug tunnel stays dark until light reaches it."

Light sources in the genre are timed or fuel-based. Deep Rock Galactic's flares last **25 seconds by default** and 30 with a modifier, and the flashlight is a last resort ([DRG fan wiki](https://deeprockgalactic.fandom.com/wiki/High-Intensity_Flare?oldid=4239) [Secondary, fan wiki]). Core Keeper's lanterns free the hands and carry a glow stat ([BisectHosting](https://bisecthosting.com/blog/core-keeper-lantern-stats-effects-how-to-get) [Secondary]). Core Keeper also had a post-update bug in which lights stopped working and players were left in total darkness ([Steam discussion](https://steamcommunity.com/app/1621690/discussions/0/3759978783504648689) [Anecdotal]). That is a warning to keep a fallback light.

Readability comes from contrast. Players look at the brightest and most contrasting point on screen, so light guides the route, and a lit exit or landmark works as a breadcrumb ([Game Developer, level design tricks](https://www.gamedeveloper.com/design/level-design-tricks-of-the-trade) [Secondary]; [Unity, level design basics](https://unity.com/blog/level-design-basics) [Secondary]). Hollow Knight's muted palette stays readable through contrast and clear foreground shapes ([PC Gamer](https://www.pcgamer.com/uk/hollow-knights-charming-art-sets-the-bar-for-hand-drawn-games) [Secondary]). On the Godot side, volumetric fog works only with the Forward+ renderer, has a finite range, and short-lived lights should set Volumetric Fog Energy to 0 to avoid ghosting ([Godot docs, volumetric fog](https://docs.godotengine.org/en/4.4/tutorials/3d/volumetric_fog.html) [Sourced, 4.4 page]). Emissive materials (surfaces that glow on their own) are the cheap way to make crystals and mushrooms glow ([Godot docs](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html) [Sourced, via our performance note]).

Numbers for the lantern radius, fall-off, ambient floor and tone mapping were not found in any source we read. The Godot tone-mapper choices (Filmic, ACES, AgX) are listed in a class-reference snippet, and we could not open the 4.7 docs, so **every light and tone value is [Guess]**, to test against the painted sheets.

**Action for us:** keep caves dark by default, and light them only from the lantern, flares, glow groves and placed lights. Use one shadowed spot light for the lantern. Give flares a 25 to 30 second timer with a fade in the last seconds, and turn their shadows off. Add a faint "night eye" fallback light so no one is ever fully blind. Use warm light for safe places (hearth, bed, lit exits) and a different, cooler or sickly colour for danger, with shapes or icons too. Use a dark brown-blue ambient floor and match the fog colour to it, so distance fades into one tone instead of black. Keep volumetric fog to the glow groves, with a short range. Test Filmic, ACES and AgX against the painted sheets, and keep the one that keeps paint colours alive.

## Settings are the cheapest way to please players

The Game Accessibility Guidelines' basic tier gives a short list that costs little to build. It asks for a **wide choice of difficulty**, settings that are **saved and remembered**, **remappable controls**, **subtitles for all important speech**, **separate volume controls for effects, speech and music**, **high contrast between text and background**, **no essential information from colour alone**, and **a sensible default FOV for 3D games** ([Game Accessibility Guidelines, basic](https://gameaccessibilityguidelines.com/basic/) [Sourced]). Microsoft's Xbox guidelines add that players should choose first or third person, and that remapping should go from "swap digital buttons" to "any action to any input" ([XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117) [Sourced]).

Players complain loudly when options are missing. The most-cited missing items in our anecdotal sources are **key rebinding** and **FOV sliders**. Space Marine 2 players asked for an FOV slider and mentioned refunds ([Steam thread](https://steamcommunity.com/app/2183900/discussions/0/4763207599010744355) [Anecdotal]). Battlefield 6 players said head bob and camera shake caused nausea even with some effects off ([EA forum](https://forums.ea.com/discussions/battlefield-6-general-discussion-en/head-bobbing-and-camera-shake-causing-nausea/12760421) [Anecdotal]). Avowed has separate head bob, head bob strength and camera shake sliders, and its guide suggests setting them to zero ([Escapist](https://escapistmagazine.com/best-settings-to-reduce-motion-sickness-in-avowed) [Secondary]). Grounded has an arachnophobia slider from 0 to 5 that changes only how spiders look, applied per player, so friends still see default spiders ([PC Gamer](https://www.pcgamer.com/a-fear-of-spiders-wont-hold-you-back-in-grounded) [Secondary]).

For the Steam Deck (Valve's handheld), the Steamworks rules say the smallest text should be **at least 9 pixels** at 1280x800, with **12 pixels recommended**, glyphs (button pictures) must match the active input, and the default controller setup must reach all content ([Steamworks, Steam Deck compatibility](https://partner.steamgames.com/doc/steamdeck/compat) [Sourced]). Godot's InputMap can change key bindings at runtime, but the engine does not save them, so we must store each action's events in our own settings file and reload them on start ([Godot InputMap docs](https://docs.godotengine.org/en/stable/classes/class_inputmap.html) [Sourced]; [Godot forum](https://forum.godotengine.org/t/need-help-saving-controller-remaps/142711) [Anecdotal]). The 3D resolution scale (with FSR 2.2 as the best-quality option) can be set at runtime through the viewport's scale ([Godot resolution scaling docs](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html) [Sourced, via search snippets]).

We found **no Steam review counts per missing option**, so the ranking below is an inference from anecdotes and guidelines. Mouse sensitivity, invert-Y, brightness and frame-cap complaints were not verified.

**Action for us:** build a rebind screen that saves each action's events to the player's own settings file, with a reset button, before the demo. Add subtitles on by default, with a size option and a dark box behind text. Add four volume sliders. Put FOV, head bob, camera shake and motion blur in one "Comfort" group with gentle defaults. Add a brightness slider, because a dark-cave game needs it **[Guess]**. Design the UI at 1280x800, with the smallest text at 12 pixels and a UI scale slider. Never use colour alone for ore, danger or ownership. Keep settings per player, and never let the host change another player's comfort settings.

## Ranked action table

Confidence: **High** = a guideline, official doc or rule with a named source. **Medium** = a principle from several sources, or one solid source, with numbers still guesses. **Low** = a guess to test in play. Rank is by how much the action should help players, weighted by how often the problem appears in our sources and how cheap the fix is.

| Rank | Action | Why | Confidence |
|---|---|---|---|
| 1 | Test join, leave, rejoin and host change in every build; show a connection-quality icon | Connection is the most common co-op complaint (Grounded about 39, Deep Rock about 36) | Medium (counts rough) |
| 2 | Full key remapping with a reset button, saved to each player's own file | Most-cited missing option; GAG motor, XAG 107; Godot does not save remaps | High |
| 3 | Subtitles on by default for voice, with size and dark box | GAG hearing; voice lines are planned | High |
| 4 | Four volume sliders: master, music, effects, voice | GAG hearing | High |
| 5 | Lower the aim point to chest height and move the camera closer in steps | Camera-too-high complaint; framing rule from Little Polygon | Medium (numbers Guess) |
| 6 | Spring arm pulls the camera in when rock blocks the view; fade the rock | Unreal line-of-sight rule | Medium |
| 7 | Attack tickets per dwarf per attack type (starting 1-2 melee, 1 heavy, 2 ranged) | Stops swarms; concept repeated across sources | Medium (numbers Guess) |
| 8 | Enemies without a ticket keep moving to slots; spawn packs in front of the dwarf | Stacked attacks and surprise hits from behind | Medium |
| 9 | Edge arrow coloured by attack type, plus a mark above each attacker | God of War and Batman examples | Medium |
| 10 | FOV slider with a safe default; head bob, shake and motion blur toggles in a Comfort group | Many anecdotal complaints; GAG vision; XAG 117 | Medium |
| 11 | Finer rotation step and hold-key free placement; show the active snap point | Valheim manual snap; Conan and Fallout requests | Medium (step Guess) |
| 12 | Green, yellow and red support ghost; refuse red; fixed rule | Valheim guide; 7 Days to Die bug report | Medium |
| 13 | Same snap points for stone and wood; keep orientation when the material changes | Conan orientation complaints | Medium |
| 14 | Each dwarf keeps its own rewards and unlocks in a shared world | Shared-progress friction (Rogue Core, Enshrouded) | Medium-low |
| 15 | Solo play fair: a helper character or scaled early fights | Grounded solo complaints (about 40); Bosco praise (about 56) | Medium-low |
| 16 | Lantern as main light (one shadowed spot), flares 25-30 s, night-eye fallback | Deep Rock flares (fan wiki); Core Keeper lights bug | Medium (radius Guess) |
| 17 | Caves dark by default; light computed by position; dug tunnels stay dark until lit | Foundry developer blog | Medium-high |
| 18 | Colour language for safe and danger, with shapes too; dark blue-brown floor, not black | GAG vision; Foundry; contrast sources | Medium-low (colours Guess) |
| 19 | Sprint ramp of 0.3-0.6 s by tween; slower turn and slide-to-stop; debug acceleration graph | Darcey; Titanfall 2; Echo Point Nova | Medium (method); Low (numbers) |
| 20 | One stamina pool for sprint, dodge and attack; sprint never drains the dodge reserve | Dark Souls III model (aggregator) | Low-medium |
| 21 | Sprint FOV widening by a few degrees | Common practice (forum posts) | Low |
| 22 | One bonus per furniture category, with a visible range ring | Valheim comfort; Enshrouded "rarely rewarded" | Medium-low |
| 23 | One dig-and-make-room tool, taught in the first hour | Enshrouded three-hour pickaxe basement | Medium-low |
| 24 | Each new zone brings a new mechanic, not only bigger numbers | Deep Rock late-game staleness (about 23) | Medium-low |
| 25 | Large-base frame-rate test before the demo | Valheim large bases (about 9); Grounded (about 8) | Medium-low |
| 26 | Settings file per player, host never changes comfort settings | Co-op rule plus GAG general | Medium |
| 27 | Design UI at 1280x800 with 12 px minimum text and a UI scale slider | Steamworks Deck rules (9 px floor) | High (rule); Medium (fit) |
| 28 | 3D resolution-scale slider with an FSR 2.2 option and bilinear fallback | Godot resolution docs (snippets) | Medium |
| 29 | Creature-look slider per player, only if cave creatures upset players | Grounded arachnophobia slider | Low |
| 30 | Publish a short roadmap and reply fast to big bugs | Rogue Core fix plan under 24 hours; Valheim complaints | Medium-low |
| 31 | Test Filmic, ACES and AgX against the painted sheets | Godot tone-mapper snippets | Low |

## Conclusion

The most useful change in our thinking is that **the cheapest wins are not the flashy ones**. Reliable joins, remapping and subtitles cost little and answer the most common complaints in this genre. The fights and camera are harder, and our sources give rules but no dwarf-sized numbers. That means the camera and sprint values must come from a short test loop in the game, with each build graded on one thing (the camera in a tunnel, the sprint in a hall, a three-dwarf fight) rather than a long list.

The main open questions are the ones our research could not close: DOOM's real token counts, the Nesky camera mistake list, and the Naughty Dog slot numbers. Each one needs the primary talk or slides, not secondary write-ups. Until then, every number in this report marked **[Guess]** should be treated as a starting point, and the owner should judge it in play.
