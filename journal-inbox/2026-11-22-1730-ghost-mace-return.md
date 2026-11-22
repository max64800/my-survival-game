## 2026-11-22: Ghost mace stops "teleporting" after a swing (F688), angry eyes (F681)

**What we did**
- F681: all four ghosts got angry teardrop eyes (flat glowing shapes, round bulb low and in, sharp tip up and out, a slanted cut on the inner side).
- F688: after every ghost swing, the mace jumped a little right before reaching its resting spot. Found three separate causes and fixed all three:
  1. The arm went back to rest in 0.18 s at full speed, then stopped dead. Ghosts now take 0.6 s and ease out
     (`DwarfRig.one_blend_out` / `one_ease`, set in `ghost.gd _dress`). The player's own timing is unchanged.
  2. `DwarfFist._apply_pose` blended bones one at a time against a half-blended parent. At about 17% of the way back
     a bone's "shortest way round" flipped and the arm snapped. Now every bone first gets its full pose, then each one
     blends against that finished pose.
  3. `DwarfFist._hold` slerped the weapon grip toward the swing aim, and the aim could flip to the other "hemisphere"
     in one frame (the grip spun 138°). Now it remembers last frame's sign and keeps turning the same way.
- New test `test_the_mace_eases_back_without_a_jump`: measures the mace head's speed every frame for all four ghosts;
  no frame may be 3× faster than its neighbours (now 1.3–2.4×; before up to 6.9×).
- The 3D page got the same smooth return (the grip always slerps from rest toward the swing aim).

**Mistakes and hurdles**
- Logging bone poses read back 0: the skeleton modifier's changes are gone after the frame. Fixed by measuring the
  mace head's world position instead.
- I first blamed the forearm roll; switching it off changed nothing, so that was a dead end.
- Measuring the 3D page per frame didn't work: Chrome slows animations in background tabs. Fell back to a code check
  plus "no console errors".
- Another Claude window's half-done edit (`dwarf_fight.gd:331`, `var eff_reach :=`) stopped all tests from compiling.
  I worked around it with a temporary patch in my test script that undid itself; that window has since fixed it (F687).
- Small slips: a "Cannot infer type" in my test (fixed with `: float`), an insert that split a comment line, and a sed
  that broke my test script's quotes (rewrote it).
