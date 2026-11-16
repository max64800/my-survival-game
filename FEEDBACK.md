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

- **F68, the monsters look like blobs / Play-Doh (said 3×).** 1st time (Nov 14): "raw blocks; build them the way Claude 2 hand-built the anvil". Claude 3 hand-built them. Then the Mac's creature guide and PC prompt said "use the 3D forge", so on Nov 15 Claude 3 replaced them with forged ones: soft and melted. 2nd time (Nov 15): "rebuild by hand, like the crafting tables". **Different approach now:** a written rule with a check (`docs/art/MODEL-RULES.md`, Rule 1: hand-built only, every model needs its build script), the creature guide rewritten, and the hand-built versions rebuilt to match the approved pictures, Rock Beetle first. 3rd time (Nov 15, late): hand-built, but "too simple, like Roblox, glued together". **Different approach again:** sculpt and bake by script (pieces melted into one skin, carved, painted, baked), one beetle at a time with your notes each round; every lesson goes into `docs/art/CREATURE-RECIPE.md` so the snail and bat start from it (F142-F148).
- **F19/F109, the caves look too round (said 2×).** 1st time (Nov 14, F19): "make a 50-50 mix of smooth and sharp". Tried: noise that makes big patches either smooth or sharp and angular (measured 49.6% rocky); still round, because digging scoops out balls and the caves are blended balls and tubes. 2nd time (Nov 15, F109). **Different approach now (Nov 16):** chunky 1 m blocks everywhere, like 7 Days to Die: every 1 m point of the cave is either rock or air (with a little random lopsidedness), digging removes one block, flattening works in blocks.

- **F79, rules that don't stick: roofs (said 1×, but the plan already said it on Nov 14).** The plan said Stonehold = flat roof only, sloped roofs hollow, but the build menu still offers every roof to every material and some roof pieces came out filled. **Different approach:** Rule 4 in `MODEL-RULES.md`, enforced in the build menu code with a test, plus a thickness test for roof pieces.

- **F82, tanning rack ropes not attached (said 2×, rope problems overall many times).** F45 (Nov 15) said "the hide is laced on with rope", but the lacing ropes still stop short of the hide, so it floats. **Different approach:** Rule 1 of MODEL-RULES plus the photo sheets (`tools/model_review/`): every rope must be checked from the side view, and the floating-parts check must treat the hide and ropes as separate parts that have to touch.

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
| Model quality (stations, gear, building pieces) | F34-F66, F73-F80, F82-F86 | Most common: parts floating / not touching (8 notes), too-perfect shapes, flat colour, loose rope |
| Creature looks (Rock Beetle rounds) | F68, F142-F148, F163-F164, F166 | Gaps between parts (stones, joints) said most; then the face. The same "touching, worn, not too clean" wish as the building pieces |

---

## Open (still to do)

*(Nov 15 evening, your play test on the PC. You chose the fixes from multiple-choice questions.)*

- [ ] **F87. Menu (priority).** Escape doesn't let you leave the game; you can't make a new world or delete one. Plan: Escape menu with Resume, Save, Save and go to the main menu, Quit to desktop; the main menu lists your worlds (play / delete with "are you sure?") and makes new named worlds. *From: you. Said: 1×*
- [ ] **F88. Hotbar items aren't shown in the bag (priority).** You had a pickaxe on the hotbar but not equipped, so it looked lost. Plan: the bag shows the hotbar row too; a pickaxe you carry is used for digging even if it isn't in the pickaxe slot. *From: you. Said: 1×*
- [ ] **F89. Losing your pickaxe can leave you stuck** (no stone without a pickaxe, no pickaxe without stone). You chose: dig with bare hands, slower, so you can always get stone. *From: you. Said: 1×*
- [ ] **F90. Fallen pillars/walls are ghosts** (you walk through them). You chose: they land as solid rubble you bump into and stand on, and you mine it back for some of the material. *From: you. Said: 1×*
- [ ] **F91. The hanging roots don't look good.** You chose: rebuilt by hand in Blender in the workbench style (gnarled, twisting, little side roots, a soil clump at the top), and some glow faintly at the tips. *From: you. Said: 1×*
- [ ] **F92. Crafting should take a little time.** You chose: 1-3 s, a progress bar fills and the dwarf does a working motion; walking away cancels it and you keep your materials. *From: you. Said: 1×*
- [ ] **F93. Dropped items are tiny.** Make them about 5 times bigger. *From: you. Said: 1×*
- [ ] **F96. See where things go before placing them.** When you place a workbench (or any station, chest, bed, campfire, lamp...), show a see-through preview of it where it will land, green when it fits and red when it doesn't, like the build hammer's ghost pieces. *From: you. Said: 1×*
- [ ] **F97. Raising a piece's height with Page Up / Page Down is awkward and hard to discover.** Hold Shift and turn the mouse wheel to raise or lower what you're building (foundations and everything else), with a hint on screen. *From: you. Said: 1×*
- [ ] **F98. Blueprints are there from the very start.** They should be earned later, not given right away. You chose: ready-made blueprints are pages found in ruins (or from bosses); saving your own builds stays allowed. *From: you. Said: 1×*
- [ ] **F99. The blueprint list has no pictures.** *From: you. Said: 1×*
- [ ] **F100. Taking a building piece down gives everything back.** You don't want free pick-up: a piece must be broken down and gives back 80% of its materials. You chose: two different buttons. Careful pick-up gives everything back, but only within 10 s of placing it (for misclicks); breaking gives 80%. Crafting stations can always be picked up and give the station back. *From: you. Said: 1×*
- [ ] **F101. Couldn't get back to walls with the build hammer, and everything built turned blue.** (Found: after choosing a blueprint, the hammer stays in blueprint mode, and each click makes a blue build site with a Builder's Chest.) Needs an obvious way back to single pieces. Nov 15 (PC): picking any piece in the B menu now leaves blueprint mode ("Back to building single pieces."), and the hint says right click or B goes back; still to do: blueprint pictures (F99). *From: you. Said: 1×*
- [ ] **F102. Chests already have materials in them** (the Builder's Chest and other chests). You chose: ruin and camp chests keep only rare finds (recipe pages, a rare gem, a map clue), no free building materials; chests you make start empty. *From: you. Said: 1×*
- [ ] **F103. Don't know how to progress:** built the Mason's Table and Workbench, but couldn't find how to make a sword or a shield. A stone sword should come quickly. (Found: the stone sword is at the Workbench but needs rope, made from fiber, and nothing tells you.) You chose: a "Next steps" goals list on screen, and every recipe shown at a station even if you can't make it yet, greyed out with what's missing and where to find it. *From: you. Said: 1×*
- [ ] **F104. Broken-rock chunks are all the same-size cubes.** You like that a block breaks into many pieces you pick up; make them different shapes, sizes and colours. *From: you. Said: 1×*
- [ ] **F107. Crystals switch their glow on and off with distance** (glow up close, dark from far away), like light switches. Their glow should stay, fading smoothly. Nov 15 (PC): the 12 real lights now fade in and out (dimmer with distance, and a light only moves to another crystal once it has faded out); the crystals' own glow never switches off. *From: you. Said: 1×*
- [ ] **F108. Don't know where to go next.** After exploring the first cavern there's no sign of where to dig. (You found the way later, but it should be clearer.) You chose: cracked walls, glowing cracks and moss where a tunnel hides behind thin rock, but later ("skip for now"). *From: you. Said: 1×*
- [ ] 🔁 **F109. The cave rock is too round.** Sharper, better world generation: some rock round, some jagged, more variety. Nov 16, you chose: chunky 1 m blocks everywhere, like 7 Days to Die (each block a little lopsided with cut corners); one block per dig; all worlds switch. In progress (code Claude). *From: you. Said: 2× (F19 was the first time)*
- [ ] **F159. Flatten the ground for building pieces and blueprints, even in caves** (not like Valheim's flattening). You chose: placing a foundation or floor cuts the rock in its space and fills dips under it, levelled to the 1 m grid, shown in the ghost; more than about 1 m to change turns it red ("too steep, dig it first"); filling costs dirt/stone (cutting gives it back) and looks like packed dirt or stone blocks; a placed blueprint first flattens its footprint plus a 1 m walkway (and clears the rock above it in caves) using its chest's dirt/stone. *From: you. Said: 1×*
- [ ] **F110. The world is too small.** Only about three big caverns and a few tunnels; at the edge of the map it just says "you need a better pickaxe". You hoped for more tunnels and maze-like passages. (Goes with F109.) Nov 16: you chose to do it (with F108) after the chunky rock and flattening are done. You chose to do this first in the world work: about twice as many caverns and rooms, twisting branching tunnels with side passages and dead ends, jagged rock, and the edge much farther away. *From: you. Said: 1×*
- [ ] **F115. Progression: Zone 1 should be a struggle but rewarding, copper shouldn't come fast** (like Valheim: wood first, metal is a milestone). You chose: Zone 1 takes 3-5 hours; copper only in the Copper Deeps (far, low caverns) and only a Fang Pickaxe (Workbench level 2) can mine it; you grow through station levels (copper-free Workbench add-ons for levels 2-3); the boss is summoned after finding the 3 markings with 5 copper ingots + 3 bat fangs + 2 glow glands. Plan: `docs/design/zone1-progression.md`. *From: you. Said: 1×*

*(Nov 15, late: your second play test. These were first numbered F116-F124, the same numbers Claude 2 used at the same moment for the Shack notes, so they became F149-F157.)*

- [ ] **F153. Dropped things are now too big** (after F93's 5×). Make them smaller. *From: you. Said: 1×*

- [ ] **F95. A way to make stone if you lose your pickaxe.** Same as F89 (bare hands dig soft rock and dirt for stone). *From: you. Said: 1×*

*(Nov 15, your notes on the 3D building pieces and monsters. Rules written in `docs/art/MODEL-RULES.md`.)*

- [ ] 🔁 **F68. Monsters: rebuild them by hand (no Play-Doh), like the crafting tables.** Plan: the Nov 14 hand-built scripts, reshaped to match the approved pictures; 4 looks on one body; Rock Beetle first for your OK. On the PC. *From: you. Said: 3×* **Nov 15 (Claude 3): Rock Beetle hand-built in all 4 looks, waiting for your OK** (pictures in `docs/art/creatures-hand-built-2026-11-15/`, 3D page Dwarf Cave Creatures). Snail and bat after your OK. 3rd time (Nov 15, late): "still too simple, like Roblox, everything glued together, not seamless; build ONE first". **Different approach:** the studio way, by script: sculpt and bake (`tools/asset_forge/creature_sculpt.py`): glued pieces melt into one skin, get carved detail, and are painted and baked onto a light game copy. Mossy beetle only, round by round, in the 3D page "Rock Beetle (sculpt test)".

*(Nov 15, late: your notes on the Rock Beetle, rounds 2 to 5, one beetle at a time. All of them are now rules for every creature: `docs/art/CREATURE-RECIPE.md`.)*

- [ ] **F143. Beetle legs: one claw per leg, segments overlapping like shingles (no joints seen), shingled belly, it must stand on its legs with the claws flat on the ground.** Rounds 3-5 (Claude 3): faceted segments that cover the next one's start, shingled belly bands, one claw; round 5: each claw lies flat on the ground like a toe and the leg stands on it. Waiting for your look. *From: you. Said: 5×* **Round 6 (Nov 16):** you said the legs are good but too perfect: every segment is now a little different (thickness, twist, uneven sides) and worn (dents, grooves, pits, scratches, grime). **Round 8 (Nov 16):** you preferred the round-6 legs and found two weird spots (a crumpled knee, the claw under the foot): back to the round-6 pose but kept thick, gentler randomness (big twists crumpled the overlaps), claws come out of the front of each foot and lie flat, flat foot soles.
- [ ] **F144. Beetle face: bloated, weird eyes, odd tusks, too much face.** Remove the nose, a mouth you barely see, revamp the eyes, tusks with more detail and no odd end. Round 5 (Claude 3): small face tucked under the shell; no nose; a thin sunk frown; each eye one clean ball with the iris, pupil and shine painted on, a heavy lid and a V of stone brows above (grumpy); sickle fangs with a blade edge, growth rings, a darker root and one sharp point. Waiting for your look. *From: you. Said: 3×* **Round 6 (Nov 16):** you said it looked like a smooth cartoon face: now rough armour (grooves, dents, pits); mouth removed; the tusks are grey toothed mandibles (pincers, not perfect, different left and right); eyes green.
- [ ] **F145. Beetle feelers just stick out.** Move them back into the two gaps above the stone brows, blended so they're attached to the body. Round 5 (Claude 3): they grow out of a knob of face skin that fills each gap, melted into the head. Waiting for your look. *From: you. Said: 2×* **Round 6 (Nov 16):** you said they still stuck out of the rock: each now comes out of a round stone-rimmed hole in the gap between the horn and the brow.
- [ ] **F146. Beetle stones too smooth and all one colour.** Add shade, scratches, wear and tear. Round 5 (Claude 3): every stone its own shade (warmer, cooler, darker, lighter), thin pale scratches cut in, darker grime stains, lighter worn edges. Waiting for your look. *From: you. Said: 3×* **Round 6 (Nov 16):** you said the scratches were barely visible: they are now about twice as wide, deeper, with a dark crease and a pale line, readable from far away. **Round 8 (Nov 16):** you said everything still looked grey: a clearly visible mix of stone shades now (brown-warm, blue-grey, plain; lighter and darker), like the stone foundation.
- [ ] **F147. The beetle's yellow part needs more detail and a humming animation.** Round 5 (Claude 3): a cut gem of big flat facets with glowing edges, cloudy depths and tiny bubbles; it hums (a slow breath of light in and out, every 3.5 s) in the game and on the 3D page, and blazes when it charges. Waiting for your look. *From: you. Said: 1×*
- [ ] **F163. The beetle's shell is still flat at the bottom; it should curve.** Round 7 (Nov 16, Claude 3): the shell's lower edge is now a curve (low over the legs in the middle of each side, higher at the head and tail) and the dome rounds under; the shell is also wider and lower. Waiting for your look. *From: you. Said: 1×*
- [ ] **F164. Bring the Rock Beetle to 10: work through Claude's 9-point list.** You chose all 9; horn bigger but flat. Round 7 (Nov 16, Claude 3): (1) bigger flat-sided horn, tip curling back; (2) fat, short legs closer to the body; (3) browner legs and face, olive moss, deep orange amber; (4) wider, lower shell, curved bottom (F163); (5) claw tips hook down a little; (6) belly painted; (7) amber has a lantern-bright middle and darker cracks; (8) cave test: **the new beetle shows up white in the game (its pictures don't load in Godot), so the game still uses the old one until that's fixed**; (9) feelers sway in the game, and a charge ends with stone chips and dust shaking off the shell. *From: you. Said: 1×*
- [ ] **F166. Every Rock Beetle that spawns should look a little different** (its stones a slightly different shade). Done in the code Nov 16 (Claude 3): each spawned creature's stone gets its own slight shade from its id, so co-op friends see the same one. Shows once the new beetle is in the game (see F164: it loads white for now). *From: you. Said: 1×*
- [ ] 🔁 **F82. Tanning rack: the ropes are not attached to the hide (again).** *From: you. Said: 2×*
- [ ] **F83. Silver sword too wide and not sharp.** Narrower blade, real edges and a point. (Silver is a later zone; fix with the weapons pass.) *From: you. Said: 1×*
- [ ] **F86. Fix what the review found (you said yes to all four groups):** (a) old plain style + reskins, (b) harsh colours + pieces poking out / past the 2 m grid, (c) floating parts + wall items standing on floor posts, (d) weapons + copper that doesn't look like copper. Details per model in the review report. *From: Claude, approved by you Nov 15.*
  - Nov 15 (PC, code Claude): (c) **wall items now hang on walls** in the game: banners, bat trophy, crossed pickaxes, fossil and horn plaques, map board, rune shield, peg rack, wall torch snap flat onto a wall, the tool rack station hangs on walls. Until each model is remade with a flat back (sizes sent to the 3D Claudes) the game shows a plain board instead of the old floor-post model. Copper is now decor only (banner, wall shield, sconce, door). New checks for everyone: `tools/model_check` (floating parts, shimmer, outline, roofs, build script).
- [ ] **F55 moves up: outfits are rebuilt now** by the monsters-and-armor Claude, after the Rock Beetle (you said Nov 15).

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

- [ ] **F55. All outfits too blocky and simple; remake (ChatGPT pictures).** *From: you. Said: 1×*

**Claude noticed, waiting for your OK** (not fixed until you say so):

- [ ] **N1. Spore Rock Beetle: one leg floats loose under the body** (seen in `docs/art/creatures-2026-11-15/all_12_models.jpg`, bottom right). Found by Claude on the Mac, Nov 15. Fix when you say yes.

## Done

Fixed items live in `FEEDBACK-done.md` (moved there unchanged on Nov 16 to keep this file short). Before adding a new item, Grep BOTH files for a keyword: if it matches a fixed item, bump its Said count there, or if it came back, mark it 🔁 and add it to "Things that keep coming back" above.
