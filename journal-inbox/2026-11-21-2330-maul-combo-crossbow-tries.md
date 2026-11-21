## Nov 21, 2026: the great maul's own combo, and crossbow moves to try (dwarf-animations, chat 17)

**What we did**
- The skeleton miners were renamed (F533): Bone Rot, Hollow Miner, The Pit Boss.
- **The great maul (F534):** the owner picked the moves on the Dwarf Moves page: left click = side swing, left click = head shove, right click = the whirl. Three KayKit skeleton moves (Slice, Stab, Spinning) were baked onto the dwarf. The whirl clip is short (0.67 s), so it plays 3 turns over the heavy's 2.1 s. While it plays you walk at half speed. New test: test_great_maul_slice_shove_then_whirl.
- **Crossbow (F535, "reloads like a gun"):** the only aim and reload moves we had were pistol ones. A new bake script (crossbow_kaykit_bake.gd) turns KayKit's crossbow moves (aim, shoot, two-hand reload, one-hand reload) into normal clips for the dwarf ("c/" library). They're on the Dwarf Moves page (version 8) for the owner to judge. Not in the game yet.

**Mistakes and hurdles**
- A Python edit failed because I wrote two tabs of indent where the code had one. I fixed it and applied the edit again.
- `godot` isn't on the PATH in this shell: the full path to the WinGet Godot is needed (GODOT=... for run_tests.sh).
- First crossbow try: the bow lay sideways across his chest. The KayKit skeleton turns its hips 46° to aim; our dwarf's legs keep facing ahead, so the chest ended up turned too far. Fix: hips and head stay at rest, the chest keeps its world turn plus 40° more, so the bow line (right hand to left hand) points ahead.
- My first maths for the crossbow's turn in the hand was in the wrong frame (the crossbow's own, not its holder's). The pictures looked backward. The numbers then showed it already pointed forward, and a close-up picture agreed: the stock just reaches far behind him.
- A bake run hung for 5 minutes: `not bn in KEEP_REST` in GDScript must be written `not (bn in KEEP_REST)`. A script error keeps a SceneTree script from quitting, so runs now use `timeout`.

**Next**
- The owner watches "Crossbow: new moves to try". If OK, the game's aim, shoot and reload switch from the pistol clips to "c/Aim", "c/Shoot", "c/Reload" (DwarfRig.ANIMS.aim, DwarfModel.react shoot/reload).
