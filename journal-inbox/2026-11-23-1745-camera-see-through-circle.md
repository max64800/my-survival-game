## Nov 23 — A see-through circle round the dwarf (F807 round 3)

**What we did.** The owner liked the camera ("the camera is good") and asked for a see-through *circle*: a building
piece in the way should be almost fully clear right round the dwarf and more and more solid toward the screen's
corners, instead of the whole piece fading the same.
- New paint pieces: `src/art/see_through.gdshaderinc` (the circle: it leaves out dots, like the rock's speckle) and
  `src/art/see_through.gdshader` (a stand-in for a model's normal paint: same colour, picture and shine, plus the circle).
  The shared prop paint (`prop.gdshader`) got the circle too, for code-made pieces.
- `CameraFade` now gives each piece in the way its own copy of the see-through paint and fades it in, then puts the
  normal paint back when it's out of the way. The camera tells the paint where the dwarf and the camera are
  (three "global" values listed in `project.godot`).
- Shadows stay whole: the paint only cuts dots when it's drawn for the player's camera, not for a lamp.
- The search tube is wider now (1 m) so a piece next to the one in the way doesn't make a hard edge; floors and
  stairs below his chest are skipped.
- New knobs in `dwarf_feel.gd`: CAM_CIRCLE_MIDDLE, CAM_CIRCLE_CORNERS, CAM_CIRCLE_SIZE, CAM_CIRCLE_TUBE.
- New photo robot `-- camcheck` (builds a small stone room, photographs the dwarf from behind a wall).

**Mistakes and hurdles.**
- The known bug first: when a piece was removed while see-through, the code put the dead piece into a typed variable
  before checking it, so Godot shouted "previously freed instance" hundreds of times and test_camera_doorway failed.
  Fix: check the piece is still alive before using it.
- Claude's first try used a per-object "instance uniform" for how see-through a piece is. Every prop in the cave uses the
  same paint, so Godot ran out of room for them ("Too many instances using shader instance variables", ~2000 errors).
  Fix: only pieces in the way get their own copy of the paint, with a plain setting.
- First photo: the whole wall was almost gone everywhere, no circle. Cause: Godot's camera math flips the up-down sign,
  so the "distance from the dwarf on screen" came out negative and counted as the middle everywhere. Fix: `abs()`.
- `godot` isn't on this PC's PATH again: tests run with `GODOT=<WinGet Godot 4.7.2 console exe>`.
- The corners looked very dark at 0.15, so the corner knob is 0.3.
