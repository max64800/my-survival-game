# Ruin 10: the Smeltery Terraces (F845, owner picked it Nov 24)

An old dwarf bronze-works in **Hearthbrick** (clay_brick), set into the cave in three steps. It can be rebuilt in its
own brick, or mended in wood (`wooden_smeltery`). Concept sheet: `ideas_sheet.jpg`. 3D page:
`tools/ruins/make_smeltery_page.py` + `tools/ruins/smeltery_page.html`.

Code: `BlueprintLibrary._smeltery()` (design stage: in `make()` and `NAMES`, not in `IDS` / `REBUILD_ONLY` yet).
Checks: `tests/test_smeltery_design.gd` (sound, nothing falls, walk-through, both materials).

## The plan (2 m grid, before the shift `SMELT_SHIFT = (5, 0, -3)`; box 52 x 24 x 22)
Rebuilt Nov 25 to match the owner's approved shape model `smeltery_shapes.html`.
| Part | Where | Heights |
|---|---|---|
| Vaults (store rooms) | cells x -12..16, z 2..4 and x -12..8, z -6..0 | foundation 1.0, flat roof/terrace 3.0 |
| Yard + split stair | x -6..6, z 6..10; the grand stair splits in two (foundation_steps at x -4 and 4, z 12), then one 3-wide flight at z 6 onto the terrace | yard 1.0 |
| Smelting hall | x -6..8, z -6..0 on the terrace (left wall on x = -7); storey 1 two walls tall (3.25 + 5.5, beam band at 5.25) | floor 7.5, roof 9.75 + 11.75 |
| Hall front balcony | wood floors x -6..6, z 2 on brick corbels (6.5), railed | 7.5 |
| Stair turret | 6-sided at `SMELT_STAIR_TURRET` (-9.05, -0.5), door on the yard side, ladder inside, 4 storeys + railed top | 1 / 3.25 / 5.5 / 7.75 / 10, top 12.25 |
| Chimney tower | square x 10..16, z -6..0, 6 storeys; doors out onto the wrap balcony at 7.75 | 1 / 3.25 / 5.5 / 7.75 / 10 / 12.25 |
| Wrap balcony | brick floors round the tower's front (z 2) and right side (x 18) on corbels, railed | 7.5 |
| Corner spires | carved columns on corbels at the square top's two front corners (x 9 and 17, z 1); the back two would be in the rock | 13.2 .. 17.5 |
| Ring room + crown + chimney | 12-sided on the tower (centre `SMELT_TOWER`), 5 balconies on corbels, a square chimney with a cap band | 14.5, deck 16.5, chimney 16.75..20.75, cap 22.35 (~23 m) |
| Furnace house | 12-sided at `SMELT_FURNACE` (-24.73, 2), 3 storeys + railed deck where it steps in | 1 / 3.25 / 5.5 / deck 7.5 |
| Furnace top (neck) | thinner 6-sided ring on the deck, ladder inside, railed top | 7.75 / 10, top 12.25 |
| Furnace porch | 1 cell on the furnace's front, steps, door, windows, lean-to roof | 1.0 |
| Bridge | x -20..-14, z 2, roofed in wood (roof_45_ridge on wood pillars), brick pier with 4 carved columns at x -18 | 3.0, roof 5.25 |
| Watch turret | 6-sided at `SMELT_WATCH` (19.05, 5.4) on the terrace's front-right corner, steps + door, ladder, railed crown | 1 / 3.25 / 5.5, top 7.75 |

Cave: rock behind z < -10.2 (after the shift, `smelt_rock_top`), the dip under the bridge comes from the world.
**The cave must be about 24 m tall here.**

Where it differs from the shape model (2 m pieces can't make everything):
- The stair and watch turrets are 6-sided (3.5 m across, owner's pick Nov 25) with ladders, not tiny round towers.
- The tower's corner turrets are carved stone spires on brackets, only on the two front corners.
- The hall's left jetty is gone (the stair turret stands there). The lower terrace stays at yard height.
- The porch is 1 cell wide with a lean-to roof; the chimney cap is a brick trim band (no bronze piece).
- Ladders through the 6-sided floors' open triangle are not tried in the game yet.

## Recipe items covered (GRAND-RUIN-RECIPE)
- Different heights: vaults 3.25, watch turret ~8.75, furnace ~13, hall ~13.75, stair turret ~13, tower ~23.
- Things on brackets: hall balcony, wrap balcony, bridge ends, corner spires, tower crown balconies.
- Outline steps out (vaults), in (hall), out (balconies). Three shape changes on the tower (square, 12-sided, crown, chimney).
- Terrace with a split grand stair to the main door, bands at the floor lines, symmetry broken (tower right, furnace left).
- A round tower meets straight parts only on one flat side (furnace to bridge).

## Lessons used
- Tall storey = two walls with a beam band between (else the upper wall floats).
- Wood is too weak high up: in the wood version the whole chimney tower (from 0.9 m up) and its wrap balcony stay brick
  (`_smelt_top_stays_brick`). With only the top half brick, the wooden chimney walls and cap fell in the strength test.
- Solid walls under doors and windows above; vault arches moved to x -2 and 2.
- Stacked stairs (F838) for the tall storeys, whole free block at both ends of every flight.
- Two pieces may not claim the same wall spot (the furnace deck's inner railing had to go where the neck wall stands).
- 3D page ruin: a railing whose floor fell goes too; the bridge's wood roof falls whole; tower cut band only 1 m, so
  no chimney wall stands on a broken one.

## Cost
- Brick: 8,862 Clay Brick, 1,314 Mortar, 48 Copper Ingot, 213 Rootwood Plank, 26 Rope (1,328 pieces).
- The ruin mended in wood (340 pieces new): 2,310 Rootwood Plank, 281 Rope, 190 Clay Brick, 19 Mortar.

## Next (after the owner's OK)
The real ruin in the game (like `ruin_prow_hall.gd`): chests in the vaults, junk, beetles, the cave shape, a placement
test that nothing grows inside it, then add the ids to `IDS` / `REBUILD_ONLY`.
