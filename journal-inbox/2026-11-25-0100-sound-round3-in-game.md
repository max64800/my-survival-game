# 2026-11-25: Owner's sound picks, rounds 2 and 3, put in the game

**What we did (simple version):** The owner listened to 75 new sounds on the review page (round 3) and marked them.
We put every LOVE and MAYBE in the game, plus the round 2 LOVEs we had not installed yet.

- New sounds: footsteps (step), two sword swings, waterfall, bag close (2), heavy hit (2), shield block (2), parry,
  soft digging, metal clink (4 hits cut from one pickaxe recording), hard shell hit, rock thud (2).
- **Each building material now has its own placing sound** (wood, stone, brick): new slots `build_wood`, `build_stone`,
  `build_brick`, chosen in `src/build/builder.gd` (`_ev_add_piece`) by the piece's family. Stations still use `build`.
- Hit (normal): every try was "no", so the old sound stays. Beetle charge rumble: only a MAYBE for normal beetle noises,
  not the charging stomps, so nothing installed (still open). Owner's idea "Sword Thud (435210) for a boss killing blow"
  is noted, not built.
- Credits for all of it are in `CREDITS.md`.

**Hurdles and mistakes**
- The tests did not even start. Cause: another chat's commit (`c7f10613`, stairs) deleted the line
  `const WORKBENCH_RANGE` from `pieces.gd` while `builder.gd` still uses it, and an older commit left
  `World.rock_mat` in `dwarf.gd` (nothing defines it). That is why the full run earlier showed 451 failed checks.
  I put the constant back and removed the 5 dead lines in `dwarf.gd` (the next line, `_cam_fade.update`, already does the fade).
  Lesson: when a whole test run fails in world generation, look for a compile error first.
- Earlier I wrongly guessed these failures were unrelated; they were a real break in main.
