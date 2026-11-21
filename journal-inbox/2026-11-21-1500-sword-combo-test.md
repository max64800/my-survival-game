## 2026-11-21: sword combo test brought up to date

**What we did:** `test_sword_swings_the_ual_combo_slowly` (tests/test_visuals.gd) failed on "hit 3 plays at half the
pack's speed". The game was right: in chat 18 the owner asked for the sword's third hit (the jump and spin) to be 30%
slower, and `DwarfRig.attack_seconds` does that. The test still expected all three hits at the same speed (and its
message still said "half speed" from chat 15). The test now expects hit 3 at 1/0.7 of the clip length and says so.

**Hurdles:**
- `tools/run_tests.sh` failed at first: `godot` isn't on the PATH on this PC. Found Godot 4.7.2 in the WinGet packages
  folder and passed it as `GODOT=...`.
- Lesson: when the owner changes a feel number, update its test in the same commit.
