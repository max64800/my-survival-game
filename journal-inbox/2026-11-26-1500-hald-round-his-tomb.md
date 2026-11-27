## Nov 26 — F910 🔁: Hald Ironbrow can now get round his tomb

**What we did:** The owner could hide behind Hald's tomb for ever: "he tries to fit between the tomb and the brazier,
and he just can't fit." F902 (Nov 25) had taught ghosts to step round things, but only by turning left or right
in front of whatever was in the way.
- **Cause:** the gap between the tomb and each brazier is about 1.0 m, and Hald's body is about 1.2 m wide.
  His "is the way open?" check looked along one thin line, so the gap looked open to him. He also looked only
  1.6 m ahead, so he never saw that the way round the far side of a brazier was free.
- **Fix (`src/combat/ghost.gd`):** when his straight way is blocked and you are on his floor, he lays a small grid
  of 40 cm squares over the floor between you both. He marks every square where his round body would touch stone,
  then walks the shortest free path (Godot's ready-made `AStarGrid2D`). The map is redrawn every 0.4 s. The
  look-ahead check now looks along his middle and both edges. If the map finds no path, the old steering still
  runs, and it swaps sides if he hardly moves for a second.
- **Test:** `test_hald_comes_round_his_tomb_to_you` (tests/test_hald.gd) copies the real tomb, braziers and helm
  plinth sizes from Hald's plan into a test room. You hide at three spots behind the tomb, and Hald starts from two
  spots. He must reach you every time.

**Mistakes and hurdles:**
- Claude's first fix (the wider check plus swapping sides) still failed the new test: with you behind the middle of
  the tomb, Hald paced from one brazier gap to the other. That was the same "turn left or right" idea that had
  already failed in F902, so Claude switched to the grid map.
- The test room took three tries before Hald would chase at all. A stand-in dungeon with too few parts threw an
  error. Then Hald thought you had left the dungeon, because its outline box was still at the real tomb. Then he
  slept for ever, because he didn't know which room was his. The fix was to use the real Tomb map, moved onto the
  test room.
- The grid map and the wide check broke `test_a_ghost_follows_you_up_the_grand_stair`, because both took stair
  steps for walls. Now both are used only when you are on his floor level (within 0.6 m up or down). On stairs the
  old thin-line way still runs.
- `only=test_hald_comes_round` picked no file and passed with 0 checks. `only=` takes a file; one test needs
  `only=test_hald fn=<test name>`.
- The owner said mid-task that no spikes show under the breaking floors in either stone dungeon. Claude logged it as
  F912 🔁 (from F904 and F908), and the owner chose to fix it in a new chat.
