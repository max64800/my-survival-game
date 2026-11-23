## Nov 23 — The camera stops pumping at doors, and buildings in the way turn see-through (F806, F807)

**What we did**
- F806 (big priority): near a round doorway the camera jumped right into the dwarf's head and then went in, out,
  in, out. Found the cause with a new test (`tests/test_camera_doorway.gd`): 0.8 m in front of a doorway the camera
  swung between 0.35 m and 2.71 m behind him, over and over.
- The cause was a loop. When the camera got pushed in close, it also slid from over his shoulder to behind his head.
  That slide moved where its "feeler" (an invisible ball that checks for walls) starts. Behind his head the line back
  through the doorway was clear, so the camera glided out, slid back to the shoulder, scraped the round frame, and
  jumped in again. Like a dog chasing its own tail.
- Fix: the sideways spot now comes from the zoom you chose, not from where the camera got pushed to. A new
  `CameraRoom.best_side` tries four spots from the shoulder in toward the middle and takes the farthest-out one with
  a clear line back. The choice depends only on where he stands, so it can't chase itself. It also keeps the old
  F766 promise: in a narrow tunnel the camera still tucks in behind his head.
- F807: a new `src/player/camera_fade.gd`. Each frame a fat invisible tube from the camera to his chest finds the
  built pieces inside it; they fade to about half see-through (knob `CAM_BUILD_FADE` in `dwarf_feel.gd`) and fade
  back when they're out of the way. It uses Godot's own per-model "transparency", so every model keeps its paint.
  Test: `tests/test_camera_fade.gd`.
- Committed `dwarf_feel.gd` (and the other chat's journal note): code already in the repo used it, but the file
  itself had never been committed, so a fresh copy of the project wouldn't even start.

**Mistakes and hurdles**
- The test runner couldn't find Godot (`godot` isn't a command on this PC). It's installed by WinGet in
  `AppData\Local\Microsoft\WinGet\Packages\GodotEngine...`; set `GODOT` to its `_console.exe`.
- Claude's first fix only checked the shoulder spot sideways. The in-out loop stopped, but the camera still sat
  jammed against his head, because the line back went through the doorway off-centre and its edge scraped the frame.
  Trying several spots toward the middle fixed that.
- Claude's first draft of the helper had two leftover junk lines (a loop that did nothing, and a line using a
  name from inside the loop). Caught on reading it back, before any run.
- Checked the fix the honest way: put the old camera line back for a moment and the new tests failed (3 jumps
  walking through a doorway), then restored the fix.
- 4 to 5 `test_dwarf` checks fail (hair swing, stun meter, fists, one aim check). They fail the same way with the
  old camera, so they come from other unfinished work, not this.
