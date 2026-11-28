# Ruin 15: the Pillar Spiral (F942), build plan

Owner, Nov 28: picked from 3 ideas (Pillar Spiral, Chasm Bridge-Town, Stepped Shrine): **Pillar Spiral**,
materials **stone + brick + wood**, the first ruin with all three: Stonehold stone at the bottom (flat roofs),
Hearthbrick brick in the middle storeys (sloped tile roofs), Shack wood on top (sloped shingle roofs).
`STONE` = `cut_stone`, `BRICK` = `clay_brick`, `WOOD` = `plank_root`, mixed per piece with `_add(id, mat, pos, rot)`
like `_brickcrown()`. Shape model first, for the owner's OK: `docs/design/ruin15/pillar_spiral_shapes.html`.

## The idea
A giant natural rock column stands from the cave floor to the ceiling (25 m). Dwarves built a round stone hall
round its foot, then a stair-gallery that winds up round the pillar like a corkscrew, with one house on each side,
each a storey higher than the one before. The last and tallest is the Bell Tower over the main door, with a lookout
near the ceiling. Bridges reach out to a kiln house on a rock lump and a shrine dug into the cave wall.
**The first ruin you climb round and round.** Different from all 14: no other ruin wraps round something, and its
roofs climb in a spiral (4 houses, 4 heights, all round one middle).

## The parts (page metres; front = +z, the pillar's middle at x 0, z 0, cave floor y 0)
Floors 2.25 m apart. Shift to `BlueprintLibrary`'s odd wall lines as Brickcrown did; keep the proportions.
1. **The pillar:** cave rock, about 9 m wide at the foot, 7.5 m in the middle, flaring into the ceiling at 25.
   Use a natural column (F657): the world already grows stone columns; the ruin looks for a big one and must NOT
   be moved off it (the one exception to the placement rule: this column IS the ruin's middle). Ask the owner
   before the build chat if a column that big doesn't grow; then the ruin grows its own pillar.
2. **Ground shape:** cave floor y 0 round the pillar; the floor in front steps down to -2.25 (a rock edge at
   z 15); a crack on the right (x 14..18, floor -4.5); a rock lump past it (x 19..30, z -10..8, top 2.25) with
   steps cut down its front; the cave wall behind with a rock shelf at 9 (x -14..8, z -22..-13); ceiling 25.
3. **Ring Hall (A):** stone 12-sided ring R = 3 (22 m across), 0..4.5 (one tall storey, band at 2.25, cornice at
   4.5), a ring-shaped room round the pillar. Big round main door at the front flat side, lanterns. Flat roof
   terrace at 4.5 with battlements (not at the arch bridge). Stacked stairs inside, coming up at the terrace's
   front-left corner (between the Bunk House and the Bell Tower).
4. **Front plinth + grand stair:** stone, x -6..6, z 11..16, top 0; the grand stair down to the low floor
   (x -2..2, z 16..20, 9 steps of 25 cm).
5. **The Spiral:** a wooden stair-gallery 2.5 m wide hugging the pillar (r 4..6.5), rock on the inside. One flight
   per side, each up one floor, clockwise from above: right side 4.5 -> 6.75, back 6.75 -> 9, left 9 -> 11.25,
   front 11.25 -> 13.5. Each corner is a flat landing; each flight has a free 2 m block at its foot and top.
   Posts down to the terrace, brackets into the rock.
6. **Four houses**, one per side outside the Spiral (r 6.5..10.5), each with a lower door on the landing before
   its side's flight and an upper door on the landing after it (stairs inside link the two):
   - **Lamp House (right):** brick, 4.5..9 (2 storeys), gable tile roof (ridge ~11.5). Doors at 4.5 and 6.75.
   - **Store House (back):** brick 4.5..9, wooden storey 9..11.25 jutting 1 m back on brackets, gable shingle
     roof (~13.5). Doors at 6.75 and 9, a back door at 9 onto the Shrine Bridge.
   - **Bunk House (left):** brick 4.5..11.25 (3 storeys), wooden storey 11.25..13.5 jutting 1 m left on brackets,
     gable shingle roof (~16). Doors at 9 and 11.25.
   - **Bell Tower (front, over the main door):** brick 4.5..13.5 (4 storeys, a band at each), wooden storey
     13.5..15.75 jutting 1 m left and right on brackets (not over the front, nothing hangs over the main door),
     then the **Eyrie**: an 8-sided wooden lookout 15.75..18, a steep 8-sided spire to ~22, a bell and a finial.
     Doors at 11.25 and 13.5. **The best chest is in the Eyrie.**
     The tower changes shape 4 times: square brick, wider wood (out), 8-sided (in), spire.
7. **Arch Bridge (right):** stone, x 11..19, z -1..1, deck 4.5, from the terrace's right flat side over the crack.
8. **Kiln House (C)** on the rock lump: brick x 19..27, z -4..4, 2.25..6.75 (2 storeys), upper door on the bridge,
   lower door on the lump; gable tile roof, two chimneys. A chest.
9. **Shrine Bridge (back):** wood, x -1..1, from the Store House's back door (9) to the rock shelf (z -13), 1.5 m.
10. **Rock Shrine (D)** on the shelf: stone x -4..4, z -21..-15.5, back 1 m in the cave wall, 9..11.75, flat roof
    with battlements, round door facing the bridge. A chest.

Heights above the floor: Ring Hall 4.5, Kiln House ~9.5, Lamp House ~11.5, Rock Shrine ~12, Store House ~13.5,
Bunk House ~16, Bell Tower ~22 (one clear tallest), ceiling 25.
Ground levels: crack -4.5, low floor -2.25, cave floor 0, lump 2.25, shelf 9 (five).

## The way through (the fun of it)
Grand stair -> main door -> Ring Hall (round the pillar, a chest) -> stairs up -> terrace (4.5) -> the Spiral:
right flight (Lamp House) -> back flight (Store House; side trip over the Shrine Bridge) -> left flight (Bunk House)
-> front flight -> Bell Tower -> Eyrie (18) with the best chest. Side trip: terrace -> Arch Bridge -> Kiln House.

## Rule check (GRAND-RUIN-RECIPE + RUIN-RULES)
- 7 volumes (Ring Hall, 4 houses, Kiln House, Rock Shrine), 6+ heights, one tallest. The roofline climbs in a
  spiral: roofs at 9, 11.25, 13.5, 15.75 plus the spire, so it changes every few metres all round.
- Up, out, up, out: Bunk House and Bell Tower each step out on brackets, the Eyrie steps back in. Overhangs on
  brackets: Store House, Bunk House, Bell Tower, the Spiral into the rock. Brackets on plain wall only
  (`_brackets_off_windows`, `bracket_on_glass`).
- Castle: a ring that isn't the small watchtower ring (R = 3), meeting straight parts on flat square sides
  (the plinth at the front, the Arch Bridge on the right).
- Built into the cave (5 of 5): the pillar through the middle, the Shrine dug into the wall, five ground levels,
  two bridges over gaps, stairs hugging rock (the Spiral, the lump steps), the ceiling low over the Eyrie.
- Focal point: grand stair -> big round main door, lanterns, the Bell Tower right above it.
  Symmetry broken by the Kiln House on one side.
- Mine-head lessons (F912): every door has floor level with it (landings, terrace, bridge decks, the lump); no
  ramps to windows, no ladders.
- Stairs: a whole free 2 m block past every foot and top (each Spiral landing is 2.5 x 4.5 m); head room: the
  next turn of the Spiral is 9 m above, nothing hangs over a flight.
- Doors: 1 m of clear floor both sides; the main door gets 4 m of plinth and the low floor in front.
- Nothing grown (crystals, roots, small columns) on the terrace, the Spiral, the bridges or the lump steps.

## In the ruin
The left flight of the Spiral has fallen (you go up through the Bunk House inside instead), the Eyrie's spire
leans, the bell lies on the terrace, a Kiln House chimney is broken, rubble from the ceiling on the terrace,
holes in the roofs. Rebuild (cut stone + clay brick + wood) teaches the blueprint.

## Risks to settle in the build chat
- A natural column 9 m wide and 25 m tall may be rare (the world grows thinner ones). Owner's call (ask): grow one
  for this ruin, or a thinner pillar.
- The R = 3 ring is big: show the price on the ruin page; R = 2 (15 m) with smaller houses is the fallback.
- The Spiral is new: stairs and landings round a pillar; check the camera inside the narrow gallery (F784).

## Steps (in order, one at a time)
1. Owner OKs the shape page.
2. `BlueprintLibrary._pillar_spiral()` + id `"pillar_spiral"` in `IDS`/`NAMES`/`make()` (copy `_sinkhole_ring()`;
   the ring from `_big_ring_layer` / `_big_ring_edges` with R = 3).
3. A design test like the Sinkhole Ring one (stairs free block, walk-through, every door reachable, brackets off
   windows, F912 door steps, the ring meets the bridge and plinth flush, nothing inside the pillar).
4. Ruin page from the real blueprint, photographed first.
5. Owner OK, then the ruin in the game: find (or grow) the pillar, the crack, the lump and the shelf.
