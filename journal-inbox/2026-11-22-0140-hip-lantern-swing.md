## Nov 22: The hip lantern swings (F613, Claude 3)

**What the owner asked:** "make it swing too", for the Hip Lantern on the belt.

**What we did:** `lantern.gd` `_swing_step()`: a small pendulum. Each frame it looks at how the belt point speeds up or
slows down (walking, stopping, turning, the hips swaying in the walk) and pushes the lantern the other way, then a spring
pulls it back and it dies down. It turns around the belt ring, so the ring stays on the belt. Up to about 30°.
Teleports and the first frame start it still. Test: `test_hip_lantern_swings_when_he_stops` (straight when still, swings
8–35° on a hard stop, ring stays on the belt, still again after 3 s, clear of the ground).

**Mistakes and hurdles (Claude's own)**
- The first swing was much too small (5°). I blamed the push number, changed it, and got the same result. The real cause was
  the glitch cap (40 m/s²): it also cut off a real hard stop. Lesson: work out which limit is clamping before tuning.
- Saving the F613 note, I committed the whole FEEDBACK.md file, which also swept in another Claude's unsaved F577 line.
  Harmless (it's a real line), but against the "only your own lines" rule. Next time: commit a copy of HEAD plus only my
  line for shared files.
