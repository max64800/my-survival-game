# Grand ruins: how to make a ruin players can't build themselves (owner, Nov 21, 2026)

The owner, after the Old Kiln: "Right now all of our towers are either circular or squared. They're very easy shapes.
... I'm not a builder. I don't know how to build stuff like that. But I do want players to see this and say: oh my
god, I don't know how to build like that, but I absolutely love it. If I had a blueprint... This is a very unique
selling point of our game. Starting from the next one, build them this complicated and this good. If you're missing
any pieces, we can create some."

So from ruin 6 (Twin Gate) on, every ruin's whole version is a **showpiece**: the kind of building only a skilled
builder makes. The ruin is the advert; the blueprint is the prize. This file is the recipe. It adds to
`BLUEPRINT-RECIPE.md` (its rules still hold: stairs never start against a wall, no steps in corners, no window beside
a door, round doors, Hearthbrick/Shack roofs slope, Stonehold roofs flat) and `ruin-rebuild-plan.md`.

We learn the *ways of building* from the best player builds in other games (the owner's screenshots, Nov 21: big
timber-and-stone halls, castles, a tall tiered tower). We never copy a build, a name or a look: the shapes come from
our own dwarf world and our own piece kit.

**Every lesson from the ruins built so far (stairs, railings, doors, caves, rebuilds) is in
`docs/design/RUIN-RULES.md`. Read it first.**

## What the great builds do (and our simple ones don't)

1. **Many volumes, not one box.** A main hall, wings, a tower, a gatehouse, a lean-to: each its own block with its own
   roof, joined together. Their heights step up toward one tallest part, so the outline reads as a pyramid or a
   mountain from far away. Rule: **at least 4 volumes of at least 3 different heights**, and one clear tallest.
2. **A strong silhouette on top.** Roofs at many levels, steep spires on the towers, small roofs poking out of big ones
   (dormers), lookout rooms on top of towers, a weathervane or banner at the very top. Rule: **the roofline changes
   every 4-6 m**; no long flat ridge with nothing on it.
3. **Upper floors wider than lower ones.** Top floors jut out over the walls below on brackets (a jetty), tower tops
   overhang on corbels, balconies stick out. It is the single most "how did they do that" trick, and it throws deep
   shadows. Rule: **every grand ruin has at least one overhang on brackets.**
4. **Built on a base.** A raised stone plinth or terraces with low walls and railings, wide stair flights up to the
   main door, a lower terrace at the side. The building sits *on* something. Rule: **a terrace or plinth with a grand
   stair**, landings on open ground.
5. **Materials in bands.** Heavy stone at the bottom, then brick or timber framing higher up, a trim band (cornice)
   at every floor line and under every roof. Rule: **a visible band at every floor line**; the ground storey heavier.
6. **Rhythm and depth on every wall.** Pillars every bay, windows set back, walls that step in and out, no wall longer
   than 6 m without a break (a pillar, a buttress, a bay window, a turn). Rule: **nothing flat and long.**
7. **One grand focal point.** A big arched entrance in the middle of the main front, lit, flanked by statues, banners
   or columns; the stairs lead to it. Rule: **the eye lands on the main door first.**
8. **Symmetry, broken once.** The main front is mostly symmetrical; one tower or wing on one side breaks it on
   purpose, so it looks grown, not stamped.
9. **Towers that aren't tubes.** Square towers with corner turrets; towers that change shape as they rise (square
   base, eight sides above, round lantern on top); towers in tiers, each a bit narrower, each with its own cornice;
   a spire roof on top. Rule: **a tower changes at least twice from bottom to top.**
10. **Lived-in details.** Banners, lanterns at doors, statues, planters, crates by the door, furniture inside (the
    ruin junk and decor rules). The ruin shows them broken; the blueprint stays empty for the player to furnish.

## Shapes our grid can make (2 m pieces)
- Squares, rectangles, L, T, U and courtyards; the 12-sided ring (round towers, `_ring_*` helpers; any size with
  `_big_ring_*`, see Castle builds below); half pieces
  (`foundation_half`, `floor_half`, `wall_narrow`: 1 m steps in the outline); triangles (`floor_triangle`,
  `foundation_triangle`); diagonal walls and railings (`wall_diagonal`, `half_wall_diagonal`, `window_diagonal`,
  `railing_diagonal`: eight-sided towers, cut corners, bay windows).
- Roofs: `roof_26` / `roof_45` slopes, ridges, inner and outer corners (hips and valleys: a square tower gets a
  pyramid roof from four outer corners; an L hall gets a valley), gables.
- Stonehold: battlements and corner battlements, flat roofs. Hearthbrick and Shack: sloped only.

## Pieces we are missing (make them when a ruin needs them; owner, Nov 21: "we can create some")
Every new piece: Blender by script in the style (MODEL-RULES.md), a game piece with a price, tests.
- **Brackets / corbels** (all 3 styles): under a floor that juts out 1 m past the wall below (jetties, balconies,
  overhanging tower tops). The key missing piece.
- **Spire roofs**: a steep pyramid cap for square towers (4 m and 6 m) and a cone for the 12-sided ring (the Kiln
  Crown's closed sister), in Shack and Hearthbrick; with a finial on top.
- **Dormer**: a small window with its own little gable roof that sits on a big roof slope.
- **Cornice / trim band**: a thin moulding that runs along a floor line or under the eaves (a wall-top piece).
- **Buttress**: a sloped pier against a wall (breaks long walls, holds tall ones).
- **Grand portal**: a wide round arch (4 m) for main entrances and gates. (The owner's rule is one round doorway per
  style: ask before making a second kind.)
- **Turret**: a small round corner tower on brackets, hanging off a square tower's corner (castle look).
- **Spiral stair** for round towers (stairs that turn 30 degrees a step).

## Checklist before the 3D page
- [ ] 4+ volumes, 3+ heights, one tallest; the roofline changes every 4-6 m.
- [ ] At least one overhang on brackets; a tower that changes shape twice.
- [ ] A terrace or plinth, a grand stair to a focal main door.
- [ ] Bands at floor lines; no flat wall longer than 6 m.
- [ ] The BLUEPRINT-RECIPE rules (stairs, steps, windows, round doors, roofs per style); everything on the grid,
      stairs meet floors, nothing floats (the blueprint checks).
- [ ] Stairs up to a balcony land on floor as wide as the stairs, with room to step off and walk to the door
      (owner, Nov 22, F615: a 1 m balcony beside a 2 m stair "doesn't really work"; make a 2 m landing there).
- [ ] Every staircase has a whole free 2 m block past its foot and its top (a triangle after round-stage stairs);
      move the stairs rather than squeeze in half railings (owner, Nov 23, F811). `test_stairs_free_block` must pass.
- [ ] The dwarf can walk everywhere (owner, Nov 22, F626): balconies and galleries are whole floor tiles (no half
      or small floors), spiral stairs need a tower of 4×4 cells or more and go in and out onto open floor (never
      a wall or a railing), no roof cap. Add a test like `test_hearth_manor_stairs_lead_onto_floor`.
- [ ] Every rule in `docs/design/RUIN-RULES.md`, and every lesson in `docs/design/WALK-THROUGH-RULES.md` (doors with room on both sides, nothing across a stair's
      way out, corner stairs come out sideways). `test_walk_through` must pass.
- [ ] Cost: a showpiece is big. Show the price on the page; the owner decides if it is too much.
- [ ] Page from `tools/ruins/kiln_page.html` (ruin / wood / original, "Mark new pieces", roof and upper floor on/off,
      decor inside the ruin). Photograph it yourself first; at most 2 photo rounds.

## Layered builds: up, out, up, out (owner, Nov 22, for ruin 8 on)
The owner, after the Hearth Manor: "make it more complicated, layered... it goes up, then it expands, then it goes
up, then it expands again". We still had flat walls and square towers. What the best survival-game builders do
(research Nov 22; mostly old forum guides, so treat it as ideas, not facts):
1. **Stepped tiers (a stepped pyramid).** Stack foundations so each tier is one cell smaller (or bigger), with a long
   stair up the outside to the building on top. For us: a 2-3 tier plinth, then the hall on top.
2. **Out, then up, then out again.** A storey sticks out 1 cell past the one below on brackets (a jetty); the next
   storey steps back in (a setback) with a walkable terrace on the ledge; the one above that juts out again. The
   outline zig-zags, like a stack of offset boxes. Every overhang is held by brackets or a pillar/foundation below
   (our Structure must say it stands).
3. **Changing shape on the way up.** A square base, cut corners above (diagonal walls), round or octagonal at the
   top. Keep the same shape above and below a support (square on square), and change it on a floor, not mid-wall.
4. **Thick, layered outer walls.** A wall, a gap, a second wall (a walkway or a gallery inside the thickness);
   pillars or buttresses standing proud of the wall face; recessed window bays. No flat 6 m wall.
5. **Bridges and walkways between parts.** A covered bridge or open walkway from one tower or wing to another at an
   upper storey; a sloped walkway down to a lower terrace.
6. **Built into the rock.** Half the building grows out of the cave wall or a rock ledge: cheap to read as "old", and
   it gives levels for free. (Our ruins carve their space, so this means a back side set into rock.)
Checklist add: **at least 2 places where the outline steps OUT above a step IN** (seen from the side it is not a
straight line), and every jutting floor walkable (the F626 rule).

## Built into the cave (owner, Nov 22, F657: every ruin from now on)
The owner loved how Cliff Watch's back sits in the rock and the Prow Hall plan's lone tower stands on a rock lump:
"all the next buildings... using the shape of the cave... not just on a flat surface, but embedded in the cave.
You can amplify this." So no ruin stands alone on a flat carved floor any more. Use at least 3 of these:
1. **A back or a side set into a rock wall** (rooms that go into the rock, rock showing through broken walls).
2. **Parts on different ground levels:** a terrace on a ledge, a tower on a rock lump, a cellar dug down.
3. **A bridge or walkway over a dip or a gap** in the cave floor.
4. **Stairs cut into a slope** between levels, rock on one side.
5. **Rock that "grew" back:** a pillar of cave rock through a broken floor, the cave ceiling low over a back room.
The cave shape is made by the world, not by building pieces. **Owner, Nov 23: use a cave that's already there.**
The world grows its caves as normal; the ruin finds a natural cave that fits its plan and carves only a little.
Never grow a cave round the fort or place extra rock lumps round it (Twin Gate first, then every ruin). The placement rule still holds: nothing the world
grows (columns, crystals, plants) stands inside the ruin or on its paths. Show the cave shape on the 3D page.
Checklist add: **3+ of the 5 above, and the cave rock visible on the page.**

## Castle builds: round towers from squares and triangles (owner, Nov 22, F656)
The owner wants castle builds like the best survival-game builders make. Research Nov 22 (floor-plan guides, circle
tutorials and the owner's 12 reference pictures; the web was thin, the pictures taught most). We learn the
patterns, never copy a build, a name or a picture.
1. **No curved pieces.** A "round" tower is a 12-sided ring: 6 triangles (a hexagon) in the middle, a square on each
   of its sides, a triangle in each gap. The closest to a circle you can get with 90 and 60 degree corners.
2. **Bigger rings = the same plan, scaled.** A ring R times wider splits every big piece into R x R small ones:
   squares = 6 R^2, triangles = 12 R^2, 12 flat sides of R walls each. R = 1: 7.5 m across (our watchtower),
   R = 2: 15 m, R = 3: 22 m. In code: `_big_ring_layer`, `_big_ring_edges`, `_big_ring_corners`,
   `_big_ring_stairs`, `_big_ring_rails` (`BlueprintLibrary`; test tower `stonehold_round_test`).
3. **Round towers on a rectangle's corners.** Four rings, and the hall between them meets each ring on one flat
   side (a square side faces straight out, so a straight wall snaps to it).
4. **Tower, long wall or bridge, tower.** Two (or six, in a hexagon) round towers joined by straight walls with a
   walkway on top. The walkway meets each tower on a flat side.
5. **Wedge tips.** Rooms end in a triangle point, not a flat end (a prow), or a half ring (a round apse).
6. **Stairs round the ring's edge.** Flights run along the outer row of squares, a different side each floor; the
   middle stays open for a room (or a tight spiral round a middle pillar in a small ring).
7. **Many sizes and heights.** A big ring with a small ring standing on its roof (steps in as it rises); a small
   ring that juts out above (on brackets) for a wider top; turrets on brackets on corners; every tower a different
   height, the tallest one in the middle or at the gate.
8. **Roofs that point.** The small towers get pointed cone or spire roofs; the big ones battlements. (Stonehold is
   flat-only: which style gets cones is the owner's call.)
9. **Lay the plan first.** The good builds start from a floor plan of the foundation layer only: the outline is the
   design. Draw it from rings, wedges and rectangles before adding walls.
Checklist add: **at least one ring that isn't the small watchtower ring**, and a round tower meeting a straight part.
