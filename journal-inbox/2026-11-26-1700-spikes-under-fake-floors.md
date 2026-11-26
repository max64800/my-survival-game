## Nov 26 — F912 🔁: you can finally see the spikes under the fake floors

**What we did:** The owner fell through Hald's fake floors but saw no spikes, and saw none in the Quiet Barrows'
trench either. This had come back from F904 and F908.
- **What the plans said:** everything was right on paper. Spike beds stood 3 m under every loose slab, 10 m under
  the bridge's cracked slabs, and all along the Barrows trench.
- **What the game showed:** a test game with a camera straight over the Hall of Candles pit showed a bare rock
  bottom. A ray shot straight down hit **rock at the hall's floor height**. The pit was covered over.
- **Cause:** the game digs each room as a box and works out "how far am I from rock" for every spot. A pit's box
  ended *exactly* at the floor of the room above. Right on that shared line both boxes say "0 m from rock", and 0
  counts as rock. So a paper-thin sheet of rock stretched over every pit at floor level. You fell through it
  (the kill check only looks at where you are), but your eyes saw that sheet, never the spikes. This hit all five
  pits in both stone dungeons (candle pit, Broken Stair pit, Hall of Names pit, the chasm under the Bridge of Oaths,
  the Ash Bridge trench).
- **Fix (`src/world/dungeon_map.gd`):** each pit's box now reaches 0.5 m up into the room above it, the way Old Pell's
  ladder shaft always did (that's why the shaft never had the sheet). Picture after: spikes at the bottom of the pit.
  The plans didn't change; only the rock digging did. "Falling in kills" works as before.
- **Tests:** `test_spikes_you_can_see_under_every_fake_floor` (test_hald) checks that each fake floor has a spike bed
  right under it, and builds the *real rock* the game makes over every spike bed to check it is open up to the floor.
  test_barrows' trench test does the same for every trench spike. I checked both tests fail on the old numbers
  ("rock at 0.0") and pass on the new ones.

**Mistakes and hurdles:**
- My first picture was taken from behind the dwarf and showed nothing useful. Fix: a camera of its own, straight
  over the pit, after the slab falls.
- In the second picture the pit looked "open with a rock floor", so I first thought the spikes were missing or sunk.
  Only the ray (rock at 0.02 m, right at floor height) showed the floor was really a lid.
- My first version of the new test passed on the broken numbers. It checked the "smooth" rock shape every 0.5 m,
  starting 0.4 m under the floor, so it stepped right past the thin sheet at exactly 0. The fixed test reads the
  real rock blocks the game builds, one per metre, through the floor line.
- Tried to empty my picture folder with `rm` on a variable path; a safety check stopped it. I used a new folder
  for each round instead.
- Found the same bug in Mossprop Workings' chasm (its top is exactly the Great Cave's floor). Asked the owner first
  (they didn't mention it); they said yes, so it got the same 0.5 m fix and the same rock check in test_mossprop.
- The full test run took 2 hours (1102 tests, 27 failed), and I had cut its output to the last 25 lines, so I could
  only see a few of the failures (Jolt body limit, test-world saving: parts I didn't touch). Instead of a second
  2-hour run, I re-ran every dungeon and ghost test file: all pass. Next time: keep only the FAIL lines, not the tail.
