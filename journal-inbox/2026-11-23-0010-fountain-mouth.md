## Nov 22, late: F782 fountain, mouth cleaned

**What we did**
- The owner spotted leftover water in the dwarf's mouth, plus the small crystal there, and asked to erase both.
  `healing_fountain_trellis.py` now uses a slightly wider "darker teal water" colour test over the whole model (it used to
  check only the basin), and the mouth crystal is gone. 135 more water faces were cut. Passes the model checks; page updated.

**Mistakes and hurdles**
- Claude's darker-water test only looked low in the basin, so the darker water in the mouth was missed. The owner caught it
  on the 3D page. Fix: the test now covers the whole model (moss is safe: it is yellow-green, and the test needs blue above red).
