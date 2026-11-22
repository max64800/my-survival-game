## Smooth walk-to-run (F701)

What we did: the owner noticed that pressing Shift (run) made the dwarf snap from walking speed straight to
running speed, like a jump cut, instead of speeding up smoothly. Think of a car: pressing the gas pedal doesn't
teleport you to 60 mph, it eases you there. We wanted walking-to-running to feel the same way.

The old code picked a "target speed" (walk or run) the instant you pressed or let go of Shift, then had a separate
system that pushes your actual speed toward that target pretty fast. Because the target itself jumped instantly,
your speed still closed almost the whole gap in about two frames (1/30th of a second) — too fast for a human eye,
basically a snap.

The fix: we added a second, slower "easing" step. Instead of the target jumping straight to run speed, it now
slides there over about a third of a second (a new number called `SPEED_BLEND` in `dwarf.gd`). The dwarf still
speeds up quickly, just not instantly — it feels like accelerating, not teleporting. This also means slowing back
down from run to walk eases out the same way.

Hurdles:
- First attempt to edit the file failed because of a tabs-vs-spaces mismatch (we guessed the code used two tabs
  of indentation where it actually used one) — fixed by re-reading the exact line before editing again.
- We wrote a new automated test to check this (`test_walk_eases_into_run_not_a_snap` in `tests/test_dwarf.gd`).
  To make sure the test was actually testing something real (not just passing no matter what), we temporarily
  turned the fix back off, re-ran the test, and watched it fail with "biggest step 1.21 m/s" — proof the old snap
  would have been caught. Then we turned the fix back on and it passed again.
- Running the whole test suite showed 3 unrelated failures (hair swing timing, an aiming test, and the stun meter)
  — these come from another Claude session's in-progress changes to the combat file (`dwarf_fight.gd`), not from
  our walking change. We left those alone since they're not ours to fix.
- The very first full-suite run we started (before this fix) hit a crash (segfault) deep in dungeon-building test
  code, totally unrelated to walking or running. Flagging it for the owner as a "Claude noticed" item rather than
  chasing it, since it's not something they asked about and not something this task touched.
- A muted, tagged test game (`claude=walk_to_run_smoothing`) booted cleanly with no new errors.

What was checked: the new unit test (and proved it actually catches the bug), the full `test_dwarf.gd` file (no
regressions from our change), and a real muted test-game boot.

Next: F702 (hold-to-dash).
