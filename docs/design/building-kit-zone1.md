# Zone 1 building kit (the plan the owner approved, November 14, 2026)

Only Mossy Hollows (Zone 1). Other zones come later. Every model follows the workbench style
(`docs/art/CREATURE-STYLE.md` rules, `CLAUDE.md`): chunky hand-made shapes, hand-painted textures, never perfect.

## 3 styles, each with its own design (like Conan Exiles tiers, not reskins)

| Style | Material | Feel | Roof |
|---|---|---|---|
| **Delver's Shack** (starter) | Rootwood | Rough split logs and uneven planks, bark on the edges, rope lashings, slightly crooked | Sloped, wooden shingles |
| **Stonehold** (mid) | Cut Stone | Big chunky dwarf masonry, deep mortar, heavy timber lintels over doors, carved keystones | **Flat**, with a low battlement edge (owner's choice) |
| **Hearthbrick** (best in Zone 1) | Clay Brick | Warm fired brick in patterns, rounded arched windows and doors | Sloped, clay roof tiles |

**Copper is decor only:** hinges, nails, lanterns, trims, a reinforced door. No copper walls, floors or roofs.
(Today's copper building family and copper roofs go away from the Zone 1 build menu.)

## The kit

Same 13 pieces in every style:
Foundation · **Triangle foundation** · Stairs · Floor/ceiling · **Triangle floor/ceiling** · Wall · Half wall ·
Doorway · Window wall · Pillar · Beam · Door · Railing.

Plus the roof set:
- **Delver's Shack and Hearthbrick (sloped):** Gable wall (the triangle end wall) · Roof slope · Outer corner ·
  Inner corner · Ridge cap → 18 pieces each.
- **Stonehold (flat):** Flat roof slab · Battlement edge · Battlement corner → 16 pieces.

Total: **52 models** (18 + 18 + 16). Ladder, mine prop and decor stay shared (one look each).

### Rules for the shapes
- **Roofs are hollow:** a sloped roof piece is a thin slanted panel (like a lean-to), open underneath. Corners are
  two slanted panels meeting at an edge. Never a solid wedge or pyramid.
- **A ceiling is the floor seen from below:** the floor piece's underside shows beams and boards (wood) or
  vaulting/slabs (stone, brick).
- **Triangles like Conan Exiles:** equilateral, every side = one wall length (2 m), so any normal wall fits any
  triangle edge and six triangles make a hexagon (round towers). Today's triangles are half-squares with a special
  2.83 m diagonal wall; replace them. Snapping must allow 60° turns. (`wall_diagonal` and friends can go.)
- Exact sizes (2 m grid, 2 m walls) and straight snapping edges, but chunky and imperfect on the surface.

## How they're made (not picture-to-3D)

Building pieces must be exact sizes to snap and tile, and picture-to-3D makes lumpy, slightly wrong sizes. So:
1. ChatGPT pictures to lock the design: per style, **1 style sheet** (all pieces on one sheet) and **1 finished
   house** picture. Plus **about 6 hand-painted tileable textures** that are still missing (some exist already:
   wood planks, shingles, slate, stone).
2. Build the meshes in Blender to exact sizes (by script): bevelled, chipped, wobbly edges, uneven planks/stones,
   painted with those textures. Save as `assets/models/build/<piece>__<family>.glb` (the game already loads these).
3. Check in the game: snapping, no gaps, no floating parts, the "white edges" bug fixed.

Order: **Delver's Shack first** (style sheet → house picture → owner reviews → models → test in game), then
Stonehold, then Hearthbrick.

## Later (owner wants it, after the kit)
**Creative beams like Valheim:** simple beams and poles in a few lengths, and slanted beams (26° and 45°) for
decor and creative building.
