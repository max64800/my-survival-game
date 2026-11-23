## 2026-11-23 — Twin Gate stairs, round 3: a robot dwarf walks the towers (F783)

**What we did**
- Made a robot walk (`src/debug/tower_walk.gd`, run with `-- ruintest=twin_gate walk`). It loads the Twin Gate, opens the chest so it
  rebuilds, then walks the real dwarf body up and down every flight in both towers and through every door.
- Made a "where can I walk?" map (`src/debug/reach_map.gd`). It is a flood fill: like pouring water on the floor and seeing
  where it can flow, in 25 cm steps, using the dwarf's own body shape.
- Found two real blocks:
  1. The deck stairs come up *inside* the round stage. Full railings on both long sides meant the stair top only led out of
     the door, so the stage was fenced off. Now the stage-side railing is short (only on the deep half of the hole).
  2. The right tower is a mirror of the left one, but its stage stairs were not mirrored. Their foot sat behind a gap of 0.7 m,
     too narrow for the dwarf. Added a `back` flag so they climb the other way, plus a load-time fix for old worlds (`_fix_right_stage`).
- The robot then climbed every flight up and down in both towers to 13.25 m: 0 problems.
- New test `test_every_tower_flight_and_door_can_be_reached`. It fails with the old railing, so it would have caught this.
- New rule row 8 in `docs/design/WALK-THROUGH-RULES.md`.

**Mistakes and hurdles (including Claude's)**
- The robot first measured heights wrongly, so it reported climbs that weren't real. Fixed by measuring from the feet.
- The first flood fill gave false alarms: it lifted straight up at a stair's foot and bumped the floor above. Fixed by trying
  "forward and a little up together" first, like sliding up a ramp.
- The first robot run crashed, and another chat's half-finished file had a parse error that stopped the game from starting.
- I fixed the blueprint, but the left tower stayed blocked: the ruin is built from a saved JSON file, which I hadn't made again.
- In the test, doors stayed shut (they only open after they are added to the scene), and an open door leaf then fenced a stair top.
  The test now leaves doors out, since a player always pushes a door away from themselves.
- I wrote the fix spots with the wrong z (blueprint spots, not shifted ones). Fixed before committing.
- A test variable named `short` clashed with one already there. Renamed it.
- `test_ruin_twin_gate` still has failing checks (stone "learn both blueprints", the wooden rebuild). They fail at HEAD too
  (checked in a clean copy), so they are not from this change. Handed them to the Twin Gate fixes chat.

**Handed over:** F781 (jitter), F803 (falling through going down), F804 (floating stair railings) and F811 went to the
"Twin Gate fixes" chat, which also replaces the short-railing fix with its F811 layout.
