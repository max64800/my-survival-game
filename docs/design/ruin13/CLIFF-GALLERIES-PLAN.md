# Ruin 13: the Cliff Galleries (F913), build plan

Owner, Nov 26: "I really liked the stone and wood" (the Mine-head). Picked from 4 ideas: **Cliff Galleries**.
Shape model first, for the owner's OK: `docs/design/ruin13/cliff_galleries_shapes.html`.
Owner's rule from the Mine-head: **every building is stone below, wood above.** Stone parts have flat roofs
(Stonehold), wood parts sloped ones (Shack). Mix per piece with `_add(id, mat, pos, rot)` like `_minehead()`.

## The idea
Dwarves lived up a tall rock wall. A stone hall is dug into the foot of the cliff; above it, houses sit on natural
rock ledges, and wooden rooms and walkways hang out from the cliff on brackets. You climb the ruin like a mountain:
hall, bridge, house, cliff stairs, hanging gallery, and the watch tower at the top with the best chest.

## The parts (page metres; front = +z, the cliff face at z -10, cave floor y 0)
Shift to `BlueprintLibrary`'s odd wall lines as Brickcrown did; keep the proportions. Floors 2.25 m apart.
1. **Stone terrace + grand stair:** x -8..8, z -10..3, 1.5 m; 4 m stair to the front at x -2..2 (z 3..6),
   up to the main door. Lanterns on posts each side of the door (decor).
2. **Stone Hall (A):** x -6..6, z -14..-3 (back 4 m in the rock). Stone 1.5..6 (tall hall, band at 3.75), round main
   door at x 0, tall windows. Inside: two flights straight on (`_stacked_stairs`) up to 6.
   **Flat stone roof terrace** on the back strip z -10..-7 at 6, railings.
   **Wooden upper storey** on the front: x -7..7, z -7..-3 (juts 1 m out left and right on **brackets**; not over
   the main door: nothing hangs over a door), 6..8.25, gable shingle roof (ridge along x). Its right door
   (x 7, z -5) opens onto the bridge.
3. **The crack:** a dip in the cave floor x 8..12, from the cliff forward, about 5 m deep (use a natural one; dig
   only a little).
4. **Crack bridge:** wood, x 7..13, z -6..-4, deck at 6, railings, one braced post pair down into the crack.
5. **Ledge R:** a natural rock ledge x 12..26, z -10..-2, top at 6.
6. **Ledge House (B)** on ledge R: stone storey x 13..23, z -14..-4 (back 4 m in the rock), 6..8.25, round door
   at x 13 (z -6) level with the bridge. Wooden storey x 13..23, z -10..-3 (juts 1 m on brackets), 8.25..10.5,
   gable shingle roof. Its left door (x 13, z -9) opens onto the cliff stairs.
7. **Cliff stairs:** wood, pinned to the cliff (z -10..-8): a landing x 10..13 at 8.25, then two flights straight
   on (x 10 -> 6 up to 10.5, x 6 -> 2 up to 12.75). The cliff on one side, railing on the other.
8. **Hanging Gallery:** wood walkway x -8..2, z -10..-8, at 12.75, 2 m wide (whole floor tiles). Brackets into the
   rock + posts standing on the Stone Hall's flat roof (6). Railings on the open side. Ends on shelf L.
9. **Shelf L:** a natural tall rock buttress x -22..-8, z -10..-2, top at 12.75.
10. **Watch Tower (C)**, the tallest; changes shape 3 times:
    - stone, two storeys: x -18..-10, z -12..-3 (back 2 m in rock), 12.75..17.25, band at 15, round door on its
      right face (x -10, z -6.5).
    - wooden storey 17.25..19.5 jutting 1 m out at the front and left on **brackets** (x -19..-10, z -10..-2);
      the right side stays flush (nothing over the door). A deck with railings round the lookout.
    - wooden 8-sided lookout 19.5..21.75 (cut corners: `wall_diagonal` / `window_diagonal`), the best chest here.
    - a steep 8-sided roof to about 26.5; a finial (Shack: sloped; a spire piece may be needed, ask first).
    - a wooden **hoist arm** sticking out of the wooden storey's front with a rope down to the store shed (decor).
11. **Store shed** at the foot of shelf L: x -20..-12, z -2..3, stone 0..1.2, wood to 3, a lean-to roof against
    the shelf, round door with 2 steps up to it.

Heights: shed 3.5, Stone Hall ~10, Ledge House ~13, Watch Tower ~26.5 (one clear tallest). Cave needs ~29 m.
Ground levels: cave floor 0, crack -5, ledge R 6, shelf L 12.75.

## The way up (the fun of it)
Grand stair -> main door (1.5) -> hall stairs -> wooden storey (6) -> crack bridge -> Ledge House stone room (6) ->
its stairs -> wooden storey (8.25) -> cliff stairs -> Hanging Gallery (12.75) -> shelf L -> Watch Tower door ->
tower stairs -> lookout (19.5) with the best chest.

## Rule check (GRAND-RUIN-RECIPE + RUIN-RULES)
- 5 volumes, 4+ heights, one tallest (tower). Roofline changes every 4-6 m. Bands at every floor line.
- Overhangs on brackets: hall upper storey, Ledge House upper storey, tower wooden storey (out, in, out), gallery.
  Brackets on plain wall only, never on a window (`_brackets_off_windows`).
- Built into the cave (4 of 5): backs in rock (A, B, C), three ground levels, bridge over the crack, gallery and
  stairs along the cliff. Use a cave that's there (F657): find a cavern with a tall wall, a ledge and a crack.
- **Mine-head lessons (F912):** every door has steps up to it, or floor level with it; no ramp leads to a window;
  any ladder's top ends level with the floor you step onto (this plan uses stairs, no ladders).
- Stairs: a whole free 2 m block past every foot and top; flights stacked straight on; head room over flights.
- Doors: 1 m of clear floor both sides; the main door gets 10 m of open ground in front.

## In the ruin
The gallery's middle has fallen onto the hall's roof, the crack bridge sags, the tower's roof leans, holes in the
shingle roofs, a rock pillar through the Ledge House's broken floor. Rebuild (cut stone + wood) teaches the blueprint.

## Steps (in order, one at a time)
1. Owner OKs the shape page.
2. `BlueprintLibrary._cliff_galleries()` + id `"cliff_galleries"` in `IDS`/`NAMES`/`make()` (copy `_minehead()`).
3. A design test like `tests/test_minehead_design.gd` (stairs free block, walk-through, every door reachable, brackets
   off windows, F912 door steps).
4. Ruin page from the real blueprint (copy `tools/ruins/make_minehead_page.py`), photograph it yourself.
5. Owner OK, then the ruin in the game (copy `src/world/ruin_minehead.gd` + `tools/ruins/make_minehead_ruin.py`):
   find a cavern with a tall wall, a ledge and a crack; carve only a little.
