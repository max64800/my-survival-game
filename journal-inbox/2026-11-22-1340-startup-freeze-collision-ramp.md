## Nov 22 — Found why the game froze at the very start ("7 FPS", slow motion) (F417)

**What we did:** The owner was playing live and said the game was at ~7 FPS from the start, felt like slow motion, and
they had to close it. They asked Claude to check the logs.
- The shared game log (`godot.log`) was no help: several test robots were also running on the same PC at the same
  time and writing into it, so it was a garbled mix of everyone's sessions. The game's *other* log, `user://watch.txt`,
  only gets written by a real play session (never a robot) — that one was clean and told the real story.
- The clean log showed: the game froze solid for about 7 seconds right at the start, while "loading the rock around
  you". After that it ran a smooth 60 FPS the whole time it was open. So this wasn't an ongoing slowdown — it was one
  big freeze at the very beginning that felt like the whole game was broken.
- The cause: the instant you spawn, the game asks Voxel Tools (the cave engine) for 100 m of walkable (solid) rock
  all at once. Building solid ground costs 3-5x more than just drawing it, and it happens on the game's one main
  thread — so asking for all 100 m in a single go froze the picture for several seconds.
- The fix: `src/world/world.gd` got `collision_ramp(elapsed)` — the ground now starts solid for 24 m around you
  (plenty to stand on) and grows to the full 100 m over 6 seconds instead of all at once. `src/main.gd` drives this
  every frame after you spawn. Nothing looks different to a player; the ground just becomes walkable a little further
  out each second instead of all at once.
- New test: `tests/test_world.gd` → `test_collision_ramp_starts_small_and_grows_to_full_distance`.
- Logged under F417 in `FEEDBACK.md` (same recurring "FPS drop near the start" family as past fixes for slow creature
  loading and firefly swarms) since this is another cause of that same long-running complaint, not a new one.

**Mistakes and hurdles:**
- Claude's first read of the logs was wrong: it grabbed timestamped lines out of the garbled shared `godot.log` and
  found a real LOW FPS 7-8 pattern — but that turned out to be from Claude's *own* background test-suite run at an
  earlier time, not the owner's session at all. Switching to the player-only `user://watch.txt` (which the game's own
  code already explains is there for exactly this reason) gave the real, clean answer.
- Before trusting the fix, Claude ran the same failing regression test (`test_save`) with its own changes stashed out,
  to prove a pre-existing compile error (from another Claude's in-progress, uncommitted edit to `src/combat/dwarf_fight.gd`
  on the same shared PC) was not caused by this fix. It wasn't — that file was left untouched, as always.
- A stale background "run the whole test suite" task from an earlier, unrelated fix had been running for over 30
  minutes without finishing; it was stopped since it was no longer useful and the owner was worried about several
  Claude windows loading the PC down at once.

**Files changed:** `src/world/world.gd`, `src/main.gd`, `tests/test_world.gd`, `FEEDBACK.md`.
