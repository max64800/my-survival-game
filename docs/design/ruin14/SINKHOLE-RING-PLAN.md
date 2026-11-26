# Ruin 14: the Sinkhole Ring (F915), build plan

Owner, Nov 26: picked from 4 ideas (Sinkhole Ring, Bridge-Houses, Pillar Abbey, Stepped Shrine): **Sinkhole Ring**,
materials **stone + wood** (Stonehold stone below with flat roofs, Shack wood above with sloped shingle roofs;
`STONE` = `cut_stone`, `WOOD` = `plank_root`, mix per piece with `_add(id, mat, pos, rot)` like `_brickcrown()`).
Shape model first, for the owner's OK: `docs/design/ruin14/sinkhole_ring_shapes.html`.

## The idea
Dwarves found a deep round hole in the cave floor (a sinkhole) and built a great round stone tower up from its
bottom, so its top rises out past the rim. Houses cling to the pit's walls, stairs are pinned to the rock, and two
bridges reach from the rim and the cave wall to the tower. **The first ruin you go DOWN into**: in the ruin the
front bridge has fallen into the pit, so you climb down the pit walls, go in at the bottom, and climb up through the
tower's inside to the lookout. Rebuilt, the bridge is the short way across.
Different from all 13: no other ruin sits in a pit, and it has the first really big round tower (ring R = 2, 15 m).

## The parts (page metres; front = +z, the pit's middle at x 0, z 0, cave floor (rim) y 0)
Floors 2.25 m apart. Shift to `BlueprintLibrary`'s odd wall lines as Brickcrown did; keep the proportions.
1. **The sinkhole:** about x -13..13, z -15..10 (cut corners), 9 m deep (floor y -9). Its right wall is a straight
   rock face at x 13. Use a natural pit (F657): find a cave with a deep dip; carve only a little.
   - **Ledge R:** a natural shelf in the pit at y -4.5: x 9..13 for z -7..2, widening to x 4..13 for z -15..-7.
   - **Back shelf:** behind the pit the cave wall rises to a rock shelf at y 6.75 (x -12..6, z -24..-15).
2. **Front terrace + grand stair:** stone terrace x -6..6, z 12..23, top 2.25; a grand stair to the front
   (x -2..2, z 23..27, 9 steps of 25 cm). Lanterns each side of the main door (decor).
3. **Gatehouse (A):** stone, x -4..4, z 14..20, 2.25..6.75 (one tall storey, band at 4.5), flat roof with
   battlements. Round main door at x 0 facing +z; round back door at x 0 facing the bridge; round side door on the
   right (x 4, z 17) onto the terrace, then **side steps** down to the rim (x 6..10, z 16..18, 9 steps).
   A small **wooden watch hut** on the roof's back-left corner (x -4..0, z 14..18, 6.75..9) with a sloped roof:
   it breaks the symmetry on purpose.
4. **Gate Bridge:** stone, x -1..1, z 7.5..12, deck 2.25, railings; meets the tower ring on its front flat side.
   In the ruin its middle has fallen into the pit (rubble on the pit floor).
5. **Great Tower (B), the round base:** stone 12-sided ring R = 2 (15 m across), from the pit floor -9 up to 2.25:
   - **Well Hall** -9..-4.5 (tall, `_stacked_stairs`), an old dry well in the middle (a dark round hole, decor),
     round door on the back flat side (z -7.5) onto the pit floor.
   - middle storey -4.5..0 (tall, stacked stairs), rim storey 0..2.25.
   - stairs run along the ring's outer row of squares, a different side each storey (GRAND-RUIN Castle rule 6).
   - **flat stone roof terrace** at 2.25 with battlements (not where the bridge and the keep door are).
   Bands at -4.5, 0 and a cornice at 2.25.
6. **The Keep (on the terrace):** stone square x -4..4, z -4..4 (4 x 4 cells), 2.25..6.75 (one tall storey,
   stacked stairs along one wall), round door facing +z (3.5 m of terrace in front of it).
7. **The Crown storey:** wood, 6.75..9, x -5..5, z -5..4: juts 1 m out left, right and back on **brackets**;
   the front stays flush (nothing hangs over the keep door). A **wooden balcony** on its right side (x 5..7,
   z -2..2, on brackets) looks over the Ledge House. A round back door (z -5) onto the High Bridge.
8. **The Lookout:** wooden 8-sided room 9..11.25 on the Crown's deck (cut corners: `wall_diagonal` /
   `window_diagonal`), railings round the deck. **The best chest is here.** A steep 8-sided wooden roof to about
   16.5 (Shack: sloped; a spire piece may be needed, ask first), a finial on top.
   The tower changes shape 4 times: round base, square keep, wider square crown (out), 8-sided lookout (in), spire.
9. **Pit stairs:** wood, pinned to the pit's right wall (x 11..13): top on the rim (z 10..12, y 0), two flights
   straight on going back (z 10 -> 6 down to -2.25, z 6 -> 2 down to -4.5), onto Ledge R. Rock on one side,
   railing on the other, struts into the rock.
10. **Ledge House (C)** on Ledge R: stone storey x 7..13, z -15..-9 (back 2 m in the rock, to z -17), -4.5..-2.25,
    round front door at x 10 facing +z (only one door: the wooden storey juts over the left side, and nothing hangs
    over a door). Inside stairs up to the wooden storey -2.25..0, jutting 1 m left (x 6..13) on brackets over the
    ledge path, a small **balcony** on its front right corner
    (x 11..13, z -9..-7; not over the door), a gable shingle roof (ridge along z) peeking up past the rim (~2.5).
11. **Back-wall stairs:** wood, pinned to the pit's back wall (z -15..-13): a landing x 4..7 at -4.5, then two
    flights straight on going left (x 4 -> 0 down to -6.75, x 0 -> -4 down to -9). Free floor x -6..-4 at the foot.
12. **High Bridge:** wood, x -1..1, from the Crown's back door (z -5, deck 6.75) to the back shelf (z -15), 10 m,
    two braced post pairs standing on the terrace and the pit floor. Railings both sides. In the ruin it sags.
13. **Winch House (D)** on the back shelf: stone storey x -9..1, z -23..-17 (back 2 m in the cave wall),
    6.75..9, round door at x 0 facing the bridge; wooden storey 9..11.25 jutting 1 m left and right on brackets,
    gable shingle roof to ~13.5. A timber **hoist arm** out of its left end over the pit with a rope and bucket
    down to the pit floor at (-8, -11.5), away from every path (decor).

Heights above the rim: Ledge House ~2.5, Gatehouse 6.75 (hut roof ~10.5), Winch House ~13.5, tower ~16.5 (one clear
tallest). From the pit floor the tower is ~25.5 m tall. The cave needs ~19 m above the rim here.
Ground levels: pit floor -9, Ledge R -4.5, rim 0, terrace 2.25, back shelf 6.75 (five).

## The way through (the fun of it)
Grand stair -> main door (2.25) -> gatehouse -> side door -> side steps down to the rim -> pit stairs down to Ledge R
(-4.5) -> along the ledge past the Ledge House (side room, a chest) -> back-wall stairs down to the pit floor (-9) -> round the tower to
its back door -> Well Hall (chest by the well) -> tower stairs up to the terrace (2.25) -> keep -> Crown (6.75) ->
Lookout (9) with the best chest. Side trip: High Bridge to the Winch House. Rebuilt: the Gate Bridge is a short way
from the gatehouse straight onto the terrace.

## Rule check (GRAND-RUIN-RECIPE + RUIN-RULES)
- 5 volumes (gatehouse, round base, keep + crown + lookout, Ledge House, Winch House), 4+ heights, one tallest.
  Roofline changes every 4-6 m: hut, gatehouse battlements, Ledge House gable, Winch House gable, spire.
- Up, out, up, out: wide round base -> keep steps in -> Crown juts out -> Lookout steps in. Overhangs on brackets:
  Crown, Crown balcony, Ledge House storey + balcony, Winch House storey. Brackets on plain wall only
  (`_brackets_off_windows`, `bracket_on_glass`).
- Castle: a ring that isn't the small watchtower ring (R = 2), meeting a straight part (the Gate Bridge) on a flat
  square side. Only the front side joins the grid; the back door and High Bridge are a door + a bridge from the
  square Crown, not grid joins to the ring.
- Built into the cave (5 of 5): backs in rock (C, D), five ground levels, two bridges over the pit, stairs pinned to
  the pit walls, the pit itself. Use a pit that's there (F657).
- Focal point: grand stair to the gatehouse's round main door, lanterns. Symmetry broken by the watch hut.
- Mine-head lessons (F912): every door has steps up to it or floor level with it (gatehouse side door -> side
  steps; Ledge House door on the ledge; tower back door on the pit floor); no ramp to a window; no ladders.
- Stairs: a whole free 2 m block past every foot and top (pit stairs: rim z 10..12 and ledge z 0..2; back-wall
  stairs: landing x 4..6 and floor x -6..-4; side steps: terrace and rim x 10..12). Flights stacked straight on.
  Head room: the Ledge House balcony and High Bridge are not over any flight.
- The keep's inside (4 x 4 cells) only just fits one flight with free blocks: if it doesn't, widen the keep to 5 x 5.
- Doors: 1 m of clear floor both sides; the main door gets 10 m of open ground in front of the grand stair.
- Nothing grown (columns, crystals, roots) in the pit, on the ledges, the stairs or the bridges' landings.

## In the ruin
The Gate Bridge's middle lies in the pit, the High Bridge sags, the Lookout's spire leans, holes in the shingle roofs,
the watch hut is half gone, a rock pillar has grown up through the Well Hall's broken floor beside the well.
Rebuild (cut stone + wood) teaches the blueprint.

## Risks to settle in the build chat
- A natural pit this deep (9 m) and wide (26 m) may be rare. Score caverns on a dip; if none is deep enough, dig the
  pit deeper only a little and tell the owner.
- The ring R = 2 stone base is big: show the price on the ruin page; the owner decides if it is too much.

## Steps (in order, one at a time)
1. Owner OKs the shape page.
2. `BlueprintLibrary._sinkhole_ring()` + id `"sinkhole_ring"` in `IDS`/`NAMES`/`make()` (copy `_cliff_galleries()`;
   the ring from `_big_ring_layer` / `_big_ring_edges` / `_big_ring_stairs`).
3. A design test like the Cliff Galleries one (stairs free block, walk-through, every door reachable, brackets off
   windows, F912 door steps, the ring meets the bridge flush).
4. Ruin page from the real blueprint (copy the Cliff Galleries page maker), photograph it yourself.
5. Owner OK, then the ruin in the game (copy the Cliff Galleries ruin): find a cavern with a deep pit and a cave
   wall shelf behind it; carve only a little.
