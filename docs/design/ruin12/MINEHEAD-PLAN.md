# Ruin 12: Mine-head Works (F899), build plan

Owner OK'd the shape model on Nov 25 ("looks great"): `docs/design/ruin12/minehead_shapes.html`
(page: https://claude.ai/artifact/G8K4FjTZYpdf6xPypeXUoW). Owner's picks: layout "ledge + trestle", a shaft you climb
down (8 m, ladders, mine room with the best chest), a NEW piece **Head Wheel** (Shack, in the build menu), looks only
(no moving lift), and **every building stone below, wood above**.

## The idea
An old dwarf mine entrance. A rope ran from the engine in the stone house, over the wheel on the headframe, down the
shaft; carts rolled over a trestle bridge to the ore shed. Materials: `STONE` = `cut_stone` (Stonehold, flat roofs),
`WOOD` = Shack planks (sloped shingle roofs). Mix per piece with `_add(id, mat, pos, rot)` like `_brickcrown()`.
Stone bands / beams at every floor line.

## The parts (page metres; front = +z, the rock face behind at z = -10; upper cave floor y 0)
Shift to `BlueprintLibrary`'s odd wall lines as Brickcrown did (BRICKCROWN-PLAN "The parts"); keep the proportions.
1. **Stone terrace + grand stair:** x -15..1, z -3..2, 1.5 m; 4 m stair to the front at x -10..-6.
2. **Engine house:** x -14..-2, z -12..-3 (back 2 m in the rock). Stone hall 1.5..7.5 (tall storey for the engine,
   band at 4.4), round door at x -8, tall windows; flat stone roof terrace with railings on x -14..-10.
   Wooden top storey x -10..-2, z -12..-3.5, 7.7..10.2, sloped shingle roof (ridge along x); a rope hole on its x -2 face.
3. **Stack:** 8-sided stone chimney at (-16.5, -9), to 17 m (stacked stone pillars or a ring; no new piece unless asked).
4. **Boiler shed:** x -20..-15, z -9..-3.5: stone 0..1.2, wood to 3, a lean-to roof sloping down to -x, round door.
5. **Headframe** (shaft hole x 3..7, z -6..-2, centre (5, -4)); the tallest part, changes shape 3 times:
   - stone collar/plinth x 1..9, z -8..4, 1.5 m, with the hole; front apron for the stair.
   - tier 1 wood 8×8, posts 1.5..6, **loading deck** at 6 (open over the cage way), railings; stair x 1..3 from the
     apron (two flights straight on, `_stacked_stairs`).
   - tier 2 wood 6×6 (x 2..8, z -7..-1), 6..12.75, girts at every floor line + X braces (`brace`).
   - tier 3: an 8×8 top deck at 12.75 jutting out 1 m on **brackets** (`corbel`, Shack), railings.
   - wheel stand: posts at x 3/7, z -6/-2 to 17.6, cross beams at 15.5 holding the axle.
   - **Head Wheel** (new piece) axle along z at (5, 15.5, -4), ~4 m across; a small sloped hood roof over it (eaves 17.6).
   - rope: wheel → the engine house's rope hole; wheel → down the shaft (decor, not a piece).
6. **Shaft + mine room:** shaft 8 m deep (cave floor to y -8.5), `ladder` pieces on its back wall. Mine room
   x -5..7, z -7..-1, y -8.5..-5.5 (dug by the ruin, natural lumpy edge like Brickcrown's courtyard), `mine_prop`
   frames every 3 m, the fallen cage, the best chest at x -4, a caved-in tunnel end (rubble/rock).
7. **Trestle bridge:** deck y 6, x 9..18, z -5..-3, from the loading deck to the ore shed's loft door; wooden legs at
   x 11 (upper floor), 13.5 and 16 (dip floor y -5), cross beams + X braces; railings; `rail_track` decor + a cart.
8. **The dip:** x 12..17, z -8 forward, about 5 m deep (dug by the ruin, like Brickcrown's dip under the bridge).
9. **Ore shed** on the lower ledge (y -3): stone plinth x 18..30, z -12..2 to -0.75; stone ground storey x 19..29,
   z -12..-2 to 2.5 with 3 ore chutes on its front; wood 2.5..6; wooden loft 6..8.25 jutting 1 m at the front and left
   on brackets, round door where the trestle arrives; sloped shingle roof (ridge along x). Back 2 m in the rock.
10. **Cart rails** along the ledge under the chutes (z 1.2, x 18..34), 2 carts (decor `rail_track`, `mine_cart`).
11. **Stairs in the rock:** stone stairs x 12..17, z -10..-8, from the upper floor (y 0) down to the ledge (y -3),
    rock wall on their back side.

Heights: terrace 1.5, boiler shed 4, engine house 10 (+roof), ore shed ~11 from its ledge, stack 17, headframe ~20.
Shaft 8 m down. Cave needs ~22 m. Ground levels: upper floor 0, ledge -3, dip -5, mine room -8.5.

In the ruin: the wheel hangs crooked, the trestle's middle span lies in the dip, the cage lies at the bottom of the
shaft, roofs have holes. Rebuild (cut stone + wood) teaches the blueprint.

## Steps (in order, one at a time)
1. **Head Wheel piece** (Shack): read `docs/art/MODEL-RULES.md` first; Blender by script in the workbench style
   (chunky, hand-painted, no perfect circles: a 12-16 sided rim, 8 spokes, a hub, an iron axle with end caps; every
   part touching). A game piece with a price, in the Shack build menu. Show it to the owner (render/page) before use.
   Snaps onto two beams/posts 4 m apart; `CREDITS.md` if any pack model is used; piece icon (`make_piece_icons.py`).
2. `BlueprintLibrary._minehead()` + id `"minehead_works"` in `IDS`/`NAMES`/`make()`; BLUEPRINT-RECIPE, the
   GRAND-RUIN-RECIPE checklist and RUIN-RULES (stairs free block, walk-through, brackets off windows, round doors).
3. A design test like `tests/test_brickcrown_design.gd`.
4. Ruin page from the real blueprint (copy `tools/ruins/make_brickcrown_page.py`), photograph it yourself.
5. Owner OK, then the ruin in the game (copy `ruin_brickcrown.gd` + `make_brickcrown_ruin.py`): find a cavern with a
   rock wall behind, dig the shaft + mine room, the dip and the ledge step only a little (F657: use the cave that's there).
