# Dash roll: constant speed, not a speed burst (F702, 4th round)

**What we did:** Last round fixed the roll ANIMATION so it kept playing (tumbling) through a held dash instead of
standing up early. The owner played that fix and liked the animation — but spotted a different, older problem
hiding underneath it: the dwarf's actual travel speed sped up toward the end of a held dash, so he felt "too fast
at the end of the long dodge." The owner's rule was simple: beginning and end of the dash must move at exactly
the same speed. Holding the button should only make the dash last longer, never faster.

**The mistake:** Back in the very first attempt at this feature (Nov 22), we added a `DASH_SPEED_MULT := 1.8`
multiplier that ramped a held dash's speed from 1x up to 1.8x as it approached the 0.75 s hold cap. That was meant
to make "holding it longer" feel like a real forward burst. It's exactly what the owner was complaining about on
the 2nd and 3rd rounds too ("he propels me forward" / "speeds up at the end"), but each time we fixed the
animation-timing SYMPTOM around it instead of asking why he was still speeding up at all.

**The fix:** Deleted `DASH_SPEED_MULT` and the lerp in `DwarfFight.dodge_velocity()` entirely. The dash now always
moves at `DODGE_DISTANCE / DODGE_TIME` (≈6.67 m/s), tap or held, start to finish. Holding the button still makes
the dash travel farther — but only because it keeps moving for longer (up to the same 0.75 s cap as before), never
because it moves faster.

**How we checked it:** Ran the `src/debug/dashcheck.gd` robot (built for the last round's fix) again — it holds
the real dodge key and prints the dwarf's speed every physics tick. Before: speed held at 6.67 for the first
0.45 s, then climbed steadily to ~11.7 by t=0.75 s. After: speed holds flat at 6.67 for the entire 0.75 s hold,
only slowing down naturally once the dash ends and he's standing again. Added a new automated test,
`test_held_dash_moves_at_the_same_speed_start_to_finish`, which samples the dash's speed right after the button
is pressed and right before it ends and checks they match.

**Hurdle:** the full test suite (`tools/run_tests.sh` with no filters) took far longer than its usual ~2-3 minutes
this round — the `GODOT` test process was still visibly chewing through CPU three-quarters of an hour later. Checked
with Windows `Get-Process`: CPU time kept climbing steadily the whole time (not stuck), just starved for CPU
because several other Claude chats were running their own Godot instances on the same PC at once. Ran the
dash-specific tests (`only=test_dwarf fn=dash`) on their own first to confirm the fix quickly, then let the full
suite keep running in the background rather than block on it.

**Also hit:** `test_dwarf_fist.test_great_swings_keep_fists_and_handle_room` failed once, passed the next two times,
with my dash change present both times — confirmed flaky/unrelated (it's about fist-swing handle clearance, not
dodging) rather than a regression, by re-running it a few times.

Files: `src/combat/dwarf_fight.gd` (removed `DASH_SPEED_MULT`, `dodge_velocity()` now constant-speed), minor
comment cleanups in `src/combat/combat.gd` and `tests/test_dwarf.gd` that referenced the old "speeding up" wording,
new test in `tests/test_dwarf.gd`.
