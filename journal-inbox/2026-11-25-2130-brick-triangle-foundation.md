## Nov 25: F725 brick triangle foundation looked old, F865 wooden steep roofs looked flat

**What we did**
- F865: the "flat, wood-like" roof after rebuilding the Smeltery was the wooden (Shack) steep roof. Its models start
  10-13 cm up, sitting on the wall's top beam. The fit check only allowed 10 cm, so the game threw the real model out
  and showed the plain shape made in code. Steep roofs now allow 15 cm, and a test fails if any buildable piece's model
  is thrown out.
- F725: the brick Triangle Foundation really did show the old first-version bricks. The new model file was on the
  drive since Nov 20, but Godot keeps its own converted copy of each model (in `.godot/imported`) and only remakes it
  when the file's "last changed" time moves. Three files (triangle foundation, brick column base, 26° brick gable end)
  kept an old time, probably from OneDrive syncing, so Godot never re-read them. Touching them and re-importing fixed
  it. New test `test_every_model_copy_is_fresh` catches this from now on.
- Added `kitcheck part=triangles` (brick foundation, triangle foundation, floor, triangle floor side by side).

**Mistakes and hurdles**
- Claude first looked in the wrong places: the model file, its icon and its textures were all fine, so Claude wrote
  "checked, not fixed" earlier today. The clue only came from asking the *running game* which paints the piece used:
  "limestone_dark, brick_a" (old names) instead of "hblime, hbbrick". Lesson: when a model looks old in the game but
  the file is new, compare the game's loaded copy, not the file.
- The first test scene put the triangle where the ruin column and the shadow hid it; moving it out in the open showed it.
- The `--import` run did nothing at first, because Godot trusts the file time before the file's contents.
