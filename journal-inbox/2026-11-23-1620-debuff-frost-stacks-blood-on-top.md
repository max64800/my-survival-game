# F799/F802 round 7b: frost grows per stack but stays modest, blood shows over the ice

**What we did**
- Frost strength per chill stack (1 to 5) is now a list in `hud.gd`: `CHILL_EDGE_BY_STACK = [0.15, 0.35, 0.6, 0.68, 0.76]`.
  Stack 3 is the look the owner liked. Stacks 4, 5 and frozen are only a little bigger, so 5 never covers too much.
- Blood (low health) is now drawn on top of the frost in `screen_edge_flash.gdshader`. Before, the ice covered it and the owner could barely see it.
  Poison and fire still draw as before (approved).
- Test updated (`test_edge_flash.gd`), preview page republished (version 10).

**Hurdles**
- Claude's mistake: the owner said "one is okay, two less, three even less, four and five more". Claude read it as "stop growing at 3" first, which was wrong (the owner saw no change between 3, 4, 5).
  Fix: made a table of numbers per stack and showed it so the owner could confirm; they said yes.
- `godot` is not on this PC's PATH: run tests with `GODOT=<WinGet Godot 4.7.2 console exe>`.

**Tests:** `only=edge_flash`, 9 checks pass.
