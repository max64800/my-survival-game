# Walk-through rules: lessons from every round (owner, Nov 23, 2026)

The owner asked: "document everything that we're learning after every round, so we don't make these kind of mistakes."
Every time a building turns out hard to walk through, the lesson goes here **and** gets an automatic check.
Read this before building or changing any blueprint, ruin or tower. Newest lessons at the bottom.
All ruin lessons (not only walking) are gathered in `docs/design/RUIN-RULES.md`.

| # | Lesson (the rule) | What went wrong | Automatic check |
|---|---|---|---|
| 1 | **Spiral stairs only in a tower of 4×4 cells or more, going in and out onto open floor.** Better: use straight or corner stairs. | Nov 22 (F626, F713): spiral stairs in the Manor and Twin Gate couldn't be climbed; you got stuck in a tower. | `test_dwarf_walks_up_every_tower_flight` walks a robot dwarf up every flight. |
| 2 | **Balconies and galleries are whole floor tiles**, and a stair lands on floor as wide as the stair. | Nov 22 (F615): a 1 m balcony beside a 2 m stair "doesn't really work". | `test_hearth_manor_stairs_lead_onto_floor` and its cousins. |
| 3 | **Nothing stands across a stair's way in or way out**: no railing, wall or battlement. | Nov 23 (F783): the Twin Gate's corner stairs were fenced in. | `test_walk_through.test_stairs_ways_in_and_out_are_open` (every blueprint). |
| 4 | **Corner stairs come out SIDEWAYS** (in at their front, out at their left side, near the back), not straight ahead. When a tower is the mirror image of another, the way out flips side too, so check each tower on its own. | Nov 23 (F783): the railing gap was left at the "front", where nobody comes out. The right tower was a mirror copy, so its gap was on the wrong side as well. | Same test: it knows the corner stairs' real way out. |
| 5 | **Every door has clear floor on both sides** (about 1 m), where you walk up to it and where it swings open. Put stairs so they arrive **at** the door, not beside it with a railing in between. | Nov 23 (F783): on the Twin Gate's roof, railings stood right inside both tower doors. The deck stairs climbed the wrong way, so the railing fenced off the stair hole and the door with it. | `test_walk_through.test_doors_have_room_on_both_sides` (every blueprint), proven by `test_the_door_check_finds_the_old_twin_gate_railing`. |
| 6 | **Fixing a blueprint also fixes worlds already built**: a ruin that changes gets a load-time fix (take the old pieces out, put the new ones in, only where nothing is in the way). | Nov 22–23 (F713, F783): old saves kept the broken stairs and railings. | `test_rebuild_the_twin_gate_in_stone` builds the old way, loads, checks it's fixed. |
| 7 | **The camera only bumps into big solid pieces** (walls, floors, roofs, stairs) and rock. Thin pieces (railings, battlements, posts, lamps) never push it in. A new thin piece needs nothing; a new solid piece goes on the `SOLID` list in `src/player/camera_room.gd`. | Nov 23 (F784): walking along the Twin Gate's wall walks, every railing passing behind the dwarf made the camera jump in and out (jitter). | `test_camera_room` |
| 8 | **Walk it from the floor, not flight by flight.** Every flight's foot and top, and both sides of every upper door, must be reachable from the ground floor (a flood fill with the dwarf's own body). A stair hole inside a room gets railings only on its deep half; a mirrored building mirrors its stairs too; a ruin built from a JSON gets that JSON made again after the blueprint changes. | Nov 23 (F783 round 3): each flight climbed fine on its own, yet the deck stairs' full railings fenced off the round stage, and the right tower's stage stairs (not mirrored) started behind a 0.7 m gap. The ruin still used the old JSON. | `test_new_pieces.test_every_tower_flight_and_door_can_be_reached` (uses `src/debug/reach_map.gd`); robot walk: `-- ruintest=twin_gate walk`. |

## Before calling a building done
1. Run `tools/run_tests.sh only=test_walk_through` (every blueprint, under 2 seconds).
2. Walk it yourself in the game, or have the robot walk every flight.
3. Something new went wrong? Add a row above **and** a check that would have caught it.
