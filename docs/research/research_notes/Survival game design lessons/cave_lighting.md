# Cave lighting: readable and beautiful dark caves in 3D games

Scope: how dark underground spaces are kept readable and attractive, tied to our Godot 4.7 game (Forward+, hand-painted chunky style, dig-anywhere voxel caves, carried lantern, glowing crystals/mushrooms/glow groves, dark dungeons and ruins).

Pre-read: the lights section of `godot_performance.md` was skimmed first (shadow cost per light type, Forward+ clustering, shadow atlas, LightmapGI being wrong for dug caves, shader warm-up). Those points are not repeated here except where this research adds something new.

Research note on source quality: most game-specific sources are press coverage, fan wikis and forum posts, not developer talks. Where a point comes from a community post or a press summary, it is marked. The GDC/talk searches for Deep Rock Galactic and Subnautica returned no usable talk transcripts. Godot documentation fetches were blocked in this session, so Godot points come from search snippets of docs.godotengine.org pages and the Godot class reference, and are marked "snippet".

## How do other games handle darkness and visibility?

### Takeaway
The games that do dark caves well treat darkness as a resource the player manages (flares, lanterns, glow sources) and keep one clear light or colour cue per route. Caves are dark by default and light comes from things the player places or finds. Lighting is also made position-based, not one global ambient value.

### Cited Findings
- Deep Rock Galactic: flares give light for 25 seconds by default (30 with a modifier), and the closed-alpha era had players rely on headlights once flares ran out — [DRG Wiki, High-Intensity Flare](https://deeprockgalactic.fandom.com/wiki/High-Intensity_Flare?oldid=4239) (fan wiki).
- Deep Rock Galactic: a community post says the game is designed around flares for visibility, the flashlight is a last resort, and shadows on lights were avoided to keep the look — [devtrackers.gg post on DRG flashlight](https://devtrackers.gg/deep-rock-galactic/p/0bd9f650-all-my-issues-with-drg-flashlight-short-video-comparison-and-analysis) (community opinion, not an official statement).
- Deep Rock Galactic: an Unreal interview says the game depends on stark contrast between light and dark — [Unreal Engine interview](https://www.unrealengine.com/en-US/developer-interviews/guns-gold-and-glory-in-the-caverns-of-deep-rock-galactic).
- Core Keeper: torches are the basic light source; blue glow tulips also give light and can be placed as decor; lanterns are portable lights that free the hands and carry a glow stat — [BisectHosting guide](https://bisecthosting.com/blog/core-keeper-lantern-stats-effects-how-to-get); [Gamer Journalist, Torches](https://gamerjournalist.com/core-keeper-torches/).
- Core Keeper: a later update gave underground areas special lighting attention (more realistic light sources, better shadow diffusion, light-emitting surfaces) — [PCGamesN, Core Keeper update](https://www.pcgamesn.com/core-keeper/update-steam-survival-game-zelda).
- Core Keeper: PC Gamer describes tunnelling into pitch-black areas as creepy and claustrophobic, and base lighting as warm — [PC Gamer review](https://www.pcgamer.com/co-op-survival-game-core-keeper-gets-the-mix-of-cozy-and-creepy-just-right).
- Core Keeper: players reported a post-update bug where lights stopped working and they were left in total darkness — [Steam discussion](https://steamcommunity.com/app/1621690/discussions/0/3759978783504648689). This is a warning that a light system needs a fallback and a test.
- Valheim (Mistlands): the biome uses a new fog-lighting system, and a wisp-based torch and fountain were added as light sources. The base game limits artificial light to campfires, hearths and torches, and the fuel changes the light colour — [PC Gamer, Mistlands](https://www.pcgamer.com/uk/valheim-teases-mistlands-biome-and-new-caverns-in-the-mountains/); [GamesRadar, Mistlands](https://gamesradar.com/valheims-mistlands-update-is-spellbindingly-pretty-and-utterly-deadly). Iron Gate's CEO said composition and lighting mattered more to him than texture detail (press quote via [GamePressure/PC Gamer coverage](https://www.gamepressure.com/newsroom/valheim-continues-to-grow-turnip-ornaments-mountain-caves-and-a-d/zc3b61)).
- Valheim: a Steam user claimed mist plus dynamic lighting hurt performance — [Steam discussion](https://steamcommunity.com/app/892970/discussions/0/4027970229978236462) (single user, not verified).
- Valheim: a mod adds per-dungeon darkness profiles, showing players want darkness to vary by place — [Nexus Mods, Valheim mod 3336](https://www.nexusmods.com/valheim/mods/3336) (mod, not an official feature).
- Subnautica 2 (deep dive coverage): visibility is the main fear lever. The first game used bioluminescence early on, then less light as you go deeper. Coverage of a deep dive with Anthony Gallegos — [Creative Bloq](https://www.creativebloq.com/3d/video-game-design/subnautica-2-uses-unreal-engine-5-to-make-the-ocean-feel-psychologically-hostile); [El-Balad](https://www.el-balad.com/17009743). Players debate whether very dark water suits tight spaces (kelp caves, wrecks) more than open areas — [Unknown Worlds forums](https://forums.unknownworlds.com/discussion/156331).
- Hollow Knight: reviewers say the muted, mostly monotone palette stays readable because of contrast and clear foreground elements; benches have a distinct look that stands out from the background — [PC Gamer](https://www.pcgamer.com/uk/hollow-knights-charming-art-sets-the-bar-for-hand-drawn-games); [GameRant](https://gamerant.com/hollow-knights-indie-games/) (press summaries, not developer talks). The 80.lv breakdown was found, but its text did not load, so no developer quote is cited.
- Foundry (voxel survival, Unity): caves are dark by default because sunlight is traced down from the sky. Day/night light used to leak into caves because ambient light was global. The fix computes light per position and terrain. Player lights are stored per block and do not change with time of day. Each chunk starts dark; light spreads outward and fades — [Foundry dev blog 17](https://www.paradoxinteractive.com/games/foundry/news/dev-blog-17-new-lighting-system-and-art-backlog). This is the closest match to our dig-anywhere caves.

### Inferences
- Flares and lanterns are the same design tool in two costumes: a timed or fuel-based light the player carries and must manage. Our lantern can use the DRG pattern (fuel or time, with a weaker fallback light) and the Core Keeper pattern (carried light that frees the hands).
- A dug tunnel is dark until the player's light or a placed light reaches it. Foundry's position-based light supports this directly and matches our "caves change when dug" constraint.
- Subnautica's and Valheim's experience suggests darkness works best as a gradient by depth or biome, not a flat black. That fits "one dungeon should be dark like another": the owner wants dungeons to share a darkness rule but vary by place or depth.

### Gaps
- No talk transcripts found for DRG flare or flashlight design, or for Subnautica dark-zone lighting. Only community or press summaries.
- Minecraft caves, Spelunky 2, Ori, Grounded and Abiotic Factor were not researched in this pass. Ask for a follow-up if these matter.
- Core Keeper's and Valheim's internal lighting numbers (light radius, fall-off) were not found.

## Readability principles: value contrast, silhouettes, colour language, fog, and pure black

### Takeaway
Players' eyes go to the brightest and most contrasting thing, so the job is to make the important things (routes, exits, enemies, loot) brighter or differently coloured than the cave around them, and to keep the rest calm and slightly lifted from pure black.

### Cited Findings
- Players tend to look at the brightest point on screen, so lighting makes a focal point; in Mirror's Edge the route forward is lit and nearby areas are shadowed, which pulls the player along — [Game Developer, Lighting and guiding](https://www.gamedeveloper.com/design/level-design-tricks-of-the-trade).
- Players' eyes go to contrast; a bright door in a dark landscape is hard to miss — [Unity, Level design basics](https://unity.com/blog/level-design-basics).
- Simple exponential fog can greatly improve silhouette readability, per one developer quoted in a Game Developer search summary — [Game Developer search results](https://www.gamedeveloper.com/design/level-design-tricks-of-the-trade) (a secondary summary; treat as a lead).
- Hollow Knight's palette is muted and monotone, and reviewers credit contrast and separate foreground elements for readability — [PC Gamer](https://www.pcgamer.com/uk/hollow-knights-charming-art-sets-the-bar-for-hand-drawn-games).
- Colour coding: coloured light can reinforce paths and create contrast; light can also signal whether an action was good or bad — [Game Developer, Lighting and guiding](https://www.gamedeveloper.com/design/level-design-tricks-of-the-trade).
- Overly bright lighting can break a game's look and feel and feel hand-holding; the advice is to show, not tell — [Game Developer, Lighting and guiding](https://www.gamedeveloper.com/design/level-design-tricks-of-the-trade).
- Subnautica 2 coverage: infected areas use a more desaturated palette and murky visibility, so colour and visibility signal danger — [Creative Bloq](https://www.creativebloq.com/3d/video-game-design/subnautica-2-uses-unreal-engine-5-to-make-the-ocean-feel-psychologically-hostile).

### Inferences
- Colour language for us (proposal, to test in game): warm light = safe or home (hearths, campfires, our bed), cool or pale light = unknown or wild, a sickly green or purple glow = danger or hostile, and glowing interactables = a bright warm-white edge or pulse. This follows the same warm/cool split as Valheim's fuel-coloured lights and Subnautica's infected palette, but no source gives this exact rule.
- Enemies and loot should be lit by their own small light or rim light, or be a colour the cave does not use, so they stand out as silhouettes.
- Avoid pure black: give the cave a faint ambient floor (dark brown-blue, not black) so shapes and hand-painted detail stay visible. Use fog colour to match this floor so distance fades into the same tone.

### Gaps
- No sourced numeric values for ambient floor, fog density or contrast ratio. Tune in game.
- No source on specific colour-language rules from DRG, Core Keeper or Spelunky.
- Pure-black avoidance: no direct developer source found; the rule is an inference from the readability sources above.

## Lighting for stylised hand-painted 3D in Godot 4 (tone mapping, glow, fog, screen effects)

### Takeaway
Godot 4 gives us tone mapping (Linear, Reinhard, Filmic, ACES, AgX), glow, SSAO/SSIL and volumetric fog, all of which can be turned on for mood. The main cost limits are on the Mobile renderer and on volumetric fog range. Use emissive materials for glowing surfaces and reserve real lights for the lantern and a few key sources.

### Cited Findings
- Godot 4 tone mappers in the class reference: Aces, Agx, Filmic (also Linear and Reinhard in the editor) — [Godot class reference snippet, via search](https://straydragon.github.io/godot-csharp-api-doc/4.4-stable/main/Godot.Environment.ToneMapper.html) (snippet, not a fetched docs page).
- The AgX entry says TonemapWhite is fixed at 16.29, and AgX is unsuitable with the Mobile renderer — same snippet source (snippet).
- ACES is a high-contrast, film-like curve that desaturates bright values; Filmic is the Uncharted 2 curve — [Godot class reference snippet](https://straydragon.github.io/godot-csharp-api-doc/4.4-stable/main/Godot.Environment.ToneMapper.html); [Godot proposal #7545 on AgX](https://github.com/godotengine/godot-proposals/discussions/7545) (snippet).
- Environment and post-processing page (stable and 4.7 editions) covers tone mapping, glow, fog and SSAO/SSIL settings. Text not fetched; [Godot docs, Environment and post-processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html).
- Volumetric fog works only with the Forward+ renderer, not Mobile or Compatibility. It has a finite range, so the docs suggest adding normal fog to hide the far edge. All light types take part, controlled by each light's Volumetric Fog Energy. Short-lived dynamic lights should set this to 0 to avoid ghosting — [Godot docs, Volumetric fog and fog volumes](https://docs.godotengine.org/en/4.4/tutorials/3d/volumetric_fog.html) (snippet from the 4.4 page; Forward+ point also in the 4.4 .rst source).
- FogVolumes add to or subtract from the global Environment density; density 0 with FogVolumes is valid; FogVolumes only show if volumetric fog is enabled — same volumetric fog page (snippet).
- Glow and emissive: performance doc advice (from the earlier performance note) is to use emissive materials instead of lights for large glowing areas — [Godot docs, Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html) (quoted in `godot_performance.md`).
- Foundry: lighting is computed per position, so caves are dark by default — [Foundry dev blog 17](https://www.paradoxinteractive.com/games/foundry/news/dev-blog-17-new-lighting-system-and-art-backlog).

### Inferences
- Tone mapping: AgX is listed in Godot 4 but warns against Mobile. Our target is Forward+ desktop, so AgX is allowed. A safe default for a chunky painted look is Filmic or ACES with a modest exposure, because they keep painted colour from going grey. Test AgX against the painted sheets before committing. This is a suggestion, not a sourced rule.
- Volumetric fog is a good fit for dust and mist in a glow grove, not for the whole cave. Keep its range short and mask the far edge with normal fog. Set Volumetric Fog Energy to 0 on lantern flicker and any short-lived light, so it does not ghost.
- Glow: use emissive crystal and mushroom materials with a small number of real lights. This matches the performance note's advice.
- Ambient floor and fog colour should be the same dark tone. Set the Environment ambient colour and fog colour together so the cave fades into one tone rather than a grey wall.

### Gaps
- Godot docs main pages were blocked in this session; exact tone mapping, glow and SSAO parameter defaults are not verified from a fetched page. Verify on the 4.7 docs page before tuning.
- No sourced benchmark for volumetric fog cost in caves.
- No source on how AgX or Filmic affects hand-painted textures specifically. Test in game.

## Guiding the player with light: lit paths, exits, landmarks

### Takeaway
Light works best as breadcrumbs: light the route, the exits and the next landmark, and leave everything else a little darker. Keep it restrained, since too much light makes the player feel led by the hand.

### Cited Findings
- Light is one of the most effective guidance tools. Designers use it to highlight exits, paths, points of interest and the first appearance of a new enemy. Making important entrances and exits visibly lit is a simple habit that pays off — [Unity, Level design basics](https://unity.com/blog/level-design-basics).
- Lighting sets the mood of an area at the same time — [Unity, Level design basics](https://unity.com/blog/level-design-basics).
- Mirror's Edge: lit route, shadowed sides, creating contrast that naturally leads the player forward — [Game Developer, Lighting and guiding](https://www.gamedeveloper.com/design/level-design-tricks-of-the-trade).
- Light islands as breadcrumbs: one designer builds light islands so the player can tell where they are going, with only important parts lit — [Game Developer search summary](https://www.gamedeveloper.com/design/level-design-tricks-of-the-trade) (secondary summary).
- Academic: a 2019 Press Start study looked at light, colour and architecture guiding players through large nonlinear 3D levels, as a way to reduce reliance on UI — [Press Start, Aug 2019](https://doaj.org/article/ab776b49ae504139be99f28f732d3d6b) (abstract only; not read in full).
- Foundry: player-built lights were a performance problem when players could light individual sources — [Foundry dev blog 17](https://www.paradoxinteractive.com/games/foundry/news/dev-blog-17-new-lighting-system-and-art-backlog) and the search summary of letting players light sources.

### Inferences
- Use a lit exit at every cave entrance and a lit landmark (glow grove, crystal cluster, hearth) at every fork. The lantern's light should lead to these points, not wander.
- Route light should be a warm or pale colour; dead ends and danger areas stay cool or dim. Coloured light can mark the route the way Witcher 3's red footprints mark it, but in light, not UI.
- Enemies should be introduced by a light, per the designer advice on enemy first appearance.

### Gaps
- No source for light distance or spacing values between landmarks.
- No source on how many player-made lights a multiplayer cave can handle; the Foundry note is a warning only.

## Player light: lantern radius, flares and glowsticks, shadows from the player's light

### Takeaway
The lantern should be the main way to see, with a clear radius and a fuel or time cost; flares and glowsticks are tools that give a bright, short burst. Shadows from the player light are costly, so the lantern should be the one shadowed light, and crystals and placed lights should not cast shadows.

### Cited Findings
- DRG flares: 25 s default light, 30 s with a modifier; flares are the main source, flashlight a last resort — [DRG Wiki](https://deeprockgalactic.fandom.com/wiki/High-Intensity_Flare?oldid=4239); [devtrackers.gg](https://devtrackers.gg/deep-rock-galactic/p/0bd9f650-all-my-issues-with-drg-flashlight-short-video-comparison-and-analysis).
- Core Keeper lanterns free the hands and add a glow stat; the glow stat is part of gear — [BisectHosting guide](https://bisecthosting.com/blog/core-keeper-lantern-stats-effects-how-to-get).
- Godot: one shadowed light costs one shadow render for a spot, six for an omni with cube shadows; a single shadowed directional light lowers resolution for all — from the earlier performance note, [Godot docs, Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html).
- Godot: distance fade needs Begin, Shadow and Length set; the light is invisible at Begin + Length — same page, quoted in the performance note.

### Inferences
- Lantern: one spot light with shadows (cheapest shadowed light, one render), with a short radius and a dim fall-off. This gives the "light from the player" feel that makes ledges and rock lumps readable.
- Flares: a bright, short point or spot light with shadows off (they are short-lived, so no shadow cost worth it), with volumetric fog energy 0 so they do not ghost. Use a 25-30 s timer like DRG, with a visible fade in the last seconds.
- Glowsticks or crystal lights: omni or spot without shadows, distance fade on. This matches the performance note.
- Fallback: a weak "night eye" ambient light when all lanterns and flares are out, so the player is never fully blind (Core Keeper's bug shows the risk).
- Co-op: each player's lantern is one shadowed light, so 4 players is 4 shadowed lights. That is still a small atlas, but test it against the 88-light budget from the performance note.

### Gaps
- No numeric lantern radius or fuel values from any game source; tune in game.
- No source on what Subnautica or DRG do for shadows from the player's light.

## Suggested next steps (for the report writer or the owner)
1. Build a cave test scene in Godot 4.7 with: one spot-light lantern (shadows on), two flare-type lights (shadows off), emissive crystals, a fog volume, and one AgX/Filmic comparison against painted sheets.
2. Check the Godot 4.7 Environment and post-processing and volumetric fog pages directly for exact defaults (the fetch was blocked here).
3. Ask for a follow-up on Minecraft caves, Spelunky 2 and Ori if the owner wants more reference games.
