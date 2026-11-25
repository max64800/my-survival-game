# Ruin 11: Brickcrown Keep (F895), build plan

Owner OK'd the shape model on Nov 25: `docs/design/ruin11/brickcrown_shapes.html`
(page: https://claude.ai/artifact/Th7UtndFNRJU6u2KmqSTbE). Build it from real pieces now.

## The idea
An old **Stonehold** stone fort, later mended and built higher in **Hearthbrick** brick.
- Stone (`STONE` = `cut_stone`): everything at the bottom, the right tower, the curtain wall, the courtyard rooms.
  Stone parts have **flat** tops with battlements (Stonehold = flat roofs only).
- Brick (`BRICK` = `clay_brick`): the keep's two top storeys, the left tower's top, one mended crack.
  Brick parts have **sloped** tile roofs (Hearthbrick = sloped only; the left tower gets a pointed roof).
- Stone trim bands / cornices at every floor line, also between brick storeys (this ties the two together).
- Mixing works: every blueprint piece has its own `mat` (`_add(id, mat, pos, rot)`); the Smeltery already mixes.

## The parts (model metres; the model's x/z, front = +z, rock wall behind at z = -12)
The model puts walls on even lines (x = -8, 8...). In `BlueprintLibrary` walls sit on odd lines (foundations at even
centres, see `_smeltery()`), so shift the whole plan 1 m (or resize a part by one cell); keep the proportions.
1. **Terrace + grand stair (stone):** x -10..10, z 0..6, 1.5 m high; a 4 m-wide stair to the front at x -2..2.
2. **Keep:** x -8..8, z -12..0, its back in the cave's rock.
   - Storeys 1-2 stone (0..7.5), band at the floor line, two buttresses on the front, round front door at x 0.
   - Storey 3 brick, sticks out 1 m at the front and right on stone corbels (`corbel`), stone band on top.
   - Storey 4 brick, steps back in (x -6..7, z -12..-3), railed terrace in front of it; gable tile roof
     (ridge along x), brick chimney.
   - A side door from storey 1 into the courtyard (x 8 face, z -9).
3. **Left tower:** 12-sided ring (R = 1, `_ring_layer` / `_ring_edges`, like the watchtower), meets the keep's left
   side on one flat side. Stone to 9 m, then a thinner brick ring with a walkway round it, then a pointed roof.
   (A pointed roof over a ring may need a new brick piece: ask the owner before making any new piece.)
4. **Curtain wall (stone):** keep's right side to the right tower, 2 m thick, 7 m, walkway + battlements both sides.
   A round-topped **gate** (stone `gateway` + `gate_leaf` doors) at x 12..16 into the courtyard.
   One crack mended with brick on its front (a few brick wall pieces in the stone wall).
5. **Bridge + dip:** the dip in the cave floor is only in front of the gate; a stone bridge crosses it to the gate.
6. **Right tower (all stone):** 12-sided ring on a rock lump (its base 3 m up), to 13 m, flat battlement top.
7. **Wall to the rock (owner's add):** a short stone wall, same height as the curtain wall, from the right tower's
   back to the cave's rock wall.
8. **Courtyard (owner's add):** behind the gate, carved about 8 m back into the cave rock, x 8..23, z -6..-20.
   Stone paving, a well, the rock hanging over its back.
   **Owner, Nov 25: the carved rock must look natural, NOT square.** So the ruin's carve points for the courtyard
   are a lumpy outline (radius wobbling with noise, uneven ceiling, a few rock bulges left standing), never a box.
   See how `RuinSmeltery.carve_points()` (`src/world/ruin_smeltery.gd`) carves; the courtyard is extra carve points
   with a noisy edge. The world's own cave still decides the rest (GRAND-RUIN-RECIPE "Built into the cave").
9. **Rooms in the rock (owner's add):** on the courtyard's left (x 8 face, z -20..-12) the keep's stone base goes on
   into the rock: a stone front with two round doors and windows, 2 small stone rooms behind it inside the rock.

Heights: terrace 1.5, curtain wall 7, left tower 16, right tower 13 (on 3 m of rock), keep roof 19. Cave needs ~21 m.

## Steps (in order, one at a time)
1. `BlueprintLibrary._brickcrown()` + ids `"brickcrown_keep"` (mixed) in `IDS`/`NAMES`/`make()`; a wooden rebuild
   only if the owner asks. Follow `docs/design/BLUEPRINT-RECIPE.md`, the GRAND-RUIN-RECIPE checklist and
   `RUIN-RULES.md` (stairs free block, walk-through, brackets off windows, round doors only).
2. A design test like `tests/test_smeltery_design.gd` (stairs on floor, nothing floats, walk-through, brackets).
3. Ruin page from the real blueprint (copy `tools/ruins/make_smeltery_page.py`: ruin / whole, "Mark new pieces"),
   photograph it yourself (headless Edge works when chrome-devtools times out:
   `msedge --headless=new --use-angle=swiftshader --enable-unsafe-swiftshader --screenshot=... URL#view`).
4. Owner OK, then the ruin in the game (copy `ruin_smeltery.gd` + `make_smeltery_ruin.py`), with the natural courtyard carve.
