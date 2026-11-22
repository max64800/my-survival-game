# What Makes Base-Building Satisfying in Survival Games

Scope: sourced design rules for snapping pieces, placement controls, stability, comfort buffs, building UI, and tight underground building, each tied to an action for our 3D underground dwarf co-op game (root wood / Stonehold stone / Hearthbrick clay pieces, half walls, diagonal walls, roofs, stairs, round doors, blueprints, ruins, support beams, digging rooms out of rock).

Source-quality note: the search pass was short (about 15 tool calls). Most sources are player forums (Steam, Funcom, Nexus, Thunderstore), third-party guides, or press. Official developer devlogs were hard to reach. Several older sources are from 2015-2016 (Fallout 4) and 2017-2019 (Conan forums). Each finding is marked **[Sourced]** (a page said it), **[Anecdotal]** (one player or forum post), or **[Inference]** (my reasoning from the sources, for our game).

---

## 1. Snapping vs. free placement vs. rotation steps (the owner's "45° per press" complaint)

### Takeaway
Players praise snapping when it is predictable, and they complain when it grabs the wrong point. The fix that keeps appearing across games is to let the player choose the snap point and to let them place freely while holding a key, not to remove snapping.

### Cited Findings
- **[Sourced]** Valheim's manual snapping feature (Iron Gate's Jonathan Smårs, Feb 10, 2023 announcement) was built "to solve the age-old problem of building floor supports, etc." The pivot point moves from the piece's middle to its corners or ends. Players pick which snap point to use, and holding Shift places a piece freely without snapping. [Source: PCGamesN, "Valheim building set to get way easier with snapping update"](https://www.pcgamesn.com/valheim/building-snapping-update)
- **[Sourced]** The same Valheim article says the older behaviour was pieces auto-snapping to nearby objects and jumping between snap points in an awkward way. Stone bricks have eight connection points to choose from. [Source: PCGamesN](https://www.pcgamesn.com/valheim/building-snapping-update)
- **[Sourced, search snippet]** A later Valheim patch added manual snap-point choice with Q and E for precision building. [Source: GameStar patch-note reprint, listed in search results](https://www.gamestar.de/artikel/update-valheim-wikinger-sandbox-flexibel-optionen,3399519,seite2.html) (confirm wording before quoting)
- **[Anecdotal, Fallout 4, 2015-2016]** Players said snapping "always" caused trouble, walls snapped the wrong way, atrium ceilings snapped correctly "about half the time," and there was no in-game snap toggle. Holding E to disable snapping did not work well because the piece snapped back on release. Players asked for finer or slower rotation. [Sources: Steam Community Fallout 4 discussions, e.g. https://steamcommunity.com/app/377160/discussions/0/312265526375692366 ; Nexus thread "possible to slow down object rotation in build mode," https://forums.nexusmods.com/topic/4522655-possible-to-slow-down-object-rotation-in-build-mode ; Nexus "mod request more snap controls," https://forums.nexusmods.com/topic/13274283-mod-request-more-snap-controls-snappable-buildings]
- **[Sourced, Fallout 4 mod]** The Place Everywhere mod lets players toggle item and floor snapping, which shows that a snap toggle was a community request. [Source: Nexus Fallout 4 mod thread, https://www.nexusmods.com/fallout4/mods/28834?tab=posts ] (mod-page claim, not an official feature)
- **[Anecdotal, Conan Exiles]** Players asked for a hold-to-place-freely button because "snap points and piece orientation often refuse to change." [Source: Funcom forum "Frustrating build system," https://forums.funcom.com/t/frustrating-build-system/79451]
- **[Sourced, Conan Exiles forum]** Rotation is limited to 90° and 60° combinations, so players use "scaffolding" (extra pieces) to reach other angles. [Source: Funcom forum "Fence foundation rework suggestion," https://forums.funcom.com/t/fence-foundation-rework-suggestion/174548]
- **[Anecdotal, Conan Exiles]** Pieces sometimes flip orientation unexpectedly, especially fence foundations, which a player called "extremely irritating." Players asked for an orientation lock. [Source: Funcom forum "Suggestion: Orientation Lock," https://forums.funcom.com/t/suggestion-orientation-lock/172460]
- **[Sourced, Conan Exiles bug list]** A known build-hammer issue made the placement ghost cycle through many snap points, sometimes putting pieces inside meshes or in the wrong spot. [Source: Funcom forum "Current Bugs & Issues Pt. 2," https://forums.funcom.com/t/current-bugs-issues-pt-2/269980]
- **[Sourced, practitioner forum]** Satisfactory's grid/free mix: a guide says holding left Ctrl in build mode toggles between free-form and snap-to-world-grid. A guide advises using grid snapping early so later expansion is easier. [Source: VideoGamer, "How to snap to world grid in Satisfactory," https://www.videogamer.com/guides/satisfactory-how-to-snap-to-world-grid]
- **[Sourced, practitioner]** Fortnite-style building uses a strict 1 m grid with four piece types. The reported strengths are speed, simplicity, and tight combat integration. [Source: Skillselion case-studies reference, https://skillselion.com/skills/bbeierle12/skill-mcp-claude/case-studies-reference] (secondary aggregator; treat as a lead, not a verified source)
- **[Anecdotal, developer forum]** A dev suggested highlighting connection points and snapping to ends or midpoints. [Source: Unreal Engine forum "Snap Builder like most survival games," https://forums.unrealengine.com/t/snap-builder-like-most-survival-games/54308]

### Inferences (for our game)
- **Offer both modes and make the switch easy:** normal snapping for most pieces, a "free" mode while holding a key (Valheim's Shift, Satisfactory's Ctrl idea). This answers the "can't line things up" complaint without throwing away the snap that keeps walls tidy.
- **The 45° step is the likely cause of the complaint.** Valheim and Fallout 4 players both asked for finer or slower rotation. Consider a fine step (for example 15° or 5°, or hold a key to step finer) plus a default that snaps to the wall's own edge. Conan's 90/60 limit made players build scaffolding, which is a warning sign for us.
- **Show the snap point.** Valheim's Q/E snap point choice is more useful when the player can see which corner or end is active. Highlight it on the ghost.
- **Half walls and mixed materials:** the Conan orientation-flip complaints suggest that a piece should keep its orientation when the material changes. Stone and wood half walls should share the same snap points so they can sit side by side.

### Gaps
- No official Iron Gate devlog text on the rotation rules was reachable (the Valheim rotation/snap source is a press article quoting the dev's video). Patch-note wording on Q/E was from a German reprint only.
- No 2020-2026 source on Fallout 4 or Conan rotation changes was found. Those complaints are from 2015-2019 forums.

---

## 2. Stability / structural integrity: fun or annoying, and how to show it

### Takeaway
Players accept a support system when the game shows, in advance and in colour, why a piece will fall. They get annoyed when a block drops with no warning, or when a bug makes the rule look random.

### Cited Findings
- **[Sourced, guide]** Valheim colours pieces by support when you look at them with the hammer. A community guide describes blue for well grounded, green for well supported, yellow for losing support, and red for the weakest. A red piece can still stand, but a new piece built further from it usually collapses. [Source: Mobalytics Valheim building guide, https://mobalytics.gg/gamebase/guides/valheim-general-building-guide ; Gamepressure Valheim building guide, https://www.gamepressure.com/valheim/building/zde2ae] (guide sources; colour meaning not checked in the game)
- **[Sourced, mod page]** The Quads Build Orders mod shows a plan ghost coloured by support (blue solid, green to red weaker, red = would fall). A mod's description says red means the click does nothing, so the game blocks placement. [Source: Thunderstore, Quads Build Orders, https://thunderstore.io/c/valheim/p/Quads_Lab/Quads_Build_Orders/v/1.14.7/] (mod claim; vanilla ghost colours not confirmed)
- **[Sourced, 7 Days to Die community]** Integrity is described as max load divided by mass, rounded down. Players can add pillars every 4-5 blocks. Blocks have a "Vertical Support: Yes/No" stat. The pause-menu Structural Integrity Visualizer shows stability by colour. [Source: xgamingserver 7DTD guide, https://xgamingserver.com/blog/7-days-to-die-base-building-guide/ ; Steam post, https://steamcommunity.com/app/251570/discussions/0/3810656323963286462] (guide and forum claims; check current patch)
- **[Anecdotal, 7 Days to Die]** Players said building became "impossible" and blocks "dropped randomly." Others replied that collapses are part of learning the game. [Source: 7DTD Steam discussions, search results listed above, e.g. https://steamcommunity.com/app/251570/discussions/0/619568793945872474] (2023 posts)
- **[Sourced, bug report]** A 7DTD bug report says integrity was simulated before neighbouring chunks finished loading, so results were wrong. [Source: TFP community, https://community.thefunpimps.com/threads/possibly-a-bug-wrong-structural-integrity-calculation-on-incremental-chunk-loading.25299/latest]
- **[Sourced, Valheim]** Valheim's ghost/colour feedback is part of the "what would fall" lesson: the player sees the problem before placing. [same Valheim guide sources as above]

### Inferences (for our game)
- **Show support before placing.** Our blueprint and ghost preview should colour a piece green (fully supported), yellow (weak), or red (would fall), and refuse the placement when red. This matches the Valheim and 7DTD pattern and fits the owner's support-beam and cave-in plan.
- **Make the rule readable in one glance.** Use one number or icon per piece (for example "holds 3 more") rather than a formula.
- **Keep the support rule fixed and simple,** so players learn it once. Avoid rules that change with chunk loading (the 7DTD bug).
- **Cave-ins:** warn before the drop, in colour, and show the weak beam in the ghost. Let the player fix it before the stone falls.

### Gaps
- No 2020-2026 player-survey data on whether support systems are fun overall. Reactions above are forum posts.
- Vanilla Valheim ghost colours were not confirmed from an official source.

---

## 3. Comfort, buffs, and why players decorate

### Takeaway
Players build beautiful bases when the building itself changes something they care about (a longer buff, safety, a home). Pure decoration without a reason gets less use. A buff that rewards variety in categories makes players think about layout.

### Cited Findings
- **[Sourced, guide]** Valheim comfort controls how long the Rested buff lasts. The formula given is 7 minutes plus the current Comfort level. Comfort comes from furniture and misc items, and each category counts once, so multiple pieces of the same category do not add up. [Source: Exitlag Valheim comfort guide, https://www.exitlag.com/blog/valheim-comfort/ ] (aggregator-style guide; verify numbers in the current wiki)
- **[Sourced, guide]** Furniture must be within about 10 m of the player, and fires and lights must work. Players often leave a cold hearth and come back to no buff. [Source: Gamerevolution Valheim comfort levels, https://www.gamerevolution.com/guides/673919-valheim-comfort-levels-purpose-how-to-boost-pc ]
- **[Conflicting]** Guides disagree on the maximum comfort (17 vs 24 with a seasonal item) and on the regen numbers (+50%/+100% vs +200%/+300%). [Sources: Mobalytics comfort guide, https://mobalytics.gg/gamebase/guides/valheim-comfort-rested-guide ; Shacknews Maypoles, https://shacknews.com/article/123431/maypoles-in-valheim-everything-you-need-to-know?amphtml=1 ] Do not copy any number from these; check the wiki for the current patch.
- **[Anecdotal, Steam forum]** A player said the 10 m range forces all comfort items close together; others asked for a bigger range rather than a rework. [Source: Steam Valheim discussion, https://steamcommunity.com/app/892970/discussions/0/3841053719668056988/?l=turkish]
- **[Sourced, press]** PC Gamer says Enshrouded base building is especially exciting for builders, but "rarely sees a reward for the extra effort." [Source: PC Gamer, Enshrouded building roundup, https://pcgamer.com/mountain-keeps-hobbit-holes-and-sick-castles-enshrouded-players-are-hard-at-work-with-that-excellent-building-system ] (search-snippet summary; body not fetched)
- **[Sourced, search snippet]** GameSkinny's Enshrouded early-access review says building is "a time-sucking process," and a basic house with a door and roof took the reviewer about an hour. Decoration was limited in early access. [Source: GameSkinny, https://www.gameskinny.com/reviews/enshrouded-early-access-review-brave-the-fog/ ] (fetch was blocked with a 403; claim from search snippet only)

### Inferences (for our game)
- **Give every build a reason.** Our dwarf game could give a bonus per category of furniture, such as a bed, a lamp, a table, and a stone shelf, with a clear counter the player can see. This matches the "one per category" lesson.
- **Reward the effort in a way the player sees.** Enshrouded's "rarely rewarded" complaint says a bonus should be visible (for example "warm room +10 rest").
- **Keep the comfort range small and readable.** If the range is too big or too small, players stop caring. Show the range as a ring on the ground.

### Gaps
- Enshrouded's comfort or "building reward" feature was not confirmed. Search did not turn up an official Keen source.

---

## 4. Building UI: radial menus, categories, ghost colours, costs, uneven ground, camera

### Takeaway
The best-rated UIs show the piece, its cost, and whether it fits, all at once. Players complain most about a hammer or piece cycle that jumps between options.

### Cited Findings
- **[Sourced, Conan Exiles bug list]** The build hammer cycles the ghost through many snap points, which is hard to control. [Source: Funcom forum, https://forums.funcom.com/t/current-bugs-issues-pt-2/269980] (see section 1)
- **[Sourced, Enshrouded search results]** The Enshrouded Construction Hammer has an add mode and a remove mode for the same shape. Foundation blocks remove terrain in tidy cubes. You need the hammer and an active Flame Altar within range to place blocks. [Source: Allthings.how Enshrouded base building tips, https://allthings.how/enshrouded-1-0-base-building-tips-that-save-materials-and-time/ ] (guide claim; not checked in game)
- **[Anecdotal]** One Enshrouded streamer spent 3 hours digging a basement with a pickaxe before learning the Construction Hammer was much faster. [Source: GamesRadar, https://www.gamesradar.com/3-hours-into-manually-mining-out-their-basement-enshrouded-player-learns-the-survival-rpg-has-a-tool-that-would-have-done-it-in-an-instant ] (lesson: a fast tool must be found early)
- **[Sourced, developer interview]** Enshrouded's Creative Director said the team wanted props, terrain, and building blocks to stay modifiable, and said "getting the whole interface right was a bit of a struggle." [Source: Enshrouded director interview, ginx.tv, https://www.ginx.tv/en/?p=60975 ] (search-snippet summary)
- **[Sourced, Enshrouded AMA recap]** The World Design Team said voxel building "allowed for unique structures and deep customization." [Source: Enshrouded world design team AMA recap, https://enshrouded.com/de-DE/news/enshrouded-world-design-team-reddit-ama-recap ]
- **[Sourced, Valheim mods]** Community tools show snap-point rings and axis rings, which help precise placement. Vanilla UI was not confirmed. [Sources: Thunderstore GhostBuild, https://thunderstore.io/c/valheim/p/Azumatt/GhostBuild/ ; Runic Precision Build Tool, https://thunderstore.io/c/valheim/p/Chazman/RunicPrecisionBuildTool/ ] (mod claims)
- **[Sourced, practitioner]** A developer said that building with up to 2k instanced structures was feasible; with plain spawned objects, performance dropped at about 100k. [Source: Unreal forum, search snippet, https://forums.unrealengine.com/t/building-mechanics-wip-discussion-what-do-you-think-direction-to-head/19263 ] (developer forum claim; not verified)

### Inferences (for our game)
- **Hammer cycle fix:** the owner's "hard to get back to walls" complaint matches the Conan bug. Use a stable focus: the piece under the crosshair stays the target until the player moves away, and the wheel or key changes piece type, not the snap point.
- **Show cost and fit in the same ghost.** A green/red ghost with the cost next to it is the Valheim-style pattern.
- **Add/remove on one tool.** Enshrouded's hammer shows the same shape can add or remove. Our blueprint fill and dig could share one tool with a mode key.
- **Teach the fast tool early.** The Enshrouded pickaxe-first confusion suggests a dwarf tutorial should show the faster dig/room tool before the first basement.

### Gaps
- No radial-menu or camera-during-building source was found in this search. Not researched: camera zoom, radial vs list menus, and placing on uneven ground.
- No source on undo or repair was found for these games.

---

## 5. Enshrouded: voxel building and digging with prefab pieces (closest to our dig-anywhere caves)

### Takeaway
Enshrouded is the closest reference: players can dig and reshape voxel terrain and then place prefab-like pieces. Praise focuses on freedom and creativity. Complaints focus on slowness and a thin reward loop.

### Cited Findings
- **[Sourced, press]** The voxel system lets players edit the terrain; reviewers praise the freedom to build "absolutely anything." [Sources: PC Gamer 1.0 review, https://www.pcgamer.com/games/survival-crafting/enshrouded-1-0-review/ ; OpenCritic PPG review list, https://opencritic.com/ppg/review/16119/enshrouded ] (snippets; body not fetched)
- **[Sourced, search snippet]** Digital Trends reported that every voxel can be added or removed and the game does not use realistic physics, so builds do not topple. Blocks float where left. [Source: Digital Trends, https://digitaltrends.com/?p=3390102 ] (search-snippet summary)
- **[Sourced, press]** GamingTrend's preview says the tools make underground building "incredibly easy." [Source: GamingTrend preview, https://gamingtrend.com/enshrouded-preview-voxels-pickaxes-and-wingsuits/ ]
- **[Sourced, review]** GameSkinny says building is "time-sucking" and frustrating; a basic house took about an hour. [Source: GameSkinny, https://www.gameskinny.com/reviews/enshrouded-early-access-review-brave-the-fog/ ] (search snippet; fetch blocked)
- **[Sourced, press]** Players built mountain keeps and "hobbit holes" underground. [Source: PC Gamer, https://pcgamer.com/mountain-keeps-hobbit-holes-and-sick-castles-enshrouded-players-are-hard-at-work-with-that-excellent-building-system ]
- **[Sourced, count caveat]** The Steam review count is not stable across snapshots (around 39k vs 48k "very positive"). [Source: Enshrouded Steam page, https://store.steampowered.com/app/1203620/Enshrouded/ ]

### Inferences (for our game)
- **Digging is a building step.** Players want to dig a room and then place walls in it. Keep dig and place in one flow, with a quick "make room" tool.
- **Voxel freedom vs. prefab speed.** Enshrouded players praise free shapes, but they complain about speed. For us, blueprints (prefab) give speed; freeform digging gives freedom. Let blueprints and dig work on the same cave walls.
- **Keep the pieces clean on rough rock.** Enshrouded's tidy cube foundation pieces (from the guide) solve the uneven-rock problem by cutting neat blocks. Our round/diagonal pieces may need a similar "flat cut" tool on uneven rock.

### Gaps
- The Enshrouded building devlog was not found. The "prefab + voxel" mechanic details come from guides and press, not from Keen's own text.
- Not verified: whether Enshrouded has undo or support/integrity rules.

---

## 6. Building in tight underground spaces

### Takeaway
Little direct evidence was found. The strongest signal is from Enshrouded players, who built underground homes and praised easy underground building, and from the Enshrouded lesson that a fast dig tool is needed.

### Cited Findings
- **[Sourced, press]** Enshrouded players built underground homes "to rival the halls of Moria." [Source: GamesRadar, https://gamesradar.com/enshrouded-players-are-literally-going-deep-on-the-survival-games-building-systems-with-underground-homes-to-rival-the-halls-of-moria ] (headline and snippet; body not fetched)
- **[Sourced, press]** GamingTrend says underground building is easy in Enshrouded. (see section 5)
- **[Anecdotal]** A player's 3-hour pickaxe basement. (see section 4)
- **[Sourced, Valheim comfort]** Warm, sheltered rooms matter for comfort. Players only get the buff if the room is sealed and warm enough. [Exitlag guide, see section 3]

### Inferences (for our game)
- **Tight spaces need a clear fit check.** Show whether a piece fits in the dug room before placing (red ghost when it clips the rock).
- **Keep a "room" test.** A room is a space that is closed and has a light. This can feed the comfort buff and the cave-in check together.
- **Round doors and diagonal walls:** these shapes are where tight caves go wrong. Test them in narrow cuts first.

### Gaps
- No 2020-2026 source found on building in narrow cave tunnels, support beams underground, or cave-in warnings in survival games. This is the biggest gap for our game.
- No Minecraft, Space Engineers, Rust, or V Rising source was reached in this pass. Those remain open.

---

## Items not yet covered (for a follow-up search)
- Minecraft and Space Engineers: grid, rotation, and undo design (not reached).
- V Rising building rules (only one empty thread found).
- Undo, moving placed pieces, and repair (no usable sources found).
- Camera during building and radial menus (not reached).
- Official Keen Games (Enshrouded) and Iron Gate (Valheim) developer devlogs on building (the Valheim one is a press article; the Keen one was not reached).
- Player surveys on whether stability rules are fun (only forum posts found).

## Summary of Owner-Complaint Matches
| Owner complaint | Matching evidence | Suggested action (inference) |
|---|---|---|
| Pieces rotate 45° per press | Valheim Shift free-place and Q/E snap choice; Fallout 4 and Conan requests for fine rotation; Conan 90/60 limit | Finer rotation step, hold-key free mode, default snap to the wall's edge |
| Triangle half walls can't mix stone and wood | Conan orientation flips on fence pieces | Same snap points for every material; keep orientation when the material changes |
| Hard to get back to walls with the build hammer | Conan hammer cycling through snap points (bug list) | Stable focus on the piece under the crosshair; wheel changes type, not snap point |
