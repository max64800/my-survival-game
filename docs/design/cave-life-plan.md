# Cave life plan (owner's picks, Nov 16, 2026)

The owner: "I want moss to be fluffy, some grass here and there, small roots that stick out of the ground, so the
caves don't look hollow. Natural columns out of rock, or big roots that connect small openings."

The owner picked **every idea**, with life in **patches**: lush near light (glowing things), water and roots, bare rock
in between. That way the lush spots feel special and the game stays fast.

## Batches (one at a time, about 4 pieces each; the owner OKs each before the next)

Each piece is hand-built in Blender by script, the cave-plants way (`tools/asset_forge/builds/cave_plants.py`: sculpt,
paint, bake, then `glb_jpeg_fix`), and shown on the 3D page (https://claude.ai/artifact/Mk9JzQ9EqRX2GhK9bZpt3F).
Then it goes in the game and gets a cave close-up (`lookdev plants`).

### Batch 1: ground cover (F188)
1. **Fluffy moss cushions:** thick, soft and fuzzy on floors and rock tops, spilling over ledges, thicker where it's
   damp. Drawn as stacked layers (a shell or fur shader), so it looks like velvet in the lantern light.
2. **Pale cave grass:** whitish-yellow or blue-green tufts that lean away as you walk through.
3. **Small roots poking out** of floors and walls: curled ends with hair roots.
4. **Lichen and cave ferns:** orange or teal crusts on walls; small curly ferns round glowing things.

**Status (Nov 16): built, waiting for the owner's OK.** Models: `tools/asset_forge/builds/cave_cover.py` (moss,
moss_drape, grass, rootlet, rootlet_b, lichen, fern). Game: `src/art/cave_life.gd` (patches round glowing things,
drips and roots; plain mushrooms and fiber get none), `moss_shell.gdshader` (fuzz as 12 stacked layers),
`plant_bend.gdshader` (grass and ferns lean away from dwarfs). Close-ups: `lookdev cover`. Cost: ~0.2 ms per frame
in the first big cavern; the placing runs in the background while the cave loads (~2-3 s). Test: `test_cave_life`.

### Batch 1b: glowing mushroom meadows + glow threads (owner, Nov 17; F216, F217) — build this next
The owner (Mac chat): "not grass but little long-ish mushrooms like grass… make it glow and leave a trail behind us for a
few seconds". Picked by multiple choice:
- **Mushroom grass instead of grass, almost everywhere** on flat floors (a carpet like Valheim's grass): thin,
  long-stalked little mushrooms with tiny caps, in tufts of 5-9. Bare only on steep rock, close to walls, on dug
  spots and on built floors. It replaces the pale cave grass (moss, ferns, roots, gravel and tiny mushrooms stay).
- **Dark until touched:** pale stalks (the lantern still shows them up close), no glow on their own. Where a dwarf
  **or a creature** walks, the stalks light up **teal-blue** (the glow-crystal colour) and fade over about 5 seconds,
  leaving a glowing trail. So you can spot a beetle crossing a dark meadow by its trail.
- **Bend and sway:** a slow draft sway everywhere, and they bend away as you walk through (like the grass now, F198).
- **Ceiling: glow threads**, like real glow-worm caves: clusters of 10-40 thin threads (0.3-1.5 m) with tiny beads,
  hanging from cavern ceilings and overhangs, always glowing faintly teal-blue with a slow twinkle, swaying a little.
  The black ceiling becomes a soft starry sky. Nothing new on the ground besides the mushroom grass ("nothing for now").

How (for the builder):
1. Model: one tuft hand-built in Blender by script the cave-cover way (`builds/cave_cover.py`), 2-3 variants; the
   glow thread as a thin strip with beads. MODEL-RULES apply (no Play-Doh, no shimmer). Show on the 3D page first.
2. Placing: MultiMesh per chunk over floors with an upward normal (y > 0.7), same seed = same carpet on every
   computer; thick near you, thinning out to ~45 m, nothing beyond (visibility range), so speed stays OK
   (`perfcheck` before/after; the owner's PC is the judge).
3. Trail: a small node keeps the last ~48 "touch" points (position + time) of every dwarf and creature (positions
   every ~0.3 m moved). It's looks only, so every computer works it out from the positions it already has (no network).
   The stalk shader adds teal emission by distance to each point x (1 - age / 5 s). No real lights.
4. Glow threads: ceiling spots (normal y < -0.7) in caverns, a few hundred clusters; emissive shader with a slow twinkle
   and sway. Looks only, not breakable.
5. Tests: the carpet covers most flat floor in a test cave and none on steep rock; a touch point lights stalks and is
   gone after 5 s; trails from a monster too. Close-ups with `lookdev` (meadow at night with a trail, the ceiling).

### Batch 2: big shapes (F189)
1. **Natural rock columns:** a stalactite and stalagmite grown together. Some are pinched in the middle, some have
   drip-stone curtains.
2. **Giant root pillars and bridges:** from ceiling to floor, or spanning small gaps and openings.
3. **Root curtains in doorways:** thin hanging roots across narrow passages that sway as you push through.
4. **Arches and mossy boulders:** natural arches in big rooms, fallen boulders with a blanket of moss.

### Batch 3: things that move (F190)
1. **Drifting glowing spores** near mushrooms.
2. **Tiny critters:** crickets, centipedes and beetles that run away when you come close (only for looks).
3. **Water:** drips making puddles, small trickling streams, mist over pools.
4. **Glowing veins** in the rock and **shelf fungi** on walls.

## Rules to keep
- Patches, not everywhere: placed by "how alive is this spot" (near glow spots, drips and roots), the same on every
  computer from the cave's seed (`Clutter`-style MultiMesh batches, hidden when the rock near them is dug).
- Looks only unless the owner says otherwise. Big shapes that block the way must still be diggable or passable.
- Cheap: MultiMeshes, nothing drawn farther than about 70 m, no extra real lights.
- Sounds (if any): real CC0 recordings only, never synth.
