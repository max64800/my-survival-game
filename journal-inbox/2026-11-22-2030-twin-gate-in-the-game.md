## Nov 22 (evening, PC): the Twin Gate goes into the game (ruin 6, F479 + F656)

**What we did**
- The Twin Gate (the grand stone gatehouse with two towers) is now a ruin in new worlds, copied from how the Prow Hall
  was put in: `src/world/ruin_twin_gate.gd`, hooked into main.gd, cave_maker.gd (its spot is picked and kept clear),
  loot_props.gd and the dev menu's Ruins list ("Twin Gate").
- The owner said yes to cave shapes (F657): the game grows a rough rock wall behind the barracks and two rock lumps
  (one by the grand stair, one by the fallen tower), and digs an L-shaped moat beside the left tower.
  The blueprint only digs air round its own pieces (a shared helper `_air_only_round_pieces`, now used by the Prow
  Hall too).
- Three new Stonehold pieces became real game pieces: Buttress, Corner Turret (bartizan, walk-in from the deck) and
  Short Battlement. Models installed from `stonehold_v2_twin.py`, icons made, entries in Pieces.LIST.
- The trims (bands, corner blocks, brackets, buttresses, turrets) used to live only in the Python ruin script.
  Now the blueprint adds them itself (`BlueprintLibrary._twin_trims`), so rebuilding gives you the same building
  as the ruin shows. The Python script was changed so it never adds them twice.
- Tests: `tests/test_ruin_twin_gate.gd`: plan whole, stands up, blueprint matches its ruin, cave shape, spot keeps
  clear on 3 worlds, in the Ruins menu, full rebuild in stone (1,100 pieces).
- Logged owner feedback: F626 🔁 (Hearth Manor: spiral stairs can't be climbed, odd pyramid roof), F169 🔁 (remove the
  solid block under every stair) and F710 (the Prow Hall's main-building floors are too low).

**Mistakes and hurdles (and fixes)**
- The test runner couldn't find Godot (not on PATH in this shell): set `GODOT=` in the same command.
- One test "passed" while the code had a compile error (the runner printed ALL PASSED after "Failed to load
  script"). Lesson: when a single test passes suspiciously fast, check the output for "Compilation failed".
- A GDScript type error (`var z := 5.0 * sz` with an untyped loop value) broke loading: typed it as float.
- The cave check counted 155 "digs into rock" that were really moat digs below ground where no rock grows (rock
  height 0). Fixed the check to only count spots where rock is grown.
- The stone rebuild stalled twice: first "someone is in the way" (the test dwarf stood where a buttress goes;
  moved it high above the gate), then "something is in the way": the 3.3 m turret's whole box blocked the tower
  deck's own walls and floor. Fix: a piece can now say which part of it takes room (`overlap_rect`); the turret only
  takes the part past the tower corner.
