# Ruin 10: the Smeltery Terraces (F845, owner picked it Nov 24)

An old dwarf bronze-works in **Hearthbrick** (clay_brick), set into the cave in three steps. It can be rebuilt in its
own brick, or mended in wood (`wooden_smeltery`). Concept sheet: `ideas_sheet.jpg`. 3D page:
`tools/ruins/make_smeltery_page.py` + `tools/ruins/smeltery_page.html`.

Code: `BlueprintLibrary._smeltery()` (design stage: in `make()` and `NAMES`, not in `IDS` / `REBUILD_ONLY` yet).
Checks: `tests/test_smeltery_design.gd` (sound, nothing falls, walk-through, both materials).

## The plan (2 m grid, before the shift `SMELT_SHIFT = (5, 0, -3)`; box 48 x 20 x 22)
| Part | Where | Heights |
|---|---|---|
| Vaults (store rooms) | cells x -12..16, z 2..4 and x -12..8, z -6..0 | foundation 1.0, flat roof/terrace 3.0 |
| Yard + grand stair | x -6..6, z 6..10, stairs at z 6 (x -2, 0, 2) onto the terrace | yard 1.0 |
| Smelting hall | x -6..6, z -6..0 on the terrace; storey 1 two walls tall (3.25 + 5.5, beam band at 5.25) | floor 7.5, roof 9.75 + 11.75 |
| Hall jetty | upper floor out to x -8..8 on corbels (left side and front) | 7.5 |
| Chimney tower | square x 10..16, z -6..0, 6 storeys | 1 / 3.25 / 5.5 / 7.75 / 10 / 12.25 |
| Ring room + crown | 12-sided on the tower (centre `SMELT_TOWER`), 5 balconies on corbels | 14.5, deck 16.5 (top ~18.75) |
| Furnace house | 12-sided at `SMELT_FURNACE` (-24.73, 2), 3 storeys + railed deck | 1 / 3.0 / 5.25 / deck 7.5 |
| Bridge | x -20..-14, z 2, from the furnace's flat side to the terrace, corbels at both ends | 3.0 |

Cave: rock behind z < -10.2 (after the shift, `smelt_rock_top`), the dip under the bridge comes from the world.
**The cave must be about 20 m tall here.**

## Recipe items covered (GRAND-RUIN-RECIPE)
- Different heights: vaults 3.25, furnace ~8.75, hall ~13.75, tower ~18.75.
- Things on brackets: hall jetty, bridge ends, tower crown balconies.
- Outline steps out (vaults), in (hall), out (jetty). Two shape changes on the tower (square, 12-sided, crown).
- Terrace with a grand stair to the main door, bands at the floor lines, symmetry broken (tower right, furnace left).
- A round tower meets straight parts only on one flat side (furnace to bridge).

## Lessons used
- Tall storey = two walls with a beam band between (else the upper wall floats).
- Wood is too weak high up: in the wood version everything on the tower from 7.4 m up stays brick (`_smelt_top_stays_brick`).
- Solid walls under doors and windows above; vault arches moved to x -2 and 2.
- Stacked stairs (F838) for the tall storeys, whole free block at both ends of every flight.

## Cost
- Brick: 7,526 Clay Brick, 1,074 Mortar, 34 Copper Ingot (1,050 pieces).
- The ruin mended in wood: see the 3D page (about 300 pieces new).

## Next (after the owner's OK)
The real ruin in the game (like `ruin_prow_hall.gd`): chests in the vaults, junk, beetles, the cave shape, a placement
test that nothing grows inside it, then add the ids to `IDS` / `REBUILD_ONLY`.
