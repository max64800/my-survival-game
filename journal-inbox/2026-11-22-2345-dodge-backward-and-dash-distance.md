## Nov 22 — The dodge still went backward sometimes, and a held dash died early (F702)

**What we did**
- The owner's bug report had two separate causes hiding under one feeling ("I dodge backwards, then it
  dodges forward, so I go back in place"):
  1. The roll's locked travel direction could itself be captured backward on the one frame it starts, if a key
     or the camera yaw misread for just that frame (same family as F494's keyboard quirk). In `dwarf.gd`, if the
     direction we're about to lock in is the dead opposite of how the dwarf's body is *actually already moving*
     at real speed, we now trust the real movement instead — a body can't flip direction in 1/60th of a second,
     but one bad input reading can.
  2. A held "big dodge" could cut out partway and just sprint the rest of the way, because the same
     dropped-input-frame quirk could read the dodge key as "let go" for one frame right as the normal roll time
     ended. Added a little grace in `dwarf_fight.gd` (`_dodge_held_grace`) so one dropped frame doesn't end a
     held dash early.
- Also made a held dash actually feel longer, not just last longer: past the normal roll time, `dodge_velocity()`
  now ramps speed up to 1.8x by the time you've held it the whole way, so a big dash gets a real forward burst
  instead of just the same roll speed sustained for longer.
- 2 new tests in `tests/test_dwarf.gd` covering both bugs directly (one dropped frame mid-dash, one flipped
  frame while already moving).

**Hurdles and mistakes**
- My new local variable `hv` collided with an unrelated `hv` another chat was adding in the same function for
  its own sprint-skid work — `godot --check-only` caught it as a parse error. Renamed mine to `real_v`.
- Another chat was actively editing `dwarf.gd` and `tests/test_dwarf.gd` at the same time. Committing the live
  files whole would have swept in their unfinished work. Rebuilt clean copies from the last commit plus only my
  own lines, and committed those instead of the live files, so their in-progress work stays uncommitted and
  untouched.
- Building those clean copies on Windows, a plain Python file read/write silently turned the file's line endings
  into Windows-style, which made every line look "changed" against the original. Fixed by turning off Python's
  newline translation when reading and writing.
- A first attempt at that same clean-copy step accidentally dropped a few lines that should have stayed. Caught
  it by comparing the rebuilt file against the original line by line before trusting it.
- The first attempt to actually save the commit failed outright (forgot to pass the tree to `git commit-tree`).
  Nothing was lost — just redid it correctly the second time.
