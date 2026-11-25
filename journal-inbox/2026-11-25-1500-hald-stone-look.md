## Nov 25: the Tomb of Hald's stone look, and signposts at every dungeon door (F856, F857, F871, F875, F844)

**What we did**
- **F856 🔁, the buried chest on boards:** the Scribe's Niche loose stone used Mossgate's wooden board floor. Hald now has
  its own `floor_loose_flagstone` (Stonehold flagstones round a loose square stone; parts still "frame" and "stone").
  Then I looked at what stands around every one of Hald's 7 chests, not just the model names. One more wooden thing turned
  up: the recipe stand at the end is a root-wood lectern. Hald now has a stone stand (`recipe_stand_stone`, a new Storage
  kind, so the other dungeons keep theirs).
- **F857 🔁, the stash wall:** the "cracked" junction in `make_hald.py` now also places its two narrow walls beside the
  cracked wall (the gaps). The wall got a ragged hole right through its middle, so you see the chest behind it. It still
  breaks and falls in pieces.
- **F871, faint runes:** the lintel's runes are cut twice as big and deep, with a glowing amber line in each groove.
- **F875, the stand only worked at its foot:** its touch box was a chest's (0.7 m tall), below the book at 0.9-1.1 m.
  Now it is 1.25 m tall.
- **F844, signposts:** a new model (`builds/dungeon_signpost.py`): a hewn post in a stone cairn, a crossbar with three
  skulls, a board, and a green tick. The game puts one beside every dungeon's way in and shows 1, 2 or 3 skulls (small,
  medium, big). It lays the recipe's picture on the board and shows the tick once the group has learned it. Every computer
  works out the same spot from the world number (co-op ready), and the tick follows the host's learned list.
  It stands inside the doorway's clear circle, so nothing the world grows lands on it.
- 5 new tests in `tests/test_hald.gd` (the Shield-Brother test stays last). All 5 models pass the model checks.

**Mistakes and hurdles**
- **Cracked wall, round 1:** the hole looked boxy and the dark backing filled most of it, because the backing's hole was
  smaller than the ragged gap in the stones. Fix: no single backing, but strips that follow the hole row by row.
- **The strips then shimmered** (model check): neighbouring strips touched face to face, and their edges sat 1 mm from the
  stones' joints, so they showed through. Fix: each strip overlaps its neighbour with a different thickness, and the edges
  stay 3-4 cm away from the joints.
- **Small slips:** a push was rejected because another chat had pushed first (pulled and pushed again). I also looked for
  `kit_zone1.py` in the wrong folder (it is in `tools/asset_forge/builds/`).
- **The test runner** counts each test as one "check", so "1 checks" means the whole test passed, not that only one line
  ran.
