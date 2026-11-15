# Master feedback list

Every piece of feedback you give goes here, **even after it's fixed**.
Fixed items get ~~crossed out~~, never deleted, so we can see the whole history.

**How to read it**
- `[ ]` = still to do. `[x]` + ~~crossed out~~ = done (with the date and what changed).
- **Said** = how many times you've brought it up. If something comes back after it was "fixed",
  it gets a 🔁, moves back to the top, and goes in **Things that keep coming back** below,
  because that means the fix didn't really work.
- **From:** *you* = you said it. *Claude* = Claude spotted it in a play session and you said "yes, fix it".

---

## Things that keep coming back 🔁

- **F25, the dwarf doesn't look dwarvish (said 2×).** 1st time: "short and wide". Claude 3 made a rigged dwarf, a bit better. 2nd time: "legs and arms should be shorter". 2nd try (Claude 3): thick short bones, broad shoulders, barrel chest. 3rd time: "looks like a bulky guy". Next try: stout and round, not muscular. About 4 heads tall, a round belly, stubby legs, arms reaching the hips at most.

## Patterns (what kind of things you notice most)

| Area | Items | Notes |
|---|---|---|
| Seeing in the dark (light) | F1, F12 | The lantern comes up a lot: brightness, then refilling |
| Moving around (walking, jumping, climbing) | F2, F3 | |
| Controls + camera | F18, F23, F27 | |
| Making the game / tools | F4, F5, F6, F7, F16 | |
| Sound | F8, F15, F67 | Sounds must feel old-world: wood, stone, leather, metal. No beeps or whooshes |
| The start of the game (first 5 minutes) | F10, F11 | |
| A world that feels alive (enemies, ruins) | F9, F21 | Columns asked for twice (F9, F21) |
| Cave shapes (round vs sharp, tunnels) | F19, F20 | |
| Digging feel + resources | F13, F14 | |
| Pictures / looks | F17, F22, F24, F25, F26, F28, F29, F30, F31, F68, F69, F70, F71, F72 | **The dwarf's look keeps coming up (F25 said twice)** |
| Model quality (stations, gear, building pieces) | F34-F66 | Most common: parts floating / not touching (8 notes), too-perfect shapes, flat colour, loose rope |

---

## Open (still to do)

*(Nov 14, after your first real play session. You chose: merge everything into main; start kit = rocks + roots + 1 crystal; 25–50 chunks; copper very rare.)*

- [ ] **F28. Sometimes the game loads with textures, sometimes plain and blocky.** Not a loading bug: there are 2 versions. **main** (the desktop icon, Claudes 1+2) has plain colors. Claude 3's **visuals** copy has textures, the new dwarf and new monsters, but hasn't been merged into main yet (20+ changes). Fix: Claude 3 merges visuals into main, then everyone uses the one version. *From: you. Said: 1×*
- [ ] **F24. The beard isn't attached to the face.** → Claude 3, on the `visuals` branch: the pack's little beard stays small on the face, and a real full beard grows from the jaw down over the chest. Waiting for you to look. *From: you. Said: 1×*
- [ ] **F25. The dwarf doesn't look dwarvish.** Should be short and WIDE, with shorter legs and arms, not a "small guy". → Claude 3, on the `visuals` branch: stubby legs (measured: 34% of the height), short arms that end at the hips, a round belly (not muscles), a big head, big hands and boots. Waiting for you to look. *From: you. Said: 3×* ("short and wide"; "legs and arms should be shorter"; "a bulky guy: shorter legs, shorter arms, maybe fat")
- [ ] **F26. The long things hanging from the ceiling look like icicles,** the same width top to bottom. Real stalactites: wide at the top, getting thinner, a rounded tip, smaller ones around them. (They're actually roots, so roots should look like roots too.) → Claude 3, on the `visuals` branch: roots are twisted, knobbly wood that forks into thin strands, and real stone stalactite clusters hang from the ceilings. Waiting for you to look. *From: you. Said: 1×*
- [ ] **F29. The game looks too "Roblox-y".** Make it look more like Valheim (Grounded if possible): real textures, better colours and shapes, not super realistic. → Claude 3, on the `visuals` branch: hand-painted rock, darker cave with fog and dust, painted grain on everything, fire, lantern, effects, cave clutter, monsters that move. Waiting for you to try it. *From: you. Said: 1×*
- [ ] **F30. Animations: running, jumping, swinging…** → Claude 3, on the `visuals` branch: a real 3D dwarf with idle, walk, jog, sprint, jump + landing, mining swing, axe chop, sword attacks, roll, block, shield, crossbow, getting hit, eating, climbing ladders, getting up; friends see it in co-op. *From: you. Said: 1×*

- [ ] **F31. Monsters: start with snails, bats and a beetle, polish them first.** Snails slow but hit hard, hide in the shell after a few hits (90% less damage); big bats that swoop in, attack, fly out; a beetle. Drops and uses chosen in a multiple-choice session (docs/design/monsters-first-three.md). → Claude 3, on the `visuals` branch: built; the other monsters are hidden for now. Waiting for you to try it. *From: you. Said: 1×*
- [ ] **F34. Hand-built station models: second pass.** Anvil too simple (horn looks like a pyramid); bed too blocky (mattress, pillow, cover); fires are blobs (campfire, cooking pot, smelters, sconce); chest has big blocks at the bottom; copper chest should look different from the normal chest; stone chest → a stone crate; water in the copper basin and drip bucket (and the odd drop); farm-plot mushrooms; glow torch rope and top need more detail; ore crate ores float; rope doesn't look like rope; rune too simple; stray green bits on the rune slab and smelter; tanning-rack hide looks wacky; training dummy should be stone with more detail; cooking pot has a stick going into the pot. Loved: workbench, gem bench, masonry table, top of the chest. → Claude 2, in progress. *From: you. Said: 1×*

*(Nov 14, your notes on every station, weapon, outfit and building piece. Full details, grouped by kind of problem: `docs/art/MODEL-FEEDBACK-2026-11-14.md`. New rule: every model in the workbench style; ChatGPT pictures whenever they help.)*

- [x] ~~**F34. Bellows need a lot of work.** Boards, handles and nozzle float apart; remake as one hinged piece with leather pleats.~~ Done Nov 15 (Claude 2): New bellows from the night picture: one piece, two pear-shaped boards with handle loops, pleated leather between them, copper nozzle and hinge strap, on a stand. *From: you. Said: 1×*
- [x] ~~**F35. The campfire still floats a bit.** ("still": it was meant to be fixed before.)~~ Done Nov 15 (Claude 2): New campfire: stones sitting in a dirt patch, logs resting on the embers; the automatic check finds nothing floating. *From: you. Said: 1×*
- [x] ~~**F36. The carpentry table needs more stuff on it.**~~ Done Nov 15 (Claude 2): Carpentry bench now covered in work: plank stack, saw, mallet, square, shavings, pegs, a vise, a shelf with a tool box. *From: you. Said: 1×*
- [x] ~~**F37. The chest's base is still wider than the lid; make them match.**~~ Done Nov 15 (Claude 2): New chest: base exactly as wide as the lid, copper straps and corners, lock plate, rope handles. *From: you. Said: 1×*
- [x] ~~**F38. Chopping block: the axe doesn't look like an axe; the tree rings stick out and are perfect circles.**~~ Done Nov 15 (Claude 2): New stump with roots and bark, uneven rings, a real axe (wedge head, leather grip) bitten into it. *From: you. Said: 1×*
- [x] ~~**F39. Cooking pot soup looks the same everywhere; needs a gradient and texture.**~~ Done Nov 15 (Claude 2): Stew now has a dark broth, a red middle and chunks; the pot hangs from a real 3-leg tripod (F64). *From: you. Said: 1×*
- [x] ~~**F40. Copper drip basin water is one flat shade.**~~ Done Nov 15 (Claude 2): Water now has depth: a dark bottom layer, a lighter top and a pale ring (basin, bucket, grindstone, fountain). *From: you. Said: 1×*
- [x] ~~**F41. Grindstone: the side wood blocks aren't attached; the blue bottom needs a darker gradient.**~~ Done Nov 15 (Claude 2): New grindstone: every block on one base, iron brackets, crank, stone trough with darker water. *From: you. Said: 1×*
- [x] ~~**F42. Ore Crate: the gems float above the pile** (the F33 pile).~~ Done Nov 15 (Claude 2): The ore now sits on a real heap shape, with the lumps and crystals sunk into it. *From: you. Said: 1×*
- [x] ~~**F43. Rune slab: the top-left of the frame is missing.**~~ Done Nov 15 (Claude 2): The carved border is now a raised frame set forward, so all four corners show. *From: you. Said: 1×*
- [x] ~~**F44. The stone saw floats, not attached to anything.**~~ Done Nov 15 (Claude 2): New stone saw: the frame saw stands in the cut of the stone (F65), on a heavy sawhorse. *From: you. Said: 1×*
- [x] ~~**F45. Tanning rack: lean it back with supports (like Valheim).**~~ Done Nov 15 (Claude 2): New tanning rack: leans back on two lashed props, the hide is laced on with rope. *From: you. Said: 1×*
- [x] ~~**F46. Tool rack: hang it on the wall instead of standing.**~~ Done Nov 15 (Claude 2): New tool rack is a wall board (flat back). Claude 1 still has to let it snap onto walls in the game. *From: you. Said: 1×*
- [x] ~~**F47. Training dummy: a lumpy, not-perfect square head.**~~ Done Nov 15 (Claude 2): New dummy: lumpy stitched sack head with an angry face, straw arms, straw skirt. *From: you. Said: 1×*
- [x] ~~**F48. Bolts: better feathers; tips in different crystal colours.**~~ Done Nov 15 (Claude 2): Bolts are longer, with three real feathers and big crystal tips: grey, red, blue, green, amber. *From: you. Said: 1×*
- [x] ~~**F49. Building hammer: no spikes, just iron plates on the sides (it's for building).**~~ Done Nov 15 (Claude 2): The building hammer is now a mallet with iron plates on both faces, no spikes. *From: you. Said: 1×*
- [x] ~~**F50. Crossbow string must be tight.**~~ Done Nov 15 (Claude 2): The string runs tight and straight from each bow tip to the nut. *From: you. Said: 1×*
- [x] ~~**F51. Shield back: a big forearm strap + a hand grip near the edge (Spartan style), not 2 sticks.**~~ Done Nov 15 (Claude 2): Shield backs now have a wide leather forearm strap with a buckle and a wrapped hand grip near the rim. *From: you. Said: 1×*
- [x] ~~**F52. Copper spear: tighter rope.**~~ Done Nov 15 (Claude 2): The spear's rope is wound tight with no gaps, plus a binding under the head. *From: you. Said: 1×*
- [x] ~~**F53. Copper sword: tight rope along the whole handle, no gaps.**~~ Done Nov 15 (Claude 2): The sword's rope covers the whole handle with no gaps. *From: you. Said: 1×*
- [x] ~~**F54. Stone tools too perfect: chip them more. Stone sword has rope sticking out.**~~ Done Nov 15 (Claude 2): Stone heads are chipped much more; the stone sword lost the rope that stuck out of its blade. *From: you. Said: 1×*
- [ ] **F55. All outfits too blocky and simple; remake (ChatGPT pictures).** *From: you. Said: 1×*
- [x] ~~**F56. Material items need remaking too.**~~ Done Nov 15 (Claude 2): All 48 material items remade from the 4 night pictures. *From: you. Said: 1×*
- [x] ~~**F57. Doorway should be round, like a hobbit door.**~~ Done Nov 15 (game code): the Doorway and the Door are round-topped (curve starts at 1.3 m). The stone Arched Doorway has a ring of wedge stones. Claude 2's hand-made door and doorway models are still square, and are being remade round. *From: you. Said: 1×*
- [x] ~~**F58. White stuff shows on the edges of pieces when you turn** (doorway, stone, arches in clay brick and copper).~~ Done Nov 15. Cause: the shader's "rim light" lit up every surface seen edge-on, no matter where the light was. A stone wall is dozens of small blocks with gaps, so turning made white streaks on all their edges. The rim light is now off for building pieces (props and monsters keep it). *From: you. Said: 2×* (doorway/stone; arches)
- [x] ~~**F59. Arches (clay brick, copper) look weird.**~~ Done Nov 15. The curved stones were separate boxes poking into the opening, overlapping the beam on the same flat face (that flickers). Now the arch is a real curve of wedge stones that meet edge to edge, with the corners above filled in. *From: you. Said: 1×*
- [x] ~~**F60. Each building material should have its own design, not a reskin; each tier a bit fancier.**~~ Done Nov 15 (Claude 2): Three styles, each its own design: Delver's Shack (logs, planks, shingles), Stonehold (stone in 4 tones, copper bands, flat roof, battlements), Hearthbrick (bricks, limestone, terracotta tiles). *From: you. Said: 1×*
- [x] ~~**F61. Barrel rings don't touch each other.**~~ Done Nov 15 (Claude 2): Wide copper bands now hug the barrel's bulge at every height; a lid handle and a copper tap. *From: you. Said: 1×*
- [x] ~~**F62. Beams: halves don't touch, a beam can't be 2 bricks; no perfect rectangles anywhere (curves, scratches, texture).**~~ Done Nov 15 (Claude 2): Beams are single rough logs or timbers now (no halves, no bricks); every block is a little uneven and tilted. *From: you. Said: 1×*
- [x] ~~**F63. Drop 3 mine props from the decor set: pickaxe in a rock pile, winch with bucket, tunnel support frame.**~~ Done Nov 15: mine props picture redone with only the other 5. *From: you. Said: 1×*
- [x] ~~**F64. Cooking pot tripod needs a third leg behind.**~~ Done Nov 15 (picture): new pot on a real 3-leg tripod. The 3D model still needs it. *From: you. Said: 1×*
- [x] ~~**F65. Stone saw: the station is decent, but the saw on top is not physically possible.**~~ Done Nov 15 (picture): a frame saw whose blade sits in a cut in the stone. The 3D model still needs it. *From: you. Said: 1×*
- [x] ~~**F66. Lineup: change the smart dwarf to the old one (match his head sheet).**~~ Done Nov 15: new lineup, old smart dwarf with the long forked beard; happy and strong unchanged. *From: you. Said: 1×*

**Claude noticed, waiting for your OK** (not fixed until you say so):

- [ ] **N1. Spore Rock Beetle: one leg floats loose under the body** (seen in `docs/art/creatures-2026-11-15/all_12_models.jpg`, bottom right). Found by Claude on the Mac, Nov 15. Fix when you say yes.

## Done

- [x] ~~**F72. Creatures need variety, like the cave itself.**~~ Done Nov 14 (Claude 3, waiting for your look). Every part has its own texture (waxy shell, rock knobs, three pebble colors, mossy rock, glowing gem clusters, grainy shield). Each creature now has hand-built versions and the game picks one per creature, plus a slightly different size: beetles 4 each (horn curved / bent / broken / forked, gems amber / teal / violet, more or less moss), bats 4 colors (+ torn ears), snails 3 colors. Co-op friends see the same individual. *From: you. Said: 1×*
- [x] ~~**F71. Rock Beetles, 2nd pass.**~~ Done Nov 14 (Claude 3, waiting for your look). Rebuilt after real "ironclad" beetles: two wing cases with a groove, a waxy shell with black drops, rows of knobs (rock, pebbles, mossy stones), four big knobs at the back, a flared spiky rim, a grainy front shield with humps and spiky corners. Charging: head down, back end up, red eyes, and the cracks in the shell glow like coals. Standing still, all six feet are on the ground; walking uses a real insect walk (two sets of three legs in turns). The Great one has spike rows, bigger spikes and side horns. *From: you. Said: 1×*
- [x] ~~**F70. Cave Bat asleep: it lies flat on the ceiling.**~~ Fixed Nov 14 (Claude 3, waiting for your look). It now hangs head-down by its feet, with folded wings wrapped round its body like a cloak (built as their own pieces, shown only while it sleeps). In flight the wings half-fold on each upstroke and the body lifts with each beat. Four fur colors (brown, ash grey, rust, sandy); some have a torn ear. *From: you. Said: 1×*
- [x] ~~**F69. Rock Snail, 2nd pass.**~~ Done Nov 14 (Claude 3, waiting for your look). Hiding: the whole body, tail too, shrinks into the shell, the shell settles onto the ground, and only two small eyes peek out. New body: real snail skin (little bumps with grooves), a fleshy collar where it meets the shell, a breathing hole on its side, a ridge and dark stripe down the tail, an ochre wavy skirt edge, snout lobes, ringed eye stalks that sway as it looks around, and the body ripples as it crawls. Three versions: slate, olive, rusty (shells grey, sandy, dark slate; one grows a violet crystal). *From: you. Said: 1×*

- [x] ~~**F68. The monsters look like raw blocks. Build them the way Claude 2 hand-built the anvil.**~~ Done Nov 14 (Claude 3, `visuals`, version 1, waiting for your look). All three are now hand-built in Blender with Claude 2's kit plus a new "creature" add-on: the Rock Snail has a real spiral stone shell with growth ridges and moss, and one soft, damp body that pulls in when it hides; the Cave Bat has real bat wings (finger bones with skin between, scalloped edges), fur, big ears and fangs; the Rock Beetle has a domed stone shell, a curved horn, hooked jaws, six jointed legs and the glowing soft back end. The Great Rock Beetle gets side horns, a darker shell and more moss. Legs walk, wings flap and the snail's body hides in the game. See them in the 3D viewer. *From: you. Said: 1×*

- [x] ~~**F67. The sounds feel futuristic; they don't match a medieval game.**~~ Fixed Nov 14 (Claude 3, `visuals`). Claude drew every sound as a picture to find the "computer" ones: the bag open/close was a rising sci-fi whoosh, the pickup was a synth pluck, the lantern refill was a pure beep, and the monster death was an electronic tone. All 4 are now real recordings of cloth, leather and a metal latch, and a heavy thud for deaths. The new creature sounds are built only from real recordings too: a door creak sped up = bat squeal, cloth = wing beats, a heavy thump = snail slam. Waiting for you to listen. *From: you. Said: 1×*

- [x] ~~**F32. Kiln + smelter that work on their own.**~~ Done Nov 14. New **Kiln** (Workbench: 15 stone, 8 clay) and **Coal**.
  - Put a chest (or the Ore Crate) within 5 m. The Kiln takes wood from it and puts coal back in.
  - The **Smelter** takes ore and fuel (coal first, then wood) from nearby chests and puts the bars into a chest.
  - The **Twin Smelter** does both: one side smelts, the other makes coal. Coal also works as fuel when you smelt by hand.
  *From: you. Said: 1×*
- [x] ~~**F33. The Ore Crate should look fuller the more you put in.**~~ Done Nov 14. A pile of ore (Claude 2's model) shows inside the crate and rises as you fill it: a few ores already show, and it's heaped up at about 400 items. *From: you. Said: 1×*

- [x] ~~**F27. The game grabs my mouse even when I'm in another program, and Claude's tests take my mouse.**~~ Fixed Nov 14. When you switch away (click another window or Alt+Tab), the game lets go of the mouse and pauses. Click back into the game to keep playing. Claude's test robots only *pretend* to hold the mouse now, so they never touch yours. *From: you. Said: 1×*
- [x] ~~**F23. Real equipment slots.**~~ Done Nov 14. 9 slots in the bag window (Tab): Pickaxe, Lantern, Weapon, Shield, Head, Chest, Legs, Feet, Pack.
  - With an empty hand (or just holding rocks), you dig with the equipped pickaxe. **F** draws or puts away the equipped weapon.
  - **Right-click** an item to equip it or take it off. Pickaxes, lanterns, clothes and backpacks put themselves on when you get them.
  - Armor soaks up damage (2% per point, at most 60%): a leather set (workbench, 22%) and a copper set (anvil, 48%).
  - A **Leather Satchel** opens 10 more bag slots.
  - Equipped things stay with you when you die.
  - Pictures by Claude 2. *From: you. Said: 1×*
- [x] ~~**C1. The game only runs at ~50 FPS on the RTX 3060 Ti.**~~ Explained + sped up Nov 14. Claude 3 measured it: the ~50-60 is just the frame cap. Your screen is 60 Hz and "vsync" holds the game to it. Without the cap it runs ~200-300 FPS. Speed-ups along the way: glowing things are now found through a grid instead of checking every one (Claude 3), and the block-breaking burst reuses its shapes (Claude 1). A few small hitches remain, from the cave re-building itself after digging. *From: Claude (first PC run). Said: 1×*
- [x] ~~**F21. Columns should look better, like great dwarf halls, not just blocks.**~~ Done Nov 14. Carved columns: a stepped base, an 8-sided shaft with 2 bands that narrows toward the top, and a wide stepped top. Broken ones snap off with a jagged top, and their fallen pieces and rubble lie around them. *From: you. Said: 1×*
- [x] ~~**F20. More tunnels, like Minecraft.**~~ Done Nov 14. About 3x the tunnels: more loops, more dead ends, and 16 twisty side passages per area that branch, cross, climb and dip. *From: you. Said: 1×*
- [x] ~~**F19. Caves too round: make a 50-50 mix of smooth and sharp/rocky.**~~ Done Nov 14. Big patches of the cave are either smooth and round, or sharp and angular like broken stone. Measured: 49.6% rocky. *From: you. Said: 1×*
- [x] ~~**F9. The world feels empty: enemies, abandoned structures, columns.**~~ Done Nov 14. The merge brought monsters, 3 bosses, ruins, camps and shrines. Ruins now have carved columns (mostly broken) and crumbling block walls, and 1-2 rows of great columns stand in every big cavern (9 in cave 42). *From: you. Said: 1×*
- [x] ~~**F22. Holding a pickaxe when I have nothing.**~~ Fixed Nov 14. Any non-tool (empty hand, rocks, food) used to fall back to drawing a pickaxe. Now an empty hand holds nothing. *From: you. Said: 1×*
- [x] ~~**F17. Pictures for items.**~~ Done Nov 14. Claude 2 made 170 item pictures, and Claude 1 shows them in the hotbar and bag (the old colored square only if a picture is missing). *From: you. Said: 1×*
- [x] ~~**F15. A menu to mute/unmute and change the volume.**~~ Done Nov 14. On the pause screen (Esc): a Sound slider and a Mute switch, remembered next time. *From: you. Said: 1×*
- [x] ~~**F14. Copper is too common.**~~ Fixed Nov 14. Measured: copper went from 8% of the cave wall rock down to 1.3% (1/6, as you chose). Jungle silver is unchanged. *From: you. Said: 1×*
- [x] ~~**F13. A broken block should burst into lots of pieces.**~~ Done Nov 14. 25-50 little bits pop out, tumble, then fly into you. Still 1 item, like before. *From: you. Said: 1×*
- [x] ~~**F12. Refilling the lantern was impossible.**~~ Fixed Nov 14. Two reasons: most crystals grew too high to reach, and R failed silently (for example when the lantern was nearly full). Now every cavern has crystals at dwarf height, R always says what's wrong, and rootwood works as fuel too. *From: you. Said: 1×*
- [x] ~~**F11. Start with nothing: pick up rocks, craft a pickaxe and a lantern.**~~ Done Nov 14. 6 loose rocks, 1 crystal and 3 thin roots (pull them by hand) in the room. Tab: Stone Pickaxe (3 stone + 2 rootwood) and Lantern (2 stone + 1 rootwood + 1 crystal). A hint line tells you each next step. *From: you. Said: 1×*
- [x] ~~**F10. Start in a small room with a glowing hole, dig through, run a tunnel, reach the cave.**~~ Done Nov 14. A small sealed room, a soft dirt wall with a glowing crack (light leaking through), and a 15-20 m tunnel to the first big cavern. Tested on 6 different caves. *From: you. Said: 1×*
- [x] ~~**F18. The mouse wheel should zoom the camera, not change the hotbar. Hotbar = keys 1-9.**~~ Done Nov 14. The wheel zooms smoothly from 1.4 m to 8 m behind the dwarf, and the hotbar now has 9 slots (keys 1-9). *From: you. Said: 1×*
- [x] ~~**F16. Merge all the steps (up to the Fungal Jungle) into main.**~~ Done Nov 14. The desktop icon now plays everything: crafting, survival, building, monsters, ruins, bosses, the Fungal Jungle. 214 auto-checks pass, and the autopilot played through all of it. *From: you. Said: 1×*
- [x] ~~**F8. Mute only Claude's tests. When I play, I want sound.**~~ Fixed Nov 14. Muting was already only for Claude's test runs. The real problem was that Step 1 had **no sounds at all** (they'd only been built on the Step 6 branch). Now Step 1 has 11 sounds from Kenney's free packs: pickaxe swing, digging (soft for moss/dirt, hard for stone), rock breaking, a "clink" on rock that's too hard, crystals, footsteps, pickups, lantern refill, and bag open/close. *From: you. Said: 1×*

- [x] ~~**F1. The lantern is too dim.**~~ Fixed Nov 14. The dwarf's own body *and* the lantern's glass box were blocking the light, like holding a flashlight behind your back. Now neither blocks it, and the light reaches further. *From: Claude (test session), you said yes. Said: 1×*
- [x] ~~**F2. The dwarf gets stuck on small ledges and bumps.**~~ Fixed Nov 14. The dwarf now steps up anything up to 50 cm tall by itself, like stairs. Taller walls still need a jump. *From: Claude (test session), you said yes. Said: 1×*
- [x] ~~**F3. Add a jump.**~~ Fixed Nov 14. Space already jumped, but on bumpy cave floors it often didn't work, because the game wasn't sure the dwarf was standing. Now a jump works for a moment after you walk off an edge, and if you press it just before you land. It's a bit higher too (about 1.5 m). *From: you. Said: 1×*
- [x] ~~**F4. Record the game every time I play, automatically.**~~ Done Nov 14 (OBS auto-recorder). *From: you. Said: 1×*
- [x] ~~**F5. Put the game on my desktop.**~~ Done Nov 14 ("Dwarf Game" icon, plus a "Dwarf Game Sessions" folder icon). *From: you. Said: 1×*
- [x] ~~**F6. Mute the game while Claude is testing.**~~ Done Nov 14. Every Claude now runs the game silent. *From: you. Said: 1×*
- [x] ~~**F7. No feedback pop-up; I'll say it in chat.**~~ Done Nov 14. The box is off. Claude still checks every session by itself. *From: you. Said: 1×*
