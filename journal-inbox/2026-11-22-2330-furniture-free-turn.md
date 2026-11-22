## Nov 22 (night, PC): furniture turns any way and shows its real shape while placing (F726)

**What we did**
- The owner said tables, stools and other furniture showed only as a box while placing and only turned a quarter at a time.
  The crafting bench already did it right: a see-through copy of the real model, turned 5° a tap.
- Furniture and loose decor (place "free", not wall decor, not old ruin wreckage, not the corner turret) now:
  - show their real model as the green/red ghost (before, every ghost used the plain code shape, which is a box for furniture);
  - turn 5° per Q / E tap, and a smooth 60° a second when held (the same pace as the stations);
  - go where you aim in 10 cm steps instead of 50 cm.
- How the turn is saved: the turn number already had 0-3 for quarter turns and 4-15 for 30° steps. 16-87 now mean 5° steps.
  Old saves, blueprints and ruins keep exactly the same numbers, so nothing old moves.
- New test: `tests/test_free_turn_furniture.gd` (turn numbers, snapping, Q/E steps, ghost = real model).

**Mistakes and hurdles**
- `godot` isn't on the Bash PATH on the PC again; ran the tests with `GODOT` set to the WinGet console exe.
- `git diff --strip-trailing-cr` isn't a git option (it's a `diff` one). Instead I built my own versions of the shared files
  (HEAD + only my changes) and put them in a separate index, so other chats' unsaved work in pieces.gd, piece_node.gd and
  FEEDBACK files stayed out of my commit.
- `test_new_pieces` crashed once (segfault in the hatch test), then passed on a re-run: a flaky crash, not from this change.
- `test_ruin_spire.test_spot_is_found_quickly` fails ("the same spot every time"). Not from this change (old turn numbers
  give identical results); another chat has unsaved changes in `cave_maker.gd`, which picks that spot.
