# F799 round 7: frost stops growing at 3 stacks, smaller ice plates

**What we did**
- The owner liked the debuff screens. One change: the frost covered too much at 4 and 5 stacks.
- Now 1, 2 and 3 stacks grow the frost, and 3 stacks is the most it ever covers. Stacks 4, 5 and the "frozen" state look the same as 3.
  - Think of it like a cup that is full at 3 spoons: more spoons don't make it fuller.
- The ice plates (the little cracked squares) are smaller: sizes 5/9/16 became 7/12/21 in `screen_edge_flash.gdshader`.
- `hud.gd` has a new `CHILL_EDGE_MAX` (0.6, the same strength the owner saw at 3 stacks). The preview page uses the same cap.

**Hurdles**
- `godot` isn't on this PC's PATH, so `run_tests.sh` crashed at first (Claude's mistake: should have set `GODOT` right away). Found the program under WinGet and passed it in `GODOT=...`.
- One old test expected full frost at "frozen". Updated it to the new rule.

**Tests:** `only=edge_flash`, 9 checks pass. Preview page republished as version 8.
