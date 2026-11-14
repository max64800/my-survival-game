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

Same 14 pieces in every style:
Foundation · **Triangle foundation** · Stairs · Floor/ceiling · **Triangle floor/ceiling** · Wall · Half wall ·
Window wall · **Sloped wall** (a wall cut corner to corner: fills the gap beside stairs and under the sides
of a sloped roof) · **Round doorway** (hobbit-hole style) · **Round door** · Pillar · Beam · Railing.
**Round doors only** (owner, November 14): no square doorway or square door in any style.
Foundations keep **tall legs** (a crawl space is fine; players can raise/lower foundations like in Conan).

Plus the roof set:
- **Delver's Shack and Hearthbrick (sloped):** Gable wall (the triangle end wall) · Roof slope · Outer corner ·
  Inner corner · Ridge cap → 19 pieces each.
- **Stonehold (flat):** Flat roof slab · Battlement edge · Battlement corner → 17 pieces.

Total: **55 models** (19 + 19 + 17). Ladder, mine prop and decor stay shared (one look each).

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

**Delver's Shack style sheet approved direction (v2, November 14):** ChatGPT chat "Generate Building Kit Sheet",
second picture (21 pieces, 7 × 3; ignore its square doorway and square door).
Before modelling, also make: the finished house, a "how it joins" detail sheet (wall corner, wall on foundation,
roof edge on wall, floor seen from below = the ceiling), and one texture sheet (bark log, split plank, grey
weathered plank, log end-rings). Dark bark-covered logs for frames, lighter split planks, a few grey weathered
boards, pale straw rope lashings, copper hinges, a stone ring around the round doorway.

**Delver's Shack reference pictures, all done (same ChatGPT chat "Generate Building Kit Sheet"):**
1. Kit sheet v2 (21 pieces).
2. Finished house: tall log legs on flat stone footings, stairs up to a porch with a log railing, round door with a
   lantern beside it, shuttered windows, gable end, shingle roof with rope-lashed ridge log and one hipped corner.
3. "How it joins" sheet: wall corner = a shared bark-covered corner post with the planks butting in and a rope
   lashing at the top; wall on foundation = bottom log pegged onto the foundation's top beam; roof edge = rafters
   on the wall's top log with a short overhang; ceiling = floor underside with 2 cross beams and pegged planks;
   roof underside = rafters + battens + shingle backs; triangle + square floors meet edge to edge.
4. Texture sheet: bark log, light split planks with iron pegs, grey weathered planks with moss in the gaps,
   log end-rings with a bark rim. (The first request silently failed; asking again worked.)
New detail from the house worth keeping: **flat stone footings under every log leg.**

Order: **Delver's Shack first** (style sheet → house picture → owner reviews → models → test in game), then
Stonehold, then Hearthbrick.

## Later (owner wants it, after the kit)
**Creative beams like Valheim:** simple beams and poles in a few lengths, and slanted beams (26° and 45°) for
decor and creative building.
