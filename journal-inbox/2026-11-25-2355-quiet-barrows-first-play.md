## 2026-11-25: The Quiet Barrows, the owner's first play (F907-F909)

**What we did**
- The owner played Dungeon 6 for the first time and sent 3 screenshots:
  - The ghosts can't climb the stairs (F907).
  - The open strips beside the bridge need spikes (F908).
  - The Spear Gate has 4 spear walls and should have 1 (F909).
- Added tests to `tests/test_barrows.gd`. Both stair flights are walkable. A ghost follows you up the Deep Stair.
- Found where the Spiral Stair goes wrong:
  - A Bearded Shade climbs to the top and then stops 5 m short of you, probably at the doorway at the top.
  - The Barrow Warden never leaves the foot of the stair.
  - The two tests for this are parked as `todo_` (they don't run yet) until the fix.
- Checked the chasm: the rock is dug out the full 10 m and the spikes are at the bottom. In the dark it just looks like a shallow floor.
- Fixed the "5 dungeons built" check (now 6) in the copper-to-bronze chat's test file. That file is theirs, so I didn't commit it.

**Mistakes and hurdles**
- In the test runner, `only=test_barrows.name` printed nothing. Run the whole test_barrows suite instead.
- The owner asked to pause, so F907-F909 are written down with what was found. The full test suite was stopped before it finished.
