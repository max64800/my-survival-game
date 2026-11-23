## Nov 23: F807/F798, the jump that finished early and "sprinted" through the air

**What we did**
- The owner reported (after the dodge/dash fix): "the animation should be slowed down when he jumps... the
  animation finishes and then he just sprints forward... we've been working in circles and haven't figured it out."
- First ruled out the easy guesses: there's no separate "long jump" move in the code, and the jump pose isn't a
  looping clip that restarts (it's a short clip that just holds its last frame once it runs out, same idea as a
  paused video). That holding was the actual bug: the jump pose clip is only about half a second long, but a real
  jump can hang in the air well over a second (bigger launch speed = longer hang time, same arc either way). Once
  the clip ran out, the legs froze on its last frame — and if that frame looked anything like a running stride,
  the dwarf looked like he was already running while he was still sailing through the air.
- Fixed it the same way the dodge roll already fixes a similar problem (F702): stretch the clip's playback speed
  to match how long this specific jump is expected to stay in the air, instead of always playing it at the clip's
  own fixed speed. The expected hang time is worked out the moment he leaves the ground, from the jump's launch
  speed and gravity (schoolbook "how long does a thrown ball stay up" math) — a step off a ledge (not a real jump)
  skips this and plays the clip at its normal speed, same as before.
- Changed `src/player/dwarf_rig.gd` (added a speed-control knob to the jump pose in the animation blend tree, same
  pattern as the one already feeding the roll), `src/player/dwarf.gd` (works out the expected hang time when a
  jump starts) and `src/player/dwarf_model.gd` (passes it through). New test:
  `test_jump_animation_is_stretched_to_match_how_long_hes_really_airborne` in `tests/test_dwarf.gd`.
- Logged as F798 (fixed) in FEEDBACK.md.

**Mistakes and hurdles**
- First guess was wrong: suspected the ground-check (`is_on_floor()`) was triggering too early mid-jump and
  cutting the jump short. Reading the animation code ruled this out — the jump pose is a held pose blended by
  amount, not a timed clip that could "finish and loop" on its own, so a ground-detection bug wouldn't explain a
  clip finishing early. The real cause (a too-short clip for a long hang time) only showed up after reading how
  the already-fixed dodge roll solves the exact same kind of problem and checking whether jump had the same fix —
  it didn't.
- `src/player/dwarf.gd`, `tests/test_dwarf.gd` and `FEEDBACK.md` all had another Claude session's unrelated,
  uncommitted work mixed in (sprint/camera code, other feedback items). Committed only this fix's own lines by
  building the commit from a clean copy of each file (read from the last commit, with just this fix's edits
  applied), instead of committing the whole messy working copy.
