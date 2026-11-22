## Nov 23: Twin Gate doors, corner stairs and camera jitter (F783, F784)

**What the owner saw (3 screenshots):** on the rebuilt wooden Twin Gate, both tower doors on the gate roof had a
railing right behind them, the corner stairs in the towers were fenced in, and the camera jittered on the wall walks.
The owner also asked us to write down every lesson after each round, so these mistakes don't come back.

**What we did**
- The roof-level stairs in each tower now climb toward the door. Before, they climbed away from it, and the railing
  round their stair hole stood right inside the door.
- The railing gap at the corner stairs is now on the side you really step off. Corner stairs come out sideways, not
  straight ahead. The right tower is a mirror image, so its gap had to flip too.
- Worlds already built get fixed when they load (`RuinTwinGate._fix_blocked_ways`).
- Camera: a new `CameraRoom` (src/player/camera_room.gd). The camera now only bumps into big solid pieces and rock,
  and slips past railings, battlements and posts.
- New lessons page `docs/design/WALK-THROUGH-RULES.md` (7 lessons so far), linked from both recipes.
- New checks: `test_walk_through` (every blueprint: stairs' ways in and out, room at every door, plus a self-test
  proving it catches the old railing), `test_camera_room`, and a load-fix check in the Twin Gate test.

**Mistakes and hurdles (including Claude's)**
- Root cause 1: Claude placed the deck stairs without checking where they arrive compared with the door.
- Root cause 2: Claude thought corner stairs come out straight ahead. They come out sideways. Mirroring the tower
  copied the mistake to the other side.
- Claude wrote `var corner_out := ...`, which Godot can't type. It broke compiling for every chat until it was fixed
  to `var corner_out: bool = ...` (another chat spotted it).
- Claude first labelled the fix F782, but that number was already taken (the healing fountain). Renamed to F783.
- The first door check tested at 1 m height. A railing is only 1 m tall, so it missed the very railing it was meant to
  catch. Now it tests at waist height, and a self-test puts the old railing back to prove the check finds it.
- The first door check used square "shoebox" outlines and wrongly blamed the Prow Hall's slanted railings. It now
  uses each piece's true outline.
- Another chat's robot test (walking up every flight) failed: the flight now ends at a closed door 0.73 m past the
  top. Its last step now lands just past the top step instead.
- `tools/run_tests.sh` couldn't find Godot on this PC. We set `GODOT` to the WinGet Godot console program.
- Found, not fixed (asking the owner): the Watchtower Cabin's stairs start against a wall.
- Still open: a test error inside builder.gd from another chat's unfinished work (the wooden rushed rebuild test).
- The Twin Gate's 3D page (tools/ruins/twin_gate_page.html) still shows the old stairs.
