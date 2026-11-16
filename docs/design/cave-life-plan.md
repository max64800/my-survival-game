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
