## 2026-11-25: Brickcrown Keep page v2 (F895, the owner's page notes)

**What we did**
- The owner looked at page v1 and listed what was wrong: the brick house on top was too small, the left tower had
  no round brick roof, the courtyard was an open hollow when solid rock should cover it, the terrace should be stone,
  and the brick-mended crack should be plain stone. They drew the size the house should be on a screenshot.
- `BlueprintLibrary._brickcrown()`: storey 4 is now x -5..5, z -11..1 (5 by 6 cells). It has a 3-row-high tile roof
  with its ridge along x, gables at both ends, two dormers and a door onto the front terrace. The chimney moved to the
  right terrace strip with 5 levels, so it pokes up past the ridge. The terrace floors outside the house and all the
  terrace railings are now stone. The curtain crack is now stone.
- test_brickcrown_design: removed the "mended crack" exception, so now no brick is allowed below storey 3 at all.
- Page: the rock is now solid behind the keep, behind the curtain wall and behind the right tower, so the courtyard is
  a cave room inside it. A dark mouth sits behind the gate. "The courtyard" button turns the rock off to look in.
  Text updated. Republished as v2 at the same link.

**Mistakes and hurdles**
- `git pull` was blocked (local main clashes with origin, which the handoff already warned about). I skipped it and
  checked the to-do list against the local files instead.
- The heightfield rock can't hang over anything, so "rock over the courtyard" means the rock simply buries the yard on
  the page. The game's real carve (a lumpy room with a rock ceiling) comes when the ruin goes in.

**Left**
- The left tower's round brick roof, a new piece made in Blender (MODEL-RULES). Then the owner's OK, then the ruin in the game.
