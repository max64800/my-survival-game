## Nov 23 — The held dash's "stand up" animation was finishing mid-burst, not after it (F702)

**What we did**
- F702 came back a 3rd time: "I think I realized the problem. In order for me to do a long dodge, I am holding the
  control key all the way until the dwarf stops rolling... after my animation of the dodge is done, he propels me
  forward." Real self-diagnosis, confirmed exactly right.
- Built a debug robot, `src/debug/dashcheck.gd`: holds the real "dodge" key (Ctrl) like a real keyboard would, prints
  every physics tick's dodge state and roll-animation stretch next to his real position/speed, and takes screenshots
  at key moments.
- Root cause (found from the robot's numbers + screenshots, not guessed): the roll animation clip was always
  stretched to finish in exactly 0.75 s (`Combat.DASH_HOLD_MAX`) for ANY held dash — same stretch a plain quick tap
  gets. A quick tap stops moving well before 0.75 s, so the clip's last bit (stand up, settle) plays while he's
  already stationary — invisible, fine, intended. But a HELD dash keeps speeding up right up to that same 0.75 s
  cap, so that identical "stand up" animation content played out DURING the fastest part of the dash — looking
  exactly like the animation ending and then physics shoving him the rest of the way, which is precisely what the
  owner described.
- Fix: `DwarfFight.dodge_expected_duration()` now returns `DASH_HOLD_MAX + DASH_RECOVERY_TAIL` (0.75 + 0.3 = 1.05 s)
  while a dash is still held, instead of flatly `DASH_HOLD_MAX`. This gives the clip the same kind of "stand up"
  budget a tap roll already gets (the 0.3 s between `DODGE_TIME` and `ROLL_TIME`), but spent AFTER the held dash's
  speed burst ends, during its natural slow-down, instead of during the burst. No changes needed in `dwarf_rig.gd`
  — it already re-stretches the playing clip live to whatever target duration it's given; only the target value was
  wrong. No changes to any tuning numbers (dash distance, speed, hold cap) either — this was purely an animation
  bug.
- Re-ran the same robot after the fix: at t=0.75 s (same distance/speed as the broken run, so a fair comparison),
  he's now still mid-roll instead of already standing; screenshot confirms it (crouched/tucked at t=0.75, back to
  standing only once his velocity has decayed around t=0.95).
- New test `test_held_dash_roll_still_has_recovery_left_when_the_dash_ends`; updated
  `test_roll_animation_matches_how_long_the_dash_lasts` to expect the new, longer stretch.

**Hurdles and mistakes**
- Early on, reasoned abstractly about possible fixes (looping the clip, freezing a frame, etc.) from a summary of
  earlier findings instead of the actual saved robot log and screenshots. Caught it and went back to read the real
  data directly — that's what surfaced the exact, load-bearing detail (`DASH_HOLD_MAX` happens to equal
  `DwarfRig.ROLL_TIME`, both 0.75 s) that explained the whole bug. Lesson: re-read the real evidence, don't reason
  from a paraphrase of it, especially for a timing bug this exact.
- `tools/run_tests.sh`'s `only=` filters by test FILE name, not test function name — `only=dash` matched 0 checks
  (a misleadingly "successful" empty run). `fn=` is the one that filters by function name; the right combo for one
  test file is `only=<file> fn=<function>`.
- `tools/run_tests.sh` needs `GODOT` set on this PC (`godot` isn't on PATH) — same as every other session this week.
- Two already-running Godot processes showed up mid-session; a `taskkill` on them was auto-denied as a destructive
  action. Asked the owner instead of forcing it — they said those were leftovers from testing and fine to close
  (turned out they'd already exited on their own by the time the retry ran).
- Ran the full `test_dwarf.gd` file at the end (not just the dash-filtered subset) and found 3 failures
  (`test_braid_tufts_swing_when_moving`, `test_aim_skips_things_behind_the_dwarf`, `test_your_own_stun_meter`).
  Checked by stashing this session's changes and re-running those 3 on the old code: the hair-swing and stun-meter
  ones fail identically either way (pre-existing, unrelated to this fix); the aim one passed on its own that time
  (flaky dummy-renderer error, not caused by this change). Not touched here.

**Play-test:** hold Ctrl for a long dash — he should still look like he's mid-tumble through the fast part, only
standing up as he slows down near the end, not mid-burst.
