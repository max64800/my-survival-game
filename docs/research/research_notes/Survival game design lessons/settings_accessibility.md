# Settings and Accessibility Options Expected in a 2026 PC Co-op Survival Game

Research date: 2026-11-22. Scope: options PC players expect, with a ranked checklist for a 3D underground dwarf survival co-op game in Godot 4.7 (keyboard and mouse first, gamepad and Steam Deck later, dark caves, voice lines, music, Steam Next Fest demo).

Evidence labels used below:
- **[Sourced]** a cited page or document says it.
- **[Anecdotal]** forum posts or single review threads. Not a count of reviews.
- **[Inference]** my conclusion from the sources, not stated by them.
- **[Gap]** searched, nothing reliable found.

Important limit: I found no data on how many Steam reviews mention each missing option. The ranking in the checklist is an inference from the anecdotal sources and the accessibility guidelines, not a measured complaint count.

---

## Key question 1: Which missing options cause the most negative Steam reviews?

### Takeaway
No reliable count of negative reviews per missing option was found. The most repeated anecdotal complaints across PC games are: no key rebinding, no FOV slider, and motion effects (head bob, camera shake) that cannot be turned off. Missing mouse sensitivity/invert and brightness/V-sync were not verified in this session.

### Cited Findings
- Missing rebinding: a Steam community thread on a Black Widow remake says none of its modes let you remap any controls; another thread argues remapping should be an option or the game is "close to unplayable" without a controller. [Anecdotal] — [Steam forum, Black Widow: Recharged](https://steamcommunity.com/app/1714180/discussions/0/3156453942269110505)
- Keyboard/mouse feels unfinished: a reviewer says keyboard "doesn't work at all for full game play"; a GamingOnLinux article on Rebel Galaxy Outlaw quotes a reviewer calling mouse/keyboard "not great." [Anecdotal] — [GamingOnLinux, Rebel Galaxy Outlaw and Steam reviews](https://www.gamingonlinux.com/2022/09/rebel-galaxy-outlaw-and-some-reflection-on-steam-reviews/comment_id=232335)
- Controller-only binding layout: a Dead Space forum post says that when any controller is plugged in, it uses an incorrect button layout. [Anecdotal] — [EA forum link found in search, Dead Space](https://forums.ea.com/discussions/-/-/7186361) (search snippet only; not opened)
- FOV complaints recur across years and publishers: Warhammer 40,000: Space Marine 2 (no FOV slider, refund requests mentioned); LEGO Star Wars: The Skywalker Saga (player felt sick, asked for FOV); The Callisto Protocol (slider still missing after a patch). [Anecdotal] — [Space Marine 2 Steam thread](https://steamcommunity.com/app/2183900/discussions/0/4763207599010744355); [Callisto Protocol Steam thread](https://steamcommunity.com/app/1544020/discussions/0/4288061352813175765)
- Borderlands 4: Gearbox said it was "exploring" an FOV slider on PS5 and Xbox Series X|S after console complaints; the PC version already had FOV settings. [Sourced for Gearbox statement via search snippet] — [Windows Central, Borderlands 4](https://www.windowscentral.com/gaming/borderlands-4-players-slam-the-rpg-fps-for-leaving-two-huge-features-out-of-the-console-versions-and-i-dont-blame-them)
- Counterpoint: some FOV complaints come from players not finding the existing setting. The Finals reviewers said most negative reviews came from people who did not know how to change in-game settings. Far Cry 4 had an FOV slider and complaints were dismissed by its creative director. [Anecdotal] — [PC Gamer, Far Cry 4 FOV](https://www.pcgamer.com/far-cry-4-users-complain-about-lack-of-fov-slider-are-revealed-to-be-pirates)
- Motion-related nausea: Battlefield 6 forum users say head bob and camera shake cause nausea even with some camera effects off. [Anecdotal] — [EA forum, Battlefield 6 head bobbing](https://forums.ea.com/discussions/battlefield-6-general-discussion-en/head-bobbing-and-camera-shake-causing-nausea/12760421)
- Mouse acceleration and missing FOV on PC: Uncharted: Legacy of Thieves (PC) players complained about forced mouse acceleration and no FOV slider. [Anecdotal] — [FPS Review, Uncharted PC](https://www.thefpsreview.com/2022/10/21/uncharted-legacy-of-thieves-collection-players-complain-of-forced-mouse-acceleration-lack-of-fov-slider-cpu-compatibility-issues-and-more-on-pc/)
- Mouse sensitivity and invert-Y: not searched in this session. [Gap]
- V-sync / frame cap, brightness/gamma, colorblind modes: not searched in this session as review complaints. [Gap]

### Inferences
- Rebinding and FOV are the two most-cited items in the anecdotal results. Treat this as a ranking hint, not a measured fact.
- Complaints appear both as "option missing" and "option hard to find." Put the sliders in an obvious Settings tab and add a short in-game tip for the FOV slider.

### Gaps
- No Steam review counts per option. A Steam review search per game (for example, searching review text for "FOV", "remap", "subtitles") would fill this, but it needs a browser session on Steam, which this research could not do.
- No 2026 data for Valheim, Enshrouded, Core Keeper or Grounded complaint patterns.

---

## Key question 2: Accessibility guidelines and cheap basics

### Takeaway
The Game Accessibility Guidelines (GAG) "basic" tier is the cheapest starting list. Most basic items are settings or content choices that cost little to add early: remapping, subtitles, separate volume sliders, saved settings, and a documented accessibility page.

### Cited Findings
- GAG basic tier, General: offer a wide choice of difficulty levels; provide accessibility feature details on packaging/website and in-game; make sure all settings are saved/remembered; solicit accessibility feedback. [Sourced] — [Game Accessibility Guidelines, basic](https://gameaccessibilityguidelines.com/basic/)
- GAG basic, Motor: include an option to adjust game speed; allow controls to be remapped; include an option to adjust control sensitivity; include a toggle/slider for haptics; make all UI reachable with the same input as gameplay. [Sourced] — [GAG basic](https://gameaccessibilityguidelines.com/basic/)
- GAG basic, Vision: high contrast between text/UI and background; no essential information by colour alone; set an appropriate default FOV for 3D games. [Sourced] — [GAG basic](https://gameaccessibilityguidelines.com/basic/)
- GAG basic, Hearing: subtitles for all important speech; separate volume controls for effects, speech and music; no essential information from sound alone. [Sourced] — [GAG basic](https://gameaccessibilityguidelines.com/basic/)
- GAG basic, Cognitive: avoid flicker and repetitive patterns; let players read text at their own pace; start the game without many menu layers; readable default font size. [Sourced] — [GAG basic](https://gameaccessibilityguidelines.com/basic/)
- Xbox Accessibility Guidelines (XAG) version 3.2 (June 2023) is the Microsoft version. XAG 101 covers text size and fonts; XAG 104 says subtitles should have a larger default minimum size; XAG 107 covers remapping, distinguishing basic (swap digital buttons) from full (any action to any input). XAG 117 covers visual distractions and motion settings, and recommends first/third-person choice. [Sourced via search snippets] — [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117); [Microsoft guidelines hub](https://learn.microsoft.com/gaming/accessibility/guidelines)
- XAG has a caveat: one Microsoft page says text size should not be taken into account, which conflicts with the rest of the guidance. Treat the dedicated text-size section as authoritative. [Sourced, conflict noted] — search snippet, Microsoft guidelines hub
- AbleGamers "Includification" (2012) is an older developer guide with good / better / best tiers, covering colour-blind modes, remappable keys and speed settings. It has been superseded by the AbleGamers and University of York "Accessible Player Experiences" patterns (2018). [Sourced] — [accessible.games, Includification](https://accessible.games/includification/); the Accessible Player Experiences page was not opened. [Gap]
- Can I Play That: the site has accessibility reviews, but the search found no review of a co-op survival game. [Gap] — [caniplaythat.com](https://caniplaythat.com/page/2/)

### Inferences
Cheap basics for our game (low cost, high value):
1. Full key rebinding for keyboard and mouse, with a reset button. (GAG motor, XAG 107)
2. Subtitles for voice lines, with a size option and a dark background box. Voice lines are planned, so this matters from day one. (GAG hearing, XAG 104)
3. Three or four volume sliders: master, music, effects, voice. (GAG hearing)
4. Save all settings to a file under `user://`, and apply them on boot. (GAG general)
5. Accessibility page on the Steam store and in game, even if short. (GAG general)
6. Do not show important warnings, ore types or danger signs by colour alone. Use shape or icons too. This matters in a dark cave game where colour is the easiest signal to lose. (GAG vision)
7. Game-speed option is a bigger job; consider it later. (GAG motor)

### Gaps
- Full text of the Accessible Player Experiences patterns and the XAG 101/104/107 pages was not opened. The points above come from search snippets for XAG.

---

## Key question 3: Motion sickness in third-person games

### Takeaway
Motion sickness in third-person games usually comes from camera movement (head bob, camera shake, auto-follow swing, motion blur) and a field of view that feels wrong. Give each one an off switch or slider. A third-person toggle alone does not fix it.

### Cited Findings
- Head bob and camera shake sliders are common in recent games. Avowed has separate head bob, head bob strength and camera shake sliders, and its guide suggests setting them to zero; it also says the third-person toggle made no difference when head bob was off. [Sourced via guide snippet] — [Escapist, settings to reduce motion sickness in Avowed](https://escapistmagazine.com/best-settings-to-reduce-motion-sickness-in-avowed)
- Elder Scrolls Online has a first-person head bob slider; Cyberpunk 2077 lets players adjust secondary camera movement. [Sourced via search snippet] — no single URL opened; [Gap for exact citation]
- Microsoft XAG 117 (visual distractions and motion settings) recommends letting players choose first- or third-person views. [Sourced] — [XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117)
- Third-person does not fix everything. Battlefield 6 players report nausea from head bob even with camera effects off; a Bohemia feedback thread says third-person rocking is worse for some; an Assassin's Creed Mirage commenter blamed auto camera follow. [Anecdotal] — [EA forum, Battlefield 6](https://forums.ea.com/discussions/battlefield-6-general-discussion-en/head-bobbing-and-camera-shake-causing-nausea/12760421); [Bohemia feedback T141763](https://feedback.bistudio.com/T141763); [AC Mirage Steam thread](https://steamcommunity.com/app/3035570/discussions/1/561358509790209978)
- GAG basic: set an appropriate default FOV for the expected viewing environment in 3D games. [Sourced] — [GAG basic](https://gameaccessibilityguidelines.com/basic/)
- Players commonly raise FOV and turn off motion blur. Minecraft's FOV goes up to 110 degrees; Halo Infinite has a FOV slider. [Anecdotal / product facts from search snippets] — no URL opened; [Gap for exact citation]

### Causes and options (our game)
| Cause | Option to add |
|---|---|
| Head bob while walking/mining | Head bob slider (0 = off) |
| Camera shake from hits, blasts, falling rock | Camera shake slider (0 = off) |
| Motion blur | Toggle (default off) |
| Too low or too high FOV | FOV slider, sensible default |
| Camera swing when turning or auto-follow | Camera follow speed / smoothing slider |
| Third-person view | Optional first-person toggle (XAG 117) |

### Inferences
- In a cave game, tight tunnels make the camera feel close to walls. A FOV that is too wide in small rooms can also cause nausea. Test FOV in narrow tunnels, not only in open halls.
- Put motion sliders in one "Comfort" group. This makes them easy to find.

### Gaps
- No controlled study found on motion sickness rates by option. Evidence here is player reports and guidelines.

---

## Key question 4: Steam Deck Verified requirements

### Takeaway
Valve's own page sets a hard floor of 9 px for the smallest on-screen text at 1280x800, recommends 12 px, requires controller glyphs to match the active input, and requires that the default controller setup can reach all content with no setup.

### Cited Findings
- Text: "the smallest on-screen font character should never fall below 9 pixels in height at 1280x800." Recommended: "aiming for 12px whenever possible," plus user-configurable text size and contrast where possible. [Sourced] — [Steamworks, Steam Deck compatibility](https://partner.steamgames.com/doc/steamdeck/compat)
- Glyphs: "On-screen glyphs must match the inputs being used," covering Deck, Steam Controller or Xbox glyphs. Mouse and keyboard glyphs must not show while a controller is the default input. Recommended: Steam Input API. [Sourced] — [Steamworks, Steam Deck compatibility](https://partner.steamgames.com/doc/steamdeck/compat)
- Default settings: the default controller configuration must give access to all content; no in-game setup is needed to enable controller support. Frame rate default must be playable (30 fps at 800p is named as the Deck target). [Sourced] — [Steamworks](https://partner.steamgames.com/doc/steamdeck/compat)
- Resolution: the game must run at a resolution the Deck supports. 1280x800 is preferred, 1280x720 also recommended. [Sourced] — [Steamworks](https://partner.steamgames.com/doc/steamdeck/compat)
- Text entry: if the game needs typing, use the Steamworks text-entry API to open the on-screen keyboard, or provide built-in entry usable with a controller. [Sourced] — [Steamworks](https://partner.steamgames.com/doc/steamdeck/compat)
- Remapping is not a stated requirement on the page. [Sourced, absence noted] — [Steamworks](https://partner.steamgames.com/doc/steamdeck/compat)
- Small text is a common reason for a Playable (not Verified) rating. Example: 007 First Light had small in-game text fixed before it earned Verified. [Sourced via search snippet] — [Digital Citizen, 007 First Light](https://www.digitalcitizen.life/007-first-light-earns-steam-deck-verified-status-after-small-text-issue-is-resolved/)
- Valve says display tests are not run for Steam Machine (text size and resolution vary by display). Secondary source (GamingOnLinux, Jan 2026): Steam Machine verification has fewer constraints, but text sizing is a worry. [Sourced via secondary article] — [GamingOnLinux, Jan 2026](https://www.gamingonlinux.com/2026/01/steam-machine-verification-will-have-fewer-constraints-than-steam-deck-but-text-sizing-worries-me/)

### Inferences
- Design UI at 1280x800 from the start. Make the smallest text at least 12 px at that size, and offer a UI scale slider above that.
- Hide keyboard glyphs when a controller is active. Use Steam Input glyph sets when we add gamepad support.
- Our game is mouse-first now, but keep a "controller can reach everything" rule in the design so the Deck port is not a rebuild.

### Gaps
- Steam's exact "Verified" checklist (beyond the compatibility page) was not fully read. Secondary sources only for the Verified criteria.

---

## Key question 5: Godot 4.7 support

### Takeaway
Godot's InputMap can change bindings at runtime, but runtime changes are not saved by the engine. We must save the events ourselves and reload them on start. 3D resolution scaling with FSR 2.2 exists in Godot docs. UI scaling and gamepad glyph support were not verified against the 4.7 docs in this session.

### Cited Findings
- InputMap runtime methods: `action_add_event`, `action_erase_event`, `action_erase_events`, `action_get_events`, `action_has_event`, `load_from_project_settings` (clears all action events and reloads from ProjectSettings). The page does not say whether runtime changes persist. [Sourced] — [Godot InputMap class docs](https://docs.godotengine.org/en/stable/classes/class_inputmap.html)
- Forum guidance: InputMap changes are session-only; save `action_get_events()` per action (for example in a ConfigFile under `user://`), reload on start, and when rebinding a key, erase only the matching event type so gamepad and mouse bindings stay. Store a version number for later migration. [Anecdotal, community forum] — [Godot forum, saving controller remaps](https://forum.godotengine.org/t/need-help-saving-controller-remaps/142711); search snippet also mentions [a forum thread on serializing the InputMap](https://forum.godotengine.org/t/how-to-serialize-input-map/20329)
- Add-ons: Rebind Kit (MIT, Godot 4.6 per asset page) and a 4.2.1 InputMap save project exist. Not reviewed. [Sourced for existence] — [Godot asset library, Rebind Kit](https://godotengine.org/asset-library/asset/5606)
- 3D resolution scaling: Godot docs list FSR 2.2 as a Scaling 3D mode (Rendering > Scaling 3D; available since 4.2). It is the slowest mode but the highest quality of the options. It does its own anti-aliasing, so the TAA setting is ignored in that mode. Scale can be set at runtime with `scaling_3d_scale` on a Viewport. Fallback to bilinear when the renderer does not support FSR. [Sourced; search snippets of the official docs] — [Godot resolution scaling docs](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html)
- The docs page was returned for several versions (4.2 through stable). The exact 4.7 wording was not checked. [Gap]
- Common PC games with upscaling: Enshrouded offers DLSS and FSR (guides say FSR 3.x, versions conflict between sources). Valheim has no built-in FSR; a Thunderstore mod adds FSR 1 (mod developers say tested only on Linux, one Windows report). [Sourced via guide snippets, mixed] — [Primagames, Enshrouded graphics](https://primagames.com/gaming/best-graphics-settings-for-enshrouded); [Thunderstore, GraphicsOverdrive](https://thunderstore.io/c/valheim/p/Wubarrk/GraphicsOverdrive/)
- UI scaling: the Godot UI scaling/multiple-resolutions doc page returned 404 when fetched. Not verified. [Gap]
- Gamepad glyphs: not searched beyond the Steam Deck glyph rule. [Gap]

### Inferences
- Plan the settings file now: `user://settings.cfg` with sections for video, controls (the saved InputMap events), audio, gameplay, accessibility. Load before the first scene.
- Add a "Reset to defaults" button that calls `load_from_project_settings()` and then deletes the saved bindings.
- Keep the 3D scale slider (0.5 to 1.0 with FSR) separate from UI scale. UI scale affects text and should follow the Steam Deck 12 px rule.

### Gaps
- Confirmed Godot 4.7 UI scaling API. Confirmed Godot 4.7 gamepad glyph tools.
- Core Keeper settings (not found in search results at all).

---

## Key question 6: What survival games offer

### Takeaway
Survival games in the sample offer graphics presets, upscaling (FSR and DLSS in Enshrouded), and a few accessibility toggles. Grounded is the clearest example of a per-player "creature look" option (arachnophobia mode). Valheim's vanilla game has little beyond graphics presets.

### Cited Findings
- Grounded: Arachnophobia Safe Mode, a 0 to 5 slider in the Accessibility tab. Level changes how spiders look (legs removed, then fangs, then reduced to floating blobs); guides say it does not change gameplay or difficulty. [Sourced via guide snippets] — [PC Gamer, Grounded spider mode](https://www.pcgamer.com/a-fear-of-spiders-wont-hold-you-back-in-grounded); [GamesRadar, Grounded arachnophobia mode](https://www.gamesradar.com/grounded-arachnophobia-mode-lets-you-turn-spiders-into-legless-blobs-and-everything-in-between)
- Grounded: the setting applies only to the player's own game. Friends still see default spiders in multiplayer. [Sourced via guide snippet; URL not mapped to the claim] — search results from Game8 and Millenium guides; [Gap for a precise citation]
- Grounded 2 has a similar five-level mode. [Sourced via snippet] — [Game8, Grounded 2](https://game8.co/games/Grounded-2/archives/538352)
- Enshrouded: DLSS and FSR upscaling; presets; guides advise lowering shadows or voxel detail for FPS. [Sourced via guides, mixed on FSR version] — [Primagames](https://primagames.com/gaming/best-graphics-settings-for-enshrouded)
- Valheim: vanilla graphics are mostly presets; the GraphicsOverdrive mod adds FSR 1/3 and DLSS. [Sourced via mod page and guide] — [PC Gamer, Valheim graphics](https://www.pcgamer.com/valheim-recommended-graphics-settings) (snippet); [Thunderstore](https://thunderstore.io/c/valheim/p/Wubarrk/GraphicsOverdrive/)
- Core Keeper: no settings results in this session. [Gap]

### Inferences
- A creature-look option (Grounded-style) fits our dwarf game if we have spiders, worms, or other cave beasts that some players dislike. It needs to be a per-player setting so friends keep their own view, and it must not change gameplay. Note the Grounded multiplayer behaviour as a design choice to decide, not a rule.

### Gaps
- Core Keeper, Valheim subtitles and colour modes, and survival-game difficulty settings were not checked.

---

## Ranked checklist for our game

Ranking is an inference from the anecdotal complaint evidence and the guidelines, not a measured count. Columns: rank, option, evidence tag, action for our game.

| Rank | Option | Evidence | Action for our game |
|---|---|---|---|
| 1 | Full key and mouse rebinding, reset button | Anecdotal complaints; GAG motor; XAG 107 | Build a rebind screen on InputMap; save `action_get_events()` to `user://settings.cfg`; reload on boot; add reset. Do this before the Next Fest demo. |
| 2 | FOV slider with a sensible default | Anecdotal complaints (many games); GAG vision | Add FOV slider, default in the mid range; test in narrow tunnels too. |
| 3 | Head bob, camera shake, motion blur off | Anecdotal (BF6, Avowed guide); XAG 117 | Three sliders or toggles in a "Comfort" group, all default to a gentle setting. |
| 4 | Subtitles for voice lines, with size and background | GAG hearing; XAG 104 | Subtitles on by default for voice lines; size option; dark box behind text. |
| 5 | UI text size / UI scale | Steam Deck 9 px floor, 12 px recommended; XAG 101 | Design at 1280x800; smallest text 12 px; UI scale slider. |
| 6 | Separate volume sliders (music, effects, voice, master) | GAG hearing | Four AudioServer bus sliders. |
| 7 | 3D resolution scale and FSR option | Godot docs (FSR 2.2); Enshrouded and Valheim mod examples | Viewport `scaling_3d_scale` slider; FSR 2.2 when available, bilinear fallback. |
| 8 | Mouse sensitivity and invert Y | Not verified this session | Add sliders anyway (standard for PC); [Gap] for complaint evidence. |
| 9 | Brightness / gamma for dark caves | Not verified this session; design inference | Brightness slider is important for a dark-cave game; [Gap] for complaint evidence. |
| 10 | Colour-safe signals | GAG vision | Do not use colour alone for ore, danger, or ownership. Add icons or shapes. |
| 11 | Frame cap and V-sync | Not verified this session | Add frame cap and V-sync toggle; [Gap] for evidence. |
| 12 | Creature look / "creature-safe" mode | Grounded (sourced) | Only if we have creatures that cause discomfort; per-player, no gameplay change. |
| 13 | Game-speed option | GAG motor | Later; not a priority for survival pacing. |
| 14 | Controller glyphs (match active input) and controller-reachable UI | Steam Deck Verified; GAG motor | Plan with Steam Input when gamepad support starts. |
| 15 | Accessibility page on Steam and in game | GAG general | Write when the demo page is made. |

### Co-op specific notes
- Settings are per player (FOV, subtitles, motion, colours, creature look). The host should not change another player's comfort settings.
- Co-op rebinding: each player's bindings are saved on their own machine. No host approval needed for settings. This fits the co-op rule "request → host approves → everyone updates" only for gameplay actions, not for personal options.
- Multiplayer complaints about shared visuals were not researched. [Gap]

---

## Overall gaps
- No Steam review counts per option (cannot rank by real complaint volume).
- No 2026 data on Core Keeper, Valheim or Grounded settings beyond what is above.
- Mouse sensitivity, invert Y, V-sync, frame cap, brightness, and colourblind modes not checked against sources.
- Godot 4.7 UI scaling API and gamepad glyph tools not verified.
- Can I Play That: no co-op survival rating found.
- Accessible Player Experiences patterns (AbleGamers/York) not read.
