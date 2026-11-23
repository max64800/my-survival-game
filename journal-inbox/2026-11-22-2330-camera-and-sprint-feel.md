## Nov 22 — Dwarf-sized camera and a heavy dwarf's sprint (F469, F766, F775)

**What we did**
- New knob file `src/player/dwarf_feel.gd`: every camera and sprint number in one place, each with a plain note.
- Camera: looks at his chest (0.9 m, was 1.0), starts at 3.0 m (was 3.4). Looking down stretches it out 15%,
  looking up brings it in 25%. The spring arm now only *feels* for rock; the camera is placed by hand, so it
  jumps in at once when rock is behind it and glides back out instead of popping. The over-the-shoulder offset now
  shrinks when rock pushes the camera in (it used to stay out to the side, inside a narrow tunnel's wall).
- Rock between the camera and his chest fades to a speckle (a dither in `terrain.gdshader`, fed every frame through
  the new `World.rock_mat`). Picked over fading whole terrain chunks, which would hide big parts of the cave.
- Sprint: walk → sprint ramps over 0.45 s (eased), back over 0.3 s; sprinting turns at most 0.6 turns a second;
  letting go mid-sprint skids about 1 m; sprint stops while one dodge's energy is left (and waits for 10 more before
  sprinting again, so it doesn't stutter); the view widens 4° at full sprint.
- 6 new tests in `tests/test_dwarf.gd` (ramp, turn, skid, dodge reserve, camera tilt, camera slide-in + glide-out).

**Hurdles and mistakes**
- `tools/run_tests.sh` couldn't find Godot (`godot` isn't on this PC's PATH). Fixed by pointing `GODOT` at the
  WinGet copy of Godot 4.7.2.
- The SpringArm3D moves its children itself, both ways, instantly. Taking the camera off it was the only way to get
  a slow glide back out.
- My dodge-reserve test failed: sprint stopped at 19.91 energy, just under a dodge's 20 (the last running step
  dipped under). Fixed by stopping one step early.
- 4 dwarf tests already failed before this work (aim skips things behind, stun meter, braid tufts, fist room in big
  swings). I checked by running the old code. Not touched here.
